extends Area2D

var player_in_range: bool = false

# --- THIS IS WHERE YOU ADD THE CONVERSATION ---
var my_story = [
	{"name": "Dawnie", "text": "Whoa, watch where you're swinging that hammer!"},
	{"name": "Emerald Knight", "text": "Stand aside. I have a Bronze Lancer to catch."},
	{"name": "Dawnie", "text": "Fine, but don't say I didn't warn you."}
]

func _process(_delta: float) -> void:
	# If the player is close AND they press the Up arrow...
	if player_in_range and Input.is_action_just_pressed("ui_down"):
		
		
		# AND if the dialogue box isn't already open on the screen...
		if not Dialog.get_node("Panel").visible:
			
			# Start the conversation!
			Dialog.start_dialogue(my_story)

# --- SIGNALS ---
# Connect these from the Node tab to know when the player is close!
func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
