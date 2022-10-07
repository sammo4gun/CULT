extends MarginContainer

onready var number_label = $HBoxContainer/Bars/Bar/Count/Background/Number

var altitude

func _ready():
	pass

func map_ready(w, h, alt):
	altitude = alt

func _on_Selector_new_selection(new_selected):
	if new_selected:
		number_label.text = str(altitude[new_selected])
	else:
		number_label.text = ''
