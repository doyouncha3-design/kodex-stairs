extends Node2D
## 게임 흐름. 규칙 상수는 scripts/rules.gd.

const STEP_W := 120.0
const STEP_H := 60.0
const CAM_OFFSET := Vector2(0, -230)
const SAVE := "user://best.save"
const StairScene := preload("res://scenes/Stair.tscn")

enum State { READY, PLAYING, FALLING, CLEAR }

var state := State.READY
var dirs: Array[int] = []
var stair_pos: Array[Vector2] = []
var idx := 0          # 서 있는 계단 번호 == 수익률 %
var facing := 1
var energy := 1.0
var elapsed := 0.0
var best := 0.0
var delta_tw: Tween

@onready var stairs: Node2D = $Stairs
@onready var player: Node2D = $Player
@onready var sprite: Sprite2D = $Player/Sprite2D
@onready var cam: Camera2D = $Camera2D
@onready var pct_label: Label = %Pct
@onready var delta_label: Label = %Delta
@onready var timer_label: Label = %Timer
@onready var best_label: Label = %Best
@onready var energy_bg: ColorRect = %EnergyBg
@onready var energy_fill: ColorRect = %EnergyFill
@onready var overlay: ColorRect = %Overlay
@onready var msg: Label = %Msg
@onready var flash: ColorRect = %Flash


func _ready() -> void:
	best = _load_best()
	_new_game()


func _new_game() -> void:
	for c in stairs.get_children():
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	dirs = Rules.make_dirs(rng)
	stair_pos.clear()
	var p := Vector2.ZERO
	for i in dirs.size():
		if i > 0:
			p += Vector2(dirs[i] * STEP_W, -STEP_H)
		stair_pos.append(p)
		var s := StairScene.instantiate()
		s.position = p
		s.z_index = Rules.TOTAL - i
		s.get_node("Label").text = "%d%%" % i
		stairs.add_child(s)
	idx = 0
	facing = dirs[1]
	energy = 1.0
	elapsed = 0.0
	state = State.READY
	_place_player()
	cam.position = player.position + CAM_OFFSET
	_update_hud()
	overlay.visible = true
	msg.text = "KODEX 수익률 계단\n\n한 칸 = +1%\n200%까지 가장 빨리 오르세요\n\n잘못 밟으면 -30%\n게이지가 비어도 -30%\n\n왼쪽 탭: 방향 전환   오른쪽 탭: 오르기\n\n탭하여 시작"


func _place_player() -> void:
	player.position = stair_pos[idx]
	player.z_index = Rules.TOTAL - idx + 1
	sprite.flip_h = facing < 0


func _process(dt: float) -> void:
	cam.position = cam.position.lerp(player.position + CAM_OFFSET, minf(1.0, 12.0 * dt))
	if state != State.PLAYING:
		return
	elapsed += dt
	energy -= dt * Rules.drain_per_sec(idx)
	if energy <= 0.0:
		energy = 0.0
		_fall()
	_update_hud()


func _input(e: InputEvent) -> void:
	var turn := -1  # -1 없음, 1 방향 전환, 0 그대로 오르기
	if e is InputEventScreenTouch and e.pressed:
		turn = 1 if e.position.x < get_viewport().get_visible_rect().size.x * 0.5 else 0
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_LEFT, KEY_A:
				turn = 1
			KEY_RIGHT, KEY_D, KEY_SPACE, KEY_UP:
				turn = 0
	if turn < 0:
		return
	match state:
		State.CLEAR:
			_new_game()
		State.READY:
			overlay.visible = false
			state = State.PLAYING
			_step(turn == 1)
		State.PLAYING:
			_step(turn == 1)


func _step(turn: bool) -> void:
	facing = Rules.next_facing(facing, turn)
	if not Rules.is_correct(facing, false, dirs[idx + 1]):
		sprite.flip_h = facing < 0
		_fall()
		return
	idx += 1
	energy = minf(1.0, energy + Rules.ENERGY_GAIN)
	_place_player()
	sprite.scale = Vector2(1.2, 0.8)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.12)
	_pop_pct()
	_show_delta("+1%", Color(0.4, 1, 0.5))
	if idx >= Rules.TOTAL:
		_clear()


func _fall() -> void:
	state = State.FALLING
	_show_delta("-%d%%" % Rules.FALL_STEPS, Color(1, 0.3, 0.3))
	flash.color.a = 0.45
	create_tween().tween_property(flash, "color:a", 0.0, 0.5)
	_shake()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(player, "position:y", player.position.y + 700.0, 0.55).set_ease(Tween.EASE_IN)
	tw.tween_property(player, "rotation", TAU * (1 if facing > 0 else -1), 0.55)
	tw.chain().tween_callback(_land)


func _land() -> void:
	idx = Rules.fall_target(idx)
	facing = dirs[idx] if idx > 0 else dirs[1]
	player.rotation = 0.0
	energy = 1.0
	_place_player()
	_pop_pct()
	_update_hud()
	state = State.PLAYING


func _clear() -> void:
	state = State.CLEAR
	if best == 0.0 or elapsed < best:
		best = elapsed
		_save_best()
	_update_hud()
	overlay.visible = true
	msg.text = "200% 달성!\n\n기록  %.2f초\n최고  %.2f초\n\n탭하여 다시 시작" % [elapsed, best]


func _update_hud() -> void:
	pct_label.text = "%d%%" % idx
	timer_label.text = "%.2f초" % elapsed
	best_label.text = ("최고 %.2f초" % best) if best > 0.0 else "최고 --"
	energy_fill.size.x = energy_bg.size.x * energy
	energy_fill.color = Color(0.2, 0.9, 0.4) if energy > 0.3 else Color(1, 0.35, 0.3)


func _pop_pct() -> void:
	pct_label.text = "%d%%" % idx
	pct_label.pivot_offset = pct_label.size / 2.0
	pct_label.scale = Vector2(1.25, 1.25)
	pct_label.modulate = Color(0.6, 1, 0.7) if state != State.FALLING else Color(1, 0.5, 0.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(pct_label, "scale", Vector2.ONE, 0.15)
	tw.tween_property(pct_label, "modulate", Color.WHITE, 0.3)


func _show_delta(t: String, c: Color) -> void:
	if delta_tw:
		delta_tw.kill()
	delta_label.text = t
	delta_label.modulate = c
	delta_label.position.y = 270.0
	delta_tw = create_tween().set_parallel(true)
	delta_tw.tween_property(delta_label, "position:y", 230.0, 0.5)
	delta_tw.tween_property(delta_label, "modulate:a", 0.0, 0.5).set_delay(0.15)


func _shake() -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(cam, "offset", Vector2(randf_range(-14, 14), randf_range(-14, 14)), 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)


func _load_best() -> float:
	if not FileAccess.file_exists(SAVE):
		return 0.0
	var f := FileAccess.open(SAVE, FileAccess.READ)
	return f.get_float() if f else 0.0


func _save_best() -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_float(best)
