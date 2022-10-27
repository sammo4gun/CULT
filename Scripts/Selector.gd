extends Node2D

var selected_tile = null
var building = null

signal new_selection

onready var ground = get_node('/root/World/YDrawer/Ground')

func getSelected():
	return selected_tile

func setSelected(tile):
	selected_tile = tile[0]
	
	self.position = ground.map_to_world(selected_tile)
	self.position.y += 30 - 16*tile[1]
	self.visible = true
	
	building = $"../Towns".get_building(selected_tile)
	if building != null:
		building.on_selected()
	
	emit_signal("new_selection", selected_tile)

func deSelect():
	if building!= null:
		building.on_deselected()
		building = null
	
	self.selected_tile = null
	self.visible = false
	emit_signal("new_selection", selected_tile)
