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
	var img := _img(140, 70)
	img.fill_rect(Rect2i(0, 0, 140, 24), Color("ffb066"))
	img.fill_rect(Rect2i(0, 24, 140, 46), ORANGE)
	img.fill_rect(Rect2i(0, 24, 140, 4), DARK)
	img.fill_rect(Rect2i(0, 0, 140, 2), Color(1, 1, 1, 0.9))
	img.fill_rect(Rect2i(0, 0, 2, 70), DARK)
	img.fill_rect(Rect2i(138, 0, 2, 70), DARK)
	img.save_png("res://assets/stair.png")


func _player() -> void:
	var img := _img(96, 96)
	img.fill_rect(Rect2i(30, 50, 36, 40), Color("1f3b73"))
	img.fill_rect(Rect2i(30, 86, 16, 10), Color("222222"))
	img.fill_rect(Rect2i(50, 86, 16, 10), Color("222222"))
	img.fill_rect(Rect2i(44, 50, 8, 30), ORANGE)
	_circle(img, 48, 30, 22, Color("ffd9b3"))
	img.fill_rect(Rect2i(26, 6, 44, 12), Color("3b2a1a"))
	_circle(img, 54, 30, 3, Color.BLACK)
	_circle(img, 64, 30, 3, Color.BLACK)
	img.fill_rect(Rect2i(56, 40, 10, 2), Color("c0392b"))
	img.save_png("res://assets/player.png")


func _bg() -> void:
	var img := _img(720, 1280)
	var top := Color("0b1a3a")
	var bottom := Color("16305f")
	for y in 1280:
		img.fill_rect(Rect2i(0, y, 720, 1), top.lerp(bottom, y / 1280.0))
	for y in range(0, 1280, 80):
		img.fill_rect(Rect2i(0, y, 720, 1), Color(1, 1, 1, 0.06))
	img.save_png("res://assets/bg.png")


func _icon() -> void:
	var img := _img(256, 256)
	img.fill(ORANGE)
	for i in 4:
		img.fill_rect(Rect2i(32 + i * 48, 200 - i * 48, 48, 24), Color.WHITE)
	img.save_png("res://icon.png")
