extends Node2D

export var HEIGHT = 60
export var WIDTH = 40
export var NUM_TOWNS = 3
var speed_factor = 1

# statistics about the map
var _altitude = {}
var _moisture = {}
var openSimplexNoise = OpenSimplexNoise.new()
var rng = RandomNumberGenerator.new()
var Town = preload("res://Scenes/Town.tscn")

# generated map visible features
var _mtype = {}
var _mheight = {}
var _mroads = [] # list of dictionaries of tiles with roads
var _mbuildings = {}

var towns_dict = {}

var time = null
var new_time

onready var selector = $Selector
onready var GUI = $Camera2D/CanvasLayer/GUI
onready var drawer = $Map
onready var pathfinding = $Pathfinder
onready var towns = $Towns
onready var population = $Population
onready var namegenerator = $NameGenerator
onready var daynightcycle = $Day_Night

func _ready():
	randomize()
	_altitude = buildEnv(100, 5)
	_moisture = buildEnv(50, 2)
	terrainMap()
	
	pathfinding.initialisePathfinding(WIDTH, HEIGHT, _mtype, _mheight)
	
	#include code to produce civilization
	#_mroads = buildEmpty()
	_mbuildings = buildEmpty()
	
	for i in NUM_TOWNS:
		towns_dict["town" + str(i)] = make_town()
	
	# clean up roads by removing roads that don't connect buildings
	
	GUI.map_ready(_altitude, _mbuildings)
	drawer.map_ready(WIDTH, HEIGHT, \
					_mtype, _mheight, \
					_mroads, _mbuildings)
	
	daynightcycle.start_cycle(5)
	GUI.start_time()
	time = get_time()["hour"]

var starttime = OS.get_unix_time()
func _process(_delta):
	if time != null:
		new_time = get_time()['hour']
		if new_time!= time:
			time = new_time
			population._hour_update(time)

func make_town():
	var town = Town.instance()
	town.connect("construct_roads", self, "_on_Town_construct_roads")
	town.connect("construct_building", self, "_on_Town_construct_building")
	town.connect("destroy_roads", self, "_on_Town_destroy_roads")
	town.set_parents(drawer, pathfinding, self, namegenerator, population)
	towns.add_child(town)
	
	town.NUM_RESIDENTIAL = 10
	town.build_town(WIDTH, HEIGHT, _mtype, _mheight)
	return town

func buildEmpty():
	var map = {}
	for x in range(WIDTH):
		for y in range(HEIGHT):
			map[Vector2(x,y)] = 0
	return map

# Returns what contents are of a tile. Does not work on tiles with
# a building or road of any kind.
func get_tile(location):
	var nm = "null"
	match _mtype[location]:
		0: nm = "Earth"
		1: nm = "Dirt"
		2: nm = "Highlight"
		3: nm = "Water"
		4: nm = "Grass"
		5: nm = "Trees"
	return {"name": nm}

# Builds an empty map to render
func buildEnv(per, oct):
	openSimplexNoise.seed = randi()
	openSimplexNoise.period = per
	openSimplexNoise.octaves = oct
	
	var map = {}
	
	for x in range(WIDTH):
		for y in range(HEIGHT):
			# set hidden values for tiles
			map[Vector2(x, y)] = 2*abs(openSimplexNoise.get_noise_2d(x,y))
	return map

func terrainMap():
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var coord = Vector2(x, y)
			_mtype[coord] = 3
			_mheight[coord] = 0
			
			#set mountains
			if _altitude[coord] > 0.13:
				_mtype[coord] = 0
				if _moisture[coord] > 0.9:
					_mtype[coord] = 5
				elif _moisture[coord] > 0.7:
					if rng.randf_range(0,1) > 0.7:
						_mtype[coord] = 5
				else:
					if rng.randf_range(0,1) > 0.95:
						_mtype[coord] = 5
				
			if _altitude[coord] > 0.6:
				_mtype[coord] = 1
				_mheight[coord] = 1	
			if _altitude[coord] > 0.8:
				_mtype[coord] = 1
				_mheight[coord] = 2

func is_road_tile(tile):
	for path in _mroads:
		if tile in path:
			return true
	return false

func get_time():
	return daynightcycle.get_time()

func _on_tile_selected(tile):
	if tile:
		selector.setSelected(tile)
	else: selector.deSelect()
	
func selected_person(person):
	selector.selectPerson(person)

func _on_Town_construct_roads(path, buildings, type):
	if len(path) > 1:
		var p = {}
		for tile in path:
			if not tile in buildings and not is_road_tile(tile):
				p[tile] = type
				_mtype[tile] = 2
		_mroads.append(p)

func _on_Town_construct_building(building):
	for loc in building.location:
		_mbuildings[loc] = building.get_id()
		_mtype[loc] = 2

func _on_Town_destroy_roads(roads):
	for tile in roads:
		for path in _mroads:
			if tile in path:
				path.erase(tile)
				_mtype[tile] = 0

var sp = 0
var sp_factors = [1,2,4,0.25,0.5]
func _on_GUI_button():
	sp += 1
	sp = sp % 5
	speed_factor = sp_factors[sp]
	daynightcycle.adjust_cycle(1.0/sp_factors[sp])
