extends Resource
class_name GunResource

# Basic gun properties
@export var gun_name: String = "Default Gun"
@export var gun_scene: PackedScene
@export var gun_icon: Texture2D

# Gun stats (matching your Gun class properties)
@export var damage: int = 1
@export var magazine_size: int = 10
@export var bullet_count: int = 1
@export var reload_time: float = 1.0
@export_range(0, 2) var hold_type: int = 1
@export_range(0, 360) var shot_radius: float = 0
@export_range(0, 10) var shot_delay: float = 0.1

# Additional properties
@export var bullet: PackedScene
@export var description: String = "A basic gun"
@export var unlocked: bool = true  # Whether this gun is available to the player
