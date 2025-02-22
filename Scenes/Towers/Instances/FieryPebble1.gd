extends Tower

func get_tier_stats() -> Dictionary:
	return {
		1: {splash_radius = 150},
		2: {splash_radius = 160},
		3: {splash_radius = 170},
		4: {splash_radius = 180},
		5: {splash_radius = 190},
		6: {splash_radius = 200},
	}


func load_specials(_modifier: Modifier):
	set_attack_style_splash({_stats.splash_radius: 0.25})
