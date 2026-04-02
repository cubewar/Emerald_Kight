extends Camera2D

var shake_strength: float = 0.0
var shake_fade: float = 5.0

func apply_shake(strength: float = 10.0):
	shake_strength = strength

func _process(delta):
	if shake_strength > 0:
		# Fade out the shake over time
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		
		# Apply random offset to the camera
		var random_x = randf_range(-shake_strength, shake_strength)
		var random_y = randf_range(-shake_strength, shake_strength)
		offset = Vector2(random_x, random_y)
