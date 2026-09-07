extends "res://scripts/prop.gd"

@export var shoot_interval: float = 0.6
@export var bullet_force: float = 35.0

var timer: float = 0.0
@onready var nozzle: Node3D = $Nozzle
@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound

func _ready():
	super._ready()
	prop_name = "Automated Turret"
	shoot_sound.stream = preload("res://sounds/toolgun.wav")

func _physics_process(delta):
	timer += delta
	if timer >= shoot_interval:
		timer = 0.0
		if not freeze: # Only shoot if not frozen, or shoot all the time? Let's shoot all the time so players can freeze it to make fixed defense turrets!
			shoot()

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
	
	# Despawn after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func(): if is_instance_valid(ball): ball.queue_free())
