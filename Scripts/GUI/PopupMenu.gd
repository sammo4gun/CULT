extends MarginContainer

var is_pressed = false
onready var gui = $"../GUI"
var mouse_on = false

func _ready():
	hide()

func deselect():
	if is_pressed:
		hide()
		is_pressed = false
	
func _input(event):
	if mouse_on:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				get_tree().set_input_as_handled()

func _on_Area2D_mouse_entered():
	mouse_on = true

func _on_Area2D_mouse_exited():
	mouse_on = false
