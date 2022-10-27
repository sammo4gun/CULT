extends Node2D

var type
var location
var house_name
var town_name
var town
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

var time_start = 0
var chance = 0.0

func _process(delta):
	if time_start > 0 and len(inside) > 0:
		if OS.get_unix_time()-time_start > 1:
			time_start = OS.get_unix_time()
			if town.rng.randf_range(0,1) < chance:
				# Send whoever is inside on a little walk
				inside[0].square_and_back()
				chance = 0.0
			else: 
				chance += 0.05

func build(twn, loc, nmg):
	time_start = OS.get_unix_time()
	town = twn
	town_name = twn.town_name
	location = loc
	name_generator = nmg

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

var selected = false

func enter(person):
	self.inside.append(person)
	if selected: town.get_parent().ping_gui()

func leave(person):
	self.inside.erase(person)
	if selected: town.get_parent().ping_gui()

func on_selected():
	selected = true

func on_deselected():
	selected = false
