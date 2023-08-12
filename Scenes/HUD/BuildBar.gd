extends GridContainer


# Dictionary of all in-game towers with the associated buttons
# Buttons should be always created inside a dedicated container,
# which means you should call the parent of a button
# if you want to change the visual part of it.
@onready var _tower_buttons: Dictionary = {}

# Adds every tower button possible to the list.
# Although, this is a mutable list, so every time
# you build a tower, the ID of the tower is removed from this list.
# If you want unlimited tower buttons in the panel, switch the flag
# 'unlimited towers' to 'true'.
@onready var available_tower_buttons: Array


var _current_element: Element.enm = Element.enm.NONE : set = set_element, get = get_element
var current_size: String


func _ready():
	BuildTower.tower_built.connect(_on_Tower_built)
	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)


func _add_all_towers():
	print_verbose("Start adding all towers to BuildBar.")
	
	for tower_id in Properties.get_tower_id_list():
		var is_released: bool = TowerProperties.is_released(tower_id)
		if !is_released:
			continue

		var script_exists: bool = TowerManager.script_exists_for_tower(tower_id)
		if !script_exists:
			continue
	
		var tower_button = TowerButton.make(tower_id)
		var button_container = UnitButtonContainer.make()
		button_container.add_child(tower_button)
		
		_tower_buttons[tower_id] = tower_button
		button_container.hide()
		add_child(button_container)
	
	for tower_id in _tower_buttons.keys():
		available_tower_buttons.append(tower_id)

#	NOTE: call set_element() to show towers for currently
#	selected element. 
	set_element(_current_element)

	print_verbose("BuildBar has added all towers.")


func add_tower_button(tower_id):
	available_tower_buttons.append(tower_id)
	var element: Element.enm = Properties.get_csv_properties(tower_id)[Tower.CsvProperty.ELEMENT]
	if element == _current_element:
		_tower_buttons[tower_id].get_parent().show()


func remove_tower_button(tower_id):
	available_tower_buttons.erase(tower_id)
	_tower_buttons[tower_id].get_parent().hide()


func get_element() -> Element.enm:
	return _current_element

func set_element(element: Element.enm):
	_current_element = element
	
	for tower_button in _tower_buttons.values():
		tower_button.get_parent().hide()
	
	var available_towers_for_element = _get_available_tower_buttons_for_element(element)
	
	for tower_id in available_towers_for_element:
		_tower_buttons[tower_id].get_parent().show()


func _on_Tower_built(tower_id):
	match Globals.game_mode:
		GameMode.enm.BUILD: return
		GameMode.enm.RANDOM_WITH_UPGRADES: remove_tower_button(tower_id)
		GameMode.enm.TOTALLY_RANDOM: remove_tower_button(tower_id)


func _get_available_tower_buttons_for_element(element: Element.enm) -> Array:
	var element_string: String = Element.convert_to_string(element)
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.ELEMENT, element_string)
	
	var res: Array = []
	for tower_id in tower_id_list:
		var tier: int = TowerProperties.get_tier(tower_id)
		var is_first_tier: bool = tier == 1
		var display_all_tower_tiers: bool = Config.display_all_tower_tiers()
		var tier_is_ok: bool = is_first_tier || display_all_tower_tiers
		
		if available_tower_buttons.has(tower_id) && tier_is_ok:
			res.append(tower_id)
	
	return res


func _on_game_mode_was_chosen():
	if Globals.game_mode == GameMode.enm.BUILD:
		_add_all_towers()
