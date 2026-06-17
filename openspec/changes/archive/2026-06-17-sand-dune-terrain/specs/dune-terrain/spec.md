## ADDED Requirements

### Requirement: Rolling sand-dune surface
The gameplay world SHALL present a continuous, undulating sand-dune surface in place of a flat ground plane. The surface SHALL vary in height across the play area so the car drives up and down dune faces rather than across level ground.

#### Scenario: Surface varies in height
- **WHEN** the gameplay scene loads
- **THEN** the drivable ground is a continuous undulating surface whose height differs noticeably between dune crests and the troughs between them

#### Scenario: Sandy appearance
- **WHEN** the gameplay scene is rendered
- **THEN** the terrain reads visually as sand (sandy color/material) rather than the previous flat green plane

### Requirement: Terrain collision
The dune surface SHALL have collision that conforms to its shape so the car rests on and drives along the actual contour of the dunes, with no gaps the car can fall through within the play area.

#### Scenario: Car rests on the surface contour
- **WHEN** the car is placed anywhere within the play area and left under gravity
- **THEN** it comes to rest on the dune surface at that location's height rather than passing through it or floating above it

#### Scenario: Collision tracks the visible shape
- **WHEN** the car drives from a trough up a dune face
- **THEN** its supported height rises in step with the visible slope, matching where the surface is drawn

### Requirement: Jumpable crests
At least some dune crests SHALL be shaped so that a car approaching at high speed leaves the surface at the crest, producing a jump, rather than the terrain being so gentle that the car never becomes airborne.

#### Scenario: Crest launches a fast car
- **WHEN** the car climbs a dune face at high speed and passes over the crest
- **THEN** the terrain shape allows the car to leave the ground at the crest and travel through the air before landing

#### Scenario: Bounded, traversable play area
- **WHEN** the car drives across the play area
- **THEN** the dunes remain drivable (no walls so steep the car cannot climb or descend them at normal speed) across the full bounded area
