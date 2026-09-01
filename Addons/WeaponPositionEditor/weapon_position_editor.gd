@tool
extends Node3D

@export_category("Weapon Editor")

@export var weapon_container: Node3D

@export_category("Actions")

@export_tool_button("Save To Resource", "Callable")
var save_action = save_transform


func get_weapon() -> WeaponSlot:
	if weapon_container == null:
		return null

	for child in weapon_container.get_children():
		if child is WeaponSlot:
			return child

	return null


func save_transform() -> void:
	var weapon := get_weapon()

	if weapon == null:
		push_error("WeaponSlot not found")
		return

	if weapon.model == null:
		push_error("Weapon model not assigned")
		return

	if weapon.resources == null:
		push_error("WeaponResource not assigned")
		return

	if weapon.resources.pos_val.size() < 2:
		weapon.resources.pos_val.resize(2)

	# Берём transform непосредственно из модели
	var position := weapon.model.position
	var rotation := weapon.model.rotation

	# Записываем в Resource
	weapon.resources.pos_val[0] = position
	weapon.resources.pos_val[1] = rotation

	# Помечаем Resource изменённым
	weapon.resources.emit_changed()

	# Сохраняем Resource на диск
	var resource_path := weapon.resources.resource_path

	if resource_path.is_empty():
		push_error("WeaponResource has no resource_path")
		return

	var error := ResourceSaver.save(weapon.resources, resource_path)

	if error != OK:
		push_error("Failed to save WeaponResource: %s" % error)
		return

	print("=== SAVED ===")
	print("Resource: ", resource_path)
	print("Position: ", position)
	print("Rotation: ", rotation)
