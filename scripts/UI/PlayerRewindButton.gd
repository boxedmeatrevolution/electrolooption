extends Node2D

onready var sprite := $Sprite
onready var enabled := false

signal clicked();

func _process(delta):
	if !enabled:
		sprite.frame = 2
	else:
		if Utility.mode == Utility.MODE_PLAYER_REWIND:
			sprite.frame = 1
		else:
			sprite.frame = 0

func _click(viewport: Node2D, event: InputEvent, idx: int) -> void:
	if enabled:
		if event is InputEventMouseButton:
			if event.pressed && event.button_index == BUTTON_LEFT:
				if Utility.mode == Utility.MODE_PLAYER_DEFAULT:
					Utility.mode = Utility.MODE_PLAYER_REWIND
				elif Utility.mode == Utility.MODE_PLAYER_REWIND:
					Utility.mode = Utility.MODE_PLAYER_DEFAULT

func _input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.pressed && event.button_index == BUTTON_RIGHT:
			if Utility.mode == Utility.MODE_PLAYER_REWIND:
				Utility.mode = Utility.MODE_PLAYER_DEFAULT
