extends CharacterBody2D
class_name Enemy

@export var Health: float = 0
@export var Damage: int = 0
@export var Speed: int = 0

@onready var player = get_node("/root/Game/Player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cpu_particles_2d = $CPUParticles2D
@onready var collision_shape_2d = $CollisionShape2D

# Knockback properties
@export var knockback_strength: float = 0  # Strength of the knockback
@export var knockback_duration: float = 0  # Duration of the knockback effect
var knockback_timer: float = 0  # Timer to track knockback duration
var knockback_direction: Vector2 = Vector2.ZERO  # Direction of knockback

var camera2d: Camera2D
var cameraShakeNoise: FastNoiseLite

func _ready():
	camera2d = get_node("/root/Game/Player/DynamicCamera")
	cameraShakeNoise = FastNoiseLite.new()

func _physics_process(delta):
	if knockback_timer > 0:
		# Apply knockback if the timer is still active
		knockback_timer -= delta
		velocity = knockback_direction.normalized() * knockback_strength
	else:
		if Health > 0:
			move(delta)
		
		
	# Apply regular movement logic
	move_and_slide()

func move(_delta):
	pass

func take_damage(amount):
	Health -= amount
	FreezeFrameManager.framefreeze(0.1, 0.1)
	cpu_particles_2d.restart()
	apply_knockback(player.global_position)
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(StartCameraShake, 8.0, 2.0, 0.8)
	
	if Health <= 0:
		die()
		
	damaged()

func damaged():
	pass

func StartCameraShake(intensity: float):
	var cameraOffset = cameraShakeNoise.get_noise_1d(Time.get_ticks_msec()) * intensity
	camera2d.offset.x = cameraOffset
	camera2d.offset.y = cameraOffset

func apply_knockback(source_position: Vector2):
	# Set the knockback direction to be opposite of the player
	knockback_direction = global_position.direction_to(source_position).normalized() * -1
	knockback_timer = knockback_duration  # Set the knockback duration
	velocity = knockback_direction * knockback_strength  # Apply the knockback velocity



func die():
	cpu_particles_2d.restart()
	damaged()
	animated_sprite.stop()
	await get_tree().create_timer(0.3, true, false, true).timeout
	queue_free()

