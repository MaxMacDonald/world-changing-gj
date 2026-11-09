extends CanvasLayer

const FULL_HEART := preload("res://full heart.png")
const HALF_HEART := preload("res://half heart.png")
const EMPTY_HEART := preload("res://blank heart.png")

const LIVES_PER_HEART := 2 # 1 heart represent 2 lives
const HEART_SIZE := Vector2(56, 56)

@onready var hearts_box: HBoxContainer = $Hearts
@onready var money_label: Label = $MoneyLabel
@onready var game_over_label: Label = $GameOverLabel

var _hearts: Array[TextureRect] = []

# create a full row of 10 hearts
func set_max_lives(max_lives: int) -> void:
	for heart in _hearts:
		heart.queue_free()
	_hearts.clear()
	var count := ceili(max_lives / float(LIVES_PER_HEART))
	for i in count:
		var heart := TextureRect.new()
		heart.texture = FULL_HEART
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = HEART_SIZE
		hearts_box.add_child(heart)
		_hearts.append(heart)

func set_lives(lives: int) -> void:
	for i in _hearts.size():
		var left := lives - i * LIVES_PER_HEART
		if left >= LIVES_PER_HEART:
			_hearts[i].texture = FULL_HEART
		elif left > 0:
			_hearts[i].texture = HALF_HEART
		else:
			_hearts[i].texture = EMPTY_HEART

func set_money(amount: int) -> void:
	money_label.text = "%d" % amount

func show_game_over() -> void:
	game_over_label.show()
