extends MarginContainer

var is_pressed = false
var character = false

onready var gui = $"../GUI"
onready var name_label = $MarginContainer/VBoxContainer/Name/Background/Label
onready var job_label = $MarginContainer/VBoxContainer/Job/Background/Label

func _ready():
	hide()

func _process(_delta):
	if character:
		name_label.text = character.person_name[0] + '\n' + character.person_name[1]
		if character.profession == "none":
			job_label.text = "no job"
		else: job_label.text = character.profession

func deselect():
	if is_pressed:
		hide()
		is_pressed = false
	
func reselect(person):
	if not person:
		deselect()
	elif is_pressed:
		character = person
		
func pressed(person):
	if not is_pressed and person: 
		show()
		character = person
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
