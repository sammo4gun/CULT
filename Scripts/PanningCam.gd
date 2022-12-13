extends Camera2D

onready var ground_layer = get_node("/root/World/YDrawer/Ground")

const MIN_ZOOM: float = 0.6
const MAX_ZOOM: float = 5.0
const ZOOM_INCREMENT: float = 0.1

const ZOOM_RATE: float = 8.0

var _target_zoom: float = 3.0

# SCREEN SHAKE VARIABLES
var NOISE_SHAKE_SPEED = 30.0
var NOISE_SHAKE_STRENGTH = 60.0
var SHAKE_DECAY_RATE = 5.0
var noise = OpenSimplexNoise.new()
var noise_i = 0.0
var shake_strength = 0.0

var screen_busy = false # is true when there is a "cutscene"

func _ready():
	#set position to center of map
	position = ground_layer.map_to_world(Vector2(
		get_node("/root/World").WIDTH/2,
		get_node("/root/World").HEIGHT/2))
	position.y += 32
	
	noise.seed = get_parent().rng.randi()
	noise.period = 2

func _physics_process(delta):
	zoom = lerp(zoom, _target_zoom * Vector2.ONE, ZOOM_RATE * delta)
	
	shake_strength = lerp(shake_strength, 0, SHAKE_DECAY_RATE * delta)
	offset = get_noise_offset(delta)

func shake_screen():
	shake_strength = NOISE_SHAKE_STRENGTH

func fade_to_tile(_tile):
	# Turn black
	# jump to tile
	pass

func jump_to_tile(tile):
	position = ground_layer.map_to_world(tile)
	position.y += 32
	zoom = 1.5 * Vector2.ONE
	_target_zoom = 0.7
	shake_screen()

func get_noise_offset(delta):
	noise_i += delta * NOISE_SHAKE_SPEED
	
	return Vector2(
		noise.get_noise_2d(1, noise_i)   * shake_strength,
		noise.get_noise_2d(100, noise_i) * shake_strength
	)

func _unhandled_input(event: InputEvent):
	if not screen_busy:
		if event is InputEventMouseMotion:
			if event.button_mask in [BUTTON_LEFT, BUTTON_MASK_MIDDLE]:
				position -= event.relative * zoom
		
		if event is InputEventMouseButton:
			if event.is_pressed():
				if event.button_index == BUTTON_WHEEL_UP:
					zoom_in()
				if event.button_index == BUTTON_WHEEL_DOWN:
					zoom_out()
		
		if event is InputEventKey:
			if event.pressed and event.scancode == KEY_O:
				jump_to_tile(Vector2(50,50))

func zoom_in():
	_target_zoom = max(_target_zoom - ZOOM_INCREMENT, MIN_ZOOM)
	set_physics_process(true)

func zoom_out():
	_target_zoom = min(_target_zoom + ZOOM_INCREMENT, MAX_ZOOM)
	set_physics_process(true)
