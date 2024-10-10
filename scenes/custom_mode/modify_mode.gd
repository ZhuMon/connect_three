extends Control

signal chosen_color_changed(chosen_color: String)

@export var chosen_color: String = ""

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

		change_color.pressed.connect(_on_change_color_toggled.bind(change_color))

		add_child(change_color)

		change_colors.append(change_color)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_change_color_toggled(button: TextureButton) -> void:
	if button.button_pressed:
		print(button.get_meta("color"))
		chosen_color = button.get_meta("color")

		# unpress all other buttons
		for change_color in change_colors:
			if change_color != button:
				change_color.button_pressed = false

	else:
		chosen_color = ""
		print("clean chosen color")

	emit_signal("chosen_color_changed", chosen_color)