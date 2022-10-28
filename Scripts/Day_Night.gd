extends CanvasModulate

var started = false
var original_ticks_per_hour
var ticks_per_hour
var factor
var time_started

var current_time
var elapsed
var current_frame

func start_cycle(secs):
	time_started = OS.get_ticks_msec()
	elapsed = 0
	factor = 1
	started = true
	original_ticks_per_hour = secs * 1000
	ticks_per_hour = secs * 1000

func adjust_cycle(fact):
	elapsed = elapsed / factor
	factor = fact
	ticks_per_hour = original_ticks_per_hour * factor
	elapsed = int(elapsed * factor)

func pause_cycle():
	started = false

var clock = {'hour': 0, 'minute': 0}

# Returns the time in hours and minutes of the current cycle.
func get_time():
	if current_frame != null:
		clock["hour"] = int(current_frame)
		clock['minute'] = 10*int(range_lerp(current_frame - int(current_frame), 0, 1.0, 0, 6))
	return clock

func _process(delta):
	if started:
		elapsed += int(1000 * delta)
		elapsed = elapsed % int(24.0 * ticks_per_hour)
		current_frame = range_lerp(elapsed, 0, int(24.0 * ticks_per_hour), 0, 24)
		$AnimationPlayer.play("Day_night_cycle")
		$AnimationPlayer.seek(current_frame)
		
