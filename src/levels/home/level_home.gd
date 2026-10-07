class_name LevelHome
extends Node2D

## Main house level controller for Caju Game.
## Sets initial player active status and routes character switching to GameManager.

var caju1: CharacterBody2D
var caju2: CharacterBody2D

func _ready() -> void:
	if has_node("Caju"):
		caju1 = get_node("Caju")
	elif has_node("Entities/Players/Caju"):
		caju1 = get_node("Entities/Players/Caju")
		
	if has_node("Caju2"):
		caju2 = get_node("Caju2")
	elif has_node("Entities/Players/Caju2"):
		caju2 = get_node("Entities/Players/Caju2")

	if caju1 and caju1.has_method("make_active"):
		caju1.make_active()
	if caju2 and caju2.has_method("make_inactive"):
		caju2.make_inactive()
