extends "res://scripts/prop.gd"

@export var wind_power: float = 26.0
@export var wind_range: float = 9.0

@onready var rotor: Node3D = $Rotor

func _ready():
	super._ready()
	prop_name = "Industrial Fan"

func _process(delta):
	if freeze:
		return
	# spin the blades (visual)
	if is_instance_valid(rotor):
		rotor.rotate_z(delta * 26.0)

func _physics_process(delta):
	if freeze:
		return
	# airflow blows along -Z (out of the front of the fan)
	var origin: Vector3 = global_position
	var fwd: Vector3 = -global_transform.basis.z
	var props = get_tree().get_nodes_in_group("props")
	for p in props:
		if not is_instance_valid(p) or p == self:
			continue
		if not (p is RigidBody3D):
			continue
		var rel: Vector3 = p.global_position - origin
		var dist: float = rel.length()
		if dist > wind_range or dist < 0.01:
			continue
		if rel.normalized().dot(fwd) < 0.25:
			continue
		var falloff: float = 1.0 - dist / wind_range
		# wind force scales with mass so every object feels the same push
		p.apply_central_force(fwd * wind_power * falloff * p.mass)
