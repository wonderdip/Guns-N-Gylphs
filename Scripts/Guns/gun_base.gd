extends Node2D
class_name Gun

@export var bullet: PackedScene
@export var damage: int = 0
@export var magazine_size: int = 0
@export var bullet_count: int = 0
@export var reload_time: float = 0
@export_range(0, 2) var hold_type: int = 0
@export_range(0, 360) var shot_radius: float = 0
@export_range(0, 1000) var shot_delay: float = 0

@onready var shot_particles = $Pivot/GunSprite/BulletPoint/ShotParticles
@onready var gun_sprite = $Pivot/GunSprite
@onready var bullet_point = $Pivot/GunSprite/BulletPoint
@onready var pivot = $Pivot
@onready var player: Node2D = get_node("/root/World/Player")

var can_shoot: bool = true 
var current_mag_size: int = magazine_size
var reloading: bool = false


func _process(_delta):
	call_deferred("update_art")
	
	if Input.is_action_just_pressed("reload"):
		reload()
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		CameraShakeManager.cam_shake(5, 2, 0.2)
		
	if player.dodging == true:
		can_shoot = false
	else:
		can_shoot = true
	
	
func update_art():
	pass
	
func _ready():
	current_mag_size = magazine_size  # Start fully loaded


func shoot():
	if not can_shoot or reloading:
		return  # Don't shoot if already reloading or on cooldown

	if current_mag_size <= 0:
		reload()
		return
		
	# Handle bullet spread
	var angle = (get_global_mouse_position() - gun_sprite.global_position).angle()
	var random_offset = randf_range(-7, 7)
	angle += deg_to_rad(random_offset)
	
	can_shoot = false  # Prevent instant re-shooting
	current_mag_size -= bullet_count  # Subtract ONE bullet per shot (not bullet_count)
	
	for i in range(bullet_count):
		var new_bullet = bullet.instantiate()
		new_bullet.global_position = bullet_point.global_position
		new_bullet.damage = damage
		new_bullet.get_node("BulletSprite").hide()
		
		if bullet_count == 1:
			new_bullet.rotation = angle
		else:
			var arc_rad = deg_to_rad(shot_radius)
			var increment = arc_rad / (bullet_count - 1)
			new_bullet.global_rotation = angle + (increment * i - arc_rad / 2)
		
		get_tree().root.call_deferred("add_child", new_bullet)
	await get_tree().create_timer(shot_delay).timeout  # Apply shot delay
	# If out of bullets, start reload automatically
	if current_mag_size <= 0:
		reload()
	else:
		can_shoot = true  # Otherwise, allow shooting again



func reload():
	if reloading:
		return  # Prevent multiple reloads at once
	reloading = true
	can_shoot = false  # Disable shooting while reloading
	
	await get_tree().create_timer(reload_time).timeout  # Simulate reload time
	current_mag_size = magazine_size  # Reload magazine
	reloading = false
	can_shoot = true  # Allow shooting again
