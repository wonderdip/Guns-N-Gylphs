extends Gun

func _process(delta):
	if Input.is_action_just_pressed("reload"):
		reload()
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		CameraShakeManager.cam_shake(5, 2, 0.2)
		
	# Update shoot state
	can_shoot = not player.dodging and not reloading
	
	if can_shoot:
		call_deferred("update_art")
	else:
		pivot.rotation += deg_to_rad(720) * delta  # spin!

func update_art():
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position

	# Rotate the pivot toward the mouse
	var angle = (mouse_pos - pivot_pos).angle()
	pivot.global_rotation = angle

	# Flip sprite
	var delta_x = mouse_pos.x - pivot_pos.x
	if delta_x < -dead_zone:
		pivot.scale.y = -1
	elif delta_x > dead_zone:
		pivot.scale.y = 1



