extends MarginContainer

onready var name_label = $HBoxContainer/Bars/Bar1/Name/Background/Number
onready var building_label = $HBoxContainer/Bars/Bar2/Building/Background/Number
onready var contents_label = $HBoxContainer/Bars/Bar2/Contents/Background/Number

onready var towns = $"../../../Towns"
onready var world = get_tree().root.get_child(0)

var altitude
var buildings
var past_pos = Vector2(0,0)

func _process(delta):
	$HBoxContainer/Button.rect_size.x = 40
	$HBoxContainer/Button.rect_size.y = 40
	if past_pos != get_viewport().size:
		rect_position.y = get_viewport().size.y/30
		rect_position.x = get_viewport().size.x/20
		var new_size = get_viewport().size.x * 15 /20
		$Background.position.x += (new_size - rect_size.x) / 2
		$Background.scale.x += (new_size/rect_size.x) / 2
		rect_size.x = new_size
		past_pos = get_viewport().size

func map_ready(alt, roads, builds):
	altitude = alt
	buildings = builds

func display(selection):
	var building = towns.get_building(selection)
	
	var tile_stats = world.get_tile(selection)
	name_label.text = str(tile_stats["name"])
	
	if building:
		name_label.text = "Built ground of " + str(building.town_name)
		building_label.text = str(building.house_name)
		contents_label.text = "TBA"
	else:
		building_label.text = "None"
		contents_label.text = "TBA"
		var road = towns.get_road(selection)
		if road:
			name_label.text = "Built ground of " + str(road)
			building_label.text = "Road"
			contents_label.text = "TBA"
	

func rm_display():
	name_label.text = ''

func _on_Selector_new_selection(new_selected):
	if new_selected != null:
		display(new_selected)
	else:
		rm_display()


func _on_Details_pressed():
	name_label.text = ("button.")
