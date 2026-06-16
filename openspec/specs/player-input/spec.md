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
The game SHALL always provide WASD keyboard bindings for driving — W accelerate, S brake/reverse, A steer left, D steer right — so the car is fully drivable with WASD regardless of whether a gamepad is connected. Digital key presses SHALL be treated as full-magnitude analog input. Arrow keys MAY be bound as additional aliases, but WASD bindings MUST always be present.

#### Scenario: WASD driving with no gamepad
- **WHEN** no gamepad is connected and the player uses W, A, S, and D
- **THEN** the car accelerates, brakes/reverses, and steers left/right equivalently to gamepad control

#### Scenario: WASD always available alongside a gamepad
- **WHEN** a gamepad is connected and in use
- **THEN** W, A, S, D continue to drive the car, and either input source can be used at any time without a mode switch

#### Scenario: Full keyboard playability
- **WHEN** the player uses the keyboard only
- **THEN** every gameplay action — accelerate, brake/reverse, steer, handbrake, and pause — is reachable from the keyboard

### Requirement: Controller hotplug detection
The game SHALL detect gamepad connection and disconnection at runtime and continue accepting input from a controller connected after the game has started.

#### Scenario: Connect after launch
- **WHEN** a gamepad is connected while the game is already running
- **THEN** the game recognizes the controller and its analog input drives the car without a restart

#### Scenario: Disconnect during play
- **WHEN** the active gamepad is disconnected during play
- **THEN** the game stops applying its input and remains controllable via the keyboard fallback
