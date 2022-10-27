extends Node

signal refresh

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

func ping_gui():
	emit_signal("refresh")