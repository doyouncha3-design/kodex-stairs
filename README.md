# KODEX 수익률 계단

무한의 계단을 패러디한 수익률 게임. 한 칸 오를 때마다 +1%, 200%에 가장 빨리 도달하면 끝.
잘못 밟거나 게이지가 비면 -30%.

- 엔진: Godot 4.7.2 (GL Compatibility, 2D)
- 플레이: `docs/index.html` 을 GitHub Pages 로 서비스 → 주소를 QR 로 배포
- 조작: 화면 왼쪽 탭 = 방향 전환 후 오르기, 오른쪽 탭 = 그대로 오르기. PC 는 ← → (A/D)

## 폴더

| 경로 | 내용 |
|---|---|
| `scenes/Main.tscn` | 게임 화면. HUD, 오버레이, 카메라 |
| `scenes/Stair.tscn`, `scenes/Player.tscn` | 계단 한 칸, 캐릭터. 그림 교체 지점 |
| `scripts/main.gd` | 게임 흐름 (입력, 추락, 클리어, 기록 저장) |
| `scripts/rules.gd` | 규칙 상수와 순수 함수 (200칸, -30칸, 게이지 속도) |
| `tests/test_rules.gd` | 규칙 헤드리스 검증 |
| `tools/make_placeholders.gd` | 임시 PNG 생성기 |
| `assets/` | PNG, 한글 폰트 (Noto Sans KR Bold 서브셋, OFL) |
| `docs/` | 웹 내보내기 결과. GitHub Pages 가 이 폴더를 서비스 |
| `export_presets.cfg` | Web(스레드 없음), Android, iOS 프리셋 |

## 그림 바꾸기

같은 파일명으로 `assets/` 에 덮어쓰고 Godot 에서 다시 내보내면 끝.

| 파일 | 크기 | 기준점 |
|---|---|---|
| `assets/stair.png` | 140×70 | 윗면 중앙이 계단 위치. 윗면 높이 24px 에 숫자가 올라감 |
| `assets/player.png` | 96×96 | 발바닥 중앙이 계단 위. 오른쪽을 보는 그림 (왼쪽은 자동 반전) |
| `assets/bg.png` | 720×1280 | 화면 비율에 맞춰 잘려서 채워짐 |
| `icon.png` | 256×256 | 앱 아이콘, 웹 파비콘 |

크기를 바꾸려면 `scenes/Stair.tscn` 의 `offset` 과 `scripts/main.gd` 의 `STEP_W`, `STEP_H` 만 맞추면 된다.
캐릭터 애니메이션을 넣을 때는 `Player.tscn` 의 `Sprite2D` 를 `AnimatedSprite2D` 로 바꾸면 되고, 스크립트는 `sprite` 변수의 타입만 바꾸면 된다.

## 빌드 (터미널)

```bash
G="$HOME/Downloads/Godot.app/Contents/MacOS/Godot"
"$G" --headless --path . --import
"$G" --headless --path . --script tests/test_rules.gd
"$G" --headless --path . --export-release Web "$PWD/docs/index.html"
```

로컬 확인: `python3 -m http.server 8765 --directory docs` 후 http://localhost:8765

## GitHub Pages + QR

1. 저장소를 GitHub 에 올린다 (`docs/` 포함).
2. Settings → Pages → Build and deployment → Source: **Deploy from a branch**, Branch: **main**, Folder: **/docs** → Save.
3. 1~2분 뒤 `https://<계정>.github.io/<저장소>/` 에서 열린다.
4. QR: 아래 주소를 브라우저에서 열면 PNG 가 나온다. `<주소>` 자리에 3번 주소를 넣는다.
   `https://api.qrserver.com/v1/create-qr-code/?size=600x600&data=<주소>`

웹 프리셋은 스레드를 끈 상태라 GitHub Pages 에 추가 헤더 없이 바로 돌아간다.
`index.wasm` 이 약 40MB (gzip 전송 시 약 10MB). 줄이려면 Godot 커스텀 템플릿으로 안 쓰는 모듈(3D, 물리, 네비게이션 등)을 빼고 빌드한다.

## 앱 출시

- Android: 프리셋 `Android`. Godot 에디터 → Editor Settings 에 Android SDK, 키스토어 설정 후 Export.
- iOS: 프리셋 `iOS`. Export 하면 Xcode 프로젝트가 `build/ios/` 에 생기고 Xcode 에서 서명 후 배포.

## 규칙 값 조정

`scripts/rules.gd` 상단 상수.

| 상수 | 뜻 | 기본 |
|---|---|---|
| `TOTAL` | 목표 % | 200 |
| `FALL_STEPS` | 추락 시 잃는 % | 30 |
| `ENERGY_GAIN` | 한 칸당 게이지 회복 | 0.14 |
| `DRAIN_START` / `DRAIN_END` | 초당 게이지 감소 (0% / 200%) | 0.22 / 0.50 |
