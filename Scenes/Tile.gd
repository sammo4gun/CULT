extends Area2D

# an empty tile. Can be extended for different tile types.

# the TYPE of terrain, i.e. grass, dirt, water, whatever...
var type = 0

# the LAYER of terrain, i.e. is it on a hill or not, or which layer of
# hill.
var layer = 0

# the buildings that are built on this tile.
var buildings = []

var x_pos
var y_pos

signal get_selected

func setSelected():
	emit_signal("get_selected", self)

func select():
	$Sprite.visible=true
	
func deselect():
	$Sprite.visible=false

# make this the selected node if it gets clicked.
# TODO: Make sure only one tile can be selected at once, and that
# the front tile is the one that is selected.
func _on_Node2D_input_event(viewport, event, shape_idx):
	if  event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		setSelected() 

func construct(given_type, given_layer, given_buildings):
	type = given_type
	layer = given_layer
	buildings = given_buildings
	setPosition(x_pos, y_pos)

func setCoords(i,j):
	x_pos = i
	y_pos = j
	setPosition(x_pos, y_pos)

func setPosition(i, j):
	# calculate the isometric position of the tile based on the i, j, 
	# and layer. This is useful for drawing buildings on top of the 
	# tile.
	position = Vector2.ZERO
	
	position.y += 64
	
	position.x += y_pos*32
	position.y += y_pos*16
	
	position.x -= x_pos*32
	position.y += x_pos*16
	
	position.y -= layer*16
