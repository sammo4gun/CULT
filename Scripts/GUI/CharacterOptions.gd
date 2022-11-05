extends "res://Scripts/GUI/PopupMenu.gd"

var character = false

onready var name_label = $MarginContainer/VBoxContainer/Name/Background/Label
onready var job_label = $MarginContainer/VBoxContainer/Job/Background/Label

func _process(_delta):
	if character:
		name_label.text = character.person_name[0] + '\n' + character.person_name[1]
		if character.profession == "none":
			job_label.text = "no job"
		else: job_label.text = character.profession
	
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
