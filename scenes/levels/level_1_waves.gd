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
	# Wave 1 - Just basic slimes
	{
		"spawns": [
			{"enemy": "basic", "point": "SpawnLeft", "count": 5, "interval": 1.5},
		],
		"time_after": 5.0,
	},
	# Wave 2 - Slimes from two directions
	{
		"spawns": [
			{"enemy": "basic", "point": "SpawnLeft", "count": 6, "interval": 1.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 4, "interval": 1.5, "delay": 3.0},
		],
		"time_after": 5.0,
	},
	# Wave 3 - Introducing armoured slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 6, "interval": 1.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 7, "interval": 0.6},
		],
		"time_after": 5.0,
	},
	# Wave 4 - Introducing sword slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 6, "interval": 1.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 7, "interval": 0.6},
			{"enemy": "sword", "point": "SpawnRight", "count": 3, "interval": 1.4},
		],
		"time_after": 5.0,
	},
	# Wave 5 - More sword slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 12, "interval": 0.5},
			{"enemy": "basic", "point": "SpawnRight", "count": 5, "interval": 0.6},
			{"enemy": "sword", "point": "SpawnRight", "count": 5, "interval": 0.6},
		],
		"time_after": 5.0,
	},
	# Wave 6 - First Big Slime
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 5, "interval": 1.0},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 1, "interval": 1.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 5, "interval": 0.6},
			{"enemy": "sword", "point": "SpawnRight", "count": 3, "interval": 1.4},
		],
		"time_after": 5.0,
	},
	# Wave 7 - More Big Slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 5, "interval": 1.0},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 2, "interval": 1.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 5, "interval": 0.6},
			{"enemy": "sword", "point": "SpawnRight", "count": 3, "interval": 1.4},
			{"enemy": "big_slime", "point": "SpawnRight", "count": 1, "interval": 1.0},
		],
		"time_after": 5.0,
	},
	# Wave 8 - Longer Wave, more swords
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 10, "interval": 1.0},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 4, "interval": 1.0},
			{"enemy": "basic", "point": "SpawnLeft", "count": 10, "interval": 0.3},
			{"enemy": "basic", "point": "SpawnRight", "count": 10, "interval": 0.6},
			{"enemy": "sword", "point": "SpawnRight", "count": 12, "interval": 1.4},
			{"enemy": "big_slime", "point": "SpawnRight", "count": 2, "interval": 1.0},
		],
		"time_after": 5.0,
	},
	# Wave 9 - Faster Wave, more big slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 20, "interval": 0.5},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 16, "interval": 0.5},
			{"enemy": "basic", "point": "SpawnLeft", "count": 20, "interval": 0.15},
			{"enemy": "basic", "point": "SpawnRight", "count": 20, "interval": 0.3},
			{"enemy": "sword", "point": "SpawnRight", "count": 24, "interval": 0.7},
			{"enemy": "big_slime", "point": "SpawnRight", "count": 8, "interval": 0.5},
		],
		"time_after": 5.0,
	},
	# Wave 10 - Boss Wave
	{
		"spawns": [
			{"enemy": "big_slime", "point": ["SpawnLeft","SpawnRight"], "count": 50, "interval": 0.5},
			{"enemy": "sword", "point": ["SpawnLeft","SpawnRight"], "count": 100, "interval": 0.25},
			{"enemy": "armoured", "point": ["SpawnLeft","SpawnRight"], "count": 100, "interval": 0.25},
		],
		"wait_for_clear": true,
	},
]
