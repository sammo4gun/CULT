extends Node2D

var type = 1
var location
var house_name

var rng = RandomNumberGenerator.new()

var FIRST_NAME = ["John", "Mark", "Jesse", "Leia", "Anne"]

var FIRST_HALF_NAMES = ["White", "Black", "Yellow", "Strong", "Small"]
var SECOND_HALF_NAMES = ["foot", "beard", "man", "singer", "john"]

func buildname():
	rng.randomize()
	var nm = ""
	
	nm += FIRST_NAME[rng.randi_range(0,4)] + " "
	nm += FIRST_HALF_NAMES[rng.randi_range(0,4)]
	nm += SECOND_HALF_NAMES[rng.randi_range(0,4)]
	
	return nm

func build(loc):
	location = loc
	house_name = buildname()

func get_location():
	return self.location

func set_type(id):
	type = id
	if id == 1:
		pass
	if id == 2:
		house_name = "Mayor " + house_name
