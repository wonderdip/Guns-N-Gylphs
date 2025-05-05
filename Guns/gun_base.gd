extends Node2D
class_name Gun

# Gun properties - these will be set from GunResource
var bullet: PackedScene
var damage: int = 0
var magazine_size: int = 0
var bullet_count: int = 0
var reload_time: float = 0
var hold_type: int = 0
var shot_radius: float = 0
var shot_delay: float = 0

@onready var shot_particles = $Pivot/GunSprite/BulletPoint/ShotParticles
@onready var gun_sprite = $Pivot/GunSprite
@onready var bullet_point = $Pivot/GunSprite/BulletPoint
@onready var pivot = $Pivot
@onready var player: Node2D = get_node("/root/World/Player")

var can_shoot: bool = true 
var current_mag_size: int = magazine_size
var reloading: bool = false
var gun_name: String = "Default Gun"
var dead_zone: float = 5.0

# Configure gun from resource
func configure_from_resource(resource: GunResource) -> void:
	gun_name = resource.gun_name
	bullet = resource.bullet
	damage = resource.damage
	magazine_size = resource.magazine_size
	current_mag_size = magazine_size
	bullet_count = resource.bullet_count
	reload_time = resource.reload_time
	hold_type = resource.hold_type
	shot_radius = resource.shot_radius
	shot_delay = resource.shot_delay

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
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position

	# Rotate the pivot toward the mouse
	var angle = (mouse_pos - pivot_pos).angle()
	pivot.global_rotation = angle

	# Only flip if the mouse is clearly on one side
	var delta_x = mouse_pos.x - pivot_pos.x
	if delta_x < -dead_zone:
		pivot.scale.y = -1
	elif delta_x > dead_zone:
		pivot.scale.y = 1

func _ready():
	# Initialize gun state
	current_mag_size = magazine_size  # Start fully loaded
	reloading = false
	can_shoot = true


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
	# Don't reload if we're already reloading or if the magazine is already full
	if reloading or current_mag_size >= magazine_size:
		return
	
	# Start reload process
	reloading = true
	can_shoot = false  # Disable shooting while reloading
	
	# Create a timer for reload
	var reload_timer = get_tree().create_timer(reload_time)
	
	# Wait for reload time to complete
	await reload_timer.timeout
	
	# Only complete the reload if the gun still exists and hasn't been removed
	if is_instance_valid(self) and not is_queued_for_deletion():
		# Reload complete
		current_mag_size = magazine_size
		reloading = false
		can_shoot = true
