## 1. Scaffold the landing scene

- [x] 1.1 Create `res://scenes/LandingScreen.tscn` rooted at a full-rect `Control`, with a `ColorRect` background filling the viewport in very dark grey (≈ `#1A1A1A`)
- [x] 1.2 Add a top-anchored container in the top third of the screen with top/left/right margins for the title
- [x] 1.3 Build the title as two stacked `Label`s ("Nitro Buggies"): a back label (sandy orange ≈ `#C8761E`) offset down-right, and a front label (sandy yellow ≈ `#E8C76A`) at the base position
- [x] 1.4 Create `res://scripts/landing_screen.gd` and attach it to the root; wire any node references in code in `_ready` (not via .tscn NodePath exports)

## 2. Title style variants

- [x] 2.1 Source up to three open-licensed (OFL/CC0) 80s block display fonts, import them, and add attribution to `assets/ATTRIBUTION.md` (fall back to the default font if none are available in time)
- [x] 2.2 Implement Variant A (Outrun chrome): heavy block font, large lower-right shadow offset, tight spacing, centered
- [x] 2.3 Implement Variant B (Arcade marquee): condensed/tall font, medium offset, left-aligned to the left margin
- [x] 2.4 Implement Variant C (Neon stack): rounded block font, small crisp offset, wide letter spacing, centered
- [x] 2.5 In `landing_screen.gd`, read a `--variant=a|b|c` launch flag via `OS.get_cmdline_user_args()` at `_ready` (default `a`) and apply the matching variant's font/offset/alignment/spacing — no in-game selector

## 3. Start-the-game gate

- [x] 3.1 In `landing_screen.gd`, handle `ui_accept` (ENTER) in `_unhandled_input` and call `get_tree().change_scene_to_file("res://scenes/Main.tscn")`
- [x] 3.2 Verify the main game does not start until ENTER is pressed

## 4. Wire entry point

- [x] 4.1 Change `project.godot` `run/main_scene` from `res://scenes/Main.tscn` to `res://scenes/LandingScreen.tscn`
- [x] 4.2 Confirm `Main.tscn` still runs standalone (rollback path unchanged)
- [x] 4.3 Add a `[display]` section to `project.godot` (base `1152x648`, `stretch/mode="canvas_items"`, `stretch/aspect="expand"`) so the title keeps its proportion at any window size; verify at 1080p and ultrawide

## 5. Review, choose, and finalize

- [x] 5.1 Launch each variant via its flag (`godot -- --variant=a|b|c`, screenshot via `tools/` or interactive run) and have the user pick one
- [x] 5.2 Make the chosen variant the unconditional default in `LandingScreen.tscn`; remove the `--variant` flag handling, the other two variants, and any unused fonts/attribution
- [x] 5.3 Verify the final screen interactively: title in top third with margins, sandy-yellow face over sandy-orange lower-right block shadow on a very dark grey background, and ENTER starts the race
