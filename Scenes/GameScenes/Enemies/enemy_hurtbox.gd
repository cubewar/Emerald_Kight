extends Area2D

func take_damage(amount: int, hit_direction: float):
	get_parent().deflect(hit_direction)
