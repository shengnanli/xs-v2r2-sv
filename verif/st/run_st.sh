#!/usr/bin/env bash
# =============================================================================
# run_st.sh —— 香山 V2R2 系统级(ST)验证封装: golden 基线编译 + difftest 运行,
#              以及 "替换重写模块后重编+重跑" 的全流程。
#
# 走 VCS difftest 路径(非 verilator emu): 预编译 verilator emu 因 glibc 版本跑
# 不动, 故用宿主 VCS 编 simv + NEMU difftest 跑真实程序(coremark)。
#
# 子命令:
#   build              编译 golden 基线 difftest simv(不替换任何模块)
#   run                跑当前 simv(coremark + NEMU difftest)
#   sub <M> [M2 ...]   substitute.sh 安装重写模块 M(install 进 build/rtl)→ 重编 → 跑
#   restore-all        restore.sh --all 还原所有被替换模块(并提示需重编)
#   env                打印将使用的环境变量并自检 vcs/nemu/workload 是否就绪
#
# 关键环境约束(详见 README.md):
#   - WITH_CHISELDB=0  避免缺 sqlite3.h 编译失败。
#   - NUM_CORES=1      单核 difftest。
#   - RTL_SUFFIX=sv    库文件后缀。
#   - VCS_ARCH_OVERRIDE=linux 必须配 -full64(VCS 环境怪癖)。
#   - 重编 simv 前 **必须 rm -f build/simv**(否则 make 不重链, 替换不进 simv)。
#   - 跑 coremark 必须 +ram_size=8589934592。
#
# 全端口 wrapper(已固化, 见 README §2.1): substitute.sh 解析 golden M 的完整端口表,
#   生成的 module M 端口与 golden 1:1; 功能子集接重写核(经改名的子集 wrapper),
#   golden 多余的 perf/debug/背压口直通/占位。**已系统级实测**: Alu(组合) 与
#   Bku(2 拍流水) 替换后 coremark difftest 均 HIT GOOD TRAP @ cycle 6492(== golden)。
#
# 纪律: `sub` 会写 $NOOP_HOME/build/rtl。golden 基线在后台编时**不要**跑 build/sub;
#       只有基线编完、确认无其它进程占用 build/rtl 后再用。先用 substitute.sh --dry-run
#       做独立 elaborate 干跑验证 bundle。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 可配置(均可用环境变量覆盖) -------------------------------------------
export NOOP_HOME="${NOOP_HOME:-/home/eda/xs-env/XiangShan}"
export NEMU_HOME="${NEMU_HOME:-$NOOP_HOME}"
export DESIGN_DIR="${DESIGN_DIR:-$NOOP_HOME}"
export NUM_CORES="${NUM_CORES:-1}"
export RTL_SUFFIX="${RTL_SUFFIX:-sv}"
export WITH_CHISELDB="${WITH_CHISELDB:-0}"
export VCS_ARCH_OVERRIDE="${VCS_ARCH_OVERRIDE:-linux}"
# 默认负载: coremark(2 迭代), 在 ready-to-run 下。
RUN_BIN="${RUN_BIN:-$NOOP_HOME/ready-to-run/coremark-2-iteration.bin}"
# NEMU 参考 so(difftest)。默认指向 ready-to-run 的 nemu-so, 即开 diff 逐指令比对。
REF_SO="${REF_SO:-$NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so}"
# 仿真内存大小: coremark difftest **必需** +ram_size=8589934592 (8GiB), 否则跑挂。
RAM_SIZE="${RAM_SIZE:-8589934592}"

DIFFTEST="$NOOP_HOME/difftest"
MAKE_COMMON=( -C "$DIFFTEST" DESIGN_DIR="$DESIGN_DIR" NOOP_HOME="$NOOP_HOME" \
              NEMU_HOME="$NEMU_HOME" NUM_CORES="$NUM_CORES" RTL_SUFFIX="$RTL_SUFFIX" \
              WITH_CHISELDB="$WITH_CHISELDB" )

log() { echo "[run_st] $*" >&2; }
die() { echo "[run_st] ERROR: $*" >&2; exit 1; }

cmd_env() {
  echo "NOOP_HOME      = $NOOP_HOME"
  echo "NEMU_HOME      = $NEMU_HOME"
  echo "NUM_CORES      = $NUM_CORES"
  echo "RTL_SUFFIX     = $RTL_SUFFIX"
  echo "WITH_CHISELDB  = $WITH_CHISELDB"
  echo "VCS_ARCH_OVERRIDE = $VCS_ARCH_OVERRIDE"
  echo "RUN_BIN        = $RUN_BIN"
  echo "REF_SO         = ${REF_SO:-<unset, diff disabled>}"
  echo "RAM_SIZE       = $RAM_SIZE"
  echo "--- self-check ---"
  command -v vcs >/dev/null 2>&1 && echo "vcs            : $(command -v vcs)" || echo "vcs            : NOT FOUND"
  [[ -n "${VCS_HOME:-}" ]] && echo "VCS_HOME       : $VCS_HOME" || echo "VCS_HOME       : NOT SET"
  [[ -f "$RUN_BIN" ]] && echo "workload       : present" || echo "workload       : MISSING $RUN_BIN"
  [[ -d "$NOOP_HOME/build/rtl" ]] && echo "build/rtl      : $(ls "$NOOP_HOME/build/rtl"/*.sv 2>/dev/null | wc -l) .sv files" || echo "build/rtl      : MISSING"
  if [[ -n "$REF_SO" ]]; then [[ -f "$REF_SO" ]] && echo "REF_SO         : present" || echo "REF_SO         : MISSING $REF_SO"; fi
  find "$NOOP_HOME/build/rtl" -name '*.sv.golden' -printf '  substituted: %f\n' 2>/dev/null | sed 's/\.sv\.golden//' || true
}

cmd_build() {
  # **必须 rm -f build/simv**: 否则 make 认为 simv 已是最新而不重链, 替换的模块
  # 不会进 simv。VCS 增量编译只重编改过的文件(替 1 模块 ~30s-2min)。
  log "compiling difftest simv (rm -f build/simv first; VCS incremental)..."
  rm -f "$NOOP_HOME/build/simv"
  make "${MAKE_COMMON[@]}" simv
}

cmd_run() {
  # 走 **确认可用** 的直跑命令(非 make simv-run): 直接 ./simv +workload +diff
  # +ram_size。+ram_size=8589934592 必需。golden 与 Alu/Bku 替换均 HIT GOOD TRAP@6492。
  [[ -x "$NOOP_HOME/build/simv" ]] || die "no build/simv — run '$0 build' first"
  local diff_opt=()
  [[ -n "$REF_SO" ]] && diff_opt=( "+diff=$REF_SO" )
  log "running simv on $(basename "$RUN_BIN") (ram_size=$RAM_SIZE, diff=${REF_SO:-off})..."
  ( cd "$NOOP_HOME/build/${RUN_BIN##*/}" 2>/dev/null || cd "$NOOP_HOME/build"
    "$NOOP_HOME/build/simv" "+workload=$RUN_BIN" "${diff_opt[@]}" \
      "+ram_size=$RAM_SIZE" -suppress=ASLR_DETECTED_INFO )
}

cmd_sub() {
  [[ $# -ge 1 ]] || die "sub needs at least one module name"
  for m in "$@"; do
    log "substituting module $m into build/rtl ..."
    "$SCRIPT_DIR/substitute.sh" "$m"
  done
  log "rebuilding simv with substituted module(s)..."
  cmd_build
  cmd_run
}

cmd_restore_all() {
  "$SCRIPT_DIR/restore.sh" --all
  log "modules restored. Re-run '$0 build' to recompile golden simv."
}

case "${1:-}" in
  env)          shift; cmd_env "$@";;
  build)        shift; cmd_build "$@";;
  run)          shift; cmd_run "$@";;
  sub)          shift; cmd_sub "$@";;
  restore-all)  shift; cmd_restore_all "$@";;
  ""|-h|--help) sed -n '2,40p' "$0";;
  *)            die "unknown subcommand '$1' (see --help)";;
esac
