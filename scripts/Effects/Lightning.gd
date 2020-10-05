extends Node2D

onready var line := $Line2D
export var target := Vector2(0, 0)
var points := []
var rng := RandomNumberGenerator.new()
var segs_start = null

const LENGTH_PER_SEGMENT := 10.0
const NORMAL := 32.0
const JITTER_TIME := 10
const JITTER_SPACE := 100

func _ready() -> void:
	rng.randomize()
	var distance := (self.global_position - target).length()
	var num_segments := max(int(distance / LENGTH_PER_SEGMENT), 2)
	if segs_start != null:
		num_segments = segs_start
	for i in range(0, num_segments):
		points.append(0.0)
		line.add_point(Vector2.ZERO)


func _process(delta: float) -> void:
	var end := target - self.global_position
	var distance := end.length()
	var num_segments := int(distance / LENGTH_PER_SEGMENT)
	while num_segments > points.size():
		points.append(rng.randf())
		line.add_point(Vector2.ZERO)
	# Randomize points slightly.
	points[0] = 0.0
	points[-1] = 0.0
	for i in range(1, points.size() - 1):
		var shift := abs(Utility.gaussian(0.0, JITTER_TIME * delta))
		if distance != 0.0:
			var diff : float = (points[i - 1] - 2.0 * points[i] + points[i + 1]) / pow((distance / (points.size() - 1)), 2)
			if randf() < 0.5 - diff * JITTER_SPACE * JITTER_SPACE:
				points[i] -= shift
			else:
				points[i] += shift
	# Evenly space points along line.
	for i in range(0, points.size()):
		var tangent := end * i / (points.size() - 1)
		var normal : Vector2 = NORMAL * points[i] * Vector2(
			end.y,
			end.x
		).normalized()
		line.set_point_position(i, tangent + normal)
