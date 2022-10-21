extends Node

func get_building(location):
	for child in get_children():
		if child.get_building(location):
			return(child.get_building(location))

func check_ownership(location):
	for town in get_children():
		if location in town._mroads:
			return town
	return false
