extends Node2D

# Room components
@onready var tilemap = $TileMap
@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D

@export var door: PackedScene

# Room states
enum RoomState {LOCKED, UNLOCKED, CLEARED}
var current_state = RoomState.LOCKED

# Room properties
var room_size_tiles = Vector2(0, 0)  # Size in tiles, not pixels
var tile_size = 16  # Size of a single tile in pixels
var room_index = 0
var door_width = 3  # Door width in tiles (odd number recommended for symmetry)

var FLOOR_TILES = [
	Vector2(4, 0),
	Vector2(5, 0),
	Vector2(6, 0),
	Vector2(7, 0),
	Vector2(8, 0),
	Vector2(9, 0),
	Vector2(4, 1),
	Vector2(5, 1),
	Vector2(6, 1),
	Vector2(7, 1),
	Vector2(8, 1),
	Vector2(9, 1),
]

var WALL_TOP_TILES = [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(2, 0),
	Vector2(3, 0),
]

var WALL_BOTTOM_TILES = [
	Vector2(0, 1),
	Vector2(1, 1),
	Vector2(2, 1),
	Vector2(3, 1)
]

var WALL_RIGHT_TILES = [
	Vector2(1, 2),
	Vector2(1, 3),
	Vector2(1, 4)
]

var WALL_LEFT_TILES = [
	Vector2(0, 2),
	Vector2(0, 3),
	Vector2(0, 4)
]

var CORNER_TOP_LEFT_TILES = [
	Vector2(6, 2)
]

var CORNER_TOP_RIGHT_TILES = [
	Vector2(7, 2)
]

var CORNER_BOTTOM_RIGHT_TILES = [
	Vector2(9, 2)
]

var CORNER_BOTTOM_LEFT_TILES = [
	Vector2(8, 2)
]

# Door positions
var doors = {
	"north": false,
	"east": false, 
	"south": false,
	"west": false
}

# Connected rooms
var connected_rooms = []

# Signal for state changes
signal state_changed(room_index, new_state)

# Add this to your Room.gd script's setup method after generate_layout()

func setup(size_in_tiles, single_tile_size, index, door_width_tiles=3):
	room_size_tiles = size_in_tiles
	tile_size = single_tile_size
	room_index = index
	door_width = door_width_tiles
	
	# Size the area2D to match the room
	var shape = RectangleShape2D.new()
	var room_pixel_size = Vector2(room_size_tiles.x * tile_size, room_size_tiles.y * tile_size)
	shape.size = room_pixel_size  # Slightly smaller than the room
	collision_shape.shape = shape
	collision_shape.position = room_pixel_size * 0.5  # Center the collision shape
	
	# Set initial state based on index
	# First room is always unlocked
	if index == 1:
		set_state(RoomState.CLEARED)

	else:
		set_state(RoomState.LOCKED)

	# Generate the room layout
	generate_layout()
	
	# Spawn doors at each doorway (new code)
	if doors["north"]:
		spawn_door(Vector2(0, -1))
	if doors["east"]:
		spawn_door(Vector2(1, 0))
	if doors["south"]:
		spawn_door(Vector2(0, 1))
	if doors["west"]:
		spawn_door(Vector2(-1, 0))

func generate_layout():
	# Clear any existing tiles
	tilemap.clear()
	
	# Calculate room dimensions
	var width_tiles = int(room_size_tiles.x)
	var height_tiles = int(room_size_tiles.y)
	
	# Leave space for walls (1 tile on each edge)
	var inner_width = width_tiles - 2
	var inner_height = height_tiles - 2
	
	# Draw the floor
	for x in range(1, 1 + inner_width):
		for y in range(1, 1 + inner_height):
			# Pick a random floor tile from the array
			var random_floor = FLOOR_TILES[randi() % FLOOR_TILES.size()]
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(random_floor))
	
	# Calculate door positions and sizes
	@warning_ignore("integer_division")
	var north_door_start = int(1 + (inner_width - door_width) / 2)
	var south_door_start = north_door_start
	@warning_ignore("integer_division")
	var east_door_start = int(1 + (inner_height - door_width) / 2)
	var west_door_start = east_door_start
	
	# Draw walls with potential doorways
	# Top wall
	for x in range(1, 1 + inner_width):
		var is_door = doors["north"] and x >= north_door_start and x < north_door_start + door_width
		if not is_door:
			var random_top = WALL_TOP_TILES[randi() % WALL_TOP_TILES.size()]
			tilemap.set_cell(0, Vector2i(x, 0), 0, Vector2i(random_top))
	
	# Right wall
	for y in range(1, 1 + inner_height):
		var is_door = doors["east"] and y >= east_door_start and y < east_door_start + door_width
		if not is_door:
			var random_right = WALL_RIGHT_TILES[randi() % WALL_RIGHT_TILES.size()]
			tilemap.set_cell(0, Vector2i(1 + inner_width, y), 0, Vector2i(random_right))
	
	# Bottom wall
	for x in range(1, 1 + inner_width):
		var is_door = doors["south"] and x >= south_door_start and x < south_door_start + door_width
		if not is_door:
			var random_bottom = WALL_BOTTOM_TILES[randi() % WALL_BOTTOM_TILES.size()]
			tilemap.set_cell(0, Vector2i(x, 1 + inner_height), 0, Vector2i(random_bottom))
	
	# Left wall
	for y in range(1, 1 + inner_height):
		var is_door = doors["west"] and y >= west_door_start and y < west_door_start + door_width
		if not is_door:
			var random_left = WALL_LEFT_TILES[randi() % WALL_LEFT_TILES.size()]
			tilemap.set_cell(0, Vector2i(0, y), 0, Vector2i(random_left))
	
	# Draw corners
	tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(CORNER_TOP_LEFT_TILES[0]))
	tilemap.set_cell(0, Vector2i(1 + inner_width, 0), 0, Vector2i(CORNER_TOP_RIGHT_TILES[0]))
	tilemap.set_cell(0, Vector2i(1 + inner_width, 1 + inner_height), 0, Vector2i(CORNER_BOTTOM_RIGHT_TILES[0]))
	tilemap.set_cell(0, Vector2i(0, 1 + inner_height), 0, Vector2i(CORNER_BOTTOM_LEFT_TILES[0]))

# Create a doorway based on direction
# Modify your create_doorway function to include door spawning
func create_doorway(direction):
	
	if direction.x > 0:  # Going east
		doors["east"] = true
	elif direction.x < 0:  # Going west
		doors["west"] = true
	elif direction.y > 0:  # Going south
		doors["south"] = true
	elif direction.y < 0:  # Going north
		doors["north"] = true
	
	# Redraw the room with the new door
	generate_layout()
	
	# Spawn a door at this doorway
	spawn_door(direction)

# Add this to your Room.gd script after the create_doorway function

# Spawn a door at the specified direction
func spawn_door(direction):
	var door_instance = door.instantiate()
	add_child(door_instance)
	
	# Calculate the door position based on room dimensions and door direction
	var door_position = Vector2.ZERO
	
	# Calculate room dimensions in pixels
	var room_width_pixels = room_size_tiles.x * tile_size
	var room_height_pixels = room_size_tiles.y * tile_size
	
	# Calculate door width in pixels
	var _door_width_pixels = door_width * tile_size
	
	# Calculate the position based on direction and center on the doorway
	if direction.x > 0:  # East door
		door_position.x = room_width_pixels   # Right edge of room
		door_position.y = room_height_pixels / 2  # Vertically centered
	elif direction.x < 0:  # West door
		door_position.x = 0  # Left edge of room
		door_position.y = room_height_pixels / 2  # Vertically centered
	elif direction.y > 0:  # South door
		door_position.x = room_width_pixels / 2  # Horizontally centered
		door_position.y = room_height_pixels  # Bottom edge of room
	elif direction.y < 0:  # North door
		door_position.x = room_width_pixels / 2  # Horizontally centered
		door_position.y = 0  # Top edge of room
	
	# Add a debug print
	print("Spawning door at direction: ", direction, " position: ", door_position)
	
	# Setup the door
	door_instance.setup(direction, self)
	door_instance.position = door_position
	
	# Name the door based on its direction
	if direction.x > 0:
		door_instance.name = "EastDoor"
	elif direction.x < 0:
		door_instance.name = "WestDoor"
	elif direction.y > 0:
		door_instance.name = "SouthDoor"
	elif direction.y < 0:
		door_instance.name = "NorthDoor"

# Register a connection to another room
func add_connected_room(room_indexs):
	if not room_indexs in connected_rooms:
		connected_rooms.append(room_indexs)

# Set room state
func set_state(new_state):
	var old_state = current_state
	current_state = new_state
	
	# Emit signal if state changed
	if old_state != new_state:
		emit_signal("state_changed", room_index, new_state)

# Check if room is locked
func is_locked():
	return current_state == RoomState.LOCKED

# Check if room is cleared
func is_cleared():
	return current_state == RoomState.CLEARED
	
# Called when player enters the room
func _on_area_2d_body_entered(body):
	if body.has_method("is_player") and body.is_player():
		if current_state == RoomState.UNLOCKED:
			# TODO: Trigger enemies to spawn here
			pass
