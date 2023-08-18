extends Node2D

var titleScreen = preload('res://Scenes/TitleScreen/TitleScreen.tscn')

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_packed(titleScreen);

func _input(event: InputEvent):
	if event.is_pressed():
		get_tree().change_scene_to_packed(titleScreen);
