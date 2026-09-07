extends Node3D

@export var balloon_force: float = 15.0
@onready var sphere: MeshInstance3D = $Sphere
@onready var string_mesh: MeshInstance3D = $StringMesh

func _physics_process(delta):
	var parent = get_parent()
	if parent is RigidBody3D:
		parent.unfreeze_prop()
		parent.apply_force(Vector3.UP * balloon_force * parent.mass * 1.5, global_position - parent.global_position)
		
	var time = Time.get_ticks_msec() / 1000.0
	var sway = Vector3(sin(time * 3.0) * 0.3, 2.0, cos(time * 2.5) * 0.3)
	sphere.position = sway
	
	# Point string towards sphere
	string_mesh.position = sway / 2.0
	string_mesh.look_at(global_position + sway, Vector3.UP)
	string_mesh.rotate_x(PI/2)
	string_mesh.scale.y = sway.length()
