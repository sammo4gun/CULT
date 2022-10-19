extends Node2D

signal construct_roads
signal construct_building

#Generation Variables

export var EDGE_DIST = 10
export var NUM_BUILDINGS = 5
export var SDEV_DIST = 20

var Building = preload("res://Scenes/Building.tscn")

var rng = RandomNumberGenerator.new()
var map_heights
var map_types
var width
var height

#Storing variables

var _center

var _mbuildings = {} #maps map locations to building IDs
var _buildings = {} #maps building IDs to information

#Utility
onready var drawer = $"../YDrawer"
onready var pathfinder = $"../Pathfinder"

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
	for x in range(width):
		for y in range(height):
			var coord = Vector2(x,y)
			#if its a road...
			if get_parent().is_road_tile(coord):
				if loc.distance_to(coord) < dist:
					th = coord
					dist = loc.distance_to(coord)
	return(th)

func canbuild(loc, w, h):
	#check its within the map
	if loc.x >= 0 and loc.x < w and loc.y >= 0  and loc.y < h \
		and not loc in _mbuildings \
		and map_heights[loc] == 0 and \
		map_types[loc] != 3 and \
		not get_parent().is_road_tile(loc):
			var target = get_nearest_road(loc)
			if target != null:
				return pathfinder.findRoadPath(loc, target)
			return [loc]
	return false

func get_town_hall_loc():
	for b in _buildings:
		if _buildings[b].type == 2:
			return _buildings[b].location
	return null

func construct_building(i, type):
	var x
	var y
	var loc
	var t = 0
	while true:
		t += 1
		rng.randomize()
		x = round(rng.randfn(_center.x, SDEV_DIST))
		y = round(rng.randfn(_center.y, SDEV_DIST))
		loc = Vector2(x, y)
		var p = canbuild(loc, width, height)
		if p:
			_mbuildings[loc] = i
			_buildings[i] = new_building(loc, type)
			emit_signal("construct_roads", p, _mbuildings)
			emit_signal("construct_building", _buildings[i])
			break
		if t >= 20:
			print("Couldn't finish building: " + str(i))
			return
			

func build_town(w, h, mtypes, mheights):
	width = w
	height = h
	map_types = mtypes
	map_heights = mheights
	_center = pick_center(w,h)

	var loc
	var x
	var y
	
	# build town center
	
	construct_building(0, 2)
	
	# build town square
	
	# build residential buildings
	
	for i in range(NUM_BUILDINGS):
		i += 1
		construct_building(i, 1)
	
func get_building(location):
	if not location in _mbuildings:
		return false
	var i = _mbuildings[location]
	return _buildings[i]

func new_building(location, id):
	var building = Building.instance()
	building.build(location)
	building.set_type(id)
	drawer.add_child(building)
	return building
