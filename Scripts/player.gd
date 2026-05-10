extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# -- MOMENTUM VARIABLES ---
const ACCELERATION = 800.0 # How fast the knight reaches max speed
const FRICTION = 1000.0    # How fast the knight slides to a stop

# --- GAME FEEL TIMERS ---
var coyote_timer: float = 0.0
const COYOTE_TIME: float = 0.15 

var charge_timer: float = 0.0
const CHARGE_TIME_REQUIRED: float = 0.6 # How many seconds to hold to get a heavy attack

var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_TIME: float = 0.1 

var knockback_velocity: Vector2 = Vector2.ZERO

var is_invincible: bool = false
var invincibility_timer: float = 0.0
const INVINCIBILITY_TIME: float = 1.0 # 1 second of safety after getting hit

signal health_changed(current_health: int, max_health: int)


enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	CHARGE,
	HEAVY_ATTACK
}

@export var current_state : State = State.IDLE

func _ready():
	# Shout out our starting health so the UI can draw it
	health_changed.emit(Global.current_health, Global.max_health)
	

func _physics_process(delta: float) -> void:
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return # Skip the rest of the movement logic while flying backwards!
		
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			$AnimatedSprite2D.modulate.a = 1.0 # Return sprite to full opacity (solid)
			
	# 1. Update Game Feel Timers
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# 2. Add gravity globally
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. Run the logic specific to our current state
	# We pass 'delta' into our states now so Acceleration/Friction works smoothly
	match current_state:
		State.IDLE:
			state_idle(delta)
		State.RUN:
			state_run(delta)
		State.JUMP:
			state_jump(delta)
		State.FALL:
			state_fall(delta)
		State.ATTACK:
			state_attack(delta)
		State.CHARGE:
			state_charge(delta)
		State.HEAVY_ATTACK:
			state_heavy_attack(delta)
			
	# 4. Always apply movement at the very end of the frame!
	move_and_slide()


# --- STATE LOGIC FUNCTIONS ---

func state_idle(delta):
	$AnimationPlayer.play("Idle") 
	# NEW: Smoothly slide to a stop using FRICTION
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta) 
	
	# Transitions
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0: 
		perform_jump()
	elif Input.get_axis("moveLeft", "moveRight"):
		current_state = State.RUN
	elif not is_on_floor():
		current_state = State.FALL

func state_run(delta):
	$AnimationPlayer.play("Run") 
	var direction = Input.get_axis("moveLeft", "moveRight")
	
	# NEW: Smoothly speed up using ACCELERATION
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		# If we let go of the keys, go back to IDLE (where friction will slow us down)
		current_state = State.IDLE 
		
	# Transitions
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		perform_jump()
	elif not is_on_floor():
		current_state = State.FALL

func state_jump(delta):
	$AnimationPlayer.play("Jump") 
	
	# NEW: Variable Jump Height (Short Hop)
	# If we let go of jump while moving UP, cut upward speed in half!
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	var direction = Input.get_axis("moveLeft", "moveRight")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Transitions
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif velocity.y > 0: 
		current_state = State.FALL

func state_fall(delta):
	# $AnimationPlayer.play("Fall") 
	
	var direction = Input.get_axis("moveLeft", "moveRight")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Transitions
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0: 
		perform_jump()
	elif is_on_floor():
		if Input.get_axis("moveLeft", "moveRight"):
			current_state = State.RUN
		else:
			current_state = State.IDLE

func state_attack(delta):
	$AnimationPlayer.play("Attack")
	
	var direction = Input.get_axis("moveLeft", "moveRight")
	
	# NEW: Attack Movement Logic
	if is_on_floor():
		# Ground attack: Can move, but slower (half speed), and NO flipping sprite!
		var attack_speed = SPEED * 0.5 
		if direction:
			velocity.x = move_toward(velocity.x, direction * attack_speed, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	else:
		# Air attack: Normal air momentum, NO flipping sprite!
		if direction:
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func state_charge(delta):
	# Optional: You can make a specific "Charge" animation later
	$AnimationPlayer.play("Charge") 
	
	# Root the player to the ground while charging
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# Count up the timer
	charge_timer += delta
	
	# Visual Feedback: Make the Emerald Knight glow green when fully charged!
	if charge_timer >= CHARGE_TIME_REQUIRED:
		$AnimatedSprite2D.modulate = Color(0.5, 2.0, 0.5) 
		
	# What happens when we let go of the button?
	if Input.is_action_just_released("attack"):
		$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0) # Reset color to normal
		
		if charge_timer >= CHARGE_TIME_REQUIRED:
			current_state = State.HEAVY_ATTACK
		else:
			# Released too early! Cancel the charge.
			current_state = State.IDLE if is_on_floor() else State.FALL

func state_heavy_attack(delta):
	$AnimationPlayer.play("Heavy_Attack") 
	
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	else:
		# Allow very slow mid-air steering for the heavy slam
		var direction = Input.get_axis("moveLeft", "moveRight")
		if direction:
			velocity.x = move_toward(velocity.x, direction * (SPEED * 0.3), ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
# --- HELPER FUNCTIONS ---

func perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0 
	coyote_timer = 0.0 
	current_state = State.JUMP

# --- SIGNALS AND JUICE ---

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Attack":
		if Input.is_action_pressed("attack"):
			current_state = State.CHARGE
			charge_timer = 0.0 # Reset the timer
		else:
			current_state = State.IDLE if is_on_floor() else State.FALL
	elif anim_name == "Heavy_Attack":
		# Heavy attack is done, return to normal
		current_state = State.IDLE if is_on_floor() else State.FALL

func hit_stop():
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_hammmer_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "EnemyHurtbox":
		var direction_to_enemy = sign(area.global_position.x - global_position.x)
		
		# --- CHECK WHICH ATTACK WE ARE USING ---
		if current_state == State.HEAVY_ATTACK:
			hit_stop()
			$Camera2D.apply_shake(30.0) # Massive screen shake!
			area.get_parent().take_damage(3, direction_to_enemy) # Deal 3 Damage
		else:
			hit_stop()
			$Camera2D.apply_shake(15.0) # Normal shake
			area.get_parent().take_damage(1, direction_to_enemy) # Deal 1 Damage
		
		

# --- HEALTH LOGIC ---

func take_damage(amount: int, hit_direction: float):
	# If we are currently invincible, ignore the hit entirely!
	if is_invincible:
		return 

	Global.current_health -= amount
	
	if Global.current_health < 0:
		Global.current_health = 0
		
	health_changed.emit(Global.current_health, Global.max_health)
	
	if Global.current_health == 0:
		die()
	else:
		# We didn't die, so trigger I-Frames!
		is_invincible = true
		invincibility_timer = INVINCIBILITY_TIME
		
		# Make the player 50% transparent to visually show they are invincible
		$AnimatedSprite2D.modulate.a = 0.5
		knockback_velocity = Vector2(hit_direction * 200, -150)

func upgrade_max_health():
	if Global.max_health < 5:
		Global.max_health += 1
		Global.current_health = Global.max_health # Fully heal the player on upgrade
		
		# Tell the UI to draw a brand new square!
		health_changed.emit(Global.current_health, Global.max_health)

func die():
	# For now, just reload the scene when we die
	get_tree().reload_current_scene()
