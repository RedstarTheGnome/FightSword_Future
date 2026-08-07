class_name CombatResolver
extends RefCounted


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

static func roll_d6() -> int:
	return randi_range(1,6)
	
static func wound_threshold(strength: int, toughness: int) -> int:
	if strength >= toughness * 2:
		return 2
	elif strength > toughness:
		return 3
	elif strength == toughness:
		return 4
	elif strength * 2 <= toughness:
		return 6
	else:
		return 5

static func resolve_hits(skill: int, shots: int) -> int:
	var hits := 0
	for i in shots:
		var roll = roll_d6()
		if roll != 1 and roll >= skill:
			hits += 1
	return hits
	
static func resolve_wounds(strength: int, toughness: int, hits: int) -> int:
	var threshold = wound_threshold(strength, toughness)
	var wounds := 0
	for i in hits:
		var roll = roll_d6()
		if roll != 1 and roll >= threshold:
			wounds += 1
	return wounds
	
static func resolve_failed_saves(save: int, ap: int, wounds: int) -> int:
	var modified_save = save + ap
	var failed := 0
	for i in wounds:
		var roll = roll_d6()
		if roll == 1 or roll < modified_save:
			failed += 1
	return failed
	
	
	
