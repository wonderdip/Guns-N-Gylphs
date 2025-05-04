extends Node2D

signal enemies_defeated

# Room components
@onready var tilemap = $TileMap
@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D

@export var door: PackedScene
@export var tile_definitions: TileDefinitions
@export var enemies_per_room: int
@export var enemies: Array[PackedScene] = []



# Room states
enum RoomState {LOCKED, UNLOCKED, CLEARED}
var current_state = RoomState.LOCKED

# Room properties
var room_size_tiles = Vector2(0, 0)  # Size in tiles, not pixels
var tile_size = 16  # Size of a single tile in pixels
var room_index = 0
var door_width = 3  # Door width in tiles (odd number recommended for symmetry)
var enemies_remaining = 0
var enemies_spawned := false

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

func _ready():
	# Load tile definitions if not assigned
	if not tile_definitions:
		tile_definitions = load("res://resources/tile_definitions.tres")

func setup(size_in_tiles, single_tile_size, index, door_width_tiles=3):
	room_size_tiles = size_in_tiles
	tile_size = single_tile_size
	room_index = index
	door_width = door_width_tiles
	
	# Size the area2D to match the room
	var shape = RectangleShape2D.new()
	var room_pixel_size = Vector2(room_size_tiles.x * tile_size, room_size_tiles.y * tile_size)
	shape.size = room_pixel_size*0.8  # Slightly smaller than the room
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
	
	# Spawn doors at each doorway
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
			# Use the tile_definitions resource for random floor tiles
			var random_floor = tile_definitions.get_random_floor_tile()
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
			var random_top = tile_definitions.get_random_wall_tile("top")
			tilemap.set_cell(0, Vector2i(x, 0), 0, Vector2i(random_top))
	
	# Right wall
	for y in range(1, 1 + inner_height):
		var is_door = doors["east"] and y >= east_door_start and y < east_door_start + door_width
		if not is_door:
			var random_right = tile_definitions.get_random_wall_tile("right")
			tilemap.set_cell(0, Vector2i(1 + inner_width, y), 0, Vector2i(random_right))
	
	# Bottom wall
	for x in range(1, 1 + inner_width):
		var is_door = doors["south"] and x >= south_door_start and x < south_door_start + door_width
		if not is_door:
			var random_bottom = tile_definitions.get_random_wall_tile("bottom")
			tilemap.set_cell(0, Vector2i(x, 1 + inner_height), 0, Vector2i(random_bottom))
	
	# Left wall
	for y in range(1, 1 + inner_height):
		var is_door = doors["west"] and y >= west_door_start and y < west_door_start + door_width
		if not is_door:
			var random_left = tile_definitions.get_random_wall_tile("left")
			tilemap.set_cell(0, Vector2i(0, y), 0, Vector2i(random_left))
	
	# Draw corners
	tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(tile_definitions.CORNER_TOP_LEFT))
	tilemap.set_cell(0, Vector2i(1 + inner_width, 0), 0, Vector2i(tile_definitions.CORNER_TOP_RIGHT))
	tilemap.set_cell(0, Vector2i(1 + inner_width, 1 + inner_height), 0, Vector2i(tile_definitions.CORNER_BOTTOM_RIGHT))
	tilemap.set_cell(0, Vector2i(0, 1 + inner_height), 0, Vector2i(tile_definitions.CORNER_BOTTOM_LEFT))

# Create a doorway based on direction
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

# Called when a room should be locked for combat
func lock_for_combat():
	# Set the state first (this doesn't directly affect physics)
	set_state(RoomState.LOCKED)
	
	# Then defer the door locking
	call_deferred("_deferred_lock_doors")
	call_deferred("on_player_entered_room")

func on_player_entered_room():
	if enemies_spawned:
		return  # Already spawned, don't spawn again
	
	spawn_enemies()
	enemies_spawned = true

func _deferred_lock_doors():
	# Close all doors
	for child in get_children():
		if child.name.ends_with("Door") and child.has_method("lock"):
			child.lock()

func spawn_enemies():
	for i in enemies_per_room:
		var enemy_scene = enemies.pick_random()
		if enemy_scene:
			call_deferred("_spawn_single_enemy", enemy_scene)
	
	# Add a counter to track defeated enemies
	enemies_remaining = enemies_per_room

func _spawn_single_enemy(enemy_scene):
	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)
	
	# Position the enemy randomly within the room
	var x = randf_range(tile_size * 2, room_size_tiles.x * tile_size - tile_size * 2)
	var y = randf_range(tile_size * 2, room_size_tiles.y * tile_size - tile_size * 2)
	enemy_instance.position = Vector2(x, y)
	
	# Optionally connect to a signal to detect when it's defeated
	if enemy_instance.has_signal("defeated"):
		enemy_instance.connect("defeated", Callable(self, "_on_enemy_defeated"))

func _on_enemy_defeated():
	enemies_remaining -= 1
	print(enemies_remaining)
	if enemies_remaining <= 0:
		all_enemies_defeated()
		
# Function to handle when all enemies are defeated
func all_enemies_defeated():
	# Set room to cleared state
	set_state(RoomState.CLEARED)

# Check if room is locked
func is_locked():
	return current_state == RoomState.LOCKED

# Check if room is cleared
func is_cleared():
	return current_state == RoomState.CLEARED

# Called when player enters the room
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		if current_state != RoomState.CLEARED:
			await get_tree().create_timer(0.1).timeout
			call_deferred("lock_for_combat")
