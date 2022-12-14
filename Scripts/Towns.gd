extends Node

signal refresh

onready var map = $"../Map"

func _hour_update(time):
	for town in get_children():
		town._hour_update(time)

# Either returns the name of a town or the name of a person 
func get_owner_obj(tile):
	for town in get_children():
		var own = town.get_tile_owner(tile)
		if own: return own
	return null

func get_building(location):
	for town in get_children():
		if town.get_building(location):
			return(town.get_building(location))
	return get_parent().get_cave(location)

func has_building(location):
	for town in get_children():
		if town.get_building(location):
			return true
	return false

func get_proper_building(location):
	for town in get_children():
		var b = town.get_building(location)
		if b:
			if b.is_proper():
				return b
	return null

func get_road(location):
	for town in get_children():
		if town.get_road(location):
			return town.town_name

func building_exists(house):
	for town in get_children():
		for building in town.get_children():
			if building.house_name == house:
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

func get_full_building(loc):
	for town in get_children():
		if loc in town._mbuildings:
			return town._mbuildings[loc].get_location()

func map_get_building_connected(loc):
	for town in get_children():
		if loc in town._mbuildings:
			return town._mbuildings[loc].map_connected

func map_set_building_connected(loc, from):
	for town in get_children():
		if loc in town._mbuildings:
			town._mbuildings[loc].map_connected = true
			town._mbuildings[loc].add_entrance_tile(from)
			return

func map_set_building_disconnected(loc):
	for town in get_children():
		if loc in town._mbuildings:
			town._mbuildings[loc].map_connected = false
			town._mbuildings[loc].clean_entrance_tiles()
			return

func get_rand_town_center():
	if get_children():
		return get_children()[get_parent().rng.randi_range(0,len(get_children())-1)]._center
	else: return Vector2(get_parent().WIDTH/2, get_parent().LENGTH/2)

func get_pos(location):
	return map.get_pos(location[0])

func ping_gui():
	emit_signal("refresh")

func update_building(location, building):
	map.refresh_building(location, building)

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
