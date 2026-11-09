class_name TerrainGrid extends Node2D
## The terraforming grid.
##
## Every cell has a height:
##   +0  flat ground
##   +1  hill  : enemies walk over it slower, towers on it get extra range
##   +2  wall  : enemies can't walk through (they path around, or dig a tunnel when going
##               around would take too long). Blocks projectiles.
##
## A dug +2 cell becomes a TUNNEL: walkable at normal speed, but it still blocks projectiles.
##
## Enemy pathing uses two cost maps (see FlowField):
##   "around"  - walls are impassable
##   "through" - walls can be dug (costs dig_time each)
## An enemy digs when going around takes longer than path_tolerance x going through.

signal terrain_changed
## Fired after a cell's height changes (used by the visuals for animation only).
signal cell_height_changed(cell: Vector2i, from_height: int, to_height: int)
## Fired when an undug wall becomes a tunnel.
signal tunnel_dug(cell: Vector2i)

const MAX_HEIGHT := 2
const FLAG_SPAWN := 1
const FLAG_BASE := 2

@export_group("Grid")
@export var cell_size := 80
## Number of cells. The grid starts at this node's position.
@export var grid_size := Vector2i(24, 13.5)

@export_group("Visuals")
## Animate cells growing and sinking. Off = they change instantly. Sprites are set in terrain_art.gd.
@export var animate := true
@export var entities_root: Node2D

@export_group("Terraforming cost")
## Gold to raise a cell: [0 -> +1, +1 -> +2].
@export var raise_costs: Array[int] = [20, 40]
## Fraction of the raise cost you get back when lowering a cell.
@export_range(0.0, 1.0) var lower_refund_ratio := 0.5

@export_group("Gameplay")
## Enemy speed multiplier while on a +1 hill.
@export_range(0.05, 1.0) var hill_speed_multiplier := 0.5
## Tower range multiplier while on a +1 hill.
@export var hill_range_multiplier := 1
## Enemies dig when going around takes longer than this many times going through.
@export var path_tolerance := 1.5
## Cells within this many pixels of the homebase can't be terraformed.
@export var base_protect_radius := 72.0
## Extra cells around each spawn point that can't be terraformed or built on.
@export var spawn_protect_margin := 1
## An enemy this close (px) to a cell stops it being raised into a wall.
@export var enemy_clearance := 24.0

## Increases on every change. Enemies use this to know when to re-plan.
var version := 0
var goal_cell := Vector2i(-1, -1)

var _height := PackedByteArray()
var _tunnel := PackedByteArray()
var _flags := PackedByteArray()
var _open := PackedByteArray()
var _mult := PackedFloat32Array()

var _fields := {}
var _fields_version := -1

var _visuals: TerrainVisuals
var _overlay: Overlay
var _show_grid := false
var _hover_cell := Vector2i(-1, -1)
var _hover_ok := true

func _ready() -> void:
	add_to_group("terrain")
	var n := grid_size.x * grid_size.y
	_height.resize(n)
	_height.fill(0)
	_tunnel.resize(n)
	_tunnel.fill(0)
	_flags.resize(n)
	_flags.fill(0)
	_open.resize(n)
	_open.fill(1)
	_mult.resize(n)
	_mult.fill(1.0)
	_visuals = TerrainVisuals.new()
	_visuals.animate = animate
	_visuals.entities_root = entities_root
	add_child(_visuals)
	_overlay = Overlay.new()
	_overlay.grid = self
	add_child(_overlay)
	

## Call once from the level: marks the homebase and spawn areas as protected
## and tells the pathfinding where the goal is.
func setup(homebase: Homebase, spawn_points_root: Node) -> void:
	_flags.fill(0)
	var base_pos := homebase.global_position
	goal_cell = world_to_cell(homebase.attack_point.global_position)

	for y in grid_size.y:
		for x in grid_size.x:
			var c := Vector2i(x, y)
			if cell_to_world(c).distance_to(base_pos) <= base_protect_radius:
				_flags[_idx(c)] |= FLAG_BASE
	if in_bounds(goal_cell):
		_flags[_idx(goal_cell)] |= FLAG_BASE

	if spawn_points_root:
		for sp in spawn_points_root.get_children():
			if not sp is Node2D:
				continue
			var rect := Rect2(sp.global_position, Vector2.ZERO)
			for child in sp.get_children():
				if child is CollisionShape2D and child.shape != null:
					if child.shape is RectangleShape2D:
						var size: Vector2 = child.shape.size
						rect = rect.merge(child.global_transform * Rect2(-size / 2.0, size))
					elif child.shape is CircleShape2D:
						var r: float = child.shape.radius
						rect = rect.merge(Rect2(child.global_position - Vector2(r, r), Vector2(r, r) * 2.0))
			var margin := Vector2i(spawn_protect_margin, spawn_protect_margin)
			var c0 := world_to_cell(rect.position) - margin
			var c1 := world_to_cell(rect.end) + margin
			for y in range(c0.y, c1.y + 1):
				for x in range(c0.x, c1.x + 1):
					if in_bounds(Vector2i(x, y)):
						_flags[_idx(Vector2i(x, y))] |= FLAG_SPAWN

	_overlay.queue_redraw()

# ---------------------------------------------------------------- coordinates

func world_to_cell(pos: Vector2) -> Vector2i:
	var p := pos - global_position
	return Vector2i(floori(p.x / cell_size), floori(p.y / cell_size))

## Centre of a cell in world space.
func cell_to_world(cell: Vector2i) -> Vector2:
	return global_position + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size

func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(global_position + Vector2(cell) * cell_size, Vector2(cell_size, cell_size))

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func clamp_cell(cell: Vector2i) -> Vector2i:
	return cell.clamp(Vector2i.ZERO, grid_size - Vector2i.ONE)

func world_rect() -> Rect2:
	return Rect2(global_position, Vector2(grid_size * cell_size))

func _idx(cell: Vector2i) -> int:
	return cell.y * grid_size.x + cell.x

# ---------------------------------------------------------------- queries

func get_height(cell: Vector2i) -> int:
	return _height[_idx(cell)] if in_bounds(cell) else 0

func is_tunnel(cell: Vector2i) -> bool:
	return in_bounds(cell) and _tunnel[_idx(cell)] == 1

## A +2 block that has not been dug out.
func is_undug_wall(cell: Vector2i) -> bool:
	return in_bounds(cell) and _open[_idx(cell)] == 0

func speed_multiplier_at(pos: Vector2) -> float:
	var cell := world_to_cell(pos)
	return _mult[_idx(cell)] if in_bounds(cell) else 1.0

func range_multiplier_at(pos: Vector2) -> float:
	return hill_range_multiplier if get_height(world_to_cell(pos)) == 1 else 1.0

func blocks_projectiles(cell: Vector2i) -> bool:
	return in_bounds(cell) and _height[_idx(cell)] >= MAX_HEIGHT

func can_build_tower_at(pos: Vector2) -> bool:
	var cell := world_to_cell(pos)
	if not in_bounds(cell):
		return false
	var i := _idx(cell)
	return _height[i] < MAX_HEIGHT and (_flags[i] & FLAG_SPAWN) == 0

## True if a straight line between the two points passes through a projectile-blocking cell.
## Walks the grid cell by cell so nothing is skipped, however long the segment is.
func segment_blocked(from: Vector2, to: Vector2) -> bool:
	var a := (from - global_position) / cell_size
	var b := (to - global_position) / cell_size
	var cell := Vector2i(floori(a.x), floori(a.y))
	var end := Vector2i(floori(b.x), floori(b.y))
	if blocks_projectiles(cell):
		return true
	if cell == end:
		return false

	var d := b - a
	var step := Vector2i(int(signf(d.x)), int(signf(d.y)))
	var t_max := Vector2(INF, INF)
	var t_delta := Vector2(INF, INF)
	if step.x != 0:
		t_max.x = ((cell.x + (1 if step.x > 0 else 0)) - a.x) / d.x
		t_delta.x = absf(1.0 / d.x)
	if step.y != 0:
		t_max.y = ((cell.y + (1 if step.y > 0 else 0)) - a.y) / d.y
		t_delta.y = absf(1.0 / d.y)

	var guard := absi(end.x - cell.x) + absi(end.y - cell.y) + 2
	while cell != end and guard > 0:
		guard -= 1
		if t_max.x < t_max.y:
			cell.x += step.x
			t_max.x += t_delta.x
		else:
			cell.y += step.y
			t_max.y += t_delta.y
		if blocks_projectiles(cell):
			return true
	return false

func distance_to_cell(pos: Vector2, cell: Vector2i) -> float:
	var r := cell_rect(cell)
	var dx := maxf(maxf(r.position.x - pos.x, 0.0), pos.x - r.end.x)
	var dy := maxf(maxf(r.position.y - pos.y, 0.0), pos.y - r.end.y)
	return Vector2(dx, dy).length()

# ---------------------------------------------------------------- terraforming

## Empty string if the cell can be raised, otherwise the reason it can't.
func check_raise(cell: Vector2i) -> String:
	if not in_bounds(cell):
		return "Outside the map"
	var i := _idx(cell)
	if _flags[i] != 0:
		return "Protected area"
	var h := _height[i]
	if h >= MAX_HEIGHT:
		return "Already at maximum height"
	if h + 1 >= MAX_HEIGHT:
		if _tower_in_cell(cell):
			return "A tower is on this tile"
		if _enemy_near_cell(cell):
			return "An enemy is in the way"
	return ""

func get_raise_cost(cell: Vector2i) -> int:
	var h := get_height(cell)
	return raise_costs[h] if h < raise_costs.size() else 0

## Raises a cell by one. Call check_raise() first and take payment yourself.
func raise_cell(cell: Vector2i) -> void:
	if check_raise(cell) == "":
		_set_height(cell, get_height(cell) + 1)

func can_lower(cell: Vector2i) -> bool:
	return in_bounds(cell) and _height[_idx(cell)] > 0

func get_lower_refund(cell: Vector2i) -> int:
	var h := get_height(cell)
	if h <= 0 or h - 1 >= raise_costs.size():
		return 0
	return int(raise_costs[h - 1] * lower_refund_ratio)

## Lowers a cell by one (clearing any tunnel). Pay out the refund yourself.
func lower_cell(cell: Vector2i) -> void:
	if can_lower(cell):
		_set_height(cell, get_height(cell) - 1)

## Turns an undug +2 block into a tunnel (called by enemies when they finish digging).
func dig_tunnel(cell: Vector2i) -> void:
	if not is_undug_wall(cell):
		return
	var i := _idx(cell)
	_tunnel[i] = 1
	_refresh(i)
	_touch()
	tunnel_dug.emit(cell)

func _set_height(cell: Vector2i, h: int) -> void:
	var i := _idx(cell)
	var old := _height[i]
	_height[i] = h
	if h < MAX_HEIGHT:
		_tunnel[i] = 0
	_refresh(i)
	_touch()
	if old != h:
		cell_height_changed.emit(cell, old, h)

func _refresh(i: int) -> void:
	_open[i] = 1 if (_height[i] < MAX_HEIGHT or _tunnel[i] == 1) else 0
	_mult[i] = hill_speed_multiplier if _height[i] == 1 else 1.0

func _touch() -> void:
	version += 1
	terrain_changed.emit()

func _tower_in_cell(cell: Vector2i) -> bool:
	var rect := cell_rect(cell)
	for t in get_tree().get_nodes_in_group("towers"):
		if rect.has_point(t.global_position):
			return true
	return false

func _enemy_near_cell(cell: Vector2i) -> bool:
	var rect := cell_rect(cell).grow(enemy_clearance)
	for e in get_tree().get_nodes_in_group("enemies"):
		if rect.has_point(e.global_position):
			return true
	return false

# ---------------------------------------------------------------- enemy pathing

func has_route() -> bool:
	return in_bounds(goal_cell)

func _get_fields(speed: float, dig_time: float) -> Array:
	if _fields_version != version:
		_fields.clear()
		_fields_version = version
	var key := "%s|%s" % [speed, dig_time]
	if not _fields.has(key):
		var around := FlowField.new()
		around.build(grid_size.x, grid_size.y, cell_size, goal_cell, _open, _mult, speed, dig_time, false)
		var through := FlowField.new()
		through.build(grid_size.x, grid_size.y, cell_size, goal_cell, _open, _mult, speed, dig_time, true)
		_fields[key] = [around, through]
	return _fields[key]

## Should an enemy standing in this cell dig through walls rather than walk around them?
## True when going around takes more than path_tolerance times longer than going
## through (dig time included), or when there is no way around at all.
func should_dig(cell: Vector2i, speed: float, dig_time: float) -> bool:
	if not has_route():
		return false
	var f := _get_fields(speed, dig_time)
	var around: float = f[0].cost_at(cell)
	var through: float = f[1].cost_at(cell)
	if is_inf(around):
		return true
	return around > path_tolerance * through

## The next cell to walk into. Vector2i(-1, -1) if there is no route.
func get_step(cell: Vector2i, speed: float, dig_time: float, through: bool) -> Vector2i:
	if not has_route():
		return Vector2i(-1, -1)
	var f := _get_fields(speed, dig_time)
	var field: FlowField = f[1] if through else f[0]
	return field.best_neighbor(cell)

# ---------------------------------------------------------------- visuals

## Cosmetic only: lets a digging enemy make the cliff shake and kick up dust.
func notify_digging(cell: Vector2i, delta: float) -> void:
	if _visuals:
		_visuals.notify_digging(cell, delta)

# ---------------------------------------------------------------- overlay (grid lines / hover)

## Show or hide the grid lines and highlight one cell (used by the build controller).
func set_overlay(show_grid: bool, hover: Vector2i = Vector2i(-1, -1), hover_ok: bool = true) -> void:
	if show_grid == _show_grid and hover == _hover_cell and hover_ok == _hover_ok:
		return
	_show_grid = show_grid
	_hover_cell = hover
	_hover_ok = hover_ok
	if _overlay:
		_overlay.queue_redraw()

func draw_overlay(canvas: CanvasItem) -> void:
	if not _show_grid:
		return
	var size := Vector2(grid_size * cell_size)
	var line := Color(1, 1, 1, 0.16)
	for x in grid_size.x + 1:
		canvas.draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, size.y), line, 1.0)
	for y in grid_size.y + 1:
		canvas.draw_line(Vector2(0, y * cell_size), Vector2(size.x, y * cell_size), line, 1.0)
	for y in grid_size.y:
		for x in grid_size.x:
			if _flags[y * grid_size.x + x] != 0:
				canvas.draw_rect(Rect2(Vector2(x, y) * cell_size, Vector2(cell_size, cell_size)), Color(0.85, 0.2, 0.2, 0.16))
	if in_bounds(_hover_cell):
		var r := Rect2(Vector2(_hover_cell) * cell_size, Vector2(cell_size, cell_size))
		var col := Color(0.3, 1.0, 0.4) if _hover_ok else Color(1.0, 0.35, 0.3)
		canvas.draw_rect(r, Color(col, 0.3))
		canvas.draw_rect(r, col, false, 3.0)

## Draws the grid lines / hover highlight on top of the terrain.
class Overlay extends Node2D:
	var grid: TerrainGrid
	func _draw() -> void:
		if grid:
			grid.draw_overlay(self)
