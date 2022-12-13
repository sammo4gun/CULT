extends "res://Scripts/Persons/Professions.gd"

# CREATION: Sets parents, owned house, starting house, and position
# Also calls make_thoughts() to figure out who this person is.
func create(wrld, pop, twn, hse) -> void:
	world = wrld
	population = pop
	town = twn
	house = hse
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	speeds = wrld.SPEEDS
	ground = pop.ground
	
	in_building = house
	location = house.get_location()[0]
	create_name()
	position = ground.map_to_world(location)
	position.y += 45
	prevloc = location
	
	prev_work_building = get_work.call_func()
	
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
		travel_time = stepify(square_dist / 10.0, 0.1)
	else: 
		travel_time = 0.5

# UTILITY: Update hour times
func _time_update(t):
	world_time = t
	if world_time < 6.0 or world_time > 21.0:
		day_time = "night"
	elif world_time < 8.0:
		day_time = "dawn"
	elif world_time < 18.0:
		day_time = "day"
	elif world_time < 21.0:
		day_time = "dusk"
	
	if world_time == 2.0:
		set_travel_time()
		day_reset.call_func()
		day_reset_social()
	._time_update(t)

func set_work(prof, bs = null):
	boss = bs
	profession = prof
	update_profession()
	if town: 
		set_travel_time()
	reconsider = true

func set_travel_time() -> void:
	var work = get_work.call_func()
	
	var needs_redoing = false
	if typeof(work) != typeof(prev_work_building):
		needs_redoing = true
	elif work != prev_work_building:
		needs_redoing = true
	
	if needs_redoing:
		var work_dist = 0
		if typeof(work) == 17:
			work_dist = len(pathfinding.walkToBuilding(house.get_location()[0], work, house, world._mbuildings, town._mroads, [1,2], false))
		if typeof(work) == 19:
			work_dist = len(pathfinding.walkRoadPath(house.get_location()[0], work, world._mbuildings, town._mroads, [1,2], false))
		travel_time = int(work_dist / 10)
		prev_work_building = work

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
	if world.get_time_paused(): 
		return
	if open:
		reconsider = false
		match activity:
			"home":
				# At home or want to go home.
				if is_at_home():
					if not in_building.lights_on and day_time != "day":
						in_building.turn_lights_on()
					if in_building.lights_on and day_time == 'day':
						in_building.turn_lights_off()
					if day_time == "night":
						open = false
						asleep()
						activity = "sleep"
					if world_time >= max(2.0, 7.0 - travel_time) and \
					   world_time <= 20.0 - travel_time and \
					   not work_done:
						open = false
						prepare_to_leave()
						activity = "work"
				else: 
					open = false
					go_building(house)
			"sleep":
				if in_building.lights_on: 
					in_building.turn_lights_off()
				if day_time in ['day', 'dawn']:
					open = false
					awaken()
					activity = "home"
				if world_time > max(2.0, 7.0 - travel_time) and \
				   world_time <= 20.0 - travel_time:
					open = false
					awaken()
					activity = "home"
			"work":
				# At home and preparing to go to the square
				if work_done:
					activity = "home"
				elif is_at_work():
					open = false
					work_activity()
				else:
					open = false
					go_path(get_path_to_building(get_work.call_func()))
			"conversing":
				if engaging and share_square(conversing):
					open = false
					var t = pick_topic(conversing)
					if t:
						if not present_q(conversing, t):
							end_conv(conversing) # conversation got ended
					else:
						end_conv(conversing) # no topic to talk about
				elif engaging:
					open = false
					go_person(conversing)
				else: 
					open = false
	
	._process(delta)

# BEHAVIOUR: Do whatever activity you consider "work"
func work_activity():
	yield(do_work.call_func(), "completed")
	open = true

func share_square(person):
	return location == person.location

func is_at_home():
	if in_building:
		if in_building == house:
			return true
	return false

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
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_X:
			if selected: 
				print(string_name)
				print(activity)
				print(open)
				print(conversing)
				print(in_building)
				print(get_work.call_func())
				print()

