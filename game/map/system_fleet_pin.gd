extends Node2D

var faction = null
var color = null

func _ready():
	$Sprite.set_modulate(Color(color[0], color[1], color[2]))
