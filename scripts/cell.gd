extends StaticBody2D
class_name Cell

@export var grid_pos: Vector2i = Vector2i(0, 0)

var owner_current: String = ""          # "P1" / "P2" / ""
var occupant_state_id: String = ""      # MaskState.id ou "" si vide

func is_empty() -> bool:
	return occupant_state_id == ""

func set_occupant(ownr: String, state_id: String) -> void:
	owner_current = ownr
	occupant_state_id = state_id

func clear() -> void:
	owner_current = ""
	occupant_state_id = ""
