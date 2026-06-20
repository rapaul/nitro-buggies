# player-input

## Purpose

Define device-agnostic player input for driving so gameplay reads named actions across keyboard and gamepad, with analog control and runtime controller hotplug support.

## Requirements

### Requirement: Device-agnostic input actions
The game SHALL define input via Godot `InputMap` actions (accelerate, brake/reverse, steer, handbrake, pause) so that gameplay code reads named actions rather than specific device buttons.

#### Scenario: Gameplay reads named actions
- **WHEN** the vehicle controller queries input
- **THEN** it reads from named `InputMap` actions and never references hardware-specific button or key codes directly

### Requirement: Gamepad analog control
The game SHALL read steering and throttle from analog gamepad axes so that the car responds proportionally to how far the stick or trigger is pressed.

#### Scenario: Analog steering
- **WHEN** a gamepad's left stick X axis is moved partway
- **THEN** the steering input reported to the vehicle is proportional to the axis displacement

#### Scenario: Analog throttle and brake
- **WHEN** the right trigger (accelerate) or left trigger (brake) is pressed partway
- **THEN** the corresponding throttle or brake magnitude is proportional to trigger travel

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

### Requirement: Controller hotplug detection
The game SHALL detect gamepad connection and disconnection at runtime and continue accepting input from a controller connected after the game has started.

#### Scenario: Connect after launch
- **WHEN** a gamepad is connected while the game is already running
- **THEN** the game recognizes the controller and its analog input drives the car without a restart

#### Scenario: Disconnect during play
- **WHEN** the active gamepad is disconnected during play
- **THEN** the game stops applying its input and remains controllable via the keyboard fallback

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
