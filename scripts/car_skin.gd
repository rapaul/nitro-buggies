extends RefCounted
class_name CarSkin
## Applies the Kenney car-kit shared palette atlas to instantiated car models.
##
## The kit GLBs reference colormap.png as an external image, which Godot's .glb
## importer does not bind — so every part imports with a null albedo texture and
## renders lit-but-white. Every part shares one atlas and UV layout, so a single
## material applied as material_override colors the whole car correctly.

const COLORMAP := "res://assets/cars/Textures/colormap.png"

static var _material: StandardMaterial3D


static func _shared_material() -> StandardMaterial3D:
	# Built once and reused across every mesh and preview (read-only).
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_texture = load(COLORMAP)
		_material.metallic = 0.0
	return _material


## Override the (textureless) material on every MeshInstance3D under `model`.
static func apply(model: Node) -> void:
	var mat := _shared_material()
	for mi in _meshes(model, []):
		(mi as MeshInstance3D).material_override = mat


static func _meshes(n: Node, acc: Array) -> Array:
	if n is MeshInstance3D:
		acc.append(n)
	for c in n.get_children():
		_meshes(c, acc)
	return acc
