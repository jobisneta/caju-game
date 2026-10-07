extends Node2D

@onready var player_a: CharacterBody2D = $CharacterBody2D_1
@onready var player_b: CharacterBody2D = $CharacterBody2D_2

var current_player: CharacterBody2D

func _ready() -> void:
	# Define who starts active
	current_player = player_a
	player_a.make_active()
	player_b.make_inactive()

func _unhandled_input(event: InputEvent) -> void:
	# Press 'Tab' or your assigned switch key
	if event.is_action_pressed("ui_focus_next"):
		switch_character()

func switch_character() -> void:
	if current_player == player_a:
		player_a.make_inactive()
		player_b.make_active()
		current_player = player_b
	else:
		player_b.make_inactive()
		player_a.make_active()
		current_player = player_a
