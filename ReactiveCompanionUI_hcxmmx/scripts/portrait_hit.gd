extends Control

signal portrait_clicked
signal portrait_drag_started
signal portrait_dragged(delta: Vector2)
signal portrait_drag_finished

const FRONT_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/front.png")
const SIDE_ATLAS: Texture2D = preload("res://ReactiveCompanionUI_hcxmmx/images/chino/side.png")

var pose_name := "front"
var _front_image: Image
var _side_image: Image
var _dragging := false
var _last_drag_position := Vector2.ZERO


func _ready() -> void:
	_front_image = FRONT_ATLAS.get_image()
	_side_image = SIDE_ATLAS.get_image()


func _has_point(point: Vector2) -> bool:
	# Only painted pixels intercept the game while interaction is enabled.
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	var pixel := Vector2i(floori(point.x), floori(point.y))
	var image: Image
	if pose_name == "front":
		pixel -= Vector2i(38, 0)
		if pixel.x < 0 or pixel.x >= 230 or pixel.y < 0 or pixel.y >= 538:
			return false
		image = _front_image
	else:
		pixel -= Vector2i(0, 4)
		if pixel.x < 0 or pixel.x >= 306 or pixel.y < 0 or pixel.y >= 534:
			return false
		image = _side_image
	return image != null and image.get_pixelv(pixel).a > 0.15


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			portrait_clicked.emit()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_dragging = true
				_last_drag_position = event.global_position
				portrait_drag_started.emit()
			elif _dragging:
				_dragging = false
				portrait_drag_finished.emit()
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = event.global_position - _last_drag_position
		_last_drag_position = event.global_position
		if delta.length_squared() > 0.0:
			portrait_dragged.emit(delta)
		accept_event()
