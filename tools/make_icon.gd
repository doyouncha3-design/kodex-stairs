extends SceneTree
## 앱 아이콘 생성: 하늘색 바탕 + 캐릭터. 실행 후 ./build.sh 가 icon.png 로 반영한다.
## 실행: Godot --headless --path . --script tools/make_icon.gd

func _init() -> void:
	var size := 1024
	var out := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y in size:  # 위는 밝고 아래는 진한 하늘색
		out.fill_rect(Rect2i(0, y, size, 1), Color("eaf6ff").lerp(Color("7cc4ff"), float(y) / size))
	var ch := Image.load_from_file(ProjectSettings.globalize_path("res://art/player.png"))  # 원본이 선명하다
	ch.convert(Image.FORMAT_RGBA8)
	var data := ch.get_data()
	for o in range(3, data.size(), 4):  # 가장자리 잡티 제거 (import_art.gd 와 같은 기준)
		if data[o] < 26:
			data[o] = 0
	ch.set_data(ch.get_width(), ch.get_height(), false, Image.FORMAT_RGBA8, data)
	var used := ch.get_used_rect()
	ch = ch.get_region(used)
	var s := size * 0.78 / ch.get_height()  # 홈 화면 아이콘은 모서리가 깎이므로 가운데 78% 안에
	ch.resize(roundi(ch.get_width() * s), roundi(ch.get_height() * s), Image.INTERPOLATE_LANCZOS)
	out.blend_rect(ch, Rect2i(Vector2i.ZERO, ch.get_size()), Vector2i((size - ch.get_width()) / 2, (size - ch.get_height()) / 2))
	out.save_png("res://art/icon.png")
	print("art/icon.png written")
	quit()
