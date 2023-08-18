extends Node2D


func updateName(displayName: String, record: String):
	$Label.text = displayName;
	$Label2.text = record + 'M';
