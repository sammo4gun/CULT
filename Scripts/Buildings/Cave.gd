extends "res://Scripts/Buildings/ConstructedBuilding.gd"

func _ready():
	._ready()
	directional_sprites = {
		0: 75,
		1: 76
	}
	type = "cave"
	house_name = "Mysterious Cave"
	BUILDING_LAYER = {1: false,  2: false}
	MULTI_ROAD =     {1: false,  2: false}

func cave_build(location, poss_directions, pos):
	.build(null, [location], null, pos)
	var dir = poss_directions[rng.randi_range(0, len(poss_directions)-1)]
	set_main_dir(dir)
	set_light_dir(dir)
	turn_lights_on()

func set_light_dir(dir):
	if dir == 0:
		lights.rotation_degrees = 330
		lights.position += Vector2(10,5)
		pass # set light to face the east
	if dir == 1:
		lights.rotation_degrees = 30
		lights.position += Vector2(-10,5)
