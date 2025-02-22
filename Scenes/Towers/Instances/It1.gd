extends Tower


class Summoner:
	var size: float = 3.0
	var corruption_effect: int = 0
	var recreation_effect: int = 0
	var from_pos: Vector2 = Vector2.ZERO
	var to_pos: Vector2 = Vector2.ZERO


var multiboard: MultiboardValues
var sum: Summoner = Summoner.new()
var recreation_field_exists: bool = false
var corruption_field_exists: bool = false
var can_teleport: bool = false
# NOTE: this map is never cleared which is a bit suspect but
# considering that the amount of creeps in game is capped at
# 1000's and this stores references - it's not a big deal.
var summoner_units: Dictionary = {}


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]It Hunger[/color]\n"
	text += "Every time an enemy creep is transported by Dark Ritual or killed by this tower, It permanently gains 0.1% spelldamage. There is a maximum of 700% bonus spelldamage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.01% spelldamage\n"
	text += " \n"

	text += "[color=GOLD]Dark Ritual[/color]\n"
	text += "When this tower attacks, it awakens the powerful dark magic in Recreation and Corruption Fields, dealing 3000 spelldamage to all creeps unfortunate enough to be standing in those areas. If a non-boss enemy in Corruption Field is affected by Dark Ritual for the first time, it will be immediately transported to Recreation Field.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+100 spelldamage\n"
	text += " \n"
	text += "NOTE: has a 1 sec cooldown\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]It Hunger[/color]\n"
	text += "Every time an enemy creep is transported by Dark Ritual or killed by this tower, It permanently gains spelldamage.\n"
	text += " \n"

	text += "[color=GOLD]Dark Ritual[/color]\n"
	text += "When this tower attacks, it awakens the powerful dark magic in Recreation and Corruption Fields. \n"

	return text


func get_autocast_recreation_description() -> String:
	var text: String = ""

	text += "Set up Recreation Field at a chosen location. Field has 250 AoE and will punish creeps that walk over it at the wrong moment.\n"

	return text


func get_autocast_recreation_description_short() -> String:
	var text: String = ""

	text += "Set up Recreation Field at a chosen location.\n"

	return text


func get_autocast_corruption_description() -> String:
	var text: String = ""

	text += "Set up Corruption Field at a chosen location. Field has 250 AoE and will punish creeps that walk over it at the wrong moment.\n"

	return text


func get_autocast_corruption_description_short() -> String:
	var text: String = ""

	text += "Set up Corruption Field at a chosen location.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.005)


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Spelldamage Bonus")

	var autocast_recreation: Autocast = Autocast.make()
	autocast_recreation.title = "Recreation Field"
	autocast_recreation.description = get_autocast_recreation_description()
	autocast_recreation.description_short = get_autocast_recreation_description_short()
	autocast_recreation.icon = "res://path/to/icon.png"
	autocast_recreation.caster_art = ""
	autocast_recreation.target_art = ""
	autocast_recreation.autocast_type = Autocast.Type.AC_TYPE_NOAC_POINT
	autocast_recreation.num_buffs_before_idle = 0
	autocast_recreation.cast_range = 800
	autocast_recreation.auto_range = 0
	autocast_recreation.cooldown = 5
	autocast_recreation.mana_cost = 0
	autocast_recreation.target_self = false
	autocast_recreation.is_extended = true
	autocast_recreation.buff_type = null
	autocast_recreation.target_type = TargetType.new(TargetType.TOWERS)
	autocast_recreation.handler = on_autocast_recreation
	add_autocast(autocast_recreation)

	var autocast_corruption: Autocast = Autocast.make()
	autocast_corruption.title = "Corruption Field"
	autocast_corruption.description = get_autocast_corruption_description()
	autocast_corruption.description_short = get_autocast_corruption_description_short()
	autocast_corruption.icon = "res://path/to/icon.png"
	autocast_corruption.caster_art = ""
	autocast_corruption.target_art = ""
	autocast_corruption.autocast_type = Autocast.Type.AC_TYPE_NOAC_POINT
	autocast_corruption.num_buffs_before_idle = 0
	autocast_corruption.cast_range = 800
	autocast_corruption.auto_range = 0
	autocast_corruption.cooldown = 5
	autocast_corruption.mana_cost = 0
	autocast_corruption.target_self = false
	autocast_corruption.is_extended = true
	autocast_corruption.buff_type = null
	autocast_corruption.target_type = TargetType.new(TargetType.TOWERS)
	autocast_corruption.handler = on_autocast_corruption
	add_autocast(autocast_corruption)


func on_destruct():
	var recreation_effect: int = sum.recreation_effect
	Effect.destroy_effect(recreation_effect)
	var corruption_effect: int = sum.corruption_effect
	Effect.destroy_effect(corruption_effect)


func on_attack(_event: Event):
	var tower: Tower = self
	var aoe_dmg: float = 3000 + 100 * tower.get_level()

	if !can_teleport:
		return

	tower.do_spell_damage_aoe(sum.from_pos.x, sum.from_pos.y, 250.0, aoe_dmg, tower.calc_spell_crit_no_bonus(), 0.0)

#	40.0 Oo
#	(this is original script writer expressing surprise at
#	the "40.0" scale value)
	var dmg1: int = Effect.create_colored("ArcaneTowerAttack.mdl", sum.from_pos.x, sum.from_pos.y, 100.0, 270.0, 40.0, Color8(0, 0, 0, 255))
	Effect.set_lifetime(dmg1, 1.0)

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), sum.from_pos.x, sum.from_pos.y, 250.0)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var creep: Creep = next as Creep

		if creep.get_size() >= CreepSize.enm.BOSS:
			continue

		var already_summoned: bool = summoner_units.has(creep)

		if already_summoned:
			continue

		summoner_units[creep] = true

		var tp1: int = Effect.create_animated("DarkSummonTarget.mdl", next.get_x(), next.get_y(), 0.0, 270.0)
		Effect.set_lifetime(tp1, 1.0)

		it_kill()

		var random_offset_top_down: Vector2 = Vector2(randf_range(-25, 25), randf_range(-25, 25))
		var random_offset_isometric: Vector2 = Isometric.top_down_vector_to_isometric(random_offset_top_down)
		var to_pos: Vector2 = sum.to_pos + random_offset_isometric

		creep.move_to_point(to_pos)

		var tp2: int = Effect.create_animated("DarkSummonTarget.mdl", to_pos.x, to_pos.y, 0.0, 270.0)
		Effect.set_lifetime(tp2, 1.0)

	tower.do_spell_damage_aoe(sum.to_pos.x, sum.to_pos.y, 250.0, aoe_dmg, tower.calc_spell_crit_no_bonus(), 0.0)
	var dmg2: int = Effect.create_colored("ArcaneTowerAttack.mdl", sum.to_pos.x, sum.to_pos.y, 100.0, 270.0, 40.0, Color8(0, 0, 0, 255))
	Effect.set_lifetime(dmg2, 1.0)

#	NOTE: this is how the 1 sec cooldown for teleport is
#	implemented. Wonky, might cause problems.
	can_teleport = false
	await get_tree().create_timer(1.0).timeout
	can_teleport = true


func on_kill(_event: Event):
	it_kill()


func on_autocast_recreation(event: Event):
	var tower: Tower = self
	var autocast: Autocast = event.get_autocast_type()
	var last_pos: Vector2 = sum.to_pos
	sum.to_pos = autocast.get_target_pos()

	if Utils.is_point_on_creep_path(sum.to_pos):
		if recreation_field_exists:
			Effect.set_position(sum.recreation_effect, sum.to_pos)
		else:
			recreation_field_exists = true
			sum.recreation_effect = Effect.create_colored("VampiricAura.mdl", sum.to_pos.x, sum.to_pos.y, 0, 270.0, 2.0, Color8(255, 0, 0, 255))
			Effect.no_death_animation(sum.recreation_effect)
	else:
		sum.to_pos = last_pos
		tower.get_player().display_small_floating_text("Invalid location!", tower, 255, 150, 0, 30)


func on_autocast_corruption(event: Event):
	var tower: Tower = self
	var autocast: Autocast = event.get_autocast_type()

	if !recreation_field_exists:
		tower.get_player().display_small_floating_text("You must place the recreation field first!", tower, 255, 150, 0, 30)
		
		return

	can_teleport = true
	sum.from_pos = autocast.get_target_pos()

# 	No need to check the location in this field's placement
	if corruption_field_exists:
		Effect.set_position(sum.corruption_effect, sum.from_pos)
	else:
		corruption_field_exists = true
		sum.corruption_effect = Effect.create_colored("VampiricAura.mdl", sum.from_pos.x, sum.from_pos.y, 0, 270.0, 2.0, Color8(0, 0, 255, 255))
		Effect.no_death_animation(sum.corruption_effect)


func on_tower_details() -> MultiboardValues:
	var spelldmg_bonus: float = sum.size - 3.0
	var spelldmg_bonus_string: String = Utils.format_percent(spelldmg_bonus, 1)
	multiboard.set_value(0, spelldmg_bonus_string)

	return multiboard


func it_kill():
	var tower: Tower = self
	var mod: float = 0.001 + 0.0001 * tower.get_level()

	if sum.size < 10.0:
#		700% cap
		tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, mod)
		sum.size += mod

	if sum.size < 3.7:
		# TODO: implement when unit scale is implemented
		# SetUnitScale(tower, sum.size - 2.7, sum.size, sum.size)
		return
