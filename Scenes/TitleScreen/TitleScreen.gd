extends Node2D

func _ready():
	$FrogFace.visible = false;
	Twitch.OnSucess.connect(onTwitchConnectionSuccess);

func _on_button_pressed() -> void:
	Twitch.authenticate();
	$FrogFace.visible = true;
	$TitleContainer/TextureButton.visible = false;

func onTwitchConnectionSuccess():
	get_tree().change_scene_to_file('res://Scenes/Climb/Climb.tscn');
