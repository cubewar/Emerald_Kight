extends Node2D

@onready var anim_player = $AnimationPlayer
@export var player: CharacterBody2D # Drag your Player node into this slot in the Inspector!

# --- THE SCRIPT FOR YOUR OPENING SCENE ---
var intro_text = [
	{"name": "Ruby King", "text": "Emerald Knight... the Crystal Kingdom is fracturing."},
	{"name": "Ruby King", "text": "The Trilateral King has grown too bold. His reign of terror must end today."},
	{"name": "Emerald Knight", "text": "My hammer is yours, my King. Where do I find him?"},
	{"name": "Ruby King", "text": "Beyond the jagged peaks. Go. Do not return until the Trilateral King falls."}
]

func _ready() -> void:
	# Start the cutscene the moment the game loads!
	play_opening_cinematic()

func play_opening_cinematic():
	# 1. FREEZE THE PLAYER IMMEDIATELY
	# We don't want the player running around while the king is talking!
	if player:
		player.set_physics_process(false)
		# Optional: Force the player into an "Idle" or "Kneel" animation here
		# player.get_node("AnimatedSprite2D").play("Idle")
	
	# 2. PLAY THE OPENING ANIMATION (e.g., screen fading in)
	anim_player.play("intro_fade_in")
	
	# Wait for the fade-in to finish
	await anim_player.animation_finished 
	
	# Add a tiny dramatic pause before the King speaks (0.5 seconds)
	await get_tree().create_timer(0.5).timeout
	
	# 3. START THE DIALOGUE
	Dialog.start_dialogue(intro_text)
	
	# Wait for the player to read everything and close the text box
	await Dialog.dialogue_finished 
	
	# 4. UNFREEZE THE PLAYER! THE GAME BEGINS!
	if player:
		player.set_physics_process(true)
		
	# Optional: You can queue_free() the director so it deletes itself and saves memory
	queue_free()
