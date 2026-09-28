#!/usr/bin/env python3
"""gen_l2_reqbuf.py —— RequestBuffer 的机械部分：类型定义、golden 同名 wrapper、FM 钉点。

可读核 xs_RequestBuffer_core 在 rtl/uncore/RequestBuffer.sv 里手写，本脚本**不碰**；它只原地替换同一文件
的 GENERATED(types) / GENERATED(wrapper) 两个区，并写 verif/ut/RequestBuffer/fm_pins_pre.tcl：

  types    a_req_t = io_in_bits_* 的 14 个字段（SinkA 送来的 A 请求里真正存在的字段）；
           task_t  = io_out_bits_* 的 93 个字段（出口 TaskBundle，wayMask 被 Scala 强制全 1 后删了）；
           entry_t = 缓冲表项 ReqEntry {valid, rdy, channel, req, waitMP, waitMS}，字段表逐字取自 golden
           FastArbiter_2 的 io_in_0_bits_*（核对：task_* 恰好 = channel + a_req_t 全部字段）。
           第一个端口字段放结构体最高位；`alias` 是 SV 保留字，写成 alias_。
  wrapper  端口按 golden；issueArb（FastArbiter_2）/ chosenQ（Queue1_ChosenQBundle）按 golden 实例名例化；
           msInfo_<i>_* 打包成核的数组口。
  pins     只钉 perf 专用的 12 个寄存器（见 emit_pins 的说明）；其余 FM 自己配得上。

用法：python3 scripts/gen_l2_reqbuf.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'uncore', 'RequestBuffer.sv')
PINS = os.path.join(REPO, 'verif', 'ut', 'RequestBuffer', 'fm_pins_pre.tcl')
MOD = 'RequestBuffer'
SV_KEYWORDS = {'alias'}
N_ENTRY, N_MSHR = 4, 16
MS_F = ['valid', 'channel', 'set', 'reqTag', 'metaTag', 'willFree', 'needRelease', 'meta_prefetchSrc',
        'dirHit', 'isAcqOrPrefetch', 'isPrefetch', 'param', 'mergeA', 's_refill']


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('module %s(' % mod)
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t


def fname(f):
    return f + '_' if f in SV_KEYWORDS else f


def fields(P, prefix):
    return [(n[len(prefix):], w) for _, w, n in P if n.startswith(prefix)]


def build():
    P, gtxt = ports(MOD)
    A = fields(P, 'io_in_bits_')
    T = fields(P, 'io_out_bits_')
    FP, _ = ports('FastArbiter_2')
    E = fields(FP, 'io_in_0_bits_')
    assert [f for f, _ in E][:2] == ['valid', 'rdy'] and [f for f, _ in E][-2:] == ['waitMP', 'waitMS'], E
    task_part = [(f[len('task_'):], w) for f, w in E[2:-2]]
    assert task_part[0] == ('channel', 3) and task_part[1:] == A, 'FastArbiter_2 的 task_* 不等于 channel + a_req_t'
    QP, _ = ports('Queue1_ChosenQBundle')
    assert fields(QP, 'io_deq_bits_bits_task_') == T, 'chosenQ 出队 task 字段表 != io_out 字段表'
    assert fields(QP, 'io_enq_bits_bits_') == E, 'chosenQ 入队字段表 != FastArbiter_2 载荷'
    for f in MS_F:
        assert all(('input', w, 'io_mshrInfo_%d_%s' % (i, 'valid' if f == 'valid' else 'bits_' + f)) in P
                   for i in range(N_MSHR) for w in [dict((n, w) for _, w, n in P)['io_mshrInfo_0_%s' % ('valid' if f == 'valid' else 'bits_' + f)]]), f
    return P, A, T, E, gtxt


def struct(name, F, comment):
    L = ['  // %s（%d 个字段，%d 位）' % (comment, len(F), sum(w for _, w in F)), '  typedef struct packed {']
    for f, w in F:
        L.append('    logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), fname(f)))
    L.append('  } %s;' % name)
    return L


def emit_types(A, T):
    L = struct('a_req_t', A, 'A 请求：io_in_bits_* 的字段')
    L.append('')
    L += struct('task_t', T, '出口 TaskBundle：io_out_bits_* 的字段')
    L.append('')
    L += ['  // 缓冲表项 ReqEntry（= FastArbiter_2 载荷 / chosenQ 入队字段）',
          '  typedef struct packed {',
          '    logic        valid;',
          '    logic        rdy;',
          '    logic [2:0]  channel;',
          '    a_req_t      req;',
          '    logic [3:0]  waitMP;',
          '    logic [15:0] waitMS;',
          '  } entry_t;']
    return '\n'.join(L)


def emit_wrapper(P, A, T, E):
    L = []
    W = L.append
    W('module %s' % MOD)
    W('  import requestbuffer_pkg::*;')
    W('(')
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    W('  a_req_t     inReq;')
    W('  task_t      outTask, deqTask;')
    W('  logic       arbIn_valid [N_ENTRY];')
    W('  entry_t     arbIn_entry [N_ENTRY];')
    W('  entry_t     arbOut_entry, enqEntry;')
    W('  logic       arbOut_valid, enqValid, enqReady, deqValid, deqReady;')
    W('  logic [1:0] arbOut_chosen, enqId, deqId;')
    W('')
    W("  assign inReq = '{")
    W(',\n'.join('    io_in_bits_%s' % f for f, _ in A))
    W('  };')
    W('')
    ms = []
    for f in MS_F:
        port = 'valid' if f == 'valid' else 'bits_' + f
        core = {'meta_prefetchSrc': 'prefetchSrc'}.get(f, f)
        ms.append(('ms_' + core, "'{" + ', '.join('io_mshrInfo_%d_%s' % (i, port) for i in range(N_MSHR)) + '}'))
    conns = [('clock', 'clock'), ('reset', 'reset'),
             ('in_valid', 'io_in_valid'), ('in_ready', 'io_in_ready'), ('in_req', 'inReq'),
             ('out_ready', 'io_out_ready'), ('out_valid', 'io_out_valid'), ('out_task', 'outTask')] + ms + [
             ('mainPipeBlock', "'{io_mainPipeBlock_0, io_mainPipeBlock_1}"),
             ('arbS2_valid', 'io_taskFromArb_s2_valid'), ('arbS2_channel', 'io_taskFromArb_s2_bits_channel'),
             ('arbS2_set', 'io_taskFromArb_s2_bits_set'), ('arbS2_mshrTask', 'io_taskFromArb_s2_bits_mshrTask'),
             ('s1Entrance_valid', 'io_s1Entrance_valid'), ('s1Entrance_set', 'io_s1Entrance_bits_set'),
             ('arbIn_valid', 'arbIn_valid'), ('arbIn_entry', 'arbIn_entry'),
             ('arbOut_valid', 'arbOut_valid'), ('arbOut_entry', 'arbOut_entry'), ('arbOut_chosen', 'arbOut_chosen'),
             ('chosenQ_enqValid', 'enqValid'), ('chosenQ_enqEntry', 'enqEntry'), ('chosenQ_enqId', 'enqId'),
             ('chosenQ_enqReady', 'enqReady'), ('chosenQ_deqValid', 'deqValid'), ('chosenQ_deqTask', 'deqTask'),
             ('chosenQ_deqId', 'deqId'), ('chosenQ_deqReady', 'deqReady'),
             ('aMergeTask_valid', 'io_aMergeTask_valid'), ('aMergeTask_id', 'io_aMergeTask_bits_id'),
             ('hasHitPfInMSHR_valid', 'io_hasHitPfInMSHR_valid'), ('hasHitPfInMSHR_bits', 'io_hasHitPfInMSHR_bits'),
             ('hasPfLateInMSHR_valid', 'io_hasPfLateInMSHR_valid'), ('hasMergeA', 'io_hasMergeA')]
    W('  xs_RequestBuffer_core u_core (')
    W(',\n'.join('    .%-22s (%s)' % c for c in conns))
    W('  );')
    W('')

    def ent_expr(var, f):
        if f in ('valid', 'rdy', 'waitMP', 'waitMS'):
            return '%s.%s' % (var, f)
        g = f[len('task_'):]
        return '%s.channel' % var if g == 'channel' else '%s.req.%s' % (var, fname(g))
    W('  // 发射仲裁：4 个表项 -> chosenQ（端口不带 ready，赢家下标走 io_chosen）')
    W('  FastArbiter_2 issueArb (')
    ac = [('clock', 'clock'), ('reset', 'reset')]
    for k in range(N_ENTRY):
        ac.append(('io_in_%d_valid' % k, 'arbIn_valid[%d]' % k))
        for f, _ in E:
            ac.append(('io_in_%d_bits_%s' % (k, f), ent_expr('arbIn_entry[%d]' % k, f)))
    ac.append(('io_out_ready', 'enqReady'))
    ac.append(('io_out_valid', 'arbOut_valid'))
    for f, _ in E:
        ac.append(('io_out_bits_%s' % f, ent_expr('arbOut_entry', f)))
    ac.append(('io_chosen', 'arbOut_chosen'))
    W(',\n'.join('    .%-28s (%s)' % c for c in ac))
    W('  );')
    W('')
    W('  // 发射队列（1 项，pipe）：记下赢家与它的表项号')
    W('  Queue1_ChosenQBundle chosenQ (')
    qc = [('clock', 'clock'), ('reset', 'reset'), ('io_enq_ready', 'enqReady'), ('io_enq_valid', 'enqValid')]
    for f, _ in E:
        qc.append(('io_enq_bits_bits_%s' % f, ent_expr('enqEntry', f)))
    qc += [('io_enq_bits_id', 'enqId'), ('io_deq_ready', 'deqReady'), ('io_deq_valid', 'deqValid')]
    for f, _ in T:
        qc.append(('io_deq_bits_bits_task_%s' % f, 'deqTask.%s' % fname(f)))
    qc.append(('io_deq_bits_id', 'deqId'))
    W(',\n'.join('    .%-40s (%s)' % c for c in qc))
    W('  );')
    W('')
    W('  // 出口任务拆回端口；合并任务与统计里直接透传入口字段的部分')
    for f, _ in T:
        W('  assign io_out_bits_%s = outTask.%s;' % (f, fname(f)))
    for d, w, n in P:
        m = re.fullmatch(r'io_aMergeTask_bits_task_(\w+)', n)
        if m:
            W('  assign %s = io_in_bits_%s;' % (n, m.group(1)))
    W('  assign io_ATag = io_in_bits_tag;')
    W('  assign io_ASet = io_in_bits_set;')
    W('  assign io_hasPfLateInMSHR_bits = io_in_bits_reqSource;')
    W('')
    W('endmodule')
    return '\n'.join(L)


def emit_pins(A):
    """只钉 perf 专用的 12 个 1 位寄存器（其余寄存器 FM 自己按名 / 签名全部配上 —— 诊断跑实测 0 unmatched）。

    这 12 个只被 perf / assert 读，是两侧对称的未读寄存器；FM 不给未读寄存器做签名配对，golden 的匿名名
    REG / REG_<n> / enable_REG_<n> 与重写的语义名配不上，于是两侧各自落单 —— 必须按名钉。"""
    pins = []
    for k in range(N_ENTRY):
        pins.append(('REG' if k == 0 else 'REG_%d' % (2 * k), 'u_core/validPrev_reg\\[%d\\]' % k))
        pins.append(('REG_%d' % (2 * k + 1), 'u_core/timerClear_reg\\[%d\\]' % k))
        pins.append(('enable_REG' if k == 0 else 'enable_REG_%d' % k, 'u_core/histValidPrev_reg\\[%d\\]' % k))
    L = ['# RequestBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_reqbuf.py（勿手改）',
         '#',
         '# 只钉 perf 专用的 12 个 1 位寄存器（每个表项 3 个：RegNext(valid) / 清零脉冲 / 直方图采样），',
         '#   golden  REG / REG_<2k> / REG_<2k+1> / enable_REG[_k]   <->  重写  u_core/validPrev / timerClear / histValidPrev [k]',
         '# 它们只被 perf 打印与 ifndef SYNTHESIS 的 assert 读（两侧对称的未读寄存器），FM 不给未读寄存器做签名配对，',
         '# 名字又完全不同，不钉就两侧各自落单。其余寄存器（含 4 个对称表项）FM 按名 / 签名全部自动配上：',
         '# 诊断跑（不产 receipt）实测 0(0) unmatched compare points。',
         '# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
         '# fail-closed：逐条数返回值，拒一条或总数不等于字面位数就 error。进 fm.log 的输出一律 ASCII。',
         'set ::RB_PIN_EXPECT %d' % len(pins),
         'set ::RB_PIN_OK 0',
         'set ::RB_PIN_BAD 0',
         'proc rb_pin {r i} {',
         '  if {[set_user_match $r $i]} { incr ::RB_PIN_OK } else {',
         '    incr ::RB_PIN_BAD',
         '    if {$::RB_PIN_BAD <= 10} { puts "RB_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'puts "RB_PIN_BEGIN RequestBuffer expect=$::RB_PIN_EXPECT"']
    for r, i in pins:
        L.append('rb_pin r:/WORK/RequestBuffer/%s_reg i:/WORK/RequestBuffer/%s' % (r, i))
    L += ['puts "RB_PIN_END ok=$::RB_PIN_OK bad=$::RB_PIN_BAD expect=$::RB_PIN_EXPECT"',
          'if {$::RB_PIN_BAD != 0 || $::RB_PIN_OK != $::RB_PIN_EXPECT} {',
          '  error "RB_PIN_MISMATCH ok=$::RB_PIN_OK bad=$::RB_PIN_BAD expect=$::RB_PIN_EXPECT"',
          '}']
    return '\n'.join(L) + '\n', len(pins)


def replace_region(txt, tag, body):
    b = re.search(r'(// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(// END GENERATED\(%s\))' % (tag, tag), txt, re.S)
    assert b, '找不到 GENERATED(%s) 区' % tag
    indent = re.match(r'\s*', txt[txt.rfind('\n', 0, b.start()) + 1:]).group(0)
    return txt[:b.start()] + b.group(1) + body + '\n' + indent + b.group(3) + txt[b.end():]


def with_nav(txt):
    if txt.count('\n') + 1 <= 1500:
        return txt
    import tempfile
    import pathlib
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import gen_file_nav
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d) / 'RequestBuffer.sv'
        tmp.write_text(txt)
        gen_file_nav.apply(tmp)
        return tmp.read_text()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    P, A, T, E, _ = build()
    cur = open(RTL).read()
    new = replace_region(cur, 'types', emit_types(A, T))
    new = replace_region(new, 'wrapper', emit_wrapper(P, A, T, E))
    new = with_nav(new)
    pins, npins = emit_pins(A)
    curp = open(PINS).read() if os.path.exists(PINS) else None
    if a.check:
        bad = [p for p, c, n in ((RTL, cur, new), (PINS, curp, pins)) if c != n]
        for p in bad:
            print('DRIFT: %s' % p)
        return 1 if bad else 0
    if cur != new:
        open(RTL, 'w').write(new)
    os.makedirs(os.path.dirname(PINS), exist_ok=True)
    if curp != pins:
        open(PINS, 'w').write(pins)
    print('RequestBuffer: a_req_t %d 字段 / task_t %d 字段 / entry 载荷 %d 字段；钉点 %d 位' % (len(A), len(T), len(E), npins))
    return 0


if __name__ == '__main__':
    sys.exit(main())
