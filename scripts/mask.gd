extends Node2D

@onready var sprite_2d = $Sprite2D
@onready var shadow = $Sprite2D/shadow

@export var def : MaskDef # data
var state_id : String = "" # instance runtime
var ownr_origin : String = "" # "P1" / "P2" from state

var mouse_in : bool = false
var is_dragging : bool = false
var draggable : bool = true # if mask played, can't be dragged anymore
var current_goal_scale : Vector2 = Vector2(0.2,0.2)
var scale_tween : Tween
var last_pos : Vector2
var max_card_rotation : float = 12.5
var is_inside_droppable : bool = false
var home_tween : Tween
var home_pos : Vector2 # used to return back to last position if drop not allowed
var body_ref
# temporary labels for values (get vals from state)
@onready var label = $Labels/Label
@onready var label_2 = $Labels/Label2
@onready var label_3 = $Labels/Label3
@onready var label_4 = $Labels/Label4

func _ready():
	EventBus.mask_drop_success.connect(_on_mask_played)
	if def:
		sprite_2d.texture = def.art_texture
		shadow.texture = def.shadow_texture
		#sprite_2d.modulate = def.tint_color

func _process(delta):
	drag_logic(delta)

func set_home_pos(p : Vector2) -> void:
	home_pos = p

func return_home() -> void:
	if home_tween:
		home_tween.kill()
	home_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	home_tween.tween_property(self, "global_position", home_pos, 0.225)

func bind(def_in : MaskDef, state_id_in : String, ownr) -> void:
	def = def_in
	state_id = state_id_in
	ownr_origin = ownr
	# TODO: temporary
	#get_state().apply_bonus("right", 3)
	_refresh_visual()
	update_labels()

func update_labels() -> void:
	var st: MaskState = MaskDB.get_state(state_id)
	if st == null:
		label.text = "?"
		label_2.text = "?"
		label_3.text = "?"
		label_4.text = "?"
		return
	label.text    = str(st.val_top())
	label_2.text  = str(st.val_right())
	label_3.text = str(st.val_bottom())
	label_4.text   = str(st.val_left())

func _refresh_visual() -> void:
	if def:
		sprite_2d.texture = def.art_texture
		shadow.texture = def.shadow_texture
		#sprite_2d.modulate = def.tint_color

func get_state() -> MaskState:
	return MaskDB.get_state(state_id)

func get_vals() -> Dictionary:
	var st: MaskState = get_state()
	if st == null:
		return {"top": 0, "right": 0, "bottom": 0, "left": 0}
	return {
		"top": st.val_top(),
		"right": st.val_right(),
		"bottom": st.val_bottom(),
		"left": st.val_left()
	}

func drag_logic(delta: float) -> void:
	if not draggable:
		return
	shadow.position = Vector2(-12, 12).rotated(sprite_2d.rotation)

	# 1) Début du drag (edge)
	if not is_dragging and mouse_in and Input.is_action_just_pressed("click"):
		is_dragging = true
		Mousebrain.node_being_dragged = self
		sprite_2d.z_index = 100
		_change_scale(Vector2(1.2, 1.2))
		# pas de return ici, on laisse bouger dès ce frame

	# 2) Drag en cours
	if is_dragging and Input.is_action_pressed("click"):
		global_position = lerp(global_position, get_global_mouse_position(), 22.0 * delta)
		_set_rotation(delta)
		return

	# 3) Drop (edge)
	if is_dragging and Input.is_action_just_released("click"):
		is_dragging = false
		_change_scale(Vector2(1.0, 1.0))
		sprite_2d.rotation_degrees = lerp(sprite_2d.rotation_degrees, 0.0, 22.0 * delta)
		sprite_2d.z_index = 0

		# Émettre l’event SEULEMENT si on est bien sur une Cell droppable
		if is_inside_droppable and body_ref is Cell:
			EventBus.mask_drop_attempt.emit(body_ref, self, state_id, ownr_origin)
		else:
			return_home()

		if Mousebrain.node_being_dragged == self:
			Mousebrain.node_being_dragged = null
		return

	# 4) Idle (pas de drag)
	sprite_2d.z_index = 0
	_change_scale(Vector2(1.0, 1.0))
	sprite_2d.rotation_degrees = lerp(sprite_2d.rotation_degrees, 0.0, 22.0 * delta)

func _on_mouse_entered():
	mouse_in = true

func _on_mouse_exited():
	mouse_in = false

func _change_scale(desired_scale : Vector2):
	if desired_scale == current_goal_scale:
		return
	if scale_tween:
		scale_tween.kill()
	scale_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(sprite_2d, "scale", desired_scale, 0.125)
	
	current_goal_scale = desired_scale

func _set_rotation(delta : float) -> void:
	var desired_rotation : float = clamp((global_position - last_pos).x * 0.85, -max_card_rotation, max_card_rotation)
	sprite_2d.rotation_degrees = lerp(sprite_2d.rotation_degrees, desired_rotation, 12.0 * delta)

	last_pos = global_position

func _on_area_2d_body_entered(body):
	print("body entered")
	if body.is_in_group('droppable'):
		is_inside_droppable = true
		body_ref = body

func _on_area_2d_body_exited(body):
	print("body ex")
	if body.is_in_group('droppable'):
		if body_ref == body:
			is_inside_droppable = false
			body_ref = null

func _on_mask_played(mask : Node) -> void:
	if mask == self:
		draggable = false
	
