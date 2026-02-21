extends Area2D

@onready var anim_sprite = $AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.spring_up()
		$AnimatedSprite2D.play("active")


func _on_animated_sprite_2d_animation_finished() -> void:
	$AnimatedSprite2D.play("inactive")
