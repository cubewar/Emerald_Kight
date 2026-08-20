extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D 

# --- TRACKING THE HITS ---
var hit_count: int = 0
var has_spoken_warning: bool = false

# The dialogue to play when the player is being annoying
var warning_text = [
	{
		"name": "Ruby King", 
		"text": "Have you lost your mind, Emerald Knight?! Save your strength for the Trilateral King!", 
		"pitch": 0.75 # Deep kingly voice
	}
]

func _ready() -> void:
	if anim_sprite:
		# Updated to capital "Idle"
		anim_sprite.play("Idle") 

func take_damage(amount: int, hit_direction: float = 0.0) -> void:
	# 1. Count the hit!
	hit_count += 1
	
	# 2. Trigger the dialogue if hit 3 times (and only if he hasn't spoken yet!)
	if hit_count == 6 and not has_spoken_warning:
		has_spoken_warning = true # Lock the door so this never happens again
		Dialog.start_dialogue(warning_text)
	
	# 3. Play the hurt animation
	if anim_sprite:
		# Updated to capital "Hurt"
		anim_sprite.play("Hurt") 
		
		# Optional: Play a hit sound effect
		# SoundManager.play_sfx("enemy_hurt")
		
		# Wait for a fraction of a second so the flinch is visible
		await get_tree().create_timer(0.4).timeout
		
		# Return to the Idle animation
		anim_sprite.play("Idle")
