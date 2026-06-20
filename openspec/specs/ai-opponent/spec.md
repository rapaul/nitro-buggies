# ai-opponent

## Purpose

A computer-driven opponent car in single-player — its presence in the world, and the seek-pickup / hunt-and-weave / fireball-with-50%-miss behaviour that drives it — so the pickup and combat systems make the solo race a contest.

## Requirements

### Requirement: An AI opponent races in single-player
A single-player race SHALL contain exactly one computer-driven opponent car in addition to the player's car, both sharing the same world. The opponent SHALL be a full vehicle: it SHALL collect and use pickups, take fireball damage, lose health, be eliminable, and respawn after falling off the edge, using the same vehicle systems as the player car. Its control inputs (throttle, steering, handbrake, use-item) SHALL be produced by the AI rather than read from the keyboard or gamepad, and the player's inputs SHALL NOT drive the opponent.

The AI opponent SHALL be active for the real single-player launch flow (enabled when "1P" is confirmed on the landing screen) and SHALL default to off when the main game scene is launched directly without going through the landing screen.

#### Scenario: Opponent present in single-player
- **WHEN** a single-player race starts via the landing screen's 1P flow
- **THEN** the world contains the player's car and one AI-controlled opponent car

#### Scenario: Player input does not drive the opponent
- **WHEN** the player applies throttle and steering
- **THEN** only the player's car responds and the AI opponent is unaffected by those inputs

#### Scenario: Opponent participates in combat and outcome
- **WHEN** the AI opponent loses its last health bar
- **THEN** the match ends with the player shown as the winner; and **WHEN** the player loses its last health bar instead, the player is shown as eliminated

#### Scenario: Off by default when launched directly
- **WHEN** the main game scene is loaded directly without the landing-screen 1P flow enabling the opponent
- **THEN** the single-player race contains only the player's car and no AI opponent

### Requirement: AI seeks a pickup when it holds none
While the AI opponent holds no item, it SHALL drive toward the nearest currently-available pickup in order to collect one.

#### Scenario: Empty AI drives to the nearest pickup
- **WHEN** the AI opponent holds no item
- **THEN** it steers toward and closes distance on the nearest available pickup

### Requirement: AI hunts the player when it holds an item
While the AI opponent holds an item, it SHALL drive toward the player's car rather than toward pickups.

#### Scenario: Armed AI chases the player
- **WHEN** the AI opponent is holding an item
- **THEN** it drives toward the player's car

### Requirement: AI weaves and never drives straight for long
While hunting the player, the AI opponent SHALL continually alternate its steering left and right so that it never holds a straight (un-steered) heading for more than about 0.5 seconds.

#### Scenario: Steering alternates at least twice per second
- **WHEN** the AI opponent is hunting the player over a sustained period
- **THEN** its applied steering direction reverses at intervals no longer than about 0.5 seconds, so it is never driving straight for longer than that

### Requirement: AI uses a held nitro to chase
When the AI opponent is holding a nitro while hunting the player, it SHALL use the nitro (applying the speed boost) so that it is freed to seek the next pickup.

#### Scenario: AI consumes nitro
- **WHEN** the AI opponent is hunting the player while holding a nitro
- **THEN** it uses the nitro, its held item is cleared, and the boost is applied

### Requirement: AI fires a fireball at the player with a 50% miss chance
When the AI opponent holds a fireball and is roughly facing the player, it SHALL fire it. Each fireball the AI uses SHALL have a 50% probability of being deliberately aimed to miss (fired wide of the player) and otherwise aimed at the player.

#### Scenario: AI fires when facing the player
- **WHEN** the AI opponent holds a fireball and its heading is roughly aligned with the player
- **THEN** it uses the fireball, launching a projectile

#### Scenario: Half of fired fireballs are aimed to miss
- **WHEN** the AI opponent uses many fireballs over the course of play
- **THEN** about half are aimed directly at the player and about half are deliberately aimed wide so they miss
