# NFT Battle Arena

Turn-based combat system where players battle their NFT characters in strategic combat.

## Features

- Turn-based combat mechanics
- HP-based battle system
- Player statistics tracking
- Battle history and outcomes
- Strategic damage dealing (1-30 per turn)

## How to Battle

1. Create a battle by calling `create-battle` with opponent address
2. Take turns calling `attack` with damage amount (1-30)
3. Battle continues until one player reaches 0 HP
4. Winner is recorded and stats updated

## Smart Contract Functions

- `create-battle`: Start a new battle with opponent
- `attack`: Deal damage during your turn
- `get-battle`: View battle details
- `get-player-stats`: Check win/loss record
- `get-battle-count`: Total battles created

## Game Mechanics

- Each player starts with 100 HP
- Damage per attack: 1-30 points
- Turn-based system ensures fair play
- Automatic winner determination