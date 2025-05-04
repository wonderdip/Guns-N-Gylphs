extends Resource
class_name GunList

# Array of gun resources
@export var guns: Array[GunResource] = []

# Get a gun by name
func get_gun_by_name(name: String) -> GunResource:
	for gun in guns:
		if gun.gun_name == name:
			return gun
	return null
	
# Get a gun by index
func get_gun_by_index(index: int) -> GunResource:
	if index >= 0 and index < guns.size():
		return guns[index]
	return null
	
# Get all unlocked guns
func get_unlocked_guns() -> Array[GunResource]:
	var unlocked_guns: Array[GunResource] = []
	for gun in guns:
		if gun.unlocked:
			unlocked_guns.append(gun)
	return unlocked_guns
