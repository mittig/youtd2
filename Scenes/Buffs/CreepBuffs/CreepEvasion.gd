class_name CreepEvasion extends BuffType


func _init(parent: Node):
	super("creep_evasion", 0, 0, true, parent)
	add_event_on_damaged(on_damaged, 1.0, 0.0)


func on_damaged(event: Event):
	var creep: Unit = event.get_target()
	var evade_success: bool = creep.calc_chance(0.25)

	if evade_success:
		event.damage = 0
