extends Node2D

var is_pressed = false
var character = false

onready var gui = get_parent()
onready var name_label = $MarginContainer/VBoxContainer/Name/Background/Label
onready var job_label = $MarginContainer/VBoxContainer/Job/Background/Label

func _ready():
	hide()
	position.x = get_viewport().size.x/2

func _process(_delta):
	if character:
		name_label.text = character.person_name[0] + '\n' + character.person_name[1]
		if character.profession == "none":
			job_label.text = "no job"
		else: job_label.text = character.profession

func deselect_person():
	if is_pressed:
		hide()
		is_pressed = false
	
func reselect_person():
	if is_pressed:
		character = gui.selected_person

func pressed():
	if not is_pressed and gui.selected_person: 
		show()
		character = gui.selected_person
		is_pressed = true
	else: 
		hide()
		character = false
		is_pressed = false

var mouse_on = false

func _input(event):
	if mouse_on:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				get_tree().set_input_as_handled()

func _on_Area2D_mouse_entered():
	mouse_on = true

func _on_Area2D_mouse_exited():
	mouse_on = false
