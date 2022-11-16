extends "res://Scripts/Buildings/ConstructedBuilding.gd"

func _ready():
	._ready()
	type = "store"
	house_name = name_generator.store()
	BUILDING_LAYER = {1: true,  2: true}
	MULTI_ROAD =     {1: false, 2: true}
