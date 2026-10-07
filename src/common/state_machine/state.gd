class_name State
extends Node

## Base class for states in a node-based finite state machine.

signal transitioned(state: State, new_state_name: String)

var actor: CharacterBody2D

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func frame_update(_delta: float) -> void:
	pass
