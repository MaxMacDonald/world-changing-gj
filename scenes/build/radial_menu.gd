class_name RadialMenu extends Control
## A ring of clickable slots drawn around a point. Lives on a CanvasLayer.
##
## open() takes an array of entry dictionaries (one per slot):
##   "label"   : String  - shown in the centre when hovered
##   "cost"    : int     - shown under the slot (-1 = no cost)
##   "price_text": String - shown under the slot in green instead of a cost (e.g. "+42")
##   "angle"   : float   - position on the ring in radians (0 = right, PI/2 = bottom).
##                         Slots without one are spaced evenly starting from the top.
##   "icon"    : Texture2D (optional)
##   "glyph"   : String  - short text drawn instead of an icon (optional)
##   "enabled" : bool    - can it be clicked?
##   "note"    : String  - small text in the centre when hovered (optional)

signal entry_selected(index: int)

const RING_RADIUS := 100.0
const SLOT_RADIUS := 40.0

var _center := Vector2.ZERO
var _entries: Array = []
var _hover := -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hide()

func is_open() -> bool:
	return visible

func open(screen_pos: Vector2, entries: Array) -> void:
	_entries = entries
	# Keep the whole ring on screen.
	var margin := RING_RADIUS + SLOT_RADIUS + 24.0
	var vp := get_viewport_rect().size
	_center = Vector2(clampf(screen_pos.x, margin, vp.x - margin), clampf(screen_pos.y, margin, vp.y - margin))
	_hover = _slot_at(get_local_mouse_position())
	show()
	queue_redraw()

func close() -> void:
	hide()

func _slot_pos(i: int) -> Vector2:
	var angle: float = _entries[i].get("angle", -PI / 2.0 + TAU * i / _entries.size())
	return _center + Vector2.from_angle(angle) * RING_RADIUS

func _slot_at(pos: Vector2) -> int:
	for i in _entries.size():
		if pos.distance_to(_slot_pos(i)) <= SLOT_RADIUS:
			return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _slot_at(event.position)
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var i := _slot_at(event.position)
			if i == -1:
				close()
			elif _entries[i].get("enabled", false):
				close()
				entry_selected.emit(i)
		else:
			close()
		accept_event()

func _text(pos: Vector2, width: float, text: String, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, 5, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)

func _draw() -> void:
	if _entries.is_empty():
		return

	draw_arc(_center, RING_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.6), 20)

	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var p := _slot_pos(i)
		var enabled: bool = e.get("enabled", false)

		var fill := Color(0.12, 0.12, 0.16, 0.55)
		if enabled:
			fill = Color(0.32, 0.45, 0.68, 0.95) if i == _hover else Color(0.15, 0.15, 0.22, 0.92)
		draw_circle(p, SLOT_RADIUS, fill)
		draw_arc(p, SLOT_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.9 if enabled else 0.3), 2.0, true)

		var tint := Color(1, 1, 1, 1.0 if enabled else 0.4)
		var icon: Texture2D = e.get("icon")
		if icon:
			var size_factor: float = e.get("icon_size", 1.3)
			var sc := (SLOT_RADIUS * size_factor) / maxf(icon.get_width(), icon.get_height())
			var s := icon.get_size() * sc
			draw_texture_rect(icon, Rect2(p - s / 2.0, s), false, tint)
		elif e.get("glyph", "") != "":
			var glyph: String = e.glyph
			var gsize := 36 if glyph.length() <= 2 else 24
			_text(p + Vector2(-SLOT_RADIUS, gsize / 3.0), SLOT_RADIUS * 2.0, glyph, gsize, tint)

		var cost: int = e.get("cost", -1)
		var price_text: String = e.get("price_text", "")
		if price_text != "":
			_text(p + Vector2(-SLOT_RADIUS, SLOT_RADIUS + 20), SLOT_RADIUS * 2.0, price_text, 18, Color(0.5, 1.0, 0.5))
		elif cost >= 0:
			var cost_color := Color(1, 0.85, 0.3) if enabled else Color(1, 0.4, 0.4)
			_text(p + Vector2(-SLOT_RADIUS, SLOT_RADIUS + 20), SLOT_RADIUS * 2.0, str(cost), 18, cost_color)

	if _hover != -1:
		var h: Dictionary = _entries[_hover]
		_text(_center + Vector2(-70, 0), 140.0, h.get("label", ""), 18, Color.WHITE)
		var note: String = h.get("note", "")
		if note != "":
			_text(_center + Vector2(-70, 20), 140.0, note, 14, Color(1, 0.7, 0.5))
