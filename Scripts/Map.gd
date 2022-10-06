extends Node2D

# The visible map. It loads data from the WORLD script, splits it into types,
# and then sends it to the appropriate TileMaps where it gets put onto the 
# screen.

var _visible_map = []
var _layered_map = []

onready var ground = $Ground
onready var hill = $Hill

onready var _layers = {0: ground, 1: hill}

func map_ready(map):
	_visible_map = map
	splitMap()
	drawMap()

# Splits maps into different layers as based on the "layers" var set
# above.
func splitMap():
	var sz = len(_visible_map)
	for area in _layers:
		_layered_map.append([])
		
		for i in range(sz):
			_layered_map[area].append([])
			for j in range(sz):
				if _visible_map[i][j].layer == area:
					_layered_map[area][i].append(_visible_map[i][j].type)
				else: _layered_map[area][i].append(-1)

func drawMap():
	var n = 0
	for area in _layers:
		_layers[area].drawMap(_layered_map[n])
		n+=1
