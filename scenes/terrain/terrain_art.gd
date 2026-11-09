extends RefCounted
## Art and animation settings for the terrain. Everything you'd tweak lives here.
##
## TO USE YOUR OWN ART: overwrite the PNG files in Assets-Placeholder/Terrain/ using the
## same file names, or point the preloads below at new files. Nothing else needs to change.
##
## Sprite rules:
##   * Transparent PNGs. Each sprite is scaled so its WIDTH matches one grid cell (48px).
##   * The BOTTOM edge of the sprite is the ground line of its cell. A sprite taller than
##     it is wide (like the cliff) simply sticks up above the cell, over the row behind it.
##   * HILL and CLIFF may have several variants. Each cell picks one at random (the same
##     one every time) and is sometimes mirrored, so rows don't look copy-pasted.
##   * As a cell grows, the sprite is revealed from the TOP DOWN and cut off at the ground
##     line, so it looks like it is pushing up out of the ground. Put the interesting part
##     of the silhouette at the top of the sprite.

# ---- sprites ----
const HILL_BACK := [
	preload("res://terrainAssets/hill-hole-back.png"),
	preload("res://terrainAssets/hill-hole-back.png"),
]
const HILL_FRONT := [
	preload("res://terrainAssets/hill-hole-front.png"),
	preload("res://terrainAssets/hill-hole-front.png"),
]
const CLIFF := [
	preload("res://terrainAssets/cliff.png"),
	preload("res://terrainAssets/cliff.png"),
]
## Drawn on the front of a cliff cell that has been dug through.
const TUNNEL := preload("res://terrainAssets/broken cliff without crater.png")
## Cracked/disturbed dirt drawn at the base while ground is rising or sinking.
const CRACK := null

## true = pixel art (crisp, nearest-neighbour). false = smooth scaling for hi-res art.
const PIXEL_ART := true

# ---- animation timing (seconds) ----
const HILL_RISE_TIME := 0.45     # flat -> hill
const CLIFF_RISE_TIME := 0.8     # hill -> cliff
const LOWER_TIME := 0.4          # any lowering
const TUNNEL_POP_TIME := 0.3     # tunnel mouth appearing when an enemy finishes digging

const CRATER_BACK_SORT := -0.7
const CRATER_FRONT_SORT := -0.3
## How far the top overshoots on the way up before settling (fraction of one level).
## 0 = no bounce. Around 0.1 is a gentle pop.
const OVERSHOOT := 0.12
## How much wider the sprite gets at the peak of the overshoot (squash and stretch).
const SQUASH := 0.6

# ---- dust ----
const DUST_PER_RISE := 9
const DUST_PER_LOWER := 5
const DUST_PER_TUNNEL := 14
const DUST_COLOR_HILL := Color(0.62, 0.5, 0.34, 0.85)
const DUST_COLOR_CLIFF := Color(0.66, 0.65, 0.66, 0.85)
const DUST_COLOR_TUNNEL := Color(0.42, 0.33, 0.25, 0.9)

# ---- crack decal under the growing ground ----
const CRACK_SCALE := 1.35        # size relative to a cell
const CRACK_ALPHA := 0.9

# ---- while an enemy is digging a cliff ----
const DIG_SHAKE_AMOUNT := 1.8    # pixels
const DIG_SHAKE_TIME := 0.12     # how long the shake lingers after each dig tick
const DIG_DUST_INTERVAL := 0.14  # seconds between dust puffs
