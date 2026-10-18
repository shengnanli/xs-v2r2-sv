#!/usr/bin/env bash
# =============================================================================
# run_fullchip.sh —— 整芯片（SimTop + difftest + NEMU）仿真跑起来，golden / impl 两侧。
#
# 为什么不是 full_elab.sh：full_elab.sh 编的是 `+define+SYNTHESIS` 的 **XSTop**，
# 那条路上 difftest 的 DPI（都在 `ifndef SYNTHESIS 里）整块被剔掉，跑不出任何
# 架构状态比对。仿真必须走 difftest 官方 VCS 流：top=tb_top → SimTop → XSTop，
# **不定义 SYNTHESIS**、定义 DIFFTEST。所以「elaborate 过」与「能仿真」是两次
# 完全不同的编译，前者绿不蕴含后者绿。
#
# 取舍规则复用 scripts/full_elab_filelist.py（重写件优先 + package 拓扑序），
# 本脚本只把它的产物接到 difftest 的 Makefile 上：
#   * golden 侧：DESIGN_DIR/build/rtl 指向 G1-canonical/golden-rtl，纯 golden。
#   * impl 侧：同一个 build/rtl 作 `-y` 库兜底，另用 EXTRA="-f <impl 清单>" 把
#     292 个重写件 + 1782 个未重写 golden 件显式喂进去。VCS 的库搜索是惰性的：
#     显式清单里已定义的模块不会再去库目录找，于是「重写件优先」自动成立。
#     SimTop.sv 由 Makefile 显式传（$(SIM_TOP_V)），故从清单里剔掉防重定义。
#
# 环境坑（本工程记录在案）：VCS_ARCH_OVERRIDE=linux 必须配 -full64（difftest 的
# vcs.mk 自带 -full64，这里只补 override）。
# 运行必需 +ram_size=8589934592（默认 8TB 会让 NEMU init_mem 崩）。
#
# 用法:
#   verif/sim/run_fullchip.sh build  golden|impl
#   verif/sim/run_fullchip.sh run    golden|impl [workload.bin] [max-cycles]
#   verif/sim/run_fullchip.sh setup  golden|impl      # 只建工作区与清单
# =============================================================================
set -euo pipefail

SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIMW="${SIMW:-/home/eda/xs-env/sim-work}"
GOLDEN_RTL="${GOLDEN_RTL:-/home/eda/xs-env/G1-canonical/golden-rtl}"
XS_HOME="${XS_HOME:-/home/eda/xs-env/XiangShan}"
DIFFTEST="${DIFFTEST:-$SIMW/difftest}"
RAM_SIZE="${RAM_SIZE:-8589934592}"
REF_SO="${REF_SO:-$XS_HOME/ready-to-run/riscv64-nemu-interpreter-so}"

log() { echo "[fullchip] $*" >&2; }
die() { echo "[fullchip] ERROR: $*" >&2; exit 2; }


regen_generated_src() {
  local gs=$SIMW/regen/build/generated-src
  if [ -f "$gs/difftest-dpic.cpp" ] && check_dpic "$gs/difftest-dpic.cpp"; then return 0; fi
  log "重新生成与 golden RTL 同一次配置的 difftest DPI 胶水（~20 分钟，只做一次）"
  mkdir -p "$SIMW/regen/build"
  ( cd "$XS_HOME" && \
    JAVA_HOME=/home/eda/xs-env/toolchain/jdk-17.0.13+11 \
    PATH=/home/eda/xs-env/toolchain/jdk-17.0.13+11/bin:/home/eda/xs-env/toolchain:$PATH \
    NOOP_HOME="$SIMW/regen" NEMU_HOME="$XS_HOME" \
    make sim-verilog CONFIG=KunminghuV2Config NUM_CORES=1 ISSUE=E.b \
         BUILD_DIR="$SIMW/regen/build" > "$SIMW/regen/gen.log" 2>&1 )
  # NOOP_HOME 决定 generated-src 落点（difftest common/FileControl.scala 硬编码
  # $NOOP_HOME/build/generated-src，不跟 --target-dir 走）；BUILD_DIR 决定 RTL 落点。
  # 两个都指向隔离目录，$XS_HOME/build 一个字节都不动。
  check_dpic "$gs/difftest-dpic.cpp" || die "重新生成的 dpic 仍与 golden RTL 对不上，见 $SIMW/regen/gen.log"
}

check_dpic() {  # $1=difftest-dpic.cpp；返回 0 表示函数集合与 golden RTL 完全一致
  local a b
  a=$(grep -oP 'void\s+v_difftest_\K\w+' "$1" 2>/dev/null | sort -u)
  b=$(grep -oP '^\s*DummyDPICWrapper_\K\w+(?=\s+\w+\s*\()' "$GOLDEN_RTL/GatewayEndpoint.sv" | sort -u)
  [ -n "$a" ] && [ "$a" = "$b" ]
}

setup() {
  local side=$1; local dd=$SIMW/$side
  mkdir -p "$dd/build"
  # 幂等：impl 侧上一次跑完后 build/rtl 是**真目录**（下面按文件逐个软链），
  # 此时 `ln -sfn` 不会替换它而是在里面建一个 golden-rtl 链接，接着 `rm -f` 又会
  # 因为「Is a directory」失败 —— 脚本第二次跑必崩。先按类型清干净再建链接。
  if [ -d "$dd/build/rtl" ] && [ ! -L "$dd/build/rtl" ]; then rm -rf "$dd/build/rtl"; fi
  ln -sfn "$GOLDEN_RTL" "$dd/build/rtl"
  # ★ 不能用 $XS_HOME/build/generated-src ★：那份是 22:01 那次 --fpga-platform
  # --disable-all 生成覆盖上去的，与 21:40 的 build/rtl(= G1 golden) 不是同一次生成。
  # golden RTL 例化 27 种 DummyDPICWrapper_*，那份 dpic 只给 21 个函数，
  # 一跑就 Error-[DPI-DIFNF]（golden 自己也跑不起来）。所以在隔离目录重新生成一份。
  # 判据（机械可复算）：dpic 提供的 v_difftest_* 名字集合必须等于 golden
  # GatewayEndpoint.sv 例化的 DummyDPICWrapper_* 名字集合。
  regen_generated_src
  [ -d "$dd/build/generated-src" ] || cp -r "$SIMW/regen/build/generated-src" "$dd/build/generated-src"
  for f in chisel_db.cpp chisel_db.h constantin.cpp constantin.hpp constantin.txt perfCCT.cpp perfCCT.h; do
    [ -f "$dd/build/$f" ] || cp "$XS_HOME/build/$f" "$dd/build/$f"
  done
  if [ "$side" = impl ]; then
    if [ "${XSTILE_ONLY:-0}" = 1 ]; then
      # codex 0238：只换 XSTile，核外保持 golden（见 verif/sim/xstile_sim_filelist.py 头注释）。
      python3 "$SV_HOME/verif/sim/xstile_sim_filelist.py" \
          --out "$dd/files_impl_nosimtop.f" --tsv "$dd/srcmap.tsv" \
          --rename-dir "$dd/outcore_renamed" >"$dd/filelist.log"
      cat "$dd/filelist.log" >&2
    else
      python3 "$SV_HOME/scripts/full_elab_filelist.py" --with-difftest \
          --out "$dd/files_simtop.f" >"$dd/filelist.log"
      grep -v '/SimTop\.sv$' "$dd/files_simtop.f" > "$dd/files_impl_nosimtop.f"
    fi
    # ★ 必须打的 SimTop 补丁（见 verif/sim/README.md）★
    # golden SimTop 用 9897 条**绝对层次引用**(XMR) 把模块内部信号(_GEN_n /
    # _T_n_probe / *_probe) 直接引到 LogPerfEndpoint(9903 端口全 input, 纯观测)。
    # 重写件内部命名与 golden 不同 → Error-[XMRE] 整芯片仿真编不出来。
    # perfCnt 只喂性能计数器, 不进 difftest 架构比对, 故接常量 '0。
    # 这一步 **不改 golden、不改 rtl/**：只在本工作区生成 SimTop.sv 的打补丁副本。
    rm -rf "$dd/build/rtl"
    mkdir -p "$dd/build/rtl"
    # XSTILE_ONLY=1：build/rtl（= vcs 的 `-y` 库兜底目录）**只放打补丁的 SimTop.sv**，
    # 不链任何 golden 件 —— 清单漏件 VCS 当场报错，不可能静默回落到 golden 逻辑。
    if [ "${XSTILE_ONLY:-0}" != 1 ]; then
      for f in "$GOLDEN_RTL"/*; do ln -sfn "$f" "$dd/build/rtl/$(basename "$f")"; done
    fi
    rm -f "$dd/build/rtl/SimTop.sv"
    python3 - "$GOLDEN_RTL/SimTop.sv" "$dd/build/rtl/SimTop.sv" <<'PYEOF'
import re, sys, pathlib
src = pathlib.Path(sys.argv[1]).read_text()
pat = re.compile(r"\(\s*SimTop\.[A-Za-z0-9_.]+\s*\)")
n = len(pat.findall(src))
pathlib.Path(sys.argv[2]).write_text(
    "// PATCHED-FOR-SIM: %d 条 perfCnt_bore 层次引用(XMR)接成 '0\n" % n + pat.sub("('0)", src))
print("[fullchip] SimTop 打补丁: %d 条 XMR -> '0" % n)
PYEOF
    log "impl 清单: $(grep -c "$SV_HOME/rtl/" "$dd/files_impl_nosimtop.f") 重写件 + \
$(grep -c "$GOLDEN_RTL" "$dd/files_impl_nosimtop.f") golden 件"
  fi
}

build() {
  local side=$1; local dd=$SIMW/$side extra=""
  [ "$side" = impl ] && extra="-f $dd/files_impl_nosimtop.f"
  export VCS_ARCH_OVERRIDE=linux
  # 必须 rm -f build/simv：否则 make 认为已最新不重链，替换不进 simv（v2r2 踩过）。
  rm -f "$dd/build/simv"
  # ★ 换过 generated-src 之后必须删掉 C++ 的 .o ★：difftest-state.h 的结构体布局
  # 会跟着变，而 vcs.mk 的依赖里没有头文件，增量编译会留下按旧布局编出来的
  # difftest.o/diffstate.o…，症状是"整数寄存器对得上、pc 和浮点是随机值"的假失配
  # 甚至裸 segfault。**只删 C++ 的 .o**，RTL 的 .o（interfaceF.*）不能动，
  # 否则整芯片要重编 ~55 分钟。
  if [ -d "$dd/build/simv-compile" ]; then
    local n=0
    for cpp in $(find "$DIFFTEST/src/test/csrc" "$DIFFTEST/config" "$dd/build" -name '*.cpp' 2>/dev/null); do
      local o="$dd/build/simv-compile/$(basename "$cpp" .cpp).o"
      [ -f "$o" ] && { rm -f "$o"; n=$((n+1)); }
    done
    rm -f "$dd/build/simv-compile"/*.gch
    log "清掉 $n 个 C++ .o 强制按新 difftest-state.h 重编"
  fi
  make -C "$DIFFTEST" simv \
      DESIGN_DIR="$dd" NOOP_HOME="$XS_HOME" NEMU_HOME="$XS_HOME" \
      NUM_CORES=1 RTL_SUFFIX=sv WITH_CHISELDB=0 EXTRA="$extra" \
      2>&1 | tee "$dd/build.log" | grep -E "^(Error|Warning-\[(?!TFIPC|SIOB|OPD))|make.*Error" || true
  [ -x "$dd/build/simv" ] || die "$side simv 未生成，见 $dd/build.log"
  log "$side simv OK: $dd/build/simv"
}

run() {
  local side=$1; local dd=$SIMW/$side
  local bin=${2:-$XS_HOME/ready-to-run/coremark-2-iteration.bin}
  local maxc=${3:-}
  [ -x "$dd/build/simv" ] || die "no $dd/build/simv — 先 build"
  local rundir=$dd/run/$(basename "$bin" .bin)
  mkdir -p "$rundir"
  local opts=( "+workload=$bin" "+diff=$REF_SO" "+ram_size=$RAM_SIZE" -suppress=ASLR_DETECTED_INFO )
  [ -n "$maxc" ] && opts+=( "+max-cycles=$maxc" )
  log "run $side: $(basename "$bin") ${maxc:+max-cycles=$maxc}"
  ( cd "$rundir" && VCS_ARCH_OVERRIDE=linux "$dd/build/simv" "${opts[@]}" 2>"$rundir/assert.log" \
      | tee "$rundir/sim.log" )
}

case "${1:-}" in
  setup) setup "${2:?golden|impl}";;
  build) setup "${2:?golden|impl}"; build "$2";;
  run)   shift; run "${1:?golden|impl}" "${2:-}" "${3:-}";;
  *) sed -n '2,32p' "$0";;
esac
