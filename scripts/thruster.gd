extends Node3D

@export var thrust_force: float = 20.0
@export var keycode: int = KEY_T

var is_active: bool = false
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var flame_mesh: Node3D = $Flame
@onready var flame_light: OmniLight3D = $Flame/FlameLight

func _ready():
	audio_player.stream = preload("res://sounds/thruster.wav")
	set_active(false)

func _process(delta):
	# Toggle when key is just pressed
	if Input.is_key_pressed(keycode):
		if not is_active:
			set_active(true)
		elif is_active:
			# flame flicker
			if is_instance_valid(flame_mesh):
				flame_mesh.scale = Vector3(
					1.0 + randf_range(0.0, 0.28),
					1.0 + randf_range(0.0, 0.45),
					1.0 + randf_range(0.0, 0.28))
			if is_instance_valid(flame_light):
				flame_light.light_energy = randf_range(3.2, 5.0)
	else:
		if is_active:
			set_active(false)
	if is_instance_valid(flame_light):
		flame_light.light_energy = lerpf(flame_light.light_energy, 4.0, delta * 4.0)

func set_active(active: bool):
	is_active = active
	if is_instance_valid(flame_mesh):
		flame_mesh.visible = is_active
		if not is_active:
			flame_mesh.scale = Vector3.ONE
	if is_instance_valid(audio_player):
		if is_active and not audio_player.playing:
			audio_player.play()
		elif not is_active and audio_player.playing:
			audio_player.stop()

func _physics_process(delta):
	if is_active:
		var parent = get_parent()
		if parent is RigidBody3D:
			# Apply force in the local +Y direction of the thruster
			parent.unfreeze_prop()
			parent.apply_force(global_transform.basis.y * thrust_force * parent.mass * 2.0, global_position - parent.global_position)
