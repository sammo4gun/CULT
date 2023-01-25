extends Control

signal make_cave

var cave = null
var string_name

var acolytes = []
var first = false

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

var DEVIL_PROPHETIC_DREAMS = {
	"envy": "{f} dreamt of a land where a huge grey snake had eaten everything and everyone - all of {t} had been consumed by it, and it was coming for {f}'s house, next. As the snake bore down upon them, {f} could hear the voices of their townmates speaking to them through the fog, as if screaming in pain, or perhaps... delight? Before they could find out, the snake averted its path, and {f} awoke in a cold sweat. The vision left them confused - and before long, their mind was reeling with visions of an ancient cave thrumming with energy...",
	"sloth": "{f} would awake that morning to a feeling of contentment. The sheets upon their skin were silky smooth, their breakfast tasted divine, and even the sun seemed to bear down on them in magnificent delicacy. But stepping outside, the cold wind stripped them of their comfort, and the world seemed as cruel as ever. The first taste of bitterness had touched {f}'s heart - but that bitterness would soon be replaced by visions of an ancient cave thrumming with energy...",
	"greed": "{f} dreamt of a barren desert, where water was as precious as gold. In this scorched land, the barrel of water on their back was their salvation, and they used it to survive every day. But no matter how much they filled it, over time the water would all vanish, to the sun, to the vultures, or to their own thirst. They awoke parched, their head swimming from dehydration. The fear of the dream would chase them all morning, but would soon be replaced by visions of an ancient cave thrumming with energy...",
	"wrath": "{f} dreamt of a silent world of loneliness. They looked around for the light, their friends, anything, but found only ashen trees and broken homes. When they finally did find people, they were laughing and singing - but they could not hear {f}, and would not even look at him. His heart sank as far as it could go, and he felt himself choke on a sea of anguish and bitter resentment. \n \n Come morning, all that was left was an aching emptiness, and visions of an ancient cave thrumming with energy...",
	"gluttony": "{f} dreamt of an apple hidden away in an orchard, its red flesh beaming at them, tantalizing. Every time {f} would come closer, the apple would drift away, from branch to branch, twig to twig. When they finally grabbed it, felt their teeth pierce its glorious skin, the taste of blood and puss filled their mouth. They awoke gasping - and famished. The apple had been false, but {f} knew it could not be far - their mind reeled with visions of an ancient cave thrumming with energy...",
	"lust": "{f} awoke early that morning to a touch more gentle than they had ever known. It filled them with warmth, an exquisite kind of love they had believed to be impossible. Looking into the eyes of the person that awoke them, their eyes fell upon a skeletally thin figure with bony appendages, its eyes regarding him with a thrumming orange hue. {f} was aghast, but the figure was gone before their mind could even comprehend it. Only an aching emptiness remained, along with strange memories of an ancient cave thrumming with energy...",
	"pride": "{f} dreamt of a dark world devoid of colour and life. A mountain of broken idols lay at their feet, all staring up at them with shrivelled eyes that begged for release. They found themselves laughing at the broken land that surrounded them, for within it the wills of men and beasts were like twigs in their grip. \n \n Come morning, all that was left was an aching emptiness, and visions of an ancient cave thrumming with energy..."
}

func first_whispers(person) -> String:
	return "I see you, {n}. You shall serve me well.".format({"n": person.string_name})
	
#	var chosen_sin = ["envy", "sloth", "greed", "wrath", "gluttony", "lust", "pride"][world.rng.randi_range(0, 6)]
#
#	return DEVIL_PROPHETIC_DREAMS[chosen_sin].format({"n": person.string_name, \
#													  "f": person.person_name[0], \
#													  "l": person.person_name[1], \
#													  "t": person.town.town_name})

func make_first_acolyte(person):
	first = true
	var cave_stats = get_cave_loc(person)
	if cave_stats:
		print('gonna work')
		yield(person, "night_reset")
		world.play_ominous_message(first_whispers(person))
		make_cave(person, cave_stats)
	else:
		print('not gonna work')
		first = false

func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_O and world.selector.selected_person:
			if not first:
				make_first_acolyte(world.selector.selected_person)
