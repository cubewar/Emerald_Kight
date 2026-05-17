extends HBoxContainer

# Drag your two 32x32 textures into these slots in the Inspector!
@export var life_full: Texture2D
@export var life_empty: Texture2D

func update_lives(current_health: int, max_health: int):
	# 1. Delete the old life icons
	for child in get_children():
		child.queue_free()
		
	# 2. Draw the new life icons based on Max Health
	for i in range(max_health):
		var life_icon = TextureRect.new()
		
		# If the current loop number is less than our health, it's a full life!
		if i < current_health:
			life_icon.texture = life_full
		else:
			life_icon.texture = life_empty
			
		# Force it to stay exactly 32x32 pixels
		life_icon.custom_minimum_size = Vector2(32, 32)
		life_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		
		# Add it to our HBoxContainer
		add_child(life_icon)
