#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_exublock.py —— ExuBlock 外壳（ExuBlock_1 浮点执行块、ExuBlock 整数执行块）wrapper 与 FM 钉点生成器。

沿用 scripts/gen_exeunit.py 的做法：从 G1 golden `ExuBlock_<k>.sv` 机械解析，生成

  1. `rtl/backend/ExuBlock_<k>.sv` —— golden 同名 wrapper：端口表逐字照抄；各 ExeUnit 的例化（实例名、
     端口顺序与 golden 一一对应）；本层时序逻辑（frm 打拍）交给手写的 `xs_ExuBlock_core`。
     wrapper 里**没有手写逻辑**，只有连线。
  2. `verif/ut/ExuBlock_<k>/fm_pins_pre.tcl` —— FM「匹配前」钉点：
     (a) 本层寄存器：golden 扁平名 exus_io_frm_REG / _1 … ↔ 核 u_core/exu_frm_reg[k][b]，逐位；
     (b) 每个 ExeUnit 自己签核时用过的钉点：tclsh 桩真跑那份钉点文件，取出实际发出的 set_user_match
         序列，加上实例路径前缀照搬。条数必须等于 docs/pin_call_seq.tsv（只读）里该文件登记的调用数
         （尚未登记的子钉点文件见 PENDING_PIN_LOGS：改与该 child 签核 fm.log 里钉点文件自己打印的计数核对）。
  3. `verif/ut/ExuBlock_<k>/fm_pins.tcl`（只有含「动态钉点」child 的变体才有，当前 = ExuBlock 的 exus_7 = ExeUnit_7）——
     child 的匹配后钉点文件机械改前缀照搬：`/WORK/<child 类型>/` -> `/WORK/<变体>/<实例>/`、守卫同理，替换次数逐项核对。

## ExuBlock（整数执行块，2026-10-04 exublock0 lane 加）比 ExuBlock_1 多的本层结构

  * 致命错误上报：exus_7（ExeUnit_7，含 CSR）的 io_error 在本层再打两拍（HasCriticalErrors），交给共享件
    rtl/common/xs_CriticalErrorDelay_core.sv（与 ExeUnit_7 那一层同一个件）；
  * CSR 的 instrAddrTransType 从 exus_7 的 csrio 出来，既送顶层口、又送各 BranchUnit/JumpUnit 所在的 ExeUnit
    （Scala `exus.map(_.io.instrAddrTransType.foreach(_ := csrio.instrAddrTransType))`）——纯连线；
  * perf：alu / brh 的 fire 个数分布（PopCount(fire) === i）在综合口径下被删，golden 只剩无读者的 *_probe / _GEN* 线。

## fail-closed（不认识的形状一律退出，不猜）

  * golden 每个 reg 都必须是 `exus_io_frm_REG(_k)`，且 always 块里恰为 `<= io_frm;`；
  * 每个 golden `_GEN*` 线都必须是 `_<实例>_io_in_ready & io_in_<i>_<j>_valid`（发射口 fire，只喂已删的
    性能计数），且不许有任何读者；ExuBlock 的 *_probe / PopCount 线同理：只许读 fire 线 / 别的 perf 线 / 常量，
    且读者只能是别的 perf 线；
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
VARIANTS = ['ExuBlock_1', 'ExuBlock', 'ExuBlock_2']

# child 类型 -> 该类型签核时用过的「匹配前」钉点文件（相对 verif/ut/）
CHILD_PIN_FILES = {
    'ExeUnit_8':  'ExeUnit_8/fm_pins_pre.tcl',
    'ExeUnit_9':  'ExeUnit_9/fm_pins_pre.tcl',
    'ExeUnit_10': 'ExeUnit_10/fm_pins_pre.tcl',
    'ExeUnit':    'ExeUnit/fm_pins_pre.tcl',
    'ExeUnit_1':  'ExeUnit_1/fm_pins_pre.tcl',
    'ExeUnit_4':  None,              # 单 FU（Alu）无外壳寄存器、无子钉点：gen_exeunit.py 不为它生成钉点文件
    'ExeUnit_5':  'ExeUnit_5/fm_pins_pre.tcl',
    'ExeUnit_7':  'ExeUnit_7/fm_pins_pre.tcl',
    # 向量执行块 ExuBlock_2（exublock2b lane 加）
    'ExeUnit_13': 'ExeUnit_13/fm_pins_pre.tcl',
    'ExeUnit_14': 'ExeUnit_14/fm_pins_pre.tcl',
    'ExeUnit_15': 'ExeUnit_15/fm_pins_pre.tcl',
    'ExeUnit_16': 'ExeUnit_16/fm_pins_pre.tcl',
    'ExeUnit_17': 'ExeUnit_17/fm_pins_pre.tcl',
}

# child 签核用的**动态**钉点文件（匹配后跑）：进本层后机械改前缀照搬成 verif/ut/<变体>/fm_pins.tcl
DYN_CHILD_PIN_FILES = {
    'ExeUnit_7': 'ExeUnit_7/fm_pins.tcl',
}

# 还没进 docs/pin_call_seq.tsv 的子钉点文件（派生表由集成者在 main 上统一登记，lane 不改）：
#   条数改与该 child **签核跑**的 fm.log 里钉点文件自己打印的 `<TAG>_PIN_END ok=N bad=0 expect=N` 核对 ——
#   那是同一份钉点文件在 FM 里真跑出的计数。登记后两处都在，取登记值并要求与 fm.log 一致。
PENDING_PIN_LOGS = {
    'verif/ut/ExeUnit_7/fm_pins_pre.tcl': 'evidence/52257043735e/ExeUnit_7/fm.log',
    'verif/ut/ExeUnit_13/fm_pins_pre.tcl': 'evidence/5ec0626546dd/ExeUnit_13/fm.log',
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
        # ---- 致命错误两拍：io_error_<k>_REG / _REG_1（来源 = 某个 child 的 io_error_<j>）----
        self.err = []
        err_lines = []
        for n in list(g.reg_w):
            m = re.fullmatch(r'io_error_(\d+)_REG', n)
            if not m:
                continue
            k = int(m.group(1))
            n2 = f'io_error_{k}_REG_1'
            if g.reg_w[n] != 1 or g.reg_w.get(n2) != 1:
                die(f'{top}: {n} / {n2} 不是一对 1 位寄存器')
            src = None
            for a in g.always:
                mm = re.search(re.escape(n) + r' <= (_(\w+?)_io_error_\d+);', a)
                if mm:
                    src = mm.group(1)
            if src is None or not any(src[1:].startswith(i + '_io_') for _, i, _ in g.insts):
                die(f'{top}: {n} 的来源不是某个 child 的 io_error')
            if dict(g.assign).get(f'io_error_{k}') != n2:
                die(f'{top}: io_error_{k} 不是直接取 {n2}')
            self.err.append((k, src))
            err_lines += [f'{n} <= {src};', f'{n2} <= {n};']
        self.err.sort()
        if [k for k, _ in self.err] != list(range(len(self.err))):
            die(f'{top}: io_error 下标不连续')
        err_regs = {f'io_error_{k}_REG{s}' for k, _ in self.err for s in ('', '_1')}
        # ---- frm 寄存器：exus_io_frm_REG, _1, _2 … 按下标排序 ----
        def ridx(n):
            m = re.fullmatch(r'exus_io_frm_REG(?:_(\d+))?', n)
            if not m:
                die(f'{top}: 不认识的寄存器 {n}')
            return int(m.group(1) or 0)
        self.frm_regs = sorted([n for n in g.reg_w if n not in err_regs], key=ridx)
        if [ridx(n) for n in self.frm_regs] != list(range(len(self.frm_regs))):
            die(f'{top}: frm 寄存器下标不连续 {self.frm_regs}')
        for n in self.frm_regs:
            if g.reg_w[n] != 3:
                die(f'{top}: {n} 宽度 {g.reg_w[n]} != 3')
        lines = [ln.strip() for a in g.always for ln in a.splitlines() if ln.strip()]
        if sorted(lines) != sorted([f'{n} <= io_frm;' for n in self.frm_regs] + err_lines):
            die(f'{top}: always 块不是纯 frm 打拍 + 错误两拍: {lines}')
        self.frm_idx = {n: k for k, n in enumerate(self.frm_regs)}
        # ---- 实例 ----
        self.inst_names = [n for _, n, _ in g.insts]
        for typ, _, _ in g.insts:
            if typ not in CHILD_PIN_FILES:
                die(f'{top}: 不认识的 child 类型 {typ}')
        # ---- _GEN* / *_probe：发射口 fire 与 perf 计数，无读者（perf 线之间互读除外）----
        perf = set(g.wire_expr)
        for w, e in g.wire_expr.items():
            m = re.fullmatch(r'(_\w+_io_in_ready) & (io_in_\d+_\d+_valid)', e)
            if not ((w.startswith('_GEN') or w.endswith('_probe')) and (m or not self.fire_free(e, perf))):
                die(f'{top}: 不认识的 wire 表达式 {w} = {e}')
            for _, _, cs in g.insts:
                if any(re.search(r'\b' + w + r'\b', x) for _, x in cs):
                    die(f'{top}: {w} 有读者')
            if any(re.search(r'\b' + w + r'\b', x) for _, x in g.assign) or \
                    any(re.search(r'\b' + w + r'\b', a) for a in g.always):
                die(f'{top}: {w} 有读者')
        # ---- 顶层 assign：发射口 ready 直通 / child 输出直通（csrio）/ 错误两拍 ----
        for p, e in g.assign:
            if re.fullmatch(r'io_error_\d+', p) and p in {f'io_error_{k}' for k, _ in self.err}:
                continue
            if self.g.port_dir.get(p) != 'output' or not self.child_wire(e):
                die(f'{top}: 不认识的 assign {p} = {e}')
            if not (re.fullmatch(r'io_in_\d+_\d+_ready', p) and re.fullmatch(r'_\w+_io_in_ready', e)) and \
                    not (p.startswith('io_csrio_') and e.endswith('_' + p)):
                die(f'{top}: 不认识的 assign {p} = {e}')

    @staticmethod
    def fire_free(e, perf):
        """perf 线表达式里出现的标识符：只许是 fire 线、别的 perf 线、发射口 ready/valid、常量。
        返回不合规的标识符集合（空 = 合规）。"""
        bad = set()
        for i in re.findall(r"\b[A-Za-z_]\w*\b", re.sub(r"\d+'[hbdo][0-9a-fA-F_]+", ' ', e)):
            if i in perf or re.fullmatch(r'_\w+_io_in_ready|io_in_\d+_\d+_valid', i):
                continue
            bad.add(i)
        return bad

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
    if v.err:
        L.append(f'// 本层时序逻辑只有两样：frm 打拍（{len(v.frm_regs)} 份，xs_ExuBlock_core，rtl/backend/xs_ExuBlock_core.sv）与')
        L.append(f'//   致命错误两拍（io_error × {len(v.err)}，xs_CriticalErrorDelay_core，rtl/common/xs_CriticalErrorDelay_core.sv）；')
        L.append('//   发射口 ready/valid/bits、写回口、冲刷、CSR 的 csrio、DFT 时钟门控使能全部直连 ExeUnit。')
    else:
        L.append(f'// 本层时序逻辑只有 frm 打拍（{len(v.frm_regs)} 份），在 xs_ExuBlock_core（rtl/backend/xs_ExuBlock_core.sv）；')
        L.append('//   发射口 ready/valid/bits、写回口、冲刷、DFT 时钟门控使能全部直连 ExeUnit。')
    L.append('// 子模块：各 ExeUnit 均为已签核件（两侧白盒，实例名与 golden 相同）。')
    L.append(f'// golden 对照：G1-canonical/golden-rtl/{v.top}.sv')
    L.append('// 本文件导航：')
    L.append('//   §1 发射口 → ExeUnit 分发：ExeUnit 输出线 + io_in_*_ready 直通')
    L.append('//   §2 本层核：frm 打拍' + (' + 致命错误两拍' if v.err else ''))
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
        if p.startswith('io_in_'):
            L.append(f'  assign {p} = {e[1:]};')
    csr_pass = [(p, e) for p, e in g.assign if p.startswith('io_csrio_')]
    if csr_pass:
        L.append('  // CSR 的地址翻译模式：从含 CSR 的 ExeUnit 出来，送顶层口（另经 §3 送各 BranchUnit/JumpUnit 所在 ExeUnit）')
        for p, e in csr_pass:
            L.append(f'  assign {p} = {e[1:]};')
    L.append('')
    L.append('  // ===========================================================================')
    L.append('  // §2 本层核：frm 打拍（每个 ExeUnit 一份）' + ('；致命错误两拍' if v.err else ''))
    L.append('  // ===========================================================================')
    L.append(f'  wire [2:0] exu_frm [{len(v.frm_regs)}];')
    L.append('')
    L.append(f'  xs_ExuBlock_core #(.N_FRM({len(v.frm_regs)})) u_core (')
    L.append('    .clock   (clock),')
    L.append('    .frm     (io_frm),')
    L.append('    .exu_frm (exu_frm)')
    L.append('  );')
    L.append('')
    if v.err:
        L.append('  // 致命错误上报：child 的 io_error 在本层再打两拍（HasCriticalErrors；共享件 xs_CriticalErrorDelay_core）')
        L.append(f'  wire [{len(v.err) - 1}:0] err_out;')
        L.append('')
        L.append(f'  xs_CriticalErrorDelay_core #(.N({len(v.err)})) u_err (')
        L.append('    .clock   (clock),')
        L.append('    .err_in  ({' + ', '.join(src[1:] for _, src in reversed(v.err)) + '}),')
        L.append('    .err_out (err_out)')
        L.append('  );')
        for k, _ in v.err:
            L.append(f'  assign io_error_{k} = err_out[{k}];')
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
    if CHILD_PIN_FILES[typ] is None:
        if (REPO / 'verif' / 'ut' / typ / 'fm_pins_pre.tcl').exists():
            die(f'{typ}: 登记为无钉点文件，但 verif/ut/{typ}/fm_pins_pre.tcl 存在')
        return []
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
    rel = f'verif/ut/{CHILD_PIN_FILES[typ]}'
    if rel in PENDING_PIN_LOGS:
        # 与 child 签核跑 fm.log 里钉点文件自己打印的计数核对（未登记时这是唯一依据，登记后两者都要对上）
        log = PENDING_PIN_LOGS[rel]
        if log.startswith('@@'):
            die(f'{typ}: {rel} 未登记且尚无签核 fm.log')
        ends = re.findall(r'^(\w+)_PIN_END ok=(\d+) bad=(\d+) expect=(\d+)$', (REPO / log).read_text(), re.M)
        if len(ends) != 1 or not (int(ends[0][1]) == int(ends[0][3]) == len(pairs) and ends[0][2] == '0'):
            die(f'{typ}: 钉点调用数 {len(pairs)} 与签核 fm.log {log} 的 PIN_END {ends} 不符')
        if want is None:
            want = len(pairs)
    if want is None or want != len(pairs):
        die(f'{typ}: 钉点调用数 {len(pairs)} 与 pin_call_seq.tsv 登记 {want} 不符')
    out = []
    for p in pairs:
        # 允许 `set_user_match -type cell r i`（向量 ExeUnit 里 VFAlu 的钉点按 cell 钉，同 gen_exeunit.py）：类型原样带到本层
        cell = len(p) == 4 and p[0] == '-type' and p[1] == 'cell'
        if cell:
            p = p[2:]
        if len(p) != 2 or not p[0].startswith(f'r:/WORK/{typ}/') or not p[1].startswith(f'i:/WORK/{typ}/'):
            die(f'{typ}: 钉点形状不认识 {p}')
        out.append((p[0][len(f'r:/WORK/{typ}/'):], p[1][len(f'i:/WORK/{typ}/'):]) + (('cell',) if cell else ()))
    return out


def tcl_esc(s):
    # 先转义反斜杠本身（打包结构体寄存器名里可能带字面 \），再转义方括号（同 gen_exeunit.py）
    return s.replace('\\', '\\\\').replace('[', '\\[').replace(']', '\\]')


def gen_pins(v):
    rows = []
    for n in v.frm_regs:
        k = v.frm_idx[n]
        for b in range(3):
            rows.append((f'{n}_reg[{b}]', f'u_core/exu_frm_reg[{k}][{b}]'))
    shell_n = len(rows)
    child = []
    for typ, iname, _ in v.g.insts:
        for rp, ip, *cell in child_pin_pairs(typ):
            child.append((iname, typ, f'{iname}/{rp}', f'{iname}/{ip}') + tuple(cell))
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
    if any(len(c) > 4 for c in child):
        L.append(f'proc {tag.lower()}_pin_cell {{r i}} {{')
        L.append(f'  set rr "r:/WORK/{v.top}/$r"')
        L.append(f'  set ii "i:/WORK/{v.top}/$i"')
        L.append(f'  if {{[set_user_match -type cell $rr $ii]}} {{ incr ::{tag}_PIN_OK }} else {{')
        L.append(f'    incr ::{tag}_PIN_BAD')
        L.append(f'    if {{$::{tag}_PIN_BAD <= 10}} {{ puts "{tag}_PIN_FAIL: cell $rr <-> $ii" }}')
        L.append('  }')
        L.append('}')
    L.append(f'puts "{tag}_PIN_BEGIN {v.top} expect={total}"')
    L.append('# ---- (a) 本层寄存器 ----')
    for r, i in rows:
        L.append(f'{tag.lower()}_pin {tcl_esc(r)} {tcl_esc(i)}')
    cur = None
    for iname, typ, r, i, *cell in child:
        if cur != iname:
            L.append(f'# ---- (b) {iname}（{typ}）：verif/ut/{CHILD_PIN_FILES[typ]} 的调用序列 ----')
            cur = iname
        L.append(f'{tag.lower()}_pin{"_cell" if cell else ""} {tcl_esc(r)} {tcl_esc(i)}')
    L.append(f'puts "{tag}_PIN_END ok=$::{tag}_PIN_OK bad=$::{tag}_PIN_BAD expect={total}"')
    L.append(f'if {{$::{tag}_PIN_BAD != 0}} {{ error "{tag}_PIN_REFUSED=$::{tag}_PIN_BAD" }}')
    L.append(f'if {{$::{tag}_PIN_OK != {total}}} {{ error "{tag}_PIN_COUNT=$::{tag}_PIN_OK expected {total}" }}')
    return '\n'.join(L) + '\n'


def gen_dyn_pins(v):
    """含动态钉点 child 的变体：child 的匹配后钉点文件机械改前缀照搬（逐项核替换次数）。"""
    parts = []
    for typ, name, _ in v.g.insts:
        if typ not in DYN_CHILD_PIN_FILES:
            continue
        rel = DYN_CHILD_PIN_FILES[typ]
        src = (REPO / 'verif' / 'ut' / rel).read_text()
        old_pfx, new_pfx = f'/WORK/{typ}/', f'/WORK/{v.top}/{name}/'
        old_g, new_g = f'if {{$top eq "{typ}"}} {{', f'if {{$top eq "{v.top}"}} {{'
        n_pfx = src.count(old_pfx)
        if n_pfx == 0 or src.count(old_g) != 1 or src.count(new_pfx):
            die(f'{v.top}.{name}: {rel} 的前缀 / 守卫形状不认识（前缀 {n_pfx} 处，守卫 {src.count(old_g)} 处）')
        out = src.replace(old_pfx, new_pfx).replace(old_g, new_g)
        if out.count(new_pfx) != n_pfx or old_pfx in out or out.count(new_g) != 1:
            die(f'{v.top}.{name}: {rel} 改前缀后核对不过')
        parts.append((name, typ, rel, n_pfx, out))
    if not parts:
        return None
    L = [f'# {v.top} FM「匹配后」钉点 —— 自动生成：scripts/gen_exublock.py gen_dyn_pins（勿手改）',
         '#',
         '# child 签核用的动态钉点文件（匹配后按 report_unmatched_points 现场配对、fail-closed）整份照搬，',
         '# 只做两处机械替换：点名前缀 /WORK/<child 类型>/ -> /WORK/<本变体>/<实例名>/，守卫 $top eq "<child 类型>" -> 本变体。']
    for name, typ, rel, n_pfx, _ in parts:
        L.append(f'#   {name}（{typ}）<- verif/ut/{rel}：前缀替换 {n_pfx} 处，守卫 1 处')
    L.append('')
    body = '\n'.join(L) + '\n'
    for name, typ, rel, n_pfx, out in parts:
        body += f'# ==== {name}（{typ}）：verif/ut/{rel} 改前缀 ====\n' + out
    return body


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
        dyn = gen_dyn_pins(v)
        if dyn is not None:            # 只有含动态钉点 child 的变体才管这个文件
            outs[REPO / 'verif' / 'ut' / top / 'fm_pins.tcl'] = dyn
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
