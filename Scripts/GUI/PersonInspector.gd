extends MarginContainer

onready var label = $NinePatchRect/Label
onready var gui = $"../../.."

var events = []

func add_event(ev):
	var ev_text = (gui.get_time() if len(gui.get_time())-1 else "00:00") + " - " + ev
	if len(events) == 6:
		label.text = label.text.right(len(events[0]))
		events.remove(0)
	label.text = label.text + '\n' + ev_text
	events.append('\n' + ev_text)
