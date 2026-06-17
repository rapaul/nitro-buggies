class_name DuneHeight
extends RefCounted
## Deterministic dune surface height — the single source of truth shared by the
## terrain mesh, its collision heightmap, and the test harness.
##
## Elongated dune ridges from a product of sines with anisotropic wavelengths:
## a long wavelength along X stretches each crest into a ridge line running in
## the X direction, while a wider wavelength along Z sets how far apart the
## ridges sit and how gently their faces rise. As before, the x=0 and z=0 axes
## are held perfectly flat (height 0) — each carries a sin(0)=0 factor — so the
## car spawns at the origin and the planar handling tests drive along those axes
## on level ground while the dunes rise everywhere else.

const AMPLITUDE := 5.0       ## peak dune height above the zero plane (m)
const WAVELENGTH_X := 160.0  ## ridge length along X: distance between successive crest lines (m)
const WAVELENGTH_Z := 70.0   ## ridge spacing/face length along Z, the driving direction (m)


static func height(x: float, z: float) -> float:
	var kx := TAU / WAVELENGTH_X
	var kz := TAU / WAVELENGTH_Z
	return AMPLITUDE * sin(x * kx) * sin(z * kz)
