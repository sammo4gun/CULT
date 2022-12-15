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
	set_main_dir(poss_directions[rng.randi_range(0, len(poss_directions)-1)])
	turn_lights_on()
