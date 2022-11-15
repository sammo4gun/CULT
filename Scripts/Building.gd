extends Node2D

var type
var location
var house_name
var name_generator
var town_name
var town

var map_connected = false
var can_enter = false
var selected = false

var sprites = {}

# list of owners of the building
var owners = []

# list of people that are currently inside the building
var inside = []

var TYPES = {
	"residence": 1,
	"center": 2,
	"square": 3,
	"store": 4,
	"farm": 5
}

func _ready():
	pass

func _hour_update(_time):
	pass

func build(twn, loc, nmg, pos):
	town = twn
	town_name = twn.town_name
	location = loc
	name_generator = nmg
	position = pos
	for tile in location:
		sprites[tile] = 4

func destroy():
	pass

func get_location():
	return self.location

func get_id():
	return TYPES[type]

func get_type():
	return type

func is_type(ty):
	if type == ty: return true
	return false

func add_owner(person):
	if not person in owners: 
		owners.append(person)
		if len(owners) == 1:
			house_name += ": " + person.string_name

func set_sprite(tile, id):
	sprites[tile] = id

func get_sprite(tile):
	return sprites[tile]

func is_proper():
	return false

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
