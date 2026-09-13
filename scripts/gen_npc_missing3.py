#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_npc_missing3.py —— 生成 NewPipelineConnectPipe_29 / _34 / _35 的薄文件与共用 tb。

这三个变体在 G1 golden 里存在、在 rtl/ 里此前完全没有实现（家族 owner 的 UT 头上
写明"G1 新增的 _29/_34/_35 在 rtl/ 里还没有实现，不在本 UT 范围"）。

为什么用生成器而不是手写：三者合计 607 个端口 / 292 个 payload 字段。端口表、
packed struct 成员表、打包/拆包赋值、位宽自检、以及 tb 的驱动/比对/覆盖代码
全部是 G1 golden 端口表的机械函数——手抄 292 个字段正是这一族历史上集体配错的
成因。本脚本从 `$GOLDEN_RTL/<变体>.sv` 现场解析端口表，顺序、位宽、方向逐项照抄。

生成物（可复跑，幂等）：
  rtl/uncore/NewPipelineConnectPipe_{29,34,35}.sv
  verif/ut/NewPipelineConnectPipe_29_34_35/tb.sv
  verif/ut/NewPipelineConnectPipe_29_34_35/neg_width.sv   （必失败负测的被测件）

fail-closed：端口行解析不了、模块体语义与"纯参数变体"不符（in_ready/valid 方程、
逐字段 RegEnable 直连、in/out 字段集对称）任一条不成立，立即退出，不生成任何东西。

用法：
  python3 scripts/gen_npc_missing3.py            # 写入仓库
  python3 scripts/gen_npc_missing3.py --check     # 只校验 golden 语义，不写文件
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('GOLDEN_RTL',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
UT_DIR = REPO / 'verif' / 'ut' / 'NewPipelineConnectPipe_29_34_35'

_PORT = re.compile(r'^\s*(input|output)\s+'
                   r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?'
                   r'([A-Za-z_]\w*)\s*,?\s*$')


class GoldenError(Exception):
    """golden 不符合预期 —— 一律 fail-closed，绝不"照猜"生成。"""


# ---------------------------------------------------------------------------
# golden 解析 + 语义核对
# ---------------------------------------------------------------------------
def parse_golden(name):
    """返回 (ports, has_flush)。ports = [(dir, width, name)]，顺序照 golden。

    同时机械核对本变体确实是 xs_PipelineConnect 的纯参数变体：
      * io_in_ready = io_out_ready | ~valid（无 isOlder 项）
      * valid' = [~isFlush &] (fire | ~rightOutFire & valid)，异步复位清 0
      * 每个 io_out_bits_X 的驱动源都是 data_X，
        每个 data_X 都在 if (fire) 块里从 io_in_bits_X 装载
      * in/out 字段集合与位宽逐项对称
    """
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
    body = '\n'.join(lines[i:])
    # firtool 会把长赋值折行，统一压成一行再匹配
    flat = re.sub(r'\n\s{4,}', ' ', body)

    if not re.search(r'wire\s+\[?[\d:]*\]?\s*io_in_ready_0 = io_out_ready \| ~valid;', body):
        raise GoldenError('%s: in_ready 方程不是 out_ready|~valid（isOlder 变体？）' % name)
    if not re.search(r'wire\s+\[?[\d:]*\]?\s*_data_T = io_in_ready_0 & io_in_valid;', body):
        raise GoldenError('%s: fire 方程不是 in_ready & in_valid' % name)
    m = re.search(r'always @\(posedge clock or posedge reset\) begin\s*'
                  r'if \(reset\)\s*valid <= 1\'h0;\s*else\s*valid <= (.+?);', body, re.S)
    if not m:
        raise GoldenError('%s: valid 寄存器不是"异步复位 + 单条 else"形状' % name)
    vnxt = m.group(1).strip()
    has_flush = any(p == 'io_isFlush' for _, _, p in ports)
    want = ('~io_isFlush & (_data_T | ~io_rightOutFire & valid)' if has_flush
            else '_data_T | ~io_rightOutFire & valid')
    if vnxt != want:
        raise GoldenError('%s: valid 次态 %r != 期望 %r' % (name, vnxt, want))

    m = re.search(r'always @\(posedge clock\) begin\s*if \(_data_T\) begin\n(.*?)\n\s*end\n\s*end // always @\(posedge\)',
                  body, re.S)
    if not m:
        raise GoldenError('%s: 找不到 if (fire) 的数据寄存块' % name)
    regmap = {}
    joined = []
    for ln in m.group(1).split('\n'):
        s = ln.strip()
        if not s:
            continue
        if joined and not joined[-1].endswith(';'):
            joined[-1] += ' ' + s
        else:
            joined.append(s)
    for s in joined:
        mm = re.match(r'^(\w+) <= (\S+);$', s)
        if not mm:
            raise GoldenError('%s: 寄存行看不懂 %r' % (name, s))
        if mm.group(1) in regmap:
            raise GoldenError('%s: %s 被重复赋值' % (name, mm.group(1)))
        regmap[mm.group(1)] = mm.group(2)

    outmap = {}
    for mm in re.finditer(r'^  assign (\w+) = (.+?);$', flat, re.M):
        outmap[mm.group(1)] = mm.group(2).strip()
    if outmap.get('io_in_ready') != 'io_in_ready_0':
        raise GoldenError('%s: io_in_ready 不是直接来自 in_ready 组合式' % name)
    if outmap.get('io_out_valid') != 'valid':
        raise GoldenError('%s: io_out_valid 不是 valid 寄存器' % name)

    infields = [(p[len('io_in_bits_'):], w) for d, w, p in ports
                if p.startswith('io_in_bits_')]
    outfields = [(p[len('io_out_bits_'):], w) for d, w, p in ports
                 if p.startswith('io_out_bits_')]
    if infields != outfields:
        raise GoldenError('%s: in/out 字段表不对称' % name)
    for f, _w in outfields:
        if outmap.get('io_out_bits_' + f) != 'data_' + f:
            raise GoldenError('%s: io_out_bits_%s 不是 data_%s（疑似组合直通）' % (name, f, f))
        if regmap.get('data_' + f) != 'io_in_bits_' + f:
            raise GoldenError('%s: data_%s 不是从 io_in_bits_%s 装载' % (name, f, f))
    if set(regmap) != {'data_' + f for f, _ in outfields}:
        raise GoldenError('%s: 寄存块里有 payload 之外的寄存器' % name)

    want_ctrl = ['clock', 'reset', 'io_in_ready', 'io_in_valid',
                 'io_out_ready', 'io_out_valid', 'io_rightOutFire']
    if has_flush:
        want_ctrl.append('io_isFlush')
    got_ctrl = [p for _d, _w, p in ports
                if not p.startswith('io_in_bits_') and not p.startswith('io_out_bits_')]
    if got_ctrl != want_ctrl:
        raise GoldenError('%s: 控制端口表 %r != 期望 %r' % (name, got_ctrl, want_ctrl))
    return ports, has_flush


# ---------------------------------------------------------------------------
# payload 字段分组（只为可读性；分组不影响功能）
# ---------------------------------------------------------------------------
GROUPS = [
    # (端口名前缀, 分组键, 该组的一句话说明)。同一个键的多个前缀合成一组。
    ('uop_vpu_fpu_',           'vpufpu',   'uop.vpu.fpu：向量指令里的浮点子束（folding / reduction / 精度标志）'),
    ('uop_vpu_',               'vpu',      'uop.vpu：向量控制束（vtype 现态与推测态、vl/vstart/vmask、各类形态标志）'),
    ('uop_debugInfo_',         'dbginfo',  'uop.debugInfo：性能剖析时间戳。**随流水打拍透传，不是组合直通**'),
    ('uop_debug_seqNum_',      'seqnum',   'uop.debug.seqNum：调试用指令序号'),
    ('uop_debug_',             'dbg',      'uop.debug_*：调试用透传字段'),
    ('uop_exceptionVec_',      'exc',      '@EXC@'),
    ('uop_preDecodeInfo_',     'predec',   'uop.preDecodeInfo：前端预译码信息（打拍透传，非组合直通）'),
    ('uop_traceBlockInPipe_',  'trace',    'uop.traceBlockInPipe：指令轨迹（RISC-V trace）字段'),
    ('uop_srcLoadDependency_', 'srcdep',   'uop.srcLoadDependency：5 个源 × 3 级的 load 依赖倒计时'),
    ('uop_srcType_',           'srctype',  'uop.srcType：5 个源的类型编码'),
    ('uop_srcState_',          'srcstate', 'uop.srcState：5 个源的就绪位'),
    ('uop_psrc_',              'psrc',     'uop.psrc：物理源寄存器号'),
    ('uop_useRegCache_',       'regcache', 'uop.useRegCache / uop.regCacheIdx：寄存器缓存旁路'),
    ('uop_regCacheIdx_',       'regcache', 'uop.useRegCache / uop.regCacheIdx：寄存器缓存旁路'),
    ('uop_fpu_',               'fpu',      'uop.fpu：标量浮点控制（fmt/rm/typ/wflags）'),
    ('uop_ftq',                'ftq',      'uop.ftq*：取指队列指针与块内偏移'),
    ('uop_robIdx_',            'rob',      'uop.robIdx：ROB 表项指针（flag = 回绕位）'),
    ('uop_sqIdx_',             'sq',       'uop.sqIdx：store queue 指针（flag = 回绕位）'),
    ('uop_lqIdx_',             'lq',       'uop.lqIdx：load queue 指针（flag = 回绕位）'),
    ('uop_waitForRobIdx_',     'waitrob',  'uop.waitForRobIdx：store set 依赖的 ROB 指针'),
    ('uop_',                   'uop',      'uop：微操作本身的控制位'),
]


def group_of(field):
    for pref, key, gloss in GROUPS:
        if field.startswith(pref):
            return key, gloss
    return '@top', '本级自己的数据字段（不属于 uop 束）'


def exc_gloss(fields):
    """异常向量那一组的说明按本变体实际导出的编号写，别照抄别的变体。"""
    idx = sorted(int(f.rsplit('_', 1)[1]) for f, _w in fields
                 if f.startswith('uop_exceptionVec_'))
    if not idx:
        return None
    if idx == list(range(len(idx))):
        return ('uop.exceptionVec：异常向量，本变体导出 %d 号位全体（0~%d）'
                % (len(idx), idx[-1]))
    return ('uop.exceptionVec：异常向量，本变体只导出用得到的 %d 号位 —— %s（编号不连续）'
            % (len(idx), '/'.join(str(i) for i in idx)))


def grouped(fields):
    """[(field,w)] -> [(gloss_or_None, field, w)]，组变化时给出注释文本。

    同一组在 golden 端口表里被别的组隔开时（uop 通用位就常见），第二次起只写
    "（续）"，不重复整段说明。
    """
    exc = exc_gloss(fields)
    out, prev, seen = [], None, set()
    for f, w in fields:
        key, gloss = group_of(f)
        if gloss == '@EXC@':
            gloss = exc
        note = None
        if key != prev:
            note = gloss if key not in seen else gloss.split('：')[0] + '（续）'
            seen.add(key)
            prev = key
        out.append((note, f, w))
    return out


# ---------------------------------------------------------------------------
# 薄文件生成
# ---------------------------------------------------------------------------
def decl(width):
    return '' if width == 1 else '[%d:0] ' % (width - 1)


HEADERS = {
    'NewPipelineConnectPipe_29': [
        '// NewPipelineConnectPipe_29.sv — 向量 merge buffer 写回口的单拍流水缓冲。',
        '// 例化点（G1 golden，共 3 处）：VSMergeBufferImp.VMergebufferPipelineConnect0、',
        '//   VLMergeBufferImp.VMergebufferPipelineConnect0 / …Connect1 —— 向量 store/load 的',
        '//   merge buffer 把一条向量指令的各分片结果拼齐后，经本级送往写回网络。',
        '// 本变体参数与规模：payload = 72 字段 / 1023 位（uop 控制束 + 128 位向量结果 data',
        '//   + vdIdx/vdIdxInField 两个目的向量寄存器索引）；模块端口 152 个（78 输入 / 74 输出），',
        '//   带 io_isFlush；golden 模块体 589 行。',
        '// 家族关系：与全族共用一个核 xs_PipelineConnect（rtl/common/PipelineConnect.sv），',
        '//   本文件只提供本变体的 payload 字段表与打包/拆包，不复制任何核逻辑。',
        '//   核语义：in_ready = out_ready | ~valid；fire = in_valid & in_ready；',
        "//   valid' = ~isFlush & (fire | ~rightOutFire & valid)（异步复位清 0）；",
        '//   data = RegEnable(in_bits, fire)。',
        '// 时序（逐字段从 G1 golden 机械核实，判据见 scripts/gen_npc_missing3.py）：',
        '//   **没有任何组合直通字段**——debugInfo_* 在内的每个 io_in_bits_* 都在 fire 拍',
        '//   写进数据寄存器、下一拍才出现在 io_out_bits_* 上。唯一的组合输出是 io_in_ready。',
        '// ★名字警告★：G0(v2r2) 里叫 NewPipelineConnectPipe_29 的不存在；本变体在 G0 里',
        '//   叫 NewPipelineConnectPipe_27（82 端口），G1 编号平移 +2 且 payload 从 37 字段/535 位',
        '//   扩到 72 字段/1023 位。判据是例化坑位集合相等，见 scripts/check_name_collisions.py。',
    ],
    'NewPipelineConnectPipe_34': [
        '// NewPipelineConnectPipe_34.sv — MemBlock 里"其它 store 输出"回 Backend 的单拍流水缓冲。',
        '// 例化点（G1 golden，唯一一处）：MemBlock.inner_otherStoutConnect —— 非普通 store 流水线',
        '//   （原子/CMO/misalign 等）的 store 写回结果，经本级送回后端写回网络。',
        '// 本变体参数与规模：payload = 46 字段 / 760 位（24 位异常向量 + trigger + rfWen/flushPipe',
        '//   + pdest/robIdx/sqIdx + 完整 debugInfo 时间戳束 + 64 位 data + debug_isMMIO）；',
        '//   模块端口 99 个（51 输入 / 48 输出）；golden 模块体 422 行。',
        '// ★本变体没有 io_isFlush 端口★：golden 的 valid 次态是',
        "//   valid' = fire | ~rightOutFire & valid，没有冲刷项。所以例化共享核时把",
        '//   io_isFlush 恒接 1\'b0，与 golden 逐位等价。',
        '// 家族关系：与全族共用一个核 xs_PipelineConnect（rtl/common/PipelineConnect.sv），',
        '//   本文件只提供本变体的 payload 字段表与打包/拆包，不复制任何核逻辑。',
        '// 时序（逐字段从 G1 golden 机械核实）：**没有任何组合直通字段**，全部 RegEnable 打拍；',
        '//   唯一的组合输出是 io_in_ready = io_out_ready | ~valid。',
        '// ★名字警告★：本变体在 G0(v2r2) 里叫 NewPipelineConnectPipe_32（71 端口），',
        '//   G1 编号平移 +2 且 payload 从 32 字段/231 位扩到 46 字段/760 位。',
        '//   判据是例化坑位集合相等，见 scripts/check_name_collisions.py。',
    ],
    'NewPipelineConnectPipe_35': [
        '// NewPipelineConnectPipe_35.sv — 向量访存拆分器 → load/store 流水线之间的单拍流水缓冲。',
        '// 例化点（G1 golden，共 4 处）：MemBlock.inner_VsSplitConnectStu / …Stu_1 /',
        '//   inner_VlSplitConnectLdu / …Ldu_1 —— VsSplit/VlSplit 把一条向量访存指令拆成若干',
        '//   逐元素/逐段的访存请求，每个请求带完整 uop 上下文，经本级送进标量 load/store 流水线。',
        '// 本变体参数与规模：payload = 174 字段 / 1446 位，是全族最大的一个',
        '//   （地址束 vaddr/basevaddr/mask/reg_offset/alignedType/vecActive… + 几乎完整的',
        '//   DynInst uop 束 + mBIndex/elemIdx/elemIdxInsideVd/splitIndex 四个拆分索引）；',
        '//   模块端口 356 个（180 输入 / 176 输出），带 io_isFlush；golden 模块体 1197 行。',
        '// 家族关系：与全族共用一个核 xs_PipelineConnect（rtl/common/PipelineConnect.sv），',
        '//   本文件只提供本变体的 payload 字段表与打包/拆包，不复制任何核逻辑。',
        '//   核语义：in_ready = out_ready | ~valid；fire = in_valid & in_ready；',
        "//   valid' = ~isFlush & (fire | ~rightOutFire & valid)（异步复位清 0）；",
        '//   data = RegEnable(in_bits, fire)。',
        '// 时序（逐字段从 G1 golden 机械核实）：**没有任何组合直通字段**，',
        '//   preDecodeInfo_* / debugInfo_* 也一样是打拍透传。唯一的组合输出是 io_in_ready。',
        '// ★名字警告★：本变体在 G0(v2r2) 里叫 NewPipelineConnectPipe_33（96 端口），',
        '//   而 G1 里另有一个 NewPipelineConnectPipe_33（17 端口，VSegmentUnit 用）——',
        '//   同名不同物。G1 的 _35 相对 G0 的 _33 多了 130 个字段（uop 束从 44 字段扩到 174）。',
        '//   判据是例化坑位集合相等，见 scripts/check_name_collisions.py。',
    ],
}


def gen_rtl(name, ports, has_flush):
    infields = [(p[len('io_in_bits_'):], w) for d, w, p in ports if p.startswith('io_in_bits_')]
    total = sum(w for _f, w in infields)
    L = list(HEADERS[name])
    L.append('')
    L.append('module %s (' % name)
    # 端口表逐行照 golden 顺序/位宽，只把类型写成 logic
    plines = []
    for d, w, pn in ports:
        plines.append('  %-6s logic %s%s' % (d, decl(w), pn))
    L.append(',\n'.join(plines))
    L.append(');')
    L.append('')
    L.append('  // ---------------------------------------------------------------------------')
    L.append('  // 本变体的 payload 布局。用 packed struct 而不是手工位切片：入口打包与出口拆包')
    L.append('  // 都按同一组成员名访问，"字段错位"在结构上就不可能发生（这一族历史上正是')
    L.append('  // 手工切片 + 照抄错基线的端口表而集体配错）。成员顺序照 G1 golden 端口表，')
    L.append('  // 顺序本身不影响功能——核只把 payload 当一坨位搬运。')
    L.append('  // ---------------------------------------------------------------------------')
    L.append('  typedef struct packed {')
    for note, f, w in grouped(infields):
        if note:
            L.append('    // %s' % note)
        L.append('    logic %-9s %s;' % (decl(w).strip() or '', f))
    L.append('  } payload_t;')
    L.append('')
    L.append('  // G1 golden 该变体所有 io_in_bits_* 的位宽之和。传给共享核做防呆：')
    L.append('  // 核里的 initial 会校验 DATA_WIDTH（= $bits(payload_t)）与它相等。')
    L.append('  // ★这个参数必须显式传★——核给了默认值 PAYLOAD_W_G1 = DATA_WIDTH，省略即等于不校验。')
    L.append('  localparam int unsigned PAYLOAD_W_G1 = %d;' % total)
    L.append('')
    L.append('  payload_t in_payload, out_payload;')
    L.append('')
    L.append('  // 入口打包：端口 -> struct 成员（同名逐项）')
    L.append('  always_comb begin')
    wid = max(len(f) for f, _ in infields)
    for f, _w in infields:
        L.append('    in_payload.%-*s = io_in_bits_%s;' % (wid, f, f))
    L.append('  end')
    L.append('')
    L.append('  // 出口拆包：struct 成员 -> 端口（同名逐项）')
    for f, _w in infields:
        L.append('  assign io_out_bits_%-*s = out_payload.%s;' % (wid, f, f))
    L.append('')
    L.append('  // ---------------------------------------------------------------------------')
    L.append('  // elaborate 期位宽不变式。')
    L.append('  //')
    L.append('  // 本轮反复出事的形态是「逻辑全对、只有某个字段位宽停在旧基线」：随机激励未必')
    L.append('  // 打到高位，UT 照样 errors=0，要等 FM 才炸。这里把它提前到 time 0。')
    L.append('  // 判据：入口端口位宽之和 == 出口端口位宽之和 == PAYLOAD_W_G1 == $bits(payload_t)。')
    L.append('  // 任何一个端口或 struct 成员的位宽被改动，这四个数就不再相等（后两项由共享核')
    L.append('  // 里的 initial 负责）。「两处互相抵消的改动」逃得过位宽和，但逃不过')
    L.append('  // scripts/port_contract_lint.py（逐端口比 G1 golden）与 UT 的逐拍输出比对。')
    L.append('  // ---------------------------------------------------------------------------')
    for side in ('in', 'out'):
        L.append('  localparam int unsigned %s_PORT_BITS =' % side.upper())
        terms = ['$bits(io_%s_bits_%s)' % (side, f) for f, _w in infields]
        buf = '   '
        chunk = []
        for t in terms:
            chunk.append(t)
            if len(chunk) == 4:
                L.append('   ' + ' + '.join(chunk) + ' +')
                chunk = []
        if chunk:
            L.append('   ' + ' + '.join(chunk) + ';')
        else:
            L[-1] = L[-1][:-2] + ';'
    L.append('')
    L.append('  initial begin')
    L.append('    if (IN_PORT_BITS != PAYLOAD_W_G1)')
    L.append('      $fatal(1, "%s: 入口端口位宽之和 %%0d != G1 golden 的 %%0d 位",' % name)
    L.append('             IN_PORT_BITS, PAYLOAD_W_G1);')
    L.append('    if (OUT_PORT_BITS != PAYLOAD_W_G1)')
    L.append('      $fatal(1, "%s: 出口端口位宽之和 %%0d != G1 golden 的 %%0d 位",' % name)
    L.append('             OUT_PORT_BITS, PAYLOAD_W_G1);')
    L.append('  end')
    L.append('')
    L.append('  // 共享核：本文件不含任何流水/握手逻辑，全部在 xs_PipelineConnect 里。')
    if not has_flush:
        L.append('  // 本变体 golden 无 io_isFlush（valid 次态没有冲刷项），故核的 io_isFlush 恒接 0。')
    L.append('  xs_PipelineConnect #(')
    L.append('    .DATA_WIDTH   ($bits(payload_t)),')
    L.append('    .PAYLOAD_W_G1 (PAYLOAD_W_G1)')
    L.append('  ) u_core (')
    L.append('    .clock           (clock),')
    L.append('    .reset           (reset),')
    L.append('    .io_in_ready     (io_in_ready),')
    L.append('    .io_in_valid     (io_in_valid),')
    L.append('    .io_in_bits      (in_payload),')
    L.append('    .io_out_ready    (io_out_ready),')
    L.append('    .io_out_valid    (io_out_valid),')
    L.append('    .io_out_bits     (out_payload),')
    L.append('    .io_rightOutFire (io_rightOutFire),')
    L.append('    .io_isFlush      (%s)' % ('io_isFlush' if has_flush else "1'b0"))
    L.append('  );')
    L.append('')
    L.append('endmodule')
    L.append('')
    return '\n'.join(L)


# ---------------------------------------------------------------------------
# tb 生成
# ---------------------------------------------------------------------------
def rnd(w):
    n = (w + 31) // 32
    if n == 1:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * n))


TB_HEAD = r'''// NewPipelineConnectPipe_29 / _34 / _35 UT —— golden vs 派生 _xs 双例化，一个 tb 三个变体。
//
// 为什么另开目录而不是并进 verif/ut/NewPipelineConnectPipe/：那个 tb 是家族 owner 的
// 14 变体聚合件，其 Makefile 头上明写"_29/_34/_35 在 rtl/ 里还没有实现，不在本 UT 范围"。
// 主树同时有多位 owner 在动，改别人的 tb 会撞车；三者又恰好是同一批"G1 新增/重编号"
// 变体，合成一个 tb 一次编译即可。
//
// 被测语义（三者共用核 xs_PipelineConnect，见 rtl/common/PipelineConnect.sv）：
//   in_ready = out_ready | ~valid
//   fire     = in_valid & in_ready
//   valid'   = ~isFlush & (fire | ~rightOutFire & valid)     （_34 无 isFlush 项）
//   data     = RegEnable(in_bits, fire)   —— 全部字段打拍，无组合直通
//
// 覆盖闸（流水连接件极易假绿：握手永远畅通、flush 永不触发也能 errors=0）：
//   fire / 反压(in_valid & ~in_ready) / hold(valid & ~rightOutFire) /
//   deq(valid & rightOutFire) / 占用中被改写(valid & out_ready & in_valid) /
//   flush 命中占用中的表项 / flush 与 fire 同拍（冲刷优先级） /
//   payload 每一位都取到过 1、也取到过 0（位宽写窄或字段漏掉不会假绿）。
//   _34 golden 没有 io_isFlush 端口，两条 flush 闸对它不适用，明确跳过而不是记 0 放过。
//
// 采样时机：覆盖必须在**时钟沿之前**采。沿后再采就永远看不到 flush（flush 恰恰把
// valid 清成 0 了），fire/反压同理会串到下一拍——家族 owner 第一版就是沿后采、
// 14 个变体 flush 全 0 却全绿，是覆盖闸救回来的。
`timescale 1ns/1ps

`define CHECK(TAG,SIG) begin \
  if (!$isunknown(g_``TAG``_``SIG)) begin \
    checks++; nchk_``TAG``++; \
    if (g_``TAG``_``SIG !== i_``TAG``_``SIG) begin \
      errors++; nerr_``TAG``++; \
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
'''


def gen_tb(variants):
    L = [TB_HEAD]
    for name, ports, has_flush in variants:
        tag = 'v' + name.split('_')[-1]
        infields = [(p[len('io_in_bits_'):], w) for d, w, p in ports if p.startswith('io_in_bits_')]
        total = sum(w for _f, w in infields)
        L.append('  // ==========================================================================')
        L.append('  // %s —— %d 字段 / %d 位 payload%s' %
                 (name, len(infields), total, '' if has_flush else '（golden 无 io_isFlush）'))
        L.append('  // ==========================================================================')
        L.append('  logic %s_io_in_valid;' % tag)
        for f, w in infields:
            L.append('  logic %s%s_io_in_bits_%s;' % (decl(w), tag, f))
        L.append('  logic %s_io_out_ready;' % tag)
        L.append('  logic %s_io_rightOutFire;' % tag)
        if has_flush:
            L.append('  logic %s_io_isFlush;' % tag)
        L.append('  wire  g_%s_io_in_ready, i_%s_io_in_ready;' % (tag, tag))
        L.append('  wire  g_%s_io_out_valid, i_%s_io_out_valid;' % (tag, tag))
        for f, w in infields:
            L.append('  wire  %sg_%s_io_out_bits_%s, i_%s_io_out_bits_%s;' % (decl(w), tag, f, tag, f))
        L.append('  longint nchk_%s = 0; int nerr_%s = 0;' % (tag, tag))
        L.append('  longint fire_%s = 0, bp_%s = 0, hold_%s = 0, deq_%s = 0, owr_%s = 0;' %
                 (tag, tag, tag, tag, tag))
        if has_flush:
            L.append('  longint flush_%s = 0, flfire_%s = 0;' % (tag, tag))
        L.append('  logic [%d:0] por_%s = \'0, pand_%s = \'1;   // payload 逐位或 / 逐位与' %
                 (total - 1, tag, tag))
        cat = ', '.join('%s_io_in_bits_%s' % (tag, f) for f, _w in infields)
        L.append('  wire  [%d:0] pcat_%s = {%s};' % (total - 1, tag, cat))
        for pfx, inst in (('g_', 'u_g_'), ('i_', 'u_i_')):
            mod = name if pfx == 'g_' else name + '_xs'
            L.append('  %s %s%s (' % (mod, inst, tag))
            cl = ['    .clock(clock), .reset(reset)',
                  '    .io_in_valid(%s_io_in_valid)' % tag]
            for f, _w in infields:
                cl.append('    .io_in_bits_%s(%s_io_in_bits_%s)' % (f, tag, f))
            cl.append('    .io_out_ready(%s_io_out_ready)' % tag)
            cl.append('    .io_rightOutFire(%s_io_rightOutFire)' % tag)
            if has_flush:
                cl.append('    .io_isFlush(%s_io_isFlush)' % tag)
            cl.append('    .io_in_ready(%s%s_io_in_ready)' % (pfx, tag))
            cl.append('    .io_out_valid(%s%s_io_out_valid)' % (pfx, tag))
            for f, _w in infields:
                cl.append('    .io_out_bits_%s(%s%s_io_out_bits_%s)' % (f, pfx, tag, f))
            L.append(',\n'.join(cl))
            L.append('  );')
        L.append('')

    # drive
    L.append('  task automatic drive_all();')
    for name, ports, has_flush in variants:
        tag = 'v' + name.split('_')[-1]
        infields = [(p[len('io_in_bits_'):], w) for d, w, p in ports if p.startswith('io_in_bits_')]
        L.append('    %s_io_in_valid     = ($urandom %% 100) < 75;' % tag)
        L.append('    %s_io_out_ready    = ($urandom %% 100) < 55;' % tag)
        L.append('    %s_io_rightOutFire = ($urandom %% 100) < 50;' % tag)
        if has_flush:
            L.append('    %s_io_isFlush      = ($urandom %% 512) == 0;' % tag)
        for f, w in infields:
            L.append('    %s_io_in_bits_%s = %s;' % (tag, f, rnd(w)))
    L.append('  endtask')
    L.append('')

    # check
    L.append('  task automatic check_all();')
    for name, ports, has_flush in variants:
        tag = 'v' + name.split('_')[-1]
        infields = [(p[len('io_in_bits_'):], w) for d, w, p in ports if p.startswith('io_in_bits_')]
        L.append('    `CHECK(%s,io_in_ready)' % tag)
        L.append('    `CHECK(%s,io_out_valid)' % tag)
        for f, _w in infields:
            L.append('    `CHECK(%s,io_out_bits_%s)' % (tag, f))
    L.append('  endtask')
    L.append('')

    # sample
    L.append('  task automatic sample_cov();')
    for name, ports, has_flush in variants:
        tag = 'v' + name.split('_')[-1]
        L.append('    if (%s_io_in_valid && g_%s_io_in_ready === 1\'b1) begin' % (tag, tag))
        L.append('      fire_%s++; por_%s |= pcat_%s; pand_%s &= pcat_%s;' % (tag, tag, tag, tag, tag))
        if has_flush:
            L.append('      if (%s_io_isFlush) flfire_%s++;' % (tag, tag))
        L.append('    end')
        L.append('    if (%s_io_in_valid && g_%s_io_in_ready === 1\'b0) bp_%s++;' % (tag, tag, tag))
        L.append('    if (g_%s_io_out_valid === 1\'b1) begin' % tag)
        if has_flush:
            L.append('      if (%s_io_isFlush) flush_%s++;' % (tag, tag))
        L.append('      if (%s_io_rightOutFire) deq_%s++; else hold_%s++;' % (tag, tag, tag))
        L.append('      if (%s_io_out_ready && %s_io_in_valid) owr_%s++;' % (tag, tag, tag))
        L.append('    end')
    L.append('  endtask')
    L.append('')

    L.append(r'''  int cov_fail = 0;
  task automatic gate(string nm, longint got, longint need, string why);
    if (got < need) begin
      $display("COVERAGE HOLE: %s = %0d < %0d —— %s", nm, got, need, why);
      cov_fail++;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    drive_all();
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_all();
      #1 sample_cov();          // 沿前采：见文件头「采样时机」
      @(posedge clock);
      #1 check_all();
    end
''')
    L.append('    $display("\\n==== NewPipelineConnectPipe_29/_34/_35: checks=%0d errors=%0d (ncycles=%0d) ====", checks, errors, NCYCLES);')
    L.append('    $display("%-28s %10s %7s %9s %8s %8s %8s %8s %7s %7s %6s",')
    L.append('             "variant", "checks", "errors", "fire", "backpr", "hold", "deq", "owrite",')
    L.append('             "flush", "fl&fire", "payld");')
    for name, ports, has_flush in variants:
        tag = 'v' + name.split('_')[-1]
        fl = ('flush_%s, flfire_%s' % (tag, tag)) if has_flush else '-1, -1'
        L.append('    $display("%%-28s %%10d %%7d %%9d %%8d %%8d %%8d %%8d %%7d %%7d %%6s", "%s",' % name)
        L.append('             nchk_%s, nerr_%s, fire_%s, bp_%s, hold_%s, deq_%s, owr_%s, %s,' %
                 (tag, tag, tag, tag, tag, tag, tag, fl))
        L.append('             ((&por_%s) && (pand_%s == \'0)) ? "ok" : "HOLE");' % (tag, tag))
    L.append('    $display("（flush 列 -1 = 该变体 golden 无 io_isFlush 端口，两条 flush 闸不适用）");')
    L.append('')
    for name, ports, has_flush in variants:
        tag = 'v' + name.split('_')[-1]
        L.append('    gate("%s.fire",   fire_%s, 1000, "从没锁进过数据");' % (name, tag))
        L.append('    gate("%s.backpr", bp_%s,    100, "上游从没被挡过（握手永远畅通=假绿）");' % (name, tag))
        L.append('    gate("%s.hold",   hold_%s,  100, "表项从没被压住过");' % (name, tag))
        L.append('    gate("%s.deq",    deq_%s,   100, "表项从没被下游取走过");' % (name, tag))
        L.append('    gate("%s.owr",    owr_%s,   100, "从没在占用中被新数据改写过");' % (name, tag))
        if has_flush:
            L.append('    gate("%s.flush",  flush_%s,  10, "flush 从没命中占用中的表项");' % (name, tag))
            L.append('    gate("%s.flush&fire", flfire_%s, 10, "flush 与 fire 从没同拍过（冲刷优先级没测到）");' % (name, tag))
        L.append('    if (!(&por_%s)) begin $display("COVERAGE HOLE: %s payload 有位从未取到 1"); cov_fail++; end' % (tag, name))
        L.append('    if (pand_%s != \'0) begin $display("COVERAGE HOLE: %s payload 有位从未取到 0"); cov_fail++; end' % (tag, name))
    L.append(r'''
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
''')
    return '\n'.join(L)


# ---------------------------------------------------------------------------
# 必失败负测：把 _35 的 uop_vpu_vmask 端口从 128 位改成 64 位（"位宽停在旧值"
# 这一类真实故障的最小复现），本文件的 IN_PORT_BITS 不变式必须在 time 0 $fatal。
# ---------------------------------------------------------------------------
def gen_neg(name, ports, rtl_text):
    """把 _35 的 io_in_bits_uop_vpu_vmask 从 128 位改成 64 位，做成独立模块 + neg_tb。

    这是"逻辑全对、只有某个字段位宽停在旧基线"这一类真实故障的最小复现。
    期望：仿真 time 0 触发 $fatal（入口端口位宽之和 1382 != 1446）。
    """
    neg = name + '_negwidth'
    t = rtl_text
    old = '  input  logic [127:0] io_in_bits_uop_vpu_vmask'
    if old not in t:
        raise GoldenError('负测：找不到要改窄的 io_in_bits_uop_vpu_vmask 端口行')
    t = t.replace(old, '  input  logic [63:0] io_in_bits_uop_vpu_vmask')
    t = t.replace('module %s (' % name, 'module %s (' % neg)
    t = t.replace('"%s: ' % name, '"%s: ' % neg)
    body = t.split('\n')
    k = 0
    while k < len(body) and (body[k].startswith('//') or not body[k].strip()):
        k += 1
    # neg_tb 的信号宽度也按改窄后的端口来，免得再叠一层端口位宽不匹配的警告
    negports = [(d, 64 if pn == 'io_in_bits_uop_vpu_vmask' else w, pn)
                for d, w, pn in ports]
    L = [
        '// neg_width.sv —— 必失败负测（codex 0145）：证明 _35 的 elaborate 期位宽不变式不是摆设。',
        '// 内容 = NewPipelineConnectPipe_35 的逐字副本，只把 io_in_bits_uop_vpu_vmask 从 128 位',
        '// 改窄成 64 位（"逻辑全对、位宽停在旧基线"这一类真实故障的最小复现），模块改名',
        '// NewPipelineConnectPipe_35_negwidth 以免与被测件撞名。',
        '// 期望：仿真 time 0 触发 $fatal（入口端口位宽之和 1382 != G1 的 1446）。',
        '// 跑不炸就说明不变式失效 —— Makefile 的 neg 目标反过来判 NEG FAILED。',
        '// 本文件由 scripts/gen_npc_missing3.py 生成，勿手改。',
        '',
    ] + body[k:] + ['', 'module neg_tb;']
    for d, w, pn in negports:
        L.append('  logic %sn_%s;' % (decl(w), pn))
    L.append('  %s u_dut (' % neg)
    L.append(',\n'.join('    .%s(n_%s)' % (pn, pn) for _d, _w, pn in negports))
    L.append('  );')
    L.append('  initial begin')
    L.append('    #1 $display("NEG_ESCAPED: 位宽改窄了却没触发不变式 —— 闸是摆设");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    L.append('')
    return '\n'.join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只核对 golden 语义，不写文件')
    a = ap.parse_args()

    targets = ['NewPipelineConnectPipe_29', 'NewPipelineConnectPipe_34',
               'NewPipelineConnectPipe_35']
    variants = []
    for n in targets:
        ports, hf = parse_golden(n)
        nin = sum(1 for d, _w, _p in ports if d == 'input')
        nout = len(ports) - nin
        print('[ok] %s: %d 端口(%d in / %d out), payload %d 字段 / %d 位, isFlush=%s' %
              (n, len(ports), nin, nout,
               sum(1 for _d, _w, p in ports if p.startswith('io_in_bits_')),
               sum(w for _d, w, p in ports if p.startswith('io_in_bits_')), hf))
        variants.append((n, ports, hf))
    if a.check:
        return 0

    for n, ports, hf in variants:
        p = REPO / 'rtl' / 'uncore' / (n + '.sv')
        p.write_text(gen_rtl(n, ports, hf))
        print('written', p)
    UT_DIR.mkdir(parents=True, exist_ok=True)
    (UT_DIR / 'tb.sv').write_text(gen_tb(variants))
    print('written', UT_DIR / 'tb.sv')
    n35, p35, f35 = variants[2]
    (UT_DIR / 'neg_width.sv').write_text(gen_neg(n35, p35, gen_rtl(n35, p35, f35)))
    print('written', UT_DIR / 'neg_width.sv')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except GoldenError as e:
        print('FAIL(golden 不符合"纯参数变体"预期): %s' % e, file=sys.stderr)
        sys.exit(2)
