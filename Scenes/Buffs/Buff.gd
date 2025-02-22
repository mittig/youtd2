class_name Buff
extends Node2D


# Buff stores buff parameters and applies them to target
# while it is active.


var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _caster: Unit
var _target: Unit
var _modifier: Modifier = Modifier.new()
var _level: int
var _power: int
var _time: float
var _friendly: bool
var _type: String
var _stacking_group: String
var _timer: Timer
# Map of Event.Type -> list of EventHandler's
var event_handler_map: Dictionary = {}
var _original_duration: float = 0.0
var _tooltip_text: String
var _buff_icon: String
var _purgable: bool
var _cleanup_done: bool = false
var _inherited_periodic_timers: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	if _time > 0.0:
		_timer = Timer.new()
		add_child(_timer)
		_timer.timeout.connect(_on_timer_timeout)

		var buff_duration_mod: float = _caster.get_prop_buff_duration()
		var debuff_duration_mod: float = _target.get_prop_debuff_duration()

		var total_time: float = _time * buff_duration_mod

		if !_friendly:
			total_time *= debuff_duration_mod

		_timer.start(total_time)
		_original_duration = total_time

	_target.death.connect(_on_target_death)
	_target.kill.connect(_on_target_kill)
	_target.level_up.connect(_on_target_level_up)
	_target.attack.connect(_on_target_attack)
	_target.attacked.connect(_on_target_attacked)
	_target.dealt_damage.connect(_on_target_dealt_damage)
	_target.damaged.connect(_on_target_damaged)
	_target.spell_casted.connect(_on_target_spell_casted)
	_target.spell_targeted.connect(_on_target_spell_targeted)

	_target.tree_exited.connect(_on_target_tree_exited)
	_caster.tree_exited.connect(_on_caster_tree_exited)

	var create_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CREATE, create_event)

#	NOTE: every unit has a trigger buff, don't add it to
#	combat log - it would clutter up the log
	var is_trigger_buff: bool = get_type().is_empty()
	if !is_trigger_buff:
		CombatLog.log_buff_apply(_caster, _target, self)


#########################
###       Public      ###
#########################

# NOTE: buff.refreshDuration() in JASS
func refresh_duration():
	set_remaining_duration(_original_duration)


# NOTE: buff.removeBuff() in JASS
func remove_buff():
	if _cleanup_done:
		return

	var cleanup_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.CLEANUP, cleanup_event)

	_target._remove_buff_internal(self)

	queue_free()


# NOTE: buff.purgeBuff() in JASS
func purge_buff():
	var purge_event: Event = _make_buff_event(null)
	_call_event_handler_list(Event.Type.PURGE, purge_event)

	remove_buff()


#########################
###      Private      ###
#########################

func _add_event_handler(event_type: Event.Type, handler: Callable):
	if !event_handler_map.has(event_type):
		event_handler_map[event_type] = []

	event_handler_map[event_type].append(handler)


func _add_periodic_event(handler: Callable, period: float):
	var timer: Timer

#	NOTE: inheriting periodic timers is a hack to to
# 	preserve item cooldowns when item is removed from tower
	if _inherited_periodic_timers.has(handler):
		timer = _inherited_periodic_timers[handler]

		if timer.get_parent() != null:
			timer.get_parent().remove_child(timer)
			timer.set_paused(false)
	else:
		timer = Timer.new()
		timer.wait_time = period
		timer.one_shot = false
		timer.autostart = true
		_inherited_periodic_timers[handler] = timer

	add_child(timer)
	timer.timeout.connect(_on_periodic_event_timer_timeout.bind(handler, timer))


func _add_event_handler_unit_comes_in_range(handler: Callable, radius: float, target_type: TargetType):
	var buff_range_area: BuffRangeArea = BuffRangeArea.make(radius, target_type, handler)
	add_child(buff_range_area)

	buff_range_area.unit_came_in_range.connect(_on_unit_came_in_range)


func _call_event_handler_list(event_type: Event.Type, event: Event):
	if !_can_call_event_handlers():
		return

#	NOTE: we need to set the _cleanup_done flag in this
#	precise place.
#   - It has to be set after we call
#     _can_call_event_handlers() because
#     _can_call_event_handlers returns false if this flag is
#     set.
#	- It also has to be set before we call event handlers so
#	  that cleanup handler gets called once but then doesn't
#	  recurse into another cleanup handler. (yes, some
#	  cleanup handlers can trigger another cleanup event).
	if event_type == Event.Type.CLEANUP:
		_cleanup_done = true

	if !event_handler_map.has(event_type):
		return

	event._buff = self

	var handler_list: Array = event_handler_map[event_type]

	for handler in handler_list:
		handler.call(event)


# Convenience function to make an event with "_buff" variable set to self
func _make_buff_event(target_arg: Unit) -> Event:
	var event: Event = Event.new(target_arg)
	event._buff = self

	return event


func _refresh_by_new_buff():
	refresh_duration()

#	NOTE: refresh event is triggered only when refresh
#	is caused by an application of buff with same level.
#	Not triggered when refresh_duration() is called for
#	other reasons.
	_emit_refresh_event()


func _emit_refresh_event():
	var refresh_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.REFRESH, refresh_event)


func _upgrade_by_new_buff(new_level: int, new_power: int):
	refresh_duration()
	
	set_level(new_level)
	set_power(new_power)

	var upgrade_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.UPGRADE, upgrade_event)


func _add_aura(aura_type: AuraType):
	var aura: Aura = aura_type.make(get_caster())
	add_child(aura)


# NOTE: when a buff is queued for deletion it means that the
# buff was removed from the target unit. If any other events
# are triggered in the same frame before the buff is
# deleted, the buff shouldn't respond to them.
func _can_call_event_handlers() -> bool:
	return !is_queued_for_deletion() && !_cleanup_done


func _change_giver_of_aura_effect(new_caster: Unit):
	var old_caster: Unit = _caster

	if old_caster == new_caster:
		return

	old_caster.tree_exited.disconnect(_on_caster_tree_exited)

	_caster = new_caster
	_caster.tree_exited.connect(_on_caster_tree_exited)


#########################
###     Callbacks     ###
#########################

func _on_unit_came_in_range(handler: Callable, unit: Unit):
	if !_can_call_event_handlers():
		return

	var range_event: Event = _make_buff_event(unit)

	handler.call(range_event)


func _on_timer_timeout():
	var expire_event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.EXPIRE, expire_event)

	remove_buff()


func _on_target_death(death_event: Event):
	death_event._buff = self
	_call_event_handler_list(Event.Type.DEATH, death_event)
	
	remove_buff()


# Explanation of all of the cases where buff needs to be
# removed due to a "tree_exited" signal:
# 
# 1. Buff needs to be removed when buff's target exits the
#    tree. Target is gone => buff is invalid.
# 
# 2. Buff needs to be removed when buff's caster exits the
#    tree. Caster is gone => event handlers are invalid =>
#    buff is invalid.
#
# 3. Buff needs to be removed when buff's BuffType exits the
#    tree. This case is necessary to correctly handle buffs
#    created by items. BuffType is gone => item is gone =>
#    event handlers are invalid => buff is invalid.


func _on_target_tree_exited():
	remove_buff()


func _on_caster_tree_exited():
	remove_buff()


func _on_buff_type_tree_exited():
	remove_buff()


func _on_target_kill(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.KILL, event)


func _on_target_level_up():
	var event: Event = _make_buff_event(_target)
	_call_event_handler_list(Event.Type.LEVEL_UP, event)


func _on_target_attack(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.ATTACK, event)


func _on_target_attacked(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.ATTACKED, event)


func _on_target_dealt_damage(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.DAMAGE, event)


func _on_target_damaged(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.DAMAGED, event)


func _on_target_spell_casted(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.SPELL_CAST, event)


func _on_target_spell_targeted(event: Event):
	event._buff = self
	_call_event_handler_list(Event.Type.SPELL_TARGET, event)


func _on_periodic_event_timer_timeout(handler: Callable, timer: Timer):
	if !_can_call_event_handlers():
		return

	Globals.is_inside_periodic_event = true
	
	var periodic_event: Event = _make_buff_event(_target)
	periodic_event._timer = timer
	handler.call(periodic_event)

	Globals.is_inside_periodic_event = false


#########################
### Setters / Getters ###
#########################

func is_friendly() -> bool:
	return _friendly


# NOTE: buff.setRemainingDuration() in JASS
func set_remaining_duration(duration: float):
	if _timer != null:
		_timer.start(duration)


# NOTE: buff.getRemainingDuration() in JASS
func get_remaining_duration() -> float:
	var remaining_duration: float = _timer.get_time_left()

	return remaining_duration


# NOTE: buff.isPurgable() in JASS
func is_purgable() -> bool:
	return _purgable


func get_buff_icon() -> String:
	return _buff_icon


# NOTE: if no tooltip text is defined, return type name to
# at least make it possible to identify the buff
func get_tooltip_text() -> String:
	if !_tooltip_text.is_empty():
		return _tooltip_text
	else:
		return _type


func get_modifier() -> Modifier:
	return _modifier


# NOTE: buff.setLevel() in JASS
func set_level(level: int):
	_level = level
	set_power(level)


# Level is used to compare this buff with another buff of
# same type that is active on target and determine which
# buff is stronger. Stronger buff will end up remaining
# active on the target.
# NOTE: buff.getLevel() in JASS
func get_level() -> int:
	return _level


# Power level is used to calculate the total time and total
# value of modifiers.
# NOTE: buff.getPower() in JASS
func get_power() -> int:
	return _power


# NOTE: buff.setPower() in JASS
func set_power(power: int):
	var old_power: int = _power
	_power = power
	_target.change_modifier_power(get_modifier(), old_power, power)


func get_type() -> String:
	return _type


func get_stacking_group() -> String:
	return _stacking_group


# NOTE: buff.getCaster() in JASS
func get_caster() -> Unit:
	return _caster


# NOTE: buff.getBuffedUnit() in JASS
func get_buffed_unit() -> Unit:
	return _target
