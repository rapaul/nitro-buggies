# vehicle-respawn

## Purpose

Detect when the player car falls off the edge of the playable area and respawn it at the centre after a sustained fall, clearing its momentum.

## Requirements

### Requirement: Fall-off-edge detection
The game SHALL detect when the player car has left the playable area. The car is considered fallen off the edge while its horizontal position is beyond the play-area bounds on either the X or Z axis.

#### Scenario: Car drives past the edge
- **WHEN** the car's horizontal position moves beyond the boundary of the playable area
- **THEN** the car is considered to be falling off the edge

#### Scenario: Car remains within the play area
- **WHEN** the car is anywhere inside the playable area, including airborne during a normal jump
- **THEN** the car is not considered to be falling off the edge and no respawn is triggered

### Requirement: Respawn after sustained fall
The game SHALL respawn the player car once it has been falling off the edge continuously for 1 second. A fall shorter than 1 second SHALL NOT trigger a respawn.

#### Scenario: Sustained fall triggers respawn
- **WHEN** the car has been beyond the play-area bounds continuously for 1 second
- **THEN** the car is respawned

#### Scenario: Returning before the delay cancels the respawn
- **WHEN** the car leaves the play-area bounds and returns within the play area before 1 second has elapsed
- **THEN** no respawn occurs and the fall timer is reset

### Requirement: Respawn placement and state reset
When the car respawns, the game SHALL place it at the centre of the play area, 20 metres above the ground, and SHALL reset its velocity so it does not retain the momentum from the fall.

#### Scenario: Respawn location
- **WHEN** the car is respawned
- **THEN** it is positioned at the horizontal centre of the play area, 20 metres above the ground at that point, and falls back down to land under normal gravity

#### Scenario: Momentum is cleared
- **WHEN** the car is respawned after falling off the edge at speed
- **THEN** its velocity is reset so it begins the respawn descent without carrying the previous fall's velocity
