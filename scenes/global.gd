extends Node

var scenes = {
    "levels": preload("res://scenes/level_mode/levels.tscn"),
    "custom": preload("res://scenes/custom_mode/custom_mode.tscn"),
    "level_window": preload("res://scenes/level_mode/level_window.tscn"),
    "menu": preload("res://scenes/init_window.tscn"),
    "random": preload("res://scenes/random_mode/random_window.tscn")
}
var current_scene = null

func _ready():
    var root = get_tree().root
    current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(scene, args):
    # This function will usually be called from a signal callback,
    # or some other function in the current scene.
    # Deleting the current scene at this point is
    # a bad idea, because it may still be executing code.
    # This will result in a crash or unexpected behavior.

    # The solution is to defer the load to a later time, when
    # we can be sure that no code from the current scene is running:

    _deferred_goto_scene.call_deferred(scene, args)


func _deferred_goto_scene(mode, args):
    # It is now safe to remove the current scene.
    current_scene.free()

    # Instance the new scene.
    if mode in scenes:
        print("Loading scene: " + mode)
        current_scene = scenes[mode].instantiate()
        for key in args.keys():
            current_scene.set(key, args[key])
    else:
        print("Unknown mode.")
        return # Unknown mode.

    # Add it to the active scene, as child of root.
    get_tree().root.add_child(current_scene)

    # Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
    get_tree().current_scene = current_scene