extends Node2D

var selected_tile = null
var selected_person = null
var building = null

signal selected_tile
signal selected_person

onready var ground = get_node('/root/World/YDrawer/Ground')

func getSelected():
	return selected_tile

func setSelected(tile):
	if selected_tile == tile[0]: return
	if selected_person != null:
		selected_person.on_deselected()
		selected_person = null
	
	selected_tile = tile[0]
	
	self.position = ground.map_to_world(selected_tile)
	self.position.y += 30 - 16*tile[1]
	self.visible = true
	
	building = $"../Towns".get_building(selected_tile)
	if building != null:
		building.on_selected()
	
	emit_signal("selected_tile", selected_tile)

func deSelect():
	if selected_person != null:
		selected_person.on_deselected()
		selected_person = null
	if building != null:
		building.on_deselected()
		building = null
	
	self.selected_tile = null
	self.visible = false
	emit_signal("selected_tile", selected_tile)

func selectPerson(person):
	if selected_person == person: return
	if selected_person != null:
		selected_person.on_deselected()
	if building!= null:
		building.on_deselected()
		building = null
	selected_tile = null
	visible = false
	selected_person = person
	selected_person.on_selected()
	
	emit_signal("selected_person", selected_person)
