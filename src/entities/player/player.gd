class_name Player
extends CharacterBody2D

## 2D Platformer Player Controller for Caju Game.
## Features kinematic jump physics, coyote time, jump buffering,
## smooth acceleration/friction, and decoupled active/inactive state handling.

signal activated
signal deactivated

@export_group("Movement")
@export var speed: float = 120.0
@export var acceleration: float = 900.0
@export var friction: float = 800.0

@export_group("Kinematic Jump")
@export var jump_height: float = 48.0
@export var jump_time_to_peak: float = 0.32
@export var jump_time_to_descent: float = 0.26

@export_group("Game Feel")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.10

@export_group("State")
@export var is_active: bool = false

# Internal kinematics
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

# Timers
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false

# Node references with fallback for node name variations
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") if get_node_or_null("AnimatedSprite2D") else get_node_or_null("AnimatedSprite2D2")
@onready var camera: Camera2D = get_node_or_null("Camera2D")

func _ready() -> void:
	add_to_group("player")
	_calculate_kinematics()
	
	# Register with GameManager if present
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").register_player(self)
	
	if is_active:
		make_active()
	else:
		make_inactive()

func _calculate_kinematics() -> void:
	jump_velocity = - (2.0 * jump_height) / jump_time_to_peak
	jump_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	fall_gravity = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

func _physics_process(delta: float) -> void:
	# Update coyote time
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(0.0, _coyote_timer - delta)
	
	# Update jump buffer
	_jump_buffer_timer = max(0.0, _jump_buffer_timer - delta)
	
	if is_active:
		_process_active_input(delta)
	else:
		_process_inactive_physics(delta)
	
	# Apply gravity (both active and inactive players fall naturally!)
	var gravity: float = jump_gravity if velocity.y < 0.0 else fall_gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Check landing for signals
	if not _was_on_floor and is_on_floor():
		if has_node("/root/EventBus"):
			get_node("/root/EventBus").player_landed.emit(self)
	_was_on_floor = is_on_floor()
	
	move_and_slide()
	_update_animation()

func _process_active_input(delta: float) -> void:
	# Horizontal movement with acceleration and friction
	var direction: float = _get_horizontal_input()
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		if anim:
			anim.flip_h = (direction < 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	
	# Register jump buffer
	if _is_jump_just_pressed():
		_jump_buffer_timer = jump_buffer_time
	
	# Execute jump when buffer is valid and either on floor or in coyote time
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_execute_jump()
	
	# Variable jump height: release early to perform micro-jumps
	if _is_jump_just_released() and velocity.y < 0.0:
		velocity.y *= 0.5

func _process_inactive_physics(delta: float) -> void:
	# Inactive character decelerates smoothly and maintains physics
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _execute_jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").player_jumped.emit(self)

func _get_horizontal_input() -> float:
	var axis: float = 0.0
	if Input.is_action_pressed("right") or Input.is_action_pressed("move_right"):
		axis += 1.0
	if Input.is_action_pressed("left") or Input.is_action_pressed("move_left"):
		axis -= 1.0
	return axis

func _is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")

func _is_jump_just_released() -> bool:
	return Input.is_action_just_released("jump") or Input.is_action_just_released("ui_accept")

func _update_animation() -> void:
	if not anim:
		return
	
	if is_on_floor():
		if abs(velocity.x) > 5.0:
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		if velocity.y < 0.0:
			# Play full jump animation on ascent
			if anim.sprite_frames and anim.sprite_frames.has_animation("jump"):
				anim.play("jump")
			elif anim.sprite_frames and anim.sprite_frames.has_animation("jump_1"):
				anim.play("jump_1")
		else:
			# Falling frame on descent
			if anim.sprite_frames and anim.sprite_frames.has_animation("jump_1"):
				anim.play("jump_1")
			elif anim.sprite_frames and anim.sprite_frames.has_animation("jump"):
				anim.play("jump")

func make_active() -> void:
	is_active = true
	if camera:
		camera.enabled = true
		camera.make_current()
	activated.emit()

func make_inactive() -> void:
	is_active = false
	if camera:
		camera.enabled = false
	deactivated.emit()

func _exit_tree() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").unregister_player(self)
