class_name TerrainVisuals extends Node2D
## Draws the terrain and animates it. Purely cosmetic: it never changes the terrain data.
##
## The real height of a cell changes instantly (that is what pathing, towers, etc. use).
## This node keeps a separate animation per cell and draws the sprites "growing" out of
## the ground toward the real height. Settings and sprites are in terrain_art.gd.

const ART = preload("res://scenes/terrain/terrain_art.gd")

var animate := true

var _terrain: TerrainGrid
var _w := 0
var _h := 0
var _cs := 48.0

var _anims := {}      # cell index -> {from, to, t, dur, rising}
var _decals := {}     # cell index -> {t, dur}   crack decal at the base
var _tunnels := {}    # cell index -> {t}        tunnel mouth popping in
var _shakes := {}     # cell index -> seconds of shaking left
var _dig_dust := {}   # cell index -> seconds since the last puff
var _particles: Array = []
var _time := 0.0
var _active := false
var _back_c1 := 0.0   # easing constant that gives exactly ART.OVERSHOOT

func _ready() -> void:
	_terrain = get_parent() as TerrainGrid
	_w = _terrain.grid_size.x
	_h = _terrain.grid_size.y
	_cs = float(_terrain.cell_size)
	_back_c1 = _solve_back_constant(ART.OVERSHOOT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if ART.PIXEL_ART else CanvasItem.TEXTURE_FILTER_LINEAR
	_terrain.cell_height_changed.connect(_on_cell_height_changed)
	_terrain.tunnel_dug.connect(_on_tunnel_dug)

# ------------------------------------------------------------------ events from the terrain

func _on_cell_height_changed(cell: Vector2i, from_height: int, to_height: int) -> void:
	var i := cell.y * _w + cell.x
	if not animate:
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
	queue_redraw()

func _on_tunnel_dug(cell: Vector2i) -> void:
	var i := cell.y * _w + cell.x
	_shakes.erase(i)
	if not animate:
		queue_redraw()
		return
	_tunnels[i] = {"t": 0.0}
	_burst(cell, ART.DUST_PER_TUNNEL, ART.DUST_COLOR_TUNNEL)
	_active = true
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

	for i in _anims.keys():
		var a: Dictionary = _anims[i]
		a.t += delta
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
		if t.t >= ART.TUNNEL_POP_TIME:
			_tunnels.erase(i)
		else:
			_active = true
	for i in _shakes.keys():
		_shakes[i] -= delta
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

	# One last redraw on the frame the final animation finishes.
	if _active or was_active:
		queue_redraw()

# ------------------------------------------------------------------ drawing

@warning_ignore("integer_division")
func _draw() -> void:
	# 1. Disturbed ground, under everything.
	if ART.CRACK:
			
		for i in _decals:
			var d: Dictionary = _decals[i]
			var alpha := sin(clampf(d.t / d.dur, 0.0, 1.0) * PI) * ART.CRACK_ALPHA
			var size: float = _cs * ART.CRACK_SCALE
			var centre := Vector2((i % _w + 0.5) * _cs, (i / _w + 0.55) * _cs)
			draw_texture_rect(ART.CRACK, Rect2(centre - Vector2(size, size) / 2.0, Vector2(size, size)), false, Color(1, 1, 1, alpha))

	# 2. Cells, back rows first so cliffs in front overlap the ones behind them.
	for y in _h:
		for x in _w:
			var i := y * _w + x
			var cell := Vector2i(x, y)
			var real_h := _terrain.get_height(cell)
			var anim: Variant = _anims.get(i)
			if real_h == 0 and anim == null:
				continue

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
			var base := Vector2((x + 0.5) * _cs, (y + 1.0) * _cs)

			var hill_r := clampf(eff, 0.0, 1.0)
			var cliff_r := clampf(eff - 1.0, 0.0, 1.0)
			if hill_r > 0.0:
				var tex: Texture2D = ART.HILL[hsh % ART.HILL.size()]
				_draw_emerging(tex, base, hill_r, over if grow_to == 1 else 0.0, flip, 0.0)
			if cliff_r > 0.0:
				var tex: Texture2D = ART.CLIFF[hsh % ART.CLIFF.size()]
				var shake := 0.0
				if _shakes.has(i):
					shake = sin(_time * 80.0) * ART.DIG_SHAKE_AMOUNT * clampf(_shakes[i] / ART.DIG_SHAKE_TIME, 0.0, 1.0)
				_draw_emerging(tex, base, cliff_r, over if grow_to == 2 else 0.0, flip, shake)
			if cliff_r >= 0.999 and _terrain.is_tunnel(cell):
				var pop := 1.0
				if _tunnels.has(i):
					pop = _ease_out_back(clampf(_tunnels[i].t / ART.TUNNEL_POP_TIME, 0.0, 1.0))
				_draw_tunnel(base, pop)

	# 3. Dust.
	for p in _particles:
		var t := clampf(p.life / p.max, 0.0, 1.0)
		var c: Color = p.color
		draw_circle(p.pos, p.size * (0.6 + 0.9 * t), Color(c.r, c.g, c.b, c.a * (1.0 - t)))

## Draws the top `reveal` fraction of a sprite, sitting on the ground line at `base`, so it
## looks like it is pushing up out of the ground. `over` stretches it taller and a bit wider
## while it overshoots.
func _draw_emerging(tex: Texture2D, base: Vector2, reveal: float, over: float, flip: bool, shake_x: float) -> void:
	var rows := roundi(tex.get_height() * reveal) # whole pixel rows keeps pixel art crisp
	if rows <= 0:
		return
	var scale_f := _cs / tex.get_width()
	var width := tex.get_width() * scale_f * (1.0 + over * ART.SQUASH)
	var height := rows * scale_f * (1.0 + over)
	draw_set_transform(base + Vector2(shake_x, 0.0), 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect_region(tex, Rect2(-width / 2.0, -height, width, height), Rect2(0, 0, tex.get_width(), rows))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_tunnel(base: Vector2, pop: float) -> void:
	var tex: Texture2D = ART.TUNNEL
	var scale_f := _cs / tex.get_width() * pop
	var size := tex.get_size() * scale_f
	draw_texture_rect(tex, Rect2(base.x - size.x / 2.0, base.y - size.y, size.x, size.y), false)
