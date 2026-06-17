## MODIFIED Requirements

### Requirement: High-angle top-down view
The camera SHALL be positioned as a third-person chase camera that sits low and close behind the player car, looking forward along the car's heading so the horizon is visible, rather than framing the scene from a high overhead top-down angle.

#### Scenario: Third-person framing
- **WHEN** the gameplay scene loads
- **THEN** the player car is framed from behind at a low angle, with the ground ahead of the car and the horizon visible

#### Scenario: Camera follows the car's heading
- **WHEN** the car turns to face a new direction
- **THEN** the camera swings around to remain behind the car relative to its heading, keeping the car's forward direction pointing into the screen

### Requirement: Smooth follow
The camera SHALL follow the player car so the car stays within frame, using smoothed motion rather than rigidly snapping to the car's position and orientation each frame.

#### Scenario: Following a moving car
- **WHEN** the car drives across the ground plane
- **THEN** the camera tracks it so the car remains in view, easing toward the chase position rather than jumping instantly

#### Scenario: Stable when stationary
- **WHEN** the car is stationary
- **THEN** the camera settles to a steady position without jitter
