class_name CollapsablePanelContainer
extends PanelContainer


signal visibility_mode_changed(expanded: bool)


func _ready():
	resized.connect(_on_resized)
	_on_resized()


func update_visibility_mode(expanded: bool):
	set_size(Vector2.ZERO)
	visibility_mode_changed.emit(expanded)


# Just to make sure the contents inside the window
# won't reposition randomly after resizing.
func _on_resized():
	set_position(Vector2.ZERO)
	print("[control resize] %s pos %s size %s" % [name, position, size])
	var resize_boundary = 1440
	if size.y > resize_boundary:
		print("[control resize] uncontrolled resize")
		set_deferred("size", 0)
		
