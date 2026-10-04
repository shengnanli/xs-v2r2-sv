#!/usr/bin/env python3
"""gen_mmiobridge.py —— 生成 rtl/uncore/MMIOBridge.sv 的 golden 同名 wrapper 区（手写核区一个字节都不动）。

MMIOBridge（coupledL2 tl2chi/MMIOBridge.scala）= 16 个事务槽 + 3 个仲裁器 + 少量胶合逻辑。胶合逻辑在手写核
xs_MMIOBridge_core 里；本脚本只生成 GENERATED(mmiobridge-wrapper) 区：
  * wrapper 端口 = golden 端口（逐行同名同宽同序）；
  * 16 个槽按 golden 的实例名 entries_<i> 与模块名（MMIOBridgeEntry / _2 / _4 / _8）例化，模块名从 golden 现读；
  * 3 个仲裁器按 golden 实例名 txreqArb / mmio_txdat_arb / mmio_channel_D_arb 例化；
  * 每个子模块端口（从 golden 子模块端口表现读）必须**恰好命中一条**接线规则，否则生成失败；
  * wrapper 的每个 output 必须恰好被驱动一次（子模块输出 / 核输出 / 常量表），否则生成失败；
  * 常量表逐项与 golden 的 `assign <port> = <常量>;` 比对（值不同或多/少一项都失败）；
  * 每个槽的 io_id 字面量、io_pCrd 接线与 golden 实例连线逐项比对。

用法：python3 scripts/gen_mmiobridge.py [--check]
  --check：不写文件，只比较生成结果与库里文件是否逐字相同（漂移 → rc=1）。
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'uncore', 'MMIOBridge.sv')
TOP = 'MMIOBridge'
NUM = 16
TAG = 'mmiobridge-wrapper'

# CHI 通道里本桥不用的字段：常量（逐项与 golden 比对）
CONSTS = [
    # TileLink D：param / sink 不用
    ('auto_mmio_in_d_bits_param', "2'h0"), ('auto_mmio_in_d_bits_sink', "1'h0"),
    # TXREQ：QoS 固定 0xE；ID/路由字段由下游 NoC 填，这里全 0；不分配、不可缓存、不窥探
    ('io_tx_req_bits_qos', "4'hE"), ('io_tx_req_bits_tgtID', "11'h0"), ('io_tx_req_bits_srcID', "11'h0"),
    ('io_tx_req_bits_returnNID', "11'h0"), ('io_tx_req_bits_stashNIDValid', "1'h0"),
    ('io_tx_req_bits_returnTxnID', "12'h0"), ('io_tx_req_bits_ns', "1'h0"),
    ('io_tx_req_bits_likelyshared', "1'h0"), ('io_tx_req_bits_memAttr_allocate', "1'h0"),
    ('io_tx_req_bits_memAttr_cacheable', "1'h0"), ('io_tx_req_bits_snpAttr', "1'h0"),
    ('io_tx_req_bits_lpIDWithPadding', "8'h0"), ('io_tx_req_bits_snoopMe', "1'h0"),
    ('io_tx_req_bits_expCompAck', "1'h0"), ('io_tx_req_bits_tagOp', "2'h0"),
    ('io_tx_req_bits_traceTag', "1'h0"), ('io_tx_req_bits_mpam_perfMonGroup', "1'h0"),
    ('io_tx_req_bits_mpam_partID', "9'h0"), ('io_tx_req_bits_mpam_mpamNS', "1'h0"),
    ('io_tx_req_bits_rsvdc', "4'h0"),
    # TXDAT：opcode 恒 NonCopyBackWrData(0x3)，其余不用的字段 0
    ('io_tx_dat_bits_qos', "4'h0"), ('io_tx_dat_bits_srcID', "11'h0"), ('io_tx_dat_bits_homeNID', "11'h0"),
    ('io_tx_dat_bits_opcode', "4'h3"), ('io_tx_dat_bits_resp', "3'h0"), ('io_tx_dat_bits_dataSource', "4'h0"),
    ('io_tx_dat_bits_cBusy', "3'h0"), ('io_tx_dat_bits_dbID', "12'h0"), ('io_tx_dat_bits_tagOp', "2'h0"),
    ('io_tx_dat_bits_tag', "8'h0"), ('io_tx_dat_bits_tu', "2'h0"), ('io_tx_dat_bits_rsvdc', "4'h0"),
]

# 核端口 -> wrapper 里的线（核的 output 若是 wrapper 端口，算"驱动 wrapper 输出"）
CORE_CONN = [
    ('a_valid', 'auto_mmio_in_a_valid'), ('a_ready', 'auto_mmio_in_a_ready'),
    ('slot_reqReady', 'slot_reqReady'), ('slot_reqValid', 'slot_reqValid'),
    ('slot_waitOnReadReceipt', 'slot_waitOnReadReceipt'),
    ('slot_txReqValid', 'slot_txReqValid'), ('slot_txReqOpcode', 'slot_txReq_opcode'),
    ('slot_txReqReady', 'slot_txReqReady'), ('txReqArb_inReady', 'txReqArb_inReady'),
    ('txReqArb_inValid', 'txReqArb_inValid'),
    ('rxRsp_valid', 'io_rx_rsp_valid'), ('rxRsp_txnID', 'io_rx_rsp_bits_txnID'), ('rxRsp_ready', 'io_rx_rsp_ready'),
    ('slot_rxRspValid', 'slot_rxRspValid'),
    ('rxDat_valid', 'io_rx_dat_valid'), ('rxDat_txnID', 'io_rx_dat_bits_txnID'), ('rxDat_ready', 'io_rx_dat_ready'),
    ('slot_rxDatValid', 'slot_rxDatValid'), ('slot_rxDatReady', 'slot_rxDatReady'),
]
CORE_OUTS = {'a_ready', 'slot_reqValid', 'slot_txReqReady', 'txReqArb_inValid', 'rxRsp_ready',
             'slot_rxRspValid', 'rxDat_ready', 'slot_rxDatValid'}

# 槽端口接线规则：(正则, 目标模板)；{i}=槽号；\1 = 字段名。目标以 slot_ 开头的是每槽数组元素。
ENTRY_RULES = [
    (r'clock$', 'clock'), (r'reset$', 'reset'),
    (r'io_req_ready$', 'slot_reqReady[{i}]'), (r'io_req_valid$', 'slot_reqValid[{i}]'),
    (r'io_req_bits_(\w+)$', r'auto_mmio_in_a_bits_\1'),
    (r'io_resp_ready$', 'slot_respReady[{i}]'), (r'io_resp_valid$', 'slot_respValid[{i}]'),
    (r'io_resp_bits_(\w+)$', r'slot_resp_\1[{i}]'),
    (r'io_chi_tx_req_ready$', 'slot_txReqReady[{i}]'), (r'io_chi_tx_req_valid$', 'slot_txReqValid[{i}]'),
    (r'io_chi_tx_req_bits_(\w+)$', r'slot_txReq_\1[{i}]'),
    (r'io_chi_tx_dat_ready$', 'slot_txDatReady[{i}]'), (r'io_chi_tx_dat_valid$', 'slot_txDatValid[{i}]'),
    (r'io_chi_tx_dat_bits_(\w+)$', r'slot_txDat_\1[{i}]'),
    (r'io_chi_rx_rsp_ready$', 'slot_rxRspReady[{i}]'), (r'io_chi_rx_rsp_valid$', 'slot_rxRspValid[{i}]'),
    (r'io_chi_rx_rsp_bits_(\w+)$', r'io_rx_rsp_bits_\1'),
    (r'io_chi_rx_dat_ready$', 'slot_rxDatReady[{i}]'), (r'io_chi_rx_dat_valid$', 'slot_rxDatValid[{i}]'),
    (r'io_chi_rx_dat_bits_(\w+)$', r'io_rx_dat_bits_\1'),
    (r'io_id$', '{idlit}'),
    (r'io_pCrd_query_(\w+)$', r'io_pCrd_{i}_query_\1'), (r'io_pCrd_grant$', 'io_pCrd_{i}_grant'),
    (r'io_waitOnReadReceipt$', 'slot_waitOnReadReceipt[{i}]'),
]

# 仲裁器：(实例名, 模块名, 输入侧前缀, 输出侧目标前缀, ready/valid 线名)
ARBS = [
    ('txreqArb', 'RRArbiterInit_13', 'slot_txReq_', 'io_tx_req',
     {'in_ready': 'txReqArb_inReady', 'in_valid': 'txReqArb_inValid'}),
    ('mmio_txdat_arb', 'Arbiter16_CHIDAT', 'slot_txDat_', 'io_tx_dat',
     {'in_ready': 'slot_txDatReady', 'in_valid': 'slot_txDatValid'}),
    ('mmio_channel_D_arb', 'Arbiter16_TLBundleD', 'slot_resp_', 'auto_mmio_in_d',
     {'in_ready': 'slot_respReady', 'in_valid': 'slot_respValid'}),
]


def die(msg):
    raise SystemExit('gen_mmiobridge: ' + msg)


def golden_text(mod):
    return open(os.path.join(G, mod + '.sv')).read()


def ports(mod):
    t = golden_text(mod)
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
    """golden MMIOBridge 里每个实例：{实例名: (模块名, {端口: 连线文本})}"""
    t = golden_text(TOP)
    body = t[t.index('\nmodule %s(' % TOP):]
    insts = {}
    for m in re.finditer(r'^  (\w+) (\w+) \((.*?)^  \);', body, re.S | re.M):
        mod, inst, conns = m.group(1), m.group(2), m.group(3)
        cm = {}
        for c in re.finditer(r'\.(\w+)\s*\((.*?)\)(?:,|\s*$)', conns, re.S):
            cm[c.group(1)] = ' '.join(c.group(2).split())
        insts[inst] = (mod, cm)
    return insts


def apply_rules(rules, port, **kw):
    hits = [(pat, tmpl) for pat, tmpl in rules if re.match(pat, port)]
    if len(hits) != 1:
        die('端口 %s 命中 %d 条规则（必须恰好 1 条）' % (port, len(hits)))
    pat, tmpl = hits[0]
    return re.sub(pat, tmpl, port).format(**kw)


def emit():
    P = ports(TOP)
    pdir = {n: d for d, w, n in P}
    pw = {n: w for d, w, n in P}
    insts = golden_instances()
    slot_mod = {}
    for i in range(NUM):
        name = 'entries_%d' % i
        if name not in insts:
            die('golden 里找不到实例 %s' % name)
        slot_mod[i] = insts[name][0]
        if not slot_mod[i].startswith('MMIOBridgeEntry'):
            die('%s 的模块是 %s' % (name, slot_mod[i]))
    expect_insts = {'entries_%d' % i for i in range(NUM)} | {a[0] for a in ARBS}
    if set(insts) != expect_insts:
        die('golden 实例集合不符：多 %s 少 %s' % (sorted(set(insts) - expect_insts), sorted(expect_insts - set(insts))))
    for inst, mod, *_ in ARBS:
        if insts[inst][0] != mod:
            die('%s 是 %s 不是 %s' % (inst, insts[inst][0], mod))

    # 槽端口：四个变体除 io_id 位宽外必须逐项相同
    EP = {m: ports(m) for m in set(slot_mod.values())}
    base = [(d, w, n) for d, w, n in EP['MMIOBridgeEntry'] if n != 'io_id']
    for m, pl in EP.items():
        if [(d, w, n) for d, w, n in pl if n != 'io_id'] != base:
            die('%s 的端口表（除 io_id）与 MMIOBridgeEntry 不同' % m)
    ew = {n: w for d, w, n in base}

    driven = {}           # wrapper output -> 驱动者

    def drive(port, who):
        if port in driven:
            die('wrapper 输出 %s 被驱动两次（%s / %s）' % (port, driven[port], who))
        driven[port] = who

    # 常量表 vs golden
    gt = golden_text(TOP)
    # golden 的常量输出有两种写法：直接 `assign 端口 = 常量;`，或经一根常量 wire
    # （`wire ... mmioNodeIn_d_bits_param = 2'h0;` + `assign 端口 = mmioNodeIn_d_bits_param;`）。两种都算。
    cwire = dict(re.findall(r"^  wire\s+(?:\[\d+:0\]\s+)?(\w+) = (\d+'h[0-9A-F]+);$", gt, re.M))
    gconst = {}
    for port, rhs in re.findall(r"^  assign (\w+) = (\w+|\d+'h[0-9A-F]+);$", gt, re.M):
        if re.match(r"\d+'h", rhs):
            gconst[port] = rhs
        elif rhs in cwire:
            gconst[port] = cwire[rhs]
    # 核驱动的常量输出（rxRsp_ready 恒 1）不在常量表里，单独核对
    if gconst.pop('io_rx_rsp_ready', None) != "1'h1":
        die('golden io_rx_rsp_ready 不是常量 1')
    mine = dict(CONSTS)
    if gconst != mine:
        die('常量表与 golden 不同：%s' % sorted(set(gconst.items()) ^ set(mine.items())))

    L = []
    A = L.append
    A('module %s (' % TOP)
    A(',\n'.join('  %-6s %-9s%s' % (d, '' if w == 1 else '[%d:0]' % (w - 1), n) for d, w, n in P))
    A(');')
    A('')
    A('  localparam int unsigned NUM_SLOTS = %d;' % NUM)
    A('')
    A('  // ---- 每槽的线：握手用打包向量，数据字段用按槽下标的数组 ----')
    vec = ['slot_reqReady', 'slot_reqValid', 'slot_waitOnReadReceipt', 'slot_respReady', 'slot_respValid',
           'slot_txReqReady', 'slot_txReqValid', 'txReqArb_inReady', 'txReqArb_inValid',
           'slot_txDatReady', 'slot_txDatValid', 'slot_rxRspReady', 'slot_rxRspValid',
           'slot_rxDatReady', 'slot_rxDatValid']
    for v in vec:
        A('  logic [NUM_SLOTS-1:0] %s;' % v)
    arrays = []
    for pre, chan in (('slot_resp_', 'io_resp_bits_'), ('slot_txReq_', 'io_chi_tx_req_bits_'),
                      ('slot_txDat_', 'io_chi_tx_dat_bits_')):
        for d, w, n in base:
            if n.startswith(chan):
                f = n[len(chan):]
                arrays.append(pre + f)
                A('  logic %-9s %s [NUM_SLOTS];' % ('' if w == 1 else '[%d:0]' % (w - 1), pre + f))
    A('')
    A('  // ---- 胶合逻辑：选槽 / 读保序 / RX 分发（手写核）----')
    A('  xs_MMIOBridge_core #(.NUM_SLOTS(NUM_SLOTS)) u_core (')
    cl = []
    for cp, wire in CORE_CONN:
        cl.append('    .%-22s (%s)' % (cp, wire))
        if cp in CORE_OUTS and wire in pdir:
            if pdir[wire] != 'output':
                die('核输出 %s 接到了 wrapper 输入 %s' % (cp, wire))
            drive(wire, 'u_core.' + cp)
    A(',\n'.join(cl))
    A('  );')
    A('')
    A('  // ---- 16 个事务槽（实例名与模块名同 golden）----')
    for i in range(NUM):
        mod = slot_mod[i]
        g_conn = insts['entries_%d' % i][1]
        idw = dict((n, w) for d, w, n in EP[mod])['io_id']
        idlit = "%d'h%X" % (idw, i)
        if g_conn.get('io_id') != idlit:
            die('entries_%d.io_id golden=%s 生成=%s' % (i, g_conn.get('io_id'), idlit))
        A('  %s entries_%d (' % (mod, i))
        cl = []
        for d, w, n in EP[mod]:
            tgt = apply_rules(ENTRY_RULES, n, i=i, idlit=idlit)
            base_t = tgt.split('[')[0]
            if base_t in pdir:
                if pdir[base_t] == 'output':
                    if d != 'output':
                        die('entries_%d.%s 是输入却接 wrapper 输出 %s' % (i, n, base_t))
                    drive(base_t, 'entries_%d.%s' % (i, n))
                    if g_conn.get(n) != base_t:
                        die('entries_%d.%s golden 接 %s，生成接 %s' % (i, n, g_conn.get(n), base_t))
                if pw[base_t] != w:
                    die('entries_%d.%s 位宽 %d 与 %s 位宽 %d 不同' % (i, n, w, base_t, pw[base_t]))
            elif base_t not in vec and base_t not in arrays and base_t not in ('clock', 'reset') \
                    and not re.match(r"\d+'h", base_t):
                die('entries_%d.%s 的目标 %s 不是已声明的线' % (i, n, tgt))
            if base_t in arrays and ew[n] != w:
                die('位宽不符 %s' % n)
            cl.append('    .%-33s (%s)' % (n, tgt))
        A(',\n'.join(cl))
        A('  );')
    A('')
    A('  // ---- 三个仲裁器（实例名同 golden）----')
    for inst, mod, inpre, outpre, rv in ARBS:
        AP = ports(mod)
        A('  %s %s (' % (mod, inst))
        cl = []
        for d, w, n in AP:
            m_in = re.match(r'io_in_(\d+)_(ready|valid|bits_(\w+))$', n)
            m_out = re.match(r'io_out_(ready|valid|bits_\w+)$', n)
            if n in ('clock', 'reset'):
                tgt = n
            elif m_in:
                k = int(m_in.group(1))
                if not 0 <= k < NUM:
                    die('%s.%s 槽号越界' % (inst, n))
                if m_in.group(2) == 'ready':
                    tgt = '%s[%d]' % (rv['in_ready'], k)
                elif m_in.group(2) == 'valid':
                    tgt = '%s[%d]' % (rv['in_valid'], k)
                else:
                    tgt = '%s%s[%d]' % (inpre, m_in.group(3), k)
                    if inpre + m_in.group(3) not in arrays:
                        die('%s.%s 的数据字段 %s 槽侧没有' % (inst, n, m_in.group(3)))
            elif m_out:
                tgt = '%s_%s' % (outpre, m_out.group(1))
                if tgt not in pdir:
                    die('%s.%s -> %s 不是 wrapper 端口' % (inst, n, tgt))
                if pw[tgt] != w:
                    die('%s.%s 位宽不符' % (inst, n))
                if d == 'output':
                    drive(tgt, '%s.%s' % (inst, n))
            else:
                die('%s.%s 无接线规则' % (inst, n))
            cl.append('    .%-30s (%s)' % (n, tgt))
        A(',\n'.join(cl))
        A('  );')
    A('')
    A('  // ---- 常量字段（本桥不用的 TileLink / CHI 字段，值同 golden）----')
    for p, v in CONSTS:
        drive(p, 'const')
        A('  assign %s = %s;' % (p, v))
    outs = {n for d, w, n in P if d == 'output'}
    if set(driven) != outs:
        die('wrapper 输出未全覆盖：缺 %s 多 %s' % (sorted(outs - set(driven)), sorted(set(driven) - outs)))
    A('')
    A('endmodule')
    return '\n'.join(L)


def replace_region(text, body):
    begin = '// BEGIN GENERATED(%s)' % TAG
    end = '// END GENERATED'
    i = text.index(begin)
    j = text.index(end, i)
    return text[:i] + begin + '\n' + body + '\n' + end + text[j + len(end):]


def main():
    cur = open(OUT).read()
    new = replace_region(cur, emit())
    if '--check' in sys.argv[1:]:
        ok = new == cur
        print(('OK: ' if ok else 'DRIFT: ') + OUT)
        return 0 if ok else 1
    if new != cur:
        open(OUT, 'w').write(new)
    print('wrote ' + OUT)
    return 0


if __name__ == '__main__':
    sys.exit(main())
