# Getting Started: A Top-Down, Turn-Based Tactics Game in Godot (Warhammer 40k style)

This guide takes you from "empty Godot project" to "I can select a unit and move it across the battlefield." It's structured so the foundation supports the later phases (shooting, charging, fighting) without a rewrite.

---

## 1. Install & Set Up Godot

1. Download **Godot 4.x** from godotengine.org (get the "Standard" version, not .NET, unless you specifically want C#).
2. Open Godot → **New Project** → pick a folder → **Create & Edit**.
3. Project Settings to change early:
   - **Display → Window → Size**: set a sensible base resolution (e.g. 1920x1080) and set **Stretch Mode** to `canvas_items` so it scales cleanly.
   - **Rendering → Renderer**: "Forward+" (default) is fine, or "Mobile" if targeting weaker hardware.

---

## 2. Decide: 2D or 3D?

Warhammer 40k's tabletop is inherently a **3D board viewed from an angled/top-down camera**, but you have two honest options:

| Approach | Pros | Cons |
|---|---|---|
| **2D (top-down sprites)** | Much faster to build, simpler collision/movement math, easier UI | Flatter look, models are just sprites |
| **3D (orthographic/angled camera)** | Looks and feels closer to the tabletop, models can be real minis | More setup complexity (lighting, cameras, 3D collision) |

**Recommendation:** Start in **3D with an orthographic camera**. This gets you the "tabletop wargame" look (you can literally use 3D models later) while movement/turn logic is identical either way. If you'd rather move faster and worry about visuals later, 2D top-down is equally valid — just substitute `Node2D`/`Sprite2D` for `Node3D`/`MeshInstance3D` below.

This guide assumes **3D**.

---

## 3. Core Scene Structure

Set up your scene tree like this to start:

```
Main (Node3D)
├── Battlefield (Node3D)          # the "table" — terrain, environment
│   └── Ground (MeshInstance3D + StaticBody3D)  # for raycasting clicks
├── Camera (Camera3D)              # orthographic, angled down
├── Units (Node3D)                 # container for all unit instances
├── GameManager (Node)             # turn/phase logic
└── UI (CanvasLayer)                # unit info, phase indicator etc.
```

### Ground / Battlefield
- Add a large flat `MeshInstance3D` (a `PlaneMesh` works) with a `StaticBody3D` + `CollisionShape3D`. You need this so mouse clicks can be translated into world positions via raycasting.
- This is also where you'll later add terrain features (cover, ruins) that affect movement/line of sight.

### Camera
- Add a `Camera3D`, set **Projection → Orthogonal** (this avoids perspective distortion, giving you that clean tabletop read).
- Angle it downward (e.g. rotate ~45–60° on the X axis) and position it above/behind the battlefield.
- Optionally script simple pan/zoom controls later — not needed for step one.

---

## 4. Build a Unit

In Warhammer 40k, a **Unit** is a squad made of individual **Models**. Structure this as two scene types:

### `Model.tscn` (a single miniature)
```
Model (Node3D)
├── Mesh (MeshInstance3D)        # placeholder: capsule or box for now
├── CollisionShape3D              # for click-selection later
```
Keep this dumb — it just represents visual position. Its own script can be minimal:

```gdscript
# Model.gd
extends Node3D

var base_size: float = 0.5  # tabletop "base" radius, useful later for coherency checks
```

### `Unit.tscn` (a squad)
```
Unit (Node3D)
├── Model1 (instance of Model.tscn)
├── Model2 (instance of Model.tscn)
├── Model3 (instance of Model.tscn)
```

Give `Unit` a script that tracks state and moves its models together:

```gdscript
# Unit.gd
extends Node3D
class_name Unit

@export var unit_name: String = "Tactical Squad"
@export var movement_range: float = 6.0   # inches-equivalent; pick a unit scale
@export var models: Array[Node3D] = []

var has_moved_this_turn: bool = false
var selected: bool = false

func _ready():
    # Auto-collect model children if not manually assigned
    if models.is_empty():
        for child in get_children():
            if child is Node3D:
                models.append(child)

func select():
    selected = true
    # TODO: visual highlight (outline shader, selection ring decal, etc.)

func deselect():
    selected = false

func move_to(target_position: Vector3):
    if has_moved_this_turn:
        return
    # Simple version: move whole unit's origin, models keep formation
    var offset = target_position - global_position
    global_position = target_position
    has_moved_this_turn = true
```

**Why models are separate nodes:** later you'll want individual model removal (casualties), unit coherency checks (models must stay within X of each other), and per-model line-of-sight for shooting — all of which need each model to exist independently rather than as one blob sprite.

For now, arrange 3–10 `Model` instances inside a `Unit` in a simple grid/line formation directly in the editor.

---

## 5. Selecting & Moving Units (the first playable slice)

This is the part you asked to get working first. Approach: **raycast from mouse click into the 3D world**, and either select a unit under the cursor, or move the currently selected unit to the clicked point.

Add a script to your `GameManager` node:

```gdscript
# GameManager.gd
extends Node

@onready var camera: Camera3D = $"../Camera"
var selected_unit: Unit = null

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
        # Clicked on a unit -> select it
        var unit = hit_object if hit_object is Unit else hit_object.get_parent()
        _select_unit(unit)
    else:
        # Clicked on ground -> move selected unit there
        if selected_unit:
            selected_unit.move_to(result.position)

func _select_unit(unit: Unit) -> void:
    if selected_unit:
        selected_unit.deselect()
    selected_unit = unit
    selected_unit.select()
```

**Important setup detail:** for the unit-click detection (`hit_object is Unit`) to work, your `Unit`'s collision shape needs to be a `StaticBody3D`/`Area3D` that the raycast can hit — either put a `CollisionShape3D` directly under `Unit`, or check `get_parent()` up the tree from whichever model was clicked (the code above does the one-level version; extend it if your hierarchy is deeper).

At this point you can: click a unit to select it, click the ground to move it. That's your first playable loop.

---

## 6. Movement Range Constraint (tabletop-accurate)

Right now `move_to()` moves anywhere. To respect movement range like the tabletop:

```gdscript
func move_to(target_position: Vector3):
    if has_moved_this_turn:
        return
    var distance = global_position.distance_to(target_position)
    if distance > movement_range:
        print("Target out of movement range!")
        return
    global_position = target_position
    has_moved_this_turn = true
```

You'll likely want a **visual range indicator** (a translucent circle/cylinder mesh scaled to `movement_range`) that appears when a unit is selected — a `MeshInstance3D` with a `CylinderMesh` (very flat) and a semi-transparent material works well for this.

---

## 7. Phases & Turn Structure

Since the whole game is built around Movement → Shooting → Charge → Fight phases, set that up early even if only Movement does anything yet:

```gdscript
# GameManager.gd (add to it)
enum Phase { MOVEMENT, SHOOTING, CHARGE, FIGHT }
var current_phase: Phase = Phase.MOVEMENT
var current_player: int = 1

func next_phase():
    match current_phase:
        Phase.MOVEMENT: current_phase = Phase.SHOOTING
        Phase.SHOOTING: current_phase = Phase.CHARGE
        Phase.CHARGE: current_phase = Phase.FIGHT
        Phase.FIGHT:
            current_phase = Phase.MOVEMENT
            _end_turn()

func _end_turn():
    current_player = 2 if current_player == 1 else 1
    for unit in get_tree().get_nodes_in_group("units"):
        unit.has_moved_this_turn = false
```

Gate `_handle_click`'s move logic behind `if current_phase == Phase.MOVEMENT:` — this way clicking during the Shooting phase can later trigger a different action (target selection) instead of movement.

Add units to a `"units"` group (Node → Groups tab in the editor, or `add_to_group("units")` in code) so `GameManager` can iterate over them without hardcoding references.

---

## 8. Suggested Order of Work From Here

1. ✅ Select unit → move within range (you'll have this after the above)
2. Add a **UI phase indicator** and a "Next Phase" / "End Turn" button
3. Add **movement range visualization** (the translucent circle)
4. Add **unit coherency checks** (models within X units of each other after a move)
5. Add **Shooting phase**: click enemy unit while in range → resolve simple hit/wound/save rolls
6. Add **Charge phase**: distance check + charge roll, move into engagement range
7. Add **Fight phase**: melee resolution, similar dice-roll structure to shooting
8. Layer in **stat blocks** (Movement, Toughness, Save, Wounds, etc.) as `Resource` files so units are data-driven rather than hardcoded

---

## 9. A Note on Scale

Pick one "unit of measurement" early (e.g. 1 Godot unit = 1 tabletop inch) and stay consistent across movement ranges, weapon ranges, and charge distances — it'll save you constant re-conversion headaches later.

---

## 10. Version Control

Since you're already setting this up with GitHub: commit after each numbered step above. Turn-based tactics games are easy to break subtly (e.g. a phase-gating bug that lets you move during shooting), so small, revertible commits will save you time.
