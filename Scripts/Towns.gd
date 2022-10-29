extends Node

signal refresh

onready var map = $"../Map"

func get_building(location):
	for town in get_children():
		if town.get_building(location):
			return(town.get_building(location))

func get_road(location):
	for town in get_children():
		if town.get_road(location):
			return town.town_name

func building_exists(house):
	for town in get_children():
		for building in town.get_children():
			if building.house_name==house:
				return true
	return false

func town_exists(house):
	for town in get_children():
		for building in town.get_children():
			if building.house_name==house:
				return true
	return false

func check_ownership(location):
	for town in get_children():
		if location in town._mroads:
			return town
		if location in town._mbuildings:
			return town
	return false

func get_pos(location):
	return map.get_pos(location[0])

func ping_gui():
	emit_signal("refresh")
	
func update_building(location, value):
	map.update_building(location, value)

func _on_Population_chosen_profession(person, prof):
	match prof:
		"farmer": 
			person.town.build_farm(person)
		"shopkeep":
			pass
		"mayor":
			pass
