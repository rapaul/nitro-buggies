# pickups

## Purpose

Collectible pickups in the race that grant a held item — a nitro speed boost or an offensive fireball — that the player triggers, turning the race into a contest.

## Requirements

### Requirement: Pickups exist at fixed respawning spots
The race SHALL place pickups at exactly eight fixed positions on the dune surface. Each spot SHALL hold either a nitro or a fireball pickup, seated on the terrain surface (its height sampled from the same dune source the terrain uses). When a pickup is taken, its spot SHALL respawn a pickup of the same type after a short delay. Pickups SHALL be present in both single-player and two-player races.

#### Scenario: Eight pickups seated on the terrain
- **WHEN** the race starts
- **THEN** eight pickups appear at the fixed spots, each resting on the dune surface at its position

#### Scenario: A taken spot respawns
- **WHEN** a pickup is taken from its spot
- **THEN** the spot is empty for a short delay and then a pickup of the same type reappears there

#### Scenario: Pickups in both modes
- **WHEN** a race starts in either single-player or two-player mode
- **THEN** pickups are present in the world

### Requirement: Driving over a pickup grants it
A car that drives over an available pickup SHALL receive that pickup as its currently held item, and the pickup SHALL be removed from the world (entering its respawn delay).

#### Scenario: Collect on contact
- **WHEN** a car with no held item drives over an available pickup
- **THEN** the car's held item becomes that pickup's type and the pickup is removed from the world

### Requirement: A car holds at most one pickup, no replacement
A car SHALL hold at most one pickup at a time. While a car already holds a pickup, driving over another pickup SHALL have no effect — the held pickup SHALL NOT be replaced and the driven-over pickup SHALL remain available.

#### Scenario: Already holding one, no replace
- **WHEN** a car that already holds a pickup drives over another pickup
- **THEN** the car's held pickup is unchanged and the driven-over pickup is not consumed

### Requirement: Held pickup shown in a lower-right box
Each player's view SHALL display the car's currently held pickup in a box in the lower-right of that player's screen area — the full screen in single-player, that player's half in two-player. When the car holds no pickup the box SHALL show as empty.

#### Scenario: Box shows the held item
- **WHEN** a car is holding a pickup
- **THEN** that player's lower-right box shows an indicator of the held pickup's type

#### Scenario: Empty when nothing held
- **WHEN** a car holds no pickup
- **THEN** that player's lower-right box shows as empty

### Requirement: Using a pickup consumes it
Each player SHALL have a "use item" action. Triggering it while holding a pickup SHALL activate that pickup's effect and clear the held item (so the box becomes empty). Triggering it while holding nothing SHALL do nothing.

#### Scenario: Use activates and clears
- **WHEN** a player triggers the use action while holding a pickup
- **THEN** that pickup's effect activates and the player's held item is cleared

#### Scenario: Use with nothing held
- **WHEN** a player triggers the use action while holding no pickup
- **THEN** nothing happens

### Requirement: Nitro gives a timed speed boost
Using a nitro pickup SHALL apply a 2× boost to the car's top speed for 5 seconds, after which the car's top speed SHALL return to normal.

#### Scenario: Boost doubles top speed
- **WHEN** a car uses a nitro pickup
- **THEN** its top speed is doubled for 5 seconds and then returns to its normal value

### Requirement: Fireball is a terrain-following forward projectile
Using a fireball pickup SHALL launch a projectile from the front of the car travelling straight ahead along the car's heading. The projectile SHALL follow the terrain surface (its height tracking the dune surface beneath it) as it travels. The projectile SHALL continue until it has passed roughly 10 m beyond the edge of the play area, at which point it SHALL disappear.

#### Scenario: Travels straight ahead along the terrain
- **WHEN** a car uses a fireball
- **THEN** a projectile launches directly in front of the car along its heading and rides the terrain surface as it moves

#### Scenario: Disappears past the edge
- **WHEN** a fireball reaches and continues past the play-area edge
- **THEN** it disappears after travelling about 10 m beyond the edge

### Requirement: Fireball damages an enemy vehicle on hit
When a fireball strikes a vehicle other than the one that fired it, it SHALL remove one health bar from that vehicle and SHALL be consumed (disappear) at that point.

#### Scenario: Hit removes one bar
- **WHEN** a fireball strikes an enemy vehicle
- **THEN** that vehicle loses one health bar and the fireball disappears

#### Scenario: Does not hit its own car
- **WHEN** a fireball is travelling away from the car that fired it
- **THEN** it does not damage the firing car
