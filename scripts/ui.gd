extends CanvasLayer

@onready var hud_panel = $HUD
@onready var crosshair = $HUD/Crosshair
@onready var health_label = $HUD/BottomLeft/HealthLabel
@onready var weapon_label = $HUD/BottomLeft/WeaponLabel
@onready var tool_info_label = $HUD/BottomLeft/ToolInfoLabel

@onready var spawn_menu = $SpawnMenu
@onready var props_grid = $SpawnMenu/MainPanel/PropsGrid
@onready var entities_grid = $SpawnMenu/MainPanel/EntitiesGrid
@onready var tools_panel = $SpawnMenu/MainPanel/ToolsPanel
@onready var env_panel = $SpawnMenu/MainPanel/EnvPanel

@onready var tab_props = $SpawnMenu/Sidebar/PropsTab
@onready var tab_entities = $SpawnMenu/Sidebar/EntitiesTab
@onready var tab_tools = $SpawnMenu/Sidebar/ToolsTab
@onready var tab_env = $SpawnMenu/Sidebar/EnvTab

func _ready():
	spawn_menu.visible = false
	hud_panel.visible = true
	
	$SpawnMenu/Sidebar/ResumeBtn.pressed.connect(func(): GameManager.toggle_spawn_menu())
	
	GameManager.spawn_menu_toggled.connect(_on_spawn_menu_toggled)
	GameManager.weapon_changed.connect(_on_weapon_changed)
	
	_setup_props_menu()
	_setup_entities_menu()
	_setup_tools_menu()
	_setup_env_menu()
	
	_show_tab("props")

func _process(delta):
	if is_instance_valid(GameManager.player):
		health_label.text = "HEALTH: 100"
		
	if GameManager.active_weapon_index == 2:
		tool_info_label.visible = true
		tool_info_label.text = "Mode: " + GameManager.toolgun_mode.to_upper()
	else:
		tool_info_label.visible = false

func _on_weapon_changed(index: int):
	var w_name = "PHYSGUN"
	if index == 2: w_name = "TOOLGUN"
	elif index == 3: w_name = "GRAVITY GUN"
	weapon_label.text = "WEAPON: " + w_name

func _on_spawn_menu_toggled(is_open: bool):
	spawn_menu.visible = is_open
	crosshair.visible = not is_open

func _show_tab(tab_name: String):
	props_grid.visible = (tab_name == "props")
	entities_grid.visible = (tab_name == "entities")
	tools_panel.visible = (tab_name == "tools")
	env_panel.visible = (tab_name == "env")

# Setup prop spawning
func _setup_props_menu():
	tab_props.pressed.connect(func(): _show_tab("props"))
	
	var prop_list = [
		{"name": "Wooden Crate", "path": "res://objects/crate.tscn"},
		{"name": "Metal Barrel", "path": "res://objects/barrel.tscn"},
		{"name": "Explosive Barrel", "path": "res://objects/explosive_barrel.tscn"},
		{"name": "Bouncy Ball", "path": "res://objects/bouncy_ball.tscn"},
		{"name": "Jump Ramp", "path": "res://objects/ramp.tscn"},
		{"name": "Wooden Plank", "path": "res://objects/plank.tscn"},
		{"name": "Heavy Metal Cube", "path": "res://objects/cube.tscn"},
		{"name": "Ragdoll Dummy", "path": "res://objects/dummy_ragdoll.tscn"},
		{"name": "Traffic Cone", "path": "res://objects/traffic_cone.tscn"},
		{"name": "Beach Ball", "path": "res://objects/beach_ball.tscn"},
		{"name": "Cardboard Box", "path": "res://objects/cardboard_box.tscn"},
		{"name": "Rubber Tire", "path": "res://objects/tire.tscn"},
		{"name": "Metal Pipe", "path": "res://objects/metal_pipe.tscn"}
	]
	
	for item in prop_list:
		var btn = Button.new()
		btn.text = item["name"]
		btn.custom_minimum_size = Vector2(160, 100)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _spawn_item(item["path"]))
		props_grid.add_child(btn)

func _setup_entities_menu():
	tab_entities.pressed.connect(func(): _show_tab("entities"))
	
	var ent_list = [
		{"name": "Automated Turret", "path": "res://objects/turret.tscn"},
		{"name": "Industrial Fan", "path": "res://objects/fan.tscn"},
		{"name": "Launch Pad", "path": "res://objects/bounce_pad.tscn"},
		{"name": "Proximity Mine", "path": "res://objects/mine.tscn"}
	]
	
	for item in ent_list:
		var btn = Button.new()
		btn.text = item["name"]
		btn.custom_minimum_size = Vector2(160, 100)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _spawn_item(item["path"]))
		entities_grid.add_child(btn)

func _spawn_item(path: String):
	if is_instance_valid(GameManager.player):
		var scene = load(path)
		if scene:
			var inst = scene.instantiate()
			get_tree().current_scene.add_child(inst)
			# Spawn 3.5m in front of player
			var spawn_pos = GameManager.player.global_position + Vector3(0, 1.0, 0) - GameManager.player.transform.basis.z * 3.5
			inst.global_position = spawn_pos
			
			# Play spawn sound
			var player = AudioStreamPlayer.new()
			player.stream = preload("res://sounds/toolgun.wav")
			player.pitch_scale = 1.3
			add_child(player)
			player.play()
			player.finished.connect(func(): player.queue_free())

func _setup_tools_menu():
	tab_tools.pressed.connect(func(): _show_tab("tools"))
	
	# Tool mode selections
	var modes = ["weld", "thruster", "balloon", "color", "remover"]
	var vbox = $SpawnMenu/MainPanel/ToolsPanel/ModesVBox
	
	for mode in modes:
		var btn = Button.new()
		btn.text = "Mode: " + mode.to_upper()
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(m=mode): GameManager.toolgun_mode = m)
		vbox.add_child(btn)
		
	# Color selections
	var colors_grid = $SpawnMenu/MainPanel/ToolsPanel/ColorsGrid
	var palette = [
		Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW,
		Color.ORANGE, Color.PURPLE, Color.CYAN, Color.WHITE, Color.DARK_GRAY
	]
	
	for col in palette:
		var cbtn = Button.new()
		cbtn.custom_minimum_size = Vector2(50, 50)
		var style = StyleBoxFlat.new()
		style.bg_color = col
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.WHITE
		cbtn.add_theme_stylebox_override("normal", style)
		cbtn.add_theme_stylebox_override("hover", style)
		cbtn.pressed.connect(func(c=col): GameManager.toolgun_color = c)
		colors_grid.add_child(cbtn)

func _setup_env_menu():
	tab_env.pressed.connect(func(): _show_tab("env"))
	
	var clear_btn = $SpawnMenu/MainPanel/EnvPanel/ClearPropsButton
	clear_btn.pressed.connect(func(): GameManager.clear_all_props())
	
	var time_slider = $SpawnMenu/MainPanel/EnvPanel/TimeSlider
	time_slider.value_changed.connect(_on_time_changed)

func _on_time_changed(val: float):
	# Update sun light
	var sun = get_tree().current_scene.get_node_or_null("Sun")
	if sun and sun is DirectionalLight3D:
		sun.rotation.x = lerp(-PI/8, -PI, val)
