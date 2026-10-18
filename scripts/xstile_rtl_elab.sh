#!/usr/bin/env bash
# =============================================================================
# xstile_rtl_elab.sh —— 只用「重写逻辑 + 已批准存储模型」把 XSTile elaborate 出来（codex 0238 主线 1）
#
# 源清单由 scripts/xstile_srcmap.py 机械生成：闭包内 RTL 全取 rtl/，golden 只有登记过的
# 存储模型（sha256 逐字对登记表）。本脚本做两件 srcmap 自己做不到的事：
#
#   1. 用 VCS 真 elaborate：清单少一个被例化的模块 → Error-[CFCILFBI]，当场失败。
#      所以 srcmap 的例化识别即使漏认，也漏不过这里。
#   2. **不给 -top**：VCS 会把清单里所有「没被任何人例化」的模块列为 Top Level Modules。
#      要求这一栏**只有 XSTile**——多出来的就是清单里混进了闭包外的件（srcmap 多认）。
#
# 编译设定：+define+SYNTHESIS（与 full_elab.sh 一致，可综合口径）。仿真口径
# （SimTop / DIFFTEST / 不定义 SYNTHESIS）在 verif/sim/ 泳道，不在这里。
#
# 用法: bash scripts/xstile_rtl_elab.sh [workdir]     # 默认 build_xstile_rtl/
# =============================================================================
set -euo pipefail
SV_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="${1:-$SV_HOME/build_xstile_rtl}"
mkdir -p "$W"
cd "$W"
export VCS_ARCH_OVERRIDE=linux

python3 "$SV_HOME/scripts/xstile_srcmap.py" --filelist "$W/files.f"
find "$SV_HOME/rtl" -type d | sed 's/^/+incdir+/' > "$W/inc.f"

set +e
vcs -full64 -sverilog -timescale=1ns/1ps +define+SYNTHESIS +error+100000 \
    -f "$W/inc.f" -f "$W/files.f" -o "$W/simv_xstile_rtl" -l "$W/elab.log" \
    > /dev/null 2>&1
rc=$?
set -e

nerr=$(grep -cE '^Error-' "$W/elab.log" || true)
# VCS 在 Parsing 之后打印:
#   Top Level Modules:
#          XSTile
#   TimeScale is 1 ns / 1 ps
tops=$(awk '/^Top Level Modules:/{f=1;next} f&&/^[[:space:]]+[A-Za-z_]/{print $1;next} f{exit}' "$W/elab.log")
echo "vcs rc=$rc  errors=$nerr"
echo "Top Level Modules: $(echo $tops)"
if [ "$rc" -ne 0 ] || [ "$nerr" -ne 0 ]; then
    grep -A4 -E '^Error-' "$W/elab.log" | head -40
    echo "XSTILE_RTL_ELAB: FAIL（elaborate 失败）"; exit 1
fi
# 判据：XSTile 必须是顶层；其余顶层必须都**不在**源表闭包里。
#   - 不在闭包里的顶层 = 与闭包内模块同文件、但没被例化的件（例：rtl/backend/MulUnit.sv 里的
#     C22/C53/CSA3_2，重写件改用 xs_ 核后它们闲置）。文件进了清单、模块没进设计，如实列出，不判红。
#   - 在闭包里却成了顶层 = srcmap 多认了一个「例化」，映射表就不是实际 elaborate 的集合 → 判红。
python3 - "$SV_HOME/docs/xstile_srcmap.tsv" $tops <<'PY'
import sys
rows = [l.split('\t') for l in open(sys.argv[1]) if l.strip() and not l.startswith(('#', 'module\t'))]
closure = {r[0] for r in rows}
tops = set(sys.argv[2:])
if 'XSTile' not in tops:
    print('XSTILE_RTL_ELAB: FAIL（XSTile 不是顶层）'); sys.exit(1)
bad = sorted((tops - {'XSTile'}) & closure)
idle = sorted(tops - {'XSTile'} - closure)
print(f'同文件闲置（不在闭包、未例化）{len(idle)}: {" ".join(idle)}')
if bad:
    print(f'XSTILE_RTL_ELAB: FAIL（源表闭包里的 {bad} 实际没被例化：srcmap 多认）'); sys.exit(1)
PY
echo "XSTILE_RTL_ELAB: PASS（rtl $(grep -c "^$SV_HOME/rtl/" "$W/files.f") 文件 + 存储模型 $(grep -vc "^$SV_HOME/rtl/" "$W/files.f") 文件；闭包 $(grep -vcE '^(#|module	)' "$SV_HOME/docs/xstile_srcmap.tsv") 模块全部实际 elaborate）"
