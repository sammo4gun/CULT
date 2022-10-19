extends Node2D

var type
var location
var house_name

var TYPES = {
	"residential": 1,
	"center": 2,
	"square": 3
}

func build(loc):
	location = loc

func get_location():
	return self.location

func set_type(ty):
	type = TYPES[ty]
	if type == 1:
		house_name = $NameGenerator.buildname()
	if type == 2:
		house_name = "Mayor " + $NameGenerator.buildname()
	if type == 3:
		house_name = "Town Square"
