#!/usr/bin/env python3
"""gen_rob.py -- generate the mechanically-derived regions of rtl/backend/Rob.sv.

Rob's golden is 266,227 lines / 2200 ports / 8 child instances. Almost none of
that bulk is design intent: it is a port table and eight instance pin lists that
firtool flattened. Those are generated here and marked
`// BEGIN GENERATED(<tag>)` / `// END GENERATED`; everything outside the markers
is hand-written and this script must not touch it (CONVENTIONS 单文件规范).

Generated regions
  ports     the `module Rob` port declarations, name-for-name and width-for-width
            with golden, in golden's order.
  children  the 8 child instantiations. All 8 are SYMMETRIC BLACKBOXES: neither
            the ref nor the impl side is given a body for them (CONVENTIONS
            §子模块处理). That makes Rob a CONDITIONAL green -- it depends on all
            8 children being signed off independently. The receipt must carry
            that dependency; Rob must never be reported as an unconditional pass.

Child pin nets are rewritten as:
  * a top-level `io_*` port            -> used directly (576 of 868 pins)
  * `clock` / `reset`                  -> used directly (28)
  * a literal                          -> kept verbatim (8)
  * anything else                      -> `n_<golden net name>`, a wrapper-local
                                          net (256). Each such net is either
                                          driven by `xs_Rob_core` (child input)
                                          or by another child's output pin.

Usage
  python3 scripts/gen_rob.py --check        # regenerate into memory, diff, rc=1 on drift
  python3 scripts/gen_rob.py --write        # rewrite the GENERATED regions in place
  python3 scripts/gen_rob.py --manifest     # print the core<->wrapper net interface
"""
import argparse, collections, hashlib, os, re, sys

GOLDEN = os.environ.get(
    'ROB_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
TARGET = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'rtl', 'backend', 'Rob.sv')

BEGIN = '// BEGIN GENERATED(%s)'
END = '// END GENERATED'


# --------------------------------------------------------------------------
# golden parsing
# --------------------------------------------------------------------------
def load_golden(path):
    with open(path) as f:
        text = f.read()
    return text, text.split('\n')


def parse_ports(lines):
    """Golden's port header, verbatim order. -> [(dir, hi, lo, name)]"""
    start = next(i for i, l in enumerate(lines) if l.startswith('module Rob('))
    end = next(i for i in range(start, len(lines)) if lines[i].strip() == ');')
    out = []
    for l in lines[start:end + 1]:
        m = re.match(r'\s*(input|output)\s+(?:wire\s+)?'
                     r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)', l)
        if m:
            hi = None if m.group(2) is None else int(m.group(2))
            lo = None if m.group(3) is None else int(m.group(3))
            out.append((m.group(1), hi, lo, m.group(4)))
    return out, end


def parse_children(lines, body_start):
    """The 8 child instances. -> [(type, inst, [(pin, net)])]"""
    out, i = [], body_start
    while i < len(lines):
        m = re.match(r'^\s{0,4}([A-Za-z_]\w*)\s+(\w+)\s*\(\s*$', lines[i])
        if m:
            j, pins = i + 1, []
            while j < len(lines) and not re.match(r'^\s*\);', lines[j]):
                pm = re.match(r'\s*\.(\w+)\s*\((.*?)\)\s*,?\s*$', lines[j])
                if pm:
                    pins.append((pm.group(1), pm.group(2).strip()))
                j += 1
            out.append((m.group(1), m.group(2), pins))
            i = j
        i += 1
    return out


def child_pin_widths(golden_dir, ctype):
    """子模块自己的端口位宽 -> {pin: width}。

    表达式引脚的线宽只能从**被连的那个引脚**上取（golden 里没有这根线的声明）。
    """
    path = os.path.join(golden_dir, ctype + '.sv')
    w = {}
    with open(path) as f:
        for l in f:
            m = re.match(r'\s*(?:input|output)\s+(?:wire\s+)?'
                         r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)', l)
            if m:
                w[m.group(3)] = (1 if m.group(1) is None
                                 else int(m.group(1)) - int(m.group(2)) + 1)
            if re.match(r'\s*\);', l) and w:
                break
    return w


def child_output_pins(golden_dir, ctype):
    """Read the child's own golden file to learn which pins are outputs.

    Needed to tell a net the core must DRIVE (child input) from one the core
    CONSUMES (child output). Guessing from the name would be exactly the
    'name matches so it must be the same thing' mistake the house rules ban.
    """
    path = os.path.join(golden_dir, ctype + '.sv')
    outs = set()
    with open(path) as f:
        for l in f:
            m = re.match(r'\s*output\s+(?:wire\s+)?(?:\[[^\]]*\])?\s*(\w+)', l)
            if m:
                outs.add(m.group(1))
            if re.match(r'\s*\);', l) and outs:
                break
    return outs


LITERAL = re.compile(r"^\d*'[hbdHBD][0-9a-fA-FxzXZ_]+$")
# firtool writes an unconnected child output as `.pin (/* unused */)`.
# ★这不是一个网名★：不识别它，9 个 deqPtrGenModule 的 io_canCommitPriorityCond_*
# 会被折成同一个"网" `n_/*`（既不是合法标识符，又把 9 个悬空口连成一根线）。
UNUSED = re.compile(r'^/\*\s*unused\s*\*/$')


IDENT_ONLY = re.compile(r'^[A-Za-z_][A-Za-z_0-9$]*$')


def classify(net, portnames, inst=None, pin=None):
    if UNUSED.match(net):
        return 'unused', ''
    if net in portnames:
        return 'port', net
    if net in ('clock', 'reset'):
        return 'clk', net
    if LITERAL.match(net):
        return 'const', net
    if not IDENT_ONLY.match(net):
        # ★4 个引脚接的是**表达式**不是网★（实测）：
        #   rab.io_fromRob_walkSize   (walkSizeSum[7:0])     位选
        #   rab/vtypeBuffer.io_fromRob_walkEnd (state & walkFinished)
        #   deqPtrGenModule.io_state  ({1'h0, state})        拼接
        # 不认出来就会 'n_' + 表达式，长出 `n_walkSizeSum[7:0]` /
        # `n_state &` / `n_{1'h0, state}` 这种既非标识符、又把表达式截断的假网。
        # 处置：给它一根以**引脚**命名的线，由核驱动（表达式属于核的逻辑）。
        if inst is None or pin is None:
            raise SystemExit('gen_rob: 表达式引脚 %r 缺少 inst/pin 上下文' % net)
        return 'expr', 'n_%s_%s' % (inst, pin)
    return 'net', 'n_' + net


# --------------------------------------------------------------------------
# emitters
# --------------------------------------------------------------------------
def register_inventory(lines):
    """Golden's register spec, split into entry-indexed arrays and scalars.

    firtool flattens every array into `<prefix>_<idx>_<field>` scalars. Folding
    them back is what turns 11,695 register declarations into 13 array families
    plus 452 loose registers -- and it is also the pin map: each family gives
    `r:.../<prefix>_<i>_<field>_reg[<b>]` <-> `i:.../<prefix>_<field>_reg[<i>][<b>]`
    mechanically, so name-pinning is a nested loop rather than a hand-built
    table. (The previous round needed 16,161 hand-written pins because its
    packed-struct core had no such correspondence to generate.)
    """
    decl = {}
    for l in lines:
        m = re.match(r'\s*reg\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*;', l)
        if m:
            w = 1 if m.group(1) is None else int(m.group(1)) - int(m.group(2)) + 1
            decl[m.group(3)] = w
    fam = collections.defaultdict(dict)
    scalars = {}
    for n, w in decl.items():
        m = re.match(r'^(.*?)_(\d+)_(.+)$', n)
        if m:
            fam[(m.group(1), m.group(3))][int(m.group(2))] = w
        else:
            scalars[n] = w
    byprefix = collections.defaultdict(list)
    for (pre, f), idxs in fam.items():
        widths = set(idxs.values())
        byprefix[pre].append((f, len(idxs), sorted(widths)))
    return byprefix, scalars


def emit_ports(ports):
    w = max(len(d) for d, _, _, _ in ports)
    rng = []
    for d, hi, lo, n in ports:
        rng.append('' if hi is None else '[%d:%d]' % (hi, lo))
    rw = max(len(r) for r in rng)
    lines = []
    for (d, hi, lo, n), r in zip(ports, rng):
        comma = ',' if (d, hi, lo, n) != ports[-1] else ''
        lines.append('  %-*s logic %-*s %s%s' % (w, d, rw, r, n, comma))
    return lines


def emit_children(children, portnames, golden_dir):
    lines = []
    for ctype, inst, pins in children:
        outs = child_output_pins(golden_dir, ctype)
        lines.append('  // %s -- symmetric blackbox (neither side gets a body);'
                     ' Rob is conditional on its own signoff.' % ctype)
        lines.append('  %s %s (' % (ctype, inst))
        pw = max(len(p) for p, _ in pins)
        for k, (pin, net) in enumerate(pins):
            kind, name = classify(net, portnames, inst, pin)
            tail = ',' if k != len(pins) - 1 else ''
            tag = '' if kind != 'net' else ('   // <- core' if pin not in outs
                                            else '   // -> core')
            lines.append('    .%-*s (%s)%s%s' % (pw, pin, name, tail, tag))
        lines.append('  );')
        lines.append('')
    return lines


def wrapper_nets(children, portnames, golden_dir):
    """Split the wrapper-local nets three ways.

    A net that a child OUTPUT pin drives is not the core's to produce, even
    when another child consumes it -- `n__exceptionGen_io_state_*` is driven by
    exceptionGen and read by deqPtrGenModule, so it is pure wrapper routing.
    Classifying by 'is some consumer an input pin' would have put those 7 nets
    in the core's obligation list. Drivers decide, consumers do not.
    """
    driven_by_child = {}
    consumed = collections.defaultdict(list)
    for ctype, inst, pins in children:
        outs = child_output_pins(golden_dir, ctype)
        for pin, net in pins:
            kind, name = classify(net, portnames, inst, pin)
            if kind == 'expr':
                # 表达式引脚永远是"核驱动"：它就是核里那段逻辑的出口。
                consumed[name].append((ctype, inst, pin))
                continue
            if kind != 'net':
                continue
            if pin in outs:
                driven_by_child[name] = (ctype, inst, pin)
            else:
                consumed[name].append((ctype, inst, pin))
    core_drives = {n: v[0] for n, v in consumed.items()
                   if n not in driven_by_child}
    core_reads = {n: v for n, v in driven_by_child.items()
                  if n not in consumed}
    routed = {n: (driven_by_child[n], consumed[n]) for n in driven_by_child
              if n in consumed}
    return core_drives, core_reads, routed


# --------------------------------------------------------------------------
# core <-> wrapper interface
# --------------------------------------------------------------------------
def net_widths(lines):
    """golden 里每个网/寄存器的位宽 -> {name: width}。

    wrapper 局部网 `n_<golden net>` 的位宽只能从 golden 的声明拿。猜不得：
    错一位，子模块引脚宽度对不上，VCS 只给 warning 而不是 error。
    """
    w = {}
    pat = re.compile(r'^\s*(?:wire|reg)\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)\s*[;=]')
    for l in lines:
        m = pat.match(l)
        if m:
            w[m.group(3)] = (1 if m.group(1) is None
                             else int(m.group(1)) - int(m.group(2)) + 1)
    return w


def core_port_name(net):
    """wrapper 网名 -> 核上的端口名。只去掉 firtool 留下的前导下划线。"""
    return net.lstrip('_')


def core_iface(children, ports, golden_dir):
    """核必须驱动 / 必须读的那两组网，键是**核端口名**。"""
    portnames = {p[3] for p in ports}
    drives, reads, routed = wrapper_nets(children, portnames, golden_dir)
    d = {core_port_name(n[2:]): n[2:] for n in drives}      # 去掉 'n_'
    r = {core_port_name(n[2:]): n[2:] for n in list(reads) + list(routed)}
    if len(d) != len(drives) or len(r) != len(reads) + len(routed):
        raise SystemExit('gen_rob: 去前导下划线后核端口名撞车，需要改名表')
    return d, r


def child_driven_outputs(children, ports, golden_dir):
    """直接由某个子模块输出脚驱动的顶层 output —— 这些**不是**核的义务。"""
    portnames = {p[3] for p in ports}
    out = set()
    for ctype, inst, pins in children:
        co = child_output_pins(golden_dir, ctype)
        for pin, net in pins:
            if net in portnames and pin in co:
                out.add(net)
    return out


_IDENT = re.compile(r'[A-Za-z_][A-Za-z_0-9$]*')


def strip_sv_comments(text):
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.S)
    return re.sub(r'//[^\n]*', ' ', text)


def core_body(target_lines):
    """核的手写体：core_ports 区结束标记之后，到核的 endmodule 为止。"""
    b = BEGIN % 'core_ports'
    i = next(k for k, l in enumerate(target_lines) if l.strip() == b)
    j = next(k for k in range(i + 1, len(target_lines))
             if target_lines[k].strip() == END)
    k = next(k for k in range(j + 1, len(target_lines))
             if target_lines[k].strip() == 'endmodule')
    return '\n'.join(target_lines[j + 1:k])


def analyse_core(target_lines, ports, children, golden_dir, netw):
    """从**核体实际引用的名字**推出核的端口表，并做双向断言。

    正向：核体里提到的每个 golden 端口名，按 golden 的方向/位宽出现在核端口上。
    ★反向★（CONVENTIONS 第五条）：核体里任何形如 io_* / gatewayIn_* 的标识符
    如果不是 golden 的端口，就是打错了名字 —— 这种错的失败模式不是报错，
    是这个名字在 golden 里一次都不出现、于是安静地变成一个悬空网。
    另外两条硬断言：核必须驱动的顶层 output 一个都不许漏；
    必须驱动的 wrapper 网一个都不许漏。
    """
    body = strip_sv_comments(core_body(target_lines))
    idents = set(_IDENT.findall(body))
    pmap = {p[3]: p for p in ports}
    drives, reads = core_iface(children, ports, golden_dir)
    childout = child_driven_outputs(children, ports, golden_dir)

    bogus = sorted(i for i in idents
                   if (i.startswith('io_') or i.startswith('gatewayIn_'))
                   and i not in pmap)
    if bogus:
        raise SystemExit(
            'gen_rob: 核体里这些名字长得像顶层端口，但 golden 里没有（打错名字）：\n  '
            + '\n  '.join(bogus[:40]))

    must_drive = sorted(p[3] for p in ports
                        if p[0] == 'output' and p[3] not in childout)
    missing_out = [n for n in must_drive if n not in idents]
    missing_net = sorted(n for n in drives if n not in idents)
    if missing_out or missing_net:
        raise SystemExit(
            'gen_rob: 核体没有提到这些它必须驱动的东西 —— 这正是 SCAFFOLD 的形状：\n'
            '  顶层 output 缺 %d 个，前 20：%s\n'
            '  子模块输入网缺 %d 个，前 20：%s'
            % (len(missing_out), missing_out[:20],
               len(missing_net), missing_net[:20]))

    rows = [('input', None, None, 'clock'), ('input', None, None, 'reset')]
    for p in ports:
        if p[3] in ('clock', 'reset') or p[3] not in idents:
            continue
        if p[0] == 'output' and p[3] in childout:
            raise SystemExit('gen_rob: 核体提到了由子模块驱动的顶层 output %r' % p[3])
        rows.append(p)
    for nm in sorted(drives):
        w = netw.get(drives[nm])
        if w is None:
            raise SystemExit('gen_rob: golden 里找不到网 %r 的声明，位宽无处可取'
                             % drives[nm])
        rows.append(('output', w - 1, 0, nm) if w > 1 else ('output', None, None, nm))
    for nm in sorted(reads):
        if nm not in idents:
            continue
        w = netw.get(reads[nm])
        if w is None:
            raise SystemExit('gen_rob: golden 里找不到网 %r 的声明，位宽无处可取'
                             % reads[nm])
        rows.append(('input', w - 1, 0, nm) if w > 1 else ('input', None, None, nm))
    return rows, drives, reads


def emit_core_ports(rows):
    rng = ['' if hi is None else '[%d:%d]' % (hi, lo) for _, hi, lo, _ in rows]
    dw = max(len(d) for d, _, _, _ in rows)
    rw = max(len(r) for r in rng)
    out = []
    for k, ((d, hi, lo, n), r) in enumerate(zip(rows, rng)):
        out.append('  %-*s logic %-*s %s%s'
                   % (dw, d, rw, r, n, ',' if k != len(rows) - 1 else ''))
    return out


def emit_core_inst(rows, drives, reads):
    pw = max(len(n) for _, _, _, n in rows)
    out = ['  xs_Rob_core u_core (']
    for k, (d, hi, lo, n) in enumerate(rows):
        if n in drives:
            net = 'n_' + drives[n]
        elif n in reads:
            net = 'n_' + reads[n]
        else:
            net = n
        out.append('    .%-*s (%s)%s' % (pw, n, net, ',' if k != len(rows) - 1 else ''))
    out.append('  );')
    return out


def emit_wrapper_nets(children, ports, golden_dir, netw):
    """wrapper 局部网的声明 —— 核的端口和子模块引脚在这里接头。

    位宽来源分两种，都不是猜的：
      · 普通网  -> golden 里那条 wire/reg 声明；
      · 表达式引脚 -> **被连的那个子模块引脚**自己的位宽（golden 里没有这根线）。
    """
    portnames = {p[3] for p in ports}
    plain, expr = {}, {}
    for ctype, inst, pins in children:
        cw = None
        for pin, net in pins:
            kind, nm = classify(net, portnames, inst, pin)
            if kind == 'net':
                plain[nm] = nm[2:]
            elif kind == 'expr':
                if cw is None:
                    cw = child_pin_widths(golden_dir, ctype)
                if pin not in cw:
                    raise SystemExit('gen_rob: %s 的引脚 %r 在它自己的 golden 里找不到'
                                     % (ctype, pin))
                expr[nm] = (cw[pin], ctype, inst, pin, net)
    out = []
    for nm in sorted(plain):
        w = netw.get(plain[nm])
        if w is None:
            raise SystemExit('gen_rob: golden 里找不到网 %r 的声明' % plain[nm])
        out.append('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', nm))
    for nm in sorted(expr):
        w, ctype, inst, pin, net = expr[nm]
        out.append('  logic %s%s;   // golden: %s.%s (%s)'
                   % ('[%d:0] ' % (w - 1) if w > 1 else '', nm, inst, pin, net))
    return out


# --------------------------------------------------------------------------
# region splice
# --------------------------------------------------------------------------
def splice(target_lines, tag, new_body):
    b, e = BEGIN % tag, END
    try:
        i = next(k for k, l in enumerate(target_lines) if l.strip() == b)
    except StopIteration:
        raise SystemExit('gen_rob: marker %r not found in %s' % (b, TARGET))
    j = next(k for k in range(i + 1, len(target_lines))
             if target_lines[k].strip() == e)
    return target_lines[:i + 1] + new_body + target_lines[j:]


SKELETON = """// scratch skeleton for gen_rob.py --selftest. Not the core.
module Rob (
  // BEGIN GENERATED(ports)
  // END GENERATED
);
  // BEGIN GENERATED(children)
  // END GENERATED
endmodule
"""


CORE_SKELETON = """module xs_Rob_core (
  // BEGIN GENERATED(core_ports)
  // END GENERATED
);
%s
endmodule
module Rob(
  // BEGIN GENERATED(ports)
  // END GENERATED
);
  // BEGIN GENERATED(wrapper_nets)
  // END GENERATED
  // BEGIN GENERATED(core_inst)
  // END GENERATED
  // BEGIN GENERATED(children)
  // END GENERATED
endmodule
"""


def _core_assert_rows(d, ports, children, gdir, netw):
    """★证明那两条硬断言看得见改变★（CONVENTIONS：判据也要自证）。

    只声明端口、不驱动输出的文件正是上一轮那个 SCAFFOLD 的形状。
    这里用两个最小样本证明 analyse_core 会对它判红：
      · 核体里出现一个 golden 里没有的 io_* 名字 -> 报"打错名字"
      · 核体只驱动 1 个输出          -> 报"这正是 SCAFFOLD 的形状"，
                                        且缺口计数必须是 647-1 与 61
    """
    def probe(body):
        tgt = os.path.join(d, 'core_probe.sv')
        with open(tgt, 'w') as f:
            f.write(CORE_SKELETON % body)
        with open(tgt) as f:
            lines = f.read().split('\n')
        try:
            analyse_core(lines, ports, children, gdir, netw)
            return None
        except SystemExit as e:
            return str(e)

    typo = probe('  assign io_commits_isCommit = 1\'b0;\n'
                 '  assign io_typo_that_is_not_a_golden_port = 1\'b0;')
    scaffold = probe('  assign io_commits_isCommit = 1\'b0;')
    return [
        ('core_typo_caught', typo is not None and '打错名字' in typo,
         '核体里假的 io_* 名字被抓（%s）' % (typo or '★没抓到★').splitlines()[0][:44]),
        ('core_scaffold_caught',
         scaffold is not None and 'SCAFFOLD' in scaffold
         and '缺 646 个' in scaffold and '缺 61 个' in scaffold,
         '只驱动 1 个输出的核被判红，缺口计数 646/61'
         if scaffold else '★没抓到：SCAFFOLD 能过★'),
    ]


def selftest(golden):
    """Prove the splice is (a) idempotent and (b) actually scoped to the markers.

    (b) is the half that is easy to skip. A generator that rewrote the WHOLE
    file would pass an idempotency check just as happily -- run it twice, same
    bytes -- while quietly eating the hand-written core. So the skeleton carries
    a sentinel line outside the markers and the test requires it to survive.
    """
    import shutil, tempfile
    d = tempfile.mkdtemp(prefix='gen-rob-selftest-')
    tgt = os.path.join(d, 'Rob.sv')
    sentinel = '// HANDWRITTEN-SENTINEL do not touch\n'
    with open(tgt, 'w') as f:
        f.write(sentinel + SKELETON + sentinel)
    gtext, glines = load_golden(golden)
    ports, hdr_end = parse_ports(glines)
    children = parse_children(glines, hdr_end)
    portnames = {p[3] for p in ports}
    gdir = os.path.dirname(os.path.abspath(golden))

    def run():
        with open(tgt) as f:
            cur = f.read().split('\n')
        new = splice(cur, 'ports', emit_ports(ports))
        new = splice(new, 'children', emit_children(children, portnames, gdir))
        with open(tgt, 'w') as f:
            f.write('\n'.join(new))
        with open(tgt, 'rb') as f:
            return hashlib.sha256(f.read()).hexdigest()

    h1 = run()
    h2 = run()
    body = open(tgt).read()
    rows = [
        ('idempotent', h1 == h2,
         'two regens byte-identical (%s)' % h1[:16]),
        ('scoped', body.count(sentinel) == 2,
         'both hand-written sentinels outside the markers survived'),
        ('ports_present', body.count('io_redirect_bits_robIdx_value') >= 1,
         'ports region actually populated'),
        ('children_present', 'CommitStuckCounter commitStuckCounter (' in body,
         'children region actually populated'),
        # ★2026-09-20 抓到的真缺陷★：firtool 把悬空的子模块输出写成
        # `.pin (/* unused */)`。不识别它，9 个 io_canCommitPriorityCond_* 会折成
        # 同一个"网" `n_/*` —— 既不是合法标识符，又把 9 个悬空口短接成一根线。
        ('unused_pins_open',
         'n_/*' not in body
         and re.search(r'\.io_canCommitPriorityCond_0\s*\(\)', body) is not None,
         '悬空子模块输出写成 `()`，没有变成名为 `n_/*` 的假网'),
    ] + _core_assert_rows(d, ports, children, gdir, net_widths(glines))
    # Negative: a splice that ignored the END marker would swallow the trailing
    # sentinel. Simulate by checking the marker pair is still intact and empty
    # regions can be re-emptied.
    ok = all(r[1] for r in rows)
    for name, good, why in rows:
        print('%-16s %-5s %s' % (name, 'OK' if good else 'FAIL', why))
    shutil.rmtree(d, ignore_errors=True)
    return 0 if ok else 1



def _target_absent_is_expected(target, module):
    """目标文件不存在时，判断这是不是**预期内**的（核还没建），并给出退出码。

    ★不许 fail-open★：目标不在就无脑返回 0，等于"删掉产物即可让闸变绿"。
    所以要和台账交叉核对：docs/coverage_three_axis.tsv 里该模块若是 MISSING，
    说明核确实还没写（本仓刻意不建空壳 —— 上一轮那个驱动 0 个输出的 SCAFFOLD
    就是这么骗过台账一整轮的），此时"无可比对"是事实；
    若台账说已 REWRITTEN 而文件却不见了，那就是真出事了，必须红。
    """
    import io, os
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    led = os.path.join(repo, 'docs', 'coverage_three_axis.tsv')
    status = None
    try:
        with io.open(led, encoding='utf-8') as f:
            for line in f:
                if line.startswith('#'):
                    continue
                p = line.rstrip('\n').split('\t')
                if len(p) >= 2 and p[0] == module:
                    status = p[1].strip()
                    break
    except IOError:
        pass
    if status == 'MISSING':
        sys.stderr.write(
            '%s --check: 目标 %s 尚未建立，台账也记着 MISSING —— 无可比对，视为通过。\n'
            % (module, target))
        sys.stderr.write(
            '  （核落地后本条会自动变成真正的逐字节比对；此处不 fail-open：\n'
            '   台账若已记 REWRITTEN 而文件不见，本闸会红。）\n')
        return 0
    sys.stderr.write(
        '%s --check: 目标 %s 不存在，而台账状态是 %s（不是 MISSING）—— 判失败。\n'
        % (module, target, status))
    return 1

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN)
    ap.add_argument('--target', default=TARGET)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--check', action='store_true')
    g.add_argument('--write', action='store_true')
    g.add_argument('--manifest', action='store_true')
    g.add_argument('--regmap', action='store_true')
    g.add_argument('--selftest', action='store_true')
    a = ap.parse_args()

    if a.selftest:
        return selftest(a.golden)

    gtext, glines = load_golden(a.golden)
    print('# golden %s' % a.golden, file=sys.stderr)
    print('# sha256 %s' % hashlib.sha256(gtext.encode()).hexdigest(),
          file=sys.stderr)
    ports, hdr_end = parse_ports(glines)
    children = parse_children(glines, hdr_end)
    portnames = {p[3] for p in ports}
    golden_dir = os.path.dirname(os.path.abspath(a.golden))

    if a.regmap:
        byprefix, scalars = register_inventory(glines)
        tot = 0
        print('%-32s %7s %6s %10s  %s'
              % ('array prefix', '#fields', 'depth', 'bits', 'width anomalies'))
        for pre in sorted(byprefix,
                          key=lambda x: -sum(c * w[0] for _, c, w in byprefix[x])):
            flds = byprefix[pre]
            depth = max(c for _, c, _ in flds)
            bits = sum(c * w[0] for _, c, w in flds)
            tot += bits
            odd = [f for f, c, w in flds if len(w) > 1 or c != depth]
            print('%-32s %7d %6d %10d  %s'
                  % (pre, len(flds), depth, bits,
                     ('%d ragged: %s' % (len(odd), ','.join(odd[:3]))) if odd else '-'))
        print('# entry-indexed  %d families  %d fields  %d bits'
              % (len(byprefix), sum(len(v) for v in byprefix.values()), tot))
        print('# scalar         %d regs  %d bits' % (len(scalars), sum(scalars.values())))
        print('# grand total    %d bits' % (tot + sum(scalars.values())))
        return 0

    if a.manifest:
        drive, read, routed = wrapper_nets(children, portnames, golden_dir)
        print('# ports %d  children %d  child pins %d'
              % (len(ports), len(children),
                 sum(len(p) for _, _, p in children)))
        kinds = collections.Counter()
        for _, _inst, pins in children:
            for pin, net in pins:
                kinds[classify(net, portnames, _inst, pin)[0]] += 1
        print('# child pin sources: %s' % dict(kinds))
        print('# NOTE: this lists CHILD PIN nets only. The core may also read'
              ' a `route` net; what it may not do is drive one.')
        print('# core MUST DRIVE %d nets, core READS %d nets, '
              'child->child routing %d nets'
              % (len(drive), len(read), len(routed)))
        for n in sorted(drive):
            print('drive\t%s\t%s.%s' % (n, drive[n][1], drive[n][2]))
        for n in sorted(read):
            print('read\t%s\t%s.%s' % (n, read[n][1], read[n][2]))
        for n in sorted(routed):
            src, dsts = routed[n]
            print('route\t%s\t%s.%s -> %s' % (
                n, src[1], src[2],
                ','.join('%s.%s' % (d[1], d[2]) for d in dsts)))
        return 0

    import os as _os
    if not _os.path.exists(a.target):
        return _target_absent_is_expected(a.target, 'Rob')
    with open(a.target) as f:
        tgt = f.read().split('\n')
    netw = net_widths(glines)
    rows, drives, reads = analyse_core(tgt, ports, children, golden_dir, netw)
    new = splice(tgt, 'core_ports', emit_core_ports(rows))
    new = splice(new, 'ports', emit_ports(ports))
    new = splice(new, 'wrapper_nets',
                 emit_wrapper_nets(children, ports, golden_dir, netw))
    new = splice(new, 'core_inst', emit_core_inst(rows, drives, reads))
    new = splice(new, 'children',
                 emit_children(children, portnames, golden_dir))
    out = '\n'.join(new)

    if a.write:
        with open(a.target, 'w') as f:
            f.write(out)
        print('gen_rob: wrote %s' % a.target, file=sys.stderr)
        return 0

    same = out == '\n'.join(tgt)
    print('gen_rob --check: %s' % ('OK (no drift)' if same else 'DRIFT'),
          file=sys.stderr)
    return 0 if same else 1


if __name__ == '__main__':
    sys.exit(main())
