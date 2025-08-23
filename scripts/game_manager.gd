extends Node
class_name GameManager

@onready var label = $Label # temp

@onready var board = $Board
var current_owner: String = "P1"
var placed_count: int = 0

func _ready() -> void:
	EventBus.mask_drop_attempt.connect(_on_mask_drop_attempt)
	start_match()

func start_match() -> void:
	# (prochaine étape) créer les MaskState P1/P2 et appeler board.init_hands_from_states(...)
	board.init_hands()

func _on_mask_drop_attempt(target_cell: Node, mask_node: Node2D, state_id: String, owner_origin: String) -> void:
	if owner_origin != current_owner:
		failed_drop(mask_node, "not_current")
		return
	if request_place(mask_node, target_cell, state_id, owner_origin):
		EventBus.mask_drop_success.emit(mask_node)
		mask_node.global_position = target_cell.global_position
		_after_place()

func failed_drop(mask : Node, reason : String) -> bool:
	print("failed drop:", reason)
	if mask and mask.has_method('return_home'):
		mask.return_home()
	return false

# Appelé quand un Mask est lâché sur une Cell
func request_place(mask_node : Node, target: Cell, state_id: String, owner_origin: String) -> bool:
	if target == null:
		return failed_drop(mask_node, "no target")
	if not target.is_empty():
		return failed_drop(mask_node, "cell not empty")
	var st: MaskState = MaskDB.get_state(state_id)
	if st == null:
		return failed_drop(mask_node, "state null/not found")
	# Place
	target.set_occupant(owner_origin, state_id)
	# Captures TT
	board._resolve_captures(target)
	EventBus.mask_placed.emit(owner_origin)
	return true

func _after_place() -> void:
	placed_count += 1
	if current_owner == "P1":
		label.text = 'P2 turn'
		current_owner = "P2"
	else:
		label.text = 'P1 turn'
		current_owner = "P1"
	if placed_count >= 9:
		_end_match()
	EventBus.new_turn.emit(current_owner)

func _end_match() -> void:
	print_debug("MATCH ENDED !")
