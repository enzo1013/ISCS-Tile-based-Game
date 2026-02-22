extends AnimatableBody2D

@export var speed: float = 100.0
@export var distance: float = 200.0
@export var direction: Vector2 = Vector2.RIGHT

var start_position: Vector2
var moving_forward: bool = true


func _ready() -> void:
	start_position = global_position
	direction = direction.normalized()


func _physics_process(delta: float) -> void:
	var target: Vector2

	if moving_forward:
		target = start_position + direction * distance
	else:
		target = start_position

	var displacement = target - global_position
	var move_step = speed * delta

	if displacement.length() <= move_step:
		global_position = target
		moving_forward = not moving_forward
	else:
		global_position += displacement.normalized() * move_step
