## ADDED Requirements

### Requirement: Sand spray from the rear wheels
The player vehicle SHALL emit a sand-spray particle effect from behind each of its two rear wheels while it is driving on the ground, so that moving over the sand kicks up a visible trail of grains. The spray SHALL be presentation-only: it SHALL NOT alter the vehicle's handling, collision, input response, or physics forward direction. The two emitters SHALL stay positioned behind the rear wheels as the car climbs, descends, jumps, and tumbles (i.e. they SHALL track the vehicle body's heading, not its visually tilted/rolling model).

#### Scenario: Driving on the ground sprays sand
- **WHEN** the car is on the ground and moving at a normal driving speed
- **THEN** a sand-spray trail is emitted from behind each rear wheel

#### Scenario: Two trails, one per rear wheel
- **WHEN** the spray is active
- **THEN** there are two distinct emitters positioned behind the left and right rear wheels, mirrored across the car's centre line

#### Scenario: Spray does not change handling
- **WHEN** the car with the spray effect is driven
- **THEN** acceleration, braking/reverse, steering, drift, jumping/landing, and camera-follow behave exactly as before the effect was added

### Requirement: Spray is gated to wheels-on-sand motion
The sand spray SHALL be emitted only while the vehicle is grounded and in motion. The vehicle SHALL NOT emit spray while airborne, while stationary, or while rolling below a small speed threshold. A sideways slide (drift) SHALL also trigger spray even if forward speed is low.

#### Scenario: No spray while airborne
- **WHEN** the car leaves the ground (cresting a dune or jumping)
- **THEN** no sand spray is emitted until the wheels are back on the ground

#### Scenario: No spray while stopped
- **WHEN** the car is stationary (or rolling below the speed threshold) on the ground
- **THEN** no sand spray is emitted

#### Scenario: Drifting sprays sand
- **WHEN** the car is sliding sideways (e.g. a handbrake drift) on the ground
- **THEN** sand spray is emitted even if its forward speed is low

### Requirement: Spray intensity tracks speed and drift
The amount of sand thrown SHALL scale with how hard the car is working the surface — increasing with forward speed and with the magnitude of sideways slide — so that fast driving and hard drifts visibly throw more sand than slow, gentle motion.

#### Scenario: Faster driving throws more sand
- **WHEN** the car drives forward faster
- **THEN** the spray becomes more intense than at low speed

#### Scenario: Hard drift throws more sand than a cruise
- **WHEN** the car is in a hard sideways drift
- **THEN** the spray fans out more than during straight-line cruising at the same throttle
