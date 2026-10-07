extends Node

## Global Event Bus for Caju Game.
## Enables decoupled communication between entities, UI, and managers.

@warning_ignore("unused_signal")
signal player_swapped(active_player: CharacterBody2D)
@warning_ignore("unused_signal")
signal player_jumped(player: CharacterBody2D)
@warning_ignore("unused_signal")
signal player_landed(player: CharacterBody2D)
@warning_ignore("unused_signal")
signal item_collected(item_name: String, collector: CharacterBody2D)
@warning_ignore("unused_signal")
signal level_completed
