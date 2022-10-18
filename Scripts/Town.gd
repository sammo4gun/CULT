extends Node2D

#Generation Variables

export var EDGE_DIST = 10
export var NUM_BUILDINGS = 5
export var SDEV_DIST = 10

var Building = preload("res://Scenes/Building.tscn")

var rng = RandomNumberGenerator.new()
var map_heights
var map_types

#Storing variables

var _center

var _mbuildings = {} #maps map locations to building IDs
var _buildings = {} #maps building IDs to information

#Utility
onready var ground = get_node('/root/World/Map/Ground')
onready var drawer = $"../YDrawer"

func pick_center(w, h):
	var c
	while true:
		rng.randomize()
		var x = EDGE_DIST + rng.randi() % (w-(2*EDGE_DIST))
		var y = EDGE_DIST + rng.randi() % (h-(2*EDGE_DIST))
		c = Vector2(x, y)
		if map_types[c] != 3 and map_heights[c] == 0:
			return c

func canbuild(loc, w, h):
	#check its within the map
	if loc.x >= 0 and loc.x < w and loc.y >= 0  and loc.y < h:
		#check if no building is there yet
		if not loc in _mbuildings:
			if map_heights[loc] == 0 and map_types[loc] != 3:
				#TODO: check if it is accessible
				return true
	return false

func build_town(w, h, mtypes, mheights):
	map_types = mtypes
	map_heights = mheights
	_center = pick_center(w,h)
	
	for i in range(NUM_BUILDINGS):
		rng.randomize()
		var loc
		var x
		var y
		while true:
			x = round(rng.randfn(_center.x, SDEV_DIST))
			y = round(rng.randfn(_center.y, SDEV_DIST))
			loc = Vector2(x, y)
			if canbuild(loc, w, h):
				break
		_mbuildings[loc] = i
		_buildings[i] = new_building(loc)
	print(self.position.y)
	
	
func new_building(location):
	var building = Building.instance()
	building.set_place(location, map_heights[location], ground)
	drawer.add_child(building)
	return building
