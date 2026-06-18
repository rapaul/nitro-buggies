## ADDED Requirements

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
