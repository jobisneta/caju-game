class_name Player
extends CharacterBody2D

## 2D Platformer Player Controller for Caju Game.
## Features kinematic jump physics, coyote time, jump buffering,
## smooth acceleration/friction, and decoupled active/inactive state handling.

signal activated
signal deactivated
signal health_changed(current: int, max_val: int)
signal interacted(target: Node2D)

@export_group("Identity")
@export var character_id: String = "caju"
@export var character_name: String = "Caju"
@export var portrait_texture: Texture2D = null

@export_group("Glide Mechanics")
@export var can_glide: bool = false
@export var glide_max_fall_speed: float = 35.0
@export var glide_gravity_scale: float = 0.15

@export_group("Push Mechanics")
@export var can_push_crates: bool = false
@export var push_speed: float = 60.0

@export_group("Health")
@export var max_health: int = 3
@export var current_health: int = 3

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

var na_escada: bool = false
var is_gliding: bool = false
const VELOCIDADE_ESCALADA = 150.0 # Ajuste a velocidade como preferir

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
	
	# --- LÓGICA DE ESCADA VS GRAVIDADE ---
	if na_escada:
		is_gliding = false
		if is_active:
			# Somente o personagem ativo pode subir/descer a escada
			# Suporta perfeitamente WASD (W/S) e setas direcionais (Cima/Baixo)
			var move_dir: float = 0.0
			if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("jump") or Input.is_action_pressed("ui_up"):
				move_dir -= 1.0
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
				move_dir += 1.0
			velocity.y = move_dir * VELOCIDADE_ESCALADA
		else:
			# Personagem inativo fica parado na escada (sem gravidade, sem movimento)
			velocity.y = 0.0
			velocity.x = 0.0
	else:
		var gravity: float = jump_gravity if velocity.y < 0.0 else fall_gravity
		if not is_on_floor():
			if can_glide and is_active and velocity.y > 0.0 and (Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept")):
				is_gliding = true
				velocity.y += gravity * glide_gravity_scale * delta
				if velocity.y > glide_max_fall_speed:
					velocity.y = glide_max_fall_speed
			else:
				is_gliding = false
				velocity.y += gravity * delta
		else:
			is_gliding = false
			
	# Check landing for signals
	if not _was_on_floor and is_on_floor():
		if has_node("/root/EventBus"):
			get_node("/root/EventBus").player_landed.emit(self)
	_was_on_floor = is_on_floor()
	
	move_and_slide()
	_handle_push_crates(delta)
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
	# (Não permite pular se estiver no meio da escada para evitar bugs)
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and not na_escada:
		_execute_jump()
	
	# Variable jump height: release early to perform micro-jumps
	if _is_jump_just_released() and velocity.y < 0.0:
		velocity.y *= 0.5

	# Interaction with items / objects (Key 'E')
	if Input.is_action_just_pressed("interact"):
		interact_with_nearby()

func interact_with_nearby() -> bool:
	if not is_inside_tree():
		return false
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28.0
	query.shape = shape
	query.transform = global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true
	# Layer 10 (interactables, bit 10 = 512) + Layer 1 (world = 1)
	query.collision_mask = 512 | 1
	
	var results = space_state.intersect_shape(query, 16)
	for hit in results:
		var collider = hit.collider
		if collider and collider != self and collider.has_method("interact"):
			collider.interact(self)
			interacted.emit(collider)
			if has_node("/root/EventBus"):
				get_node("/root/EventBus").player_interacted.emit(self, collider)
			return true
	
	# Checagem adicional: nós no grupo "interactable" no alcance
	var interactables = get_tree().get_nodes_in_group("interactable")
	for node in interactables:
		if node is Node2D and node != self and global_position.distance_to(node.global_position) <= 36.0:
			if node.has_method("interact"):
				node.interact(self)
				interacted.emit(node)
				if has_node("/root/EventBus"):
					get_node("/root/EventBus").player_interacted.emit(self, node)
				return true

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").player_interacted.emit(self, null)
	return false

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
	
	# --- PRIORIDADE MÁXIMA: Escada ---
	if na_escada:
		if abs(velocity.y) > 1.0:
			anim.play("climb")
		else:
			# Parado na escada: mostra frame da animação climb sem animar
			if anim.animation != "climb":
				anim.play("climb")
			anim.pause()
		return # Interrompe aqui para não rodar mais nada!
	
	# --- Restantes animações (Chão / Pulo / Planar) ---
	if is_on_floor():
		if abs(velocity.x) > 5.0:
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		if is_gliding:
			anim.play("glide")
		else:
			anim.play("jump")

func make_active() -> void:
	is_active = true
	if camera:
		camera.enabled = true
		camera.make_current()
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").active_player = self
	activated.emit()

func make_inactive() -> void:
	is_active = false
	if camera:
		camera.enabled = false
	deactivated.emit()

func set_camera_limits(left: int, right: int, top: int, bottom: int) -> void:
	if camera:
		camera.limit_left = left
		camera.limit_right = right
		camera.limit_top = top
		camera.limit_bottom = bottom

func take_damage(amount: int = 1) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").player_health_changed.emit(self, current_health, max_health)

func heal(amount: int = 1) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").player_health_changed.emit(self, current_health, max_health)

func set_health(val: int) -> void:
	current_health = clampi(val, 0, max_health)
	health_changed.emit(current_health, max_health)
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").player_health_changed.emit(self, current_health, max_health)

func _exit_tree() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").unregister_player(self)

func _handle_push_crates(delta: float) -> void:
	if not is_active or not can_push_crates:
		return
	
	var input_dir: float = _get_horizontal_input()
	if input_dir == 0.0:
		return
		
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.has_method("push"):
			var normal = collision.get_normal()
			# Colisão horizontal na direção oposta à normal (ou seja, jogador indo contra a caixa)
			if abs(normal.x) > 0.6 and sign(-normal.x) == sign(input_dir):
				var pushed = collider.push(Vector2(input_dir, 0.0), push_speed, delta)
				if pushed:
					velocity.x = input_dir * push_speed
