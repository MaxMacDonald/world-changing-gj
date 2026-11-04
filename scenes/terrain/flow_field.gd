class_name FlowField extends RefCounted
## A "time to reach the base" map over the terrain grid, built with Dijkstra from the goal outwards.
## Costs are in SECONDS for an enemy with a given speed and dig time.
##
## Two kinds are built (see TerrainGrid):
##   through = false : undug +2 blocks are impassable          ("go around")
##   through = true  : undug +2 blocks can be dug, each costing dig_time ("go through")
##
## Movement rules (same for both kinds):
##   * 8 directions. A diagonal step is only allowed if both orthogonal cells it squeezes
##     past are open, so nobody cuts through the corner of a wall.
##   * Walking over a +1 hill is slower (per-cell speed multiplier).

const SQRT2 := 1.41421356
const DIRS := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
## Only used to choose between equal-cost neighbours: prefer the one nearest the goal,
## which keeps paths looking like straight lines instead of staircases.
const TIE_BREAK := 0.000001

var width := 0
var height := 0
var cell_size := 48.0
var goal := Vector2i.ZERO
var cost := PackedFloat64Array()

var _open := PackedByteArray()
var _mult := PackedFloat32Array()
var _speed := 50.0
var _dig_time := 3.0
var _through := false

var _heap_cost := PackedFloat64Array()
var _heap_cell := PackedInt32Array()

@warning_ignore("integer_division")
func build(w: int, h: int, cs: float, goal_cell: Vector2i, open: PackedByteArray, mult: PackedFloat32Array, speed: float, dig_time: float, through: bool) -> void:
	width = w
	height = h
	cell_size = cs
	goal = goal_cell
	_open = open
	_mult = mult
	_speed = maxf(speed, 0.001)
	_dig_time = dig_time
	_through = through

	cost.resize(w * h)
	cost.fill(INF)
	_heap_cost.clear()
	_heap_cell.clear()
	if not _in_bounds(goal.x, goal.y):
		return

	var goal_i := goal.y * width + goal.x
	cost[goal_i] = 0.0
	_push(0.0, goal_i)

	while not _heap_cell.is_empty():
		var c := _heap_cost[0]
		var b := _heap_cell[0]
		_pop()
		if c > cost[b]:
			continue # stale heap entry
		var bx := b % width
		var by := b / width
		for dir: Vector2i in DIRS:
			# 'a' is a neighbour of 'b'; we relax the move a -> b.
			var ax := bx + dir.x
			var ay := by + dir.y
			if not _can_move(ax, ay, bx, by):
				continue
			var a := ay * width + ax
			var dist := cell_size * (SQRT2 if (dir.x != 0 and dir.y != 0) else 1.0)
			var nc := c + _edge(a, b, dist)
			if nc < cost[a]:
				cost[a] = nc
				_push(nc, a)

func cost_at(cell: Vector2i) -> float:
	if not _in_bounds(cell.x, cell.y):
		return INF
	return cost[cell.y * width + cell.x]

## The neighbouring cell to step into next (Vector2i(-1, -1) if there is no route).
func best_neighbor(cell: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	if not _in_bounds(cell.x, cell.y):
		return best
	var a := cell.y * width + cell.x
	var best_total := INF
	for dir: Vector2i in DIRS:
		var n := cell + dir
		if not _can_move(cell.x, cell.y, n.x, n.y):
			continue
		var ni := n.y * width + n.x
		if is_inf(cost[ni]):
			continue
		var dist := cell_size * (SQRT2 if (dir.x != 0 and dir.y != 0) else 1.0)
		var total := _edge(a, ni, dist) + cost[ni] + TIE_BREAK * Vector2(n).distance_to(Vector2(goal))
		if total < best_total:
			best_total = total
			best = n
	return best

# ---------- internals ----------

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height

## Is moving from cell a to the neighbouring cell b allowed?
func _can_move(ax: int, ay: int, bx: int, by: int) -> bool:
	if not _in_bounds(ax, ay) or not _in_bounds(bx, by):
		return false
	if not _through:
		if _open[ay * width + ax] == 0 or _open[by * width + bx] == 0:
			return false
	if ax != bx and ay != by:
		if _open[by * width + ax] == 0 or _open[ay * width + bx] == 0:
			return false
	return true

## Seconds to travel centre-to-centre from a to b (plus digging b if it is undug rock).
func _edge(a: int, b: int, dist: float) -> float:
	var t := dist * 0.5 / (_speed * _mult[a]) + dist * 0.5 / (_speed * _mult[b])
	if _through and _open[b] == 0:
		t += _dig_time
	return t

func _swap(i: int, j: int) -> void:
	var c := _heap_cost[i]
	_heap_cost[i] = _heap_cost[j]
	_heap_cost[j] = c
	var n := _heap_cell[i]
	_heap_cell[i] = _heap_cell[j]
	_heap_cell[j] = n

func _push(c: float, cell: int) -> void:
	_heap_cost.append(c)
	_heap_cell.append(cell)
	var k := _heap_cell.size() - 1
	while k > 0:
		var p := (k - 1) >> 1
		if _heap_cost[p] <= _heap_cost[k]:
			break
		_swap(p, k)
		k = p

func _pop() -> void:
	var last := _heap_cell.size() - 1
	_heap_cost[0] = _heap_cost[last]
	_heap_cell[0] = _heap_cell[last]
	_heap_cost.resize(last)
	_heap_cell.resize(last)
	var n := last
	var k := 0
	while true:
		var l := 2 * k + 1
		if l >= n:
			break
		var r := l + 1
		var m := l
		if r < n and _heap_cost[r] < _heap_cost[l]:
			m = r
		if _heap_cost[k] <= _heap_cost[m]:
			break
		_swap(k, m)
		k = m
