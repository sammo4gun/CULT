extends "res://Scripts/Buildings/ConstructedBuilding.gd"

func _ready():
	._ready()
	type = "residence"
	house_name = "Residence"
	BUILDING_LAYER = {1: true,  2: true}
	MULTI_ROAD =     {1: false, 2: true}
