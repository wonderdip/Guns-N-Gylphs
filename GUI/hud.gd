extends Node2D

@onready var ammo_sprite = $CanvasLayer/AmmoSprite
@onready var gun_container = get_node("/root/World/Player/CurrentGun")

var current_gun
var ammo_sprites = []

func _ready():
	# Get the first gun in the container
	update_current_gun()
	
	# Hide the original sprite
	if ammo_sprite:
		ammo_sprite.visible = false
		
	# Initial setup of ammo display
	update_ammo_display()

func _process(_delta):
	# Update gun reference if needed
	update_current_gun()
	
	# Only update when ammo changes
	if current_gun:
		update_ammo_display()

func update_current_gun():
	# Get the first child of the gun container
	if is_instance_valid(gun_container) and gun_container.get_child_count() > 0:
		current_gun = gun_container.get_child(0)

func update_ammo_display():
	# Clear existing sprites
	clear_ammo_sprites()
	
	
	# Create new sprites based on current ammo
	if current_gun and "current_mag_size" in current_gun:
		# Make sure your gun has this property
		var current_ammo = current_gun.current_mag_size
		
		for i in current_ammo:
			var new_ammo = ammo_sprite.duplicate()
			new_ammo.visible = true
			# Position horizontally with some spacing
			new_ammo.position = ammo_sprite.position + Vector2(0, i * 40)
			$CanvasLayer.add_child(new_ammo)
			ammo_sprites.append(new_ammo)

func clear_ammo_sprites():
	# Remove all existing ammo sprites
	for sprite in ammo_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	ammo_sprites.clear()


