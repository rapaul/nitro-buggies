## Context

The project boots directly into `res://scenes/Main.tscn` (a `Node3D` race scene) via `project.godot` `run/main_scene`. There is no UI layer, no scene-switching, and no menu/title infrastructure yet. Input is routed through Godot's `InputMap`; Godot's built-in `ui_accept` action already includes ENTER by default, so no new input mapping is strictly required.

This change inserts a 2D UI screen in front of gameplay. It is a small, self-contained addition — one `Control`-based scene plus a short controller script — but it touches the project entry point and introduces the project's first font asset, so a few choices are worth pinning down before coding.

## Goals / Non-Goals

**Goals:**
- Show a branded "Nitro Buggies" title screen on launch with the 80s block look the user described (sandy-yellow face, sandy-orange lower-right block shadow, very dark grey background, top-third placement with margins).
- Start the existing race on ENTER with a clean scene swap.
- Deliver three title style variants for the user to compare, then keep the one chosen.

**Non-Goals:**
- No options/settings menu, car select, audio, or animated transitions.
- No change to gameplay, camera, or driving input behavior.

## Decisions

### Scene structure: Control-based landing scene as the new main scene
A new `res://scenes/LandingScreen.tscn` rooted at a full-rect `Control` (or `ColorRect` for the background) with the title built from `Label` nodes. `project.godot` `run/main_scene` points at it. On ENTER the controller calls `get_tree().change_scene_to_file("res://scenes/Main.tscn")`.

- *Why:* Minimal, idiomatic Godot. `Main.tscn` stays untouched and still runs standalone for testing.
- *Alternative considered:* Keep `Main.tscn` as root and overlay a `CanvasLayer` title that hides on start. Rejected — couples the menu into the gameplay scene and complicates the existing `main.gd` (pause handling, camera wiring) for no benefit.

### Title + block shadow: two stacked Labels
Render the title as two overlapping `Label`s sharing the same font/size: a back label filled sandy-orange, offset down-right by a fixed pixel amount, and a front label filled sandy-yellow at the base position. Both sit inside a top-anchored container with top/left/right margins.

- *Why:* A real, controllable block shadow (solid offset duplicate) rather than a soft `FontOutline`/`shadow` — matches the chunky 80s look and keeps the offset directly tunable per variant. Simple, no shaders.
- *Alternative considered:* `Label` built-in `shadow_color`/`shadow_offset` theme properties. Viable and even simpler, but gives less control over a hard chunky block and is harder to make read as a distinct sandy-orange slab; kept as a fallback if the duplicate-label approach looks off.
- *Colors (starting point, tunable):* sandy yellow ≈ `#E8C76A`, sandy orange ≈ `#C8761E`, background very dark grey ≈ `#1A1A1A`.

### ENTER handling: built-in `ui_accept`
The controller's `_unhandled_input` checks `event.is_action_pressed("ui_accept")` (ENTER is bound by default) to trigger the scene change.

- *Why:* No `InputMap` edit needed; ENTER works out of the box and KP-Enter/Space come along for free.
- *Alternative considered:* A dedicated `start` action or raw `KEY_ENTER` check. Rejected as unnecessary; can be added later if we want ENTER-only with no Space.

### Resolution independence: project stretch mode
The title is built with a fixed font size and pixel offsets, so on its own it would stay the same physical size while the window grows — looking tiny when maximized. Rather than recomputing font size/offset on every `size_changed`, set the project's 2D stretch in `project.godot` `[display]`: base viewport `1152x648`, `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"`. Godot then scales the whole UI canvas to the window, so the title, block shadow, and margins keep their proportions at any resolution.

- *Why:* One settings change, no per-frame code; scales every current and future UI element uniformly. `expand` avoids letterboxing — a wider window reveals more space (extra side margin for the centered title) instead of distorting glyphs.
- *Scope note:* Stretch is a **global** setting, so it also governs the 3D race scene. With `expand`, a wider window shows slightly more of the track horizontally rather than zooming — the standard choice for an arcade racer; gameplay handling/camera are unaffected (verified). Switch the aspect to `keep` if 3D letterboxing is ever preferred.
- *Alternative considered:* Scale `font_size` and `SHADOW_OFFSET` in code on the `size_changed` signal. Rejected — more code, only fixes this one screen, and re-implements what stretch mode does for free.

### Three variants: how they differ and how they're reviewed
The three variants vary the title treatment so the user can pick a feel. Proposed axes:
- **Variant A — Outrun chrome:** heavy geometric block font, large lower-right shadow offset (chunky slab), tight letter spacing, centered in the top third.
- **Variant B — Arcade marquee:** condensed/tall block font, medium offset, left-aligned against the left margin, slightly smaller shadow.
- **Variant C — Neon stack:** rounded block font, small crisp offset, wide letter spacing, centered.

Each variant is a distinct configuration (font resource + offset + alignment + spacing). They are selected for review via a **command-line flag**, not any in-game UI. The controller reads the flag at `_ready` and applies the matching variant's font/offset/alignment/spacing. After the user picks one, the chosen variant becomes the unconditional default in `LandingScreen.tscn`, and the flag handling, the other two variants, and their unused fonts are removed.

- *Flag mechanism:* Read a custom arg via `OS.get_cmdline_user_args()` so it is passed after `--`, e.g. `godot -- --variant=b` (a/b/c, default `a`). At `_ready` the controller parses it and configures the title; nothing variant-related is wired in the `.tscn`, per the node-export gotcha.
- *Why a launch flag over an in-game switch:* The user wants to compare builds, not expose a selector to players. A flag keeps the variants entirely out of the shipped game's UI and makes per-variant screenshots scriptable via `tools/`.
- *Alternative considered:* Exported `variant` enum set in the editor / three visibility-toggled nodes. Rejected — the user explicitly asked for a launch flag so variants can be chosen at launch and then deleted.

### Fonts
80s block display fonts are not bundled with Godot. Source up to three open-licensed display fonts (e.g. SIL OFL / CC0 from a reputable source), import as `.ttf`/`FontFile`, and record attribution alongside the existing `assets/ATTRIBUTION.md`. Only the chosen variant's font is kept.

- *Fallback:* If sourcing fonts stalls, ship with Godot's default font bold-and-large for layout, and treat the actual font swap as the variant differentiator — the block-shadow/color/layout still reads as the intended look.

## Risks / Trade-offs

- **Font licensing/availability** → Use OFL/CC0 fonts only and attribute them; if none fit in time, fall back to the default font so the screen still ships and the layout is correct.
- **Headless screenshot of a 2D Control may differ from interactive run** → Verify the chosen variant once in an interactive run before considering it done; the `tools/` scripts (per `[[godot-headless-validation]]`) are for quick iteration, not final sign-off.
- **Node-export wiring from hand-authored `.tscn` is unreliable in this project** (`[[godot-tscn-node-export-gotcha]]`) → Wire any node references (e.g. title labels for variant switching) in code within `_ready`, not via `.tscn` NodePath exports.
- **Entry-point change** → If the landing screen breaks, gameplay is unreachable from launch. Mitigation: `Main.tscn` is unchanged and can still be set as `main_scene` to roll back instantly.

## Open Questions

- Final pick among the three variants (and thus which font ships) — to be resolved by user review during apply.
- Exact sandy-yellow / sandy-orange / dark-grey hex values — starting values above; confirm against the chosen font visually.
- Should ENTER be the only start key, or is Space (via `ui_accept`) acceptable too? Defaulting to "Space is fine" unless the user wants ENTER-only.
