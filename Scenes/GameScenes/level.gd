extends Node2D # Or whatever your level's root node is

func _ready():
	# We tell the Player's signal to connect directly to the LifeContainer's function
	$Player.health_changed.connect($HUD/LifeContainer.update_lives)
	
	# Optional: Force the player to shout their starting health right after connecting, 
	# just to make sure the UI draws perfectly on frame 1.
	$Player.health_changed.emit($Player.current_health, $Player.max_health)
