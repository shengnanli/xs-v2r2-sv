#!/usr/bin/env bash
# =============================================================================
# run_perfbind.sh —— 用 **perf 重绑版 SimTop** 建整芯片 impl 仿真，并与 golden
# 逐计数器对比 perf。
#
# 为什么是独立脚本而不是改 run_fullchip.sh：快速仿真泳道正在用
# `verif/sim/run_fullchip.sh` 的现有行为（9897 条 XMR 全接 `'0` 的 smoke 版
# SimTop）跑 CoreMark/Dhrystone。perf 重绑是**另一条**交付，不能挡住它、也不能
# 改它脚下的路。所以这里另起工作目录（默认 $SIMW=/home/eda/xs-env/sim-work-perfbind），
# 与 run_fullchip.sh 的工作目录零重叠。
#
# 与 run_fullchip.sh 的唯一实质差别就是 SimTop：
#   run_fullchip.sh : 9897 条 XMR 全部 -> `'0`（impl 侧 perf 计数器全灭）
#   本脚本          : 按 docs/perf_bore_map.tsv 重绑 9733 条（98.3%），
#                     其余 164 条仍接 `'0` 但**登记在 docs/perf_bore_unbound.tsv**，
#                     perf 比对时按名字排除，不拿假零冒充「相等」。
#
# compare 子命令现在还会**按档裁定**（codex 0162 D3）：排除集合取自
# docs/perf_gap_ledger.tsv，每条差异按 docs/perf_tier_ledger.tsv 的档位 +
# 持有模块是否已重写判 WAIVED / BLOCKING。判据见 scripts/perf_tier.py 头部，
# 闸见 scripts/check_perf_tier.py（在 scripts/gate_all.sh 里）。
# 加 --emit-mismatch docs/perf_mismatch_ledger.tsv 把逐条裁定落成台账（带输入 sha256）。
#
# perf 打印怎么来的：LogPerfEndpoint 的 `io_logEnable = timer>=logCtrl_begin &&
# timer<logCtrl_end`，difftest 的 `+b=`/`+e=` 给这两个值，**默认 begin=end=0
# 所以一行都不打**。必须给 `+e=<大数>`。dump 时刻由 difftest 在
# GOODTRAP/EXCEED/FAIL 或 `+max-cycles` 最后一拍触发。打印走 `$fwrite(32'h80000002)`
# = **stderr**，所以 PERF 落在 assert.log 而不是 sim.log。
#
# 环境坑（本工程记录在案）：VCS_ARCH_OVERRIDE=linux 必须配 -full64（difftest 的
# vcs.mk 自带 -full64）。运行必需 +ram_size=8589934592。
#
# 用法:
#   verif/sim/run_perfbind.sh setup            # 生成重绑 SimTop + 工作区
#   verif/sim/run_perfbind.sh build            # 建 impl simv（重绑版）
#   verif/sim/run_perfbind.sh run  impl|golden [workload.bin] [max-cycles]
#   verif/sim/run_perfbind.sh compare <golden-assert.log> <impl-assert.log>
# =============================================================================
set -euo pipefail

SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIMW="${SIMW:-/home/eda/xs-env/sim-work-perfbind}"
GOLDEN_RTL="${GOLDEN_RTL:-/home/eda/xs-env/G1-canonical/golden-rtl}"
XS_HOME="${XS_HOME:-/home/eda/xs-env/XiangShan}"
# difftest 与 generated-src 复用 run_fullchip.sh 已经建好的那份（只读取，不写回）。
SRC_SIMW="${SRC_SIMW:-/home/eda/xs-env/sim-work}"
DIFFTEST="${DIFFTEST:-$SRC_SIMW/difftest}"
RAM_SIZE="${RAM_SIZE:-8589934592}"
REF_SO="${REF_SO:-$XS_HOME/ready-to-run/riscv64-nemu-interpreter-so}"
LOG_END="${LOG_END:-100000000}"

log() { echo "[perfbind] $*" >&2; }
die() { echo "[perfbind] ERROR: $*" >&2; exit 2; }

setup() {
  local dd=$SIMW/impl
  mkdir -p "$dd/build"
  [ -d "$SRC_SIMW/regen/build/generated-src" ] || \
    die "缺 $SRC_SIMW/regen/build/generated-src —— 先跑一次 verif/sim/run_fullchip.sh setup golden"
  [ -d "$dd/build/generated-src" ] || cp -r "$SRC_SIMW/regen/build/generated-src" "$dd/build/generated-src"
  for f in chisel_db.cpp chisel_db.h constantin.cpp constantin.hpp constantin.txt perfCCT.cpp perfCCT.h; do
    [ -f "$dd/build/$f" ] || cp "$XS_HOME/build/$f" "$dd/build/$f"
  done
  python3 "$SV_HOME/scripts/full_elab_filelist.py" --with-difftest --golden "$GOLDEN_RTL" \
      --out "$dd/files_simtop.f" >"$dd/filelist.log"
  grep -v '/SimTop\.sv$' "$dd/files_simtop.f" > "$dd/files_impl_nosimtop.f"
  rm -rf "$dd/build/rtl"; mkdir -p "$dd/build/rtl"
  for f in "$GOLDEN_RTL"/*; do ln -sfn "$f" "$dd/build/rtl/$(basename "$f")"; done
  rm -f "$dd/build/rtl/SimTop.sv"
  python3 "$SV_HOME/scripts/perf_rebind.py" --golden "$GOLDEN_RTL" \
      --filelist "$dd/files_simtop.f" --emit-simtop "$dd/build/rtl/SimTop.sv"
  # golden 侧不需要重绑（它本来就自洽），但为了两侧同一条命令，给它一份纯 golden 树。
  local gd=$SIMW/golden
  mkdir -p "$gd/build"; ln -sfn "$GOLDEN_RTL" "$gd/build/rtl"
  [ -d "$gd/build/generated-src" ] || cp -r "$SRC_SIMW/regen/build/generated-src" "$gd/build/generated-src"
  for f in chisel_db.cpp chisel_db.h constantin.cpp constantin.hpp constantin.txt perfCCT.cpp perfCCT.h; do
    [ -f "$gd/build/$f" ] || cp "$XS_HOME/build/$f" "$gd/build/$f"
  done
}

build() {
  local side=${1:-impl} dd=$SIMW/${1:-impl} extra=""
  [ "$side" = impl ] && extra="-f $dd/files_impl_nosimtop.f"
  export VCS_ARCH_OVERRIDE=linux
  rm -f "$dd/build/simv"
  make -C "$DIFFTEST" simv \
      DESIGN_DIR="$dd" NOOP_HOME="$XS_HOME" NEMU_HOME="$XS_HOME" \
      NUM_CORES=1 RTL_SUFFIX=sv WITH_CHISELDB=0 EXTRA="$extra" \
      > "$dd/build.log" 2>&1 || true
  [ -x "$dd/build/simv" ] || die "$side simv 未生成，见 $dd/build.log"
  log "$side simv OK: $dd/build/simv"
}

run() {
  local side=$1 dd=$SIMW/$1
  local bin=${2:-$XS_HOME/ready-to-run/coremark-2-iteration.bin}
  local maxc=${3:-20000}
  [ -x "$dd/build/simv" ] || die "no $dd/build/simv — 先 build"
  local rundir=$dd/run/$(basename "$bin" .bin)-$maxc
  mkdir -p "$rundir"
  log "run $side: $(basename "$bin") max-cycles=$maxc（PERF 落 stderr → assert.log）"
  ( cd "$rundir" && VCS_ARCH_OVERRIDE=linux "$dd/build/simv" \
      "+workload=$bin" "+diff=$REF_SO" "+ram_size=$RAM_SIZE" \
      "+max-cycles=$maxc" "+e=$LOG_END" -suppress=ASLR_DETECTED_INFO \
      2>"$rundir/assert.log" | tee "$rundir/sim.log" ) || true
  log "PERF 行数: $(grep -c '\[PERF ' "$rundir/assert.log" || true)  ($rundir/assert.log)"
}

case "${1:-}" in
  setup)   setup;;
  build)   setup; build "${2:-impl}";;
  run)     shift; run "${1:?impl|golden}" "${2:-}" "${3:-}";;
  compare) shift; python3 "$SV_HOME/scripts/perf_compare.py" "$@";;
  *) sed -n '2,32p' "$0";;
esac
