extends Node2D

export var SPEED = 60

signal movement_arrived

onready var selector = $Selector
onready var bubble = $Thoughts
onready var feelings = {"happy": $Happy, "surprise": $Surprise, "sweat" : $Sweat}

var namegenerator
var population
var world
var pathfinding
var ground
var behaviours
var speeds

# There are two parts to creating a person: 1. their own stats and 2. the role they fill in the world.
# 1.
var person_name = []
var string_name = ""
# Characteristics
# Appearance

# 2.
var town
var house
# Friends
var profession
var work_loc
var owned_properties = {}

# 3. One-time calc variables
var paths_from_home = {}
var wake_up_time

# DIRECT STATE VARIABLES
var location
var in_building

var activity = "home"

#UTILITY

var moving_to = null
var target_step = null
var prevloc = Vector2(0,0)
var adj_speed = SPEED

var time_start = 0
var chance = 0.0
var mouse_on = false

var open = true
var world_time = 0
# night, dawn, day, dusk
var day_time = "night"

# CREATION: Sets parents, owned house, starting house, and position
# Also calls make_thoughts() to figure out who this person is.
func create(wrld, pop, twn, hse, beh) -> void:
	time_start = OS.get_unix_time()
	world = wrld
	population = pop
	town = twn
	house = hse
	behaviours = beh
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	speeds = wrld.SPEEDS
	ground = pop.ground
	
	in_building = house
	location = house.location[0]
	create_name()
	position = ground.map_to_world(location)
	position.y += 45
	prevloc = location
	
	make_thoughts()

func destroy() -> void:
	queue_free()

# CREATION: Randomly generates what this person's job and personality is like.
func make_thoughts() -> void:
	# As the character starts at home, this calculates their path from home to
	# work to save processing time.
	var square_locations = town.get_town_square_loc()
	var square_dist = 0
	$Popup/Label.text = person_name[0] + '\n' + person_name[1]
	if square_locations:
	#	paths_from_home[square_locations] = get_path_to(square_locations)
		square_dist = len(get_path_to(square_locations))
		wake_up_time = 7 - int(square_dist / 10)
	else: 
		wake_up_time = 7
	
	# Determine Professions
	
	if house.type == "center":
		profession = "mayor"
	elif house.type == "store":
		profession = "shopkeep"
	elif square_dist > 3 and world.rng.randf_range(0,1) > 0.8: 
		profession = "farmer"
	else: 
		profession = "none"
	
	population.chosen_profession(self, profession)

# CREATION: Pinged by the town after done constructing work stuff.
func set_work():
	var work = get_work()
	#paths_from_home[work] = get_path_to(work)
	var square_dist = len(get_path_to_building(work))
	wake_up_time = 7 - int(square_dist / 10)

# CREATION: Makes the name of the player.
func create_name() -> void:
	var potname
	while true:
		potname = [namegenerator.person_first(), namegenerator.person_last()]
		if not population.name_exists(potname):
			person_name = potname
			for part in person_name:
				string_name += part + " "
			string_name = string_name.trim_suffix(" ")
			break

func _process(delta):
	if open:
		match activity:
			"home":
				# At home or want to go home.
				if in_building:
					if in_building == house:
						if not in_building.lights_on and day_time != "day":
							in_building.turn_lights_on()
						if day_time == "night":
							open = false
							asleep()
							activity = "sleep"
						if world_time >= wake_up_time and world_time <= 20 - (7 - wake_up_time):
							open = false
							prepare_to_leave()
							activity = "work"
					elif location in get_work().location:
						open = false
						go_building(house)
			"sleep":
				if in_building.lights_on: in_building.turn_lights_off()
				if day_time in ['day', 'dawn']: 
					open = false
					awaken()
					activity = "home"
				if world_time >= wake_up_time and world_time <= 20 - (7 - wake_up_time):
					open = false
					awaken()
					activity = "home"
			"work":
				# At home and preparing to go to the square
				if in_building:
					if in_building == house:
						open = false
						var work_building = get_work()
						if work_building in paths_from_home:
							go_path(paths_from_home[work_building])
						else: 
							paths_from_home[work_building] = get_path_to_building(work_building)
							go_path(paths_from_home[work_building])
					
					elif location in get_work().location:
						var square_time = 20 - (7 - wake_up_time)
						if world_time <= square_time:
							open = false
							work_activity()
						else: activity = "home"
	
	if target_step != null and moving_to == null:
		moving_to = ground.map_to_world(target_step)
		moving_to.y += 45
		adj_speed = calculate_speed(location, target_step)
		if world.towns.get_building(target_step):
			if not world.towns.get_building(target_step).can_enter:
				var target_y = town.rng.randi_range(moving_to.y - 8, moving_to.y + 12)
				var target_x = town.rng.randi_range(moving_to.x - 10, moving_to.x + 10)
				moving_to = Vector2(target_x, target_y)
	
	if moving_to != null:
		position = position.move_toward(moving_to, delta * adj_speed * world.speed_factor)
		if position == moving_to:
			location = target_step
			target_step = null
			moving_to = null
			emit_signal("movement_arrived")

# UTILITY: Calculate speed from the speed factors of two travelling squares
func calculate_speed(loc, target):
	if loc in town._mroads:
		if target in town._mroads:
			return SPEED
		return SPEED*0.8/speeds[world._mtype[target]]
	return SPEED*0.6/speeds[world._mtype[loc]]

# BEHAVIOUR: Call the square enjoyment function, then set open to true
func work_activity():
	yield(work_enjoyer(), "completed")
	open = true

func go_building(building):
	var path = pathfinding.walkToBuilding(location, building, in_building, world._mbuildings, town._mroads, [1,2], false)
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Head to a target after generating a path to that target
func go(target):
	var path = pathfinding.walkRoadPath(location, target, world._mbuildings, town._mroads, [1,2], false)
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Follow a path to its completion
func go_path(path):
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Take a few seconds to wake up / do other end of night stuff
func awaken():
	yield(get_tree().create_timer(timer_length(0.5,3.0)), "timeout")
	# give a certain amount of time to wake up / do other end-of-night stuff
	open = true

# BEHAVIOUR: Take a few seconds to go to sleep / do other end of evening stuff
func asleep():
	yield(get_tree().create_timer(timer_length(1.0,6.0)), "timeout")
	# give a certain amount of time to go to sleep / do other end-of-evening stuff
	open = true

# BEHAVIOUR: Take a few seconds to leave the house / do other end of morning stuff
func prepare_to_leave():
	yield(get_tree().create_timer(timer_length(0.5,3.0)), "timeout")
	# give a certain amount of time to prepare for leaving to the square
	open = true

# EXECUTION: Displays an emotion for a random period of time
func display_emotion(feeling):
	if bubble.visible != true:
		bubble.visible = true
		feelings[feeling].visible = true
		
		yield(get_tree().create_timer(timer_length(0.3,0.6)), "timeout")
		
		bubble.visible = false
		feelings[feeling].visible = false

# EXECUTION: Enter the building on current square
func enter_building():
	assert(world._mbuildings[location] != 0)
	in_building = world.towns.get_building(location)
	in_building.enter(self)
	if in_building.can_enter:
		$Area2D/CollisionShape2D.disabled=true
		visible = false

# EXECUTION: Leaves the building on current square
func leave_building():
	assert(world._mbuildings[location] != 0)
	if in_building.can_enter:
		if in_building.lights_on and len(in_building.inside) < 2: 
			in_building.turn_lights_off()
		$Area2D/CollisionShape2D.disabled=false
		visible = true
	in_building.leave(self)
	in_building = false

# EXECUTION: Enjoy work for a few seconds
func work_enjoyer():
	assert(location in get_work().location)
	yield(get_tree().create_timer(timer_length(1.0,0)), "timeout")
	
	if in_building.type == "square":
		var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(0,0)]
		var step
		step = choices[world.rng.randi_range(0,4)]
		if (location + step) in get_work().location:
			var target = location + step
			target_step = target
			yield(self, "movement_arrived")
		
		if world.rng.randf_range(0,1) > 0.5:
			display_emotion("happy")
		
		yield(get_tree().create_timer(timer_length(0.5,1.0)), "timeout")
	
	elif in_building.type == "farm":
		
		if not in_building.is_watered(location):
			in_building.water(location)
			display_emotion("sweat")
			yield(get_tree().create_timer(timer_length(2.0,4.0)), "timeout")
		else:
			var to_water = []
			for tile in get_work().location:
				if not in_building.is_watered(tile):
					to_water.append(tile)
			var dist = 9999
			if len(to_water) < 1:
				to_water = get_work().location
			var go_tile
			for tile in to_water:
				if location.distance_to(tile) < dist:
					go_tile = tile
					dist = location.distance_to(tile)
			target_step = go_tile
			yield(self, "movement_arrived")
	return true

# UTILITY: Returns the squares associated with "work"
func get_work():
	if profession == "farmer" and "farm" in owned_properties:
		var chosen_farm = owned_properties["farm"][world.day % len(owned_properties['farm'])]
		return chosen_farm
	return town.get_town_square()

# UTILITY: Get a path to a target
func get_path_to(target):
	return pathfinding.walkRoadPath(location, target, world._mbuildings, town._mroads, [1,2], false)

func get_path_to_building(building):
	return pathfinding.walkToBuilding(location, building, in_building, world._mbuildings, town._mroads, [1,2], false)

# UTILITY: Setting the target square to each square following the path.
func follow_path(path):
	assert(path[0] == location)
	if in_building:
		leave_building()
	
	for step in path:
		# instead of ugly jump, set it to be a smooth transition from current location to the next step.
		if location != step:
			target_step = step
			yield(self, "movement_arrived")
	
	if world.towns.get_building(location):
		enter_building()
	
	return true

# UTILITY: Adds a piece of property to the player's owned_properties 
# dictionary.
func add_property(building) -> void:
	var type = building.get_type()
	if type in owned_properties:
		owned_properties[type].append(building)
	else: 
		owned_properties[type] = [building]
	building.add_owner(self)

# UTILITY: Update hour times
func _hour_update(hour):
	world_time = hour
	if world_time < 6 or world_time > 21:
		day_time = "night"
	elif world_time < 8:
		day_time = "dawn"
	elif world_time < 18:
		day_time = "day"
	elif world_time < 21:
		day_time = "dusk"

# UTILITY: Doing a timer from range mini to maxi compensated for speed factor
func timer_length(mini, maxi) -> float:
	if maxi:
		return world.rng.randf_range(mini, maxi)/world.speed_factor
	return mini/world.speed_factor

# UTILITY: On selected
func on_selected():
	display_emotion("surprise")
	selector.visible = true

# UTILITY: Not selected
func on_deselected():
	selector.visible = false

func _input(event):
	if mouse_on:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				world.selected_person(self)
				get_tree().set_input_as_handled()

func _on_Area2D_mouse_entered():
	if not population.mouse_on:
		population.mouse_on = true
		$Popup.visible = true
		mouse_on = true

func _on_Area2D_mouse_exited():
	population.mouse_on = false
	$Popup.visible = false
	mouse_on = false
