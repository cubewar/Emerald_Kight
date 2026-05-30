extends CharacterBody2D

@export var projectile_scene: PackedScene # Drag your Projectile scene here in the Inspector!

var health: int = 2
var facing_direction: int = -1
var state_timer: float = 2.0 
var isPlayerNear = false
var player = null
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
	if isPlayerNear:
		$AnimatedSprite2D.play("Detected")
	else:
		$AnimatedSprite2D.play("Idle")
		
	if isPlayerNear and state_timer <= 0:
		if player:
			current_state = State.SHOOT

func state_shoot():
	# 1. Turn Blue to warn the player
	$AnimatedSprite2D.play("Shoot")
	# 2. Instantiate the projectile
	var new_projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(new_projectile)
	
	# 3. Calculate the exact diagonal angle to the player
	var aim_vector = (player.global_position - global_position).normalized()
	
	# 4. Position it slightly in front of the enemy (using the aim vector!)
	new_projectile.global_position = global_position + (aim_vector * 20)
	
	# 5. Hand the vector over to the projectile
	new_projectile.direction = aim_vector
	
	# 6. Reset
	state_timer = 2.0
	current_state = State.IDLE

# Standard damage code so they die if the player hits them OR deflects a shot at them!
func take_damage(amount: int, hit_direction: float = 0.0):
	health -= amount
	if health <= 0:
		queue_free()


func _on_enemy_hurtbox_body_entered(body: Node2D) -> void:
	take_damage(1)


func _on_player_vision_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		isPlayerNear = true
		player = body


func _on_player_vision_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		isPlayerNear = false
		player = null
