extends Node2D
## 게임 흐름. 규칙 상수는 scripts/rules.gd.

const STEP_W := 120.0
const STEP_H := 60.0
const CAM_OFFSET := Vector2(0, -230)
const CFG := "user://settings.cfg"
const StairScene := preload("res://scenes/Stair.tscn")

enum State { TITLE, READY, PLAYING, FALLING, CLEAR }

var state := State.TITLE
var dirs: Array[int] = []
var stair_pos: Array[Vector2] = []
var idx := 0          # 서 있는 계단 번호 == 수익률 %
var facing := 1
var energy := 1.0
var elapsed := 0.0
var best := 0.0
var classic := false   # true = 원작 방식(방향 전환/오르기), false = 좌우 탭
var delta_tw: Tween
var climb_t := 0.0     # 오르기 포즈를 보여줄 남은 시간

# assets/ 에 파일이 있으면 쓰고 없으면 기본 그림. 목록과 규격은 ART_GUIDE.md
var tex_player: Texture2D = _tex("player")
var tex_climb: Texture2D = _tex("player_climb", tex_player)
var tex_fall: Texture2D = _tex("player_fall", tex_player)
var tex_win: Texture2D = _tex("player_win", tex_player)
var tex_stairs: Array[Texture2D] = []  # 0~49, 50~99, 100~149, 150~199, 200

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
@onready var title: Label = %Title
@onready var start_btn: Button = %StartBtn
@onready var flash: ColorRect = %Flash
@onready var hint_l: Label = %HintL
@onready var hint_r: Label = %HintR
@onready var mode_btn: Label = %ModeBtn
@onready var logo: TextureRect = %Logo
@onready var logo_top: TextureRect = %LogoTop


func _ready() -> void:
	_load_cfg()
	_apply_art()
	start_btn.pressed.connect(_on_start_pressed)
	_apply_mode_text()
	_new_game()


static func _tex(key: String, fallback: Texture2D = null) -> Texture2D:
	var path := "res://assets/%s.png" % key
	return load(path) if ResourceLoader.exists(path) else fallback


func _apply_art() -> void:
	var base := _tex("stair")
	tex_stairs = [base]
	for key in ["stair_50", "stair_100", "stair_150", "stair_goal"]:
		tex_stairs.append(_tex(key, tex_stairs[-1]))
	$Far/Sprite2D.texture = _tex("bg_far")
	logo.texture = _tex("logo")
	logo_top.texture = logo.texture
	var btn := _tex("btn_start")
	if btn:
		for st in ["normal", "hover", "pressed"]:
			var box := StyleBoxTexture.new()
			box.texture = btn
			if st == "pressed":
				box.modulate_color = Color(0.75, 0.75, 0.75)
			start_btn.add_theme_stylebox_override(st, box)


func _stair_tex(i: int) -> Texture2D:
	return tex_stairs[4] if i >= Rules.TOTAL else tex_stairs[mini(i / 50, 3)]


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
		s.texture = _stair_tex(i)
		s.get_node("Label").text = "%d%%" % i
		stairs.add_child(s)
	idx = 0
	facing = dirs[1]
	energy = 1.0
	elapsed = 0.0
	state = State.TITLE
	_place_player()
	cam.position = player.position + CAM_OFFSET
	_update_hud()
	_show_overlay("KODEX\n수익률 계단", "한 칸 = +1%%\n200%%까지 가장 빨리 오르세요\n\n잘못 밟으면 -%d%%\n게이지가 비어도 -%d%%" % [Rules.FALL_STEPS, Rules.FALL_STEPS], "시작")


func _show_overlay(t: String, m: String, btn: String) -> void:
	var touch := DisplayServer.is_touchscreen_available()
	title.text = t
	logo.visible = logo.texture != null and state == State.TITLE
	logo_top.visible = false
	title.visible = not logo.visible
	msg.text = m + ("" if touch else "\n\nSpace 키를 눌러 %s" % btn)
	start_btn.text = btn
	start_btn.visible = touch
	mode_btn.visible = touch and state == State.TITLE
	overlay.visible = true


func _start() -> void:
	overlay.visible = false
	logo_top.visible = logo_top.texture != null
	state = State.READY
	delta_label.text = "탭해서 출발!" if DisplayServer.is_touchscreen_available() else "Space로 출발!"
	delta_label.modulate = Color(1, 0.85, 0.4)
	delta_label.position.y = 345.0


func _on_start_pressed() -> void:
	if state == State.TITLE:
		_start()
	elif state == State.CLEAR:
		_new_game()
		_start()


func _place_player() -> void:
	sprite.texture = tex_player
	player.position = stair_pos[idx]
	player.z_index = Rules.TOTAL - idx + 1
	sprite.flip_h = facing < 0


func _process(dt: float) -> void:
	cam.position = cam.position.lerp(player.position + CAM_OFFSET, minf(1.0, 12.0 * dt))
	if climb_t > 0.0:
		climb_t -= dt
		if climb_t <= 0.0 and state == State.PLAYING:
			sprite.texture = tex_player
	if state != State.PLAYING:
		return
	elapsed += dt
	if idx > 0:  # 바닥(0%)에서는 게이지가 줄지 않는다
		energy -= dt * Rules.drain_per_sec(idx)
	if energy <= 0.0:
		energy = 0.0
		_fall()
	_update_hud()


func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		# 키보드: Space = 시작/오르기, Shift = 방향 전환
		match state:
			State.TITLE, State.CLEAR:
				if e.keycode == KEY_SPACE:
					_on_start_pressed()
			State.READY, State.PLAYING:
				if e.keycode == KEY_SHIFT:
					_act(true)
				elif e.keycode == KEY_SPACE:
					_act(false)
		return
	if not (e is InputEventScreenTouch and e.pressed):
		return
	match state:
		State.TITLE:  # 시작은 버튼으로. 여기서는 조작 방식 토글만
			if mode_btn.get_global_rect().has_point(e.position):
				_toggle_mode()
		State.READY, State.PLAYING:
			var right: bool = e.position.x >= get_viewport().get_visible_rect().size.x * 0.5
			_act((not right) if classic else ((1 if right else -1) != facing))


func _act(turn: bool) -> void:
	if state == State.READY:
		state = State.PLAYING
	if state == State.PLAYING:
		_step(turn)


func _toggle_mode() -> void:
	classic = not classic
	_save_cfg()
	_apply_mode_text()


func _apply_mode_text() -> void:
	var touch := DisplayServer.is_touchscreen_available()
	mode_btn.visible = touch
	if classic or not touch:
		hint_l.text = "◀ 방향 전환" + ("" if touch else "\n(Shift)")
		hint_r.text = "오르기 ▲" + ("" if touch else "\n(Space)")
	else:
		hint_l.text = "◀ 왼쪽 계단"
		hint_r.text = "오른쪽 계단 ▶"
	mode_btn.text = "조작 방식: %s   [여기를 눌러 바꾸기]" % ("원작 (방향 전환 / 오르기)" if classic else "좌우 탭")


func _step(turn: bool) -> void:
	facing = Rules.next_facing(facing, turn)
	if not Rules.is_correct(facing, false, dirs[idx + 1]):
		sprite.flip_h = facing < 0
		_fall()
		return
	idx += 1
	energy = minf(1.0, energy + Rules.ENERGY_GAIN)
	_place_player()
	sprite.texture = tex_climb
	climb_t = 0.12
	sprite.scale = Vector2(1.2, 0.8)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.12)
	_pop_pct()
	_show_delta("+1%", Color(0.4, 1, 0.5))
	if idx >= Rules.TOTAL:
		_clear()


func _fall() -> void:
	state = State.FALLING
	sprite.texture = tex_fall
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
	sprite.texture = tex_win
	if best == 0.0 or elapsed < best:
		best = elapsed
		_save_cfg()
	_update_hud()
	_show_overlay("200% 달성!", "기록  %.2f초\n최고  %.2f초" % [elapsed, best], "다시 하기")


func _update_hud() -> void:
	pct_label.text = "%d%%" % idx
	timer_label.text = "%.2f초" % elapsed
	best_label.text = ("최고 %.2f초" % best) if best > 0.0 else "최고 --"
	timer_label.visible = state != State.TITLE
	pct_label.visible = state != State.TITLE
	energy_bg.visible = state != State.TITLE
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
	delta_label.position.y = 345.0
	delta_tw = create_tween().set_parallel(true)
	delta_tw.tween_property(delta_label, "position:y", 305.0, 0.5)
	delta_tw.tween_property(delta_label, "modulate:a", 0.0, 0.5).set_delay(0.15)


func _shake() -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(cam, "offset", Vector2(randf_range(-14, 14), randf_range(-14, 14)), 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)


func _load_cfg() -> void:
	var c := ConfigFile.new()
	if c.load(CFG) == OK:
		best = c.get_value("game", "best", 0.0)
		classic = c.get_value("game", "classic", false)


func _save_cfg() -> void:
	var c := ConfigFile.new()
	c.set_value("game", "best", best)
	c.set_value("game", "classic", classic)
	c.save(CFG)
