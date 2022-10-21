extends Node2D

signal construct_roads
signal construct_building

#Generation Variables
export var NUM_RESIDENTIAL = 5
export var NUM_STORES = 3
export var MAX_SQUARE_SIZE = 4

export var CHANCE_BY_SQUARE = 0.7
export var MAX_PATH_DIST = 30
export var SDEV_RESIDENTIAL = 20
export var SDEV_CENTER = 5
export var EDGE_DIST = 10
export var MAX_BUILD_TIME = 6

var Building = preload("res://Scenes/Building.tscn")

var rng = RandomNumberGenerator.new()
var map_heights
var map_types
var width
var height
var town_name

#Storing variables

var _center

var _mroads = [] #list of locations that have roads
var _mbuildings = {} #maps map locations to building IDs

#Utility
var drawer
var pathfinder
var world

func set_parents(dr, pf, wrld):
	drawer = dr
	pathfinder = pf
	world = wrld

func pick_center(w, h):
	var c
	while true:
		rng.randomize()
		var x = EDGE_DIST + rng.randi() % (w-(2*EDGE_DIST))
		var y = EDGE_DIST + rng.randi() % (h-(2*EDGE_DIST))
		c = Vector2(x, y)
		if map_types[c] != 3 and map_heights[c] == 0:
			return c

func get_nearest_road(loc):
	var th = get_town_hall_loc()
	if th == null:
		return null
	#var dist = th.distance_to(loc)
	var dist = 999999
	for tile in _mroads:
		if loc.distance_to(tile) < dist:
			th = tile
			dist = loc.distance_to(tile)
	for building in _mbuildings:
		if _mbuildings[building].is_type("square") and \
		   loc.distance_to(building) < dist:
			th = building
			dist = loc.distance_to(building)
	return(th)

func canpath(loc):
	var target = get_nearest_road(loc)
	if target != null:
		return pathfinder.findRoadPath(loc, target, self, world._mbuildings)
	return [loc]

func canbuild(loc):
	#check its within the map & is buildable
	if loc.x >= 0 and loc.x < width and loc.y >= 0  and loc.y < height \
		and not loc in _mbuildings \
		and map_heights[loc] == 0 \
		and map_types[loc] != 3 \
		and not world.is_road_tile(loc):
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

func construct_building(i, type, center, sdev):
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
	
	var t = 0
	while true:
		t+=1
		rng.randomize()
		var rand = rng.randf_range(0,1)
		if square_adjacents and rand <= CHANCE_BY_SQUARE:
			loc = square_adjacents[rng.randi_range(0,len(square_adjacents)-1)]
		else:
			loc = random_location(center, sdev)
		var p
		if canbuild(loc): 
			p = canpath(loc)
		else:
			p = false
		if p:
			if len(p) < MAX_PATH_DIST:
				var new_build = new_building([loc], type)
				_mbuildings[loc] = new_build
				for tile in p:
					if not tile in _mroads and not tile in _mbuildings:
						_mroads.append(tile)
				emit_signal("construct_roads", p, _mbuildings)
				emit_signal("construct_building", new_build)
				return true
		if OS.get_unix_time() - time_start >= MAX_BUILD_TIME:
			print("Couldn't finish building: " + str(i))
			return false

# This is for special types of buildings, that require different 
# shapes than just 1x1
func construct_spec_building(i, type, center, sdev):
	if type == "square":
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
			x_sz = rng.randi_range(2,MAX_SQUARE_SIZE)
			y_sz = max(2, x_sz + rng.randi_range(-1,+1))
			locs = []
			for wid in range(x_sz):
				for hi in range(y_sz):
					locs.append(Vector2(x,y) + Vector2(wid, hi))
			#check if all are buildable
			
			var cb = true
			for loc in locs:
				if not canbuild(loc):
					cb = false
			
			#check if at least one is pathable
			var path = false
			if cb:
				for loc in locs:
					path = canpath(loc)
					if path: break
			
			#can we build?
			if path:
				if len(path) < MAX_PATH_DIST:
					var new_build = new_building(locs, type)
					for loc in locs: _mbuildings[loc] = new_build
					for tile in path:
						if not tile in _mroads and not tile in _mbuildings:
							_mroads.append(tile)
					emit_signal("construct_roads", path, _mbuildings)
					emit_signal("construct_building", new_build)
					return true
			if OS.get_unix_time() - time_start >= MAX_BUILD_TIME:
				print("Couldn't finish building: " + str(i))
				return false

func build_town(w, h, mtypes, mheights):
	width = w
	height = h
	map_types = mtypes
	map_heights = mheights
	_center = pick_center(w,h)
	town_name = "Town nr: " + str(rng.randi())
	
	var loc
	var x
	var y
	
	var i = 0
	
	# build town center
	construct_building(i, "center", _center, SDEV_CENTER)
	i+=1
	
	# build town square
	construct_spec_building(i, "square", get_town_hall_loc(), SDEV_CENTER/2)
	i+=1
	
	# build store buildings
	
	for v in range(NUM_STORES):
		if not construct_building(i, "store", get_town_square_loc()[0], SDEV_CENTER/2):
			print("FAILED TO BUILD")
			break
		i+=1
	
	# build residential buildings
	
	for v in range(NUM_RESIDENTIAL):
		if not construct_building(i, "residential", _center, SDEV_RESIDENTIAL):
			print("FAILED TO BUILD")
			break
		i+=1
		
func get_building(location):
	if not location in _mbuildings:
		return false
	return _mbuildings[location]

func new_building(location, ty):
	var building = Building.instance()
	building.build(location)
	building.set_type(ty)
	building.set_town(town_name)
	drawer.add_child(building)
	return building
