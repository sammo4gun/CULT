extends Node2D

export var HEIGHT = 60
export var WIDTH = 40

onready var drawer = $Map

# statistics about the map
var _altitude = {}
var openSimplexNoise = OpenSimplexNoise.new()

# generated map visible features
var _mtype = {}
var _mheight = {}

onready var selector = $Selector

func _ready():
	randomize()
	_altitude = buildMap(100, 5)
	populateMap()
	drawer.map_ready(WIDTH, HEIGHT, _mtype, _mheight)

# Builds an empty map to render
func buildMap(per, oct):
	openSimplexNoise.seed = randi()
	openSimplexNoise.period = per
	openSimplexNoise.octaves = oct
	
	var map = {}
	
	for x in range(WIDTH):
		for y in range(HEIGHT):
			# set hidden values for tiles
			map[Vector2(x, y)] = 2*abs(openSimplexNoise.get_noise_2d(x,y))
	return map

func populateMap():
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var coord = Vector2(x, y)
			_mtype[coord] = 3
			_mheight[coord] = 0
			
			if _altitude[coord] > 0.12:
				_mtype[coord] = 0
			if _altitude[coord] > 0.6:
				_mtype[coord] = 1
				_mheight[coord] = 1
			if _altitude[coord] > 0.8:
				_mtype[coord] = 1
				_mheight[coord] = 2
func _on_tile_selected(tile):
	selector.setSelected(tile)
