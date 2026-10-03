#!/usr/bin/env bash
# =============================================================================
# run_perf_z0.sh —— perf 主比较的 **Z0 初值口径**整芯片构建 / 运行（codex 0207 P1）
#
# Z0 = 两侧（golden 与 impl）都：
#   · 编译期不定义任何 RANDOMIZE_*（firtool 的 $random initial 块、每拍 garbage 全不生成）；
#   · 编译期保留 +vcs+initreg+random（initreg 支持）；
#   · 运行期显式 +vcs+initreg+0 → 所有 reg/logic 与存储阵列上电为 0。
# 原因：firtool 的 RANDOMIZE_*_INIT 用无种子 `$random`，那是全设计共用的一条随机流，
# 换掉任何一个带 $random initial 的 golden 模块，后面所有 golden 寄存器的初值都会平移，
# 与 +ntb_random_seed 无关。这是 simulation-only 伪差，不据此改 RTL。见 docs/lanes/tage-initmem.md。
#
# 工作区布局与 verif/sim/run_perfbind.sh 相同（直接调它的 setup），只是：
#   · vcs 命令取自 difftest `make -n vcs-build`（机械生成，不手抄），去掉 RANDOMIZE_*；
#   · 额外编进 verif/sim/perf_cfg_stamp.sv 作第二个 top —— 它在 assert.log 里打
#     [PERFCFG] 行（仿真器现场测得的设定），scripts/perf_compare.py 据此做设定闸。
#
# 用法:
#   verif/sim/run_perf_z0.sh setup
#   verif/sim/run_perf_z0.sh build golden|impl
#   verif/sim/run_perf_z0.sh run   golden|impl [workload.bin] [max-cycles] [额外 plusarg...]
#   verif/sim/run_perf_z0.sh all   [workload.bin] [max-cycles]      # setup+两侧 build+run
#   环境: SIMW（默认 /home/eda/xs-env/sim-work-perfz0）、JOBS（默认 16）、DIFFTEST、SRC_SIMW
# =============================================================================
set -euo pipefail

SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SIMW="${SIMW:-/home/eda/xs-env/sim-work-perfz0}"
export SRC_SIMW="${SRC_SIMW:-/home/eda/xs-env/sim-work}"
export DIFFTEST="${DIFFTEST:-$SRC_SIMW/difftest}"
XS_HOME="${XS_HOME:-/home/eda/xs-env/XiangShan}"
RAM_SIZE="${RAM_SIZE:-8589934592}"
REF_SO="${REF_SO:-$XS_HOME/ready-to-run/riscv64-nemu-interpreter-so}"
LOG_END="${LOG_END:-100000000}"
JOBS="${JOBS:-16}"
STAMP="$SV_HOME/verif/sim/perf_cfg_stamp.sv"

log() { echo "[perfz0] $*" >&2; }
die() { echo "[perfz0] ERROR: $*" >&2; exit 2; }

setup() { "$SV_HOME/verif/sim/run_perfbind.sh" setup; }

build() {
  local side=${1:?golden|impl} dd=$SIMW/${1} extra="" cmd
  [ "$side" = impl ] && extra="-f $dd/files_impl_nosimtop.f"
  cmd=$(cd "$DIFFTEST" && make -s -n vcs-build \
          DESIGN_DIR="$dd" NOOP_HOME="$XS_HOME" NEMU_HOME="$XS_HOME" \
          NUM_CORES=1 RTL_SUFFIX=sv WITH_CHISELDB=0 EXTRA="$extra" 2>/dev/null | grep '^vcs ')
  [ "$(printf '%s\n' "$cmd" | wc -l)" = 1 ] || die "make -n 没给出唯一一条 vcs 命令"
  case " $cmd " in *" +vcs+initreg+random "*) ;; *) die "difftest 的 vcs 命令里没有 +vcs+initreg+random";; esac
  cmd=$(printf '%s' "$cmd" | sed -E -e 's/ \+define\+RANDOMIZE_[A-Za-z_]+(=[^ ]*)?//g' -e "s/ -j[0-9]+ / -j$JOBS /")
  case "$cmd" in *RANDOMIZE*) die "去 RANDOMIZE_* 失败";; esac
  printf '%s %s -top perf_cfg_stamp\n' "$cmd" "$STAMP" > "$dd/vcs_cmd_z0.sh"
  rm -f "$dd/build/simv"
  ( cd "$dd/build" && VCS_ARCH_OVERRIDE=linux bash "$dd/vcs_cmd_z0.sh" > "$dd/build.log" 2>&1 ) || true
  [ -x "$dd/build/simv" ] || die "$side simv 未生成，见 $dd/build.log"
  log "$side simv OK: $dd/build/simv"
}

run() {
  local side=${1:?golden|impl} dd=$SIMW/$1
  local bin=${2:-$XS_HOME/ready-to-run/coremark-2-iteration.bin}
  local maxc=${3:-20000}
  shift; shift || true; shift || true
  [ -x "$dd/build/simv" ] || die "no $dd/build/simv — 先 build"
  local tag; tag=$(printf '%s' "$*" | tr -cs 'A-Za-z0-9=' '_')
  local rundir=$dd/run/$(basename "$bin" .bin)-$maxc${tag:+-$tag}
  mkdir -p "$rundir"
  log "run $side: $(basename "$bin") max-cycles=$maxc +vcs+initreg+0 $*"
  ( cd "$rundir" && VCS_ARCH_OVERRIDE=linux "$dd/build/simv" \
      "+workload=$bin" "+diff=$REF_SO" "+ram_size=$RAM_SIZE" \
      "+max-cycles=$maxc" "+b=0" "+e=$LOG_END" +vcs+initreg+0 "$@" -suppress=ASLR_DETECTED_INFO \
      > "$rundir/sim.log" 2> "$rundir/assert.log" ) || true
  log "$side: $(grep -oE 'EXCEEDED MAX CYCLE|HIT GOOD TRAP|HIT BAD TRAP|ABORT' "$rundir/sim.log" | head -1)" \
      " PERF 行 $(grep -c '\[PERF ' "$rundir/assert.log" || true)  $(grep -m1 '^\[PERFCFG\]' "$rundir/assert.log" || echo '★无 PERFCFG')"
}

case "${1:-}" in
  setup) setup;;
  build) build "${2:?golden|impl}";;
  run)   shift; run "$@";;
  all)   shift; setup; build golden; build impl; run golden "$@"; run impl "$@";;
  *) sed -n '2,26p' "$0";;
esac
