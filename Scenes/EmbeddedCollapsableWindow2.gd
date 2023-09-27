extends Window


@export var _menu: CollapsablePanelContainer
@export var _start_position: Vector2


func _ready():
	position = Vector2(_start_position.x - _menu.size.x, _start_position.y)


func _on_control_visibility_mode_changed(_expanded: bool):
	reset_size()


func _on_menu_resized():
	print("%s has been resized. Windows size: %s. Menu: [s - %s, p - %s]." % [_menu.name, size, _menu.size, _menu.position])
