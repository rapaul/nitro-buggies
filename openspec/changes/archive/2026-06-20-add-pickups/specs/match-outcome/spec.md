## ADDED Requirements

### Requirement: Eliminated player sees a faded WASTED screen
When a player's vehicle is eliminated (health reaches zero), that player's portion of the screen SHALL fade and display the word "WASTED" in the title font, coloured in red and orange.

#### Scenario: WASTED on elimination
- **WHEN** a player's vehicle loses its last health bar
- **THEN** that player's portion of the screen fades and shows "WASTED" in the title font, coloured red/orange

### Requirement: Surviving player sees a WINNER screen
When a player's vehicle is eliminated, the surviving player's view SHALL display the word "WINNER" in the title font, coloured gold.

#### Scenario: WINNER on the other view
- **WHEN** one player's vehicle is eliminated and another vehicle remains
- **THEN** the surviving player's view shows "WINNER" in the title font, coloured gold

### Requirement: Outcome typeface matches the title
The "WASTED" and "WINNER" words SHALL be drawn in the same block display font used for the "Nitro Buggies" title, differing only in colour (red/orange for WASTED, gold for WINNER).

#### Scenario: Same font as the title
- **WHEN** a WASTED or WINNER message is shown
- **THEN** it uses the same display font as the landing-screen title
