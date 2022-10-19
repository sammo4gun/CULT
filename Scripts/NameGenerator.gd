extends Node

var FIRST_NAME = ["John", "Mark", "Jesse", "Leia", "Anne"]

var FIRST_HALF_NAMES = ["White", "Black", "Yellow", "Strong", "Small"]
var SECOND_HALF_NAMES = ["foot", "beard", "man", "singer", "john"]

var rng = RandomNumberGenerator.new()

func buildname():
	rng.randomize()
	var nm = ""
	
	nm += FIRST_NAME[rng.randi_range(0,4)] + " "
	nm += FIRST_HALF_NAMES[rng.randi_range(0,4)]
	nm += SECOND_HALF_NAMES[rng.randi_range(0,4)]
	
	return nm
