extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Optional: Play a death sound or animation on the player
		Engine.time_scale = 0.5
		
		body.visible = false 
		body.set_physics_process(false) 
		
		timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
