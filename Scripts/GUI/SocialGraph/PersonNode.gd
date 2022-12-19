extends GraphNode

onready var text = $TextEdit

var outputs = []

func _ready():
	set_slot(0, true, 0, Color(1, 1, 1, 1), false, 0, Color(1,0,0,1)) #input slot

func op_to_colour(op):
	return Color(1-op, op, 0)

func add_num_outputs(ops):
	if not ops:
		return
	var size_y = 1
	var i = 1
	for op in ops:
		var cont = Control.new()
		cont.rect_min_size.y = float(size_y)
		# set color based on opinion
		set_slot(i, false, 0, Color(0, 0, 0, 0), true, 0, op_to_colour(op))
		add_child(cont)
		#move_child(cont, 0)
		outputs.append(cont)
		i+= 1

func remove_outputs():
	for child in outputs:
		remove_child(child)
		child.queue_free()
	outputs = []

func _on_Control_mouse_entered():
	get_parent().mouse_entered(self)

func _on_Control_mouse_exited():
	get_parent().mouse_left(self)
