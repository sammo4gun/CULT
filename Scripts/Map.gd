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

onready var ground = $"../YDrawer/Ground"
onready var hill = $"../YDrawer/Hill"
onready var mountain = $"../YDrawer/Mountain"
onready var towns = $"../Towns"
onready var world = get_parent()

onready var _layers = {0: ground, 1: hill, 2: mountain}

func map_init(w, h, types, heights, roads, buildings):
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
	drawMap()

# Change the type of terrain on a square
func terrain_update(tile: Vector2):
	var type = world._mtype[tile]
	if type == 5:
		_types[tile] = 23+rng.randi_range(0,9)
	else: 
		_types[tile] = type
	
	for lay in _layers:
		if _heights[tile] == lay:
			#redraw that tile on that layer
			_layers[lay].updateTerrain(tile, type)

# Change the type of road on a path, connect that road to adjacent 
# buildings/roads.
func road_update(path: Dictionary):
	var type
	_roads.append(path)
	for tile in path:
		_roads_dirs[tile] = [0, 0, 0, 0]
		type = path[tile]
	
	# Tiles for now must always be on the 0 layer, (_layers[0])
	for tile in path:
		var i = 0
		for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
			match type:
				1:
					if (tile + dif) in path or \
					   (world.is_road_tile(tile+dif) == 1):
						if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
							_roads_dirs[tile][i] = 1
							_layers[0].updateRoad(tile, _roads_dirs[tile], type)
							_roads_dirs[tile+dif][(i+2)%4] = 1
							_layers[0].updateRoad(tile+dif, _roads_dirs[tile+dif], type)
					elif towns.has_building(tile+dif):
						if towns.get_building(tile+dif).BUILDING_LAYER[type] and \
						   (not towns.map_get_building_connected(tile+dif) or \
						   towns.get_building(tile+dif).MULTI_ROAD[type]):
							building_update(tile+dif)
							_roads_dirs[tile][i] = 1
							_layers[0].updateRoad(tile, _roads_dirs[tile], type)
							#add entrance
				2:
					if (world.is_road_tile(tile+dif) == 2) and\
					   (towns.get_owner_obj(tile+dif) == towns.get_owner_obj(tile)):
							_roads_dirs[tile][i] = 1
							_layers[0].updateRoad(tile, _roads_dirs[tile], type)
							_roads_dirs[tile+dif][(i+2)%4] = 1
							_layers[0].updateRoad(tile+dif, _roads_dirs[tile+dif], type)
					elif towns.has_building(tile+dif):
						if (towns.get_building(tile+dif).BUILDING_LAYER[type]) and \
						   (towns.get_owner_obj(tile+dif) == towns.get_owner_obj(tile)) and \
						   (not towns.map_get_building_connected(tile+dif) or \
							towns.get_building(tile+dif).MULTI_ROAD[type]):
							_roads_dirs[tile][i] = 1
							_layers[0].updateRoad(tile, _roads_dirs[tile], type)
							towns.map_set_building_connected(tile+dif, tile)
			i += 1

func remove_road(tile: Vector2):
	var i = 0
	for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
		if _roads_dirs[tile][i] == 1 and world.is_road_tile(tile+dif):
			_roads_dirs[tile+dif][(i+2)%4] = 0
			_layers[0].updateRoad(tile+dif, _roads_dirs[tile+dif], world.is_road_tile(tile+dif))
		elif _roads_dirs[tile][i] == 1 and towns.has_building(tile+dif):
			towns.map_set_building_disconnected(tile+dif)
			full_building_update(tile+dif)
		i+=1

# Change the type of building on a square, connect that building to adjacent
# roads.
func building_update(tile: Vector2):
	var building = towns.get_building(tile)
	var TYPE = building.get_id()
	var LAYER = building.BUILDING_LAYER
	var MULTI = building.MULTI_ROAD
	
	_buildings[tile] = TYPE
	
	for lay in _layers:
		if _heights[tile] == lay:
			# CASE ONE: Simple house. Draw house, update roads
			var d = 0
			var i = 0
			if LAYER[1]:
				# Check for squares and make the connection. Connected = true, d=i
				# Connection check for a town square that the house belongs to
				for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
					if (tile + dif) in _buildings:
						if _buildings[(tile + dif)] == 3:
							if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
								towns.map_set_building_connected(tile, tile+dif)
								d=i
								if not MULTI[1]: 
									break
					i += 1
				
				# Check for connected main roads if not connected.
				i = 0
				if (MULTI[1]) or (not towns.map_get_building_connected(tile)):
					for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
						if world.is_road_tile(tile+dif) == 1:
							if towns.check_ownership(tile+dif) == towns.check_ownership(tile):
								_roads_dirs[tile + dif] = modify_road(_roads_dirs[tile + dif], i)
								towns.map_set_building_connected(tile, tile+dif)
								d=i
								_layers[lay].updateRoad(tile+dif, _roads_dirs[tile+dif], 1)
								if not MULTI[1]: 
									break
						i += 1
			
			if LAYER[2]:
				i = 0
				# Finally, connected personal roads, only for show.
				if (MULTI[2]) or (not towns.map_get_building_connected(tile)):
					for dif in [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]:
						if world.is_road_tile(tile+dif) == 2:
							if towns.get_owner_obj(tile+dif) == towns.get_owner_obj(tile):
								_roads_dirs[tile + dif] = modify_road(_roads_dirs[tile + dif], i)
								_layers[lay].updateRoad(tile+dif, _roads_dirs[tile+dif], 2)
								towns.map_set_building_connected(tile, tile+dif)
								# UPDATE ROAD ON THIS TILE WITH OPPOSING DIRECTION
								if not MULTI[2]: 
									break
						i += 1
			
			# ACTUAL DRAWING
			if building.is_proper(): 
				building.set_main_dir(d)
			
			# Change this to just pass the direction?
			_layers[lay].updateBuilding(tile, building)

func full_building_update(tile: Vector2):
	var all_tiles = towns.get_full_building(tile)
	for tile in all_tiles:
		building_update(tile)

func remove_building(tile: Vector2):
	var i = 0
	for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
		if world.is_road_tile(tile+dif):
			_roads_dirs[tile+dif][(i+2)%4] = 0
			_layers[0].updateRoad(tile+dif, _roads_dirs[tile+dif], world.is_road_tile(tile+dif))
		i+=1

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				emit_signal("selected_tile", setSelected(get_global_mouse_position()))

func get_pos(location):
	var pos = ground.map_to_world(location)
	pos.y += 48
	return pos

# converts the value "5" to one of the correct tree values
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

func modify_road(dirs, i):
	if dirs[(i+3)%4] == 0:
		dirs[(i+3)%4] = 1
	return dirs

# This returns true if there is a road at position pos with a connection in
# direction i
func road_has_dir(pos, i):
	if pos in _roads_dirs and world.is_road_tile(pos):
		if _roads_dirs[pos][i] == 1:
			return true
	return false

func refresh_building(location, building):
	ground.updateBuilding(location, building)
