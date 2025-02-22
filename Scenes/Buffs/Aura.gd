class_name Aura
extends Node2D

# Aura applies an aura effect(buff) to targets in range of
# caster. Should be created using AuraType.

# NOTE: it is important to use get_units_in_range() for all
# aura range checking code. get_units_in_range() does the
# special range extension for towers - other range/distance
# functions don't.

var _aura_range: float = 10.0
var _target_type: TargetType = null
var _target_self: bool = false
var _level: int = 0
var _level_add: int = 0
var _power: int = 0
var _power_add: int = 0
var _aura_effect: BuffType = null

# NOTE: this is only used by MagicalSightBuff. All other
# aura's do not include invisible units.
var _include_invisible: bool = false

var _caster: Unit = null
var _target_list: Array = []


#########################
###     Built-in      ###
#########################

func _ready():
	_caster.level_changed.connect(_on_caster_level_changed)
	tree_exited.connect(_on_tree_exited)


#########################
###       Public      ###
#########################

# Triggers REFRESH event for buffs applied by this aura.
func refresh():
	var units_in_range: Array = Utils.get_units_in_range(_target_type, global_position, _aura_range, _include_invisible)

	for unit in units_in_range:
		var buff: Buff = unit.get_buff_of_type(_aura_effect)

		if buff == null:
			continue

		var buff_caster: Unit = buff.get_caster()
		var buff_was_applied_by_this_aura: bool = buff_caster == _caster

		if !buff_was_applied_by_this_aura:
			continue
		
		buff._emit_refresh_event()


func get_power() -> int:
	return _power + _caster.get_level() * _power_add


func get_level() -> int:
	return _level + _caster.get_level() * _level_add


func get_range() -> float:
	return _aura_range


#########################
###      Private      ###
#########################

func _remove_aura_effect_from_units(unit_list: Array):
	_remove_invalid_targets()

	for target in unit_list:
		var buff: Buff = target.get_buff_of_type(_aura_effect)

		if buff != null && buff.get_caster() == _caster:
#			NOTE: use _on_timer_timeout() instead of
#			remove_buff() so that buff emits the EXPIRE
#			event. Aura effects are supposed to emit EXPIRE
#			event according to youtd engine docs.
			buff._on_timer_timeout()


func _remove_invalid_targets():
	var invalid_list: Array = []
	
	for target in _target_list:
		if !is_instance_valid(target):
			invalid_list.append(target)

	for target in invalid_list:
		_target_list.erase(target)


func _change_buff_level_to_this_aura_level(buff: Buff):
	buff.set_level(get_level())
	buff.set_power(get_power())
	buff._change_giver_of_aura_effect(_caster)
	buff._emit_refresh_event()


#########################
###     Callbacks     ###
#########################

func _on_timer_timeout():
	_remove_invalid_targets()

	var units_in_range: Array = Utils.get_units_in_range(_target_type, global_position, _aura_range, _include_invisible)

# 	Remove buff from units that have went out of range or
# 	became invisible
	var removed_target_list: Array = []

	for target in _target_list:
		var in_range = units_in_range.has(target)

		if !in_range || (target.is_invisible() && !_include_invisible):
			removed_target_list.append(target)

	for target in removed_target_list:
		_target_list.erase(target)

	_remove_aura_effect_from_units(removed_target_list)

# 	Apply buff to units in range
	for unit in units_in_range:
		if !_target_self && unit == _caster:
			continue

		var active_buff: Buff = unit.get_buff_of_type(_aura_effect)

		if active_buff == null:
			_aura_effect.apply_advanced(_caster, unit, get_level(), get_power(), -1)
			_target_list.append(unit)
		else:
			var can_increase_level: bool = active_buff.get_level() < get_level()
			if can_increase_level:
				_change_buff_level_to_this_aura_level(active_buff)


func _on_tree_exited():
	_remove_aura_effect_from_units(_target_list)


# Level down the aura buffs here when tower levels down.
# Note that level ups are handled in _on_timer_timeout().
# 
# NOTE: the way lving down is handled is a bit imperfect
# because if there are two towers with same aura and one of
# them levels down, then the aura will temporarily level
# down for 0.2s and then go back up to the level of the
# strongest aura. It's not critical and I couldn't find a
# better solution which doesn't break anything else.
func _on_caster_level_changed():
	_remove_invalid_targets()
	
	var new_level: int = _caster.get_level()

	for target in _target_list:
		var active_buff: Buff = target.get_buff_of_type(_aura_effect)

		if active_buff == null:
			continue

		var need_to_level_down: bool = active_buff.get_level() > new_level

		if need_to_level_down:
			_change_buff_level_to_this_aura_level(active_buff)
