extends Node2D
class_name Board

const W: int = 3
const H: int = 3
@onready var grid = $grid
@onready var hand_p1 = $HandP1/Hand
@onready var hand_p2 = $HandP2/Hand

@export var cell_size: Vector2 = Vector2(128, 128)
@export var origin: Vector2 = Vector2.ZERO
const MASKS_DIR := "res://masks/masks_definitions"
var masks: Array[MaskDef] = []

var hand_scene = preload("res://scenes/hand.tscn")

enum Dir { TOP, RIGHT, BOTTOM, LEFT }

var cells: Array = []  # Array<Array<Cell>>

func _ready() -> void:
	for f in DirAccess.get_files_at(MASKS_DIR):
		if f.ends_with(".tres"):
			var m := ResourceLoader.load(MASKS_DIR + "/" + f) as MaskDef
			if m:
				masks.append(m)
	_init_cells_grid()

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

func pick_random_mask() -> MaskDef:
	return masks.pick_random()

func init_hands() -> void:
	# pour le POC : créer des MaskState en dur


	var p1_states: Array[String] = [
		MaskDB.add_from_def(pick_random_mask(), "P1").id,
		MaskDB.add_from_def(pick_random_mask(),  "P1").id,
		MaskDB.add_from_def(pick_random_mask(),  "P1").id,
		MaskDB.add_from_def(pick_random_mask(),  "P1").id,
		MaskDB.add_from_def(pick_random_mask(),  "P1").id,
	]
	var p2_states: Array[String] = [
		MaskDB.add_from_def(pick_random_mask(), "P2").id,
		MaskDB.add_from_def(pick_random_mask(),  "P2").id,
		MaskDB.add_from_def(pick_random_mask(),  "P2").id,
		MaskDB.add_from_def(pick_random_mask(),  "P2").id,
		MaskDB.add_from_def(pick_random_mask(),  "P2").id,
	]

	hand_p1.spawn_from_states(p1_states)
	hand_p2.spawn_from_states(p2_states)

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < W and p.y >= 0 and p.y < H

func get_cell(query: Vector2i) -> Cell:
	if not in_bounds(query):
		return null
	var c = cells[query.y][query.x]
	return c if c is Cell else null


func _resolve_captures(center: Cell) -> void:
	var p: Vector2i = center.grid_pos
	var state_new: MaskState = MaskDB.get_state(center.occupant_state_id)
	if state_new == null:
		print_debug("new cell state not found")
		return

	# (voisin, direction_du_nouveau_vers_voisin, direction_opposée_du_voisin)
	var checks: Array = [
		{ "q": Vector2i(p.x, p.y - 1), "d_new": Dir.TOP,    "d_nei": Dir.BOTTOM },
		{ "q": Vector2i(p.x + 1, p.y), "d_new": Dir.RIGHT,  "d_nei": Dir.LEFT   },
		{ "q": Vector2i(p.x, p.y + 1), "d_new": Dir.BOTTOM, "d_nei": Dir.TOP    },
		{ "q": Vector2i(p.x - 1, p.y), "d_new": Dir.LEFT,   "d_nei": Dir.RIGHT  }
	]

	for item in checks:
		var query: Vector2i = item["q"]
		if not in_bounds(query):
			continue
		var cell: Cell = get_cell(query)
		if cell == null:
			continue
		if cell.is_empty():
			continue
		# Compare faces
		var cell_state : MaskState = MaskDB.get_state(cell.occupant_state_id)
		if cell_state == null:
			continue
		var v_new: int = _value_on(state_new, int(item["d_new"]))
		var v_nei: int = _value_on(cell_state, int(item["d_nei"]))
		if v_new > v_nei:
			cell.set_new_owner(cell.current_mask_node, center.owner_current)  # flip (seule la cell change d’owner)
			cell.current_mask_node.do_a_flip()

func _value_on(st: MaskState, dir: int) -> int:
	match dir:
		Dir.TOP:    return st.val_top()
		Dir.RIGHT:  return st.val_right()
		Dir.BOTTOM: return st.val_bottom()
		Dir.LEFT:   return st.val_left()
	return 0
