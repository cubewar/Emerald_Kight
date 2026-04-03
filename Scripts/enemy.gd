extends CharacterBody2D # Changed from Node2D

const SPEED = 60.0
const KNOCKBACK_RESISTANCE = 10.0 # How fast the enemy stops sliding after being hit

var health: int = 2
var dir = 1
var knockback_velocity = Vector2.ZERO

@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Handle Knockback (if we were recently hit)
	if knockback_velocity != Vector2.ZERO:
		# Gradually slow down the knockback slide
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_RESISTANCE)
		velocity.x = knockback_velocity.x
	else:
		# 3. Normal Patrol Logic (only if not being knocked back)
		if ray_cast_left.is_colliding():
			dir = 1 # Turn Right
			animated_sprite.flip_h = false
		if ray_cast_right.is_colliding():
			dir = -1 # Turn Left
			animated_sprite.flip_h = true
			
		velocity.x = dir * SPEED

	# 4. Use move_and_slide instead of position.x
	move_and_slide()

# This function is called by the Player's script when the hammer hits
func take_damage(amount: int, hit_direction: float):
	health -= amount
	
	# Apply physical knockback: move away from the player and slightly up
	knockback_velocity = Vector2(hit_direction * 250, -100)
	
	# Flash red or play an animation here later!
	print("Bronze Enemy hit! Health remaining: ", health)
	
	if health <= 0:
		die()

func die():
	# You can play a "shatter" animation here later
	queue_free()
