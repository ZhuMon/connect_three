extends Node2D

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
var concrete_piece = preload("res://scenes/pieces/concrete_piece.tscn")
var all_pieces = []
var saved_pieces = [] # initial map
var not_matchable = ["Concrete", ""]
var history_pieces = []

# Record the chosen piece
var first_choose = Vector2(0,0)
var final_choose = Vector2(0,0)
var controlling = false

var is_started = false
var color_to_change = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    all_pieces = make_2d_array()
    # get_tree().get_root().get_node("StartButton").hide()

    saved_pieces = make_2d_array()
    spawn_all_concrete_pieces()

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

func spawn_all_concrete_pieces():
    for i in width:
        for j in height:
            var empty_piece = concrete_piece.instantiate()
            add_child(empty_piece);
            empty_piece.position = grid_to_pixel(i, j)
            empty_piece.color = "Concrete"
            all_pieces[i][j] = empty_piece

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
                change_color()
                return
            touch_difference(first_choose, final_choose)
            controlling = false

func swap_pieces(column, row, direction):
    var first_piece = all_pieces[column][row]
    var other_piece = all_pieces[column + direction.x][row+direction.y]

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

func change_color():
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

    piece.color = color_to_change_this_time

    var node = piece.get_node("Sprite2D")
    node.texture = piece_images[color_to_change_this_time]

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
                for i in range(row+1, height):
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



func save_template():
    saved_pieces = make_2d_array()
    for column in width:
        for row in height:
            if all_pieces[column][row] != null:
                saved_pieces[column][row] = all_pieces[column][row].color
            else:
                saved_pieces[column][row] = "Concrete"


func restore_template():
    free_all_pieces()

    for column in width:
        for row in height:
            var saved_color = saved_pieces[column][row]
            if saved_color != null:
                var new_piece = concrete_piece.instantiate()
                new_piece.color = saved_color
                new_piece.position = grid_to_pixel(column, row)

                var node = new_piece.get_node("Sprite2D")
                node.texture = piece_images[saved_color]

                all_pieces[column][row] = new_piece
                add_child(new_piece)

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