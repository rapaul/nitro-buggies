## ADDED Requirements

### Requirement: Car models render in their kit colors
Car models SHALL render using the shared car-kit palette atlas (`colormap.png`) so that their body, windows, lights, and wheels show their intended colors, rather than appearing as untextured white. This SHALL apply wherever a car model is displayed.

#### Scenario: Model shows color, not white
- **WHEN** a car model is instantiated and displayed
- **THEN** its mesh surfaces carry a material whose albedo texture is the colormap palette (non-null), so the rendered car shows distinct colors rather than a uniform white

#### Scenario: In-race vehicle is colored
- **WHEN** the main game scene runs and the selected vehicle is shown
- **THEN** the vehicle renders with its colormap colors

#### Scenario: Landing-screen previews are colored
- **WHEN** the landing screen shows its rotating vehicle previews
- **THEN** each preview vehicle renders with its colormap colors

### Requirement: Appearance does not alter handling or selection
Applying the kit colors SHALL be a purely visual change and SHALL NOT alter vehicle handling, collision, selection, camera, or scene-flow behavior.

#### Scenario: Behavior unchanged after coloring
- **WHEN** the colored car is driven in the race
- **THEN** acceleration, braking/reverse, steering, drift, and camera-follow behave exactly as before the appearance change
