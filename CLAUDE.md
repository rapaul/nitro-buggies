# CLAUDE.md

Project-specific guidance for nitro-buggies (Godot 4.6, GDScript). Godot binary is at `~/.local/bin/godot`.

## Verifying changes

Headless validation tools live in `tools/` (e.g. `drive_test.gd`, `landing_test.gd`). Run them with `godot --headless -s tools/<name>.gd`. Headless input still propagates — `Input.parse_input_event(InputEventAction…)` reaches `_unhandled_input`, so behavior like ENTER → scene-change is testable headless even though pixels aren't.

### Screenshotting UI (visual verification)

`--headless` has no rendering and cannot screenshot. To visually verify 2D/UI scenes (Control screens), render actual pixels: this machine has a real display (`DISPLAY=:0`, Wayland) and a GPU (`/dev/dri/renderD128`), so run windowed with the GL driver.

Pattern: a `SceneTree` tool script that instantiates the scene, `await process_frame` a few times, then `get_root().get_texture().get_image().save_png(path)` and `quit()`. See `tools/landing_shot.gd`, which takes `--shot=<path>` after `--`.

```
godot --rendering-driver opengl3 -s tools/landing_shot.gd -- --shot=/tmp/x.png
```

Then read the PNG to view it. Default window is 1152x648.
