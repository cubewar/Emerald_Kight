extends CharacterBody2D

const PROJECTILE_SCENE = preload("res://Scenes/GameScenes/Enemies/SilverProjectile.tscn")

# --- UI SIGNALS ---
signal health_changed(current_health, max_health)
signal boss_defeated

# --- BOSS STATS ---
@export var boss_name: String = "Silver Knight"
@export var boss_color: Color = Color.LIGHT_STEEL_BLUE
var max_health: int = 100
var current_health: int = max_health

# --- AI VARIABLES ---
var state_timer: float = 2.0
var attack_choice: int = 0
var shots_fired: int = 0

enum State { IDLE, TELEGRAPH_HORIZ, ATTACK_HORIZ, SHOOT_STORM }
var current_state: State = State.IDLE

# --- NODES ---
# IMPORTANT: Make sure your Area2D is named exactly "HorizontalLaser" in the scene tree
@onready var horiz_laser_visual = $HorizontalLaser/ColorRect
@onready var horiz_laser_hitbox = $HorizontalLaser/CollisionShape2D


func _ready():
	# Ensure the laser is completely hidden and disabled when the boss spawns
	if horiz_laser_visual and horiz_laser_hitbox:
		horiz_laser_visual.visible = false
		horiz_laser_hitbox.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	# Basic gravity so the rectangle stands on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# The Boss Brain
	match current_state:
		State.IDLE:
			state_idle(delta)
		State.TELEGRAPH_HORIZ:
			state_telegraph_horiz(delta)
		State.ATTACK_HORIZ:
			state_attack_horiz(delta)
		State.SHOOT_STORM:
			state_shoot_storm(delta)

	move_and_slide()


# --- STATE LOGIC ---

func state_idle(delta):
	velocity.x = 0
	state_timer -= delta
	
	if state_timer <= 0:
		# Randomly pick between the Laser Sweep (0) or the Projectile Storm (1)
		attack_choice = randi() % 2
		
		if attack_choice == 0:
			current_state = State.TELEGRAPH_HORIZ
			state_timer = 0.6 # The player has 0.6 seconds to react!
		else:
			current_state = State.SHOOT_STORM
			state_timer = 1.0 # Wait 1 second between bursts


func state_telegraph_horiz(delta):
	horiz_laser_visual.visible = true
	horiz_laser_visual.color = Color(1.0, 0.0, 0.0, 0.3) # Faint transparent red
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.ATTACK_HORIZ
		state_timer = 0.2 # The laser stays deadly for exactly 0.2 seconds


func state_attack_horiz(delta):
	horiz_laser_visual.color = Color(1.0, 0.0, 0.0, 1.0) # Solid red
	horiz_laser_hitbox.set_deferred("disabled", false)
	
	state_timer -= delta
	if state_timer <= 0:
		horiz_laser_visual.visible = false
		horiz_laser_hitbox.set_deferred("disabled", true)
		current_state = State.IDLE
		state_timer = 2.0 # Rest for 2 seconds


func state_shoot_storm(delta):
	velocity.x = 0
	state_timer -= delta
	
	if state_timer <= 0:
		fire_shotgun_spread()
		shots_fired += 1
		
		if shots_fired >= 3:
			shots_fired = 0
			current_state = State.IDLE
			state_timer = 2.0 # Rest for 2 seconds
		else:
			state_timer = 0.5 # Wait half a second before the next burst!


func fire_shotgun_spread():
	# Find the player using their group (Make sure the Emerald Knight is in the "player" group!)
	var target = get_tree().get_first_node_in_group("player") 
	if target == null: return
	
	# Calculate the base angle pointing directly at the player
	var base_direction = (target.global_position - global_position).normalized()
	var spread_angles = [-0.25, 0.0, 0.25] # Up 15 deg, Straight, Down 15 deg
	
	for angle_offset in spread_angles:
		var new_projectile = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(new_projectile)
		
		# Spawn it slightly in front of the boss so it doesn't instantly hit itself
		new_projectile.global_position = global_position + (base_direction * 20)
		new_projectile.direction = base_direction.rotated(angle_offset)


# --- SIGNALS & COMBAT ---

func start_fight():
	print("1. Start fight was triggered!") 
	
	var boss_ui = get_tree().get_first_node_in_group("boss_ui") 
	
	if boss_ui:
		print("2. I found the Boss UI!") 
		boss_ui.initialize_boss(boss_name, max_health, boss_color)
	else:
		print("ERROR: I could not find the UI!") 


# Connect your HorizontalLaser Area2D to this function in the Node tab!
func _on_horizontal_laser_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.name == "Player" and body.has_method("take_damage"):
		
		var shove_dir = sign(body.global_position.x - global_position.x)
		body.take_damage(20, shove_dir)


func take_damage(amount: int, hit_direction: float = 0.0):
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		boss_defeated.emit()
		queue_free()
