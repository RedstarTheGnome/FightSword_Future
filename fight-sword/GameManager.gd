extends Node

@onready var move_marker = $"../MoveMarker"

@onready var camera: Camera3D = $"../Camera"
var selected_unit: Unit = null 
	
# Called when the node enters the scene tree for the first time.
func _ready():
	move_marker.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if selected_unit == null:
		move_marker.visible = false
		return
	
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
		_selected_unit(unit)
	else:
		if selected_unit:
			selected_unit.move_to(result.position)

func _selected_unit(unit: Unit) -> void:
	if selected_unit:
		selected_unit.deselect()
	selected_unit = unit
	selected_unit.select()
	print("selected: ", unit.unit_name)
