extends Tower


func _ready():
	var frozen_thorn_buff = FrozenThorn.new(2500, 100)
	frozen_thorn_buff.apply_to_unit_permanent(self, self, 0, false)
