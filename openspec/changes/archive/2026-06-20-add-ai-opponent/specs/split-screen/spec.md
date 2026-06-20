## MODIFIED Requirements

### Requirement: Single-player remains full screen
In single-player mode the race SHALL render a single full-screen view with one chase camera following the player's car, unchanged from the existing single-player presentation. The shared world MAY additionally contain the AI opponent car (see the `ai-opponent` capability); the lone full-screen camera SHALL still follow only the player's car, with the opponent simply visible within that view when in frame.

#### Scenario: One full-screen view in single-player
- **WHEN** the race starts in single-player mode
- **THEN** the screen shows a single full-screen chase-camera view following the player's car, with no split

#### Scenario: Opponent visible but not followed
- **WHEN** a single-player race includes the AI opponent and the opponent is within the camera's view
- **THEN** the opponent car is visible in the full-screen view, while the camera continues to follow only the player's car
