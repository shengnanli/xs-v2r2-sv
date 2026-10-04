#!/usr/bin/env python3
"""gen_uncore_queues.py —— uncore-queues lane：TileLink / CHI 通道上的 chisel Queue 单态化
与两个 utility.Pipeline 单态化的薄文件生成器（fail-closed）。

firtool 把每个 `Queue(gen, entries, pipe, flow)` 单态化成 Queue<N>_<Bundle>：同一套指针/空满控制
+ 一块 ram_<D>x<W> 行为级存储 + 把 Bundle 字段拼进 ram 一个字的连线。本脚本只生成**连线**：
控制逻辑在手写核里——
  * 普通（pipe=false, flow=false）：已签共享核 rtl/common/xs_ChiselQueue_core.sv（不改）；
  * pipe=true（Queue4_CHISNP）：rtl/uncore/xs_ChiselQueuePipe_core.sv（与上者同端口，多一个 pipe）；
  * 带 flush（Queue40_L2TlbMQBundle）：rtl/memblock/L2TlbMissQueue.sv 里已签的 xs_L2TlbMissQueue_core
    （golden 里带 flush 的 Queue 只有这一个，它本来就是这个队列压平后的可读核）。
存储 ram 叶子照 golden 同名例化（2 的幂深度：两侧同源 inline；非 2 的幂见 verif/vendor_boundary.tsv）。

fail-closed 校验（任何一条不符就报错退出，不写文件）：
  1. golden 队列体去掉 `ifdef ENABLE_INITIAL_REG_ 仿真初始化段后，**每一行**都必须被认出：
     声明 / ptr_match / empty / full / do_enq / do_deq / enq_ready / deq_valid / count / 出队切片；
     always 块整段与按（深度、指针名、pipe/flush）重建的模板逐字相等；
  2. ram 例化 8 个端口逐个核对（R0_addr=deq 指针、W0_addr=enq 指针、W0_en=do_enq、R0_en=1）；
     ram 模块的 Memory 深度/字宽与端口位宽一致；
  3. W0_data 拼接（含常量段）推出每个字段的 [hi:lo]，每条 io_deq_bits_* 的切片必须：
     同名字段 => 与拼接推出的区间逐位相等；无同名入队字段 => 完全落在常量段内；
  4. 由结构判出 DEPTH / pipe / flush / 是否有 io_count，写进薄文件的核参数；
  5. Pipeline_<n>：golden 体必须恰好是一个 Queue1_<X> stages_0 例化，in<->enq / out<->deq 逐口同名。
生成物幂等；--check 只比较不写（漂移 rc=1）。

用法：python3 scripts/gen_uncore_queues.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')

# 目标 -> (输出子目录, 父模块/实例, Scala 出处与一句话说明)
TLBUF = 'rocket-chip TLBuffer（BufferParams.default = Queue(entries=2, pipe=false, flow=false)）'
QUEUES = {
    'Queue2_TLBundleA_6':  ('uncore', 'TLBuffer_6.nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_7':  ('uncore', 'TLBuffer_7.nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_8':  ('uncore', 'ICacheBuffer.nodeOut_a_q{,_1}', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_10': ('uncore', 'ICacheCtrlBuffer / TLBuffer_20 .nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_12': ('uncore', 'InstrUncacheBuffer / TLBuffer_15 .nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_14': ('uncore', 'TLBuffer_8.nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_15': ('uncore', 'TLBuffer_9.nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_19': ('uncore', 'TLBuffer_13.nodeOut_a_q{,_1,_2,_3}', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleA_31': ('uncore', 'TLBuffer_22.nodeOut_a_q', TLBUF + ' 的 A 通道'),
    'Queue2_TLBundleB':    ('uncore', 'TLBuffer_7.nodeIn_b_q', TLBUF + ' 的 B 通道（probe）'),
    'Queue2_TLBundleB_1':  ('uncore', 'TLBuffer_13.nodeIn_b_q{,_1,_2,_3}', TLBUF + ' 的 B 通道（probe）'),
    'Queue2_TLBundleC':    ('uncore', 'TLBuffer_7.nodeOut_c_q', TLBUF + ' 的 C 通道（release/probeAck）'),
    'Queue2_TLBundleC_1':  ('uncore', 'TLBuffer_13.nodeOut_c_q{,_1,_2,_3}', TLBUF + ' 的 C 通道（release/probeAck）'),
    'Queue2_TLBundleD_7':  ('uncore', 'TLBuffer_6 / ICacheBuffer .nodeIn_d_q', TLBUF + ' 的 D 通道'),
    'Queue2_TLBundleD_8':  ('uncore', 'TLBuffer_7.nodeIn_d_q', TLBUF + ' 的 D 通道'),
    'Queue2_TLBundleD_11': ('uncore', 'ICacheCtrlBuffer / TLBuffer_20 / TLBuffer_22 .nodeIn_d_q', TLBUF + ' 的 D 通道'),
    'Queue2_TLBundleD_13': ('uncore', 'InstrUncacheBuffer / TLBuffer_15 .nodeIn_d_q', TLBUF + ' 的 D 通道'),
    'Queue2_TLBundleD_15': ('uncore', 'TLBuffer_8 / TLBuffer_9 .nodeIn_d_q', TLBUF + ' 的 D 通道'),
    'Queue2_TLBundleD_20': ('uncore', 'TLBuffer_13.nodeIn_d_q{,_1,_2,_3}', TLBUF + ' 的 D 通道'),
    'Queue2_TLBundleE':    ('uncore', 'TLBuffer_7.nodeOut_e_q', TLBUF + ' 的 E 通道（grantAck）'),
    'Queue2_TLBundleE_1':  ('uncore', 'TLBuffer_13.nodeOut_e_q{,_1,_2,_3}', TLBUF + ' 的 E 通道（grantAck）'),
    'Queue16_CHIREQ':      ('uncore', 'TXREQ.queue', 'coupledL2 tl2chi/TXREQ.scala:48 `Queue(new CHIREQ, entries = mshrsAll, flow = false)`：发往 CHI 的 REQ flit 缓冲'),
    'Queue16_CHIRSP':      ('uncore', 'TXRSP.queue', 'coupledL2 tl2chi/TXRSP.scala:48 `Queue(new CHIRSP, entries = mshrsAll, flow = false)`：发往 CHI 的 RSP flit 缓冲'),
    'Queue4_CHISNP':       ('uncore', 'LCredit2Decoupled.queue', 'coupledL2 tl2chi/chi/LinkLayer.scala:182 `Queue(gen, entries = lcreditNum, pipe = true, flow = false)`：链路层收到的 SNP flit 缓冲（L-credit 数 = 深度）'),
    'Queue40_L2TlbMQBundle': ('memblock', 'L2TlbMissQueue.io_out_q', 'xiangshan mmu L2TLBMissQueue.scala `Queue(io.in, MissQueueSize, flush = Some(...))`：L2TLB miss 回灌队列（40 项、带 flush）'),
    'Queue78_PCrdGranted': ('uncore', 'TL2CHICoupledL2.pCrdQueue_s2', 'coupledL2 tl2chi/TL2CHICoupledL2.scala:189 `Queue(new PCrdGranted, entries = mshrEntryCount - 2)`：P-credit 授予记录的第一级缓冲（78 项）'),
    'Queue2_PCrdGranted':  ('uncore', 'TL2CHICoupledL2.pCrdQueue_s3', 'coupledL2 tl2chi/TL2CHICoupledL2.scala:190 `Queue(new PCrdGranted, entries = 2)`：P-credit 授予记录的第二级（供 MSHR 比对的队头）'),
}

PIPELINES = {
    'Pipeline_12': ('uncore', 'Queue1_CHIDAT', 'TL2CHICoupledL2.rxdatPipe_pipeline',
                    'coupledL2 tl2chi/TL2CHICoupledL2.scala:268 `Pipeline(linkMonitor.io.in.rx.dat)`：RXDAT 打一拍'),
    'Pipeline_13': ('uncore', 'Queue1_CHIRSP', 'TL2CHICoupledL2.rxrspPipe_pipeline',
                    'coupledL2 tl2chi/TL2CHICoupledL2.scala:269 `Pipeline(linkMonitor.io.in.rx.rsp)`：RXRSP 打一拍'),
}


class GenError(Exception):
    pass


def need(cond, msg):
    if not cond:
        raise GenError(msg)


def ports(txt, mod):
    i = txt.index('module %s(' % mod)
    j = txt.index('\n);', i)
    out = []
    for line in txt[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        need(m, '%s: 认不出端口行 %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


def strip_body(txt, mod):
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)) + 3:]
    body, n = re.subn(r'\n\s*`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_', '', body, flags=re.S)
    need(n <= 1, '%s: 多个 ENABLE_INITIAL_REG_ 段' % mod)
    need(body.rstrip().endswith('endmodule'), '%s: 体尾不是 endmodule' % mod)
    body = body.rstrip()[:-len('endmodule')]
    need('`' not in body, '%s: 初始化段之外还有宏/条件编译' % mod)
    return body


def always_template(E, D, depth, pw, flush, dq='do_deq'):
    """按 firtool 对 chisel Queue 控制寄存器的输出形状重建 always 块（归一空白后逐字比）。
    dq：出队 fire 的表达式；父模块把 deq.ready 钉成 1 时 firtool 删了 io_deq_ready 端口，
    do_deq 被内联成 `~empty`。"""
    def bump(p):
        c = 'do_enq' if p == E else dq
        if depth == 2:
            return ['if (%s)' % c, '%s <= 1\'(%s - 1\'h1);' % (p, p)]
        if depth & (depth - 1) == 0:
            return ['if (%s)' % c, "%s <= %d'(%s + %d'h1);" % (p, pw, p, pw)]
        return ['if (%s) begin' % c,
                "if (%s == %d'h%X)" % (p, pw, depth - 1), "%s <= %d'h0;" % (p, pw),
                'else', "%s <= %d'(%s + %d'h1);" % (p, pw, p, pw), 'end']
    zero = "1'h0" if depth == 2 else "%d'h0" % pw
    L = ['always @(posedge clock or posedge reset) begin', 'if (reset) begin',
         '%s <= %s;' % (E, zero), '%s <= %s;' % (D, zero), "maybe_full <= 1'h0;", 'end', 'else begin']
    if flush:
        L += ['if (io_flush) begin', '%s <= %s;' % (E, zero), '%s <= %s;' % (D, zero), 'end', 'else begin']
        L += bump(E) + bump(D) + ['end',
              'maybe_full <= ~io_flush & (do_enq == %s ? maybe_full : do_enq);' % dq]
    else:
        L += bump(E) + bump(D) + ['if (~(do_enq == %s))' % dq, 'maybe_full <= do_enq;']
    L += ['end', 'end // always @(posedge, posedge)']
    return norm(' '.join(L))


def parse_queue(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    W = {n: w for _, w, n in P}
    D_ = {n: d for d, _, n in P}
    body = strip_body(txt, mod)

    # ---- ram 例化（恰好一个）----
    rams = list(re.finditer(r'\n(\s+)(ram_\w+) (\w+) \(\n(.*?)\n\1\);', body, re.S))
    need(len(rams) == 1, '%s: ram 例化数 %d != 1' % (mod, len(rams)))
    rm = rams[0]
    ram_mod, ram_inst, conns = rm.group(2), rm.group(3), rm.group(4)
    body = body[:rm.start()] + '\n' + body[rm.end():]
    k = conns.index('.W0_data')
    simple, wdat = conns[:k], conns[k:]
    C = {}
    for line in simple.strip().splitlines():
        m = re.fullmatch(r'\s*\.(\w+)\s+\((.*)\),', line)
        need(m, '%s: 认不出 ram 连线 %r' % (mod, line))
        C[m.group(1)] = m.group(2).strip()
    m = re.fullmatch(r'\.W0_data\s+\((.*)\)', norm(wdat), re.S)
    need(m, '%s: 认不出 W0_data' % mod)
    w = m.group(1).strip()
    if w.startswith('('):
        need(w.endswith(')'), mod)
        w = w[1:-1].strip()
    items = [x.strip() for x in w[1:-1].split(',')] if w.startswith('{') else [w]
    need(set(C) == {'R0_addr', 'R0_en', 'R0_clk', 'R0_data', 'W0_addr', 'W0_en', 'W0_clk'},
         '%s: ram 端口集合 %s' % (mod, sorted(C)))

    # ---- ram 模块：深度 / 字宽 / 地址宽 ----
    rtxt = open(os.path.join(G, ram_mod + '.sv')).read()
    md = re.search(r'reg \[(\d+):0\] Memory\[0:(\d+)\];', rtxt)
    need(md, '%s: 认不出 Memory 声明' % ram_mod)
    word_w, depth = int(md.group(1)) + 1, int(md.group(2)) + 1
    rP = {n: wd for _, wd, n in ports(rtxt, ram_mod)}
    pw = max(1, (depth - 1).bit_length())
    need(rP['R0_addr'] == pw and rP['W0_addr'] == pw, '%s: 地址宽 %d != %d' % (ram_mod, rP['R0_addr'], pw))
    need(rP['R0_data'] == word_w and rP['W0_data'] == word_w, ram_mod)

    # ---- W0_data 布局（msb 在前，含常量段）----
    layout, hi = [], word_w
    for it in items:
        z = re.fullmatch(r"(\d+)'h([0-9A-F]+)", it)
        if z:
            wd, val = int(z.group(1)), int(z.group(2), 16)
            need(val < (1 << wd), mod)
            layout.append(('const', wd, val, hi - 1, hi - wd))
        else:
            need(re.fullmatch(r'io_enq_bits_\w+', it) and D_.get(it) == 'input', '%s: W0_data 项 %r' % (mod, it))
            wd = W[it]
            layout.append(('field', wd, it[len('io_enq_bits_'):], hi - 1, hi - wd))
        hi -= wd
    need(hi == 0, '%s: W0_data 总宽 != %d' % (mod, word_w))
    frng = {f: (h, l) for kind, _, f, h, l in layout if kind == 'field'}
    need(len(frng) == sum(1 for x in layout if x[0] == 'field'), '%s: 字段重复' % mod)

    # ---- 寄存器与指针名 ----
    regs = re.findall(r'\n\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body)
    need([r[1] for r in regs][2:] == ['maybe_full'] and len(regs) == 3, '%s: 寄存器 %s' % (mod, regs))
    E, D = regs[0][1], regs[1][1]
    need((E, D) in (('wrap', 'wrap_1'), ('enq_ptr_value', 'deq_ptr_value')), '%s: 指针名 %s/%s' % (mod, E, D))
    need((depth == 2) == (E == 'wrap'), mod)
    for r in regs[:2]:
        need((int(r[0]) + 1 if r[0] else 1) == pw, '%s: 指针宽' % mod)
    need(C['R0_addr'] == D and C['W0_addr'] == E and C['W0_en'] == 'do_enq' and C['R0_en'] == "1'h1"
         and C['R0_clk'] == 'clock' and C['W0_clk'] == 'clock', '%s: ram 连线 %s' % (mod, C))
    rd = C['R0_data']

    # ---- always 块 ----
    flush = 'io_flush' in W
    deq_ready_port = 'io_deq_ready' in W
    dq = 'do_deq' if deq_ready_port else '~empty'
    am = re.search(r'\n\s*(always @\(posedge clock or posedge reset\) begin.*?end // always @\(posedge, posedge\))', body, re.S)
    need(am, '%s: 没有 always 块' % mod)
    tpl = always_template(E, D, depth, pw, flush, dq)
    need(norm(am.group(1)) == tpl, '%s: always 块与模板不等\n  golden: %s\n  模板:   %s' % (mod, norm(am.group(1)), tpl))
    body = body[:am.start()] + '\n' + body[am.end():]
    need(body.count('always') == 0, '%s: 还有别的 always' % mod)

    # ---- 其余每一行都要认出来 ----
    pipe = False
    has_count = False
    deq = {}
    ready_wire = None
    seen = set()
    for raw in body.splitlines():
        s = norm(raw)
        if not s:
            continue
        m = re.fullmatch(r'reg (?:\[\d+:0\] )?\w+;', s)
        if m:
            continue  # 已核
        m = re.fullmatch(r'wire (?:\[(\d+):0\] )?(\w+);', s)
        if m:
            n = m.group(2)
            if n == rd:
                need(int(m.group(1)) + 1 == word_w, mod)
            elif n in ('io_enq_ready', 'io_enq_ready_0'):
                ready_wire = n
            else:
                raise GenError('%s: 未知 wire 声明 %r' % (mod, s))
            continue
        fixed = {
            'wire ptr_match = %s == %s;' % (E, D): 'ptr_match',
            'wire empty = ptr_match & ~maybe_full;': 'empty',
            'wire full = ptr_match & maybe_full;': 'full',
            'wire do_enq = ~full & io_enq_valid;': 'do_enq',
            'wire do_enq = io_enq_ready & io_enq_valid;': 'do_enq',
            'wire do_enq = io_enq_ready_0 & io_enq_valid;': 'do_enq',
            'wire do_deq = io_deq_ready & ~empty;': 'do_deq',
            'assign io_enq_ready = ~full;': 'enq_ready',
            'assign io_enq_ready = ~(ptr_match & maybe_full);': 'enq_ready',
            'assign io_enq_ready_0 = io_deq_ready | ~(ptr_match & maybe_full);': 'enq_ready0_pipe',
            'assign io_enq_ready = io_enq_ready_0;': 'enq_ready',
            'assign io_deq_valid = ~empty;': 'deq_valid',
        }
        # golden 里 wire 声明带对齐空格：`wire        ptr_match = ...` 已被 norm 压成单空格；带位宽的也剥掉
        s2 = re.sub(r'^wire \[\d+:0\] ', 'wire ', s)
        if s2 in fixed:
            tag = fixed[s2]
            need(tag not in seen, '%s: %s 出现两次' % (mod, tag))
            seen.add(tag)
            if tag == 'enq_ready0_pipe':
                pipe = True
            continue
        if depth & (depth - 1) == 0 and s == 'assign io_count = {maybe_full & ptr_match, %d\'(%s - %s)};' % (pw, E, D):
            has_count = True
            continue
        m = re.fullmatch(r'assign (io_deq_bits_\w+) = %s(?:\[(\d+)(?::(\d+))?\])?;' % re.escape(rd), s)
        if m:
            n = m.group(1)
            need(D_.get(n) == 'output' and n not in deq, '%s: %s' % (mod, n))
            h = int(m.group(2)) if m.group(2) else word_w - 1
            l = int(m.group(3)) if m.group(3) else (h if m.group(2) else 0)
            deq[n] = (h, l)
            continue
        raise GenError('%s: golden 里有模板外的行：%r' % (mod, s))

    # ---- 控制形状一致性 ----
    req = {'ptr_match', 'empty', 'do_enq'}
    req |= {'do_deq'} if deq_ready_port else set()
    req |= {'enq_ready'} if 'io_enq_ready' in W else set()
    req |= {'deq_valid'} if 'io_deq_valid' in W else set()
    need(req <= seen, '%s: 缺 %s' % (mod, req - seen))
    need(deq_ready_port or 'do_deq' not in seen, mod)
    need('io_enq_valid' in W, '%s: 没有 io_enq_valid' % mod)
    if pipe:
        need(ready_wire == 'io_enq_ready_0', mod)
    need(not (pipe and flush), mod)
    if rd.startswith('io_deq_bits_'):     # ram 读口直接接输出（单字段）
        need(len(layout) == 1 and layout[0][0] == 'field' and D_.get(rd) == 'output' and not deq, mod)
        deq[rd] = (word_w - 1, 0)
    else:
        need(re.fullmatch(r'_\w+_R0_data', rd) is not None, '%s: R0_data 线名 %s' % (mod, rd))
    # 每个输出端口都恰好被驱动一次
    outs = [n for d, _, n in P if d == 'output']
    for n in outs:
        need(n in deq or n in ('io_enq_ready', 'io_deq_valid') or (n == 'io_count' and has_count),
             '%s: 输出 %s 没有驱动' % (mod, n))
    need(('io_count' in W) == has_count, mod)

    # ---- 出队切片 vs 入队拼接 ----
    consts = [(h, l) for kind, _, _, h, l in layout if kind == 'const']
    for n, (h, l) in deq.items():
        f = n[len('io_deq_bits_'):]
        need(h - l + 1 == W[n], '%s: %s 宽 %d != %d' % (mod, n, h - l + 1, W[n]))
        if f in frng:
            need(frng[f] == (h, l), '%s: %s 切片 [%d:%d] != 拼接推出的 %s' % (mod, n, h, l, frng[f]))
        else:
            need(any(cl <= l and h <= ch for ch, cl in consts), '%s: %s [%d:%d] 既不是入队字段也不在常量段' % (mod, n, h, l))
    return dict(mod=mod, P=P, ram_mod=ram_mod, ram_inst=ram_inst, depth=depth, word_w=word_w, pw=pw,
                layout=layout, deq=deq, pipe=pipe, flush=flush, has_count=has_count,
                deq_ready_port=deq_ready_port, lines=len(txt.splitlines()), W=W)


def port_block(P):
    return ',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P)


def emit_queue(R):
    m = R['mod']
    sub, parent, what = QUEUES[m]
    L = []
    A = L.append
    kind = 'flush' if R['flush'] else ('pipe' if R['pipe'] else 'plain')
    A('// %s.sv —— %s' % (m, what))
    A('//')
    A('// chisel3 Queue(entries=%d, pipe=%s, flow=false%s) 的单态化；例化处：%s。' % (
        R['depth'], 'true' if R['pipe'] else 'false', ', flush' if R['flush'] else '', parent))
    if kind == 'plain':
        A('// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；')
    elif kind == 'pipe':
        A('// 控制逻辑在 rtl/uncore/xs_ChiselQueuePipe_core.sv（pipe=true：满队列只要出口在接，入口照样 ready）；')
    else:
        A('// 控制+存储都在已签的 xs_L2TlbMissQueue_core（rtl/memblock/L2TlbMissQueue.sv，40 项、flush 一拍清空）；')
    if R['depth'] & (R['depth'] - 1):
        A('// 存储叶子 %s（%d 项 x %d 位；深度非 2 的幂 —— FM 边界须按 verif/vendor_boundary.tsv 逐父级审定）。' % (
            R['ram_mod'], R['depth'], R['word_w']))
    else:
        A('// 存储是 golden 的 %s 行为级叶子（%d 项 x %d 位，两侧同源 inline）。' % (R['ram_mod'], R['depth'], R['word_w']))
    A('// 本文件只做字段拼接/拆分。ram 字（lsb 起）：')
    seg = []
    for kind_, wd, f, h, l in reversed(R['layout']):
        seg.append(('%s[%d:%d]' % (f, h, l)) if kind_ == 'field' else ("%d'h%X[%d:%d]" % (wd, f, h, l)))
    line = '//  '
    for s in seg:
        if len(line) + len(s) + 2 > 110:
            A(line)
            line = '//  '
        line += ' ' + s
    A(line)
    if any(x[0] == 'const' for x in R['layout']):
        A('// 常量段：父模块入队时恒为常量的 Bundle 字段（firtool 删了入口端口，把常量直接拼进 ram 字）；')
        A('//   出队时照样从 ram 读出 —— 上电后第一次入队之前它们是 ram 的初值，照 golden 保留，不省。')
    enq_only = [n for d, _, n in R['P'] if n.startswith('io_enq_bits_')
                and n[len('io_enq_bits_'):] not in {x[2] for x in R['layout'] if x[0] == 'field'}]
    if enq_only:
        A('// 入队端口 %s 没有存进 ram（出队侧无读者，firtool 删了存储但留了端口），这里同样只留端口。' % ', '.join(enq_only))
    unread = [x[2] for x in R['layout'] if x[0] == 'field' and 'io_deq_bits_' + x[2] not in R['deq']]
    if unread:
        A('// 存进 ram 但出队侧没有端口的字段：%s（两侧对称的未读存储位）。' % ', '.join(unread))
    A('// golden %d 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。' % R['lines'])
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_uncore_queues.py' % m)
    A('module %s (' % m)
    A(port_block(R['P']))
    A(');')
    A('')
    concat = ', '.join(('io_enq_bits_' + f) if k == 'field' else ("%d'h%X" % (wd, f)) for k, wd, f, _, _ in R['layout'])
    if kind == 'flush':
        # 复用的核必须正是这个队列：40 项、47 位字、例化同名 ram（实例名与 golden 同，UT 的 Memory 同步路径靠它）
        core = open(os.path.join(REPO, 'rtl', 'memblock', 'L2TlbMissQueue.sv')).read()
        need(re.search(r'localparam int DEPTH\s*=\s*%d;' % R['depth'], core) and
             re.search(r'\n  %s %s \(' % (R['ram_mod'], R['ram_inst']), core) and
             'module xs_L2TlbMissQueue_core' in core and R['word_w'] == 47,
             '%s: xs_L2TlbMissQueue_core 与 golden 队列参数不符' % m)
        A('  logic [%d:0] ramReadWord;' % (R['word_w'] - 1))
        A('')
        A('  xs_L2TlbMissQueue_core u_core (')
        A('    .clock     (clock),')
        A('    .reset     (reset),')
        A('    .flush     (io_flush),')
        A('    .enq_valid (io_enq_valid),')
        A('    .enq_ready (io_enq_ready),')
        A('    .enq_bits  ({%s}),' % concat)
        A('    .deq_valid (io_deq_valid),')
        A('    .deq_ready (io_deq_ready),')
        A('    .deq_bits  (ramReadWord)')
        A('  );')
    else:
        cw = R['depth'].bit_length()
        A('  logic       do_enq;')
        A('  logic [%d:0] enq_ptr, deq_ptr;' % (R['pw'] - 1))
        A('  logic       empty;')
        A('  logic [%d:0] count;' % (cw - 1))
        A('  logic       enq_ready, deq_valid;')
        A('  logic [%d:0] ramReadWord;' % (R['word_w'] - 1))
        A('')
        if kind == 'pipe':
            A('  xs_ChiselQueuePipe_core #(.DEPTH(%d)) u_core (' % R['depth'])
        else:
            A("  xs_ChiselQueue_core #(.DEPTH(%d), .FLOW(1'b0)) u_core (" % R['depth'])
        for a, b in (('clock', 'clock'), ('reset', 'reset'), ('enq_valid', 'io_enq_valid'), ('enq_ready', 'enq_ready'),
                     ('deq_valid', 'deq_valid'), ('deq_ready', 'io_deq_ready' if R['deq_ready_port'] else "1'b1"),
                     ('do_enq', 'do_enq'),
                     ('enq_ptr', 'enq_ptr'), ('deq_ptr', 'deq_ptr'), ('empty', 'empty')):
            A('    .%-9s (%s),' % (a, b))
        A('    .count     (count)')
        A('  );')
        A('')
        A('  // 存储：写口在 enq_ptr、读口恒使能读 deq_ptr（组合读）')
        A('  %s %s (' % (R['ram_mod'], R['ram_inst']))
        A('    .R0_addr (deq_ptr),')
        A("    .R0_en   (1'b1),")
        A('    .R0_clk  (clock),')
        A('    .R0_data (ramReadWord),')
        A('    .W0_addr (enq_ptr),')
        A('    .W0_en   (do_enq),')
        A('    .W0_clk  (clock),')
        A('    .W0_data ({%s})' % concat)
        A('  );')
        A('')
        if 'io_enq_ready' in R['W']:
            A('  assign io_enq_ready = enq_ready;')
        if 'io_deq_valid' in R['W']:
            A('  assign io_deq_valid = deq_valid;')
        if R['has_count']:
            A('  assign io_count     = count;')
    A('')
    for n, _, _ in [(n, 0, 0) for d, _, n in R['P'] if n in R['deq']]:
        h, l = R['deq'][n]
        src = 'ramReadWord' if (h, l) == (R['word_w'] - 1, 0) else (
            'ramReadWord[%d]' % h if h == l else 'ramReadWord[%d:%d]' % (h, l))
        A('  assign %s = %s;' % (n, src))
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def parse_pipeline(mod, child):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    body = strip_body(txt, mod)
    m = re.fullmatch(r'\s*%s stages_0 \(\n(.*?)\n  \);\s*' % child, body, re.S)
    need(m, '%s: 体不是恰好一个 %s stages_0 例化' % (mod, child))
    cP = ports(open(os.path.join(G, child + '.sv')).read(), child)
    conns = []
    for line in m.group(1).splitlines():
        c = re.fullmatch(r'\s*\.(\w+)\s+\((\w+)\),?', line)
        need(c, '%s: 连线 %r' % (mod, line))
        conns.append((c.group(1), c.group(2)))
    need([c[0] for c in conns] == [n for _, _, n in cP], '%s: 子端口顺序/集合' % mod)
    mp = {'clock': 'clock', 'reset': 'reset'}
    for cn, pn in conns:
        exp = mp.get(cn) or re.sub(r'^io_enq_', 'io_in_', re.sub(r'^io_deq_', 'io_out_', cn))
        need(pn == exp, '%s: %s 接 %s，期望 %s' % (mod, cn, pn, exp))
    need(sorted(pn for _, pn in conns) == sorted(n for _, _, n in P), '%s: 端口未全接' % mod)
    pw = {n: w for _, w, n in P}
    for _, w, n in cP:
        need(pw[dict(conns)[n]] == w, '%s: %s 位宽' % (mod, n))
    return dict(mod=mod, P=P, child=child, conns=conns, lines=len(txt.splitlines()))


def emit_pipeline(R):
    m = R['mod']
    sub, child, parent, what = PIPELINES[m]
    L = []
    A = L.append
    A('// %s.sv —— %s' % (m, what))
    A('//')
    A('// utility.Pipeline(gen, depth = 1, pipe = true) 的单态化；例化处：%s。' % parent)
    A('//   utility/Pipeline.scala：depth 个 Queue(gen, entries = 1, pipe = true, flow = false) 首尾相接。')
    A('// 本模块没有自己的逻辑：唯一一级就是已签核的深度 1 队列 %s（rtl/uncore/%s.sv，' % (child, child))
    A('// 控制+存储在共享核 rtl/common/xs_ChiselQueue1_core.sv），这里按 golden 实例名 stages_0 接上，')
    A('// io_in_* -> io_enq_*、io_deq_* -> io_out_* 逐口同名。')
    A('// golden %d 行；由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐口校验。' % R['lines'])
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_uncore_queues.py' % m)
    A('module %s (' % m)
    A(port_block(R['P']))
    A(');')
    A('')
    A('  %s stages_0 (' % child)
    w = max(len(c) for c, _ in R['conns'])
    A(',\n'.join('    .%s (%s)' % (c.ljust(w), p) for c, p in R['conns']))
    A('  );')
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    jobs = []
    try:
        for q, (sub, _, _) in QUEUES.items():
            R = parse_queue(q)
            txt = emit_queue(R)
            jobs.append((q, sub, txt,
                         'depth=%-2d pipe=%d flush=%d word=%-3d fields=%d const=%d deq=%d count=%d' % (
                             R['depth'], R['pipe'], R['flush'], R['word_w'],
                             sum(1 for x in R['layout'] if x[0] == 'field'),
                             sum(1 for x in R['layout'] if x[0] == 'const'), len(R['deq']), R['has_count'])))
        for p, (sub, child, _, _) in PIPELINES.items():
            R = parse_pipeline(p, child)
            jobs.append((p, sub, emit_pipeline(R), 'stages_0=%s conns=%d' % (child, len(R['conns']))))
    except GenError as e:
        print('FAIL: %s' % e, file=sys.stderr)
        return 2
    for name, sub, txt, info in jobs:
        p = os.path.join(REPO, 'rtl', sub, name + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-24s %s' % (name, info))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
