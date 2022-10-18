extends Node2D

var selected_tile = null

signal new_selection

onready var ground = get_node('/root/World/YDrawer/Ground')

func getSelected():
	return selected_tile

func setSelected(tile):
	selected_tile = tile[0]
	
	self.position = ground.map_to_world(selected_tile)
	self.position.y += 30 - 16*tile[1]
	self.visible = true
	emit_signal("new_selection", selected_tile)

func deSelect():
	self.selected_tile = null
	self.visible = false
	emit_signal("new_selection", selected_tile)
