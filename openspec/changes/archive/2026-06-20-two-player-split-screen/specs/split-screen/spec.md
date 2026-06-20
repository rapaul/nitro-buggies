## ADDED Requirements

### Requirement: Two-player horizontal split
In two-player mode the race SHALL render two viewports of the same world stacked vertically, with Player 1's view filling the top half of the screen and Player 2's view filling the bottom half.

#### Scenario: Screen is split top and bottom
- **WHEN** the race starts in two-player mode
- **THEN** the screen is divided horizontally into two equal halves, Player 1's view on top and Player 2's view on the bottom

#### Scenario: Both views show the same world
- **WHEN** the two-player race is running
- **THEN** both halves render the same shared game world (terrain, lighting, and both cars), each from its own camera

### Requirement: Per-player car and chase camera
In two-player mode the race SHALL spawn one car per player, and each half's view SHALL be a third-person chase camera following only that player's car, behaving like the single-player chase camera.

#### Scenario: Each half follows its own car
- **WHEN** the two-player race is running and a player drives
- **THEN** that player's half follows that player's car with the chase camera, and the other half is unaffected

#### Scenario: Both cars exist in the world
- **WHEN** the two-player race starts
- **THEN** two cars are present in the shared world, one per player

### Requirement: Single-player remains full screen
In single-player mode the race SHALL render a single full-screen view with one car and one chase camera, unchanged from the existing single-player presentation.

#### Scenario: One full-screen view in single-player
- **WHEN** the race starts in single-player mode
- **THEN** the screen shows a single full-screen chase-camera view of one car, with no split

### Requirement: Off-edge respawn applies to every car
The existing off-edge respawn behavior SHALL apply to each car independently in two-player mode, so either car that falls off the edge is respawned without affecting the other.

#### Scenario: One car falls off in two-player mode
- **WHEN** one player's car falls off the edge for the respawn delay while the other stays in bounds
- **THEN** only the fallen car is respawned at the centre and the other car continues unaffected
