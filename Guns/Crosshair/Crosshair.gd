extends CanvasLayer


func _process(_delta):
	$Sprite2D.global_position = get_window().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

