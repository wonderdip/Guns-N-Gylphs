extends Node2D

func ready():
	spawn_enemies()
	
func spawn_enemies():
	var mummy = preload("res://Scenes/Enemies/Mummy.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	mummy.global_position = %PathFollow2D.global_position
	add_child(mummy)

func _on_spawn_timer_timeout():
	spawn_enemies()
	
