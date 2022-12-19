extends GraphEdit

# THIS IS A WHOLE ASS SEPARATE SCREEN USED FOR DEBUGGING RN

onready var world = $"../.."
onready var population = $"../../Population"

var personnode = preload("res://Scenes/GUI/SocialGraph/PersonNode.tscn")

var nodes = {}

func generate_social_graph():
	var x = 50
	var y = 50
	for pers in population.pop:
		var n = personnode.instance()
		x += 200
		if x > 700:
			x = 50
			y += 80
		nodes[pers] = n
		n.title = pers.string_name
		n.offset = Vector2(x, y)
		add_child(n)

func update_all_social():
	# set positions to be separate from each other
	var node
	for pers in nodes:
		node = nodes[pers]
		node.text.text = "knows: " + str(len(pers.ppl_known))

func get_social_colour(op):
	return Color(op, op, op)
	pass #opinion ranges from negative to positive, map it to a colours

func add_social(pers):
	var node = nodes[pers]
	var i = 0
	var ops = []
	for known in pers.ppl_known:
		ops.append(pers.ppl_known[known]["op"])
	node.add_num_outputs(ops)
	for known in pers.ppl_known:
		var _t = connect_node(str(node), i, str(nodes[known]), 0)
		i += 1

func remove_social(node):
	for connection in get_connection_list():
		if connection['from'] == str(node):
			disconnect_node(connection["from"], connection["from_port"], connection['to'], connection['to_port'])
	node.remove_outputs()

var current_drag
var selected_node
var focused = false

func set_selected(node):
	if selected_node:
		remove_social(selected_node)
	if not node:
		selected_node = null
	else:
		selected_node=node
		for pers in nodes:
			if nodes[pers] == selected_node:
				world.selected_person(pers)
				add_social(pers)

func mouse_entered(node):
	current_drag = node
	if not selected_node:
		set_selected(current_drag)

func mouse_left(_node):
	current_drag = null
	if not focused:
		set_selected(null)

func _input(event):
	if event is InputEventMouseButton and visible:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if current_drag:
				set_selected(current_drag)
				focused = true
			elif focused: 
				focused = false
				if selected_node: set_selected(null)

func toggle_display():
	if not visible:
		update_all_social()
		visible = true
	else:
		visible = false
