extends Node2D

export var SPEED = 60

signal movement_arrived

onready var selector = $Selector
onready var bubble = $Thoughts
onready var feelings = {"happy": $Happy, "surprise": $Surprise}

var namegenerator
var population
var world
var pathfinding
var ground

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
# Job/Role

# DIRECT STATE VARIABLES
var location
var in_building
var on_square

var activity = "home"

var moving_to = null
var target_step = null
var prevloc = Vector2(0,0)

var time_start = 0
var chance = 0.0

var open = true
var world_time
func _process(delta):
	if open:
		world_time = world.get_time()
		if world_time['hour'] < 6 or world_time['hour'] > 18:
			activity = 'home'
		else: activity = 'square'
		match activity:
			"home":
				# At home or want to go home.
				if in_building:
					pass
				if on_square:
					open = false
					go(house.location)
			"square":
				# At home and feel like going to the square
				if in_building:
					if OS.get_unix_time()-time_start > 1:
						time_start = OS.get_unix_time()
						if town.rng.randf_range(0,1) < chance:
							# Send whoever is inside on a little walk
							open = false
							go(town.get_town_square_loc())
							chance = 0.0
						else: 
							chance += 0.05
				# On the square and having fun
				if on_square:
					open = false
					square_activity()
	
	if target_step != null and moving_to == null:
		moving_to = ground.map_to_world(target_step)
		moving_to.y += 45
		if world.towns.get_building(target_step):
			if world.towns.get_building(target_step).type == 3:
				var target_y = town.rng.randi_range(moving_to.y - 8, moving_to.y + 12)
				var target_x = town.rng.randi_range(moving_to.x - 10, moving_to.x + 10)
				moving_to = Vector2(target_x, target_y)
	
	if moving_to != null:
		position = position.move_toward(moving_to, delta*SPEED)
		if position == moving_to:
			location = target_step
			target_step = null
			moving_to = null
			emit_signal("movement_arrived")
	
func create(wrld, pop, twn, hse):
	time_start = OS.get_unix_time()
	world = wrld
	population = pop
	town = twn
	house = hse
	in_building = house
	namegenerator = wrld.namegenerator
	pathfinding = wrld.pathfinding
	ground = pop.ground
	location = house.location[0]
	get_name()
	position = ground.map_to_world(location)
	position.y += 45
	prevloc = location

func get_name():
	var potname
	while true:
		potname = [namegenerator.person_first(), namegenerator.person_last()]
		if not population.name_exists(potname):
			person_name = potname
			for part in person_name:
				string_name += part + " "
			string_name = string_name.trim_suffix(" ")
			break

func display_emotion(feeling):
	if bubble.visible != true:
		bubble.visible = true
		feelings[feeling].visible = true
		
		yield(get_tree().create_timer(world.rng.randf_range(0.3,0.6)), "timeout")
		
		bubble.visible = false
		feelings[feeling].visible = false

func enter_building():
	assert(world._mbuildings[location] != 0)
	in_building = world.towns.get_building(location)
	in_building.enter(self)
	in_building.turn_lights_on()
	$Area2D/CollisionShape2D.disabled=true
	visible = false

func leave_building():
	assert(world._mbuildings[location] != 0)
	in_building.leave(self)
	in_building.turn_lights_off()
	in_building = false
	$Area2D/CollisionShape2D.disabled=false
	visible = true

func follow_path(path):
	assert(path[0] == location)
	if in_building:
		leave_building()
	if on_square:
		on_square = false
	
	for step in path:
		# instead of ugly jump, set it to be a smooth transition from current location to the next step.
		if location != step:
			target_step = step
			yield(self, "movement_arrived")
	
	if world.towns.get_building(location):
		if world.towns.get_building(location).can_enter:
			enter_building()
		else: on_square = true
	
	return true

func square_enjoyer():
	assert(world.towns.get_building(location).type == 3)
	yield(get_tree().create_timer(1.0), "timeout")
	
	var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), null, Vector2(0,0)]
	var step
	var building
	while true:
		step = choices[world.rng.randi_range(0,5)]
		if step == null:
			break
		building = world.towns.get_building(location + step)
		if building:
			if building.type == 3:
				var target = location + step
				target_step = target
				yield(self, "movement_arrived")
		
		if world.rng.randf_range(0,1) > 0.5:
			display_emotion("happy")
		#yield(tile_enjoyer(1.5), "completed")
		yield(get_tree().create_timer(1.0), "timeout")
	
	return true

func go(target):
	var path = pathfinding.walkRoadPath(location, target, town._mroads)
	yield(follow_path(path), "completed")
	open = true

# only call this if on a square
func square_activity():
	yield(square_enjoyer(), "completed")
	open = true

func on_selected():
	display_emotion("surprise")
	selector.visible = true
	
func on_deselected():
	selector.visible = false

var mouse_on = false

func _input(event):
	if mouse_on:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				world.selected_person(self)
				get_tree().set_input_as_handled()

func _on_Area2D_mouse_entered():
	mouse_on = true

func _on_Area2D_mouse_exited():
	mouse_on = false
