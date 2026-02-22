extends Area2D

@onready var anim_sprite = $AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.collect_coin()
		anim_sprite.play("collected")


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim_sprite.animation == "collected":
		queue_free()
