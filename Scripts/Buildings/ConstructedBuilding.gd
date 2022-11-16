extends "res://Scripts/Building.gd"

onready var lights = $HouseLights

var FLOOR_TYPES = ["ground", "first"]

# who live here
var inhabitants = []

# floors -> rooms
var rooms = {}

var contents = {}

# State variables
var lights_on = false

func _ready():
	can_enter = true
	contents["food"] = 5
	contents["clothes"] = 2
	._ready()

func set_inhabitant(person, is_owner):
	if is_owner:
		owners.append(person)
		house_name += ": " + person.string_name
	inhabitants.append(person)
	inside.append(person)

func remove_person(person):
	if person in owners:
		owners.erase(person)
	if person in inhabitants:
		inhabitants.erase(person)
	if person in inside:
		inside.erase(person)

func unmake():
	queue_free()

func get_inside():
	return inside

func is_proper():
	return true

func add_content(item, amount = 1):
	contents[item] = contents.get(item, 0) + amount

func turn_lights_on():
	lights_on = true
	lights.visible = true
	town.update_building(self, location[0])

func turn_lights_off():
	lights_on = false
	lights.visible = false
	town.update_building(self, location[0])

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

func set_sprite(tile, id):
	if len(location) == 1 and tile in location:
		sprite = id
		if sprite in LIGHT_MAP:
			light_sprite = LIGHT_MAP[id]
	else:
		sprites[tile] = id

func get_sprite(tile):
	if len(location) == 1 and tile in location:
		if lights_on:
			return light_sprite
		else: 
			return sprite
	else:
		return sprites[tile]
