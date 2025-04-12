extends Node2D

# Reference to the dungeon generator script
@export var dungeon_generator: Node2D

# Enemy scene preload
@export var enemy_scenes: Array[PackedScene] = []

# Enemy spawn settings
@export var min_enemies_per_room: int = 2
@export var max_enemies_per_room: int = 5
@export var spawn_offset_from_wall: int = 1

# Optional: Difficulty scaling
@export var increase_enemies_by_room: bool = true
@export var enemy_increase_factor: float = 0.5  # Add 0.5 more enemies per room (rounded)

# Debug
@export var debug_mode: bool = false

func _ready():
	# Wait for the dungeon to generate before spawning enemies
	# This assumes that dungeon_generator emits this signal when ready
	if dungeon_generator:
		# Connect to the ready signal with a 1-frame delay to ensure dungeon is fully generated
		call_deferred("spawn_enemies")
	else:
		push_error("Enemy Spawner: No dungeon generator reference assigned!")

func spawn_enemies():
	# Get room data from the dungeon generator
	var rooms = dungeon_generator.room_creation_order
	
	if rooms.size() <= 0:
		push_error("Enemy Spawner: No rooms found!")
		return
	
	if debug_mode:
		print("Starting enemy spawning in ", rooms.size() - 1, " rooms (skipping first room)")
	
	# Skip the first room (index 0) as it's the player's starting room
	for i in range(1, rooms.size()):
		var room = rooms[i]
		
		# Calculate enemies based on room number if scaling is enabled
		var enemy_count = min_enemies_per_room
		if increase_enemies_by_room:
			# More enemies in deeper rooms
			enemy_count = min_enemies_per_room + floor(i * enemy_increase_factor)
			# Cap at maximum
			enemy_count = min(enemy_count, max_enemies_per_room)
		else:
			# Random number of enemies in each room
			enemy_count = randi_range(min_enemies_per_room, max_enemies_per_room)
		
		if debug_mode:
			print("Spawning ", enemy_count, " enemies in room ", i)
		
		# Spawn enemies in this room
		for j in range(enemy_count):
			spawn_enemy_in_room(room)

func spawn_enemy_in_room(room: Rect2i):
	if enemy_scenes.size() == 0:
		push_error("Enemy Spawner: No enemy scenes assigned!")
		return
	
	# Choose a random enemy type
	var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	
	# Calculate a random position within the room, accounting for walls
	var spawn_x = randi_range(
		room.position.x + spawn_offset_from_wall, 
		room.end.x - spawn_offset_from_wall
	)
	
	var spawn_y = randi_range(
		room.position.y + spawn_offset_from_wall, 
		room.end.y - spawn_offset_from_wall
	)
	
	# Instantiate the enemy
	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)
	
	# Position the enemy - multiply by your tile size (16 * 4 based on your player positioning)
	enemy_instance.position = Vector2(spawn_x, spawn_y) * 16 * 4
	
	# Optional: Tag the enemy with room data for AI behavior
	if enemy_instance.has_method("set_home_room"):
		enemy_instance.set_home_room(room)
		
	if debug_mode:
		print("Enemy spawned at position: ", enemy_instance.position)

# This function can be called to spawn more enemies during gameplay if needed
func spawn_additional_enemies(count: int, exclude_first_room: bool = true):
	var rooms = dungeon_generator.room_creation_order
	
	# Start from index 1 if excluding first room
	var start_index = 1 if exclude_first_room else 0
	
	for i in range(count):
		# Choose a random room (excluding the first if specified)
		var room_index = randi_range(start_index, rooms.size() - 1)
		spawn_enemy_in_room(rooms[room_index])
