class_name GameManager
extends Node

@onready var resolve_shooting_button = $"../UI/ResolveShootingButton"

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

#shooting states
var shooting_unit: Unit = null
var active_model: BattleModel = null
var weapon_assignments: Dictionary = {}

var allocating_damage: bool = false
var pending_damage_amount: int = 0
var pending_damage_target: Unit = null 
var damage_queue: Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	move_marker.visible = false
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	resolve_shooting_button.pressed.connect(_on_resolve_shooting_pressed)
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
	
	if allocating_damage:
		_handle_damage_allocation_click(hit_object)
		return
	
	if current_phase == Phase.SHOOTING:
		_handle_shooting_click(hit_object)
		return
	
	var clicked_unit = _resolve_clicked_unit(hit_object)
	if clicked_unit:
		_request_select(clicked_unit)
	else:
		if selected_unit:
			_request_move(selected_unit, result.position)
			
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
	

func _handle_shooting_click(hit_object: Node) -> void:
	var model_node = hit_object if hit_object is BattleModel else hit_object.get_parent()
	var owning_unit = _resolve_clicked_unit(hit_object)
	if owning_unit == null:
		return

	if owning_unit.owner_player == current_player:
		if shooting_unit != owning_unit:
			_select_shooting_unit(owning_unit)
		elif model_node is BattleModel:
			active_model = model_node
			print("Active weapon: ", model_node.model_data.weapon_name)
	else:
		if active_model != null:
			weapon_assignments[active_model] = owning_unit
			print("%s assigned to fire at %s" % [active_model.model_data.weapon_name, owning_unit.unit_data.display_name])
			active_model = null
			
			
func _select_shooting_unit(unit: Unit) -> void:
	if unit.has_shot_this_turn:
		print("This unit has already shot this turn!")
		return
	shooting_unit = unit
	active_model = null
	weapon_assignments.clear()
	unit_panel.update_panel(unit)
	print("shooting wiht: ", unit.unit_data.display_name)
	
func _handle_damage_allocation_click(hit_object: Node) -> void:
	var model_node = hit_object if hit_object is BattleModel else hit_object.get_parent()
	if not (model_node is BattleModel):
		return
	if model_node.get_owning_unit() != pending_damage_target or not model_node.is_alive:
		return
	
	model_node.take_damage(pending_damage_amount)
	print("%s took %d damage" % [model_node.model_data.display_name, pending_damage_amount])
	
	_pop_next_damage_instance()
	
func _on_resolve_shooting_pressed() -> void:
	if shooting_unit == null or current_phase != Phase.SHOOTING:
		return
	_resolve_shooting()


func _resolve_shooting() -> void:
	for model in weapon_assignments.keys():
		if not model.is_alive:
			continue
		var target_unit: Unit = weapon_assignments[model]
		var target_models = target_unit.get_alive_models()
		if target_models.is_empty():
			continue
		var data = model.model_data
		var rep_target = target_models[0] #change later
		var hits = CombatResolver.resolve_hits(data.weapon_skill, data.weapon_shots)
		var wounds = CombatResolver.resolve_wounds(data.weapon_strength, rep_target.model_data.toughness, hits)
		var failed_saves = CombatResolver.resolve_failed_saves(rep_target.model_data.save, data.weapon_ap, wounds)
		
		print("%s fires at %s: %d hits, %d wounds, %d failed saves" % [data.weapon_name, target_unit.unit_data.display_name, hits, wounds, failed_saves])
		
		for i in failed_saves:
			_queue_damage(target_unit, data.weapon_damage)
		
	shooting_unit.has_shot_this_turn = true
	shooting_unit = null
	active_model = null
	weapon_assignments.clear()
		
func _queue_damage(target_unit: Unit, amount: int) -> void:
	damage_queue.append({"target": target_unit, "amount": amount})
	if not allocating_damage:
		_pop_next_damage_instance()

func _pop_next_damage_instance() -> void:
	if damage_queue.is_empty():
		allocating_damage = false
		pending_damage_target = null
		return
	var entry = damage_queue.pop_front()
	allocating_damage = true
	pending_damage_target = entry["target"]
	pending_damage_amount = entry["amount"]
	print("Player %d: click a model on %s to allocate %d damage" % [
		3 - current_player, entry["target"].unit_data.display_name, entry["amount"]
	])
#resolve click helper
func _resolve_clicked_unit(hit_object: Node) -> Unit:
	if hit_object is BattleModel:
		return hit_object.get_owning_unit()
	if hit_object is Unit:
		return hit_object
	var parent = hit_object.get_parent()
	if parent is BattleModel:
		return parent.get_owning_unit()
	if parent is Unit:
		return parent
	return null
