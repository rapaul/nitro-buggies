# vehicle-selection

## Purpose

Let the player pick which vehicle they race, presented as a row of rotating 3D previews on the landing screen, so the chosen model carries through into gameplay.

## Requirements

### Requirement: Three random distinct vehicles
The landing screen SHALL present exactly three vehicle previews, each showing a distinct 3D vehicle model chosen at random from the Kenney car kit, with no model appearing more than once.

#### Scenario: Three distinct models are shown
- **WHEN** the landing screen is shown
- **THEN** three vehicle previews are displayed, each a different vehicle model from the car kit, and no model is repeated

#### Scenario: Selection is randomized per visit
- **WHEN** the landing screen is entered on separate occasions
- **THEN** the set of three models is drawn at random each time and is not fixed to a single hardcoded trio

#### Scenario: Only drivable vehicles are eligible
- **WHEN** the three models are picked
- **THEN** they are drawn only from drivable vehicle models in the kit, never from non-vehicle props such as cones, debris, boxes, or loose wheels

### Requirement: Picker layout in the bottom two-thirds
The three previews SHALL be laid out within the bottom two-thirds of the screen (below the title area), arranged in a single row, equally spaced, with visible margins on all sides — above, below, between the previews, and to the left and right.

#### Scenario: Previews sit below the title
- **WHEN** the landing screen is visible
- **THEN** all three previews are positioned within the lower two-thirds of the viewport, clear of the title in the top third

#### Scenario: Equal spacing with margins
- **WHEN** the previews are laid out
- **THEN** they form one evenly-spaced row with margins around the group and equal gaps between previews, so no preview touches a screen edge or its neighbor

#### Scenario: Vehicle height is about one third of the resolution
- **WHEN** a vehicle is rendered in its preview
- **THEN** the vehicle's on-screen height is approximately one third of the viewport height, scaling with the resolution

#### Scenario: Shared ground line
- **WHEN** the three vehicles are displayed
- **THEN** the bottom of each vehicle rests at the same screen height, so they appear to sit on a common ground level regardless of their differing sizes

### Requirement: Previews rotate slowly
Each vehicle preview SHALL rotate continuously about its vertical axis at one full revolution every three seconds, independent of frame rate.

#### Scenario: One revolution per three seconds
- **WHEN** a preview is displayed for three seconds
- **THEN** its model has rotated a full 360 degrees about the vertical axis

#### Scenario: Rotation is frame-rate independent
- **WHEN** the frame rate varies
- **THEN** the rotation rate remains one revolution every three seconds rather than scaling with frames

### Requirement: Preview viewing angle
Each vehicle SHALL be shown upright — its underside toward the bottom of the screen, not from a top-down angle — and tilted so the back of the vehicle rides up by about 15 degrees.

#### Scenario: Upright, back-tilted presentation
- **WHEN** a preview is displayed
- **THEN** the vehicle is seen from a near-horizontal angle with its underside toward the bottom of the screen and its back raised by roughly 15 degrees

### Requirement: Selection highlight starts on the left
Exactly one preview SHALL be marked as selected at all times, indicated by a chunky square outline drawn around it large enough that the vehicle model sits entirely inside the square. On entry the leftmost preview SHALL be the selected one.

#### Scenario: Left preview selected on entry
- **WHEN** the landing screen is first shown
- **THEN** the leftmost preview is the selected one and is enclosed by the chunky square outline

#### Scenario: Car fits inside the square
- **WHEN** the selection highlight is drawn around a preview
- **THEN** the outline is a chunky square sized so the whole vehicle model is contained within it

#### Scenario: Exactly one selection
- **WHEN** the picker is visible
- **THEN** exactly one preview carries the selection highlight at any time

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

### Requirement: Confirmed vehicle carries into the race
When a player confirms their selection, the game SHALL record that player's selected vehicle model and start the race once all required players have confirmed, with each player's in-game car rendering the model that player selected.

#### Scenario: Selected model is used in gameplay
- **WHEN** a player confirms a selected vehicle and the race starts
- **THEN** that player's car in the race renders the model that player selected on the landing screen

#### Scenario: Each player gets their own model in two-player
- **WHEN** two players confirm different vehicles and the two-player race starts
- **THEN** Player 1's car renders Player 1's chosen model and Player 2's car renders Player 2's chosen model
