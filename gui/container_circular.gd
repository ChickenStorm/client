tool
extends Container

class_name CircularContainer

enum ANCHOR_POSITION {
	TOP_LEFT,
	TOP,
	TOP_RIGHT,
	LEFT,
	CENTER,
	RIGTH,
	BOTTOM_LEFT,
	BOTTOM,
	BOTTOM_RIGHT,
}

export(float) var angle_start_offset = 0.0 setget set_angle_start_offset
export(float) var angle_end_offset = 0.0 setget set_angle_end_offset
export(float) var radius_ratio = 1.0 setget set_radius_ratio

export(ANCHOR_POSITION) var anchor_position = ANCHOR_POSITION.TOP_LEFT setget set_anchor_position

export(bool) var aspect_ratio_force = true setget set_aspect_ratio_force
export(bool) var clip_center_node = false setget set_clip_center_node

var _warning_string = ""

func _ready():
	pass

func _notification(what):
	if (what==NOTIFICATION_SORT_CHILDREN):
		sort_children()

func sort_children():
	_reset_warning()
	# children_check
	if get_child_count() == 0:
		return
	var number_of_circular_button = 0
	var number_of_centered_node = 0
	for node in get_children():
		if not node is CircularButton and node.visible:
			node.raise()
			number_of_centered_node += 1
		elif node.visible:
			number_of_circular_button += 1
	if number_of_centered_node > 1 :
		_warn("There is more than one non circular button node.")
	elif number_of_centered_node == 0:
		_warn("There is less than one non circular button node.")
	var center_node = get_child(get_child_count() -1 )
	if not center_node is Control:
		_warn("The lowest center node is not a Control, aborting ...")
		return
	# size set up
	var rect_size_element_use 
	var aspect_ratio = Vector2(1.0,1.0)
	match anchor_position:
		ANCHOR_POSITION.BOTTOM, ANCHOR_POSITION.TOP:
			var y_extra = 0.0 if clip_center_node else center_node.rect_size.y /2.0
			var y_comp =  max(rect_size.x, 1) / 2.0  + y_extra
			if aspect_ratio_force:
				rect_size = Vector2(max(rect_size.x, 1.0),y_comp)
			aspect_ratio.y = 0.5 + y_extra/rect_size.x
			rect_size_element_use = rect_size.y
		ANCHOR_POSITION.LEFT, ANCHOR_POSITION.RIGTH:
			var x_extra = 0.0 if clip_center_node else center_node.rect_size.y /2.0
			var x_comp =  max(rect_size.y, 1) / 2.0  + x_extra
			if aspect_ratio_force:
				rect_size = Vector2(x_comp,max(rect_size.y, 1.0))
			aspect_ratio.x = 0.5 + x_extra/rect_size.y
			rect_size_element_use = rect_size.x
		_ :
			if aspect_ratio_force:
				rect_size = Vector2(max(rect_size.x, rect_size.y), max(rect_size.x, rect_size.y))
			rect_size_element_use = min(rect_size.x, rect_size.y)
	rect_size_element_use = max(rect_size_element_use,1.0)
	# position of center node
	for i in range (get_child_count()-number_of_centered_node,get_child_count()):
		var child_center = get_child(i)
		if child_center is Control and child_center.visible:
			match anchor_position:
				ANCHOR_POSITION.TOP_LEFT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_TOP_LEFT)
				ANCHOR_POSITION.TOP:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_TOP)
				ANCHOR_POSITION.TOP_RIGHT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_TOP_RIGHT)
				ANCHOR_POSITION.LEFT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_LEFT)
				ANCHOR_POSITION.CENTER:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER)
				ANCHOR_POSITION.RIGTH:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_RIGHT)
				ANCHOR_POSITION.BOTTOM_LEFT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_BOTTOM_LEFT)
				ANCHOR_POSITION.BOTTOM:
					child_center.set_anchors_and_margins_preset(Control.PRESET_CENTER_BOTTOM)
				ANCHOR_POSITION.BOTTOM_RIGHT:
					child_center.set_anchors_and_margins_preset(Control.PRESET_BOTTOM_RIGHT)
			# set grow direction
			child_center.grow_horizontal = Control.GROW_DIRECTION_BOTH
			child_center.grow_vertical = Control.GROW_DIRECTION_BOTH
			if not clip_center_node:
				match anchor_position:
					ANCHOR_POSITION.TOP_LEFT, ANCHOR_POSITION.TOP, ANCHOR_POSITION.TOP_RIGHT:
						child_center.grow_vertical = Control.GROW_DIRECTION_END
				match anchor_position:
					ANCHOR_POSITION.BOTTOM_LEFT, ANCHOR_POSITION.BOTTOM, ANCHOR_POSITION.BOTTOM_RIGHT:
						child_center.grow_vertical = Control.GROW_DIRECTION_BEGIN
				match anchor_position:
					ANCHOR_POSITION.BOTTOM_LEFT, ANCHOR_POSITION.TOP_LEFT, ANCHOR_POSITION.LEFT:
						child_center.grow_horizontal = Control.GROW_DIRECTION_END
				match anchor_position:
					ANCHOR_POSITION.TOP_RIGHT, ANCHOR_POSITION.RIGTH, ANCHOR_POSITION.BOTTOM_RIGHT:
						child_center.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		elif not child_center is Control:
			_warn("A center node is not a Control.")
	# angle
	var angle_start = 0.0
	var angle_end = 0.0
	var is_in_corner = false
	match anchor_position:
		ANCHOR_POSITION.TOP_LEFT:
			angle_end = 90.0
			is_in_corner = true
		ANCHOR_POSITION.TOP:
			angle_end = 180.0
		ANCHOR_POSITION.TOP_RIGHT:
			angle_start = 90.0
			angle_end = 180.0
			is_in_corner = true
		ANCHOR_POSITION.LEFT:
			angle_start = -90.0
			angle_end = 90.0
		ANCHOR_POSITION.CENTER:
			angle_end = 360.0
		ANCHOR_POSITION.RIGTH:
			angle_start = 90.0
			angle_end = 270.0
		ANCHOR_POSITION.BOTTOM_LEFT:
			angle_start =-90.0
			angle_end = 0.0
			is_in_corner = true
		ANCHOR_POSITION.BOTTOM:
			angle_start = 180.0
			angle_end = 360.0
		ANCHOR_POSITION.BOTTOM_RIGHT:
			angle_start = 180.0
			angle_end = 270.0
			is_in_corner = true
	angle_start = angle_start + angle_start_offset
	angle_end = angle_end + angle_end_offset
	# position of circular button
	for i in range(get_child_count()-number_of_centered_node):
		var node = get_child(i)
		if node is CircularButton and node.visible:
			node.set_margins_preset(Control.PRESET_TOP_LEFT)
			node.set_anchors_preset(Control.PRESET_TOP_LEFT)
			node.angle_start = angle_start + i * (angle_end-angle_start) / number_of_circular_button
			node.angle_end = angle_start + (i+1) * (angle_end-angle_start) / number_of_circular_button
			if is_in_corner:
				node.rect_size = (rect_size * Vector2( 1.0 / aspect_ratio.x, 1.0 / aspect_ratio.y) - center_node.rect_size/2.0)*2.0
				node.radius_in = center_node.rect_size.x / rect_size_element_use * radius_ratio / 2.0
			else:
				node.rect_size = rect_size * Vector2( 1.0 / aspect_ratio.x, 1.0 / aspect_ratio.y)
				node.radius_in = center_node.rect_size.x / rect_size_element_use * radius_ratio
			node.rect_position = center_node.rect_size / 2.0 + center_node.rect_position - node.rect_size/2.0

func set_radius_ratio(new_ratio):
	if new_ratio < 0.0 :
		return
	radius_ratio = new_ratio
	queue_sort()

func set_aspect_ratio_force(ratio_force):
	aspect_ratio_force = ratio_force
	queue_sort()

func _reset_warning():
	_warning_string = ""
	update_configuration_warning()
	
func _warn(string):
	_warning_string += ("\n" if _warning_string != "" else "") + string
	update_configuration_warning()

func _get_configuration_warning():
	return _warning_string

func set_angle_start_offset(new_angle):
	angle_start_offset = new_angle
	queue_sort()

func set_angle_end_offset(new_angle):
	angle_end_offset = new_angle
	queue_sort()
	
func set_anchor_position(new_anchor):
	anchor_position = new_anchor
	queue_sort()

func set_clip_center_node(clip):
	clip_center_node = clip
	queue_sort()
