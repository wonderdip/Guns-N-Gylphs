extends Node2D

signal dungeon_ready

# Grid settings
@export var grid_size = Vector2(10, 10)  # 10x10 grid
@export var tile_size = 16  # Size of a single tile in pixels
@export var room_width_tiles = 10  # Number of tiles per room width
@export var room_height_tiles = 10  # Number of tiles per room height
@export var room_spacing = 2  # Additional spacing between rooms (in room units)
@export var min_rooms = 5
@export var max_rooms = 15
@export var room_chance = 0.6  # Chance of a room spawning in a cell
@export var first_room_position = Vector2(0, 0)  # Fixed position for the first room
@export var door_width = 3  # Width of doors in tiles (odd number recommended)
@export var use_custom_seed = false  # Whether to use a custom seed
@export var custom_seed = 0  # Custom seed value if enabled

# Room types and chances
@export var room_types: Array[RoomType] = []

# Scene references
@export var corridor_scene: PackedScene

# Tracking variables
var rooms = []  # Array to store room instances
var corridors = []  # Array to store corridor instances
var room_grid = []  # 2D array to track which grid cells have rooms
var connections = []  # Array to track connections between rooms
var current_seed = 0  # Store the current seed

func _ready():
	# Add to a group for easier access from other scripts
	add_to_group("dungeon_generator")
	
	# Generate the dungeon
	generate_new_dungeon()
	
	# Signal that the dungeon is ready
	emit_signal("dungeon_ready")

func generate_new_dungeon():
	# Clear any existing dungeon
	clear_dungeon()
	
	# Set up the seed
	if use_custom_seed:
		current_seed = custom_seed
	else:
		current_seed = randi()
	
	seed(current_seed)
	
	for frames in 2:
		await Engine.get_main_loop().process_frame
	
	# Generate the new dungeon
	initialize_grid()
	generate_dungeon()

func clear_dungeon():
	# Remove all room instances
	for room_data in rooms:
		if is_instance_valid(room_data["instance"]):
			room_data["instance"].queue_free()
	
	# Remove all corridor instances
	for corridor in corridors:
		if is_instance_valid(corridor):
			corridor.queue_free()
	
	# Force removal of any remaining children that might be rooms or corridors
	for child in get_children():
		if child.name.begins_with("Room") or child.name.begins_with("Corridor"):
			child.queue_free()
	
	# Clear tracking arrays
	rooms.clear()
	corridors.clear()
	connections.clear()
	room_grid.clear()

func initialize_grid():
	# Create a 2D array filled with null values
	room_grid = []
	for x in range(grid_size.x):
		var column = []
		for y in range(grid_size.y):
			column.append(null)
		room_grid.append(column)

func generate_dungeon():
	# First, decide how many rooms to create
	var num_rooms = randi_range(min_rooms, max_rooms)
	
	# Initialize room type instance counters
	var room_type_instances = {}
	for i in range(room_types.size()):
		room_type_instances[i] = 0
	
	# Start with the first room at a fixed position (always use regular room for first room)
	create_room(first_room_position.x, first_room_position.y, 1, 0)  # Index 0 is assumed to be the default room type
	
	# Now generate the rest of the rooms through expansion
	var current_room_count = 1
	
	while current_room_count < num_rooms:
		# Pick a random existing room
		var source_room = rooms[randi() % rooms.size()]
		var source_index = source_room["index"]
		var source_pos = source_room["grid_pos"]
		
		# Try to place a room in an adjacent cell
		var directions = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]
		directions.shuffle()
		
		for dir in directions:
			var new_pos = source_pos + dir
			
			# Check if position is valid and empty
			if is_valid_position(new_pos) and room_grid[new_pos.x][new_pos.y] == null:
				# Random chance to create a room
				if randf() <= room_chance:
					current_room_count += 1
					
					# Select a room type based on weighted probability
					var room_type_index = select_room_type(room_type_instances)
					
					create_room(new_pos.x, new_pos.y, current_room_count, room_type_index)
					create_corridor(source_pos, new_pos, source_index, current_room_count)
					
					# Increment the instance counter for this room type
					room_type_instances[room_type_index] += 1
					break
	
	print("Generated dungeon with ", rooms.size(), " rooms using seed: ", current_seed)
	unlock_rooms_connected_to(1)

func select_room_type(room_type_instances):
	# Calculate total available weight
	var total_weight = 0.0
	var available_types = []
	
	for i in range(room_types.size()):
		var room_type = room_types[i]
		if room_type.max_instances == -1 or room_type_instances[i] < room_type.max_instances:
			total_weight += room_type.weight
			available_types.append(i)
	
	# Default to room type 0 if no room types are available (should be the standard room)
	if available_types.size() == 0:
		return 0
		
	# Select a room type based on weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for type_index in available_types:
		cumulative_weight += room_types[type_index].weight
		if random_value <= cumulative_weight:
			return type_index
	
	# Fallback to the first available type
	return available_types[0]

func is_valid_position(pos):
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

func create_room(x, y, index, room_type_index):
	# Get the room scene based on the type index
	var room_scene = room_types[room_type_index].scene
	
	# Create a new room instance
	var room_instance = room_scene.instantiate()
	add_child(room_instance)
	
	room_instance.connect("state_changed", Callable(self, "_on_room_state_changed"))
	
	# Calculate room size in pixels based on tile size
	var room_pixel_width = room_width_tiles * tile_size
	var room_pixel_height = room_height_tiles * tile_size
	
	# Calculate room position with spacing
	var total_width = room_pixel_width + (tile_size * room_spacing)
	var total_height = room_pixel_height + (tile_size * room_spacing)
	
	# Configure the room
	room_instance.position = Vector2(x * total_width, y * total_height)
	room_instance.name = "Room" + str(index)
	
	# Store room information
	var room_data = {
		"instance": room_instance,
		"grid_pos": Vector2(x, y),
		"index": index,
		"pixel_pos": room_instance.position,
		"pixel_size": Vector2(room_pixel_width, room_pixel_height),
		"state": room_instance.current_state,
		"room_type": room_type_index,
		"is_special": room_types[room_type_index].is_special
	}
	
	rooms.append(room_data)
	room_grid[x][y] = index
	
	# Setup the room
	room_instance.setup(Vector2(room_width_tiles, room_height_tiles), tile_size, index, door_width)
	print("Created room with index: ", index, " type: ", room_type_index, " at position: ", Vector2(x, y))

func create_corridor(from_pos, to_pos, from_index, to_index):
	# Store the connection information
	connections.append({
		"from": from_index,
		"to": to_index,
		"from_pos": from_pos,
		"to_pos": to_pos
	})
	
	# Determine direction
	var direction = to_pos - from_pos
	var corridor_dir = Vector2.ZERO
	
	# Calculate corridor direction (either horizontal or vertical)
	if abs(direction.x) > abs(direction.y):
		corridor_dir = Vector2(sign(direction.x), 0)
	else:
		corridor_dir = Vector2(0, sign(direction.y))
	
	# Find the room instances by their index attribute
	var from_room = null
	var to_room = null
	
	for room in rooms:
		if room["index"] == from_index:
			from_room = room
		if room["index"] == to_index:
			to_room = room
		
		
		# Early exit if we found both rooms
		if from_room != null and to_room != null:
			break
	
	# Check if rooms were found
	if from_room == null or to_room == null:
		print("Error: Could not find rooms with indices ", from_index, " and ", to_index)
		return
	
	# Tell the rooms to create doorways in appropriate walls
	from_room["instance"].create_doorway(corridor_dir)
	to_room["instance"].create_doorway(-corridor_dir)
	
	# Create visual corridor between rooms
	create_corridor_instance(from_room, to_room, corridor_dir)

func _on_room_state_changed(room_index, new_state):
	for room in rooms:
		if room["index"] == room_index:
			room["state"] = new_state
			# Use the actual room instance to access the enum
			if new_state == room["instance"].RoomState.CLEARED:
				unlock_rooms_connected_to(room_index)
			break

func create_corridor_instance(from_room, to_room, direction):
	var corridor_instance = corridor_scene.instantiate()
	add_child(corridor_instance)
	
	# Get room positions and sizes
	var from_pos = from_room["pixel_pos"]
	var to_pos = to_room["pixel_pos"]
	var from_size = from_room["pixel_size"]
	var to_size = to_room["pixel_size"]
	
	var corridor_position = Vector2.ZERO
	var corridor_length = 0
	
	if direction.x != 0:  # Horizontal corridor
		# Calculate Y position (centered on the room's height)
		@warning_ignore("integer_division")
		var corridor_y = from_pos.y + (from_size.y / 2) - ((door_width * tile_size) / 2)
		
		if direction.x > 0:  # Right direction
			# Position at the right edge of the left room, but back 1 tile to overlap
			corridor_position.x = from_pos.x + from_size.x - tile_size
			corridor_position.y = corridor_y
			# Length is the gap between rooms plus 2 tiles for overlap
			corridor_length = (to_pos.x - (from_pos.x + from_size.x)) + (2 * tile_size)
		else:  # Left direction
			# Position at the left edge of the right room, but back 1 tile to overlap
			corridor_position.x = to_pos.x + to_size.x - tile_size
			corridor_position.y = corridor_y
			# Length is the gap between rooms plus 2 tiles for overlap
			corridor_length = (from_pos.x - (to_pos.x + to_size.x)) + (2 * tile_size)
	else:  # Vertical corridor
		# Calculate X position (centered on the room's width)
		@warning_ignore("integer_division")
		var corridor_x = from_pos.x + (from_size.x / 2) - ((door_width * tile_size) / 2)
		
		if direction.y > 0:  # Down direction
			# Position at the bottom edge of the top room, but back 1 tile to overlap
			corridor_position.x = corridor_x
			corridor_position.y = from_pos.y + from_size.y - tile_size
			# Length is the gap between rooms plus 2 tiles for overlap
			corridor_length = (to_pos.y - (from_pos.y + from_size.y)) + (2 * tile_size)
		else:  # Up direction
			# Position at the top edge of the bottom room, but back 1 tile to overlap
			corridor_position.x = corridor_x
			corridor_position.y = to_pos.y + to_size.y - tile_size
			# Length is the gap between rooms plus 2 tiles for overlap
			corridor_length = (from_pos.y - (to_pos.y + to_size.y)) + (2 * tile_size)
	
	# Convert pixel length to tile length and ensure minimum length
	var corridor_length_tiles = max(1, int(corridor_length / tile_size))
	
	# Set the corridor's position
	corridor_instance.position = corridor_position
	
	# Setup the corridor
	corridor_instance.setup(corridor_length_tiles, door_width, tile_size, direction, corridors.size())
	
	# Add to corridors array
	corridors.append(corridor_instance)

func unlock_rooms_connected_to(index):
	for connection in connections:
		if connection["from"] == index:
			unlock_room_by_index(connection["to"])
		elif connection["to"] == index:
			unlock_room_by_index(connection["from"])


# Helper function to unlock a room by its index
func unlock_room_by_index(index):
	for room in rooms:
		if room["index"] == index:
			# Set room state to unlocked
			if room["instance"] != null and is_instance_valid(room["instance"]):
				if room["instance"].current_state == room["instance"].RoomState.LOCKED:
					room["instance"].set_state(room["instance"].RoomState.UNLOCKED)
					print("Unlocked room with index: ", index)
			break


func get_room_grid():
	return room_grid

func get_room_at_grid_position(grid_pos):
	if grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y:
		var room_index = room_grid[grid_pos.x][grid_pos.y]
		if room_index != null:
			# Find and return the room data
			for room in rooms:
				if room["index"] == room_index:
					return room
	return null
