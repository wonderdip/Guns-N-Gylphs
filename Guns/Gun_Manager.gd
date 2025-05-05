extends Node
class_name GunManager

# Reference to the player
@export var player: Node2D
@export var gun_list_resource: GunList
@export var current_gun_parent: Node2D

# Current gun information
var current_gun_index: int = 0
var equipped_guns: Array[String] = []  # Names of guns the player has
var active_gun: Gun = null
var can_switch: bool = true
# Dictionary to store ammo state for each gun
var gun_ammo_state: Dictionary = {}

func _ready():
	# Initialize with the first gun if available
	if gun_list_resource and gun_list_resource.guns.size() > 0:
		# Add unlocked guns to the player's inventory and initialize their ammo state
		for gun in gun_list_resource.get_unlocked_guns():
			equipped_guns.append(gun.gun_name)
			
			# Initialize ammo state with full magazines
			gun_ammo_state[gun.gun_name] = {
				"current_mag_size": gun.magazine_size,
				"reloading": false
			}
		
		# Equip the first gun
		if equipped_guns.size() > 0:
			equip_gun(0)


func _process(_delta):
	if can_switch == true:
		# Handle weapon switching
		if Input.is_action_just_pressed("next_weapon"):
			next_gun()

		elif Input.is_action_just_pressed("prev_weapon"):
			prev_gun()


func weapon_switch_check():
	await get_tree().create_timer(1).timeout
	can_switch = true

func next_gun():
	var next_index = (current_gun_index + 1) % equipped_guns.size()
	equip_gun(next_index)
	can_switch = false
	weapon_switch_check()

func prev_gun():
	var prev_index = (current_gun_index - 1)
	if prev_index < 0:
		prev_index = equipped_guns.size() - 1
	equip_gun(prev_index)
	can_switch = false
	weapon_switch_check()

func equip_gun(index: int):
	if index < 0 or index >= equipped_guns.size():
		return
	
	# Save current gun's ammo state if there is an active gun
	if active_gun:
		gun_ammo_state[equipped_guns[current_gun_index]] = {
			"current_mag_size": active_gun.current_mag_size,
			"reloading": active_gun.reloading
		}
	
	# Clear current gun
	for child in current_gun_parent.get_children():
		child.queue_free()
	
	current_gun_index = index
	var gun_name = equipped_guns[index]
	var gun_resource = gun_list_resource.get_gun_by_name(gun_name)
	
	if gun_resource and gun_resource.gun_scene:
		# Instantiate the new gun
		var new_gun = gun_resource.gun_scene.instantiate()
		current_gun_parent.add_child(new_gun)
		active_gun = new_gun
		
		# Configure the gun with resource values
		if new_gun.has_method("configure_from_resource"):
			new_gun.configure_from_resource(gun_resource)
			
		# Restore ammo state if we have saved it before
		if gun_ammo_state.has(gun_name):
			new_gun.current_mag_size = gun_ammo_state[gun_name]["current_mag_size"]
			
			# If the gun was in the middle of reloading when we switched away,
			# we need to reset its reload state, as the reload process was interrupted
			if gun_ammo_state[gun_name]["reloading"]:
				# Instead of continuing the reload, reset the reload state
				# so the player needs to trigger the reload again
				new_gun.reloading = false
				new_gun.can_shoot = true
			else:
				# Normal case - gun wasn't reloading
				new_gun.reloading = false
				new_gun.can_shoot = true

func add_gun(gun_name: String) -> bool:
	# Add a gun to the player's inventory if it exists in the gun list
	var gun_resource = gun_list_resource.get_gun_by_name(gun_name)
	if gun_resource and not equipped_guns.has(gun_name):
		equipped_guns.append(gun_name)
		
		# Initialize ammo state for the new gun (full magazine)
		gun_ammo_state[gun_name] = {
			"current_mag_size": gun_resource.magazine_size,
			"reloading": false
		}
		
		return true
	return false

func remove_gun(gun_name: String) -> bool:
	# Remove a gun from the player's inventory
	var index = equipped_guns.find(gun_name)
	if index != -1:
		equipped_guns.remove_at(index)
		
		# If we removed the current gun, equip another one
		if index == current_gun_index:
			if equipped_guns.size() > 0:
				equip_gun(min(index, equipped_guns.size() - 1))
		# If we removed a gun before the current one, adjust the index
		elif index < current_gun_index:
			current_gun_index -= 1
		
		return true
	return false
