extends Node2D

const Blob := preload("res://entities/Effects/Blob.tscn")
const Lightning := preload("res://entities/Effects/Lightning.tscn")
const Poof := preload("res://entities/Effects/Poof.tscn")

const NUM_BLOBS := 7
const NUM_LIGHTNING := 4
const LIGHTNING_TIME := 0.4
onready var lifetime := 0.0

var blobs := []
var lightnings := []

func _ready() -> void:
	var parent := get_parent()
	var poof := Poof.instance()
	parent.add_child(poof)
	poof.global_position = global_position + Vector2(0, 1)
	blobs.resize(NUM_BLOBS)
	lightnings.resize(NUM_BLOBS)
	for i in range(0, NUM_BLOBS):
		blobs[i] = Blob.instance()
		blobs[i].global_position = global_position + Vector2(rand_range(-20.0, 20.0), rand_range(-20.0, 20.0))
		parent.add_child(blobs[i])
	for i in range(0, NUM_LIGHTNING):
		lightnings[i] = Lightning.instance()
		lightnings[i].position = Vector2.ZERO
		lightnings[i].target = blobs[i].global_position
		lightnings[i].segs_start = 10
		blobs[randi() % NUM_BLOBS].add_child(lightnings[i])

func _process(delta : float) -> void:
	if lifetime < LIGHTNING_TIME:
		for i in range(0, NUM_LIGHTNING):
			if lightnings[i] != null:
				lightnings[i].target = blobs[i].global_position
				if randf() < 0.3 * delta / LIGHTNING_TIME:
					lightnings[i].queue_free()
					lightnings[i] = null
		lifetime += delta
	else:
		for i in range(0, NUM_LIGHTNING):
			if lightnings[i] != null:
					lightnings[i].queue_free()
					lightnings[i] = null
		queue_free()
