extends Node2D

var SPRITE_DICT

var BUILDING_LAYER
var MULTI_ROAD

var type
var location
var house_name
var name_generator
var town_name
var town

var map_connected = false
var entrance_tiles = []
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

func unmake():
	queue_free()

func get_location():
	assert(location[0])
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

func set_entrance(tile):
	entrance_tiles.append(tile)

func get_sprite(tile):
	return sprites[tile]

func is_proper():
	return false

func add_entrance_tile(tile):
	if not tile in entrance_tiles:
		entrance_tiles.append(tile)
	
	clean_entrance_tiles()

func clean_entrance_tiles():
	for tile in entrance_tiles:
		if (not town.world.is_road_tile(tile) and \
			not tile in town.get_town_square_loc()) or \
		   tile in location:
			entrance_tiles.erase(tile)

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
