extends Area2D

@export_file("*.tscn") var next_level_path: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		if next_level_path != "":
			
			# Find the Main scene at the very top of the game tree
			var main_scene = get_tree().root.get_node("Main")
			
			if main_scene:
				# Tell Main to do the swap!
				main_scene.load_level(next_level_path)
			else:
				print("Error: Could not find the Main scene!")
