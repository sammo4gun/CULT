extends Node2D

var type
var location
var house_name
var town_name
var name_generator
var can_enter = true

# who live here
var inhabitants = []

# who are currently here
var inside = []

var TYPES = {
	"residential": 1,
	"center": 2,
	"square": 3,
	"store": 4,
	"tavern": 5
}

func build(loc, nmg):
	location = loc
	name_generator = nmg

func set_town(town):
	town_name = town

func get_location():
	return self.location

func is_type(ty):
	if ty in TYPES:
		if TYPES[ty] == type:
			return true
	return false

func set_type(ty):
	type = TYPES[ty]
	if type == 1:
		house_name = "Residence"
	if type == 2:
		house_name = "Mayors House"
	if type == 3:
		house_name = "Town Square"
		can_enter = false
	if type == 4:
		house_name = name_generator.store()

func set_inhabitant(person, is_owner):
	if is_owner:
		house_name += ": " + person.string_name
	inhabitants.append(person)
	inside.append(person)

func enter(person):
	self.inside.append(person)

func leave(person):
	self.inside.erase(person)

func on_selected():
	if len(inside) > 0:
		# Send an inhabitant on a lil walk
		inside[0].square_and_back()
