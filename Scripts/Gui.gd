extends MarginContainer

onready var number_label = $HBoxContainer/Bars/Bar/Count/Background/Number

onready var town = $"../../../Town"

var altitude
var buildings

func map_ready(alt, roads, builds):
	altitude = alt
	buildings = builds

func display(selection):
	var building = town.get_building(selection)
	
	number_label.text = str(selection)
	
	if building:
		number_label.text = str(building.house_name)
	
func rm_display():
	number_label.text = ''

func _on_Selector_new_selection(new_selected):
	if new_selected != null:
		display(new_selected)
	else:
		rm_display()
