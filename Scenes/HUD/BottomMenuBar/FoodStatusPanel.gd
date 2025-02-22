@tool
extends ResourceStatusPanel


func _ready():
	super()

	if not Engine.is_editor_hint():
		FoodManager.changed.connect(_on_food_changed)
		_on_food_changed()


func _on_food_changed():
	var current_food: int = FoodManager.get_current_food()
	var food_cap: int = FoodManager.get_food_cap()
	var label_text: String = "%d/%d" % [current_food, food_cap]
	set_label_text(label_text)
