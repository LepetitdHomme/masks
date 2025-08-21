extends Resource
class_name MaskDef

@export var mask_id: String = ""
@export var display_name: String = ""

@export var art_texture : Texture2D
@export var shadow_texture : Texture2D
@export var tint_color : Color = Color.WHITE

@export var base_top: int = 1
@export var base_right: int = 1
@export var base_bottom: int = 1
@export var base_left: int = 1
