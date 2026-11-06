extends RefCounted
## The towers that appear in the radial build menu.
## Order = menu slot order (clockwise from the top). Max 4; unused slots show as empty.
##
##   "name" : shown in the middle of the menu when hovered
##   "cost" : price in gold
##   "scene": the tower scene to place
##   "icon" : texture shown in the menu

const MAX_SLOTS := 4

const TOWERS := [
	{
		"name": "Crossbow",
		"cost": 60,
		"scene": preload("res://scenes/towers/tower_basic.tscn"),
		"icon": preload("res://Assets-Placeholder/Towers/Combat Towers/spr_tower_crossbow.png"),
	},
	{
		"name": "Kelvin",
		"cost": 80,
		"scene": preload("res://scenes/towers/tower_kelvin.tscn"),
		"icon": preload("res://Assets-Placeholder/Towers/Combat Towers/spr_tower_lightning_tower.png")
	}
]
