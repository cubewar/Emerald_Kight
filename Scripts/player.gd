extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK
}

# Track the current state (Start in IDLE)
@export var current_state : State = State.IDLE

func _physics_process(delta: float) -> void:
	# 1. Add gravity globally (happens in every state unless on the floor)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Run the logic specific to our current state
	match current_state:
		State.IDLE:
			state_idle()
		State.RUN:
			state_run()
		State.JUMP:
			state_jump()
		State.FALL:
			state_fall()
		State.ATTACK:
			state_attack()
			
	# 3. Always apply movement at the very end of the frame!
	move_and_slide()


# --- STATE LOGIC FUNCTIONS ---

func state_idle():
	$AnimationPlayer.play("Idle") # Make sure capitalization matches your animation exactly!
	velocity.x = move_toward(velocity.x, 0, SPEED) # Stop sliding
	
	# Transitions out of IDLE
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP
	elif Input.get_axis("moveLeft", "moveRight"):
		current_state = State.RUN
	elif not is_on_floor():
		current_state = State.FALL

func state_run():
	$AnimationPlayer.play("run") 
	var direction = Input.get_axis("moveLeft", "moveRight")
	
	# Handle movement and flipping the sprite
	if direction:
		velocity.x = direction * SPEED
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		# No direction pressed? Go back to IDLE
		current_state = State.IDLE 
		
	# Transitions out of RUN
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP
	elif not is_on_floor():
		current_state = State.FALL

func state_jump():
	# $AnimationPlayer.play("Jump") # Uncomment if you have a jump animation
	
	# Allow horizontal movement while in the air
	var direction = Input.get_axis("moveLeft", "moveRight")
	if direction:
		velocity.x = direction * SPEED
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Transitions out of JUMP
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif velocity.y > 0: # If we start moving downwards, we are falling!
		current_state = State.FALL

func state_fall():
	# $AnimationPlayer.play("Fall") # Uncomment if you have a fall animation
	
	# Allow horizontal movement while in the air
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Transitions out of FALL
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif is_on_floor():
		# Did we land while holding a direction? Go to RUN. Otherwise, IDLE.
		if Input.get_axis("ui_left", "ui_right"):
			current_state = State.RUN
		else:
			current_state = State.IDLE

func state_attack():
	$AnimationPlayer.play("Attack")
	velocity.x = 0 # Lock the player in place for the heavy strike
	
	# Notice there is NO input checking here. 
	# We rely entirely on the animation signal to return to IDLE.


# --- SIGNALS AND JUICE ---

# IMPORTANT: Make sure this is connected from your AnimationPlayer's Node tab!
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Attack":
		current_state = State.IDLE # Return to normal when swing is done

func hit_stop():
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0

# IMPORTANT: Make sure this is connected from your HammerHitbox Area2D Node tab!
func _on_hammmer_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "EnemyHurtbox":
		hit_stop()
		$Camera2D.apply_shake(15.0) 
		# area.get_parent().take_damage(1)
