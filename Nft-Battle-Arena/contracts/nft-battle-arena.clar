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
