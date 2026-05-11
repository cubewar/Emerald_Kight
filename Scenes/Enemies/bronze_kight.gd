extends CharacterBody2D

# --- SIGNALS FOR THE UI ---
signal health_changed(current_health, max_health)
signal boss_defeated

# --- STATS ---
var max_health: int = 20
var health: int = max_health
const WALK_SPEED: float = 50.0
const SMASH_SPEED: float = 300.0

# --- AI VARIABLES ---
var facing_direction: int = -1 # Starts facing left
var knockback_velocity: Vector2 = Vector2.ZERO

# --- TIMERS ---
var state_timer: float = 2.0 # Starts with a 2-second delay before attacking
enum State { WAKEUP, CHASE, WINDUP, SMASH, RECOVERY }
var current_state: State = State.WAKEUP

# --- NODES ---
# If using a ColorRect, change this to $ColorRect
@onready var visual = $Sprite2D 
@onready var boss_hitbox = $BossHitbox/CollisionShape2D
@export var player: CharacterBody2D # Drag the player into this slot in the editor!

func _ready():
	# Make sure the hitbox is off when the scene loads
	boss_hitbox.set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Bosses are heavy! Less knockback than the Lancer.
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
			state_chase()
		State.WINDUP:
			state_windup(delta)
		State.SMASH:
			state_smash(delta)
		State.RECOVERY:
			state_recovery(delta)

	move_and_slide()

# --- STATE LOGIC ---

func state_wakeup(delta):
	velocity.x = 0
	visual.modulate = Color.WHITE # Normal color
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.CHASE

func state_chase():
	visual.modulate = Color.WHITE
	
	if player:
		# Find which way the player is and walk towards them
		var direction_to_player = sign(player.global_position.x - global_position.x)
		
		# If the player crossed over to the other side, flip the boss!
		if direction_to_player != 0 and direction_to_player != facing_direction:
			flip_boss(direction_to_player)
			
		velocity.x = facing_direction * WALK_SPEED
		
		# If we get close enough to the player, start the attack!
		var distance = abs(player.global_position.x - global_position.x)
		if distance < 80: # 80 pixels away
			current_state = State.WINDUP
			state_timer = 0.8 # 0.8 seconds to react!
			velocity.x = 0

func state_windup(delta):
	# Turn YELLOW to warn the player an attack is coming!
	visual.modulate = Color.YELLOW
	velocity.x = 0 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.SMASH
		state_timer = 0.3 # The smash is fast!

func state_smash(delta):
	# Turn RED because the hitbox is lethal!
	visual.modulate = Color.RED
	boss_hitbox.set_deferred("disabled", false)
	
	velocity.x = facing_direction * SMASH_SPEED
	
	state_timer -= delta
	if state_timer <= 0 or is_on_wall():
		current_state = State.RECOVERY
		state_timer = 1.5 # Exhausted for 1.5 seconds

func state_recovery(delta):
	# Turn BLUE to show the boss is vulnerable
	visual.modulate = Color.CORNFLOWER_BLUE
	boss_hitbox.set_deferred("disabled", true)
	velocity.x = move_toward(velocity.x, 0, 800 * delta) 
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.CHASE

# --- HELPER FUNCTIONS ---

func flip_boss(new_direction):
	facing_direction = new_direction
	visual.flip_h = (facing_direction == 1)
	
	# Move the hitbox to the correct side!
	if facing_direction == 1:
		$BossHitbox.position.x = abs($BossHitbox.position.x) # Right side
	else:
		$BossHitbox.position.x = -abs($BossHitbox.position.x) # Left side

# --- COMBAT LOGIC ---

func take_damage(amount: int, hit_direction: float = 0.0):
	health -= amount
	
	# Tiny knockback to feel the impact, but doesn't interrupt the boss's attack!
	knockback_velocity = Vector2(hit_direction * 50, 0)
	
	# TELL THE UI TO UPDATE!
	health_changed.emit(health, max_health)
	
	if health <= 0:
		boss_defeated.emit()
		queue_free() # Boss dies!

# Connect your BossHitbox 'body_entered' signal here!
func _on_boss_hitbox_body_entered(body: Node2D) -> void:
	if body == self: return
	if body.has_method("take_damage"):
		var shove_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(2, shove_dir) # Deals 2 damage!
