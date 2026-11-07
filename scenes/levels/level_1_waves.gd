extends RefCounted
## All wave data for level 1. Edit this file to design the level.
##
## Each WAVE is a dictionary:
##   "spawns"         : array of spawn groups (all groups in a wave run at the same time)
##   "wait_for_clear" : (optional, default false) wait until all enemies are gone before the wave counts as finished
##   "time_after"     : (optional, default 0) seconds to wait before the next wave starts
##
## Each SPAWN GROUP is a dictionary:
##   "enemy"    : key from ENEMY_SCENES in enemy_spawner.gd (e.g. "basic")
##   "point"    : SpawnPoint node name, or an array of names to pick randomly per enemy
##   "count"    : (optional, default 1) how many enemies
##   "interval" : (optional, default 1.0) seconds between each enemy in this group
##   "delay"    : (optional, default 0) seconds after the wave starts before this group begins

const WAVES := [
	# Wave 1
	{
		"spawns": [
			{"enemy": "basic", "point": "SpawnLeft", "count": 5, "interval": 1.5},
		],
		"time_after": 5.0,
	},
	# Wave 2
	{
		"spawns": [
			{"enemy": "sword", "point": "SpawnLeft", "count": 6, "interval": 1.0},
			{"enemy": "armoured", "point": "SpawnRight", "count": 4, "interval": 1.5, "delay": 3.0},
		],
		"time_after": 5.0,
	},
	# Wave 3 - enemies pick a random spawn each time
	{
		"spawns": [
			{"enemy": "big_slime", "point": ["SpawnLeft", "SpawnRight"], "count": 15, "interval": 0.6},
		],
		"wait_for_clear": true,
	},
]
