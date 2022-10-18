extends Node2D

func set_place(location, height, ground):
	self.position = ground.map_to_world(location)
	self.position.y += 22 - 16*height
	print(location)
