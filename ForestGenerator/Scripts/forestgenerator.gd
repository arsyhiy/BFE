extends Node3D

# ========== НАСТРОЙКИ В РЕДАКТОРЕ ==========
@export var tree_scene: PackedScene
@export var tree_count: int = 300
@export var forest_size: float = 80.0 # TODO: определить значение 1 к метрам  
@export var min_scale: float = 0.7 # что это значит?
@export var max_scale: float = 1.3 # а это? 

# Настройки ландшафта
@export var height_amplitude: float = 4.0
@export var noise_frequency: float = 0.04
@export var show_terrain: bool = true
@export var terrain_height_offset: float = 5.0

# ========== НОВЫЕ НАСТРОЙКИ ДЛЯ ИГРОКА ==========
@export_group("Player Spawning")
@export var auto_spawn_player: bool = true
@export var player_spawn_height: float = 3.0 # NOTE: нужен такой чтобы не оказался в земле  по идеии мы не можем прегудагать.

# ========== ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ==========
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()

var path_points := [
	Vector2(-30, -20),
	Vector2(-15, -5),
	Vector2(0, 0),
	Vector2(15, 5),
	Vector2(30, 20)
]

var player_node: CharacterBody3D = null

# ========== _READY ==========
func _ready() -> void:
	rng.randomize()
	setup_noise()
	
	if show_terrain:
		generate_terrain_mesh()
	
	generate_forest()
	print("Лес сгенерирован! Деревьев: ", tree_count)
	
	# Ждем 3 кадра чтобы все загрузилось
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Ищем игрока и сажаем его на ландшафт
	find_and_position_player()
	
	# Отладочная информация
	print("=== ОТЛАДКА КОЛЛИЗИЙ ===")
	print("Смещение ландшафта: ", terrain_height_offset)
	print("Высота в центре (0,0): ", get_height(0, 0))
	
	# # Создаем тестовые маркеры
	# create_test_markers()

# ========== ПОИСК И ПОЗИЦИОНИРОВАНИЕ ИГРОКА ==========
# NOTE: я предлагаю идею что игрок вспавнится на заранее придуманной для него template точке 5 на 5 квадрат который выгледит как точка вспавна. 
func find_and_position_player() -> void:
	print("🔍 Ищем игрока...")
	
	# Получаем корневую ноду (Testing)
	var root = get_tree().current_scene
	print("Корневая нода: ", root.name)
	
	# Ищем игрока по имени "player" в корневой сцене
	var found = false
	for child in root.get_children():
		print("   Проверяем: ", child.name, " (", child.get_class(), ")")
		
		# Ищем по имени "player" (регистр важен!)
		if child.name == "player" and child is CharacterBody3D:
			player_node = child
			found = true
			print("✅ Найден игрок по имени 'player': ", child.name)
			break
		
		# Если это CharacterBody3D
		if child is CharacterBody3D:
			player_node = child
			found = true
			print("✅ Найден игрок как CharacterBody3D: ", child.name)
			break
	
	# Если не нашли в корне, ищем рекурсивно
	if not found:
		print("🔍 Ищем рекурсивно по всей сцене...")
		player_node = find_player_recursive(root)
		if player_node:
			found = true
			print("✅ Найден игрок рекурсивно: ", player_node.name)
	
	if player_node:
		position_player_on_terrain()
	else:
		print("❌ ИГРОК НЕ НАЙДЕН!")
		print("   Все ноды в корневой сцене:")
		for child in root.get_children():
			print("     - ", child.name, " (", child.get_class(), ")")

func find_player_recursive(node: Node) -> CharacterBody3D:
	# Проверяем текущий узел
	if node is CharacterBody3D and node.name == "player":
		return node
	
	# Проверяем всех детей
	for child in node.get_children():
		var result = find_player_recursive(child)
		if result != null:
			return result
	
	return null

func position_player_on_terrain() -> void:
	if not player_node:
		return
	
	# Получаем позицию игрока
	var player_pos = player_node.global_position
	
	# Получаем высоту ландшафта в этой точке
	var terrain_y = get_height(player_pos.x, player_pos.z)
	
	# Игрок ДОЛЖЕН быть НАД ландшафтом
	var new_y = terrain_y + player_spawn_height
	
	print("📍 Позиционирование игрока:")
	print("   Высота ландшафта: ", terrain_y)
	print("   Высота игрока (была): ", player_pos.y)
	print("   Высота игрока (станет): ", new_y)
	print("   Разница: ", new_y - player_pos.y)
	
	# Устанавливаем игрока над ландшафтом
	player_node.global_position.y = new_y
	
	# Обнуляем скорость
	if player_node.has_method("set_velocity"):
		player_node.velocity = Vector3.ZERO
	elif "velocity" in player_node:
		player_node.velocity = Vector3.ZERO
	
	print("✅ Игрок посажен на ландшафт! Новая высота: ", new_y)

# func create_test_markers() -> void:
# 	# Красный маркер в центре
# 	var marker1 := MeshInstance3D.new()
# 	var sphere1 := SphereMesh.new()
# 	sphere1.radius = 0.5
# 	marker1.mesh = sphere1
# 	var mat1 := StandardMaterial3D.new()
# 	mat1.albedo_color = Color.RED
# 	mat1.emission_enabled = true
# 	mat1.emission = Color.RED
# 	marker1.material_override = mat1
# 	var h1 = get_height(0, 0)
# 	marker1.position = Vector3(0, h1 + 0.5, 0)
# 	add_child(marker1)
# 	print("📍 Красный маркер на высоте: ", marker1.position.y)
# 	
# 	# Синий маркер в точке (10, 10)
# 	var marker2 := MeshInstance3D.new()
# 	var sphere2 := SphereMesh.new()
# 	sphere2.radius = 0.5
# 	marker2.mesh = sphere2
# 	var mat2 := StandardMaterial3D.new()
# 	mat2.albedo_color = Color.BLUE
# 	mat2.emission_enabled = true
# 	mat2.emission = Color.BLUE
# 	marker2.material_override = mat2
# 	var h2 = get_height(10, 10)
# 	marker2.position = Vector3(10, h2 + 0.5, 10)
# 	add_child(marker2)
# 	print("📍 Синий маркер на высоте: ", marker2.position.y)
# 	
# 	# Зеленый маркер в точке (-10, -10)
# 	var marker3 := MeshInstance3D.new()
# 	var sphere3 := SphereMesh.new()
# 	sphere3.radius = 0.5
# 	marker3.mesh = sphere3
# 	var mat3 := StandardMaterial3D.new()
# 	mat3.albedo_color = Color.GREEN
# 	mat3.emission_enabled = true
# 	mat3.emission = Color.GREEN
# 	marker3.material_override = mat3
# 	var h3 = get_height(-10, -10)
# 	marker3.position = Vector3(-10, h3 + 0.5, -10)
# 	add_child(marker3)
# 	print("📍 Зеленый маркер на высоте: ", marker3.position.y)

# ========== НАСТРОЙКА ШУМА ==========
func setup_noise() -> void:
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_frequency
	noise.seed = rng.randi()
	
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.08
	detail_noise.seed = rng.randi()

# ========== ФУНКЦИЯ ВЫСОТЫ ==========
func get_height(x: float, z: float) -> float:
	var main_h = noise.get_noise_2d(x, z) * height_amplitude
	var detail_h = detail_noise.get_noise_2d(x, z) * 0.5
	
	var ravine = noise.get_noise_2d(x * 1.8, z * 1.8)
	if ravine < -0.3:
		var depth = (abs(ravine) - 0.3) * 3.0
		main_h -= depth
	
	var path_width = 2.5
	var on_path = false
	for i in range(path_points.size() - 1):
		var p1 = path_points[i]
		var p2 = path_points[i + 1]
		var dist = distance_to_segment(Vector2(x, z), p1, p2)
		if dist < path_width:
			on_path = true
			break
	
	if on_path:
		main_h -= 0.4
	
	return main_h + detail_h + terrain_height_offset

# ========== РАССТОЯНИЕ ДО ОТРЕЗКА ==========
func distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = point - a
	var t = ap.dot(ab) / ab.dot(ab)
	t = clamp(t, 0.0, 1.0)
	var closest = a + t * ab
	return point.distance_to(closest)

# ========== ГЕНЕРАЦИЯ ЛЕСА ==========
func generate_forest() -> void:
	if not tree_scene:
		print("ОШИБКА: Не назначена сцена дерева!")
		return
	
	for i in tree_count:
		var tree := tree_scene.instantiate()
		
		var x := rng.randf_range(-forest_size / 2.0, forest_size / 2.0)
		var z := rng.randf_range(-forest_size / 2.0, forest_size / 2.0)
		var y := get_height(x, z)
		
		tree.position = Vector3(x, y, z)
		tree.rotation.y = rng.randf_range(0.0, TAU)
		
		var scale := rng.randf_range(min_scale, max_scale)
		tree.scale = Vector3.ONE * scale

		add_child(tree)

# ========== ДОБАВЛЕНИЕ КОЛЛИЗИИ К ДЕРЕВУ ==========
func add_collision_to_tree(tree: Node) -> void:
	var has_collision := false
	for child in tree.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			has_collision = true
			break
	
	if not has_collision:
		var mesh_instance := find_mesh_instance(tree)
		if mesh_instance and mesh_instance.mesh:
			var aabb := mesh_instance.mesh.get_aabb()
			var mesh_size: float = aabb.size.length() * 0.5 * tree.scale.x
			
			var collision_shape := CollisionShape3D.new()
			var cylinder_shape := CylinderShape3D.new()
			var radius: float = max(mesh_size * 0.3, 0.3)
			var height: float = max(mesh_size * 0.8, 1.0)
			cylinder_shape.radius = radius
			cylinder_shape.height = height
			collision_shape.shape = cylinder_shape
			
			collision_shape.position = Vector3(0, height * 0.3, 0)
			tree.add_child(collision_shape)

func find_mesh_instance(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := find_mesh_instance(child)
		if found:
			return found
	return null

# ========== ГЕНЕРАЦИЯ ЛАНДШАФТА ==========
func generate_terrain_mesh() -> void:
	var terrain_group := Node3D.new()
	terrain_group.name = "TerrainGroup"
	
	var static_body := StaticBody3D.new()
	static_body.name = "TerrainCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var subdivisions := 80
	var size := forest_size
	var half_size := size / 2.0
	var step := size / subdivisions

	var vertices := []

	for i in range(subdivisions + 1):
		for j in range(subdivisions + 1):
			var x := -half_size + i * step
			var z := -half_size + j * step
			var y := get_height(x, z)
			vertices.append(Vector3(x, y, z))

	# ВАЖНО: Сначала добавляем вершины
	for v in vertices:
		st.add_vertex(v)

	# Потом индексы треугольников
	for i in range(subdivisions):
		for j in range(subdivisions):
			var idx := i * (subdivisions + 1) + j
			var idx2 := idx + 1
			var idx3 := idx + subdivisions + 1
			var idx4 := idx3 + 1

			st.add_index(idx)
			st.add_index(idx3)
			st.add_index(idx2)

			st.add_index(idx2)
			st.add_index(idx3)
			st.add_index(idx4)

	st.generate_normals()

	var mesh := st.commit()
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.15)
	material.roughness = 0.9
	
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	var shape_mesh := mesh.create_trimesh_shape()
	if shape_mesh:
		collision_shape.shape = shape_mesh
		print("✅ Коллизия ландшафта создана успешно!")
	else:
		print("❌ ОШИБКА: Не удалось создать коллизию ландшафта!")

	static_body.add_child(collision_shape)
	static_body.add_child(mesh_instance)
	terrain_group.add_child(static_body)

	add_child(terrain_group)

	print("Ландшафт создан! Размер: ", size, "x", size)
	print("Вершин в меше: ", vertices.size())
	print("Высота центра: ", get_height(0, 0))
	print("Collision layer: ", static_body.collision_layer)
	print("Collision mask: ", static_body.collision_mask)

# ========== ВИЗУАЛИЗАЦИЯ ТРОПИНОК ==========
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			toggle_path_visualization()
		
		if event.keycode == KEY_F5:
			print("🔄 Принудительная привязка игрока (F5)")
			find_and_position_player()

var path_visualization: Node3D

func toggle_path_visualization() -> void:
	if path_visualization:
		path_visualization.queue_free()
		path_visualization = null
		print("Тропинки скрыты")
	else:
		show_paths()
		print("Тропинки показаны")

func show_paths() -> void:
	path_visualization = Node3D.new()
	path_visualization.name = "PathVisualization"
	add_child(path_visualization)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.0, 0.5)
	
	for i in range(path_points.size() - 1):
		var p1 = path_points[i]
		var p2 = path_points[i + 1]
		
		var segment = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 1.0
		cylinder.bottom_radius = 1.0
		cylinder.height = p1.distance_to(p2)
		segment.mesh = cylinder
		segment.material_override = material
		
		var mid = (p1 + p2) / 2.0
		var y = get_height(mid.x, mid.y)
		segment.position = Vector3(mid.x, y + 0.1, mid.y)
		
		var angle = atan2(p2.y - p1.y, p2.x - p1.x)
		segment.rotation.y = -angle
		
		path_visualization.add_child(segment)
