extends CanvasLayer

const FULL_HEART := preload("res://full heart.png")
const HALF_HEART := preload("res://half heart.png")
const EMPTY_HEART := preload("res://blank heart.png")

const LIVES_PER_HEART := 2 # 1 heart represent 2 lives
const HEART_SIZE := Vector2(56, 56)
const DIGHT_HEIGHT := 52.0

@onready var hearts_box: HBoxContainer = $Hearts
@onready var money_digits: HBoxContainer = $MoneyDigits
@onready var game_over_label: Label = $GameOverLabel
@onready var wave_label: Label = $WaveLabel

var _hearts: Array[TextureRect] = []
var _digits: Array[Texture2D] = []

func _ready() -> void:
	game_over_label.add_theme_font_override("font", preload("res://scenes/ui/harrington_fixed.tres"))
	wave_label.add_theme_font_override("font", preload("res://scenes/ui/harrington_fixed.tres"))
	for i in 10:
		_digits.append(load("res://%d.png" % i))

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
	var text := str(amount)
	while money_digits.get_child_count() < text.length(): # when there isn't enough picture slots
		# creating a new digit slot
		var digit := TextureRect.new()
		digit.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		digit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		digit.custom_minimum_size.y = DIGHT_HEIGHT
		money_digits.add_child(digit)
	while money_digits.get_child_count() > text.length(): # when there is too many picture slots
		var last := money_digits.get_child(money_digits.get_child_count() - 1)
		money_digits.remove_child(last)
		last.queue_free()
	# adding the digit image into the slots
	for i in text.length():
		money_digits.get_child(i).texture = _digits[int(text[i])]

func show_game_over() -> void:
	game_over_label.show()

func show_wave_started(wave) -> void:
	wave_label.text = "Wave " + str(wave) + " Started!"
	wave_label.show()
	await get_tree().create_timer(5.0).timeout
	wave_label.hide()
