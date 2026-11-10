extends RefCounted
## The towers that appear in the radial build menu.
## Order = menu slot order (clockwise from the top). Max 4; unused slots show as empty.
##
##   "name" : shown in the middle of the menu when hovered
##   "cost" : price in gold
##   "scene": the tower scene to place
##   "icon" : texture shown in the menu
##   "upgrades" : up to MAX_UPGRADES upgrade paths, shown on the wheel when you select the tower
##
## Each UPGRADE is a dictionary:
##   "stat"      : "damage", "fire_rate" or "range"
##   "name"      : shown in the menu
##   "glyph"     : short text shown on the wheel slot (3 letters fits best)
##   "costs"     : gold for each level, e.g. [40, 80] = two levels costing 40 then 80
##   "per_level" : how much each level adds
##                   damage    -> extra damage per bullet      (1 = +1 damage)
##                   fire_rate -> fraction faster              (0.3 = +30% shots per second)
##                   range     -> fraction larger              (0.2 = +20% range)


const MAX_SLOTS := 4
const MAX_UPGRADES := 4

## Fraction of the gold spent on a tower (purchase + upgrades) you get back when selling it.
const SELL_RATIO := 0.7

const TOWERS := [
	{
		"name": "Students",
		"cost": 50,
		"scene": preload("res://scenes/towers/tower_basic.tscn"),
		"icon": preload("res://projectile tower.png"),
		"upgrades": [
			{"stat": "damage", "name": "Damage", "glyph": "DMG", "costs": [40, 80], "per_level": 1.0},
			{"stat": "fire_rate", "name": "Fire Rate", "glyph": "SPD", "costs": [40, 80], "per_level": 0.3},
			{"stat": "range", "name": "Range", "glyph": "RNG", "costs": [30, 60], "per_level": 0.2},
			{"stat": "explosive", "name": "Explosive", "glyph": "BOM", "costs": [200], "per_level": 130.0, "description": "Bolt explode, hitting nearby slimes", "icon": preload("res://explosion circle.png"), "icon_size": 2.35},
		],
	},
	{
		"name": "Kelvin",
		"cost": 125,
		"scene": preload("res://scenes/towers/tower_kelvin.tscn"),
		"icon": preload("res://kelvinator.png"),
		"upgrades": [
			{"stat": "damage", "name": "Damage", "glyph": "DMG", "costs": [40, 80], "per_level": 1.0},
			{"stat": "fire_rate", "name": "Fire Rate", "glyph": "SPD", "costs": [40, 80], "per_level": 0.3},
			{"stat": "range", "name": "Range", "glyph": "RNG", "costs": [30, 60], "per_level": 0.2},
			{"stat": "chain", "name": "Chain", "glyph": "CHN", "icon": preload("res://thunder circle.png"), "icon_size": 2.35,"costs": [235], "per_level": 2, "description": "Beam jumps to 2 more enemies"},
		],
	},
	{
		"name": "Steam",
		"cost": 100,
		"scene": preload("res://scenes/towers/tower_steam.tscn"),
		"icon": preload("res://canon_aoe.png"),
		"upgrades": [
			{"stat": "damage", "name": "Damage", "glyph": "DMG", "costs": [40,80], "per_level": 1.0},
			{"stat": "fire_rate", "name":"Fire Rate", "glyph": "SPD", "costs": [40, 80], "per_level": 0.3},
			{"stat": "range", "name": "Range", "glyph": "RNG", "costs": [30,60], "per_level":0.2},
			{"stat": "scald", "name": "Scald", "glyph": "SCD", "icon": preload("res://steam circle.png"), "icon_size": 2.35, "costs": [210], "per_level": 3.0, "description": "Scalded slimes take 30% more damage"
			}
		],
	},
	]
