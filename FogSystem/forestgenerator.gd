extends Node3D

@export var tree_scene: PackedScene
@export var tree_count: int = 200
@export var forest_size: float = 100.0
@export var min_scale: float = 0.8
@export var max_scale: float = 1.2

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	generate_forest()


func generate_forest() -> void:
	for i in tree_count:
		var tree := tree_scene.instantiate()

		var x := rng.randf_range(-forest_size / 2.0, forest_size / 2.0)
		var z := rng.randf_range(-forest_size / 2.0, forest_size / 2.0)

		tree.position = Vector3(x, 0.0, z)

		tree.rotation.y = rng.randf_range(0.0, TAU)

		var scale := rng.randf_range(min_scale, max_scale)
		tree.scale = Vector3.ONE * scale

		add_child(tree)
