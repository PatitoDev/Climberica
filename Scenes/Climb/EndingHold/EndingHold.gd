extends Node2D

var char:String;
var isLeft: bool = false;

func getPlacementPosition():
	return $HandHoldPosition.global_position;

func _on_area_2d_body_entered(body: Node2D) -> void:
	Global.IsHandOnEnd.emit();
	$GPUParticles2D.emitting = true;
