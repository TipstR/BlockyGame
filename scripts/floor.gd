extends Node3D

@export var size := 0.33
@export var water_drag := 200
@export var water_angular_drag := 0.5
@export var displacementAmount := 1.0

@onready var connected_blocks = {
	"front_block": null,
	"back_block": null,
	"left_block": null,
	"right_block": null,
	"bottom_block": null,
	"top_block": null
}
@onready var mass = -1
@onready var float_force = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	var depth = -self.global_position.y
	if depth > 0:
		var buoyancy = depth/2
		
		get_parent().apply_force(Vector3.UP * 9.81 * buoyancy * float_force, global_position - get_parent().global_position)
		get_parent().apply_central_force(buoyancy * -get_parent().linear_velocity * water_drag)
			
		get_parent().apply_torque(buoyancy * -get_parent().angular_velocity * water_angular_drag)
