#!/usr/bin/env bash
# =============================================================================
# run_fastsim.sh —— 「快 simv」泳道：把 difftest 的 VCS 编译从 debug 形态切成
# 快速形态，**只动编译开关，不动任何功能 define**，golden / impl 两侧同一套开关。
#
# 为什么需要它
# ------------
# difftest 的 `vcs.mk` 把 `-debug_access+all` 写死在 VCS_FLAGS 里：
#     VCS_FLAGS += -full64 +v2k -top $(VCS_TOP) -timescale=1ns/1ns -sverilog \
#                  -debug_access+all +lint=TFIPC-L
# 整芯片(SimTop+XSTop)下这一条让仿真慢到 ~44 cycle/s，coremark / dhrystone 这类
# 百万周期量级的负载根本跑不到终点。没有任何办法在命令行上「取消」它（VCS 没有
# 反向开关，`EXTRA=` 只能追加），所以唯一的正路是**在本泳道自己的 difftest 副本里
# 改 vcs.mk**——不碰 /home/eda/xs-env/sim-work/difftest（其它泳道在用），
# 更不碰 rtl/ 与 G1-canonical golden。
#
# 事实更正（对上一轮 README 的一处纠正）
# --------------------------------------
# README 与工单都写「-debug_access+all **+ verdi PLI**」。实测 build.log 第 6 行的
# 真实 vcs 命令行里**没有任何 verdi PLI**：`-P .../novas.tab .../pli.a` 只在
# `ifeq ($(CONSIDER_FSDB),1)` 里追加，而本流程从未设过 CONSIDER_FSDB。
# 也就是说慢的原因只有 `-debug_access+all` 一条。
#
# 改了什么（机械可复算，见 `$SIMF/difftest/vcs.mk.patch.txt`）
# ------------------------------------------------------------
#   1. 删掉 `-debug_access+all`          <- 唯一的性能改动
#   2. `-j200` -> `-j$VCS_JOBS`(默认 16) <- 32 核机器上两侧并行编译，防 200x2 打爆内存
# **没有增删任何 `+define+`**：DIFFTEST / VCS / RANDOMIZE_* / UNIT_DELAY /
# RANDOMIZE_DELAY=1 / +vcs+initreg+random / -timescale=1ns/1ns 全部原样保留，
# 两侧完全一致。代价：**没有波形能力**（`+dump-wave` 会失效）。
#
# 用法:
#   verif/sim/run_fastsim.sh setup                 # 造 sim-fast 工作区 + 打 vcs.mk 补丁
#   verif/sim/run_fastsim.sh build golden|impl
#   verif/sim/run_fastsim.sh run   golden|impl <workload.bin> [max-cycles] [tag]
#   verif/sim/run_fastsim.sh flags                 # 打印两侧实际 vcs 命令行的差分
# =============================================================================
set -euo pipefail

SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIMF="${SIMF:-/home/eda/xs-env/sim-fast}"
STOCK_SIMW="${STOCK_SIMW:-/home/eda/xs-env/sim-work}"
STOCK_DIFFTEST="${STOCK_DIFFTEST:-$STOCK_SIMW/difftest}"
VCS_JOBS="${VCS_JOBS:-16}"
XS_HOME="${XS_HOME:-/home/eda/xs-env/XiangShan}"
REF_SO="${REF_SO:-$XS_HOME/ready-to-run/riscv64-nemu-interpreter-so}"
RAM_SIZE="${RAM_SIZE:-8589934592}"

log() { echo "[fastsim] $*" >&2; }
die() { echo "[fastsim] ERROR: $*" >&2; exit 2; }

setup_workspace() {
  mkdir -p "$SIMF"
  # 复用上一轮已经验过的 generated-src（与 golden RTL 同一次 make sim-verilog 生成，
  # check_dpic 门禁通过），不重跑那 20 分钟的 chisel 生成。
  [ -e "$SIMF/regen" ] || ln -sfn "$STOCK_SIMW/regen" "$SIMF/regen"
  # difftest 副本 + vcs.mk 补丁
  if [ ! -d "$SIMF/difftest" ]; then
    cp -a "$STOCK_DIFFTEST" "$SIMF/difftest"
    rm -rf "$SIMF/difftest/.git"
  fi
  local mk="$SIMF/difftest/vcs.mk"
  if grep -q 'debug_access' "$mk"; then
    cp "$mk" "$mk.orig"
    sed -i -e 's/ -debug_access+all//' -e "s/-j200/-j$VCS_JOBS/" "$mk"
    diff -u "$mk.orig" "$mk" > "$SIMF/difftest/vcs.mk.patch.txt" || true
    log "vcs.mk 已打补丁:"; sed -n '1,40p' "$SIMF/difftest/vcs.mk.patch.txt" >&2
  fi
  # ★ 第二处必须打的补丁 ★：difftest 的 src/test/vsrc/vcs/top.v 无条件（`ifdef VCS`）
  # 调用 $vcdplusfile/$vcdpluson。这两个 VPD 系统任务**只在 -debug_access 下才被定义**，
  # 哪怕运行期由 `if ($test$plusargs("dump-wave"))` 门住，VCS 也在**编译期**报
  #   Error-[UST] Undefined System Task call to '$vcdpluson'
  # 直接编不出 simv。快 simv 本来就没有波形能力，所以把这两行换成明确的报错提示。
  local tv="$SIMF/difftest/src/test/vsrc/vcs/top.v"
  if grep -q '\$vcdpluson' "$tv"; then
    cp "$tv" "$tv.orig"
    python3 - "$tv" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
old = '      $vcdplusfile("simv.vpd");\n      $vcdpluson;\n'
new = ('      $display("[fastsim] this simv is built WITHOUT -debug_access; '
       'no VPD wave available.");\n      $fatal;\n')
assert s.count(old) == 1, "top.v 的 VPD 块与预期不符，停"
p.write_text(s.replace(old, new))
PY
    diff -u "$tv.orig" "$tv" > "$SIMF/difftest/top.v.patch.txt" || true
    log "top.v 已打补丁(去 VPD 系统任务):"; sed -n '1,20p' "$SIMF/difftest/top.v.patch.txt" >&2
  fi
  grep -q '\$vcdpluson' "$tv" && die "top.v 补丁没生效"
  grep -q 'debug_access' "$mk" && die "vcs.mk 补丁没生效，debug_access 仍在"
  grep -q 'CONSIDER_FSDB' "$mk" || die "vcs.mk 被改坏了"
  mkdir -p "$SIMF/workloads"
  log "工作区: $SIMF (difftest=$SIMF/difftest, jobs=$VCS_JOBS)"
}

drive() {  # 把 run_fullchip.sh 指到快工作区；它负责 setup/SimTop 补丁/清 .o/调 make
  SIMW="$SIMF" DIFFTEST="$SIMF/difftest" "$SV_HOME/verif/sim/run_fullchip.sh" "$@"
}

run() {  # $1=side $2=bin [$3=max-cycles] [$4=tag]
  local side=$1 bin=$2 maxc=${3:-} tag=${4:-}
  local dd=$SIMF/$side
  [ -x "$dd/build/simv" ] || die "no $dd/build/simv — 先 build"
  local name; name=$(basename "$bin" .bin)
  local rundir="$dd/run/${tag:-$name}"
  mkdir -p "$rundir"
  local opts=( "+workload=$bin" "+diff=$REF_SO" "+ram_size=$RAM_SIZE" -suppress=ASLR_DETECTED_INFO )
  [ -n "$maxc" ] && opts+=( "+max-cycles=$maxc" )
  log "run $side $name ${maxc:+max-cycles=$maxc} -> $rundir"
  ( cd "$rundir" && VCS_ARCH_OVERRIDE=linux "$dd/build/simv" "${opts[@]}" \
      2>"$rundir/assert.log" | tee "$rundir/sim.log" )
}

bench() {  # $1=workload.bin $2=tag [$3=max-cycles] —— 两侧并行跑同一负载并出裁定
  local bin=$1 tag=$2 maxc=${3:-}
  local t0 t1
  t0=$(date +%s)
  ( run golden "$bin" "$maxc" "$tag" >/dev/null 2>&1; echo "golden rc=$?" ) &
  local gp=$!
  ( run impl   "$bin" "$maxc" "$tag" >/dev/null 2>&1; echo "impl   rc=$?" ) &
  local ip=$!
  wait $gp || true; wait $ip || true
  t1=$(date +%s)
  log "bench $tag 墙钟 $((t1-t0))s"
  python3 "$SV_HOME/verif/sim/bench_verdict.py" \
      "$SIMF/golden/run/$tag/sim.log" "$SIMF/impl/run/$tag/sim.log" "$tag" || true
}

flags() {
  for s in golden impl; do
    echo "=== $s ==="
    grep -m1 '^vcs ' "$SIMF/$s/build.log" 2>/dev/null | tr ' ' '\n' \
      | grep -E '^(\+define|\-timescale|\-sverilog|\+v2k|\-full64|\+vcs|\-debug|\+lint|\-CFLAGS|\-LDFLAGS)' || true
  done
}

case "${1:-}" in
  setup) setup_workspace;;
  build) setup_workspace; drive build "${2:?golden|impl}";;
  run)   shift; run "${1:?side}" "${2:?workload.bin}" "${3:-}" "${4:-}";;
  bench) shift; bench "${1:?workload.bin}" "${2:?tag}" "${3:-}";;
  flags) flags;;
  *) sed -n '2,45p' "$0";;
esac
