extends SceneTree
## art/ 의 원본 그림(ChatGPT 결과물)을 게임 규격으로 다듬어 assets/ 에 저장한다.
## 실행: ./build.sh
## 순서: 단색 배경 제거 → 투명 여백 잘라내기 → 칸 크기에 맞춰 축소 → 기준점 정렬.

const SRC := "res://art/"
const EXTS := ["png", "webp", "jpg", "jpeg"]
const TOL := 60  # 배경색으로 볼 RGB 차이 합 (0~765)

# 이름: [출력 크기, 정렬, 배경 제거]
# feet = 발이 아래 가운데, top = 윗면이 위쪽, center = 가운데, cover = 화면 꽉 채워 자르기
const SPEC := {
	"player": [Vector2i(192, 192), "feet", true],
	"player_climb": [Vector2i(192, 192), "feet", true],
	"player_fall": [Vector2i(192, 192), "center", true],
	"player_win": [Vector2i(192, 192), "feet", true],
	"stair": [Vector2i(280, 140), "top", true],
	"stair_50": [Vector2i(280, 140), "top", true],
	"stair_100": [Vector2i(280, 140), "top", true],
	"stair_150": [Vector2i(280, 140), "top", true],
	"stair_goal": [Vector2i(280, 140), "top", true],
	"bg": [Vector2i(1440, 2560), "cover", false],
	"bg_far": [Vector2i(1440, 2560), "cover", true],
	"logo": [Vector2i(1200, 350), "center", true],
	"btn_start": [Vector2i(880, 240), "center", true],
	"icon": [Vector2i(512, 512), "cover", false],
}


func _init() -> void:
	var done := 0
	for key in SPEC:
		var path := _find(key)
		if path == "":
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null or img.is_empty():
			printerr("  ✗ %s: 그림을 읽지 못함" % path.get_file())
			continue
		var src_size := img.get_size()
		img.convert(Image.FORMAT_RGBA8)
		var size: Vector2i = SPEC[key][0]
		var mode: String = SPEC[key][1]
		if SPEC[key][2]:
			_cut_background(img, key)
		var out: Image
		if mode == "cover":
			out = _cover(img, size)
		else:
			_drop_faint(img)
			var used := img.get_used_rect()
			if used.size == Vector2i.ZERO:
				printerr("  ✗ %s: 전부 투명함" % path.get_file())
				continue
			out = _fit(img.get_region(used), size, mode)
		var dest := "res://icon.png" if key == "icon" else "res://assets/%s.png" % key
		out.save_png(dest)
		print("  ✓ %s (%dx%d) → %s (%dx%d)" % [path.get_file(), src_size.x, src_size.y, dest.get_file(), size.x, size.y])
		done += 1
	print("그림 %d개 반영" % done)
	quit()


func _find(key: String) -> String:
	for ext in EXTS:
		if FileAccess.file_exists(SRC + key + "." + ext):
			return SRC + key + "." + ext
	return ""


## 네 모서리가 같은 단색이면 모서리에서부터 이어진 그 색을 투명하게 만든다.
## ponytail: 단순 flood fill. 바깥 반투명 테두리(안티에일리어싱)는 조금 남을 수 있다. 두꺼운 외곽선이면 티 안 남.
func _cut_background(img: Image, key: String) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var corners := [img.get_pixel(0, 0), img.get_pixel(w - 1, 0), img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1)]
	if corners.all(func(c: Color) -> bool: return c.a < 0.1):
		return  # 이미 투명 배경
	var k: Color = corners[0]
	for c in corners:
		if absi(c.r8 - k.r8) + absi(c.g8 - k.g8) + absi(c.b8 - k.b8) > TOL:
			print("  ! %s: 배경이 단색이 아니라 자동 제거를 건너뜀. 투명 배경이나 흰 단색 배경으로 다시 받으세요" % key)
			return
	var data := img.get_data()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack := PackedInt32Array([0, w - 1, (h - 1) * w, h * w - 1])
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if seen[i]:
			continue
		seen[i] = 1
		var o := i * 4
		if absi(data[o] - k.r8) + absi(data[o + 1] - k.g8) + absi(data[o + 2] - k.b8) > TOL:
			continue
		data[o + 3] = 0
		var x := i % w
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if i >= w: stack.append(i - w)
		if i < (h - 1) * w: stack.append(i + w)
	img.set_data(w, h, false, Image.FORMAT_RGBA8, data)


## ChatGPT 투명 PNG 가장자리의 거의 안 보이는 잡티를 지운다. 안 지우면 여백 자르기가 잡티까지 포함해 그림이 작아진다.
func _drop_faint(img: Image) -> void:
	var data := img.get_data()
	for o in range(3, data.size(), 4):
		if data[o] < 26:  # 알파 10% 미만
			data[o] = 0
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)


func _fit(img: Image, size: Vector2i, mode: String) -> Image:
	img.fix_alpha_edges()  # 축소할 때 지운 배경색이 테두리로 번지지 않게
	var s := minf(float(size.x) / img.get_width(), float(size.y) / img.get_height())
	var nw := maxi(1, roundi(img.get_width() * s))
	var nh := maxi(1, roundi(img.get_height() * s))
	img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var out := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var y := 0
	if mode == "feet":
		y = size.y - nh
	elif mode == "center":
		y = (size.y - nh) / 2
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((size.x - nw) / 2, y))
	return out


func _cover(img: Image, size: Vector2i) -> Image:
	var s := maxf(float(size.x) / img.get_width(), float(size.y) / img.get_height())
	img.resize(maxi(size.x, ceili(img.get_width() * s)), maxi(size.y, ceili(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	return img.get_region(Rect2i((img.get_width() - size.x) / 2, (img.get_height() - size.y) / 2, size.x, size.y))
