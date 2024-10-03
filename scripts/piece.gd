extends Node2D

@export var color: String
var matched: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func move(pos):
	var tween = create_tween()
	var tweener = tween.tween_property(self, ^"position", pos, .3)
	if tweener == null:
		print("error: tweener is empty")
		return
	tweener.set_ease(Tween.EASE_OUT)
	tweener.set_trans(Tween.TRANS_SINE)
	tween.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func dim():
	var sprite = self.get_node("Sprite2D")
	sprite.modulate = Color(1, 1, 1, 0.5)