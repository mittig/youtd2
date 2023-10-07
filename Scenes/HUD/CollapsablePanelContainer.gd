class_name CollapsablePanelContainer
extends PanelContainer


signal visibility_mode_changed(expanded: bool, reset: bool)


func _ready():
	resized.connect(_on_resized)
	_on_resized()


func update_visibility_mode(expanded: bool):
	set_size(Vector2.ZERO)
	visibility_mode_changed.emit(expanded, false)


# Should be implemented in inheritors.
func is_expanded() -> bool:
	return true


# Just to make sure the contents inside the window
# won't reposition randomly after resizing.
func _on_resized():
	set_position(Vector2.ZERO)
	var resize_boundary = 1440
	if size.y > resize_boundary:
		push_error("%s has been resized out of boundary: %s" % [name, size.y])
		# The trick is to reset the size in the end of the frame
		# whenever strange uncontrolled resizing happens.
		# Resetting size in the same frame won't work.
		set_deferred("size", 0)
		# Now we need to make sure that parent Window is
		# resized as well.
		visibility_mode_changed.emit(is_expanded(), true)
		
