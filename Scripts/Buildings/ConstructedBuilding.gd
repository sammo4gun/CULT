extends "res://Scripts/Building.gd"

onready var lights = $HouseLights

var FLOOR_TYPES = ["ground", "first"]

# who live here
var inhabitants = []

# floors -> rooms
var rooms = {}

# State variables
var lights_on = false

func _ready():
	can_enter = true
	._ready()

func set_inhabitant(person, is_owner):
	if is_owner:
		owners.append(person)
		house_name += ": " + person.string_name
	inhabitants.append(person)
	inside.append(person)

func is_proper():
	return true

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
