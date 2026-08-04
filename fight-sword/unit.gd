extends Node3D
class_name Unit

@export var unit_name: String = "Tactical Squad"
@export var movement_range: float = 6.0
@export var models: Array[Node3D] = []

var has_moved_this_turn: bool= false
var selected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
    if models.is_empty():
        for child in get_children():
            if child is Node3D:
                models.append(child)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func select():
    selected = true
    #add visual identifier here

func deselect():
    selected = false

func move_to(target_position: Vector3):
    if has_moved_this_turn:
        return
    var offset = target_position - global_position
    global_position = target_position
    has_moved_this_turn = true
    print("moved to: ", target_position)
