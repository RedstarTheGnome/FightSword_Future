extends Panel
@onready var name_label = $VBoxContainer/NameLabel
@onready var movement_label = $VBoxContainer/MovementLabel
@onready var status_label = $VBoxContainer/StatusLabel



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_panel(unit):
	if unit == null:
		name_label.text = "No Unit Selected"
		movement_label.text = ""
		status_label.text = ""
		return
	
	name_label.text = unit.unit_name
	movement_label.text = "Movement: %s\"" % unit.movement_range
	
	if unit.has_moved_this_turn:
		status_label.text = "Status: Moved"
	else:
		status_label.text= "Status: Ready"
