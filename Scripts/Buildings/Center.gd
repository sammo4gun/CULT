extends "res://Scripts/Buildings/ConstructedBuilding.gd"

func _ready():
	._ready()
	directional_sprites = {
		2: 20,
		3: 20,
		0: 22,
		1: 21
	}
	type = "center"
	house_name = "Mayors House"
	BUILDING_LAYER = {1: true,  2: true}
	MULTI_ROAD =     {1: true,  2: true}
