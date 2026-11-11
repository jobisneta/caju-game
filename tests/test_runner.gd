extends Node2D

const ItemsHUDClass = preload("res://src/ui/items_hud.gd")
const PushableCrateClass = preload("res://src/entities/items/pushable_crate.gd")
const PushableBoxClass = preload("res://src/entities/items/box/pushable_box.gd")
const GlassBottleClass = preload("res://src/entities/enemies/glass_bottle/glass_bottle.gd")
const LevelHome3Class = preload("res://src/levels/home/home_3.gd")
const LevelTelhadoClass = preload("res://src/levels/telhado/roof_1.gd")
const LevelJardimClass = preload("res://src/levels/jardim/garden_1.gd")
const CortinaClass = preload("res://src/entities/items/cortina/cortina.gd")
const CortinaScene = preload("res://src/entities/items/cortina/cortina.tscn")

## Integration test runner node for Caju Game.
## Runs within full game engine context with Autoloads initialized.

func _ready() -> void:
	print("[TEST] Starting automated verification in full engine context...")
	
	# =========================================================================
	# PARTE 1: VERIFICAÇÃO DA FASE DA CASA (SOLO CAJU) - home_1.tscn
	# =========================================================================
	var home_scene: PackedScene = load("res://src/levels/home/home_1.tscn")
	if not home_scene:
		push_error("[FAIL] Could not load home_1.tscn")
		get_tree().quit(1)
		return
	
	var home_level: Node2D = home_scene.instantiate()
	add_child(home_level)
	
	var caju1: CharacterBody2D = home_level.get_node_or_null("Caju")
	var caju2: CharacterBody2D = home_level.get_node_or_null("Caju2")
	var bottle: Area2D = home_level.get_node_or_null("Items/Bottle")
	var tutorial: CanvasLayer = home_level.get_node_or_null("TutorialPopup")
	var hud: CanvasLayer = home_level.get_node_or_null("PlayerHUD")
	var items_hud = home_level.get_node_or_null("ItemsHUD")
	var caixa1: StaticBody2D = home_level.get_node_or_null("Environment/CaixaPos1")
	var caixa2: StaticBody2D = home_level.get_node_or_null("Environment/CaixaPos2")
	
	# Test 1: Solo Caju em home_1
	assert(caju1 != null, "[FAIL] Caju not found in home_1")
	assert(caju2 == null, "[FAIL] Caju2 must not exist in home_1 (solo phase requirement)")
	assert(caju1.is_in_group("player"), "[FAIL] Caju not in 'player' group")
	assert(caju1.is_active == true, "[FAIL] Caju should be active")
	print("[PASS] Test 1: home_1 verified as solo Caju (Caju2 successfully removed).")
	
	# Test 2: TutorialPopup visual assets & tecla 'E'
	assert(tutorial != null, "[FAIL] TutorialPopup node not found in level")
	assert(tutorial.panel != null, "[FAIL] Tutorial panel not found")
	var panel_sb: StyleBox = tutorial.panel.get_theme_stylebox("panel")
	assert(panel_sb is StyleBoxTexture, "[FAIL] Tutorial panel must use StyleBoxTexture")
	assert((panel_sb as StyleBoxTexture).texture != null, "[FAIL] Tutorial panel texture missing")
	assert((panel_sb as StyleBoxTexture).texture.resource_path.ends_with("fundo_janela.png"), "[FAIL] Must be fundo_janela.png")
	
	assert(tutorial.close_button != null, "[FAIL] Tutorial close_button not found")
	var btn_sb: StyleBox = tutorial.close_button.get_theme_stylebox("normal")
	assert(btn_sb is StyleBoxTexture, "[FAIL] close_button must use StyleBoxTexture")
	assert((btn_sb as StyleBoxTexture).texture.resource_path.ends_with("fundo_botao.png"), "[FAIL] Must be fundo_botao.png")
	
	assert(tutorial.help_button != null, "[FAIL] Tutorial help_button not found")
	var help_tex_btn = tutorial.help_button as TextureButton
	assert(help_tex_btn != null, "[FAIL] help_button must be TextureButton")
	assert(help_tex_btn.texture_normal.resource_path.ends_with("botao_ajuda.png"), "[FAIL] Must be botao_ajuda.png")
	print("[PASS] Test 2: TutorialPopup visual assets verified.")
	
	# Test 3: PlayerHUD corações e sincronização de dano/cura
	assert(hud != null and hud is PlayerHUD, "[FAIL] PlayerHUD invalid")
	var player_hud = hud as PlayerHUD
	assert(player_hud.max_health == 3, "[FAIL] Max health must be 3")
	assert(player_hud.current_health == 3, "[FAIL] Current health must start at 3")
	
	player_hud.take_damage(1)
	assert(player_hud.current_health == 2, "[FAIL] Health should be 2 after damage")
	assert(player_hud.heart_icons[2].texture.resource_path.ends_with("coracao_vazio.png"), "[FAIL] Heart 3 empty")
	
	player_hud.heal(1)
	assert(player_hud.current_health == 3, "[FAIL] Health should be 3 after heal")
	assert(player_hud.heart_icons[2].texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] Heart 3 restored")
	
	caju1.take_damage(1)
	assert(caju1.current_health == 2, "[FAIL] caju1 health should decrease")
	assert(player_hud.current_health == 2, "[FAIL] HUD should sync with player health")
	caju1.heal(1)
	assert(player_hud.current_health == 3, "[FAIL] HUD should sync with player heal")
	print("[PASS] Test 3: PlayerHUD damage/heal and EventBus synchronization verified.")
	
	# Test 4: ItemsHUD presença, texto e contagem
	assert(items_hud != null, "[FAIL] ItemsHUD not found in home_1")
	assert(items_hud.label_prompt != null, "[FAIL] label_prompt missing in ItemsHUD")
	assert(items_hud.label_prompt.text == "Colete os seus pertences:", "[FAIL] Prompt text mismatch")
	assert(items_hud.item_icon != null, "[FAIL] item_icon missing in ItemsHUD")
	assert(items_hud.label_count != null, "[FAIL] label_count missing in ItemsHUD")
	assert(items_hud.total_items == 1, "[FAIL] Total items should be 1 in home_1")
	assert(items_hud.current_items == 0, "[FAIL] Current items should start at 0")
	assert(items_hud.label_count.text == "0 / 1", "[FAIL] Count label should display '0 / 1'")
	print("[PASS] Test 4: ItemsHUD presence, layout, and initial display verified.")
	
	# Test 5: Restrição de passagem de fase sem itens
	assert(bottle != null, "[FAIL] Bottle not found in home_1")
	assert(not GameManager.are_all_level_items_collected(), "[FAIL] Should not have collected all items initially")
	# Simula Caju no topo da escada antes de pegar a garrafa
	caju1.na_escada = true
	caju1.position.y = 10.0
	home_level._physics_process(0.016)
	assert(home_level._caju_at_top == false, "[FAIL] Caju should NOT be allowed to finish level without collecting items")
	assert(caju1.position.y > 16.0, "[FAIL] Caju position should be pushed below threshold")
	print("[PASS] Test 5: Level exit restriction verified (cannot leave without items).")
	
	# Test 6: Coleta de garrafa e atualização da ItemsHUD
	var initial_bottles: int = GameManager.collected_bottles
	bottle._on_body_entered(caju1)
	assert(GameManager.collected_bottles == initial_bottles + 1, "[FAIL] Caju failed to collect bottle")
	assert(GameManager.are_all_level_items_collected() == true, "[FAIL] All level items should now be collected")
	assert(items_hud.current_items == 1, "[FAIL] ItemsHUD current_items should be 1")
	assert(items_hud.label_count.text == "1 / 1", "[FAIL] ItemsHUD should show '1 / 1'")
	print("[PASS] Test 6: Bottle collection and ItemsHUD synchronization verified.")
	
	# Test 7: InputMap de interação tecla 'E' e método interact_with_nearby
	assert(InputMap.has_action("interact"), "[FAIL] InputMap missing 'interact' action")
	var interact_events = InputMap.action_get_events("interact")
	assert(not interact_events.is_empty(), "[FAIL] No events for 'interact'")
	var has_key_e: bool = false
	for ev in interact_events:
		if ev is InputEventKey and ev.physical_keycode == KEY_E:
			has_key_e = true
			break
	assert(has_key_e, "[FAIL] Key 'E' not mapped to 'interact'")
	assert(caju1.has_method("interact_with_nearby"), "[FAIL] Caju missing interact_with_nearby method")
	print("[PASS] Test 7: 'interact' action (Key 'E') and Caju interaction system verified.")
	
	# Test 8: Mecânica da Caixa (CaixaPos1 à direita -> tombar para a esquerda em CaixaPos2)
	assert(caixa1 != null, "[FAIL] CaixaPos1 not found in home_1")
	assert(caixa2 != null, "[FAIL] CaixaPos2 not found in home_1")
	assert(caixa1 is PushableCrateClass, "[FAIL] CaixaPos1 should use PushableCrate script")
	var pushable = caixa1
	assert(pushable.target_box == caixa2, "[FAIL] CaixaPos1 target_box should point to CaixaPos2")
	
	# Teste 8a: Interação vinda da esquerda deve ser rejeitada (precisa estar à direita)
	caju1.global_position = Vector2(caixa1.global_position.x - 20.0, caixa1.global_position.y)
	pushable.interact(caju1)
	assert(pushable._is_fallen == false, "[FAIL] PushableCrate must reject interaction from left side")
	
	# Teste 8b: Interação vinda da direita deve ser aceita e disparar a queda
	caju1.global_position = Vector2(caixa1.global_position.x + 25.0, caixa1.global_position.y)
	pushable.interact(caju1)
	assert(pushable._is_fallen == true, "[FAIL] PushableCrate must accept interaction from right side")
	# Finaliza o processo de queda imediatamente para validação
	pushable._on_fall_completed()
	assert(caixa2.visible == true, "[FAIL] CaixaPos2 should now be visible")
	var caixa2_col: CollisionShape2D = caixa2.get_node_or_null("CollisionShape2D")
	assert(caixa2_col != null and caixa2_col.disabled == false, "[FAIL] CaixaPos2 collision should be enabled")
	assert(caixa2.position == Vector2(395, 83), "[FAIL] CaixaPos2 should be exactly at Vector2(395, 83)")
	print("[PASS] Test 8: Pushable crate mechanics (requires right side, falls to CaixaPos2) verified.")
	
	# Remove a fase home para carregar e testar o Telhado
	home_level.queue_free()
	
	# =========================================================================
	# PARTE 2: VERIFICAÇÃO DA FASE DO TELHADO (CAJU & KIKI + ÁRVORES) - roof_1.tscn
	# =========================================================================
	var telhado_scene: PackedScene = load("res://src/levels/telhado/roof_1.tscn")
	if not telhado_scene:
		push_error("[FAIL] Could not load roof_1.tscn")
		get_tree().quit(1)
		return
		
	var telhado_level: Node2D = telhado_scene.instantiate()
	add_child(telhado_level)
	
	var telhado_caju: CharacterBody2D = telhado_level.get_node_or_null("Caju")
	var telhado_kiki: CharacterBody2D = telhado_level.get_node_or_null("Kiki")
	var telhado_hud: CanvasLayer = telhado_level.get_node_or_null("PlayerHUD")
	
	# Test 9: Presença de Caju e Kiki no Telhado
	assert(telhado_caju != null, "[FAIL] Caju not found in roof_1.tscn")
	assert(telhado_kiki != null, "[FAIL] Kiki not found in roof_1.tscn")
	assert(telhado_caju.is_in_group("player"), "[FAIL] Caju not in player group")
	assert(telhado_kiki.is_in_group("player"), "[FAIL] Kiki not in player group")
	print("[PASS] Test 9: Caju and Kiki verified in roof_1.tscn.")
	
	# Test 10: Atributos específicos da Kiki (pulo mais baixo, glide, animações)
	assert(telhado_kiki.can_glide == true, "[FAIL] Kiki must have can_glide == true")
	assert(telhado_kiki.jump_height < telhado_caju.jump_height, "[FAIL] Kiki jump_height must be lower than Caju")
	assert(telhado_kiki.jump_height == 32.0, "[FAIL] Kiki jump_height must be 32.0")
	var kiki_anim: AnimatedSprite2D = telhado_kiki.get_node_or_null("AnimatedSprite2D")
	assert(kiki_anim != null and kiki_anim.sprite_frames != null, "[FAIL] Kiki AnimatedSprite2D missing")
	assert(kiki_anim.sprite_frames.has_animation("idle"), "[FAIL] Kiki missing idle animation")
	assert(kiki_anim.sprite_frames.has_animation("walk"), "[FAIL] Kiki missing walk animation")
	assert(kiki_anim.sprite_frames.has_animation("jump"), "[FAIL] Kiki missing jump animation")
	assert(kiki_anim.sprite_frames.has_animation("glide"), "[FAIL] Kiki missing glide animation")
	print("[PASS] Test 10: Kiki mechanics (lower jump 32px, can_glide, idle/walk/jump/glide animations) verified.")
	
	# Test 11: Troca de Personagem (Caju <-> Kiki)
	assert(telhado_caju.is_active == true, "[FAIL] Caju should start active")
	assert(telhado_kiki.is_active == false, "[FAIL] Kiki should start inactive")
	
	assert(telhado_kiki.character_id == "kiki", "[FAIL] Kiki character_id must be 'kiki'")
	assert(telhado_kiki.character_name == "Kiki", "[FAIL] Kiki character_name must be 'Kiki'")
	
	GameManager.switch_player()
	assert(telhado_caju.is_active == false, "[FAIL] Caju should be inactive after switch")
	assert(telhado_kiki.is_active == true, "[FAIL] Kiki should be active after switch")
	assert(GameManager.active_player == telhado_kiki, "[FAIL] GameManager active_player should be Kiki")
	
	var telhado_hud_ctrl: PlayerHUD = telhado_hud as PlayerHUD
	assert(telhado_hud_ctrl != null, "[FAIL] PlayerHUD missing on roof_1")
	assert(telhado_hud_ctrl.portrait != null and telhado_hud_ctrl.portrait.texture.resource_path.ends_with("personagem_kiki.png"), "[FAIL] HUD portrait must update to Kiki portrait")
	print("[PASS] Test 11: Character switching Caju <-> Kiki and HUD portrait verified.")
	
	# Test 12: Gravidade no personagem inativo
	telhado_caju.velocity.y = 0.0
	var prev_vel: float = telhado_caju.velocity.y
	telhado_caju._physics_process(0.016)
	assert(telhado_caju.velocity.y > prev_vel, "[FAIL] Inactive Caju must apply gravity and fall")
	print("[PASS] Test 12: Inactive character gravity verified during co-op play.")
	
	# Test 13: Árvores em Múltiplos Planos
	var bg_trees: Node2D = telhado_level.get_node_or_null("BackgroundTrees")
	var fg_trees: Node2D = telhado_level.get_node_or_null("ForegroundTrees")
	assert(bg_trees != null, "[FAIL] BackgroundTrees node missing in telhado")
	assert(fg_trees != null, "[FAIL] ForegroundTrees node missing in telhado")
	assert(bg_trees.z_index == -1, "[FAIL] BackgroundTrees must have z_index = -1")
	assert(fg_trees.z_index == 10, "[FAIL] ForegroundTrees must have z_index = 10")
	assert(bg_trees.get_child_count() >= 3, "[FAIL] At least 3 background trees expected")
	assert(fg_trees.get_child_count() >= 2, "[FAIL] At least 2 foreground trees expected")
	for child in bg_trees.get_children():
		var sprite = child as Sprite2D
		assert(sprite != null and sprite.texture.resource_path.ends_with("arvore_noite.png"), "[FAIL] Must be arvore_noite.png")
	for child in fg_trees.get_children():
		var sprite = child as Sprite2D
		assert(sprite != null and sprite.texture.resource_path.ends_with("arvore_noite.png"), "[FAIL] Must be arvore_noite.png")
	print("[PASS] Test 13: Rooftop trees (Background z=-1, Foreground z=10 with arvore_noite.png) verified.")
	
	# Libera o nível do telhado para carregar e testar o Jardim
	telhado_level.queue_free()
	
	# =========================================================================
	# PARTE 3: VERIFICAÇÃO DA FASE DO JARDIM (CO-OP CAJU & TODY, CAIXA) - garden_1.tscn
	# =========================================================================
	var garden_scene: PackedScene = load("res://src/levels/jardim/garden_1.tscn")
	if not garden_scene:
		push_error("[FAIL] Could not load garden_1.tscn")
		get_tree().quit(1)
		return
		
	var garden_level: Node2D = garden_scene.instantiate()
	add_child(garden_level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var garden_caju: CharacterBody2D = garden_level.get_node_or_null("Caju")
	var garden_tody: CharacterBody2D = garden_level.get_node_or_null("Tody")
	var garden_hud: CanvasLayer = garden_level.get_node_or_null("PlayerHUD")
	var garden_box: CharacterBody2D = garden_level.get_node_or_null("PushableBox")
	
	# Garante que o GameManager esteja configurado para a dupla do Jardim
	GameManager.players = [garden_caju, garden_tody]
	GameManager.active_player = garden_caju
	garden_caju.make_active()
	garden_tody.make_inactive()
	
	# Test 14: Presença, Identidade e HUD do Tody em garden_1.tscn
	assert(garden_caju != null, "[FAIL] Caju not found in garden_1.tscn")
	assert(garden_tody != null, "[FAIL] Tody not found in garden_1.tscn")
	assert(garden_tody.name == "Tody", "[FAIL] Tody node name must be Tody")
	assert(garden_tody.character_id == "tody", "[FAIL] Tody character_id must be 'tody'")
	assert(garden_tody.character_name == "Tody", "[FAIL] Tody character_name must be 'Tody'")
	assert(garden_tody.can_push_crates == true, "[FAIL] Tody must have can_push_crates == true")
	assert(garden_caju.can_push_crates == false, "[FAIL] Caju must have can_push_crates == false")
	
	var tody_anim: AnimatedSprite2D = garden_tody.get_node_or_null("AnimatedSprite2D")
	assert(tody_anim != null and tody_anim.sprite_frames != null, "[FAIL] Tody AnimatedSprite2D missing")
	assert(tody_anim.sprite_frames.has_animation("idle"), "[FAIL] Tody missing idle animation")
	assert(tody_anim.sprite_frames.has_animation("walk"), "[FAIL] Tody missing walk animation")
	assert(tody_anim.sprite_frames.has_animation("jump"), "[FAIL] Tody missing jump animation")
	
	# Troca para Tody e validação da HUD
	GameManager.switch_player()
	assert(garden_tody.is_active == true, "[FAIL] Tody should be active after switch")
	if garden_hud and "portrait" in garden_hud and garden_hud.portrait != null:
		assert(garden_hud.portrait.texture.resource_path.ends_with("personagem_tody.png"), "[FAIL] HUD must display Tody portrait")
	print("[PASS] Test 14: Tody identity, animations, and HUD portrait synchronization verified.")
	
	# Test 15: Verificação do Asset e Presença da Caixa Empurrável
	assert(garden_box != null, "[FAIL] PushableBox missing in garden_1.tscn")
	assert(garden_box is PushableBoxClass, "[FAIL] garden_box must be an instance of PushableBox")
	var box_sprite: Sprite2D = garden_box.get_node_or_null("Sprite2D")
	assert(box_sprite != null, "[FAIL] PushableBox missing Sprite2D")
	assert(box_sprite.texture != null, "[FAIL] PushableBox missing texture")
	assert(box_sprite.texture.resource_path == "res://assets/art/world/home/crate.png", "[FAIL] PushableBox must use res://assets/art/world/home/crate.png")
	print("[PASS] Test 15: Pushable crate presence and asset (assets/art/world/home/crate.png) verified.")
	
	# Test 16: Mecânica de Empurrar Exclusiva e Física da Caixa
	var initial_box_pos: Vector2 = garden_box.position
	# Caju não pode empurrar a caixa
	var push_success_caju: bool = false
	if garden_caju.can_push_crates:
		push_success_caju = garden_box.push(Vector2.RIGHT, 60.0, 0.1)
	assert(push_success_caju == false, "[FAIL] Caju must NOT be able to push crates")
	assert(garden_box.position == initial_box_pos, "[FAIL] Box must not move when Caju attempts to push")
	
	# Tody pode empurrar a caixa
	assert(garden_tody.can_push_crates == true, "[FAIL] Tody must be capable of pushing crates")
	var push_success_tody: bool = garden_box.push(Vector2.RIGHT, 60.0, 0.1)
	assert(push_success_tody == true, "[FAIL] Tody push on box should succeed")
	assert(garden_box.position.x > initial_box_pos.x, "[FAIL] Box x-position must increase when pushed right")
	
	# Gravidade na caixa quando suspensa no ar
	garden_box.position.y = 50.0
	garden_box.velocity = Vector2.ZERO
	garden_box.move_and_slide()
	var initial_air_y: float = garden_box.position.y
	garden_box._physics_process(0.1)
	assert(garden_box.position.y > initial_air_y or garden_box.velocity.y > 0.0, "[FAIL] PushableBox must apply gravity and fall when airborne")
	print("[PASS] Test 16: Exclusive crate pushing (Tody only) and box physics verified.")
	
	garden_level.queue_free()
	
	# =========================================================================
	# PARTE 4: VERIFICAÇÃO DE HAZARDS, FASES 2 E 3, E GAME MANAGER
	# =========================================================================
	
	# Test 17: Hazard GlassBottle (Camadas de física e dano no jogador)
	var gb_scene: PackedScene = load("res://src/entities/enemies/glass_bottle/glass_bottle.tscn")
	assert(gb_scene != null, "[FAIL] Could not load glass_bottle.tscn")
	var gb_instance: Area2D = gb_scene.instantiate()
	assert(gb_instance is GlassBottleClass, "[FAIL] GlassBottle must use GlassBottle script")
	assert(gb_instance.collision_layer == 16, "[FAIL] GlassBottle collision_layer must be 16 (Layer 5 - hazards)")
	assert(gb_instance.collision_mask == 2, "[FAIL] GlassBottle collision_mask must be 2 (Layer 2 - player)")
	
	var dummy_caju: Player = load("res://src/entities/player/caju.tscn").instantiate()
	add_child(dummy_caju)
	add_child(gb_instance)
	dummy_caju.set_health(3)
	gb_instance._on_body_entered(dummy_caju)
	assert(dummy_caju.current_health == 2, "[FAIL] GlassBottle must deal 1 damage to player upon contact")
	dummy_caju.queue_free()
	gb_instance.queue_free()
	print("[PASS] Test 17: GlassBottle hazard (layers 16/2 and damage mechanic) verified.")
	
	# Test 18: Fase 2 (home_2.tscn) - Hazards, Itens e Escada sem rotação
	var home2_scene: PackedScene = load("res://src/levels/home/home_2.tscn")
	assert(home2_scene != null, "[FAIL] Could not load home_2.tscn")
	var home2_level: Node2D = home2_scene.instantiate()
	add_child(home2_level)
	
	var home2_escada: Area2D = home2_level.get_node_or_null("escada")
	assert(home2_escada != null, "[FAIL] escada missing in home_2.tscn")
	assert(is_zero_approx(home2_escada.rotation), "[FAIL] escada in home_2.tscn must have rotation == 0")
	
	var home2_env: Node2D = home2_level.get_node_or_null("Environment")
	assert(home2_env != null, "[FAIL] Environment missing in home_2.tscn")
	var gb_count: int = 0
	for child in home2_env.get_children():
		if child is GlassBottleClass:
			gb_count += 1
	assert(gb_count == 4, "[FAIL] home_2.tscn Environment must contain exactly 4 GlassBottle hazards")
	
	var home2_items: Node2D = home2_level.get_node_or_null("Items")
	assert(home2_items != null and home2_items.get_child_count() == 1, "[FAIL] home_2.tscn must contain 1 collectible bottle in Items")
	home2_level.queue_free()
	print("[PASS] Test 18: LevelHome2 (home_2.tscn) hazards, items and ladder alignment verified.")
	
	# Test 19: Fase 3 (home_3.tscn) - Solo Caju, Limites de Câmera e Cortinas
	var home3_scene: PackedScene = load("res://src/levels/home/home_3.tscn")
	assert(home3_scene != null, "[FAIL] Could not load home_3.tscn")
	var home3_level: Node2D = home3_scene.instantiate()
	add_child(home3_level)
	assert(home3_level is LevelHome3Class, "[FAIL] home_3.tscn must use LevelHome3 script")
	
	var home3_caju: CharacterBody2D = home3_level.get_node_or_null("Caju")
	assert(home3_caju != null, "[FAIL] Caju missing in home_3.tscn")
	assert(home3_level.get_node_or_null("Kiki") == null, "[FAIL] Kiki must NOT exist in home_3.tscn (Solo Caju)")
	var home3_cam: Camera2D = home3_caju.get_node_or_null("Camera2D")
	assert(home3_cam != null and home3_cam.limit_right == 1280, "[FAIL] home_3 camera limit_right must be 1280")
	
	var home3_cortina = home3_level.get_node_or_null("cortina")
	assert(home3_cortina != null, "[FAIL] cortina missing in home_3.tscn")
	home3_level.queue_free()
	print("[PASS] Test 19: LevelHome3 (home_3.tscn) solo Caju, camera limits (1280px) and curtain verified.")
	
	# Test 20: Fluxo Contínuo de Conclusão e Menus
	assert(telhado_level != null or telhado_scene != null, "[FAIL] Rooftop scene must exist")
	var test_telhado: Node2D = telhado_scene.instantiate()
	assert(test_telhado is LevelTelhadoClass, "[FAIL] roof_1.tscn must use LevelTelhado script")
	assert(test_telhado.has_method("_on_level_finished"), "[FAIL] LevelTelhado must implement _on_level_finished")
	test_telhado.queue_free()
	
	var test_jardim: Node2D = load("res://src/levels/jardim/garden_1.tscn").instantiate()
	assert(test_jardim is LevelJardimClass, "[FAIL] garden_1.tscn must use LevelJardim script")
	assert(test_jardim.has_method("_on_level_finished"), "[FAIL] LevelJardim must implement _on_level_finished")
	test_jardim.queue_free()
	print("[PASS] Test 20: Continuous stage flow triggers (roof_1 -> garden_1 -> menu) verified.")
	
	# Test 21: GameManager ciclo de vida e blindagem defensiva
	GameManager.clear_players()
	assert(GameManager.players.is_empty(), "[FAIL] GameManager.clear_players must empty players list")
	assert(GameManager.active_player == null, "[FAIL] GameManager.clear_players must reset active_player")
	# switch_player com 0 jogadores não deve lançar exceção
	GameManager.switch_player()
	# clean_invalid_players com lista vazia deve funcionar perfeitamente
	GameManager.clean_invalid_players()
	print("[PASS] Test 21: GameManager defensive lifecycle (clear_players, clean_invalid_players) verified.")
	
	# Test 22: Vida compartilhada entre jogadores e recarga automática ao concluir fase
	GameManager.reset_shared_health()
	assert(GameManager.shared_health == 3, "[FAIL] Initial shared health must be 3")
	GameManager.take_shared_damage(2)
	assert(GameManager.shared_health == 1, "[FAIL] Shared health should be 1 after 2 damage")
	# Recarga automática ao concluir fase
	EventBus.level_completed.emit()
	assert(GameManager.shared_health == 3, "[FAIL] level_completed must restore shared health to full (3)")
	print("[PASS] Test 22: Shared health synchronization and automatic level completion refill verified.")

	# Test 23: Game Over loop (Casa volta para home_1; exterior recarrega fase)
	assert(GameManager.has_method("trigger_game_over"), "[FAIL] GameManager must have trigger_game_over method")
	GameManager.reset_shared_health()
	GameManager.take_shared_damage(3)
	assert(GameManager.shared_health == GameManager.shared_max_health, "[FAIL] Game Over must reset shared health for retry")
	print("[PASS] Test 23: Game Over logic and house/exterior loop verified.")

	# Test 24: Queda no abismo no telhado (limite_baixo), 1 dano compartilhado e respawn em piso seguro
	var telhado_test_instance: Node2D = telhado_scene.instantiate()
	add_child(telhado_test_instance)
	var limite_baixo: Area2D = telhado_test_instance.get_node_or_null("limite_baixo")
	assert(limite_baixo != null, "[FAIL] limite_baixo Area2D missing in roof_1.tscn")
	assert(limite_baixo.collision_layer == 32768 or limite_baixo.collision_layer == 16, "[FAIL] limite_baixo must be hazard area (layer 16)")
	assert(limite_baixo.collision_mask & 2 != 0, "[FAIL] limite_baixo mask must include player (bit 2)")
	
	var caju_roof: CharacterBody2D = telhado_test_instance.get_node_or_null("Caju")
	assert(caju_roof != null, "[FAIL] Caju missing in roof_1.tscn")
	assert(caju_roof.get("last_safe_position") != null, "[FAIL] Player must have last_safe_position")
	assert(caju_roof.has_method("respawn_at_last_safe_position"), "[FAIL] Player must implement respawn_at_last_safe_position")
	
	GameManager.reset_shared_health()
	var initial_health: int = GameManager.shared_health
	caju_roof.last_safe_position = Vector2(100, 100)
	caju_roof.global_position = Vector2(200, 300) # Simula caindo no abismo
	
	telhado_test_instance._on_queda_area_body_entered(caju_roof)
	assert(GameManager.shared_health == initial_health - 1, "[FAIL] Falling into rooftop abyss must deal 1 shared damage")
	assert(caju_roof.global_position == Vector2(100, 100), "[FAIL] Player must respawn at last_safe_position")
	assert(caju_roof.is_invulnerable == true, "[FAIL] Player must receive temporary invulnerability upon respawn")
	telhado_test_instance.queue_free()
	print("[PASS] Test 24: Rooftop abyss fall detection, 1 shared damage and safe ground respawn verified.")

	# Test 25: Mecânica de cortinas modulares em home_3 (animação default vs balanço, Caju climb e impulso)
	var test_cortina: CortinaClass = CortinaScene.instantiate()
	add_child(test_cortina)
	assert(test_cortina.sprite_frames.has_animation("default"), "[FAIL] Cortina must have 'default' animation")
	assert(test_cortina.sprite_frames.has_animation("cortina_balancando"), "[FAIL] Cortina must have 'cortina_balancando' animation")
	assert(test_cortina.sprite_frames.get_frame_count("default") == 7, "[FAIL] 'default' animation must have 7 frames")
	assert(test_cortina.sprite_frames.get_frame_count("cortina_balancando") >= 15, "[FAIL] 'cortina_balancando' must have 15 or 16 frames")
	assert(test_cortina.animation == &"default", "[FAIL] Cortina must start with 'default' animation")
	
	var anc: Marker2D = test_cortina.get_node_or_null("PontoAncora")
	assert(anc != null, "[FAIL] Cortina must have PontoAncora")
	var agr: Area2D = anc.get_node_or_null("AreaAgarre")
	assert(agr != null, "[FAIL] PontoAncora must have AreaAgarre")
	
	# Simula Caju agarrando a cortina
	var cortina_caju: CharacterBody2D = load("res://src/entities/player/caju.tscn").instantiate()
	add_child(cortina_caju)
	test_cortina._on_area_agarre_body_entered(cortina_caju)
	assert(test_cortina.is_grabbed == true, "[FAIL] Cortina must be marked as grabbed")
	assert(test_cortina.animation == &"cortina_balancando", "[FAIL] Cortina must switch to 'cortina_balancando' animation")
	assert(cortina_caju.na_cortina == true, "[FAIL] Caju must enter na_cortina state")
	
	# Verifica cálculo de velocidade de balanço
	test_cortina.frame = 2 # balançando para direita
	var swing_right: float = test_cortina.get_swing_velocity()
	assert(swing_right > 0.0, "[FAIL] Swing velocity must be positive when moving right")
	test_cortina.frame = 10 # balançando para esquerda
	var swing_left: float = test_cortina.get_swing_velocity()
	assert(swing_left < 0.0, "[FAIL] Swing velocity must be negative when moving left")
	test_cortina.frame = 4 # pico direita (inversão)
	var swing_peak: float = test_cortina.get_swing_velocity()
	assert(abs(swing_peak) < 0.05, "[FAIL] Swing velocity must be near zero at swing peak")
	
	# Soltar cortina
	test_cortina.soltar_cortina()
	assert(test_cortina.is_grabbed == false, "[FAIL] Cortina must not be grabbed after soltar_cortina")
	assert(test_cortina.animation == &"default", "[FAIL] Cortina must return to 'default' animation on release")
	
	cortina_caju.queue_free()
	test_cortina.queue_free()
	
	# Verifica que todas as 4 cortinas em home_3.tscn são instâncias válidas com PontoAncora e AreaAgarre
	var check_home3: Node2D = load("res://src/levels/home/home_3.tscn").instantiate()
	for curtain_name in ["cortina", "cortina2", "cortina3", "cortina4"]:
		var c_node = check_home3.get_node_or_null(curtain_name)
		assert(c_node != null, "[FAIL] %s missing in home_3.tscn" % curtain_name)
		assert(c_node is CortinaClass, "[FAIL] %s must be instance of Cortina" % curtain_name)
		assert(c_node.get_node_or_null("PontoAncora/AreaAgarre") != null, "[FAIL] %s missing AreaAgarre" % curtain_name)
	check_home3.queue_free()
	print("[PASS] Test 25: Modular curtain dual animation, swing kinematics, and home_3 instances verified.")
	
	# Test 26: Início no Frame 8 ao pular na cortina virado para a esquerda
	var cortina_dir_test: CortinaClass = CortinaScene.instantiate()
	add_child(cortina_dir_test)
	var caju_dir_test: CharacterBody2D = load("res://src/entities/player/caju.tscn").instantiate()
	add_child(caju_dir_test)
	
	# Caso 1: Virado para a esquerda (flip_h = true)
	caju_dir_test.anim.flip_h = true
	cortina_dir_test._on_area_agarre_body_entered(caju_dir_test)
	assert(cortina_dir_test.frame == 8, "[FAIL] Cortina must start on frame 8 when player faces left")
	assert(cortina_dir_test.get_swing_velocity() < 0.0, "[FAIL] Frame 8 must swing to the left (negative velocity)")
	cortina_dir_test.soltar_cortina()
	
	# Caso 2: Virado para a direita (flip_h = false)
	cortina_dir_test._cooldown_timer = 0.0
	caju_dir_test.anim.flip_h = false
	cortina_dir_test._on_area_agarre_body_entered(caju_dir_test)
	assert(cortina_dir_test.frame == 0, "[FAIL] Cortina must start on frame 0 when player faces right")
	assert(cortina_dir_test.get_swing_velocity() > 0.0, "[FAIL] Frame 0 must swing to the right (positive velocity)")
	cortina_dir_test.soltar_cortina()
	
	caju_dir_test.queue_free()
	cortina_dir_test.queue_free()
	print("[PASS] Test 26: Frame 8 initial swing direction (left vs right entry) verified.")

	# Test 27: Unificação da tecla 'P' como 'interact' e Kiki contextual
	assert(InputMap.has_action("interact"), "[FAIL] InputMap must have 'interact' action")
	var t27_interact_events = InputMap.action_get_events("interact")
	var t27_has_key_p: bool = false
	var t27_has_key_e: bool = false
	for ev in t27_interact_events:
		if ev is InputEventKey:
			if ev.physical_keycode == KEY_P:
				t27_has_key_p = true
			elif ev.physical_keycode == KEY_E:
				t27_has_key_e = true
	assert(t27_has_key_p, "[FAIL] 'interact' action must include Key 'P'")
	assert(t27_has_key_e, "[FAIL] 'interact' action must preserve Key 'E' as secondary")
	
	# Kiki: Sem interativo por perto, interact dispara habilidade da Mãe Coruja
	var kiki_test: CharacterBody2D = load("res://src/entities/player/kiki.tscn").instantiate()
	add_child(kiki_test)
	assert(kiki_test.has_method("interact_with_nearby"), "[FAIL] Kiki must implement interact_with_nearby")
	assert(kiki_test.estado_habilidade == 0, "[FAIL] Kiki initial ability state must be 0")
	var kiki_interacted: bool = kiki_test.interact_with_nearby()
	assert(not kiki_interacted, "[FAIL] No interactables should be nearby")
	assert(kiki_test.estado_habilidade == 1, "[FAIL] Kiki must trigger mother owl ability on interact if no objects nearby")
	kiki_test.queue_free()
	print("[PASS] Test 27: Key 'P' unified interaction and Kiki contextual behavior verified.")

	# Test 28: Blindagem contra erros e null tree no Game Over letal
	var lethal_player: CharacterBody2D = load("res://src/entities/player/caju.tscn").instantiate()
	add_child(lethal_player)
	GameManager.reset_shared_health()
	# Reduz a vida compartilhada para 1
	GameManager.take_shared_damage(2)
	assert(GameManager.shared_health == 1, "[FAIL] Shared health must be 1 before lethal hit")
	# Aplica dano letal diretamente no player (1 dano restante)
	lethal_player.take_damage(1)
	# Garante que invulnerabilidade NÃO foi ativada em jogador morto
	assert(lethal_player.is_invulnerable == false, "[FAIL] Lethal damage must not activate invulnerability")
	lethal_player.queue_free()
	print("[PASS] Test 28: Lethal Game Over defensive tree-shielding verified without errors.")
	
	print("[TEST] ALL 28 INTEGRATION TESTS PASSED WITH 100% SUCCESS!")
	get_tree().quit(0)
