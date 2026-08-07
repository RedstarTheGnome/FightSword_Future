class_name GameManager
extends Node

@onready var move_marker = $"../MoveMarker"
@onready var unit_panel = $"../UI/UnitPanel"

@onready var end_turn_button = $"../UI/EndTurnButton"
@onready var phase_label = $"../UI/PhaseLabel"

@onready var camera: Camera3D = $"../Camera"
var selected_unit: Unit = null 

@export var valid_material : Material
@export var invalid_material : Material


enum Phase {COMMAND, MOVEMENT, SHOOTING, CHARGING, FIGHTING}
var current_phase: Phase = Phase.MOVEMENT
var current_player: int = 1 
	
# Called when the node enters the scene tree for the first time.
func _ready():
	move_marker.visible = false
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_update_phase_label()
	
	#for testing
	#var hits = CombatResolver.resolve_hits(4,5)
	#var wounds = CombatResolver.resolve_wounds(4,3,hits)
	#var fails = CombatResolver.resolve_failed_saves(5, 0, wounds)
	#print("hits:  %d, wounds: %d, failed saves: %d" % [hits,wounds,fails])
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if selected_unit == null:
		move_marker.visible = false
		return
	#Ghost of unit placement
	var mouse_pos= get_viewport().get_mouse_position()
	var space_state = get_viewport().world_3d.direct_space_state
	
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		move_marker.visible = false
		return
	
	move_marker.visible = true
	move_marker.global_position = result.position
	#end ghost
	
	var distance = selected_unit.global_position.distance_to(result.position)
	if distance <= selected_unit.unit_data.movement_range:
		move_marker.get_node("MeshInstance3D").material_override = valid_material
	else:
		move_marker.get_node("MeshInstance3D").material_override = invalid_material

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(screen_pos: Vector2) -> void:
	var space_state = get_viewport().world_3d.direct_space_state
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return
	var hit_object = result.collider
	
	if hit_object is Unit or hit_object.get_parent() is Unit:
		var unit = hit_object if hit_object is Unit else hit_object.get_parent()
		_request_select(unit)
	else:
		if selected_unit:
			_request_move(selected_unit,result.position)
			
func _request_select(unit: Unit):
	if unit.owner_player != current_player:
		print("That's not your unit!")
		return
	_selected_unit(unit)

func _request_move(unit: Unit, target_position: Vector3):
	if unit.owner_player != current_player:
		print("That's not your unit!")
		return
	if current_phase != Phase.MOVEMENT:
		print("Can't move outside Movement phase!")
		return
	unit.move_to(target_position)
func _selected_unit(unit: Unit):
	if selected_unit:
		selected_unit.deselect()
		#unit_panel.update_panel(null)
		
	selected_unit = unit
	selected_unit.select()
	unit_panel.update_panel(unit)
	print("selected: ", unit.unit_data.display_name)
	
func next_phase():
	match current_phase:
		Phase.COMMAND: current_phase = Phase.MOVEMENT
		Phase.MOVEMENT: current_phase = Phase.SHOOTING
		Phase.SHOOTING: current_phase = Phase.CHARGING
		Phase.CHARGING: current_phase = Phase.FIGHTING
		Phase.FIGHTING:
			current_phase = Phase.MOVEMENT
			_end_turn()

func _end_turn():
	current_player = 2 if current_player == 1 else 1
	for unit in get_tree().get_nodes_in_group("units"):
		unit.has_moved_this_turn = false
		unit.has_shot_this_turn = false
		
func _on_end_turn_pressed():
	next_phase()
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	_update_phase_label()

func _update_phase_label():
	phase_label.text = "Player %d - %s" % [current_player, Phase.keys()[current_phase]]		
