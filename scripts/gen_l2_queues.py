#!/usr/bin/env python3
"""gen_l2_queues.py —— 从 G1 golden 生成 coupledL2 用到的 chisel Queue 单态化薄文件。

每个 Queue<N>_<Bundle> = 共享控制核 rtl/common/xs_ChiselQueue_core.sv + 一块 golden 的
ram_<D>x<W>（firtool 行为级存储叶子，两侧同源 inline）+ 字段拼/拆连线。本脚本只做连线：

  1. 解析 golden：端口表、ram 例化（模块名/实例名/W0_data 的字段拼接顺序）、每个
     io_deq_bits_* 的来源（ram 字的哪一段、flow 时的 `empty ? io_enq_bits_* :` 旁路）；
  2. 由结构判出 DEPTH（ram 深度）与 FLOW（deq_valid 是否含 io_enq_valid）；
  3. **机器校验**：W0_data 拼接顺序推出的每个字段的 [hi:lo] 必须与 deq 赋值里的切片逐字段
     相等；golden 里每条 assign 都必须被识别，剩一条就报错（证明 golden 里没有模板外的逻辑）；
  4. 写出 rtl/uncore/<Q>.sv（幂等）；--check 只比较不写。

用法：python3 scripts/gen_l2_queues.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'uncore')

# 目标 -> (在哪个父模块里用、一句话说明)
QUEUES = {
    'Queue16_DSBeat':         ('TXDAT',       'TXDAT 的数据队列（queueData0/1 各存一个 256 位 beat），flow'),
    'Queue16_TaskBundle':     ('TXDAT',       'TXDAT 的任务队列：只留下拼 CHI DAT 报文要用的 10 个字段，flow'),
    'Queue2_CHISNP':          ('RXSNP',       'RXSNP 入口的 2 项 snoop 缓冲'),
    'Queue16_GrantQueueTask': ('GrantBuffer', 'GrantBuffer 的 grant 任务队列（D 通道报文头）'),
    'Queue16_GrantQueueData': ('GrantBuffer', 'GrantBuffer 的 grant 数据队列（两份，各存一个 beat）'),
}


def ports(txt, mod):
    i = txt.index('module %s(' % mod)
    j = txt.index('\n);', i)
    out = []
    for line in txt[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def parse(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    names = {n for _, _, n in P}
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    body = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '\n', body, flags=re.S)
    m = re.search(r'\n  (ram_\w+) (\w+) \((.*?)\n  \);', body, re.S)
    assert m, mod + ': 没找到 ram 例化'
    ram_mod, ram_inst, conns = m.group(1), m.group(2), m.group(3)
    rtxt = open(os.path.join(G, ram_mod + '.sv')).read()
    md = re.search(r'reg \[(\d+):0\] Memory\[0:(\d+)\];', rtxt)
    word_w, depth = int(md.group(1)) + 1, int(md.group(2)) + 1
    wd = re.search(r'\.W0_data\s*\(\s*(.*?)\s*\)\s*$', conns, re.S)
    wtxt = re.sub(r'\s+', '', wd.group(1))
    fields = [f[len('io_enq_bits_'):] for f in wtxt.strip('{}').split(',')]
    W = {n[len('io_enq_bits_'):]: w for d, w, n in P if n.startswith('io_enq_bits_')}
    # 拼接是 msb 在前：从最后一个字段（lsb）往上排
    rng, lo = {}, 0
    for f in reversed(fields):
        rng[f] = (lo + W[f] - 1, lo)
        lo += W[f]
    assert lo == word_w, '%s: 字段总宽 %d != ram 字宽 %d' % (mod, lo, word_w)
    rd = re.search(r'\.R0_data\s*\((\w+)\)', conns).group(1)
    flow = bool(re.search(r'\(?io_enq_valid \| ~empty\)?', body))   # deq_valid（或被内联进 do_deq）含 enq_valid 即 flow
    # 逐条 deq 赋值核对切片
    deq = {}
    for d, w, n in P:
        if d != 'output' or not n.startswith('io_deq_bits_'):
            continue
        f = n[len('io_deq_bits_'):]
        if rd == n:          # ram 读口直接接到输出（单字段、无 flow）
            assert fields == [f] and not flow
            deq[f] = 'direct'
            continue
        a = re.search(r'assign %s =\s*(.*?);' % re.escape(n), body, re.S)
        assert a, '%s: 没有 %s 的赋值' % (mod, n)
        e = re.sub(r'\s+', ' ', a.group(1))
        sl = r'%s(?:\[(\d+)(?::(\d+))?\])?' % re.escape(rd)
        mm = re.fullmatch((r'empty \? io_enq_bits_%s : ' % re.escape(f) if flow else '') + sl, e)
        assert mm, '%s: %s 的赋值不是模板形状: %s' % (mod, n, e)
        hi = int(mm.group(1)) if mm.group(1) else word_w - 1
        lo_ = int(mm.group(2)) if mm.group(2) else (hi if mm.group(1) else 0)
        assert (hi, lo_) == rng[f], '%s: %s 切片 [%d:%d] != 拼接推出的 %s' % (mod, n, hi, lo_, rng[f])
        deq[f] = rng[f]
    has = lambda n: n in names
    cnt = re.search(r'assign io_count =', body) is not None
    return dict(mod=mod, P=P, ram_mod=ram_mod, ram_inst=ram_inst, depth=depth, word_w=word_w,
                fields=fields, rng=rng, flow=flow, deq=deq, has_enq_ready=has('io_enq_ready'),
                has_deq_valid=has('io_deq_valid'), has_count=cnt,
                lines=len(txt.splitlines()))


def emit(R):
    m = R['mod']
    parent, what = QUEUES[m]
    L = []
    A = L.append
    A('// %s.sv —— %s' % (m, what))
    A('//')
    A('// chisel3 Queue(entries=%d, flow=%s) 的单态化（父模块 %s）。控制逻辑全在' % (R['depth'], 'true' if R['flow'] else 'false', parent))
    A('// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 %s 行为级' % R['ram_mod'])
    A('// 存储叶子（%d 项 x %d 位，两侧同源 inline）。本文件只做字段拼接/拆分：' % (R['depth'], R['word_w']))
    A('//   ram 字（lsb 起）：' + '  '.join('%s[%d:%d]' % (f, R['rng'][f][0], R['rng'][f][1]) for f in reversed(R['fields'])))
    unused = [f for f in R['fields'] if f not in R['deq']]
    enq_only = [n[len('io_enq_bits_'):] for d, w, n in R['P'] if n.startswith('io_enq_bits_') and n[len('io_enq_bits_'):] not in R['fields']]
    if enq_only:
        A('// 另有 %d 个 io_enq_bits_* 端口在 golden 里没有被存进 ram（父模块出队时用不到，firtool' % len(enq_only))
        A('// 删掉了存储但保留了端口），这里同样只留端口、不接任何东西。')
    A('// golden %d 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。' % R['lines'])
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_l2_queues.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in R['P']))
    A(');')
    A('')
    pw = max(1, (R['depth'] - 1).bit_length())
    cw = R['depth'].bit_length()
    A('  logic             do_enq;')
    A('  logic [%d:0]       enq_ptr, deq_ptr;' % (pw - 1))
    A('  logic             empty;')
    A('  logic [%d:0]       count;' % (cw - 1))
    A('  logic             enq_ready, deq_valid;')
    A('  logic [%d:0] ramReadWord;' % (R['word_w'] - 1))
    A('')
    A('  xs_ChiselQueue_core #(.DEPTH(%d), .FLOW(1\'b%d)) u_core (' % (R['depth'], 1 if R['flow'] else 0))
    A('    .clock     (clock),')
    A('    .reset     (reset),')
    A('    .enq_valid (io_enq_valid),')
    A('    .enq_ready (enq_ready),')
    A('    .deq_valid (deq_valid),')
    A('    .deq_ready (io_deq_ready),')
    A('    .do_enq    (do_enq),')
    A('    .enq_ptr   (enq_ptr),')
    A('    .deq_ptr   (deq_ptr),')
    A('    .empty     (empty),')
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
    A('    .W0_data ({%s})' % ', '.join('io_enq_bits_' + f for f in R['fields']))
    A('  );')
    A('')
    if R['has_enq_ready']:
        A('  assign io_enq_ready = enq_ready;')
    if R['has_deq_valid']:
        A('  assign io_deq_valid = deq_valid;')
    if R['has_count']:
        A('  assign io_count     = count;')
    if R['flow']:
        A('  // flow：队列空时 enq 数据直接旁路到 deq')
    for f in R['fields']:
        if f not in R['deq']:
            continue
        hi, lo = R['rng'][f]
        src = 'ramReadWord' if (hi, lo) == (R['word_w'] - 1, 0) else ('ramReadWord[%d]' % hi if hi == lo else 'ramReadWord[%d:%d]' % (hi, lo))
        A('  assign io_deq_bits_%s = %s%s;' % (f, 'empty ? io_enq_bits_%s : ' % f if R['flow'] else '', src))
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


# 单项队列（entries=1）：firtool 不生成指针、不例化 ram 叶子，只有 full + 一个整字寄存器 ram
QUEUES1 = {
    'Queue1_ChosenQBundle': ('RequestBuffer', 'RequestBuffer 的 chosenQ：仲裁出的那一项（含 buffer 下标 id）在此等 MainPipe 收，pipe'),
}


def parse1(mod):
    """单项队列：解析 `ram <= {拼接}` 与每条 io_deq_bits_* 的切片，并逐项校验。"""
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    m = re.search(r'reg\s+\[(\d+):0\]\s+ram;', body)
    word_w = int(m.group(1)) + 1
    pipe = 'assign io_enq_ready_0 = io_deq_ready | ~full;' in body
    assert pipe or 'assign io_enq_ready_0 = ~full;' in body, mod
    cm = re.search(r'ram <=\s*\{(.*?)\};', body, re.S)
    items = [x.strip() for x in re.sub(r'\s+', ' ', cm.group(1)).split(',')]
    W = {n: w for _, w, n in P}
    layout, hi = [], word_w
    for it in items:
        z = re.fullmatch(r"(\d+)'h0", it)
        w = int(z.group(1)) if z else W[it]
        layout.append((it, hi - 1, hi - w))
        hi -= w
    assert hi == 0, '%s: 拼接总宽 != %d' % (mod, word_w)
    enq_rng = {it[len('io_enq_bits_'):]: (a, b) for it, a, b in layout if it.startswith('io_enq_bits_')}
    zero = [(a, b) for it, a, b in layout if not it.startswith('io_enq_bits_')]
    deq = []
    for d, w, n in P:
        if d != 'output' or not n.startswith('io_deq_bits_'):
            continue
        f = n[len('io_deq_bits_'):]
        a = re.search(r'assign %s = ram\[(\d+)(?::(\d+))?\];' % re.escape(n), body)
        assert a, '%s: %s 不是 ram 切片' % (mod, n)
        rh, rl = int(a.group(1)), int(a.group(2) or a.group(1))
        assert rh - rl + 1 == w, (mod, n)
        if f in enq_rng:
            assert enq_rng[f] == (rh, rl), '%s: %s 切片与入队拼接不一致' % (mod, n)
        else:
            assert any(zl <= rl and rh <= zh for zh, zl in zero), '%s: %s 既不是入队字段也不在补零段' % (mod, n)
        deq.append((n, rh, rl, f in enq_rng))
    unread = [f for f in enq_rng if 'io_deq_bits_' + f not in {n for n, *_ in deq}]
    return dict(mod=mod, P=P, word_w=word_w, pipe=pipe, layout=layout, deq=deq, unread=unread,
                lines=len(txt.splitlines()))


def emit1(R):
    m = R['mod']
    parent, what = QUEUES1[m]
    L = []
    A = L.append
    A('// %s.sv —— %s' % (m, what))
    A('//')
    A('// chisel3 Queue(entries=1, pipe=%s, flow=false) 的单态化（父模块 %s）。控制与存储在' % ('true' if R['pipe'] else 'false', parent))
    A('// rtl/common/xs_ChiselQueue1_core.sv；本文件只把 Bundle 字段按 golden 的顺序拼成 %d 位字、再拆回来。' % R['word_w'])
    A('// ★照 golden 保留的两类"没用的位"★：')
    A('//   * 补零段：入队时恒为 0 的 TaskBundle 字段（SinkA 送来的 A 请求里这些字段是常量 0），golden 仍占着 ram 的位，')
    A('//     出队时照样从 ram 读出（上电后第一次入队之前它们是 ram 的初值）；')
    A('//   * 出队没人要的字段：%s —— 存进 ram 但无读者（FM 里两侧对称的未读位）。' % ', '.join(R['unread']))
    A('// golden %d 行；由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。' % R['lines'])
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_l2_queues.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in R['P']))
    A(');')
    A('')
    A('  logic [%d:0] enqWord, deqWord;' % (R['word_w'] - 1))
    A('')
    A('  // 入队字（高位在前；补零段是恒 0 的 Bundle 字段）')
    A('  assign enqWord = {')
    A(',\n'.join('    %s' % ("%d'h0" % (a - b + 1) if not it.startswith('io_enq_bits_') else it) for it, a, b in R['layout']))
    A('  };')
    A('')
    A("  xs_ChiselQueue1_core #(.W(%d), .PIPE(1'b%d)) u_core (" % (R['word_w'], 1 if R['pipe'] else 0))
    A('    .clock     (clock),')
    A('    .reset     (reset),')
    A('    .enq_valid (io_enq_valid),')
    A('    .enq_ready (io_enq_ready),')
    A('    .enq_word  (enqWord),')
    A('    .deq_valid (io_deq_valid),')
    A('    .deq_ready (io_deq_ready),')
    A('    .deq_word  (deqWord)')
    A('  );')
    A('')
    for n, rh, rl, _ in R['deq']:
        A('  assign %s = %s;' % (n, 'deqWord[%d]' % rh if rh == rl else 'deqWord[%d:%d]' % (rh, rl)))
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for q in QUEUES:
        R = parse(q)
        txt = emit(R)
        p = os.path.join(OUT, q + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-24s depth=%-2d flow=%d word=%-3d fields=%d deq=%d' % (q, R['depth'], R['flow'], R['word_w'], len(R['fields']), len(R['deq'])))
    for q in QUEUES1:
        R = parse1(q)
        txt = emit1(R)
        p = os.path.join(OUT, q + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-24s depth=1  pipe=%d word=%-3d deq=%d unread=%s' % (q, R['pipe'], R['word_w'], len(R['deq']), ','.join(R['unread'])))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
