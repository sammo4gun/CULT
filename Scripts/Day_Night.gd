extends CanvasModulate

var started = false
var seconds_per_hour = 2
var time_started

var current_time
var elapsed
var current_frame

func start_cycle(secs):
	time_started = OS.get_ticks_msec()
	started = true
	seconds_per_hour = secs

func pause_cycle():
	started = false

var clock = {'hour': 0, 'minute': 0}

# Returns the time in hours and minutes of the current cycle.
func get_time():
	if current_frame != null:
		clock["hour"] = int(current_frame)
		clock['minute'] = 10*int(range_lerp(current_frame - int(current_frame), 0, 1.0, 0, 6))
	return clock

func _process(_delta):
	if started:
		current_time = OS.get_ticks_msec()
		elapsed = (current_time - time_started) % (1000 * 24 * seconds_per_hour)
		current_frame = range_lerp(elapsed, 0, 1000 * 24 * seconds_per_hour, 0, 24)
		$AnimationPlayer.play("Day_night_cycle")
		$AnimationPlayer.seek(current_frame)
		
