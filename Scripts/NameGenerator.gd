extends Node

var rng = RandomNumberGenerator.new()

var FIRST_NAME = ["John", "Mark", "Jesse", "Leia", "Anne"]

var FIRST_HALF_NAMES = ["White", "Black", "Yellow", "Strong", "Small"]
var SECOND_HALF_NAMES = ["foot", "beard", "man", "singer", "john"]

func person():
	rng.randomize()
	var nm = ""
	
	nm += FIRST_NAME[rng.randi_range(0,4)] + " "
	nm += FIRST_HALF_NAMES[rng.randi_range(0,4)]
	nm += SECOND_HALF_NAMES[rng.randi_range(0,4)]
	
	return nm

var STORE = ["Clothing Shop", "Bakery", "Furniture Shop"]

func store():
	rng.randomize()
	return STORE[rng.randi_range(0,2)]
