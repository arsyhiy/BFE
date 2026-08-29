#extends CharacterBody3D
#
#@export var target: Node3D
#@export var speed := 3.0
#
#@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
#
#
#func _physics_process(_delta):
	#if target == null:
		#return
#
	#navigation_agent.target_position = target.global_position
#
	#if navigation_agent.is_navigation_finished():
		#velocity = Vector3.ZERO
		#move_and_slide()
		#return
#
	#var next_position := navigation_agent.get_next_path_position()
	#var direction := global_position.direction_to(next_position)
#
	#print(
		#"enemy=", global_position,
		#" next=", next_position,
		#" direction=", direction
	#)
#
	#velocity = Vector3(
		#direction.x * speed,
		#0.0,
		#direction.z * speed
	#)
#
	#move_and_slide()


extends CharacterBody3D

@export var target: Node3D
@export var speed := 3.0
@export var max_hp := 100

var hp: int

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	hp = max_hp
	add_to_group("Enemies")


func _physics_process(_delta):
	if target == null:
		return

	navigation_agent.target_position = target.global_position

	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)

	velocity = Vector3(
		direction.x * speed,
		0.0,
		direction.z * speed
	)

	move_and_slide()


func hitscan_hit(damage: int, hit_direction: Vector3, hit_position: Vector3) -> void:
	hp -= damage

	print("Enemy получил ", damage, " урона. HP: ", hp)

	if hp <= 0:
		die()


func die() -> void:
	queue_free()
