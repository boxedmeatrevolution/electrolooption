const GameState := preload("res://scripts/GameState.gd")

const MONSTER_TYPE_BASIC = 1
const MONSTER_TYPE_LASER = 2

var rng := RandomNumberGenerator.new()
var _level := 1
var _turn_of_last_spawn := 0

func _init(level):
	_level = level

## Returns an array where each element is a dictionary of the form
## {
##		pos: IVec   - where the monster should spawn
##		type: int   - enum eg. MONSTER_TYPE_BASIC
## }
## Empty array means nothing spawns.   
func get_spawn(gs: GameState) -> Array:
	var spawns = []
	var no_monsters = gs.get_monster_ids().size() == 0
	var turns_since_last_spawn = gs.turn - _turn_of_last_spawn
	if false: #no_monsters or turns_since_last_spawn >= 15:
		var posns = gs.get_cached_legal_monster_spawns()
		if posns.size() > 0:
			var i = rng.randi_range(0, posns.size() - 1)
			var type = rng.randi_range(1,2)
			spawns.append({
				"pos": posns[i],
				"type": type
			})
			_turn_of_last_spawn = gs.turn
	return spawns
