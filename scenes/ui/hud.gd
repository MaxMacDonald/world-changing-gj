extends CanvasLayer

@onready var lives_label: Label = $LivesLabel
@onready var money_label: Label = $MoneyLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var pause_menu: Panel = $PauseMenu
@onready var exit_button: Button = $PauseMenu/ControlsList/ExitGame
var paused = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	exit_button.pressed.connect(exit_game)

func set_lives(lives: int) -> void:
	lives_label.text = "Lives: %d" % lives

func set_money(amount: int) -> void:
	money_label.text = "Gold: %d" % amount

func show_game_over() -> void:
	game_over_label.show()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if paused:
				get_tree().paused = false
				pause_menu.hide()
				paused = false
			else:
				get_tree().paused = true
				pause_menu.show()
				paused = true
				
func exit_game() -> void:
	get_tree().quit()
