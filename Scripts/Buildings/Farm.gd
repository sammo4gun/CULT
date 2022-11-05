extends "res://Scripts/Building.gd"

var state = {}

func _ready():
	._ready()
	type = "farm"
	house_name = "Farm"
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
