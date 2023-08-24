extends Node2D

var poleScene = preload('res://Scenes/Climb/Hold/hold.tscn');

@export var poleDistance := 20;

var nextHold = null;
var startingPosition := 180;
var positionInMeters := 0;
var totalHeightInMeters := 0;
var counter := 0;
var lastUser = null;
var poleAmount:int;

@onready var frog: Node2D = $Frog
@onready var holds = [];
@onready var ending: Node2D = $Ending
@onready var onScreenHighScore: Node2D = $OnScreenHighScore
@onready var offScreenHighScoreContainer: Node2D = $'UI Back/Control/TopRankOffScreen'
@onready var meterLabelOnScreen: Label = $'UI Front/Node2D/MeterContainer/MeterLabel'
@onready var meterLabelOffScreen: Label = $'UI Back/Control/TopRankOffScreen/MeterLabel'
@onready var meterLabelName: Label = $'UI Back/Control/TopRankOffScreen/MeterLabelName'

const ENDING_EXTRA_HEIGHT_IN_METERS = 17;
const STARTING_POLE_Y_POSITION = 84;
const POLE_X_OFFSET = 7;

func _ready():
	poleAmount = Ranking.topRank.poleSize;
	print('pole size at ', poleAmount);
	totalHeightInMeters = floor((poleDistance * poleAmount) / 10.0) + ENDING_EXTRA_HEIGHT_IN_METERS;
	Twitch.OnMessage.connect(onMessage);
	generateHolds();
	if Ranking.topRank.yPosition == 0:
		onScreenHighScore.global_position.y = 300;
	else:
		onScreenHighScore.global_position.y = Ranking.topRank.yPosition;
	if Ranking.topRank.userName:
		onScreenHighScore.updateName(Ranking.topRank.userName, str(Ranking.topRank.heightInMeters));
	offScreenHighScoreContainer.visible = Ranking.topRank.yPosition < frog.getPosition().y - 150;
	updateRankingLabel();
	updateNextLabel();

func generateHolds():
	var lastYPolePosition = STARTING_POLE_Y_POSITION;

	for i in range(poleAmount):
		var isLeft = !(i % 2) > 0;
		var pole = poleScene.instantiate();
		$Holds.add_child(pole);
		pole.global_position.y = lastYPolePosition - poleDistance;
		if isLeft:
			pole.global_position.x = $StartPolePointer.global_position.x - POLE_X_OFFSET;
		else:
			pole.global_position.x = $StartPolePointer.global_position.x + POLE_X_OFFSET;
		pole.isLeft = isLeft;
		lastYPolePosition = pole.global_position.y;
		pole.char = str(i);
		if i == 0:
			nextHold = pole;
		else:
			holds.push_back(pole);

		ending.global_position.y = lastYPolePosition - poleDistance;
	$Ending.initFrom(poleAmount);

func _physics_process(delta: float) -> void:
	if nextHold:
		$BallonCenterPoint.global_position.y = Global.gameCamera.global_position.y;
	else:
		$BallonCenterPoint.global_position.y -= 1;
	$Pole.global_position.y = max($Frog.getPosition().y - 500, ending.global_position.y);
	var height = floor(((-$Frog.getPosition().y + startingPosition) / 10));
	positionInMeters = height;
	meterLabelOnScreen.text = str(height) + '/' + str(totalHeightInMeters) + 'M'

func updateRanking(userName: String, userId: String):
	if positionInMeters > Ranking.topRank.heightInMeters:
		var tween = get_tree().create_tween();
		tween.tween_property(onScreenHighScore, 'global_position:y', $Frog.getPosition().y, 0.5);

		onScreenHighScore.updateName(userName, str(positionInMeters));
		Ranking.topRank.heightInMeters = positionInMeters;
		Ranking.topRank.yPosition = onScreenHighScore.global_position.y;
		Ranking.topRank.userName = userName;
		Ranking.topRank.userId = userId;

	updateRankingLabel();
	offScreenHighScoreContainer.visible = Ranking.topRank.yPosition < $Frog.getPosition().y - 150;

func updateRankingLabel():
	if !Ranking.topRank.userName:
		return;
	meterLabelOffScreen.text = str(Ranking.topRank.heightInMeters) + 'M';
	meterLabelName.text = Ranking.topRank.userName;

func onMessage(msg: ChatMessage):
	if $Frog.isFalling:
		return

	var regex = RegEx.new()
	regex.compile("^[0-9]+$");
	var result = regex.search(msg.message);
	if !result:
		return;

	if !nextHold:
		return;

#	if msg.userId == lastUser:
		#return;

	if msg.message == str(counter):
		lastUser = msg.userId;
		frog.moveHand(nextHold.isLeft, nextHold.getPlacementPosition());
		nextHold = holds.pop_front();
		updateRanking(msg.displayName, msg.userId);
		if !nextHold:
			nextHold = ending.getNextHold();
			if !nextHold:
				Global.OnWin.emit(msg.userId, msg.displayName);
				return;
		counter += 1;
		updateNextLabel();
		return;
	Twitch.timeoutUser(msg.userId, 5);
	$Notification.showText('Wrong Number!\n' + msg.displayName);
	frog.fall();

func updateNextLabel():
	$BallonCenterPoint/Balloon.updateLabel(str(counter));

func _exit_tree() -> void:
	Ranking.saveState();

func _on_frog_on_frog_has_died() -> void:
	get_tree().change_scene_to_file('res://Scenes/Climb/Climb.tscn');
