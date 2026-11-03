extends CanvasLayer

@onready var lives_label: Label = $LivesLabel
@onready var game_over_label: Label = $GameOverLabel

func set_lives(lives: int) -> void:
	lives_label.text = "Lives: %d" % lives

func show_game_over() -> void:
	game_over_label.show()
