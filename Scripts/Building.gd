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

# State variables
var lights_on = true

var TYPES = {
	"residential": 1,
	"center": 2,
	"square": 3,
	"store": 4,
	"tavern": 5
}

func build(twn, loc, nmg):
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


func turn_lights_on():
	lights_on = true
	town.update_building(self)

func turn_lights_off():
	lights_on = false
	town.update_building(self)

var LIGHT_MAP = {
	16: 45,
	17: 46,
	18: 47,
	19: 48,
	20: 42,
	21: 43,
	22: 44
}
var sprite = 16
var light_sprite = 45

func set_sprite(id):
	sprite = id
	if sprite in LIGHT_MAP:
		light_sprite = LIGHT_MAP[id]

func get_sprite():
	if lights_on: return light_sprite
	else: return sprite

func on_selected():
	selected = true

func on_deselected():
	selected = false
