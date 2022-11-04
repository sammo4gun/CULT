extends MarginContainer

var is_pressed = false
var building = false

onready var gui = $"../GUI"
onready var type_label = $Main/TypeBar/Name/NinePatchRect/Label

func _ready():
	hide()

func _process(_delta):
	if building:
		type_label.text = building.type

func deselect():
	if is_pressed:
		hide()
		is_pressed = false
	
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
