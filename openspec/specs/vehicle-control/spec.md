# vehicle-control

## Purpose

Define arcade vehicle handling for the player car — acceleration, braking/reverse, speed-dependent steering, drift/grip, and deterministic fixed-tick physics.

## Requirements

### Requirement: Forward acceleration
The player vehicle SHALL accelerate forward when the accelerate control is applied, with speed scaling proportionally to analog throttle input and capped at a maximum forward speed.

#### Scenario: Throttle from standstill
- **WHEN** the car is stationary and the accelerate control is held at full
- **THEN** the car gains forward speed over time until it reaches its maximum forward speed and does not exceed it

#### Scenario: Partial analog throttle
- **WHEN** the accelerate control is applied at roughly half its analog range
- **THEN** the car accelerates more gently than at full throttle and settles at a lower steady-state speed

### Requirement: Braking and reverse
The player vehicle SHALL slow down when the brake control is applied while moving forward, and SHALL move in reverse when the brake control is held after the car has stopped.

#### Scenario: Braking while moving forward
- **WHEN** the car is moving forward and the brake control is applied
- **THEN** the car decelerates toward a stop

#### Scenario: Engaging reverse
- **WHEN** the car is stopped and the brake control continues to be held
- **THEN** the car accelerates backward up to a maximum reverse speed that is lower than the maximum forward speed

### Requirement: Steering
The player vehicle SHALL turn left or right based on analog steering input, and the turn rate SHALL depend on the car's current speed so that the car cannot pivot in place at zero speed.

#### Scenario: Steering while moving
- **WHEN** the car is moving forward and steering input is applied to one side
- **THEN** the car's heading rotates toward that side and it follows a curved path

#### Scenario: No steering at standstill
- **WHEN** the car is stationary and steering input is applied
- **THEN** the car's heading does not change appreciably until the car begins to move

### Requirement: Drift and grip behavior
The player vehicle SHALL exhibit lateral grip that resists sideways sliding under normal cornering, and SHALL allow the rear to slide (drift) when grip is reduced via the handbrake control.

#### Scenario: Gripped cornering
- **WHEN** the car corners at moderate speed without the handbrake
- **THEN** the car tracks the steered direction with limited sideways slide

#### Scenario: Handbrake drift
- **WHEN** the handbrake control is applied while cornering at speed
- **THEN** lateral grip is reduced and the rear of the car slides outward, producing a drift

### Requirement: Deterministic fixed-tick handling
Vehicle physics and handling SHALL be integrated on Godot's fixed physics tick so that car behavior is independent of rendering frame rate.

#### Scenario: Frame-rate independence
- **WHEN** the same throttle and steering inputs are applied over the same elapsed time at different rendering frame rates
- **THEN** the car reaches an equivalent position and heading within a small tolerance
