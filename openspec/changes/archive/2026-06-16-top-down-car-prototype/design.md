## Context

Greenfield repo with only a PRD. This change delivers Milestone 1 (Prototype): one Kenney car driving top-down under gamepad/keyboard control with a following camera, on a flat ground plane. There is no track, lap timing, or menu yet. The PRD leaves the physics approach open (`VehicleBody3D` vs. custom `RigidBody3D` arcade handling) and flags it for prototyping — that is the central decision here, since car *feel* is the thing this milestone exists to validate.

Constraints: Godot 4.6.x, GDScript, free/non-commercial tooling, Kenney glTF assets, 60 fps target, fixed physics tick.

## Goals / Non-Goals

**Goals:**
- Get a Kenney car moving with handling that feels good enough to judge.
- Prove out the device-agnostic input path (analog gamepad + keyboard fallback + hotplug).
- Establish a project structure that later milestones (track, lap timing, menus) can build on without rework.
- Frame-rate-independent handling via the physics tick.

**Non-Goals:**
- Track geometry, collision walls, lap detection, menus, export pipeline (later milestones).
- Final tuning of handling values — prototype-quality tuning is enough.
- macOS support and split-screen data structures (deferred / open in PRD).

## Decisions

### Physics: custom arcade handling on `CharacterBody3D` over `VehicleBody3D`
`VehicleBody3D` simulates a real suspension/wheel raycast model. It is realistic but fiddly to tune and fights against a tight arcade "top-down" feel; it also couples handling to suspension behavior that does not matter from a top-down camera. For an arcade top-down racer, a custom kinematic model gives direct, predictable control over acceleration curves, grip, and drift.

**Decision:** Implement the car as a `CharacterBody3D` (or `RigidBody3D` if collision response later demands it) with a hand-written arcade model: forward speed from throttle, decay/brake/reverse, speed-dependent steering, and a lateral-velocity grip term whose strength drops when the handbrake is held (producing drift). All integration runs in `_physics_process`.

**Alternatives considered:** `VehicleBody3D` (rejected for v1 prototype — over-realistic, harder to tune, suspension irrelevant top-down). Pure `RigidBody3D` with forces (rejected for now — less direct control of feel; revisit if/when we need rich collision response against track walls in Milestone 2).

> Note: this contradicts the PRD's leaning toward `VehicleBody3D`; the prototype is exactly where to settle it. If custom handling feels worse, swapping to `VehicleBody3D` is contained to the car scene/script.

### Input: `InputMap` actions read via `Input.get_axis` / `get_vector`
Define actions (`accelerate`, `brake`, `steer_left`, `steer_right`, `handbrake`, `pause`) in `project.godot`, mapped to both gamepad and keyboard per the PRD table. The controller reads composite analog values (`Input.get_axis("brake","accelerate")`, `Input.get_axis("steer_left","steer_right")`), which gives keyboard keys full-magnitude values and gamepad axes proportional values for free. Godot emits hotplug signals (`Input.joy_connection_changed`) which we connect for connect/disconnect handling.

**Alternatives considered:** polling raw `Input.get_joy_axis` (rejected — bypasses `InputMap`, loses keyboard fallback and remap-ability).

### Camera: `Camera3D` follow rig with smoothed position
A `Camera3D` placed at a fixed high pitch/height offset above the car. Each frame in `_physics_process`/`_process`, lerp the camera toward the car's position (keeping the fixed offset) for smooth follow. Use a perspective camera at a steep angle for the top-down look (orthographic is an easy later toggle if a flatter look is wanted).

**Alternatives considered:** rigid parenting the camera to the car (rejected — snaps/jitters, no smoothing, rotates with the car). Orthographic projection (deferred — perspective at high angle reads fine and keeps depth cues).

### Scene structure
- `Car.tscn` — root car body node + Kenney mesh child + collision shape + `car.gd` controller.
- `CameraRig.tscn` (or a camera node in the main scene) — `Camera3D` + `camera.gd` follow script with an exported target.
- `Main.tscn` — flat ground plane (`StaticBody3D` + mesh), directional light, instances the car and camera, wires the camera target to the car.

This keeps the car and camera reusable when a real track scene replaces `Main.tscn` later.

## Risks / Trade-offs

- **Custom handling may feel worse than `VehicleBody3D`** → Mitigation: scope is isolated to `car.gd` + `Car.tscn`; tunable exported parameters; swap path documented above.
- **Trigger axis ranges differ across controllers/platforms** → Mitigation: rely on Godot's SDL mappings and `InputMap`; test with at least one real gamepad; deadzone the axes.
- **`CharacterBody3D` arcade model may not give the collision response Milestone 2 needs against walls** → Mitigation: keep the model's integration separable so a move to `RigidBody3D` is feasible; revisit at track milestone.
- **Frame-rate-independence bugs** → Mitigation: all handling in `_physics_process` with `delta`; verify by running at capped vs. uncapped FPS (spec scenario).

## Open Questions

- Perspective vs. orthographic for the final top-down look — defaulting to perspective; revisit after seeing it move.
- Exact handling tuning values (accel, max speed, grip, drift falloff) — to be dialed in during the prototype, not pre-decided here.
- Carried over from PRD: macOS target, split-screen data structures — out of scope for this change.
