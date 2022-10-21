extends Node

func get_building(location):
	for town in get_children():
		if town.get_building(location):
			return(town.get_building(location))

func check_ownership(location):
	for town in get_children():
		if location in town._mroads:
			return town
		if location in town._mbuildings:
			return town
	return false
