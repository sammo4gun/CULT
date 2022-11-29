extends "res://Scripts/Buildings/Building.gd"

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
	BUILDING_LAYER = {1: true, 2: false}
	MULTI_ROAD = 	 {1: true, 2: false}

func get_sprite(tile):
	var dirs = [0,0,0,0]
	var i = 0
	for dif in [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]:
		if tile + dif in location:
			dirs[i] = 1
		i += 1
	return SQUARE_DICT[dirs]
