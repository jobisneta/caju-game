extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func _on_botao_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/menu_principal.tscn")
	pass # Replace with function body.
