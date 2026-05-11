extends Control

func _on_bronze_kight_health_changed(current_health: Variant, max_health: Variant) -> void:
	$HealthBar.max_value = max_health
	$HealthBar.value = current_health
