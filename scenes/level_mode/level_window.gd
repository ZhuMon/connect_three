extends Node2D

var level_file_path: String

var grid_scene = preload("res://scenes/grid.tscn")
var grid_scene_instance = null
var level_info = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # load the level
    grid_scene_instance = grid_scene.instantiate()
    grid_scene_instance.position = Vector2(0, 0)
    add_child(grid_scene_instance)

    level_info = grid_scene_instance.get_level_info_from_file(level_file_path)
    start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func start():
    grid_scene_instance.spawn_level_pieces(level_info)
    grid_scene_instance.start()

func _on_restart_button_pressed() -> void:
    grid_scene_instance.free_all_pieces()
    start()

func _on_menu_button_pressed() -> void:
    Global.goto_scene("levels", {})