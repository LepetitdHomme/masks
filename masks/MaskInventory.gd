extends Node
# autoloaded as MaskDB
var states : Dictionary = {} # state_id : String - > MaskState

func _gen_id() -> String:
	return 'msk_%d' % Time.get_ticks_msec()

func add_from_def(def : MaskDef, ownr := "") -> MaskState:
	var id : String = _gen_id()
	var st : MaskState = MaskState.new(id, def, ownr)
	states[id] = st
	return st

func get_state(id : String) -> MaskState:
	var value : MaskState = states.get(id)
	return value if value is MaskState else null

func remove_state(id : String) -> void:
	states.erase(id)
