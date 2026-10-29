# KODEX 수익률 계단

무한의 계단을 패러디한 수익률 게임. 한 칸 오를 때마다 +1%, 200%에 가장 빨리 도달하면 끝.
잘못 밟거나 게이지가 비면 -10%.

- 엔진: Godot 4.7.2 (GL Compatibility, 2D)
- 플레이: `docs/index.html` 을 GitHub Pages 로 서비스 → 주소를 QR 로 배포
- 터치(기본): 왼쪽 탭 = 왼쪽 위 계단, 오른쪽 탭 = 오른쪽 위 계단
- 터치(원작): 시작 화면의 "조작 방식"을 누르면 원작처럼 왼쪽 = 방향 전환, 오른쪽 = 오르기
- 키보드: 항상 원작 방식. Shift = 방향 전환, Space = 오르기

## 휴대폰으로 하기

- 주소: https://doyouncha3-design.github.io/kodex-stairs/
- QR: [`docs/qr.png`](docs/qr.png) (1000×1000, 오류 정정 H 등급이라 인쇄·축소에도 잘 읽힘). 소식지에는 가로 2cm 이상으로 넣는다.
- 홈 화면에 추가하면 캐릭터 아이콘으로 주소창 없이 앱처럼 열린다. 한 번 열었던 휴대폰은 인터넷이 약해도 빨리 뜬다.
  - 아이폰: Safari 로 열기 → 공유 버튼 → "홈 화면에 추가"
  - 안드로이드: Chrome 으로 열기 → 오른쪽 위 ⋮ → "홈 화면에 추가" 또는 "앱 설치"
  - 카카오톡 등 앱 안에서 열렸다면 "다른 브라우저로 열기"를 먼저 누른다 (앱 안 브라우저에서는 홈 화면 추가가 안 된다).
- 게임을 고쳐서 푸시하면 1~2분 뒤 같은 주소·같은 QR 에 반영된다. 홈 화면에 추가한 사람도 다음에 열 때 새 버전을 받는다.
- 앱 아이콘은 `tools/make_icon.gd` 로 만든 `art/icon.png` 다. 캐릭터를 바꾸면 이 스크립트를 다시 실행하고 `./build.sh`.

## 폴더

| 경로 | 내용 |
|---|---|
| `scenes/Main.tscn` | 게임 화면. HUD, 오버레이, 카메라 |
| `scenes/Stair.tscn`, `scenes/Player.tscn` | 계단 한 칸, 캐릭터. 그림 교체 지점 |
| `scripts/main.gd` | 게임 흐름 (입력, 추락, 클리어, 기록 저장) |
| `scripts/rules.gd` | 규칙 상수와 순수 함수 (200칸, -10칸, 게이지 속도) |
| `tests/test_rules.gd` | 규칙 헤드리스 검증 |
| `tools/make_placeholders.gd` | 임시 PNG 생성기 |
| `tools/import_art.gd` | `art/` 원본을 게임 규격으로 다듬는 도구 |
| `art/` | ChatGPT 원본 그림 넣는 곳 (게임 용량에 안 들어감) |
| `build.sh` | 한 번에 빌드 |
| `assets/` | PNG, 한글 폰트 (Noto Sans KR Bold 서브셋, OFL) |
| `docs/` | 웹 내보내기 결과. GitHub Pages 가 이 폴더를 서비스 |
| `export_presets.cfg` | Web(스레드 없음), Android, iOS 프리셋 |

## 그림 바꾸기

ChatGPT 로 만든 그림을 `art/` 에 정해진 파일명으로 넣고 `./build.sh` 를 실행하면 된다.
만들 그림 목록, 순서, 프롬프트, 규칙은 [ART_GUIDE.md](ART_GUIDE.md) 에 있다.

## 빌드 (터미널)

```bash
./build.sh
```

그림 다듬기, 가져오기, 규칙 검사, 웹 내보내기를 차례로 한다. Godot 위치가 다르면 `GODOT=/경로/Godot ./build.sh`.

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
| `FALL_STEPS` | 추락 시 잃는 % | 10 |
| `ENERGY_GAIN` | 한 칸당 게이지 회복 | 0.14 |
| `DRAIN_START` / `DRAIN_END` | 초당 게이지 감소 (0% / 200%) | 0.22 / 0.50 |
