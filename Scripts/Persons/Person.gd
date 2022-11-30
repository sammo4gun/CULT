extends "res://Scripts/Persons/Professions.gd"

# CREATION: Sets parents, owned house, starting house, and position
# Also calls make_thoughts() to figure out who this person is.
func create(wrld, pop, twn, hse) -> void:
	time_start = OS.get_unix_time()
	world = wrld
	population = pop
	town = twn
	house = hse
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	speeds = wrld.SPEEDS
	ground = pop.ground
	
	in_building = house
	location = house.location[0]
	create_name()
	position = ground.map_to_world(location)
	position.y += 45
	prevloc = location
	
	make_thoughts()

func destroy() -> void:
	queue_free()

# CREATION: Randomly generates what this person's job and personality is like.
func make_thoughts() -> void:
	# As the character starts at home, this calculates their path from home to
	# work to save processing time.
	var square_locations = town.get_town_square_loc()
	var square_dist = 0
	$Popup/Label.text = person_name[0] + '\n' + person_name[1]
	if square_locations:
		square_dist = len(get_path_to(square_locations))
		wake_up_time = 7 - int(square_dist / 10)
	else: 
		wake_up_time = 7

func set_work(prof):
	profession = prof
	update_profession()
	reconsider = true

func set_wakeup_time() -> void:
	var work = get_work.call_func()
	var square_dist = len(get_path_to_building(work))
	wake_up_time = 7 - int(square_dist / 10)

# CREATION: Makes the name of the player.
func create_name() -> void:
	var potname
	while true:
		potname = [namegenerator.person_first(), namegenerator.person_last()]
		if not population.name_exists(potname):
			person_name = potname
			for part in person_name:
				string_name += part + " "
			string_name = string_name.trim_suffix(" ")
			break

func _process(delta):
	if open:
		match activity:
			"home":
				# At home or want to go home.
				if in_building:
					if in_building == house:
						if not in_building.lights_on and day_time != "day":
							in_building.turn_lights_on()
						if day_time == "night":
							open = false
							asleep()
							activity = "sleep"
						if world_time >= wake_up_time and world_time <= 20 - (7 - wake_up_time):
							open = false
							prepare_to_leave()
							activity = "work"
					else:
						open = false
						go_building(house)
				else: 
					open = false
					go_building(house)
			"sleep":
				if in_building.lights_on: in_building.turn_lights_off()
				if day_time in ['day', 'dawn']: 
					open = false
					awaken()
					activity = "home"
				if world_time == 2:
					set_wakeup_time()
				if world_time >= wake_up_time and world_time <= 20 - (7 - wake_up_time):
					open = false
					awaken()
					activity = "home"
			"work":
				# At home and preparing to go to the square
				if in_building:
					if in_building != get_work.call_func():
						open = false
						go_path(get_path_to_building(get_work.call_func()))
					
					else:
						var square_time = 20 - (7 - wake_up_time)
						if world_time <= square_time:
							open = false
							work_activity()
						else: activity = "home"
				else: 
					open = false
					go_path(get_path_to_building(get_work.call_func()))
	._process(delta)

# BEHAVIOUR: Do whatever activity you consider "work"
func work_activity():
	yield(do_work.call_func(), "completed")
	open = true

func _input(event):
	if mouse_on:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				world.selected_person(self)
				get_tree().set_input_as_handled()

func _on_Area2D_mouse_entered():
	if not population.mouse_on:
		population.mouse_on = true
		$Popup.visible = true
		mouse_on = true

func _on_Area2D_mouse_exited():
	population.mouse_on = false
	$Popup.visible = false
	mouse_on = false

# UTILITY: On selected
func on_selected():
	display_emotion("surprise")
	selected = true
	selector.visible = true

# UTILITY: Not selected
func on_deselected():
	selected = false
	selector.visible = false

func _unhandled_input(event):
	if selected:
		if event is InputEventKey:
			if event.pressed and event.scancode == KEY_I:
				if profession == "farmer": set_work("none")
				elif profession == "none": set_work("farmer")
