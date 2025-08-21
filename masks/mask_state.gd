extends RefCounted
class_name MaskState

var id: String
var def: MaskDef
var owner: String = ""      # "P1" / "P2"
var cooldown: int = 0

var bonus_top: int = 0
var bonus_right: int = 0
var bonus_bottom: int = 0
var bonus_left: int = 0

func _init(_id: String, _def: MaskDef, _owner: String = "") -> void:
	id = _id
	def = _def
	owner = _owner

func val_top() -> int:    return def.base_top    + bonus_top
func val_right() -> int:  return def.base_right  + bonus_right
func val_bottom() -> int: return def.base_bottom + bonus_bottom
func val_left() -> int:   return def.base_left   + bonus_left

func apply_bonus(dir: String, delta: int) -> void:
	match dir:
		"top":    bonus_top += delta
		"right":  bonus_right += delta
		"bottom": bonus_bottom += delta
		"left":   bonus_left += delta
