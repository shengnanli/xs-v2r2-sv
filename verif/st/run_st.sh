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
# NEMU 参考 so(difftest), 若未设留空则不开 diff。
REF_SO="${REF_SO:-}"

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
  echo "--- self-check ---"
  command -v vcs >/dev/null 2>&1 && echo "vcs            : $(command -v vcs)" || echo "vcs            : NOT FOUND"
  [[ -n "${VCS_HOME:-}" ]] && echo "VCS_HOME       : $VCS_HOME" || echo "VCS_HOME       : NOT SET"
  [[ -f "$RUN_BIN" ]] && echo "workload       : present" || echo "workload       : MISSING $RUN_BIN"
  [[ -d "$NOOP_HOME/build/rtl" ]] && echo "build/rtl      : $(ls "$NOOP_HOME/build/rtl"/*.sv 2>/dev/null | wc -l) .sv files" || echo "build/rtl      : MISSING"
  if [[ -n "$REF_SO" ]]; then [[ -f "$REF_SO" ]] && echo "REF_SO         : present" || echo "REF_SO         : MISSING $REF_SO"; fi
  find "$NOOP_HOME/build/rtl" -name '*.sv.golden' -printf '  substituted: %f\n' 2>/dev/null | sed 's/\.sv\.golden//' || true
}

cmd_build() {
  log "compiling golden-baseline difftest simv (VCS path)..."
  make "${MAKE_COMMON[@]}" simv
}

cmd_run() {
  local opts=( RUN_BIN="$RUN_BIN" )
  [[ -n "$REF_SO" ]] && opts+=( REF_SO="$REF_SO" )
  log "running simv on $(basename "$RUN_BIN")..."
  make "${MAKE_COMMON[@]}" "${opts[@]}" simv-run
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
