extends Node2D

export var SPEED = 100

signal movement_arrived

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

# DIRECT STATE VARIABLES
var location
var in_building

var moving_to = null
var target_step = null
var prevloc = Vector2(0,0)

func _physics_process(delta):
	if prevloc != location:
		position = ground.map_to_world(location)
		position.y += 45
		prevloc = location
	
	if target_step != null and moving_to == null:
		moving_to = ground.map_to_world(target_step)
		moving_to.y += 45
	
	if moving_to != null:
		position = position.move_toward(moving_to, delta*SPEED)
		if position == moving_to:
			location = target_step
			moving_to = null
			target_step = null
			emit_signal("movement_arrived")
	
func create(wrld, pop, twn, hse):
	world = wrld
	population = pop
	town = twn
	house = hse
	in_building = house
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	ground = pop.ground
	location = house.location[0]
	get_name()

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

func enter_building():
	assert(world._mbuildings[location] != 0)
	in_building = world.towns.get_building(location)
	in_building.enter(self)
	visible = false

func leave_building():
	assert(world._mbuildings[location] != 0)
	in_building.leave(self)
	in_building = false
	visible = true

func follow_path(path):
	assert(path[0] == location)
	if in_building:
		leave_building()
	
	for step in path:
		# instead of ugly jump, set it to be a smooth transition from current location to the next step.
		if location != step:
			target_step = step
			yield(self, "movement_arrived")
	
	if world.towns.get_building(location).can_enter:
		enter_building()
	
	return true

func square_enjoyer():
	assert(world.towns.get_building(location).type == 3)
	yield(get_tree().create_timer(.5), "timeout")
	
	var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), null, Vector2(0,0)]
	var step
	var building
	while true:
		step = choices[world.rng.randi_range(0,5)]
		if step == null:
			break
		building = world.towns.get_building(location + step)
		if building:
			if building.type == 3:
				var target = location + step
				target_step = target
				yield(self, "movement_arrived")
		yield(get_tree().create_timer(.5), "timeout")
	return true

func square_and_back():
	var path = pathfinding.walkRoadPath(location, town.get_town_square_loc(), town._mroads)
	
	yield(follow_path(path), "completed")
	
	# have a fun time at the square!
	yield(square_enjoyer(), "completed")
	
	path = pathfinding.walkRoadPath(location, house.location, town._mroads)
	
	follow_path(path)
