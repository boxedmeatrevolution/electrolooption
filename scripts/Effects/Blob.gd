extends Node2D

onready var sprite := $Sprite

onready var rot_speed := rand_range(-10.0, 10.0)
onready var velocity := Vector2(
	rand_range(-400.0, 400.0),
	rand_range(-400.0, 400.0))
onready var MAX_LIFETIME := 1.0
onready var lifetime := MAX_LIFETIME
const GRAVITY := 800.0

func _ready():
	sprite.frame = randi() % 3

func _process(delta : float) -> void:
	sprite.rotation += delta * rot_speed
	position += delta * velocity
	velocity.y += delta * GRAVITY
	lifetime -= delta
	if lifetime < 0.5 * MAX_LIFETIME:
		sprite.modulate = Color(1.0, 1.0, 1.0, clamp(0.2, lifetime / (0.5 * MAX_LIFETIME), 1))
	if lifetime < 0:
		queue_free()
	
