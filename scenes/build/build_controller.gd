class_name BuildController extends Node
## Handles everything the player does with the mouse to build:
##
##   IDLE       Right click empty ground: build menu. Click a tower: select it (shows its range)
##              and open its upgrade / sell menu.
##   PLACING    A ghost tower follows the mouse. Left click places it, right click / Esc cancels.
##   TERRAFORM  Left click (or drag) raises terrain, right click (or drag) lowers it. Esc exits.

signal tower_placed(tower: Tower)
signal tower_selected(tower: Tower)
signal tower_upgraded(tower: Tower, stat: String)
signal terraform_exited

const CATALOG = preload("res://scenes/build/tower_catalog.gd")

enum Mode { IDLE, PLACING, TERRAFORM }

## Towers can't be placed closer than this to another tower (or the homebase).
@export var min_tower_spacing := 48.0
## If true, you stay in placement mode after placing (while you can afford it).
@export var keep_placing := false
## Towers snap to the centre of terrain cells.
@export var snap_towers_to_grid := true
## How close (px) a click must be to a tower to select it.
@export var tower_pick_radius := 30.0
## Size of the radial menu (build wheel and tower upgrade wheel). 1.0 = full size.
@export_range(0.4, 1.5, 0.05) var wheel_scale := 0.65
## After buying an upgrade, show the tower's wheel again so you can keep upgrading.
@export var reopen_menu_after_upgrade := true


var wallet: Wallet
var tower_container: Node
var terrain: TerrainGrid

var _mode := Mode.IDLE
var _menu: RadialMenu
var _menu_context := "build"    # "build" or "tower": which options the wheel is showing
var _menu_pos := Vector2.ZERO
var _selected: Tower
var _range_indicator: RangeIndicator
var _hint: Label
var _ghost: TowerGhost
var _placing: Dictionary = {}

var _paint_button := 0          # which mouse button is currently painting terrain (0 = none)
var _erase_mode: bool = false
var _paint_last_pos := Vector2.ZERO
var _stroke: Dictionary = {}    # cells already changed during the current drag
var _message := ""
var _message_time := 0.0

func _ready() -> void:
	add_to_group("build_controller")
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_range_indicator = RangeIndicator.new()
	add_child(_range_indicator)

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


func is_terraforming() -> bool:
	return _mode == Mode.TERRAFORM

## Closes the wheel and leaves any placement / terraform / selection state.
func cancel_everything() -> void:
	_menu.close()
	_cancel_placement()
	_deselect()
	if _mode == Mode.TERRAFORM:
		_exit_terraform()

## True while Esc should cancel something here (placing, terraforming, radial menu)
## rather than open the pause menu.
func is_busy() -> bool:
	return _mode != Mode.IDLE or _selected != null or (_menu != null and _menu.is_open())

# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	
	if _mode == Mode.TERRAFORM:
		
		_terraform_input(event)
		return

	if event is InputEventMouseButton and event.pressed:
		var left: bool = event.button_index == MOUSE_BUTTON_LEFT
		var right: bool = event.button_index == MOUSE_BUTTON_RIGHT
		if _mode == Mode.PLACING:
			if right:
				_cancel_placement()
				get_viewport().set_input_as_handled()
			elif left:
				_try_place()
				get_viewport().set_input_as_handled()
		elif left or right:
			var tower := _tower_at(get_viewport().get_canvas_transform().affine_inverse() * event.position)
			if tower:
				_select(tower)
				_open_tower_menu(event.position)
				get_viewport().set_input_as_handled()
			elif right:
				_deselect()
				_open_menu(event.position)
				get_viewport().set_input_as_handled()
			else:
				_deselect()
	elif event.is_action_pressed("ui_cancel"):
	# Only consume Esc if there is something to cancel; otherwise the pause menu gets it.
		if _mode == Mode.PLACING:
			_cancel_placement()
			get_viewport().set_input_as_handled()
		elif _menu.is_open():
			_menu.close()
			get_viewport().set_input_as_handled()
		elif _selected != null:
			_deselect()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_message_time = maxf(0.0, _message_time - delta)

	if _selected != null and not is_instance_valid(_selected):
		_selected = null
	if _selected != null:
		_range_indicator.show_for(_selected.global_position, _selected.get_range())
	else:
		_range_indicator.hide()

	match _mode:
		Mode.PLACING:
			_update_ghost()
		Mode.TERRAFORM:
			_update_terraform_hover()

# ------------------------------------------------------------------ radial menu

func _open_menu(screen_pos: Vector2) -> void:
	_menu_context = "build"
	_menu_pos = screen_pos
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
	if _menu_context == "tower":
		_on_tower_menu_selected(index)
	elif index < CATALOG.MAX_SLOTS:
		_start_placement(CATALOG.TOWERS[index])
	else:
		_enter_terraform()

# ------------------------------------------------------------------ selecting, upgrading, selling

## The catalog entry a placed tower was built from ({} if it isn't a catalog tower).
func _def_for(tower: Tower) -> Dictionary:
	for def: Dictionary in CATALOG.TOWERS:
		if def.scene.resource_path == tower.scene_file_path:
			return def
	return {}

## The nearest selectable tower to a world position (the homebase can't be selected).
func _tower_at(world_pos: Vector2) -> Tower:
	var best: Tower = null
	var best_dist := tower_pick_radius
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Homebase or t.is_ghost or _def_for(t).is_empty():
			continue
		var d: float = t.global_position.distance_to(world_pos)
		if d <= best_dist:
			best = t
			best_dist = d
	return best

func _select(tower: Tower) -> void:
	# Towers that were already in the level (not built through this controller) get
	# their upgrade data and sell value filled in the first time they are selected.
	var def := _def_for(tower)
	if tower.upgrade_defs.is_empty():
		tower.upgrade_defs = def.get("upgrades", [])
	if tower.invested < 0:
		tower.invested = def.cost
	tower.recompute_stats()
	_selected = tower
	tower_selected.emit(tower)

func _deselect() -> void:
	_selected = null
	_range_indicator.hide()

func _sell_value(tower: Tower) -> int:
	return floori(maxi(tower.invested, 0) * CATALOG.SELL_RATIO)

func _upgrade_text(u: Dictionary) -> String:
	if u.has("description"):
		return u.description
	match u.stat:
		"damage":
			return "+%d damage" % roundi(u.per_level)
		"fire_rate":
			return "+%d%% fire rate" % roundi(u.per_level * 100.0)
		"range":
			return "+%d%% range" % roundi(u.per_level * 100.0)
	return ""

## Upgrades are spread around the wheel and Sell is always at the bottom.
func _open_tower_menu(screen_pos: Vector2) -> void:
	if _selected == null:
		return
	_menu_context = "tower"
	_menu_pos = screen_pos
	var upgrades: Array = _tower_upgrades(_selected)
	var step := TAU / (upgrades.size() + 1)
	var entries: Array = []
	for i in upgrades.size():
		var u: Dictionary = upgrades[i]
		var level := _selected.get_upgrade_level(u.stat)
		var max_level: int = u.costs.size()
		var entry := {
			"label": "%s  %d/%d" % [u.name, level, max_level],
			"glyph": u.get("glyph", u.name.left(3).to_upper()),
			"angle": PI / 2.0 + step * (i + 1), # clockwise from the bottom: left, top, right...
		}
		if level >= max_level:
			entry["enabled"] = false
			entry["note"] = "Max level"
		else:
			var cost: int = u.costs[level]
			var affordable := wallet.can_afford(cost)
			entry["cost"] = cost
			entry["enabled"] = affordable
			entry["note"] = _upgrade_text(u) if affordable else "Not enough gold"
		entries.append(entry)
	var refund := _sell_value(_selected)
	entries.append({
		"label": "Sell",
		"glyph": "$",
		"price_text": "+%d" % refund,
		"enabled": true,
		"note": "Refund %d gold" % refund,
		"angle": PI / 2.0,
	})

	_menu.open(screen_pos, entries)

func _tower_upgrades(tower: Tower) -> Array:
	var all: Array = _def_for(tower).get("upgrades", [])
	return all.slice(0, CATALOG.MAX_UPGRADES)

func _on_tower_menu_selected(index: int) -> void:
	if _selected == null or not is_instance_valid(_selected):
		return
	var upgrades := _tower_upgrades(_selected)
	if index < upgrades.size():
		if _buy_upgrade(upgrades[index]) and reopen_menu_after_upgrade:
			_open_tower_menu(_menu_pos)
	else:
		_sell_selected()

func _buy_upgrade(u: Dictionary) -> bool:
	var level := _selected.get_upgrade_level(u.stat)
	if level >= u.costs.size():
		return false
	var cost: int = u.costs[level]
	if not wallet.spend(cost):
		return false
	_selected.upgrade_levels[u.stat] = level + 1
	_selected.invested += cost
	_selected.recompute_stats()
	Sound.play("money_spent")
	tower_upgraded.emit(_selected, u.stat)
	return true

func _sell_selected() -> void:
	wallet.add(_sell_value(_selected))
	_selected.remove_from_group("towers") # stop counting it immediately (queue_free is deferred)
	Sound.play("money_receive")
	_selected.queue_free()
	_deselect()


# ------------------------------------------------------------------ tower placement

func _start_placement(def: Dictionary) -> void:
	_deselect()
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
	tower.upgrade_defs = _placing.get("upgrades", [])
	tower.invested = _placing.cost
	tower.recompute_stats() # also picks up the hill bonus for its final position
	tower_placed.emit(tower)
	Sound.play("construct_tower")

	if not (keep_placing and wallet.can_afford(_placing.cost)):
		_cancel_placement()

# ------------------------------------------------------------------ terraforming

func _enter_terraform() -> void:
	_deselect()
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
	terraform_exited.emit()

func _terraform_input(event: InputEvent) -> void:
	_erase_mode = event.shift_pressed if event is InputEventWithModifiers else Input.is_key_pressed(KEY_SHIFT)
	print(_erase_mode)
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT):
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
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_exit_terraform()
		
	

func _paint_cell(cell: Vector2i) -> void:
	if _stroke.has(cell):
		return
	_stroke[cell] = true
	if _paint_button == MOUSE_BUTTON_LEFT and _erase_mode == false:
		_raise(cell)
	elif _erase_mode == true:
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
	Sound.play("construct_terrain", 0.0, 0.1)

func _lower(cell: Vector2i) -> void:
	if not terrain.can_lower(cell):
		return
	var refund := terrain.get_lower_refund(cell)
	terrain.lower_cell(cell)
	Sound.play("construct_terrain", -4.0, 0.1)
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
	_hint.text = "TERRAFORM   Left Click: raise    L-Shift + Left Click: lower    Right Click: exit\n" + info
