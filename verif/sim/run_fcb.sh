#!/usr/bin/env bash
# =============================================================================
# run_fcb.sh —— codex 0238 主线 B：整芯片 SimTop「只换 XSTile」benchmark 对拍。
#
# 在 run_fastsim.sh（快 simv，无 -debug_access）之上加两件事，golden / impl 两侧完全同一套：
#   1. impl 清单走 verif/sim/xstile_sim_filelist.py（XSTILE_ONLY=1）：XSTile 闭包全取 rtl/
#      + 97 个登记存储模型；核外全取 golden；impl 的 `-y` 库目录只有打补丁的 SimTop.sv。
#   2. difftest C++ 加一个**只写文件、不参与判定**的逐拍提交 trace（XS_COMMIT_TRACE=<path>），
#      两侧 simv 用同一份 difftest 副本编出来。trace 的格式与比对判据见
#      docs/lanes/fullchip-bench.md（跑之前已提交）。
#
# 用法:
#   verif/sim/run_fcb.sh setup
#   verif/sim/run_fcb.sh build  golden|impl
#   verif/sim/run_fcb.sh run    golden|impl <workload.bin> [max-cycles] [tag]
#   verif/sim/run_fcb.sh compare <tag>        # 比两侧 commit.trace + 终点计数
#   verif/sim/run_fcb.sh cputest [并行度]      # nexus-am cputest 33 个，两侧各跑 + 逐个 compare
#   verif/sim/run_fcb.sh srcmap-check          # impl 清单/build.log 对仓内 docs/xstile_srcmap.tsv
# 工作区默认 /home/eda/xs-env/sim-fcb（SIMF= 可改）。完整说明：docs/fullchip_sim.md。
#
# 调试（Verdi）模式——与上面的快速路径完全分开，不改快速路径的任何行为与输出：
#   verif/sim/run_fcb.sh build-debug golden|impl
#   verif/sim/run_fcb.sh run-debug   golden|impl <workload.bin> [max-cycles] [tag] [plusarg...]
#   verif/sim/run_fcb.sh verdi       golden|impl <tag>
# 调试工作区 DSIMF（默认 ${SIMF}-debug，独立的 difftest 副本与 golden/impl 构建目录）。
# 调试 difftest 副本 = 原版 vcs.mk（保留 -debug_access+all）+ -kdb + CONSIDER_FSDB + 同一份
# FCB_COMMIT_TRACE 补丁；功能 define 与快速路径逐个相同（只多调试开关）。
# 波形：run-debug 带 +dump-wave=fsdb（全程）或再加 +wave-begin=<ns> +wave-end=<ns>（窗口；
# 时钟周期 2ns，reset 在 100ns 释放）。也可 +dump-wave=vpd（VPD，全程）。
# =============================================================================
set -euo pipefail
SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SIMF="${SIMF:-/home/eda/xs-env/sim-fcb}"
DSIMF="${DSIMF:-${SIMF%/}-debug}"
STOCK_SIMW="${STOCK_SIMW:-/home/eda/xs-env/sim-work}"
STOCK_DIFFTEST="${STOCK_DIFFTEST:-$STOCK_SIMW/difftest}"
VCS_JOBS="${VCS_JOBS:-16}"
export XSTILE_ONLY=1
FS="$SV_HOME/verif/sim/run_fastsim.sh"
log() { echo "[fcb] $*" >&2; }
die() { echo "[fcb] ERROR: $*" >&2; exit 2; }

patch_trace() {  # [$1=difftest 目录，默认 $SIMF/difftest]
  local dt="${1:-$SIMF/difftest}"
  local f="$dt/src/test/csrc/difftest/difftest.cpp"
  grep -q 'FCB_COMMIT_TRACE' "$f" && return 0
  [ -f "$f.orig" ] || cp "$f" "$f.orig"
  python3 - "$f" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
anchor = ("inline int Difftest::check_all() {\n"
          "  state->cycle_count = get_trap_event()->cycleCnt;\n"
          "  state->has_progress = false;\n")
assert s.count(anchor) == 1, 'check_all 锚点与预期不符，停'
hook = r'''
  // FCB_COMMIT_TRACE（verif/sim/run_fcb.sh 打的补丁）：逐拍把 DUT 送来的提交/异常事件
  // 原样写文件，**在任何 checker 消费/清零之前**，不改变 difftest 的任何判定路径。
  {
    static FILE *fcb_ct = nullptr;
    static bool fcb_init = false;
    if (!fcb_init) {
      fcb_init = true;
      const char *p = getenv("XS_COMMIT_TRACE");
      if (p && *p) {
        fcb_ct = fopen(p, "w");
        if (fcb_ct) {
          setvbuf(fcb_ct, nullptr, _IOFBF, 1 << 20);
          fprintf(fcb_ct, "# FCB_COMMIT_TRACE v1\n");
        }
      }
    }
    if (fcb_ct) {
      uint64_t cyc = get_trap_event()->cycleCnt;
      if (dut->event.valid) {
        fprintf(fcb_ct, "E %lu irq=%x exc=%x epc=%lx einst=%08x nmi=%d\n", cyc, dut->event.interrupt,
                dut->event.exception, dut->event.exceptionPC, dut->event.exceptionInst, dut->event.hasNMI);
      }
      for (int i = 0; i < CONFIG_DIFF_COMMIT_WIDTH; i++) {
        const DifftestInstrCommit &c = dut->commit[i];
        if (!c.valid)
          continue;
        bool w = c.rfwen | c.fpwen | c.vecwen;
        fprintf(fcb_ct,
                "C %lu %d pc=%lx inst=%08x rvc=%d rfwen=%d fpwen=%d vecwen=%d v0wen=%d wdest=%d wdata=%016lx "
                "skip=%d fused=%d special=%x rob=%d lq=%d sq=%d ld=%d st=%d\n",
                cyc, i, c.pc, c.instr, c.isRVC, c.rfwen, c.fpwen, c.vecwen, c.v0wen, c.wdest,
                w ? get_commit_data(dut, i) : 0UL, c.skip, c.nFused, c.special, c.robIdx, c.lqIdx, c.sqIdx,
                c.isLoad, c.isStore);
      }
      if (get_trap_event()->hasTrap) {
        fprintf(fcb_ct, "T %lu instrCnt=%lu code=%lu pc=%lx\n", cyc, get_trap_event()->instrCnt,
                get_trap_event()->code, get_trap_event()->pc);
        fflush(fcb_ct);
      }
      if ((cyc & 0xffff) == 0)
        fflush(fcb_ct);
    }
  }
'''
p.write_text(s.replace(anchor, anchor + hook))
PY
  diff -u "$f.orig" "$f" > "$dt/commit_trace.patch.txt" || true
  grep -q 'FCB_COMMIT_TRACE' "$f" || die "trace 补丁没生效"
  log "difftest.cpp 已加 commit trace（补丁: $dt/commit_trace.patch.txt）"
}

# ---------------------------------------------------------------------------
# 调试工作区（DSIMF）。只在这里出现 -debug_access/-kdb；快速路径（SIMF）一行不受影响。
# ---------------------------------------------------------------------------
setup_debug() {
  [ "$(readlink -f "$DSIMF")" != "$(readlink -f "$SIMF")" ] || die "DSIMF 不能与 SIMF 相同（$DSIMF）"
  mkdir -p "$DSIMF/workloads"
  [ -e "$DSIMF/regen" ] || ln -sfn "$STOCK_SIMW/regen" "$DSIMF/regen"
  local dt="$DSIMF/difftest"
  if [ ! -d "$dt" ]; then
    cp -a "$STOCK_DIFFTEST" "$dt"
    rm -rf "$dt/.git"
  fi
  local mk="$dt/vcs.mk"
  if ! grep -q 'FCB_DEBUG' "$mk"; then
    grep -q -- ' -debug_access+all' "$mk" || die "调试 difftest 的 vcs.mk 里没有 -debug_access+all（副本不是原版？$STOCK_DIFFTEST）"
    [ -f "$mk.orig" ] || cp "$mk" "$mk.orig"
    # 1) -j200 -> -j$VCS_JOBS（与快速路径同一处，非功能）
    # 2) 在 -debug_access+all 后加 -kdb（Verdi KDB）与 +define+CONSIDER_FSDB（打开 top.v 的 fsdb 分支）。
    #    不走 vcs.mk 的 CONSIDER_FSDB=1：那个分支给 EXTRA 赋值，而 impl 侧用命令行 EXTRA="-f 清单"，
    #    命令行变量会把它整个盖掉。VCS 2024 在 -debug_access/-kdb 下原生支持 $fsdbDump*，无需 novas.tab PLI。
    sed -i -e "s/-j200/-j$VCS_JOBS/" \
           -e 's/ -debug_access+all / -debug_access+all -kdb +define+CONSIDER_FSDB /' "$mk"
    sed -i '1i # FCB_DEBUG: verif/sim/run_fcb.sh setup_debug 打的补丁（-kdb、CONSIDER_FSDB、-j）' "$mk"
    diff -u "$mk.orig" "$mk" > "$dt/vcs.mk.debug.patch.txt" || true
    log "调试 vcs.mk 已打补丁:"; cat "$dt/vcs.mk.debug.patch.txt" >&2
  fi
  grep -q -- '-debug_access+all -kdb +define+CONSIDER_FSDB' "$mk" || die "调试 vcs.mk 补丁没生效"
  # top.v：fsdb 分支加可选窗口（+wave-begin=<ns> / +wave-end=<ns>），全芯片全程 dump 太大。
  local tv="$dt/src/test/vsrc/vcs/top.v"
  if ! grep -q 'FCB_DEBUG_WAVE' "$tv"; then
    [ -f "$tv.orig" ] || cp "$tv" "$tv.orig"
    python3 - "$tv" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
old = '      $fsdbDumpfile("simv.fsdb");\n      $fsdbDumpvars(0,"+mda");\n'
new = ('      // FCB_DEBUG_WAVE（verif/sim/run_fcb.sh）：可选窗口 +wave-begin=<ns> +wave-end=<ns>\n'
       '      $fsdbDumpfile("simv.fsdb");\n'
       '      fork begin\n'
       '        longint fcb_wb, fcb_we;\n'
       '        if (!$value$plusargs("wave-begin=%d", fcb_wb)) fcb_wb = 0;\n'
       '        if (!$value$plusargs("wave-end=%d", fcb_we)) fcb_we = 0;\n'
       '        if (fcb_wb > 0) #(fcb_wb);\n'
       '        $fsdbDumpvars(0,"+mda");\n'
       '        $display("[fcb-debug] fsdb dump on at %0t", $time);\n'
       '        if (fcb_we > fcb_wb) begin #(fcb_we - fcb_wb); $fsdbDumpoff; '
       '$display("[fcb-debug] fsdb dump off at %0t", $time); end\n'
       '      end join_none\n')
assert s.count(old) == 1, "top.v 的 fsdb 块与预期不符，停"
assert '$vcdpluson' in s, "调试 top.v 应保留原版 VPD 分支"
p.write_text(s.replace(old, new))
PY
    diff -u "$tv.orig" "$tv" > "$dt/top.v.debug.patch.txt" || true
  fi
  grep -q 'FCB_DEBUG_WAVE' "$tv" || die "调试 top.v 补丁没生效"
  patch_trace "$dt"
  log "调试工作区: $DSIMF (difftest=$dt)"
}

case "${1:-}" in
  setup) "$FS" setup; patch_trace;;
  build) "$FS" setup; patch_trace; "$FS" build "${2:?golden|impl}";;
  run)
    side=${2:?side}; bin=${3:?bin}; maxc=${4:-}; tag=${5:-$(basename "$bin" .bin)}
    mkdir -p "$SIMF/$side/run/$tag"
    export XS_COMMIT_TRACE="$SIMF/$side/run/$tag/commit.trace"
    "$FS" run "$side" "$bin" "$maxc" "$tag";;
  compare)
    tag=${2:?tag}
    python3 "$SV_HOME/verif/sim/commit_compare.py" \
      "$SIMF/golden/run/$tag" "$SIMF/impl/run/$tag";;
  build-debug)
    side=${2:?golden|impl}
    setup_debug
    SIMW="$DSIMF" DIFFTEST="$DSIMF/difftest" "$SV_HOME/verif/sim/run_fullchip.sh" build "$side"
    log "调试 simv: $DSIMF/$side/build/simv（KDB: $DSIMF/$side/build/simv.daidir）";;
  run-debug)
    side=${2:?side}; bin=${3:?bin}; maxc=${4:-}; tag=${5:-$(basename "$bin" .bin)}
    shift $(( $# < 5 ? $# : 5 ))
    mkdir -p "$DSIMF/$side/run/$tag"
    export XS_COMMIT_TRACE="$DSIMF/$side/run/$tag/commit.trace"
    SIMF="$DSIMF" SIM_PLUSARGS="$*" "$FS" run "$side" "$bin" "$maxc" "$tag";;
  verdi)
    side=${2:?side}; tag=${3:?tag}
    db="$DSIMF/$side/build/simv.daidir"; wv="$DSIMF/$side/run/$tag/simv.fsdb"
    [ -d "$db" ] || die "没有 $db —— 先 build-debug $side"
    cmd=(verdi -dbdir "$db")
    [ -f "$wv" ] && cmd+=(-ssf "$wv")
    log "${cmd[*]}"
    if [ -n "${DISPLAY:-}" ]; then ( cd "$DSIMF/$side/run/$tag" 2>/dev/null || cd "$DSIMF/$side"; exec "${cmd[@]}" ) &
    else log "未设 DISPLAY，只打印命令"; fi;;
  srcmap-check)
    python3 "$SV_HOME/verif/sim/check_xstile_srcmap.py" \
      --filelist "$SIMF/impl/files_impl_nosimtop.f" --build-log "$SIMF/impl/build.log" --label impl;;
  cputest)  # nexus-am cputest 33 个，两侧各跑，逐个 compare；$2=并行度
    J=${2:-8}; CT=${CT_DIR:-/home/eda/xs-env/nexus-am/tests/cputest/build}
    for s in golden impl; do for b in "$CT"/*-riscv64-xs.bin; do echo "$s $b"; done; done |
      xargs -P "$J" -n2 sh -c 'n=$(basename "$2" -riscv64-xs.bin); timeout 1800 "$0" run "$1" "$2" 2000000 "ct_$n" >/dev/null 2>&1; true' "$0" 2>/dev/null ||
      true
    ok=0; bad=0
    for b in "$CT"/*-riscv64-xs.bin; do
      n=$(basename "$b" -riscv64-xs.bin)
      if "$0" compare "ct_$n" > "$SIMF/impl/run/ct_$n/compare.txt" 2>&1; then ok=$((ok+1)); r=PASS; else bad=$((bad+1)); r=FAIL; fi
      printf '%-20s %s  %s\n' "$n" "$r" "$(grep -E '^\[B\] 逐拍' "$SIMF/impl/run/ct_$n/compare.txt" | head -1)"
    done
    echo "cputest: PASS=$ok FAIL=$bad";;
  *) sed -n '3,/^set -euo/p' "$0" | sed '$d';;
esac
