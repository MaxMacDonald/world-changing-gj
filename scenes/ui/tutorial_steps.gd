extends RefCounted
## The tutorial, as data. Edit the text or reorder steps here.
##
## Each step is a dictionary:
##   "title"     : heading
##   "text"      : body text. {c1} {c2} = terraform costs, {tower} {tower_name} = first catalog tower
##   "wait"      : what completes the step
##                   "continue"        - player presses the button
##                   "raise"           - any tile is raised
##                   "wall"            - any tile reaches +2 (skipped if one already exists)
##                   "terraform_exit"  - player leaves terraform mode (skipped if not in it)
##                   "tower_placed"    - a tower is built
##                   "tower_selected"  - a tower is clicked
##                   "tower_upgraded"  - an upgrade is bought
##   "button"    : (optional) label of the Continue button
##   "min_gold"  : (optional) top the player's gold up to at least this when the step starts,
##                 so they can always afford what the step asks for
##   "highlight" : (optional) pulsing rings: "base" and/or "spawns"
##
## Gold is reset to the normal starting amount when the tutorial ends.

const STEPS := [
	{
		"title": "Defend your base!",
		"text": "Waves of enemies march from the marked zones toward your base. Every one that reaches it costs a life, and if you run out of lives it's game over.\n\nSurvive every wave to win! Let's learn the tools.",
		"wait": "continue",
		"button": "Show me!",
		"highlight": ["base", "spawns"],
	},
	{
		"title": "Reshape the land",
		"text": "Right click the ground to open the build wheel and choose Terraform (T). Then LEFT CLICK a tile to raise it into a pit ({c1} gold). Drag to paint several tiles.",
		"wait": "raise",
		"min_gold": 100,
	},
	{
		"title": "pits and walls",
		"text": "Pits slow enemies down. Click a pit again to make it a WALL ({c2} gold). Walls block enemies and bullets, so put one in their way! If the way around is too long, the enemies might try to dig a tunnel through instead.\n",
		"wait": "wall",
		"min_gold": 100,
	},
	{
		"title": "Done terraforming",
		"text": "Right click to leave terraform mode.",
		"wait": "terraform_exit",
	},
	{
		"title": "Build a tower",
		"text": "Right click empty ground to open the build wheel, pick the {tower_name}, then LEFT CLICK to place it ({tower} gold).\n\n",
		"wait": "tower_placed",
		"min_gold": 150,
	},
	{
		"title": "Select your tower",
		"text": "LEFT CLICK your tower to see its range and open its upgrade wheel.",
		"wait": "tower_selected",
	},
	{
		"title": "Upgrade it",
		"text": "Pick an upgrade from the wheel: damage, fire rate or range. SELL is always at the bottom if you change your mind.\n\nThe wheel closed? Click the tower to open it again.",
		"wait": "tower_upgraded",
		"min_gold": 100,
	},
	{
		"title": "You can fight too!",
		"text": "If you need to you can squish the slimes by hand. It doesn't do much damage though!",
		"wait": "continue",
		"button": "Ok!",
	},
	{
		"title": "You're ready!",
		"text": "Spend your gold wisely, mix walls and towers, and protect the base. Press ESC any time to pause.\n\nGood luck!",
		"wait": "continue",
		"button": "Start!",
	},
]
