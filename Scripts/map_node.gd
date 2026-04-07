extends Area2D
class_name MapNode # <-- This is the magic word that fixes your error!

@export var level_number: int = 1
@export_file("*.tscn") var level_path: String

# --- NEW: PATH CONNECTIONS ---
# These will appear in the Inspector so you can link nodes together!
@export var up_node: MapNode
@export var down_node: MapNode
@export var left_node: MapNode
@export var right_node: MapNode

func _ready():
	# Darken the node if we haven't unlocked it yet
	if level_number > Global.highest_unlocked_level:
		modulate = Color(0.3, 0.3, 0.3)
