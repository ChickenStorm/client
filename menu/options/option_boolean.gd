extends Control


export(String) var option_name setget set_option_name
export(bool) var is_checked = false setget set_is_checked
export(bool) var disabled = false setget set_disabled

signal option_pressed(is_pressed)

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/CheckBox.connect("pressed",self,"_on_button_toggle")

func set_option_name(new_label : String):
	$HBoxContainer/Label.text = new_label

func _on_button_toggle(is_pressed):
	is_checked = is_pressed
	emit_signal("option_pressed",is_pressed)

func set_is_checked(new_is_checked : bool):
	is_checked = new_is_checked
	$HBoxContainer/CheckBox.pressed = is_checked

func set_disabled(is_disabled : bool):
	disabled = is_disabled
	#TODO