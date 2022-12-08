extends Node

signal chosen_profession

var Person = preload("res://Scenes/Person.tscn")

var pop = []
var towns = []
var mouse_on = false

var working_on_squares = {}

onready var namegenerator = $"../NameGenerator"
onready var ydrawer = $"../YDrawer"
onready var ground = $"../YDrawer/Ground"
onready var world = $".."

func _time_update(time):
	for person in pop:
		person._time_update(time)

func random_person(excluded = [], profs = []):
	var potpers = []
	for pers in pop:
		if not pers in excluded:
			if len(profs) > 0:
				if pers.profession in profs:
					potpers.append(pers)
	if len(potpers) > 0:
		return potpers[world.rng.randi_range(0,len(potpers)-1)]
	return false

func make_person(town, house):
	# Determine the profession of the person based on the town. In this case,
	# Farmer if square_dist > 3 and world.rng.randf_range(0,1) > 0.8.
	var pers = Person.instance()
	
	var t = true
	for tile in town.get_town_square_loc():
		if house.get_location()[0].distance_to(tile) <= 3:
			t = false
			break
	
	if house.type == "center":
		pers.set_work("mayor")
	elif t and world.rng.randf_range(0,1) > 0.3:
		pers.set_work("farmer")
	elif world.rng.randf_range(0,1) > 0.7:
		pers.set_work("lumberjack")
	else: 
		pers.set_work("none")
	
	for loc in house.get_location():
		town.set_tile_owner(loc, pers)
	
	pers.create(world, self, town, house)
	emit_signal("chosen_profession", pers, pers.profession)
	
	house.set_inhabitant(pers, true)
	pop.append(pers)
	ydrawer.add_child(pers)
	if not town in towns:
		towns.append(town)

func replace_person(new_person, old_person):
	if old_person.house:
		for loc in old_person.house.get_location():
			old_person.town.set_tile_owner(loc, new_person)
		old_person.house.set_inhabitant(new_person, true)
	for type in old_person.owned_properties:
		for build in old_person.owned_properties[type]:
			for loc in build.get_location():
				old_person.town.set_tile_owner(loc, new_person)
	unmake_person(old_person)
	
	pop.append(new_person)
	ydrawer.add_child(new_person)
	
func unmake_person(person):
	assert(person in pop)
	if person.house:
		person.house.remove_person(person)
	pop.erase(person)
	person.destroy()

func set_working_on(location, person):
	working_on_squares[location] = person

func get_working_on(location):
	return working_on_squares.get(location, false)

func get_population():
	return pop

func name_exists(nm):
	for person in pop:
		if person.person_name == nm:
			return true
	return false
