extends "res://Scripts/Persons/Person.gd"

# This function will have behaviours and specific functions for farmers

func make_thoughts():
	.make_thoughts()
	profession = "farmer"

func get_required_help(farms) -> Dictionary:
	var help_dict = {}
	for farm in farms:
		help_dict[farm] = farm.required_workers
	return help_dict

func get_work():
	if "farm" in owned_properties:
		var chosen_farm = owned_properties["farm"][world.day % len(owned_properties['farm'])]
		return chosen_farm

func make_slave():
	var person = population.random_person()
	print(person.string_name)
	person.change_type("farmer")

func work_enjoyer():
	if not in_building.is_watered(location):
		in_building.water(location)
		display_emotion("sweat")
		yield(get_tree().create_timer(timer_length(2.0,4.0)), "timeout")
	else:
		var to_water = []
		for tile in get_work().location:
			if not in_building.is_watered(tile):
				to_water.append(tile)
		var dist = 9999
		if len(to_water) < 1:
			to_water = get_work().location
		var go_tile
		for tile in to_water:
			if location.distance_to(tile) < dist:
				go_tile = tile
				dist = location.distance_to(tile)
		target_step = go_tile
		yield(self, "movement_arrived")

func _unhandled_input(event):
	if selected:
		if event is InputEventKey:
			if event.pressed and event.scancode == KEY_I:
				make_slave()
