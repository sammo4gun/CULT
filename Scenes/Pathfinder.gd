extends Node

# Code that takes two locations on the map and finds the route between
# them, or returns false if there is none.
#
# Based on the A* Algorithm.

export var ROAD_NOISE = 5

var width
var height
var map_types
var map_heights

var rng = RandomNumberGenerator.new()

onready var town = get_node("../Town")

func initialisePathfinding(w, h, mtypes, mheights):
	width = w
	height = h
	map_types = mtypes
	map_heights = mheights

# For now, lets say the higher portions of the map are simply not 
# available.
# Returns a list of the coords or false.
func findRoadPath(start, finish):
	var g = {start: 0}
	var h = {start: 0}
	var parents = {}
	
	var open = []
	var closed = []
	
	open.append(start)
	
	var buildings = town._mbuildings
	var cur
	while true:
		if len(open) == 0: return false
		
		var minimum = 999999
		var promising = null
		for val in open:
			cur = h[val] + g[val]
			if cur < minimum:
				promising = val
				minimum = cur
		open.erase(promising)
		
		for vec in [Vector2(-1,0),Vector2(1,0), Vector2(0,1), Vector2(0,-1)]:
			var new_pos = promising + vec
			if new_pos == finish:
				var path = []
				path.append(new_pos)
				new_pos = promising
				while true:
					path.append(new_pos)
					if new_pos == start:
						return path
					new_pos = parents[new_pos]
			if new_pos in map_types:
				if map_types[new_pos] != 3 and \
					map_heights[new_pos] == 0 and \
					not new_pos in buildings:
					#compute g
					var tg = g[promising] + rng.randi_range(1,ROAD_NOISE)
					if map_types[new_pos] >= 27 and map_types[new_pos] <= 36: tg += 10
					#compute h
					var th = new_pos.distance_to(finish)
					if new_pos in open or new_pos in closed:
						if g[new_pos] + h[new_pos] > tg+th:
							g[new_pos] = tg
							h[new_pos] = th
							parents[new_pos] = promising
							open.append(new_pos)
					else:
						g[new_pos] = tg
						h[new_pos] = th
						parents[new_pos] = promising
						open.append(new_pos)
			closed.append(promising)
