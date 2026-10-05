#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_sms.py —— SMSPrefetcher 的 golden 同名 wrapper 与 FM「匹配前」钉点生成器。

生成两样：
  1. rtl/memblock/SMSPrefetcher.sv 的 GENERATED(sms-wrapper) 区：golden 同名 wrapper。
     端口表逐字照抄 golden；核 xs_SMSPrefetcher_core 的连线写在本脚本 CORE_CONN（手定）；
     5 个 child 的例化照 golden 的实例名 / 端口顺序，每条连线表达式必须是下面三种之一：
       顶层端口（原样）/ 另一 child 的输出线（golden `_inst_port` 去掉前导下划线）/ GLUE 表里的胶合信号
     （换成核输出）。认不出的表达式一律报错退出，不猜。
  2. verif/ut/SMSPrefetcher/fm_pins_pre.tcl：
     (a) 本层寄存器：golden 扁平名 <-> 核 u_core 里的同义寄存器，逐位（SHELL_REGS 表，字面位数 fail-closed）；
     (b) child 自己签核时用过的钉点：tclsh 桩真跑那份钉点文件取 set_user_match 调用序列，加实例前缀照搬；
         条数必须等于 docs/pin_call_seq.tsv 登记的调用数（只读），否则拒绝生成；
     (c) train_filter 进了本层才变成无读者的对称死位：按语义整组钉（TF_DEAD / TF_STAGES，字面位数 fail-closed）。

用法：python3 scripts/gen_sms.py [--check]   （--check 只比对不写，有漂移 rc=1）
"""
import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
G = pathlib.Path(os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl'))
TOP = 'SMSPrefetcher'
TAG = 'sms-wrapper'
OUT = REPO / 'rtl' / 'memblock' / 'SMSPrefetcher.sv'
PINS = REPO / 'verif' / 'ut' / TOP / 'fm_pins_pre.tcl'

# child 实例名 -> (类型, 该类型签核时的钉点文件，相对 verif/ut/)
CHILDREN = {
    'train_filter':     ('SMSTrainFilter',        'SMSTrainFilter/fm_pins_pre.tcl'),
    'active_gen_table': ('ActiveGenerationTable', 'ActiveGenerationTable/fm_pins_pre.tcl'),
    'stride':           ('StridePF',              'StridePF/fm_pins_pre.tcl'),
    'pht':              ('PatternHistoryTable',   'PatternHistoryTable/fm_pins_pre.tcl'),
    'pf_filter':        ('PrefetchFilter',        'PrefetchFilter/fm_pins_pre.tcl'),
}

# golden 本层胶合表达式 -> wrapper 里的核输出
GLUE = {
    'train_vld_s0_last_REG': 's0_valid',
    'train_region_tag_s0': 's0_region_tag',
    'train_region_p1_tag_s0': 's0_region_p1_tag',
    'train_region_m1_tag_s0': 's0_region_m1_tag',
    'train_region_offset_s0': 's0_region_offset',
    'train_pht_index_s0': 's0_pht_index',
    'train_pht_tag_s0': 's0_pht_tag',
    'train_allow_cross_region_p1_s0': 's0_allow_cross_p1',
    'train_allow_cross_region_m1_s0': 's0_allow_cross_m1',
    "{2'h0, train_region_paddr_s0}": 's0_region_paddr',
    'train_region_vaddr_s0': 's0_region_vaddr',
    'train_s0_pc[9:0]': 's0_pc[9:0]',
    '_probe_0': 'filter_gen_valid',
}

# 核的端口连线（核端口 -> wrapper 表达式）；核输出线在 wrapper 里同名声明
CORE_OUT_W = [
    ('s0_valid', 1), ('s0_pc', 50), ('s0_region_tag', 11), ('s0_region_p1_tag', 11),
    ('s0_region_m1_tag', 11), ('s0_allow_cross_p1', 1), ('s0_allow_cross_m1', 1),
    ('s0_pht_tag', 13), ('s0_pht_index', 5), ('s0_region_offset', 4),
    ('s0_region_paddr', 40), ('s0_region_vaddr', 40), ('filter_gen_valid', 1),
]
CORE_CONN = [
    ('clock', 'clock'), ('reset', 'reset'),
    ('train_valid', 'train_filter_io_train_req_valid'),
    ('train_vaddr', 'train_filter_io_train_req_bits_vaddr'),
    ('train_paddr', 'train_filter_io_train_req_bits_paddr'),
    ('train_pc', 'train_filter_io_train_req_bits_pc'),
] + [(n, n) for n, _ in CORE_OUT_W if n != 'filter_gen_valid'] + [
    ('pht_en', 'io_pht_en'),
    ('pht_gen_valid', 'pht_io_pf_gen_req_valid'),
    ('filter_gen_valid', 'filter_gen_valid'),
    ('enable', 'io_enable'),
    ('l2_pf_valid', 'pf_filter_io_l2_pf_addr_valid'),
    ('l2_pf_addr', 'pf_filter_io_l2_pf_addr_bits'),
    ('l2_req_valid', 'io_l2_req_valid'),
]

# golden 本层寄存器 -> 核寄存器（宽度须相同，逐位钉）
SHELL_REGS = {
    'train_vld_s0_last_REG': 's0_valid',
    'train_s0_pc': 's0_pc',
    'train_region_tag_s0': 's0_region_tag',
    'train_region_p1_tag_s0': 's0_region_p1_tag',
    'train_region_m1_tag_s0': 's0_region_m1_tag',
    'train_allow_cross_region_p1_s0': 's0_allow_cross_p1',
    'train_allow_cross_region_m1_s0': 's0_allow_cross_m1',
    'train_pht_tag_s0': 's0_pht_tag',
    'train_pht_index_s0': 's0_pht_index',
    'train_region_offset_s0': 's0_region_offset',
    'train_region_paddr_s0': 'region_paddr_q',
    'train_region_vaddr_s0': 's0_region_vaddr',
}
SHELL_BITS = 186   # 字面：1+50+11×3+1+1+13+5+4+38+40

# ---- train_filter 在本层新出现的对称死位（子模块自己签核时不需要钉）----
# SMSTrainFilter 单独签核时，它的输出口 train_req.{vaddr,paddr,pc} 全部是比较点，3 级重排寄存器与 8 项
# 表项的每一位都有读者，FM 靠扇出签名配得上。装进本层后，下面这些位**只**通向已死的逻辑：
#   pc[0]、pc[49:20]：本层只读 pc[6:1]（PHT index）与 pc[19:7]（PHT tag）；pc[9:0] 另送 StridePF，
#                     而 StridePF 在本配置对外不可见 —— 所以 pc[0] 与 pc[49:20] 无读者；
#   paddr[9:0]：本层只存区域实地址 paddr[47:10]；
#   vaddr[5:0]：本层只用 vaddr[49:6]（块地址），块内偏移无读者。
# 这些位两侧都变成"无读者的寄存器"，没有扇出签名，FM 配不上（diagnostic-full 实测 799/799 unmatched unread）。
# 按语义整组钉：golden 与重写核的级 / 项一一对应（golden 的 3 级 = ld_reorder_res_0_1_k / ld_reorder_res_1_2_k /
# ld_reorder_k，重写核 = a_* / b_* / c_*；表项 entries_e = ent_*[e]），重写核把 {paddr, pc} 打包成一个
# payload：payload[49:0] = pc，payload[97:50] = paddr。
TF_DEAD = {'pc': [0] + list(range(20, 50)), 'paddr': list(range(10)), 'vaddr': list(range(6))}
TF_STAGES = ([('ld_reorder_res_0_1_%d_bits_' % k, 'a', k) for k in range(3)]
             + [('ld_reorder_res_1_2_%d_bits_' % k, 'b', k) for k in range(3)]
             + [('ld_reorder_%d_bits_' % k, 'c', k) for k in range(3)]
             + [('entries_%d_' % e, 'ent', e) for e in range(8)])
TF_EXTRA_BITS = 799   # 字面：17 组 × (31 + 10 + 6)


def train_filter_extra_pins():
    out = []
    for gpre, ipre, k in TF_STAGES:
        stage_pc = 'uop_pc' if gpre.startswith('ld_reorder') else 'pc'
        for f, bits in TF_DEAD.items():
            for b in bits:
                gname = '%s%s_reg[%d]' % (gpre, stage_pc if f == 'pc' else f, b)
                if f == 'vaddr':
                    iname = 'u_core/%s_vaddr_reg[%d][%d]' % (ipre, k, b)
                else:
                    iname = 'u_core/%s_payload_reg[%d][%d]' % (ipre, k, b if f == 'pc' else 50 + b)
                out.append(('train_filter/' + gname, 'train_filter/' + iname))
    if len(out) != TF_EXTRA_BITS:
        die('train_filter 附加钉点 %d，字面期望 %d' % (len(out), TF_EXTRA_BITS))
    return out


def die(msg):
    raise SystemExit('gen_sms: ERROR: ' + msg)


def golden_text():
    return (G / (TOP + '.sv')).read_text()


def golden_body():
    t = golden_text()
    i = t.index('\nmodule %s(' % TOP) + 1
    return t[i:t.index('\nendmodule', i)]


def golden_port_lines():
    b = golden_body()
    head = b[:b.index('\n);')]
    out = []
    for ln in head.splitlines()[1:]:
        m = re.match(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', ln)
        if not m:
            die('端口行解析失败 %r' % ln)
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def golden_wires():
    w = {}
    for m in re.finditer(r'^  wire\s+(?:\[(\d+):0\]\s+)?(_\w+);', golden_body(), re.M):
        w[m.group(2)] = 1 if m.group(1) is None else int(m.group(1)) + 1
    return w


def golden_regs():
    return [(m.group(2), 1 if m.group(1) is None else int(m.group(1)) + 1)
            for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', golden_body(), re.M)]


def golden_instances():
    insts = []
    for m in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)^  \);', golden_body(), re.S | re.M):
        conns = []
        for c in re.finditer(r'\.(\w+)\s*\((.*?)\)\s*(?:,|$)', m.group(3), re.S):
            conns.append((c.group(1), ' '.join(c.group(2).split())))
        insts.append((m.group(1), m.group(2), conns))
    return insts


def rng(w):
    return '[%d:0]' % (w - 1) if w > 1 else ''


def emit_wrapper():
    ports = golden_port_lines()
    pnames = {n for _, _, n in ports}
    gw = golden_wires()
    insts = golden_instances()
    if [n for _, n, _ in insts] != list(CHILDREN):
        die('golden 实例序列 %s 与 CHILDREN 不符' % [n for _, n, _ in insts])
    L = ['module %s (' % TOP]
    for k, (d, w, n) in enumerate(ports):
        L.append('  %-6s %-9s %s%s' % (d, rng(w), n, ',' if k + 1 < len(ports) else ''))
    L.append(');')
    L.append('')
    L.append('  // ---- child 输出线（golden `_<实例>_<端口>` 去掉前导下划线）----')
    used_child_wires = []
    for name, w in gw.items():
        if not any(name.startswith('_%s_' % c) for c in CHILDREN):
            continue
        used_child_wires.append(name)
        L.append('  wire %-8s %s;' % (rng(w), name[1:]))
    L.append('  // ---- 核输出线 ----')
    for n, w in CORE_OUT_W:
        L.append('  wire %-8s %s;' % (rng(w), n))
    L.append('')
    L.append('  xs_SMSPrefetcher_core u_core (')
    for k, (p, e) in enumerate(CORE_CONN):
        L.append('    .%-18s (%s)%s' % (p, e, ',' if k + 1 < len(CORE_CONN) else ''))
    L.append('  );')

    def conv(iname, p, e):
        if e in pnames:
            return e
        if e in GLUE:
            return GLUE[e]
        if re.fullmatch(r'_\w+', e) and e in gw and e[1:].split('_io_')[0] in CHILDREN:
            return e[1:]
        die('%s.%s: 认不出的连线表达式 %r' % (iname, p, e))

    for typ, iname, conns in insts:
        if CHILDREN[iname][0] != typ:
            die('%s 类型 %s 与表不符' % (iname, typ))
        L.append('')
        L.append('  %s %s (' % (typ, iname))
        wmax = max(len(p) for p, _ in conns)
        for k, (p, e) in enumerate(conns):
            L.append('    .%s (%s)%s' % (p.ljust(wmax), conv(iname, p, e), ',' if k + 1 < len(conns) else ''))
        L.append('  );')
    # golden 顶层 assign 中直连 child 输出的那几条（其余由核驱动）
    for m in re.finditer(r'^  assign (io_\w+) =\s*(.*?);', golden_body(), re.S | re.M):
        port, e = m.group(1), ' '.join(m.group(2).split())
        if port == 'io_l2_req_valid':
            continue   # 核 §3 驱动
        if re.fullmatch(r'_\w+', e) and e in gw:
            L.append('  assign %s = %s;' % (port, e[1:]))
        else:
            die('顶层 assign %s = %r 认不出' % (port, e))
    L.append('')
    L.append('endmodule')
    return '\n'.join(L)


def child_pin_pairs(typ, rel):
    f = REPO / 'verif' / 'ut' / rel
    stub = (
        'rename puts ::__orig_puts\n'
        'proc puts {args} {}\n'
        'set ::CALLS {}\n'
        'proc set_user_match {args} { lappend ::CALLS $args; return 1 }\n'
        'set top %s\n'
        'source {%s}\n'
        'foreach c $::CALLS { ::__orig_puts stdout [join $c "\\t"] }\n' % (typ, f)
    )
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as t:
        t.write(stub)
        tn = t.name
    r = subprocess.run(['tclsh', tn], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    pathlib.Path(tn).unlink()
    if r.returncode != 0:
        die('tclsh 跑 %s 失败: %s' % (f, r.stderr[:300]))
    pairs = [tuple(ln.split('\t')) for ln in r.stdout.splitlines() if ln.strip()]
    want = None
    for ln in (REPO / 'docs' / 'pin_call_seq.tsv').read_text().splitlines():
        c = ln.split('\t')
        if len(c) >= 3 and c[0] == 'verif/ut/' + rel and c[1] == typ:
            want = int(c[2])
    if want is None or want != len(pairs):
        die('%s: 钉点调用数 %d 与 pin_call_seq.tsv 登记 %s 不符' % (typ, len(pairs), want))
    for p in pairs:
        if len(p) != 2 or not p[0].startswith('r:/WORK/%s/' % typ) or not p[1].startswith('i:/WORK/%s/' % typ):
            die('%s: 钉点形状不认识 %s' % (typ, p))
    return [(a[len('r:/WORK/%s/' % typ):], b[len('i:/WORK/%s/' % typ):]) for a, b in pairs]


def tcl_esc(s):
    return s.replace('\\[', '[').replace('\\]', ']').replace('[', '\\[').replace(']', '\\]')


def emit_pins():
    rows = []
    regs = golden_regs()
    if sorted(n for n, _ in regs) != sorted(SHELL_REGS):
        die('golden 本层寄存器集合 %s 与 SHELL_REGS 不符' % sorted(n for n, _ in regs))
    for n, w in regs:
        i = 'u_core/%s_reg' % SHELL_REGS[n]
        if w == 1:
            rows.append(('%s_reg' % n, i))
        else:
            rows += [('%s_reg[%d]' % (n, b), '%s[%d]' % (i, b)) for b in range(w)]
    if len(rows) != SHELL_BITS:
        die('本层寄存器 %d 位，字面期望 %d' % (len(rows), SHELL_BITS))
    child = []
    for iname, (typ, rel) in CHILDREN.items():
        for a, b in child_pin_pairs(typ, rel):
            child.append((iname, typ, rel, '%s/%s' % (iname, a), '%s/%s' % (iname, b)))
    extra = train_filter_extra_pins()
    total = len(rows) + len(child) + len(extra)
    ri = set()
    for r, i in rows + [(c[3], c[4]) for c in child] + extra:
        if i in ri:
            die('impl 侧不单射：%s' % i)
        ri.add(i)
    L = []
    L.append('# SMSPrefetcher FM「匹配前」钉点 —— 自动生成：scripts/gen_sms.py（勿手改）')
    L.append('#')
    L.append('# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。')
    L.append('# (a) 本层寄存器 %d 位：golden 扁平名 <-> xs_SMSPrefetcher_core（u_core）的同义寄存器；' % len(rows))
    L.append('# (b) child 签核时用过的钉点 %d 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀；' % len(child))
    L.append('# (c) train_filter 在本层新出现的对称死位 %d 位：按语义整组钉（依据见 scripts/gen_sms.py TF_DEAD 注释）。' % len(extra))
    L.append('# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。')
    L.append('set ::SMS_PIN_OK 0')
    L.append('set ::SMS_PIN_BAD 0')
    L.append('proc sms_pin {r i} {')
    L.append('  set rr "r:/WORK/%s/$r"' % TOP)
    L.append('  set ii "i:/WORK/%s/$i"' % TOP)
    L.append('  if {[set_user_match $rr $ii]} { incr ::SMS_PIN_OK } else {')
    L.append('    incr ::SMS_PIN_BAD')
    L.append('    if {$::SMS_PIN_BAD <= 10} { puts "SMS_PIN_FAIL: $rr <-> $ii" }')
    L.append('  }')
    L.append('}')
    L.append('puts "SMS_PIN_BEGIN %s expect=%d"' % (TOP, total))
    L.append('# ---- (a) 本层寄存器 ----')
    for r, i in rows:
        L.append('sms_pin %s %s' % (tcl_esc(r), tcl_esc(i)))
    cur = None
    for iname, typ, rel, r, i in child:
        if cur != iname:
            L.append('# ---- (b) %s（%s）：verif/ut/%s 的调用序列 ----' % (iname, typ, rel))
            cur = iname
        L.append('sms_pin %s %s' % (tcl_esc(r), tcl_esc(i)))
    L.append('# ---- (c) train_filter 本层新死位：gen_sms.py TRAIN_FILTER 附加钉点（依据见该表注释）----')
    for r, i in extra:
        L.append('sms_pin %s %s' % (tcl_esc(r), tcl_esc(i)))
    L.append('puts "SMS_PIN_END ok=$::SMS_PIN_OK bad=$::SMS_PIN_BAD expect=%d"' % total)
    L.append('if {$::SMS_PIN_BAD != 0} { error "SMS_PIN_REFUSED=$::SMS_PIN_BAD" }')
    L.append('if {$::SMS_PIN_OK != %d} { error "SMS_PIN_COUNT=$::SMS_PIN_OK expected %d" }' % (total, total))
    return '\n'.join(L) + '\n'


def replace_region(text, body):
    begin = '// BEGIN GENERATED(%s)' % TAG
    end = '// END GENERATED'
    i = text.index(begin)
    j = text.index(end, i)
    return text[:i] + begin + '\n' + body + '\n' + end + text[j + len(end):]


def main():
    check = '--check' in sys.argv[1:]
    outs = [(OUT, replace_region(OUT.read_text(), emit_wrapper())), (PINS, emit_pins())]
    rc = 0
    for path, txt in outs:
        cur = path.read_text() if path.exists() else None
        if check:
            ok = cur == txt
            print(('OK: ' if ok else 'DRIFT: ') + str(path.relative_to(REPO)))
            rc |= 0 if ok else 1
        elif cur != txt:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(txt)
            print('wrote ' + str(path.relative_to(REPO)))
        else:
            print('unchanged ' + str(path.relative_to(REPO)))
    return rc


if __name__ == '__main__':
    sys.exit(main())
