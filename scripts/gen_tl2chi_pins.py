#!/usr/bin/env python3
"""gen_tl2chi_pins.py —— TL2CHICoupledL2 / L2Top 的 FM「匹配前」钉点（verif/ut/<T>/fm_pins_pre.tcl）。

为什么要这么多钉点（2026-10-04 诊断跑实测）：两个目标都把 TL2CHICoupledL2 的整个闭包两侧白盒 elaborate。
child 单独签核时，FM 靠三样东西配上 golden 扁平寄存器名 vs 重写数组名：child 自己的钉点、名字、以及
scripts/fm_eq.tcl 的 auto_match_flattened_arrays（它只剥**顶层**的 u_core/）。进了父级，第三样失效
（路径成了 slices_<k>/u_core/...），签名分析在这个规模下一个也没配上——只用 child 钉点文件时 unmatched 25051。
所以本脚本把每个 child 单独签核时 FM **实际配上**的全部寄存器配对（matched.rpt）收割下来，加子实例前缀钉进父级。
不改共享 scripts/fm_eq.tcl。

三部分，全部 fail-closed：
  (1) child 配对表 verif/ut/TL2CHICoupledL2/child_pairs.tsv（`--harvest` 生成、入库）：
      对每个 child 模块（CHILDREN）读 verif/ut/<UT>/fm_work/<child>/matched.rpt（main 当前字节上的 diagnostic-full 跑，
      不产 receipt；fm_work 不入库），取寄存器类配对（DFF* / LAT*），并上同一跑 fm.log 里 child 钉点的生效回显
      （matched.rpt 不列无读者 / 常量点）；两侧相对路径不同的才收（相同的父级 FM 按名自配）。
      连续位 [0..W-1] 两侧一一对应的折叠成一行宽度 W。表头记每个 child 的 matched.rpt sha256 与配对位数。
  (2) 本层自己的寄存器（xs_TL2CHICoupledL2_core 里与 golden 名字不同的：§1 两条 RegNextN 链、§4 perf 两级）：OWN_RULES，
      golden 名从 golden 现读（寄存器存在、位宽相符）。
  (3) 生成：按 golden 实例表（TL2CHICoupledL2 32 个、L2Top 21 个）把 child 配对加实例前缀展开；L2Top 里的
      inner_l2cache 再递归展开 TL2CHICoupledL2 的那一套（含 (2)）。每个 child 模块在表里必须有条目（或显式列入
      NO_PAIRS 并说明：两侧路径全同，无需钉），表里也不许有用不到的 child。
  运行期：逐条数 set_user_match 返回值，拒一条或总数 != 字面期望即 error（期望数写进生成的文件，生成时还与
  EXPECT 字面值比对）。

用法：python3 scripts/gen_tl2chi_pins.py --harvest   # 由各 child 的 matched.rpt 重建 child_pairs.tsv
      python3 scripts/gen_tl2chi_pins.py             # 生成两个目标的 fm_pins_pre.tcl
      python3 scripts/gen_tl2chi_pins.py --check     # 与仓库里的文件逐字节比较，不一致 rc=1（不读 fm_work）
"""
import hashlib
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import parent_wrapper_lib as lib  # noqa: E402

REPO = os.path.dirname(HERE)
G = lib.G
PAIRS_TSV = os.path.join(REPO, 'verif', 'ut', 'TL2CHICoupledL2', 'child_pairs.tsv')

# child 模块 -> 它单独签核的 UT 目录（matched.rpt 在 verif/ut/<UT>/fm_work/<child>/）
CHILDREN = {
    # TL2CHICoupledL2 的直接 child
    'Slice': 'Slice', 'Slice_1': 'Slice', 'Slice_2': 'Slice', 'Slice_3': 'Slice',
    'Prefetcher': 'Prefetcher', 'MMIOBridge': 'MMIOBridge', 'LinkMonitor': 'LinkMonitor',
    'Queue78_PCrdGranted': 'UncoreChiQueues', 'Queue2_PCrdGranted': 'UncoreChiQueues',
    'FastArbiter': 'FastArbiterL2c', 'FastArbiter_1': 'FastArbiterL2c', 'FastArbiter_26': 'FastArbiterL2c',
    'FastArbiter_27': 'Arithmetic200c', 'FastArbiter_28': 'FastArbiter_28',
    'RRArbiterInit_20': 'RRArbiterInitVariants',
    'Pipeline_2': 'L2PipelineLeaves4', 'Pipeline_3': 'L2PipelineLeaves4',
    'Pipeline_10': 'L2PipelineLeaves4', 'Pipeline_11': 'L2PipelineLeaves4',
    'Pipeline_12': 'ChiRxPipelines', 'Pipeline_13': 'ChiRxPipelines',
    'Arbiter4_L2CacheErrorInfo': 'ArbiterLeaves5', 'Arbiter4_L2ToL1Hint': 'Pipeline200c',
    'TopDownMonitor': 'TopDownMonitor', 'L2Cache': 'L2Cache', 'MbistIntfL2': 'MbistIntfL2',
    # L2Top 的直接 child（除 TL2CHICoupledL2）
    'TLBuffer_13': 'TLBuffer_13', 'TLBuffer_15': 'TLBuffer_15', 'TLBuffer_20': 'TLBuffer_20',
    'TLBuffer_22': 'TLBuffer_22', 'TLBuffer_6': 'TLBuffer_6', 'TLBuffer_8': 'TLBuffer_8',
    'TLXbar_5': 'TLXbar_5', 'TLXbar_6': 'TLXbar_6',
    'TLLogger': 'TLLogger', 'TLLogger_1': 'QueueChiSpillLogger200c', 'TLLogger_2': 'QueueChiSpillLogger200c',
    'BusErrorUnit': 'BusHPerfCounter200c', 'BusPerfMonitor': 'BusArbLeaves', 'IntBuffer': 'IntBuffer',
    'DelayN_334': 'DelayN', 'DelayNWithValid_203': 'DelayNWithValid',
}
NESTED = {'TL2CHICoupledL2'}          # 本脚本自己展开的 child（L2Top.inner_l2cache）
TARGETS = ['TL2CHICoupledL2', 'L2Top']

# 本层（xs_TL2CHICoupledL2_core）与 golden 名字不同的寄存器：(golden 寄存器名, impl 元素（相对 TL2CHICoupledL2）, 位宽)
def own_rules():
    r = [('allCanFire_REG', 'u_core/noHint2_d1_reg', 1), ('allCanFire_REG_1', 'u_core/noHint2_d2_reg', 1),
         ('allCanFire_REG_2', 'u_core/noHint3_d1_reg', 1), ('allCanFire_REG_3', 'u_core/noHint3_d2_reg', 1),
         ('allCanFire_REG_4', 'u_core/noHint3_d3_reg', 1)]
    stages = ['pick2_d1', 'pick2_d2', 'pick3_d1', 'pick3_d2', 'pick3_d3']
    for i in range(4):
        for j, st in enumerate(stages):
            n = 5 * i + j
            r.append(('sliceCanFire_REG' + ('' if n == 0 else '_%d' % n), 'u_core/%s_reg[%d]' % (st, i), 1))
    for k in range(1, 69):
        r.append(('io_perf_%d_value_REG' % k, 'u_core/perf_d1_reg[%d]' % (k - 1), 6))
        r.append(('io_perf_%d_value_REG_1' % k, 'u_core/perf_d2_reg[%d]' % (k - 1), 6))
    return r


OWN_EXPECT = 5 + 20 + 68 * 2 * 6       # 841 位


def die(msg):
    raise SystemExit('gen_tl2chi_pins: ' + msg)


# ---------------------------------------------------------------------------
# (1) 收割
# ---------------------------------------------------------------------------
PT = re.compile(r'^\s+(Ref|Impl)\s+(\S+)\s+(?:\S+\s+)?([ri]:/\S+)\s*$')


def harvest_child(child, ut):
    path = os.path.join(REPO, 'verif', 'ut', ut, 'fm_work', child, 'matched.rpt')
    if not os.path.exists(path):
        die('缺 %s：先在 verif/ut/%s 跑 make fm-%s FM_MODE=diagnostic-full' % (path, ut, child))
    raw = open(path, 'rb').read()
    lines = raw.decode().splitlines()
    pairs = []
    pending = None
    for ln in lines:
        m = PT.match(ln)
        if not m:
            continue
        side, typ, p = m.groups()
        if side == 'Ref':
            pending = (typ, p)
        else:
            if pending is None:
                die('%s: Impl 行前没有 Ref 行: %r' % (child, ln))
            rtyp, rp = pending
            pending = None
            if not (rtyp.startswith(('DFF', 'LAT')) and typ.startswith(('DFF', 'LAT'))):
                continue
            rpre, ipre = 'r:/WORK/%s/' % child, 'i:/WORK/%s/' % child
            if not rp.startswith(rpre) or not p.startswith(ipre):
                die('%s: 配对路径不在顶层下: %s / %s' % (child, rp, p))
            r, i = rp[len(rpre):], p[len(ipre):]
            if r != i:
                pairs.append((r, i))
    # 再并上 child 自己钉点生效的配对（fm.log 里 "Set a match between" 的回显）：matched.rpt 默认不列
    # 无读者 / 常量的点，但它们进了父级照样要配（2026-10-04 实测：Slice 的 sourceB probes_*_waitG[6:4]）。
    logp = os.path.join(os.path.dirname(path), 'fm.log')
    lograw = open(logp, 'rb').read()
    seen = set(pairs)
    for m in re.finditer(r'^Set a match between the following objects:\n\t(r:/\S+)\n\s+\(\?\) (i:/\S+)$',
                         lograw.decode(), re.M):
        rp, ip = m.group(1), m.group(2)
        rpre, ipre = 'r:/WORK/%s/' % child, 'i:/WORK/%s/' % child
        if not rp.startswith(rpre) or not ip.startswith(ipre):
            die('%s: 钉点回显路径不在顶层下: %s / %s' % (child, rp, ip))
        pr = (rp[len(rpre):], ip[len(ipre):])
        if pr[0] != pr[1] and pr not in seen:
            seen.add(pr)
            pairs.append(pr)
    if len({r for r, _ in pairs}) != len(pairs) or len({i for _, i in pairs}) != len(pairs):
        die('%s: 收割到的配对不单射' % child)
    return pairs, hashlib.sha256(raw + lograw).hexdigest()


def fold(pairs):
    """连续位 [0..W-1] 两侧一一对应的折叠成 (rbase, ibase, W)；其余 (r, i, 0)"""
    bit = re.compile(r'^(.*)\[(\d+)\]$')
    groups = {}
    single = []
    for r, i in pairs:
        mr, mi = bit.match(r), bit.match(i)
        if mr and mi and mr.group(2) == mi.group(2):
            groups.setdefault((mr.group(1), mi.group(1)), set()).add(int(mr.group(2)))
        else:
            single.append((r, i, 0))
    out = []
    for (rb, ib), bits in groups.items():
        if bits == set(range(len(bits))) and len(bits) > 1:
            out.append((rb, ib, len(bits)))
        else:
            out += [('%s[%d]' % (rb, b), '%s[%d]' % (ib, b), 0) for b in sorted(bits)]
    return sorted(out + single)


def harvest_all():
    L = ['# child_pairs.tsv —— scripts/gen_tl2chi_pins.py --harvest 从各 child 的 diagnostic-full matched.rpt 收割（勿手改）',
         '# 列：child  ref 相对路径  impl 相对路径  宽度（0 = 单点；W = 两侧 [0..W-1] 逐位对应）。只收两侧路径不同的寄存器配对。']
    body = []
    for child, ut in CHILDREN.items():
        pairs, sha = harvest_child(child, ut)
        L.append('# %s\tut=%s\tmatched.rpt+fm.log sha256=%s\tbits=%d' % (child, ut, sha, len(pairs)))
        body += ['%s\t%s\t%s\t%d' % (child, r, i, w) for r, i, w in fold(pairs)]
    return '\n'.join(L + body) + '\n'


def load_pairs():
    if not os.path.exists(PAIRS_TSV):
        die('缺 %s：先跑 --harvest' % PAIRS_TSV)
    tab, declared = {}, {}
    for ln in open(PAIRS_TSV):
        ln = ln.rstrip('\n')
        m = re.match(r'^# (\w+)\tut=\S+\tmatched\.rpt\+fm\.log sha256=[0-9a-f]{64}\tbits=(\d+)$', ln)
        if m:
            declared[m.group(1)] = int(m.group(2))
            continue
        if ln.startswith('#') or not ln:
            continue
        c, r, i, w = ln.split('\t')
        tab.setdefault(c, []).append((r, i, int(w)))
    for c in CHILDREN:
        if c not in declared:
            die('child_pairs.tsv 里没有 %s 的表头' % c)
        n = sum(w or 1 for _, _, w in tab.get(c, []))
        if n != declared[c]:
            die('%s：表内 %d 位 != 表头 %d' % (c, n, declared[c]))
    if set(tab) - set(CHILDREN):
        die('child_pairs.tsv 里有未知 child：%s' % sorted(set(tab) - set(CHILDREN)))
    return tab


# ---------------------------------------------------------------------------
# (2)(3) 展开
# ---------------------------------------------------------------------------
def golden_regs(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('\nmodule %s(' % mod)
    return {m.group(2): 1 if m.group(1) is None else int(m.group(1)) + 1
            for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', t[i:], re.M)}


def expand(top, tab):
    """返回 [(ref 相对 top, impl 相对 top, 宽度)]"""
    out = []
    for mod, inst, _ in lib.golden_instances(top):
        if mod in NESTED:
            out += [(inst + '/' + r, inst + '/' + i, w) for r, i, w in expand(mod, tab)]
            continue
        if mod not in CHILDREN:
            die('%s 的 child %s（%s）不在 CHILDREN 表里' % (top, inst, mod))
        out += [(inst + '/' + r, inst + '/' + i, w) for r, i, w in tab.get(mod, [])]
    if top == 'TL2CHICoupledL2':
        regs = golden_regs(top)
        n = 0
        for g, i, w in own_rules():
            if regs.get(g) != w:
                die('golden %s 的寄存器 %s 宽 %s，规则写 %d' % (top, g, regs.get(g), w))
            out.append((g + '_reg', i, 0 if w == 1 else w))
            n += w
        if n != OWN_EXPECT:
            die('本层钉点 %d 位，字面期望 %d' % (n, OWN_EXPECT))
    return out


def build(top, tab):
    pairs = expand(top, tab)
    if len({p[0] for p in pairs}) != len(pairs) or len({p[1] for p in pairs}) != len(pairs):
        die('%s：映射不单射' % top)
    n = sum(w or 1 for _, _, w in pairs)
    if n != EXPECTED[top]:
        die('%s：钉点 %d 位，字面期望 %d（child_pairs.tsv 变了就要同时改 EXPECTED）' % (top, n, EXPECTED[top]))
    o = ['# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_tl2chi_pins.py（勿手改）' % top,
         '#',
         '# 内容 = 闭包里每个 child 单独签核时 FM 实际配上的寄存器配对（verif/ut/TL2CHICoupledL2/child_pairs.tsv，',
         '# 两侧相对路径不同的才收）加实例前缀，外加 TL2CHICoupledL2 本层与 golden 名字不同的寄存器（%d 位）。' % OWN_EXPECT,
         '# set_user_match 只声明两点对应，比较照比。fail-closed：逐条数返回值；拒一条或总数 != %d 即 error。' % n,
         'set ::TL2_PIN_OK 0',
         'set ::TL2_PIN_BAD 0',
         'proc tl2_pin {r i} {',
         '  if {[set_user_match "r:/WORK/%s/$r" "i:/WORK/%s/$i"]} { incr ::TL2_PIN_OK } else {' % (top, top),
         '    incr ::TL2_PIN_BAD',
         '    if {$::TL2_PIN_BAD <= 10} { puts "TL2_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'proc tl2_pinw {r i w} {',
         '  for {set b 0} {$b < $w} {incr b} { tl2_pin "${r}\\[$b\\]" "${i}\\[$b\\]" }',
         '}',
         'puts "TL2_PIN_BEGIN %s expect=%d"' % (top, n)]
    for r, i, w in pairs:
        o.append(('tl2_pin {%s} {%s}' % (r, i)) if w == 0 else ('tl2_pinw {%s} {%s} %d' % (r, i, w)))
    o += ['puts "TL2_PIN_END %s ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD"' % top,
          'if {$::TL2_PIN_BAD != 0 || $::TL2_PIN_OK != %d} {' % n,
          '  error "TL2_PIN_MISMATCH ok=$::TL2_PIN_OK bad=$::TL2_PIN_BAD expect=%d"' % n,
          '}']
    return '\n'.join(o) + '\n'


# 字面期望（位数）。child_pairs.tsv 重新收割后若变化，必须同时改这里——防止静默漂移。
EXPECTED = {
    'TL2CHICoupledL2': 283021,
    'L2Top': 292228,
}


def main():
    argv = sys.argv[1:]
    if '--harvest' in argv:
        txt = harvest_all()
        open(PAIRS_TSV, 'w').write(txt)
        print('wrote ' + PAIRS_TSV)
        return 0
    tab = load_pairs()
    check = '--check' in argv
    rc = 0
    for top in TARGETS:
        path = os.path.join(REPO, 'verif', 'ut', top, 'fm_pins_pre.tcl')
        txt = build(top, tab)
        if check:
            ok = os.path.exists(path) and open(path).read() == txt
            print(('OK: ' if ok else 'DRIFT: ') + path)
            rc |= 0 if ok else 1
        else:
            if not os.path.exists(path) or open(path).read() != txt:
                open(path, 'w').write(txt)
            print('wrote ' + path)
    return rc


if __name__ == '__main__':
    sys.exit(main())
