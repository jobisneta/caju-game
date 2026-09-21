extends CharacterBody2D

@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0
@export var is_active: bool = false
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	if is_active:
		camera.make_current()
	else:
		camera.enabled = false


func _physics_process(delta: float) -> void:
	
	if not is_active:
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func make_active() -> void:
	is_active = true
	camera.enabled = true
	camera.make_current()

func make_inactive() -> void:
	is_active = false
	camera.enabled = false
