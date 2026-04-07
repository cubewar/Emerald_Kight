extends Node

@onready var level_holder: Node2D = $LevelHolder

# When the game first boots up, load Level 1
func _ready() -> void:
	load_level("res://Scenes/GameScenes/game.tscn") # Make sure this path matches your actual level 1!

func load_level(level_path: String) -> void:
	# 1. Destroy the old level
	for child in level_holder.get_children():
		child.queue_free()
		
	# 2. Wait for the old level to fully delete safely
	await get_tree().process_frame 
		
	# 3. Load the new level from the file path
	var next_level_resource = load(level_path)
	if next_level_resource:
		var next_level_instance = next_level_resource.instantiate()
		level_holder.add_child(next_level_instance)
	else:
		print("Error: Could not load level at path: ", level_path)
