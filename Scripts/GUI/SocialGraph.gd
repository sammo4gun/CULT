extends GraphEdit

# THIS IS A WHOLE ASS SEPARATE SCREEN USED FOR DEBUGGING RN

onready var world = $"../.."
onready var population = $"../../Population"

var nodes = {}

func generate_social_graph():
	var x = 50
	var y = 50
	for pers in population.pop:
		var n = GraphNode.new()
		n.title = pers.string_name
		n.offset = Vector2(x, y)
		x += 200
		if x > 700:
			x = 50
			y += 80
		n.set_slot_enabled_left(0, true)
		n.set_slot_enabled_right(0, true)
		nodes[pers] = n
		add_child(n)
	
	for pers in nodes:
		for known in pers.ppl_known:
			connect_node(str(nodes[pers]), 0, str(nodes[known]), 1)

func remove_social_graph():
	for n in nodes:
		remove_child(nodes[n])
		nodes[n].queue_free()
	nodes = {}

func toggle_display():
	if not visible:
		generate_social_graph()
		visible = true
	else:
		remove_social_graph()
		visible = false
