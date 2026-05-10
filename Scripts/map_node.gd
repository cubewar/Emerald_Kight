extends Area2D
class_name MapNode 

@export var level_number: int = 1
@export_file("*.tscn") var level_path: String

# --- PATH CONNECTIONS ---
@export var up_node: MapNode
@export var down_node: MapNode
@export var left_node: MapNode
@export var right_node: MapNode

@export var Tsprite: Texture2D
func _ready():
	# Darken the node if we haven't unlocked it yet
	if level_number > Global.highest_unlocked_level:
		modulate = Color(0.3, 0.3, 0.3)
		
	# Automatically draw lines to all connected nodes
	draw_path_lines()
	$Sprite2D.texture = Tsprite

func draw_path_lines():
	# 1. Put all connected nodes into an array so we can loop through them
	var connections = [up_node, down_node, right_node]
	
	for node in connections:
		# 2. Check if a node was actually assigned in the inspector
		if node != null:
			var line = Line2D.new()
			
			# Point 1: The center of THIS node (Vector2.ZERO is local center)
			line.add_point(Vector2.ZERO)
			
			# Point 2: The center of the CONNECTED node 
			# (We subtract our position from theirs to get the relative distance)
			line.add_point(node.global_position - global_position)
			
			# 3. Make the line look good
			line.width = 3.0
			line.default_color = Color(0.627, 0.53, 0.232, 1.0) # Light gray color
			line.z_index = -1 # CRITICAL: Forces the line to draw BEHIND the map icons
			
			# 4. Add the generated line to the game
			add_child(line)
