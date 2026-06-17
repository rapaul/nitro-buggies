## MODIFIED Requirements

### Requirement: Rolling sand-dune surface
The gameplay world SHALL present a continuous, undulating sand-dune surface in place of a flat ground plane. The dunes SHALL form **elongated ridges** — crest lines that run long in one horizontal direction — rather than a field of discrete rounded hills. Successive ridges SHALL be **spaced further apart** than a field of small bumps, and each dune face SHALL be **gentle enough that climbing it from trough to crest takes a sustained ascent** (a low slope per metre travelled), not a short steep step.

#### Scenario: Surface forms elongated ridges
- **WHEN** the gameplay scene loads
- **THEN** the drivable ground is a continuous undulating surface whose crests form long ridge lines, and the height differs noticeably between dune crests and the troughs between them

#### Scenario: Ridges are widely spaced with gentle faces
- **WHEN** the car drives from a trough toward the next crest
- **THEN** the crest is reached only after a sustained climb across a wide, gently sloped face, rather than immediately cresting a short steep bump

#### Scenario: Sandy appearance matches a warm desert palette
- **WHEN** the gameplay scene is rendered
- **THEN** the terrain reads as warm golden desert sand and the surrounding sky/horizon reads as a pale, hazy warm desert sky, evoking the Sahara reference rather than the previous pale-yellow ground

### Requirement: Jumpable crests
At least some dune crests SHALL be shaped so that a car approaching at high speed leaves the surface at the crest, producing a jump, rather than the terrain being so gentle that the car never becomes airborne. Because the faces are gentler than before, the crest itself MAY require a higher approach speed to launch, but a jump at full throttle SHALL remain achievable.

#### Scenario: Crest launches a fast car
- **WHEN** the car climbs a dune face at full throttle and passes over a crest
- **THEN** the terrain shape allows the car to leave the ground at the crest and travel through the air before landing

#### Scenario: Bounded, traversable play area
- **WHEN** the car drives across the play area
- **THEN** the dunes remain drivable (no walls so steep the car cannot climb or descend them at normal speed) across the full bounded area
