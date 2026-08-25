extends CanvasLayer

const TEXTSOUND = preload("res://Scenes/Sounds/SFX/click.wav")
const NEXTSOUND = preload("res://Scenes/Sounds/SFX/next.wav")

@onready var text_label = $NinePatchRect/TextLabel
@onready var name_label = $NinePatchRect/NameLabel
@onready var profile = $NinePatchRect/TextureFrame/Profile
signal dialogue_finished
var dialogue_data: Array = []
var current_index: int = 0

# --- TYPING VARIABLES ---
var is_typing: bool = false
var typing_speed: float = 0.04 # Seconds per character
var current_tween: Tween
var current_text_raw: String = ""
var last_char_index: int = -1

func _ready():
	$NinePatchRect.hide()

func start_dialogue(data: Array):
	dialogue_data = data
	current_index = 0
	$NinePatchRect.show()
	show_next_message()

func show_next_message():
	if current_index >= dialogue_data.size():
		$NinePatchRect.hide()
		dialogue_finished.emit()
		return
	
	var current_message = dialogue_data[current_index]
	name_label.text = current_message["name"]
	
	
	if current_message.has("portrait"):
		profile.texture = current_message["portrait"]
		profile.show() 
	else:
		profile.texture = null
		profile.hide()
		
	# Set full text
	current_text_raw = current_message["text"]
	text_label.text = current_text_raw
	
	# Reset typing counters
	text_label.visible_characters = 0
	last_char_index = 0
	is_typing = true
	
	if current_tween:
		current_tween.kill()
		
	current_tween = create_tween()
	var total_time = current_text_raw.length() * typing_speed
	
	# Animate using tween_method to catch each letter change
	current_tween.tween_method(set_visible_chars_and_play_sound, 0, current_text_raw.length(), total_time)
	current_tween.finished.connect(_on_typing_finished)

# --- SOUND & LETTER UPDATE ---
func set_visible_chars_and_play_sound(char_count: int) -> void:
	text_label.visible_characters = char_count
	
	# Check if a new letter was revealed
	if char_count > last_char_index and char_count <= current_text_raw.length():
		var new_char = current_text_raw[char_count - 1]
		
		# Only play sound for actual characters (skip spaces and newlines)
		if new_char != " " and new_char != "\n" and new_char != "\t":
			play_type_sound()
			
		last_char_index = char_count

func play_type_sound():
	# If your SoundManager supports pitch shifting, you can add slight variation
	SoundManager.play_sfx(TEXTSOUND)

func _on_typing_finished():
	is_typing = false

func _input(event):
	if event.is_action_pressed("ui_down") and $NinePatchRect.visible:
		if is_typing:
			SoundManager.play_sfx(NEXTSOUND)
			if current_tween:
				current_tween.kill()
			text_label.visible_characters = -1
			is_typing = false
		else:
			current_index += 1
			SoundManager.play_sfx(NEXTSOUND)
			show_next_message()
