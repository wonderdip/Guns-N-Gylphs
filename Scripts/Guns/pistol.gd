extends Gun

var dead_zone = 5.0  # pixels

func update_art():
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position

	# Rotate the pivot toward the mouse
	var angle = (mouse_pos - pivot_pos).angle()
	pivot.global_rotation = angle

	# Only flip if the mouse is clearly on one side
	var delta_x = mouse_pos.x - pivot_pos.x
	if delta_x < -dead_zone:
		pivot.scale.y = -1
	elif delta_x > dead_zone:
		pivot.scale.y = 1





