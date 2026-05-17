extends Node
class_name FXController

# We export these so you can drag and drop the Player's sprite and camera into the inspector!
@export var target_sprite: AnimatedSprite2D
@export var target_camera: Camera2D 

# --- HIT STOP ---
# Now you can pass custom durations and slow-down amounts!
func play_hit_stop(time_scale: float = 0.1, duration: float = 0.05):
	Engine.time_scale = time_scale
	# We multiply duration by time_scale so the timer respects the slowed-down time
	await get_tree().create_timer(duration * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0

# --- SCREEN SHAKE ---
func play_shake(intensity: float):
	if target_camera and target_camera.has_method("apply_shake"):
		target_camera.apply_shake(intensity)

# --- QUICK COLOR FLASH ---
# Great for taking damage or parrying!
func flash_color(fcolor: Color, duration: float = 0.1):
	if target_sprite:
		var original_color = target_sprite.modulate
		target_sprite.modulate = fcolor
		await get_tree().create_timer(duration).timeout
		target_sprite.modulate = original_color

# --- CONTINUOUS OPACITY / I-FRAMES ---
func set_opacity(alpha: float):
	if target_sprite:
		target_sprite.modulate.a = alpha
