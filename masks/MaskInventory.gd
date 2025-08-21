extends Node
# autoloaded as MaskDB
var states : Dictionary = {} # state_id : String - > MaskState
var _seq: int = 0

func _gen_id() -> String:
	_seq += 1
	return "msk_%d_%d" % [Time.get_ticks_usec(), _seq]  # microsec + compteur

func add_from_def(def : MaskDef, ownr : String = "") -> MaskState:
	if ownr.is_empty():
		print_debug("no owner to mask state")
		return
	var id : String = _gen_id()
	var st : MaskState = MaskState.new(id, def, ownr)
	states[id] = st
	return st

func get_state(id : String) -> MaskState:
	var value : MaskState = states.get(id)
	return value if value is MaskState else null

func remove_state(id : String) -> void:
	states.erase(id)
