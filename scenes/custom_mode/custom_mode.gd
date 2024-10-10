extends Node2D

var grid_scene = preload("res://scenes/grid.tscn")
var grid_scene_instance = null
var modify_mode_instance = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    grid_scene_instance = grid_scene.instantiate()
    grid_scene_instance.position = Vector2(0, 0)

    add_child(grid_scene_instance)

    modify_mode_instance = get_node("ModifyMode")
    modify_mode_instance.chosen_color_changed.connect(grid_scene_instance._on_chosen_color_changed)
    


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _on_start_button_pressed() -> void:
    grid_scene_instance.clean_concrete_pieces()
    grid_scene_instance.start()


func _on_save_template_button_pressed() -> void:
    grid_scene_instance.save_template()

func _on_restore_template_button_pressed() -> void:
    grid_scene_instance.restore_template()


func _on_reset_button_pressed() -> void:
    grid_scene_instance.reset()