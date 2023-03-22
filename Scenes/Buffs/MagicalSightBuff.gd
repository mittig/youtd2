class_name MagicalSightBuff
extends BuffType

# Magical sight effect, makes creeps in radius visible. Creeps
# become invisible again once they leave range. Note that if
# creep leaves range of a unit with magical sight but stays in
# range of another unit with magical sight, then the creep
# will stay visible.


var magical_sight_aura_scene = preload("res://Scenes/Buffs/Aura.tscn")


func _init(radius: float):
	super("magical_sight", 0, 0, true)

	var aura_effect: BuffType = BuffType.new("", 0, 0, false)
	aura_effect.add_event_on_create(self, "on_effect_create")
	aura_effect.set_event_on_cleanup(self, "on_effect_cleanup")
	
	var aura: Aura.Data = Aura.Data.new()
	aura.aura_range = radius
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 0
	aura.power = 0
	aura.power_add = 0
	aura.aura_effect_is_friendly = false
	aura.aura_effect = aura_effect

	add_aura(aura)


func on_effect_create(event: Event):
	var target = event.get_target()
	target.add_invisible_watcher()


func on_effect_cleanup(event: Event):
	var target = event.get_target()
	target.remove_invisible_watcher()
