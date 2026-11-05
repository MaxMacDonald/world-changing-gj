class_name BuildController extends Node
## Handles everything the player does with the mouse to build:
##
##   IDLE       Right click: open the radial menu.
##   PLACING    A ghost tower follows the mouse. Left click places it, right click / Esc cancels.
##   TERRAFORM  Left click (or drag) raises terrain, right click (or drag) lowers it. Esc exits.

signal tower_placed(tower: Tower)

const CATALOG = preload("res://scenes/build/tower_catalog.gd")

enum Mode { IDLE, PLACING, TERRAFORM }

## Towers can't be placed closer than this to another tower (or the homebase).
@export var min_tower_spacing := 48.0
## If true, you stay in placement mode after placing (while you can afford it).
@export var keep_placing := false
## Towers snap to the centre of terrain cells.
@export var snap_towers_to_grid := true

var wallet: Wallet
var tower_container: Node
var terrain: TerrainGrid

var _mode := Mode.IDLE
var _menu: RadialMenu
var _hint: Label
var _ghost: TowerGhost
var _placing: Dictionary = {}

var _paint_button := 0          # which mouse button is currently painting terrain (0 = none)
var _paint_last_pos := Vector2.ZERO
var _stroke: Dictionary = {}    # cells already changed during the current drag
var _message := ""
var _message_time := 0.0

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_menu = RadialMenu.new()
	layer.add_child(_menu)
	_menu.entry_selected.connect(_on_menu_entry_selected)

	_hint = Label.new()
	layer.add_child(_hint)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -100.0
	_hint.offset_bottom = -20.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.hide()

func setup(new_wallet: Wallet, new_tower_container: Node, new_terrain: TerrainGrid) -> void:
	wallet = new_wallet
	tower_container = new_tower_container
	terrain = new_terrain

# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	
	if _mode == Mode.TERRAFORM:
		
		_terraform_input(event)
		return

	if event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if _mode == Mode.PLACING:
				_cancel_placement()
			else:
				_open_menu(event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and _mode == Mode.PLACING:
			_try_place()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if _mode == Mode.PLACING:
			_cancel_placement()
		elif _menu.is_open():
			_menu.close()

func _process(delta: float) -> void:
	_message_time = maxf(0.0, _message_time - delta)
	match _mode:
		Mode.PLACING:
			_update_ghost()
		Mode.TERRAFORM:
			_update_terraform_hover()

# ------------------------------------------------------------------ radial menu

func _open_menu(screen_pos: Vector2) -> void:
	var entries: Array = []
	for i in CATALOG.MAX_SLOTS:
		if i < CATALOG.TOWERS.size():
			var t: Dictionary = CATALOG.TOWERS[i]
			var affordable := wallet.can_afford(t.cost)
			entries.append({
				"label": t.name,
				"cost": t.cost,
				"icon": t.get("icon"),
				"enabled": affordable,
				"note": "" if affordable else "Not enough gold",
			})
		else:
			entries.append({"label": "Empty slot", "enabled": false})
	entries.append({"label": "Terraform", "glyph": "T", "enabled": terrain != null})
	_menu.open(screen_pos, entries)

func _on_menu_entry_selected(index: int) -> void:
	if index < CATALOG.MAX_SLOTS:
		_start_placement(CATALOG.TOWERS[index])
	else:
		_enter_terraform()

# ------------------------------------------------------------------ tower placement

func _start_placement(def: Dictionary) -> void:
	_cancel_placement()
	_mode = Mode.PLACING
	_placing = def
	_ghost = TowerGhost.new()
	add_child(_ghost)
	_ghost.setup(def.scene.instantiate() as Tower)
	if terrain:
		terrain.set_overlay(true)
	_hint.show()
	_update_ghost()

func _cancel_placement() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_placing = {}
	if _mode == Mode.PLACING:
		_mode = Mode.IDLE
		_hint.hide()
		if terrain:
			terrain.set_overlay(false)

func _placement_position() -> Vector2:
	var mouse := _ghost.get_global_mouse_position()
	if snap_towers_to_grid and terrain:
		var cell := terrain.world_to_cell(mouse)
		if terrain.in_bounds(cell):
			return terrain.cell_to_world(cell)
	return mouse

func _update_ghost() -> void:
	var pos := _placement_position()
	_ghost.global_position = pos
	var valid := _can_place(pos)
	_ghost.set_valid(valid)
	var hill_bonus := 1.0
	if terrain:
		hill_bonus = terrain.range_multiplier_at(pos)
	_ghost.set_range_multiplier(hill_bonus)

	var text := "Left click: place (%d gold)    Right click / Esc: cancel" % _placing.cost
	if not valid:
		text = "Can't build here"
	elif hill_bonus > 1.0:
		text += "\nHill: +%d%% range" % roundi((hill_bonus - 1.0) * 100.0)
	_hint.text = text

func _can_place(pos: Vector2) -> bool:
	if terrain and not terrain.can_build_tower_at(pos):
		return false
	for t in get_tree().get_nodes_in_group("towers"):
		if t.global_position.distance_to(pos) < min_tower_spacing:
			return false
	return true

func _try_place() -> void:
	var pos := _ghost.global_position
	if not _can_place(pos):
		return
	if not wallet.spend(_placing.cost):
		_cancel_placement()
		return

	var tower := _placing.scene.instantiate() as Tower
	tower_container.add_child(tower)
	tower.global_position = pos
	tower.update_range() # pick up the hill bonus for its final position
	tower_placed.emit(tower)

	if not (keep_placing and wallet.can_afford(_placing.cost)):
		_cancel_placement()

# ------------------------------------------------------------------ terraforming

func _enter_terraform() -> void:
	_cancel_placement()
	_mode = Mode.TERRAFORM
	_paint_button = 0
	_hint.show()
	_update_terraform_hover()

func _exit_terraform() -> void:
	_mode = Mode.IDLE
	_paint_button = 0
	_stroke.clear()
	_hint.hide()
	terrain.set_overlay(false)

func _terraform_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		if event.pressed:
			_paint_button = event.button_index
			_stroke.clear()
			_paint_last_pos = terrain.get_global_mouse_position()
			_paint_cell(terrain.world_to_cell(_paint_last_pos))
		elif event.button_index == _paint_button:
			_paint_button = 0
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _paint_button != 0:
		# Walk the cells between the last and current mouse position so fast drags don't skip any.
		var pos := terrain.get_global_mouse_position()
		var steps := maxi(1, ceili(_paint_last_pos.distance_to(pos) / (terrain.cell_size * 0.5)))
		for s in range(1, steps + 1):
			_paint_cell(terrain.world_to_cell(_paint_last_pos.lerp(pos, float(s) / steps)))
		_paint_last_pos = pos
	elif event.is_action_pressed("ui_cancel"):
		_exit_terraform()

func _paint_cell(cell: Vector2i) -> void:
	if _stroke.has(cell):
		return
	_stroke[cell] = true
	if _paint_button == MOUSE_BUTTON_LEFT:
		_raise(cell)
	else:
		_lower(cell)

func _raise(cell: Vector2i) -> void:
	var reason := terrain.check_raise(cell)
	if reason != "":
		_flash(reason)
		return
	var cost := terrain.get_raise_cost(cell)
	if not wallet.spend(cost):
		_flash("Not enough gold (need %d)" % cost)
		return
	terrain.raise_cell(cell)

func _lower(cell: Vector2i) -> void:
	if not terrain.can_lower(cell):
		return
	var refund := terrain.get_lower_refund(cell)
	terrain.lower_cell(cell)
	if refund > 0:
		wallet.add(refund)

func _flash(message: String) -> void:
	_message = message
	_message_time = 1.5

func _update_terraform_hover() -> void:
	var cell := terrain.world_to_cell(terrain.get_global_mouse_position())
	var reason := terrain.check_raise(cell)
	var cost := terrain.get_raise_cost(cell)
	var can_raise := reason == "" and wallet.can_afford(cost)
	terrain.set_overlay(true, cell, can_raise)

	var info := reason
	if reason == "":
		info = "Raise to +%d: %d gold" % [terrain.get_height(cell) + 1, cost]
		if not wallet.can_afford(cost):
			info += "  (not enough gold)"
	if terrain.can_lower(cell):
		info += "    |    Lower: +%d gold" % terrain.get_lower_refund(cell)
	if _message_time > 0.0:
		info = _message
	_hint.text = "TERRAFORM   Left click: raise    Right click: lower    Esc: exit\n" + info
