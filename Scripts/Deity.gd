extends Control

signal make_cave

var cave = null
var string_name

var acolytes = []

onready var world = get_parent()
onready var transition = $"../TransitionScreen"
var Cave = preload("res://Scenes/Buildings/Cave.tscn")

func _ready():
	string_name = "Devil"

func make_cave(acolyte, cave_stats):
	var cave_loc = cave_stats[0]
	var cave_dirs = cave_stats[1]
	
	if world.in_anim:
		yield(world, "anim_over")
	
	cave = Cave.instance()
	
	world.drawer.add_child(cave)
	
	cave.cave_build(cave_loc, cave_dirs, world.drawer.get_pos(cave_loc)) 
	
	world.camera.jump_to_tile(cave_loc)
	world.selected_person(acolyte)
	acolytes.append(acolyte)
	emit_signal("make_cave", cave)

func get_cave_loc(person):
	var possibles = []
	for x in range(world.WIDTH-1):
		for y in range(world.HEIGHT-1):
			if world._mheight[Vector2(x,y)] == 1 and \
			   (world._mheight[Vector2(x,y+1)] == 0 or world._mheight[Vector2(x+1,y)] == 0):
				if person.house.location[0].distance_to(Vector2(x,y)) < person.town._center.distance_to(Vector2(x,y)):
					possibles.append(Vector2(x,y))
	
	var chosen_square
	var focused_house = person.house.location[0] #homeless different?
	var dist_range = [20, 30]
	while dist_range[0] > 0:
		# pick all squares that come within dist range to house
		var in_range_squares = []
		for square in possibles:
			var dist = focused_house.distance_to(square)
			if dist >= dist_range[0] and dist < dist_range[1]:
				in_range_squares.append(square)
		
		while in_range_squares:
			chosen_square = in_range_squares[world.rng.randi_range(0, len(in_range_squares)-1)]
			in_range_squares.erase(chosen_square)
			
			# check if the square can walk to the house no problem, if so, return
			if person.pathfinding.walkRoadPath(focused_house, [chosen_square], world._mbuildings, world._mroads, [1,2], false, person):
				var dirs = [] # can be 0 (E) or 1 (S) or both
				if world._mheight[Vector2(chosen_square.x,chosen_square.y+1)] == 0:
					dirs.append(1)
				if world._mheight[Vector2(chosen_square.x+1,chosen_square.y)] == 0:
					dirs.append(0)
				
				return [chosen_square, dirs]
			else: possibles.erase(chosen_square)
		
		dist_range[0] -= 4
		dist_range[1] += 4
	
	return false

func get_cave(location):
	if cave:
		if location in cave.location:
			return cave
	return null

func first_whispers(person) -> String:
	return "I see you, " + person.string_name + "... You shall serve me well."

func make_first_acolyte(person):
	var cave_stats = get_cave_loc(person)
	if cave_stats:
		world.play_ominous_message(first_whispers(person))
		make_cave(person, cave_stats)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_O and world.selector.selected_person:
			if not cave:
				make_first_acolyte(world.selector.selected_person)
