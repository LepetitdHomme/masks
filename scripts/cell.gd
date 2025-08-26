extends StaticBody2D
class_name Cell

@export var grid_pos: Vector2i = Vector2i(0, 0)
@onready var color_rect = $ColorRect

var color_p1 : Color = Color.ORANGE
var color_p2 : Color = Color.BLUE

var owner_origin: String = ""
var owner_current: String = ""          # "P1" / "P2" / ""
var occupant_state_id: String = ""      # MaskState.id ou "" si vide
var current_mask_node : Node = null

func _ready():
	color_rect.visible = false

func is_empty() -> bool:
	return occupant_state_id == ""

func set_occupant(ownr: String, mask_node : Node, state_id: String) -> void:
	if owner_origin.is_empty():
		owner_origin = ownr
	current_mask_node = mask_node
	set_new_owner(ownr)
	occupant_state_id = state_id
	

func set_new_owner(ownr : String) -> void:
	owner_current = ownr
	color_rect.visible = true
	color_rect.color = color_p1 if owner_current == "P1" else color_p2

func clear() -> void:
	owner_current = ""
	occupant_state_id = ""
