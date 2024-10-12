extends Node

var color_count = 3
const connect_types = {
    "h3": {
        "shape": [Vector2(1, 0), Vector2(2, 0)],
        "allowed_position_min_x_delta": 0,
        "allowed_position_max_x_delta": - 2,
    }, # horizontal 3
    "v3": {
        "shape": [Vector2(0, 1), Vector2(0, 2)],
        "allowed_position_min_x_delta": 0,
        "allowed_position_max_x_delta": 0,
    }, # vertical 3
    "h4": {
        "shape": [Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)],
        "allowed_position_min_x_delta": 0,
        "allowed_position_max_x_delta": - 3,
    }, # horizontal 4
    "v4": {
        "shape": [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)],
        "allowed_position_min_x_delta": 0,
        "allowed_position_max_x_delta": 0,
    }, # vertical 4
    "h5": {
        "shape": [Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)],
        "allowed_position_min_x_delta": 0,
        "allowed_position_max_x_delta": - 4,
    }, # horizontal 5
    "v5": {
        "shape": [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(0, 4)],
        "allowed_position_min_x_delta": 0,
        "allowed_position_max_x_delta": 0,
    } # vertical 5
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


func get_random_connect_type():
    var index = RandomNumberGenerator.new().randi_range(0, len(connect_types) - 1)
    return connect_types.values()[index]

func get_first_piece_position(connect_type: Dictionary, width, height):
    var x = RandomNumberGenerator.new().randi_range(0, width - 1)

    x = clampi(x, 0 + connect_type["allowed_position_min_x_delta"], width - 1 + connect_type["allowed_position_max_x_delta"])

    # future: add y

    return Vector2(x, 0)
