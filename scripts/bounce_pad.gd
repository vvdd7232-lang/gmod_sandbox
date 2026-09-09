extends "res://scripts/prop.gd"

@export var boost_y: float = 21.0

var _last_boost: Dictionary = {}

func _ready():
	super._ready()
	prop_name = "Launch Pad"
	$BoostArea.body_entered.connect(_on_boost_area_entered)

func _on_boost_area_entered(body: Node):
	if freeze:
		return
	var now: float = Time.get_ticks_msec() * 0.001
	if _last_boost.get(body, -100.0) > now - 0.55:
		return
	_last_boost[body] = now

	if body is RigidBody3D:
		# Launch props when they land on the pad
		if body.linear_velocity.y < 3.0:
			body.unfreeze_prop()
			body.linear_velocity.y = boost_y + minf(body.mass * 0.015, 2.5)
			_flash()
	elif body is CharacterBody3D and body.is_in_group("player_body"):
		# Trampoline for the player too
		if body.velocity.y < 4.0:
			body.velocity.y = boost_y + 3.0
			_flash()

func _flash():
	var l := OmniLight3D.new()
	l.light_color = Color(0.2, 1.0, 0.65)
	l.light_energy = 9.0
	l.omni_range = 6.5
	l.shadow_enabled = false
	add_child(l)
	l.global_position = global_position + Vector3.UP * 0.8
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_kill.bind(l))

func _kill(n: Node):
	if is_instance_valid(n):
		n.queue_free()

func set_custom_color(color: Color):
	# recolor body/plate only, keep neon rim readable
	for child in get_children():
		if child is MeshInstance3D and child.name in ["BaseBox", "TopPlate"]:
			var mat = child.get_active_material(0)
			if mat:
				var new_mat = mat.duplicate()
				new_mat.albedo_color = color
				child.set_surface_override_material(0, new_mat)

func _physics_process(_delta):
	# keep the boost cache small
	if _last_boost.size() > 64:
		_last_boost.clear()
