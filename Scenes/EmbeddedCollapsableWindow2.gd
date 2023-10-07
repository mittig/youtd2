extends Window


@export var _menu: CollapsablePanelContainer
@export var _start_position: Vector2
@export var _start_size: Vector2


# Record window size in expand mode, and use this value
# to restore window size after the control is switched 
# from collapsed mode to expand mode.
var expanded_size: Vector2


func _on_control_visibility_mode_changed(expanded: bool):
	if expanded:
		set_size(expanded_size)
	else:
		expanded_size = size
		set_size(_menu.size)
	unresizable = not expanded


# The easiest way to atomatically resize contents of the
# Window is to set `wrap_controls` flag to true. But it
# doesn't work as expected - inner control panel sometimes
# resized vertically to a max possible length. This method
# is supposed to fix this issue. It should be called every
# time the Window is resized.
func _on_window_resized():
	_menu.set_position(Vector2.ZERO)
	_menu.set_size(size)
