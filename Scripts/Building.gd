extends Node2D

onready var lights = $HouseLights

var type
var location
var house_name

var town_name
var town

var name_generator
var can_enter = true

# owners of the building
var owners = []

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
	"farm": 5
}

func build(twn, loc, nmg, pos):
	town = twn
	town_name = twn.town_name
	location = loc
	name_generator = nmg
	position = pos

func get_location():
	return self.location

func get_id():
	return TYPES[type]

func get_type():
	return type

func is_type(ty):
	if type == ty: return true
	return false

func set_type(ty):
	type = ty
	match type:
		"residential": house_name = "Residence"
		"center": house_name = "Mayors House"
		"square":
			house_name = "Town Square"
			can_enter = false
		"store": house_name = name_generator.store()
		"farm": house_name = "Farm"

func add_owner(person):
	if not person in owners: 
		owners.append(person)
		if len(owners) == 1:
			house_name += ": " + person.string_name

func set_inhabitant(person, is_owner):
	if is_owner:
		owners.append(person)
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
	lights.visible = true
	town.update_building(self)

func turn_lights_off():
	lights_on = false
	lights.visible = false
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
