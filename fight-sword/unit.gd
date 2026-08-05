extends Node3D
class_name Unit

@export var unit_name: String = "Tactical Squad"
@export var movement_range: float = 6.0
@export var models: Array[Node3D] = []

var has_moved_this_turn: bool= false
var selected: bool = false

var current_phase: Phase = Phase.MOVEMENT
var current_player: int = 1

enum Phase {MOVEMENT, SHOOTING, CHARGING,FIGHTING}


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
	var distance = global_position.distance_to(target_position)
	if distance > movement_range:
		print("Target out of movement range!")
		return
	global_position = target_position
	has_moved_this_turn = true
	
	
	print("moved to: ", target_position)
	
func next_phase():
	match current_phase:
		Phase.MOVEMENT: current_phase = Phase.SHOOTING
		Phase.SHOOTING: current_phase - Phase.CHARGING
		Phase.FIGHTING:
			current_phase = Phase.MOVEMENT
			_end_turn()

func _end_turn():
	current_player = 2 if current_player == 1 else 1
	for unit in get_tree().get_node_in_group("units"):
		unit.has_moved_this_turn = false
