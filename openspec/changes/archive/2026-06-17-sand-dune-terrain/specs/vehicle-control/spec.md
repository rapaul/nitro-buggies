## ADDED Requirements

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
