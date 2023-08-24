extends Node2D

@onready var loadingIcon: AnimatedSprite2D = $CanvasLayer/CenterContainer/LoadingIcon;
@onready var loginBtn: TextureButton = $CanvasLayer/CenterContainer/TitleContainer/LoginBtn;

func _ready():
	loadingIcon.visible = false;
	Twitch.OnSucess.connect(onTwitchConnectionSuccess);

func _on_button_pressed() -> void:
	Twitch.authenticate();
	loadingIcon.visible = true;
	loginBtn.visible = false;

func onTwitchConnectionSuccess():
	get_tree().change_scene_to_file('res://Scenes/Climb/Climb.tscn');
