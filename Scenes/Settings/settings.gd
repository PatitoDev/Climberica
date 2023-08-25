extends CanvasLayer

@onready var is_fullscreen_checkbox: CheckBox = $Control/SettingsPanel/VBoxContainer/IsFullscreenCheckbox
@onready var mod_timeout: CheckBox = $'Control/SettingsPanel/VBoxContainer/Mod Timeout'
@onready var user_timeout: CheckBox = $'Control/SettingsPanel/VBoxContainer/User Timeout'
@onready var volume_slider: HSlider = $Control/SettingsPanel/VBoxContainer/VolumeSlider
@onready var user_repeat: CheckBox = $'Control/SettingsPanel/VBoxContainer/User Repeat'

var masterIndex = AudioServer.get_bus_index("Master");
var isOpen := false;

func _ready():
	is_fullscreen_checkbox.button_pressed = Ranking.topRank.isFullscreen;
	mod_timeout.button_pressed = Ranking.topRank.banMods;
	user_timeout.button_pressed = Ranking.topRank.banUsers;
	volume_slider.value = Ranking.topRank.volume;
	user_repeat.button_pressed = Ranking.topRank.canRepeatNumber;
	get_window().mouse_entered.connect(_onMouseEnter);
	get_window().mouse_exited.connect(_onMouseLeave);

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed('settings'):
		toggleSettings();

func _onMouseEnter():
	$UI.visible = true;

func _onMouseLeave():
	$UI.visible = false;

func closeAll():
	isOpen = false;
	$SettingsPlayer.play_backwards('Show');

	if $Control/AreYouSurePanel.scale.y > 0.9:
		await get_tree().create_timer(0.1).timeout;
		$AreYouSurePlayer.play_backwards('Show');

func _on_delete_button_pressed() -> void:
	$AreYouSurePlayer.play('Show');

func _on_close_button_pressed() -> void:
	closeAll();

func _on_volume_slider_drag_ended(value: bool) -> void:
	Ranking.saveState();

func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(masterIndex, value);
	AudioServer.set_bus_mute(masterIndex, value <= -12);
	Ranking.topRank.volume = value;

func _on_is_fullscreen_checkbox_toggled(button_pressed: bool) -> void:
	Ranking.topRank.isFullscreen = button_pressed;
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN);
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED);
	Ranking.saveState();

func _on_mod_timeout_toggled(button_pressed: bool) -> void:
	Ranking.topRank.banMods = button_pressed;
	Ranking.saveState();

func _on_user_timeout_toggled(button_pressed: bool) -> void:
	Ranking.topRank.banUsers = button_pressed;
	Ranking.saveState();

func _on_yes_btn_pressed() -> void:
	Ranking.topRank = RankingState.new();
	Ranking.saveState();
	get_tree().change_scene_to_file('res://Scenes/SpashScreen/SplashScreen.tscn');

func _on_no_btn_pressed() -> void:
	$AreYouSurePlayer.play_backwards('Show');

func _on_user_repeat_toggled(button_pressed: bool) -> void:
	Ranking.topRank.canRepeatNumber = button_pressed;
	Ranking.saveState();

func _on_texture_button_pressed() -> void:
	toggleSettings();

func toggleSettings():
	if isOpen:
		closeAll();
	else:
		isOpen = true;
		$SettingsPlayer.play('Show');
