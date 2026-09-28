#!/usr/bin/env python3
"""gen_l2_requestarb.py —— RequestArb 的机械部分：TaskBundle 结构体、golden 同名 wrapper、FM 钉点。

可读核 xs_RequestArb_core 在 rtl/uncore/RequestArb.sv 里手写，本脚本**不碰**；它只原地替换同一文件里的
两个 GENERATED 区，并写 verif/ut/RequestArb/fm_pins_pre.tcl：

  task_t   TaskBundle（KunminghuV2Config 单态化后的 94 个字段），字段表逐字取自 golden 的
           io_taskToPipe_s2_bits_* 端口（顺序、位宽）；并**核对** sinkA/sinkB/sinkC/mshrTask/taskInfo_s1
           五组端口的字段集合与位宽都与它完全相同（dontTouch(io) 保证了没有被 DCE 的字段）。
           第一个端口字段放在结构体最高位；`alias` 是 SV 保留字，写成 alias_。
  wrapper  四组输入 bits 按字段装成 task_t；task_s2 / task_s1 拆回 taskToPipe_s2 / taskInfo_s1 端口；
           其余端口逐个接核。msInfo_*（dontTouch 保留、RequestArb 不读）不接。
  pins     golden 的 mshr_task_s1_bits_<f> / task_s2_bits_<f> 扁平寄存器（共 2 x 94 个）与重写核里
           两个 task_t 结构体寄存器的逐位对应。fail-closed：每条 set_user_match 数返回值，拒一条或
           总数不等于字面位数即 error；只消名差，不约束 ref。

用法：python3 scripts/gen_l2_requestarb.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = os.path.join(REPO, 'rtl', 'uncore', 'RequestArb.sv')
PINS = os.path.join(REPO, 'verif', 'ut', 'RequestArb', 'fm_pins_pre.tcl')
MOD = 'RequestArb'
SV_KEYWORDS = {'alias'}


def ports():
    t = open(os.path.join(G, MOD + '.sv')).read()
    i = t.index('module %s(' % MOD)
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if m:
            out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t


def fname(f):
    return f + '_' if f in SV_KEYWORDS else f


def fields_of(P, prefix):
    return [(n[len(prefix):], w) for _, w, n in P if n.startswith(prefix)]


def build():
    P, gtxt = ports()
    F = fields_of(P, 'io_taskToPipe_s2_bits_')
    assert len(F) == 94, len(F)
    for grp in ('io_sinkA_bits_', 'io_sinkB_bits_', 'io_sinkC_bits_', 'io_mshrTask_bits_', 'io_taskInfo_s1_bits_'):
        assert fields_of(P, grp) == F, '%s 的字段表与 taskToPipe_s2 不同' % grp
    # golden 寄存器表：mshr_task_s1_bits_<f> / task_s2_bits_<f> 必须与字段表一一对应
    regs = dict((m.group(2), 1 if m.group(1) is None else int(m.group(1)) + 1)
                for m in re.finditer(r'\n  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', gtxt))
    for pre in ('mshr_task_s1_bits_', 'task_s2_bits_'):
        got = sorted((k[len(pre):], w) for k, w in regs.items() if k.startswith(pre))
        assert got == sorted(F), '%s 寄存器表与字段表不一致' % pre
    return P, F


def emit_struct(F):
    L = ['  // TaskBundle（94 个字段，%d 位）：字段顺序与位宽逐字取自 golden 端口 io_taskToPipe_s2_bits_*' % sum(w for _, w in F),
         '  typedef struct packed {']
    for f, w in F:
        L.append('    logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), fname(f)))
    L.append('  } task_t;')
    return '\n'.join(L)


def emit_wrapper(P, F):
    L = []
    A = L.append
    A('module %s' % MOD)
    A('  import requestarb_pkg::*;')
    A('(')
    A(',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P))
    A(');')
    A('')
    A('  task_t sinkA_task, sinkB_task, sinkC_task, mshrTask_task, task_s1, task_s2_bits;')
    A('  logic  task_s1_valid, s1_fire, task_s2_valid;')
    A('  logic [30:0] mshrTaskS1_tag;')
    A('  logic [8:0]  mshrTaskS1_set;')
    A('')
    A('  // 四路输入按字段装成 task_t')
    for grp, var in (('io_sinkA_bits_', 'sinkA_task'), ('io_sinkB_bits_', 'sinkB_task'),
                     ('io_sinkC_bits_', 'sinkC_task'), ('io_mshrTask_bits_', 'mshrTask_task')):
        A("  assign %s = '{" % var)
        A(',\n'.join('    %s%s' % (grp, f) for f, _ in F))
        A('  };')
    A('')
    conns = [('clock', 'clock'), ('reset', 'reset'),
             ('sinkA_valid', 'io_sinkA_valid'), ('sinkA_ready', 'io_sinkA_ready'), ('sinkA_task', 'sinkA_task'),
             ('sinkB_valid', 'io_sinkB_valid'), ('sinkB_ready', 'io_sinkB_ready'), ('sinkB_task', 'sinkB_task'),
             ('sinkC_valid', 'io_sinkC_valid'), ('sinkC_ready', 'io_sinkC_ready'), ('sinkC_task', 'sinkC_task'),
             ('mshrTask_valid', 'io_mshrTask_valid'), ('mshrTask_ready', 'io_mshrTask_ready'),
             ('mshrTask_task', 'mshrTask_task'),
             ('blockA_mshrCtl', 'io_fromMSHRCtl_blockA_s1'), ('blockB_mshrCtl', 'io_fromMSHRCtl_blockB_s1'),
             ('blockC_mshrCtl', 'io_fromMSHRCtl_blockC_s1'),
             ('blockA_mainPipe', 'io_fromMainPipe_blockA_s1'), ('blockB_mainPipe', 'io_fromMainPipe_blockB_s1'),
             ('blockC_mainPipe', 'io_fromMainPipe_blockC_s1'), ('blockG_mainPipe', 'io_fromMainPipe_blockG_s1'),
             ('blockA_grantBuf', 'io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1'),
             ('blockB_grantBuf', 'io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1'),
             ('blockC_grantBuf', 'io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1'),
             ('blockMSHR_grantBuf', 'io_fromGrantBuffer_blockMSHRReqEntrance'),
             ('blockSinkB_txdat', 'io_fromTXDAT_blockSinkBReqEntrance'),
             ('blockMSHR_txdat', 'io_fromTXDAT_blockMSHRReqEntrance'),
             ('blockSinkB_txrsp', 'io_fromTXRSP_blockSinkBReqEntrance'),
             ('blockMSHR_txrsp', 'io_fromTXRSP_blockMSHRReqEntrance'),
             ('blockMSHR_txreq', 'io_fromTXREQ_blockMSHRReqEntrance'),
             ('dirRead_ready', 'io_dirRead_s1_ready'), ('dirRead_valid', 'io_dirRead_s1_valid'),
             ('dirRead_wayMask', 'io_dirRead_s1_bits_wayMask'),
             ('dirRead_refill_prefetch', 'io_dirRead_s1_bits_replacerInfo_refill_prefetch'),
             ('dirRead_refill', 'io_dirRead_s1_bits_refill'),
             ('task_s1_valid', 'task_s1_valid'), ('task_s1', 'task_s1'), ('s1_fire', 's1_fire'),
             ('task_s2_valid', 'task_s2_valid'), ('task_s2_bits', 'task_s2_bits'),
             ('s1Entrance_valid', 'io_s1Entrance_valid'), ('s1Entrance_set', 'io_s1Entrance_bits_set'),
             ('mshrTaskS1_tag', 'mshrTaskS1_tag'), ('mshrTaskS1_set', 'mshrTaskS1_set'),
             ('refillBufRead_valid', 'io_refillBufRead_s2_valid'), ('refillBufRead_id', 'io_refillBufRead_s2_bits_id'),
             ('releaseBufRead_valid', 'io_releaseBufRead_s2_valid'),
             ('releaseBufRead_id', 'io_releaseBufRead_s2_bits_id')]
    A('  xs_RequestArb_core u_core (')
    A(',\n'.join('    .%-24s (%s)' % c for c in conns))
    A('  );')
    A('')
    A('  // s1：目录读请求的其余字段直接取自 s1 任务')
    A('  assign io_dirRead_s1_bits_tag                   = task_s1.tag;')
    A('  assign io_dirRead_s1_bits_set                   = task_s1.set;')
    A('  assign io_dirRead_s1_bits_replacerInfo_channel   = task_s1.channel;')
    A('  assign io_dirRead_s1_bits_replacerInfo_opcode    = task_s1.opcode[2:0];')
    A('  assign io_dirRead_s1_bits_replacerInfo_reqSource = task_s1.reqSource;')
    A('  assign io_dirRead_s1_bits_mshrId                = task_s1.mshrId;')
    A('  assign io_dirRead_s1_bits_cmoAll                = task_s1.cmoAll;')
    A('  assign io_dirRead_s1_bits_cmoWay                = task_s1.way;')
    A('')
    A('  // 各级状态（给 MSHRCtl / MainPipe / TX 通道做冲突与反压判断）')
    A('  assign io_status_s1_tags_0 = io_sinkC_bits_tag;')
    A('  assign io_status_s1_tags_1 = io_sinkB_bits_tag;')
    A('  assign io_status_s1_tags_2 = io_ATag;')
    A('  assign io_status_s1_tags_3 = mshrTaskS1_tag;')
    A('  assign io_status_s1_sets_0 = io_sinkC_bits_set;')
    A('  assign io_status_s1_sets_1 = io_sinkB_bits_set;')
    A('  assign io_status_s1_sets_2 = io_ASet;')
    A('  assign io_status_s1_sets_3 = mshrTaskS1_set;')
    A('  assign io_status_vec_0_valid              = task_s1_valid;')
    A('  assign io_status_vec_0_bits_channel       = task_s1.channel;')
    A('  assign io_status_vec_1_valid              = task_s2_valid;')
    A('  assign io_status_vec_1_bits_channel       = task_s2_bits.channel;')
    A('  assign io_status_vec_toTX_0_valid         = task_s1_valid;')
    A('  assign io_status_vec_toTX_0_bits_channel  = task_s1.channel;')
    A('  assign io_status_vec_toTX_0_bits_txChannel = task_s1.txChannel;')
    A('  assign io_status_vec_toTX_0_bits_mshrTask = task_s1.mshrTask;')
    A('  assign io_status_vec_toTX_1_valid         = task_s2_valid;')
    A('  assign io_status_vec_toTX_1_bits_channel  = task_s2_bits.channel;')
    A('  assign io_status_vec_toTX_1_bits_txChannel = task_s2_bits.txChannel;')
    A('  assign io_status_vec_toTX_1_bits_mshrTask = task_s2_bits.mshrTask;')
    A('')
    A('  // s2 任务送 MainPipe；s1 任务信息（valid = s1_fire）')
    A('  assign io_taskToPipe_s2_valid = task_s2_valid;')
    A('  assign io_taskInfo_s1_valid   = s1_fire;')
    for f, _ in F:
        A('  assign io_taskToPipe_s2_bits_%s = task_s2_bits.%s;' % (f, fname(f)))
    for f, _ in F:
        A('  assign io_taskInfo_s1_bits_%s = task_s1.%s;' % (f, fname(f)))
    A('')
    A('endmodule')
    return '\n'.join(L)


def emit_pins(F):
    total_w = sum(w for _, w in F)
    L = ['# RequestArb FM「匹配前」钉点 —— 自动生成：scripts/gen_l2_requestarb.py（勿手改）',
         '#',
         '# 只消 golden 扁平寄存器名（mshr_task_s1_bits_<f> / task_s2_bits_<f>）与重写核里两个 task_t',
         '# 结构体寄存器（u_core/mshr_task_s1_bits / u_core/task_s2_bits）之间的命名鸿沟。',
         '# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。',
         '# fail-closed：逐条数返回值；拒一条或总数不等于字面位数就 error（safe interp 里不用 exit）。',
         '# 进 fm.log 的输出一律 ASCII。',
         'set ::RA_PIN_EXPECT %d' % (2 * total_w),
         'set ::RA_PIN_OK 0',
         'set ::RA_PIN_BAD 0',
         'proc ra_pin {r i} {',
         '  if {[set_user_match $r $i]} { incr ::RA_PIN_OK } else {',
         '    incr ::RA_PIN_BAD',
         '    if {$::RA_PIN_BAD <= 10} { puts "RA_PIN_FAIL: $r <-> $i" }',
         '  }',
         '}',
         'puts "RA_PIN_BEGIN RequestArb expect=$::RA_PIN_EXPECT"']
    for gname, iname in (('mshr_task_s1_bits', 'mshr_task_s1_bits'), ('task_s2_bits', 'task_s2_bits')):
        hi = total_w
        for f, w in F:
            lo = hi - w
            for b in range(w):
                r = 'r:/WORK/RequestArb/%s_%s_reg' % (gname, f) + ('' if w == 1 else '\\[%d\\]' % b)
                i = 'i:/WORK/RequestArb/u_core/%s_reg\\[%d\\]' % (iname, lo + b)
                L.append('ra_pin %s %s' % (r, i))
            hi = lo
    L += ['puts "RA_PIN_END ok=$::RA_PIN_OK bad=$::RA_PIN_BAD expect=$::RA_PIN_EXPECT"',
          'if {$::RA_PIN_BAD != 0 || $::RA_PIN_OK != $::RA_PIN_EXPECT} {',
          '  error "RA_PIN_MISMATCH ok=$::RA_PIN_OK bad=$::RA_PIN_BAD expect=$::RA_PIN_EXPECT"',
          '}']
    return '\n'.join(L) + '\n'


def replace_region(txt, tag, body):
    b = re.search(r'(// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(// END GENERATED\(%s\))' % (tag, tag), txt, re.S)
    assert b, '找不到 GENERATED(%s) 区' % tag
    indent = re.match(r'\s*', txt[txt.rfind('\n', 0, b.start()) + 1:]).group(0)
    return txt[:b.start()] + b.group(1) + body + '\n' + indent + b.group(3) + txt[b.end():]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    P, F = build()
    cur = open(RTL).read()
    new = replace_region(cur, 'task_t', emit_struct(F))
    new = replace_region(new, 'wrapper', emit_wrapper(P, F))
    pins = emit_pins(F)
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
    print('RequestArb: task_t %d 字段 / %d 位；钉点 %d 位' % (len(F), sum(w for _, w in F), 2 * sum(w for _, w in F)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
