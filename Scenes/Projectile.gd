extends KinematicBody2D


var target_mob: Mob = null
export var speed: int = 100
export var contact_distance: int = 30
var aura_list: Array = []


# TODO: duplicated in GunT1.gd, move somewhere to share in both places
func have_target() -> bool:
	return target_mob != null and is_instance_valid(target_mob)

func _process(delta):
	if !have_target():
		queue_free()
		return
	
#	Move towards mob
	var target_pos = target_mob.position
	var pos_diff = target_pos - position
	
	var reached_mob = pos_diff.length() < contact_distance
	
	if reached_mob:
		for aura_info in aura_list:
			var mob_list: Array = get_affected_mob_list(aura_info)
			
			for mob in mob_list:
				mob.add_aura_list([aura_info])

		queue_free()
		return
	
	var move_vector = speed * pos_diff.normalized() * delta
	
	position += move_vector


func get_affected_mob_list(aura_info: Dictionary) -> Array:
	var aura_add_range: float = aura_info["add_range"]
	var apply_to_target_only: bool = aura_add_range == 0

	if apply_to_target_only:
		return [target_mob]
	else:
		var mob_list: Array = Utils.get_mob_list_in_range(global_position, aura_add_range)

		return mob_list
