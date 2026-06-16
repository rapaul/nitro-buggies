# top-down-camera

## Purpose

Provide a high-angle top-down 3D camera that smoothly follows the player car, keeping it framed without jitter.

## Requirements

### Requirement: High-angle top-down view
The camera SHALL be positioned at a high angle above the player car so the scene reads as top-down while remaining a 3D view.

#### Scenario: Top-down framing
- **WHEN** the gameplay scene loads
- **THEN** the player car is framed from a high overhead angle with the ground plane visible around it

### Requirement: Smooth follow
The camera SHALL follow the player car so the car stays within frame, using smoothed motion rather than rigidly snapping to the car's position each frame.

#### Scenario: Following a moving car
- **WHEN** the car drives across the ground plane
- **THEN** the camera tracks it so the car remains in view, easing toward the car's position rather than jumping instantly

#### Scenario: Stable when stationary
- **WHEN** the car is stationary
- **THEN** the camera settles to a steady position without jitter
