extends Node2D

# Corridor components
@onready var tilemap = $TileMap
@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D

# Corridor properties
var corridor_length = 0  # Length in tiles
var corridor_width = 3   # Width in tiles (should match door_width)
var tile_size = 16     # Size of a single tile in pixels
var direction = Vector2.RIGHT  # Default direction
var corridor_index = 0

# Tile definitions
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

# Inverted corners for smooth transitions
var CORNER_INVERTED_TOP_LEFT = Vector2(0, 0)
var CORNER_INVERTED_TOP_RIGHT = Vector2(0, 0)
var CORNER_INVERTED_BOTTOM_LEFT = Vector2(5, 2)
var CORNER_INVERTED_BOTTOM_RIGHT = Vector2(4, 2)

# Called when added to the scene
func setup(length, width, single_tile_size, corridor_dir, index=0):
	corridor_length = length
	corridor_width = width
	tile_size = single_tile_size
	direction = corridor_dir
	corridor_index = index
	
	# Set name for easier identification
	name = "Corridor" + str(index)
	
	# Determine corridor dimensions and orientation
	var width_tiles = corridor_width
	var length_tiles = corridor_length
	
	# Adjust the size and rotation based on direction
	var corridor_pixel_size = Vector2.ZERO
	if direction.x != 0:  # Horizontal corridor
		corridor_pixel_size = Vector2(length_tiles * tile_size, width_tiles * tile_size)
		# No rotation needed for horizontal corridors
	else:  # Vertical corridor
		corridor_pixel_size = Vector2(width_tiles * tile_size, length_tiles * tile_size)
		# No rotation needed - we'll handle this in the tile layout
	
	# Create collision shape for the corridor
	var shape = RectangleShape2D.new()
	shape.size = corridor_pixel_size
	collision_shape.shape = shape
	collision_shape.position = corridor_pixel_size * 0.5  # Center the collision shape
	
	# Generate the corridor layout
	generate_layout()

func generate_layout():
	# Clear any existing tiles
	tilemap.clear()
	
	# Determine corridor dimensions based on direction
	var corridor_width_tiles = corridor_width
	var corridor_length_tiles = corridor_length
	
	if direction.x != 0:  # Horizontal corridor
		generate_horizontal_corridor(corridor_length_tiles, corridor_width_tiles)
	else:  # Vertical corridor
		generate_vertical_corridor(corridor_length_tiles, corridor_width_tiles)

func generate_horizontal_corridor(length_tiles, width_tiles):
	# Draw the floor tiles
	for x in range(length_tiles):
		for y in range(1, width_tiles - 1):
			var random_floor = FLOOR_TILES[randi() % FLOOR_TILES.size()]
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(random_floor))
	
	# Draw the top wall
	for x in range(length_tiles):
		var random_top = WALL_TOP_TILES[randi() % WALL_TOP_TILES.size()]
		tilemap.set_cell(0, Vector2i(x, 0), 0, Vector2i(random_top))
	
	# Draw the bottom wall
	for x in range(length_tiles):
		var random_bottom = WALL_BOTTOM_TILES[randi() % WALL_BOTTOM_TILES.size()]
		tilemap.set_cell(0, Vector2i(x, width_tiles - 1), 0, Vector2i(random_bottom))
	
	# Add correct corners based on corridor direction
	if direction.x > 0:  # Going right
		# Left end (connecting to room)
		tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(CORNER_INVERTED_TOP_LEFT))
		tilemap.set_cell(0, Vector2i(0, width_tiles - 1), 0, Vector2i(CORNER_INVERTED_BOTTOM_LEFT))
		
		# Right end (connecting to room)
		tilemap.set_cell(0, Vector2i(length_tiles - 1, 0), 0, Vector2i(CORNER_INVERTED_TOP_RIGHT))
		tilemap.set_cell(0, Vector2i(length_tiles - 1, width_tiles - 1), 0, Vector2i(CORNER_INVERTED_BOTTOM_RIGHT))
	else:  # Going left
		# Left end (connecting to room)
		tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(CORNER_INVERTED_TOP_LEFT))
		tilemap.set_cell(0, Vector2i(0, width_tiles - 1), 0, Vector2i(CORNER_INVERTED_BOTTOM_LEFT))
		
		# Right end (connecting to room)
		tilemap.set_cell(0, Vector2i(length_tiles - 1, 0), 0, Vector2i(CORNER_INVERTED_TOP_RIGHT))
		tilemap.set_cell(0, Vector2i(length_tiles - 1, width_tiles - 1), 0, Vector2i(CORNER_INVERTED_BOTTOM_RIGHT))

func generate_vertical_corridor(length_tiles, width_tiles):
	# Draw the floor tiles
	for y in range(length_tiles):
		for x in range(1, width_tiles - 1):
			var random_floor = FLOOR_TILES[randi() % FLOOR_TILES.size()]
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(random_floor))
	
	# Draw the left wall
	for y in range(length_tiles):
		var random_left = WALL_LEFT_TILES[randi() % WALL_LEFT_TILES.size()]
		tilemap.set_cell(0, Vector2i(0, y), 0, Vector2i(random_left))
	
	# Draw the right wall
	for y in range(length_tiles):
		var random_right = WALL_RIGHT_TILES[randi() % WALL_RIGHT_TILES.size()]
		tilemap.set_cell(0, Vector2i(width_tiles - 1, y), 0, Vector2i(random_right))
	
	# Add correct corners based on corridor direction
	if direction.y > 0:  # Going down
		# Top end (connecting to room)
		tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(CORNER_INVERTED_BOTTOM_RIGHT))
		tilemap.set_cell(0, Vector2i(width_tiles - 1, 0), 0, Vector2i(CORNER_INVERTED_BOTTOM_LEFT))
		
		# Bottom end (connecting to room)
		tilemap.set_cell(0, Vector2i(0, length_tiles - 1), 0, Vector2i(CORNER_INVERTED_TOP_RIGHT))
		tilemap.set_cell(0, Vector2i(width_tiles - 1, length_tiles - 1), 0, Vector2i(CORNER_INVERTED_TOP_LEFT))
	else:  # Going up
		# Top end (connecting to room)
		tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(CORNER_INVERTED_BOTTOM_RIGHT))
		tilemap.set_cell(0, Vector2i(width_tiles - 1, 0), 0, Vector2i(CORNER_INVERTED_BOTTOM_LEFT))
		
		# Bottom end (connecting to room)
		tilemap.set_cell(0, Vector2i(0, length_tiles - 1), 0, Vector2i(CORNER_INVERTED_TOP_RIGHT))
		tilemap.set_cell(0, Vector2i(width_tiles - 1, length_tiles - 1), 0, Vector2i(CORNER_INVERTED_TOP_LEFT))
