extends Node

signal chosen_profession

var Person = preload("res://Scenes/Person.tscn")

var pop = []
var towns = []
var mouse_on = false

onready var namegenerator = $"../NameGenerator"
onready var ydrawer = $"../YDrawer"
onready var ground = $"../YDrawer/Ground"
onready var world = $".."
onready var behaviours = $Behaviours

func _hour_update(hour):
	for person in pop:
		person._hour_update(hour)

func make_person(town, house):
	var pers = Person.instance()
	for loc in house.location:
		town.set_tile_owner(loc, pers)
	pers.create(world, self, town, house, behaviours)
	house.set_inhabitant(pers, true)
	pop.append(pers)
	ydrawer.add_child(pers)
	if not town in towns:
		towns.append(town)

func unmake_person(person):
	assert(person in pop)
	if person.house:
		person.house.remove_person(person)
	pop.erase(person)
	person.destroy()

func name_exists(nm):
	for person in pop:
		if person.person_name == nm:
			return true
	return false

func chosen_profession(person, profession):
	emit_signal("chosen_profession", person, profession)
