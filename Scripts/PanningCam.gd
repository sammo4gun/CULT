extends Camera2D

const MIN_ZOOM: float = 0.1
const MAX_ZOOM: float = 5.0
const ZOOM_INCREMENT: float = 0.1

const ZOOM_RATE: float = 8.0

var _target_zoom: float = 1.0

func _ready():
	#set position to center of map
	position = Vector2(
		0, 
		32 + (get_parent().SIZE/2)*32)

func _physics_process(delta) -> void:
	zoom = lerp(zoom, _target_zoom * Vector2.ONE, ZOOM_RATE * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == BUTTON_MASK_MIDDLE:
			position -= event.relative * zoom
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				zoom_in()
			if event.button_index == BUTTON_WHEEL_DOWN:
				zoom_out()

func zoom_in():
	_target_zoom = max(_target_zoom - ZOOM_INCREMENT, MIN_ZOOM)
	set_physics_process(true)
	
func zoom_out():
	_target_zoom = min(_target_zoom + ZOOM_INCREMENT, MAX_ZOOM)
	set_physics_process(true)
	