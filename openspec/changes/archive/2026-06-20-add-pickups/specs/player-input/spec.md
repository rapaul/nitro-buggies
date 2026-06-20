## ADDED Requirements

### Requirement: Per-player use-item action
The game SHALL define a "use item" `InputMap` action for each active player so the held pickup can be triggered: a Player 1 use action and a separate Player 2 use action. Each SHALL have a keyboard binding, with a gamepad fallback, and each SHALL trigger only its own player's car. The use action SHALL follow the same `input_prefix` convention as the other per-player driving actions (the unprefixed action for Player 1, the `p2_` action for Player 2).

#### Scenario: Player 1 use triggers only car 1
- **WHEN** the Player 1 use action is pressed
- **THEN** only Player 1's car uses its held pickup and Player 2's car is unaffected

#### Scenario: Player 2 use triggers only car 2
- **WHEN** two-player mode is running and the Player 2 use action is pressed
- **THEN** only Player 2's car uses its held pickup and Player 1's car is unaffected

#### Scenario: Reachable from the keyboard
- **WHEN** a player uses the keyboard only
- **THEN** the use-item action is reachable from the keyboard for each active player
