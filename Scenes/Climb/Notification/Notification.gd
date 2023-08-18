extends Node2D

func showText(value: String):
	$CanvasLayer/Label.text = value;
	$CanvasLayer/AnimationPlayer.play('show');
