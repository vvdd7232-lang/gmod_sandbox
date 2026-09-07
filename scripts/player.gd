extends CharacterBody3D

@export var walk_speed: float = 7.0
@export var sprint_speed: float = 14.0
@export var jump_velocity: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export var physgun_speed: float = 18.0

var gravity: float = 16.0

@onready var camera: Camera3D = $Neck/Camera3D
@onready var raycast: RayCast3D = $Neck/Camera3D/RayCast3D
@onready var physgun_beam: Node3D = $Neck/Camera3D/PhysgunBeam
@onready var physgun_audio: AudioStreamPlayer3D = $Neck/Camera3D/PhysgunAudio
@onready var toolgun_audio: AudioStreamPlayer3D = $Neck/Camera3D/ToolgunAudio

# Weapon Visuals
@onready var physgun_model: Node3D = $Neck/Camera3D/WeaponModels/PhysgunModel
@onready var toolgun_model: Node3D = $Neck/Camera3D/WeaponModels/ToolgunModel
@onready var toolgun_label: Label3D = $Neck/Camera3D/WeaponModels/ToolgunModel/Screen/Label3D
@onready var gravgun_model: Node3D = $Neck/Camera3D/WeaponModels/GravgunModel

# Physgun internal state
var physgun_grabbed_object: RigidBody3D = null
var physgun_grab_distance: float = 4.0
var physgun_grab_offset: Vector3 = Vector3.ZERO
var is_rotating_mode: bool = false

# Toolgun internal state
var toolgun_weld_first_obj: Node3D = null

# Gravgun internal state
var gravgun_held_object: RigidBody3D = null

func _ready():
	GameManager.player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	physgun_audio.stream = preload("res://sounds/physgun.wav")
	toolgun_audio.stream = preload("res://sounds/toolgun.wav")
	
	GameManager.weapon_changed.connect(_on_weapon_changed)
	_on_weapon_changed(GameManager.active_weapon_index)

func _on_weapon_changed(index: int):
	# Release any grabs
	_release_physgun()
	if is_instance_valid(gravgun_held_object):
		gravgun_held_object.on_released()
		gravgun_held_object = null
		
	physgun_model.visible = (index == 1)
	toolgun_model.visible = (index == 2)
	gravgun_model.visible = (index == 3)
	
	if toolgun_label and is_instance_valid(toolgun_label):
		toolgun_label.text = GameManager.toolgun_mode.to_upper()

func _input(event):
	if GameManager.is_spawn_menu_open:
		return
		
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if is_rotating_mode and is_instance_valid(physgun_grabbed_object):
			# Rotate grabbed object
			var rot_speed = 0.005
			physgun_grabbed_object.rotate_y(-event.relative.x * rot_speed)
			physgun_grabbed_object.rotate_x(-event.relative.y * rot_speed)
		else:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2.1, PI/2.1)

	# Rotate mode toggle
	if event is InputEventKey:
		if event.physical_keycode == KEY_E:
			is_rotating_mode = event.pressed
			
		# Weapon switches
		if event.pressed and not event.echo:
			if event.physical_keycode == KEY_1:
				GameManager.set_active_weapon(1)
			elif event.physical_keycode == KEY_2:
				GameManager.set_active_weapon(2)
			elif event.physical_keycode == KEY_3:
				GameManager.set_active_weapon(3)
			elif event.physical_keycode == KEY_Q or event.physical_keycode == KEY_TAB:
				GameManager.toggle_spawn_menu()
			elif event.physical_keycode == KEY_R:
				# Reset props / double right click
				if GameManager.active_weapon_index == 1 and is_instance_valid(physgun_grabbed_object):
					physgun_grabbed_object.unfreeze_prop()
				elif Input.is_key_pressed(KEY_SHIFT):
					GameManager.clear_all_props()

	# Scroll wheel for physgun distance or weapon select
	if event is InputEventMouseButton and event.pressed:
		if GameManager.active_weapon_index == 1 and is_instance_valid(physgun_grabbed_object):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				physgun_grab_distance = min(physgun_grab_distance + 1.0, 40.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				physgun_grab_distance = max(physgun_grab_distance - 1.0, 1.5)
		else:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var w = GameManager.active_weapon_index - 1
				if w < 1: w = 3
				GameManager.set_active_weapon(w)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var w = GameManager.active_weapon_index + 1
				if w > 3: w = 1
				GameManager.set_active_weapon(w)

func _physics_process(delta):
	if not GameManager.is_spawn_menu_open:
		_handle_movement(delta)
		_handle_weapons(delta)
	
	# Update active tool label
	if toolgun_label and toolgun_model.visible:
		toolgun_label.text = GameManager.toolgun_mode.to_upper()

func _handle_movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var spd = sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	
	if direction:
		velocity.x = direction.x * spd
		velocity.z = direction.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0, spd)
		velocity.z = move_toward(velocity.z, 0, spd)

	move_and_slide()

func _handle_weapons(delta):
	if GameManager.active_weapon_index == 1:
		_process_physgun(delta)
	elif GameManager.active_weapon_index == 2:
		_process_toolgun(delta)
	elif GameManager.active_weapon_index == 3:
		_process_gravgun(delta)

# --- PHYSGUN ---
func _process_physgun(delta):
	var left_click = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var right_click = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	if left_click:
		if not is_instance_valid(physgun_grabbed_object):
			# Try to grab
			if raycast.is_colliding():
				var hit = raycast.get_collider()
				if hit is RigidBody3D:
					physgun_grabbed_object = hit
					physgun_grabbed_object.unfreeze_prop()
					physgun_grabbed_object.on_grabbed()
					physgun_grab_distance = clamp(global_position.distance_to(raycast.get_collision_point()), 2.0, 25.0)
					if not physgun_audio.playing:
						physgun_audio.play()
		else:
			# Move grabbed object
			var target_pos = camera.global_position - camera.global_transform.basis.z * physgun_grab_distance
			var dir = (target_pos - physgun_grabbed_object.global_position)
			physgun_grabbed_object.linear_velocity = dir * physgun_speed
			physgun_grabbed_object.angular_velocity = physgun_grabbed_object.angular_velocity.lerp(Vector3.ZERO, delta * 5.0)
			
			# Freeze object on right click
			if right_click:
				physgun_grabbed_object.freeze_prop()
				toolgun_audio.pitch_scale = 1.8
				toolgun_audio.play()
				_release_physgun()
				return
				
			# Render visual laser beam
			_update_physgun_beam(target_pos)
	else:
		_release_physgun()

func _release_physgun():
	if is_instance_valid(physgun_grabbed_object):
		physgun_grabbed_object.on_released()
	physgun_grabbed_object = null
	physgun_beam.visible = false
	if physgun_audio.playing:
		physgun_audio.stop()

func _update_physgun_beam(target_pos: Vector3):
	physgun_beam.visible = true
	var start_pos = physgun_model.global_position + physgun_model.global_transform.basis.z * 0.5 - physgun_model.global_transform.basis.y * 0.1
	var length = start_pos.distance_to(target_pos)
	
	physgun_beam.global_position = start_pos.lerp(target_pos, 0.5)
	physgun_beam.look_at(target_pos, Vector3.UP)
	physgun_beam.scale = Vector3(0.05, 0.05, length)

# --- TOOLGUN ---
func _process_toolgun(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Simple debounce/just pressed check
		if not get_meta("toolgun_fired", false):
			set_meta("toolgun_fired", true)
			get_tree().create_timer(0.25).timeout.connect(func(): set_meta("toolgun_fired", false))
			
			if raycast.is_colliding():
				var hit = raycast.get_collider()
				var hit_point = raycast.get_collision_point()
				var hit_norm = raycast.get_collision_normal()
				
				toolgun_audio.pitch_scale = randf_range(0.9, 1.1)
				toolgun_audio.play()
				
				var mode = GameManager.toolgun_mode
				if mode == "weld":
					if hit is RigidBody3D:
						if not is_instance_valid(toolgun_weld_first_obj):
							toolgun_weld_first_obj = hit
							toolgun_audio.pitch_scale = 1.5
							toolgun_audio.play()
						else:
							if hit != toolgun_weld_first_obj:
								var joint = PinJoint3D.new()
								get_tree().current_scene.add_child(joint)
								joint.global_position = hit_point
								joint.node_a = joint.get_path_to(toolgun_weld_first_obj)
								joint.node_b = joint.get_path_to(hit)
								toolgun_weld_first_obj = null
								toolgun_audio.pitch_scale = 0.7
								toolgun_audio.play()
				elif mode == "thruster":
					if hit is RigidBody3D:
						var thruster = preload("res://objects/thruster.tscn").instantiate()
						hit.add_child(thruster)
						thruster.global_position = hit_point
						# Align +Y with hit normal
						if hit_norm.cross(Vector3.UP).length() < 0.01:
							thruster.rotation.x = PI/2 * sign(hit_norm.y)
						else:
							thruster.look_at(hit_point + hit_norm, Vector3.UP)
							thruster.rotate_x(-PI/2)
						thruster.thrust_force = GameManager.toolgun_thruster_force
				elif mode == "balloon":
					if hit is RigidBody3D:
						var balloon = preload("res://objects/balloon.tscn").instantiate()
						hit.add_child(balloon)
						balloon.global_position = hit_point
						balloon.balloon_force = GameManager.toolgun_balloon_force
				elif mode == "color":
					if hit.has_method("set_custom_color"):
						hit.set_custom_color(GameManager.toolgun_color)
				elif mode == "remover":
					if hit.is_in_group("props"):
						hit.take_damage(9999.0)
					elif hit.get_parent() and hit.get_parent().name == "DummyRagdoll":
						hit.get_parent().queue_free()

# --- GRAVITY GUN ---
func _process_gravgun(delta):
	var left_click = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var right_click = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	if right_click:
		if not is_instance_valid(gravgun_held_object):
			if raycast.is_colliding():
				var hit = raycast.get_collider()
				if hit is RigidBody3D and hit.mass < 200.0:
					hit.unfreeze_prop()
					var hold_target = camera.global_position - camera.global_transform.basis.z * 3.0
					var dist = hit.global_position.distance_to(hold_target)
					if dist < 1.0:
						gravgun_held_object = hit
						gravgun_held_object.on_grabbed()
					else:
						# Pull towards camera
						hit.linear_velocity = (hold_target - hit.global_position).normalized() * 25.0
		else:
			var hold_target = camera.global_position - camera.global_transform.basis.z * 3.0
			gravgun_held_object.linear_velocity = (hold_target - gravgun_held_object.global_position) * 15.0
			gravgun_held_object.angular_velocity = Vector3.ZERO
	else:
		if is_instance_valid(gravgun_held_object):
			gravgun_held_object.on_released()
			gravgun_held_object = null
			
	if left_click:
		if not get_meta("gravgun_fired", false):
			set_meta("gravgun_fired", true)
			get_tree().create_timer(0.5).timeout.connect(func(): set_meta("gravgun_fired", false))
			
			toolgun_audio.pitch_scale = 0.5
			toolgun_audio.play()
			
			if is_instance_valid(gravgun_held_object):
				# Launch held object
				var obj = gravgun_held_object
				obj.on_released()
				gravgun_held_object = null
				obj.linear_velocity = -camera.global_transform.basis.z * 60.0
			else:
				# Blast nearby objects
				var props = get_tree().get_nodes_in_group("props")
				for p in props:
					if is_instance_valid(p) and p is RigidBody3D:
						var dir = p.global_position - camera.global_position
						if dir.length() < 10.0 and dir.normalized().dot(-camera.global_transform.basis.z) > 0.5:
							p.unfreeze_prop()
							p.apply_central_impulse(-camera.global_transform.basis.z * 40.0 * p.mass)
