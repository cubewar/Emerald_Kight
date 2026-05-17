extends Camera2D

var shake_strength: float = 0.0
var shake_fade: float = 5.0

# --- LOOK-AHEAD VARIABLES ---
const LOOK_AHEAD_DISTANCE: float = 30.0  # How many pixels forward to look
const LOOK_AHEAD_SPEED: float = 2.0      # How fast the camera pans left/right

var base_offset: Vector2 = Vector2.ZERO  # Stores the smooth look-ahead position

# We grab the player's sprite so we know which way they are facing
@onready var player_sprite = $"../Pivot/AnimatedSprite2D"

func apply_shake(strength: float = 10.0):
	shake_strength = strength

func _process(delta):
	# --- 1. CALCULATE LOOK-AHEAD ---
	var target_offset_x = 0.0
	
	if player_sprite != null:
		if player_sprite.flip_h: # Player is facing Left
			target_offset_x = -LOOK_AHEAD_DISTANCE
		else:                    # Player is facing Right
			target_offset_x = LOOK_AHEAD_DISTANCE
			
	# Smoothly slide our base offset toward the target offset
	base_offset.x = lerpf(base_offset.x, target_offset_x, LOOK_AHEAD_SPEED * delta)


	# --- 2. CALCULATE SCREEN SHAKE ---
	var shake_offset = Vector2.ZERO
	
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		shake_offset.x = randf_range(-shake_strength, shake_strength)
		shake_offset.y = randf_range(-shake_strength, shake_strength)
		

	# --- 3. COMBINE THEM ---
	# We add them together so the camera looks ahead, but still shakes when you hit!
	offset = base_offset + shake_offset
