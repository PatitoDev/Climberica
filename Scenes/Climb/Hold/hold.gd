@tool
extends Node2D

@export var isLeft: bool = false: set = isLeftSetter;
@export var char: String = '';

func isLeftSetter(value: bool):
	isLeft = value;
	if isLeft:
		$HandHoldPosition.position.x = -10;
		$PoleArm.flip_h = true;
		$PoleArm.position.x = -24;
		return;
	$PoleArm.flip_h = false;
	$PoleArm.position.x = 0;
	$HandHoldPosition.position.x = 9;

func getPlacementPosition():
	return $HandHoldPosition.global_position;
