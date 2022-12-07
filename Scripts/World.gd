extends Node2D

export var HEIGHT = 60
export var WIDTH = 40
export var NUM_TOWNS = 3
var speed_factor = range_lerp(60, 20, 100, 0.25, 8)

var CURRENT

var SPEEDS = {
	0: 1.5,
	1: 2,
	2: 1,
	4: 2,
	5: 2.5
}

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
var day = 1

onready var selector = $Selector
onready var GUI = $CanvasLayer/GUI
onready var drawer = $Map
onready var pathfinding = $Pathfinder
onready var towns = $Towns
onready var population = $Population
onready var namegenerator = $NameGenerator
onready var daynightcycle = $Day_Night

func _ready():
	build_world()
	build_towns()
	start_game()

func build_world():
	randomize()
	_altitude = buildEnv(100, 5)
	_moisture = buildEnv(50, 2)
	terrainMap()
	
	pathfinding.initialisePathfinding(WIDTH, HEIGHT, _mtype, _mheight)
	drawer.map_init(WIDTH, HEIGHT, \
					_mtype, _mheight, \
					_mroads, _mbuildings)

func build_towns():
	_mbuildings = buildEmpty()
	
	var i = 0
	var c_town
	while i < NUM_TOWNS:
		c_town = make_town()
		if c_town:
			i+=1
			towns_dict["town" + str(i)] = c_town

func start_game():
	daynightcycle.start_cycle(5)
	GUI.start_time()
	time = get_time()["exact"]

func _process(_delta):
	if time != null and not get_time_paused():
		new_time = get_time()['exact']
		if new_time != time:
			if int(new_time) != int(time):
				towns._hour_update(int(new_time))
				if new_time == 0:
					day += 1
			population._time_update(new_time)
			time = new_time

func make_town():
	var town = Town.instance()
	town.connect("construct_roads", self, "_on_Town_construct_roads")
	town.connect("construct_building", self, "_on_Town_construct_building")
	town.connect("destroy_roads", self, "_on_Town_destroy_roads")
	town.connect("destroy_building", self, "_on_Town_destroy_building")
	town.set_parents(drawer, pathfinding, self, namegenerator, population)
	towns.add_child(town)
	
	town.NUM_RESIDENTIAL = 10
	if not town.build_town(WIDTH, HEIGHT, _mtype, _mheight):
		town.destroy_town()
		return false
	else: return town

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
			return path[tile]
	return 0

func get_time():
	return daynightcycle.get_time()

func _on_tile_selected(tile):
	if tile:
		selector.setSelected(tile)
	else: selector.deSelect()
	
func selected_person(person):
	selector.selectPerson(person)

func switch_selected_person(person):
	selector.switchPerson(person)

func get_time_paused():
	return daynightcycle.paused

func _on_Town_construct_roads(path, buildings, type):
	var p = {}
	for tile in path:
		if not tile in buildings and not is_road_tile(tile):
			p[tile] = type
			_mtype[tile] = 2
			drawer.terrain_update(tile)
	_mroads.append(p)
	drawer.road_update(p)

func _on_Town_construct_building(building):
	for loc in building.get_location():
		_mbuildings[loc] = building.get_id()
		_mtype[loc] = 2
		drawer.building_update(loc)

func _on_Town_destroy_roads(roads):
	for tile in roads:
		for path in _mroads:
			if tile in path:
				path.erase(tile)
				_mtype[tile] = 0
				drawer.remove_road(tile)
				drawer.terrain_update(tile)

func _on_Town_destroy_building(building):
	for loc in building.get_location():
		_mbuildings[loc] = 0
		_mtype[loc] = 0
		drawer.remove_building(loc)
		drawer.terrain_update(loc)

func _on_GUI_time_slider(speed):
	speed_factor = range_lerp(speed, 20, 100, 0.25, 8)
#	speed_factor = range_lerp(speed, 20, 100, 0.25, 80)
	daynightcycle.adjust_cycle(1.0/speed_factor)
