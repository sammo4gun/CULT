extends Node2D

func _input(ev):
	if ev is InputEventKey:
		if ev.scancode == KEY_D:
			position.x += 1
		elif ev.scancode == KEY_A:
			position.x -= 1
		elif ev.scancode == KEY_W:
			position.y -= 1
		elif ev.scancode == KEY_S:
			position.y += 1
