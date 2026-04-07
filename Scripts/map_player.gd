extends Node2D

const SPEED = 250.0

@export var starting_node: MapNode # Drag Level 1 here in the Inspector!

var current_node: MapNode
var target_node: MapNode
var is_moving: bool = false

func _ready():
	# Snap exactly to the starting node when the map loads
	if starting_node:
		current_node = starting_node
		global_position = current_node.global_position

func _process(delta):
	# STATE 1: We are traveling between nodes
	if is_moving:
		# Slide perfectly toward the target
		global_position = global_position.move_toward(target_node.global_position, SPEED * delta)
		
		# Did we arrive?
		if global_position == target_node.global_position:
			is_moving = false
			current_node = target_node
	
	# STATE 2: We are standing on a node, waiting for input
	else:
		handle_input()

func handle_input():
	# 1. Check for movement
	var next_node: MapNode = null
	
	if Input.is_action_just_pressed("ui_right") and current_node.right_node:
		next_node = current_node.right_node
	elif Input.is_action_just_pressed("ui_left") and current_node.left_node:
		next_node = current_node.left_node
	elif Input.is_action_just_pressed("ui_up") and current_node.up_node:
		next_node = current_node.up_node
	elif Input.is_action_just_pressed("ui_down") and current_node.down_node:
		next_node = current_node.down_node
		
	# If we pushed a direction, and a node exists there, check if it's unlocked!
	if next_node != null:
		if next_node.level_number <= Global.highest_unlocked_level:
			target_node = next_node
			is_moving = true
			
			# Flip sprite so the Emerald Knight faces the right way
			if target_node.global_position.x < current_node.global_position.x:
				$Sprite2D.flip_h = true
			elif target_node.global_position.x > current_node.global_position.x:
				$Sprite2D.flip_h = false
				
	# 2. Check for entering the level
	if Input.is_action_just_pressed("jump"):
		# Make sure we actually have a level to load
		if current_node.level_path != "":
			get_tree().change_scene_to_file(current_node.level_path)
