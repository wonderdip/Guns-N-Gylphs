extends CanvasLayer


@onready var map: Node2D = get_node("/root/World")
@onready var minimap_container: ColorRect = $MinimapContainer
@onready var player: Node2D = get_node("/root/World/Player")

@export var cell_size: int = 10  # Size of each cell in the minimap
@export var minimap_zoom: float = 2  # Zoom factor 

var container_size: Vector2
var minimap_size: Vector2

var colors = {
	"wall": Color(0.353, 0.212, 0.094), 
	"floor": Color(0.573, 0.388, 0.235),  
	"player": Color(0, 0, 1),      
	"door": Color(0.5, 0.3, 0),    
	"item": Color(1, 1, 0),        
	"enemy": Color(1, 0, 0.5)
}

# Constants to match your world generator
const WALL = 1
const FLOOR = 0
const DOOR = 2 

func _ready():
	
	container_size = minimap_container.size
	minimap_size = container_size
	
	minimap_container.connect("draw", Callable(self, "_on_minimap_container_draw"))

func _process(_delta):
	# Update the minimap by forcing a redraw
	if is_instance_valid(minimap_container):
		minimap_container.queue_redraw()


func _on_minimap_container_draw():
	draw_minimap_on_container()

func draw_minimap_on_container():
	# Get dungeon data directly from the map
	var dungeon_grid = get_dungeon_grid()
	
	if dungeon_grid == null or dungeon_grid.size() == 0:
		print("DEBUG: No dungeon grid available")
		return
	
	# Get dungeon size
	var dungeon_size = Vector2i(dungeon_grid.size(), dungeon_grid[0].size())
	
	# Determine center of the minimap (player position)
	var player_pos = player.global_position
	var grid_pos = world_to_grid_position(player_pos)
	
	# Calculate how many cells we can show in each direction (affected by zoom)
	var cells_visible_x = int(minimap_size.x / (2 * cell_size * minimap_zoom))
	var cells_visible_y = int(minimap_size.y / (2 * cell_size * minimap_zoom))
	
	var start_x = max(0, grid_pos.x - cells_visible_x)
	var end_x = min(dungeon_size.x - 1, grid_pos.x + cells_visible_x)
	
	# Draw the grid cells
	for x in range(start_x, end_x + 1):
		if x >= dungeon_grid.size():
			continue
			
		var row = dungeon_grid[x]
		var start_y = max(0, grid_pos.y - cells_visible_y)
		var end_y = min(row.size() - 1, grid_pos.y + cells_visible_y)
		
		for y in range(start_y, end_y + 1):
			if y >= row.size():
				continue
				
			var cell_type = row[y]
			var cell_pos = Vector2(
				(x - grid_pos.x) * cell_size * minimap_zoom + minimap_size.x / 2,
				(y - grid_pos.y) * cell_size * minimap_zoom + minimap_size.y / 2
			)
			
			# Draw different cells based on type with zoomed size
			var cell_rect = Rect2(cell_pos, Vector2(cell_size * minimap_zoom, cell_size * minimap_zoom))
			match cell_type:
				WALL: minimap_container.draw_rect(cell_rect, colors.wall)
				FLOOR: minimap_container.draw_rect(cell_rect, colors.floor)
				DOOR: minimap_container.draw_rect(cell_rect, colors.door)
				# Add more cell types as needed
	
	# Draw the player (always at center)
	minimap_container.draw_circle(Vector2(minimap_size.x / 2, minimap_size.y / 2), 
		cell_size * minimap_zoom / 2, colors.player)
	
	# Draw enemies, items, etc.
	draw_entities_on_container(grid_pos, cells_visible_x, cells_visible_y)

func draw_entities_on_container(player_grid_pos, cells_visible_x, cells_visible_y):
	# Get all enemies from the scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Draw enemies
	for enemy in enemies:
		if is_instance_valid(enemy):
			var enemy_pos = enemy.global_position
			var grid_pos = world_to_grid_position(enemy_pos)
			
			# Check if enemy is within visible range
			if (abs(grid_pos.x - player_grid_pos.x) <= cells_visible_x and 
				abs(grid_pos.y - player_grid_pos.y) <= cells_visible_y):
				
				# Calculate position relative to player with zoom factor
				var relative_pos = Vector2(
					(grid_pos.x - player_grid_pos.x) * cell_size * minimap_zoom + minimap_size.x / 2,
					(grid_pos.y - player_grid_pos.y) * cell_size * minimap_zoom + minimap_size.y / 2
				)
				
				# Draw enemy
				minimap_container.draw_circle(relative_pos, cell_size * minimap_zoom / 2, colors.enemy)
	
	# Draw items (if you have them in your game)
	var items = get_tree().get_nodes_in_group("items")
	for item in items:
		if is_instance_valid(item):
			var item_pos = item.global_position
			var grid_pos = world_to_grid_position(item_pos)
			
			# Check if item is within visible range
			if (abs(grid_pos.x - player_grid_pos.x) <= cells_visible_x and 
				abs(grid_pos.y - player_grid_pos.y) <= cells_visible_y):
				
				# Calculate position relative to player with zoom factor
				var relative_pos = Vector2(
					(grid_pos.x - player_grid_pos.x) * cell_size * minimap_zoom + minimap_size.x / 2,
					(grid_pos.y - player_grid_pos.y) * cell_size * minimap_zoom + minimap_size.y / 2
				)
				
				# Draw item
				minimap_container.draw_rect(
					Rect2(
						relative_pos - Vector2(cell_size * minimap_zoom / 4, cell_size * minimap_zoom / 4), 
						Vector2(cell_size * minimap_zoom / 2, cell_size * minimap_zoom / 2)
					), 
					colors.item
				)

func world_to_grid_position(world_pos):
	# Convert world position to grid position
	var grid_scale = get_grid_scale()
	return Vector2i(
		int(world_pos.x / grid_scale),
		int(world_pos.y / grid_scale)
	)

func get_dungeon_grid():
	# Get the dungeon grid from the WorldGenerator
	if is_instance_valid(map):
		if map.has_method("get_dungeon"):
			return map.get_dungeon()
		elif "dungeon" in map:
			return map.dungeon
	
	print("DEBUG: Could not retrieve dungeon grid")
	# Fallback: Return empty array since we can't get the actual dungeon
	return []

func get_grid_scale():
	# Try to get grid scale from the world generator
	if is_instance_valid(map):
		if map.has_method("get_grid_scale"):
			return map.get_grid_scale()
		elif "grid_scale" in map:
			return map.grid_scale
		elif "tile_size" in map:
			return map.tile_size
	
	# Default scale if not available
	return 64  # Common tile size in Godot
