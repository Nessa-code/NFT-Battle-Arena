;; NFT Battle Arena - Turn-based combat with NFT characters
;; Players can battle their NFTs against each other

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_BATTLE_NOT_FOUND (err u201))
(define-constant ERR_NOT_PLAYER_TURN (err u202))
(define-constant ERR_BATTLE_FINISHED (err u203))
(define-constant ERR_INVALID_ACTION (err u204))
(define-constant ERR_SAME_PLAYER (err u205))
(define-constant ERR_BATTLE_ACTIVE (err u206))

(define-data-var battle-counter uint u0)

(define-map battles
  { battle-id: uint }
  {
    player1: principal,
    player2: principal,
    player1-hp: uint,
    player2-hp: uint,
    current-turn: principal,
    status: (string-ascii 20),
    winner: (optional principal)
  }
)

(define-map player-stats
  { player: principal }
  { wins: uint, losses: uint, battles: uint }
)

(define-public (create-battle (opponent principal))
  (let
    (
      (battle-id (+ (var-get battle-counter) u1))
      (initial-hp u100)
    )
    (asserts! (not (is-eq tx-sender opponent)) ERR_SAME_PLAYER)
    (var-set battle-counter battle-id)
    (map-set battles
      { battle-id: battle-id }
      {
        player1: tx-sender,
        player2: opponent,
        player1-hp: initial-hp,
        player2-hp: initial-hp,
        current-turn: tx-sender,
        status: "active",
        winner: none
      }
    )
    (ok battle-id)
  )
)

(define-public (attack (battle-id uint) (damage uint))
  (let
    (
      (battle (unwrap! (map-get? battles { battle-id: battle-id }) ERR_BATTLE_NOT_FOUND))
      (is-player1 (is-eq tx-sender (get player1 battle)))
      (is-player2 (is-eq tx-sender (get player2 battle)))
      (is-current-turn (is-eq tx-sender (get current-turn battle)))
    )
    (asserts! (or is-player1 is-player2) ERR_UNAUTHORIZED)
    (asserts! is-current-turn ERR_NOT_PLAYER_TURN)
    (asserts! (is-eq (get status battle) "active") ERR_BATTLE_FINISHED)
    (asserts! (and (> damage u0) (<= damage u30)) ERR_INVALID_ACTION)
    
    (let
      (
        (new-player1-hp (if is-player2 (- (get player1-hp battle) damage) (get player1-hp battle)))
        (new-player2-hp (if is-player1 (- (get player2-hp battle) damage) (get player2-hp battle)))
        (next-turn (if is-player1 (get player2 battle) (get player1 battle)))
        (battle-over (or (<= new-player1-hp u0) (<= new-player2-hp u0)))
        (winner (if battle-over
                   (if (<= new-player1-hp u0) (some (get player2 battle)) (some (get player1 battle)))
                   none))
        (new-status (if battle-over "finished" "active"))
      )
      (map-set battles
        { battle-id: battle-id }
        {
          player1: (get player1 battle),
          player2: (get player2 battle),
          player1-hp: new-player1-hp,
          player2-hp: new-player2-hp,
          current-turn: (if battle-over (get current-turn battle) next-turn),
          status: new-status,
          winner: winner
        }
      )
      (if battle-over
        (begin
          (update-player-stats (get player1 battle) winner)
          (update-player-stats (get player2 battle) winner)
        )
        true
      )
      (ok { damage: damage, battle-over: battle-over, winner: winner })
    )
  )
)

;; Heal action - Players can heal instead of attacking
(define-public (heal (battle-id uint) (heal-amount uint))
  (let
    (
      (battle (unwrap! (map-get? battles { battle-id: battle-id }) ERR_BATTLE_NOT_FOUND))
      (is-player1 (is-eq tx-sender (get player1 battle)))
      (is-player2 (is-eq tx-sender (get player2 battle)))
      (is-current-turn (is-eq tx-sender (get current-turn battle)))
    )
    (asserts! (or is-player1 is-player2) ERR_UNAUTHORIZED)
    (asserts! is-current-turn ERR_NOT_PLAYER_TURN)
    (asserts! (is-eq (get status battle) "active") ERR_BATTLE_FINISHED)
    (asserts! (and (> heal-amount u0) (<= heal-amount u20)) ERR_INVALID_ACTION)
    
    (let
      (
        (current-player1-hp (get player1-hp battle))
        (current-player2-hp (get player2-hp battle))
        (new-player1-hp (if is-player1 
                           (if (> (+ current-player1-hp heal-amount) u100) 
                               u100 
                               (+ current-player1-hp heal-amount))
                           current-player1-hp))
        (new-player2-hp (if is-player2 
                           (if (> (+ current-player2-hp heal-amount) u100) 
                               u100 
                               (+ current-player2-hp heal-amount))
                           current-player2-hp))
        (next-turn (if is-player1 (get player2 battle) (get player1 battle)))
      )
      (map-set battles
        { battle-id: battle-id }
        {
          player1: (get player1 battle),
          player2: (get player2 battle),
          player1-hp: new-player1-hp,
          player2-hp: new-player2-hp,
          current-turn: next-turn,
          status: (get status battle),
          winner: (get winner battle)
        }
      )
      (ok { heal-amount: heal-amount, new-hp: (if is-player1 new-player1-hp new-player2-hp) })
    )
  )
)

;; Forfeit battle - Player can surrender and end the battle
(define-public (forfeit-battle (battle-id uint))
  (let
    (
      (battle (unwrap! (map-get? battles { battle-id: battle-id }) ERR_BATTLE_NOT_FOUND))
      (is-player1 (is-eq tx-sender (get player1 battle)))
      (is-player2 (is-eq tx-sender (get player2 battle)))
    )
    (asserts! (or is-player1 is-player2) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status battle) "active") ERR_BATTLE_FINISHED)
    
    (let
      (
        (winner (if is-player1 (some (get player2 battle)) (some (get player1 battle))))
        (loser tx-sender)
      )
      (map-set battles
        { battle-id: battle-id }
        {
          player1: (get player1 battle),
          player2: (get player2 battle),
          player1-hp: (get player1-hp battle),
          player2-hp: (get player2-hp battle),
          current-turn: (get current-turn battle),
          status: "forfeited",
          winner: winner
        }
      )
      (update-player-stats (get player1 battle) winner)
      (update-player-stats (get player2 battle) winner)
      (ok { forfeited-by: loser, winner: winner })
    )
  )
)

;; Private helper function for updating player statistics
(define-private (update-player-stats (player principal) (winner (optional principal)))
  (let
    (
      (current-stats (default-to { wins: u0, losses: u0, battles: u0 }
                       (map-get? player-stats { player: player })))
      (won (is-eq (some player) winner))
    )
    (map-set player-stats
      { player: player }
      {
        wins: (if won (+ (get wins current-stats) u1) (get wins current-stats)),
        losses: (if won (get losses current-stats) (+ (get losses current-stats) u1)),
        battles: (+ (get battles current-stats) u1)
      }
    )
  )
)

;; Read-only functions for querying contract state
(define-read-only (get-battle (battle-id uint))
  (map-get? battles { battle-id: battle-id })
)

(define-read-only (get-player-stats (player principal))
  (map-get? player-stats { player: player })
)

(define-read-only (get-battle-count)
  (var-get battle-counter)
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)

(define-read-only (get-battle-status (battle-id uint))
  (let
    (
      (battle (map-get? battles { battle-id: battle-id }))
    )
    (if (is-some battle)
      (unwrap-panic battle)
      { status: "not found" }
    )
  )
)

;; Get active battles for a specific player
(define-read-only (get-player-active-battles (player principal))
  (filter get-is-player-battle-active 
          (map get-battle-id-from-index (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)))
)

;; Helper function to get battle ID from index (only up to current battle count)
(define-private (get-battle-id-from-index (index uint))
  (if (<= index (var-get battle-counter)) index u0)
)

;; Helper function to check if a battle ID corresponds to an active battle for a player
(define-private (get-is-player-battle-active (battle-id uint))
  (if (is-eq battle-id u0) 
    false
    (match (map-get? battles { battle-id: battle-id })
      battle-data (and (or (is-eq tx-sender (get player1 battle-data)) 
                          (is-eq tx-sender (get player2 battle-data)))
                      (is-eq (get status battle-data) "active"))
      false
    )
  )
)

;; Get contract information
(define-read-only (get-contract-info)
  {
    owner: CONTRACT_OWNER,
    battle-count: (var-get battle-counter)
  }
)
;; End of NFT Battle Arena contract
;; Players can create battles, attack, heal, forfeit, and query battle and player statistics