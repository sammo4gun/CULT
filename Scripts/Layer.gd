extends TileMap

func _ready():
	pass

# Buid the visible tiles based on information passed through this 
# function:
func drawMap(map):
	var sz = len(map)
	for i in range(sz):
		for j in range(sz):
			set_cell(i,j, map[i][j])
