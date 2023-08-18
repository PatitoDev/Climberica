extends Node2D

var holds:Array[Node] = [];

func initFrom(startFrom: int):
	holds = $Holds.get_children();
	for pole in holds:
		startFrom += 1;
		pole.char = str(startFrom);

func getNextHold():
	return holds.pop_front();

func _ready():
	Global.OnWin.connect(end);

func end(userId: String, userName: String):
	Ranking.topRank.poleSize += 5;
	if Ranking.topRank.lastVipUserId:
		Twitch.removeVip(Ranking.topRank.lastVipUserId);
	Ranking.topRank.lastVipUserId = userId;
	Twitch.addVip(userId);
	$Control/UserName.text = userName;
	var tween = get_tree().create_tween();
	tween.tween_property(Global.gameCamera, 'global_position', $EndCameraPosition.global_position, 3);
	var timer = get_tree().create_timer(10);
	await timer.timeout;
	get_tree().change_scene_to_file('res://Scenes/Climb/Climb.tscn');
