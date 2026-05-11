extends Node2D # (Or whatever node type your Level root is)

func _ready():
	# 1. Connect the UI signal
	$Player.health_changed.connect($HUD/LifeContainer.update_lives)
	
	# 2. THE FIX: Ask the Global script for the health, not the Player!
	$Player.health_changed.emit(Global.current_health, Global.max_health)
