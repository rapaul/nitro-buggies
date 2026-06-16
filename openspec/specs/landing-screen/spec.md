# landing-screen

## Purpose

Give the game a front door: a branded title screen shown before gameplay, so the player sees "Nitro Buggies" and an explicit start gate rather than dropping straight into the race.

## Requirements

### Requirement: Landing screen is the entry point
The game SHALL boot into the landing screen before any gameplay, so the player sees the title and an explicit start gate rather than dropping directly into the race.

#### Scenario: Game launches into the landing screen
- **WHEN** the project is launched
- **THEN** the landing screen is the first scene shown and the main game scene is not yet running

### Requirement: Title presentation
The landing screen SHALL display the title text "Nitro Buggies" in the top third of the screen, set in an 80s-style block display font, colored sandy yellow, with comfortable margins from the top, left, and right edges.

#### Scenario: Title is shown in the top third
- **WHEN** the landing screen is visible
- **THEN** the text "Nitro Buggies" is rendered within the top third of the viewport, inset from the top, left, and right edges by a visible margin

#### Scenario: Title color and font
- **WHEN** the title is rendered
- **THEN** its glyphs use an 80s block display font and are filled in a sandy-yellow color

### Requirement: Title block shadow
The title SHALL be backed by a solid block drop-shadow in a sandy-orange color, offset toward the lower-right of the title, producing a chunky 80s look.

#### Scenario: Shadow is offset lower-right
- **WHEN** the title is rendered
- **THEN** a sandy-orange copy of the title sits behind it, offset to the right and below, and remains visible behind the sandy-yellow face

### Requirement: Dark background
The landing screen SHALL fill the viewport with a very dark grey background behind the title.

#### Scenario: Background fills the screen
- **WHEN** the landing screen is visible
- **THEN** the entire viewport behind the title is a very dark grey

### Requirement: Resolution-independent title scaling
The landing screen SHALL keep the title at a constant proportion of the screen regardless of window size or resolution, so the title does not appear small when the window is enlarged or maximized.

#### Scenario: Title scales with the window
- **WHEN** the window is resized or maximized to a larger resolution
- **THEN** the title (and its block shadow and margins) scale up proportionally and occupy the same fraction of the screen as at the base resolution

#### Scenario: Wider aspect adds margin, not distortion
- **WHEN** the window is a wider aspect ratio than the base resolution
- **THEN** the title keeps its proportions and remains centered, with the extra width appearing as additional side margin rather than stretched glyphs

### Requirement: ENTER starts the game
Pressing ENTER (or the gamepad confirm action) on the landing screen SHALL confirm the currently selected vehicle and then transition into the main game scene.

#### Scenario: ENTER confirms the selection and loads the main game
- **WHEN** the landing screen is visible and the player presses ENTER
- **THEN** the currently highlighted vehicle is recorded as the chosen vehicle and the screen transitions to the main game scene

#### Scenario: Game does not start before ENTER
- **WHEN** the landing screen is visible and ENTER has not been pressed
- **THEN** the main game scene does not start and the landing screen remains displayed
