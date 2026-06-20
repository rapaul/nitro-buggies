## ADDED Requirements

### Requirement: Player-count selection on launch
The landing screen SHALL present a player-count selection before vehicle picking, offering exactly two choices labelled "1P" and "2P". On entry "1P" SHALL be the selected choice.

#### Scenario: Mode selection shown first
- **WHEN** the landing screen is shown on launch
- **THEN** a player-count selection with the choices "1P" and "2P" is presented before any vehicle picking, and "1P" is selected by default

#### Scenario: Exactly two choices
- **WHEN** the player-count selection is visible
- **THEN** exactly two choices are offered — "1P" and "2P" — and exactly one of them is selected at any time

### Requirement: Mode labels use the title font and selection box
The "1P" and "2P" labels SHALL be drawn in the same block display font used for the "Nitro Buggies" title, and the currently selected label SHALL be enclosed by the same chunky square selection outline used by the vehicle picker.

#### Scenario: Labels match the title font
- **WHEN** the player-count selection is rendered
- **THEN** the "1P" and "2P" labels use the same block display font as the title

#### Scenario: Selected label has the chunky square box
- **WHEN** a player-count choice is selected
- **THEN** a chunky square outline, matching the vehicle picker's selection highlight, encloses the selected label, and only the selected label is enclosed

### Requirement: Navigate and confirm the player count
The player SHALL move the selection between "1P" and "2P" using the keyboard, and confirm it with the accept action. Confirming SHALL record the chosen player count and advance to vehicle picking.

#### Scenario: Move the selection
- **WHEN** "1P" is selected and the player presses the navigation key toward "2P"
- **THEN** the selection moves to "2P" and the chunky square box follows it

#### Scenario: Confirm records the count and advances
- **WHEN** a player-count choice is selected and the player presses the accept action
- **THEN** the chosen player count (1 or 2) is recorded and the screen advances to vehicle picking
