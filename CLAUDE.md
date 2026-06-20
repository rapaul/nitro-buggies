# CLAUDE.md

Project-specific guidance for nitro-buggies (Godot 4.6, GDScript). Godot 4.6 stable is installed at `~/.local/bin/godot` (downloaded from the GitHub release; not on PATH in non-login shells — use the full path).

## Git workflow

Always push directly to `main` — no PRs. Feature branches may be used for in-progress work, but land them by fast-forwarding `main` and pushing to origin.

## Verifying changes

Validate the project headlessly, without the editor:

- `godot --headless --import` — import assets; must finish with no error/warning.
- `godot --headless -s tools/drive_test.gd` — behavioral test harness: loads `Main.tscn`, drives via `Input.action_press`, asserts accel/reverse/steer/drift/frame-rate-independence/camera-follow/pause. Prints PASS/FAIL, exits 1 on failure.
- `godot --headless -s tools/inspect_car.gd` — prints the car mesh AABB (scale/orientation).
- `godot --headless -s tools/ground_test.gd` — asserts the visual car mesh rests on the `DuneHeight` surface (no float/sink) on flat/sloped/valley ground, and isn't pinned down while airborne. Prints PASS/FAIL, exits 1 on failure.
- `godot --headless -s tools/landing_test.gd` — landing-screen smoke for the staged flow: boots into the 1P/2P mode select (asserts the title, both mode labels, font), then the first ENTER confirms the mode and advances to the picker (no scene change), and the second ENTER confirms the vehicle and switches to `Main.tscn`.
- `godot --headless -s tools/respawn_test.gd` — asserts the car respawns at the centre ~20 m up after falling off the edge for 1 s, with momentum cleared, and that a sub-1 s excursion that returns in-bounds does not respawn. Prints PASS/FAIL, exits 1 on failure.
- `godot --headless -s tools/two_player_test.gd` — sets `Selection.player_count = 2`, loads `Main.tscn`, and asserts two cars exist, the split rendering is wired (two `SubViewport`s, each a chase camera on its own car), and the keyboard split routes correctly (P1 actions drive only car 1, P2 actions only car 2). Prints PASS/FAIL, exits 1 on failure.
- `godot --headless -s tools/ai_test.gd` — single-player AI opponent: sets `Selection.player_count = 1` and `Selection.ai_opponent = true`, loads `Main.tscn`, and asserts a second AI-controlled car plus an `AIDriver` are spawned (the AI car has no HUD — its health is not shown in 1P), an empty AI closes distance on the nearest available pickup (steering sign correct), a hunting AI weaves so its steering reverses at least every ~0.5 s (never straight longer), and the fireball aim is on-target for a forced "hit" (removing a player bar) and offset ~12 m wide for a "miss". Prints PASS/FAIL, exits 1 on failure.
- `godot --headless -s tools/pickup_test.gd` — pickup/combat loop: asserts drive-over collection sets the held item and a second pickup does not replace it, nitro doubles the effective top speed for ~5 s then reverts, a fired fireball spawns into the world and rides the `DuneHeight` surface and despawns ~10 m past the edge, a fireball removes one enemy health bar, and losing all bars emits `eliminated` (clamped at zero). Prints PASS/FAIL, exits 1 on failure. (The tool resolves the `Car`/`Fireball` scripts and the item enum at runtime, not via top-level `preload`/`Car.*`: a `-s` tool compiles before the `Selection` autoload exists, so statically pulling in `car.gd` — which references `Selection` — would fail to compile it.)

Headless input still propagates — `Input.parse_input_event(InputEventAction…)` reaches `_unhandled_input`, so behavior like ENTER → scene-change is testable headless even though pixels aren't.

Player input: the landing screen offers a 1P/2P choice. In 2P, Player 1 drives with WASD (Space handbrake, **F** to use a pickup) and Player 2 with the arrow keys (Right Shift handbrake, **Right Ctrl** to use a pickup), each on its own car; the race renders a horizontal split (P1 top, P2 bottom). Per-car action sets come from `car.gd`'s `input_prefix` ("" for P1, "p2_" for P2); the `p2_*`, per-player `p1_accept`/`p2_accept`, and `use_item`/`p2_use_item` actions live in `project.godot`.

Single-player AI opponent: in 1P the landing screen sets `Selection.ai_opponent = true`, and `main.gd` spawns one computer-driven opponent `Car` (`ai_controlled = true`, driven by `scripts/ai_driver.gd`) sharing the world. The AI seeks the nearest pickup when empty, otherwise hunts the player while weaving (never straight > ~0.5 s), uses a held nitro at once, and fires a fireball with a 50% chance of being deliberately aimed wide. The opponent has no HUD (its health is intentionally not shown in 1P) but is fully damageable/eliminable and recovered by the off-edge respawn. `ai_opponent` defaults to **false** so launching `Main.tscn` directly (the other 1P headless tests) keeps a single-car, deterministic scene; `ai_test.gd` sets it true.

What still needs a human with hardware: literal gamepad analog input and controller hotplug. Everything else is machine-verifiable.

### Screenshotting UI (visual verification)

`--headless` has no rendering and cannot screenshot. To visually verify 2D/UI scenes (Control screens), render actual pixels: this machine has a real display (`DISPLAY=:0`, Wayland) and a GPU (`/dev/dri/renderD128`), so run windowed with the GL driver.

Pattern: a `SceneTree` tool script that instantiates the scene, `await process_frame` a few times, then `get_root().get_texture().get_image().save_png(path)` and `quit()`. See `tools/landing_shot.gd`, which takes `--shot=<path>` after `--`. `tools/two_player_picker_shot.gd` (drives mode select into the 2P split picker) and `tools/two_player_race_shot.gd` (the 2P split race) follow the same pattern for the two-player views. `tools/pickup_shot.gd` renders the per-player HUD (health bar + held-pickup box) and the WASTED/WINNER overlay; it takes `--hud=<path> --wasted=<path>`.

```
godot --rendering-driver opengl3 -s tools/landing_shot.gd -- --shot=/tmp/x.png
```

Then read the PNG to view it. Default window is 1152x648.

## Web export

A `Web` export preset (`export_presets.cfg`) targets `build/web/` (gitignored). It's single-threaded — the project uses `gl_compatibility` (→ WebGL2), so no COOP/COEP cross-origin-isolation headers are needed to serve it.

Web export templates must be installed at `~/.local/share/godot/export_templates/4.6.stable/` (download `Godot_v4.6-stable_export_templates.tpz` from the GitHub release and unzip its `templates/` contents there). Then:

```
godot --headless --export-release "Web" build/web/index.html
```

To test the build, serve it over HTTP and load it in a browser (it boots from `index.html`, ~37 MB wasm):

```
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Headless Chromium (Playwright, WebGL2 via `--use-gl=angle --use-angle=swiftshader`) can drive it for an automated boot test: wait for the `<canvas>` to size and the `#status` overlay to hide, capture `page.on('console')`, then screenshot. Keyboard input reaches the engine after clicking the canvas (e.g. ENTER advances the landing screen into the driving scene). Gamepad analog input still needs a human.
