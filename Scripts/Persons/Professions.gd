extends "res://Scripts/Persons/PersonBase.gd"

var get_work = funcref(self, "get_work_unemp")
var do_work = funcref(self, "work_unemp")

var boss
var workers = []
var profession
var work_loc
var wake_up_time

var work_done = false

var PROFESSIONS_DICT = {
	"none": [		funcref(self, "get_work_unemp"), \
					funcref(self, "work_unemp")],
					
	"farmer": [		funcref(self, "get_work_farmer"), \
					funcref(self, "work_farmer")],
					
	"farmhand": [	funcref(self, "get_work_farmhand"), \
					funcref(self, "work_farmhand")],
					
	"mayor": [		funcref(self, "get_work_unemp"), \
					funcref(self, "work_unemp")]
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
	
	var square_time = 20 - (7 - wake_up_time)
	if world_time > square_time:
		work_done = true
	
	return true

# FARMER

var work_farm
var workers_farms = {} #keep track of which worker works where

func get_work_farmer():
	if "farm" in owned_properties:
		if not work_farm:
			work_farm = get_dry_farm()
			if work_farm:
				return work_farm
			else: 
				work_done = true
				return house
		else: return work_farm
	else: return get_work_unemp()

func get_dry_farm():
	if "farm" in owned_properties:
		var available_farms = []
		for farm in owned_properties["farm"]:
			for tile in farm.location:
				if not farm.is_watered(tile):
					available_farms.append(farm)
					break
		if len(available_farms) > 0:
			return available_farms[world.rng.randi_range(0,len(available_farms)-1)]
		else: return false
	else:
		return false

func give_work_farmhand(farmhand):
	assert(farmhand in workers)
	if "farm" in owned_properties:
		if not workers_farms[farmhand]:
			workers_farms[farmhand] = get_dry_farm()
			if workers_farms[farmhand]:
				return workers_farms[farmhand]
			else: 
				farmhand.work_done = true
				return farmhand.house #not necessary, should be replaced straight away
		else: return workers_farms[farmhand]
	else: 
		#should probably get rid of this farmhand if you don't even have a farm
		farmhand.work_done = true
		return farmhand.house #not necessary, should be replaced straight away

func work_farmer():
	var square_time = 20 - (7 - wake_up_time)
	if world_time > square_time:
		work_done = true
	if "farm" in owned_properties and in_building in owned_properties['farm']:
		if 1 + len(workers) < get_required_help(owned_properties['farm']):
			make_farmhand()
		if not in_building.is_watered(location):
			in_building.water(location)
			display_emotion("sweat")
			yield(get_tree().create_timer(timer_length(2.0,4.0)), "timeout")
			return true
		else:
			var to_water = []
			for tile in get_work.call_func().location:
				if not in_building.is_watered(tile):
					to_water.append(tile)
			var dist = 9999
			if len(to_water) < 1:
				to_water = get_work.call_func().location
				work_farm = null
			var go_tile
			for tile in to_water:
				if location.distance_to(tile) < dist:
					go_tile = tile
					dist = location.distance_to(tile)
			target_step = go_tile
			yield(self, "movement_arrived")
			
			return true
	else: 
		yield(work_unemp(), "completed")
		return true

func make_farmhand():
	var person = population.random_person([self], ["none"])
	workers.append(person)
	workers_farms[person] = null
	person.set_work("farmhand", self)

func get_required_help(farms) -> int:
	var helps = 0
	for farm in farms:
		helps += farm.required_workers
	return helps

# FARMHAND

func get_work_farmhand():
	return boss.give_work_farmhand(self)
#	if "farm" in boss.owned_properties:
#		var chosen_farm = boss.owned_properties["farm"][world.day % len(boss.owned_properties['farm'])]
#		return chosen_farm
#	else:
#		return get_work_unemp()

func work_farmhand():
	var square_time = 20 - (7 - wake_up_time)
	if world_time > square_time:
		work_done = true
	if "farm" in boss.owned_properties:
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
				work_done = true
			var go_tile
			for tile in to_water:
				if location.distance_to(tile) < dist:
					go_tile = tile
					dist = location.distance_to(tile)
			target_step = go_tile
			yield(self, "movement_arrived")
	else: 
		yield(work_unemp(), "completed")
		return true
