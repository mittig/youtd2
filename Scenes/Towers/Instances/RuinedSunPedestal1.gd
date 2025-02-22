extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {bounce_decrease = 0.50, undead_damage = 0.20, undead_damage_add = 0.020},
		2: {bounce_decrease = 0.48, undead_damage = 0.21, undead_damage_add = 0.021},
		3: {bounce_decrease = 0.46, undead_damage = 0.22, undead_damage_add = 0.022},
		4: {bounce_decrease = 0.44, undead_damage = 0.23, undead_damage_add = 0.023},
		5: {bounce_decrease = 0.42, undead_damage = 0.24, undead_damage_add = 0.024},
		6: {bounce_decrease = 0.40, undead_damage = 0.25, undead_damage_add = 0.025},
		7: {bounce_decrease = 0.38, undead_damage = 0.26, undead_damage_add = 0.026},
	}


func load_specials(modifier: Modifier):
	set_attack_style_bounce(3, 0.5)
	
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, _stats.undead_damage, _stats.undead_damage_add)
