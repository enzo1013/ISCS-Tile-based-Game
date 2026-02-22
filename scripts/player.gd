extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -350.0
@onready var anim_sprite = $AnimatedSprite2D
@onready var coin_label = $CoinLabel

var coin_count: int = 0


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("walk_left", "walk_right")	
	jump(delta)
	walk(direction)
	animate(direction)
	move_and_slide()


func jump(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func walk(direction: float) -> void:
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func spring_up() -> void:
	const SPRING_VELOCITY = -500.0
	velocity.y = SPRING_VELOCITY

func collect_coin() -> void:
	coin_count += 1
	coin_label.text = "Coins: " + str(coin_count)


func fell_on_water() -> void:
	get_tree().call_deferred("reload_current_scene")

func animate(direction: float) -> void:
	# Turn
	if direction == -1:
		anim_sprite.flip_h = false
	elif direction == 1:
		anim_sprite.flip_h = true

	if not is_on_floor():
		anim_sprite.play("jump")
	elif direction != 0:
		anim_sprite.play("walk")
	else:
		anim_sprite.play("idle")
