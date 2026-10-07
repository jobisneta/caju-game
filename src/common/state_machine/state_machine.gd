class_name StateMachine
extends Node

## StateMachine node to manage states and active transitions.

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func init(actor: CharacterBody2D) -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.actor = actor
			child.transitioned.connect(_on_child_transitioned)
	
	if initial_state:
		current_state = initial_state
		current_state.enter()

func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func frame_update(delta: float) -> void:
	if current_state:
		current_state.frame_update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("StateMachine: state '%s' does not exist." % new_state_name)
		return
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()

func _on_child_transitioned(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
	transition_to(new_state_name)
