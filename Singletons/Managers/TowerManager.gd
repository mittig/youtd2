extends Node


var preloaded_towers: Dictionary
const towers_dir: String = "res://Scenes/Towers/Instances"


#########################
###     Built-in      ###
#########################

func _ready():
	print_verbose("Start loading TowerManager.")
	
	# Load all tower resources to dict and associate them with tower IDs
	
	var preload_towers: bool = Config.preload_all_towers_on_startup()

	if preload_towers:
		var tower_id_list: Array = Properties.get_tower_id_list()

		for tower_id in tower_id_list:
			var tower_scene: PackedScene = _get_tower_scene(tower_id)
			
			if TowerProperties.is_released(tower_id):
				preloaded_towers[tower_id] = tower_scene
				print_verbose("Preloaded tower [%s] with ID [%s]" % [TowerProperties.get_display_name(tower_id), tower_id])

	print_verbose("TowerManager has loaded.")

	_print_tower_counts()


#########################
###       Public      ###
#########################

# Return new unique instance of the Tower by its ID. Get
# script for tower and attach to scene. Script name matches
# with scene name so this can be done automatically instead
# of having to do it by hand in scene editor.
func get_tower(id: int, is_tower_preview: bool = false) -> Tower:
	var loaded_already: bool = preloaded_towers.has(id)

	if !loaded_already:
		var tower_scene: PackedScene = _get_tower_scene(id)

		preloaded_towers[id] = tower_scene
	
	var scene: PackedScene = preloaded_towers[id]
	var tower = scene.instantiate()
	var tower_script_path: String = _get_tower_script_path_or_placeholder(id)
	var tower_script = load(tower_script_path)
	tower.set_script(tower_script)
	tower.set_id(id)
	if is_tower_preview:
		tower.set_is_tower_preview()

	if scene == Globals.placeholder_tower_scene:
		var element: Element.enm = tower.get_element()
		var element_color: Color = Element.get_color(element)
		tower._set_placeholder_modulate(element_color)

	return tower


func get_tower_family_id(id: int) -> int:
	var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)
	return csv_properties[Tower.CsvProperty.FAMILY_ID]


#########################
###      Private      ###
#########################

func _get_tower_script_path(id: int) -> String:
	var family_name: String = _get_family_name(id)
	var path: String = "%s/%s1.gd" % [towers_dir, family_name]

	return path


# Get path of tower script based on tower scene name. If
# scene name is TinyShrub4.tscn, then script name will be
# TinyShrub1.gd. Returns placeholder script if no script was
# found.
func _get_tower_script_path_or_placeholder(id: int) -> String:
	var path: String = _get_tower_script_path(id)
	var script_exists: bool = ResourceLoader.exists(path)

	if script_exists:
		return path
	else:
		push_error("No script found for id:", id, ". Tried at path:", path)

		return "res://Scenes/Towers/Tower.gd"


# Scene filename = [name of first tier tower in family] +
# tier For example for "Greater Shrub" = "TinyShrub3.tscn"
func _get_tower_scene(id: int) -> PackedScene:
	var csv_properties: Dictionary = Properties.get_tower_csv_properties_by_id(id)
	var family_name: String = _get_family_name(id)
	var tier: String = csv_properties[Tower.CsvProperty.TIER]
	var scene_path: String = "%s/%s%s.tscn" % [towers_dir, family_name, tier]

	var scene_exists: bool = ResourceLoader.exists(scene_path)
	if scene_exists:
		var scene: PackedScene = load(scene_path)

		return scene
	else:
		if Config.print_errors_about_towers():
			push_error("No scene found for id:", id, ". Tried at path:", scene_path)

		return Globals.placeholder_tower_scene


# Family name is the name of the first tier tower in the
# family, with spaces removed. Used to construct filenames
# for tower scenes and scripts.
func _get_family_name(id: int) -> String:
	var family_id: int = TowerProperties.get_family(id)
	var towers_in_family: Array = TowerProperties.get_towers_in_family(family_id)

	if towers_in_family.is_empty():
		return ""

	var first_tier_id: int = towers_in_family.front()
	var first_tier_name: String = TowerProperties.get_display_name(first_tier_id)
	var family_name: String = first_tier_name.replace(" ", "")

	return family_name


func _print_tower_counts():
	var tower_count_map: Dictionary = _get_tower_count_map()

	print_verbose("Towers with scripts:")
	var rarity_list: Array[Rarity.enm] = [
		Rarity.enm.COMMON,
		Rarity.enm.UNCOMMON,
		Rarity.enm.RARE,
		Rarity.enm.UNIQUE,
	]
	for rarity in rarity_list:
		if !tower_count_map.has(rarity):
			continue

		var rarity_string: String = Rarity.convert_to_string(rarity)
		var tower_count: int = tower_count_map[rarity]
		print_verbose("    %s = %d" % [rarity_string, tower_count])


func _get_tower_count_map() -> Dictionary:
	var tower_count_map: Dictionary = {}

	var tower_id_list: Array = Properties.get_tower_id_list()

	for tower_id in tower_id_list:
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
		if !tower_count_map.has(rarity):
			tower_count_map[rarity] = 0
		tower_count_map[rarity] += 1

	return tower_count_map
