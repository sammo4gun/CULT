extends "res://Scripts/Buildings/ConstructedBuilding.gd"

func _ready():
	type = "store"
	house_name = name_generator.store()
	._ready()
