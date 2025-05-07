extends CharacterBody2D

@onready var animated_sprite = $BodySprite
@onready var left_hand_sprite = $LeftHandSprite
@onready var right_hand_sprite = $RightHandSprite
@onready var blink_timer = $BlinkTimer
@onready var hit_flash_player = $HitFlashPlayer
@onready var hit_box = $HitBox
@onready var hurt_box = $HurtBox/CollisionShape2D
@onready var player = self
@onready var gun_manager = $GunManager

@export var Speed = 0
@export var Health = 0
@export var gun_list: GunList  # Add reference to GunList resource

# Dodge roll parameters
@export var dodge_speed_multiplier: float = 1.1
@export var dodge_length: float = 0.7
@export var dodge_cooldown: float = 0.6
@export var dodge_invincibility_length: float = 0.5
var direction

var dodging: bool = false
var can_dodge: bool = true
var dodge_direction: Vector2 = Vector2.ZERO
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_facing_left: bool = false

var mouse_pos: Vector2

func _ready():
	add_to_group("Player")
	
	# Initialize gun manager
	gun_manager.player = self
	gun_manager.current_gun_parent = $CurrentGun
	gun_manager.gun_list_resource = gun_list


func _physics_process(delta):
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	mouse_pos = get_global_mouse_position()
	
	# Handle dodge cooldown timer
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			can_dodge = true
	
	# Handle dodge mechanics
	if dodging:
		dodge_timer -= delta
		velocity = dodge_direction * Speed * dodge_speed_multiplier
		
		if dodge_timer <= 0:
			dodging = false
			dodge_cooldown_timer = dodge_cooldown
	else:
		velocity = direction * Speed
		
		# Initiate dodge when pressing dodge input and not already dodging
		if Input.is_action_just_pressed("dodge") and can_dodge:
			start_dodge()
	
	move_and_slide()
	update_animations()
	sprite_facing()
	check_enemy_collisions()
	hand_visibility()

func start_dodge():
	var mouse_dir = (get_global_mouse_position() - player.global_position).normalized()
	
	dodging = true
	can_dodge = false
	dodge_timer = dodge_length
	
	dodge_direction = mouse_dir
	
	invincibility(dodge_invincibility_length)

	# Set dodge facing only if there's horizontal movement, otherwise keep current facing
	if abs(dodge_direction.x) > 0.1:
		dodge_facing_left = dodge_direction.x < 0
	else:
		# Keep current facing
		dodge_facing_left = animated_sprite.flip_h

	# Play dodge animation and hide hands
	animated_sprite.play("Dodge")
	left_hand_sprite.hide()
	right_hand_sprite.hide()

func update_animations():

	if dodging:
		# Play roll animation if it exists, otherwise use walk
		animated_sprite.play("Dodge")
	
	elif direction.length() > 0.0:
		animated_sprite.play("Walk")
		left_hand_sprite.play("WalkHands")
		right_hand_sprite.play("WalkHands")
	else:
		animated_sprite.play("Idle")
		left_hand_sprite.play("IdleHands")
		right_hand_sprite.play("IdleHands")


func sprite_facing():
	
	if dodging:
		# Use dodge direction to set facing
		animated_sprite.flip_h = dodge_facing_left
		left_hand_sprite.flip_h = dodge_facing_left
		right_hand_sprite.flip_h = dodge_facing_left
	else:
		# Use mouse position to set facing
		
		var face_left = mouse_pos.x < global_position.x
		animated_sprite.flip_h = face_left
		left_hand_sprite.flip_h = face_left
		right_hand_sprite.flip_h = face_left


func check_enemy_collisions():
	var overlapping_enemies: Array = %HurtBox.get_overlapping_bodies()
	if overlapping_enemies.size() > 0:
		for enemy in overlapping_enemies:
			if enemy is Enemy:
				Health -= enemy.Damage
				print("Health = ",Health)
				took_damage()
				


func hand_visibility():
	mouse_pos = get_global_mouse_position()
	
	if dodging:
		left_hand_sprite.hide()
		right_hand_sprite.hide()
		if gun_manager.active_gun:
			gun_manager.active_gun.visible = false
		
	elif gun_manager.active_gun:
		gun_manager.active_gun.visible = true
		var hold_type = gun_manager.active_gun.hold_type
		
		if hold_type == 1 and mouse_pos.x < global_position.x:
			left_hand_sprite.hide()
			right_hand_sprite.show()
		elif hold_type == 1 and mouse_pos.x > global_position.x:
			left_hand_sprite.show()
			right_hand_sprite.hide()
		elif hold_type == 2:
			left_hand_sprite.hide()
			right_hand_sprite.hide()
		else:  # hold_type == 0
			left_hand_sprite.show()
			right_hand_sprite.show()
	else:
		left_hand_sprite.show()
		right_hand_sprite.show()
		

func death():
	get_tree().quit()

func took_damage():
	invincibility(1.0)
	FreezeFrameManager.framefreeze(0.4, 0)
	hit_flash()
	
	if Health <= 0:
		death()

func invincibility(duration: float):
	var player_original_layer: int = player.collision_layer
	var player_original_mask: int = player.collision_mask
	# Put player on a layer enemies don't check (for example, layer 32, something unused)
	player.collision_layer = 1 << (32 - 1)
	# Optional: also disable enemy detection mask just to be safe
	player.collision_mask &= ~(1 << (2 - 1))  
	hurt_box.set_disabled(true)
	
	await get_tree().create_timer(duration).timeout
	
	hurt_box.set_disabled(false)
	player.collision_layer = player_original_layer
	player.collision_mask = player_original_mask

func blink(length):
	var blink_speed = 0.1  # Time between blinks (fixed speed)
	var blink_count = min(10, int(length / blink_speed) * 2)  # Ensure even count
	
	blink_timer.wait_time = blink_speed
	
	for i in range(blink_count):
		blink_timer.start()
		await blink_timer.timeout
		hit_flash_player.play("HitFlash")
	
	animated_sprite.visible = true  # Ensure it's visible at the end

func hit_flash():
	while Engine.time_scale == 0:
		await get_tree().process_frame
	hit_flash_player.play("HitFlash")
	await hit_flash_player.animation_finished
	blink(1)
