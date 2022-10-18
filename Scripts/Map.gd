extends Node2D

# The visible map. It loads data from the WORLD script, splits it into types,
# and then sends it to the appropriate TileMaps where it gets put onto the 
# screen.

signal selected_tile

#types = 0:grass, 1:dirt, 2: highlighted, 3: water, 4:forest
var _types = []
#heights = 0:ground, 1:hill, 2:mountain
var _heights = []

var _layered_types = {}

var HEIGHT
var WIDTH

onready var ground = $Ground
onready var hill = $"../YDrawer/Hill"
onready var mountain = $"../YDrawer/Mountain"

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
				emit_signal("selected_tile", setSelected(get_global_mouse_position()))

# Splits maps into different layers as based on the "layers" var set
# above.
func splitMap():
	for lay in _layers:
		_layered_types[lay] = {}
		for x in range(WIDTH):
			for y in range(HEIGHT):
				var coord = Vector2(x,y)
				if _heights[coord] == lay:
					_layered_types[lay][coord] = _types[coord]
				else: _layered_types[lay][coord] = -1

func drawMap():
	for lay in _layers:
		_layers[lay].drawMap(WIDTH, HEIGHT, _layered_types[lay])

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
		if selected_pos in _layered_types[(num_layers-1-i)]:
			if _layered_types[(num_layers-1-i)][selected_pos] != -1:
				#set selected tile to these coordinates
				return [selected_pos, (num_layers-1-i)]
		pos.y += 56 - (16 * (num_layers-1-i))
	return null
