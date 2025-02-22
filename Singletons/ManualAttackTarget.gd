extends Node

# Singleton for manually selecting a target for tower
# attacks. Towers will be forced to attack the selected
# target until it dies.
# 
# There are two scenario's:
#
# 1. If no tower is selected, then all towers will switch to
#    the target.
# 2. If a tower is selected, then only the selected tower
#    will switch to the target.


var _prev_effect_id: int = 0


#########################
###     Built-in      ###
#########################

func _unhandled_input(event):
# 	NOTE: Can't select when mouse is busy with some other
# 	action, for example moving items.
	var can_select: bool = MouseState.get_state() == MouseState.enm.NONE
	if !can_select:
		return

	var right_click: bool = event.is_action_released("right_click")

	if right_click:
		_do_manual_targetting()


#########################
###      Private      ###
#########################

func _do_manual_targetting():
	var selected_unit: Unit = SelectUnit.get_selected_unit()
	var hovered_unit: Unit = SelectUnit.get_hovered_unit()

	if !hovered_unit is Creep:
		return

	var hovered_creep: Creep = hovered_unit as Creep

	var tower_list: Array[Tower]
	if selected_unit is Tower:
		var selected_tower: Tower = selected_unit as Tower
		tower_list.append(selected_tower)
	else:
		tower_list = Utils.get_tower_list()

	for tower in tower_list:
		tower.force_attack_target(hovered_creep)

#	NOTE: destroy prev effect so that there's only one arrow
#	up at a time
	Effect.destroy_effect(_prev_effect_id)
	var effect: int = Effect.create_simple_on_unit("res://Scenes/Effects/TargetArrow.tscn", hovered_creep, Unit.BodyPart.HEAD)
	Effect.set_lifetime(effect, 2.0)
	_prev_effect_id = effect
