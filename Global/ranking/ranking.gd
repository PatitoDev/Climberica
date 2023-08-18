extends Node

var PATH_TO_SAVE_FILE = 'user://save.tres';
var topRank: RankingState;

func _init() -> void:
	loadState();

func resetRecord():
	var lastVip = topRank.lastVipUserId;
	var poleSize = topRank.poleSize;
	topRank = RankingState.new();
	topRank.heightInMeters = 0;
	topRank.yPosition = 0;
	topRank.lastVipUserId = lastVip;
	topRank.poleSize = poleSize;

func saveState():
	ResourceSaver.save(topRank, PATH_TO_SAVE_FILE);

func loadState():
	if !FileAccess.file_exists(PATH_TO_SAVE_FILE):
		topRank = RankingState.new();
		topRank.heightInMeters = 0;
		topRank.yPosition = 0;
		topRank.poleSize = 5;
		return;

	topRank = load(PATH_TO_SAVE_FILE);
