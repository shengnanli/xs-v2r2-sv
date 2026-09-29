#!/usr/bin/env python3
"""gen_l2_grantbuf.py —— GrantBuffer 的机械部分：TaskBundle 结构体、golden 同名 wrapper、FM 钉点。

可读核 xs_GrantBuffer_core 在 rtl/uncore/GrantBuffer.sv 里手写，本脚本**不碰**；它只原地替换同一文件的
GENERATED(task_t) / GENERATED(wrapper) 两个区，并写 verif/ut/GrantBuffer/fm_pins_pre.tcl：

  task_t   io_d_task_bits_task_* 的 94 个字段（顺序、位宽逐字取自 golden），并核对 child Queue16_GrantQueueTask
           的 io_enq_bits_task_* 字段表与之完全相同。第一个字段放最高位；`alias` 写成 alias_。
  wrapper  端口按 golden；三个 child 队列（grantQueue / grantQueueData0/1 / pftRespQueue）按 golden 实例名例化；
           grantStatus / pipeStatusVec 打包成核的数组口。
  pins     只钉 33 个两侧对称的未读寄存器位：perf 专用的 32 个 1 位寄存器（golden REG[_k] / enable_REG[_k] <-> 核
           validPrev / histValidPrev [k]）+ grantBuf param[2]（golden grantBuf_task_param[2] <-> 核 gb_param[2]，D 通道
           param 只有 2 位）。FM 不给未读寄存器做签名配对、名字又不同。其余寄存器按名自动配。

用法：python3 scripts/gen_l2_grantbuf.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'uncore', 'GrantBuffer.sv')
PINS = os.path.join(REPO, 'verif', 'ut', 'GrantBuffer', 'fm_pins_pre.tcl')
MOD = 'GrantBuffer'
SV_KEYWORDS = {'alias'}
N_INFLIGHT = 16
PIPE = [1, 2, 3, 4]
# grantQueue 出队字段 -> 核端口
DEQ = ['isKeyword', 'opcode', 'param', 'sourceId', 'denied', 'corrupt']


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('module %s(' % mod)
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def fname(f):
    return f + '_' if f in SV_KEYWORDS else f


def fields(P, prefix):
    return [(n[len(prefix):], w) for _, w, n in P if n.startswith(prefix)]


def build():
    P = ports(MOD)
    T = fields(P, 'io_d_task_bits_task_')
    assert len(T) == 94, len(T)
    QP = ports('Queue16_GrantQueueTask')
    assert fields(QP, 'io_enq_bits_task_') == T, 'grantQueue io_enq_bits_task 字段表不同'
    qdeq = {n[len('io_deq_bits_task_'):] for _, _, n in QP if n.startswith('io_deq_bits_task_')}
    assert qdeq == set(DEQ), qdeq
    names = {n for _, _, n in P}
    for i in range(N_INFLIGHT):
        for f in ('valid', 'set', 'tag'):
            assert 'io_grantStatus_%d_%s' % (i, f) in names
    for k in PIPE:
        assert 'io_pipeStatusVec_%d_valid' % k in names and 'io_pipeStatusVec_%d_bits_channel' % k in names
    return P, T


def emit_struct(T):
    L = ['  // TaskBundle（%d 个字段，%d 位）：字段顺序与位宽逐字取自 golden 端口 io_d_task_bits_task_*' % (len(T), sum(w for _, w in T)),
         '  typedef struct packed {']
    for f, w in T:
        L.append('    logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), fname(f)))
    L.append('  } task_t;')
    return '\n'.join(L)


def emit_wrapper(P, T):
    L = []
    W = L.append
    W('module %s' % MOD)
    W('  import grantbuf_pkg::*;')
    W('(')
    W(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    W(');')
    W('')
    W('  task_t        dTask;')
    W('  logic         q_enq_valid;')
    W('  task_t        q_enq_task;')
    W('  logic [7:0]   q_enq_grantid;')
    W('  logic         q_enq_ready;')
    W('  logic         q_deq_ready;')
    W('  logic         q_deq_valid;')
    W('  logic         q_deq_isKeyword;')
    W('  logic [3:0]   q_deq_opcode;')
    W('  logic [2:0]   q_deq_param;')
    W('  logic [6:0]   q_deq_sourceId;')
    W('  logic         q_deq_denied;')
    W('  logic         q_deq_corrupt;')
    W('  logic [7:0]   q_deq_grantid;')
    W('  logic [255:0] q_deq_data0;')
    W('  logic [255:0] q_deq_data1;')
    W('  logic [4:0]   q_count;')
    W('  logic         pft_enq_valid;')
    W('  logic         pft_enq_ready;')
    W('  logic [3:0]   pft_count;')
    W('  logic [30:0]  pft_deq_tag;')
    W('  logic         gs_valid [N_INFLIGHT];')
    W('  logic [8:0]   gs_set   [N_INFLIGHT];')
    W('  logic [30:0]  gs_tag   [N_INFLIGHT];')
    W('')
    W('  // golden 端口 -> TaskBundle 结构体')
    for f, _ in T:
        W('  assign dTask.%s = io_d_task_bits_task_%s;' % (fname(f), f))
    W('')
    conns = [('clock', 'clock'), ('reset', 'reset'),
             ('dTask_valid', 'io_d_task_valid'), ('dTask', 'dTask'),
             ('q_enq_valid', 'q_enq_valid'), ('q_enq_task', 'q_enq_task'), ('q_enq_grantid', 'q_enq_grantid'),
             ('q_enq_ready', 'q_enq_ready'),
             ('q_deq_ready', 'q_deq_ready'), ('q_deq_valid', 'q_deq_valid')]
    conns += [('q_deq_' + f, 'q_deq_' + f) for f in DEQ]
    conns += [('q_deq_grantid', 'q_deq_grantid'), ('q_deq_data0', 'q_deq_data0'), ('q_deq_data1', 'q_deq_data1'),
              ('q_count', 'q_count'),
              ('d_ready', 'io_d_ready'), ('d_valid', 'io_d_valid'), ('d_opcode', 'io_d_bits_opcode'),
              ('d_param', 'io_d_bits_param'), ('d_source', 'io_d_bits_source'), ('d_sink', 'io_d_bits_sink'),
              ('d_denied', 'io_d_bits_denied'), ('d_isKeyword', 'io_d_bits_echo_isKeyword'),
              ('d_data', 'io_d_bits_data'), ('d_corrupt', 'io_d_bits_corrupt'),
              ('e_valid', 'io_e_valid'), ('e_sink', 'io_e_bits_sink'),
              ('s1_b_tag', 'io_fromReqArb_status_s1_tags_1'), ('s1_b_set', 'io_fromReqArb_status_s1_sets_1'),
              ('pipe_valid', "'{" + ', '.join('io_pipeStatusVec_%d_valid' % k for k in PIPE) + '}'),
              ('pipe_channel', "'{" + ', '.join('io_pipeStatusVec_%d_bits_channel' % k for k in PIPE) + '}'),
              ('blockA_s1', 'io_toReqArb_blockSinkReqEntrance_blockA_s1'),
              ('blockB_s1', 'io_toReqArb_blockSinkReqEntrance_blockB_s1'),
              ('blockC_s1', 'io_toReqArb_blockSinkReqEntrance_blockC_s1'),
              ('blockMSHR', 'io_toReqArb_blockMSHRReqEntrance'),
              ('pft_enq_valid', 'pft_enq_valid'), ('pft_enq_ready', 'pft_enq_ready'), ('pft_count', 'pft_count'),
              ('gs_valid', 'gs_valid'), ('gs_set', 'gs_set'), ('gs_tag', 'gs_tag')]
    W('  xs_GrantBuffer_core u_core (')
    W(',\n'.join('    .%-14s (%s)' % c for c in conns))
    W('  );')
    W('')
    W('  // D 通道任务头队列（16 项；firtool 只存了出队用得到的字段，其余 enq 端口照接）')
    W('  Queue16_GrantQueueTask grantQueue (')
    qc = [('clock', 'clock'), ('reset', 'reset'), ('io_enq_ready', 'q_enq_ready'), ('io_enq_valid', 'q_enq_valid')]
    qc += [('io_enq_bits_task_%s' % f, 'q_enq_task.%s' % fname(f)) for f, _ in T]
    qc += [('io_enq_bits_grantid', 'q_enq_grantid'), ('io_deq_ready', 'q_deq_ready'), ('io_deq_valid', 'q_deq_valid')]
    qc += [('io_deq_bits_task_%s' % f, 'q_deq_%s' % f) for f in DEQ]
    qc += [('io_deq_bits_grantid', 'q_deq_grantid'), ('io_count', 'q_count')]
    W(',\n'.join('    .%-38s (%s)' % c for c in qc))
    W('  );')
    W('')
    W('  // 两拍数据各一个队列，与任务头队列同进同出')
    for k, sl in ((0, '255:0'), (1, '511:256')):
        W('  Queue16_GrantQueueData grantQueueData%d (' % k)
        dc = [('clock', 'clock'), ('reset', 'reset'), ('io_enq_valid', 'q_enq_valid'),
              ('io_enq_bits_data_data', 'io_d_task_bits_data_data[%s]' % sl),
              ('io_deq_ready', 'q_deq_ready'), ('io_deq_bits_data_data', 'q_deq_data%d' % k)]
        W(',\n'.join('    .%-22s (%s)' % c for c in dc))
        W('  );')
    W('')
    W('  // 预取响应队列（10 项，flow），出口就是 io_prefetchResp')
    W('  Queue10_GrantBuffer_Anon pftRespQueue (')
    pc = [('clock', 'clock'), ('reset', 'reset'), ('io_enq_ready', 'pft_enq_ready'), ('io_enq_valid', 'pft_enq_valid'),
          ('io_enq_bits_tag', 'io_d_task_bits_task_tag'), ('io_enq_bits_set', 'io_d_task_bits_task_set'),
          ('io_enq_bits_vaddr', 'io_d_task_bits_task_vaddr'), ('io_enq_bits_pfSource', 'io_d_task_bits_task_reqSource'),
          ('io_deq_ready', 'io_prefetchResp_ready'), ('io_deq_valid', 'io_prefetchResp_valid'),
          ('io_deq_bits_tag', 'pft_deq_tag'), ('io_deq_bits_set', 'io_prefetchResp_bits_set'),
          ('io_deq_bits_vaddr', 'io_prefetchResp_bits_vaddr'), ('io_deq_bits_pfSource', 'io_prefetchResp_bits_pfSource'),
          ('io_count', 'pft_count')]
    W(',\n'.join('    .%-20s (%s)' % c for c in pc))
    W('  );')
    W('  // PrefetchResp.tag 比 L2 tag 宽 2 位（预取器按更大的 tag 定义），高位补 0')
    W("  assign io_prefetchResp_bits_tag = {2'b00, pft_deq_tag};")
    W('')
    for i in range(N_INFLIGHT):
        W('  assign io_grantStatus_%d_valid = gs_valid[%d];' % (i, i))
        W('  assign io_grantStatus_%d_set   = gs_set[%d];' % (i, i))
        W('  assign io_grantStatus_%d_tag   = gs_tag[%d];' % (i, i))
    W('')
    W('endmodule')
    return '\n'.join(L)


def emit_pins():
    pins = []
    for k in range(N_INFLIGHT):
        sfx = '' if k == 0 else '_%d' % k
        pins.append(('REG%s_reg' % sfx, 'u_core/validPrev_reg\\[%d\\]' % k))
        pins.append(('enable_REG%s_reg' % sfx, 'u_core/histValidPrev_reg\\[%d\\]' % k))
    # grantBuf 暂存的 param 是 3 位（TaskBundle.param），但 D 通道 param 只有 2 位：两侧都只读 [1:0]，
    # 第 2 位是对称死位，名字又不同（grantBuf_task_param / u_core.gb_param），不钉就两侧各自落单。
    pins.append(('grantBuf_task_param_reg\\[2\\]', 'u_core/gb_param_reg\\[2\\]'))
    L = ['# GrantBuffer FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_grantbuf.py（勿手改）',
         '#',
         '# 钉 %d 个两侧都没有读者、名字又不同的寄存器位：' % len(pins),
         '# (1) perf 专用的 32 个 1 位寄存器（每个 inflight 项 2 个 RegNext(valid)）：',
         '#   golden  REG[_k] / enable_REG[_k]   <->  重写  u_core/validPrev / histValidPrev [k]',
         '# REG 只喂 perf 计时器 timers（计时器只被 ifndef SYNTHESIS 的 assert 读），enable_REG 谁也不读：',
         '# (2) grantBuf 暂存的 param[2]：golden grantBuf_task_param[2] <-> 重写 u_core/gb_param[2]；',
         '#     D 通道 param 只有 2 位，两侧都只读 [1:0]。',
         '# 两侧对称的未读寄存器，FM 不给未读寄存器做签名配对，名字又不同，不钉就两侧各自落单。',
         '# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
         '# fail-closed：逐条数返回值，拒一条或总数不等于字面位数就 error。进 fm.log 的输出一律 ASCII。',
         '# 本目录还有 Queue10_GrantBuffer_Anon 一个 FM 目标：钉点只对 top 为 GrantBuffer 时生效。',
         'if {$top eq "GrantBuffer"} {',
         'set ::GB_PIN_EXPECT %d' % len(pins),
         'set ::GB_PIN_OK 0',
         'set ::GB_PIN_BAD 0',
         'proc gb_pin {r i} {',
         '  if {[set_user_match $r $i]} { incr ::GB_PIN_OK } else {',
         '    incr ::GB_PIN_BAD',
         '    if {$::GB_PIN_BAD <= 10} { puts "GB_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'puts "GB_PIN_BEGIN GrantBuffer expect=$::GB_PIN_EXPECT"']
    for r, i in pins:
        L.append('gb_pin r:/WORK/GrantBuffer/%s i:/WORK/GrantBuffer/%s' % (r, i))
    L += ['puts "GB_PIN_END ok=$::GB_PIN_OK bad=$::GB_PIN_BAD expect=$::GB_PIN_EXPECT"',
          # 期望数量用字面整数（结构闸 P3 只认字面量 / `set <var> <整数>`，不认 $::var）
          'if {$::GB_PIN_BAD != 0 || $::GB_PIN_OK != %d} {' % len(pins),
          '  error "GB_PIN_MISMATCH ok=$::GB_PIN_OK bad=$::GB_PIN_BAD expect=$::GB_PIN_EXPECT"',
          '}',
          '}']
    return '\n'.join(L) + '\n'


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
        tmp = pathlib.Path(d) / 'GrantBuffer.sv'
        tmp.write_text(txt)
        gen_file_nav.apply(tmp)
        return tmp.read_text()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    P, T = build()
    cur = open(RTL).read()
    new = replace_region(cur, 'task_t', emit_struct(T))
    new = replace_region(new, 'wrapper', emit_wrapper(P, T))
    new = with_nav(new)
    pins = emit_pins()
    curp = open(PINS).read() if os.path.exists(PINS) else ''
    if a.check:
        bad = 0
        if cur != new:
            print('DRIFT: %s' % RTL)
            bad = 1
        if curp != pins:
            print('DRIFT: %s' % PINS)
            bad = 1
        return bad
    if cur != new:
        open(RTL, 'w').write(new)
    os.makedirs(os.path.dirname(PINS), exist_ok=True)
    if curp != pins:
        open(PINS, 'w').write(pins)
    print('GrantBuffer: task_t %d 字段 / %d 位；钉点 %d' % (len(T), sum(w for _, w in T), pins.count('\ngb_pin ')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
