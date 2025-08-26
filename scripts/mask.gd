extends Node2D

@onready var sprite_2d = $Sprite2D
@onready var shadow = $Sprite2D/shadow
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var color_rect = $ColorRect

@export var def : MaskDef # data

const custom_scale = Vector2(0.8, 0.8)
const grab_scale = Vector2(1.0, 1.0)

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


# --- OVERLAY CONFIG ---
const MAX_VAL: int = 10              # on clamp 0..10
const FAN_DEG: float = 40.0          # ouverture de l’éventail par côté
const INNER_R: float = 70.0          # rayon de départ des piques (depuis le centre du masque)
const SPIKE_LEN: float = 80.0        # longueur des piques
const SPIKE_BASE: float = 25.0        # largeur de base d’un triangle
const COLOR_N: Color = Color.INDIAN_RED#(0.35, 0.8, 1.0, 0.9)   # Nord
const COLOR_E: Color = Color.INDIAN_RED#(1.0, 0.55, 0.2, 0.9)   # Est
const COLOR_S: Color = Color.INDIAN_RED#(0.9, 0.2, 0.4, 0.9)    # Sud
const COLOR_W: Color = Color.INDIAN_RED#(0.6, 1.0, 0.4, 0.9)    # Ouest



# temporary labels for values (get vals from state)
@onready var label = $Labels/Label
@onready var label_2 = $Labels/Label2
@onready var label_3 = $Labels/Label3
@onready var label_4 = $Labels/Label4

func _ready():
	scale = custom_scale
	EventBus.mask_drop_success.connect(_on_mask_played)
	if def:
		sprite_2d.texture = def.art_texture
		shadow.texture = def.shadow_texture
		#sprite_2d.modulate = def.tint_color

func _process(delta):
	drag_logic(delta)


func _draw() -> void:
	var st := MaskDB.get_state(state_id)
	if st == null: 
		return
	# NOTE: ton Sprite2D est centré → le (0,0) de ce Node2D est le centre visuel
	_draw_side(st.val_top(),    deg_to_rad(-90.0), COLOR_N)
	_draw_side(st.val_right(),  deg_to_rad(  0.0), COLOR_E)
	_draw_side(st.val_bottom(), deg_to_rad( 90.0), COLOR_S)
	_draw_side(st.val_left(),   deg_to_rad(180.0), COLOR_W)

func _draw_side(val: int, dir_angle: float, col: Color) -> void:
	val = clamp(val, 0, MAX_VAL)
	if val <= 0: 
		return

	# éventail : de -FAN/2 à +FAN/2 autour de l’angle de la direction
	var half_fan := deg_to_rad(FAN_DEG) * 0.5
	var count := val
	for i in range(count):
		var t := 0.0
		if count > 1:
			t = float(i) / float(count - 1)  # 0..1
			t = (t - 0.5) * 2.0              # -1..+1
		# angle per-spike dans l’éventail
		var a := dir_angle + t * half_fan

		# base & pointe du triangle
		var dir := Vector2.RIGHT.rotated(a)                   # vecteur direction
		var ortho := dir.rotated(PI * 0.5).normalized()       # perpendiculaire

		var base_center := dir * INNER_R
		var p0 := base_center + ortho * (SPIKE_BASE * 0.5)
		var p1 := base_center - ortho * (SPIKE_BASE * 0.5)
		var tip := dir * (INNER_R + SPIKE_LEN)

		# (option) léger dégradé alpha selon distance au centre de l’éventail
		var fade = 1.0 - 0.25 * abs(t)
		var c := Color(col.r, col.g, col.b, col.a * fade)

		draw_colored_polygon(PackedVector2Array([p0, p1, tip]), c)

func toggle_color(ownr : String):
	if ownr == "P1":
		color_rect.color = Color.ORANGE_RED
	else:
		color_rect.color = Color.BLUE

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
	toggle_color(ownr)
	# TODO: temporary
	#get_state().apply_bonus("right", 3)
	_refresh_visual()
	update_labels()
	queue_redraw()

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

	# 1) Début du drag (edge)
	if not is_dragging and mouse_in and Input.is_action_just_pressed("click"):
		is_dragging = true
		Mousebrain.node_being_dragged = self
		sprite_2d.z_index = 100
		_change_scale(grab_scale)
		# pas de return ici, on laisse bouger dès ce frame

	# 2) Drag en cours
	if is_dragging and Input.is_action_pressed("click"):
		global_position = lerp(global_position, get_global_mouse_position(), 22.0 * delta)
		_set_rotation(delta)
		return

	# 3) Drop (edge)
	if is_dragging and Input.is_action_just_released("click"):
		is_dragging = false
		_change_scale(custom_scale)
		self.rotation_degrees = 0.0
		#sprite_2d.rotation_degrees = lerp(sprite_2d.rotation_degrees, 0.0, 22.0 * delta)
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
	_change_scale(custom_scale)
	self.rotation_degrees = lerp(sprite_2d.rotation_degrees, 0.0, 22.0 * delta)

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
	scale_tween.tween_property(self, "scale", desired_scale, 0.125)
	
	current_goal_scale = desired_scale

func do_a_flip():
	animation_player.play("flip")

func _set_rotation(delta : float) -> void:
	var desired_rotation : float = clamp((global_position - last_pos).x * 0.85, -max_card_rotation, max_card_rotation)
	self.rotation_degrees = lerp(self.rotation_degrees, desired_rotation, 12.0 * delta)

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
	
