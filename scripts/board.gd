extends Node2D
class_name Board

const W: int = 3
const H: int = 3
@onready var grid = $grid
@onready var hand_p1 = $HandP1/Hand
@onready var hand_p2 = $HandP2/Hand

@export var cell_size: Vector2 = Vector2(128, 128)
@export var origin: Vector2 = Vector2.ZERO

var hand_scene = preload("res://scenes/hand.tscn")

enum Dir { TOP, RIGHT, BOTTOM, LEFT }

var cells: Array = []  # Array<Array<Cell>>

func _ready() -> void:
	EventBus.mask_drop_attempt.connect(_on_mask_drop_attempt)
	_init_cells_grid()
	init_hands()

func _init_cells_grid() -> void:
	cells.clear()
	cells.resize(H)
	for y in range(H):
		var row: Array = []
		row.resize(W)                # remplit de null
		cells[y] = row

	# Mappe uniquement les enfants de type Cell
	for child in grid.get_children():
		if child is Cell:
			var c: Cell = child
			var gp: Vector2i = c.grid_pos
			assert(in_bounds(gp), "Cell.grid_pos hors limites: %s" % [gp])
			assert(cells[gp.y][gp.x] == null, "Cell en double à %s" % [gp])
			cells[gp.y][gp.x] = c

	# Vérifie que tout est bien rempli
	for y in range(H):
		for x in range(W):
			assert(cells[y][x] is Cell, "Case manquante à (%d,%d)" % [x, y])

func init_hands() -> void:
	# pour le POC : créer des MaskState en dur
	var fire_def = load("res://masks/first_mask.tres") as MaskDef

	var p1_states: Array[String] = [
		MaskDB.add_from_def(fire_def, "P1").id,
		MaskDB.add_from_def(fire_def,  "P1").id,
		MaskDB.add_from_def(fire_def,  "P1").id,
		MaskDB.add_from_def(fire_def,  "P1").id,
		MaskDB.add_from_def(fire_def,  "P1").id,
	]
	var p2_states: Array[String] = [
		MaskDB.add_from_def(fire_def, "P2").id,
		MaskDB.add_from_def(fire_def,  "P2").id,
		MaskDB.add_from_def(fire_def,  "P2").id,
		MaskDB.add_from_def(fire_def,  "P2").id,
		MaskDB.add_from_def(fire_def,  "P2").id,
	]

	hand_p1.spawn_from_states(p1_states)
	hand_p2.spawn_from_states(p2_states)

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < W and p.y >= 0 and p.y < H

func get_cell(p: Vector2i) -> Cell:
	if not in_bounds(p):
		return null
	var c = cells[p.y][p.x]
	return c if c is Cell else null


func failed_drop(mask : Node) -> bool:
	print("failed drop")
	if mask and mask.has_method('return_home'):
		mask.return_home()
	return false

# Appelé quand un Mask est lâché sur une Cell
func request_place(mask_node : Node, target: Cell, state_id: String, owner_origin: String) -> bool:
	if target == null:
		return failed_drop(mask_node)
	if not target.is_empty():
		return failed_drop(mask_node)
	var st: MaskState = MaskDB.get_state(state_id)
	print("test3")
	if st == null:
		return failed_drop(mask_node)
	print("test4")
	# Place
	target.set_occupant(owner_origin, state_id)
	print("test5")
	# Captures TT
	_resolve_captures(target)
	print("test6")
	return true

func _resolve_captures(center: Cell) -> void:
	var p: Vector2i = center.grid_pos
	var st_new: MaskState = MaskDB.get_state(center.occupant_state_id)
	if st_new == null: return

	# (voisin, direction_du_nouveau_vers_voisin, direction_opposée_du_voisin)
	var checks: Array = [
		{ "q": Vector2i(p.x, p.y - 1), "d_new": Dir.TOP,    "d_nei": Dir.BOTTOM },
		{ "q": Vector2i(p.x + 1, p.y), "d_new": Dir.RIGHT,  "d_nei": Dir.LEFT   },
		{ "q": Vector2i(p.x, p.y + 1), "d_new": Dir.BOTTOM, "d_nei": Dir.TOP    },
		{ "q": Vector2i(p.x - 1, p.y), "d_new": Dir.LEFT,   "d_nei": Dir.RIGHT  }
	]

	for item in checks:
		var q: Vector2i = item["q"]
		if not in_bounds(q): continue
		var nei: Cell = get_cell(q)
		if nei == null: continue
		if nei.is_empty(): continue
		# Compare faces
		var st_nei: MaskState = MaskDB.get_state(nei.occupant_state_id)
		if st_nei == null: continue
		var v_new: int = _value_on(st_new, int(item["d_new"]))
		var v_nei: int = _value_on(st_nei, int(item["d_nei"]))
		if v_new > v_nei:
			nei.owner_current = center.owner_current  # flip (seule la cell change d’owner)

func _value_on(st: MaskState, dir: int) -> int:
	match dir:
		Dir.TOP:    return st.val_top()
		Dir.RIGHT:  return st.val_right()
		Dir.BOTTOM: return st.val_bottom()
		Dir.LEFT:   return st.val_left()
	return 0

func _on_mask_drop_attempt(target_cell: Cell, mask_node: Node, state_id: String, owner_origin: String) -> void:
	print("drop att")
	if request_place(mask_node, target_cell, state_id, owner_origin):
		print("req place")
		# Snap visuel : centre la carte sur la cell
		mask_node.global_position = target_cell.global_position
