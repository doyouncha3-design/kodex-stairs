extends SceneTree
## 결과 화면: 키보드로 안 넘어가고, 버튼은 잠깐 잠겼다가 풀린다.
## 실행: Godot --headless --path . --script tests/test_clear.gd

func _key(code: Key) -> InputEventKey:
	var k := InputEventKey.new()
	k.keycode = code
	k.pressed = true
	return k


func _init() -> void:
	var m = load("res://scenes/Main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._start()
	m.state = m.State.PLAYING
	m.idx = Rules.TOTAL - 1
	m.facing = m.dirs[Rules.TOTAL]
	m._step(false)
	assert(m.state == m.State.CLEAR, "200칸에서 결과 화면")
	assert(m.clear_box.visible and not m.intro.visible)
	assert(m.big_time.text.ends_with("초"))
	assert(m.again_btn.disabled, "처음엔 버튼 잠김")
	for code in [KEY_SPACE, KEY_SHIFT, KEY_ENTER]:
		m._input(_key(code))
	assert(m.state == m.State.CLEAR, "키보드로 안 넘어감")
	var t := InputEventScreenTouch.new()
	t.pressed = true
	t.position = Vector2(600, 1150)
	m._input(t)
	assert(m.state == m.State.CLEAR, "게임 터치로 안 넘어감")
	await create_timer(m.AGAIN_DELAY + 0.1).timeout
	assert(not m.again_btn.disabled, "잠시 후 버튼 풀림")
	m.again_btn.pressed.emit()
	assert(m.state == m.State.READY and not m.overlay.visible, "버튼으로 다시 시작")
	print("clear OK")
	quit()
