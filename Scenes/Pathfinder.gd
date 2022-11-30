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

onready var towns = $"../Towns"

func initialisePathfinding(w, h, mtypes, mheights):
	width = w
	height = h
	map_types = mtypes
	map_heights = mheights

# For now, lets say the higher portions of the map are simply not 
# available.
# Returns a list of the coords or false.
func findRoadPath(start, finish, town, buildings, road_type):
	var g = {start: 0}
	var h = {start: 0}
	var parents = {}
	
	var open = []
	var closed = []
	
	open.append(start)
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
				var build_restricted = check_adjacent_obs(new_pos, town, buildings, road_type)
				if map_types[new_pos] != 3 and \
					map_heights[new_pos] == 0 and \
					not build_restricted:
					#compute g
					var tg = g[promising] + rng.randi_range(1,ROAD_NOISE)
					if map_types[new_pos] >= 27 and map_types[new_pos] <= 36: 
						tg += 10
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

func check_adjacent_obs(loc, town, buildings, road_type):
	if loc in buildings:
		if buildings[loc] in [1,2,4,5]:
			return true
		var has_town_road = towns.check_ownership(loc)
		if has_town_road:
			if not has_town_road == town:
				return true
		if loc in town._mroads:
			if road_type == 2:
				return true
			if town._mroads[loc] != road_type:
				return true
	return false

func is_walkable(loc, buildings, roads, must_roads, road_types):
	if must_roads:
		if loc in roads:
			if roads[loc] in road_types:
				return true
	elif loc in buildings:
		if buildings[loc] in [1,2,4]:
			return false
		if map_types[loc] != 3 and map_heights[loc] == 0:
			return true
	return false

func walkToBuilding(start, target_building, from_building, buildings, roads, road_types, must_roads):
	var start_to_path = [start]
	if from_building:
		var needs = true
		for ent in target_building.entrance_tiles:
			if ent in from_building.location:
				needs = false
		if needs:
			var pot_start
			var cost = 99999
			var n
			for til in from_building.entrance_tiles:
				n = walkRoadPath(til, target_building.entrance_tiles, buildings, roads, road_types, must_roads, true)
				if  n[1] < cost:
					pot_start = til
					cost = n[1]
			start_to_path = walkRoadPath(start, [pot_start], buildings, roads, road_types, must_roads)
	var path_to_entrance = walkRoadPath(start_to_path[-1], target_building.entrance_tiles, buildings, roads, road_types, must_roads)
	var entrance_to_inside = walkRoadPath(path_to_entrance[-1], target_building.location, buildings, roads, road_types, must_roads)
	return start_to_path + path_to_entrance + entrance_to_inside

func walkRoadPath(start, finish, buildings, roads, road_types, must_roads, get_cost = false):
	var g = {start: 0}
	var h = {start: 0}
	var parents = {}
	
	var open = []
	var closed = []
	
	if start in finish:
		if get_cost: return [[start], 0]
		return [start]
	
	open.append(start)
	var cur
	while true:
		if len(open) == 0: 
			if get_cost: return [false, 99999999]
			return false
		
		var minimum = 999999
		var promising = null
		for val in open:
			cur = h[val] + g[val]
			if cur < minimum:
				promising = val
				minimum = cur
		open.erase(promising)
		
		if promising in finish:
			var path = []
			var new_pos = promising
			while true:
				path.append(new_pos)
				if new_pos == start:
					path.invert()
					if get_cost: return [path, g[promising]]
					return path
				new_pos = parents[new_pos]
		
		for vec in [Vector2(-1,0),Vector2(1,0), Vector2(0,1), Vector2(0,-1)]:
			var new_pos = promising + vec
			if is_walkable(new_pos, buildings, roads, must_roads, road_types) or \
			   new_pos in finish:
				#compute g
				var tg = g[promising]
				if new_pos in roads:
					tg += 1
					if promising in roads:
						if roads[promising] != roads[new_pos]:
							tg += 40
				else: tg += 30
				
				#compute h
				var th = new_pos.distance_to(finish[0])
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
