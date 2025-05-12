extends Control


func on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")


func setting_pressed() -> void:
	pass # Replace with function body.


func exit_pressed() -> void:
	get_tree().quit()
