extends "res://Scripts/Persons/PersonBase.gd"

var get_work = funcref(self, "get_work_unemp")
var do_work = funcref(self, "work_unemp")

var PROFESSIONS_DICT = {
	"farmer": [funcref(self, "get_work_farmer"), funcref(self, "work_farmer")],
	"none": [funcref(self, "get_work_unemp"), funcref(self, "work_unemp")],
	"mayor": [funcref(self, "get_work_unemp"), funcref(self, "work_unemp")]
}

# CHANGING JOBS
func update_profession():
	var funcs = PROFESSIONS_DICT[profession]
	get_work = funcs[0]
	do_work = funcs[1]

# UNEMPLOYED

# UTILITY: Returns the squares associated with "work"
func get_work_unemp():
	return town.get_town_square()

# EXECUTION: Enjoy work for a few seconds
func work_unemp():
	assert(location in get_work.call_func().location)
	yield(get_tree().create_timer(timer_length(1.0,0)), "timeout")
	
	var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(0,0)]
	var step
	step = choices[world.rng.randi_range(0,4)]
	if (location + step) in get_work.call_func().location:
		var target = location + step
		target_step = target
		yield(self, "movement_arrived")
	
	if world.rng.randf_range(0,1) > 0.5:
		display_emotion("happy")
	
	yield(get_tree().create_timer(timer_length(0.5,1.0)), "timeout")
	
	return true

# FARMER

func get_work_farmer():
	if "farm" in owned_properties:
		var chosen_farm = owned_properties["farm"][world.day % len(owned_properties['farm'])]
		return chosen_farm

func work_farmer():
	if not in_building.is_watered(location):
		in_building.water(location)
		display_emotion("sweat")
		yield(get_tree().create_timer(timer_length(2.0,4.0)), "timeout")
	else:
		var to_water = []
		for tile in get_work.call_func().location:
			if not in_building.is_watered(tile):
				to_water.append(tile)
		var dist = 9999
		if len(to_water) < 1:
			to_water = get_work.call_func().location
		var go_tile
		for tile in to_water:
			if location.distance_to(tile) < dist:
				go_tile = tile
				dist = location.distance_to(tile)
		target_step = go_tile
		yield(self, "movement_arrived")

func get_required_help(farms) -> Dictionary:
	var help_dict = {}
	for farm in farms:
		help_dict[farm] = farm.required_workers
	return help_dict
