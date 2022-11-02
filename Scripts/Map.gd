extends Node2D

# The visible map. It loads data from the WORLD script, splits it into types,
# and then sends it to the appropriate TileMaps where it gets put onto the 
# screen.

signal selected_tile

#types = 0:grass, 1:dirt, 2: highlighted, 3: water, 4:forest
var _types = {}
#heights = 0:ground, 1:hill, 2:mountain
var _heights = {}

var _roads = []
var _roads_dirs = {}

var _buildings = {}

var _layered_types = {}

var HEIGHT
var WIDTH

var rng = RandomNumberGenerator.new()

var ROADS_DICT = {
	[0,0,0,0]: 8, #should never happen
	[1,0,0,0]: 8, #8
	[0,1,0,0]: 6, #6
	[0,0,1,0]: 8, #8
	[0,0,0,1]: 6, #6
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

var SQUARE_DICT = {
	[0,1,1,0]: 39,
	[1,1,0,0]: 35,
	[1,1,1,0]: 36,
	[1,0,0,1]: 38,
	[0,1,1,1]: 34,
	[0,0,1,1]: 40,
	[1,1,1,1]: 37,
	[1,0,1,1]: 41,
	[1,1,0,1]: 33
	}

var FARM_DICT = {
	[0,1,1,0]: 73,
	[1,1,0,0]: 69,
	[1,1,1,0]: 70,
	[1,0,0,1]: 72,
	[0,1,1,1]: 68,
	[0,0,1,1]: 74,
	[1,1,1,1]: 71,
	[1,0,1,1]: 66,
	[1,1,0,1]: 67
	}

onready var ground = $"../YDrawer/Ground"
onready var hill = $"../YDrawer/Hill"
onready var mountain = $"../YDrawer/Mountain"
onready var towns = $"../Towns"

onready var _layers = {0: ground, 1: hill, 2: mountain}

func map_ready(w, h, types, heights, roads, buildings):
	WIDTH = w
	HEIGHT = h
	_heights = heights
	_types = {}
	for tile in types:
		_types[tile] = types[tile]
	_roads = []
	for path in roads:
		_roads.append(path)
		for tile in path:
			_roads_dirs[tile] = []
	_buildings = {}
	for tile in buildings:
		_buildings[tile] = buildings[tile]
	randomTrees()
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
	for path in _roads:
		for tile in path:
			var dirs = [0,0,0,0]
			var i = 0
			for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
				if (tile + dif) in path or \
				   (get_road_tile(tile+dif) == 1 and path[tile] == 1):
					if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
						dirs[i] = 1
				elif get_road_tile(tile+dif) == 2 and path[tile] == 2 and\
					 towns.get_owner_obj(tile+dif) == towns.get_owner_obj(tile):
						dirs[i] = 1
				i += 1
			_roads_dirs[tile] = dirs

func get_pos(location):
	var pos = ground.map_to_world(location)
	pos.y += 48
	return pos

var BUILDING_LAYERS = {
	1: [1,2], 
	2: [1,2], 
	3: [1  ], 
	4: [1,2], 
	5: [  2]
}

var MULTI_ROADS = {
	1: {1: false, 2: true },
	2: {1: true,  2: true }, 
	3: {1: true,  2: false}, 
	4: {1: false, 2: true },
	5: {1: false, 2: false}
}

func constructBuildings():
	for tile in _buildings:
		if _buildings[tile]:
			var d = 0
			var i = 0
			
			if 1 in BUILDING_LAYERS[_buildings[tile]]:
				# Set road type of adjacent roads
				# Check for squares and make the connection. Connected = true, d=i
				for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
					if (tile + dif) in _buildings:
						if _buildings[(tile + dif)] == 3:
							if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
								towns.map_set_building_connected(tile)
								d=i
								if not MULTI_ROADS[_buildings[tile]][1]: 
									break
					i += 1
				
				# Check for connected main roads if not connected.
				i = 0
				if (MULTI_ROADS[_buildings[tile]][1]) or (not towns.map_get_building_connected(tile)):
					for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
						if get_road_tile(tile+dif) == 1:
							if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
								_roads_dirs[tile + dif] = modify_road(_roads_dirs[tile + dif], i)
								towns.map_set_building_connected(tile)
								d=i
								if not MULTI_ROADS[_buildings[tile]][1]: 
									break
						i += 1
			
			if 2 in BUILDING_LAYERS[_buildings[tile]]:
				i = 0
				# Finally, connected personal roads, only for show.
				if (MULTI_ROADS[_buildings[tile]][2]) or (not towns.map_get_building_connected(tile)):
					for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
						if get_road_tile(tile+dif) == 2:
							if towns.get_owner_obj(tile+dif) == towns.get_owner_obj(tile):
								_roads_dirs[tile + dif] = modify_road(_roads_dirs[tile + dif], i)
								towns.map_set_building_connected(tile)
								if not MULTI_ROADS[_buildings[tile]][2]: 
									break
						i += 1
			
			# TODO: Set building type depending on whether or not
			# there are adjacent roads.
			match _buildings[tile]:
				1:
					towns.get_building(tile).set_sprite(RESIDENTIAL_TILES[d])
					_layered_types[0][tile] = towns.get_building(tile).get_sprite()
				2:
					towns.get_building(tile).set_sprite(CENTER_TILES[d])
					_layered_types[0][tile] = towns.get_building(tile).get_sprite()
				3:
					_layered_types[0][tile] = square_tile(tile, 3, SQUARE_DICT)
				4:
					towns.get_building(tile).set_sprite(RESIDENTIAL_TILES[d])
					_layered_types[0][tile] = towns.get_building(tile).get_sprite()
				5:
					_layered_types[0][tile] = square_tile(tile, 5, FARM_DICT)

var RESIDENTIAL_TILES = {
	2: 19,
	3: 19,
	0: 16 + (rng.randi_range(0,1)*2),
	1: 17
}

var CENTER_TILES = {
	2: 20,
	3: 20,
	0: 22,
	1: 21
}

func square_tile(tile, type, dict):
	var i = 0
	var dirs = [0,0,0,0]
	for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
		if (tile + dif) in _buildings:
			if _buildings[(tile + dif)] == type:
				if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
					dirs[i] = 1
		i += 1
	if not dirs in dict:
		return dict[[1,1,0,0]]
	return dict[dirs]

func drawRoads():
	for path in _roads:
		for tile in path:
			if path[tile] == 1:
				_layered_types[0][tile] = ROADS_DICT[_roads_dirs[tile]]
			if path[tile] == 2:
				_layered_types[0][tile] = ROADS_DICT[_roads_dirs[tile]]

# converts the value "4" to one of the correct tree values
func randomTrees():
	for tile in _types:
		if _types[tile] == 5:
			_types[tile] = 23+rng.randi_range(0,9)

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

func get_road_tile(tile):
	for path in _roads:
		if tile in path:
			return path[tile]
	return 0

func modify_road(dirs, i):
	if dirs[(i+3)%4] == 0:
		dirs[(i+3)%4] = 1
	return dirs

func update_building(location, value):
	ground.set_cell(location.x, location.y, value)
