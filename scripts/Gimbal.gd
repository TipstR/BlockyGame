extends Node3D

@onready var camera = get_node('/root/Main/Gimbal/Camera3D')
@onready var GUI = get_node('/root/Main/GUI')
@onready var ship = null

var old_rotation
var click_position
var sensitivity = 0.2
var zoom = 1.5

func _unhandled_input(event):
	if Input.is_action_pressed("zoom in"):
		zoom -= 0.1
		
	if Input.is_action_pressed("zoom out"):
		zoom += 0.1
	
	if zoom < 0:
		zoom = 0
		
	scale = Vector3.ONE * zoom
	
	if Input.is_action_just_pressed("rotate camera"):
		old_rotation = rotation_degrees
		click_position = get_viewport().get_mouse_position()
	if Input.is_action_pressed("rotate camera"):
		var rot_x = clamp(old_rotation.x - (get_viewport().get_mouse_position().y - click_position.y) * sensitivity, -90, 90)
		var rot_y = old_rotation.y - (get_viewport().get_mouse_position().x - click_position.x) * sensitivity
		rotation_degrees = Vector3(rot_x, rot_y, 0)

func _process(delta):
	if ship != null:
		self.global_position.x = ship.global_position.x
		self.global_position.y = ship.global_position.y + 1
		self.global_position.z = ship.global_position.z
	
func connect_camera():
	ship = get_node("/root/Main/Ship")
		
