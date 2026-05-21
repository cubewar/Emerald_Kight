extends Node2D

var speed: float = 200.0
var direction: int = 1
var is_deflected: bool = false

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta

# This triggers when the projectile touches a physics body
func _on_player_hitbox_body_entered(body: Node2D) -> void:
	
	# 1. Did it hit a wall? Destroy it!
	if body is TileMap: 
		queue_free()

	# 2. Did it hit the Player, and HASN'T been deflected yet? Hurt the player!
	if body.name == "Player" and not is_deflected:
		if body.has_method("take_damage"):
			body.take_damage(10, direction)
			queue_free()
			
	# 3. Did it hit an Enemy, and HAS been deflected? Hurt the enemy!
	if is_deflected and body.has_method("take_damage") and body.name != "Player":
		body.take_damage(20, direction) # Deals double damage!
		queue_free()

# This is called by the EnemyHurtbox when the player's hammer strikes it!
func deflect(hit_direction: float):
	is_deflected = true
	direction = hit_direction # Fly back the way the hammer swung!
	speed = 400.0 # Fly back twice as fast!
	$Sprite2D.modulate = Color.GREEN # Turn green so the player knows they succeeded!
	
	# Swap the collision mask so it stops looking for the player and starts looking for enemies
	$PlayerHitbox.set_collision_mask_value(2, false) # Stop looking at Player Layer
	$PlayerHitbox.set_collision_mask_value(3, true)  # Start looking at Enemy Layer
