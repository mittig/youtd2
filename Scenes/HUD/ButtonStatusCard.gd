class_name ButtonStatusCard
extends PanelContainer


signal visibility_level_changed(old_visibility_level: VisibilityLevel, new_visibility_level: VisibilityLevel)
signal main_button_toggled()


enum VisibilityLevel {
	FULL = 0,
	ESSENTIALS = 1,
	MENU_OPENED = 2,
	MENU_CLOSED = 3,
}


@export var _expand_button: Button : get = get_expand_button
@export var _hidable_status_panels: Array[Control]
@export var _status_panels: Array[Control]
@export var _panels_container: Control
@export var _empty_container: Container
@export var _main_button: Button : get = get_main_button
@export var _short_resource_status_panels: Array[ShortResourceStatusPanel]


var _visibility_level: VisibilityLevel = VisibilityLevel.ESSENTIALS


func _unhandled_input(event):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	if (cancelled || left_click) && _visibility_level == VisibilityLevel.FULL:
		change_visibility_level(ButtonStatusCard.VisibilityLevel.ESSENTIALS)


func _on_expand_button_pressed():
	change_visibility_level(VisibilityLevel.FULL)


func change_visibility_level(visibility_level: VisibilityLevel):
	var prev_visibility_level = _visibility_level
	match visibility_level:
		VisibilityLevel.FULL: 
			for status_panel in _status_panels:
				status_panel.visible = true
			_expand_button.visible = false 
			_panels_container.visible = true
			_empty_container.visible = false
		VisibilityLevel.ESSENTIALS: 
			for status_panel in _status_panels:
				status_panel.visible = true
			for status_panel in _hidable_status_panels:
				status_panel.visible = false
			_expand_button.visible = !_hidable_status_panels.is_empty()
			_panels_container.visible = true
			_empty_container.visible = false
			if prev_visibility_level == VisibilityLevel.MENU_OPENED:
				for panel in _short_resource_status_panels:
					panel.ack_count()
		VisibilityLevel.MENU_OPENED: 
			for status_panel in _status_panels:
				status_panel.visible = false
			_expand_button.visible = false
			_panels_container.visible = true
			_empty_container.visible = true
			for panel in _short_resource_status_panels:
				panel.ack_count()
		VisibilityLevel.MENU_CLOSED:
			_panels_container.visible = false
			_empty_container.visible = false
			for panel in _short_resource_status_panels:
				panel.ack_count()
	
	visibility_level_changed.emit(prev_visibility_level, visibility_level)
	_visibility_level = visibility_level


func get_main_button() -> Button:
	return _main_button


func get_expand_button() -> Button:
	return _expand_button


func _on_main_button_toggled(_toggled_on: bool):
	main_button_toggled.emit()
