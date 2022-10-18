extends Node2D

# The visible map. It loads data from the WORLD script, splits it into types,
# and then sends it to the appropriate TileMaps where it gets put onto the 
# screen.

signal selected_tile

#types = 0:grass, 1:dirt, 2: highlighted, 3: water, 4:forest
var _types = {}
#heights = 0:ground, 1:hill, 2:mountain
var _heights = {}

var _roads = {}

var _buildings = {}

var _layered_types = {}

var HEIGHT
var WIDTH

var rng = RandomNumberGenerator.new()

var ROADS_DICT = {
	[1,0,0,0]: 8,
	[0,1,0,0]: 6,
	[0,0,1,0]: 8,
	[0,0,0,1]: 6,
	[0,1,1,0]: 5,
	[0,1,0,1]: 6,
	[1,1,0,0]: 7,
	[1,0,1,0]: 8,
	[1,1,1,0]: 9,
	[1,0,0,1]: 10,
	[0,1,1,1]: 11,
	[0,0,1,1]: 12,
	[1,1,1,1]: 13,
	[1,0,1,1]: 14,
	[1,1,0,1]: 15
	}

onready var ground = $"../YDrawer/Ground"
onready var hill = $"../YDrawer/Hill"
onready var mountain = $"../YDrawer/Mountain"

onready var _layers = {0: ground, 1: hill, 2: mountain}

func map_ready(w, h, types, heights, roads, buildings):
	WIDTH = w
	HEIGHT = h
	_types = types
	_heights = heights
	_roads = roads
	_buildings = buildings
	splitMap()
	constructRoads()
	constructBuildings()
	drawRoads()
	drawMap()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				emit_signal("selected_tile", setSelected(get_global_mouse_position()))

func constructRoads():
	for tile in _roads:
		if _roads[tile]:
			var dirs = [0,0,0,0]
			var i = 0
			for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
				if (tile + dif) in _roads:
					if _roads[tile + dif]: 
						dirs[i] = 1
				i += 1
			_roads[tile] = dirs

func constructBuildings():
	for tile in _buildings:
		if _buildings[tile]:
			# Set road type of adjacent roads
			var i = 0
			var d = 0
			for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
				if (tile + dif) in _roads:
					if _roads[tile + dif]:
						_roads[tile + dif] = modify_road(_roads[tile + dif], i)
						if not _buildings[tile] == 2: 
							break
						else: d = i
				i += 1
			# TODO: Set building type depending on whether or not
			# there are adjacent roads.
			if _buildings[tile] == 1:
				if i == 2 or i == 3:
					_layered_types[0][tile] = 19
				if i == 0:
					_layered_types[0][tile] = 16 + (rng.randi_range(0,1)*2)
				if i == 1:
					_layered_types[0][tile] = 17
			else:
				if d == 2 or d == 3:
					_layered_types[0][tile] = 20
				if d == 0:
					_layered_types[0][tile] = 22
				if d == 1:
					_layered_types[0][tile] = 21

func drawRoads():
	for tile in _roads:
		if _roads[tile]:
			_layered_types[0][tile] = ROADS_DICT[_roads[tile]]

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

func modify_road(dirs, i):
	if dirs[(i+3)%4] == 0:
		dirs[(i+3)%4] = 1
	return dirs
