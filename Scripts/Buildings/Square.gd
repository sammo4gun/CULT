extends "res://Scripts/Building.gd"

var SQUARE_DICT = {
	[0,1,1,0]: 39,
	[1,1,0,0]: 35,
	[1,1,1,0]: 36,
	[1,0,0,1]: 38,
	[0,1,1,1]: 34,
	[0,0,1,1]: 40,
	[1,1,1,1]: 37,
	[1,0,1,1]: 41,
	[1,1,0,1]: 33
	}

func _ready():
	._ready()
	type = "square"
	house_name = "Town Square"

func get_sprite(tile):
	return SQUARE_DICT[[1,1,1,1]]
