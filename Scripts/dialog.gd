extends CanvasLayer

@onready var text_label = $Panel/TextLabel
@onready var name_label = $Panel/NameLabel
@onready var type_timer = $TypeTimer

signal dialogue_finished
var dialogue_data: Array = []
var current_index: int = 0
var is_typing: bool = false

func _ready():
	# Hide the UI when the game starts
	$Panel.hide()

# This is the function other scripts will call to start a conversation!
func start_dialogue(data: Array):
	dialogue_data = data
	current_index = 0
	$Panel.show()
	show_next_message()

func show_next_message():
	# Check if the conversation is over
	if current_index >= dialogue_data.size():
		$Panel.hide()
		dialogue_finished.emit()
		return
	
	# Grab the current dictionary from our array
	var current_message = dialogue_data[current_index]
	
	# Update the UI text
	name_label.text = current_message["name"]
	text_label.text = current_message["text"]
	
	# Hide all text, then start the typewriter timer
	text_label.visible_characters = 0
	is_typing = true
	type_timer.start()

# --- INPUT HANDLING ---
func _input(event):
	# If the panel is visible and we press our action button (e.g., "jump" or "attack")
	if event.is_action_pressed("jump") and $Panel.visible:
		if is_typing:
			# Player pressed the button while typing: SKIP the animation!
			text_label.visible_characters = text_label.get_total_character_count()
			is_typing = false
			type_timer.stop()
		else:
			# Player pressed the button after typing finished: GO TO NEXT LINE!
			current_index += 1
			show_next_message()

# --- SIGNALS ---
# Connect the TypeTimer's 'timeout' signal to this script!
func _on_type_timer_timeout() -> void:
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
	else:
		is_typing = false
		type_timer.stop()
