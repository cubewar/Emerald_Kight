extends Node2D

var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var is_deflected: bool = false

func _physics_process(delta: float) -> void:
	# Multiply the whole position by the direction vector
	position += direction * speed * delta


# This is called by the EnemyHurtbox when the player's hammer strikes it!
func take_damage(amount: int, hit_direction: float = 0.0):
	is_deflected = true
	direction = -direction
	speed = 300.0 # Fly back twice as fast!
	$Sprite2D.modulate = Color.GREEN # Turn green so the player knows they succeeded!
	
	# Swap the collision mask so it stops looking for the player and starts looking for enemies
	$EnemyHurtbox.set_collision_mask_value(2, false) # Stop looking at Player Layer
	$EnemyHurtbox.set_collision_mask_value(3, true)  # Start looking at Enemy Layer\


func _on_enemy_hurtbox_body_entered(body: Node2D) -> void:
	if body is TileMap: 
		queue_free()
	# 2. Did it hit the Player, and HASN'T been deflected yet? Hurt the player!
	if body.name == "Player" and not is_deflected:
		if body.has_method("take_damage"):
			body.take_damage(1, sign(direction.x))
			queue_free()
			
	# 3. Did it hit an Enemy, and HAS been deflected? Hurt the enemy!
	if is_deflected and body.name != "Player" and body.has_method("take_damage"):
		
		body.take_damage(2, sign(direction.x)) # Deals double damage!
		queue_free()
