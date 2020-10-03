extends Node2D

onready var line := $Line2D
export var target := Vector2(0, 0)
var points := []
var rng

const LENGTH_PER_SEGMENT := 100.0
const NORMAL := 32.0
const JITTER_TIME := 0.01
const JITTER_SPACE := 0.01

func _init() -> void:
	print("INIT???")

func _ready() -> void:
	print("READY UP???")
	rng = RandomNumberGenerator.new()
	rng.randomize()
	var distance := (self.global_position - target).length()
	var num_segments := max(int(distance / LENGTH_PER_SEGMENT), 2)
	for i in range(0, num_segments):
		points.append(rng.randfn())
		line.add_point(Vector2.ZERO)


func _process(delta: float) -> void:
	var start := self.global_position
	var end := target
	var distance := (start - end).length()
	var num_segments = int(distance / LENGTH_PER_SEGMENT)
	while num_segments < points.size():
		points.append(rng.randfn())
		line.add_point(Vector2.ZERO)
	# Randomize points slightly.
	points[0] = 0.0
	points[-1] = 0.0
	for i in range(1, points.size() - 1):
		var shift := abs(rng.randfn(0.0, JITTER_TIME * delta))
		var diff : float = (points[i - 1] - 2.0 * points[i] + points[i + 1]) / (distance / (points.size() - 1))
		if rng.randf() < 0.5 + diff:
			points[i] -= shift
		else:
			points[i] += shift
	# Evenly space points along line.
	for i in range(0, points.size()):
		var tangent := start + (start - end) * i / (points.size() - 1)
		var normal : Vector2 = NORMAL * points[i] * Vector2(
			(start - end).y,
			(start - end).x
		).normalized()
		line.set_point_position(i, tangent + normal)
