extends "res://Scripts/Persons/PersonBase.gd"

# SOCIAL STUFF AS WELL AS PERSON-SPECIFIC STUFF
# VERY IMPORTANT

var topics = {} #dictionary of things to discuss with the other ppl
var ppl_known = {} #dictionary of dictionaries

var profession

var rec_time = 0

var ASK_DICT = {
	"chat": 		funcref(self, "asked_chat"),
	"farmhand": 	funcref(self, "asked_farmhand"),
	"introduce":	funcref(self, "asked_introduce")
}

var RESPONSE_DICT = {
	"chat": 	{true:  funcref(self, "y_chat"), \
				 false: funcref(self, "n_chat")},
	"farmhand": {true:  funcref(self, "y_farmhand"), \
				 false: funcref(self, "n_farmhand")},
	"introduce": {true:  funcref(self, "y_introduce"), \
				 false: funcref(self, "n_introduce")}
}

var LENGTH_DICT = {
	"chat": 	[5,10],
	"farmhand": [10,20],
	"introduce":[10,20]
}

func make_thoughts():
	SPEED += world.rng.randf_range(-10,10)
	
	#PHYSICAL/MENTAL STATS
	
	
	c_traits = {
		"intellect": world.rng.randi_range(0,10),
		"charm": world.rng.randi_range(0,10),
		"wisdom": world.rng.randi_range(0,10),
		"health": world.rng.randi_range(0,10),
	}
	
	#PERSONALITY STATS

func day_reset_social():
	# determine how much recreation to do today
	# based on mood & personality type
	rec_time = stepify(world.rng.randf_range(1, 4), 0.1)
	if profession == "none":
		rec_time += stepify(world.rng.randf_range(1, 4), 0.1)
	rec_types = ["exercise"]
	
	# gets called every day by everyone
	for person in ppl_known:
		if "Name" in ppl_known[person]:
			if not 'chat' in topics[person]:
				topics[person].append('chat')
		else:
			mod_op(person, -0.5) # dislike people who I've met but I don't even 
								 # know their name

func get_end_work_time():
	pass

func get_home_time():
	pass

# RECREATION

var rec_types
var rec_act
var rec_locs

func recreation_activity():
	if not rec_act:
		rec_locs = null
		if world_time < 6.0 or world_time > get_home_time():
			open = true
			return false
		
		rec_act = "square"
#		if rec_types:
#			rec_act = rec_types[world.rng.randi_range(0, len(rec_types)-1)]
#			rec_types.erase(rec_act)
#		else:
#			if world.rng.randf_range(0,1) > 0.5:
#				rec_act = "square"
#			else:
#				open = true
#				return false # go home fuck this
		# go to square
		# talk to a friend
		# go for exercise
		# go for a walk
	
	match rec_act:
		"square":
			if not rec_locs:
				rec_locs = town.get_town_square().get_location()
			if location in rec_locs:
				yield(rec_on_square(), "completed")
				open = true
				rec_act = null # every few seconds check if we still want to be on square - square
				# is considered "default activity"
				return true
			else:
				go_path(get_path_to_building(town.get_town_square()))
				return true
		"exercise":
			if not rec_locs:
				rec_locs = [get_random_loc(3, house.location[0])]
			if location in rec_locs:
				yield(rec_exercise(), "completed")
				open = true
				rec_act = null
				return false
			else:
				go_path(get_path_to(rec_locs))
				return true

func rec_exercise():
	var t = world.rng.randi_range(1, 5)
	while t:
		target_step = location
		yield(self, "movement_arrived")
		display_emotion("sweat")
		yield(wait_time(15), "completed")
		t-=1
	return true

func rec_on_square():
	assert(location in town.get_town_square().get_location())
	
	# wait 10 minutes for something interesting to happen
	yield(wait_time(10, 20), "completed")
	
	var choices = [Vector2(-1,0), Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(0,0)]
	var step
	step = choices[world.rng.randi_range(0,4)]
	if (location + step) in town.get_town_square().get_location():
		var target = location + step
		target_step = target
		yield(self, "movement_arrived")
	
	if world.rng.randf_range(0,1) > 0.5:
		display_emotion("happy")
	
	yield(wait_time(10, 20), "completed")
	
	return true

# CONVERSATION

func engage_conversation(target_person, qs = []):
	# IF: We aren't in the same building, or we are already engaged in conversation,
	# or the other person didn't want to talk... return false, the conversation
	# failed to happen.
	if not (not in_building and not target_person.in_building) and \
	   (not in_building or not target_person.in_building):
		# Only one of us is in a building
		return false
	if in_building != target_person.in_building:
		# We are both in a building but not the same one.
		return false
	if not target_person.receive_conversation(self) or \
	   conversing:
		# The person did not want to talk...
		return false
	
	if not target_person in ppl_known:
		first_time_see(target_person)
	
	topics[target_person] += qs
	
	if not topics[target_person]:
		return false
	
	reconsider = true
	prev_activity = activity
	activity = "conversing"
	conversing = target_person
	engaging = true
	
	target_person.reconsider = true
	target_person.prev_activity = target_person.activity
	target_person.activity = "conversing"
	target_person.conversing = self
	
	if selected and world.SOCIAL_DEBUG_MODE: 
		print("%s has started talking to %s" % [string_name, target_person.string_name])
	return true

func receive_conversation(from_person):
	if in_building:
		assert(from_person in in_building.inside)
	
	if not conversing:
		if not from_person in ppl_known:
			first_time_see(from_person)
		return true #we always want to talk!
	
	return false

func pick_topic(target_person):
	assert(target_person in topics)
	if topics[target_person]:
		var picked_topic
		if "introduce" in topics[target_person]:
			picked_topic = "introduce"
		else:
			picked_topic = topics[target_person][world.rng.randi_range(0,len(topics[target_person])-1)]
		topics[target_person].erase(picked_topic)
		return picked_topic
	return false

func end_conv(target_person):
	assert(conversing == target_person)
	assert(target_person.conversing == self)
	
	if target_person.topics[self]:
		target_person.switch_eng(self)
		return true
	
	conversing = false
	activity = prev_activity
	prev_activity = null
	engaging = false
	open = true
	purs_casual_conv = false
	
	target_person.conversing = false
	target_person.activity = target_person.prev_activity
	target_person.prev_activity = null
	target_person.open = true
	target_person.purs_casual_conv = false
	if (selected or target_person.selected) and world.SOCIAL_DEBUG_MODE: 
		print("%s and %s are done talking \n" % [string_name, target_person.string_name])
	return true

# we already are in a conversation, but now we switch sides. The other person
# becomes the engaging one.
func switch_eng(other_person):
	activity = "conversing"
	conversing = other_person
	engaging = true
	open = true
	
	other_person.activity = "conversing"
	other_person.conversing = self
	other_person.engaging = false
	
	return true

func present_q(target_person, q):
	assert(conversing == target_person)
	assert(target_person.conversing == self)
	assert(not target_person.engaging)
	display_emotion("chat")
	
	if selected and world.SOCIAL_DEBUG_MODE: 
		print("%s has asked about %s to %s" % [string_name, str(q), target_person.string_name])
	var answers = target_person.receive_q(self, q)
	var a = answers[0]
	var leave_flag = answers[1]
	
	yield(wait_time(LENGTH_DICT[q][0], LENGTH_DICT[q][1]), "completed")
	
	if not leave_flag:
		yield(RESPONSE_DICT[q][a].call_func(), "completed")
		open = true
		return true

func receive_q(from_person, q):
	assert(conversing == from_person)
	display_emotion("chat")
	var answer = ASK_DICT[q].call_func()
	if selected and world.SOCIAL_DEBUG_MODE:
		print("%s has been asked about %s by %s" % [string_name, str(q), from_person.string_name])
	
	return answer

# TOPICS OF CONVERSATION

# INTRODUCE

func asked_introduce() -> Array:
	# Engaged party reacts to an asked question
	assert(conversing in ppl_known)
	ppl_known[conversing]['Name'] = conversing.string_name
	ppl_known[conversing]['Prof'] = conversing.profession
	if conversing.profession == "mayor":
		ppl_known[conversing]['Relation'] = "authority"
	else: ppl_known[conversing]['Relation'] = "townsmate"
	
	# IF WE DIDN'T LIKE THE LOOK, REPLY N TO NOT INTRODUCE SELF
	var intr_back = true
	mod_op(conversing, 2.0)
	
	if intr_back:
		if "introduce" in topics[conversing]:
			topics[conversing].erase("introduce")
	return [intr_back, false] # [y/n reply, end conversation flag]

func y_introduce():
	# Engaging party reacts to negative reply
	assert(conversing in ppl_known)
	ppl_known[conversing]['Name'] = conversing.string_name
	ppl_known[conversing]['Prof'] = conversing.profession
	if conversing.profession == "mayor":
		ppl_known[conversing]['Relation'] = "authority"
	else: ppl_known[conversing]['Relation'] = "townsmate"
	mod_op(conversing, 2.0)
	
	if "introduce" in topics[conversing]:
		topics[conversing].erase("introduce")
	
	yield(get_tree(), "idle_frame")
	return

func n_introduce():
	# Engaging party reacts to negative reply
	assert(conversing in ppl_known)
	mod_op(conversing, -10.0)
	
	yield(get_tree(), "idle_frame")
	return

# CHAT

func asked_chat() -> Array:
	# Engaged party is asked a chat, gives a positive or negative reply
	mod_op(conversing, 0.5)
	return [true, false] # [y/n reply, end conversation flag]

func y_chat():
	mod_op(conversing, 0.5)
	yield(get_tree(), "idle_frame")
	return
	# Engaging party reacts to positive reply

func n_chat():
	yield(get_tree(), "idle_frame")
	return
	# Engaging party reacts to negative reply

# TEMPORARY SOCIALISING FUNCTIONS (WILL HAVE TO BE MOVED TO PROPER PLACE)

func get_social_options(profs = [], excluded = []):
	assert(in_building) #or on same/adjacent location?
	var poss_people = []
	for pers in in_building.inside:
		if pers != self and \
		   ((profs and pers.profession in profs) or \
		   (len(profs) == 0)) \
		   and not pers in excluded:
			poss_people.append(pers)
	
	return poss_people

func _on_WorldCollision_area_entered(area):
	# a little conversation! If they know each other.
	var other_person = area.get_parent()
	if not other_person.purs_casual_conv and not purs_casual_conv:
		purs_casual_conv = true
		if not engage_conversation(other_person):
			purs_casual_conv = false

# OPINIONS

func get_op(person):
	return ppl_known[person]['op']

func mod_op(person, amount):
	ppl_known[person]['op'] += amount

func first_time_see(person):
	ppl_known[person] = {'op': 0.0}
	topics[person] = ['introduce']
