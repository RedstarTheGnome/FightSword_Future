extends Node3D
class_name Unit

@export var unit_data: UnitData
@export var models: Array[Node3D] = []
@export var owner_player: int = 1
@export var unit_id: String = ""

@onready var selection_ring = $SelectionRing
@onready var movement_range_mesh = $MovementRange

@onready var game_manager = get_tree().get_root().get_node("Main/GameManager")

@export var model_scene: PackedScene 


var has_moved_this_turn: bool= false
var selected: bool = false

var battle_models: Array[BattleModel] = []
var has_shot_this_turn: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("units")
	# movement ui sizes
	var diameter = unit_data.movement_range * 2.0
	movement_range_mesh.scale.x = diameter / 12.0
	movement_range_mesh.scale.z = diameter / 12.0
	
	if models.is_empty():
		for child in get_children():
			if child is Node3D:
				models.append(child)
	selection_ring.visible = false
	movement_range_mesh.visible = false
	_spawn_models()

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
	if game_manager.current_phase != GameManager.Phase.MOVEMENT:
		print("Can't move outside Movement phase!")
		return
	if has_moved_this_turn:
		return
	var distance = global_position.distance_to(target_position)
	if distance > unit_data.movement_range:
		print("Target out of movement range!")
		return
	var tween = create_tween()
	
	tween.tween_property(
		self,
		"global_position",
		target_position,
		0.5
	)
	has_moved_this_turn = true
	movement_range_mesh.visible = false
	
	print("moved to: ", target_position)
	
func _spawn_models() -> void:
	for i in unit_data.model_loadout.size():
		var model_data: ModelData = unit_data.model_loadout[i]
		var model: BattleModel = model_scene.instantiate()
		add_child(model)
		model.initialize(model_data)
		model.position = Vector3(i * 1.5,0,0)
		battle_models.append(model)
			
func get_alive_models () -> Array[BattleModel]:
	return battle_models.filter(func(m): return m.is_alive)
	
