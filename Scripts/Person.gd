extends Node2D

export var SPEED = 60

signal movement_arrived

onready var selector = $Selector
onready var bubble = $Thoughts
onready var feelings = {"happy": $Happy, "surprise": $Surprise}

var namegenerator
var population
var world
var pathfinding
var ground

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
# Job/Role

# 3. One-time calc variables
var square_path #path from home to square
var square_dist

# DIRECT STATE VARIABLES
var location
var in_building
var on_square

var activity = "home"

#UTILITY

var moving_to = null
var target_step = null
var prevloc = Vector2(0,0)

var time_start = 0
var chance = 0.0

var open = true
var world_time = 0
# night, dawn, day, dusk
var day_time = "night"

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

func _process(delta):
	if open:
		match activity:
			"home":
				# At home or want to go home.
				if in_building:
					if not in_building.lights_on and day_time != "day":
						in_building.turn_lights_on()
					if day_time == "night":
						open = false
						asleep()
						activity = "sleep"
					if day_time == "day":
						open = false
						prepare_to_leave()
						activity = "square"
				if on_square:
					open = false
					go(house.location)
			"sleep":
				if in_building.lights_on: in_building.turn_lights_off()
				if day_time != "night": 
					open = false
					awaken()
					activity = "home"
			"square":
				# At home and preparing to go to the square
				if in_building:
					if in_building.lights_on: in_building.turn_lights_off()
					open = false
					go(town.get_town_square_loc())
				# On the square and having fun
				if on_square:
					if day_time == "day":
						open = false
						square_activity()
					else: activity = "home"
	
	if target_step != null and moving_to == null:
		moving_to = ground.map_to_world(target_step)
		moving_to.y += 45
		if world.towns.get_building(target_step):
			if world.towns.get_building(target_step).type == 3:
				var target_y = town.rng.randi_range(moving_to.y - 8, moving_to.y + 12)
				var target_x = town.rng.randi_range(moving_to.x - 10, moving_to.x + 10)
				moving_to = Vector2(target_x, target_y)
	
	if moving_to != null:
		position = position.move_toward(moving_to, delta*SPEED * world.speed_factor)
		if position == moving_to:
			location = target_step
			target_step = null
			moving_to = null
			emit_signal("movement_arrived")
	
func create(wrld, pop, twn, hse):
	time_start = OS.get_unix_time()
	world = wrld
	population = pop
	town = twn
	house = hse
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	ground = pop.ground
	
	in_building = house
	location = house.location[0]
	get_name()
	position = ground.map_to_world(location)
	position.y += 45
	prevloc = location
	
	make_thoughts()

func make_thoughts():
	# As the character starts at home, this calculates their path from home to
	# work to save processing time.
	if town.get_town_square_loc():
		square_path = get_path_to(town.get_town_square_loc())
		square_dist = len(square_path)
	else: 
		square_path = []
		square_dist = 0

func get_name():
	var potname
	while true:
		potname = [namegenerator.person_first(), namegenerator.person_last()]
		if not population.name_exists(potname):
			person_name = potname
			for part in person_name:
				string_name += part + " "
			string_name = string_name.trim_suffix(" ")
			break

func display_emotion(feeling):
	if bubble.visible != true:
		bubble.visible = true
		feelings[feeling].visible = true
		
		yield(get_tree().create_timer(timer_length(0.3,0.6)), "timeout")
		
		bubble.visible = false
		feelings[feeling].visible = false

func enter_building():
	assert(world._mbuildings[location] != 0)
	in_building = world.towns.get_building(location)
	in_building.enter(self)
	$Area2D/CollisionShape2D.disabled=true
	visible = false

func leave_building():
	assert(world._mbuildings[location] != 0)
	in_building.leave(self)
	in_building = false
	$Area2D/CollisionShape2D.disabled=false
	visible = true

func follow_path(path):
	assert(path[0] == location)
	if in_building:
		leave_building()
	if on_square:
		on_square = false
	
	for step in path:
		# instead of ugly jump, set it to be a smooth transition from current location to the next step.
		if location != step:
			target_step = step
			yield(self, "movement_arrived")
	
	if world.towns.get_building(location):
		if world.towns.get_building(location).can_enter:
			enter_building()
		else: on_square = true
	
	return true

func square_enjoyer():
	assert(world.towns.get_building(location).type == 3)
	yield(get_tree().create_timer(timer_length(1.0,0)), "timeout")
	
	var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(0,0)]
	var step
	var building
	step = choices[world.rng.randi_range(0,4)]
	building = world.towns.get_building(location + step)
	if building:
		if building.type == 3:
			var target = location + step
			target_step = target
			yield(self, "movement_arrived")
	
	if world.rng.randf_range(0,1) > 0.5:
		display_emotion("happy")
	
	yield(get_tree().create_timer(timer_length(0.5,1.0)), "timeout")
	
	return true

func timer_length(mini, maxi):
	if maxi:
		return world.rng.randf_range(mini, maxi)/world.speed_factor
	return mini/world.speed_factor

func go(target):
	var path = pathfinding.walkRoadPath(location, target, town._mroads)
	yield(follow_path(path), "completed")
	open = true

func get_path_to(target):
	return pathfinding.walkRoadPath(location, target, town._mroads)

func go_path(path):
	yield(follow_path(path), "completed")
	open = true

func awaken():
	yield(get_tree().create_timer(timer_length(0.5,3.0)), "timeout")
	# give a certain amount of time to wake up / do other end-of-night stuff
	open = true

func asleep():
	yield(get_tree().create_timer(timer_length(1.0,6.0)), "timeout")
	# give a certain amount of time to go to sleep / do other end-of-evening stuff
	open = true
	

func prepare_to_leave():
	yield(get_tree().create_timer(timer_length(0.5,3.0)), "timeout")
	# give a certain amount of time to prepare for leaving to the square
	open = true

# only call this if on a square
func square_activity():
	yield(square_enjoyer(), "completed")
	open = true

func on_selected():
	print(square_dist)
	display_emotion("surprise")
	selector.visible = true
	
func on_deselected():
	selector.visible = false

var mouse_on = false

func _input(event):
	if mouse_on:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				world.selected_person(self)
				get_tree().set_input_as_handled()

func _on_Area2D_mouse_entered():
	mouse_on = true

func _on_Area2D_mouse_exited():
	mouse_on = false
