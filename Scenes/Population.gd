extends Node

signal chosen_profession

var Person = preload("res://Scenes/Persons/Person.tscn")

var pop = []
var towns = []
var mouse_on = false

onready var namegenerator = $"../NameGenerator"
onready var ydrawer = $"../YDrawer"
onready var ground = $"../YDrawer/Ground"
onready var world = $".."

func _hour_update(hour):
	for person in pop:
		person._hour_update(hour)

func random_person():
	return pop[world.rng.randi_range(0,len(pop)-1)]

func make_person(town, house):
	# Determine the profession of the person based on the town. In this case,
	# Farmer if square_dist > 3 and world.rng.randf_range(0,1) > 0.8.
	
	var pers
	
	var t = true
	for tile in town.get_town_square_loc():
		if house.location[0].distance_to(tile) <= 3:
			t = false
			break
	
	if house.type == "center":
		pers = Person.instance()
		pers.set_work("mayor")
	elif t and world.rng.randf_range(0,1) > 0.8:
		pers = Person.instance()
		pers.set_work("farmer")
		# set to farmer
	else: 
		pers = Person.instance()
		pers.set_work("none")
		# set to unemployed
	
	for loc in house.location:
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
		for loc in old_person.house.location:
			old_person.town.set_tile_owner(loc, new_person)
		old_person.house.set_inhabitant(new_person, true)
	for type in old_person.owned_properties:
		for build in old_person.owned_properties[type]:
			for loc in build.location:
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

func get_population():
	return pop

func name_exists(nm):
	for person in pop:
		if person.person_name == nm:
			return true
	return false
