extends Node2D

var is_pressed = false
var character = false

onready var gui = get_parent()

func _ready():
	hide()

func _process(_delta):
	if character:
		$MarginContainer/Label.text = character.string_name

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
