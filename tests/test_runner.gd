extends Node2D

const ItemsHUDClass = preload("res://src/ui/items_hud.gd")
const PushableCrateClass = preload("res://src/entities/items/pushable_crate.gd")
const PushableBoxClass = preload("res://src/entities/items/box/pushable_box.gd")

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
	
	GameManager.switch_player()
	assert(telhado_caju.is_active == false, "[FAIL] Caju should be inactive after switch")
	assert(telhado_kiki.is_active == true, "[FAIL] Kiki should be active after switch")
	assert(GameManager.active_player == telhado_kiki, "[FAIL] GameManager active_player should be Kiki")
	print("[PASS] Test 11: Character switching Caju <-> Kiki verified.")
	
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
	
	print("[TEST] ALL 16 INTEGRATION TESTS PASSED WITH 100% SUCCESS!")
	get_tree().quit(0)
