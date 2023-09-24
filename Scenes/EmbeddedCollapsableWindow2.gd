extends Window


@export var menu: Control
@export var start_position: Vector2
@export var initial_collapse_size: Vector2
@export var initial_expand_size: Vector2

var initial_collapse: bool = true
var initial_expand: bool = true

func _ready():
	position = Vector2(start_position.x - menu.size.x, start_position.y)
#	_on_close_requested()


#func _on_close_requested():
#	print("_on_close_request start")
#	theme_type_variation = "ClosedWindow"
#	min_size = menu.size
#	size = menu.size
#	menu.position = Vector2.ZERO
#	print("_on_close_request end")
#
#
#func _on_open_requested():
#	print("_on_open_request start")
#	theme_type_variation = ""
#	min_size = menu.size
#	size = menu.size
#	menu.position = Vector2.ZERO
#	print("_on_open_request end")
#
#
func _on_control_visibility_mode_changed(collapsed: bool):
	reset_size()


func _on_unit_menu_resized():
	print("old_size: %s | new_size: %s" % [size, menu.size])
