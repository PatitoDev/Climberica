@tool
extends Node2D

signal OnFrogHasDied;

@onready var leftHandBody: CharacterBody2D = $LeftHandBody
@onready var rightHandBody: CharacterBody2D = $RightHandBody

@onready var leftHandSprite: Sprite2D = $LeftHandBody/LeftHand
@onready var rightHandSprite: Sprite2D = $RightHandBody/RightHand

@onready var leftArmLine: Line2D = $LeftArmLine
@onready var rightArmLine: Line2D = $RightArmLine

@onready var leftShoulderMarker: Marker2D = $RigidBody2D/FrogBody/LeftShoulderMarker
@onready var rightShoulderMarker: Marker2D = $RigidBody2D/FrogBody/RightShoulderMarker
@onready var leftLegMarker: Marker2D = $RigidBody2D/FrogBody/LeftLegMarker
@onready var rightLegMarker: Marker2D = $RigidBody2D/FrogBody/RightLegMarker

var leftHandTargetPosition: Vector2;
var rightHandTargetPosition: Vector2;
var handSpeed = 100;
var legImpulse = 5;
var isFalling = false;
var freeze = false;

func _ready():
	leftHandTargetPosition = leftHandBody.global_position;
	rightHandTargetPosition = rightHandBody.global_position;
	Global.IsHandOnEnd.connect(onGrabbedLastHold);
	Global.gameCamera = $Camera2D;

func getPosition():
	return $RigidBody2D.global_position;

func fall():
	if isFalling:
		return;
	isFalling = true;
	await get_tree().create_timer(1).timeout;
	$RigidBody2D/RemoteTransform2D.queue_free();
	await get_tree().create_timer(3).timeout;
	OnFrogHasDied.emit();

func moveHand(isLeft:bool, target: Vector2):
	if isFalling:
		return;

	if isLeft:
		leftHandTargetPosition = target;
		return
	rightHandTargetPosition = target;

func handleHandMovement(delta: float, target:Vector2, body: CharacterBody2D, isLeft: bool):
	if target.distance_to(body.global_position) <= 2:
		return;

	var direction = (target - body.global_position).normalized();
	var motion = direction * (handSpeed * delta);
	body.global_position += motion;
	if isLeft:
		$LeftLeg/LeftFoot.apply_central_impulse(Vector2(legImpulse,0));
		$RightLeg/RightFoot.apply_central_impulse(Vector2(legImpulse,0));
	else:
		$LeftLeg/LeftFoot.apply_central_impulse(Vector2(-legImpulse,0));
		$RightLeg/RightFoot.apply_central_impulse(Vector2(-legImpulse,0));

func _physics_process(delta: float) -> void:
	if !isFalling:
		handleHandMovement(delta, leftHandTargetPosition, leftHandBody, true);
		handleHandMovement(delta, rightHandTargetPosition, rightHandBody, false);
	else:
		fallingPhysics();
	renderArmAndRotateHands();

func fallingPhysics():
	var fallSpeed = 100;
	leftHandBody.velocity = Vector2(0, 1 * fallSpeed);
	leftHandBody.move_and_slide();
	rightHandBody.velocity = Vector2(0, 1 * fallSpeed);
	rightHandBody.move_and_slide();

func renderArmAndRotateHands():
	renderArm(leftShoulderMarker.global_position, leftHandSprite, leftArmLine);
	renderArm(rightShoulderMarker.global_position, rightHandSprite, rightArmLine);
	renderArm(leftLegMarker.global_position, $LeftLeg/LeftFoot/Hand, $LeftLeg/LeftLegLine);
	renderArm(rightLegMarker.global_position, $RightLeg/RightFoot/Hand, $RightLeg/RightLegLine);

func renderArm(shoulder: Vector2, handSprite: Sprite2D, armLine: Line2D):
	var diff = shoulder - handSprite.global_position;
	var handToArmAngleAsDeg = rad_to_deg(atan2(diff.y, diff.x));

	var armOffsetAt90 = Vector2(0.6, 0.4);
	var armRotation = handToArmAngleAsDeg - 180; # offset is adjusted to -> so discard
	var handOffsetForAlignment = armOffsetAt90.rotated(deg_to_rad(armRotation));
	var armOriginPoint = handSprite.global_position - handOffsetForAlignment;

	armLine.global_position = armOriginPoint;
	armLine.clear_points();
	armLine.add_point(Vector2.ZERO);
	armLine.add_point(shoulder - armOriginPoint);

	handSprite.global_position = handSprite.global_position;
	handSprite.rotation_degrees = handToArmAngleAsDeg - 45; # sprite is at 45 deg angle must discard

func onGrabbedLastHold():
	if !isFalling:
		isFalling = true;
	$AnimationPlayer.play('shock');
	$RightHandBody/GPUParticles2D.emitting = true;
	Ranking.resetRecord();
	$RigidBody2D/RemoteTransform2D.queue_free();
