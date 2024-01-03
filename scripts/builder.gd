
extends Node3D

@export var structures: Array[Structure] = []  # 导出的结构数组

var map:DataMap  # 数据地图

var index:int = 0  # 正在建造的结构的索引

@export var selector:Node3D  # 光标
@export var selector_container:Node3D  # 包含结构预览的节点
@export var view_camera:Camera3D  # 用于射线检测鼠标
@export var gridmap:GridMap
@export var cash_display:Label

var plane:Plane  # 用于射线检测鼠标

func _ready():
	
	map = DataMap.new()
	plane = Plane(Vector3.UP, Vector3.ZERO)
	
	var mesh_library = MeshLibrary.new()  # 创建MeshLibrary，用于动态加载网格
	
	for structure in structures:
		
		var id = mesh_library.get_last_unused_item_id()
		
		mesh_library.create_item(id)
		mesh_library.set_item_mesh(id, get_mesh(structure.model))
		mesh_library.set_item_mesh_transform(id, Transform3D())
		
	gridmap.mesh_library = mesh_library
	
	update_structure()
	update_cash()

func _process(delta):
	
	# 控制
	
	action_rotate()  # 旋转选择 90 度
	action_structure_toggle()  # 在不同结构之间切换
	
	action_save()  # 保存
	action_load()  # 加载
	
	# 根据鼠标计算地图位置
	
	var world_position = plane.intersects_ray(
		view_camera.project_ray_origin(get_viewport().get_mouse_position()),
		view_camera.project_ray_normal(get_viewport().get_mouse_position()))

	var gridmap_position = Vector3(round(world_position.x), 0, round(world_position.z))
	selector.position = lerp(selector.position, gridmap_position, delta * 40)
	
	action_build(gridmap_position)
	action_demolish(gridmap_position)

# 从PackedScene获取网格，用于动态创建MeshLibrary

func get_mesh(packed_scene):
	var scene_state:SceneState = packed_scene.get_state()
	for i in range(scene_state.get_node_count()):
		if(scene_state.get_node_type(i) == "MeshInstance3D"):
			for j in scene_state.get_node_property_count(i):
				var prop_name = scene_state.get_node_property_name(i, j)
				if prop_name == "mesh":
					var prop_value = scene_state.get_node_property_value(i, j)
					
					return prop_value.duplicate()

# 建造（放置）一个结构

func action_build(gridmap_position):
	if Input.is_action_just_pressed("build"):
		
		var previous_tile = gridmap.get_cell_item(gridmap_position)
		gridmap.set_cell_item(gridmap_position, index, gridmap.get_orthogonal_index_from_basis(selector.basis))
		
		if previous_tile != index:
			map.cash -= structures[index].price
			update_cash()

# 拆除（移除）一个结构

func action_demolish(gridmap_position):
	if Input.is_action_just_pressed("demolish"):
		gridmap.set_cell_item(gridmap_position, -1)

# 旋转光标 90 度

func action_rotate():
	if Input.is_action_just_pressed("rotate"):
		selector.rotate_y(deg_to_rad(90))

# 切换要建造的结构

func action_structure_toggle():
	if Input.is_action_just_pressed("structure_next"):
		index = wrap(index + 1, 0, structures.size())
	
	if Input.is_action_just_pressed("structure_previous"):
		index = wrap(index - 1, 0, structures.size())

	update_structure()

# 更新光标中的结构预览

func update_structure():
	# 清除先前在光标中的结构预览
	for n in selector_container.get_children():
		selector_container.remove_child(n)
		
	# 在光标中创建新的结构预览
	var _model = structures[index].model.instantiate()
	selector_container.add_child(_model)
	_model.position.y += 0.25
	
func update_cash():
	cash_display.text = "￥" + str(map.cash)

# 保存/加载

func action_save():
	if Input.is_action_just_pressed("save"):
		print("保存地图...")
		
		map.structures.clear()
		for cell in gridmap.get_used_cells():
			
			var data_structure:DataStructure = DataStructure.new()
			
			data_structure.position = Vector2i(cell.x, cell.z)
			data_structure.orientation = gridmap.get_cell_item_orientation(cell)
			data_structure.structure = gridmap.get_cell_item(cell)
			
			map.structures.append(data_structure)
			
		ResourceSaver.save(map, "user://map.res")
	
func action_load():
	if Input.is_action_just_pressed("load"):
		print("加载地图...")
		
		gridmap.clear()
		
		map = ResourceLoader.load("user://map.res")
		if not map:
			map = DataMap.new()
		for cell in map.structures:
			gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
			
		update_cash()
