extends Node2D

var type
var location
var house_name
var town_name
var name_generator

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
		house_name = name_generator.person() + " Residence"
	if type == 2:
		house_name = "Mayor " + name_generator.person()
	if type == 3:
		house_name = "Town Square"
	if type == 4:
		house_name = name_generator.store() + " of " + name_generator.person()
