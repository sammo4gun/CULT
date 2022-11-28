extends "res://Scripts/Building.gd"

onready var lights = $HouseLights

var FLOOR_TYPES = ["ground", "first"]

# who live here
var inhabitants = []

# floors -> rooms
var rooms = {}

var contents = {}

var rng =  RandomNumberGenerator.new()
var dir = [0,0,0,0]
var directional_sprites = {
	2: 19,
	3: 19,
	0: 16 + (rng.randi_range(0,1)*2),
	1: 17
}

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

func set_main_dir(dir):
	assert(len(location) == 1)
	sprite = directional_sprites[dir]
	if sprite in LIGHT_MAP:
		light_sprite = LIGHT_MAP[sprite]
	
	var difs = [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]
	add_entrance_tile(difs[dir] + location[0])

func get_sprite(tile):
	if len(location) == 1 and tile in location:
		if lights_on:
			return light_sprite
		else: 
			return sprite
	else:
		return sprites[tile]
