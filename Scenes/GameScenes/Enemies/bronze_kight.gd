extends CharacterBody2D

# --- SIGNALS FOR THE UI ---
signal health_changed(current_health, max_health)
signal boss_defeated

# --- STATS ---
@export var boss_name: String = "Bronze Knight"
@export var boss_color: Color = Color.DARK_ORANGE # Or whatever color you want!
var max_health: int = 20
var health: int = max_health
const WALK_SPEED: float = 50.0
const SMASH_SPEED: float = 300.0

# --- AI VARIABLES ---
var facing_direction: int = -1 # Starts facing left (-1)
var knockback_velocity: Vector2 = Vector2.ZERO
var player_is_above: bool = false


# --- TIMERS ---
var state_timer: float = 2.0 
enum State { WAKEUP, CHASE, WINDUP, SMASH, RECOVERY, UP_WINDUP, UP_ATTACK }
var current_state: State = State.WAKEUP

# --- NODES ---
@onready var visual = $Sprite2D 
@onready var boss_hitbox = $BossHitbox/CollisionShape2D
@export var player: CharacterBody2D 

# Store BOTH default positions as set up in the editor (Assuming left side)
@onready var default_hitbox_x: float = $BossHitbox.position.x
@onready var default_hitbox_y: float = $BossHitbox.position.y

func _ready():
	boss_hitbox.set_deferred("disabled", true)
	flip_boss(-1)
	# Just in case the root node scale got saved in the editor, reset it!
	scale.x = 1.0 


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		velocity.x = knockback_velocity.x
		move_and_slide()
		return

	# AI State Machine
	match current_state:
		State.WAKEUP:
			state_wakeup(delta)
		State.CHASE:
			$AnimationPlayer.play("Chase")
			state_chase()
		State.WINDUP:
			state_windup(delta)
		State.SMASH:
			state_smash(delta)
		State.RECOVERY:
			state_recovery(delta)
		State.UP_WINDUP:
			state_up_windup(delta) 
		State.UP_ATTACK:
			state_up_attack(delta)

	move_and_slide()

# --- STATE LOGIC ---

func state_wakeup(delta):
	velocity.x = 0
	visual.modulate = Color.WHITE 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.CHASE
		$AnimationPlayer.play("Chase")

func state_chase():
	visual.modulate = Color.WHITE
	
	# 1. Anti-Air Check (Now uses the continuous boolean flag!)
	if player_is_above: 
		current_state = State.UP_WINDUP
		state_timer = 0.2 
		velocity.x = 0
		return # Exit the function so he doesn't try to walk
	
	# 2. Horizontal Movement Tracking
	if player:
		var distance_x = abs(player.global_position.x - global_position.x)
		var distance_y = player.global_position.y - global_position.y 
		
		var direction_to_player = sign(player.global_position.x - global_position.x)
		if direction_to_player != 0 and direction_to_player != facing_direction:
			flip_boss(direction_to_player)
			
		velocity.x = facing_direction * WALK_SPEED
		
		# 3. Normal Attack Trigger
		if distance_x < 80 and distance_y >= -30: 
			current_state = State.WINDUP
			state_timer = 0.8 
			velocity.x = 0

func state_windup(delta):
	visual.modulate = Color.YELLOW
	velocity.x = 0 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.SMASH
		state_timer = 0.3 

func state_smash(delta):
	visual.modulate = Color.RED
	boss_hitbox.set_deferred("disabled", false)
	
	# We only apply the 300 speed on the very FIRST frame of the smash
	if state_timer == 0.3: # (Matches the exact timer from state_windup!)
		velocity.x = facing_direction * SMASH_SPEED
		
		# Trigger the screen shake right when he lunges!
		if player and player.has_node("Camera2D"):
			player.get_node("Camera2D").apply_shake(15.0)
	
	# Apply heavy friction so he slides to a stop, rather than moving at a flat speed
	velocity.x = move_toward(velocity.x, 0, 600 * delta)
	
	state_timer -= delta
	if state_timer <= 0 or is_on_wall():
		current_state = State.RECOVERY
		state_timer = 1.5 
		velocity.x = 0

func state_recovery(delta):
	visual.modulate = Color.CORNFLOWER_BLUE
	boss_hitbox.set_deferred("disabled", true)
	velocity.x = move_toward(velocity.x, 0, 800 * delta) 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.CHASE
		$AnimationPlayer.play("Chase")

func state_up_windup(delta):
	visual.modulate = Color.ORANGE
	velocity.x = 0 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.UP_ATTACK
		state_timer = 1.0 
		if facing_direction == -1:
			$BossHitbox/CollisionShape2D2.position.x = 25
		else:
			$BossHitbox/CollisionShape2D2.position.x = -25
		$AnimationPlayer.play("UpAttack")

func state_up_attack(delta):
	visual.modulate = Color.RED
	boss_hitbox.set_deferred("disabled", false) 
	
	# NEW: Add a heavy screen shake to make the upward swing feel powerful
	if player and player.has_node("Camera2D"):
		player.get_node("Camera2D").apply_shake(10.0)
		
	# SoundManager.play_sfx(preload("res://Scenes/Sounds/SFX/heavy_swing.wav"))
	
	velocity.x = 0 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.RECOVERY
		state_timer = 1.2 
		
		# Turn the hitbox OFF again when the swing is done
		boss_hitbox.set_deferred("disabled", true) 
		
		$BossHitbox.position.y = default_hitbox_y 
		flip_boss(facing_direction)
		
# --- PROPER SCRIPT-ONLY FLIPPING ---
func flip_boss(new_direction):
	facing_direction = new_direction
	
	# Since your artwork naturally faces RIGHT by default:
	if facing_direction == 1: # Chasing to the RIGHT
		visual.flip_h = false # Keep default art (facing right)
		$BossHitbox.position.x = abs(default_hitbox_x) # Force hitbox to the Right (+)
	else: # Chasing to the LEFT (-1)
		visual.flip_h = true # Mirror art to face left
		$BossHitbox.position.x = -abs(default_hitbox_x) # Force hitbox to the Left (-)

# --- COMBAT LOGIC ---

func take_damage(amount: int, hit_direction: float = 0.0):
	health -= amount
	print(amount)
	knockback_velocity = Vector2(hit_direction * 50, 0)
	health_changed.emit(health, max_health)
	
	if health <= 0:
		boss_defeated.emit()
		queue_free()

func _on_boss_hitbox_body_entered(body: Node2D) -> void:
	if body == self: return
	if body.has_method("take_damage"):
		var shove_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(2, shove_dir)


# When the player touches the top box, flip the flag ON
func _on_enemy_hurtbox_body_entered(body: Node2D) -> void:
	if body == player:
		player_is_above = true

func _on_up_detector_body_exited(body: Node2D) -> void:
	if body == player:
		player_is_above = false
