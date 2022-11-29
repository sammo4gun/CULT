extends TileMap

var ROADS_DICT = {
	[0,0,0,0]: 13, #should never happen
	[1,0,0,0]: 13, #should never happen
	[0,1,0,0]: 13, #should never happen
	[0,0,1,0]: 13, #should never happen
	[0,0,0,1]: 13, #should never happen
	[0,1,1,0]: 5,
	[0,1,0,1]: 6,
	[1,1,0,0]: 7,
	[1,0,1,0]: 8,
	[1,1,1,0]: 9,
	[1,0,0,1]: 10,
	[0,1,1,1]: 11,
	[0,0,1,1]: 12,
	[1,1,1,1]: 13,
	[1,0,1,1]: 14,
	[1,1,0,1]: 15
}

# Buid the visible tiles based on information passed through this 
# function:
func drawMap(w, h, map):
	for x in range(w):
		for y in range(h):
			set_cell(x,y, map[Vector2(x,y)])

func updateTerrain(pos: Vector2, type: int):
	set_cell(int(pos.x), int(pos.y), type)

func updateRoad(pos: Vector2, dirs: Array, _type: int):
	set_cell(int(pos.x), int(pos.y), ROADS_DICT[dirs])

func updateBuilding(pos: Vector2, building):
	set_cell(int(pos.x), int(pos.y), building.get_sprite(pos))
