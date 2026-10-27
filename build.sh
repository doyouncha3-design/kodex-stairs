#!/bin/zsh
# art/ 그림 반영 → 테스트 → 웹 내보내기(docs/). 사용: ./build.sh
set -e
cd "$(dirname "$0")"
G="${GODOT:-$HOME/Downloads/Godot.app/Contents/MacOS/Godot}"
q() { "$G" --headless --path . "$@" 2>&1 | sed $'s/\e\\[[0-9;]*m//g' | grep -vE "^Godot Engine|^[[:space:]]*$|\[ *[0-9]+% \]|DONE|NotoSansKR|theme_db|resource_loader|build-tools" || true; }
echo "1/4 그림 다듬기"; q --script tools/import_art.gd
echo "2/4 가져오기";   q --import
echo "3/4 규칙 검사";  q --script tests/test_rules.gd
echo "4/4 웹 내보내기"; q --export-release Web "$PWD/docs/index.html"
echo "끝. 확인: python3 -m http.server 8765 --directory docs  →  http://localhost:8765"
