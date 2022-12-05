extends "res://Scripts/Persons/Personality.gd"

var get_work = funcref(self, "get_work_unemp")
var do_work = funcref(self, "work_unemp")
var day_reset = funcref(self, "day_reset_unemp")

var boss
var workers = []
var profession
var work_loc
var travel_time

var work_done = false

var PROFESSIONS_DICT = {
	"none": [   	funcref(self, "get_work_unemp"), \
					funcref(self, "work_unemp"), \
					funcref(self, "day_reset_unemp")],
					
	"farmer": [ 	funcref(self, "get_work_farmer"), \
					funcref(self, "work_farmer"), \
					funcref(self, "day_reset_farmer")],
					
	"farmhand":[	funcref(self, "get_work_farmhand"), \
					funcref(self, "work_farmhand"), \
					funcref(self, "day_reset_farmhand")],
					
	"mayor": [  	funcref(self, "get_work_unemp"), \
					funcref(self, "work_unemp"), \
					funcref(self, "day_reset_unemp")],
}

# CHANGING JOBS
func update_profession():
	var funcs = PROFESSIONS_DICT[profession]
	get_work = funcs[0]
	do_work = funcs[1]
	day_reset = funcs[2]

func is_at_work():
	# Update this for ppl who do not work at a building to just include squares
	if in_building:
		return in_building == get_work.call_func()
	else: return false

# UNEMPLOYED

func day_reset_unemp():
	work_done = false

# UTILITY: Returns the squares associated with "work"
func get_work_unemp():
	return town.get_town_square()

# EXECUTION: Enjoy work for a few seconds
func work_unemp():
	assert(location in get_work.call_func().get_location())
	
	var square_time = 20.0 - travel_time
	if world_time > square_time:
		work_done = true
	
	yield(get_tree().create_timer(timer_length(1.0,0)), "timeout")
	
	var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(0,0)]
	var step
	step = choices[world.rng.randi_range(0,4)]
	if (location + step) in get_work.call_func().get_location():
		var target = location + step
		target_step = target
		yield(self, "movement_arrived")
	
	if world.rng.randf_range(0,1) > 0.5:
		display_emotion("happy")
	
	yield(get_tree().create_timer(timer_length(0.5,1.0)), "timeout")
	
	return true

# FARMER

var work_farm
var workers_farms = {} #keep track of which worker works where
var need_workers = false
var recruited_time_started = null
var checked_workers = []

func day_reset_farmer():
	work_done = false
	if "farm" in owned_properties:
		if 1 + len(workers) < get_required_help(owned_properties['farm']):
			need_workers = true
			checked_workers = []
			recruited_time_started = null

func get_work_farmer():
	if "farm" in owned_properties:
		if need_workers: return town.get_town_square()
		if not work_farm:
			work_farm = get_dry_farm()
			if work_farm:
				return work_farm
			else: 
				work_done = true
				return house
		else: return work_farm
	else:
		return get_work_unemp()

func work_farmer():
	var square_time = 20.0 - travel_time
	if world_time > square_time:
		work_done = true
	if "farm" in owned_properties and in_building in owned_properties['farm']:
		if not in_building.is_watered(location):
			in_building.water(location)
			display_emotion("sweat")
			yield(get_tree().create_timer(timer_length(2.0,4.0)), "timeout")
			return true
		else:
			var to_water = []
			for tile in get_work.call_func().get_location():
				if not in_building.is_watered(tile):
					to_water.append(tile)
			var dist = 9999
			if len(to_water) < 1:
				to_water = get_work.call_func().get_location()
				work_farm = null
			var go_tile
			for tile in to_water:
				if location.distance_to(tile) < dist:
					go_tile = tile
					dist = location.distance_to(tile)
			target_step = go_tile
			yield(self, "movement_arrived")
			
			return true
		
	elif in_building == town.get_town_square() and "farm" in owned_properties:
		if need_workers:
			make_farmhand()
			yield(get_tree(), "idle_frame")
			return true
		else: 
			yield(get_tree(), "idle_frame")
			reconsider = true
			return true
	else: 
		yield(work_unemp(), "completed")
		return true

func make_farmhand():
	assert(in_building == town.get_town_square())
	# maybe split this to have the decision which farmhand not to be fully random?
	var persons = get_social_options([], checked_workers)
	if persons:
		var picked_person = null
		var closest_dist = 9999
		var dist
		for person in persons:
			dist = person.house.location[0].distance_to(house.location[0])
			if dist < closest_dist:
				closest_dist = dist
				picked_person = person
		
		if not conversing:
			engage_conversation(picked_person, ['farmhand'])
			checked_workers.append(picked_person)
	else:
		if recruited_time_started == null:
			recruited_time_started = world_time
		if world_time - recruited_time_started >= 3.0:
			# give up on finding help for today
			# maybe eventually start giving up on finding help altogether?
			need_workers = false

func farm_dry(farm):
	assert(farm.type == "farm")
	for tile in farm.get_location():
		if not farm.is_watered(tile):
			return true
	return false

func get_dry_farm():
	if "farm" in owned_properties:
		var available_farms = []
		for farm in owned_properties["farm"]:
			if farm_dry(farm): 
				available_farms.append(farm)
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
		elif not farm_dry(workers_farms[farmhand]): 
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

func get_required_help(farms) -> int:
	var helps = 0
	for farm in farms:
		helps += farm.required_workers
	return helps

# FARMER RECRUIT

func asked_farmhand() -> Array: # sure I'll be your farmhand!
	assert(conversing.profession == "farmer")
	if profession == 'none':
		return [true, false]
	return [false, false]

func y_farmhand(): # whoever I am talking to has said yes to the recruit
	workers.append(conversing)
	workers_farms[conversing] = null
	conversing.set_work("farmhand", self)
	if 1 + len(workers) >= get_required_help(owned_properties['farm']):
		need_workers = false

func n_farmhand():
	# be sad, dislike this person
	pass

# FARMHAND

func day_reset_farmhand():
	work_done = false

func get_work_farmhand():
	return boss.give_work_farmhand(self)

func work_farmhand():
	var done_time = 20.0 - travel_time
	if world_time > done_time:
		work_done = true
	if "farm" in boss.owned_properties:
		if in_building in boss.owned_properties['farm'] and location in in_building.get_location():
			if not in_building.is_watered(location):
				in_building.water(location)
				display_emotion("sweat")
				yield(get_tree().create_timer(timer_length(2.0,4.0)), "timeout")
			else:
				var to_water = []
				for tile in get_work.call_func().get_location():
					if not in_building.is_watered(tile):
						to_water.append(tile)
				var dist = 9999
				if len(to_water) < 1:
					to_water = get_work.call_func().get_location()
				var go_tile
				for tile in to_water:
					if location.distance_to(tile) < dist:
						go_tile = tile
						dist = location.distance_to(tile)
				target_step = go_tile
				yield(self, "movement_arrived")
		else: 
			reconsider = true
			yield(get_tree(), "idle_frame")
			return true
	else: 
		yield(work_unemp(), "completed")
		return true
