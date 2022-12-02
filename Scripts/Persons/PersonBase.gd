extends Node2D

export var SPEED = 60

signal movement_arrived

onready var selector = $Selector
onready var bubble = $Thoughts
onready var feelings = {"happy": $Happy, "surprise": $Surprise, "sweat" : $Sweat}

var namegenerator
var population
var world
var pathfinding
var ground
var speeds
var selected = false

# There are two parts to creating a person: 1. their own stats and 2. the role they fill in the world.
# 1.
var person_name = []
var string_name = ""
# Characteristics
# Appearance

# 2.
var town
var house
# Friends
var owned_properties = {}

# 3. One-time calc variables

# DIRECT STATE VARIABLES
var location
var in_building

var activity = "home"

#UTILITY

var moving_to = null
var target_step = null
var prevloc = Vector2(0,0)
var adj_speed = SPEED

var time_start = 0
var chance = 0.0
var mouse_on = false

var open = true
# variable to force a single check
var reconsider = false
var world_time = 0
# night, dawn, day, dusk
var day_time = "night"

var prev_work_building

func _process(delta):
	if target_step != null and moving_to == null:
		moving_to = ground.map_to_world(target_step)
		moving_to.y += 45
		adj_speed = calculate_speed(location, target_step)
		if world.towns.get_building(target_step):
			if not world.towns.get_building(target_step).can_enter:
				var target_y = town.rng.randi_range(moving_to.y - 8, moving_to.y + 12)
				var target_x = town.rng.randi_range(moving_to.x - 10, moving_to.x + 10)
				moving_to = Vector2(target_x, target_y)
	
	if moving_to != null:
		position = position.move_toward(moving_to, delta * adj_speed * world.speed_factor)
		if position == moving_to:
			location = target_step
			target_step = null
			moving_to = null
			emit_signal("movement_arrived")

# UTILITY: Calculate speed from the speed factors of two travelling squares
func calculate_speed(loc, target):
	if loc in town._mroads:
		if target in town._mroads:
			return SPEED
		return SPEED*0.8/speeds[world._mtype[target]]
	return SPEED*0.6/speeds[world._mtype[loc]]

# EXECUTION: Displays an emotion for a random period of time
func display_emotion(feeling):
	if bubble.visible != true:
		bubble.visible = true
		feelings[feeling].visible = true
		
		yield(get_tree().create_timer(timer_length(0.3,0.6)), "timeout")
		
		bubble.visible = false
		feelings[feeling].visible = false

# EXECUTION: Enter the building on current square
func enter_building():
	assert(world._mbuildings[location] != 0)
	in_building = world.towns.get_building(location)
	in_building.enter(self)
	if in_building.can_enter:
		$Area2D/CollisionShape2D.disabled=true
		visible = false

# EXECUTION: Leaves the building on current square
func leave_building():
	assert(world._mbuildings[location] != 0)
	if in_building.can_enter:
		if in_building.lights_on and len(in_building.inside) < 2: 
			in_building.turn_lights_off()
		$Area2D/CollisionShape2D.disabled=false
		visible = true
	in_building.leave(self)
	in_building = false

func go_building(building):
	var path = pathfinding.walkToBuilding(location, building, in_building, world._mbuildings, town._mroads, [1,2], false)
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Head to a target after generating a path to that target
func go(target):
	var path = pathfinding.walkRoadPath(location, target, world._mbuildings, town._mroads, [1,2], false)
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Follow a path to its completion
func go_path(path):
	yield(self.follow_path(path), "completed")
	open = true

# BEHAVIOUR: Take a few seconds to wake up / do other end of night stuff
func awaken():
	yield(get_tree().create_timer(timer_length(0.5,3.0)), "timeout")
	# give a certain amount of time to wake up / do other end-of-night stuff
	open = true

# BEHAVIOUR: Take a few seconds to go to sleep / do other end of evening stuff
func asleep():
	yield(get_tree().create_timer(timer_length(1.0,6.0)), "timeout")
	# give a certain amount of time to go to sleep / do other end-of-evening stuff
	open = true

# BEHAVIOUR: Take a few seconds to leave the house / do other end of morning stuff
func prepare_to_leave():
	yield(get_tree().create_timer(timer_length(0.5,3.0)), "timeout")
	# give a certain amount of time to prepare for leaving to the square
	open = true

# UTILITY: Get a path to a target
func get_path_to(target):
	return pathfinding.walkRoadPath(location, target, world._mbuildings, town._mroads, [1,2], false)

func get_path_to_building(building):
	return pathfinding.walkToBuilding(location, building, in_building, world._mbuildings, town._mroads, [1,2], false)

# UTILITY: Setting the target square to each square following the path.
func follow_path(path) -> bool:
	assert(path[0] == location)
	if in_building:
		leave_building()
	
	for step in path:
		if reconsider:
			reconsider = false
			yield(get_tree(), "idle_frame")
			return true
		# instead of ugly jump, set it to be a smooth transition from current location to the next step.
		if location != step:
			target_step = step
			yield(self, "movement_arrived")
	
	if world.towns.get_building(location):
		enter_building()
	
	yield(get_tree(), "idle_frame")
	return true

# UTILITY: Adds a piece of property to the player's owned_properties 
# dictionary.
func add_property(building) -> void:
	var type = building.get_type()
	if type in owned_properties:
		owned_properties[type].append(building)
	else: 
		owned_properties[type] = [building]
	building.add_owner(self)

# UTILITY: Update hour times
func _hour_update(hour):
	world_time = hour
	if world_time < 6 or world_time > 21:
		day_time = "night"
	elif world_time < 8:
		day_time = "dawn"
	elif world_time < 18:
		day_time = "day"
	elif world_time < 21:
		day_time = "dusk"

# UTILITY: Doing a timer from range mini to maxi compensated for speed factor
func timer_length(mini, maxi) -> float:
	if maxi:
		return world.rng.randf_range(mini, maxi)/world.speed_factor
	return mini/world.speed_factor

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

# TEMPORARY SOCIALISING FUNCTIONS (WILL HAVE TO BE MOVED TO PROPER PLACE)

func get_random_social(profs = []):
	assert(in_building) #or on same/adjacent location?
	var poss_people = []
	for pers in in_building.inside:
		if pers != self and pers.profession in profs:
			poss_people.append(pers)
	
	if len(poss_people) > 0:
		return poss_people[world.rng.randi_range(0,len(poss_people)-1)]
	return false

var conversing = false

func receive_q(from_person, q):
	yield(get_tree(), "idle_frame")
	return true

func engage_conversation(target_person, qs):
	conversing = target_person
	target_person.conversing = self
	for q in qs:
		# ask that question
		yield(target_person.receive_q(self, q), "completed")

func req_converse(target_person, qs):
	if target_person.rec_converse(self, qs):
		yield(engage_conversation(target_person, qs), "completed")
		return true
	else: 
		return false

func rec_converse(from_person, qs):
	if not conversing:
		return true #we always want to talk!
	else: return false
