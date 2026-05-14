extends CanvasLayer

func _ready():
	# Sets the language to Korean on load
	TranslationServer.set_locale('kr')


func _on_setting_pressed() -> void:
	pass # Replace with function body later when you build the settings menu

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LevelScene/StartingScene.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
