extends Node2D

## Legacy / Root game controller.
## Routes input to GameManager and supports fallback switching.

@onready var caju1: CharacterBody2D = $Caju
@onready var caju2: CharacterBody2D = $Caju2

var current_player: CharacterBody2D

func _ready() -> void:
	current_player = caju1
	if caju1 and caju1.has_method("make_active"):
		caju1.make_active()
	if caju2 and caju2.has_method("make_inactive"):
		caju2.make_inactive()

func _unhandled_input(event: InputEvent) -> void:
	# Only use local fallback when GameManager autoload is not present.
	# GameManager already listens for switch_character globally.
	if not has_node("/root/GameManager"):
		if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
			switch_character()

func switch_character() -> void:
	if current_player == caju1:
		caju1.make_inactive()
		caju2.make_active()
		current_player = caju2
	else:
		caju2.make_inactive()
		caju1.make_active()
		current_player = caju1


func _on_escada_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_escada_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
