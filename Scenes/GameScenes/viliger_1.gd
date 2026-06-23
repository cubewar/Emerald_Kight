extends CharacterBody2D

var player_in_range: bool = false
var is_talking: bool = false

# --- THE NPC'S DIALOGUE ---
var dialogue_lines = [
	{"name": "Villiager", "text": "Emerald Knight! Watch out for the Silver Mages up ahead!"},
	{"name": "Villiager", "text": "Their magic hurts, but a well-timed swing of your hammer will send it right back at them!"}
]

func _physics_process(delta: float) -> void:
	# 1. Basic gravity so the NPC stands on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()

	# 2. Check if the player is trying to talk!
	# (Change "ui_accept" to "ui_up" if you want them to press Up to talk)
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		talk_to_player()

func talk_to_player():
	# If we are already talking, don't trigger the text box again!
	if is_talking: 
		return
		
	is_talking = true
	
	# Start the dialogue system
	Dialog.start_dialogue(dialogue_lines)
	
	# Wait for the player to close the final text box
	await Dialog.dialogue_finished
	
	# Allow them to talk again if they press the button
	is_talking = false

# --- SIGNAL CONNECTIONS ---

# Connect the 'body_entered' signal from your InteractZone here!
func _on_interact_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		# Optional: You could make a little "Press UP to Talk" sprite appear over the NPC's head here!

# Connect the 'body_exited' signal from your InteractZone here!
func _on_interact_zone_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		# Optional: Hide the "Press UP" sprite here!
