extends Node2D

# Door properties
@export var locked_door_color: Color = Color(1, 0.3, 0.3)  # Reddish
@export var unlocked_door_color: Color = Color(1, 1, 0.5)  # Yellowish
@export var cleared_door_color: Color = Color(0.5, 1, 0.5)  # Greenish

# Door components
@onready var horizontal_sprite = $HorizontalDoor
@onready var vertical_sprite = $VerticalDoor
@onready var collision_shape = $StaticBody2D/CollisionShape2D

# Door state tracking
var is_horizontal = false
var current_room = null
var door_state = 0  # 0 = locked, 1 = unlocked, 2 = cleared

# Called when the node enters the scene tree for the first time
func _ready():
	# Start in locked state by default
	update_door_appearance(0)
	
	# Debug info
	print("Door ready, sprites loaded: ", horizontal_sprite != null, vertical_sprite != null)
	print("Collision shape ready: ", collision_shape != null)

# Initialize the door with the correct orientation and parent room
func setup(direction, parent_room):
	current_room = parent_room
	print("Door setup with direction: ", direction, " for room: ", parent_room.room_index)
	
	# Determine orientation based on direction
	if direction.x != 0:  # East or West
		is_horizontal = true
		horizontal_sprite.visible = false
		vertical_sprite.visible = true
		
		# Adjust collision shape for vertical door
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(vertical_sprite.texture.get_width(), vertical_sprite.texture.get_height())
		collision_shape.shape = rect_shape
	
	else:  # North or South
		is_horizontal = false
		horizontal_sprite.visible = true
		vertical_sprite.visible = false
		
		# Adjust collision shape for horizontal door
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(horizontal_sprite.texture.get_width(), horizontal_sprite.texture.get_height())
		collision_shape.shape = rect_shape
	
	# Connect to room state change signal
	if current_room and current_room.has_signal("state_changed"):
		if not current_room.is_connected("state_changed", Callable(self, "_on_room_state_changed")):
			current_room.connect("state_changed", Callable(self, "_on_room_state_changed"))
	
	# Set initial state based on room state
	if current_room:
		update_door_state(current_room.current_state)

# Process function to periodically check room state
func _process(_delta):
	if current_room:
		var room_state = current_room.current_state
		if door_state != room_state:
			update_door_state(room_state)

# Update door state based on room state
func update_door_state(new_state):
	door_state = new_state
	update_door_appearance(new_state)
	
	# Enable/disable collision based on state
	if new_state == 0:  # Locked
		collision_shape.disabled = false
	else:  # Unlocked or cleared
		collision_shape.disabled = true

# Update the door's visual appearance based on state
func update_door_appearance(state):
	match state:
		0:  # Locked
			horizontal_sprite.modulate = locked_door_color
			vertical_sprite.modulate = locked_door_color
		1:  # Unlocked
			horizontal_sprite.modulate = unlocked_door_color
			vertical_sprite.modulate = unlocked_door_color
		2:  # Cleared
			horizontal_sprite.modulate = cleared_door_color 
			vertical_sprite.modulate = cleared_door_color

# Signal handler for room state changes
func _on_room_state_changed(room_index, new_state):
	if current_room and current_room.room_index == room_index:
		update_door_state(new_state)
