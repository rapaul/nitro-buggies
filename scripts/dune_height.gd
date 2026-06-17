class_name DuneHeight
extends RefCounted
## Deterministic dune surface height — the single source of truth shared by the
## terrain mesh, its collision heightmap, and the test harness.
##
## "Egg-carton" dunes from a product of sines: off-axis crests and troughs, but
## the x=0 and z=0 axes are held perfectly flat (height 0). The car spawns at the
## origin and the planar handling tests drive along those axes, so they run on
## level ground while the dunes rise everywhere else.

const AMPLITUDE := 4.0    ## peak dune height above the zero plane (m)
const WAVELENGTH := 40.0  ## distance between successive crests along an axis (m)


static func height(x: float, z: float) -> float:
	var k := TAU / WAVELENGTH
	return AMPLITUDE * sin(x * k) * sin(z * k)
