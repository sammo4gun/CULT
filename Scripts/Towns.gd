extends Node

signal refresh

onready var map = $"../Map"

# Either returns the name of a town or the name of a person 
func get_owner_obj(tile):
	for town in get_children():
		var own = town.get_tile_owner(tile)
		if own: return own
	return false

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

func map_get_building_connected(loc):
	for town in get_children():
		if loc in town._mbuildings:
			return town._mbuildings[loc].map_connected

func map_set_building_connected(loc):
	for town in get_children():
		if loc in town._mbuildings:
			town._mbuildings[loc].map_connected = true
			return

func get_pos(location):
	return map.get_pos(location[0])

func ping_gui():
	emit_signal("refresh")
	
func update_building(location, value):
	map.update_building(location, value)

func _on_Population_chosen_profession(person, prof):
	match prof:
		"farmer": 
			if get_parent().rng.randf_range(0,1) < 0.8: 
				person.town.build_farm(person, 2)
			else: 
				person.town.build_farm(person, 3)
		"shopkeep":
			pass
		"mayor":
			pass
		"none":
			pass
