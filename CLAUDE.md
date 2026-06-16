# CLAUDE.md

Project-specific guidance for nitro-buggies (Godot 4.6, GDScript). Godot 4.6 stable is installed at `~/.local/bin/godot` (downloaded from the GitHub release; not on PATH in non-login shells — use the full path).

## Verifying changes

Validate the project headlessly, without the editor:

- `godot --headless --import` — import assets; must finish with no error/warning.
- `godot --headless -s tools/drive_test.gd` — behavioral test harness: loads `Main.tscn`, drives via `Input.action_press`, asserts accel/reverse/steer/drift/frame-rate-independence/camera-follow/pause. Prints PASS/FAIL, exits 1 on failure.
- `godot --headless -s tools/inspect_car.gd` — prints the car mesh AABB (scale/orientation).
- `godot --headless -s tools/landing_test.gd` — landing-screen smoke + ENTER→scene-change.

Headless input still propagates — `Input.parse_input_event(InputEventAction…)` reaches `_unhandled_input`, so behavior like ENTER → scene-change is testable headless even though pixels aren't.

What still needs a human with hardware: literal gamepad analog input and controller hotplug. Everything else is machine-verifiable.

### Screenshotting UI (visual verification)

`--headless` has no rendering and cannot screenshot. To visually verify 2D/UI scenes (Control screens), render actual pixels: this machine has a real display (`DISPLAY=:0`, Wayland) and a GPU (`/dev/dri/renderD128`), so run windowed with the GL driver.

Pattern: a `SceneTree` tool script that instantiates the scene, `await process_frame` a few times, then `get_root().get_texture().get_image().save_png(path)` and `quit()`. See `tools/landing_shot.gd`, which takes `--shot=<path>` after `--`.

```
godot --rendering-driver opengl3 -s tools/landing_shot.gd -- --shot=/tmp/x.png
```

Then read the PNG to view it. Default window is 1152x648.
