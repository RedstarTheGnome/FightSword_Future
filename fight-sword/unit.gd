extends Node3D
class_name Unit

@export var unit_name: String = "Tactical Squad"
@export var movement_range: float = 6.0
@export var models: Array[Node3D] = []

@onready var selection_ring = $SelectionRing
@onready var movement_range_mesh = $MovementRange

var has_moved_this_turn: bool= false
var selected: bool = false

var current_phase: Phase = Phase.MOVEMENT
var current_player: int = 1



#Game phases
enum Phase {COMMAND, MOVEMENT, SHOOTING, CHARGING,FIGHTING}


# Called when the node enters the scene tree for the first time.
func _ready():
	# movement ui sizes
	var diameter = movement_range * 2.0
	movement_range_mesh.scale.x = diameter / 12.0
	movement_range_mesh.scale.z = diameter / 12.0
	
	if models.is_empty():
		for child in get_children():
			if child is Node3D:
				models.append(child)
	selection_ring.visible = false
	movement_range_mesh.visible = false
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func select():
	selected = true
	selection_ring.visible = true
	movement_range_mesh.visible = true

func deselect():
	selected = false
	selection_ring.visible = false
	movement_range_mesh.visible = false

func move_to(target_position: Vector3):
	if has_moved_this_turn:
		return
	var distance = global_position.distance_to(target_position)
	if distance > movement_range:
		print("Target out of movement range!")
		return
	var tween = create_tween()
	
	tween.tween_property(
		self,
		"global_position",
		target_position,
		0.5
	)
	#if tween:
	#	return
	has_moved_this_turn = true
	
	
	print("moved to: ", target_position)
	
func next_phase():
	match current_phase:
		Phase.COMMAND: current_phase = Phase.MOVEMENT
		Phase.MOVEMENT: current_phase = Phase.SHOOTING
		Phase.SHOOTING: current_phase - Phase.CHARGING
		Phase.FIGHTING:
			current_phase = Phase.MOVEMENT
			_end_turn()

func _end_turn():
	current_player = 2 if current_player == 1 else 1
	for unit in get_tree().get_node_in_group("units"):
		unit.has_moved_this_turn = false
