## ADDED Requirements

### Requirement: Car model faces its direction of travel
A displayed car model's nose SHALL point along the vehicle's forward direction, so that when the vehicle accelerates it appears to drive nose-first. This SHALL hold for every selectable car. Correcting facing SHALL be a purely visual adjustment of the model's orientation and SHALL NOT alter the vehicle's physics forward direction, handling, collision, or selection.

#### Scenario: Selected car drives nose-first
- **WHEN** any selectable car is chosen and the accelerate control is held
- **THEN** the car travels in the direction its nose points, not its rear

#### Scenario: Facing fix does not change handling
- **WHEN** a car whose facing was corrected is driven in the race
- **THEN** acceleration, braking/reverse, steering, drift, and camera-follow behave exactly as before the facing fix
