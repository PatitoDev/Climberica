extends Resource
class_name RankingState;

@export var userId: String;
@export var userName: String;
@export var heightInMeters: int = 0;
@export var yPosition: float = 0;
@export var lastVipUserId: String;
@export var poleSize: int = 5;

@export var isFullscreen: bool = false;
@export var volume: float = 0;
@export var banMods: bool = false;
@export var banUsers: bool = true;
@export var canRepeatNumber: bool = false;
