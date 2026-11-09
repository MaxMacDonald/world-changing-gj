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
			{"enemy": "basic", "point": "SpawnLeft", "count": 10, "interval": 3.25},
		],
		"time_after": 10.0,
	},
	# Wave 2 - Slimes from two directions
	{
		"spawns": [
			{"enemy": "basic", "point": "SpawnLeft", "count": 12, "interval": 3.0}, # Should be slightly quicker
			{"enemy": "basic", "point": "SpawnRight", "count": 8, "interval": 3.25, "delay": 3.0}, # Way quicker
		],
		"time_after": 10.0,
	},
	# Wave 3 - Introducing armoured slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 12, "interval": 5.0}, # About right
			{"enemy": "basic", "point": "SpawnRight", "count": 14, "interval": 3.0},
		],
		"time_after": 10.0,
	},
	# Wave 4 - Introducing sword slimes
	{
		"spawns": [ # All about right
			{"enemy": "armoured", "point": "SpawnLeft", "count": 12, "interval": 5.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 14, "interval": 3.0},
			{"enemy": "basic", "point": "SpawnBottom", "count": 10, "interval": 5.0},
			{"enemy": "sword", "point": "SpawnRight", "count": 6, "interval": 7.0},
		],
		"time_after": 10.0,
	},
	# Wave 5 - More sword slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 14, "interval": 4.0}, # About right
			{"enemy": "basic", "point": "SpawnRight", "count": 10, "interval": 1.5}, # Should be faster
			{"enemy": "sword", "point": "SpawnRight", "count": 10, "interval": 1.75}, # Should be faster
			{"enemy": "sword", "point": "SpawnTopRight", "count": 2, "interval": 1.5}, # Should be faster
			{"enemy": "basic", "point": "SpawnBottom", "count": 10, "interval": 5.0},
		],
		"time_after": 10.0,
	},
	# Wave 6 - First Big Slime
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 10, "interval": 5.0},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 1, "interval": 5.0, "delay": 5.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 10, "interval": 3.0},
			{"enemy": "sword", "point": "SpawnRight", "count": 6, "interval": 7.0},
			{"enemy": "basic", "point": "SpawnBottom", "count": 10, "interval": 5.0},
			{"enemy": "basic", "point": "SpawnTopRight", "count": 10, "interval": 5.0},
		],
		"time_after": 10.0,
	},
	# Wave 7 - More Big Slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 10, "interval": 5.0},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 4, "interval": 5.0},
			{"enemy": "basic", "point": "SpawnRight", "count": 10, "interval": 3.0},
			{"enemy": "sword", "point": "SpawnRight", "count": 6, "interval": 7.0},
			{"enemy": "big_slime", "point": "SpawnRight", "count": 2, "interval": 5.0},
			{"enemy": "basic", "point": "SpawnBottom", "count": 10, "interval": 3.0},
			{"enemy": "basic", "point": ["SpawnTopRight","SpawnTopLeft"], "count": 10, "interval": 5.0},
		],
		"time_after": 10.0,
	},
	# Wave 8 - Longer Wave, more swords
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 20, "interval": 5.0},
			{"enemy": "big_slime", "point": ["SpawnLeft","SpawnTopLeft"], "count": 8, "interval": 5.0},
			{"enemy": "basic", "point": "SpawnLeft", "count": 20, "interval": 1.5},
			{"enemy": "basic", "point": "SpawnRight", "count": 20, "interval": 3.0},
			{"enemy": "sword", "point": ["SpawnRight","SpawnTopRight"], "count": 24, "interval": 5.0},
			{"enemy": "big_slime", "point": "SpawnRight", "count": 4, "interval": 5.0},
			{"enemy": "basic", "point": "SpawnBottom", "count": 10, "interval": 3.0},
			{"enemy": "basic", "point": ["SpawnTopRight","SpawnTopLeft"], "count": 10, "interval": 5.0},
		],
		"time_after": 10.0,
	},
	# Wave 9 - Faster Wave, more big slimes
	{
		"spawns": [
			{"enemy": "armoured", "point": "SpawnLeft", "count": 40, "interval": 2.5},
			{"enemy": "big_slime", "point": "SpawnLeft", "count": 32, "interval": 2.5},
			{"enemy": "basic", "point": "SpawnLeft", "count": 40, "interval": 0.75},
			{"enemy": "basic", "point": "SpawnRight", "count": 40, "interval": 1.5},
			{"enemy": "sword", "point": "SpawnRight", "count": 48, "interval": 2.5},
			{"enemy": "big_slime", "point": "SpawnRight", "count": 16, "interval": 2.5},
			{"enemy": "basic", "point": "SpawnBottom", "count": 10, "interval": 0.75},
			{"enemy": "basic", "point": ["SpawnTopRight","SpawnTopLeft"], "count": 10, "interval": 2.5},
		],
		"time_after": 15.0,
	},
	# Wave 10 - Boss Wave
	{
		"spawns": [
			{"enemy": "big_slime", "point": ["SpawnLeft","SpawnRight","SpawnTopLeft","SpawnTopRight"], "count": 50, "interval": 2.5},
			{"enemy": "sword", "point": ["SpawnLeft","SpawnRight","SpawnTopLeft","SpawnTopRight"], "count": 100, "interval": 1.25},
			{"enemy": "armoured", "point": ["SpawnLeft","SpawnRight","SpawnTopLeft","SpawnTopRight"], "count": 100, "interval": 0.5},
			{"enemy": "emperor", "point": "SpawnBottom", "count": 1, "interval": 3.25},
		],
		"wait_for_clear": true,
	},
]
