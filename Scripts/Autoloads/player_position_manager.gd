extends Node

signal player_room_changed(old_room_index, new_room_index)

# Cached references
var player: CharacterBody2D = null
var dungeon_generator: Node2D = null
var current_room = null
var current_room_index = 0

# Player scene reference - assign this in Project Settings > Autoload
@export var player_scene: PackedScene = preload("res://Scenes/Player.tscn")

func _ready():
	
	player = get_tree().get_root().find_child("Player", true, false)
	call_deferred("_setup_connections")

func _setup_connections():
	await get_tree().create_timer(0.1).timeout
	
	# Find the dungeon generator node
	var dungeon_gens = get_tree().get_nodes_in_group("dungeon_generator")
	if dungeon_gens.size() > 0:
		dungeon_generator = dungeon_gens[0]
		await get_tree().process_frame
		dungeon_generator.connect("dungeon_ready", Callable(self, "_on_dungeon_ready"))
		_on_dungeon_ready()
		
		print("PlayerPositionManager: Connected to dungeon generator")
	else:
		print("PlayerPositionManager: Warning - No dungeon generator found in the scene")

func _process(_delta):
	if player != null:
		update_player_room_position()

func _on_dungeon_ready():
	print("PlayerPositionManager: Dungeon ready signal received")
	spawn_player_in_first_room()

func spawn_player_in_first_room():
	if dungeon_generator == null or player == null:
		print("PlayerPositionManager: Cannot spawn player - missing dungeon or player")
		return
	
	# Get the first room (index 1)
	var first_room = null
	for room in dungeon_generator.rooms:
		if room["index"] == 1:
			first_room = room
			break
	
	if first_room != null:
		# Calculate the center position of the first room
		var room_pos = first_room["pixel_pos"]
		var room_size = first_room["pixel_size"]
		var center_pos = room_pos + (room_size / 2)
		
		# Move player to center of first room
		player.global_position = center_pos
		current_room = first_room
		current_room_index = 1
		
		print("PlayerPositionManager: Player spawned in first room at position ", center_pos)
		emit_signal("player_room_changed", null, current_room_index)
	else:
		print("PlayerPositionManager: First room not found")

func update_player_room_position():
	if player == null or dungeon_generator == null:
		return
	
	# Check which room contains the player
	for room in dungeon_generator.rooms:
		var room_instance = room["instance"]
		var area = room_instance.get_node_or_null("Area2D")
		
		if area != null and area.overlaps_body(player):
			# Player is in this room
			if current_room_index != room["index"]:
				var old_room_index = current_room_index
				current_room = room
				current_room_index = room["index"]
				
				# Emit signal about room change
				emit_signal("player_room_changed", old_room_index, current_room_index)
				print("PlayerPositionManager: Player moved to room ", current_room_index)
			
			# Room found, no need to check others
			return

func get_current_room():
	return current_room

func get_current_room_index():
	return current_room_index

func teleport_player_to_room(room_index):
	if player == null or dungeon_generator == null:
		return false
	
	# Find the target room
	var target_room = null
	for room in dungeon_generator.rooms:
		if room["index"] == room_index:
			target_room = room
			break
	
	if target_room != null:
		# Calculate the center position of the target room
		var room_pos = target_room["pixel_pos"]
		var room_size = target_room["pixel_size"]
		var center_pos = room_pos + (room_size / 2)
		
		# Move player to center of target room
		player.global_position = center_pos
		
		# Update current room tracking
		var old_room_index = current_room_index
		current_room = target_room
		current_room_index = room_index
		
		emit_signal("player_room_changed", old_room_index, current_room_index)
		return true
	
	return false
