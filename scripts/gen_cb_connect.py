#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_cb_connect.py —— CtrlBlock 流水连接族两个 child 的生成器：PipelineConnectPipe / PipeGroupConnect。

两者都是 CtrlBlock 内部"打拍 + 握手"的纯连接件，逻辑只有几行，体积全在 payload
（DecodedInst 束：一百多个字段）上：

  PipelineConnectPipe  译码 → 重命名 的单拍流水缓冲，CtrlBlock 例化 6 次
                        （decodePipeRenameModule ~ _5，同一模块）。golden 848 行 / 235 端口。
  PipeGroupConnect     重命名 → 派遣 的 6 lane 成组流水缓冲，CtrlBlock 例化 1 次
                        （renamePipeDispatch）。golden 5039 行 / 1626 端口。

为什么用生成器而不是手写：端口表、packed struct 成员表、打包/拆包赋值、位宽自检、
tb 的驱动/比对/覆盖代码全部是 G1 golden 端口表的机械函数——两个模块合计
120 + 6×134 个字段。手抄正是 NewPipelineConnectPipe 一族历史上集体配错的成因。
本脚本从 `$GOLDEN_RTL/<名>.sv` 现场解析端口表与模块体，顺序、位宽、方向逐项照抄。

★与 NewPipelineConnectPipe 家族的差别（不能直接复用 rtl/common/PipelineConnect.sv）★：
  * PipelineConnectPipe 的握手是**老式 PipelineConnect**：`in_ready = out_ready`、
    `fire = in_valid & out_ready`（不是 New 家族的 `out_ready | ~valid`）。
  * PipelineConnectPipe 有 13 个**只有出口没有入口**的字段（lsrc_3/lsrc_4/vpu_frm/
    vpu_vxrm/vpu_vuopIdx/vpu_vmask/vpu_vl/vpu_fpu_isFpToVecInst/…/vpu_lastUop/vpu_isMove）：
    上游 DecodeStage 把它们写成常量 0，firtool 把入口端口折掉了，但**寄存器还在**——
    fire 拍装入 0，其余拍保持（golden 写法 `data_x <= 6'h0` / `data_x <= ~leftFire & data_x`）。
    bug-for-bug：这些字段进 payload、入口恒接 0，寄存器与 golden 一一对应。
  * PipeGroupConnect 是 6 lane 共一个 canAcc 的成组握手：
    `canAcc = outAllFire | (validVec == 0)`，每 lane `fire_i = in_i_valid & canAcc`，
    `valid_i' = ~flush & (fire_i | ~out_i_ready & valid_i)`。lane 0 比其它 lane 多一个
    `snapshot` 字段（下游只有 lane 0 用它，其余 lane 的寄存器被 firtool 消掉了），
    所以 lane 0 与 lane 1~5 是两个不同宽度的 payload struct。

生成物（可复跑，幂等；`--check` 同时核对 golden 语义**并**比对产物是否漂移）：
  rtl/backend/PipelineConnectPipe.sv
  rtl/backend/PipeGroupConnect.sv
  verif/ut/PipelineConnectPipe/tb.sv          verif/ut/PipelineConnectPipe/negtest.sv
  verif/ut/PipeGroupConnect/tb.sv             verif/ut/PipeGroupConnect/negtest.sv
（两个 UT 的 Makefile 是手写的，不由本脚本产出。）

fail-closed：端口行解析不了、模块体语义与上面描述的形状不符（握手方程、逐字段
RegEnable 直连、in/out 字段集对称性）任一条不成立，立即退出，不生成任何东西。

用法：
  python3 scripts/gen_cb_connect.py            # 写入仓库
  python3 scripts/gen_cb_connect.py --check     # 核对 golden 语义 + 产物漂移（进 gate_all.sh）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('GOLDEN_RTL',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))

_PORT = re.compile(r'^\s*(input|output)\s+'
                   r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?'
                   r'([A-Za-z_]\w*)\s*,?\s*$')
_REG_DECL = re.compile(r'^\s+reg\s+(?:\[\s*(\d+)\s*:\s*0\s*\]\s*)?([A-Za-z_]\w*);', re.M)


class GoldenError(Exception):
    """golden 不符合预期 —— 一律 fail-closed，绝不"照猜"生成。"""


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
def parse_ports(name):
    """返回 (ports, body)。ports = [(dir, width, name)]，顺序照 golden。"""
    path = GOLDEN / (name + '.sv')
    lines = path.read_text().split('\n')
    try:
        i = next(k for k, l in enumerate(lines)
                 if re.match(r'^module\s+%s\s*\(' % re.escape(name), l)) + 1
    except StopIteration:
        raise GoldenError('%s: 找不到 module %s(' % (path, name))
    ports = []
    while not re.match(r'^\s*\)\s*;\s*$', lines[i]):
        m = _PORT.match(lines[i])
        if not m:
            raise GoldenError('%s:%d 端口行看不懂: %r' % (path, i + 1, lines[i]))
        if m.group(3) is not None and int(m.group(3)) != 0:
            raise GoldenError('%s:%d 非零 lsb，本生成器不支持' % (path, i + 1))
        w = 1 if m.group(2) is None else int(m.group(2)) + 1
        ports.append((m.group(1), w, m.group(4)))
        i += 1
    return ports, '\n'.join(lines[i:])


def reg_widths(body):
    return dict((m.group(2), 1 if m.group(1) is None else int(m.group(1)) + 1)
                for m in _REG_DECL.finditer(body))


def fields_of(ports, prefix):
    return [(p[len(prefix):], w) for _d, w, p in ports if p.startswith(prefix)]


def parse_pcp():
    """PipelineConnectPipe：返回 (ports, infields, outfields, zero_fields)。

    机械核对：
      * io_in_ready = io_out_ready；leftFire = io_in_valid & io_out_ready
      * valid' = ~io_isFlush & (leftFire | ~io_rightOutFire & valid)，异步复位清 0
      * 每个 io_out_bits_X 由 data_X 驱动；每个 data_X 要么在 if (leftFire) 块里从
        io_in_bits_X 装载（有入口的字段），要么装 0 / `~leftFire & data_X`（无入口的字段）
      * 入口字段 ⊂ 出口字段，同名同宽；出口里多出来的正是那批装 0 的字段
    """
    name = 'PipelineConnectPipe'
    ports, body = parse_ports(name)
    if not re.search(r'assign io_in_ready = io_out_ready;', body):
        raise GoldenError('%s: in_ready 不是 = io_out_ready' % name)
    if not re.search(r'wire\s+leftFire = io_in_valid & io_out_ready;', body):
        raise GoldenError('%s: leftFire 不是 in_valid & out_ready' % name)
    m = re.search(r'always @\(posedge clock or posedge reset\) begin\s*'
                  r'if \(reset\)\s*valid <= 1\'h0;\s*else\s*valid <= (.+?);', body, re.S)
    if not m or m.group(1).strip() != '~io_isFlush & (leftFire | ~io_rightOutFire & valid)':
        raise GoldenError('%s: valid 次态不是期望形状' % name)
    if not re.search(r'assign io_out_valid = valid;', body):
        raise GoldenError('%s: out_valid 不是 = valid' % name)

    infields = fields_of(ports, 'io_in_bits_')
    outfields = fields_of(ports, 'io_out_bits_')
    inw = dict(infields)
    outw = dict(outfields)
    for f, w in infields:
        if outw.get(f) != w:
            raise GoldenError('%s: 入口字段 %s(%d) 在出口缺失或位宽不同' % (name, f, w))
    zero_fields = [f for f, _w in outfields if f not in inw]

    m = re.search(r'always @\(posedge clock\) begin\s*if \(leftFire\) begin\n(.*?)\n\s*end\n(.*?)\n\s*end // always @\(posedge\)',
                  body, re.S)
    if not m:
        raise GoldenError('%s: 找不到 if (leftFire) 的数据寄存块' % name)
    loaded, zeroed = {}, set()
    for ln in m.group(1).split('\n'):
        ln = ln.strip()
        if not ln:
            continue
        mm = re.match(r'(data_\w+) <= io_in_bits_(\w+);$', ln)
        if mm:
            if mm.group(1) != 'data_' + mm.group(2):
                raise GoldenError('%s: %s 装载源不是同名端口' % (name, ln))
            loaded[mm.group(2)] = True
            continue
        mm = re.match(r'data_(\w+) <= \d+\'h0;$', ln)
        if mm:
            zeroed.add(mm.group(1))
            continue
        raise GoldenError('%s: if (leftFire) 块里有看不懂的行: %r' % (name, ln))
    for ln in m.group(2).split('\n'):
        ln = ln.strip()
        if not ln:
            continue
        mm = re.match(r'data_(\w+) <= ~leftFire & data_(\w+);$', ln)
        if not mm or mm.group(1) != mm.group(2):
            raise GoldenError('%s: 数据块尾部有看不懂的行: %r' % (name, ln))
        zeroed.add(mm.group(1))
    if set(loaded) != set(inw):
        raise GoldenError('%s: 装载字段集 != 入口字段集: %s'
                          % (name, sorted(set(loaded) ^ set(inw))))
    if zeroed != set(zero_fields):
        raise GoldenError('%s: 装 0 字段集 != (出口-入口): %s'
                          % (name, sorted(zeroed ^ set(zero_fields))))
    drives = dict(re.findall(r'assign io_out_bits_(\w+) = (\w+);', body))
    for f, _w in outfields:
        if drives.get(f) != 'data_' + f:
            raise GoldenError('%s: io_out_bits_%s 不是由 data_%s 驱动' % (name, f, f))
    rw = reg_widths(body)
    for f, w in outfields:
        if rw.get('data_' + f) != w:
            raise GoldenError('%s: reg data_%s 位宽 %r != 端口 %d' % (name, f, rw.get('data_' + f), w))
    return ports, infields, outfields, zero_fields


def parse_pgc():
    """PipeGroupConnect：返回 (ports, lanes)。lanes[i] = [(field, w)]（照 golden 顺序）。

    机械核对：
      * canAcc = io_outAllFire | {validVec_5..0} == 6'h0；io_in_i_ready = canAcc
      * validVec_i' = ~io_flush & (io_in_i_valid & canAcc | ~io_out_i_ready & validVec_i)
      * dataVec_i_X 在 if (io_in_i_valid & canAcc) 块里从 io_in_i_bits_X 装载；
        io_out_i_bits_X 由 dataVec_i_X 驱动；每 lane in/out 字段集与位宽逐项相同
      * lane 1~5 字段集相同；lane 0 = lane 1 + snapshot（位置照 golden）
    """
    name = 'PipeGroupConnect'
    ports, body = parse_ports(name)
    n = 6
    if not re.search(r'wire\s+canAcc =\s*io_outAllFire\s*\| \{validVec_5, validVec_4, validVec_3, validVec_2, validVec_1, validVec_0\} == 6\'h0;',
                     body):
        raise GoldenError('%s: canAcc 方程不是期望形状' % name)
    for i in range(n):
        if not re.search(r'validVec_%d <= ~io_flush & \(io_in_%d_valid & canAcc \| ~io_out_%d_ready & validVec_%d\);'
                         % (i, i, i, i), body):
            raise GoldenError('%s: validVec_%d 次态不是期望形状' % (name, i))
        if not re.search(r'assign io_in_%d_ready = canAcc;' % i, body):
            raise GoldenError('%s: io_in_%d_ready 不是 = canAcc' % (name, i))
        if not re.search(r'assign io_out_%d_valid = validVec_%d;' % (i, i), body):
            raise GoldenError('%s: io_out_%d_valid 不是 = validVec_%d' % (name, i, i))
    if not re.search(r'if \(reset\) begin\s*' + r'\s*'.join(r'validVec_%d <= 1\'h0;' % i for i in range(n)), body):
        raise GoldenError('%s: validVec 复位块不是期望形状' % name)

    lanes = []
    rw = reg_widths(body)
    drives = dict(('%s_%s' % (a, b), c) for a, b, c in
                  re.findall(r'assign io_out_(\d)_bits_(\w+) = (\w+);', body))
    for i in range(n):
        inf = fields_of(ports, 'io_in_%d_bits_' % i)
        outf = fields_of(ports, 'io_out_%d_bits_' % i)
        if inf != outf:
            raise GoldenError('%s: lane %d in/out 字段表不同' % (name, i))
        m = re.search(r'if \(io_in_%d_valid & canAcc\) begin\n(.*?)\n\s*end' % i, body, re.S)
        if not m:
            raise GoldenError('%s: 找不到 lane %d 的装载块' % (name, i))
        loaded = set()
        for ln in m.group(1).split('\n'):
            ln = ln.strip()
            mm = re.match(r'dataVec_%d_(\w+) <= io_in_%d_bits_(\w+);$' % (i, i), ln)
            if not mm or mm.group(1) != mm.group(2):
                raise GoldenError('%s: lane %d 装载块有看不懂的行: %r' % (name, i, ln))
            loaded.add(mm.group(1))
        if loaded != set(f for f, _w in inf):
            raise GoldenError('%s: lane %d 装载字段集 != 端口字段集' % (name, i))
        for f, w in inf:
            if drives.get('%d_%s' % (i, f)) != 'dataVec_%d_%s' % (i, f):
                raise GoldenError('%s: io_out_%d_bits_%s 驱动源不对' % (name, i, f))
            if rw.get('dataVec_%d_%s' % (i, f)) != w:
                raise GoldenError('%s: reg dataVec_%d_%s 位宽不对' % (name, i, f))
        lanes.append(inf)
    for i in range(2, n):
        if lanes[i] != lanes[1]:
            raise GoldenError('%s: lane %d 字段表 != lane 1' % (name, i))
    if [f for f in lanes[0] if f[0] != 'snapshot'] != lanes[1]:
        raise GoldenError('%s: lane 0 去掉 snapshot 后 != lane 1' % name)
    if ('snapshot', 1) not in lanes[0]:
        raise GoldenError('%s: lane 0 没有 snapshot' % name)
    return ports, lanes


# ---------------------------------------------------------------------------
# 字段分组注释（只影响 struct 里的注释，不影响任何功能）
# ---------------------------------------------------------------------------
GROUPS = [
    ('exceptionVec_',     'exc',     'exceptionVec：24 位异常向量（逐位一个端口）'),
    ('preDecodeInfo_',    'predec',  'preDecodeInfo：前端预译码信息（分支类型/call/ret/RVC）'),
    ('ftq',               'ftq',     'ftqPtr/ftqOffset：取指队列指针（flag=回绕位）与块内偏移'),
    ('srcType_',          'srctype', 'srcType：5 个源操作数的类型编码'),
    ('lsrc_',             'lreg',    'lsrc/ldest：逻辑寄存器号'),
    ('fpu_',              'fpu',     'fpu：标量浮点控制（typeTag/wflags/typ/fmt/rm）'),
    ('vpu_',              'vpu',     'vpu：向量控制（vtype 及其 spec 副本 / vstart / vmask / vl / 向量 uop 属性）'),
    ('psrc_',             'preg',    'psrc/pdest：重命名后的物理寄存器号'),
    ('robIdx_',           'rob',     'robIdx：ROB 表项指针（flag=回绕位）'),
    ('traceBlockInPipe_', 'trace',   'traceBlockInPipe：RISC-V trace 字段'),
    ('debugInfo_',        'dbginfo', 'debugInfo：性能剖析时间戳'),
    ('debug_',            'dbg',     'debug_*：调试用透传字段（fuType 副本 / 序号 / sim 触发）'),
]
SINGLES = {
    'instr': ('fetch', '取指结果：指令字 / PC / 折叠 PC'),
    'pc': ('fetch', None), 'foldpc': ('fetch', None),
    'isFetchMalAddr': ('fexc', '取指异常汇总与触发器动作'),
    'hasException': ('fexc', None), 'trigger': ('fexc', None),
    'pred_taken': ('pred', '分支预测结果与跨页取指异常修正'),
    'crossPageIPFFix': ('pred', None), 'satpFlushFirstFetchFault': ('pred', None),
    'ldest': ('lreg', 'lsrc/ldest：逻辑寄存器号'),
    'fuType': ('ctrl', '译码控制位：功能单元类型与操作 / 写使能 / 顺序约束 / 立即数'),
    'fuOpType': ('ctrl', None), 'rfWen': ('ctrl', None), 'fpWen': ('ctrl', None),
    'vecWen': ('ctrl', None), 'v0Wen': ('ctrl', None), 'vlWen': ('ctrl', None),
    'isXSTrap': ('ctrl', None), 'waitForward': ('ctrl', None), 'blockBackward': ('ctrl', None),
    'flushPipe': ('ctrl', None), 'canRobCompress': ('ctrl', None), 'selImm': ('ctrl', None),
    'imm': ('ctrl', None),
    'vlsInstr': ('uop', 'uop 拆分信息与提交类型'),
    'wfflags': ('uop', None), 'isMove': ('uop', None), 'uopIdx': ('uop', None),
    'uopSplitType': ('uop', None), 'isVset': ('uop', None), 'firstUop': ('uop', None),
    'lastUop': ('uop', None), 'numUops': ('uop', None), 'numWB': ('uop', None),
    'commitType': ('uop', None), 'numLsElem': ('uop', None),
    'pdest': ('preg', 'psrc/pdest：重命名后的物理寄存器号'),
    'instrSize': ('commit', 'ROB 压缩组大小与 FS/VS 脏位'),
    'dirtyFs': ('commit', None), 'dirtyVs': ('commit', None),
    'eliminatedMove': ('rename', '重命名阶段属性：move 消除 / 快照点'),
    'snapshot': ('rename', None),
}


def group_of(field):
    if field in SINGLES:
        key, gloss = SINGLES[field]
        if gloss is None:
            gloss = next(g for k, g in SINGLES.values() if k == key and g)
        return key, gloss
    for pref, key, gloss in GROUPS:
        if field.startswith(pref):
            return key, gloss
    return 'misc', '其它控制位'


def grouped(fields):
    """[(field,w)] -> [(note_or_None, field, w)]；组变化时给出注释文本，重复出现只写（续）。"""
    out, prev, seen = [], None, set()
    for f, w in fields:
        key, gloss = group_of(f)
        note = None
        if key != prev:
            note = gloss if key not in seen else gloss.split('：')[0] + '（续）'
            seen.add(key)
            prev = key
        out.append((note, f, w))
    return out


def decl(width):
    return '' if width == 1 else '[%d:0] ' % (width - 1)


def emit_struct(L, fields, tname, indent='  '):
    L.append('%stypedef struct packed {' % indent)
    for note, f, w in grouped(fields):
        if note:
            L.append('%s  // %s' % (indent, note))
        L.append('%s  logic %-9s %s;' % (indent, decl(w).strip(), f))
    L.append('%s} %s;' % (indent, tname))


def port_lines(ports):
    return ',\n'.join('  %-6s logic %s%s' % (d, decl(w), pn) for d, w, pn in ports)


# ---------------------------------------------------------------------------
# PipelineConnectPipe.sv
# ---------------------------------------------------------------------------
def gen_pcp_rtl(ports, infields, outfields, zero_fields):
    name = 'PipelineConnectPipe'
    total = sum(w for _f, w in outfields)
    in_bits = sum(w for _f, w in infields)
    zw = dict(outfields)
    zero_bits = sum(zw[f] for f in zero_fields)
    nin = sum(1 for d, _w, _p in ports if d == 'input')
    L = [
        '// PipelineConnectPipe.sv — CtrlBlock 里译码(DecodeStage)→重命名(Rename)之间的单拍流水缓冲。',
        '// 例化点（G1 golden）：CtrlBlock.decodePipeRenameModule ~ decodePipeRenameModule_5，',
        '//   6 条译码 lane 各一个，**同一个模块例化 6 次**（一个 FM target）。',
        '// 层次：CtrlBlock 的直接 child，0 子模块；golden 848 行 / %d 端口（%d 输入 / %d 输出）。'
        % (len(ports), nin, len(ports) - nin),
        '//',
        '// 核心机制（老式 PipelineConnect，与 NewPipelineConnectPipe 家族**不同**，不能共用',
        '//   rtl/common/PipelineConnect.sv 那个核）：',
        '//   in_ready = out_ready                       —— 直通下游 ready，没有"空即可收"项',
        '//   fire     = in_valid & out_ready',
        "//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)   （异步复位清 0）",
        '//   data     = RegEnable(in_bits, fire)         —— 全部字段打拍，无组合直通',
        '//   rightOutFire 由调用方给（CtrlBlock 接的是 rename 侧的 fire），与 out_ready 不必同步。',
        '//',
        '// ★payload 里 %d 个字段只有出口没有入口★（%s）：'
        % (len(zero_fields), ' / '.join(zero_fields)),
        '//   上游 DecodeStage 把它们写成常量 0，firtool 把入口端口折掉了，但寄存器还在——',
        '//   golden 写成 `data_x <= 0`（fire 拍）或 `data_x <= ~leftFire & data_x`，两种写法',
        '//   都是"fire 拍装 0、其余拍保持"。bug-for-bug：这些字段进 payload、入口恒接 0，',
        '//   寄存器与 golden 一一对应（复位前为 X，首个 fire 后恒 0，与 golden 一致）。',
        '//   payload 合计 %d 字段 / %d 位 = 入口 %d 位 + 恒 0 字段 %d 位。'
        % (len(outfields), total, in_bits, zero_bits),
        '//',
        '// 本文件由 scripts/gen_cb_connect.py 从 G1 golden 端口表生成，勿手改；',
        '// golden 对照：G1-canonical/golden-rtl/PipelineConnectPipe.sv。',
        '',
        '// ============================================================================',
        '// package：payload 布局。用 packed struct 而不是手工位切片：入口打包与出口拆包都按',
        '// 同一组成员名访问，字段错位在结构上就不可能发生。成员顺序照 golden 出口端口表。',
        '// ============================================================================',
        'package pipelineconnectpipe_pkg;',
    ]
    emit_struct(L, outfields, 'payload_t')
    L += [
        '',
        '  // G1 golden 出口端口（= 数据寄存器）位宽之和，传给核做 elaborate 期防呆。',
        '  localparam int unsigned PAYLOAD_W_G1 = %d;' % total,
        'endpackage',
        '',
        '// ============================================================================',
        '// 核：valid 寄存器 + RegEnable 数据寄存器 + 老式握手。payload 当一坨位搬运。',
        '// ============================================================================',
        'module xs_PipelineConnectPipe_core #(',
        '  parameter int unsigned DATA_WIDTH   = 1,',
        '  // G1 锚点（fail-closed）：wrapper 把 PAYLOAD_W_G1 原样传进来，核校验它 == 实际 payload',
        '  // 位数。默认 0 = 没传，直接 $fatal（不给"不传即不校验"留路）。',
        '  parameter int unsigned PAYLOAD_W_G1 = 0',
        ')(',
        '  input  logic                  clock,',
        '  input  logic                  reset,          // 异步高有效，仅复位 valid',
        '  output logic                  io_in_ready,',
        '  input  logic                  io_in_valid,',
        '  input  logic [DATA_WIDTH-1:0] io_in_bits,',
        '  input  logic                  io_out_ready,',
        '  output logic                  io_out_valid,',
        '  output logic [DATA_WIDTH-1:0] io_out_bits,',
        '  input  logic                  io_rightOutFire,',
        '  input  logic                  io_isFlush',
        ');',
        '',
        '  // elaborate 期参数自检（模块体里的 $fatal：VCS 在 elaborate 阶段就拦，Formality 读得进）。',
        '  if (PAYLOAD_W_G1 == 0)',
        '    $fatal(1, "xs_PipelineConnectPipe_core: wrapper must pass PAYLOAD_W_G1 (sum of G1 golden io_out_bits_* widths); DATA_WIDTH=%0d",',
        '           DATA_WIDTH);',
        '  if (DATA_WIDTH != PAYLOAD_W_G1)',
        '    $fatal(1, "xs_PipelineConnectPipe_core: packed payload is %0d bits != G1 golden sum %0d bits -- struct and G1 port table diverged",',
        '           DATA_WIDTH, PAYLOAD_W_G1);',
        '',
        '  logic                  valid;',
        '  logic [DATA_WIDTH-1:0] data;',
        '  logic                  fire;',
        '',
        '  // 老式握手：ready 直通，不看本级是否为空。',
        '  assign io_in_ready = io_out_ready;',
        '  assign fire        = io_in_valid & io_out_ready;',
        '',
        '  always_ff @(posedge clock or posedge reset) begin',
        '    if (reset) valid <= 1\'b0;',
        '    else       valid <= ~io_isFlush & (fire | (~io_rightOutFire & valid));',
        '  end',
        '',
        '  always_ff @(posedge clock) begin',
        '    if (fire) data <= io_in_bits;',
        '  end',
        '',
        '  assign io_out_valid = valid;',
        '  assign io_out_bits  = data;',
        '',
        'endmodule',
        '',
        '// ============================================================================',
        '// wrapper：golden 同名同端口。只做打包/拆包 + 位宽不变式，不含任何握手逻辑。',
        '// ============================================================================',
        'module %s import pipelineconnectpipe_pkg::*; (' % name,
        port_lines(ports),
        ');',
        '',
        '  payload_t in_payload, out_payload;',
        '',
        '  // 入口打包：端口 -> struct 成员（同名逐项）',
        '  always_comb begin',
    ]
    wid = max(len(f) for f, _w in outfields)
    for f, _w in infields:
        L.append('    in_payload.%-*s = io_in_bits_%s;' % (wid, f, f))
    L.append('    // 只有出口没有入口的字段：golden 里入口已被常量 0 折叠（见文件头），恒接 0')
    for f in zero_fields:
        L.append("    in_payload.%-*s = '0;" % (wid, f))
    L += [
        '  end',
        '',
        '  // 出口拆包：struct 成员 -> 端口（同名逐项）',
    ]
    for f, _w in outfields:
        L.append('  assign io_out_bits_%-*s = out_payload.%s;' % (wid, f, f))
    L += [
        '',
        '  // ---------------------------------------------------------------------------',
        '  // elaborate 期位宽不变式：入口端口位宽之和 + 恒 0 字段位宽 == 出口端口位宽之和',
        '  // == PAYLOAD_W_G1 == $bits(payload_t)（后一个等号由核校验）。任何一个端口或 struct',
        '  // 成员的位宽被改动，这几个数就不再相等。逐端口对 G1 golden 的权威闸仍是',
        '  // scripts/port_contract_lint.py，这里只是把同类错误提前到 elaborate。',
        '  // ---------------------------------------------------------------------------',
    ]
    for label, flist in (('IN', infields), ('OUT', outfields)):
        L.append('  localparam int unsigned %s_PORT_BITS =' % label)
        terms = ['$bits(io_%s_bits_%s)' % (label.lower(), f) for f, _w in flist]
        for k in range(0, len(terms), 4):
            chunk = ' + '.join(terms[k:k + 4])
            L.append('    ' + chunk + (' +' if k + 4 < len(terms) else ';'))
    L += [
        '  localparam int unsigned ZERO_FIELD_BITS = %d;' % zero_bits,
        '',
        '  if (IN_PORT_BITS + ZERO_FIELD_BITS != PAYLOAD_W_G1)',
        '    $fatal(1, "%s: input port bits %%0d + zero fields %%0d != G1 golden %%0d",' % name,
        '           IN_PORT_BITS, ZERO_FIELD_BITS, PAYLOAD_W_G1);',
        '  if (OUT_PORT_BITS != PAYLOAD_W_G1)',
        '    $fatal(1, "%s: output port bits %%0d != G1 golden %%0d", OUT_PORT_BITS, PAYLOAD_W_G1);' % name,
        '',
        '  xs_PipelineConnectPipe_core #(',
        '    .DATA_WIDTH   ($bits(payload_t)),',
        '    .PAYLOAD_W_G1 (PAYLOAD_W_G1)',
        '  ) u_core (',
        '    .clock           (clock),',
        '    .reset           (reset),',
        '    .io_in_ready     (io_in_ready),',
        '    .io_in_valid     (io_in_valid),',
        '    .io_in_bits      (in_payload),',
        '    .io_out_ready    (io_out_ready),',
        '    .io_out_valid    (io_out_valid),',
        '    .io_out_bits     (out_payload),',
        '    .io_rightOutFire (io_rightOutFire),',
        '    .io_isFlush      (io_isFlush)',
        '  );',
        '',
        'endmodule',
        '',
    ]
    return '\n'.join(L)


# ---------------------------------------------------------------------------
# PipeGroupConnect.sv
# ---------------------------------------------------------------------------
def gen_pgc_rtl(ports, lanes):
    name = 'PipeGroupConnect'
    n = len(lanes)
    w0 = sum(w for _f, w in lanes[0])
    w1 = sum(w for _f, w in lanes[1])
    nin = sum(1 for d, _w, _p in ports if d == 'input')
    L = [
        '// PipeGroupConnect.sv — CtrlBlock 里重命名(Rename)→派遣(Dispatch)之间的 6 lane 成组单拍流水缓冲。',
        '// 例化点（G1 golden，唯一一处）：CtrlBlock.renamePipeDispatch。',
        '// 层次：CtrlBlock 的直接 child，0 子模块；golden 5039 行 / %d 端口（%d 输入 / %d 输出）。'
        % (len(ports), nin, len(ports) - nin),
        '//',
        '// 核心机制（成组握手：6 条 lane 要么一起收、要么一起等）：',
        '//   canAcc     = outAllFire | (validVec == 0)      —— 下游整组取走、或本级全空，才收新一组',
        '//   in_i_ready = canAcc                            —— 6 个 ready 是同一根线',
        '//   fire_i     = in_i_valid & canAcc',
        "//   valid_i'   = ~flush & (fire_i | ~out_i_ready & valid_i)   （异步复位清 0）",
        '//   data_i     = RegEnable(in_i_bits, fire_i)      —— 全部字段打拍，无组合直通',
        '//   outAllFire 由调用方给（CtrlBlock 接的是 dispatch 侧"整组 fire"），与 out_i_ready 不必同步。',
        '//',
        '// ★lane 0 比其它 lane 多一个 snapshot 字段★：下游只用 lane 0 的 snapshot，lane 1~5 的',
        '//   那个寄存器被 firtool 消掉（入口出口一起没了）。所以 lane 0 用 payload_snap_t（%d 字段 / %d 位），'
        % (len(lanes[0]), w0),
        '//   lane 1~5 用 payload_t（%d 字段 / %d 位）。数据寄存器按 lane 各例化一个 slot，宽度各取各的；'
        % (len(lanes[1]), w1),
        '//   握手在一个核里做（canAcc 要看全部 6 个 valid）。',
        '//',
        '// 本文件由 scripts/gen_cb_connect.py 从 G1 golden 端口表生成，勿手改；',
        '// golden 对照：G1-canonical/golden-rtl/PipeGroupConnect.sv。',
        '//',
        '// 本文件导航（行号由生成器写入）：',
        '@@NAV@@',
        '',
        '// ============================================================================',
        '// package：两种 payload 布局（lane 0 带 snapshot）。成员顺序照 golden 各 lane 端口表。',
        '// ============================================================================',
        'package pipegroupconnect_pkg;',
        '  localparam int unsigned N_LANES = %d;' % n,
        '',
        '  // lane 1~5 的 payload',
    ]
    emit_struct(L, lanes[1], 'payload_t')
    L += ['', '  // lane 0 的 payload（多一个 snapshot，位置照 golden）']
    emit_struct(L, lanes[0], 'payload_snap_t')
    L += [
        '',
        '  // G1 golden 各 lane 入口端口位宽之和，传给 slot 做 elaborate 期防呆。',
        '  localparam int unsigned LANE0_W_G1 = %d;' % w0,
        '  localparam int unsigned LANE_W_G1  = %d;' % w1,
        'endpackage',
        '',
        '// ============================================================================',
        '// 核：成组握手（canAcc / validVec / 各 lane fire）。不碰数据。',
        '// ============================================================================',
        'module xs_PipeGroupConnect_core #(',
        '  parameter int unsigned N = 6',
        ')(',
        '  input  logic         clock,',
        '  input  logic         reset,          // 异步高有效，仅复位 valid_vec',
        '  input  logic [N-1:0] io_in_valid,',
        '  output logic         io_in_ready,    // = canAcc，N 条 lane 共用',
        '  input  logic [N-1:0] io_out_ready,',
        '  output logic [N-1:0] io_out_valid,',
        '  input  logic         io_flush,',
        '  input  logic         io_outAllFire,',
        '  output logic [N-1:0] lane_fire       // 各 lane 的数据寄存器使能',
        ');',
        '',
        '  logic [N-1:0] valid_vec;',
        '  logic         can_acc;',
        '',
        '  // 整组收新数据的条件：下游本拍整组取走，或本级 6 条 lane 全空。',
        '  assign can_acc   = io_outAllFire | ~(|valid_vec);',
        '  assign lane_fire = io_in_valid & {N{can_acc}};',
        '',
        '  always_ff @(posedge clock or posedge reset) begin',
        '    if (reset) valid_vec <= \'0;',
        '    else       valid_vec <= {N{~io_flush}} & (lane_fire | (~io_out_ready & valid_vec));',
        '  end',
        '',
        '  assign io_in_ready  = can_acc;',
        '  assign io_out_valid = valid_vec;',
        '',
        'endmodule',
        '',
        '// ============================================================================',
        '// slot：一条 lane 的数据寄存器 = RegEnable(in_bits, fire)。宽度按 lane 各取各的。',
        '// ============================================================================',
        'module xs_PipeGroupConnect_slot #(',
        '  parameter int unsigned W    = 1,',
        '  // G1 锚点（fail-closed）：wrapper 把该 lane 的 G1 位宽和传进来，默认 0 = 没传，直接 $fatal。',
        '  parameter int unsigned W_G1 = 0',
        ')(',
        '  input  logic         clock,',
        '  input  logic         fire,',
        '  input  logic [W-1:0] io_in_bits,',
        '  output logic [W-1:0] io_out_bits',
        ');',
        '',
        '  if (W_G1 == 0)',
        '    $fatal(1, "xs_PipeGroupConnect_slot: wrapper must pass W_G1 (sum of G1 golden lane port widths); W=%0d", W);',
        '  if (W != W_G1)',
        '    $fatal(1, "xs_PipeGroupConnect_slot: packed payload is %0d bits != G1 golden sum %0d bits -- struct and G1 port table diverged",',
        '           W, W_G1);',
        '',
        '  logic [W-1:0] data;',
        '',
        '  always_ff @(posedge clock) begin',
        '    if (fire) data <= io_in_bits;',
        '  end',
        '',
        '  assign io_out_bits = data;',
        '',
        'endmodule',
        '',
        '// ============================================================================',
        '// wrapper：golden 同名同端口。只做打包/拆包 + 位宽不变式 + 例化，不含握手逻辑。',
        '// ============================================================================',
        'module %s import pipegroupconnect_pkg::*; (' % name,
        port_lines(ports),
        ');',
        '',
        '  payload_snap_t in_payload_0, out_payload_0;',
    ]
    for i in range(1, n):
        L.append('  payload_t      in_payload_%d, out_payload_%d;' % (i, i))
    L += [
        '',
        '  logic [N_LANES-1:0] in_valid, out_ready, out_valid, lane_fire;',
        '  logic               in_ready;',
        '',
        '  assign in_valid  = {%s};' % ', '.join('io_in_%d_valid' % i for i in range(n - 1, -1, -1)),
        '  assign out_ready = {%s};' % ', '.join('io_out_%d_ready' % i for i in range(n - 1, -1, -1)),
    ]
    for i in range(n):
        L.append('  assign io_in_%d_ready  = in_ready;' % i)
    for i in range(n):
        L.append('  assign io_out_%d_valid = out_valid[%d];' % (i, i))
    L += [
        '',
        '  xs_PipeGroupConnect_core #(.N(N_LANES)) u_core (',
        '    .clock         (clock),',
        '    .reset         (reset),',
        '    .io_in_valid   (in_valid),',
        '    .io_in_ready   (in_ready),',
        '    .io_out_ready  (out_ready),',
        '    .io_out_valid  (out_valid),',
        '    .io_flush      (io_flush),',
        '    .io_outAllFire (io_outAllFire),',
        '    .lane_fire     (lane_fire)',
        '  );',
        '',
    ]
    for i in range(n):
        ty = 'payload_snap_t' if i == 0 else 'payload_t'
        g1 = 'LANE0_W_G1' if i == 0 else 'LANE_W_G1'
        L += [
            '  xs_PipeGroupConnect_slot #(.W($bits(%s)), .W_G1(%s)) u_slot_%d (' % (ty, g1, i),
            '    .clock       (clock),',
            '    .fire        (lane_fire[%d]),' % i,
            '    .io_in_bits  (in_payload_%d),' % i,
            '    .io_out_bits (out_payload_%d)' % i,
            '  );',
        ]
    wid = max(len(f) for f, _w in lanes[0])
    for i in range(n):
        L += [
            '',
            '  // ---------------------------------------------------------------------------',
            '  // lane %d：入口打包 / 出口拆包（同名逐项）' % i,
            '  // ---------------------------------------------------------------------------',
            '  always_comb begin',
        ]
        for f, _w in lanes[i]:
            L.append('    in_payload_%d.%-*s = io_in_%d_bits_%s;' % (i, wid, f, i, f))
        L.append('  end')
        for f, _w in lanes[i]:
            L.append('  assign io_out_%d_bits_%-*s = out_payload_%d.%s;' % (i, wid, f, i, f))
    L += [
        '',
        '  // ---------------------------------------------------------------------------',
        '  // elaborate 期位宽不变式：每 lane 入口端口位宽之和 == 出口端口位宽之和 == 该 lane 的',
        '  // G1 位宽和（== $bits(struct)，最后一个等号由 slot 校验）。',
        '  // ---------------------------------------------------------------------------',
    ]
    for i in range(n):
        for side in ('in', 'out'):
            L.append('  localparam int unsigned %s%d_PORT_BITS =' % (side.upper(), i))
            terms = ['$bits(io_%s_%d_bits_%s)' % (side, i, f) for f, _w in lanes[i]]
            for k in range(0, len(terms), 4):
                chunk = ' + '.join(terms[k:k + 4])
                L.append('    ' + chunk + (' +' if k + 4 < len(terms) else ';'))
    L.append('')
    for i in range(n):
        g1 = 'LANE0_W_G1' if i == 0 else 'LANE_W_G1'
        L += [
            '  if (IN%d_PORT_BITS != %s || OUT%d_PORT_BITS != %s)' % (i, g1, i, g1),
            '    $fatal(1, "%s: lane %d port bits in=%%0d out=%%0d != G1 golden %%0d", IN%d_PORT_BITS, OUT%d_PORT_BITS, %s);'
            % (name, i, i, i, g1),
        ]
    L += ['', 'endmodule', '']
    text = '\n'.join(L)

    # 本文件导航：行号必须真落在分节注释上（readability_audit E 类判据）。
    lines = text.split('\n')
    nav_at = lines.index('@@NAV@@')
    marks = [
        ('package pipegroupconnect_pkg;', 'package：payload 布局'),
        ('module xs_PipeGroupConnect_core #(', '核：成组握手'),
        ('module xs_PipeGroupConnect_slot #(', 'slot：单 lane 数据寄存器'),
        ('module %s import pipegroupconnect_pkg::*; (' % name, 'wrapper：端口表'),
    ] + [('  // lane %d：入口打包 / 出口拆包（同名逐项）' % i, 'wrapper：lane %d 打包/拆包' % i) for i in range(n)] + [
        ('  // elaborate 期位宽不变式：每 lane 入口端口位宽之和 == 出口端口位宽之和 == 该 lane 的', 'wrapper：位宽不变式'),
    ]
    # 替换后占位行变成 len(marks) 行，其后每一行的 1-based 行号 = 原 0-based 下标 + len(marks)。
    # 导航指向 needle 行本身：它要么就是分节注释（lane 段），要么紧贴在 "// ====" 分节注释下面。
    nav = [(lines.index(needle) + len(marks), label) for needle, label in marks]
    lines[nav_at:nav_at + 1] = ['//   L%-5d %s' % (ln, label) for ln, label in nav]
    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
def rnd(w):
    k = (w + 31) // 32
    if k == 1:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * k))


TB_COMMON = r'''`timescale 1ns/1ps

`define CHECK(TAG,SIG) begin \
  if (!$isunknown(g_``TAG``_``SIG)) begin \
    checks++; \
    if (g_``TAG``_``SIG !== i_``TAG``_``SIG) begin \
      errors++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s.%s g=%0h i=%0h", $time, `"TAG`", `"SIG`", \
                                 g_``TAG``_``SIG, i_``TAG``_``SIG); \
    end \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  longint checks = 0;
  always #5 clock = ~clock;

  int cov_fail = 0;
  task automatic gate(string nm, longint got, longint need, string why);
    if (got < need) begin
      $display("COVERAGE HOLE: %s = %0d < %0d —— %s", nm, got, need, why);
      cov_fail++;
    end
  endtask
'''

TB_TAIL = r'''
    if (cov_fail != 0) begin
      $display("TEST FAILED (%0d 个覆盖闸没过)", cov_fail);
      $fatal(1);
    end
    if (errors == 0 && checks > 100000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
'''


def gen_pcp_tb(ports, infields, outfields):
    name = 'PipelineConnectPipe'
    total = sum(w for _f, w in infields)
    L = [
        '// PipelineConnectPipe UT —— golden vs 派生 PipelineConnectPipe_xs 双例化，同激励逐拍比全部输出。',
        '//',
        '// 被测语义（核 xs_PipelineConnectPipe_core，见 rtl/backend/PipelineConnectPipe.sv）：',
        '//   in_ready = out_ready；fire = in_valid & out_ready',
        "//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)（异步复位清 0）",
        '//   data     = RegEnable(in_bits, fire)；13 个无入口字段 fire 拍装 0',
        '//',
        '// 覆盖闸（流水连接件极易假绿：握手永远畅通、flush 永不触发也能 errors=0）：',
        '//   fire / 反压(in_valid & ~out_ready) / hold(valid & ~rightOutFire) / deq(valid & rightOutFire) /',
        '//   占用中被改写(valid & fire) / flush 命中占用中的表项 / flush 与 fire 同拍（冲刷优先级）/',
        '//   入口 payload 每一位都取到过 1、也取到过 0（位宽写窄或字段漏掉不会假绿）。',
        '// 采样时机：覆盖在**时钟沿之前**采（沿后采永远看不到 flush——它把 valid 清了）。',
        '// 无入口字段的出口在首个 fire 前是 X（golden 亦然）：CHECK 宏遇 golden X 跳过，之后恒 0 参与比对。',
        '//',
        '// 本文件由 scripts/gen_cb_connect.py 生成，勿手改。',
        TB_COMMON,
        '  // ---- 激励与两侧输出 ----',
        '  logic io_in_valid, io_out_ready, io_rightOutFire, io_isFlush;',
    ]
    for f, w in infields:
        L.append('  logic %sio_in_bits_%s;' % (decl(w), f))
    L.append('  wire  g_p_io_in_ready, i_p_io_in_ready, g_p_io_out_valid, i_p_io_out_valid;')
    for f, w in outfields:
        L.append('  wire  %sg_p_io_out_bits_%s, i_p_io_out_bits_%s;' % (decl(w), f, f))
    cat = ', '.join('io_in_bits_%s' % f for f, _w in infields)
    L += [
        '  longint n_fire = 0, n_bp = 0, n_hold = 0, n_deq = 0, n_owr = 0, n_flush = 0, n_flfire = 0;',
        "  logic [%d:0] por = '0, pand = '1;   // 入口 payload 逐位或 / 逐位与" % (total - 1),
        '  wire  [%d:0] pcat = {%s};' % (total - 1, cat),
        '',
    ]
    for pfx, mod, inst in (('g_p', name, 'u_golden'), ('i_p', name + '_xs', 'u_impl')):
        L.append('  %s %s (' % (mod, inst))
        cl = ['    .clock(clock), .reset(reset)', '    .io_in_valid(io_in_valid)']
        cl += ['    .io_in_bits_%s(io_in_bits_%s)' % (f, f) for f, _w in infields]
        cl += ['    .io_out_ready(io_out_ready)', '    .io_rightOutFire(io_rightOutFire)',
               '    .io_isFlush(io_isFlush)',
               '    .io_in_ready(%s_io_in_ready)' % pfx, '    .io_out_valid(%s_io_out_valid)' % pfx]
        cl += ['    .io_out_bits_%s(%s_io_out_bits_%s)' % (f, pfx, f) for f, _w in outfields]
        L.append(',\n'.join(cl))
        L.append('  );')
        L.append('')
    L += [
        '  task automatic drive_all();',
        '    io_in_valid     = ($urandom % 100) < 75;',
        '    io_out_ready    = ($urandom % 100) < 55;',
        '    io_rightOutFire = ($urandom % 100) < 50;',
        '    io_isFlush      = ($urandom % 512) == 0;',
    ]
    for f, w in infields:
        L.append('    io_in_bits_%s = %s;' % (f, rnd(w)))
    L += [
        '  endtask',
        '',
        '  task automatic check_all();',
        '    `CHECK(p,io_in_ready)',
        '    `CHECK(p,io_out_valid)',
    ]
    for f, _w in outfields:
        L.append('    `CHECK(p,io_out_bits_%s)' % f)
    L += [
        '  endtask',
        '',
        '  task automatic sample_cov();',
        '    if (io_in_valid && io_out_ready) begin',
        '      n_fire++; por |= pcat; pand &= pcat;',
        '      if (io_isFlush) n_flfire++;',
        "      if (g_p_io_out_valid === 1'b1) n_owr++;",
        '    end',
        '    if (io_in_valid && !io_out_ready) n_bp++;',
        "    if (g_p_io_out_valid === 1'b1) begin",
        '      if (io_isFlush) n_flush++;',
        '      if (io_rightOutFire) n_deq++; else n_hold++;',
        '    end',
        '  endtask',
        '',
        '  initial begin',
        '    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end',
        "    reset = 1'b1;",
        '    drive_all();',
        '    repeat (8) @(posedge clock);',
        "    reset = 1'b0;",
        '    repeat (NCYCLES) begin',
        '      @(negedge clock);',
        '      drive_all();',
        '      #1 sample_cov();          // 沿前采：见文件头「采样时机」',
        '      @(posedge clock);',
        '      #1 check_all();',
        '    end',
        '    $display("\\n==== %s: checks=%%0d errors=%%0d (ncycles=%%0d) ====", checks, errors, NCYCLES);' % name,
        '    $display("fire=%0d backpr=%0d hold=%0d deq=%0d owrite=%0d flush=%0d flush&fire=%0d payload=%s",',
        '             n_fire, n_bp, n_hold, n_deq, n_owr, n_flush, n_flfire,',
        "             ((&por) && (pand == '0)) ? \"ok\" : \"HOLE\");",
        '    gate("fire",       n_fire,   1000, "从没锁进过数据");',
        '    gate("backpr",     n_bp,      100, "上游从没被挡过（握手永远畅通=假绿）");',
        '    gate("hold",       n_hold,    100, "表项从没被压住过");',
        '    gate("deq",        n_deq,     100, "表项从没被下游取走过");',
        '    gate("owr",        n_owr,     100, "从没在占用中被新数据改写过");',
        '    gate("flush",      n_flush,    10, "flush 从没命中占用中的表项");',
        '    gate("flush&fire", n_flfire,   10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");',
        '    if (!(&por)) begin $display("COVERAGE HOLE: 入口 payload 有位从未取到 1"); cov_fail++; end',
        "    if (pand != '0) begin $display(\"COVERAGE HOLE: 入口 payload 有位从未取到 0\"); cov_fail++; end",
        TB_TAIL,
    ]
    return '\n'.join(L)


def gen_pgc_tb(ports, lanes):
    name = 'PipeGroupConnect'
    n = len(lanes)
    L = [
        '// PipeGroupConnect UT —— golden vs 派生 PipeGroupConnect_xs 双例化，同激励逐拍比全部输出。',
        '//',
        '// 被测语义（核 xs_PipeGroupConnect_core + 6 个 slot，见 rtl/backend/PipeGroupConnect.sv）：',
        '//   canAcc = outAllFire | (validVec == 0)；in_i_ready = canAcc；fire_i = in_i_valid & canAcc',
        "//   valid_i' = ~flush & (fire_i | ~out_i_ready & valid_i)（异步复位清 0）",
        '//   data_i = RegEnable(in_i_bits, fire_i)',
        '//',
        '// 覆盖闸（按 lane 计数，每条 lane 都要过）：',
        '//   fire / 反压(in_valid & ~canAcc) / hold(valid & ~out_ready) / deq(valid & out_ready) /',
        '//   占用中被改写(valid & fire) / flush 命中占用中的表项 / 入口 payload 每一位都取到过 1 和 0；',
        '//   整组级：canAcc **仅因 outAllFire** 成立的拍（outAllFire & validVec!=0）——不打到就等于',
        '//   没测 outAllFire 那一项；flush 与 fire 同拍（冲刷优先级）。',
        '// 采样时机：覆盖在**时钟沿之前**采（沿后采永远看不到 flush——它把 valid 清了）。',
        '//',
        '// 本文件由 scripts/gen_cb_connect.py 生成，勿手改。',
        TB_COMMON,
        '  // ---- 激励与两侧输出 ----',
        '  logic io_flush, io_outAllFire;',
    ]
    for i in range(n):
        L.append('  logic io_in_%d_valid, io_out_%d_ready;' % (i, i))
        for f, w in lanes[i]:
            L.append('  logic %sio_in_%d_bits_%s;' % (decl(w), i, f))
    for i in range(n):
        L.append('  wire  g_l%d_io_in_ready, i_l%d_io_in_ready, g_l%d_io_out_valid, i_l%d_io_out_valid;' % (i, i, i, i))
        for f, w in lanes[i]:
            L.append('  wire  %sg_l%d_io_out_bits_%s, i_l%d_io_out_bits_%s;' % (decl(w), i, f, i, f))
    L.append('  longint n_fire[%d], n_bp[%d], n_hold[%d], n_deq[%d], n_owr[%d], n_flush[%d];' % ((n,) * 6))
    L.append('  longint n_allfire = 0, n_flfire = 0;')
    for i in range(n):
        tot = sum(w for _f, w in lanes[i])
        cat = ', '.join('io_in_%d_bits_%s' % (i, f) for f, _w in lanes[i])
        L.append("  logic [%d:0] por_%d = '0, pand_%d = '1;" % (tot - 1, i, i))
        L.append('  wire  [%d:0] pcat_%d = {%s};' % (tot - 1, i, cat))
    L.append('')
    for pfx, mod, inst in (('g', name, 'u_golden'), ('i', name + '_xs', 'u_impl')):
        L.append('  %s %s (' % (mod, inst))
        cl = ['    .clock(clock), .reset(reset)', '    .io_flush(io_flush), .io_outAllFire(io_outAllFire)']
        for i in range(n):
            cl.append('    .io_in_%d_valid(io_in_%d_valid), .io_in_%d_ready(%s_l%d_io_in_ready)' % (i, i, i, pfx, i))
            cl.append('    .io_out_%d_ready(io_out_%d_ready), .io_out_%d_valid(%s_l%d_io_out_valid)' % (i, i, i, pfx, i))
            cl += ['    .io_in_%d_bits_%s(io_in_%d_bits_%s)' % (i, f, i, f) for f, _w in lanes[i]]
            cl += ['    .io_out_%d_bits_%s(%s_l%d_io_out_bits_%s)' % (i, f, pfx, i, f) for f, _w in lanes[i]]
        L.append(',\n'.join(cl))
        L.append('  );')
        L.append('')
    L += [
        '  task automatic drive_all();',
        '    io_flush      = ($urandom % 512) == 0;',
        '    io_outAllFire = ($urandom % 100) < 40;',
    ]
    for i in range(n):
        L.append('    io_in_%d_valid  = ($urandom %% 100) < 70;' % i)
        L.append('    io_out_%d_ready = ($urandom %% 100) < 55;' % i)
        for f, w in lanes[i]:
            L.append('    io_in_%d_bits_%s = %s;' % (i, f, rnd(w)))
    L += ['  endtask', '', '  task automatic check_all();']
    for i in range(n):
        L.append('    `CHECK(l%d,io_in_ready)' % i)
        L.append('    `CHECK(l%d,io_out_valid)' % i)
        for f, _w in lanes[i]:
            L.append('    `CHECK(l%d,io_out_bits_%s)' % (i, f))
    L += [
        '  endtask',
        '',
        '  task automatic sample_cov();',
        '    logic any_valid;',
        '    any_valid = %s;' % ' || '.join("(g_l%d_io_out_valid === 1'b1)" % i for i in range(n)),
        "    if (io_outAllFire && any_valid && g_l0_io_in_ready === 1'b1) n_allfire++;",
    ]
    for i in range(n):
        L += [
            "    if (io_in_%d_valid && g_l0_io_in_ready === 1'b1) begin" % i,
            '      n_fire[%d]++; por_%d |= pcat_%d; pand_%d &= pcat_%d;' % (i, i, i, i, i),
            '      if (io_flush) n_flfire++;',
            "      if (g_l%d_io_out_valid === 1'b1) n_owr[%d]++;" % (i, i),
            '    end',
            "    if (io_in_%d_valid && g_l0_io_in_ready === 1'b0) n_bp[%d]++;" % (i, i),
            "    if (g_l%d_io_out_valid === 1'b1) begin" % i,
            '      if (io_flush) n_flush[%d]++;' % i,
            '      if (io_out_%d_ready) n_deq[%d]++; else n_hold[%d]++;' % (i, i, i),
            '    end',
        ]
    L += [
        '  endtask',
        '',
        '  initial begin',
        '    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end',
        '    foreach (n_fire[k]) begin n_fire[k] = 0; n_bp[k] = 0; n_hold[k] = 0; n_deq[k] = 0; n_owr[k] = 0; n_flush[k] = 0; end',
        "    reset = 1'b1;",
        '    drive_all();',
        '    repeat (8) @(posedge clock);',
        "    reset = 1'b0;",
        '    repeat (NCYCLES) begin',
        '      @(negedge clock);',
        '      drive_all();',
        '      #1 sample_cov();          // 沿前采：见文件头「采样时机」',
        '      @(posedge clock);',
        '      #1 check_all();',
        '    end',
        '    $display("\\n==== %s: checks=%%0d errors=%%0d (ncycles=%%0d) ====", checks, errors, NCYCLES);' % name,
        '    $display("group: canAcc-only-by-outAllFire=%0d flush&fire=%0d", n_allfire, n_flfire);',
        '    $display("%-5s %9s %8s %8s %8s %8s %7s %6s", "lane", "fire", "backpr", "hold", "deq", "owrite", "flush", "payld");',
    ]
    for i in range(n):
        L.append('    $display("%%-5s %%9d %%8d %%8d %%8d %%8d %%7d %%6s", "l%d", n_fire[%d], n_bp[%d], n_hold[%d], n_deq[%d], n_owr[%d], n_flush[%d],'
                 % (i, i, i, i, i, i, i))
        L.append("             ((&por_%d) && (pand_%d == '0)) ? \"ok\" : \"HOLE\");" % (i, i))
    L += [
        '    gate("allfire",    n_allfire, 100, "canAcc 从没单靠 outAllFire 成立过（outAllFire 项没测到）");',
        '    gate("flush&fire", n_flfire,   10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");',
    ]
    for i in range(n):
        L += [
            '    gate("l%d.fire",   n_fire[%d],  1000, "从没锁进过数据");' % (i, i),
            '    gate("l%d.backpr", n_bp[%d],     100, "上游从没被挡过（握手永远畅通=假绿）");' % (i, i),
            '    gate("l%d.hold",   n_hold[%d],   100, "表项从没被压住过");' % (i, i),
            '    gate("l%d.deq",    n_deq[%d],    100, "表项从没被下游取走过");' % (i, i),
            '    gate("l%d.owr",    n_owr[%d],    100, "从没在占用中被新数据改写过");' % (i, i),
            '    gate("l%d.flush",  n_flush[%d],   10, "flush 从没命中占用中的表项");' % (i, i),
            '    if (!(&por_%d)) begin $display("COVERAGE HOLE: lane %d 入口 payload 有位从未取到 1"); cov_fail++; end' % (i, i),
            "    if (pand_%d != '0) begin $display(\"COVERAGE HOLE: lane %d 入口 payload 有位从未取到 0\"); cov_fail++; end" % (i, i),
        ]
    L.append(TB_TAIL)
    return '\n'.join(L)


# ---------------------------------------------------------------------------
# 必失败负测：G1 锚点不变式必须在 elaborate 期拦下错误参数（跑不失败 = 闸是摆设）
# ---------------------------------------------------------------------------
def gen_negtest(core, params_ok, params_bad, port_conn):
    L = [
        '// negtest.sv —— %s 的 G1 锚点不变式必失败负测（由 scripts/gen_cb_connect.py 生成，勿手改）。' % core,
        '//   NEG_NARROW    payload 比 G1 锚点少 1 位（"位宽停在旧基线"这一类真实故障的最小复现）',
        '//   NEG_NO_ANCHOR 不传 G1 锚点（老 fail-open：不传即不校验）',
        '// 判据：两个都必须在 VCS elaborate 期非零退出（Error-[FEST]）。',
        'module neg_probe;',
        '  logic clock = 0;',
        '`ifdef NEG_NARROW',
        '  %s #(%s) u_dut (%s);' % (core, params_bad, port_conn),
        '`elsif NEG_NO_ANCHOR',
        '  %s #(%s) u_dut (%s);' % (core, params_ok.split(',')[0], port_conn),
        '`else',
        '  initial $fatal(1, "negtest.sv must be compiled with +define+NEG_NARROW or +define+NEG_NO_ANCHOR");',
        '`endif',
        '  initial begin',
        '    #1 $display("NEG_ESCAPED: wrong parameter elaborated -- the anchor check is a no-op");',
        '    $finish;',
        '  end',
        'endmodule',
        '',
    ]
    return '\n'.join(L)


# ---------------------------------------------------------------------------
def render_all():
    ports_p, inf_p, outf_p, zero_p = parse_pcp()
    ports_g, lanes_g = parse_pgc()
    print('[ok] PipelineConnectPipe: %d 端口, 入口 %d 字段/%d 位, 出口 %d 字段/%d 位, 恒 0 字段 %d 个'
          % (len(ports_p), len(inf_p), sum(w for _f, w in inf_p), len(outf_p),
             sum(w for _f, w in outf_p), len(zero_p)))
    print('[ok] PipeGroupConnect: %d 端口, lane0 %d 字段/%d 位, lane1~5 %d 字段/%d 位'
          % (len(ports_g), len(lanes_g[0]), sum(w for _f, w in lanes_g[0]),
             len(lanes_g[1]), sum(w for _f, w in lanes_g[1])))
    outs = {
        REPO / 'rtl' / 'backend' / 'PipelineConnectPipe.sv': gen_pcp_rtl(ports_p, inf_p, outf_p, zero_p),
        REPO / 'rtl' / 'backend' / 'PipeGroupConnect.sv': gen_pgc_rtl(ports_g, lanes_g),
        REPO / 'verif' / 'ut' / 'PipelineConnectPipe' / 'tb.sv': gen_pcp_tb(ports_p, inf_p, outf_p),
        REPO / 'verif' / 'ut' / 'PipeGroupConnect' / 'tb.sv': gen_pgc_tb(ports_g, lanes_g),
        REPO / 'verif' / 'ut' / 'PipelineConnectPipe' / 'negtest.sv': gen_negtest(
            'xs_PipelineConnectPipe_core', '.DATA_WIDTH(8), .PAYLOAD_W_G1(8)', '.DATA_WIDTH(7), .PAYLOAD_W_G1(8)',
            ".clock(clock), .reset(1'b0), .io_in_ready(), .io_in_valid(1'b0), .io_in_bits('0), "
            ".io_out_ready(1'b0), .io_out_valid(), .io_out_bits(), .io_rightOutFire(1'b0), .io_isFlush(1'b0)"),
        REPO / 'verif' / 'ut' / 'PipeGroupConnect' / 'negtest.sv': gen_negtest(
            'xs_PipeGroupConnect_slot', '.W(8), .W_G1(8)', '.W(7), .W_G1(8)',
            ".clock(clock), .fire(1'b0), .io_in_bits('0), .io_out_bits()"),
    }
    return outs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true',
                    help='核对 golden 语义，并比对产物是否与当前生成结果一致（漂移即非零退出）')
    a = ap.parse_args()
    outs = render_all()
    if a.check:
        drift = []
        for p, text in outs.items():
            if not p.exists():
                drift.append('%s: 不存在' % p.relative_to(REPO))
            elif p.read_text() != text:
                drift.append('%s: 与生成结果不一致（DRIFT）' % p.relative_to(REPO))
        if drift:
            print('FAIL: 产物漂移:\n  ' + '\n  '.join(drift), file=sys.stderr)
            return 1
        print('[ok] 6 个产物与生成结果逐字节一致')
        return 0
    for p, text in outs.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        if p.exists() and p.read_text() == text:
            print('unchanged', p.relative_to(REPO))
            continue
        p.write_text(text)
        print('written', p.relative_to(REPO))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except GoldenError as e:
        print('FAIL(golden 不符合预期形状): %s' % e, file=sys.stderr)
        sys.exit(2)
