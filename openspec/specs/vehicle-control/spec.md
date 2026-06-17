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

### Requirement: Gravity and ground support
The player vehicle SHALL be pulled downward by gravity and SHALL rest on and be supported by the terrain surface beneath it, rather than treating motion as confined to a flat plane.

#### Scenario: Settles onto the terrain
- **WHEN** the car starts or is positioned above the terrain
- **THEN** gravity brings it down until it rests on the surface, after which it does not continue to sink or drift downward

#### Scenario: Follows terrain slope while grounded
- **WHEN** the car drives up or down a dune face while remaining in contact with the surface
- **THEN** its height changes to follow the slope and it stays on the ground rather than nosing through the surface or floating off gentle bumps

### Requirement: Launching off a crest
The player vehicle SHALL become airborne when it crosses a dune crest with enough speed that its momentum carries it off the surface, rather than being forced to cling to the terrain.

#### Scenario: Fast crest crossing goes airborne
- **WHEN** the car crosses a dune crest at high speed
- **THEN** it leaves the surface and enters an airborne state with upward/forward momentum

#### Scenario: Slow crest crossing stays grounded
- **WHEN** the car crosses the same crest at low speed
- **THEN** it remains in contact with the surface and follows the contour without launching

### Requirement: Airborne flight
While airborne, the player vehicle SHALL follow a ballistic arc governed by gravity and its momentum at takeoff, and throttle SHALL NOT add forward speed and lateral grip SHALL NOT redirect motion until the car lands.

#### Scenario: Ballistic arc
- **WHEN** the car is airborne after a jump
- **THEN** it rises and falls along an arc under gravity and descends back toward the terrain

#### Scenario: No thrust or grip in the air
- **WHEN** the accelerate or steer controls are applied while the car is airborne
- **THEN** they do not change the car's airborne trajectory (no mid-air acceleration or grip-based redirection), though the car's heading may still rotate

### Requirement: Landing
The player vehicle SHALL return to grounded handling when it contacts the terrain after a jump, resuming normal acceleration, steering, and grip.

#### Scenario: Resumes driving after landing
- **WHEN** the airborne car descends and contacts the terrain surface
- **THEN** it returns to the grounded state and responds again to throttle, steering, and grip

### Requirement: Orientation follows terrain slope
While grounded, the player vehicle's visual orientation SHALL approximate the angle of the terrain beneath it, pitching and rolling so its wheels sit on the surface, rather than remaining level with the horizon. This orientation is presentation only and SHALL NOT change the car's handling — acceleration, steering, grip, jump launch, and frame-rate independence are unaffected.

#### Scenario: Pitches up a dune face
- **WHEN** the car drives up a dune face while remaining in contact with the surface
- **THEN** its nose tilts upward to approximate the slope rather than staying level with the horizon

#### Scenario: Rolls on a side-slope
- **WHEN** the car traverses a slope that rises to one side
- **THEN** it rolls toward the downhill side to approximate the lateral angle of the surface

#### Scenario: Handling unchanged by tilt
- **WHEN** the same throttle and steering inputs are applied with terrain-slope orientation enabled
- **THEN** the car's resulting position and heading match the prior planar handling within a small tolerance, so the tilt does not alter how the car drives

### Requirement: Smoothly eased orientation
While grounded, the vehicle's terrain-slope orientation SHALL ease smoothly between surface angles so it never snaps between adjacent terrain facets.

#### Scenario: No snapping between facets
- **WHEN** the car crosses from one terrain facet to an adjacent one with a different slope
- **THEN** its orientation eases toward the new angle over a short time rather than snapping instantly

### Requirement: Airborne angular momentum and self-righting
While airborne, the vehicle SHALL retain some of the angular momentum it carried at takeoff, continuing to rotate in the air rather than snapping instantly to level. It SHALL also right itself like a cat, so that by the time it contacts the terrain its orientation has returned to wheels-down regardless of its takeoff angle or how it tumbled in the air.

#### Scenario: Carries rotation into the air
- **WHEN** the car launches off a crest while pitched or rolled
- **THEN** it continues to rotate in the air for a time, carrying its takeoff angular momentum, rather than snapping immediately to level

#### Scenario: Always lands on its wheels
- **WHEN** the airborne car descends and contacts the terrain
- **THEN** its orientation has righted to wheels-down (approximately level with the surface) so it lands on its wheels, regardless of its orientation at takeoff
