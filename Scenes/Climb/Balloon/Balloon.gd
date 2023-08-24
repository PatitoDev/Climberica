extends Node2D

@onready var label: Label = $Container/Label

func updateLabel(value: String):
	label.text = value;
