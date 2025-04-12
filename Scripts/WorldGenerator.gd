extends Node2D

@export var tilemap: TileMap

# Tile atlas coordinates
var floor_tiles: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3,0)
, Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1)
, Vector2i(6,1)]
var wall_full: Vector2i = Vector2i(0, 0)
var wall_top: Vector2i = Vector2i(0, 2)
var wall_bottom: Vector2i = Vector2i(0, 1)
var wall_left: Vector2i = Vector2i(2, 1)
var wall_right: Vector2i = Vector2i(1, 1)
var corner_top_left: Vector2i = Vector2i(1, 2)
var corner_top_right: Vector2i = Vector2i(2, 2)
var corner_bottom_left: Vector2i = Vector2i(1, 3)
var corner_bottom_right: Vector2i = Vector2i(2, 3)
var reverse_corner_top_right: Vector2i = Vector2i(3, 2)
var reverse_corner_top_left: Vector2i = Vector2i(4, 2)



# Allow source_id to be set manually in the Inspector
@onready var player = get_node("Player")
@export var source_id: int = 1
@export var layer_id: int = 0

@export var dungeon_size: Vector2i = Vector2i(40, 40)
@export var min_room_size: int = 5
@export var max_room_size: int = 12
@export var max_rooms: int = 10
@export var corridor_length: int = 3
@export var corridor_width: int = 1  # Width of corridors (1 = standard, 2+ = wider)
@export var max_connections_per_room: int = 2  # Maximum connections per room
@export var spawn_chance_decrease: float = 0.15  # How much spawn chance decreases per room

var room_creation_order = []  # Stores rooms in creation order
var player_spawn_room = null  # Will store the room for player spawning

# Constants for tile types
const WALL = 1
const FLOOR = 0

# Add this to help with debugging
@export var debug_mode: bool = false

var dungeon = []
var rooms = []
var room_connections = {}  # Track connections between rooms
var tile_count = null

enum Room_State {ClEARED, LOCKED}
var room_states = {}

func _ready():
	randomize() # Ensure true randomness each run
	generate_dungeon()
	apply_tiles()
	
	# Choose a spawn room (e.g., "first", "last", "random", "middle")
	var spawn_pos = select_spawn_room("first")
	player.position = spawn_pos * 16 * 4
	
	# For debugging
	if debug_mode:
		print("Player spawn position: ", spawn_pos)
		print("Total rooms created: ", room_creation_order.size())
	
	# Now you can use spawn_pos to place your player
	# Example: player.position = spawn_pos * tile_size
	
	# Add visual debugging in editor
	if debug_mode:
		print("Dungeon generation complete - ", rooms.size(), " rooms created")
		print("TileMap valid: ", tilemap != null)
		print("TileMap has tileset: ", tilemap.tile_set != null if tilemap != null else false)
		print("Using source_id: ", source_id)
		print("Using layer_id: ", layer_id)

func generate_dungeon():
	dungeon = []  # Reset dungeon
	dungeon.resize(dungeon_size.x)
	room_creation_order = []  # Reset room creation order
	room_connections.clear()

	# Fill dungeon with walls
	for x in range(dungeon_size.x):
		var row = []
		row.resize(dungeon_size.y)
		for y in range(dungeon_size.y):
			row[y] = WALL
		dungeon[x] = row

	rooms.clear()

	# Start with a single room in the middle
	@warning_ignore("integer_division")
	var start_x = int(dungeon_size.x / 2 - max_room_size / 2)
	@warning_ignore("integer_division")
	var start_y = int(dungeon_size.y / 2 - max_room_size / 2)
	place_room(Vector2i(start_x, start_y), Vector2i(randi_range(min_room_size, max_room_size), randi_range(min_room_size, max_room_size)))
	
	# Add first room to creation order
	room_creation_order.append(rooms[0])
	
	# Initialize room connections tracking
	room_connections[0] = []
	
	# Try to place more rooms until max is reached or placement fails too many times
	var max_attempts = max_rooms * 5
	var attempts = 0
	var base_chance = 1.0
	
	while rooms.size() < max_rooms and attempts < max_attempts:
		# Calculate decreasing spawn chance as more rooms are added
		var spawn_chance = base_chance - (rooms.size() * spawn_chance_decrease)
		if spawn_chance <= 0.1:
			spawn_chance = 0.1  # Minimum chance floor
			
		# Roll for room spawn based on current chance
		if randf() > spawn_chance:
			attempts += 1
			continue
		
		# Pick a random existing room to connect from
		var source_room_idx = randi() % rooms.size()
		
		# Skip if this room already has max connections
		if room_connections[source_room_idx].size() >= max_connections_per_room:
			attempts += 1
			continue
		
		# Choose a random direction (up, right, down, left)
		var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		directions.shuffle()
		
		var placed = false
		for direction in directions:
			# Calculate exact room position with fixed corridor distance
			var source_room = rooms[source_room_idx]
			var new_room_size = Vector2i(
				randi_range(min_room_size, max_room_size),
				randi_range(min_room_size, max_room_size)
			)
			
			var corridor_exit = Vector2i(0, 0)
			var new_room_pos = Vector2i(0, 0)
			
			# ADJUSTED: Add extra distance between rooms to prevent wall overlap
			var extra_spacing = 1  # Add 1 extra tile between rooms
			
			if direction.x < 0:  # Left
				corridor_exit = Vector2i(
					source_room.position.x - corridor_length - 1 - extra_spacing,
					source_room.position.y + source_room.size.y / 2
				)
				new_room_pos = Vector2i(
					corridor_exit.x - new_room_size.x,
					corridor_exit.y - new_room_size.y / 2
				)
			elif direction.x > 0:  # Right
				corridor_exit = Vector2i(
					source_room.end.x + corridor_length + extra_spacing,
					source_room.position.y + source_room.size.y / 2
				)
				new_room_pos = Vector2i(
					corridor_exit.x,
					corridor_exit.y - new_room_size.y / 2
				)
			elif direction.y < 0:  # Up
				corridor_exit = Vector2i(
					source_room.position.x + source_room.size.x / 2,
					source_room.position.y - corridor_length - 1 - extra_spacing
				)
				new_room_pos = Vector2i(
					corridor_exit.x - new_room_size.x / 2,
					corridor_exit.y - new_room_size.y
				)
			elif direction.y > 0:  # Down
				corridor_exit = Vector2i(
					source_room.position.x + source_room.size.x / 2,
					source_room.end.y + corridor_length + extra_spacing
				)
				new_room_pos = Vector2i(
					corridor_exit.x - new_room_size.x / 2,
					corridor_exit.y
				)
			
			# Try to place the new room
			if place_room(new_room_pos, new_room_size):
				# Success! Connect rooms with exact corridor
				var corridor_start = Vector2i(0, 0)
				
				if direction.x < 0:  # Left
					corridor_start = Vector2i(
						source_room.position.x,  # Start at room edge
						source_room.position.y + source_room.size.y / 2
					)
					create_h_corridor(corridor_exit.x, corridor_start.x, corridor_start.y)
				elif direction.x > 0:  # Right
					corridor_start = Vector2i(
						source_room.end.x - 1,  # Start at room edge
						source_room.position.y + source_room.size.y / 2
					)
					create_h_corridor(corridor_start.x, corridor_exit.x, corridor_start.y)
				elif direction.y < 0:  # Up
					corridor_start = Vector2i(
						source_room.position.x + source_room.size.x / 2,
						source_room.position.y  # Start at room edge
					)
					create_v_corridor(corridor_exit.y, corridor_start.y, corridor_start.x)
				elif direction.y > 0:  # Down
					corridor_start = Vector2i(
						source_room.position.x + source_room.size.x / 2,
						source_room.end.y - 1  # Start at room edge
					)
					create_v_corridor(corridor_start.y, corridor_exit.y, corridor_start.x)
				
				# Record the connection
				var new_room_idx = rooms.size() - 1
				room_connections[source_room_idx].append(new_room_idx)
				room_connections[new_room_idx] = [source_room_idx]
				
				# Add to creation order
				room_creation_order.append(rooms[new_room_idx])
				
				placed = true
				break
				
		if not placed:
			attempts += 1

func place_room(pos: Vector2i, size: Vector2i = Vector2i.ZERO) -> bool:
	# Use provided size or randomize
	var w = size.x if size.x > 0 else randi_range(min_room_size, max_room_size)
	var h = size.y if size.y > 0 else randi_range(min_room_size, max_room_size)
	
	# Ensure the room fits inside the dungeon bounds with padding
	if pos.x < 1 or pos.y < 1 or pos.x + w >= dungeon_size.x - 1 or pos.y + h >= dungeon_size.y - 1:
		return false

	var new_room = Rect2i(pos.x, pos.y, w, h)
	
	# Check if this room overlaps with any existing room
	for room in rooms:
		if new_room.intersects(room):
			return false  # Room overlaps, reject placement
	
	# Add this line to ensure room bounds are correct
	new_room = new_room.abs()  # Ensure positive width/height 
	
	rooms.append(new_room)
	room_creation_order.append(new_room)  # Add to creation order
	carve_room(new_room)
	return true

func carve_room(room: Rect2i):
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			if x >= 0 and x < dungeon_size.x and y >= 0 and y < dungeon_size.y:
				dungeon[x][y] = FLOOR  # Floor

func create_h_corridor(x1: int, x2: int, y: int):
	# Calculate half width for vertical spread (rounded down)
	@warning_ignore("integer_division")
	var half_width = corridor_width / 2
	
	for x in range(min(x1, x2), max(x1, x2) + 1):
		# Create the corridor with the specified width
		for w in range(corridor_width):
			var corridor_y = y - half_width + w
			if x >= 0 and x < dungeon_size.x and corridor_y >= 0 and corridor_y < dungeon_size.y:
				dungeon[x][corridor_y] = FLOOR

func create_v_corridor(y1: int, y2: int, x: int):
	# Calculate half width for horizontal spread (rounded down)
	@warning_ignore("integer_division")
	var half_width = corridor_width / 2
	
	for y in range(min(y1, y2), max(y1, y2) + 1):
		# Create the corridor with the specified width
		for w in range(corridor_width):
			var corridor_x = x - half_width + w
			if corridor_x >= 0 and corridor_x < dungeon_size.x and y >= 0 and y < dungeon_size.y:
				dungeon[corridor_x][y] = FLOOR


func apply_tiles():
	# Make sure we have a valid tilemap reference
	if tilemap == null:
		print("ERROR: TileMap reference is null!")
		return
		
	# Make sure tilemap has a valid tileset
	if tilemap.tile_set == null:
		print("ERROR: TileMap has no TileSet assigned!")
		return
		
	# Clear the existing tilemap
	tilemap.clear()
	
	# We're using the source_id set in the Inspector
	if debug_mode:
		print("Starting to place tiles...")
		tile_count = 0
	
	for x in range(dungeon_size.x):
		for y in range(dungeon_size.y):
			var tile_coords = get_tile_for_position(x, y)
			
			# Set the tile with the source ID
			tilemap.set_cell(layer_id, Vector2i(x, y), source_id, tile_coords)
			
			if debug_mode:
				tile_count += 1
				if tile_count % 100 == 0:
					print("Placed ", tile_count, " tiles...")
	
	if debug_mode:
		print("All tiles placed.")
		print(rooms)


func get_tile_for_position(x: int, y: int) -> Vector2i:
	if x < 0 or y < 0 or x >= dungeon_size.x or y >= dungeon_size.y:
		return wall_full
	
	if dungeon[x][y] == WALL:
		# Check directly adjacent floor tiles
		var is_floor_left = x > 0 and dungeon[x - 1][y] == FLOOR
		var is_floor_right = x < dungeon_size.x - 1 and dungeon[x + 1][y] == FLOOR
		var is_floor_up = y > 0 and dungeon[x][y - 1] == FLOOR
		var is_floor_down = y < dungeon_size.y - 1 and dungeon[x][y + 1] == FLOOR

		# Count adjacent floors
		var adjacent_floor_count = 0
		if is_floor_left: adjacent_floor_count += 1
		if is_floor_right: adjacent_floor_count += 1
		if is_floor_up: adjacent_floor_count += 1
		if is_floor_down: adjacent_floor_count += 1
		
		# Check diagonal floor tiles
		var is_floor_top_left = (x > 0 and y > 0) and dungeon[x - 1][y - 1] == FLOOR
		var is_floor_top_right = (x < dungeon_size.x - 1 and y > 0) and dungeon[x + 1][y - 1] == FLOOR
		var is_floor_bottom_left = (x > 0 and y < dungeon_size.y - 1) and dungeon[x - 1][y + 1] == FLOOR
		var is_floor_bottom_right = (x < dungeon_size.x - 1 and y < dungeon_size.y - 1) and dungeon[x + 1][y + 1] == FLOOR
		
		# Internal corners (T-junctions) - when exactly two adjacent sides have floors
		if adjacent_floor_count == 2:
			if is_floor_left and is_floor_up:
				return reverse_corner_top_right
			if is_floor_right and is_floor_up:
				return reverse_corner_top_left
			if is_floor_left and is_floor_down:
				return wall_bottom
			if is_floor_right and is_floor_down:
				return wall_bottom
		
		# Standard walls - when exactly one adjacent side has floor
		if adjacent_floor_count == 1:
			if is_floor_left:
				return wall_left
			if is_floor_right:
				return wall_right
			if is_floor_up:
				return wall_top
			if is_floor_down:
				return wall_bottom
		
		# External corners - when diagonals have floors but sides don't
		if is_floor_top_left and !is_floor_left and !is_floor_up:
			return corner_bottom_right
		if is_floor_top_right and !is_floor_right and !is_floor_up:
			return corner_bottom_left
		if is_floor_bottom_left and !is_floor_left and !is_floor_down:
			return corner_top_right
		if is_floor_bottom_right and !is_floor_right and !is_floor_down:
			return corner_top_left
		
		return wall_full  # Default wall
	else:
		# Return a random floor tile
		return floor_tiles[randi() % floor_tiles.size()]
		
		
# Function to choose a spawn room
func select_spawn_room(spawn_method: String = "first") -> Vector2i:
	if room_creation_order.size() == 0:
		return Vector2i(0, 0)  # Fallback position
	
	var chosen_room = null
	
	match spawn_method:
		"first":
			chosen_room = room_creation_order[0]
		"last":
			chosen_room = room_creation_order[-1]
		"random":
			chosen_room = room_creation_order[randi() % room_creation_order.size()]
		"middle":
			@warning_ignore("integer_division")
			var middle_index = int(room_creation_order.size() / 2)
			chosen_room = room_creation_order[middle_index]
		_:
			# Default to first room
			chosen_room = room_creation_order[0]
	
	player_spawn_room = chosen_room
	
	# Return center position of the room
	return Vector2i(
		chosen_room.position.x + chosen_room.size.x / 2,
		chosen_room.position.y + chosen_room.size.y / 2
	)

func get_dungeon():
	return dungeon

# Add visual debugging option
func _draw():
	if debug_mode:
		for x in range(dungeon_size.x):
			for y in range(dungeon_size.y):
				var color = Color.WHITE if dungeon[x][y] == FLOOR else Color.BLACK
				draw_rect(Rect2(x * 8, y * 8, 7, 7), color)

