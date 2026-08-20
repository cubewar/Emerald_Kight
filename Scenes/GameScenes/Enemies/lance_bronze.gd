extends CharacterBody2D

# --- STATS ---
var health: int = 3
const PATROL_SPEED: float = 40.0
const CHARGE_SPEED: float = 150.0

# --- AI VARIABLES ---
var facing_direction: int = 1 # 1 is Right, -1 is Left
var knockback_velocity: Vector2 = Vector2.ZERO

# --- TIMERS ---
var state_timer: float = 0.0
const WINDUP_TIME: float = 0.6
const CHARGE_TIME: float = 0.8
const RECOVERY_TIME: float = 1.0

enum State { PATROL, WINDUP, CHARGE, RECOVERY }
var current_state: State = State.PATROL

# --- NODES ---
@onready var anim_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var edge_check_left = $RayCastLeft    # Checks for pits
@onready var edge_check_right = $RayCastRight  # Checks for pits
@onready var player_vision = $EntityVison     # NEW: Checks for the player!
@onready var spear_hitbox = $SpearHitbox/CollisionShape2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle getting hit (Knockback overrides AI)
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600 * delta)
		velocity.x = knockback_velocity.x
		move_and_slide()
		return # Skip the AI logic while flying through the air!

	# AI State Machine
	match current_state:
		State.PATROL:
			state_patrol()
		State.WINDUP:
			state_windup(delta)
		State.CHARGE:
			state_charge(delta)
		State.RECOVERY:
			state_recovery(delta)

	move_and_slide()

# --- STATE LOGIC ---

func state_patrol():
	anim_player.play("Patrol")
	sprite.frame = 0
	
	# 1. Check for walls and ledges FIRST
	if is_on_wall() or (facing_direction == 1 and not edge_check_right.is_colliding()) or (facing_direction == -1 and not edge_check_left.is_colliding()):
		flip_enemy()

	# 2. THEN set the velocity. 
	# If they flipped in the step above, this will now safely push them AWAY from the wall!
	velocity.x = facing_direction * PATROL_SPEED

	# 3. Check for the player!
	if player_vision.is_colliding():
		var object_seen = player_vision.get_collider()
		
		if object_seen != null and object_seen.name == "Player":
			current_state = State.WINDUP
			state_timer = WINDUP_TIME
			velocity.x = 0 # Stop walking immediately

func state_windup(delta):
	anim_player.play("Windup")
	sprite.frame = 1 # Show the Windup silhouette
	velocity.x = 0 # Rooted to the spot
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.CHARGE
		state_timer = CHARGE_TIME

func state_charge(delta):
	anim_player.play("Charge")
	
	# Turn the spear damage ON!
	spear_hitbox.set_deferred("disabled", false)
	
	velocity.x = facing_direction * CHARGE_SPEED
	
	state_timer -= delta
	if state_timer <= 0 or is_on_wall() or (facing_direction == 1 and not edge_check_right.is_colliding()) or (facing_direction == -1 and not edge_check_left.is_colliding()):
		current_state = State.RECOVERY
		state_timer = RECOVERY_TIME
		velocity.x = 0

func state_recovery(delta):
	sprite.frame = 0
	
	# Turn the spear damage OFF! The player is safe to attack now.
	spear_hitbox.set_deferred("disabled", true)
	
	velocity.x = move_toward(velocity.x, 0, 800 * delta) 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.PATROL
		flip_enemy()
# --- HELPER FUNCTIONS ---

func flip_enemy():
	facing_direction *= -1
	sprite.flip_h = (facing_direction == -1)
	
	# Flip the vision raycast so it looks the right way!
	player_vision.target_position.x *= -1 

	# --- THE NEW FIX ---
	# This physically moves the hitbox to the opposite side of the enemy!
	$SpearHitbox.position.x *= -1

# --- COMBAT LOGIC ---

func take_damage(amount: int, hit_direction: float):
	health -= amount
	knockback_velocity = Vector2(hit_direction * 250, -100)
	
	# Interrupt whatever the enemy was doing and force them to recover
	current_state = State.RECOVERY
	state_timer = RECOVERY_TIME 
	
	if health <= 0:
		queue_free() # Or play a death animation!
		
func _on_spear_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var direction_to_player = sign(body.global_position.x - global_position.x)
		
		# Notice there are TWO things in the parentheses here: (1, direction_to_player)
		body.take_damage(1, direction_to_player)
			
