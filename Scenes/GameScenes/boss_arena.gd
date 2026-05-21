extends Node2D

@export var boss_node: CharacterBody2D

# Expose these so you can easily tweak the camera box for different rooms!
@export var limit_left: int = 0
@export var limit_right: int = 500
@export var limit_top: int = -300
@export var limit_bottom: int = 0

@onready var trigger_zone = $TriggerZone
@onready var arena_doors = $ArenaDoors

var player_ref: CharacterBody2D
var original_cam_limits: Dictionary = {}

func _ready():
	# 1. Open the doors when the level loads
	arena_doors.process_mode = Node.PROCESS_MODE_DISABLED 
	
	# 2. Connect the death signal from the boss!
	if boss_node:
		boss_node.boss_defeated.connect(unlock_arena)

func _on_trigger_zone_body_entered(body: Node2D) -> void:
	# Check if it's the player entering the arena
	if body.name == "Player":
		player_ref = body
		
		# 1. Slam the physical doors shut
		arena_doors.process_mode = Node.PROCESS_MODE_INHERIT
		
		# 2. Grab the player's camera and lock it
		var cam = player_ref.get_node("Camera2D")
		if cam:
			# Save their original level limits so we can give them back later
			original_cam_limits["left"] = cam.limit_left
			original_cam_limits["right"] = cam.limit_right
			original_cam_limits["top"] = cam.limit_top
			original_cam_limits["bottom"] = cam.limit_bottom
			
			# Apply the new claustrophobic boss limits
			cam.limit_left = limit_left
			cam.limit_right = limit_right
			cam.limit_top = limit_top
			cam.limit_bottom = limit_bottom
			
		# 3. Turn off the trigger zone so it doesn't fire again
		trigger_zone.set_deferred("monitoring", false)

func unlock_arena():
	# 1. Open the doors
	arena_doors.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. Restore the camera back to normal level exploration
	if player_ref:
		var cam = player_ref.get_node("Camera2D")
		if cam and not original_cam_limits.is_empty():
			cam.limit_left = original_cam_limits["left"]
			cam.limit_right = original_cam_limits["right"]
			cam.limit_top = original_cam_limits["top"]
			cam.limit_bottom = original_cam_limits["bottom"]
