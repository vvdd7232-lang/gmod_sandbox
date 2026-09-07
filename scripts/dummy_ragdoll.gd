extends Node3D

func _ready():
	# Register root or let child props be registered
	GameManager.register_prop(self)

func on_grabbed():
	pass

func unfreeze_prop():
	for child in get_children():
		if child is RigidBody3D and child.has_method("unfreeze_prop"):
			child.unfreeze_prop()

func freeze_prop():
	for child in get_children():
		if child is RigidBody3D and child.has_method("freeze_prop"):
			child.freeze_prop()

func set_custom_color(color: Color):
	for child in get_children():
		if child is RigidBody3D and child.has_method("set_custom_color"):
			child.set_custom_color(color)
