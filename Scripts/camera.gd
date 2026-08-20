extends Camera2D

var shake_strength: float = 0.0
var shake_fade: float = 5.0

# --- LOOK-AHEAD VARIABLES ---
const LOOK_AHEAD_DISTANCE_X: float = 30.0  # How many pixels forward to look
const LOOK_AHEAD_DISTANCE_Y: float = 60.0  # How far to peek up or down
const LOOK_AHEAD_SPEED: float = 2.0        # How fast the camera pans

# --- DEFAULT VERTICAL OFFSET ---
# A negative number moves the camera UP, so the player sits slightly lower on the screen
const DEFAULT_Y_OFFSET: float = -20.0 

var base_offset: Vector2 = Vector2(0, DEFAULT_Y_OFFSET)  

# We grab the player's sprite so we know which way they are facing
@onready var player_sprite = $"../Pivot/AnimatedSprite2D"

func apply_shake(strength: float = 10.0):
	shake_strength = strength

func _process(delta):
	# --- 1. CALCULATE TARGET OFFSETS ---
	var target_offset_x = 0.0
	var target_offset_y = DEFAULT_Y_OFFSET
	
	# Horizontal Look-Ahead
	if player_sprite != null:
		if player_sprite.flip_h: # Player is facing Left
			target_offset_x = -LOOK_AHEAD_DISTANCE_X
		else:                    # Player is facing Right
			target_offset_x = LOOK_AHEAD_DISTANCE_X
			
	# Vertical Look-Ahead (Peeking Up/Down)
	# NOTE: Change "ui_up" and "ui_down" to match your actual Input Map names if different!
	if Input.is_action_pressed("ui_up"):
		target_offset_y = DEFAULT_Y_OFFSET - LOOK_AHEAD_DISTANCE_Y
	elif Input.is_action_pressed("ui_down"):
		target_offset_y = DEFAULT_Y_OFFSET + LOOK_AHEAD_DISTANCE_Y
			
	# Smoothly slide our base offset toward the target offsets
	base_offset.x = lerpf(base_offset.x, target_offset_x, LOOK_AHEAD_SPEED * delta)
	base_offset.y = lerpf(base_offset.y, target_offset_y, LOOK_AHEAD_SPEED * delta)


	# --- 2. CALCULATE SCREEN SHAKE ---
	var shake_offset = Vector2.ZERO
	
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		shake_offset.x = randf_range(-shake_strength, shake_strength)
		shake_offset.y = randf_range(-shake_strength, shake_strength)
		

	# --- 3. COMBINE THEM ---
	# We add them together so the camera looks ahead, but still shakes when you hit!
	offset = base_offset + shake_offset
