extends "res://Scripts/GUI/PopupMenu.gd"

var building = false

onready var type_label = $Main/TypeBar/Name/NinePatchRect/Label

func _process(_delta):
	if building:
		type_label.text = building.type

func reselect(build):
	if not build:
		deselect()
	elif is_pressed:
		building = build

func pressed(build):
	if not is_pressed and build: 
		show()
		building = build
		is_pressed = true
	else: 
		hide()
		building = false
		is_pressed = false
