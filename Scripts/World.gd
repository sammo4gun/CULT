extends Node2D

export var SIZE = 10

var TILE = preload("res://Scenes/Tile.tscn")

onready var drawer = $Map

var _map = []

var selected_tile = null

func _ready():
	buildMap()
	populateMap()
	drawer.map_ready(_map)

# Builds an empty map to render
func buildMap():
	for i in range(SIZE):
		_map.append([])
		for j in range(SIZE):
			_map[i].append(TILE.instance())
			self.add_child(_map[i][j])
			_map[i][j].setCoords(i,j)
			_map[i][j].connect("get_selected", self, "on_tile_selected")

func populateMap():
	var sz = len(_map)
	for i in range(sz):
		for j in range(sz):
			if j > 0 and j < sz-1 and i > 0 and i < sz-1:
				_map[i][j].construct(0, 0, [])
			#else: _map[i][j].construct(0, 0, [])

func on_tile_selected(tile):
	if selected_tile:
		selected_tile.deselect()
	selected_tile = tile
	selected_tile.select()
