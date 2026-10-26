extends SceneTree
## 임시 그림 생성. 실행: Godot --headless --path . --script tools/make_placeholders.gd
## 나중에 같은 파일명의 PNG로 덮어쓰면 그대로 반영된다. 크기는 README 참고.

const ORANGE := Color("f58220")
const DARK := Color("b5560c")


func _init() -> void:
	_stair()
	_player()
	_bg()
	_icon()
	print("placeholders written")
	quit()


func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func _circle(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if Vector2(x - cx, y - cy).length() <= r:
				img.set_pixel(x, y, c)


func _stair() -> void:
	var img := _img(280, 140)
	img.fill_rect(Rect2i(0, 0, 280, 48), Color("ffb066"))
	img.fill_rect(Rect2i(0, 48, 280, 92), ORANGE)
	img.fill_rect(Rect2i(0, 48, 280, 8), DARK)
	img.fill_rect(Rect2i(0, 0, 280, 4), Color(1, 1, 1, 0.9))
	img.fill_rect(Rect2i(0, 0, 4, 140), DARK)
	img.fill_rect(Rect2i(276, 0, 4, 140), DARK)
	img.save_png("res://assets/stair.png")


func _player() -> void:
	var img := _img(192, 192)
	img.fill_rect(Rect2i(60, 100, 72, 80), Color("1f3b73"))
	img.fill_rect(Rect2i(60, 172, 32, 20), Color("222222"))
	img.fill_rect(Rect2i(100, 172, 32, 20), Color("222222"))
	img.fill_rect(Rect2i(88, 100, 16, 60), ORANGE)
	_circle(img, 96, 60, 44, Color("ffd9b3"))
	img.fill_rect(Rect2i(52, 12, 88, 24), Color("3b2a1a"))
	_circle(img, 108, 60, 6, Color.BLACK)
	_circle(img, 128, 60, 6, Color.BLACK)
	img.fill_rect(Rect2i(112, 80, 20, 4), Color("c0392b"))
	img.save_png("res://assets/player.png")


func _bg() -> void:
	var img := _img(1440, 2560)
	var top := Color("0b1a3a")
	var bottom := Color("16305f")
	for y in 2560:
		img.fill_rect(Rect2i(0, y, 1440, 1), top.lerp(bottom, y / 2560.0))
	for y in range(0, 2560, 160):
		img.fill_rect(Rect2i(0, y, 1440, 2), Color(1, 1, 1, 0.06))
	img.save_png("res://assets/bg.png")


func _icon() -> void:
	var img := _img(512, 512)
	img.fill(ORANGE)
	for i in 4:
		img.fill_rect(Rect2i(64 + i * 96, 400 - i * 96, 96, 48), Color.WHITE)
	img.save_png("res://icon.png")
