extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# --- NEW: MOMENTUM VARIABLES ---
const ACCELERATION = 800.0 # How fast the knight reaches max speed
const FRICTION = 1000.0    # How fast the knight slides to a stop

# --- GAME FEEL TIMERS ---
var coyote_timer: float = 0.0
const COYOTE_TIME: float = 0.15 

var jump_buffer_timer: float = 0.0
const JUMP_BUFFER_TIME: float = 0.1 

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK
}

@export var current_state : State = State.IDLE

func _physics_process(delta: float) -> void:
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

# --- HELPER FUNCTIONS ---

func perform_jump():
	velocity.y = JUMP_VELOCITY
	jump_buffer_timer = 0.0 
	coyote_timer = 0.0 
	current_state = State.JUMP

# --- SIGNALS AND JUICE ---

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Attack":
		if is_on_floor():
			current_state = State.IDLE 
		else:
			current_state = State.FALL

func hit_stop():
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_hammmer_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "EnemyHurtbox":
		hit_stop()
		$Camera2D.apply_shake(15.0) 
		var direction_to_enemy = sign(area.global_position.x - global_position.x)
		area.get_parent().take_damage(1, direction_to_enemy)
