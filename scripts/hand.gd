extends Node2D

var MaskScene = preload("res://scenes/Mask.tscn")

func spawn_from_states(state_ids: Array[String]) -> void:
	for i in range(min(state_ids.size(), get_child_count())):
		var st_id: String = state_ids[i]
		var st: MaskState = MaskDB.get_state(st_id)
		if st == null:
			continue

		var def: MaskDef = st.def
		var mask = MaskScene.instantiate()
		add_child(mask)
		mask.bind(def, st_id)
		mask.owner_origin = st.owner
		# snap sur la cellule i de la main
		var hand_cell := get_child(i)
		mask.global_position = hand_cell.global_position
		mask.set_home_pos(mask.global_position)
