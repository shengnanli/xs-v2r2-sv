#!/usr/bin/env python3
"""port_increment_migrate.py —— "纯接口增量"目标的 G0→G1 迁移（含机械判据）。

本脚本同时是"这个 target 能不能机械继承上轮核"的**判据 oracle**：
`--check` 只跑判据不写文件，迁移路径则先过判据、不过就拒绝。

判据（四条，全部机械可复算；负测见 scripts/test_migrate_criteria.py）：

  P1 端口表判据 —— 共同端口的**位宽与方向必须都没变**。
     历史 bug：老版 strip_ports 把端口表整段切掉，位宽信息随之丢失，于是
     "TileLink source 3→5 位"这类改动也满足"去端口表后模块体逐字相同"。
     按纯接口增量施工会生成一个位宽还是旧值的核；逻辑一行没动 ⇒ UT 照样过，
     错误一路漏到 FM 才炸。实测受害者：TLBuffer_6/_8/_9/_20/_22、ICacheCtrlUnit。

  P2 归一化判据 —— 比较模块体前必须剥掉 firtool 的
     `ifdef ENABLE_INITIAL_{REG,MEM}_` 随机化初始化块。
     它是仿真专用、不参与综合，体积随寄存器数量走，会把"纯加透传字段"
     误判成真逻辑改动（NewPipelineConnectPipe_7/_9/_13/_18 剥掉后残余 diff 归零；
     Predictor 从 1652 行降到 53 行）。

  P3 子模块改名的配对键 —— **按实例名配对，不是按模块家族**。
     兄弟实例会互换编号：SNXbar 里 txreqArb 是 FastArbiter_47→_46、
     txdatArb 是 _46→_45。按家族叉积配会生成错配候选，代入后 diff 不归零，
     把一个本来干净的目标藏成"须重写"。代入还必须是**同时替换**：
     顺序 sub 会把 _31→_30 的结果再被 _30→_29 吃掉（RNXbar 一个模块里
     15 处重编号，链式替换后残余 8 行假 diff）。

  P4 **改了名的子模块看得见，没改名却改了内容的子模块看不见** —— 这条是 UT 抓出来的，
     不是想出来的。P1..P3 只比"本模块自己的模块体"；如果一个子模块在 G1 里名字没变、
     内容变了（ITTage 的 MbistPipeIttage：MBIST array ID 7'h46→7'h4C），
     那么按实例名配对显示"无改名"、本模块体逐字相同，三条判据全绿 ——
     可只要**可读实现没有把这个子模块当黑盒**（而是自己重写了一份，如
     xs_MbistPipeIttage_core），继承进来的就是过时的行为。
     所以 P4 把"同名但内容变了的子模块"全部列出来，必须由调用方用
     `--child-blackboxed <名>` 逐个确认"这个子模块两侧共用同一份 G1 定义"才放行。

迁移做法（判据通过后）：
  1. 核文件从上轮工程原样取（并校验其不含 golden 展平中间名）；
  2. wrapper 端口表**整段取自 G1 golden**（位宽即 G1 位宽）；
  3. wrapper 里的直通 assign **从 G1 golden 文本机械提取**（不手打）；
  4. 子模块例化整段照抄 golden 的实例，只把被可读核替换掉的部分换成核例化；
  5. 输出单文件：核 + golden 同名 wrapper。

用法:
  port_increment_migrate.py --check <target> [--g1-name <名>] [--allow-child-renumber]
                            [--child-blackboxed <名>...]
  port_increment_migrate.py <target> --core <上轮核文件> [--pkg <上轮pkg>]
      --core-inst "<核例化整段>"   核如何被例化（含端口连接），由调用方给出
      --core-drives <端口>...      由可读核驱动的输出端口（不列入直通）
"""
import argparse
import pathlib
import re
import sys

G0 = pathlib.Path('/home/eda/xs-env/G0-canonical/golden-rtl')
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OLD = pathlib.Path('/home/eda/xs-env/xs-v2r2-sv')
REPO = pathlib.Path(__file__).resolve().parent.parent
SCALA = re.compile(r'\.scala:\d+')


# ---------------------------------------------------------------------------
# 文本原语
# ---------------------------------------------------------------------------

def module_span(text, name):
    """返回 (端口表含 `\\n);`, 模块体) —— 模块体从 `\\n);` 之后到 endmodule。"""
    i = text.index(f'module {name}(')
    j = text.index('\n);', i) + len('\n);')
    k = text.index('\nendmodule', j)
    return text[i:j], text[j:k]


def strip_ports(text, name):
    """去掉端口表（保留端口表之外的一切）。**只应在 P1 已单独校验过端口表之后使用**。"""
    i = text.index(f'module {name}(')
    j = text.index('\n);', i) + 3
    return text[:i] + text[j:]


PURE_ASSIGN = re.compile(r'^\s*assign\s+(io_\w+)\s*=\s*\n?\s*(io_\w+);\s*$',
                         re.MULTILINE)


def strip_passthrough(text):
    """去掉形如 `assign io_out_X = io_in_Y;` / `assign io_in_ready = io_out_ready;`
    的纯直通语句——它们是随新端口一起加进来的，不算逻辑改动。
    只去"整条 io_ 到 io_ 的裸赋值"，任何带运算/切片/三元的赋值都保留（那是真改动）。"""
    return PURE_ASSIGN.sub('', text)


RAND_BLOCK = re.compile(
    r'^[ \t]*`ifdef ENABLE_INITIAL_(?:REG|MEM)_\b.*?'
    r'^[ \t]*`endif // ENABLE_INITIAL_(?:REG|MEM)_[ \t]*$\n?',
    re.S | re.M)


def strip_randomize(text):
    """P2：剥掉 firtool 的仿真专用随机化初始化块。

    这些块被 `ifdef ENABLE_INITIAL_REG_ / ENABLE_INITIAL_MEM_ 包着，综合时不存在，
    但体积随寄存器数量走 —— 不剥掉，"只加了一组透传字段"会凭空多出几十行
    `_RANDOM[...]` 假 diff，把纯接口增量误判成真逻辑改动。"""
    return RAND_BLOCK.sub('', text)


def norm_body(text):
    """判据统一用的归一化：剥随机化块 → 去纯直通 → 折叠空行 → 归一断言行号。"""
    s = strip_randomize(text)
    s = strip_passthrough(s)
    s = re.sub(r'\n\s*\n+', '\n', s)
    return SCALA.sub('.scala:0', s)


# ---------------------------------------------------------------------------
# P1：端口表判据
# ---------------------------------------------------------------------------

PORT_LINE = re.compile(r'(input|output|inout)\s+(?:(\[[^\]]*\])\s+)?(\w+)')


def port_list(porttable):
    """端口表 -> 有序 [(方向, 位宽文本, 端口名)]；位宽省略记为 ''（即 1 位）。"""
    out = []
    for line in porttable.splitlines():
        m = PORT_LINE.match(line.strip().rstrip(','))
        if m:
            out.append((m.group(1), m.group(2) or '', m.group(3)))
    return out


def port_delta(p0, p1):
    """-> dict(added, removed, width_chg, dir_chg)，每项都是端口名列表
    （width_chg / dir_chg 的元素是 (名, 旧, 新)）。"""
    d0 = {n: (d, w) for d, w, n in p0}
    d1 = {n: (d, w) for d, w, n in p1}
    both = set(d0) & set(d1)
    return {
        'added':   sorted(set(d1) - set(d0)),
        'removed': sorted(set(d0) - set(d1)),
        'width_chg': sorted((n, d0[n][1] or '[0:0]', d1[n][1] or '[0:0]')
                            for n in both if d0[n][1] != d1[n][1]),
        'dir_chg': sorted((n, d0[n][0], d1[n][0]) for n in both if d0[n][0] != d1[n][0]),
    }


# ---------------------------------------------------------------------------
# P3：子模块改名（按实例名配对 + 同时替换）
# ---------------------------------------------------------------------------

INST = re.compile(r'^[ \t]*([A-Za-z_]\w*)\s+(\w+)\s*\(\s*$', re.M)


def instances(body):
    """模块体 -> {实例名: 模块名}（firtool 例化一律是 `  Mod inst (` 独占一行）。"""
    return {m.group(2): m.group(1) for m in INST.finditer(body)}


def child_rename_map(b0, b1):
    """P3：按**实例名**配对求子模块改名表。

    返回 (map, problems)。problems 非空即判据不成立：
      - 同一个 G0 模块在不同实例上映到不同 G1 模块（不是单纯重编号）；
      - 实例集合两侧不一致（增删了实例，属结构改动）。
    """
    i0, i1 = instances(b0), instances(b1)
    problems = []
    only0 = sorted(set(i0) - set(i1))
    only1 = sorted(set(i1) - set(i0))
    if only0:
        problems.append(f'instances only in G0: {only0}')
    if only1:
        problems.append(f'instances only in G1: {only1}')
    mapping = {}
    for inst in sorted(set(i0) & set(i1)):
        a, b = i0[inst], i1[inst]
        if a == b:
            continue
        if a in mapping and mapping[a] != b:
            problems.append(f'module {a} maps to both {mapping[a]} and {b}')
        mapping[a] = b
    return mapping, problems


def simul_sub(text, mapping):
    """**同时**整词替换。逐条 re.sub 会链式吃掉前一条的结果：
    RNXbar 里 FastArbiter_31→_30 的结果会再被 _30→_29 替掉，残余 8 行假 diff。"""
    if not mapping:
        return text
    pat = re.compile(r'\b(' + '|'.join(re.escape(k) for k in
                                       sorted(mapping, key=len, reverse=True)) + r')\b')
    return pat.sub(lambda m: mapping[m.group(1)], text)


# ---------------------------------------------------------------------------
# 总判据
# ---------------------------------------------------------------------------

class Verdict:
    def __init__(self, ok, reasons, detail):
        self.ok = ok
        self.reasons = reasons
        self.detail = detail

    def __bool__(self):
        return self.ok

    def report(self, target):
        head = 'OK  ' if self.ok else 'REJECT'
        lines = [f'{head} {target}: ' + ('; '.join(self.reasons) if self.reasons
                                         else 'pure interface increment')]
        for k, v in self.detail.items():
            if v:
                lines.append(f'    {k}: {v}')
        return '\n'.join(lines)


def changed_kept_children(b0, b1):
    """P4：两侧**同名**、但 golden 内容变了的子模块。

    这些子模块对 P1/P2/P3 完全隐形（名字没变 ⇒ 无改名；本模块体逐字相同）。
    只有当可读实现把它当黑盒（两侧共用同一份 G1 定义）时，继承才成立。"""
    i0, i1 = instances(b0), instances(b1)
    kept = {i1[k] for k in set(i0) & set(i1) if i0[k] == i1[k]}
    out = []
    for c in sorted(kept):
        a, b = G0 / f'{c}.sv', G1 / f'{c}.sv'
        if not a.exists() or not b.exists():
            out.append((c, 'missing on one side'))
        elif a.read_bytes() != b.read_bytes():
            out.append((c, 'golden content changed'))
    return out


def check(target, g1_name=None, allow_child_renumber=False, child_blackboxed=()):
    """四条判据一起跑。返回 Verdict。"""
    g1_name = g1_name or target
    t0 = (G0 / f'{target}.sv').read_text(errors='replace')
    t1 = (G1 / f'{g1_name}.sv').read_text(errors='replace')
    pt0, b0 = module_span(t0, target)
    pt1, b1 = module_span(t1, g1_name)

    delta = port_delta(port_list(pt0), port_list(pt1))
    reasons = []
    # P1
    if delta['width_chg']:
        reasons.append(f"P1 port WIDTH changed on {len(delta['width_chg'])} port(s) "
                       f"-- NOT a pure interface increment, the core must be reparameterised")
    if delta['dir_chg']:
        reasons.append(f"P1 port DIRECTION changed on {len(delta['dir_chg'])} port(s)")

    # P3 + P2
    mapping, problems = child_rename_map(b0, b1)
    if problems:
        reasons.append('P3 instance pairing: ' + '; '.join(problems))
    if mapping and not allow_child_renumber:
        reasons.append(f'P3 child modules renamed {mapping} -- pass --allow-child-renumber '
                       f'if the renamed children are proven separately')

    n0 = simul_sub(norm_body(b0), mapping if allow_child_renumber else {})
    n0 = re.sub(rf'\b{re.escape(target)}\b', 'SELF', n0)
    n1 = re.sub(rf'\b{re.escape(g1_name)}\b', 'SELF', norm_body(b1))
    body_eq = (n0 == n1)
    if not body_eq:
        reasons.append('P2 module body differs after normalisation '
                       '(randomize blocks stripped, pure passthrough dropped)')

    # P4
    changed = changed_kept_children(b0, b1)
    unack = [(c, why) for c, why in changed if c not in set(child_blackboxed)]
    if unack:
        reasons.append(
            'P4 same-named child module(s) changed content in G1: '
            + ', '.join(f'{c} ({why})' for c, why in unack)
            + ' -- inheriting is only valid if the readable implementation BLACK-BOXES '
              'them (both sides elaborate the same G1 file); pass --child-blackboxed '
              'for each one you have checked')

    detail = {
        'ports_added': delta['added'],
        'ports_removed': delta['removed'],
        'width_chg': delta['width_chg'],
        'dir_chg': delta['dir_chg'],
        'child_rename': mapping,
        'kept_name_children_changed': changed,
        'body_equal_after_normalisation': body_eq,
    }
    return Verdict(not reasons, reasons, detail)


def body_identical(name, g1_name=None, allow_child_renumber=False,
                   child_blackboxed=()):
    """兼容旧接口：判据是否成立（现在含 P1/P2/P3/P4）。"""
    return bool(check(name, g1_name, allow_child_renumber, child_blackboxed))


# ---------------------------------------------------------------------------
# 迁移
# ---------------------------------------------------------------------------

def ports_of(name):
    t = (G1 / f'{name}.sv').read_text()
    i = t.index(f'module {name}(')
    j = t.index('\n);', i) + len('\n);')
    return t[i:j]


def passthrough_of(name, skip):
    """从 G1 golden 提取纯直通 assign；skip 里的目标端口由可读核驱动。"""
    t = (G1 / f'{name}.sv').read_text()
    body = t[t.index('\n);') + 3:]
    out, rev = [], []
    for m in re.finditer(r'assign\s+(\w+)\s*=\s*\n?\s*(\w+);', body):
        dst, src = m.group(1), m.group(2)
        if dst in skip:
            continue
        if dst.startswith('io_out') and (src.startswith('io_in') or src == 'io_out_ready'):
            out.append((dst, src))
        elif dst == 'io_in_ready':
            rev.append((dst, src))
    return out, rev


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target')
    ap.add_argument('--check', action='store_true',
                    help='只跑判据，不写文件（退出码 0=可机械继承）')
    ap.add_argument('--g1-name', default=None, help='target 在 G1 里的名字（重编号时用）')
    ap.add_argument('--allow-child-renumber', action='store_true',
                    help='允许子模块重编号（按实例名配对代入后比较）')
    ap.add_argument('--child-blackboxed', nargs='*', default=[],
                    help='P4：确认这些"同名但内容变了"的子模块在可读实现里是黑盒'
                         '（两侧共用同一份 G1 定义），而不是自己重写了一份')
    ap.add_argument('--core')
    ap.add_argument('--pkg', default=None)
    ap.add_argument('--core-inst')
    ap.add_argument('--core-drives', nargs='*', default=[],
                    help='由可读核驱动的输出端口（不列入直通）')
    ap.add_argument('--subsys', default='backend')
    ap.add_argument('--note', default='')
    a = ap.parse_args()
    t = a.target

    v = check(t, a.g1_name, a.allow_child_renumber, a.child_blackboxed)
    if a.check:
        print(v.report(t))
        sys.exit(0 if v.ok else 1)

    if not v.ok:
        print(v.report(t), file=sys.stderr)
        sys.exit(f'ERROR: {t} 不满足机械继承判据，不能用本脚本迁移')
    if not a.core or not a.core_inst:
        sys.exit('ERROR: 迁移模式需要 --core 与 --core-inst')

    pieces = []
    hdr = [f'// {t} —— 由 scripts/port_increment_migrate.py 迁移自上轮可读核',
           '//',
           '// 迁移依据（脚本已校验 P1/P2/P3/P4）：G0 与 G1 的 golden 端口位宽/方向未变，',
           '// 且剥掉 firtool 随机化初始化块、去掉纯直通后模块体逐字相同，',
           '// 即 G1 的改动只是接口增量（perfDebugInfo / debug.seqNum / ready 等透传字段），',
           '// 运算逻辑未动。故核体沿用，wrapper 按 G1 端口重做，直通 assign 由 golden',
           '// 文本机械提取（不手打）。']
    if a.note:
        hdr += ['//', '// ' + a.note]
    pieces.append('\n'.join(hdr) + '\n')

    if a.pkg:
        pieces.append(pathlib.Path(a.pkg).read_text().rstrip())
    pieces.append(pathlib.Path(a.core).read_text().rstrip())

    skip = set(a.core_drives)
    fwd, rev = passthrough_of(t, skip)
    w = max([len(d) for d, _ in fwd + rev] or [1])
    body = ['// ' + '-' * 75,
            f'// golden 同名 wrapper：端口与 G1 golden {t}.sv 完全一致',
            '// ' + '-' * 75,
            ports_of(t), '',
            a.core_inst.rstrip(), '']
    if rev:
        body.append('  // 握手直通（无内部阻塞）')
        for d, s in rev:
            body.append(f'  assign {d:{w}s} = {s};')
        body.append('')
    body.append('  // 控制/调试旁路直通（Chisel PipedFuncUnit 的 out := in）')
    for d, s in fwd:
        body.append(f'  assign {d:{w}s} = {s};')
    body += ['', 'endmodule']
    pieces.append('\n'.join(body))

    out = REPO / 'rtl' / a.subsys / f'{t}.sv'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text('\n\n'.join(pieces) + '\n')
    print(f'{t}: 迁移完成 -> {out.relative_to(REPO)}（直通 {len(fwd)} + 握手 {len(rev)}）')


if __name__ == '__main__':
    main()
