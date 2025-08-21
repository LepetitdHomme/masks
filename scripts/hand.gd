extends Node2D

var MaskScene = preload("res://scenes/Mask.tscn")
@onready var cell = $Cell
@onready var cell_2 = $Cell2
@onready var cell_3 = $Cell3
@onready var cell_4 = $Cell4
@onready var cell_5 = $Cell5
var cells = []

func _ready():
	for child in get_children():
		child.remove_from_group("droppable") # can't drop masks on hands' cells

func spawn_from_states(state_ids: Array[String]) -> void:
	for i in 5:
		var state_id: String = state_ids[i]
		var state : MaskState = MaskDB.get_state(state_id)
		if state == null:
			print_debug("spawn state attempt failed: state null")
			continue

		var def: MaskDef = state.def
		var mask = MaskScene.instantiate()
		add_child(mask)
		mask.bind(def, state_id, state.ownr)
		# snap sur la cellule i de la main
		var hand_cell := get_child(i)
		mask.global_position = hand_cell.global_position
		mask.set_home_pos(mask.global_position)
