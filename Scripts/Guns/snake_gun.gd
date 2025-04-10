extends Gun

func update_art():
	var angle = (get_global_mouse_position() - sprite_2d.global_position).angle()
	var angle_degrees = rad_to_deg(angle)
	angle_degrees = fposmod(angle_degrees, 360)
	
	# Map angle to frame index (0-21)
	var frame_count = 22
	var frame_index = int((angle_degrees / 360.0) * frame_count) % frame_count
	sprite_2d.frame = frame_index

	var animation_length = 2.2  # Total duration in seconds
	var time_position = (frame_index / float(frame_count)) * animation_length
	
	if Input.is_action_just_pressed("shoot"):
		
		%AnimationPlayer.play("BulletPoint_Mover")
		%AnimationPlayer.seek(time_position, false)
		shoot()
