class_name PlayerCam extends SpringArm3D

var target: Node3D = null
@export
var offset := Vector3(0,1.2,0)
@export var _yaw_range := Vector2(-50, 60)
@onready var cam: Camera3D = $Camera3D


func rotate_with_delta(delta: Vector2) -> void:
	var angles := rotation_degrees + Vector3( - delta.y, -delta.x, 0)
	var y_range := _yaw_range
	angles.x = clamp(angles.x, y_range.x, y_range.y)
	rotation_degrees = angles
	
func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseMotion
	if mouse_event != null:
		var delta := mouse_event.relative * 0.3
		rotate_with_delta(delta)


func _physics_process(_delta: float) -> void:
	if not target: return
	global_position = target.global_position + offset
