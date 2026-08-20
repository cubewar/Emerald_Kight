extends Control

@onready var health_bar = $HealthBar
@onready var name_label = $BossNameLabel

# 1. The boss calls this function right when the fight starts
func initialize_boss(boss_name: String, max_health: int, bar_color: Color):
	# Set the name
	name_label.text = boss_name
	
	# Set the text color (or you can tint the health_bar itself!)
	name_label.add_theme_color_override("font_color", bar_color)
	# Optional: If you want the bar to change color too, uncomment the line below:
	# health_bar.tint_progress = bar_color 
	
	# Set the health math
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	show() # Make sure the bar is visible!

# 2. ANY boss can connect their health signal to this function!
func update_health(current_health: int, max_health: int = 100):
	health_bar.value = current_health
