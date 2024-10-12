extends Node2D

signal pieces_cleaned

# Grid Variables
@export var width: int = 10;
@export var height: int = 9;
@export var x_start: int = 128;
@export var y_start: int = 600;
@export var offset: int = 64;

var piece_images = {
    "Blue": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Blue Piece.png"),
    "Green": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Green Piece.png"),
    "Light Green": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Light Green Piece.png"),
    "Orange": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Orange Piece.png"),
    "Pink": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Pink Piece.png"),
    "Yellow": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Yellow Piece.png"),
    "Concrete": load("res://img/Match 3 Assets/Match 3 Assets/Obstacles/Concrete.png"),
}
var piece_scene = preload("res://scenes/pieces/piece.tscn")

var all_pieces = []
var saved_pieces = [] # initial map
var not_matchable = ["Concrete", ""]
var history_pieces = []

# Record the chosen piece
var first_choose = Vector2(0, 0)
var final_choose = Vector2(0, 0)
var controlling = false

var is_started = false
var color_to_change = ""

var is_in_editor = OS.has_feature("editor")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    all_pieces = make_2d_array()
    saved_pieces = make_2d_array()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    touch_input()

func make_2d_array():
    var array = [];
    for i in width:
        array.append([])
        for j in height:
            array[i].append(null)
    return array

func new_piece(color: String, column: int, row: int):
    if !color in piece_images:
        push_error("color not in piece_images: " + color)
        return

    var piece = piece_scene.instantiate()
    piece.position = grid_to_pixel(column, row)
    piece.color = color
    piece.get_node("Sprite2D").texture = piece_images[color]

    add_child(piece)
    return piece

func spawn_all_concrete_pieces():
    for column in width:
        for row in height:
            all_pieces[column][row] = new_piece("Concrete", column, row)

func spawn_level_pieces(level_info: Array):
    var level_width = level_info.size()
    var level_height = level_info[0].size()
    if level_width != width or level_height != height:
        print("level width or height not match")
        return

    for column in width:
        for row in height:
            var color = level_info[column][row]
            if color != "":
                all_pieces[column][row] = new_piece(color, column, row)

func spawn_random_pieces():
    spawn_random_piece()

func spawn_random_piece() -> bool:
    var num = RandomConfig.color_count

    print("spawn_random_pieces: num: ", num)

    # choose the color
    var color = "Blue"

    # choose one connect type
    var connect_type = RandomConfig.get_random_connect_type()

    print("spawn_random_pieces: connect_type: ", connect_type)

    var retry = 0

    while retry < 10:
        # choose the first piece position
        var first_pos = RandomConfig.get_first_piece_position(connect_type, width, height)
        var can_move_up = true

        # check whether the piece position is valid
        if all_pieces[first_pos.x][height - 1] != null:
            retry += 1
            print("spawn_random_pieces: all_pieces[first_pos.x][height - 1] != null")
            continue
        for shape in connect_type["shape"]:
            var pos = first_pos + shape
            if all_pieces[pos.x][height - 1 - shape.y] != null:
                can_move_up = false
                break

        if !can_move_up:
            retry += 1
            print("spawn_random_pieces: !can_move_up")
            continue

        # move up the column
        move_up_column(first_pos)
        all_pieces[first_pos.x][first_pos.y] = new_piece(color, first_pos.x, first_pos.y)

        # move up other columns
        for shape in connect_type["shape"]:
            var pos = first_pos + shape
            move_up_column(pos)
            all_pieces[pos.x][pos.y] = new_piece(color, pos.x, pos.y)

        break

    if retry >= 10:
        print("spawn_random_pieces: retry >= 10")
        return false
    
    return true


func move_up_column(grid_pos: Vector2) -> bool:
    # if the top piece is not null, return error
    if all_pieces[grid_pos.x][height - 1] != null:
        print("top piece is not null")
        return false

    for i in range(height - 2, grid_pos.y, -1):
        if all_pieces[grid_pos.x][i] == null:
            continue
        assert(all_pieces[grid_pos.x][i + 1] == null)

        all_pieces[grid_pos.x][i].move(grid_to_pixel(grid_pos.x, i + 1))
        all_pieces[grid_pos.x][i + 1] = all_pieces[grid_pos.x][i]
        all_pieces[grid_pos.x][i] = null

    return true


func grid_to_pixel(column, row):
    var new_x = x_start + offset * column;
    var new_y = y_start + -offset * row;
    return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x, pixel_y):
    var new_x = round((pixel_x - x_start) / offset);
    var new_y = round((pixel_y - y_start) / -offset);
    return Vector2(new_x, new_y);

func is_in_grid(mouse_grid):
    return Rect2(0, 0, width, height).has_point(mouse_grid)

func touch_input():
    if Input.is_action_just_pressed("left_mouse"):
        var mouse_position = get_global_mouse_position()
        var mouse_grid = pixel_to_grid(mouse_position.x, mouse_position.y);
        if is_in_grid(mouse_grid):
            first_choose = mouse_grid
            controlling = true
    if Input.is_action_just_released("left_mouse"):
        var mouse_position = get_global_mouse_position()
        var mouse_grid = pixel_to_grid(mouse_position.x, mouse_position.y);
        if is_in_grid(mouse_grid):
            final_choose = mouse_grid
            if !is_started and first_choose == final_choose:
                fill_color()
                return
            touch_difference(first_choose, final_choose)
            controlling = false

func swap_pieces(column, row, direction):
    var first_piece = all_pieces[column][row]
    var other_piece = all_pieces[column + direction.x][row + direction.y]

    if not is_instance_valid(first_piece) or not is_instance_valid(other_piece):
        return
    if first_piece.color in not_matchable or other_piece.color in not_matchable:
        return
    if first_piece.color == other_piece.color:
        return

    all_pieces[column][row] = other_piece;
    all_pieces[column + direction.x][row + direction.y] = first_piece;
    first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
    other_piece.move(grid_to_pixel(column, row))

    var matches = find_matches()
    if len(matches) == 0:
        # swap back
        all_pieces[column][row] = first_piece
        all_pieces[column + direction.x][row + direction.y] = other_piece
        first_piece.move(grid_to_pixel(column, row))
        other_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
        return

    for match in matches:
        mark_matched_and_dim(match.x, match.y)

    get_node("DestroyTimer").start()

func touch_difference(grid_1, grid_2):
    var difference = grid_2 - grid_1
    if abs(difference.x) + abs(difference.y) != 1:
        return

    swap_pieces(grid_1.x, grid_1.y, difference)

func _on_chosen_color_changed(chosen_color: String) -> void:
    color_to_change = chosen_color
    print("_on_chosen_color_changed: color_to_change: ", color_to_change)

func change_color(piece: Node2D, color: String):
    piece.color = color
    var node = piece.get_node("Sprite2D")
    node.texture = piece_images[color]

func fill_color():
    if !controlling:
        return

    var color_to_change_this_time = color_to_change
    if color_to_change == "":
        color_to_change_this_time = "Concrete"
        print("color_to_change is empty")

    var piece = all_pieces[first_choose.x][first_choose.y]
    if piece.color == color_to_change_this_time:
        # clean the chosen color
        print("piece color is the same as color_to_change")
        if color_to_change_this_time == "Concrete":
            # aim to change concrete to concrete, do nothing
            return
        color_to_change_this_time = "Concrete"

    change_color(piece, color_to_change_this_time)

    print("change ", first_choose, " to color: ", color_to_change_this_time)

func find_matches() -> Array:
    var matches = []
    for column in range(width):
        for row in range(height):
            if all_pieces[column][row] != null:
                var current_color = all_pieces[column][row].color
                if current_color in not_matchable:
                    continue
                if column > 0 and column < width - 1:
                    if all_pieces[column - 1][row] != null && all_pieces[column + 1][row] != null:
                        if all_pieces[column - 1][row].color == current_color && all_pieces[column + 1][row].color == current_color:
                            matches.append(Vector2(column - 1, row))
                            matches.append(Vector2(column, row))
                            matches.append(Vector2(column + 1, row))
                if row > 0 and row < height - 1:
                    if all_pieces[column][row - 1] != null && all_pieces[column][row + 1] != null:
                        if all_pieces[column][row - 1].color == current_color && all_pieces[column][row + 1].color == current_color:
                            matches.append(Vector2(column, row - 1))
                            matches.append(Vector2(column, row))
                            matches.append(Vector2(column, row + 1))
    return matches

func mark_matched_and_dim(column, row):
    all_pieces[column][row].matched = true
    all_pieces[column][row].dim()

func destroy_matches():
    for column in width:
        for row in height:
            if all_pieces[column][row] != null and all_pieces[column][row].color != "" and all_pieces[column][row].matched:
                all_pieces[column][row].queue_free()

    # collapse pieces
    get_node("CollapseTimer").start()

func collapse_pieces():
    print("collapse_pieces")
    for column in width:
        for row in height:
            if all_pieces[column][row] == null:
                for i in range(row + 1, height):
                    if all_pieces[column][i] != null:
                        all_pieces[column][row] = all_pieces[column][i]
                        all_pieces[column][i] = null
                        all_pieces[column][row].move(grid_to_pixel(column, row))
                        break

    # check if there are still matches
    var matches = find_matches()
    if len(matches) > 0:
        for match in matches:
            mark_matched_and_dim(match.x, match.y)
        get_node("DestroyTimer").start()
        return

    # check if there are pieces
    var has_pieces = false
    for column in width:
        for row in height:
            if all_pieces[column][row] != null:
                has_pieces = true
                break

    if !has_pieces:
        emit_signal("pieces_cleaned")


func _on_destroy_timer_timeout() -> void:
    destroy_matches()

func _on_collapse_timer_timeout() -> void:
    collapse_pieces()


func start():
    is_started = true

func clean_concrete_pieces():
    for column in width:
        for row in height:
            if all_pieces[column][row] != null and all_pieces[column][row].color == "Concrete":
                all_pieces[column][row].queue_free()
                all_pieces[column][row] = null
    get_node("CollapseTimer").start()

func rotate_90_clockwise(array):
    var rows = array.size()
    var cols = array[0].size()
    var rotated = []

    for i in range(cols):
        rotated.append([])

    for i in range(cols):
        for j in range(rows):
            if array[j][i] == "Concrete":
                rotated[i].append("")
            else:
                rotated[i].append(array[rows - 1 - j][i])

    return rotated

func rotate_90_counterclockwise(array):
    var rows = array.size()
    var cols = array[0].size()
    var rotated = []

    for i in range(cols):
        rotated.append([])

    for i in range(cols):
        for j in range(rows):
            if array[j][i] == "Concrete":
                rotated[cols - 1 - i].append("")
            else:
                rotated[cols - 1 - i].append(array[j][i])

    return rotated

func save_template():
    saved_pieces = make_2d_array()

    for column in width:
        for row in height:
            if all_pieces[column][row] != null:
                saved_pieces[column][row] = all_pieces[column][row].color
            else:
                saved_pieces[column][row] = "Concrete"


    # if debug mode is on
    if is_in_editor:
        var rotated_pieces = rotate_90_counterclockwise(saved_pieces)

        var file = FileAccess.open("user://saved_level.csv", FileAccess.WRITE)

        for row in rotated_pieces:
            file.store_csv_line(row)
        file.close()
        print("saved to user://saved_level.csv")

func get_level_info_from_file(file_name: String):
    var file = FileAccess.open("res://levels/" + file_name, FileAccess.READ)
    if !file:
        print("error: file not found")
        return

    var level_info = []
    while !file.eof_reached():
        var row = file.get_csv_line()
        if row.size() == 1:
            continue
        level_info.append(row)

    file.close()

    level_info = rotate_90_clockwise(level_info)

    return level_info

func restore_template():
    free_all_pieces()

    for column in width:
        for row in height:
            var saved_color = saved_pieces[column][row]
            if saved_color != null:
                all_pieces[column][row] = new_piece(saved_color, column, row)

    is_started = false


func reset():
    free_all_pieces()
    spawn_all_concrete_pieces()
    is_started = false


func free_all_pieces():
    for column in width:
        for row in height:
            if all_pieces[column][row] != null:
                all_pieces[column][row].queue_free()
