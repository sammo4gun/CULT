extends CanvasLayer

signal back_to_game
signal any_key

var to_display_text = null

func play_ominous_message(text, start_game):
	assert(to_display_text == null)
	to_display_text = text
	$AnimationPlayer.play("ominous_message")
	if start_game:
		$ColorRect.color.a = 255
		$AnimationPlayer.seek(1)

func animate_words():
	assert(to_display_text != null)
	$AnimationPlayer.stop(false)
	
	for character in to_display_text:
		yield(get_tree().create_timer(.02), "timeout")
		$RichTextLabel.text += character
	yield(get_tree().create_timer(1.0), "timeout")
	$RichTextLabel.text += '\n\n ...press any key to continue.'
	
	yield(self, "any_key")
	$RichTextLabel.text = ''
	
	$AnimationPlayer.play()
	return true

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "ominous_message":
		to_display_text = null
		emit_signal("back_to_game")

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			emit_signal("any_key")
