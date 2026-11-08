class_name Wallet extends Node
## Holds the player's money.

signal changed(amount: int)

@export var starting_money := 1000000 # Should be 200 but set to 1 million for debugging since game is too hard right now

var money := 0

func _ready() -> void:
	money = starting_money

func can_afford(cost: int) -> bool:
	return money >= cost

func add(amount: int) -> void:
	money += amount
	changed.emit(money)
	Sound.play("money_receive", -12.0)

## Returns true (and deducts the cost) if the player can afford it.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	money -= cost
	changed.emit(money)
	return true
