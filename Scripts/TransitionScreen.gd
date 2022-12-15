extends CanvasLayer

signal back_to_game

var to_display_text = null

func animation(text):
	assert(to_display_text == null)
	to_display_text = text
	$AnimationPlayer.play("fade_to_black")

func animate_words(text):
	for character in text:
		yield(get_tree().create_timer(.3), "timeout")
		$RichTextLabel.text += character
	
	yield(get_tree(), "idle_frame")
	yield(get_tree().create_timer(1.0), "timeout")
	$RichTextLabel.text = ''
	$AnimationPlayer.play("fade_to_normal")
	return true

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_to_black":
		animate_words(to_display_text)
	if anim_name == "fade_to_normal":
		to_display_text = null
		emit_signal("back_to_game")

