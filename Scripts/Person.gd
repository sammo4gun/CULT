extends Node2D

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

func create(wrld, pop, twn, hse):
	world = wrld
	population = pop
	town = twn
	house = hse
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	ground = pop.ground
	location = house.location[0]
	get_name()

func set_pos(location):
	position = ground.map_to_world(location)
	position.y += 45
	print("Drawing here:")
	print(location)
	print(position)
	print()

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

func square_and_back():
	set_pos(location)
	visible = true
	
	var path = pathfinding.walkRoadPath(location, town.get_town_square_loc(), town._mroads)
	path.invert()
	print(path)
