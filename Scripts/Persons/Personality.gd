extends "res://Scripts/Persons/PersonBase.gd"

# SOCIAL STUFF AS WELL AS PERSON-SPECIFIC STUFF
# VERY IMPORTANT

var topics = {} #dictionary of things to discuss with the other ppl
var ppl_known = []

var ASK_DICT = {
	"chat": 		funcref(self, "asked_chat"),
	"farmhand": 	funcref(self, "asked_farmhand")
}

var RESPONSE_DICT = {
	"chat": 	{true:  funcref(self, "y_chat"), \
				 false: funcref(self, "n_chat")},
	"farmhand": {true:  funcref(self, "y_farmhand"), \
				 false: funcref(self, "n_farmhand")}
}

var LENGTH_DICT = {
	"chat": 	[5,10],
	"farmhand": [10,20]
}

func day_reset_social():
	# gets called every day by everyone
	for person in ppl_known:
		if not 'chat' in topics[person]:
			topics[person].append('chat')

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
		ppl_known.append(target_person)
		topics[target_person] = ['chat']
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
	
#	if selected: print("%s has started talking to %s" % [string_name, target_person.string_name])
	return true

func receive_conversation(from_person):
	if in_building:
		assert(from_person in in_building.inside)
	
	if not from_person in ppl_known:
		ppl_known.append(from_person)
		topics[from_person] = ['chat']
	
	if not conversing:
		return true #we always want to talk!
	return false

func pick_topic(target_person):
	assert(target_person in topics)
	if topics[target_person]:
		var picked_topic = topics[target_person][world.rng.randi_range(0,len(topics[target_person])-1)]
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
#	if selected or target_person.selected: 
#		print("%s and %s are done talking \n" % [string_name, target_person.string_name])
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
	display_emotion("chat")
	
#	if selected: print("%s has asked about %s to %s" % [string_name, str(q), target_person.string_name])
	var answers = target_person.receive_q(self, q)
	var a = answers[0]
	var leave_flag = answers[1]
	
	yield(wait_time(LENGTH_DICT[q][0], LENGTH_DICT[q][1]), "completed")
	
	open = true
	if not leave_flag:
		RESPONSE_DICT[q][a].call_func()
		return true

func receive_q(from_person, q):
	assert(conversing == from_person)
	display_emotion("chat")
	var answer = ASK_DICT[q].call_func()
#	if selected: print("%s has been asked about %s by %s" % [string_name, str(q), from_person.string_name])
	
	return answer

# TOPICS OF CONVERSATION

# CHAT

func asked_chat() -> Array:
	# What happens in this chat... need more social functions!
	return [true, false]

func y_chat():
	# Positive replies
	pass

func n_chat():
	# Negative replies
	pass

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
