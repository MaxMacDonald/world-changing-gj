class_name Tutorial extends CanvasLayer
## A short guided tutorial that runs on the real level before the first wave.
##
## The player uses the real controls. This node just shows a hint panel and watches for the
## action each step asks for (steps are listed in tutorial_steps.gd). A Skip button is always
## available. Add this script to a CanvasLayer in the level and call start() (see level_1.gd).

## Emitted when the tutorial is completed or skipped. The level starts the waves after this.
signal finished

const STEPS = preload("res://scenes/ui/tutorial_steps.gd")
const CATALOG = preload("res://scenes/build/tower_catalog.gd")

## Becomes true once the tutorial has been completed or skipped, so restarting the level
## (or returning to the menu and pressing Start) doesn't replay it.
static var shown_this_session := false
## Set to true (for example from a "How to Play" button) to show the tutorial next time
## the level loads, even if it was already shown.
static var force_next := false

## Untick to turn the tutorial off completely (handy while testing).
@export var enabled := true
## Seconds the "Nice!" confirmation shows before the next step.
@export var success_delay := 0.7

var _homebase: Homebase
var _spawn_root: Node
var _builder: BuildController
var _terrain: TerrainGrid
var _wallet: Wallet

var _running := false
var _busy := false           # a step was just completed; waiting to move on
var _index := -1
var _wait := ""

var _panel: PanelContainer
var _title: Label
var _body: Label
var _continue_button: Button
var _skip_button: Button
var _next_timer: Timer
var _highlights: Highlights

func _ready() -> void:
	layer = 5   # above the HUD, below the radial menu / pause / victory screens
	_build_ui()
	hide()

## True if the tutorial should be shown for this level load.
func should_run() -> bool:
	return enabled and (force_next or not shown_this_session)

func start(homebase: Homebase, spawn_points_root: Node, builder: BuildController, terrain: TerrainGrid, wallet: Wallet) -> void:
	_homebase = homebase
	_spawn_root = spawn_points_root
	_builder = builder
	_terrain = terrain
	_wallet = wallet
	_running = true
	force_next = false

	_builder.tower_placed.connect(func(_t): _try_complete("tower_placed"))
	_builder.tower_selected.connect(func(_t): _try_complete("tower_selected"))
	_builder.tower_upgraded.connect(func(_t, _stat): _try_complete("tower_upgraded"))
	_builder.terraform_exited.connect(func(): _try_complete("terraform_exit"))
	_terrain.cell_height_changed.connect(_on_cell_height_changed)

	show()
	_goto(0)

# ------------------------------------------------------------------ steps

func _goto(index: int) -> void:
	if not _running:
		return
	if index >= STEPS.STEPS.size():
		_finish()
		return
	_index = index
	_busy = false
	var step: Dictionary = STEPS.STEPS[index]
	_wait = step.wait

	var min_gold: int = step.get("min_gold", 0)
	if min_gold > 0 and _wallet.money < min_gold:
		_wallet.set_amount(min_gold)

	_title.text = "%d/%d   %s" % [index + 1, STEPS.STEPS.size(), step.title]
	_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	_body.text = _format(step.text)
	_continue_button.visible = _wait == "continue"
	_continue_button.text = step.get("button", "Continue")
	_set_highlights(step.get("highlight", []))

	# Nothing to do if the player already did it (e.g. built a wall early).
	if _already_done(_wait):
		_goto(index + 1)

func _already_done(wait: String) -> bool:
	match wait:
		"wall":
			for y in _terrain.grid_size.y:
				for x in _terrain.grid_size.x:
					if _terrain.get_height(Vector2i(x, y)) >= 2:
						return true
		"terraform_exit":
			return not _builder.is_terraforming()
	return false

func _try_complete(kind: String) -> void:
	if not _running or _busy or _wait != kind:
		return
	_busy = true
	_title.text = "Nice!"
	_title.add_theme_color_override("font_color", Color(0.45, 1.0, 0.5))
	_set_highlights([])
	_next_timer.start(maxf(success_delay, 0.01))

func _on_cell_height_changed(_cell: Vector2i, from_height: int, to_height: int) -> void:
	if to_height > from_height:
		_try_complete("raise")
	if to_height == 2:
		_try_complete("wall")

func _on_continue_pressed() -> void:
	if _running and _wait == "continue" and not _busy:
		_goto(_index + 1)

func _on_skip_pressed() -> void:
	_finish()

func _finish() -> void:
	if not _running:
		return
	_running = false
	shown_this_session = true
	force_next = false
	_next_timer.stop()
	_builder.cancel_everything()                       # leave terraform / placement / selection
	_wallet.set_amount(_wallet.starting_money)         # back to the normal starting gold
	hide()
	finished.emit()
	queue_free()

# ------------------------------------------------------------------ text, highlights

func _format(text: String) -> String:
	var values := {"c1": 20, "c2": 40, "tower": 60, "tower_name": "tower"}
	if _terrain and _terrain.raise_costs.size() >= 2:
		values.c1 = _terrain.raise_costs[0]
		values.c2 = _terrain.raise_costs[1]
	if CATALOG.TOWERS.size() > 0:
		values.tower = CATALOG.TOWERS[0].cost
		values.tower_name = CATALOG.TOWERS[0].name
	return text.format(values)

func _set_highlights(names: Array) -> void:
	var items: Array = []
	for n in names:
		match n:
			"base":
				items.append({"pos": _homebase.global_position, "radius": 56.0, "label": "Your base"})
			"spawns":
				for sp in _spawn_root.get_children():
					if sp is Node2D:
						items.append({"pos": sp.global_position, "radius": 64.0, "label": "Enemies come from here"})
	_highlights.items = items
	_highlights.queue_redraw()

# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	_highlights = Highlights.new()
	add_child(_highlights)

	_next_timer = Timer.new()
	_next_timer.one_shot = true
	_next_timer.timeout.connect(func(): _goto(_index + 1))
	add_child(_next_timer)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.12, 0.94)
	style.border_color = Color(1.0, 0.85, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(660, 0)
	add_child(_panel)
	# Top-right corner: clear of the HUD (top-left) and the base / spawn points it points out.
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.offset_right = -24.0
	_panel.offset_left = -24.0 - 660.0
	_panel.offset_top = 16.0

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	box.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(616, 0)
	_body.add_theme_font_size_override("font_size", 22)
	box.add_child(_body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	_continue_button = Button.new()
	_continue_button.custom_minimum_size = Vector2(180, 44)
	_continue_button.add_theme_font_size_override("font_size", 24)
	_continue_button.pressed.connect(_on_continue_pressed)
	row.add_child(_continue_button)

	_skip_button = Button.new()
	_skip_button.text = "Skip tutorial"
	_skip_button.custom_minimum_size = Vector2(150, 44)
	_skip_button.add_theme_font_size_override("font_size", 20)
	_skip_button.pressed.connect(_on_skip_pressed)
	row.add_child(_skip_button)

## Pulsing rings with labels, drawn over the world (used to point out the base and spawns).
class Highlights extends Node2D:
	var items: Array = []   # {pos (world), radius, label}
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		if not items.is_empty():
			queue_redraw()

	func _draw() -> void:
		var xf := get_viewport().get_canvas_transform()
		var font := ThemeDB.fallback_font
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		for it in items:
			var p: Vector2 = xf * it.pos
			var r: float = it.radius
			draw_arc(p, r + pulse * 8.0, 0.0, TAU, 48, Color(1.0, 0.9, 0.3, 0.95), 4.0)
			draw_arc(p, r + 14.0 + pulse * 14.0, 0.0, TAU, 48, Color(1.0, 0.9, 0.3, 0.55 * (1.0 - pulse) + 0.1), 3.0)
			var at := p + Vector2(-110.0, -r - 26.0)
			draw_string_outline(font, at, it.label, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 22, 6, Color.BLACK)
			draw_string(font, at, it.label, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 22, Color.WHITE)
