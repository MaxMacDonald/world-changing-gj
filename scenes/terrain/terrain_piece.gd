class_name TerrainPiece extends Node2D
## One drawable slice of a terrain cell (crater back, crater front, cliff or tunnel mouth).
## Lives inside the y-sorted entities node, so towers and enemies sort between the slices.
##
## The node's position is the SORT KEY. `sort_dy` moves that key up/down relative to the
## cell's ground line, and _draw() shifts the picture back by the same amount, so the
## sprite appears exactly where it would without the offset.

var tex: Texture2D
var cs := 48.0
var squash := 0.6        # how much wider it gets while overshooting
var sort_dy := 0.0       # pixels from the ground line (negative = further back)
var reveal := 1.0        # fraction of the sprite shown, from the top down
var over := 0.0          # overshoot past full height
var flip := false
var shake_x := 0.0
var scale_mul := 1.0     # extra uniform scale (used by the tunnel pop)

## Put the piece's ground line at `ground` (world space) and set its sort offset.
func configure(ground: Vector2, dy: float) -> void:
	sort_dy = dy
	global_position = ground + Vector2(0.0, dy)

func _draw() -> void:
	if tex == null:
		return
	var rows := roundi(tex.get_height() * reveal) # whole pixel rows keeps pixel art crisp
	if rows <= 0:
		return
	var s := cs / tex.get_width() * scale_mul
	var w := tex.get_width() * s * (1.0 + over * squash)
	var h := rows * s * (1.0 + over)
	# Our origin is sort_dy away from the ground line, so draw back at the ground line.
	draw_set_transform(Vector2(shake_x, -sort_dy), 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect_region(tex, Rect2(-w / 2.0, -h, w, h), Rect2(0, 0, tex.get_width(), rows))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
