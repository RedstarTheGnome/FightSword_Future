extends Node3D
var base_size: float = 0.5

var model_data: ModelData
var current_health: int = 0
var is_alive: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(data: ModelData) -> void:
	model_data = data
	current_health = data.max_health
	is_alive = true
	
func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0  and is_alive:
		die()

func die() -> void:
	is_alive = false
	queue_free()

func get_owning_unit() -> Unit:
	var node = get_parent()
	while node != null and not (node is Unit):
		node = node.get_parent()
	return node
