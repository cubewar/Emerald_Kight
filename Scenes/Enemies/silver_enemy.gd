extends CharacterBody2D

@export var projectile_scene: PackedScene # Drag your Projectile scene here in the Inspector!

var health: int = 2
var facing_direction: int = -1
var state_timer: float = 2.0 

@onready var player_vision = $PlayerVision # A RayCast2D to see the player

enum State { IDLE, SHOOT }
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()

	match current_state:
		State.IDLE:
			state_idle(delta)
		State.SHOOT:
			state_shoot()

func state_idle(delta):
	# Wait for 2 seconds, checking for the player
	state_timer -= delta
	
	if player_vision.is_colliding() and state_timer <= 0:
		var target = player_vision.get_collider()
		if target and target.name == "Player":
			current_state = State.SHOOT

func state_shoot():
	# 1. Turn Red to warn the player they are firing
	$Sprite2D.modulate = Color.RED
	
	# 2. CREATE THE PROJECTILE
	var new_projectile = projectile_scene.instantiate()
	
	# CRITICAL: Add it to the Level, NOT the enemy! 
	# If you add it to the enemy, it will move when the enemy moves.
	get_tree().current_scene.add_child(new_projectile)
	
	# 3. Position it slightly in front of the enemy
	new_projectile.global_position = global_position + Vector2(facing_direction * 20, 0)
	new_projectile.direction = facing_direction
	
	# 4. Go back to idle and wait 2 seconds before firing again
	$Sprite2D.modulate = Color.WHITE
	state_timer = 2.0
	current_state = State.IDLE

# Standard damage code so they die if the player hits them OR deflects a shot at them!
func take_damage(amount: int, hit_direction: float = 0.0):
	health -= amount
	if health <= 0:
		queue_free()


func _on_enemy_hurtbox_body_entered(body: Node2D) -> void:
	take_damage(1)
