extends MarginContainer

signal time_slider

onready var name_label = $Main/StatusBar/Bars/Bar1/Name/Background/Number
onready var location_label = $Main/StatusBar/Bars/Bar1/Location/Background/Number
onready var building_label = $Main/StatusBar/Bars/Bar2/Building/Background/Number
onready var contents_label = $Main/StatusBar/Bars/Bar2/Contents/Background/Number

onready var hour_label = $Main/StatusBar/VBoxContainer/HBoxContainer/Name2/Background/Hour
onready var minute_label = $Main/StatusBar/VBoxContainer/HBoxContainer/Name2/Background/Minute

onready var char_button = $Main/HBoxContainer/GUI_Selector/MarginContainer2/Character/Button
onready var char_anim = $Main/HBoxContainer/GUI_Selector/MarginContainer2/Character/Button/AnimationPlayer
onready var tile_button = $Main/HBoxContainer/GUI_Selector/MarginContainer/Tile/Button
onready var tile_anim = $Main/HBoxContainer/GUI_Selector/MarginContainer/Tile/Button/AnimationPlayer
onready var build_button = $Main/HBoxContainer/GUI_Selector/MarginContainer3/Building/Button
onready var build_anim = $Main/HBoxContainer/GUI_Selector/MarginContainer3/Building/Button/AnimationPlayer

onready var person_inspector = $Main/BottomBar/PersonInspector

onready var towns = $"../../Towns"
onready var world = get_tree().root.get_child(0)

onready var character_options_gui = $"../CharacterOptions"
onready var building_options_gui = $"../BuildingOptions"
onready var tile_options_gui = null

var altitude
var building
var selected_tile = null
var selected_person = null

var time_started = false

func _process(_delta):
	if time_started:
		set_time(world.get_time())

func start_time():
	time_started = true

func set_time(time):
	hour_label.text = str(time["hour"])
	if len(hour_label.text) < 2:
		hour_label.text = '0' + hour_label.text
	minute_label.text = str(time["minute"])
	if len(minute_label.text) < 2:
		minute_label.text = '0' + minute_label.text

func get_time() -> String:
	# get time in string format
	return hour_label.text + ":" + minute_label.text

func add_event(ev):
	person_inspector.add_event(ev)

func display():
	if selected_tile != null:
		location_label.text = str(selected_tile)
		building = towns.get_building(selected_tile)
		var road = towns.get_road(selected_tile)
		
		var tile_stats = world.get_tile(selected_tile)
		
		name_label.text = str(tile_stats["name"])
		match tile_stats['name']:
			"Trees":
				name_label.text += ': ' + str(world.trees_dict[selected_tile])
			"Constructed":
				assert(building or road)
				if building:
					name_label.text += " ground of " + str(building.town_name)
				elif road:
					name_label.text += " ground of " + str(road)
			"Desecrated":
				name_label.text += " Ground"
		
		if building:
			building_label.text = str(building.house_name)
			if len(building.inside) > 0:
				contents_label.text = building.inside[0].string_name
				if len(building.inside) > 1:
					contents_label.text += "+%s" % str(len(building.inside)-1)
			else: contents_label.text = "Empty"
		else:
			building_label.text = "None"
			contents_label.text = "None"
			if road:
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
	building_options_gui.reselect(null)
	selected_person = person
	character_options_gui.reselect(selected_person)
	char_anim.play("flare_red")
	display()

# Selected a new square, or clicked outside the map
func _on_Selector_selected_tile(new_selected):
	selected_tile = null
	building_options_gui.reselect(towns.get_proper_building(new_selected))
	selected_person = null
	character_options_gui.reselect(selected_person)
	
	selected_tile = new_selected
	if selected_tile != null:
		tile_anim.play("flare_red")
		if(towns.get_proper_building(selected_tile)):
			build_anim.play("flare_red")
		display()

func _on_VSlider_value_changed(value):
	emit_signal("time_slider", value)

func _on_Button_pressed():
	character_options_gui.pressed(selected_person)

func _on_Building_Button_pressed():
	building_options_gui.pressed(towns.get_proper_building(selected_tile))
