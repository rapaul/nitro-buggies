## MODIFIED Requirements

### Requirement: Smooth follow
The camera SHALL follow the player car so the car stays within frame, using smoothed motion rather than rigidly snapping to the car's position and orientation each frame. The camera SHALL NOT jerk or whip behind the car: the heading it trails and the point it looks at SHALL both be damped so that sharp steering and the car bobbing over dune crests produce steady, eased motion rather than abrupt swings.

#### Scenario: Following a moving car
- **WHEN** the car drives across the terrain
- **THEN** the camera tracks it so the car remains in view, easing toward the chase position rather than jumping instantly

#### Scenario: Stable when stationary
- **WHEN** the car is stationary
- **THEN** the camera settles to a steady position without jitter

#### Scenario: Steady through a sharp turn
- **WHEN** the car turns sharply
- **THEN** the camera eases around to trail the new heading without whipping past or snapping instantly behind the car

#### Scenario: Steady over dune crests
- **WHEN** the car bobs up and down crossing dunes
- **THEN** the camera's aim eases with the motion rather than jerking its pitch up and down each frame
