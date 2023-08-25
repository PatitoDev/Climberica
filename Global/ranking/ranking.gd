extends Node

var PATH_TO_SAVE_FILE = 'user://save.tres';
var topRank: RankingState;

func _init() -> void:
	loadState();

func saveState():
	ResourceSaver.save(topRank, PATH_TO_SAVE_FILE);

func loadState():
	if !FileAccess.file_exists(PATH_TO_SAVE_FILE):
		topRank = RankingState.new();
		return;

	topRank = load(PATH_TO_SAVE_FILE);
	if topRank.isFullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN);
