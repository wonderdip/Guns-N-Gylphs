class_name TileDefinitions
extends Resource

@export var FLOOR_TILES: Array[Vector2] = [
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

# Wall tiles
@export var WALL_TOP_TILES: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(2, 0),
	Vector2(3, 0),
]

@export var WALL_BOTTOM_TILES: Array[Vector2] = [
	Vector2(0, 1),
	Vector2(1, 1),
	Vector2(2, 1),
	Vector2(3, 1)
]

@export var WALL_RIGHT_TILES: Array[Vector2] = [
	Vector2(1, 2),
	Vector2(1, 3),
	Vector2(1, 4)
]

@export var WALL_LEFT_TILES: Array[Vector2] = [
	Vector2(0, 2),
	Vector2(0, 3),
	Vector2(0, 4)
]

# Corner tiles
@export var CORNER_TOP_LEFT: Vector2 = Vector2(6, 2)
@export var CORNER_TOP_RIGHT: Vector2 = Vector2(7, 2)
@export var CORNER_BOTTOM_RIGHT: Vector2 = Vector2(9, 2)
@export var CORNER_BOTTOM_LEFT: Vector2 = Vector2(8, 2)

# Inverted corners
@export var CORNER_INVERTED_TOP_LEFT: Vector2 = Vector2(0, 0)
@export var CORNER_INVERTED_TOP_RIGHT: Vector2 = Vector2(0, 0)
@export var CORNER_INVERTED_BOTTOM_LEFT: Vector2 = Vector2(5, 2)
@export var CORNER_INVERTED_BOTTOM_RIGHT: Vector2 = Vector2(4, 2)

# Helper method to get a random floor tile
func get_random_floor_tile() -> Vector2:
	return FLOOR_TILES[randi() % FLOOR_TILES.size()]

# Helper method to get a random wall tile based on direction
func get_random_wall_tile(wall_type: String) -> Vector2:
	match wall_type:
		"top":
			return WALL_TOP_TILES[randi() % WALL_TOP_TILES.size()]
		"bottom":
			return WALL_BOTTOM_TILES[randi() % WALL_BOTTOM_TILES.size()]
		"left":
			return WALL_LEFT_TILES[randi() % WALL_LEFT_TILES.size()]
		"right":
			return WALL_RIGHT_TILES[randi() % WALL_RIGHT_TILES.size()]
	return Vector2.ZERO
