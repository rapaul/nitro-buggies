## MODIFIED Requirements

### Requirement: ENTER starts the game
The landing screen SHALL be staged: first a player-count selection, then vehicle picking. The accept action SHALL advance through the stages rather than starting the race immediately. Confirming the player-count selection SHALL advance to vehicle picking. The race SHALL start only once every required vehicle pick has been confirmed — one confirmation in single-player, and both players' confirmations in two-player — at which point each confirmed vehicle is recorded and the screen transitions to the main game scene.

#### Scenario: Confirming the mode advances to vehicle picking
- **WHEN** the landing screen is showing the player-count selection and the player confirms a choice
- **THEN** the screen advances to vehicle picking and the race does not start yet

#### Scenario: Single-player confirm starts the race
- **WHEN** single-player was chosen and the player confirms a vehicle
- **THEN** the chosen vehicle is recorded and the screen transitions to the main game scene

#### Scenario: Two-player starts only after both confirm
- **WHEN** two-player was chosen and only one player has confirmed a vehicle
- **THEN** the race does not start, and it transitions to the main game scene only once the second player also confirms, recording both chosen vehicles

#### Scenario: Game does not start before confirmation
- **WHEN** the landing screen is visible and the required confirmations have not been made
- **THEN** the main game scene does not start and the landing screen remains displayed
