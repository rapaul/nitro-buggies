## MODIFIED Requirements

### Requirement: ENTER starts the game
Pressing ENTER (or the gamepad confirm action) on the landing screen SHALL confirm the currently selected vehicle and then transition into the main game scene.

#### Scenario: ENTER confirms the selection and loads the main game
- **WHEN** the landing screen is visible and the player presses ENTER
- **THEN** the currently highlighted vehicle is recorded as the chosen vehicle and the screen transitions to the main game scene

#### Scenario: Game does not start before ENTER
- **WHEN** the landing screen is visible and ENTER has not been pressed
- **THEN** the main game scene does not start and the landing screen remains displayed
