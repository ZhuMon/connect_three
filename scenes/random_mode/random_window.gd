extends Node2D

var grid_scene = preload("res://scenes/grid.tscn")
var grid_scene_instance = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    grid_scene_instance = grid_scene.instantiate()
    grid_scene_instance.position = Vector2(0, 0)

    add_child(grid_scene_instance)

    grid_scene_instance.spawn_random_pieces()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _on_menu_button_pressed() -> void:
    Global.goto_scene("menu", {})