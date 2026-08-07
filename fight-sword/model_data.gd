class_name ModelData
extends Resource

@export var model_type_id: String = "" 
@export var display_name: String = "Rifleman" #displays on screen ui
@export var max_health: int = 1 # hitpoints

#stats
@export var weapon_skill: int = 4
@export var toughness: int = 3
@export var save: int = 5

#weapon details
@export var weapon_name: String = "Rifle" 
@export var weapon_damage: int = 1
@export var weapon_range: float = 24.0
@export var weapon_shots: int =1
@export var weapon_ap: int = 0
@export var weapon_strength: int = 4



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
