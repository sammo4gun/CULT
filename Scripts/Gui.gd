extends MarginContainer

onready var name_label = $HBoxContainer/Bars/Bar1/Name/Background/Number
onready var location_label = $HBoxContainer/Bars/Bar1/Location/Background/Number
onready var building_label = $HBoxContainer/Bars/Bar2/Building/Background/Number
onready var contents_label = $HBoxContainer/Bars/Bar2/Contents/Background/Number

onready var towns = $"../../../Towns"
onready var world = get_tree().root.get_child(0)

var altitude
var buildings
var building
var selected_tile = null
var selected_person = null

func _process(_delta):
	$HBoxContainer/Button.rect_size.x = 40
	$HBoxContainer/Button.rect_size.y = 40
	rect_position.y = get_viewport().size.y/30
	rect_position.x = get_viewport().size.x/20
	var new_size = get_viewport().size.x * 15 /20
	$Background.position.x += (new_size - rect_size.x) / 2
	$Background.scale.x += (new_size/rect_size.x) / 2
	rect_size.x = new_size

func map_ready(alt, builds):
	altitude = alt
	buildings = builds

func display():
	if selected_tile != null:
		location_label.text = str(selected_tile)
		building = towns.get_building(selected_tile)
		
		var tile_stats = world.get_tile(selected_tile)
		name_label.text = str(tile_stats["name"])
		
		if building:
			name_label.text = "Built ground of " + str(building.town_name)
			building_label.text = str(building.house_name)
			if len(building.inside) > 0:
				contents_label.text = building.inside[0].string_name
			else: contents_label.text = "Empty"
		else:
			building_label.text = "None"
			contents_label.text = "None"
			var road = towns.get_road(selected_tile)
			if road:
				name_label.text = "Built ground of " + str(road)
				building_label.text = "Road"
				contents_label.text = "None"
	elif selected_person != null:
		name_label.text = ''
		location_label.text = ''
		building_label.text = ''
		contents_label.text = selected_person.string_name

func rm_display():
	name_label.text = ''
	location_label.text = ''
	building_label.text = ''
	contents_label.text = ''

func _on_Towns_refresh():
	display()

# Selected a new person
func _on_Selector_selected_person(person):
	selected_tile = null
	selected_person = person
	display()

# Selected a new square, or clicked outside the map
func _on_Selector_selected_tile(new_selected):
	if new_selected != null:
		selected_tile = new_selected
		selected_person = null
		display()
	else:
		selected_tile = null
		selected_person = null
		rm_display()
