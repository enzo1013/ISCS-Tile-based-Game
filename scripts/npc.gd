extends CharacterBody2D

@export var tile_size: Vector2 = Vector2(16, 16)
@export var move_time: float = 0.2

@export var tilemap_layer: TileMapLayer

@export var use_patrol_area: bool = false
@export var patrol_origin_tile: Vector2i = Vector2i(0, 0)  # top-left tile of patrol area
@export var patrol_size_tiles: Vector2i = Vector2i(5, 5)   # width/height in tiles

@export var idle_time_min: float = 0.5
@export var idle_time_max: float = 2.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var grid_offset: Vector2

var _is_moving: bool = false
var _start_pos: Vector2
var _target_pos: Vector2
var _move_timer: float = 0.0

var _current_dir: Vector2 = Vector2.DOWN
var _last_facing_dir: Vector2 = Vector2.DOWN

var _is_idle: bool = true
var _idle_timer: float = 0.0
var _idle_duration: float = 1.0

var _dirs := [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT
]
func _ready() -> void:
	grid_offset = tile_size * 0.5
	global_position = _snap_to_grid(global_position)

	_choose_new_idle_time()
	_play_idle(_last_facing_dir)

func _physics_process(delta: float) -> void:
	if _is_moving:
		_update_movement(delta)
	elif _is_idle:
		_update_idle(delta)
	else:
		_enter_idle_state()


func _update_idle(delta: float) -> void:
	_idle_timer += delta
	if _idle_timer >= _idle_duration:
		_try_random_step()

func _enter_idle_state() -> void:
	_is_idle = true
	_is_moving = false
	_choose_new_idle_time()
	_play_idle(_last_facing_dir)

func _choose_new_idle_time() -> void:
	_idle_timer = 0.0
	_idle_duration = randf_range(idle_time_min, idle_time_max)

func _try_random_step() -> void:
	var dirs_shuffled := _dirs.duplicate()
	dirs_shuffled.shuffle()

	for dir in dirs_shuffled:
		var desired_target = global_position + dir * tile_size
		if _can_move_to(desired_target):
			_start_move_to(desired_target, dir)
			return

	_enter_idle_state()

func _start_move_to(target: Vector2, dir: Vector2) -> void:
	_is_moving = true
	_is_idle = false

	_start_pos = global_position
	_target_pos = _snap_to_grid(target)
	_move_timer = 0.0

	_current_dir = dir
	_last_facing_dir = dir
	_play_walk(dir)

func _update_movement(delta: float) -> void:
	_move_timer += delta
	var t := _move_timer / move_time

	if t >= 1.0:
		t = 1.0
		_is_moving = false
		global_position = _target_pos

		_enter_idle_state()
		return

	global_position = _start_pos.lerp(_target_pos, t)

func _snap_to_grid(pos: Vector2) -> Vector2:
	var p := pos - grid_offset
	p.x = round(p.x / tile_size.x) * tile_size.x
	p.y = round(p.y / tile_size.y) * tile_size.y
	return p + grid_offset

func _can_move_to(target: Vector2) -> bool:
	if tilemap_layer == null:
		return true

	var local_target: Vector2 = tilemap_layer.to_local(target)
	var cell_coords: Vector2i = tilemap_layer.local_to_map(local_target)

	if use_patrol_area and not _is_within_patrol(cell_coords):
		return false

	var tile_data: TileData = tilemap_layer.get_cell_tile_data(cell_coords)

	if tile_data == null:
		return false

	if tile_data.has_custom_data("walkable"):
		var is_walkable: bool = bool(tile_data.get_custom_data("walkable"))
		return is_walkable

	return true

func _is_within_patrol(cell: Vector2i) -> bool:
	if not use_patrol_area:
		return true

	var x0 := patrol_origin_tile.x
	var y0 := patrol_origin_tile.y
	var x1 := x0 + patrol_size_tiles.x - 1
	var y1 := y0 + patrol_size_tiles.y - 1

	return cell.x >= x0 and cell.x <= x1 and cell.y >= y0 and cell.y <= y1

func _play_walk(dir: Vector2) -> void:
	if dir == Vector2.RIGHT:
		if anim.animation != "walk_right":
			anim.play("walk_right")
	elif dir == Vector2.LEFT:
		if anim.animation != "walk_left":
			anim.play("walk_left")
	elif dir == Vector2.UP:
		if anim.animation != "walk_up":
			anim.play("walk_up")
	elif dir == Vector2.DOWN:
		if anim.animation != "walk_down":
			anim.play("walk_down")

func _play_idle(dir: Vector2) -> void:
	if dir == Vector2.RIGHT:
		if anim.animation != "idle_right":
			anim.play("idle_right")
	elif dir == Vector2.LEFT:
		if anim.animation != "idle_left":
			anim.play("idle_left")
	elif dir == Vector2.UP:
		if anim.animation != "idle_up":
			anim.play("idle_up")
	else:
		if anim.animation != "idle_down":
			anim.play("idle_down")
