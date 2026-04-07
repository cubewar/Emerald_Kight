extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Instead of instantly killing, we check if the player can take damage
		if body.has_method("take_damage"):
			body.take_damage(1)


func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
