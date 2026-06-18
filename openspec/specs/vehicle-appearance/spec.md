# vehicle-appearance

## Purpose

Ensure car models display their intended kit colors (the shared colormap palette) wherever they are shown — the landing-screen previews and the in-race vehicle — rather than rendering as untextured white.

## Requirements

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

### Requirement: Car model faces its direction of travel
A displayed car model's nose SHALL point along the vehicle's forward direction, so that when the vehicle accelerates it appears to drive nose-first. This SHALL hold for every selectable car. Correcting facing SHALL be a purely visual adjustment of the model's orientation and SHALL NOT alter the vehicle's physics forward direction, handling, collision, or selection.

#### Scenario: Selected car drives nose-first
- **WHEN** any selectable car is chosen and the accelerate control is held
- **THEN** the car travels in the direction its nose points, not its rear

#### Scenario: Facing fix does not change handling
- **WHEN** a car whose facing was corrected is driven in the race
- **THEN** acceleration, braking/reverse, steering, drift, and camera-follow behave exactly as before the facing fix

### Requirement: Car visually rests on the terrain surface
The displayed car SHALL appear to rest on the dune surface directly beneath it, so there is no visible gap between the car and the ground (and thus between the car and its cast shadow) while the car is grounded, including on sloped terrain. The terrain height used for grounding SHALL come from the shared `DuneHeight` source so the visual surface, the collision surface, and the grounding can never drift apart. Grounding SHALL be a purely visual adjustment of the model's vertical placement and SHALL NOT alter the vehicle's physics body, collision, handling, jump/launch, floor detection, or selection.

#### Scenario: Grounded car meets the surface on a slope
- **WHEN** the car is at rest or driving on a sloped region of the dunes
- **THEN** the lowest point of the car mesh sits within a small tolerance of the `DuneHeight` surface sampled beneath the car, rather than floating above it

#### Scenario: Grounded car meets the surface on flat ground and in valleys
- **WHEN** the car is grounded on flat ground or at a valley floor
- **THEN** the lowest point of the car mesh rests on the surface with no upward gap

#### Scenario: Grounding does not change handling
- **WHEN** the car is driven in the race after the grounding adjustment
- **THEN** acceleration, braking/reverse, steering, drift, jump/launch, and camera-follow behave exactly as before the grounding change

#### Scenario: Airborne car is not pinned to the terrain
- **WHEN** the car launches off a crest and is airborne
- **THEN** the car mesh follows the body's ballistic height and is not snapped down to the terrain surface, and on landing it returns to resting on the surface
