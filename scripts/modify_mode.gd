extends CheckButton

var colors = ["Blue", "Green", "Light Green", "Orange", "Pink", "Yellow"]
var change_colors: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for color in colors:
		var change_color = TextureButton.new()
		var piece_path = "res://img/Match 3 Assets/Match 3 Assets/Pieces/" + color + " Piece.png"
		var adjacent_path = "res://img/Match 3 Assets/Match 3 Assets/Pieces/" + color + " Adjacent.png"
		change_color.texture_normal = load(piece_path)
		change_color.texture_pressed = load(adjacent_path)
		change_color.toggle_mode = true
		change_color.scale = Vector2(0.5, 0.5)
		change_color.position = Vector2(0, 30 + 64 * colors.find(color))

		# customize a parameter for the button
		change_color.set_meta("color", color)

		change_color.connect("pressed", _on_change_color_pressed)

		add_child(change_color)

		change_colors.append(change_color)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_change_color_pressed():
	# print(self.get_meta("color"))
	print(self.get_meta_list()

func get_color():
	for change_color in change_colors:
		if change_color.pressed:
			return colors[change_colors.find(change_color)]
	return null


func _on_collapse_timer_timeout() -> void:
	pass # Replace with function body.
