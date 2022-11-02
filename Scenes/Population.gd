extends Node

signal chosen_profession

var Person = preload("res://Scenes/Person.tscn")

var pop = []
var towns = []

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
	pers.create(world, self, town, house, behaviours)
	house.set_inhabitant(pers, true)
	pop.append(pers)
	for loc in house.location:
		town.set_tile_owner(loc, pers)
	ydrawer.add_child(pers)
	if not town in towns:
		towns.append(town)

func name_exists(nm):
	for person in pop:
		if person.person_name == nm:
			return true
	return false

func chosen_profession(person, profession):
	emit_signal("chosen_profession", person, profession)
