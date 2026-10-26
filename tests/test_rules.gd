extends SceneTree
## 실행: Godot --headless --path . --script tests/test_rules.gd


func _init() -> void:
	assert(Rules.is_correct(1, false, 1))
	assert(not Rules.is_correct(1, false, -1))
	assert(Rules.is_correct(1, true, -1))
	assert(Rules.is_correct(-1, true, 1))
	assert(Rules.fall_target(100) == 70)
	assert(Rules.fall_target(12) == 0)
	assert(Rules.fall_target(200) == 170)
	assert(Rules.drain_per_sec(0) < Rules.drain_per_sec(200))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var dirs := Rules.make_dirs(rng)
	assert(dirs.size() == Rules.TOTAL + 1 and dirs[0] == 0)
	for d in dirs.slice(1):
		assert(d == 1 or d == -1)
	print("rules OK")
	quit()
