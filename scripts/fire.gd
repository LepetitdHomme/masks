extends Node2D

@onready var point_light_2d = $PointLight2D
@onready var defaut_animation = $Node2D/defaut_animation
@onready var burst_animation = $Node2D/burst_animation

var tween : Tween = null
var base_energy : float = 2.5
var flash_energy : float = 4.0
var t_up := 0.08             # temps de montée
var t_down := 0.15            # temps de descente

var color_p1 : Color = Color(0.843, 0.471, 0.125)
var color_p2 : Color = Color(0.196, 0.373, 0.796)

# Called when the node enters the scene tree for the first time.
func _ready():
	defaut_animation.play("orange_0")
	burst_animation.visible = false
	burst_animation.connect("animation_finished", _play_default_animation)
	point_light_2d.energy = base_energy
	EventBus.new_turn.connect(_on_new_turn)
	EventBus.mask_placed.connect(_on_mask_placed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_new_turn(ownr : String) -> void:
	pass


func _play_default_animation():
	#defaut_animation.visible = true
	burst_animation.visible = false
	#defaut_animation.play("orange_0")

func _play_burst():
	burst_animation.visible = true
	#defaut_animation.visible = false
	burst_animation.play("orange_burst")

func _on_mask_placed(ownr : String) -> void:
	# PLAY BURST OF FIRE
	_play_burst()
	# PLAY BURST OF LIGHT
	if tween:
		tween.kill()
 # (optionnel) réinitialise au niveau de base
	point_light_2d.energy = base_energy
	point_light_2d.enabled = true

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# monte vite jusqu'au pic
	tween.tween_property(point_light_2d, "energy", flash_energy, t_up)
	# redescend en douceur vers la base
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(point_light_2d, "energy", base_energy, t_down)
