extends Node2D

## Integration test runner node.
## Runs within full game engine context with Autoloads initialized.

func _ready() -> void:
	print("[TEST] Starting automated verification in full engine context...")
	
	# Load main scene
	var level_scene: PackedScene = load("res://src/levels/home/level_home.tscn")
	if not level_scene:
		push_error("[FAIL] Could not load level_home.tscn")
		get_tree().quit(1)
		return
	
	var level: Node2D = level_scene.instantiate()
	add_child(level)
	
	var caju1: CharacterBody2D = level.get_node_or_null("Caju")
	var caju2: CharacterBody2D = level.get_node_or_null("Caju2")
	var bottle: Area2D = level.get_node_or_null("Items/Bottle")
	
	# Test 1: Verify player instances
	assert(caju1 != null, "[FAIL] Caju1 not found")
	assert(caju2 != null, "[FAIL] Caju2 not found")
	assert(caju1.is_in_group("player"), "[FAIL] Caju1 not in 'player' group")
	assert(caju2.is_in_group("player"), "[FAIL] Caju2 not in 'player' group")
	print("[PASS] Test 1: Both player instances found and in group 'player'.")
	
	# Test 2: Character switching
	assert(caju1.is_active == true, "[FAIL] Caju1 should be initially active")
	assert(caju2.is_active == false, "[FAIL] Caju2 should be initially inactive")
	
	# Switch via GameManager
	GameManager.switch_player()
	assert(caju1.is_active == false, "[FAIL] Caju1 should now be inactive")
	assert(caju2.is_active == true, "[FAIL] Caju2 should now be active")
	assert(GameManager.active_player == caju2, "[FAIL] GameManager active_player mismatch")
	print("[PASS] Test 2: Character switching toggles active states properly via GameManager.")
	
	# Test 3: Inactive character gravity (verifying it does not freeze in mid-air!)
	caju1.velocity.y = 0.0
	var prev_vel_y: float = caju1.velocity.y
	# Simulate physics process on inactive character
	caju1._physics_process(0.016)
	assert(caju1.velocity.y > prev_vel_y, "[FAIL] Inactive character must apply gravity and fall!")
	print("[PASS] Test 3: Inactive character calculates gravity correctly (anti-levitation fix verified).")
	
	# Test 4: Bottle collection by Caju 2 (verifying player 2 can collect items!)
	assert(bottle != null, "[FAIL] Bottle not found")
	var initial_bottles: int = GameManager.collected_bottles
	bottle._on_body_entered(caju2)
	assert(GameManager.collected_bottles == initial_bottles + 1, "[FAIL] Caju2 failed to collect bottle!")
	print("[PASS] Test 4: Caju2 successfully collected bottle (bottle collection bug fixed).")
	
	print("[TEST] ALL 4 CRITICAL CHECKS PASSED WITH FLYING COLORS!")
	get_tree().quit(0)
