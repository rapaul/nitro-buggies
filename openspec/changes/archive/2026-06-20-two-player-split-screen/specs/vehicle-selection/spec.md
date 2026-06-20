## ADDED Requirements

### Requirement: Two-player simultaneous split picking
In two-player mode the vehicle picker SHALL be shown for both players at the same time, with Player 1's picker in the top half of the screen and Player 2's picker in the bottom half. Each picker SHALL present its own three random distinct vehicles and be navigated independently by its own player's controls. Each player SHALL confirm their own selection independently, and the race SHALL start only once both players have confirmed.

#### Scenario: Two pickers shown at once, split top and bottom
- **WHEN** two-player mode begins vehicle picking
- **THEN** Player 1's picker fills the top half and Player 2's picker fills the bottom half, both visible and active at the same time

#### Scenario: Independent navigation
- **WHEN** Player 1 navigates their picker with their own keys
- **THEN** only Player 1's selection moves and Player 2's selection is unaffected, and vice versa

#### Scenario: Each player confirms independently
- **WHEN** one player confirms their selection while the other has not
- **THEN** that player's selection is locked in, the other player can still navigate and confirm, and the race starts only after both have confirmed

## MODIFIED Requirements

### Requirement: Navigate selection left and right
The player SHALL move the selection one preview left or right. In single-player the selection responds to the keyboard arrow keys, the A and D keys, the gamepad d-pad, or the gamepad left stick. In two-player mode each player navigates their own picker only — Player 1 with the A and D keys, Player 2 with the left and right arrow keys. Navigation SHALL clamp at the ends: pressing left on the leftmost preview or right on the rightmost preview leaves the selection unchanged.

#### Scenario: Move right
- **WHEN** a non-rightmost preview is selected and the player presses right with the controls for their picker
- **THEN** the selection moves one preview to the right and the highlight follows it

#### Scenario: Move left
- **WHEN** a non-leftmost preview is selected and the player presses left with the controls for their picker
- **THEN** the selection moves one preview to the left and the highlight follows it

#### Scenario: Per-player controls in two-player mode
- **WHEN** two-player picking is active
- **THEN** Player 1's picker responds only to A/D and Player 2's picker responds only to the left/right arrow keys

#### Scenario: Clamp at the left end
- **WHEN** the leftmost preview is selected and the player presses left
- **THEN** the selection stays on the leftmost preview

#### Scenario: Clamp at the right end
- **WHEN** the rightmost preview is selected and the player presses right
- **THEN** the selection stays on the rightmost preview

### Requirement: Confirmed vehicle carries into the race
When a player confirms their selection, the game SHALL record that player's selected vehicle model and start the race once all required players have confirmed, with each player's in-game car rendering the model that player selected.

#### Scenario: Selected model is used in gameplay
- **WHEN** a player confirms a selected vehicle and the race starts
- **THEN** that player's car in the race renders the model that player selected on the landing screen

#### Scenario: Each player gets their own model in two-player
- **WHEN** two players confirm different vehicles and the two-player race starts
- **THEN** Player 1's car renders Player 1's chosen model and Player 2's car renders Player 2's chosen model
