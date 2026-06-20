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
