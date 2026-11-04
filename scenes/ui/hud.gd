extends CanvasLayer

@onready var lives_label: Label = $LivesLabel
@onready var money_label: Label = $MoneyLabel
@onready var game_over_label: Label = $GameOverLabel

func set_lives(lives: int) -> void:
	lives_label.text = "Lives: %d" % lives

func set_money(amount: int) -> void:
	money_label.text = "Gold: %d" % amount

func show_game_over() -> void:
	game_over_label.show()
