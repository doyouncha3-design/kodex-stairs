class_name Rules
## 게임 규칙. 노드와 무관한 순수 함수라 헤드리스로 검증한다. (tests/test_rules.gd)

const TOTAL := 200
const FALL_STEPS := 10
const ENERGY_GAIN := 0.14
const DRAIN_START := 0.22   # 초당 에너지 감소 (0%)
const DRAIN_END := 0.50     # 초당 에너지 감소 (200%)


## turn 후의 방향이 다음 계단 방향과 같으면 성공.
static func next_facing(facing: int, turn: bool) -> int:
	return -facing if turn else facing


static func is_correct(facing: int, turn: bool, next_dir: int) -> bool:
	return next_facing(facing, turn) == next_dir


static func fall_target(idx: int) -> int:
	return maxi(0, idx - FALL_STEPS)


static func drain_per_sec(idx: int) -> float:
	return lerpf(DRAIN_START, DRAIN_END, float(idx) / TOTAL)


## 계단 방향 생성. dirs[0]=0(바닥), 이후 ±1. 수익률 계단은 위로만 간다.
static func make_dirs(rng: RandomNumberGenerator) -> Array[int]:
	var dirs: Array[int] = [0]
	for i in TOTAL:
		dirs.append(1 if rng.randf() < 0.5 else -1)
	return dirs
