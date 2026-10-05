#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_exublock.py —— ExuBlock 外壳（当前：ExuBlock_1，浮点执行块）wrapper 与 FM 钉点生成器。

沿用 scripts/gen_exeunit.py 的做法：从 G1 golden `ExuBlock_<k>.sv` 机械解析，生成

  1. `rtl/backend/ExuBlock_<k>.sv` —— golden 同名 wrapper：端口表逐字照抄；各 ExeUnit 的例化（实例名、
     端口顺序与 golden 一一对应）；本层时序逻辑（frm 打拍）交给手写的 `xs_ExuBlock_core`。
     wrapper 里**没有手写逻辑**，只有连线。
  2. `verif/ut/ExuBlock_<k>/fm_pins_pre.tcl` —— FM「匹配前」钉点：
     (a) 本层寄存器：golden 扁平名 exus_io_frm_REG / _1 … ↔ 核 u_core/exu_frm_reg[k][b]，逐位；
     (b) 每个 ExeUnit 自己签核时用过的钉点：tclsh 桩真跑那份钉点文件，取出实际发出的 set_user_match
         序列，加上实例路径前缀照搬。条数必须等于 docs/pin_call_seq.tsv（只读）里该文件登记的调用数。

## fail-closed（不认识的形状一律退出，不猜）

  * golden 每个 reg 都必须是 `exus_io_frm_REG(_k)`，且 always 块里恰为 `<= io_frm;`；
  * 每个 golden `_GEN*` 线都必须是 `_<实例>_io_in_ready & io_in_<i>_<j>_valid`（发射口 fire，只喂已删的
    性能计数），且不许有任何读者；
  * 每条实例连线的表达式必须是：顶层端口 / 另一实例的输出线 / frm 寄存器 / 常量 1'h1；
  * 每个顶层 assign 必须是 `io_in_<i>_<j>_ready = _<实例>_io_in_ready`。

## 用法

  python3 scripts/gen_exublock.py            # 写
  python3 scripts/gen_exublock.py --check    # 只比对不写；有漂移 rc=1（gate 自动扫描）
"""
import argparse
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
VARIANTS = ['ExuBlock_1']

# child 类型 -> 该类型签核时用过的「匹配前」钉点文件（相对 verif/ut/）
CHILD_PIN_FILES = {
    'ExeUnit_8':  'ExeUnit_8/fm_pins_pre.tcl',
    'ExeUnit_9':  'ExeUnit_9/fm_pins_pre.tcl',
    'ExeUnit_10': 'ExeUnit_10/fm_pins_pre.tcl',
}


def die(msg):
    sys.exit('gen_exublock: ERROR: ' + msg)


# =============================================================================
#  golden 解析
# =============================================================================
class Golden(object):
    def __init__(self, top):
        self.top = top
        text = (GOLDEN / f'{top}.sv').read_text()
        m = re.search(r'^module ' + re.escape(top) + r'\((.*?)\n\);\n(.*?)^endmodule', text, re.S | re.M)
        if not m:
            die(f'{top}: 找不到 module 体')
        self.port_text = m.group(1)
        body = m.group(2)
        body = re.sub(r'^[ \t]*`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '', body,
                      flags=re.S | re.M)
        if '`' in body:
            die(f'{top}: 去掉仿真块后仍有宏')
        self.ports = []
        for ln in self.port_text.splitlines():
            if not ln.strip():
                continue
            pm = re.match(r'^\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$', ln)
            if not pm:
                die(f'{top}: 端口行无法解析 {ln!r}')
            self.ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        self.port_dir = {n: d for d, _, n in self.ports}
        self.insts = []

        def take_inst(mm):
            conns = []
            for c in re.finditer(r'\.(\w+)\s*\((.*?)\)\s*(?:,|$)', mm.group(3), re.S):
                conns.append((c.group(1), ' '.join(c.group(2).split())))
            self.insts.append((mm.group(1), mm.group(2), conns))
            return ''
        body = re.sub(r'^  ([A-Z]\w*) (\w+) \(\n(.*?)^  \);\n', take_inst, body, flags=re.S | re.M)
        self.always = []

        def take_always(mm):
            self.always.append(mm.group(1))
            return ''
        body = re.sub(r'^  always @\(posedge clock\) begin\n(.*?)^  end // always @\(posedge\)\n',
                      take_always, body, flags=re.S | re.M)
        self.wire_w, self.wire_expr, self.reg_w, self.assign = {}, {}, {}, []
        for st in body.split(';'):
            st = ' '.join(st.split())
            if not st:
                continue
            mm = re.match(r'^wire (?:\[(\d+):0\] )?(\w+)(?: = (.*))?$', st)
            if mm:
                self.wire_w[mm.group(2)] = int(mm.group(1)) + 1 if mm.group(1) else 1
                if mm.group(3) is not None:
                    self.wire_expr[mm.group(2)] = mm.group(3)
                continue
            mm = re.match(r'^reg (?:\[(\d+):0\] )?(\w+)$', st)
            if mm:
                self.reg_w[mm.group(2)] = int(mm.group(1)) + 1 if mm.group(1) else 1
                continue
            mm = re.match(r'^assign (\w+) = (.*)$', st)
            if mm:
                self.assign.append((mm.group(1), mm.group(2)))
                continue
            die(f'{top}: 不认识的语句: {st[:120]}')


class Variant(object):
    def __init__(self, top):
        g = Golden(top)
        self.g = g
        self.top = top
        # ---- frm 寄存器：exus_io_frm_REG, _1, _2 … 按下标排序 ----
        def ridx(n):
            m = re.fullmatch(r'exus_io_frm_REG(?:_(\d+))?', n)
            if not m:
                die(f'{top}: 不认识的寄存器 {n}')
            return int(m.group(1) or 0)
        self.frm_regs = sorted(g.reg_w, key=ridx)
        if [ridx(n) for n in self.frm_regs] != list(range(len(self.frm_regs))):
            die(f'{top}: frm 寄存器下标不连续 {self.frm_regs}')
        for n in self.frm_regs:
            if g.reg_w[n] != 3:
                die(f'{top}: {n} 宽度 {g.reg_w[n]} != 3')
        lines = [ln.strip() for a in g.always for ln in a.splitlines() if ln.strip()]
        if sorted(lines) != sorted(f'{n} <= io_frm;' for n in self.frm_regs):
            die(f'{top}: always 块不是纯 frm 打拍: {lines}')
        self.frm_idx = {n: k for k, n in enumerate(self.frm_regs)}
        # ---- 实例 ----
        self.inst_names = [n for _, n, _ in g.insts]
        for typ, _, _ in g.insts:
            if typ not in CHILD_PIN_FILES:
                die(f'{top}: 不认识的 child 类型 {typ}')
        # ---- _GEN*：发射口 fire，无读者 ----
        for w, e in g.wire_expr.items():
            m = re.fullmatch(r'(_\w+_io_in_ready) & (io_in_\d+_\d+_valid)', e)
            if not (w.startswith('_GEN') and m):
                die(f'{top}: 不认识的 wire 表达式 {w} = {e}')
            for _, _, cs in g.insts:
                if any(re.search(r'\b' + w + r'\b', x) for _, x in cs):
                    die(f'{top}: {w} 有读者')
        # ---- 顶层 assign ----
        for p, e in g.assign:
            if not (re.fullmatch(r'io_in_\d+_\d+_ready', p) and re.fullmatch(r'_\w+_io_in_ready', e)):
                die(f'{top}: 不认识的 assign {p} = {e}')

    def child_wire(self, e):
        m = re.fullmatch(r'_(\w+?)_(io_\w+)', e)
        if m and m.group(1) in self.inst_names and e in self.g.wire_w:
            return e[1:]
        return None

    def conv(self, iname, p, e):
        if e in self.g.port_dir:
            return e
        if e in self.frm_idx:
            return f'exu_frm[{self.frm_idx[e]}]'
        if e == "1'h1":
            return "1'b1"
        cw = self.child_wire(e)
        if cw:
            return cw
        die(f'{self.top}: {iname}.{p} 认不出的连线表达式 {e!r}')


def rng(w):
    return f'[{w - 1}:0]' if w > 1 else ''


def gen_wrapper(v):
    g = v.g
    L = []
    L.append('// =============================================================================')
    L.append(f'// {v.top} —— 执行块外壳（golden 同名 wrapper；由 scripts/gen_exublock.py 从 G1 golden 生成，勿手改）')
    L.append('// -----------------------------------------------------------------------------')
    L.append('// 发射口 → ExeUnit（按 golden 实例序）：')
    for typ, iname, cs in g.insts:
        vin = dict(cs).get('io_in_valid', '?')
        port = vin[:-len('_valid')] if vin.endswith('_valid') else vin
        L.append(f'//   {port:<10} -> {iname:<7} {typ}')
    L.append(f'// 本层时序逻辑只有 frm 打拍（{len(v.frm_regs)} 份），在 xs_ExuBlock_core（rtl/backend/xs_ExuBlock_core.sv）；')
    L.append('//   发射口 ready/valid/bits、写回口、冲刷、DFT 时钟门控使能全部直连 ExeUnit。')
    L.append('// 子模块：各 ExeUnit 均为已签核件（两侧白盒，实例名与 golden 相同）。')
    L.append(f'// golden 对照：G1-canonical/golden-rtl/{v.top}.sv')
    L.append('// 本文件导航：')
    L.append('//   §1 发射口 → ExeUnit 分发：ExeUnit 输出线 + io_in_*_ready 直通')
    L.append('//   §2 本层核：frm 打拍')
    L.append('//   §3 ExeUnit 例化（写回口 io_out_* 直出；out.ready 由上层给或恒 1）')
    L.append('//   §4 唤醒 / og0-og1 取消 / perf：本层无（见核文件头）')
    L.append('// =============================================================================')
    L.append(f'module {v.top}(')
    for k, (d, w, n) in enumerate(g.ports):
        L.append(f'  {d:<6} {rng(w):<7} {n}{"," if k + 1 < len(g.ports) else ""}')
    L.append(');')
    L.append('')
    L.append('  // ===========================================================================')
    L.append('  // §1 发射口 → ExeUnit 分发')
    L.append('  //   每个发射口 io_in_<i>_<j> 恰好接一个 ExeUnit；ready 原样回给发射口（golden 的')
    L.append('  //   `_<实例>_<端口>` 去掉前导下划线即下面的线名）。')
    L.append('  // ===========================================================================')
    for w, wd in g.wire_w.items():
        if w in g.wire_expr:
            continue
        cw = v.child_wire(w)
        if not cw:
            die(f'{v.top}: 不认识的 wire 声明 {w}')
        L.append(f'  wire {rng(wd):<7} {cw};')
    for p, e in g.assign:
        L.append(f'  assign {p} = {e[1:]};')
    L.append('')
    L.append('  // ===========================================================================')
    L.append('  // §2 本层核：frm 打拍（每个 ExeUnit 一份）')
    L.append('  // ===========================================================================')
    L.append(f'  wire [2:0] exu_frm [{len(v.frm_regs)}];')
    L.append('')
    L.append(f'  xs_ExuBlock_core #(.N_FRM({len(v.frm_regs)})) u_core (')
    L.append('    .clock   (clock),')
    L.append('    .frm     (io_frm),')
    L.append('    .exu_frm (exu_frm)')
    L.append('  );')
    L.append('')
    L.append('  // ===========================================================================')
    L.append('  // §3 ExeUnit 例化：冲刷广播、发射口、写回口、frm、DFT 时钟门控使能')
    L.append('  // ===========================================================================')
    for typ, iname, cs in g.insts:
        wmax = max(len(p) for p, _ in cs)
        L.append(f'  {typ} {iname} (')
        for k, (p, e) in enumerate(cs):
            L.append(f'    .{p.ljust(wmax)} ({v.conv(iname, p, e)}){"," if k + 1 < len(cs) else ""}')
        L.append('  );')
        L.append('')
    L.append('  // ===========================================================================')
    L.append('  // §4 唤醒 / og0-og1 取消 / perf：本层无 —— 唤醒与取消在 IssueQueue / DataPath 里做；')
    L.append('  //   Scala 的 in.fire 性能计数在综合口径下被删（golden 只剩无读者的 fire 线）。')
    L.append('  // ===========================================================================')
    L.append('')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


# =============================================================================
#  钉点
# =============================================================================
def child_pin_pairs(typ):
    f = REPO / 'verif' / 'ut' / CHILD_PIN_FILES[typ]
    stub = (
        'rename puts ::__orig_puts\n'
        'proc puts {args} {}\n'
        'set ::CALLS {}\n'
        'proc set_user_match {args} { lappend ::CALLS $args; return 1 }\n'
        f'set top {typ}\n'
        f'source {{{f}}}\n'
        'foreach c $::CALLS { ::__orig_puts stdout [join $c "\\t"] }\n'
    )
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as t:
        t.write(stub)
        tn = t.name
    r = subprocess.run(['tclsh', tn], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    pathlib.Path(tn).unlink()
    if r.returncode != 0:
        die(f'tclsh 跑 {f} 失败: {r.stderr[:300]}')
    pairs = [tuple(ln.split('\t')) for ln in r.stdout.splitlines() if ln.strip()]
    want = None
    for ln in (REPO / 'docs' / 'pin_call_seq.tsv').read_text().splitlines():
        c = ln.split('\t')
        if len(c) >= 3 and c[0] == f'verif/ut/{CHILD_PIN_FILES[typ]}' and c[1] == typ:
            want = int(c[2])
    if want is None or want != len(pairs):
        die(f'{typ}: 钉点调用数 {len(pairs)} 与 pin_call_seq.tsv 登记 {want} 不符')
    out = []
    for p in pairs:
        if len(p) != 2 or not p[0].startswith(f'r:/WORK/{typ}/') or not p[1].startswith(f'i:/WORK/{typ}/'):
            die(f'{typ}: 钉点形状不认识 {p}')
        out.append((p[0][len(f'r:/WORK/{typ}/'):], p[1][len(f'i:/WORK/{typ}/'):]))
    return out


def tcl_esc(s):
    return s.replace('[', '\\[').replace(']', '\\]')


def gen_pins(v):
    rows = []
    for n in v.frm_regs:
        k = v.frm_idx[n]
        for b in range(3):
            rows.append((f'{n}_reg[{b}]', f'u_core/exu_frm_reg[{k}][{b}]'))
    shell_n = len(rows)
    child = []
    for typ, iname, _ in v.g.insts:
        for rp, ip in child_pin_pairs(typ):
            child.append((iname, typ, f'{iname}/{rp}', f'{iname}/{ip}'))
    seen = set()
    for _, i in rows + [(c[2], c[3]) for c in child]:
        if i in seen:
            die(f'{v.top}: impl 侧不单射 {i}')
        seen.add(i)
    total = shell_n + len(child)
    tag = re.sub(r'\W', '_', v.top).upper()
    L = []
    L.append(f'# {v.top} FM「匹配前」钉点 —— 自动生成：scripts/gen_exublock.py（勿手改）')
    L.append('#')
    L.append('# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。')
    L.append(f'# (a) 本层寄存器 {shell_n} 位：golden exus_io_frm_REG* <-> xs_ExuBlock_core 的 exu_frm 数组；')
    L.append(f'# (b) 各 ExeUnit 签核时用过的钉点 {len(child)} 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。')
    L.append('# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。')
    L.append(f'set ::{tag}_PIN_OK 0')
    L.append(f'set ::{tag}_PIN_BAD 0')
    L.append(f'proc {tag.lower()}_pin {{r i}} {{')
    L.append(f'  set rr "r:/WORK/{v.top}/$r"')
    L.append(f'  set ii "i:/WORK/{v.top}/$i"')
    L.append(f'  if {{[set_user_match $rr $ii]}} {{ incr ::{tag}_PIN_OK }} else {{')
    L.append(f'    incr ::{tag}_PIN_BAD')
    L.append(f'    if {{$::{tag}_PIN_BAD <= 10}} {{ puts "{tag}_PIN_FAIL: $rr <-> $ii" }}')
    L.append('  }')
    L.append('}')
    L.append(f'puts "{tag}_PIN_BEGIN {v.top} expect={total}"')
    L.append('# ---- (a) 本层寄存器 ----')
    for r, i in rows:
        L.append(f'{tag.lower()}_pin {tcl_esc(r)} {tcl_esc(i)}')
    cur = None
    for iname, typ, r, i in child:
        if cur != iname:
            L.append(f'# ---- (b) {iname}（{typ}）：verif/ut/{CHILD_PIN_FILES[typ]} 的调用序列 ----')
            cur = iname
        L.append(f'{tag.lower()}_pin {tcl_esc(r)} {tcl_esc(i)}')
    L.append(f'puts "{tag}_PIN_END ok=$::{tag}_PIN_OK bad=$::{tag}_PIN_BAD expect={total}"')
    L.append(f'if {{$::{tag}_PIN_BAD != 0}} {{ error "{tag}_PIN_REFUSED=$::{tag}_PIN_BAD" }}')
    L.append(f'if {{$::{tag}_PIN_OK != {total}}} {{ error "{tag}_PIN_COUNT=$::{tag}_PIN_OK expected {total}" }}')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    ap.add_argument('variants', nargs='*')
    a = ap.parse_args()
    drift = 0
    for top in a.variants or VARIANTS:
        v = Variant(top)
        outs = {
            REPO / 'rtl' / 'backend' / f'{top}.sv': gen_wrapper(v),
            REPO / 'verif' / 'ut' / top / 'fm_pins_pre.tcl': gen_pins(v),
        }
        for p, text in outs.items():
            cur = p.read_text() if p.exists() else None
            if a.check:
                if cur != text:
                    print(f'DRIFT {p.relative_to(REPO)}')
                    drift = 1
            elif cur != text:
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(text)
                print(f'wrote {p.relative_to(REPO)}')
    if a.check and not drift:
        print('gen_exublock: 全部与生成结果一致')
    return drift


if __name__ == '__main__':
    sys.exit(main())
