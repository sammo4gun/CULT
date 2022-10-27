extends Node

var rng = RandomNumberGenerator.new()

func random_choice(list):
	rng.randomize()
	return(list[rng.randi_range(0,len(list)-1)])

var FIRST_NAME = ["John", "Mark", "Jeremy", "Luke", "Micheal", "Jarko"] + ["Jesse"] + ["Leia", "Anne", "Anna", "Madeline", "Ruth"]

var FIRST_HALF_NAMES = ["White", "Black", "Yellow", "Strong", "Small", "Big", "Long", "Under", "Grim"]
var SECOND_HALF_NAMES = ["foot", "beard", "man", "singer", "john", "breath", "strider", "fish", "wood"]

func person():
	var nm = ""
	
	nm += random_choice(FIRST_NAME) + " "
	nm += random_choice(FIRST_HALF_NAMES)
	nm += random_choice(SECOND_HALF_NAMES)
	
	return nm

func person_first():
	return random_choice(FIRST_NAME)

func person_last():
	return random_choice(FIRST_HALF_NAMES) + random_choice(SECOND_HALF_NAMES)

var STORE = ["Clothing Shop", "Bakery", "Furniture Shop"]

func store():
	return random_choice(STORE)

var TOWN_START = ["Bloom", "Sickle", "Lake", "Wood", "Oar"]
var TOWN_END = ["send", " Town", "ton", " Place", "", "s Rest"]

func town():
	return random_choice(TOWN_START) + random_choice(TOWN_END)
