extends Area2D

@export var transition_speed: float = 1.0 

@onready var collision_shape = $CollisionShape2D

func _ready() -> void:
	# 1. Wait a tiny fraction of a second for the player and physics to load
	await get_tree().physics_frame
	
	# 2. Check if the player is ALREADY inside the box on frame 1
	for body in get_overlapping_bodies():
		if body.name == "Player":
			# If they are, manually trigger the camera pan!
			_on_body_entered(body)

# --- Your existing code below ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var camera = get_tree().get_first_node_in_group("PlayerCamera")
		
		if camera and camera is Camera2D:
			var shape = collision_shape.shape as RectangleShape2D
			if shape:
				var extents = shape.size / 2.0
				var target_left = int(global_position.x - extents.x)
				var target_right = int(global_position.x + extents.x)
				var target_top = int(global_position.y - extents.y)
				var target_bottom = int(global_position.y + extents.y)
				
				var tween = create_tween().set_parallel(true)
				tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				
				tween.tween_property(camera, "limit_left", target_left, transition_speed)
				tween.tween_property(camera, "limit_right", target_right, transition_speed)
				tween.tween_property(camera, "limit_top", target_top, transition_speed)
				tween.tween_property(camera, "limit_bottom", target_bottom, transition_speed)
