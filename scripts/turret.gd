extends "res://scripts/prop.gd"

@export var shoot_interval: float = 0.6
@export var bullet_force: float = 35.0

var timer: float = 0.0
@onready var nozzle: Node3D = $Nozzle
@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound
@onready var status_light: MeshInstance3D = $StatusLight

func _ready():
	super._ready()
	prop_name = "Automated Turret"
	shoot_sound.stream = preload("res://sounds/toolgun.wav")

func _physics_process(delta):
	timer += delta
	if timer >= shoot_interval:
		timer = 0.0
		if not freeze:
			shoot()
	# blink the status light
	if is_instance_valid(status_light):
		status_light.visible = fmod(Time.get_ticks_msec() * 0.0025, 1.0) > 0.45

func _flash_free(n: Node):
	if is_instance_valid(n):
		n.queue_free()

func shoot():
	shoot_sound.pitch_scale = randf_range(1.2, 1.5)
	shoot_sound.play()
	
	var ball = preload("res://objects/bouncy_ball.tscn").instantiate()
	get_tree().current_scene.add_child(ball)
	
	# Custom tiny ball
	ball.scale = Vector3(0.4, 0.4, 0.4)
	ball.mass = 1.0
	ball.prop_name = "Turret Pellet"
	ball.global_position = nozzle.global_position
	# Shoot in +Z direction of nozzle
	ball.linear_velocity = nozzle.global_transform.basis.z * bullet_force
	
	# Muzzle flash light
	var fl = OmniLight3D.new()
	fl.light_color = Color(1.0, 0.55, 0.25)
	fl.light_energy = 7.0
	fl.omni_range = 7.0
	fl.shadow_enabled = false
	get_tree().current_scene.add_child(fl)
	fl.global_position = nozzle.global_position
	var tw = get_tree().create_tween()
	tw.tween_property(fl, "light_energy", 0.0, 0.12).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_flash_free.bind(fl))
	
	# Despawn after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(_flash_free.bind(ball))
