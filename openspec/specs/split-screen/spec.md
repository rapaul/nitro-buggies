# split-screen

## Purpose

Render the race for one or two players: a single full-screen view in single-player, or a stacked horizontal split with a per-player chase camera in two-player, sharing one game world.

## Requirements

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
In single-player mode the race SHALL render a single full-screen view with one chase camera following the player's car, unchanged from the existing single-player presentation. The shared world MAY additionally contain the AI opponent car (see the `ai-opponent` capability); the lone full-screen camera SHALL still follow only the player's car, with the opponent simply visible within that view when in frame.

#### Scenario: One full-screen view in single-player
- **WHEN** the race starts in single-player mode
- **THEN** the screen shows a single full-screen chase-camera view following the player's car, with no split

#### Scenario: Opponent visible but not followed
- **WHEN** a single-player race includes the AI opponent and the opponent is within the camera's view
- **THEN** the opponent car is visible in the full-screen view, while the camera continues to follow only the player's car

### Requirement: Off-edge respawn applies to every car
The existing off-edge respawn behavior SHALL apply to each car independently in two-player mode, so either car that falls off the edge is respawned without affecting the other.

#### Scenario: One car falls off in two-player mode
- **WHEN** one player's car falls off the edge for the respawn delay while the other stays in bounds
- **THEN** only the fallen car is respawned at the centre and the other car continues unaffected
