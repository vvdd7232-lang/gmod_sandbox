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

func _free_node_later(n: Node, delay: float):
	get_tree().create_timer(delay).timeout.connect(_free_node.bind(n))

func _free_node(n: Node):
	if is_instance_valid(n):
		n.queue_free()

func _spawn_burst(pos: Vector3, count: int, color_a: Color, color_b: Color, lifetime: float, spread_deg: float, speed_min: float, speed_max: float, gravity_y: float, scale_min: float, scale_max: float, quad_size: float = 0.3):
	var ps := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3.UP
	pm.spread = spread_deg
	pm.initial_velocity_min = speed_min
	pm.initial_velocity_max = speed_max
	pm.gravity = Vector3(0, gravity_y, 0)
	pm.scale_min = scale_min
	pm.scale_max = scale_max
	ps.process_material = pm
	ps.amount = count
	ps.lifetime = lifetime
	ps.one_shot = true
	ps.explosiveness = 1.0
	ps.emitting = true
	
	var quad := QuadMesh.new()
	quad.size = Vector2(quad_size, quad_size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	ps.mesh = quad
	
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	grad.colors = PackedColorArray([
		color_a,
		color_b,
		Color(color_b.r, color_b.g, color_b.b, 0.0)
	])
	ps.color_ramp = grad
	
	var scene = get_tree().current_scene
	scene.add_child(ps)
	ps.global_position = pos
	_free_node_later(ps, lifetime + 0.5)

func explode():
	# Play explosion sound
	var boom = AudioStreamPlayer3D.new()
	boom.stream = preload("res://sounds/explosion.wav")
	boom.unit_size = 15.0
	boom.volume_db = 10.0
	get_tree().current_scene.add_child(boom)
	boom.global_position = global_position
	boom.play()
	boom.finished.connect(_free_node.bind(boom))
	
	# Flash light
	var flash = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.85, 0.55)
	flash.light_energy = 18.0
	flash.omni_range = explosion_radius * 2.4
	flash.shadow_enabled = false
	get_tree().current_scene.add_child(flash)
	flash.global_position = global_position
	var tw = get_tree().create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_free_node.bind(flash))
	
	# Fireball + sparks + smoke
	_spawn_burst(global_position, 110, Color(1, 0.95, 0.6, 1), Color(1, 0.35, 0.08, 1), 0.6, 180.0, 5.0, 14.0, -4.0, 0.5, 1.5, 0.55)
	_spawn_burst(global_position, 55, Color(1, 0.6, 0.25, 1), Color(0.8, 0.15, 0.05, 1), 0.9, 180.0, 8.0, 18.0, 9.0, 0.2, 0.6, 0.2)
	_spawn_burst(global_position, 30, Color(0.4, 0.39, 0.38, 1), Color(0.12, 0.12, 0.12, 1), 2.2, 30.0, 1.5, 4.0, -0.6, 1.0, 2.6, 1.1)
	
	# Expanding glow sphere (quick punch)
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = explosion_radius * 0.28
	mesh.height = explosion_radius * 0.56
	mesh.radial_segments = 20
	mesh.rings = 10
	sphere.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.25, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.12)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_receive_shadows = true
	sphere.material_override = mat
	get_tree().current_scene.add_child(sphere)
	sphere.global_position = global_position
	var tw2 = get_tree().create_tween()
	tw2.tween_property(sphere, "scale", Vector3(2.2, 2.2, 2.2), 0.22).set_trans(Tween.TRANS_QUAD)
	tw2.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw2.tween_callback(_free_node.bind(sphere))
	
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
				# chip damage to nearby barrels = chain reactions
				if p.is_explosive:
					p.take_damage(90.0 * (1.0 - dist / explosion_radius))
				
	# Check player
	if is_instance_valid(GameManager.player):
		var p_dist = GameManager.player.global_position.distance_to(global_position)
		if p_dist < explosion_radius:
			var dir = (GameManager.player.global_position - global_position).normalized()
			GameManager.player.velocity += dir * explosion_force * (1.0 - p_dist / explosion_radius)
			if GameManager.player.has_method("add_shake"):
				GameManager.player.add_shake(0.5 * (1.0 - p_dist / explosion_radius))
		
	queue_free()
