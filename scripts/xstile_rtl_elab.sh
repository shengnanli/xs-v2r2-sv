#!/usr/bin/env bash
# =============================================================================
# xstile_rtl_elab.sh —— 只用「重写逻辑 + 已批准存储模型」把 XSTile elaborate 出来（codex 0238 主线 1；
# codex 0240 C 线：主 elaborate 改显式 -top XSTile，闭包核对另作一步保留）
#
# 源清单由 scripts/xstile_srcmap.py 机械生成：闭包内 RTL 全取 rtl/，golden 只有登记过的
# 存储模型（sha256 逐字对登记表）。本脚本做两步，**两步都 PASS 才算 PASS**：
#
#   步 1 main（主 elaborate，`-top XSTile`）：
#      用 VCS 真 elaborate，显式顶层 XSTile。清单少一个被例化的模块 → Error-[CFCILFBI]，当场失败；
#      所以 srcmap 的例化识别即使漏认，也漏不过这里。判据：rc=0、0 个 Error-、Top Level Modules 恰为 XSTile。
#
#   步 2 closure（闭包核对，**不给 -top**）：
#      VCS 会把清单里所有「没被任何人例化」的模块列为 Top Level Modules。要求这一栏
#      = XSTile ∪ 闭包外闲置件——在源表闭包里却成了顶层 = srcmap 多认了一个「例化」→ 判红。
#      这一步不是给仿真用的编译，只是拿 VCS 的顶层推断做 srcmap「多认」的独立核对。
#
# 两步在各自子目录（$W/main、$W/closure，各自 csrc）里**并行**跑，墙钟约等于一次 elaborate。
#
# 编译设定：+define+SYNTHESIS（与 full_elab.sh 一致，可综合口径）。仿真口径
# （SimTop / DIFFTEST / 不定义 SYNTHESIS，顶层 tb_top）在 verif/sim/ 泳道，不在这里。
#
# 用法: bash scripts/xstile_rtl_elab.sh [workdir]     # 默认 ${TMPDIR:-/tmp}/xstile_rtl_elab（仓库外）
#       XSTILE_ELAB_STEPS=main|closure|all（默认 all）
# =============================================================================
set -euo pipefail
SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="${1:-${TMPDIR:-/tmp}/xstile_rtl_elab}"   # 默认放仓库外：build_xstile_rtl/ 不在 .gitignore 里，放仓内会弄脏工作树
STEPS="${XSTILE_ELAB_STEPS:-all}"
SRCMAP="$SV_HOME/docs/xstile_srcmap.tsv"
mkdir -p "$W"
cd "$W"
export VCS_ARCH_OVERRIDE=linux

python3 "$SV_HOME/scripts/xstile_srcmap.py" --filelist "$W/files.f"
find "$SV_HOME/rtl" -type d | sed 's/^/+incdir+/' > "$W/inc.f"

vcs_elab() {  # $1=子目录名  其余=额外 vcs 参数；返回 vcs rc
    local d="$W/$1"; shift
    rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && vcs -full64 -sverilog -timescale=1ns/1ps +define+SYNTHESIS +error+100000 \
        "$@" -f "$W/inc.f" -f "$W/files.f" -Mdir="$d/csrc" -o "$d/simv_xstile_rtl" -l "$d/elab.log" \
        > /dev/null 2>&1 )
}
# VCS 在 Parsing 之后打印:
#   Top Level Modules:
#          XSTile
#   TimeScale is 1 ns / 1 ps
tops_of() { awk '/^Top Level Modules:/{f=1;next} f&&/^[[:space:]]+[A-Za-z_]/{print $1;next} f{exit}' "$1"; }

rm -f "$W/main/rc" "$W/closure/rc"
pids=()
if [ "$STEPS" = all ] || [ "$STEPS" = main ]; then
    ( set +e; vcs_elab main -top XSTile; echo $? > "$W/main/rc" ) & pids+=($!)
fi
if [ "$STEPS" = all ] || [ "$STEPS" = closure ]; then
    ( set +e; vcs_elab closure; echo $? > "$W/closure/rc" ) & pids+=($!)
fi
[ "${#pids[@]}" -gt 0 ] || { echo "XSTILE_ELAB_STEPS=$STEPS 不认识（main|closure|all）"; exit 2; }
for p in "${pids[@]}"; do wait "$p" || true; done

fail=0
report_vcs() {  # $1=step；打印 rc/errors/tops，失败时打印前几条 Error
    local d="$W/$1" rc nerr
    rc=$(cat "$d/rc" 2>/dev/null || echo 99)
    nerr=$(grep -cE '^Error-' "$d/elab.log" 2>/dev/null || true)
    echo "[$1] vcs rc=$rc  errors=${nerr:-?}  Top Level Modules: $(tops_of "$d/elab.log" | tr '\n' ' ')"
    if [ "$rc" -ne 0 ] || [ "${nerr:-1}" -ne 0 ]; then
        grep -A4 -E '^Error-' "$d/elab.log" | head -40
        echo "[$1] FAIL（elaborate 失败）"; return 1
    fi
}

if [ -f "$W/main/rc" ]; then
    if report_vcs main; then
        mt=$(tops_of "$W/main/elab.log" | tr '\n' ' ' | sed 's/ $//')
        if [ "$mt" = XSTile ]; then
            echo "[main] PASS（-top XSTile elaborate 通过，simv=$W/main/simv_xstile_rtl）"
        else
            echo "[main] FAIL（-top XSTile 下 Top Level Modules=\"$mt\"，应恰为 XSTile）"; fail=1
        fi
    else
        fail=1
    fi
fi

if [ -f "$W/closure/rc" ]; then
    if report_vcs closure; then
        # 判据：XSTile 必须是顶层；其余顶层必须都**不在**源表闭包里。
        #   - 不在闭包里的顶层 = 与闭包内模块同文件、但没被例化的件（例：rtl/backend/MulUnit.sv 里的
        #     C22/C53/CSA3_2，重写件改用 xs_ 核后它们闲置）。文件进了清单、模块没进设计，如实列出，不判红。
        #   - 在闭包里却成了顶层 = srcmap 多认了一个「例化」，映射表就不是实际 elaborate 的集合 → 判红。
        # shellcheck disable=SC2046
        python3 - "$SRCMAP" $(tops_of "$W/closure/elab.log") <<'PY' || fail=1
import sys
rows = [l.split('\t') for l in open(sys.argv[1]) if l.strip() and not l.startswith(('#', 'module\t'))]
closure = {r[0] for r in rows}
tops = set(sys.argv[2:])
if 'XSTile' not in tops:
    print('[closure] FAIL（XSTile 不是顶层）'); sys.exit(1)
bad = sorted((tops - {'XSTile'}) & closure)
idle = sorted(tops - {'XSTile'} - closure)
print(f'[closure] 同文件闲置（不在闭包、未例化）{len(idle)}: {" ".join(idle)}')
if bad:
    print(f'[closure] FAIL（源表闭包里的 {bad} 实际没被例化：srcmap 多认）'); sys.exit(1)
print('[closure] PASS（顶层 = XSTile ∪ 闭包外闲置件）')
PY
    else
        fail=1
    fi
fi

if [ "$fail" -ne 0 ]; then echo "XSTILE_RTL_ELAB: FAIL（steps=$STEPS）"; exit 1; fi
echo "XSTILE_RTL_ELAB: PASS（steps=$STEPS；rtl $(grep -c "^$SV_HOME/rtl/" "$W/files.f") 文件 + 存储模型 $(grep -vc "^$SV_HOME/rtl/" "$W/files.f") 文件；闭包 $(grep -vcE '^(#|module	)' "$SRCMAP") 模块）"
