# Claws of Ursus
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.25, 0.0)
