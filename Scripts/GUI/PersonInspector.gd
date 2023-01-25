extends MarginContainer

onready var label = $NinePatchRect/Label
onready var gui = $"../../.."

var events = []

func add_event(ev):
	var ev_text = gui.get_time() + " - " + ev
	if len(events) == 4:
		label.text = label.text.right(len(events[0]))
		events.remove(0)
	label.text = label.text + '\n' + ev_text
	events.append('\n' + ev_text)
