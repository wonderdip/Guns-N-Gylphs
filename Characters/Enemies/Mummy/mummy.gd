extends Enemy  # Inherits from Enemy.gd for base stats

func move(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * Speed  # Regular movement velocity
	
	move_and_slide()  # Apply the movement and handle collision detection

	# Play animation
	animated_sprite.play("Walk")

	# Flip sprite based on movement direction
	animated_sprite.flip_h = direction.x < 0
	animated_sprite.modulate = Color(1, 1, 1, 1)
	
func damaged():
	animated_sprite.modulate = Color(0.8, 0, 0, 1)

