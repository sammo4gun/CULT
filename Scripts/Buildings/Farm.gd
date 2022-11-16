extends "res://Scripts/Building.gd"

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
	return FARM_DICT[[1,1,1,1]]
