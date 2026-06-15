## 1. Project scaffold

- [ ] 1.1 Create a Godot 4.6.x project (`project.godot`) configured for GDScript and a Forward+ / mobile-appropriate renderer
- [ ] 1.2 Add a Godot `.gitignore` (ignore `.godot/`, exports) and initialize the repo layout (`scenes/`, `scripts/`, `assets/`)
- [ ] 1.3 Set the physics tick rate explicitly (e.g. 60 Hz) in project settings for deterministic handling

## 2. Assets

- [ ] 2.1 Extract a car model from the local `kenney_car-kit.zip` (Kenney Car Kit, https://kenney.nl/assets/car-kit) — use the GLB format folder — and import the `.glb` into `assets/`
- [ ] 2.2 Add Kenney license/attribution file alongside the assets
- [ ] 2.3 Verify the car mesh imports with correct scale and orientation in a test scene

## 3. Input map

- [ ] 3.1 Define `InputMap` actions in project settings: `accelerate`, `brake`, `steer_left`, `steer_right`, `handbrake`, `pause`
- [ ] 3.2 Bind each action to gamepad (R2/L2 triggers, left stick X, A/Cross, Start) per the PRD table
- [ ] 3.3 Always bind WASD as primary keyboard controls (W accelerate, S brake/reverse, A steer left, D steer right); add arrow keys as aliases, plus Space (handbrake) and Esc (pause)
- [ ] 3.4 Verify WASD drives the car whether or not a gamepad is connected (no mode switch)
- [ ] 3.5 Connect `Input.joy_connection_changed` to handle controller connect/disconnect at runtime

## 4. Vehicle control

- [ ] 4.1 Create `Car.tscn`: car body node, Kenney mesh child, collision shape
- [ ] 4.2 Create `car.gd` reading input via `Input.get_axis` for throttle and steering (no raw device codes)
- [ ] 4.3 Implement forward acceleration with proportional analog throttle and a max forward speed cap
- [ ] 4.4 Implement braking, then reverse (capped below max forward speed) when held at standstill
- [ ] 4.5 Implement speed-dependent steering (no pivot at zero speed)
- [ ] 4.6 Implement lateral grip; reduce grip on handbrake to produce drift
- [ ] 4.7 Run all integration in `_physics_process(delta)` for frame-rate independence

## 5. Camera

- [ ] 5.1 Create the top-down camera (`Camera3D`) at a high-angle height/pitch offset
- [ ] 5.2 Create `camera.gd` that smoothly lerps toward the target car position keeping the fixed offset
- [ ] 5.3 Expose the follow target and smoothing factor as exported parameters

## 6. Integration scene

- [ ] 6.1 Create `Main.tscn` with a flat ground plane (`StaticBody3D` + mesh) and a directional light
- [ ] 6.2 Instance the car and camera, wire the camera target to the car, set `Main.tscn` as the run scene

## 7. Verification

- [ ] 7.1 Drive the car with a gamepad: confirm analog throttle/brake/steer, reverse, and handbrake drift
- [ ] 7.2 Drive the car with WASD only (no gamepad) and confirm accelerate/brake/reverse/steer plus handbrake and pause all work
- [ ] 7.3 Connect a gamepad after launch and confirm it takes over without restart; disconnect and confirm keyboard still drives
- [ ] 7.4 Confirm the camera follows smoothly while driving and is stable at rest
- [ ] 7.5 Run at capped vs. uncapped FPS and confirm equivalent car motion (frame-rate independence)
