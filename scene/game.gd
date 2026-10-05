extends Node2D

@onready var caju1: CharacterBody2D = $Caju
@onready var caju2: CharacterBody2D = $Caju2

var current_player: CharacterBody2D

func _ready() -> void:
	# Define who starts active
	current_player = caju1
	caju1.make_active()
	caju2.make_inactive()

func _unhandled_input(event: InputEvent) -> void:
	# Press 'Tab' or your assigned switch key
	if event.is_action_pressed("ui_focus_next"):
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
