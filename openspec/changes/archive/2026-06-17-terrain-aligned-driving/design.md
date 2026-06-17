## Context

The car is a `CharacterBody3D` (`scripts/car.gd`). It integrates motion in the horizontal plane: `forward_speed`/`lateral_speed` are projected from `-global_transform.basis.z` and `basis.x`, the body rotates with `rotate_y()` only, and floor snapping keeps it hugging the dune contour vertically. Because the body never pitches or rolls, the mesh sits level with the horizon regardless of slope. The dune shape is defined analytically by `DuneHeight.height(x, z)` and matched by the collision `HeightMapShape3D`, so `move_and_slide()` already produces an accurate `get_floor_normal()` each grounded tick.

The chase camera (`scripts/camera.gd`) places its offset using `target.rotation.y` read raw each frame and calls `look_at(target.global_position, …)` directly. Position is lerped, but the *heading* feeding the offset and the *aim point* are not damped, so sharp steering whips the camera and vertical bob over crests jerks its pitch.

This change is presentation-focused: make the car look like it sits on the slope, and make the camera trail steadily — without touching how the car drives.

## Goals / Non-Goals

**Goals:**
- The grounded car's visual orientation approximates the terrain slope (pitch + roll), eased smoothly.
- While airborne the car retains some takeoff angular momentum (keeps rotating) yet self-rights to always land wheels-down.
- The camera trails the car steadily during sharp turns and over crests.
- Existing handling and the `drive_test.gd` assertions (accel/reverse/steer/drift/frame-rate-independence/launch) remain green.

**Non-Goals:**
- Per-wheel suspension, raycast wheels, or independent wheel articulation. A single mesh tilt approximating the contact plane is enough for "wheels approximating the angle."
- Changing the collision shape or making the physics body itself pitch/roll.
- Camera collision/occlusion handling.

## Decisions

### Decision: Tilt the visual mesh, keep the physics body yaw-only
The terrain alignment is applied to the `Mesh` child node, not to the `CharacterBody3D`. The body keeps rotating on Y only.

Rationale: the entire motion model reads `basis.z`/`basis.x` as horizontal-plane vectors and the frame-rate-independence test asserts position/heading after fixed input. Pitching the body would give `basis.z` a vertical component, changing the projected forward/lateral speeds and risking handling and test regressions. Tilting only the mesh is pure presentation and provably leaves handling identical (the "Handling unchanged by tilt" scenario).

Alternative considered: rotate the body and re-derive a horizontal heading separately for movement. Rejected as more invasive for no visible benefit at this fidelity.

### Decision: Derive the surface normal from `get_floor_normal()`
While grounded, sample the contact normal Godot already computes from `move_and_slide()`. While airborne (`not is_on_floor()`), target `Vector3.UP`.

Rationale: it's free, already consistent with the collision contour, and needs no second sampling of `DuneHeight`. Facet-to-facet noise from the heightmap is absorbed by the smoothing below.

Alternative considered: analytic normal via central differences on `DuneHeight` (as the mesh builder does). Slightly smoother but duplicates sampling and ignores actual contact; keep it as a fallback only if `get_floor_normal()` proves too noisy.

### Decision: Build the target orientation from heading-projected-onto-the-slope, apply to the mesh in local space, ease with slerp
Per tick compute a target world basis whose up-axis is the surface normal and whose forward is the car's heading projected onto the plane perpendicular to that normal. Convert to the mesh's local space (the mesh is a child of the yaw-only body, so divide out the body basis) and re-apply the existing 180° yaw flip the mesh already carries (`mesh.rotate_y(PI)` in `_ready`). Ease the mesh's current basis toward the target with a quaternion `slerp` at a clamped per-tick rate (a `tilt_smoothing` export, same pattern as `grip`/camera `smoothing`).

Rationale: aligning up to the normal while preserving heading gives correct pitch and roll together. Easing in local space means the body's yaw still drives heading instantly (steering stays crisp) while only pitch/roll lag. Slerp avoids gimbal issues and snapping between facets. This grounded easing applies only while `is_on_floor()`; airborne orientation is handled separately (below).

### Decision: Airborne — integrate retained angular momentum with a righting bias that guarantees a wheels-down landing
At takeoff (the crest-launch branch / first tick off the floor) capture the mesh's current angular velocity — the rate it was tilting to follow the slope — as carried angular momentum. While airborne, advance the mesh orientation by that angular velocity instead of slerping straight to level, so the car visibly keeps rotating ("carries rotation into the air"). Layer on a righting bias toward up = `Vector3.UP` whose influence grows over the flight, plus a firm align-to-surface on the landing tick, so the mesh always converges to wheels-down before `is_on_floor()` re-triggers — the cat-righting reflex.

Rationale: pure slerp-to-level looks lifeless and ignores the request; pure retained momentum can land the car on its roof. A decaying spin plus a righting term that dominates as the flight progresses gives lively but safe motion. Expose an `air_righting` strength export to tune convergence against typical air time.

Alternative considered: instantly level the mesh in the air — rejected, looks dead and drops the angular momentum the user asked for. Full rigid-body angular dynamics on the physics body — rejected, out of scope and conflicts with the yaw-only-body decision above.

### Decision: Damp both the camera heading and the look-at point
Give the camera its own smoothed yaw that `lerp_angle`s toward `target.rotation.y`, and use that smoothed yaw to rotate the chase offset. Maintain a smoothed aim point that lerps toward `target.global_position`, and `look_at` that instead of the raw car position. Keep the existing position lerp.

Rationale: damping the heading stops the offset from swinging instantly on sharp steering; damping the aim point (especially its vertical component) stops crest bob from jerking the camera's pitch. Two small additions, no structural change. Separate smoothing constants let position, heading, and aim be tuned independently.

## Risks / Trade-offs

- **Floor normal noisy where the car straddles a valley flank** → smoothing/slerp absorbs per-tick jitter; if it still reads jumpy, switch the normal source to the analytic `DuneHeight` gradient (already proven in the mesh builder).
- **Mesh local-space math must account for the existing `rotate_y(PI)` flip** → if the flip is dropped from the per-tick basis, the car visibly faces backward; covered by re-applying the flip and by the existing "drives forward" expectation in the harness.
- **Over-damped camera lags too far behind on fast turns** → expose heading/aim smoothing constants; tune so the car stays framed (the "Following a moving car" scenario remains the guard).
- **Airborne righting too weak lands the car on its roof; too strong looks like instant leveling** → tune the `air_righting` strength and apply a firm align-to-surface on the landing tick as a hard guarantee; the "Always lands on its wheels" scenario is the guard.

## Open Questions

- None blocking. Final smoothing constants (`tilt_smoothing`, camera heading/aim smoothing) are tuning values to settle during implementation against the harness and a rendered screenshot.
