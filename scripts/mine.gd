extends "res://scripts/prop.gd"

@export var fuse_time: float = 1.1
@export var trigger_range: float = 1.5

var armed: bool = false
var _arm_timer: float = 0.0

func _ready():
	super._ready()
	prop_name = "Proximity Mine"

func _physics_process(delta):
	if not armed:
		_arm_timer += delta
		if _arm_timer >= fuse_time:
			armed = true
		return

	if freeze:
		# frozen mines are disarmed (use physgun R or just dont grab)
		return

	# blink warning LED while armed
	var led = get_node_or_null("Led")
	if is_instance_valid(led):
		led.visible = fmod(Time.get_ticks_msec() * 0.006, 1.0) > 0.4

	# Player proximity trigger
	if is_instance_valid(GameManager.player):
		var d: float = GameManager.player.global_position.distance_to(global_position)
		if d < trigger_range:
			explode()
			return

	# Fast props bumping into it (falling crates, thrown stuff)
	var props = get_tree().get_nodes_in_group("props")
	for p in props:
		if not is_instance_valid(p) or p == self:
			continue
		if p is RigidBody3D and p.linear_velocity.length() > 4.5:
			if p.global_position.distance_to(global_position) < trigger_range * 0.7:
				explode()
				return
