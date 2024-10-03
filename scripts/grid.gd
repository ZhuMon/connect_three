extends Node2D

# Grid Variables
@export var width: int;
@export var height:int;
@export var x_start: int;
@export var y_start: int;
@export var offset: int;

var piece_images = {
	"Blue": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Blue Piece.png"),
	"Green": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Green Piece.png"),
	"Light Green": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Light Green Piece.png"),
	"Orange": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Orange Piece.png"),
	"Pink": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Pink Piece.png"),
	"Yellow": load("res://img/Match 3 Assets/Match 3 Assets/Pieces/Yellow Piece.png"),
	"Concrete": load("res://img/Match 3 Assets/Match 3 Assets/Obstacles/Concrete.png"),
}
var concrete_piece = preload("res://pieces/concrete_piece.tscn")
var all_pieces = [];
var saved_pieces = [];
var not_matchable = ["Concrete", ""]

# Record the chosen piece
var first_choose = Vector2(0,0)
var final_choose = Vector2(0,0)
var controlling = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	all_pieces = make_2d_array()
	spawn_pieces()

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

func spawn_pieces():
	for i in width:
		for j in height:
			var empty_piece = concrete_piece.instantiate()
			add_child(empty_piece);
			empty_piece.position = grid_to_pixel(i, j)
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
			if first_choose == final_choose:
				change_color()
				return
			touch_difference(first_choose, final_choose)
			controlling = false

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row+direction.y]

	if first_piece == null or other_piece == null:
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

	get_parent().get_node("DestroyTimer").start()

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) + abs(difference.y) != 1:
		return

	swap_pieces(grid_1.x, grid_1.y, difference)

func change_color():
	var modified_mode = get_node("/root/GameWindow/ModifyMode")
	if modified_mode == null:
		return

	if !controlling:
		return

	if !modified_mode.is_modified_mode:
		return

	var chosen_color = modified_mode.chosen_color
	if chosen_color == "":
		return

	var piece = all_pieces[first_choose.x][first_choose.y]
	if piece.color == chosen_color:
		# clean the chosen color
		chosen_color = "Concrete"

	piece.color = chosen_color

	var node = piece.get_node("Sprite2D")
	node.texture = piece_images[chosen_color]

	print("change ", first_choose, " to color: ", chosen_color)

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
	get_parent().get_node("CollapseTimer").start()

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
		get_parent().get_node("DestroyTimer").start()

func _on_destroy_timer_timeout() -> void:
	destroy_matches()

func _on_collapse_timer_timeout() -> void:
	collapse_pieces()

func _on_start_button_pressed() -> void:
	# lock the modify mode
	var modify_mode = get_node("/root/GameWindow/ModifyMode")
	modify_mode.is_modified_mode = false
	modify_mode.button_pressed = false

	for column in width:
		for row in height:
			if all_pieces[column][row].color == "Concrete":
				all_pieces[column][row].queue_free()
				all_pieces[column][row] = null


func _on_save_template_button_pressed() -> void:
	saved_pieces = []
	for column in width:
		saved_pieces.append([])
		for row in height:
			if all_pieces[column][row] != null:
				saved_pieces.append(all_pieces[column][row].color)

func _on_restore_template_button_pressed() -> void:
	for column in width:
		for row in height:
			if all_pieces[column][row] != null:
				all_pieces[column][row].queue_free()
	
	for column in width:
		for row in height:
			if saved_pieces[column][row] != null:
				var new_piece = concrete_piece.instantiate()
				new_piece.color = saved_pieces[column][row]
				new_piece.texture = piece_images[saved_pieces[column][row]]
				new_piece.position = grid_to_pixel(column, row)
				all_pieces[column][row] = new_piece
				add_child(new_piece)

	
func _on_reset_button_pressed() -> void:
	for column in width:
		for row in height:
			if all_pieces[column][row] != null:
				all_pieces[column][row].queue_free()

	spawn_pieces()