## MODIFIED Requirements

### Requirement: Rolling sand-dune surface
The gameplay world SHALL present a continuous, undulating sand-dune surface in place of a flat ground plane. The dunes SHALL form **elongated ridges** — crest lines that run long in one horizontal direction — rather than a field of discrete rounded hills. Successive ridges SHALL be **spaced further apart** than a field of small bumps, and each dune face SHALL be **gentle enough that climbing it from trough to crest takes a sustained ascent** (a low slope per metre travelled), not a short steep step.

#### Scenario: Surface forms elongated ridges
- **WHEN** the gameplay scene loads
- **THEN** the drivable ground is a continuous undulating surface whose crests form long ridge lines, and the height differs noticeably between dune crests and the troughs between them

#### Scenario: Ridges are widely spaced with gentle faces
- **WHEN** the car drives from a trough toward the next crest
- **THEN** the crest is reached only after a sustained climb across a wide, gently sloped face, rather than immediately cresting a short steep bump

## ADDED Requirements

### Requirement: Sandy desert appearance
The terrain SHALL read as warm golden desert sand under a low, golden-hour sun that produces clear relief, not as a uniformly lit flat color, and the surrounding sky/horizon SHALL read as a pale, hazy warm desert sky. The scene SHALL be lit so that sun-facing dune slopes catch warm direct light while slopes facing away from the sun fall into ambient-only ("diffuse") shading lit by a dimmer, cooler sky fill, producing a visible terminator across the dune faces. The directional sun SHALL rake **across** the ridge lines (the ridges run long in one horizontal direction; the sun's horizontal travel SHALL be roughly perpendicular to them) so that successive ridges alternate lit and shaded rather than being evenly flat. The troughs between ridges SHALL receive contact shading (e.g. SSAO) so the hollows read as recessed. The sand albedo SHALL carry large-scale tonal variation across the surface so it does not read as a single flat color, while still keeping the car and the flat spawn corridor clearly readable from the chase camera.

#### Scenario: Low sun produces relief on the dune faces
- **WHEN** the gameplay scene is rendered
- **THEN** dune slopes facing the sun appear distinctly brighter and warmer than slopes facing away, and the slopes facing away are shaded (lit only by the cooler ambient fill) rather than appearing the same brightness as the lit slopes

#### Scenario: Troughs read as recessed
- **WHEN** the surface is rendered with successive ridges and troughs
- **THEN** the troughs between ridges appear darker/recessed relative to the crests, giving the field visible depth

#### Scenario: Surface is not a single flat color
- **WHEN** the terrain is viewed from the gameplay chase camera
- **THEN** the sand shows tonal variation across its surface rather than one uniform color, while still reading clearly as warm golden sand

#### Scenario: Gameplay view stays readable
- **WHEN** the car is driven across the dune field under the golden-hour lighting
- **THEN** the car and the flat spawn corridor remain clearly visible (the shadowed faces are darkened but not crushed to black)

### Requirement: Wind-ripple banding (optional)
The terrain MAY display wind-ripple banding across the dune faces to evoke a sand sea. This sub-requirement is satisfied either by visible ripple banding OR by being intentionally dropped — it SHALL only be implemented if a prototype confirms the banding actually reads at the gameplay chase-camera distance. If implemented, the ripples SHALL be expressed primarily through albedo light/dark banding (not solely a normal map, which prototyping showed is invisible at this distance) and SHALL run roughly perpendicular to the prevailing slope rather than as isotropic noise.

#### Scenario: Ripple banding reads at gameplay distance, or is dropped
- **WHEN** the realism work is complete
- **THEN** either parallel ripple banding is visible across the dune faces from the gameplay camera, OR the ripple feature is documented as dropped because it did not read at distance — and in neither case does an invisible/ineffective ripple effect remain in the shipped material
