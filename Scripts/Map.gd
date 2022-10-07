extends Node2D

# The visible map. It loads data from the WORLD script, splits it into types,
# and then sends it to the appropriate TileMaps where it gets put onto the 
# screen.

signal selected_tile

var _types = []
var _heights = []

var _layered_types = {}

var HEIGHT
var WIDTH

onready var ground = $Ground
onready var hill = $Hill
onready var mountain = $Mountain

onready var selector = get_node("/root/World/Selector")

onready var _layers = {0: ground, 1: hill, 2: mountain}

func map_ready(w, h, types, heights):
	WIDTH = w
	HEIGHT = h
	_types = types
	_heights = heights
	splitMap()
	drawMap()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				var n_selec = setSelected(get_global_mouse_position())
				if n_selec:
					emit_signal("selected_tile", n_selec)

# Splits maps into different layers as based on the "layers" var set
# above.
func splitMap():
	for area in _layers:
		_layered_types[area] = {}
		for x in range(WIDTH):
			for y in range(HEIGHT):
				var coord = Vector2(x,y)
				if _heights[coord] == area:
					_layered_types[area][coord] = _types[coord]
				else: _layered_types[area][coord] = -1

func drawMap():
	for area in _layers:
		_layers[area].drawMap(WIDTH, HEIGHT, _layered_types[area])

# returns the selected square and the layer it is on.
# formula for correct location is world_to_map(), then
# y -= 48 + 16*level
func setSelected(pos):
	var num_layers = len(_layers)
	var selected_pos
	# starting with the top layer, cycle through. The first starts at
	# -56 + 20*num layers, then goes down 
	for i in range(num_layers):
		pos.y -= 56 - (16 * (num_layers-1-i))
		selected_pos = ground.world_to_map(pos)
		if _layered_types[(num_layers-1-i)][selected_pos] != -1:
			#set selected tile to these coordinates
			return [selected_pos, (num_layers-1-i)]
		pos.y += 56 - (16 * (num_layers-1-i))
