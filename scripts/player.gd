extends CharacterBody2D

@export var tile_size: Vector2 = Vector2(16, 16)
var grid_offset: Vector2
@export var move_time: float = 0.15  
@export var ground_layer: TileMapLayer
@export var obstacle_layer: TileMapLayer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _is_moving: bool = false
var _start_pos: Vector2
var _target_pos: Vector2
var _move_timer: float = 0.0

var _current_dir: Vector2 = Vector2.DOWN   
var _last_facing_dir: Vector2 = Vector2.DOWN  

func _ready() -> void:
	grid_offset = tile_size * 0.5
	print("Tile size: ", tile_size, "  grid_offset: ", grid_offset)
	print("Before snap: ", global_position)
	global_position = _snap_to_grid(global_position)
	print("After snap: ", global_position)
	_play_idle(_last_facing_dir)

func _physics_process(delta: float) -> void:
	if _is_moving:
		_update_movement(delta)
	else:
		_handle_input_and_try_move()

func _handle_input_and_try_move() -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		input_dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_up"):
		input_dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2.DOWN

	_current_dir = input_dir

	if _current_dir != Vector2.ZERO:
		_last_facing_dir = _current_dir
		var desired_target := global_position + _current_dir * tile_size
		if _can_move_to(desired_target):
			_start_move_to(desired_target)
		else:
			_play_idle(_current_dir)
	else:
		_play_idle(_last_facing_dir)

func _start_move_to(target: Vector2) -> void:
	_is_moving = true
	_start_pos = global_position
	_target_pos = _snap_to_grid(target)
	_move_timer = 0.0

	_last_facing_dir = _current_dir
	_play_walk(_current_dir)

# Update the player's movement (used when they are in the process of walking)
func _update_movement(delta: float) -> void:
	_move_timer += delta
	var t := _move_timer / move_time

	# Stop after moving
	if t >= 1.0:
		t = 1.0
		_is_moving = false
		global_position = _target_pos
		
		# If the player lands on a slippery tile, check if they can slide to the next tile
		if _is_slippery(global_position):
			var target_tile := global_position + _current_dir * tile_size
			if _can_move_to(target_tile):
				_start_move_to(target_tile) # Have the player move again
				_play_idle(_last_facing_dir) # Replaces the movement animation done by _start_move_to()
				return
				
		if _is_left(global_position):
			var target_tile := global_position + Vector2.LEFT * tile_size
			if _can_move_to(target_tile):
				_start_move_to(target_tile) # Have the player move again
				_play_idle(Vector2.LEFT) # Replaces the movement animation done by Vector2 direction
				return
				
		if _is_right(global_position):
			var target_tile := global_position + Vector2.RIGHT * tile_size
			if _can_move_to(target_tile):
				_start_move_to(target_tile) # Have the player move again
				_play_idle(Vector2.RIGHT) # Replaces the movement animation done by Vector2 direction
				return
				
		if _is_up(global_position):
			var target_tile := global_position + Vector2.UP * tile_size
			if _can_move_to(target_tile):
				_start_move_to(target_tile) # Have the player move again
				_play_idle(Vector2.UP) # Replaces the movement animation done by Vector2 direction
				return
				
		if _is_down(global_position):
			var target_tile := global_position + Vector2.DOWN * tile_size
			if _can_move_to(target_tile):
				_start_move_to(target_tile) # Have the player move again
				_play_idle(Vector2.DOWN) # Replaces the movement animation done by Vector2 direction
				return

		var continued := _try_continue_moving()
		if not continued:
			_play_idle(_last_facing_dir)
		return

	global_position = _start_pos.lerp(_target_pos, t)

func _try_continue_moving() -> bool:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		input_dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_up"):
		input_dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2.DOWN

	_current_dir = input_dir

	if _current_dir == Vector2.ZERO:
		return false

	var desired_target := global_position + _current_dir * tile_size
	if _can_move_to(desired_target):
		_start_move_to(desired_target)
		return true

	return false

func _snap_to_grid(pos: Vector2) -> Vector2:
	var p := pos - grid_offset
	p.x = round(p.x / tile_size.x) * tile_size.x
	p.y = round(p.y / tile_size.y) * tile_size.y
	return p + grid_offset

func _can_move_to(target: Vector2) -> bool:
	if obstacle_layer == null:
		return true
	
	var local_target: Vector2 = obstacle_layer.to_local(target)
	var cell_coords: Vector2i = obstacle_layer.local_to_map(local_target)
	var tile_data: TileData = obstacle_layer.get_cell_tile_data(cell_coords)
	
	if tile_data == null:
		return true
	if tile_data.has_custom_data("walkable"):
		return bool(tile_data.get_custom_data("walkable"))
	
	return true

# Check if the tile at a certain coordinate is marked as slippery
func _is_slippery(position: Vector2) -> bool:
	if ground_layer == null:
		return false

	# Get position's tile data
	var local_position: Vector2 = ground_layer.to_local(position)
	var cell_coords: Vector2i = ground_layer.local_to_map(local_position)
	var tile_data: TileData = ground_layer.get_cell_tile_data(cell_coords)
	
	if tile_data == null:
		return false
	if tile_data.has_custom_data("slippery"):
		return bool(tile_data.get_custom_data("slippery"))
	
	return false
	
func _is_left(position: Vector2) -> bool:
	if ground_layer == null:
		return false
		
	# Get position's tile data
	var local_position: Vector2 = ground_layer.to_local(position)
	var cell_coords: Vector2i = ground_layer.local_to_map(local_position)
	var tile_data: TileData = ground_layer.get_cell_tile_data(cell_coords)
	
	if tile_data == null:
		return false
	if tile_data.has_custom_data("left"):
		return bool(tile_data.get_custom_data("left"))
	
	return false
	
func _is_right(position: Vector2) -> bool:
	if ground_layer == null:
		return false
		
	# Get position's tile data
	var local_position: Vector2 = ground_layer.to_local(position)
	var cell_coords: Vector2i = ground_layer.local_to_map(local_position)
	var tile_data: TileData = ground_layer.get_cell_tile_data(cell_coords)
	
	if tile_data == null:
		return false
	if tile_data.has_custom_data("right"):
		return bool(tile_data.get_custom_data("right"))
	
	return false
	
func _is_up(position: Vector2) -> bool:
	if ground_layer == null:
		return false
		
	# Get position's tile data
	var local_position: Vector2 = ground_layer.to_local(position)
	var cell_coords: Vector2i = ground_layer.local_to_map(local_position)
	var tile_data: TileData = ground_layer.get_cell_tile_data(cell_coords)
	
	if tile_data == null:
		return false
	if tile_data.has_custom_data("up"):
		return bool(tile_data.get_custom_data("up"))
	
	return false
	
func _is_down(position: Vector2) -> bool:
	if ground_layer == null:
		return false
		
	# Get position's tile data
	var local_position: Vector2 = ground_layer.to_local(position)
	var cell_coords: Vector2i = ground_layer.local_to_map(local_position)
	var tile_data: TileData = ground_layer.get_cell_tile_data(cell_coords)
	
	if tile_data == null:
		return false
	if tile_data.has_custom_data("down"):
		return bool(tile_data.get_custom_data("down"))
	
	return false
	
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
