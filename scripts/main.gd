extends Node3D

@onready var shipNode = RigidBody3D.new()
@onready var ship

@onready var blockScene = preload("res://scenes/block.tscn")
@onready var floorScene = preload("res://scenes/floor.tscn")
@onready var collisionBoxScene = preload("res://scenes/collision_box.tscn")
@onready var waterBlockScene = preload("res://scenes/waterBlock.tscn")
@onready var ghostBlockScene = preload("res://scenes/ghost_block.tscn")

@onready var woodButton = get_node("GUI/WoodButton")
@onready var steelButton = get_node("GUI/SteelButton")
@onready var sailButton = get_node("GUI/SailButton")
@onready var camera = get_node("Gimbal")
@onready var arrow = get_node("Arrow")

@onready var selected_material = "wood"
@onready var selected_type = "block"
@onready var old_ghost_position = null

@onready var rnd = RandomNumberGenerator.new()


@export var block_attributes = {
	"wood": {
		"mass": 10,
		"float_force": 50,
		"material": [preload("res://art/materials/pixel_art_16_16/wood_pixel_standard_material_3d.tres"), 
					 preload("res://art/materials/pixel_art_16_16/wood2_pixel_standard_material_3d.tres")]
	},
	"steel": {
		"mass": 50,
		"float_force": 5,
		"material": [preload("res://art/materials/metal_standard_material_3d.tres")]
	},
	"sail": {
		"mass": 1,
		"float_force": 0,
		"material": [preload("res://art/materials/fabric_standard_material_3d.tres")]
	}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	shipNode.name = "Ship"
	add_child(shipNode, true)

	ship = get_child(get_child_count() - 1)
	
	ship.freeze = true
	ship.global_position = Vector3(0, 10, 0)

	var block = blockScene.instantiate()
	block.name = "main"
	var collisionBox = collisionBoxScene.instantiate()

	ship.add_child(collisionBox, true)
	ship.add_child(block, true)
	
	ship.get_child(1).float_force = block_attributes["wood"]["float_force"]
	ship.get_child(1).mass = block_attributes["wood"]["mass"]
	ship.get_child(1).get_child(0).set_surface_override_material(0, block_attributes["wood"]["material"][0])
	ship.get_child(1).rotation_degrees.y = 90
	
	var click_box = ship.get_child(1).find_child("ClickBox*")
	ship.mass = block_attributes["wood"]["mass"]

	click_box.input_event.connect(_on_click.bind(ship.get_child(1)))
	
	ship.set_script(load("res://scripts/ship.gd"))
	ship._ready()
	camera.connect_camera()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggle physics"):
		if ship.freeze:
			ship.freeze = false
			print("Physics enabled")
			arrow.hide()
		else:
			ship.freeze = true
			ship.global_position = Vector3(0, 10, 0)
			ship.global_rotation = Vector3.ZERO
			print("Physics disabled")
			arrow.show()
		
		
func _physics_process(delta):
	
	if ship.freeze:
		if get_mouse_block_position() != old_ghost_position:
			if ship.find_child("ghost*") != null:
				ship.find_child("ghost*").queue_free()
				old_ghost_position = null
			
			if get_mouse_block_position() != null:
				project_ghost_block(get_mouse_block_position())

	else:
		if ship.find_child("ghost*") != null:
				ship.find_child("ghost*").queue_free()
				old_ghost_position = null
		
		
			
			
func _on_click(camera, event, position, normal, shape_idx, emitter):
	# New Block
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and ship.freeze:		
		var newBlockInstance = -1
		
		match selected_type:
			"block":
				newBlockInstance = blockScene.instantiate()
			"floor":
				newBlockInstance = floorScene.instantiate()

		newBlockInstance.name = selected_material + "_" + selected_type
		emitter.get_parent().add_child(newBlockInstance, true)
		var newBlock = get_last_child(emitter.get_parent())
		newBlock.owner = ship
		
		newBlock.mass = block_attributes[selected_material]["mass"] * newBlock.size
		newBlock.float_force = block_attributes[selected_material]["float_force"] * newBlock.size
		newBlock.get_child(0).set_surface_override_material(0, block_attributes[selected_material]["material"][rnd.randi_range(0, block_attributes[selected_material]["material"].size() - 1)])
		
		ship.mass += newBlock.mass
		
		newBlock.position = emitter.position + normal
		newBlock.rotation_degrees.y = 90
		
		ship.blocks[newBlock.position] = newBlock

		var click_box = newBlock.find_child("ClickBox*")
		print("newBlock Children: ", newBlock.get_children())

		click_box.input_event.connect(_on_click.bind(newBlock))
		
		var newCollisionBox = collisionBoxScene.instantiate()
		
		newCollisionBox.name = newBlock.name + "_CollisionBox"
		
		ship.add_child(newCollisionBox)
		get_last_child(ship).position = newBlock.position
		
		match normal:
			Vector3(0, 0, 1):
				emitter.connected_blocks["front_block"] = newBlock
			Vector3(0, 0, -1):
				emitter.connected_blocks["back_block"] = newBlock
			Vector3(1, 0, 0):
				emitter.connected_blocks["left_block"] = newBlock
			Vector3(-1, 0, 0):
				emitter.connected_blocks["right_block"] = newBlock
			Vector3(0, -1, 0):
				emitter.connected_blocks["bottom_block"] = newBlock
			Vector3(0, 1, 0):
				emitter.connected_blocks["top_block"] = newBlock
					
		print(ship.mass)
		print(ship.blocks)
		
		
	# Erase Block
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		if(emitter.name != "main"):
			ship.blocks.erase(emitter.position)
			get_node("Ship/" + emitter.name + "_CollisionBox").queue_free()
			emitter.queue_free()
			ship.mass -= emitter.mass
		
	
func project_ghost_block(block_position):
	var ghostBlockInstance = ghostBlockScene.instantiate()
			
	ghostBlockInstance.name = "ghost_block"
	ship.add_child(ghostBlockInstance, true)
	var ghostBlock = get_last_child(ship)
	ghostBlock.owner = ship
	
	ghostBlock.global_position = block_position
	old_ghost_position = block_position
		
			
func get_last_child(node):
	return node.get_child(node.get_child_count() - 1)		
	
func set_noise_offset(offset):
	get_last_child(self).get_child(0).mesh.material.get_shader_parameter("texture_normal").noise.offset = offset
	get_last_child(self).get_child(0).mesh.material.get_shader_parameter("texture_normal2").noise.offset = offset
	
func get_3d_mouse_position():
	var camera = get_node("Gimbal/Camera3D")
	
	var space_state = get_world_3d().get_direct_space_state()
	var mouse_position = get_viewport().get_mouse_position()
	var params = PhysicsRayQueryParameters3D.new()
	params.from = camera.project_ray_origin(mouse_position)
	params.to = camera.project_ray_normal(mouse_position) * 2000
	return space_state.intersect_ray(params)
			

func get_mouse_block_position():
	var mouse_position_3d = get_3d_mouse_position()
	if mouse_position_3d == {}:
		return null
		
	var result
		
	match mouse_position_3d["normal"]:
		Vector3(0, 0, 1):
			result = Vector3(round(mouse_position_3d["position"].x),
							round(mouse_position_3d["position"].y),
							round(mouse_position_3d["position"].z + 0.01))
		Vector3(0, 0, -1):
			result = Vector3(round(mouse_position_3d["position"].x),
							round(mouse_position_3d["position"].y),
							round(mouse_position_3d["position"].z - 0.01))
		Vector3(1, 0, 0):
			result = Vector3(round(mouse_position_3d["position"].x + 0.01),
							round(mouse_position_3d["position"].y),
							round(mouse_position_3d["position"].z))
		Vector3(-1, 0, 0):
			result = Vector3(round(mouse_position_3d["position"].x - 0.01),
							round(mouse_position_3d["position"].y),
							round(mouse_position_3d["position"].z))
		Vector3(0, -1, 0):
			result = Vector3(round(mouse_position_3d["position"].x),
							round(mouse_position_3d["position"].y - 0.01),
							round(mouse_position_3d["position"].z))
		Vector3(0, 1, 0):
			result = Vector3(round(mouse_position_3d["position"].x),
							round(mouse_position_3d["position"].y + 0.01),
							round(mouse_position_3d["position"].z))
							
	return result
	

func _on_wood_button_pressed():
	selected_material = "wood"


func _on_sai_button_pressed():
	selected_material = "sail"


func _on_steel_button_pressed():
	selected_material = "steel"


func _on_block_button_pressed():
	selected_type = "block"


func _on_floor_button_pressed():
	selected_type = "floor"
