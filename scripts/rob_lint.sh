#!/usr/bin/env bash
# Rob 核的"写到一半也能跑"的语法/隐式线闸。
#
# 为什么要有它：`gen_rob.py --write` 只有在核**驱动全** 633 个 output + 78 根网
# 之后才肯写生成区，而写核是分批的 —— 中间那些天里没有任何东西在看语法。
#
# ★两条判据，缺一不可★
#  1. VCS -sverilog +lint=all 零 error 零 warning；
#  2. ★`default_nettype none`★。没有这一条，VCS 会把**打错的名字**当成一根
#     一位的隐式 wire 安静地接受。实测抓到过两类真问题：
#       · exceptionGen_io_wb_1..5_bits_hasException —— io_wb 的下标与
#         io_writeback 的下标不是一回事，写错的那 5 根成了悬空隐式线；
#       · io_isVsetFlushPipe —— 这个端口在 golden 里被 firtool 消掉了，
#         照 Scala 写出来就是一根悬空隐式线。
#     两者 VCS 默认都**不报**。
#
# 它**不**替代 gen_rob.py 的 SCAFFOLD 断言（那条管"驱动全没有"），
# 也不替代 FM。用法：bash scripts/rob_lint.sh
set -euo pipefail
cd "$(dirname "$0")/.."
WORK="${ROB_LINT_WORK:-${TMPDIR:-/tmp}/rob_lint.$$}"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

python3 - "$WORK/core.sv" <<'PY'
import sys, os
sys.path.insert(0, 'scripts')
import gen_rob as G
text, lines = G.load_golden(G.GOLDEN)
ports, pend = G.parse_ports(lines)
children = G.parse_children(lines, pend)
gdir = os.path.dirname(G.GOLDEN)
netw = G.net_widths(lines)
tl = open('rtl/backend/Rob.sv').read().split('\n')
idents = set(G._IDENT.findall(G.strip_sv_comments(G.core_body(tl))))
pmap = {p[3]: p for p in ports}
drives, reads = G.core_iface(children, ports, gdir)
childout = G.child_driven_outputs(children, ports, gdir)
must = [p[3] for p in ports if p[0] == 'output' and p[3] not in childout]
mo = [n for n in must if n not in idents]
mn = sorted(n for n in drives if n not in idents)
sys.stderr.write('ROB_LINT progress: outputs %d/%d  nets %d/%d\n'
                 % (len(must) - len(mo), len(must), len(drives) - len(mn), len(drives)))
rows = [('input', None, None, 'clock'), ('input', None, None, 'reset')]
for p in ports:
    if p[3] in ('clock', 'reset') or p[3] not in idents:
        continue
    rows.append(p)
exprw = G.expr_pin_widths(children, set(pmap), gdir)
for nm in sorted(drives):
    if nm not in idents:
        continue
    w = netw.get(drives[nm]) if drives[nm] is not None else exprw.get(nm)
    rows.append(('output', w - 1, 0, nm) if w > 1 else ('output', None, None, nm))
for nm in sorted(reads):
    if nm not in idents:
        continue
    w = netw.get(reads[nm]) if reads[nm] is not None else exprw.get(nm)
    rows.append(('input', w - 1, 0, nm) if w > 1 else ('input', None, None, nm))
out = G.splice(tl, 'core_ports', G.emit_core_ports(rows))
txt = '\n'.join(out)
# ★闸的第二条判据就在这一行★
txt = txt.replace('module xs_Rob_core', '`default_nettype none\nmodule xs_Rob_core', 1)
open(sys.argv[1], 'w').write(txt + '\n`default_nettype wire\n')
PY

cd "$WORK"
LOG="$WORK/vcs.log"
set +e
VCS_ARCH_OVERRIDE=linux vcs -full64 -sverilog -q +error+60 \
    +lint=all,noVCDE,noONGS,noUI "$WORK/core.sv" \
    -top xs_Rob_core -o "$WORK/simv" > "$LOG" 2>&1
rc=$?
set -e
n=$(grep -cP '^(Error|Warning)-\[' "$LOG" || true)
if [ "$rc" -ne 0 ] || [ "$n" -ne 0 ]; then
  grep -A4 -P '^(Error|Warning)-\[' "$LOG" | head -60
  echo "ROB_LINT_RC=1  (vcs rc=$rc, error/warning lines=$n)"
  exit 1
fi
echo "ROB_LINT_RC=0"
