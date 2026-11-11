class_name Cortina
extends AnimatedSprite2D

## Cortina com mecânica de balanço e agarre.
## Permite que o jogador (especificamente Caju) se agarre, acompanhe o balanço
## simétrico da animação e salte com transferência de impulso horizontal.

const SWING_OFFSETS: Array[float] = [
	0.5,   # frame 0: centro
	2.5,   # frame 1: balanço direita
	7.0,   # frame 2
	13.0,  # frame 3
	17.5,  # frame 4: pico direita (inversão)
	13.0,  # frame 5: retornando
	7.0,   # frame 6
	2.5,   # frame 7
	0.5,   # frame 8: centro
	-3.5,  # frame 9: balanço esquerda
	-7.0,  # frame 10
	-14.0, # frame 11
	-18.5, # frame 12: pico esquerda (inversão)
	-14.0, # frame 13: retornando
	-7.0,  # frame 14
	-3.5   # frame 15
]

const DEFAULT_ANCHOR_Y: float = 9.5

@onready var ponto_ancora: Marker2D = $PontoAncora
@onready var area_agarre: Area2D = $PontoAncora/AreaAgarre

var is_grabbed: bool = false
var player_agarrado: Node2D = null
var _cooldown_timer: float = 0.0

func _ready() -> void:
	play("default")
	if area_agarre:
		area_agarre.body_entered.connect(_on_area_agarre_body_entered)
	frame_changed.connect(_on_frame_changed)
	_update_anchor_position()

func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = max(0.0, _cooldown_timer - delta)

func _on_frame_changed() -> void:
	_update_anchor_position()

func _update_anchor_position() -> void:
	if not ponto_ancora:
		return
	if animation == &"cortina_balancando":
		var current_frame: int = frame
		if current_frame >= 0 and current_frame < SWING_OFFSETS.size():
			ponto_ancora.position = Vector2(SWING_OFFSETS[current_frame], DEFAULT_ANCHOR_Y)
	else:
		ponto_ancora.position = Vector2(0.0, DEFAULT_ANCHOR_Y)

func _on_area_agarre_body_entered(body: Node2D) -> void:
	if _cooldown_timer > 0.0 or is_grabbed:
		return
	
	if body.is_in_group("player") and body.has_method("agarrar_cortina"):
		is_grabbed = true
		player_agarrado = body
		
		# Quando pular numa cortina olhando/movendo-se para a esquerda,
		# inicia no frame 8 (balanço à esquerda) para o movimento ser natural.
		var is_facing_left: bool = false
		if "anim" in body and body.anim and body.anim.flip_h:
			is_facing_left = true
		elif "velocity" in body and body.velocity.x < -10.0:
			is_facing_left = true
			
		play("cortina_balancando")
		if is_facing_left:
			frame = 8
		else:
			frame = 0
			
		_update_anchor_position()
		body.agarrar_cortina(self, ponto_ancora)

func soltar_cortina() -> void:
	is_grabbed = false
	player_agarrado = null
	_cooldown_timer = 0.35
	play("default")
	_update_anchor_position()

func get_swing_velocity() -> float:
	if animation != &"cortina_balancando":
		return 0.0
	var f: int = frame
	var next_f: int = (f + 1) % SWING_OFFSETS.size()
	var prev_f: int = (f - 1 + SWING_OFFSETS.size()) % SWING_OFFSETS.size()
	var raw_vel: float = (SWING_OFFSETS[next_f] - SWING_OFFSETS[prev_f]) / 2.0
	return clampf(raw_vel / 5.5, -1.0, 1.0)
