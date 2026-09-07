extends Node

signal weapon_changed(weapon_index)
signal spawn_menu_toggled(is_open)
signal prop_spawned(prop)

var spawned_props: Array = []
var active_weapon_index: int = 1 # 1: Physgun, 2: Toolgun, 3: Gravity Gun
var is_spawn_menu_open: bool = false
var player: Node3D = null

# Current Toolgun settings
var toolgun_mode: String = "weld" # weld, thruster, color, balloon, remover
var toolgun_color: Color = Color.RED
var toolgun_thruster_force: float = 15.0
var toolgun_balloon_force: float = 12.0

func register_prop(prop: Node3D):
	if not spawned_props.has(prop):
		spawned_props.append(prop)
		prop.tree_exiting.connect(func(): spawned_props.erase(prop))
		emit_signal("prop_spawned", prop)

func clear_all_props():
	var copy = spawned_props.duplicate()
	for prop in copy:
		if is_instance_valid(prop):
			prop.queue_free()
	spawned_props.clear()

func set_active_weapon(index: int):
	if active_weapon_index != index:
		active_weapon_index = index
		emit_signal("weapon_changed", active_weapon_index)

func toggle_spawn_menu():
	is_spawn_menu_open = not is_spawn_menu_open
	emit_signal("spawn_menu_toggled", is_spawn_menu_open)
	
	if is_spawn_menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
