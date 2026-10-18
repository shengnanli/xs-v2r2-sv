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
# 工作区默认 /home/eda/xs-env/sim-fcb（SIMF= 可改）。
# =============================================================================
set -euo pipefail
SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SIMF="${SIMF:-/home/eda/xs-env/sim-fcb}"
export XSTILE_ONLY=1
FS="$SV_HOME/verif/sim/run_fastsim.sh"
log() { echo "[fcb] $*" >&2; }
die() { echo "[fcb] ERROR: $*" >&2; exit 2; }

patch_trace() {
  local f="$SIMF/difftest/src/test/csrc/difftest/difftest.cpp"
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
  diff -u "$f.orig" "$f" > "$SIMF/difftest/commit_trace.patch.txt" || true
  grep -q 'FCB_COMMIT_TRACE' "$f" || die "trace 补丁没生效"
  log "difftest.cpp 已加 commit trace（补丁: $SIMF/difftest/commit_trace.patch.txt）"
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
  *) sed -n '2,20p' "$0";;
esac
