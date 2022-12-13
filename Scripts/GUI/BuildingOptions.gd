extends "res://Scripts/GUI/PopupMenu.gd"

var building = false

onready var type_label = $Main/TypeBar/Name/NinePatchRect/Label
onready var cellar_label = $Main/ResourceBar/Name/NinePatchRect/Label
onready var name_label = $Main/InfoBar/Name/NinePatchRect/Label
onready var name2_label = $Main/InfoBar/Name2/NinePatchRect/Label
onready var basement_label = $Main/BasementBar/Name/NinePatchRect/Label

onready var contents_popup = $Main/ResourceBar/Name/NinePatchRect/MenuButton.get_popup()

onready var person_options_gui = $"../CharacterOptions"
onready var world = $"../.."

var inside_people
var to_handle_contents

func _process(_delta):
	if building:
		type_label.text = building.type
		inside_people = building.get_inside()
		if inside_people:
			name_label.text = inside_people[0].string_name
		else: name_label.text = ''
		
		to_handle_contents = []
		for c in building.contents:
			if building.contents[c] > 0:
				to_handle_contents.append(c)
		
		for i in range(contents_popup.get_item_count()):
			if contents_popup.get_item_text(i).split(': ')[0] in to_handle_contents:
				contents_popup.set_item_text(i, contents_popup.get_item_text(i).split(': ')[0] + ": " + str(building.contents[contents_popup.get_item_text(i).split(': ')[0]]))
				to_handle_contents.erase(contents_popup.get_item_text(i).split(': ')[0])
			else: 
				contents_popup.remove_item(i)
		
		for c in to_handle_contents:
			contents_popup.add_item(c)

func reselect(build):
	if not build:
		deselect()
	elif is_pressed:
		building = build

func pressed(build):
	person_options_gui.pressed(null)
	if not is_pressed and build: 
		show()
		building = build
		is_pressed = true
	else: 
		hide()
		building = false
		is_pressed = false

func _unhandled_key_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_F:
			building.add_content("johnsons", 1)

func _on_name_button_pressed():
	if building and inside_people:
		person_options_gui.pressed(inside_people[0])
		world.selected_person(inside_people[0])
		reselect(null)
