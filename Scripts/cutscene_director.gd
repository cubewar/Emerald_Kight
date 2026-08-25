extends Node2D

@onready var anim_player = $AnimationPlayer
@export var player: CharacterBody2D # Drag your Player node into this slot in the Inspector!

# --- THE SCRIPT FOR YOUR OPENING SCENE ---
var intro_text = [
	{
		"name": "Ruby King", 
		"text": "Emerald Knight... the Crystal Kingdom is fracturing.", 
		"pitch": 1.3, # Deep, regal King voice
		"portrait": preload("res://Assets/sprites/rubyKingProfile.png")
	},
	{
		"name": "Ruby King", 
		"text": "The Trilateral King has grown too bold. His reign of terror must end today.", 
		"pitch": 1.3,
		"portrait": preload("res://Assets/sprites/rubyKingProfile.png")
	},
	{
		"name": "Emerald Knight", 
		"text": "My hammer is yours, my King. Where do I find him?", 
		"pitch": 0.5, # Grounded, standard hero voice
		"portrait": preload("res://Assets/sprites/emerald_kinght_profile.png")
	},
	{
		"name": "Ruby King", 
		"text": "Beyond the jagged peaks. Go. Do not return until the Trilateral King falls.", 
		"pitch": 1.3,
		"portrait": preload("res://Assets/sprites/rubyKingProfile.png")
	}
]

func _ready() -> void:
	# Start the cutscene the moment the game loads!
	play_opening_cinematic()

func play_opening_cinematic():
	# 1. FREEZE THE PLAYER IMMEDIATELY
	# We don't want the player running around while the king is talking!
	if player:
		player.set_physics_process(false)
		# Reset horizontal velocity so the player doesn't slide if they were moving
		player.velocity.x = 0
		# Optional: Force an idle animation
		# player.get_node("AnimatedSprite2D").play("Idle")
	
	# 2. PLAY THE OPENING ANIMATION (e.g., screen fading in)
	if anim_player and anim_player.has_animation("intro_fade_in"):
		anim_player.play("intro_fade_in")
		await anim_player.animation_finished 
	
	# Add a tiny dramatic pause before the King speaks (0.5 seconds)
	await get_tree().create_timer(0.5).timeout
	
	# 3. START THE DIALOGUE
	# Note: If your Autoload/Singleton is named "Dialog" or "DialogueManager", make sure this matches!
	Dialog.start_dialogue(intro_text)
	
	# Wait for the player to read everything and close the text box
	await Dialog.dialogue_finished 
	
	# 4. UNFREEZE THE PLAYER! THE GAME BEGINS!
	if player:
		player.set_physics_process(true)
		
	# Optional: Remove the director node to clean up memory
	queue_free()
