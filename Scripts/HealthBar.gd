extends Panel

@export var life_full: Texture2D
@export var life_empty: Texture2D
@onready var heart_texture = $HeartTexture
@onready var health_bar = $HealthBar
	
func update_health(new_health: int, new_max: int):
	health_bar.max_value = new_max
	health_bar.value = new_health
	if new_health <= 0:
		heart_texture = life_empty
