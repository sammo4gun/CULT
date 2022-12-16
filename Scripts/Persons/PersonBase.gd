extends Node2D

export var SPEED = 60

signal movement_arrived
signal timer_finished
signal night_reset

onready var selector = $Selector
onready var bubble = $Thoughts
onready var feelings = {"happy": $Happy, \
						"surprise": $Surprise, \
						"sweat" : $Sweat, \
						"chat": $Chat}

var emotion_priority = ['happy', 'sweat', 'surprise', 'chat']
var current_emotion = null

onready var carrying_sprites = {
	"log": $Log
}

# 0 small, 1 med, 2 large
var carrying_capacity = {
	0: 5,
	1: 2,
	2: 1
}
var carrying = {}
var encumbered = false

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
var gender = ''
# Characteristics
# Appearance

# 2.
var town
var house
# Friends
var owned_properties = {}

var boss

# DIRECT STATE VARIABLES
var location
var in_building
var swimming = false

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
var world_time = 0.0
# night, dawn, day, dusk
var day_time = "night"

var prev_work_building

var prev_activity
var conversing = false
var engaging = false

var purs_casual_conv = false

var waiting_time = 0.0

func _time_update(_t):
	if waiting_time > 0.0:
		waiting_time -= 0.1
		if waiting_time <= 0.0:
			emit_signal("timer_finished")

func _process(delta):
	if world.get_time_paused(): 
		return
	if target_step != null and moving_to == null:
		if in_building:
			if not world.towns.get_building(target_step):
				leave_building()
			elif not world.towns.get_building(target_step) == in_building:
				leave_building()
		
		moving_to = ground.map_to_world(target_step)
		moving_to.y += 45
		adj_speed = calculate_speed(location, target_step)
		
		var rand_step = false
		if world.towns.get_building(target_step):
			if not world.towns.get_building(target_step).can_enter:
				rand_step = true
		elif not world.is_road_tile(target_step):
			rand_step = true
		if rand_step:
			var target_y = world.rng.randi_range(moving_to.y - 8, moving_to.y + 12)
			var target_x = world.rng.randi_range(moving_to.x - 10, moving_to.x + 10)
			moving_to = Vector2(target_x, target_y)
		
	if moving_to != null:
		position = position.move_toward(moving_to, delta * adj_speed * world.speed_factor)
		if position == moving_to:
			location = target_step
			target_step = null
			moving_to = null
			swimming = world.is_water(location)
			if world.towns.get_building(location):
				if not in_building or in_building != world.towns.get_building(location):
					yield(enter_building(), "completed")
			emit_signal("movement_arrived")

# UTILITY: Calculate speed from the speed factors of two travelling squares
func calculate_speed(loc, target):
	var adj = 1.0
	if encumbered:
		adj = adj * 0.5
	if swimming:
		adj = adj * 0.5
	if loc in town._mroads:
		if target in town._mroads:
			return SPEED * adj
		return SPEED*adj*0.8/speeds[world._mtype[target]]
	return SPEED*adj*0.6/speeds[world._mtype[loc]]

# EXECUTION: Displays an emotion for a random period of time
func display_emotion(feeling):
	if ( current_emotion and \
		 emotion_priority.find(current_emotion) < emotion_priority.find(feeling)) or \
		 not current_emotion:
		bubble.visible = true
		feelings[feeling].visible = true
		if current_emotion: 
			feelings[current_emotion].visible = false
		current_emotion = feeling
		
		# just a straight timer length
		yield(get_tree().create_timer(timer_length(0.3,0.6)), "timeout")
		
		feelings[feeling].visible = false
		if current_emotion == feeling:
			current_emotion = null
			bubble.visible = false

# EXECUTION: Enter the building on current square
func enter_building():
	assert(world._mbuildings[location] != 0)
	in_building = world.towns.get_building(location)
	in_building.enter(self)
	if in_building.can_enter:
		$MouseCollision/CollisionShape2D.disabled=true
		visible = false
		if day_time != 'day':
			in_building.turn_lights_on()
		yield(wait_time(10, 20), "completed")
	yield(get_tree(), "idle_frame")

# EXECUTION: Leaves the building on current square
func leave_building():
#	assert(world._mbuildings[location] != 0)
	if in_building.can_enter:
		if in_building.lights_on and len(in_building.inside) < 2:
			in_building.turn_lights_off()
		$MouseCollision/CollisionShape2D.disabled=false
		visible = true
	in_building.leave(self)
	in_building = false

func go_person(person):
	var path
	if person.target_step != null:
		path = pathfinding.walkRoadPath(location, [person.target_step], world._mbuildings, town._mroads, [1,2], false, self)
	else: path = pathfinding.walkRoadPath(location, [person.location], world._mbuildings, town._mroads, [1,2], false, self)
	yield(follow_path(path), "completed")
	open = true

func go_building(building):
	var path = pathfinding.walkToBuilding(location, building, in_building, world._mbuildings, town._mroads, [1,2], false, self)
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Head to a target after generating a path to that target
func go(target):
	var path = pathfinding.walkRoadPath(location, target, world._mbuildings, town._mroads, [1,2], false, self)
	yield(follow_path(path), "completed")
	open = true

# BEHAVIOUR: Follow a path to its completion
func go_path(path):
	yield(self.follow_path(path), "completed")
	open = true

# BEHAVIOUR: Take a few seconds to wake up / do other end of night stuff
func awaken():
	yield(wait_time(10, 30), "completed")
	# give a certain amount of time to wake up / do other end-of-night stuff
	open = true

# BEHAVIOUR: Take a few seconds to go to sleep / do other end of evening stuff
func asleep():
	yield(wait_time(10, 30), "completed")
	# give a certain amount of time to go to sleep / do other end-of-evening stuff
	open = true

# BEHAVIOUR: Take a few seconds to leave the house / do other end of morning stuff
func prepare_to_leave():
	yield(wait_time(10, 30), "completed")
	# give a certain amount of time to prepare for leaving to the square
	open = true

# UTILITY: Get a path to a target
func get_path_to(target):
	return pathfinding.walkRoadPath(location, target, world._mbuildings, town._mroads, [1,2], false, self)

func get_path_to_building(building):
	if typeof(building) == 19: # if its an array, it's actually not a building, do this
		return get_path_to(building)
	return pathfinding.walkToBuilding(location, building, in_building, world._mbuildings, town._mroads, [1,2], false, self)

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
		elif world.towns.get_building(location):
			if not in_building or in_building != world.towns.get_building(location):
				yield(enter_building(), "completed")
			
#	if world.towns.get_building(location):
#		yield(enter_building(), "completed")
	
	yield(get_tree(), "idle_frame")
	return true

func add_inv(item, amount = 1):
	var item_weight = population.get_weight(item)
	if can_carry(item_weight, amount):
		carrying[item] = carrying.get(item, 0) + amount
		inv_update()
		return true
	return false

func remove_inv(item, amount = 1):
	carrying[item] -= amount
	if carrying[item] <= 0: 
		carrying.erase(item)
	inv_update()

func can_carry(weight, amount):
	var available_capacity = {}
	for type in carrying_capacity:
		available_capacity[type] = carrying_capacity[type]
	for item in carrying:
		var item_weight = population.get_weight(item)
		available_capacity[item_weight] -= carrying[item]
	if available_capacity[weight] - amount >= 0:
		return true
	return false

func inv_update():
	var available_capacity = {}
	for type in carrying_capacity:
		available_capacity[type] = carrying_capacity[type]
	
	for item in carrying_sprites:
		carrying_sprites[item].visible = false
	
	for item in carrying:
		var item_weight = population.get_weight(item)
		available_capacity[item_weight] -= carrying[item]
		if available_capacity[item_weight] <= 0:
			encumbered = true
			break
		if item in carrying_sprites:
			carrying_sprites[item].visible = true
		encumbered = false

# place a given item in a given quantity into a building
func place_in(building, item, amount = null):
	assert(in_building==building)
	if boss:
		assert(in_building in [house, boss.house])
	else: 
		assert(in_building == house)
	assert(item in carrying)
	
	if amount == null:
		building.add_content(item, carrying[item])
		remove_inv(item, carrying[item])
	else:
		assert(amount <= carrying[item])
		building.add_content(item, amount)
		remove_inv(item, amount)

# Take a given item in a given quantity out of a building
func take_out(building, item, amount = 0):
	assert(in_building==building)
	if boss:
		assert(in_building in [house, boss.house])
	else: 
		assert(in_building == house)
	#assert(item in in_building.get_contents())
	
	var quant = min(building.get_contents().get(item, 0), amount)
	if quant > 0:
		# add contents to self
		if add_inv(item, quant):
			# remove contents from house
			building.remove_content(item, quant)
			return true
	if quant == 0:
		# add contents to self
		if add_inv(item, building.get_contents()[item]):
			# remove contents from house
			building.remove_content(item, building.get_contents()[item])
			return true
	return false

# UTILITY: Adds a piece of property to the player's owned_properties 
# dictionary.
func add_property(building) -> void:
	var type = building.get_type()
	if type in owned_properties:
		owned_properties[type].append(building)
	else:
		owned_properties[type] = [building]
	building.add_owner(self)

# BEHAVIOURS
# DROP_INV go to the house and drop whatever you are holding

# GET_WATER go to the riverside and get some water

# GET_FOOD get food... whatever it takes

# UTILITY: Doing a timer from range mini to maxi compensated for speed factor
func timer_length(mini, maxi = null) -> float:
	if maxi:
		return world.rng.randf_range(mini, maxi)/world.speed_factor
	return mini/world.speed_factor

func wait_time(mini, maxi = null):
	# wait time is given in minutes, max an hour
	if maxi: 
		waiting_time = stepify(world.rng.randf_range(
			range_lerp(mini, 0, 60, 0, 1), range_lerp(maxi, 0, 60, 0, 1)
		), 0.1 )
	else:
		waiting_time = stepify(range_lerp(mini, 0, 60, 0, 1), 0.1)
	yield(self, "timer_finished")
	return true

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
