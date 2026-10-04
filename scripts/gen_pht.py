#!/usr/bin/env python3
"""gen_pht.py —— PatternHistoryTable 的两份机械产物（手写核区一个字节都不动）：

1. rtl/memblock/PatternHistoryTable.sv 的 GENERATED(pht-wrapper) 区：golden 同名 wrapper。
   * wrapper 端口 = golden 端口（逐行同名同宽同序）；
   * 核 u_core 的接线按下面 CORE_CONN 表；4 个 child 按 golden 实例名与模块名例化（从 golden 现读核对），
     每个 child 端口（从 golden child 端口表现读）必须恰好命中一条接线规则，否则生成失败；
   * child 端口若直接接 golden 顶层端口或常量，与 golden 实例连线逐项比对；
   * wrapper 的每个 output 必须恰好被驱动一次。
2. verif/ut/PatternHistoryTable/fm_pins_pre.tcl：FM「匹配前」钉点。
   golden 顶层 218 个寄存器是 firtool 扁平名（pht_valids_reg_1_17、s3_hist_12、s3_repl_update_mask_5 …），
   重写核是数组（u_core/pht_valids_reg[1][17] …）且多一层 u_core。钉点只消名差：告诉 FM"这两个点是同一个点"，
   比较照比，不约束 ref、不放宽判据。golden 每个寄存器必须恰好命中一条规则、映射单射、总位数等于字面期望；
   运行期逐条数 set_user_match 返回值，拒一条或总数不符即 error。

用法：python3 scripts/gen_pht.py [--check]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
TOP = 'PatternHistoryTable'
OUT = os.path.join(REPO, 'rtl', 'memblock', TOP + '.sv')
PINS = os.path.join(REPO, 'verif', 'ut', TOP, 'fm_pins_pre.tcl')
TAG = 'pht-wrapper'
WAYS, HIST_N = 2, 30
PIN_EXPECT_BITS = 991      # golden 顶层寄存器总位数（生成期从 golden 现算并核对）

# 核端口 -> wrapper 里的线
CORE_CONN = [
    ('clock', 'clock'), ('reset', 'reset'),
    ('lookup_valid', 'lq_out_valid'), ('lookup_ready', 'lq_out_ready'),
    ('lookup_phtIndex', 'lq_out_pht_index'), ('lookup_phtTag', 'lq_out_pht_tag'),
    ('lookup_regionPaddr', 'lq_out_region_paddr'), ('lookup_regionVaddr', 'lq_out_region_vaddr'),
    ('lookup_regionOffset', 'lq_out_region_offset'),
    ('evict_valid', 'eq_out_valid'), ('evict_ready', 'eq_out_ready'),
    ('evict_phtIndex', 'eq_out_pht_index'), ('evict_phtTag', 'eq_out_pht_tag'),
    ('evict_regionBits', 'eq_out_region_bits'), ('evict_regionBitSingle', 'eq_out_region_bit_single'),
    ('evict_regionOffset', 'eq_out_region_offset'), ('evict_accessCnt', 'eq_out_access_cnt'),
    ('evict_decrMode', 'eq_out_decr_mode'), ('evict_singleUpdate', 'eq_out_single_update'),
    ('evict_hasBeenSingleUpdated', 'eq_out_has_been_signal_updated'),
    ('ramRdValid', 'ramRdValid'), ('ramRdSet', 'ramRdSet'), ('ramRdHist', 'ramRdHist'), ('ramRdTag', 'ramRdTag'),
    ('ramWrValid', 'ramWrValid'), ('ramWrSet', 'ramWrSet'), ('ramWrHist', 'ramWrHist'), ('ramWrTag', 'ramWrTag'),
    ('ramWrDecrMode', 'ramWrDecrMode'), ('ramWrWayMask', 'ramWrWayMask'),
    ('curValid', 'pf_cur_valid'), ('curTag', 'pf_cur_region_tag'), ('curAddr', 'pf_cur_region_addr'),
    ('curBits', 'pf_cur_region_bits'),
    ('incrReady', 'pf_incr_ready'), ('incrValid', 'pf_incr_valid'), ('incrTag', 'pf_incr_region_tag'),
    ('incrAddr', 'pf_incr_region_addr'), ('incrBits', 'pf_incr_region_bits'),
    ('incrPaddrValid', 'pf_incr_paddr_valid'),
    ('decrReady', 'pf_decr_ready'), ('decrValid', 'pf_decr_valid'), ('decrTag', 'pf_decr_region_tag'),
    ('decrAddr', 'pf_decr_region_addr'), ('decrBits', 'pf_decr_region_bits'),
    ('decrPaddrValid', 'pf_decr_paddr_valid'),
]

# child: (实例名, 模块名, [(端口正则, 目标模板)])
CHILDREN = [
    ('pht_ram', 'SRAMTemplate_145', [
        (r'clock$', 'clock'), (r'reset$', 'reset'),
        (r'io_r_req_valid$', 'ramRdValid'), (r'io_r_req_bits_setIdx$', 'ramRdSet'),
        (r'io_r_resp_data_(\d+)_hist_(\d+)$', r'ramRdHist[\1][\2]'), (r'io_r_resp_data_(\d+)_tag$', r'ramRdTag[\1]'),
        (r'io_w_req_valid$', 'ramWrValid'), (r'io_w_req_bits_setIdx$', 'ramWrSet'),
        (r'io_w_req_bits_data_\d+_hist_(\d+)$', r'ramWrHist[\1]'), (r'io_w_req_bits_data_\d+_tag$', 'ramWrTag'),
        (r'io_w_req_bits_data_\d+_decr_mode$', 'ramWrDecrMode'), (r'io_w_req_bits_waymask$', 'ramWrWayMask'),
        (r'io_broadcast_ram_ctl$', "64'h0"), (r'io_broadcast_cgen$', 'sigFromSrams_bore_cgen'),
        (r'io_broadcast_(ram_(?!ctl)\w+)$', r'sigFromSrams_bore_\1'),
        (r'(boreChildrenBd_bore_\w+)$', r'\1'),
    ]),
    ('lookup_queue', 'OverrideableQueue', [
        (r'clock$', 'clock'), (r'reset$', 'reset'),
        (r'io_in_valid$', 'io_s2_agt_lookup_valid'), (r'io_in_bits_(\w+)$', r'io_s2_agt_lookup_bits_\1'),
        (r'io_out_(valid|ready)$', r'lq_out_\1'), (r'io_out_bits_(\w+)$', r'lq_out_\1'),
    ]),
    ('evict_queue', 'OverrideableQueue_1', [
        (r'clock$', 'clock'), (r'reset$', 'reset'),
        (r'io_in_valid$', 'io_agt_update_valid'), (r'io_in_bits_(\w+)$', r'io_agt_update_bits_\1'),
        (r'io_out_(valid|ready)$', r'eq_out_\1'), (r'io_out_bits_(\w+)$', r'eq_out_\1'),
    ]),
    ('pf_gen_req_arb', 'Arbiter3_PfGenReq', [
        (r'io_in_0_(valid)$', r'pf_cur_\1'), (r'io_in_0_bits_(\w+)$', r'pf_cur_\1'),
        (r'io_in_1_(valid|ready)$', r'pf_incr_\1'), (r'io_in_1_bits_(\w+)$', r'pf_incr_\1'),
        (r'io_in_2_(valid|ready)$', r'pf_decr_\1'), (r'io_in_2_bits_(\w+)$', r'pf_decr_\1'),
        (r'io_out_(valid)$', r'io_pf_gen_req_\1'), (r'io_out_bits_(\w+)$', r'io_pf_gen_req_bits_\1'),
    ]),
]

# 钉点规则：golden 顶层寄存器名 -> 核里的寄存器（FM 名 = u_core/<名>_reg[下标...]）
PIN_RULES = [
    (r'pht_valids_reg_(\d)_(\d+)', lambda m: ('pht_valids', [m[1], m[2]])),
    (r'state_reg', lambda m: ('plru_state', ['0'])),
    (r'state_reg_(\d+)', lambda m: ('plru_state', [m[1]])),
    (r's1_valid_r', lambda m: ('s1_valid', [])),
    (r's2_valid_last_REG', lambda m: ('s2_valid', [])),
    (r's3_valid_last_REG', lambda m: ('s3_valid', [])),
    (r's([12])_access_cnt_signal', lambda m: ('s%s_access_cnt' % m[1], [])),
    (r's2_pht_valids_(\d)', lambda m: ('s2_pht_valids', [m[1]])),
    (r's3_hist_(\d+)', lambda m: ('s3_hist', [m[1]])),
    (r's3_hit_vec_(\d)', lambda m: ('s3_hit_vec', [m[1]])),
    (r's3_repl_update_mask_(\d+)', lambda m: ('s3_repl_update_mask', [m[1]])),
    (r's4_pf_gen_(cur|incr|decr)_region_(valid)', lambda m: ('s4_%s_valid' % m[1], [])),
    (r's4_pf_gen_(cur|incr|decr)_region_region_(tag|addr|bits)', lambda m: ('s4_%s_%s' % (m[1], m[2]), [])),
    (r's4_pf_gen_(incr|decr)_region_paddr_valid', lambda m: ('s4_%s_paddr_valid' % m[1], [])),
    (r'(s[123]_\w+)', lambda m: (m[1], [])),     # 其余级间寄存器：同名
]


def die(msg):
    raise SystemExit('gen_pht: ' + msg)


def gtext(mod):
    return open(os.path.join(G, mod + '.sv')).read()


def ports(mod):
    t = gtext(mod)
    i = t.index('\nmodule %s(' % mod) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            die('%s: 端口行解析失败: %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def golden_instances():
    t = gtext(TOP)
    body = t[t.index('\nmodule %s(' % TOP):]
    insts = {}
    for m in re.finditer(r'^  (\w+) (\w+) \((.*?)^  \);', body, re.S | re.M):
        cm = {}
        for c in re.finditer(r'\.(\w+)\s*\((.*?)\)(?:,|\s*$)', m.group(3), re.S):
            cm[c.group(1)] = ' '.join(c.group(2).split())
        insts[m.group(2)] = (m.group(1), cm)
    return insts


def emit_wrapper():
    P = ports(TOP)
    pdir = {n: d for d, w, n in P}
    pw = {n: w for d, w, n in P}
    insts = golden_instances()
    if set(insts) != {c[0] for c in CHILDREN}:
        die('golden 实例集合 %s 与预期不同' % sorted(insts))
    driven = {}

    def drive(port, who):
        if port in driven:
            die('wrapper 输出 %s 被驱动两次（%s / %s）' % (port, driven[port], who))
        driven[port] = who

    # 每个 child 的连线，同时收集 wrapper 内部线（名字 -> 位宽 / 维度）
    wires = {}
    blocks = []
    for inst, mod, rules in CHILDREN:
        if insts[inst][0] != mod:
            die('%s 在 golden 里是 %s' % (inst, insts[inst][0]))
        gconn = insts[inst][1]
        cl = []
        for d, w, n in ports(mod):
            hits = [(p, t) for p, t in rules if re.match(p, n)]
            if len(hits) != 1:
                die('%s.%s 命中 %d 条规则' % (inst, n, len(hits)))
            tgt = re.sub(hits[0][0], hits[0][1], n)
            base = tgt.split('[')[0]
            if base in pdir:
                if pw[base] != w:
                    die('%s.%s 位宽 %d 与端口 %s 位宽 %d 不同' % (inst, n, w, base, pw[base]))
                if gconn.get(n) != base:
                    die('%s.%s golden 接 %s，生成接 %s' % (inst, n, gconn.get(n), base))
                if pdir[base] == 'output':
                    if d != 'output':
                        die('%s.%s 输入接到 wrapper 输出' % (inst, n))
                    drive(base, '%s.%s' % (inst, n))
            elif re.match(r"\d+'h", tgt):
                if gconn.get(n) != tgt:
                    die('%s.%s golden 接 %s，生成接常量 %s' % (inst, n, gconn.get(n), tgt))
            elif base not in ('clock', 'reset'):
                dims = re.findall(r'\[(\d+)\]', tgt)
                prev = wires.get(base)
                if prev is not None and (prev[0] != w or len(prev[1]) != len(dims)):
                    die('线 %s 两处位宽/维度不一致' % base)
                ext = [max(int(x) + 1, (prev[1][k] if prev else 0)) for k, x in enumerate(dims)]
                wires[base] = (w, ext)
            cl.append('    .%-31s (%s)' % (n, tgt))
        blocks.append((inst, mod, cl))
    # 核
    core_wires = {c[1] for c in CORE_CONN}
    for w_ in core_wires - {'clock', 'reset'}:
        if w_ not in wires:
            die('核接的线 %s 没有任何 child 端口用到' % w_)
    for w_ in wires:
        if w_ not in core_wires:
            die('child 线 %s 没接到核' % w_)

    L = []
    A = L.append
    A('module %s (' % TOP)
    A(',\n'.join('  %-6s %-9s%s' % (d, '' if w == 1 else '[%d:0]' % (w - 1), n) for d, w, n in P))
    A(');')
    A('')
    A('  // ---- 核与 child 之间的线（名字取 golden 字段名；数组下标 = 路 / 计数器号）----')
    for name in sorted(wires, key=lambda x: [c[1] for c in CORE_CONN].index(x)):
        w, ext = wires[name]
        A('  logic %-9s %s%s;' % ('' if w == 1 else '[%d:0]' % (w - 1), name, ''.join(' [%d]' % e for e in ext)))
    A('')
    A('  xs_PatternHistoryTable_core u_core (')
    A(',\n'.join('    .%-26s (%s)' % (cp, wn) for cp, wn in CORE_CONN))
    A('  );')
    for inst, mod, cl in blocks:
        A('')
        A('  %s %s (' % (mod, inst))
        A(',\n'.join(cl))
        A('  );')
    outs = {n for d, w, n in P if d == 'output'}
    if set(driven) != outs:
        die('wrapper 输出未全覆盖：缺 %s 多 %s' % (sorted(outs - set(driven)), sorted(set(driven) - outs)))
    A('')
    A('endmodule')
    return '\n'.join(L)


def emit_pins():
    t = gtext(TOP)
    body = t[t.index('\nmodule %s(' % TOP):]
    regs = [(m.group(2), 1 if m.group(1) is None else int(m.group(1)) + 1)
            for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body, re.M)]
    total = sum(w for _, w in regs)
    if total != PIN_EXPECT_BITS:
        die('golden 顶层寄存器 %d 位，字面期望 %d' % (total, PIN_EXPECT_BITS))
    pairs = []
    seen_i = set()
    for name, w in regs:
        hits = [(p, f) for p, f in PIN_RULES if re.fullmatch(p, name)]
        # 具体规则优先于最后一条"同名"兜底规则：除兜底外命中必须 <= 1
        specific = [h for h in hits if h[0] != PIN_RULES[-1][0]]
        if len(specific) > 1 or not hits:
            die('golden 寄存器 %s 命中 %d 条规则' % (name, len(specific) or len(hits)))
        p, f = (specific or hits)[0]
        iname, idx = f(re.fullmatch(p, name))
        ibase = 'u_core/%s_reg%s' % (iname, ''.join('[%s]' % x for x in idx))
        bits = [None] if w == 1 else list(range(w))
        for b in bits:
            r = '%s_reg' % name + ('' if b is None else '[%d]' % b)
            i = ibase + ('' if b is None else '[%d]' % b)
            if i in seen_i:
                die('映射不单射：%s' % i)
            seen_i.add(i)
            pairs.append((r, i))
    if len(pairs) != PIN_EXPECT_BITS:
        die('钉点 %d 位，期望 %d' % (len(pairs), PIN_EXPECT_BITS))
    o = []
    o.append('# PatternHistoryTable FM「匹配前」钉点 —— 自动生成：scripts/gen_pht.py（勿手改）')
    o.append('#')
    o.append('# golden 顶层 %d 个寄存器 / %d 位逐位 set_user_match 到重写核 u_core 的同义寄存器（扁平名 vs 数组名）。' % (len(regs), len(pairs)))
    o.append('# 只消名差，比较照比。fail-closed：拒一条或总数 != %d 即 error。进 fm.log 的输出一律 ASCII。' % len(pairs))
    o.append('set ::PHT_PIN_EXPECT %d' % len(pairs))
    o.append('set ::PHT_PIN_OK 0')
    o.append('set ::PHT_PIN_BAD 0')
    o.append('proc pht_pin {r i} {')
    o.append('  if {[set_user_match "r:/WORK/%s/$r" "i:/WORK/%s/$i"]} { incr ::PHT_PIN_OK } else {' % (TOP, TOP))
    o.append('    incr ::PHT_PIN_BAD')
    o.append('    if {$::PHT_PIN_BAD <= 10} { puts "PHT_PIN_FAIL: $r <-> $i" }')
    o.append('  }')
    o.append('}')
    o.append('puts "PHT_PIN_BEGIN %s expect=$::PHT_PIN_EXPECT"' % TOP)
    for r, i in pairs:
        o.append('pht_pin {%s} {%s}' % (r, i))
    o.append('puts "PHT_PIN_END %s ok=$::PHT_PIN_OK bad=$::PHT_PIN_BAD"' % TOP)
    o.append('if {$::PHT_PIN_BAD != 0} { error "PHT_PIN_MISS=$::PHT_PIN_BAD" }')
    o.append('if {$::PHT_PIN_OK != %d} { error "PHT_PIN_COUNT=$::PHT_PIN_OK expect=%d" }' % (len(pairs), len(pairs)))
    return '\n'.join(o) + '\n'


def replace_region(text, body):
    begin = '// BEGIN GENERATED(%s)' % TAG
    end = '// END GENERATED'
    i = text.index(begin)
    j = text.index(end, i)
    return text[:i] + begin + '\n' + body + '\n' + end + text[j + len(end):]


def main():
    check = '--check' in sys.argv[1:]
    outs = [(OUT, replace_region(open(OUT).read(), emit_wrapper())), (PINS, emit_pins())]
    rc = 0
    for path, txt in outs:
        cur = open(path).read() if os.path.exists(path) else None
        if check:
            ok = cur == txt
            print(('OK: ' if ok else 'DRIFT: ') + path)
            rc |= 0 if ok else 1
        elif cur != txt:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'w').write(txt)
            print('wrote ' + path)
        else:
            print('unchanged ' + path)
    return rc


if __name__ == '__main__':
    sys.exit(main())
