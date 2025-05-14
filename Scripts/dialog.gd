extends Control

@onready var label: Label = $Panel/Label

var lines = ["The old Ruby King has given the throne to the Diamond.",
		"The Diamond King now rules the Kingdom and did not want any Ruby crystals living in the kingdom.",
		"Therefore, the child of the former Ruby King was exiled.",
		"Ruby, exiled, decied to take revange for the Ruby King."]

var lineN = 0

func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			lineN += 1
			label.text = lines[lineN]
		
