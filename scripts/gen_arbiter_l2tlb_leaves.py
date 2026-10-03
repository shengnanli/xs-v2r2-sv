#!/usr/bin/env python3
"""gen_arbiter_l2tlb_leaves.py —— L2TLB 里 5 个 chisel3 固定优先级 Arbiter 的薄文件（lane l2tlb-leaves）。

  Arbiter1_L2TLBImp_Anon         outArb(i)：单入口，退化为直通
  Arbiter2_L2TLBImp_Anon_1       hptw_resp_arb：HPTW 应答（cache 命中 / HPTW 走表）两路汇流，out.ready 恒 1
  Arbiter3_bitmapReqBundle       bitmap_arb：PTW / LLPTW / HPTW 三路 bitmap 检查请求汇流
  Arbiter4_L2TlbMemReqBundle     mem_arb：PTW / LLPTW / HPTW / Bitmap 四路访存请求汇流
  Arbiter5_L2TlbWithHptwIdBundle arb2：HPTW / PTW / MissQueue / TLB / Prefetch 五路进 page cache 的请求汇流

全部是 chisel3 Arbiter（lowest-index-wins，纯组合）。2 路及以上的核是已签核的
rtl/frontend/xs_FixedPriorityArbiter_core.sv（本脚本不改核），这里只从 golden 端口表生成薄文件：
  * 载荷按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼；
  * 某一路**没有**的字段 = 上游在 Scala 里把它接成常量（或 DontCare，firtool 取 0），firtool 把常量
    折进仲裁器、删掉端口。拼载荷时在原位置填那个常量。常量值不靠猜：下表 CONSTS 每一项都写明 Scala
    出处；生成器 fail-closed 地要求"缺的字段集合 == CONSTS 登记的集合"，多一个少一个都拒绝生成；
    值本身对不对由 FM 逐位证明；
  * Arbiter2_L2TLBImp_Anon_1：Scala `hptw_resp_arb.io.out.ready := true.B`，firtool 把 out_ready 端口和
    恒为 1 的 io_in_0_ready 端口都删了 —— 薄文件给核的 out_ready 接 1'b1，第 0 路 ready 不引出；
  * Arbiter5_L2TlbWithHptwIdBundle：父级读 io.chosen（TLB 请求的 source 用到它），golden 多一个 io_chosen
    输出。核不出 chosen，薄文件按 Chisel 定义另算：第一个 valid 的下标，一路都没请求时 = NUM_IN-1；
  * 核的端口数恒等式（GOLDEN_PORTS == 2*NUM_IN + 2 + bits 端口数）讲的是"标准 Arbiter 接口"。
    上面两种端口增删在这里显式加回/扣掉后再传进去（逐项列在薄文件头），而且每一项都先核实
    golden 里确实缺/确实有那根端口，否则生成失败。

用法：python3 scripts/gen_arbiter_l2tlb_leaves.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = 'mmu'

# 模块名 -> 规格
#   num_in   入口数
#   desc     一句话说明（文件首行）
#   where    Scala 例化处与每一路的来源
#   consts   {(路, 字段): (SV 常量, Scala 出处)} —— 该路缺的字段
#   no_ready golden 删掉的握手端口（out.ready 恒 1 时）
#   chosen   golden 有 io_chosen 输出
VARIANTS = {
    'Arbiter1_L2TLBImp_Anon': dict(
        num_in=1,
        desc='L2TLB 给 TLB 的最终应答出口 outArb(i)：单入口仲裁器，退化为直通',
        where=['L2TLB.scala:142 `outArb = (0 until PtwWidth).map(i => Module(new Arbiter(..., 1)))`，',
               '每个请求方（itlb/dtlb）一个；唯一入口接 mergeArb(i) 的出口（经 sector 化转换）。',
               '入口数只剩 1，"仲裁"不发生：out = in，in.ready = out.ready（chosen 恒 0，父级不读，被删）。'],
        consts={}, no_ready=[], chosen=False),
    'Arbiter2_L2TLBImp_Anon_1': dict(
        num_in=2,
        desc='L2TLB 的 HPTW 应答汇流 hptw_resp_arb：page cache 命中 / HPTW 走表 两路应答并成一路',
        where=['L2TLB.scala:138 `hptw_resp_arb = Module(new Arbiter(..., 2))`；',
               '第 0 路 = page cache 命中且是 HPTW 请求（HptwRespArbCachePort），第 1 路 = HPTW 走表应答。',
               '出口按 id 分发给 PTW（id == FsmReqID）或 LLPTW（其余）；L2TLB.scala:624 `out.ready := true.B`。'],
        consts={(0, 'resp_gaf'): ("1'h0", 'PageTableCache.scala:765 `io.resp.bits.toHptw.resp.gaf := false.B`')},
        no_ready=['io_out_ready', 'io_in_0_ready'], chosen=False),
    'Arbiter3_bitmapReqBundle': dict(
        num_in=3,
        desc='L2TLB 的 bitmap 检查请求汇流 bitmap_arb：PTW / LLPTW / HPTW 三路并成一路送 Bitmap',
        where=['L2TLB.scala:488 `bitmap_arb = Module(new Arbiter(new bitmapReqBundle(), 3))`；',
               '第 0 路 = PTW，第 1 路 = LLPTW（内部先 RR 仲裁 llptwsize 个条目），第 2 路 = HPTW。'],
        consts={
            (0, 'id'): ("3'h6", 'PageTableWalker.scala:284 `id := FsmReqID.U`（FsmReqID = llptwsize = 6）'),
            (0, 'way_info'): ("4'h0", 'PageTableWalker.scala:287 `way_info := DontCare`（firtool 取 0）'),
            (0, 'hptw_bypassed'): ("1'h0", 'PageTableWalker.scala:288 `hptw_bypassed := false.B`'),
            (1, 'level'): ("2'h0", 'PageTableWalker.scala:1102 `level := 0.U`'),
            (1, 'hptw_bypassed'): ("1'h0", 'PageTableWalker.scala:1104 取自 LLPTW 内部 bitmap_arb 出口，'
                                           '其各入口恒 false，firtool 跨模块传播成常量 0'),
            (2, 'id'): ("3'h7", 'PageTableWalker.scala:1292 `id := HptwReqId.U`（HptwReqId = llptwsize+1 = 7）'),
            (2, 's2xlate'): ("2'h2", 'PageTableWalker.scala:1298 `s2xlate := onlyStage2`（= 2）'),
        },
        no_ready=[], chosen=False),
    'Arbiter4_L2TlbMemReqBundle': dict(
        num_in=4,
        desc='L2TLB 的访存请求汇流 mem_arb：PTW / LLPTW / HPTW / Bitmap 四路并成一路发 TileLink A',
        where=['L2TLB.scala:403 `mem_arb = Module(new Arbiter(new L2TlbMemReqBundle(), 4))`（HasBitmapCheck）；',
               '第 0 路 = PTW，第 1 路 = LLPTW，第 2 路 = HPTW，第 3 路 = Bitmap；',
               '出口 id 当 TileLink source 用（L2TLB.scala:436-442）。'],
        consts={
            (0, 'id'): ("4'h6", 'PageTableWalker.scala:295 `mem.req.bits.id := FsmReqID.U`（= 6）'),
            (0, 'hptw_bypassed'): ("1'h0", 'PageTableWalker.scala:296 `hptw_bypassed := false.B`'),
            (1, 'hptw_bypassed'): ("1'h0", 'PageTableWalker.scala:1085 `hptw_bypassed := false.B`'),
            (2, 'id'): ("4'h7", 'PageTableWalker.scala:1304 `id := HptwReqId.U`（= 7）'),
            (3, 'hptw_bypassed'): ("1'h0", 'BitmapCheck.scala:351 `hptw_bypassed := false.B`'),
        },
        no_ready=[], chosen=False),
    'Arbiter5_L2TlbWithHptwIdBundle': dict(
        num_in=5,
        desc='L2TLB 进 page cache 的请求汇流 arb2：HPTW / PTW / MissQueue / TLB / Prefetch 五路并成一路',
        where=['L2TLB.scala:132 `arb2 = Module(new Arbiter(new L2TlbWithHptwIdBundle, 5))`；端口号见 L2TLB.scala:177-181：',
               '第 0 路 = HPTW 请求，第 1 路 = PTW 转 LLPTW，第 2 路 = MissQueue 回灌，第 3 路 = TLB（arb1 出口），',
               '第 4 路 = Prefetch。出口接 page cache 的 req（L2TLB.scala:252 `out.ready := cache.io.req.ready`）。'],
        consts={
            (0, 'req_info_s2xlate'): ("2'h2", 'L2TLB.scala:227 `s2xlate := onlyStage2`（= 2）'),
            (0, 'isHptwReq'): ("1'h1", 'L2TLB.scala:229 `isHptwReq := true.B`'),
            (1, 'isHptwReq'): ("1'h0", 'L2TLB.scala:207 `isHptwReq := false.B`'),
            (1, 'hptwId'): ("3'h0", 'L2TLB.scala:209 `hptwId := DontCare`（firtool 取 0）'),
            (3, 'isHptwReq'): ("1'h0", 'L2TLB.scala:217 `isHptwReq := false.B`'),
            (3, 'hptwId'): ("3'h0", 'L2TLB.scala:219 `hptwId := DontCare`（firtool 取 0）'),
            (4, 'req_info_source'): ("2'h2", 'L2TlbPrefetch.scala `source := prefetchID.U`（prefetchID = PtwWidth = 2）'),
            (4, 'isHptwReq'): ("1'h0", 'L2TlbPrefetch.scala `isHptwReq := false.B`'),
            (4, 'hptwId'): ("3'h0", 'L2TlbPrefetch.scala `hptwId := DontCare`（firtool 取 0）'),
        },
        no_ready=[], chosen=True),
}


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('\nmodule %s(' % mod) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            raise SystemExit('%s: 端口行解析失败: %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t.count('\n')  # 与 wc -l 同口径


def sv_width(w):
    return '' if w == 1 else '[%d:0] ' % (w - 1)


def emit(mod):
    spec = VARIANTS[mod]
    num_in = spec['num_in']
    consts = spec['consts']
    P, glines = ports(mod)
    names = [n for _, _, n in P]
    width_of = {n: w for _, w, n in P}
    outf = [(n[len('io_out_bits_'):], w) for _, w, n in P if n.startswith('io_out_bits_')]
    width = sum(w for _, w in outf)

    # ---- fail-closed 形状检查 ----
    missing = []
    for k in range(num_in):
        pre = 'io_in_%d_bits_' % k
        have = [(n[len(pre):], w) for _, w, n in P if n.startswith(pre)]
        it = iter(outf)
        if not all(f in it for f in have):
            raise SystemExit('%s 第 %d 路字段不是出口字段表的保序子集（或位宽不同）' % (mod, k))
        miss = [f for f, _ in outf if (f, width_of['io_out_bits_' + f]) not in have]
        declared = sorted(f for (kk, f) in consts if kk == k)
        if sorted(miss) != declared:
            raise SystemExit('%s 第 %d 路缺的字段 %s != CONSTS 登记 %s' % (mod, k, sorted(miss), declared))
        for f in miss:
            v = consts[(k, f)][0]
            if int(v.split("'")[0]) != width_of['io_out_bits_' + f]:
                raise SystemExit('%s 第 %d 路 %s 常量 %s 位宽不对' % (mod, k, f, v))
        missing.append(miss)
        if 'io_in_%d_valid' % k not in names:
            raise SystemExit('%s 缺 io_in_%d_valid' % (mod, k))
    for n in spec['no_ready']:
        if n in names:
            raise SystemExit('%s: 登记为被删的 %s 在 golden 里存在' % (mod, n))
    if ('io_chosen' in names) != spec['chosen']:
        raise SystemExit('%s: io_chosen 存在性与登记不符' % mod)
    known = set(['io_out_ready', 'io_out_valid'] + ['io_out_bits_' + f for f, _ in outf])
    for k in range(num_in):
        known |= {'io_in_%d_ready' % k, 'io_in_%d_valid' % k}
        known |= {'io_in_%d_bits_%s' % (k, f) for f, _ in outf if f not in missing[k]}
    known -= set(spec['no_ready'])
    if spec['chosen']:
        known.add('io_chosen')
    if known != set(names):
        raise SystemExit('%s: golden 端口与已知形状不符 %s' % (mod, sorted(set(names) ^ known)[:5]))
    bits_ports = sum(1 for n in names if '_bits_' in n)
    core_ports = len(P) + len(spec['no_ready']) - (1 if spec['chosen'] else 0)
    if num_in > 1 and core_ports != 2 * num_in + 2 + bits_ports:
        raise SystemExit('%s: 端口数恒等式不成立 %d' % (mod, core_ports))

    def cat(k, ind):
        """第 k 路（k=None 为出口）的载荷拼接，一个字段一行；缺的字段填 CONSTS 常量。"""
        items = []
        for f, w in outf:
            if k is not None and f in missing[k]:
                items.append('%s /* 本路无 %s 端口，常量 */' % (consts[(k, f)][0], f))
            else:
                items.append(('io_out_bits_' if k is None else 'io_in_%d_bits_' % k) + f)
        return '{' + (',\n' + ' ' * ind).join(items) + '}'

    H = []
    W = H.append
    W('// %s.sv —— %s' % (mod, spec['desc']))
    W('//')
    for s in spec['where']:
        W('// ' + s)
    W('//')
    if num_in == 1:
        W('// chisel3 Arbiter(n=1)：没有第二路可选，整个模块就是 valid/ready/载荷的直连。')
        W('// 共享核 xs_FixedPriorityArbiter_core 要求 NUM_IN >= 2，所以本文件自足、不例化核')
        W('// （同 rtl/memblock/Arbiter1_TagWriteReq.sv 先例）。载荷 %d 个字段、%d 位。' % (len(outf), width))
    else:
        W('// chisel3 Arbiter（%d 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv'
          % num_in)
        W('// （已签核，语义讲在那里：in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路的载荷）。')
        W('// 载荷 = %d 个字段、%d 位，按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼。' % (len(outf), width))
        if consts:
            W('// ★有的入口缺字段★：上游把它接成常量，firtool 折进本模块并删掉端口；拼载荷时在原位置填常量：')
            for k in range(num_in):
                for f in missing[k]:
                    W('//   第 %d 路 %-18s = %-5s ← %s' % (k, f, consts[(k, f)][0], consts[(k, f)][1]))
        if spec['no_ready']:
            W('// ★out.ready 恒 1★：golden 删了 %s，核的 out_ready 接 1\'b1，第 0 路 ready 不引出。'
              % ' / '.join(spec['no_ready']))
        if spec['chosen']:
            W('// ★io_chosen★：父级读它，核不出，本文件按 Chisel 定义另算（第一个 valid 的下标；都不 valid 时 = %d）。'
              % (num_in - 1))
        if spec['no_ready'] or spec['chosen']:
            W('// 核的端口数恒等式按标准 Arbiter 接口算：golden %d 端口%s%s = %d。'
              % (len(P),
                 ' + 被删的 %d 根 ready' % len(spec['no_ready']) if spec['no_ready'] else '',
                 ' - io_chosen' if spec['chosen'] else '', core_ports))
    W('// golden %d 行 / %d 端口；本文件由 scripts/gen_arbiter_l2tlb_leaves.py 从 golden 端口表生成（勿手改）。'
      % (glines, len(P)))
    W('')

    B = []
    W = B.append

    def section(title):
        W('  // ' + '-' * 74)
        W('  // ' + title)
        W('  // ' + '-' * 74)
    W('module %s (' % mod)
    section('端口表（与 golden 逐名逐宽相同，%d 个）' % len(P))
    W(',\n'.join('  %-6s logic %s%s' % (d, sv_width(w), n) for d, w, n in P))
    W(');')
    W('')
    if num_in == 1:
        section('直通：单入口时"选中的那一路"永远是第 0 路')
        W('  assign io_in_0_ready = io_out_ready;')
        W('  assign io_out_valid  = io_in_0_valid;')
        fw = max(len(f) for f, _ in outf)
        for f, _ in outf:
            W('  assign io_out_bits_%s = io_in_0_bits_%s;' % (f.ljust(fw), f))
        W('')
        W('endmodule')
        return '\n'.join(H + B) + '\n'

    section('入口载荷拼接：%d 路 × %d 位，位 NUM_IN-1 = 第 0 路（优先级最高）' % (num_in, width))
    W('  localparam int unsigned NUM_IN = %d;' % num_in)
    W('  localparam int unsigned WIDTH  = %d;' % width)
    W('')
    W('  logic [NUM_IN-1:0]       in_valid_vec;')
    W('  logic [NUM_IN-1:0]       in_ready_vec;')
    W('  logic [NUM_IN*WIDTH-1:0] in_bits_flat;')
    W('  logic [WIDTH-1:0]        out_bits_flat;')
    W('  assign in_valid_vec = {%s};' % ', '.join('io_in_%d_valid' % k for k in range(num_in)))
    W('  assign in_bits_flat = {')
    W(',\n'.join('    %s' % cat(k, 5) for k in range(num_in)))
    W('  };')
    for k in range(num_in):
        if 'io_in_%d_ready' % k in names:
            W('  assign io_in_%d_ready = in_ready_vec[%d];' % (k, num_in - 1 - k))
        else:
            W('  // io_in_%d_ready 被 firtool 删掉（out.ready 恒 1 时它恒 1，父级不需要读）' % k)
    W('')
    section('核例化（xs_FixedPriorityArbiter_core，端口数恒等式在核里自检）')
    W('  xs_FixedPriorityArbiter_core #(')
    W('    .WIDTH            (WIDTH),')
    W('    .NUM_IN           (NUM_IN),')
    W('    .PORT_BITS_OUT    ($bits(%s)),' % cat(None, 25))
    W('    .PORT_BITS_LAST_IN($bits(%s)),' % cat(num_in - 1, 25))
    W('    .GOLDEN_PORTS     (%d),  // golden %d%s%s' % (
        core_ports, len(P),
        ' + %d 根被删的 ready' % len(spec['no_ready']) if spec['no_ready'] else '',
        ' - io_chosen' if spec['chosen'] else ''))
    W('    .GOLDEN_BITS_PORTS(%d)' % bits_ports)
    W('  ) u_core (')
    W('    .in_valid (in_valid_vec),')
    W('    .in_ready (in_ready_vec),')
    W('    .in_bits  (in_bits_flat),')
    W('    .out_ready(%s),' % ("1'b1" if 'io_out_ready' in spec['no_ready'] else 'io_out_ready'))
    W('    .out_valid(io_out_valid),')
    W('    .out_bits (out_bits_flat)')
    W('  );')
    W('')
    section('出口载荷拆分')
    W('  assign %s = out_bits_flat;' % cat(None, 10))
    if spec['chosen']:
        W('')
        section('io_chosen：被选中那一路的下标（Chisel：从最后一路往前覆盖，第一个 valid 胜出）')
        W('  always_comb begin')
        W("    io_chosen = %d'(NUM_IN - 1);" % width_of['io_chosen'])
        W('    for (int k = NUM_IN - 2; k >= 0; k--)')
        W("      if (in_valid_vec[NUM_IN - 1 - k]) io_chosen = %d'(k);" % width_of['io_chosen'])
        W('  end')
    W('')
    W('endmodule')
    return '\n'.join(H + B) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for mod in VARIANTS:
        txt = emit(mod)
        p = os.path.join(REPO, 'rtl', OUT_DIR, mod + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad = 1
        elif cur != txt:
            open(p, 'w').write(txt)
            print('wrote %s' % p)
    if a.check and not bad:
        print('OK: gen_arbiter_l2tlb_leaves.py（%d 个薄文件与生成结果一致）' % len(VARIANTS))
    return bad


if __name__ == '__main__':
    sys.exit(main())
