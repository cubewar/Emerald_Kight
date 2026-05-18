extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# --- GRAVITY & JUMP FEEL VARIABLES ---
const TERMINAL_VELOCITY = 500.0 # Maximum falling speed
const APEX_THRESHOLD = 50.0     # The vertical speed range where we trigger "hang time"
const APEX_GRAVITY_MULT = 0.5   # Cut gravity in half at the peak of the jump


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
	HEAVY_ATTACK,
	HURT
}

@export var current_state : State = State.IDLE

var horizontal_input: float = 0.0

func _ready():
	# Shout out our starting health so the UI can draw it
	health_changed.emit(Global.current_health, Global.max_health)
	change_state(State.IDLE)
	

func _physics_process(delta: float) -> void:
	# 1. Read Inputs ONCE per frame
	horizontal_input = Input.get_axis("moveLeft", "moveRight")
	
	# 2. I-Frame Logic
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			$FXController.set_opacity(1.0)
			
	# 3. Update Game Feel Timers
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# 4. Add gravity globally (Unless we are charging/grounded)
	if not is_on_floor():
		var applied_gravity = get_gravity().y 
		
		# --- HANG TIME (JUMP APEX) ---
		# If our vertical speed is close to 0 (the peak of the jump), reduce gravity!
		if abs(velocity.y) < APEX_THRESHOLD and current_state != State.HURT:
			applied_gravity *= APEX_GRAVITY_MULT
			
		velocity.y += applied_gravity * delta
		
		# --- TERMINAL VELOCITY ---
		# Don't let the player fall faster than our max speed limit
		if velocity.y > TERMINAL_VELOCITY:
			velocity.y = TERMINAL_VELOCITY
			
	# 5. Run the logic specific to our current state
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
		State.HURT:
			state_hurt(delta) # NEW: Hurt logic runs here now
			
	# 6. Apply movement
	move_and_slide()


# --- STATE LOGIC FUNCTIONS ---
func change_state(new_state: State) -> void:
	if current_state == new_state:
		return # Don't restart animations if we are already in this state
		
	current_state = new_state
	
	# Play animations ONLY when entering a new state!
	match current_state:
		State.IDLE:
			$AnimationPlayer.play("Idle")
		State.RUN:
			$AnimationPlayer.play("Run")
		State.JUMP:
			$AnimationPlayer.play("Jump")
		State.FALL:
			$AnimationPlayer.play("Jump")
			pass
		State.ATTACK:
			$AnimationPlayer.play("Attack")
		State.CHARGE:
			$AnimationPlayer.play("Charge")
		State.HEAVY_ATTACK:
			$AnimationPlayer.play("Heavy_Attack")
		State.HURT:
			# $AnimationPlayer.play("Hurt") # Uncomment if you have a hurt animation
			pass


func state_idle(delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta) 
	
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK)
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0: 
		perform_jump()
	elif horizontal_input != 0:
		change_state(State.RUN)
	elif not is_on_floor():
		change_state(State.FALL)

func state_run(delta):
	if horizontal_input:
		velocity.x = move_toward(velocity.x, horizontal_input * SPEED, ACCELERATION * delta)
		update_facing(horizontal_input)
	else:
		change_state(State.IDLE) 
		
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK)
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		perform_jump()
	elif not is_on_floor():
		change_state(State.FALL)

func state_jump(delta):
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	if horizontal_input:
		velocity.x = move_toward(velocity.x, horizontal_input * SPEED, ACCELERATION * delta)
		update_facing(horizontal_input)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK)
	elif velocity.y > 0: 
		change_state(State.FALL)

func state_fall(delta):
	if horizontal_input:
		velocity.x = move_toward(velocity.x, horizontal_input * SPEED, ACCELERATION * delta)
		update_facing(horizontal_input)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK)
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0: 
		perform_jump()
	elif is_on_floor():
		if horizontal_input != 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)

func state_attack(delta):
	if is_on_floor():
		var attack_speed = SPEED * 0.5 
		if horizontal_input:
			velocity.x = move_toward(velocity.x, horizontal_input * attack_speed, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	else:
		if horizontal_input:
			velocity.x = move_toward(velocity.x, horizontal_input * SPEED, ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func state_charge(delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	charge_timer += delta
	
	if charge_timer >= CHARGE_TIME_REQUIRED:
		$Pivot/AnimatedSprite2D.modulate = Color(0.5, 2.0, 0.5) 
		
	if Input.is_action_just_released("attack"):
		$Pivot/AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0) 
		if charge_timer >= CHARGE_TIME_REQUIRED:
			change_state(State.HEAVY_ATTACK)
		else:
			change_state(State.IDLE if is_on_floor() else State.FALL)

func state_heavy_attack(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	else:
		if horizontal_input:
			velocity.x = move_toward(velocity.x, horizontal_input * (SPEED * 0.3), ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func state_hurt(delta):
	# Apply friction to the knockback so we don't slide forever
	velocity.x = move_toward(velocity.x, 0, (FRICTION / 2) * delta) 
	
	# If we hit the ground, we can recover and move again
	if is_on_floor() and velocity.y >= 0:
		change_state(State.IDLE)

# --- HELPER FUNCTIONS ---

func perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0 
	coyote_timer = 0.0 
	change_state(State.JUMP)

func update_facing(direction: float):
	if direction > 0:
		$Pivot.scale.x = 1.0
	elif direction < 0:
		$Pivot.scale.x = -1.0
		

# --- SIGNALS AND JUICE ---

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Attack":
		if Input.is_action_pressed("attack"):
			change_state(State.CHARGE)
			charge_timer = 0.0 # Reset the timer
		else:
			change_state(State.IDLE if is_on_floor() else State.FALL)
	elif anim_name == "Heavy_Attack":
		# Heavy attack is done, return to normal
		change_state(State.IDLE if is_on_floor() else State.FALL)



func _on_hammmer_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "EnemyHurtbox":
		var direction_to_enemy = sign(area.global_position.x - global_position.x)
		
		# --- CHECK WHICH ATTACK WE ARE USING ---
		if current_state == State.HEAVY_ATTACK:
			$FXController.play_hit_stop(0.05, 0.1) # Much heavier hit stop
			$FXController.play_shake(30.0)
			area.get_parent().take_damage(3, direction_to_enemy) # Deal 3 Damage
		else:
			$FXController.play_hit_stop(0.1, 0.05) 
			$FXController.play_shake(15.0)
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
		
		$FXController.flash_color(Color.RED, 0.2) # Flash red when hurt!
		$FXController.set_opacity(0.5) # Set I-Frame transparency
		
		velocity = Vector2(hit_direction * 200, -150)
		change_state(State.HURT)

func upgrade_max_health():
	if Global.max_health < 5:
		Global.max_health += 1
		Global.current_health = Global.max_health # Fully heal the player on upgrade
		
		# Tell the UI to draw a brand new square!
		health_changed.emit(Global.current_health, Global.max_health)

func die():
	# For now, just reload the scene when we die
	get_tree().reload_current_scene()
