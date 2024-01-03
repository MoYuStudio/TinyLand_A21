
extends Node3D

var camera_position:Vector3  # 相机位置
var camera_rotation:Vector3  # 相机旋转

@onready var camera = $Camera

func _ready():
	
	camera_rotation = rotation_degrees  # 初始旋转
	
	pass

func _process(delta):
	
	# 将位置和旋转设置为目标值
	
	position = position.lerp(camera_position, delta * 8)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
	
	handle_input(delta)

# 处理输入

func handle_input(_delta):
	
	# 旋转
	
	var input := Vector3.ZERO
	
	input.x = Input.get_axis("camera_left", "camera_right")
	input.z = Input.get_axis("camera_forward", "camera_back")
	
	input = input.rotated(Vector3.UP, rotation.y).normalized()
	
	camera_position += input / 4
	
	# 回到中心位置
	
	if Input.is_action_pressed("camera_center"):
		camera_position = Vector3()

func _input(event):
	
	# 使用鼠标旋转相机（按住 'middle' 鼠标按钮）
	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("camera_rotate"):
			camera_rotation += Vector3(0, -event.relative.x / 10, 0)
