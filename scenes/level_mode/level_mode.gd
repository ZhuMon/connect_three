extends Node2D

var level_button = preload("res://scenes/level_mode/level_button.tscn")
var grid_scene = preload("res://scenes/grid.tscn")

var start_x = 32
var start_y = 32
var offset = 64
var num_level_in_row = 5

var level_button_instances = []

var level_info = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # check the how many csv file in the folder
    var dir = DirAccess.open("res://levels")
    if !dir:
        print("Error opening directory")
        return


    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if file_name.ends_with(".csv"):
            var level_button_instance = level_button.instantiate()
            
            # get the level name from the file name (level_1.csv -> 1)
            var level_name = file_name.split("_")[1].split(".")[0]
            level_button_instance.text = level_name

            # calculate the position of the button
            var x = start_x + (int(level_name) - 1) % num_level_in_row * offset
            var y = start_y + (int(level_name) - 1) / num_level_in_row * offset
            level_button_instance.position = Vector2(x, y)

            level_button_instance.level_file_name = file_name
            level_button_instance.level = int(level_name)

            level_button_instance.pressed.connect(_on_level_button_pressed.bind(file_name))
            add_child(level_button_instance)

            level_button_instances.append(level_button_instance)
        file_name = dir.get_next()
    


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _on_level_button_pressed(level_file_path: String) -> void:
    # clean all buttons
    for level_button_instance in level_button_instances:
        level_button_instance.queue_free()

    # load the level
    var grid_scene_instance = grid_scene.instantiate()
    grid_scene_instance.position = Vector2(0, 0)

    add_child(grid_scene_instance)

    level_info = grid_scene_instance.get_level_info_from_file(level_file_path)

    grid_scene_instance.spawn_level_pieces(level_info)