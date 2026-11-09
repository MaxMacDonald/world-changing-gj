class_name TerrainVisuals extends Node2D
## Draws the terrain and animates it. Purely cosmetic: it never changes the terrain data.
##
## The real height of a cell changes instantly (that is what pathing, towers, etc. use).
## This node keeps a separate animation per cell and shows the sprites "growing" out of
## the ground toward the real height. Settings and sprites are in terrain_art.gd.
##
## Each cell is made of TerrainPiece nodes (crater back, crater front, cliff, tunnel).
## They are added to `entities_root` (the y-sorted node that holds towers and enemies),
## so towers/enemies can be sorted between the back and front of a crater.
## Crack decals are drawn by this node itself; dust is drawn by a layer on top.

const ART = preload("res://scenes/terrain/terrain_art.gd")

var animate := true
## The y-sorted node that holds towers and enemies. Set by TerrainGrid before _ready().
var entities_root: Node2D

var _terrain: TerrainGrid
var _w := 0
var _h := 0
var _cs := 48.0

var _anims := {}      # cell index -> {from, to, t, dur, rising}
var _decals := {}     # cell index -> {t, dur}   crack decal at the base
var _tunnels := {}    # cell index -> {t}        tunnel mouth popping in
var _shakes := {}     # cell index -> seconds of shaking left
var _dig_dust := {}   # cell index -> seconds since the last puff
var _pieces := {}     # cell index -> {kind: TerrainPiece}
var _particles: Array = []
var _time := 0.0
var _active := false
var _back_c1 := 0.0   # easing constant that gives exactly ART.OVERSHOOT
var _dust: DustLayer

func _ready() -> void:
	_terrain = get_parent() as TerrainGrid
	_w = _terrain.grid_size.x
	_h = _terrain.grid_size.y
	_cs = float(_terrain.cell_size)
	_back_c1 = _solve_back_constant(ART.OVERSHOOT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if ART.PIXEL_ART else CanvasItem.TEXTURE_FILTER_LINEAR
	_terrain.cell_height_changed.connect(_on_cell_height_changed)
	_terrain.tunnel_dug.connect(_on_tunnel_dug)
	# Dust draws above everything (including the y-sorted pieces) so it isn't hidden by the hills.
	_dust = DustLayer.new()
	_dust.vis = self
	_dust.z_index = 1
	add_child(_dust)

func _exit_tree() -> void:
	# The pieces live in another node, so they won't be freed with us.
	for i in _pieces:
		for kind in _pieces[i]:
			var p: TerrainPiece = _pieces[i][kind]
			if is_instance_valid(p):
				p.queue_free()
	_pieces.clear()

# ------------------------------------------------------------------ events from the terrain

func _on_cell_height_changed(cell: Vector2i, from_height: int, to_height: int) -> void:
	var i := cell.y * _w + cell.x
	if not animate:
		_sync_cell(i)
		queue_redraw()
		return

	# Start from wherever the animation currently is, so changing your mind mid-rise is smooth.
	var start := _anim_height(_anims[i]) if _anims.has(i) else float(from_height)
	var rising := to_height > from_height
	var dur: float = ART.LOWER_TIME
	if rising:
		dur = ART.HILL_RISE_TIME if to_height == 1 else ART.CLIFF_RISE_TIME

	_anims[i] = {"from": start, "to": float(to_height), "t": 0.0, "dur": dur, "rising": rising}
	_decals[i] = {"t": 0.0, "dur": dur}

	var color: Color = ART.DUST_COLOR_HILL if maxi(from_height, to_height) == 1 else ART.DUST_COLOR_CLIFF
	_burst(cell, ART.DUST_PER_RISE if rising else ART.DUST_PER_LOWER, color)
	_active = true
	_sync_cell(i)
	queue_redraw()

func _on_tunnel_dug(cell: Vector2i) -> void:
	var i := cell.y * _w + cell.x
	_shakes.erase(i)
	if not animate:
		_sync_cell(i)
		queue_redraw()
		return
	_tunnels[i] = {"t": 0.0}
	_burst(cell, ART.DUST_PER_TUNNEL, ART.DUST_COLOR_TUNNEL)
	_active = true
	_sync_cell(i)
	queue_redraw()

## Called every frame by an enemy that is digging this cell: shake it and kick up dust.
func notify_digging(cell: Vector2i, delta: float) -> void:
	if not animate:
		return
	var i := cell.y * _w + cell.x
	_shakes[i] = ART.DIG_SHAKE_TIME
	var since: float = _dig_dust.get(i, ART.DIG_DUST_INTERVAL) + delta
	if since >= ART.DIG_DUST_INTERVAL:
		since = 0.0
		_burst(cell, 2, ART.DUST_COLOR_CLIFF)
	_dig_dust[i] = since
	_active = true

# ------------------------------------------------------------------ animation maths

## Overshoots past 1.0 and settles back ("ease out back").
func _ease_out_back(p: float) -> float:
	var c3 := _back_c1 + 1.0
	var q := p - 1.0
	return 1.0 + c3 * q * q * q + _back_c1 * q * q

## Finds the easing constant whose peak overshoot is exactly `overshoot` (0.1 = 10%).
## The peak of the curve is 4c^3 / (27 (c+1)^2), which grows with c, so bisect for it.
func _solve_back_constant(overshoot: float) -> float:
	if overshoot <= 0.0:
		return 0.0
	var lo := 0.0
	var hi := 30.0
	for k in 40:
		var mid := (lo + hi) / 2.0
		var peak := 4.0 * mid * mid * mid / (27.0 * (mid + 1.0) * (mid + 1.0))
		if peak < overshoot:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0

func _ease_in_out(p: float) -> float:
	return p * p * (3.0 - 2.0 * p)

## The cell's current visual height (can briefly exceed the target while overshooting).
func _anim_height(a: Dictionary) -> float:
	var p := clampf(a.t / a.dur, 0.0, 1.0)
	var eased := _ease_out_back(p) if a.rising else _ease_in_out(p)
	return lerpf(a.from, a.to, eased)

# ------------------------------------------------------------------ particles

func _burst(cell: Vector2i, count: int, color: Color) -> void:
	var base := Vector2((cell.x + 0.5) * _cs, (cell.y + 1.0) * _cs)
	for k in count:
		if _particles.size() >= 300:
			return
		_particles.append({
			"pos": base + Vector2(randf_range(-0.45, 0.45) * _cs, randf_range(-6.0, 2.0)),
			"vel": Vector2(randf_range(-34.0, 34.0), randf_range(-62.0, -18.0)),
			"life": 0.0,
			"max": randf_range(0.35, 0.7),
			"size": randf_range(3.0, 6.0),
			"color": color,
		})

# ------------------------------------------------------------------ per-frame update

func _process(delta: float) -> void:
	_time += delta
	var was_active := _active
	_active = false
	var touched := {}   # cells whose pieces need refreshing this frame

	for i in _anims.keys():
		var a: Dictionary = _anims[i]
		a.t += delta
		touched[i] = true
		if a.t >= a.dur:
			_anims.erase(i)
		else:
			_active = true
	for i in _decals.keys():
		var d: Dictionary = _decals[i]
		d.t += delta
		if d.t >= d.dur:
			_decals.erase(i)
		else:
			_active = true
	for i in _tunnels.keys():
		var t: Dictionary = _tunnels[i]
		t.t += delta
		touched[i] = true
		if t.t >= ART.TUNNEL_POP_TIME:
			_tunnels.erase(i)
		else:
			_active = true
	for i in _shakes.keys():
		_shakes[i] -= delta
		touched[i] = true
		if _shakes[i] <= 0.0:
			_shakes.erase(i)
		else:
			_active = true

	var k := _particles.size() - 1
	while k >= 0:
		var p: Dictionary = _particles[k]
		p.life += delta
		if p.life >= p.max:
			_particles.remove_at(k)
		else:
			p.pos += p.vel * delta
			p.vel = Vector2(p.vel.x * 0.94, p.vel.y * 0.94 + 40.0 * delta)
			_active = true
		k -= 1

	# Refresh the sprites of every cell that moved (including the frame an animation ends).
	for i in touched.keys():
		_sync_cell(i)

	# One last redraw on the frame the final animation finishes.
	if _active or was_active:
		queue_redraw()
		_dust.queue_redraw()

# ------------------------------------------------------------------ pieces

## Where a piece sorts, as a fraction of a cell relative to the cell's ground line (its bottom
## edge). A tower stands at the cell centre (-0.5), so the back rim (-0.7) sorts behind it
## and the front rim (-0.3) sorts in front of it. Change these in terrain_art.gd.
func _sort_dy(kind: String) -> float:
	match kind:
		"back": return ART.CRATER_BACK_SORT * _cs
		"front": return ART.CRATER_FRONT_SORT * _cs
		"tunnel": return 1.0   # a hair in front of the cliff it is cut into
		_: return 0.0          # cliff: sorts at the ground line like any tall object

func _get_piece(i: int, kind: String) -> TerrainPiece:
	var d: Dictionary = _pieces.get(i, {})
	if d.has(kind):
		return d[kind]
	var p := TerrainPiece.new()
	p.cs = _cs
	p.squash = ART.SQUASH
	p.texture_filter = texture_filter
	(entities_root if entities_root else self).add_child(p)
	d[kind] = p
	_pieces[i] = d
	return p

func _show_piece(i: int, kind: String, tex: Texture2D, ground: Vector2, reveal: float, over: float, flip: bool, shake_x: float = 0.0, scale_mul: float = 1.0) -> void:
	var p := _get_piece(i, kind)
	p.tex = tex
	p.reveal = reveal
	p.over = over
	p.flip = flip
	p.shake_x = shake_x
	p.scale_mul = scale_mul
	p.configure(ground, _sort_dy(kind))
	p.queue_redraw()

func _hide_piece(i: int, kind: String) -> void:
	var d: Dictionary = _pieces.get(i, {})
	if d.has(kind):
		var p: TerrainPiece = d[kind]
		if is_instance_valid(p):
			p.queue_free()
		d.erase(kind)
		if d.is_empty():
			_pieces.erase(i)

## Makes the pieces of one cell match its current (animated) state.
@warning_ignore("integer_division")
func _sync_cell(i: int) -> void:
	var x := i % _w
	var y := i / _w
	var cell := Vector2i(x, y)
	var real_h := _terrain.get_height(cell)
	var anim: Variant = _anims.get(i)
	if real_h == 0 and anim == null:
		for kind in ["back", "front", "cliff", "tunnel"]:
			_hide_piece(i, kind)
		return

	# eff = how far up the ground currently is. over = overshoot past the target.
	var eff := float(real_h)
	var over := 0.0
	var grow_to := -1
	if anim != null:
		var vh := _anim_height(anim)
		if anim.rising:
			eff = minf(vh, anim.to)
			over = maxf(vh - anim.to, 0.0)
			grow_to = int(anim.to)
		else:
			eff = vh

	var hsh := absi((x * 73856093) ^ (y * 19349663))
	var flip := ((hsh >> 4) & 1) == 1
	var ground := global_position + Vector2((x + 0.5) * _cs, (y + 1.0) * _cs)

	var hill_r := clampf(eff, 0.0, 1.0)
	var cliff_r := clampf(eff - 1.0, 0.0, 1.0)

	# Crater: back and front halves are separate pieces so things can stand between them.
	if hill_r > 0.0:
		var hill_over := over if grow_to == 1 else 0.0
		var n: int = ART.HILL_BACK.size()
		_show_piece(i, "back", ART.HILL_BACK[hsh % n], ground, hill_r, hill_over, flip)
		_show_piece(i, "front", ART.HILL_FRONT[hsh % n], ground, hill_r, hill_over, flip)
	else:
		_hide_piece(i, "back")
		_hide_piece(i, "front")

		# A dug cliff is replaced by the tunnel sprite, so the cliff piece is removed.
	var dug := cliff_r >= 0.999 and _terrain.is_tunnel(cell)

	# Cliff
	if cliff_r > 0.0 and not dug:
		var shake := 0.0
		if _shakes.has(i):
			shake = sin(_time * 80.0) * ART.DIG_SHAKE_AMOUNT * clampf(_shakes[i] / ART.DIG_SHAKE_TIME, 0.0, 1.0)
		_show_piece(i, "cliff", ART.CLIFF[hsh % ART.CLIFF.size()], ground, cliff_r, over if grow_to == 2 else 0.0, flip, shake)
	else:
		_hide_piece(i, "cliff")   # frees the node

	# Tunnel (the dug-out version of the cliff)
	if dug:
		var pop := 1.0
		if _tunnels.has(i):
			pop = _ease_out_back(clampf(_tunnels[i].t / ART.TUNNEL_POP_TIME, 0.0, 1.0))
		_show_piece(i, "tunnel", ART.TUNNEL, ground, 1.0, 0.0, false, 0.0, pop)
	else:
		_hide_piece(i, "tunnel")

# ------------------------------------------------------------------ drawing

## Only the crack decals are drawn here, under everything.
@warning_ignore("integer_division")
func _draw() -> void:
	if ART.CRACK:
		for i in _decals:
			var d: Dictionary = _decals[i]
			var alpha := sin(clampf(d.t / d.dur, 0.0, 1.0) * PI) * ART.CRACK_ALPHA
			var size: float = _cs * ART.CRACK_SCALE
			var centre := Vector2((i % _w + 0.5) * _cs, (i / _w + 0.55) * _cs)
			draw_texture_rect(ART.CRACK, Rect2(centre - Vector2(size, size) / 2.0, Vector2(size, size)), false, Color(1, 1, 1, alpha))

func draw_dust(canvas: CanvasItem) -> void:
	for p in _particles:
		var t := clampf(p.life / p.max, 0.0, 1.0)
		var c: Color = p.color
		canvas.draw_circle(p.pos, p.size * (0.6 + 0.9 * t), Color(c.r, c.g, c.b, c.a * (1.0 - t)))

## Draws the dust on top of the y-sorted pieces.
class DustLayer extends Node2D:
	var vis: TerrainVisuals
	func _draw() -> void:
		if vis:
			vis.draw_dust(self)
