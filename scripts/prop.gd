extends RigidBody3D

@export var prop_name: String = "Prop"
@export var is_explosive: bool = false
@export var explosion_force: float = 25.0
@export var explosion_radius: float = 8.0

var is_physgun_grabbed: bool = false
var original_collision_mask: int = 7
var original_collision_layer: int = 4
var health: float = 100.0

@onready var audio_player: AudioStreamPlayer3D = null

func _ready():
	original_collision_mask = collision_mask
	original_collision_layer = collision_layer
	
	# Setup impact sound
	audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = preload("res://sounds/impact.wav")
	audio_player.max_distance = 30.0
	audio_player.volume_db = -5.0
	add_child(audio_player)
	
	# Enable contact reporting for impact sounds
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)
	
	add_to_group("props")
	GameManager.register_prop(self)

func _on_body_entered(body):
	if is_physgun_grabbed:
		return
	
	var vel = linear_velocity.length()
	if vel > 2.0 and not audio_player.playing:
		audio_player.volume_db = clamp((vel - 5.0) * 2.0, -20.0, 5.0)
		audio_player.pitch_scale = randf_range(0.9, 1.1)
		audio_player.play()
		
	if is_explosive and vel > 12.0:
		take_damage(50.0)

func on_grabbed():
	is_physgun_grabbed = true
	linear_damp = 5.0
	angular_damp = 5.0

func on_released():
	is_physgun_grabbed = false
	linear_damp = 0.0
	angular_damp = 0.0

func freeze_prop():
	freeze = true

func unfreeze_prop():
	freeze = false

func set_custom_color(color: Color):
	for child in get_children():
		if child is MeshInstance3D:
			var mat = child.get_active_material(0)
			if mat:
				var new_mat = mat.duplicate()
				new_mat.albedo_color = color
				child.set_surface_override_material(0, new_mat)
			else:
				var new_mat = StandardMaterial3D.new()
				new_mat.albedo_color = color
				child.set_surface_override_material(0, new_mat)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		if is_explosive:
			explode()
		else:
			queue_free()

func explode():
	# Play explosion sound
	var boom = AudioStreamPlayer3D.new()
	boom.stream = preload("res://sounds/explosion.wav")
	boom.unit_size = 15.0
	boom.volume_db = 10.0
	get_tree().current_scene.add_child(boom)
	boom.global_position = global_position
	boom.play()
	boom.finished.connect(func(): boom.queue_free())
	
	# Create explosion particle effect or visual sphere
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = explosion_radius
	mesh.height = explosion_radius * 2
	sphere.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.1, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.1)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = mat
	get_tree().current_scene.add_child(sphere)
	sphere.global_position = global_position
	
	# Animate sphere fading
	var tween = get_tree().create_tween()
	tween.tween_property(sphere, "scale", Vector3(1.2, 1.2, 1.2), 0.2)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(func(): sphere.queue_free())
	
	# Apply physical force to nearby objects
	var props = get_tree().get_nodes_in_group("props")
	for p in props:
		if p != self and is_instance_valid(p) and p is RigidBody3D:
			var dist = p.global_position.distance_to(global_position)
			if dist < explosion_radius:
				p.unfreeze_prop()
				var dir = (p.global_position - global_position).normalized()
				var force_amt = explosion_force * (1.0 - dist / explosion_radius)
				p.apply_central_impulse(dir * force_amt * p.mass)
				
	# Check player
	if is_instance_valid(GameManager.player):
		var p_dist = GameManager.player.global_position.distance_to(global_position)
		if p_dist < explosion_radius:
			var dir = (GameManager.player.global_position - global_position).normalized()
			GameManager.player.velocity += dir * explosion_force * (1.0 - p_dist / explosion_radius)
			
	queue_free()
