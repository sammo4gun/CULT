extends "res://Scripts/Buildings/ConstructedBuilding.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	._ready()
	type = "center"
	house_name = "Mayors House"
	BUILDING_LAYER = {1: true,  2: true}
	MULTI_ROAD =     {1: true,  2: true}


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
