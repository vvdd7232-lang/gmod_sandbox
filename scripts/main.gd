extends Node3D

func _ready():
	# Make sure mouse is captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initial Sun settings
	var sun = $Sun
	if sun:
		sun.rotation.x = -PI/4
