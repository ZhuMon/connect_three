extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _on_start_button_pressed() -> void:
    Global.goto_scene("levels", {})

func _on_random_button_pressed() -> void:
    Global.goto_scene("random", {})

func _on_custom_button_pressed() -> void:
    Global.goto_scene("custom", {})
