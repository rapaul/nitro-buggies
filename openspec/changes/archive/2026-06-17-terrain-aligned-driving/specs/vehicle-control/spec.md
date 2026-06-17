## ADDED Requirements

### Requirement: Orientation follows terrain slope
While grounded, the player vehicle's visual orientation SHALL approximate the angle of the terrain beneath it, pitching and rolling so its wheels sit on the surface, rather than remaining level with the horizon. This orientation is presentation only and SHALL NOT change the car's handling — acceleration, steering, grip, jump launch, and frame-rate independence are unaffected.

#### Scenario: Pitches up a dune face
- **WHEN** the car drives up a dune face while remaining in contact with the surface
- **THEN** its nose tilts upward to approximate the slope rather than staying level with the horizon

#### Scenario: Rolls on a side-slope
- **WHEN** the car traverses a slope that rises to one side
- **THEN** it rolls toward the downhill side to approximate the lateral angle of the surface

#### Scenario: Handling unchanged by tilt
- **WHEN** the same throttle and steering inputs are applied with terrain-slope orientation enabled
- **THEN** the car's resulting position and heading match the prior planar handling within a small tolerance, so the tilt does not alter how the car drives

### Requirement: Smoothly eased orientation
While grounded, the vehicle's terrain-slope orientation SHALL ease smoothly between surface angles so it never snaps between adjacent terrain facets.

#### Scenario: No snapping between facets
- **WHEN** the car crosses from one terrain facet to an adjacent one with a different slope
- **THEN** its orientation eases toward the new angle over a short time rather than snapping instantly

### Requirement: Airborne angular momentum and self-righting
While airborne, the vehicle SHALL retain some of the angular momentum it carried at takeoff, continuing to rotate in the air rather than snapping instantly to level. It SHALL also right itself like a cat, so that by the time it contacts the terrain its orientation has returned to wheels-down regardless of its takeoff angle or how it tumbled in the air.

#### Scenario: Carries rotation into the air
- **WHEN** the car launches off a crest while pitched or rolled
- **THEN** it continues to rotate in the air for a time, carrying its takeoff angular momentum, rather than snapping immediately to level

#### Scenario: Always lands on its wheels
- **WHEN** the airborne car descends and contacts the terrain
- **THEN** its orientation has righted to wheels-down (approximately level with the surface) so it lands on its wheels, regardless of its orientation at takeoff
