extends "res://Scripts/Buildings/Building.gd"

# STATS
var required_workers = 1

# CURRENT/UPDATABLE
var state = {}

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

func _ready():
	._ready()
	type = "farm"
	house_name = "Farm"
	BUILDING_LAYER = {1: false, 2: true}
	MULTI_ROAD =     {1: false, 2: false}
	for loc in location:
		state[loc] = {'watered': 0.0}
	
	required_workers = int(float(len(location)) / 3)

func _hour_update(time):
	if time == 0:
		for loc in location:
			state[loc]['watered'] -= 0.25

func is_watered(loc):
	return state[loc]['watered'] == 1.0

func water(loc):
	assert(loc in location)
	state[loc]['watered'] += 0.25

func get_sprite(tile):
	var dirs = [0,0,0,0]
	var i = 0
	for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
		if tile + dif in location:
			dirs[i] = 1
		i += 1
	return FARM_DICT[dirs]
