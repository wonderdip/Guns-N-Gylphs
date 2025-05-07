extends BasicRoom

# Export variables
@export var chest_scene: PackedScene
@export var chest_opened_on_clear: bool = true
@export var unlock_room_on_chest_open: bool = true

# Properties
var chest_instance = null
var chest_spawned = false

# Signal for when the chest is opened
signal chest_opened

# Override the _ready function to initialize the chest room
func _ready():
	# Call the parent _ready first
	super()
	
	# Set properties for chest room
	enemies_per_room = 0  # Default to no enemies for chest rooms

# Override the setup method to add custom functionality
func setup(size_in_tiles, single_tile_size, index, door_width_tiles=3):
	# Call the parent setup method
	super(size_in_tiles, single_tile_size, index, door_width_tiles)
	
	# Spawn the chest after setup is complete
	call_deferred("spawn_chest")

# Override the generate_layout method to add custom decorations if needed
func generate_layout():
	# Call the parent method to generate the basic layout
	super()
	
	# Add any specific chest room tile decorations here
	# For example, you might want to add special floor tiles around where the chest will be

# Method to spawn a chest in the middle of the room
func spawn_chest():
	if chest_scene and not chest_spawned:
		chest_instance = chest_scene.instantiate()
		add_child(chest_instance)
		
		# Position the chest in the middle of the room
		var room_center_x = (room_size_tiles.x * tile_size) / 2
		var room_center_y = (room_size_tiles.y * tile_size) / 2
		chest_instance.position = Vector2(room_center_x, room_center_y)
		
		chest_spawned = true
		
		## Connect to chest opened signal if it exists
		#if chest_instance.has_signal("opened"):
			#chest_instance.connect("opened", Callable(self, "_on_chest_opened"))
		#
		#print("Chest spawned in room with index: ", room_index)
#
## Handler for when the chest is opened
#func _on_chest_opened():
	#emit_signal("chest_opened")
	#
	## If configured, clear the room when the chest is opened
	#if chest_opened_on_clear:
		#set_state(RoomState.CLEARED)
	#
	## If configured, unlock connected rooms when the chest is opened
	#if unlock_room_on_chest_open:
		## Find the dungeon generator to ask it to unlock connected rooms
		#var dungeon_generator = get_tree().get_first_node_in_group("dungeon_generator")
		#if dungeon_generator and dungeon_generator.has_method("unlock_rooms_connected_to"):
			#dungeon_generator.unlock_rooms_connected_to(room_index)

# Override the all_enemies_defeated method if needed
func all_enemies_defeated():
	# In chest rooms, we might not want to automatically clear the room
	# It might depend on the chest being opened instead
	if not chest_opened_on_clear:
		super()

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		# Instead of directly changing current_state, use set_state which emits signals
		set_state(RoomState.CLEARED)
		
		# Call unlock_rooms_connected_to to properly handle connected rooms
		var dungeon_generator = get_tree().get_first_node_in_group("dungeon_generator")
		if dungeon_generator and dungeon_generator.has_method("unlock_rooms_connected_to"):
			dungeon_generator.unlock_rooms_connected_to(room_index)
