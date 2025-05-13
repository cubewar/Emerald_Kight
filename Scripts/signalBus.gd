extends Node

signal display_dialog(text_key)

func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			SignalBus
		
