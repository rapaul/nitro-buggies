## ADDED Requirements

### Requirement: Two-player keyboard split
In two-player mode the keyboard SHALL be split into two independent control sets: Player 1 drives with WASD (W accelerate, S brake/reverse, A steer left, D steer right) plus a Player 1 handbrake key, and Player 2 drives with the arrow keys (Up accelerate, Down brake/reverse, Left steer left, Right steer right) plus a separate Player 2 handbrake key. Each control set SHALL drive only its own player's car.

#### Scenario: Player 1 controls only car 1
- **WHEN** two-player mode is running and Player 1 presses W, A, S, or D
- **THEN** only Player 1's car responds and Player 2's car is unaffected

#### Scenario: Player 2 controls only car 2
- **WHEN** two-player mode is running and Player 2 presses an arrow key
- **THEN** only Player 2's car responds and Player 1's car is unaffected

#### Scenario: Both players drive at once
- **WHEN** both players press their driving keys simultaneously
- **THEN** each car responds to its own player's input independently

## MODIFIED Requirements

### Requirement: WASD keyboard control
The game SHALL always provide WASD keyboard bindings for Player 1 driving — W accelerate, S brake/reverse, A steer left, D steer right — so the car is fully drivable with WASD regardless of whether a gamepad is connected. Digital key presses SHALL be treated as full-magnitude analog input. The arrow keys SHALL be reserved as Player 2's driving controls and SHALL NOT also drive Player 1's car, so that in two-player mode the two control sets stay independent.

#### Scenario: WASD driving with no gamepad
- **WHEN** no gamepad is connected and the player uses W, A, S, and D
- **THEN** the car accelerates, brakes/reverses, and steers left/right equivalently to gamepad control

#### Scenario: WASD always available alongside a gamepad
- **WHEN** a gamepad is connected and in use
- **THEN** W, A, S, D continue to drive Player 1's car, and either input source can be used at any time without a mode switch

#### Scenario: Arrow keys are Player 2's, not a Player 1 alias
- **WHEN** two-player mode is running and an arrow key is pressed
- **THEN** only Player 2's car responds, and Player 1's car (WASD) is not driven by the arrow keys

#### Scenario: Full keyboard playability
- **WHEN** the player uses the keyboard only
- **THEN** every gameplay action — accelerate, brake/reverse, steer, handbrake, and pause — is reachable from the keyboard for each active player
