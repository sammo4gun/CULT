extends "res://Scripts/Persons/PersonBase.gd"

# SOCIAL STUFF AS WELL AS PERSON-SPECIFIC STUFF
# VERY IMPORTANT

var topics = {} #dictionary of things to discuss with the other ppl
var ppl_known = []

var ASK_DICT = {
	"chat":			funcref(self, "asked_chat"),
	"farmhand": 	funcref(self, "asked_farmhand")
}

var RESPONSE_DICT = {
	"chat": 	{true:	funcref(self, "y_chat"), \
				 false: funcref(self, "n_chat")},
	"farmhand": {true:	funcref(self, "y_farmhand"), \
				 false: funcref(self, "n_farmhand")}
}

func day_reset_social():
	# gets called every day by everyone
	for person in ppl_known:
		if not 'chat' in topics[person]:
			topics[person].append('chat')

func engage_conversation(target_person, qs):
	if not target_person.receive_conversation(self):
		# The person did not want to talk...
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
	
	if not target_person in ppl_known:
		ppl_known.append(target_person)
		topics[target_person] = ['chat']
	
	for q in qs:
		topics[target_person].append(q)
	
#	print("%s is talking to %s" % [string_name, target_person.string_name])
	return true

func receive_conversation(from_person):
	if in_building:
		assert(from_person in in_building.inside)
	
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
	
	conversing = false
	activity = prev_activity
	prev_activity = null
	engaging = false
	open = true
	
	target_person.conversing = false
	target_person.activity = target_person.prev_activity
	target_person.prev_activity = null
	target_person.open = true
#	print("%s is done talking to %s" % [string_name, target_person.string_name])
	return true

func present_q(target_person, q):
	yield(get_tree().create_timer(timer_length(0.5,1.0)), "timeout")
	display_emotion("chat")
	
	var answers = target_person.receive_q(self, q)
	var a = answers[0]
	var leave_flag = answers[1]
	
	yield(get_tree().create_timer(timer_length(0.5,1.0)), "timeout")
	
	open = true
	if not leave_flag:
		RESPONSE_DICT[q][a].call_func()
		return true

func receive_q(from_person, q):
	if conversing != from_person:
		print(conversing)
		print(conversing.profession)
		print(from_person)
		if from_person: print(from_person.profession)
		print(self)
		print(self.profession)
	assert(conversing == from_person)
	display_emotion("chat")
	var answer = ASK_DICT[q].call_func()
#	print("%s has asked about %s to %s" % [from_person.string_name, str(q), string_name])
	
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
