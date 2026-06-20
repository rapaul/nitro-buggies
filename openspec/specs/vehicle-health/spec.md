# vehicle-health

## Purpose

Give each vehicle a finite three-bar health value that fireball hits deplete, with an on-screen bar and elimination when it runs out.

## Requirements

### Requirement: Vehicles have a three-bar health value
Every vehicle SHALL start each race with a health value of three bars. The health value SHALL never go below zero or above three.

#### Scenario: Full health at start
- **WHEN** a race starts
- **THEN** each vehicle has three of three health bars

### Requirement: Health bar shown on the player's view
Each player's view SHALL display that vehicle's current health as a bar of three segments — the full screen in single-player, that player's half in two-player. The display SHALL update when the vehicle's health changes.

#### Scenario: Health display reflects current bars
- **WHEN** a vehicle's health changes
- **THEN** that player's health bar shows the current number of bars remaining

### Requirement: Taking damage removes health bars
A vehicle SHALL lose health when damaged. A fireball hit SHALL remove exactly one bar. Damage SHALL clamp the health at zero (a vehicle already at zero cannot go negative).

#### Scenario: One fireball hit removes one bar
- **WHEN** a vehicle at full health is hit by a fireball
- **THEN** its health drops to two bars

#### Scenario: Damage clamps at zero
- **WHEN** a vehicle with zero bars would take further damage
- **THEN** its health stays at zero

### Requirement: Losing all bars eliminates the vehicle
When a vehicle's health reaches zero, that vehicle SHALL be eliminated — that player has lost the race.

#### Scenario: Third hit eliminates
- **WHEN** a vehicle loses its third and last health bar
- **THEN** that vehicle is eliminated and its player has lost
