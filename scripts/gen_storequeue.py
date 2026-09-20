#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_storequeue.py —— StoreQueue 可读核的**端口契约**与状态声明生成器。

只生成机械部分（端口表、子模块例化绑定、per-entry 状态声明），功能方程一律手写。
判据是 G1 golden：/home/eda/xs-env/G1-canonical/golden-rtl/StoreQueue.sv。

用法：
    gen_storequeue.py --dump-ports      # 打印端口表（调试）
    gen_storequeue.py --emit-wrapper    # 打印 golden 同名 wrapper 的端口段 + 连线段
    gen_storequeue.py --check           # 幂等校验（与仓库内文件比对）
"""
from __future__ import print_function
import argparse, re, sys, pathlib

GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/StoreQueue.sv')

# =============================================================================
# 差分 UT 方案（本轮，尚未实现；实现前请连同下面这条教训一起读）
# -----------------------------------------------------------------------------
# ★上一轮的 UT 没有判别力，这是本轮 UT 设计的第一前提★
#
# 实测（xs-v2r2-sv/verif/ut/StoreQueue/tb.sv:1184 起）：上一轮的 tb 对**每一根输入
# 逐位独立均匀随机**（`$urandom_range(0,1)` 一根一行，604 根全这么打），跑 seed
# 1/7/42 各 200k 拍 errors=0；而同一版 RTL 的 FM 是 **FAILED / 1487 failing**
# （xs-v2r2-sv/docs/memblock/StoreQueue.md §7.3）。
#
# 为什么对一个队列来说这种激励几乎没有判别力：
#   · sqIdx / robIdx / numLsElem 每拍独立随机 → 入队落点与 enqPtr 自洽关系被打散，
#     队列基本进不到「连续占用 + 有序提交 + 有序退队」的深状态；
#   · rob.scommit / pendingPtr 随机 → CommitWidth=8 的提交链条几乎不可能连成串，
#     而 FM 指认的失配点恰恰就是 `committed`/`completed` 的 8 路 gather-mux；
#   · 握手对端（sbuffer.ready / uncache.resp / cmoOpResp）随机 → mmio/NC/CBO 三个
#     状态机大多停在 idle；
#   · 两侧 DUT 收同一份垃圾激励，没被激活的差异**按构造**不会现形。
#
# 本轮 UT 必须做到（判据是「注入真 bug 能被抓到」，不是「拍数够」）：
#
# 1) 协议感知的约束随机激励，而不是逐位独立随机：
#    · 入队：维护 tb 侧的影子 enqPtr，req.sqIdx 按它推进；numLsElem 取 1..8；
#      needAlloc 与 req.valid 同源；受 io_enq_canAccept 反压。
#    · sta/std：只对**已分配**的条目发 storeAddrIn/storeDataIn，stWbIndex 从影子
#      队列里取；storeAddrInRe 严格是 storeAddrIn 的下一拍（golden 就是 RegNext）。
#    · 提交：维护影子 robIdx 序，rob.pendingPtr 单调推进，scommit 按已入队数给。
#    · 反压：sbuffer.ready / uncache 各握手做加权随机（0%/50%/100% 三档轮换），
#      保证「满队列 + 反压」与「空队列」两个极端都反复到达。
#    · forward：sqIdx/sqIdxMask 与影子队列自洽，地址在少数几个 cache line 上打靶，
#      否则 CAM 永远不命中，转发通路等于没测。
# 2) 定向场景（各自独立的 test，不靠随机撞）：
#    非对齐跨 16B 拆分 / 跨 4K 页交接 / mmio 全流程 / NC 全流程 / CBO + cbo_zero /
#    向量 vecMbCommit 与 vecExceptionFlag / redirect 在各拍位置冲刷 / 队列满 /
#    ★rdataPtr 与 deqPtr 拉开距离★（两个独立计数器，最易写错）。
# 3) ★判别力证明★：至少 4 个 mutant（不进库，跑完即弃），UT 必须报错：
#    M1 memBackTypeMM 在入队时一起清零（§TRAP-2，golden 不清）
#    M2 addrvalid 写优先级改成「s2 一律压 s1」（真实是口1-s1 压口0-s2）
#    M3 committed 的 8 路 gather-mux 合并成一路（= 上一轮 FM 指认的失配形态）
#    M4 SqPtr 加法写成 {flag,value} 整体自增（56 非 2 的幂，绕回点会错）
#    任何一个 mutant 不被报出 → 该 UT 的 errors=0 不作数，先修 UT 再谈 RTL。
# 4) 不复位寄存器有 2913 个 → `+vcs+initreg+random` 与 `+vcs+initreg+0` 两轮都要过。
# 5) 比对口径：golden 与重写件双例化，逐拍比全部 399 根输出，
#    `!$isunknown(golden)` 跳 don't-care；checks/errors 计数打印。
# =============================================================================


PORT_RE = re.compile(
    r'^\s*(input|output|inout)\s+(?:wire\s+|reg\s+)?(\[\s*\d+\s*:\s*\d+\s*\]\s*)?([A-Za-z_]\w*)\s*(,)?\s*$')


def parse_ports(path=GOLDEN):
    """从 golden 模块头解析端口表。fail-closed：解析不出就报错退出。"""
    lines = path.read_text().split('\n')
    start = None
    for i, l in enumerate(lines):
        if l.startswith('module StoreQueue('):
            start = i
            break
    if start is None:
        sys.exit('FATAL: golden 里找不到 `module StoreQueue(`')
    ports = []
    for l in lines[start + 1:]:
        if l.startswith(');'):
            break
        m = PORT_RE.match(l)
        if m:
            ports.append((m.group(1), (m.group(2) or '').strip(), m.group(3)))
        elif l.strip():
            sys.exit('FATAL: 端口行解析失败：%r' % l)
    if not ports:
        sys.exit('FATAL: 端口表为空')
    return ports


# ---------------------------------------------------------------------------
# 通道切分：golden 端口名形如 io_<chan>[_<idx>][_bits]_<field...>。
# 把带下标的通道识别出来,让可读核用「结构体数组」而不是 1003 根扁平线。
# 结构体的**字段集与位宽全部从 golden 端口表推导**,不是手抄 —— 手抄会漏字段,
# 而漏字段在 elaborate/UT 都不报,只有 FM 才炸(上一轮的教训)。
# ---------------------------------------------------------------------------
IDX_CHANS = [
    ('io_enq_req', 6), ('io_storeAddrIn', 2), ('io_storeAddrInRe', 2),
    ('io_storeDataIn', 2), ('io_storeMaskIn', 2), ('io_forward', 3),
    ('io_sbuffer', 2), ('io_vecFeedback', 2), ('io_perf', 8),
    ('io_diffStore_diffInfo', 2), ('io_diffStore_pmaStore', 2),
]


def split_channels(ports):
    """返回 (chans, scalars)。chans[name] = {'n':N, 'fields':[(dir,width,field)]}"""
    chans, scalars, taken = {}, [], set()
    for prefix, n in IDX_CHANS:
        fields, seen = [], {}
        for d, w, nm in ports:
            m = re.match(re.escape(prefix) + r'_(\d+)_(.+)$', nm)
            if not m:
                continue
            i, f = int(m.group(1)), m.group(2)
            if i >= n:
                sys.exit('FATAL: %s 下标 %d 超出预期 %d' % (prefix, i, n))
            seen.setdefault(i, []).append((d, w, f))
            taken.add(nm)
        if not seen:
            sys.exit('FATAL: 通道 %s 在 golden 端口表里一根都没有' % prefix)
        # fail-closed：每个下标的字段集必须一致，否则不是一个规整通道
        ref = seen[min(seen)]
        for i, fl in seen.items():
            if fl != ref:
                sys.exit('FATAL: 通道 %s 的第 %d 份字段集与第 0 份不一致'
                         '（golden 对某些下标做了 DCE，不能当规整数组处理）' % (prefix, i))
        chans[prefix] = {'n': len(seen), 'fields': ref}
    for d, w, nm in ports:
        if nm not in taken:
            scalars.append((d, w, nm))
    return chans, scalars


def sv_range(w):
    return (w + ' ') if w else ''


def struct_name(prefix):
    return prefix.replace('io_', 'sq_') + '_t'


def emit_pkg_structs(chans):
    """每个规整通道按方向拆成 ..._in_t / ..._out_t 两个 packed struct。"""
    out = []
    for prefix, info in chans.items():
        for d, suffix in (('input', 'in'), ('output', 'out')):
            fl = [(w, f) for dd, w, f in info['fields'] if dd == d]
            if not fl:
                continue
            tn = struct_name(prefix) + '_' + suffix
            out.append('  typedef struct packed {')
            for w, f in fl:
                out.append('    logic %-10s %s;' % (sv_range(w), f))
            out.append('  } %s;' % tn)
            out.append('')
    return out


def core_port_lines(chans, scalars):
    """可读核端口：规整通道走结构体数组，其余保持 golden 名（便于对照）。"""
    lines = []
    for prefix, info in chans.items():
        for d, suffix in (('input', 'in'), ('output', 'out')):
            if not any(dd == d for dd, _, _ in info['fields']):
                continue
            tn = struct_name(prefix) + '_' + suffix
            nm = prefix.replace('io_', '') + '_' + suffix
            lines.append('  %-6s %-26s %-24s [%d]' % (d, tn, nm, info['n']))
    for d, w, nm in scalars:
        if nm in ('clock', 'reset'):
            continue
        lines.append('  %-6s %-26s %-24s' % (d, 'logic ' + sv_range(w), nm))
    return lines


# ---------------------------------------------------------------------------
# per-entry 状态清单：★复位域逐条来自 G1 golden 实测★（不是照 Chisel 抄）。
#   async  = golden `always @(posedge clock or posedge reset)` 块，异步复位到 0
#   none   = golden `always @(posedge clock)` 块，**完全不复位**
# 实测：async 1076 个 reg / none 2913 个 reg，合计 3989 = golden reg 声明总数。
# 复现：scripts/gen_storequeue.py --reset-audit
# ---------------------------------------------------------------------------
ENTRY_FLAGS_ASYNC = [
    ('allocated',     '条目已分配（活 store）'),
    ('completed',     '数据已离开 SQ（可退队），与 committed 不同'),
    ('addrvalid',     'sta 已写入 paddr/vaddr/mask（或被异常强置）'),
    ('datavalid',     'std 已写入数据（fire 后 1 拍）'),
    ('committed',     'ROB 已提交，不可撤销（挡 needCancel）'),
    ('unaligned',     '非对齐 store'),
    ('cross16Byte',   '非对齐且跨 16B，需要 2 拍拆分'),
    ('pending',       'mmio，等着走到 ROB 头'),
    ('nc',            '不可缓存（pbmt NC）'),
    ('mmio',          'mmio'),
    ('memBackTypeMM', '★入队时不清★——见 §TRAP-2'),
    ('isVec',         '向量 store，只在入队时写'),
    ('vecLastFlow',   '本条目是向量 uop 的最后一个 flow，只在入队时写'),
    ('vecMbCommit',   '向量 merge buffer 判了 commit/flush'),
    ('hasException',  '该退队但不许写 sbuffer'),
    ('waitStoreS2',   '仍在等 store_s2 的 mmio/异常裁决；入队置 1'),
]
# golden 里 `r_*` / `r_1_*` 就是 stAddrReadyVec / stDataReadyVec 的输出寄存器
# （Chisel 的 GatedValidRegNext，使能 = 整条 56 位向量 != 现值；异步复位到 0）。
READY_VEC_ASYNC = [
    ('stAddrReadyVec_q', 'golden `r_*`',   'io_stAddrReadyVec_*'),
    ('stDataReadyVec_q', 'golden `r_1_*`', 'io_stDataReadyVec_*'),
]


def reset_audit(path=GOLDEN):
    """从 golden 直接重算复位域分区，作为上面清单的可复跑依据。"""
    L = path.read_text().split('\n')
    blocks = []
    for i, l in enumerate(L):
        if re.match(r'\s+always @\(', l):
            depth, started = 0, False
            for j in range(i, len(L)):
                depth += len(re.findall(r'\bbegin\b', L[j])) - len(re.findall(r'\bend\b', L[j]))
                if re.search(r'\bbegin\b', L[j]):
                    started = True
                if started and depth <= 0:
                    break
            lhs = set()
            for l2 in L[i:j + 1]:
                m = re.match(r'\s*([A-Za-z_]\w*)\s*<=', l2)
                if m:
                    lhs.add(m.group(1))
            blocks.append((i + 1, j + 1, 'async' if 'posedge reset' in l else 'sync', lhs))
    ndecl = sum(1 for l in L if re.match(r'\s+reg\b', l))
    print('golden reg 声明 : %d' % ndecl)
    for a, b, kind, lhs in blocks:
        if not lhs:
            continue
        has_rst = kind == 'async'
        print('L%-6d-%-6d %-5s 复位=%-3s 驱动 %d 个 reg'
              % (a, b, kind, 'async' if has_rst else '无', len(lhs)))
    tot = sum(len(l) for _, _, _, l in blocks)
    print('合计驱动 %d 个 reg（须等于声明数 %d）：%s'
          % (tot, ndecl, 'OK' if tot == ndecl else '★不一致'))


HEAD = r'''// =============================================================================
//  StoreQueue —— 访存子系统的存储队列（G1 golden: StoreQueue.sv, 77145 行 / 1003 端口）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala (1597 行)
//               同目录 StoreQueueData.scala / sbuffer/DatamoduleResultBuffer.scala
//  golden 基线：G1-canonical (XiangShan kunminghu-v2 @ b36a1a2a5, KunminghuV2Config)
//
//  ★★★ 本文件是**考古阶段的骨架**，不是完成的重写 ★★★
//  只有「已在 golden 上实测核对过」的东西才写进来：
//    · 端口契约（1003 根，逐位从 golden 端口表推导，不是手抄）
//    · per-entry 状态清单与**复位域**（async / 不复位，实测分区见 §3）
//    · 多源写同一状态位的**优先级骨架**（条件线名已留，方程未追清的标 TODO）
//    · 5 个子模块的例化形状
//  功能方程绝大部分**尚未追清**，集中列在文件末尾 §9 待办清单。
//  任何人不得据本文件声称 StoreQueue 已重写完成。
//
//  store 的一生：
//    dispatch 入队(分配条目) → sta 写地址(s1/s2 两拍) → std 写数据 → ROB 提交
//    → 读出送 dataBuffer → 写 Sbuffer(可缓存) / 走 uncache(mmio·NC) → 退队
//  并行地，load 通过 forward 端口在队列里做地址 CAM 做 store-to-load 转发。
//
// =============================================================================
// 本文件导航：
//@NAV@
'''



# ---------------------------------------------------------------------------
# 输出驱动分解（--outmap）
#
# 为什么要有这张表：StoreQueue 的 399 根输出不是一个均质的工作量。实测分解后
# 才看得出「哪些根必须等子模块、哪些根是纯直连」。没有这张表，后续 lane 只能
# 凭 77145 行这个数字估工，那个数字**严重高估**真实逻辑量（firtool 把每个宽
# mux 摊成几十行，行数是排版产物不是逻辑量）。
#
# 分类口径（全部从 golden 机械提取，不靠人读）：
#   submodule     该输出在 golden 里直接接某个子模块的输出端口
#                 ★这类根的正确性取决于子模块，父层证不了★
#   assign_direct assign io_x = <单个标识符>;  —— firtool 把逻辑提到具名 wire 了，
#                 真正的逻辑在那根 wire 上，不在这条 assign 上
#   assign_expr   assign 右边是真表达式（按标识符个数分档）
# ---------------------------------------------------------------------------
def outmap(path=GOLDEN):
    txt = path.read_text()
    ports = parse_ports(path)
    outs = [(d, w, n) for d, w, n in ports if d == 'output']
    onames = set(n for d, w, n in outs)
    body = txt[txt.index(');', txt.index('module StoreQueue')):]
    drv = {}
    for s in body.split(';'):
        m = re.search(r'assign\s+([A-Za-z_][A-Za-z0-9_]*)\s*=', s)
        if m and m.group(1) in onames:
            drv[m.group(1)] = ' '.join(s[m.end():].split())
    # 子模块实例的端口直连：.someport(io_xxx)
    inst = {}
    for im in re.finditer(r'^\s{2}([A-Z][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(',
                          body, re.M):
        start = im.end()
        depth, i = 1, start
        while i < len(body) and depth:
            if body[i] == '(':
                depth += 1
            elif body[i] == ')':
                depth -= 1
            i += 1
        for pm in re.finditer(r'\.\s*([A-Za-z0-9_]+)\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)',
                              body[start:i]):
            if pm.group(2) in onames:
                inst[pm.group(2)] = '%s.%s' % (im.group(1), pm.group(1))
    rows = ['# 由 scripts/gen_storequeue.py --outmap 从 G1 golden 机械生成，勿手改',
            '# output\twidth\tdriver_kind\tdriver_detail']
    for d, w, n in outs:
        if n in inst:
            kind, det = 'submodule', inst[n]
        elif n in drv:
            e = drv[n]
            ntok = len(re.findall(r'[A-Za-z_][A-Za-z0-9_]*', e))
            if ntok <= 1:
                kind, det = 'assign_direct', e
            else:
                kind, det = 'assign_expr%d' % ntok, (e[:120] + ('...' if len(e) > 120 else ''))
        else:
            kind, det = 'UNDRIVEN', ''
        rows.append('%s\t%s\t%s\t%s' % (n, w if w else '[0:0]', kind, det))
    return '\n'.join(rows) + '\n'

def emit(chans, scalars):
    S = []          # (锚点名, 标题) -> 行号，最后回填导航
    out = []

    def sec(title):
        out.append('')
        out.append('// ' + '-' * 77)
        out.append('// ' + title)
        out.append('// ' + '-' * 77)
        S.append((len(out) - 2, title))   # 指向标题那一行

    # ---- package ----
    sec('§1 storequeue_pkg —— 参数、SqPtr 环形指针、各通道结构体')
    out.append('package storequeue_pkg;')
    out.append('')
    out.append('  // 参数取自 Parameters.scala（KunminghuV2Config 未覆盖任何一项），')
    out.append('  // 每一项都已用 golden 的端口下标/位宽反查确认。')
    out.append('  localparam int SQ_SIZE      = 56;  // StoreQueueSize，★非 2 的幂★')
    out.append('  localparam int SQ_IDX_W     = 6;   // = $clog2(64)，指针 value 位宽')
    out.append('  localparam int N_STA        = 2;   // StorePipelineWidth（storeAddrIn/Re）')
    out.append('  localparam int N_STD        = 2;   // 同上（storeDataIn/storeMaskIn）')
    out.append('  localparam int N_FWD        = 3;   // LoadPipelineWidth（forward 查询口）')
    out.append('  localparam int N_ENSBUF     = 2;   // EnsbufferWidth（sbuffer/deq/rdata）')
    out.append('  localparam int N_ENQ        = 6;   // LSQEnqWidth = RenameWidth')
    out.append('  localparam int N_COMMIT     = 8;   // CommitWidth（cmtPtrExt 8 份）')
    out.append('  localparam int N_VECFB      = 2;   // VecLoadPipelineWidth（vecFeedback）')
    out.append('  localparam int N_PERF       = 8;')
    out.append('  localparam int VLEN         = 128;')
    out.append('')
    out.append('  // 门限三则，全部按 golden 的字面形式记（不要转写成「<=」再自己换算）：')
    out.append('  //   golden L5190 : allowEnqueue   = validCount  < 6\'h35 (53)')
    out.append('  //   golden L69648: io_force_write = valid_cnt   > 6\'h33 (51)')
    out.append('  //                  持续条件         valid_cnt   > 6\'h2E (46)')
    out.append('  localparam int ALLOW_ENQ_LT      = 53;  // validCount < 53')
    out.append('  localparam int FORCE_WR_SET_GT   = 51;')
    out.append('  localparam int FORCE_WR_HOLD_GT  = 46;')
    out.append('')
    sec('§1.1 SqPtr —— 56 项环形指针（★不是 2 的幂，加法是比较-减法★）')
    out.append('  // CircularQueuePtr：{flag,value}，flag 每绕一圈翻转。因为 56 不是 2 的幂，')
    out.append('  // 「+」必须写成 new=value+v; if (new>=56) {flag=~flag; value=new-56;}，')
    out.append('  // ★绝不能写成对 {flag,value} 整体做计数器自增★。')
    out.append('  typedef struct packed {')
    out.append('    logic                 flag;')
    out.append('    logic [SQ_IDX_W-1:0]  value;')
    out.append('  } sqptr_t;')
    out.append('')
    out.append('  function automatic sqptr_t sqptr_add(sqptr_t p, int unsigned v);')
    out.append('    int unsigned nv;')
    out.append('    nv = p.value + v;')
    out.append('    if (nv >= SQ_SIZE) sqptr_add = \'{flag: ~p.flag, value: SQ_IDX_W\'(nv - SQ_SIZE)};')
    out.append('    else               sqptr_add = \'{flag:  p.flag, value: SQ_IDX_W\'(nv)};')
    out.append('  endfunction')
    out.append('')
    out.append('  // isAfter / distanceBetween 只在「相距不超过一圈」时有效（golden 同）。')
    out.append('  function automatic logic sqptr_after(sqptr_t a, sqptr_t b);')
    out.append('    sqptr_after = (a.flag ^ b.flag) ^ (a.value > b.value);')
    out.append('  endfunction')
    out.append('')
    out.append('  function automatic logic [SQ_IDX_W:0] sqptr_dist(sqptr_t a, sqptr_t b);')
    out.append('    sqptr_dist = (a.flag == b.flag) ? (a.value - b.value)')
    out.append('                                    : (SQ_SIZE + a.value - b.value);')
    out.append('  endfunction')
    out.append('')
    sec('§1.2 通道结构体（字段集与位宽由 golden 端口表机械推导）')
    out += emit_pkg_structs(chans)
    out.append('endpackage')
    out.append('')

    # ---- core ----
    sec('§2 xs_StoreQueue_core —— 可读核')
    out.append('module xs_StoreQueue_core')
    out.append('  import storequeue_pkg::*;')
    out.append('(')
    out.append('  input  logic                      clock,')
    out.append('  input  logic                      reset,')
    pl = core_port_lines(chans, scalars)
    for i, l in enumerate(pl):
        out.append(l + (',' if i != len(pl) - 1 else ''))
    out.append(');')
    out.append('')

    sec('§3 per-entry 状态 —— ★复位域是 golden 实测，不是照 Chisel 抄★')
    out.append('  // golden 只有两个时序块，泾渭分明（scripts/gen_storequeue.py --reset-audit 可复跑）：')
    out.append('  //   always @(posedge clock or posedge reset)  L62202-69650  1076 reg  异步复位')
    out.append('  //   always @(posedge clock)                   L20336-58753  2913 reg  ★完全不复位★')
    out.append('  //   1076 + 2913 = 3989 = golden reg 声明总数（守恒）')
    out.append('  // 把不复位的那 2913 个照抄成「有复位」是真 bug，elaborate 与 lint 都不会报。')
    out.append('')
    out.append('  // ---- 异步复位到 0 的 per-entry 标志位（每条 56 位）----')
    for n, c in ENTRY_FLAGS_ASYNC:
        out.append('  logic [SQ_SIZE-1:0] %-16s // %s' % (n + ';', c))
    out.append('')
    out.append('  // allvalid 在 golden 里是**组合线**，不是寄存器（Chisel SQ:259 是 Wire）。')
    out.append('  logic [SQ_SIZE-1:0] allvalid;')
    out.append('  assign allvalid = addrvalid & datavalid & allocated;')
    out.append('')
    out.append('  // ---- 就绪向量输出寄存器（golden r_* / r_1_*）----')
    out.append('  // Chisel 是 GatedValidRegNext：使能 = 「整条 56 位次态 != 现值」，异步复位 0。')
    out.append('  // 该使能与「无条件 RegNext」功能等价（次态等于现值时写不写都一样），')
    out.append('  // 但 golden 里确实是带使能的形式；这里照抄结构，别化简。')
    for n, g_, o in READY_VEC_ASYNC:
        out.append('  logic [SQ_SIZE-1:0] %-20s // %s -> %s' % (n + ';', g_, o))
    out.append('  logic [SQ_SIZE-1:0] stAddrReadyVecReg, stDataReadyVecReg; // 组合次态')
    out.append('')
    out.append('  // ---- 指针 ----')
    out.append('  // ★DCE 形状必须照抄★（golden 实测，多写出来的就是 unread，FM 判 PARTIAL）：')
    out.append('  //   enqPtrExt   Chisel 6 份，golden **只剩第 0 份**（1..5 flag+value 全死）')
    out.append('  //   cmtPtrExt   Chisel 8 份，golden 保留 8 份 value，但 **只有第 0 份有 flag**')
    out.append('  //   deqPtrExt   2 份，两份的 flag 与 value **都活**')
    out.append('  //               （Chisel 侧分析曾判 deqPtrExt(1).flag 已死 —— golden 实测是活的，')
    out.append('  //                 L69109 的 dataPtrInDeqGroupRangeVec 读它。以 golden 为准。）')
    out.append('  //   rdataPtrExt 2 份全活（第 1 份 flag 经 dataBuffer 逃逸到 cboZeroStout.sqIdx）')
    out.append('  sqptr_t                     enqPtrExt;               // 仅第 0 份')
    out.append('  sqptr_t                     deqPtrExt   [N_ENSBUF];')
    out.append('  sqptr_t                     rdataPtrExt [N_ENSBUF];')
    out.append('  logic [SQ_IDX_W-1:0]        cmtPtrValue [N_COMMIT];  // 8 份 value')
    out.append('  logic                       cmtPtrFlag;              // ★只有第 0 份有 flag★')
    out.append('  sqptr_t                     addrReadyPtrExt, dataReadyPtrExt;')
    out.append('')
    out.append('  // ---- 不复位的 per-entry 载荷（golden 的 2913 个无复位 reg 的主体）----')
    out.append('  // 每条目一份 uop 快照：24 位 exceptionVec + 26 个字段。整块**不复位**。')
    out.append('  // ★按「一个字段一个 56 项数组」声明★，不要打包成 struct 数组：上一轮')
    out.append('  //   用 struct 数组导致 FM 与 golden 的扁平标量 allocated_N 约 35K 个寄存器')
    out.append('  //   配对不收敛，大量 unverified（见 xs-v2r2-sv/docs/memblock/StoreQueue.md §7.3）。')
    out.append('  logic [23:0]  uop_exceptionVec [SQ_SIZE];')
    out.append('  logic [34:0]  uop_fuType       [SQ_SIZE];')
    out.append('  logic [8:0]   uop_fuOpType     [SQ_SIZE];')
    out.append('  logic [7:0]   uop_robIdx_value [SQ_SIZE];')
    out.append('  logic         uop_robIdx_flag  [SQ_SIZE];')
    out.append('  logic [6:0]   uop_uopIdx       [SQ_SIZE];')
    out.append('  // TODO(§9-A) 其余 uop 字段照 golden 端口表补全（共 52 个，勿凭记忆列）。')
    out.append('')

    sec('§4 多源写优先级骨架 —— ★条件线名照 golden，方程未追清处标 TODO★')
    out.append('  // golden 实测的写优先级（最高在前）。条件线在 golden 里是 _GEN_*，')
    out.append('  // 这里给它们取回可读名；**方程本身尚未逐条追清**，见 §9。')
    out.append('  //')
    out.append('  //   uop 载荷 / nc / unaligned / cross16Byte：')
    out.append('  //       sta 口1-s1  >  sta 口0-s1  >  入队分配')
    out.append('  //       （golden L20337: if(_GEN_553) else if(_GEN_497) else if(entryCanEnq)；')
    out.append('  //         _GEN_553 = io_storeAddrIn_1_valid & 命中本条目）')
    out.append('  //   addrvalid / mmio / memBackTypeMM / hasException：')
    out.append('  //       口1-s2 > 口1-s1 > 口0-s2 > 口0-s1 > 入队')
    out.append('  //       ★不是「s2 一律压 s1」★——两条流水是展开的，口1 的 s1 压过口0 的 s2。')
    out.append('  //       （golden L63833-63849 的四层 if/else 就是这个形状）')
    out.append('  //   allocated  ：needCancel(冲刷) > 入队置位 > 退队清零')
    out.append('  //   completed  ：needCancel > sbuffer 回执 > 提交时 nc&异常 > cboZero 回写')
    out.append('  //                > mmio 回写 > NC 完成 > 入队清零 > 退队清零')
    out.append('  //   pending    ：mmio 发请求时清零 > 口1-s2 > 口0-s2 > 入队')
    out.append('  //   vecMbCommit：maControl.withSamePtr > 向量反馈 > 入队清零')
    out.append('')
    out.append('  // ===================== ★TRAP-2：memBackTypeMM 不清 ★ =====================')
    out.append('  // golden L63835/63843 只在两个 sta-s2 分支里写 memBackTypeMM，最内层 else')
    out.append('  // **没有** `~entryCanEnq & memBackTypeMM` 这一项 —— 而同一组里的 mmio 与')
    out.append('  // hasException 都有。也就是说：入队**不清** memBackTypeMM，它会保留上一个')
    out.append('  // 占用者的值，直到某次 sta-s2 覆盖。Chisel 侧同样确认（入队清零清单里没有它）。')
    out.append('  // 顺手抹平成「入队一起清」是真 bug，UT 极难打到。')
    out.append('  // =======================================================================')
    out.append('')
    out.append('  // TODO(§9-B) entryCanEnq / needCancel / 各 _GEN_ 条件的方程')
    out.append('')

    sec('§5 子模块例化 —— ★5 个子模块在本仓一个都没有实现★')
    out.append('  // golden 例化 5 个（G0 与 G1 相同的 5 个，实例名照抄）：')
    out.append('  //   dataModule      SQDataModule   (56,rd2,wr2,fwd3)  内部 16×SQData8Module 按字节分道')
    out.append('  //   paddrModule     SQAddrModule   (dataWidth=48)     物理地址阵列 + 地址 CAM')
    out.append('  //   vaddrModule     SQAddrModule_1 (dataWidth=50)     虚地址阵列 + 地址 CAM（转发用它选）')
    out.append('  //   dataBuffer      DatamoduleResultBuffer            SQ 读出级到 Sbuffer 的 2 项 skid')
    out.append('  //   exceptionBuffer StoreExceptionBuffer              7 口单条目「最老者胜」异常地址锁存')
    out.append('  // paddrModule/vaddrModule 是同一个 Chisel 类的两次不同 dataWidth 例化，')
    out.append('  // 可读实现应写成一个参数化核 + 两个薄 wrapper（家族规则）。')
    out.append('  //')
    out.append('  // ★状态★：这 5 个在 docs/g1_configured_universe.tsv 里都是 new_target，')
    out.append('  //   rtl/ 下**一个都不存在**；docs/g1_universe.tsv 只收了 StoreExceptionBuffer。')
    out.append('  //   docs/migration_plan_199.tsv 的 StoreQueue 行记 n_children_todo=1，')
    out.append('  //   ★漏记了另外 4 个★。StoreQueue 的签核在它们落地前无法闭合。')
    out.append('  // TODO(§9-C) 5 个子模块的例化与绑定')
    out.append('')

    sec('§6 组合输出 —— TODO')
    out.append('  // TODO(§9-D) 全部 399 根输出的驱动')
    out.append('')

    sec('§7 时序：异步复位块（对应 golden L62202-69650）')
    out.append('  always_ff @(posedge clock or posedge reset) begin')
    out.append('    if (reset) begin')
    for n, _ in ENTRY_FLAGS_ASYNC:
        out.append('      %-16s <= \'0;' % n)
    for n, _, _ in READY_VEC_ASYNC:
        out.append('      %-16s <= \'0;' % n)
    out.append('      // TODO(§9-E) 指针的复位初值：enq/deq/rdata/cmt 的第 i 份复位成 value=i,flag=0')
    out.append('    end')
    out.append('    else begin')
    out.append('      // TODO(§9-E) 按 §4 的优先级填次态')
    out.append('    end')
    out.append('  end')
    out.append('')

    sec('§8 时序：★不复位★块（对应 golden L20336-58753，2913 个 reg）')
    out.append('  // 这里**故意没有 if (reset)**——golden 这一整块不复位。加上复位就是真 bug。')
    out.append('  always_ff @(posedge clock) begin')
    out.append('    // TODO(§9-A) uop 载荷按「口1-s1 > 口0-s1 > 入队」三级优先级锁存')
    out.append('  end')
    out.append('')

    sec('§9 待办清单 —— ★尚未追清的方程，逐条列明，不许含糊★')
    for t in [
        'A. uop 载荷 52 个字段的完整清单与三级优先级锁存（结构已确认，字段未逐条对齐）',
        'B. entryCanEnq（6 路 dispatch 的环形区间覆盖判定）与 needCancel（含向量异常旗标的',
        '   「严格在后」变体）的方程 —— 两者都只从 Chisel 读过，未在 golden 上核对',
        'C. 5 个子模块（SQDataModule/SQAddrModule/SQAddrModule_1/DatamoduleResultBuffer/',
        '   StoreExceptionBuffer）的重写，本仓一个都没有',
        'D. 399 根输出的驱动方程，其中这些整块未追：',
        '   · store-to-load 转发（3 口 CAM、forwardMask1/2 的 deqMask 区间选择、',
        '     dataInvalid 里「任意已分配的非对齐 store 无条件致 dataInvalid」这条怪规则）',
        '   · 出队到 dataBuffer/Sbuffer 的三分支（跨 16B 拆分 / 非跨 16B 非对齐 / 常规）',
        '   · mmio 5 态 FSM 与 NC 4 态 FSM，以及 CBO 分支对 FSM 的**越权覆盖**',
        '   · cboZero 通路、向量通路（vecExceptionFlag 的 set/clear 优先级）',
        '   · 跨 4K 页到 StoreMisalignBuffer 的交接',
        '   · 8 路 perf 计数与 difftest 的 diffStore / gatewayIn_packed_48_bore',
        'D2. ★perf 观测探针★：golden 里有 15 个 `*_probe` 线，SimTop 的 perf 台账通过',
        '   XMR 观测它们（docs/perf_bore_map.tsv 里 21 行绑到 StoreQueue）。本文件一进',
        '   rtl/，这 21 行就从 T0_UNCHANGED 掉到未绑定 —— 可读核必须**按同名导出**：',
        '     empty_probe / empty_1_probe / exHalf_probe / exHalf_1_probe',
        '     _io_sqFull_T_probe / mmioDoReq_probe / validCount_probe',
        '     perfEvents_0_2_probe / perfEvents_2_2_probe',
        '     vpmaskNotEqual{,_1,_2}_probe / vaddrMatchFailed{,_1,_2}_probe',
        '   （★不许接零冒充已绑★，见 docs/perf_bore_unbound.tsv 的口径）',
        'E. 全部指针推进方程（sqDeqCnt 的「循环内后写者胜」、readyReadGoVec 的组合链、',
        '   addrReady/dataReadyPtr 的 stride<=4 推进与冲刷时的强制值）',
        'F. ★rdataPtr 与 deqPtr 是两个独立计数器★，RAM 读地址用的是 rdataPtrExtNext（提前一拍），',
        '   模块内部再寄存一次。这条极易写错，必须在 UT 里单独钉。',
        'G. ★读锁存值还是读 live 值★ —— 上一轮在这里出过一个真 bug：',
        '   io_cmoOpReq_bits_opcode 取了 uop[deqPtr].fuOpType 的**当前值**。',
        '   本轮已在 G1 golden 上复核（不是凭记忆），钉死如下：',
        '     StoreQueue.sv:76759  assign io_cmoOpReq_bits_opcode = {1\'h0, uncacheUop_fuOpType[1:0]};',
        '     StoreQueue.sv:12951  reg  [8:0] uncacheUop_fuOpType;      <- 是**寄存器**',
        '     StoreQueue.sv:58436  uncacheUop_fuOpType <= _GEN_380;     <- 在不复位块里锁存',
        '                          （always @(posedge clock) 自 L20336 起，条件 _GEN_388）',
        '   即 golden 读的是**锁存的那一拍**，不是 uop[deqPtr] 的 live 值。',
        '   uncacheUop_* 这一整族（fuOpType/rfWen/uopIdx/pdest/robIdx_* ...）都是同一个',
        '   锁存组，写 uncache/CBO 通路时一律读锁存值。这类错只在特定时序下暴露，',
        '   随机 UT 不保证抓得到，必须**按构造**写对。',
    ]:
        out.append('//   ' + t)
    out.append('')
    out.append('endmodule')
    out.append('')

    # ---- wrapper ----
    sec('§10 StoreQueue —— golden 同名 wrapper（1003 根端口，逐位对齐）')
    out.append('module StoreQueue(')
    allp = [(d, w, n) for d, w, n in parse_ports()]
    for i, (d, w, n) in enumerate(allp):
        out.append('  %-6s %-10s %s%s' % (d, sv_range(w).strip(), n,
                                          ',' if i != len(allp) - 1 else ''))
    out.append(');')
    out.append('')
    # §9-G 扁平端口 <-> 结构体数组接线 + u_core 例化（机械生成，不手写）
    out.append('  // 扁平 golden 端口 <-> 可读核结构体数组的接线。')
    out.append('  // ★本段全部由 gen_storequeue.py 机械生成★：字段顺序直接取自')
    out.append('  //   emit_pkg_structs 用的同一张 chans 表，所以 packed struct 的位序')
    out.append('  //   与这里的赋值**按构造**一致，不存在手写错位的可能。')
    out.append('')
    for prefix, info in chans.items():
        base = prefix.replace('io_', '')
        n = info['n']
        for d, suffix in (('input', 'in'), ('output', 'out')):
            fl = [(w, f) for dd, w, f in info['fields'] if dd == d]
            if not fl:
                continue
            tn = struct_name(prefix) + '_' + suffix
            out.append('  %s %s_%s [%d];' % (tn, base, suffix, n))
            for i in range(n):
                for w, f in fl:
                    flat = '%s_%d_%s' % (prefix, i, f)
                    if d == 'input':
                        out.append('  assign %s_%s[%d].%s = %s;' % (base, suffix, i, f, flat))
                    else:
                        out.append('  assign %s = %s_%s[%d].%s;' % (flat, base, suffix, i, f))
            out.append('')
    out.append('  xs_StoreQueue_core u_core (')
    conn = ['    .clock(clock)', '    .reset(reset)']
    for prefix, info in chans.items():
        base = prefix.replace('io_', '')
        for d, suffix in (('input', 'in'), ('output', 'out')):
            if not [1 for dd, w, f in info['fields'] if dd == d]:
                continue
            conn.append('    .%s_%s(%s_%s)' % (base, suffix, base, suffix))
    for d, w, n in scalars:
        if n in ('clock', 'reset'):
            continue
        conn.append('    .%s(%s)' % (n, n))
    out.append(',\n'.join(conn))
    out.append('  );')
    out.append('')
    out.append('endmodule')

    # ---- 回填导航 ----
    # ★不用行号算术★：先用占位符拼出最终文本，再**在成品里搜分节标题的真实行号**
    #   回填。readability_audit 的 E 项按行号校验导航，算错一行就红，而算术形式
    #   每加一节都得重算偏移 —— 直接搜索是幂等且免疫偏移的写法。
    body = '\n'.join(out)
    nav = ['//   L@%d@ %s' % (i, title) for i, (_, title) in enumerate(S)]
    text = HEAD.replace('//@NAV@', '\n'.join(nav)) + body + '\n'
    lines = text.split('\n')
    for i, (_, title) in enumerate(S):
        ln = next(k for k, l in enumerate(lines) if l == '// ' + title) + 1
        text = text.replace('L@%d@' % i, 'L%-6d' % ln)
    # fail-closed：占位符必须全部被替换
    if '@' in ''.join(l for l in text.split('\n') if l.startswith('//   L')):
        raise SystemExit('FATAL: 导航占位符未全部回填')
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dump-ports', action='store_true')
    ap.add_argument('--reset-audit', action='store_true')
    ap.add_argument('--outmap', action='store_true',
                    help='输出驱动分解表 -> docs/storequeue_output_map.tsv')
    ap.add_argument('--emit', action='store_true')
    ap.add_argument('--check', action='store_true',
                    help='幂等校验：重新生成并与仓库内 rtl/memblock/StoreQueue.sv 比对，'
                         '不一致则退出码 1（供 gate_all.sh 调用）')
    ap.add_argument('-o', '--out')
    a = ap.parse_args()
    ports = parse_ports()
    if a.dump_ports:
        for d, w, n in ports:
            print('%-6s %-10s %s' % (d, w, n))
        return
    if a.reset_audit:
        reset_audit()
        return
    OUTMAP = pathlib.Path(__file__).resolve().parent.parent / 'docs' / 'storequeue_output_map.tsv'
    if a.outmap:
        OUTMAP.write_text(outmap())
        print('wrote %s' % OUTMAP)
        return 0
    if a.check:
        want_map = outmap()
        if not OUTMAP.exists() or OUTMAP.read_text() != want_map:
            print('FAIL gen_storequeue --check: %s 与 golden 不一致（跑 --outmap 重生成）' % OUTMAP)
            return 1
        chans, scalars = split_channels(ports)
        want = emit(chans, scalars)
        tgt = pathlib.Path(__file__).resolve().parent.parent / 'rtl' / 'memblock' / 'StoreQueue.sv'
        if not tgt.exists():
            print('FAIL gen_storequeue --check: %s 不存在' % tgt)
            return 1
        got = tgt.read_text()
        if got != want:
            import difflib
            d = list(difflib.unified_diff(got.splitlines(), want.splitlines(),
                                          'repo', 'regen', lineterm=''))
            print('FAIL gen_storequeue --check: %s 与生成器输出不一致 (%d 行差异)'
                  % (tgt, len(d)))
            for line in d[:40]:
                print(line)
            return 1
        print('PASS gen_storequeue --check: %s 与生成器输出一致 (%d 行)'
              % (tgt, want.count(chr(10))))
        return 0
    if a.emit:
        chans, scalars = split_channels(ports)
        t = emit(chans, scalars)
        if a.out:
            pathlib.Path(a.out).write_text(t)
            print('wrote %s (%d lines)' % (a.out, t.count('\n')))
        else:
            print(t)
        return
    ap.print_help()


if __name__ == '__main__':
    sys.exit(main() or 0)
