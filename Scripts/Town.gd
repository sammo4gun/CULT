extends Node2D

signal construct_roads
signal construct_building
signal destroy_roads

#Generation Variables
export var NUM_RESIDENTIAL = 5
export var NUM_STORES = 3
export var MAX_SQUARE_SIZE = 4

export var CHANCE_BY_SQUARE = 0.7
export var MAX_PATH_DIST = 30
export var SDEV_RESIDENTIAL = 20
export var SDEV_CENTER = 5
export var EDGE_DIST = 10
export var MAX_BUILD_TIME = 10

var Residence = preload("res://Scenes/Buildings/Residence.tscn")
var Farm = preload("res://Scenes/Buildings/Farm.tscn")
var Center = preload("res://Scenes/Buildings/Center.tscn")
var Square = preload("res://Scenes/Buildings/Square.tscn")
var Store = preload("res://Scenes/Buildings/Store.tscn")

var TYPE_DICT={
	"residence": Residence,
	"farm": Farm,
	"center": Center,
	"square": Square,
	"store": Store
}

var rng = RandomNumberGenerator.new()
var map_heights
var map_types
var width
var height
var town_name

#Storing variables

var _center

var _owners = {}
var _mroads = {} #maps map locations to road types
# 1 = normal road
# 2 = "personal" road or dirt path
var _mbuildings = {} #maps map locations to buildings
var unique_buildings = []

#Utility
var drawer
var pathfinder
var world
var name_generator
var population

func _hour_update(time):
	for building in unique_buildings:
		building._hour_update(time)

func set_parents(dr, pf, wrld, nmg, pop):
	drawer = dr
	pathfinder = pf
	world = wrld
	name_generator = nmg
	population = pop

func build_town(w, h, mtypes, mheights):
	width = w
	height = h
	map_types = mtypes
	map_heights = mheights
	_center = pick_center(w,h)
	while true:
		town_name = name_generator.town()
		if not world.towns.town_exists(town_name):
			break
	
	var current_location
	
	# build town square
	construct_multi_building(_center, \
							 SDEV_CENTER/2, \
							 'square', \
							 true, \
							 ['road1', 'square'], \
							 1, \
							 true, \
							 MAX_SQUARE_SIZE,
							 self)
	
	# build town center
	current_location = construct_building("center", get_town_square_loc()[0], SDEV_CENTER, ['road1', 'square'], 1)
	
	create_resident(population, self, _mbuildings[current_location])

	
	# build store buildings
	
	for _i in range(NUM_STORES):
		current_location = construct_building("store", get_town_square_loc()[0], SDEV_CENTER/2, ['road1', 'square'], 1) 
		if current_location == null:
			print("FAILED TO BUILD")
			break
		create_resident(population, self, _mbuildings[current_location])
	
	# build residential buildings
	
	for _i in range(NUM_RESIDENTIAL):
		current_location = construct_building("residence", _center, SDEV_RESIDENTIAL, ['road1', 'square'], 1)
		if current_location == null:
			print("FAILED TO BUILD")
			break
		create_resident(population, self, _mbuildings[current_location])
	
	clean_roads()

func build_farm(person, nr):
	for _i in nr:
		var farmers_house = person.house.location[0]
		var new_farm = construct_multi_building( \
					   person.house.location[0], \
					   SDEV_CENTER/2, \
					   'farm', \
					   false, \
					   [farmers_house], \
					   2, \
					   true,
					   5,
					   person)
		if new_farm:
			person.add_property(new_farm)
			person.set_work()

func pick_center(w, h):
	var c
	while true:
		rng.randomize()
		var x = EDGE_DIST + rng.randi() % (w-(2*EDGE_DIST))
		var y = EDGE_DIST + rng.randi() % (h-(2*EDGE_DIST))
		c = Vector2(x, y)
		if map_types[c] != 3 and map_heights[c] == 0:
			return c

func get_nearest_town_square(loc):
	var dist = 9999
	var ths = get_town_square_loc()
	var th
	var cdist
	if ths == null:
		return [null, dist]
	for square_tile in ths:
		cdist = loc.distance_to(square_tile)
		if cdist < dist:
			th = square_tile
			dist = cdist
	return [th, dist]

func get_nearest_road(loc, types):
	#var dist = th.distance_to(loc)
	var dist = 999999
	var cdist
	var th = null
	for tile in _mroads:
		if _mroads[tile] in types:
			cdist = loc.distance_to(tile)
			if cdist < dist:
				th = tile
				dist = cdist
	return [th, dist] 

func get_nearest_building_path(loc, v):
	var closest_dist = loc.distance_to(v)
	var closest_tile = v
	for tile in _mroads:
		if _mroads[tile] == 2:
			if v in get_connected_squares(tile, _mroads, 2):
				if closest_dist > tile.distance_to(loc):
					closest_tile = tile
	return closest_tile

func get_nearest(loc, ls):
	var closest_distance = 999999
	var closest_tile = null
	var cur
	for v in ls:
		if typeof(v) == 5: #if it is a vector2 (i.e. location)
			if v in _mbuildings:
				closest_tile = get_nearest_building_path(loc, v)
			else: closest_tile = v
			closest_distance = loc.distance_to(v)
	if "square" in ls:
		cur = get_nearest_town_square(loc)
		if cur[1] < closest_distance:
			closest_distance = cur[1]
			closest_tile = cur[0]
	if "road1" in ls:
		cur = get_nearest_road(loc, [1])
		if cur[1] < closest_distance:
			closest_distance = cur[1]
			closest_tile = cur[0]
	if "road2" in ls:
		cur = get_nearest_road(loc, [2])
		if cur[1] < closest_distance:
			closest_distance = cur[1]
			closest_tile = cur[0]
	return closest_tile

func canwalk_to(loc, target, roads, type):
	return pathfinder.walkRoadPath(loc, target, world._mbuildings, roads, type, true)
	
var BUILD_TO_ROAD = {
	"residence": [1,2],
	"center": [1,2],
	"square": [1],
	"store": [1,2],
	"farm": [2]
}

func get_connected_buildings(loc, roads, road_type, owner_only = false):
	var connections = 0
	var done_buildings = []
	if not loc in _mbuildings:
		if not loc in roads: return 0
		elif not roads[loc] in road_type: return 0
	for place in _mbuildings:
		if not owner_only or get_tile_owner(loc) == get_tile_owner(place):
			for type in road_type:
				if type in BUILD_TO_ROAD[_mbuildings[place].type]:
					if canwalk_to(loc, [place], roads, road_type):
						if not _mbuildings[place] in done_buildings:
							done_buildings.append(_mbuildings[place])
							connections += 1
	return connections

func get_connected_squares(loc, roads, road_type, owner_only = false):
	var all_connected = [loc]
	var open = [loc]
	var closed = []
	var current
	while len(open) > 0:
		current = open[0]
		for dif in [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]:
			if (current + dif) in roads and not (current+dif) in closed:
				if roads[current+dif] == road_type:
					if not owner_only or get_tile_owner(current) == get_tile_owner(current+dif):
						all_connected.append(current+dif)
						open.append(current+dif)
			closed.append(current)
			open.erase(current)
	return all_connected

func clean_roads():
	var all_roads_erased = []
	for type in [1,2]:
		var roads_to_go = []
		var temp_roads = {}
		for rd in _mroads:
			if _mroads[rd] == type:
				temp_roads[rd] = _mroads[rd]
				roads_to_go.append(rd)
		#var i = 0
		while len(roads_to_go) > 0:
			var building_connections = get_connected_buildings(roads_to_go[0], _mroads, [type])
			var square_connections = get_connected_squares(roads_to_go[0], _mroads, type)
			for square in square_connections:
				roads_to_go.erase(square)
			for rd in square_connections:
				if rd in _mroads:
					temp_roads.erase(rd)
					if not get_connected_buildings(square_connections[0], temp_roads, [type]) < building_connections:
						if _mroads[rd] == type and not rd in _mbuildings: 
							all_roads_erased.append(rd)
							emit_signal("destroy_roads", [rd])
							_mroads.erase(rd)
						else: temp_roads[rd] = _mroads[rd]
					else: temp_roads[rd] = _mroads[rd]
	
	var temp_roads = {}
	for rd in _mroads:
		if _mroads[rd] == 2:
			temp_roads[rd] = _mroads[rd]
	#now clean farms
	var done = []
	for loc in _mbuildings:
		if _mbuildings[loc].type in ["residence", "center", "store"] and \
		   not _mbuildings[loc] in done:
			var building_connections = get_connected_buildings(loc, _mroads, [2], true)
			var square_connections = get_connected_squares(loc, _mroads, 2, true)
			for tile in square_connections:
				if _mroads.get(tile, 0) == 2:
					temp_roads.erase(tile)
					if not get_connected_buildings(loc, temp_roads, [2], 'farm') < building_connections:
						if not tile in _mbuildings: 
							all_roads_erased.append(tile)
							emit_signal("destroy_roads", [tile])
							_mroads.erase(tile)
						else: temp_roads[tile] = _mroads[tile]
					else: temp_roads[tile] = _mroads[tile]
		
	
	return all_roads_erased

func canpath_to(loc, target, type):
	if target != null:
		return pathfinder.findRoadPath(loc, target, self, world._mbuildings, type, world._mroads)
	return [loc]

func canbuild(loc, check_adj):
	#check its within the map & is buildable
	if loc.x >= 0 and loc.x < width and loc.y >= 0  and loc.y < height \
		and not loc in _mbuildings \
		and world._mbuildings[loc] == 0 \
		and map_heights[loc] == 0 \
		and map_types[loc] != 3 \
		and not loc in _mroads \
		and not world.is_road_tile(loc):
			if not check_adj: return true
			else: 
				for dif in [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]:
					if not canbuild(loc+dif, false):
						return false
				return true
	return false

func get_town_hall_loc():
	for b in _mbuildings:
		if _mbuildings[b].is_type("center"):
			return _mbuildings[b].location[0]
	return null

func get_town_square_loc():
	for b in _mbuildings:
		if _mbuildings[b].is_type("square"):
			return _mbuildings[b].location
	return null

#return how many adjacent tiles are available
func get_adjacents(tiles):
	var adjs = []
	if tiles == null:
		return 0
	for tile in tiles:
		for dif in [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]:
			if (tile+dif).x >= 0 and (tile+dif).x < width and (tile+dif).y >=0 and (tile+dif).y <height:
				if not (tile+dif) in _mbuildings \
				   and map_heights[(tile+dif)] == 0 \
				   and map_types[(tile+dif)] != 3 :
					adjs.append(tile+dif)
	return adjs

func get_max_adjacents(tiles):
	var adjs = []
	if tiles == null:
		return 0
	for tile in tiles:
		for dif in [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]:
			if (tile+dif).x >= 0 and (tile+dif).x < width and (tile+dif).y >=0 and (tile+dif).y <height:
				if not (tile+dif) in tiles \
				   and map_heights[(tile+dif)] == 0 \
				   and map_types[(tile+dif)] != 3 :
					adjs.append(tile+dif)
	return adjs

func random_location(center, sdev):
	var x = int(round(rng.randfn(center.x, sdev))) % width
	var y = int(round(rng.randfn(center.y, sdev))) % height
	return Vector2(x, y)

# Construct a building that is 1x1
func construct_building(type, center, sdev, connect, road_type):
	var loc
	var time_start = OS.get_unix_time()
	rng.randomize()
	var square_exists = get_town_square_loc()
	var square_adjacents = false
	var max_square_adjacents = false
	if square_exists != null:
		square_adjacents = get_adjacents(square_exists)
		max_square_adjacents = get_max_adjacents(square_exists)
		if float(len(square_adjacents))/float(len(max_square_adjacents)) <= 0.4:
			square_adjacents = false
	
	while true:
		rng.randomize()
		var rand = rng.randf_range(0,1)
		if square_adjacents and rand <= CHANCE_BY_SQUARE and type != 'center':
			loc = square_adjacents[rng.randi_range(0,len(square_adjacents)-1)]
		else:
			loc = random_location(center, sdev)
		var p
		if canbuild(loc, false): 
			var tar = get_nearest(loc, connect)
			p = canpath_to(loc, tar, road_type)
		else:
			p = false
		if p:
			if len(p) < MAX_PATH_DIST:
				var new_build = new_building([loc], type)
				_mbuildings[loc] = new_build
				unique_buildings.append(new_build)
				for tile in p:
					if not tile in _mroads and not tile in _mbuildings:
						_mroads[tile] = road_type
						set_tile_owner(tile, self)
				emit_signal("construct_roads", p, _mbuildings, road_type)
				emit_signal("construct_building", new_build)
				return loc
		if OS.get_unix_time() - time_start >= MAX_BUILD_TIME:
			print("Couldn't finish building")
			return null

# This is for special types of buildings, that require different 
# shapes than just 1x1
func construct_multi_building(center, \
							  sdev, \
							  type, \
							  is_road, \
							  paths_to, \
							  road_type, \
							  no_adj, \
							  size, \
							  owner_obj):
	var x
	var y
	var x_sz
	var y_sz
	var locs
	var time_start = OS.get_unix_time()
	#keep repeating until we find it... or time runs out
	while true:
		rng.randomize()
		x = round(rng.randfn(center.x, sdev))
		y = round(rng.randfn(center.y, sdev))
		x_sz = rng.randi_range(2,size)
		y_sz = max(2, x_sz + rng.randi_range(-1,+1))
		locs = []
		for wid in range(x_sz):
			for hi in range(y_sz):
				locs.append(Vector2(x,y) + Vector2(wid, hi))
		#check if all are buildable
		
		var cb = true
		for loc in locs:
			if not canbuild(loc, no_adj):
				cb = false
		
		#check if at least one is pathable
		var path = false
		var tar
		var tpath
		if cb:
			for loc in locs:
				tar = get_nearest(loc, paths_to)
				if not path: path = canpath_to(loc, tar, road_type)
				else:
					tpath = canpath_to(loc,tar,road_type)
					if tpath:
						if len(tpath) < len(path):
							path = tpath
		
		#can we build?
		if path:
			if len(path) < MAX_PATH_DIST:
				var new_build = new_building(locs, type)
				unique_buildings.append(new_build)
				for loc in locs: 
					_mbuildings[loc] = new_build
					set_tile_owner(loc, owner_obj)
					if is_road: 
						_mroads[loc] = road_type
				for tile in path:
					if not tile in _mroads and not tile in _mbuildings:
						_mroads[tile] = road_type
						set_tile_owner(tile, owner_obj)
				emit_signal("construct_roads", path, _mbuildings, road_type)
				emit_signal("construct_building", new_build)
				return new_build
		if OS.get_unix_time() - time_start >= MAX_BUILD_TIME:
			print("Couldn't finish building")
			return false

func create_resident(pop, town, house):
	pop.make_person(town, house)

func get_building(location):
	if not location in _mbuildings:
		return false
	return _mbuildings[location]

func get_road(location):
	if location in _mroads:
		return _mroads[location]
	return false

func set_tile_owner(location, obj):
	_owners[location] = obj

func get_tile_owner(location):
	if location in _owners:
		return _owners[location]
	return false

func new_building(location, ty):
	var building = TYPE_DICT[ty].instance()
	building.build(self, location, name_generator, world.towns.get_pos(location))
	drawer.add_child(building)
	return building

func update_building(building):
	world.towns.update_building(building.location[0], building.get_sprite())
