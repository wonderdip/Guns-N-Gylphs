extends Node2D

var travelled_distance = 0
@export var Speed = 1000
@export var max_distance = 1200
var damage = 0 #dont change the damage of the gun gets passed on to it

# Assuming Area2D is a child node of Node2D
@onready var area = $Area2D
@onready var bullet_sprite = $BulletSprite

func _ready():
	area.global_position = global_position
	hide_sprite_temporarily()

func hide_sprite_temporarily():
	# Hide sprite immediately when the bullet is created
	bullet_sprite.hide()
	await get_tree().create_timer(0.025).timeout
	bullet_sprite.show()
	
	
func _physics_process(delta):
	
	var direction = Vector2.RIGHT.rotated(rotation)
	
	# Move the Node2D (root) position
	global_position += direction * Speed * delta
	
	# Make sure the Area2D follows the root Node2D's position
	area.global_position = global_position
	area.global_rotation = global_rotation
	travelled_distance += Speed * delta
	if travelled_distance > max_distance:
		queue_free()


func _on_area_2d_body_entered(body):
	if body is Enemy:
		body.take_damage(damage)
		queue_free()
	if body is TileMap:
		queue_free()


