extends Resource
class_name RoomType

@export var weight: float = 1.0
@export var scene: PackedScene
@export var is_special: bool = false
@export var max_instances: int = -1  # -1 means unlimited

