extends Area2D

# This will create a little folder icon in the Inspector 
# so you can easily pick which scene to load!
@export_file("*.tscn") var next_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Optional: You could add a fade-to-black animation here later!
		
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
		else:
			print("WARNING: No next scene selected for this transition zone!")
