extends Node2D

var selected_tile = null

onready var ground = get_node('/root/World/Map/Ground')

func _ready():
	pass

func getSelected():
	return selected_tile

func setSelected(tile):
	selected_tile = tile[0]
	
	# now set location
	# formula for correct location is world_to_map(), then
	# y -= 48 + 16*level
	
	self.position = ground.map_to_world(selected_tile)
	self.position.y += 48 - 16*tile[1]
