#!/usr/bin/env python3
"""gen_depth1queue_leaves5.py —— 族 D（深度 1 队列叶，5 个）薄文件生成器。

5 个目标全部是 chisel3 Queue(entries=1) 的单态化：firtool 展开后只剩一个 full 标志
（异步复位）+ 一个装整条 payload 的 ram 寄存器（不复位），没有指针、没有存储叶子。
diff 过 5 份 golden，结构同构，共三种子形态：

  * PIPE=1（enq_ready = deq_ready | ~full，"边出边进"）：Queue1_PrefetchReq /
    Queue1_PrefetchResp / Queue1_PrefetchTrain（SMS 预取流水 Pipeline_1/2/3 的级寄存器）；
  * PIPE=0（enq_ready = ~full）：Queue1_BundleMap（AXI4UserYanker_2 里给 id==0 的 AR
    存 tl_state、R 通道 last 时弹出）；Queue1_L1PrefetchReq（MemBlock 的 Pipeline 级寄存器，
    L1 预取请求进 DCache 前打一拍；2026-10-03 agent/fe-mem-misc 并入，家族由 5 个变为 6 个，
    文件名保留原名以免牵动已有引用）；
  * 无 ready 端口：Queue1_UInt32（Pipeline_10/11 的级寄存器，父模块里 deq 恒被接走，
    enq_ready 恒 1，两个 ready 端口被 firtool 常数折叠删掉）——等价于 PIPE=1 且
    deq_ready 恒 1：do_enq 退化为 io_enq_valid，full 更新退化为
    `~(io_enq_valid == full)`，与 golden 逐式对上。

控制 + 存储全部复用已签核的共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头；
Queue1_ChosenQBundle 同用），本脚本只生成每变体的薄文件：golden 端口表 + 字段按
golden 的 ram 拼接顺序拼成整字 / 拆回来。

机器校验（fail-closed，任何一条对不上就拒绝生成）：
  1. 端口表逐项解析；full/ram 寄存器声明、两个 always 块、do_enq 定义、enq_ready
     赋值、full 更新式，都必须逐字命中所属子形态的模板；
  2. ram 拼接各字段的 [hi:lo] 由端口位宽机械推出，总宽必须恰好等于 ram 字宽；
  3. 每条 io_deq_bits* 输出的 ram 切片必须与拼接布局逐字段一致；
  4. golden 体内的每条 assign 都必须被本脚本识别（集合相等），剩一条就报错——
     证明 golden 里没有模板外的逻辑。

用法：python3 scripts/gen_depth1queue_leaves5.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')

# 模块 -> (输出子目录, 父模块, 一句话说明)
QUEUES = {
    'Queue1_PrefetchReq':   ('frontend', 'Pipeline_1（SMS 预取流水）',
                             'SMS 预取请求在 Pipeline_1 的级寄存器（深度 1，pipe）'),
    'Queue1_PrefetchResp':  ('frontend', 'Pipeline_3',
                             'SMS 预取响应在 Pipeline_3 的级寄存器（深度 1，pipe）'),
    'Queue1_PrefetchTrain': ('frontend', 'Pipeline_2',
                             'SMS 预取训练数据在 Pipeline_2 的级寄存器（深度 1，pipe）'),
    'Queue1_UInt32':        ('frontend', 'Pipeline_10 / Pipeline_11',
                             '32 位无反压流水的级寄存器（深度 1；无 ready 端口）'),
    'Queue1_L1PrefetchReq': ('memblock', 'Pipeline（MemBlock 里 L1 预取请求送 DCache 前的级寄存器）',
                             'L1 预取请求（L1Prefetcher → DCache）的级寄存器（深度 1，非 pipe）'),
    'Queue1_BundleMap':     ('uncore',   'AXI4UserYanker_2',
                             'AXI4UserYanker_2 给 id==0 的 AR 暂存 tl_state（size+source），'
                             'R 通道 last 时弹出（深度 1，非 pipe）'),
}

PORT_RE = re.compile(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')
ASSIGN_RE = re.compile(r'assign\s+(\w+)\s*=\s*(.*?);', re.S)


def fail(mod, msg):
    raise SystemExit('gen_depth1queue_leaves5: %s: %s' % (mod, msg))


def ports(txt, mod):
    i = txt.index('module %s(' % mod)
    j = txt.index('\n);', i)
    out = []
    for line in txt[i:j].splitlines()[1:]:
        m = PORT_RE.match(line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1,
                        m.group(3)))
    if not out:
        fail(mod, '端口表解析为空')
    return out


def parse(mod):
    txt = open(os.path.join(G, mod + '.sv')).read()
    P = ports(txt, mod)
    names = {n for _, _, n in P}
    W = {n: w for _, w, n in P}
    body = txt[txt.index('\n);', txt.index('module %s(' % mod)):]
    # 初始随机化块与队列语义无关（UT 编 +define+SYNTHESIS 时整块不在），剥掉再比对
    body = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '\n',
                  body, flags=re.S)
    body1 = re.sub(r'\s+', ' ', body)

    m = re.search(r'reg\s+\[(\d+):0\]\s+ram;', body)
    if not m:
        fail(mod, '没有 reg [W-1:0] ram 声明')
    word_w = int(m.group(1)) + 1
    if not re.search(r'\breg\s+full;', body):
        fail(mod, '没有 reg full 声明')

    # --- 子形态判定（三选一，模板逐字命中才算）---
    has_enq_rdy = 'io_enq_ready' in names
    has_deq_rdy = 'io_deq_ready' in names
    if has_enq_rdy != has_deq_rdy:
        fail(mod, 'enq/deq ready 只存在其一，不在已知子形态里')
    if has_enq_rdy:
        pipe = 'assign io_enq_ready_0 = io_deq_ready | ~full;' in body1
        if pipe:
            if 'wire do_enq = io_enq_ready_0 & io_enq_valid;' not in body1:
                fail(mod, 'PIPE=1 形态但 do_enq 定义不符')
        else:
            if 'wire do_enq = ~full & io_enq_valid;' not in body1:
                fail(mod, 'PIPE=0 形态但 do_enq 定义不符')
            if 'assign io_enq_ready = ~full;' not in body1:
                fail(mod, 'PIPE=0 形态但 enq_ready 赋值不符')
        wen, cond, ns = 'do_enq', '~(do_enq == (io_deq_ready & full))', 'do_enq'
    else:
        # 无 ready：enq_ready 恒 1、deq_ready 恒 1 被折叠掉；full 更新相应退化
        pipe = True   # 等价 PIPE=1 + deq_ready 恒 1（见文件头说明）
        wen, cond, ns = 'io_enq_valid', '~(io_enq_valid == full)', 'io_enq_valid'

    # --- full 更新式与 ram 写使能：逐字模板 ---
    # 'always @(posedge clock)' 不是异步复位那行的子串（后者是 "...clock or ..."），
    # 两个计数各自独立成立
    if body.count('always @(posedge clock or posedge reset)') != 1:
        fail(mod, '异步复位 always 块不是恰好一个')
    if body.count('always @(posedge clock)') != 1:
        fail(mod, 'ram 写 always 块不是恰好一个')
    full_tpl = ('if (reset) full <= 1\'h0; else if (%s) full <= %s;' % (cond, ns))
    if re.sub(r'\s+', ' ', full_tpl) not in body1:
        fail(mod, 'full 更新式不符模板: %s' % full_tpl)
    if 'if (%s) ram <=' % wen not in body1:
        fail(mod, 'ram 写使能不是 if (%s)' % wen)

    # --- ram 拼接 → 字段布局（lsb 起）---
    cm = re.search(r'ram\s*<=\s*(\{.*?\}|\w+)\s*;', body, re.S)
    if not cm:
        fail(mod, '没找到 ram <= 赋值')
    raw = cm.group(1)
    if raw.startswith('{'):
        items = [x.strip() for x in re.sub(r'\s+', ' ', raw[1:-1]).split(',')]
    else:
        items = [raw]
    layout, hi = [], word_w
    for it in items:
        if it not in W or not it.startswith('io_enq_bits'):
            fail(mod, 'ram 拼接项 %s 不是入队 payload 端口（本族无补零段）' % it)
        layout.append((it, hi - 1, hi - W[it]))
        hi -= W[it]
    if hi != 0:
        fail(mod, 'ram 拼接总宽 %d != ram 字宽 %d' % (word_w - hi, word_w))
    rng = {it[len('io_enq_bits_'):] if it.startswith('io_enq_bits_') else '': (a, b)
           for it, a, b in layout}
    # io_enq_bits（UInt32）这种无下缀字段的 key 为空串，改用整字
    if items == ['io_enq_bits']:
        rng = {'': (word_w - 1, 0)}

    # --- deq 输出切片逐字段核对 ---
    deq = []
    for d, w, n in P:
        if d != 'output' or not n.startswith('io_deq_bits'):
            continue
        f = n[len('io_deq_bits_'):] if n.startswith('io_deq_bits_') else ''
        a = re.search(r'assign %s = ram(?:\[(\d+)(?::(\d+))?\])?;' % re.escape(n), body)
        if not a:
            fail(mod, '%s 不是 ram 切片' % n)
        rh = int(a.group(1)) if a.group(1) else word_w - 1
        rl = int(a.group(2)) if a.group(2) else (rh if a.group(1) else 0)
        if rh - rl + 1 != w:
            fail(mod, '%s 切片宽 %d != 端口宽 %d' % (n, rh - rl + 1, w))
        if rng.get(f) != (rh, rl):
            fail(mod, '%s 切片 [%d:%d] 与入队拼接布局 %s 不一致' % (n, rh, rl, rng.get(f)))
        deq.append((n, rh, rl))
    unread = [f for f in rng if f and ('io_deq_bits_' + f) not in {n for n, _, _ in deq}]

    # --- 全覆盖断言：golden 体内的每条 assign 都必须已被识别 ---
    expect = {'io_deq_valid': 'full'}
    if has_enq_rdy:
        if pipe:
            expect['io_enq_ready_0'] = 'io_deq_ready | ~full'
            expect['io_enq_ready'] = 'io_enq_ready_0'
        else:
            expect['io_enq_ready'] = '~full'
    for n, rh, rl in deq:
        if (rh, rl) == (word_w - 1, 0):
            expect[n] = 'ram'
        elif rh == rl:
            expect[n] = 'ram[%d]' % rh
        else:
            expect[n] = 'ram[%d:%d]' % (rh, rl)
    got = {n: re.sub(r'\s+', ' ', e).strip() for n, e in ASSIGN_RE.findall(body)}
    if got != expect:
        fail(mod, 'assign 集合有模板外内容: 多 %s / 少 %s'
                  % (sorted(set(got) - set(expect)), sorted(set(expect) - set(got))))

    return dict(mod=mod, P=P, word_w=word_w, pipe=pipe, has_rdy=has_enq_rdy,
                layout=layout, deq=deq, unread=unread, glines=len(txt.splitlines()))


def header(R):
    m = R['mod']
    sub, parent, what = QUEUES[m]
    L = ['// %s.sv —— %s' % (m, what), '//']
    if not R['has_rdy']:
        L.append('// payload %d 位（io_enq_bits → io_deq_bits 直通一个整字）。golden 没有 ready 端口：' % R['word_w'])
        L.append('// 父模块 %s 里 deq 恒被接走（deq_ready 恒 1）、enq_ready 恒 1，两个端口都被 firtool' % parent)
        L.append('// 常数折叠删掉；等价于 PIPE=1 + deq_ready 恒 1，do_enq 退化为 io_enq_valid，')
        L.append('// full 更新退化为 `~(io_enq_valid == full)`——下方例化照此接。')
    else:
        fields = [it[len('io_enq_bits_'):] for it, _, _ in R['layout']]
        L.append('// payload %d 位（%s），父模块 %s。' % (R['word_w'], ' + '.join(fields), parent))
        L.append('// ram 字（lsb 起）：' + '  '.join('%s[%d:%d]' % (
            (it[len('io_enq_bits_'):] or 'bits'), a, b) for it, a, b in reversed(R['layout'])))
        if R['pipe']:
            L.append('// PIPE=1：队满时只要本拍 deq 接走就能同拍再入队（enq_ready = deq_ready | ~full）。')
        else:
            L.append('// PIPE=0：enq_ready = ~full，满时拒收；同拍入出不存在（结构性）。')
        if R['unread']:
            L.append('// ★照 golden 保留★：字段 %s 存进 ram 但 deq 侧无读者（firtool 留了存储删了输出；' % ', '.join(R['unread']))
            L.append('// FM 里两侧对称的未读位，不许"顺手"删掉）。')
    L.append('// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，'
             'Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。')
    L.append('// golden %d 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。' % R['glines'])
    return '\n'.join(L) + '\n\n'


def emit(R):
    m = R['mod']
    L = [header(R)]
    A = L.append
    A('// BEGIN GENERATED(%s) —— scripts/gen_depth1queue_leaves5.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n)
                 for d, w, n in R['P']))
    A(');')
    A('')
    if not R['has_rdy']:
        # 无 ready 变体：单字段整字直通，deq_ready 恒 1、enq_ready 恒 1（不引出）
        A('  xs_ChiselQueue1_core #(.W(%d), .PIPE(1\'b1)) u_core (' % R['word_w'])
        A('    .clock     (clock),')
        A('    .reset     (reset),')
        A('    .enq_valid (io_enq_valid),')
        A('    .enq_ready (),')
        A('    .enq_word  (io_enq_bits),')
        A('    .deq_valid (io_deq_valid),')
        A('    .deq_ready (1\'b1),')
        A('    .deq_word  (io_deq_bits)')
        A('  );')
    else:
        A('  logic [%d:0] enqWord, deqWord;' % (R['word_w'] - 1))
        A('')
        A('  // 入队字（高位在前，照 golden 的 ram 拼接顺序）')
        A('  assign enqWord = {')
        A(',\n'.join('    %s' % it for it, _, _ in R['layout']))
        A('  };')
        A('')
        A('  xs_ChiselQueue1_core #(.W(%d), .PIPE(1\'b%d)) u_core ('
          % (R['word_w'], 1 if R['pipe'] else 0))
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
        for n, rh, rl in R['deq']:
            src = 'deqWord[%d]' % rh if rh == rl else \
                  ('deqWord' if (rh, rl) == (R['word_w'] - 1, 0) else 'deqWord[%d:%d]' % (rh, rl))
            A('  assign %s = %s;' % (n, src))
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
        p = os.path.join(REPO, 'rtl', QUEUES[q][0], q + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-24s pipe=%d rdy=%d word=%-3d deq=%d unread=%s'
              % (q, R['pipe'], R['has_rdy'], R['word_w'], len(R['deq']),
                 ','.join(R['unread']) or '-'))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
