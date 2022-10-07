extends TileMap

func _ready():
	pass

# Buid the visible tiles based on information passed through this 
# function:
func drawMap(w, h, map):
	for x in range(w):
		for y in range(h):
			set_cell(x,y, map[Vector2(x,y)])
