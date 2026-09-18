#!/usr/bin/env python3
"""gen.py —— 生成 UncacheEntry 家族的参数化核、16 个薄 wrapper 与 UT testbench。

为什么必须生成：golden 每个变体 **611 个标量端口**（uop bundle 被 firtool 逐字段
展平），tb 还要把每个端口各连两遍（golden / 重写）、逐拍比对 401 个输出。手抄必错。

★家族考古结论（实测，不是推的）★
  16 个 golden 文件（UncacheEntry / _1 … _15）各 1852 行、611 端口。把模块名归一后
  **逐字节 diff：每一对都只差第 906 行一个常数**：

      req_valid & io_uncache_idResp_valid & io_uncache_idResp_bits_mid == 7'hN

  N = 0..F 恰好等于文件后缀（基名 UncacheEntry 为 0）。除此之外 0 处差异 ——
  端口表、寄存器表、复位域、全部 404 条 assign 一字不差。
  与 Chisel 对账：`class UncacheEntry(entryIndex: Int)`，entryIndex 在整个类里
  **只被用了两次**：`idResp.bits.mid === entryIndex.U` 与
  `io.uncache.req.bits.id := entryIndex.U`；后者在 KunminghuV2Config 下被父级
  LoadQueueUncache 丢弃（golden 端口表里没有 io_uncache_req_bits_id），所以展开后
  只剩一处。⇒ **16/16 全是纯参数变体，一个核覆盖全部 16 个，没有一个要单列。**
  父级：LoadQueueUncache.sv 例化 entries_0..entries_15 ↔ UncacheEntry{,_1..._15}，
  实例号与 mid 常数一一对应（脚本 check_family() 每次跑都复核这两件事）。

用法：python3 gen.py          （幂等：内容不变不碰文件）
      python3 gen.py --check  （只核对，不写；家族假设被推翻时非零退出）
"""
import argparse
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'rtl' / 'memblock'

VARIANTS = ['UncacheEntry'] + [f'UncacheEntry_{i}' for i in range(1, 16)]
# 变体名 -> entryIndex（= idResp.mid 比较常数）。由 check_family() 从 golden 实测复核。
ENTRY_ID = {m: (0 if m == 'UncacheEntry' else int(m.split('_')[1])) for m in VARIANTS}

PORT_RE = re.compile(r'^\s*(input|output)\s+(\[[^\]]*\]\s*)?(\w+)\s*,?\s*$')


# ---------------------------------------------------------------------------
# golden 解析
# ---------------------------------------------------------------------------
def golden_text(mod):
    return (GOLDEN / f'{mod}.sv').read_text()


def golden_body(mod):
    t = golden_text(mod)
    return t[t.index(f'module {mod}('):]


def golden_ports(mod='UncacheEntry'):
    """返回 [(dir, width_decl_or_'', name)]，顺序即 golden 端口表顺序。"""
    body = golden_body(mod)
    head = body[:body.index(');')]
    out = []
    for line in head.splitlines()[1:]:
        m = PORT_RE.match(line)
        if m:
            out.append((m.group(1), (m.group(2) or '').strip(), m.group(3)))
    return out


def width_bits(decl):
    """'[7:0]' -> 8; '' -> 1。"""
    if not decl:
        return 1
    hi, lo = decl.strip()[1:-1].split(':')
    return int(hi) - int(lo) + 1


def golden_assigns(mod='UncacheEntry'):
    """[(lhs, rhs)]，已把折行拼回一行。"""
    code = re.sub(r'\n\s+', ' ', golden_body(mod))
    return re.findall(r'assign (\w+) = ([^;]+);', code)


def golden_regs(mod='UncacheEntry'):
    return re.findall(r'^  reg\s+(\[[^\]]*\]\s*)?(\w+);', golden_body(mod), re.M)


# ---------------------------------------------------------------------------
# 家族假设复核（每次生成都跑；假设被推翻就当场停）
# ---------------------------------------------------------------------------
def check_family():
    """逐个复核 16 个变体：除模块名与 mid 常数外必须逐字节相同。不许外推。"""
    errs = []
    base = golden_text('UncacheEntry')
    for m in VARIANTS:
        t = golden_text(m)
        norm = t.replace(m, 'UncacheEntry')
        if m == 'UncacheEntry':
            norm_expect = base
        else:
            # 把基名文件的 mid 常数换成本变体的，再与归一后的本变体比
            norm_expect = base.replace(
                "io_uncache_idResp_bits_mid == 7'h0;",
                "io_uncache_idResp_bits_mid == 7'h%X;" % ENTRY_ID[m])
        if norm != norm_expect:
            d = [i for i, (a, b) in enumerate(zip(norm.splitlines(),
                                                  norm_expect.splitlines()))
                 if a != b]
            errs.append(f'{m}: 与「纯参数变体」假设不符，差异行 {d[:10]}')
        # 直接把 mid 常数读出来核对
        mids = re.findall(r'io_uncache_idResp_bits_mid == 7\'h([0-9A-F]+);', t)
        if mids != ['%X' % ENTRY_ID[m]]:
            errs.append(f'{m}: mid 常数实测 {mids}，期望 {ENTRY_ID[m]:X}')
    # 父级实例号 <-> 变体名的对应
    parent = (GOLDEN / 'LoadQueueUncache.sv').read_text()
    inst = re.findall(r'^  (UncacheEntry(?:_\d+)?) (entries_\d+) \($', parent, re.M)
    want = [(m, f'entries_{ENTRY_ID[m]}') for m in VARIANTS]
    if sorted(inst) != sorted(want):
        errs.append(f'LoadQueueUncache 实例映射实测 {inst}，期望 {want}')
    return errs


# ---------------------------------------------------------------------------
# 端口分组（全部从 golden 端口表机械推导，不硬编码字段清单）
# ---------------------------------------------------------------------------
PORTS = None          # 延迟初始化
REQ_FIELDS = None     # io_req_bits_<f> 的 <f> 列表（=190 个 payload 字段）


def init_tables():
    global PORTS, REQ_FIELDS
    PORTS = golden_ports()
    REQ_FIELDS = [n[len('io_req_bits_'):] for d, w, n in PORTS
                  if d == 'input' and n.startswith('io_req_bits_')]


def port_width(name):
    for d, w, n in PORTS:
        if n == name:
            return w
    raise KeyError(name)


# 核内部把 golden 的几个中间 wire 换成有语义的名字；payload 寄存器沿用 golden 的
# req_* 名（它们本身就是语义名：被锁存的那条请求的某个字段）。
WIRE_MAP = {
    'io_mmioOut_valid_0': 'mmio_out_valid',
    'io_ncOut_valid_0': 'nc_out_valid',
    'io_uncache_req_valid_0': 'uncache_req_valid',
    'uncacheData': 'resp_data',
    'slaveAccept': 'slave_accept',
    'slaveId': 'slave_id',
    'uncacheState': 'state',
    'flush': 'flush',
}


def map_rhs(rhs):
    """把 golden assign 的右值翻成核内部名字。只允许出现白名单里的符号。"""
    allowed = set(WIRE_MAP) | {'denied', 'corrupt', 'req_valid'}
    allowed |= {'req_' + f for f in REQ_FIELDS}
    allowed |= {'req_uop_flushPipe', 'req_uop_replayInst'}
    allowed |= {'state', 'S_IDLE', 'writeback'}  # (|uncacheState) 的替换产物

    def sub(m):
        w = m.group(0)
        if w in WIRE_MAP:
            return WIRE_MAP[w]
        if w in allowed:
            return w
        raise AssertionError(f'未预期的右值符号: {w} (in {rhs})')

    # 特判：state 的比较在核里用 enum
    r = rhs
    r = r.replace('(|uncacheState)', '(state != S_IDLE)')
    # ★前瞻必须排掉数字字面量★：7'h0 / 65'h0 里的 h0 也能匹配标识符正则，
    # 不排掉会把常数当成未知符号（第一次跑就在 {65'h0, uncacheData} 上炸过）。
    return re.sub(r"(?<![\w'])[A-Za-z_]\w*", sub, r)


# ---------------------------------------------------------------------------
# 核
# ---------------------------------------------------------------------------
CORE_HEADER = '''\
// =============================================================================
// xs_UncacheEntry_core —— LoadQueueUncache 的**单条** uncache(MMIO / NC) load 条目
//                         （UncacheEntry 家族 16 个变体共用的参数化核）
//
// 位置：MemBlock / LSU 的 LoadQueue 侧。一条 load 如果落在 uncacheable 区间
//       （MMIO 设备寄存器，或 NC = non-cacheable 普通内存），DCache 不能替它做，
//       必须整条搬到这里排队，由 Uncache 单元走总线单发单收。LoadQueueUncache
//       并排放 16 条本模块（entries_0..entries_15），每条装一笔在飞的 uncache load。
//
// 一条请求在本条目里走的四步（uncacheState）：
//   S_IDLE  收下请求后停在这里等发车条件：
//           · NC     —— 无条件可发（NC 访问没有副作用顺序要求）
//           · MMIO   —— 必须等自己成为 ROB 头（io_rob_pendingMMIOld 且
//                       req.uop.robIdx == 上一拍的 io_rob_pendingPtr）。
//                       MMIO 读有副作用，一旦发出去就不能被投机取消。
//   S_REQ   往 Uncache 总线发 req（addr/vaddr/mask/nc/memBackTypeMM/robIdx），
//           握手成功进 S_RESP。
//   S_RESP  等数据回来（io_uncache_resp）。数据、denied、corrupt 落寄存器。
//   S_WAIT  往 load 写回口送结果：NC 走 io_ncOut，MMIO 走 io_mmioOut +
//           io_mmioRawData。对方 ready 即完成，回 S_IDLE。
//
// 另一条与四步状态并行的握手：**slaveId**。Uncache 单元收下请求后会广播一个
// idResp{mid, sid}：mid 是"这笔是哪条 entry 的"，sid 是"我把它放在我的第几号槽"。
// 每条 entry 只认 mid == 自己的编号（ENTRY_ID，这就是家族 16 个变体唯一的差别），
// 认领时把 sid 记进 slave_id 并把 slave_accept 置起，供父级查询。
//
// flush（本条目作废）在四个状态里含义不同，这是本模块最容易看漏的地方：
//   S_IDLE / S_REQ  收到指向本条目的 redirect 立刻作废（还没发车，可以直接丢）；
//   S_RESP          **不能立刻丢** —— 请求已经在总线上，必须等 resp 回来才认账，
//                   所以 need_flush 先被 need_flush_q 记住，等 resp 那一拍才 flush；
//   S_WAIT          写回完成（writeback）或被 redirect 打中，都回 S_IDLE。
//
// 判据是 golden RTL（G1-canonical/golden-rtl/UncacheEntry*.sv），Chisel
// （XiangShan src/main/scala/xiangshan/mem/lsqueue/LoadQueueUncache.scala）只用来
// 解释"为什么"。几处"照抄 golden、不许抹平"的地方就地注明：
//
//   · req_uop_flushPipe / req_uop_replayInst 是两个**没有输入端口**的 payload 位。
//     父级对这两位给的是常数 0，firtool 于是把锁存写成 `q <= ~enq & q` ——
//     一个只会衰减到 0、再也起不来的寄存器，而它俩照样接到 mmioOut / ncOut 的
//     flushPipe / replayInst 输出上。**这两个寄存器必须原样保留**：FM 把寄存器当
//     自由变量、不做可达性分析，少一份就是 golden-only 死位，连双射都没有。
//
//   · pending_ptr_{flag,value}_q 的写使能是"新值与旧值不等才写"——
//     写同一个值和不写完全等价，所以这道使能在功能上是恒等的冗余。照抄。
//
//   · io_mmioOut / io_ncOut / io_exception 三处的 exceptionVec 都**不是**直接透传
//     req_uop_exceptionVec：第 5 位（loadAccessFault）被 denied 覆盖、第 19 位
//     （hardwareError）被 `corrupt & ~denied` 覆盖。对应地 golden 的输入端口表里
//     根本没有 io_req_bits_uop_exceptionVec_5 / _19（父级恒 0，被 firtool 消掉），
//     所以这两位也没有 req_uop_exceptionVec_5 / _19 寄存器。
//
//   · denied / corrupt 只在"收下新请求"那一拍清零（`~enq & q`），flush 不清。
//
// 家族 16 个变体（实测，见 verif/ut/UncacheEntry/gen.py 的 check_family()）：
//   除模块名外**逐字节只差一个常数** 7'hN（N = 0..F = 后缀 = 父级 entries_N 的槽号），
//   即本核的 ENTRY_ID 参数。没有一个变体有结构差异，故 16/16 全部由本核覆盖。
// =============================================================================
'''


def emit_core():
    L = []
    A = L.append
    A(CORE_HEADER.rstrip('\n'))
    A('')
    A('module xs_UncacheEntry_core #(')
    A("  // 本条目在 LoadQueueUncache 里的槽号；只用在一处：认领 Uncache 的 idResp。")
    A("  parameter logic [6:0] ENTRY_ID = 7'd0")
    A(') (')
    # 端口表（与 golden 逐位同名同序）
    A('  // BEGIN GENERATED(core-ports)  —— 端口表逐位抄自 G1 golden UncacheEntry.sv')
    for i, (d, w, n) in enumerate(PORTS):
        comma = '' if i == len(PORTS) - 1 else ','
        A(f'  {d:<6} {w:<9} {n}{comma}')
    A('  // END GENERATED')
    A(');')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 状态定义（uncacheState 的四步）')
    A('  // ---------------------------------------------------------------------------')
    A('  typedef enum logic [1:0] {')
    A("    S_IDLE = 2'd0,  // 已收下请求（或空闲），等发车条件")
    A("    S_REQ  = 2'd1,  // 等 Uncache 总线收走 req")
    A("    S_RESP = 2'd2,  // 等 Uncache 回数据")
    A("    S_WAIT = 2'd3   // 等 load 写回口收走结果")
    A('  } state_e;')
    A('')
    A('  state_e state;')
    A('  state_e next_state;')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 被锁存的请求（payload）')
    A('  //')
    A('  // 这一整段只做一件事：收下一条 uncache load 的**整个 bundle**，原样存住，')
    A('  // 到写回时再原样吐出去。190 个字段逐个列出是 golden 的展平形状，照抄。')
    A('  // 寄存器名沿用 golden 的 req_<字段>（本身就是语义名），便于逐个对照。')
    A('  // ★这一段整段不带复位★ —— golden 的复位域里只有下面「控制寄存器」那几个。')
    A('  // ---------------------------------------------------------------------------')
    A('  logic req_valid;   // 本条目当前装着一条有效请求（带复位）')
    A('')
    A('  // BEGIN GENERATED(payload-decl)')
    for f in REQ_FIELDS:
        w = port_width('io_req_bits_' + f)
        A(f'  logic {w:<9} req_{f};')
    A('  // END GENERATED')
    A('')
    A('  // 两个没有输入端口的 payload 位：父级恒 0，展开成"只会衰减到 0"的寄存器。')
    A('  // 一份都不许少（见文件头）。')
    A('  logic           req_uop_flushPipe;')
    A('  logic           req_uop_replayInst;')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 控制寄存器（golden 的复位域就是这一组 + req_valid，异步复位）')
    A('  // ---------------------------------------------------------------------------')
    A('  logic           slave_accept;         // 已认领 Uncache 的 idResp')
    A('  logic [3:0]     slave_id;             // 认领到的 sid（不复位）')
    A('  logic [63:0]    resp_data;            // Uncache 回来的数据（不复位）')
    A('  logic           denied;               // 总线拒绝 -> loadAccessFault')
    A('  logic           corrupt;              // 总线数据损坏 -> hardwareError')
    A('  logic           need_flush_q;         // S_RESP 期间被 redirect 打中，记账等 resp')
    A('  logic           pending_mmio_ld_q;    // io_rob_pendingMMIOld 打一拍')
    A('  logic           pending_ptr_flag_q;   // io_rob_pendingPtr 打一拍')
    A('  logic [7:0]     pending_ptr_value_q;')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 组合：握手、redirect 判定、发车条件')
    A('  // ---------------------------------------------------------------------------')
    A('  logic flush;              // 本拍本条目作废/退休（父级也要看，见 io_flush）')
    A('  logic need_flush;         // 本拍 redirect 打中本条目')
    A('  logic writeback;          // 本拍写回口成交')
    A('  logic slave_ack;          // 本拍 Uncache 的 idResp 是给本条目的')
    A('  logic can_send_req;       // 本拍允许发车（MMIO 要等 ROB 头）')
    A('  logic enq;                // 本拍收下一条新请求（payload 写使能）')
    A('  logic mmio_out_valid;')
    A('  logic nc_out_valid;')
    A('  logic uncache_req_valid;')
    A('')
    A('  // CircularQueuePtr：{flag, value}。needFlush 与"是不是 ROB 头"都按它比。')
    A('  wire [8:0] req_rob_idx      = {req_uop_robIdx_flag, req_uop_robIdx_value};')
    A('  wire [8:0] redirect_rob_idx = {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value};')
    A('  wire [8:0] rob_pending_ptr  = {pending_ptr_flag_q, pending_ptr_value_q};')
    A('')
    A('  // robIdx.needFlush(redirect)：')
    A('  //   level=1（精确 redirect，只冲掉这一条自己）时比"完全相等"；')
    A('  //   否则比"是不是排在 redirect 之后"——环形指针的 isAfter 展开成')
    A('  //   flag 异或 flag 再异或 (value > value)。')
    A('  //   ★ `>` 的优先级高于 `^`，golden 就是这么写的，别加括号改语义 ★')
    A('  assign need_flush = req_valid & io_redirect_valid')
    A('                    & ((io_redirect_bits_level & (req_rob_idx == redirect_rob_idx))')
    A('                       | (req_uop_robIdx_flag ^ io_redirect_bits_robIdx_flag')
    A('                          ^ (req_uop_robIdx_value > io_redirect_bits_robIdx_value)));')
    A('')
    A('  assign slave_ack = req_valid & io_uncache_idResp_valid')
    A('                   & (io_uncache_idResp_bits_mid == ENTRY_ID);')
    A('')
    A('  assign uncache_req_valid = (state == S_REQ)  & ~need_flush;')
    A('  assign nc_out_valid      = (state == S_WAIT) & ~need_flush &  req_nc;')
    A('  assign mmio_out_valid    = (state == S_WAIT) & ~need_flush & ~req_nc;')
    A('  assign writeback = req_nc ? (io_ncOut_ready   & nc_out_valid)')
    A('                            : (io_mmioOut_ready & mmio_out_valid);')
    A('')
    A('  // MMIO 读有副作用，必须等它成为 ROB 头才发；NC 无条件可发。')
    A('  assign can_send_req = req_valid & ~need_flush')
    A('                      & (req_nc | (pending_mmio_ld_q & (req_rob_idx == rob_pending_ptr)));')
    A('')
    A('  // flush 在四个状态里含义不同（见文件头）。')
    A('  always_comb begin')
    A('    case (state)')
    A('      S_RESP : flush = io_uncache_resp_valid & (need_flush | need_flush_q);')
    A('      S_WAIT : flush = need_flush | writeback;')
    A('      default: flush = need_flush;   // S_IDLE / S_REQ：还没发车，直接丢')
    A('    endcase')
    A('  end')
    A('')
    A('  // 收请求：flush 优先于 io_req_valid（golden 的 when(flush) 在最前面）。')
    A('  assign enq = ~flush & io_req_valid;')
    A('')
    A('  always_comb begin')
    A('    next_state = state;')
    A('    case (state)')
    A('      S_IDLE : if (need_flush)      next_state = S_IDLE;')
    A('               else if (can_send_req) next_state = S_REQ;')
    A('      S_REQ  : if (need_flush)      next_state = S_IDLE;')
    A('               else if (io_uncache_req_ready & uncache_req_valid) next_state = S_RESP;')
    A('      S_RESP : if (io_uncache_resp_valid)')
    A('                 next_state = (need_flush | need_flush_q) ? S_IDLE : S_WAIT;')
    A('      S_WAIT : if (need_flush | writeback) next_state = S_IDLE;')
    A('      default: ;')
    A('    endcase')
    A('  end')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 时序：控制寄存器（异步复位域 —— golden 只有这几个带复位）')
    A('  // ---------------------------------------------------------------------------')
    A('  always_ff @(posedge clock or posedge reset) begin')
    A('    if (reset) begin')
    A("      req_valid           <= 1'b0;")
    A("      slave_accept        <= 1'b0;")
    A('      state               <= S_IDLE;')
    A("      denied              <= 1'b0;")
    A("      corrupt             <= 1'b0;")
    A("      need_flush_q        <= 1'b0;")
    A("      pending_mmio_ld_q   <= 1'b0;")
    A("      pending_ptr_flag_q  <= 1'b0;")
    A("      pending_ptr_value_q <= 8'h0;")
    A('    end')
    A('    else begin')
    A('      // 优先级：flush 丢弃 > 收新请求 > 认领 idResp（只动 slave_*） > 写回完成。')
    A('      req_valid    <= ~flush & (io_req_valid | (slave_ack | ~writeback) & req_valid);')
    A('      slave_accept <= ~(flush | io_req_valid) & (slave_ack | ~writeback & slave_accept);')
    A('      state        <= next_state;')
    A('')
    A('      // denied / corrupt：resp 那一拍取总线的值；否则只在"收下新请求"时清零。')
    A('      // ★flush 不清它俩★（golden 如此）。')
    A('      if (io_uncache_resp_valid) begin')
    A('        denied  <= io_uncache_resp_bits_denied;')
    A('        corrupt <= io_uncache_resp_bits_corrupt;')
    A('      end')
    A('      else begin')
    A('        denied  <= ~enq & denied;')
    A('        corrupt <= ~enq & corrupt;')
    A('      end')
    A('')
    A('      need_flush_q      <= ~flush & (need_flush | need_flush_q);')
    A('      pending_mmio_ld_q <= io_rob_pendingMMIOld;')
    A('      // 写使能是"新值与旧值不等"——功能上恒等于无条件打拍，照抄 golden。')
    A('      if ({io_rob_pendingPtr_flag, io_rob_pendingPtr_value} != rob_pending_ptr) begin')
    A('        pending_ptr_flag_q  <= io_rob_pendingPtr_flag;')
    A('        pending_ptr_value_q <= io_rob_pendingPtr_value;')
    A('      end')
    A('    end')
    A('  end')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 时序：payload / slave_id / resp_data（**无复位**域）')
    A('  // ---------------------------------------------------------------------------')
    A('  always_ff @(posedge clock) begin')
    A('    if (enq) begin')
    A('      // BEGIN GENERATED(payload-latch)')
    for f in REQ_FIELDS:
        A(f'      req_{f} <= io_req_bits_{f};')
    A('      // END GENERATED')
    A('    end')
    A('')
    A('    // 这两位没有输入端口（父级恒 0）：写进来就是 0，之后再也起不来。照抄。')
    A('    req_uop_flushPipe  <= ~enq & req_uop_flushPipe;')
    A('    req_uop_replayInst <= ~enq & req_uop_replayInst;')
    A('')
    A('    // 认领 idResp 记下 sid。收新请求的那一拍不认领（golden 的 elsewhen 次序）。')
    A('    if (~(flush | io_req_valid) & slave_ack)')
    A('      slave_id <= io_uncache_idResp_bits_sid;')
    A('')
    A('    if (io_uncache_resp_valid)')
    A('      resp_data <= io_uncache_resp_bits_data;')
    A('  end')
    A('')
    A('  // ---------------------------------------------------------------------------')
    A('  // 输出：mmioOut / ncOut / mmioRawData / uncache.req / exception')
    A('  //')
    A('  // 除下面这几根有真逻辑外，mmioOut / ncOut / exception 的 uop 字段全是把锁存的')
    A('  // req_* 原样吐出去（exceptionVec 第 5 / 19 位除外，见文件头）。')
    A('  // 整段由 gen.py 从 golden 的 404 条 assign 机械翻译（只换内部 wire 名），')
    A('  // 保证 401 个输出逐位对齐。')
    A('  // ---------------------------------------------------------------------------')
    A('  // BEGIN GENERATED(outputs)')
    seen = set()
    for lhs, rhs in golden_assigns():
        if lhs in ('flush', 'io_mmioOut_valid_0', 'io_ncOut_valid_0',
                   'io_uncache_req_valid_0'):
            continue      # 这三根是核内部 wire，上面已经 assign 过
        seen.add(lhs)
        A(f'  assign {lhs} = {map_rhs(rhs)};')
    A('  // END GENERATED')
    A('')
    A('endmodule')
    # 自检：401 个输出一个不少
    outs = [n for d, w, n in PORTS if d == 'output']
    missing = [o for o in outs if o not in seen]
    assert not missing, f'输出未驱动: {missing[:5]}'
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# 薄 wrapper
# ---------------------------------------------------------------------------
def emit_wrapper(mod):
    eid = ENTRY_ID[mod]
    L = []
    A = L.append
    A('// ' + '=' * 75)
    A(f'// {mod} —— LoadQueueUncache 第 {eid} 号 uncache(MMIO/NC) load 条目')
    A(f'//            （UncacheEntry 家族 16 个变体之一，薄 wrapper）')
    A('//')
    A(f'// 本变体参数与规模：ENTRY_ID = {eid}（= 父级 LoadQueueUncache 的 entries_{eid}）')
    A(f'//   golden {mod}.sv = 1852 行 / 611 端口（16 个变体一律相同）')
    A('//')
    A('// 本变体与家族其它 15 个的差别**只有一个常数**：认领 Uncache 的 idResp 时比的')
    A(f"//   io_uncache_idResp_bits_mid == 7'h{eid:X}")
    A('// 除此之外 golden 逐字节相同（端口表、寄存器表、复位域、404 条 assign 全一致，')
    A('// 由 verif/ut/UncacheEntry/gen.py 的 check_family() 每次生成时实测复核）。')
    A('//')
    A('// 逻辑全部在参数化核 xs_UncacheEntry_core（同目录 xs_UncacheEntry_core.sv）里；')
    A('// 本文件只做端口表与例化，端口逐位抄自 G1 golden 同名模块。')
    A('// 自动生成：verif/ut/UncacheEntry/gen.py —— 勿手改')
    A('// ' + '=' * 75)
    A('')
    A('// BEGIN GENERATED(uncentry-wrapper)')
    A(f'module {mod}(')
    for i, (d, w, n) in enumerate(PORTS):
        comma = '' if i == len(PORTS) - 1 else ','
        A(f'  {d:<6} {w:<9} {n}{comma}')
    A(');')
    A('')
    A(f"  xs_UncacheEntry_core #(.ENTRY_ID(7'h{eid:X})) u_core (")
    for i, (d, w, n) in enumerate(PORTS):
        comma = '' if i == len(PORTS) - 1 else ','
        A(f'    .{n:<52}({n}){comma}')
    A('  );')
    A('')
    A('endmodule')
    A('// END GENERATED')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# testbench
# ---------------------------------------------------------------------------
# 这些输入由 tb 的定向激励驱动，不进"全随机"批；其余 io_req_bits_* 等全部随机。
DIRECTED_IN = {
    'clock', 'reset',
    'io_req_valid', 'io_redirect_valid', 'io_redirect_bits_level',
    'io_redirect_bits_robIdx_flag', 'io_redirect_bits_robIdx_value',
    'io_req_bits_uop_robIdx_flag', 'io_req_bits_uop_robIdx_value',
    'io_rob_pendingMMIOld', 'io_rob_pendingPtr_flag', 'io_rob_pendingPtr_value',
    'io_req_bits_nc', 'io_req_bits_mmio',
    'io_mmioOut_ready', 'io_ncOut_ready',
    'io_uncache_req_ready',
    'io_uncache_idResp_valid', 'io_uncache_idResp_bits_mid',
    'io_uncache_resp_valid', 'io_uncache_resp_bits_denied',
    'io_uncache_resp_bits_corrupt', 'io_uncache_idResp_bits_sid',
}


def rnd_expr(w):
    if w <= 32:
        return f"{w}'($urandom())"
    parts = ', '.join(['$urandom()'] * ((w + 31) // 32))
    return f"{w}'({{{parts}}})"


def emit_tb():
    ins = [(w, n) for d, w, n in PORTS if d == 'input']
    outs = [(w, n) for d, w, n in PORTS if d == 'output']
    # 输出打包成一根向量：每拍每变体只比一次，失配时才逐端口扫描定位。
    off, layout = 0, []
    for w, n in outs:
        b = width_bits(w)
        layout.append((n, off, b))
        off += b
    NOW = off

    L = []
    A = L.append
    A('// ' + '=' * 75)
    A('// UncacheEntry 家族 UT：16 个变体各一对 DUT（golden <M> 对重写 <M>_xs），')
    A('// 全部 32 个实例共享**同一套**激励与时钟/复位，逐拍比对每个变体自己的')
    A(f'// {len(outs)} 个输出端口（打包成 {NOW} 位向量，见「比对」段）。')
    A('//')
    A('// ★为什么 16 对共享一套激励★')
    A('// 16 个变体逐字节只差一个常数：认领 Uncache idResp 时比的 mid 值（0..15）。')
    A('// 同一套激励喂给 16 对，io_uncache_idResp_bits_mid 每拍取 0..17 的随机值 ——')
    A('// 于是每一拍恰好有 0 或 1 个变体认领。这直接把"每个薄 wrapper 有没有把对的')
    A('// ENTRY_ID 传进核"变成可观测的：传错了就有变体在该认领时不认领。')
    A('// 单独给每对造激励反而测不到这件事。')
    A('//')
    A('// ★激励为什么不是「每个输入独立均匀随机」★')
    A('// 本模块的判别力全在几个"要撞上才看得见"的点：')
    A('//   · MMIO 发车条件 = pendingMMIOld 且 req.robIdx == 上一拍的 pendingPtr；')
    A('//     robIdx 是 9 位，独立均匀随机的话 200k 拍也撞不上几次 ⇒ MMIO 根本发不出去。')
    A('//     所以 robIdx / pendingPtr / redirect.robIdx 全部从**同一个 8 元小池子**')
    A('//     里抽（flag 1 位 × value 0..3），撞车是常态。')
    A('//   · S_RESP 期间被 redirect 打中 -> need_flush_q 记账 -> resp 那一拍才 flush。')
    A('//     要求 redirect 落在 S_RESP 且该拍 resp 不来。redirect 概率给到 12%，')
    A('//     resp_valid 给 35%，两者独立 ⇒ 这条路径每千拍都会走到（见 COVERAGE）。')
    A('//   · 收新请求压过在飞请求（golden 的 XSError 条件）：io_req_valid 给 35%。')
    A('//')
    A('// ★暖机（本模块必须有）★')
    A('// golden 一条 entry 共 203 个寄存器 / 1670 位，其中**只有 9 个寄存器 / 17 位在')
    A('// 复位域**（req_valid 1 / slaveAccept 1 / uncacheState 2 / denied 1 / corrupt 1 /')
    A('//  needFlushReg 1 / pendingld_last_REG 1 / pendingPtr_next_r_flag 1 +')
    A('//  pendingPtr_next_r_value 8）—— 另外 1653 位一个都不复位（payload 190 个字段、')
    A('// slaveId、uncacheData、flushPipe、replayInst）。这三个数由')
    A('// reset_domain_check.py 从 golden 现场数出来并打印，不是抄来的。')
    A('// +vcs+initreg 给 golden 与重写两个实例**各掷各的随机值**，不暖机第一拍就会')
    A('// 因初值不同而报错。暖机 = 复位撤销后依次：')
    A('//   1 拍 io_req_valid=1（写满 190 个 payload 字段 + 把 flushPipe/replayInst 压 0）')
    A('//   16 拍 idResp_valid=1 且 mid=0..15（让每个变体各认领一次，写死 slaveId）')
    A('//   1 拍 uncache_resp_valid=1（写死 uncacheData）')
    A('// 之后才打开比较。')
    A('// ★暖机之后必须复核变异仍能被抓到★ —— 见 mutants.sh，每个变异体的 errors 数')
    A('// 都记在那里。')
    A('//')
    A('// ★复位域怎么把关★')
    A('// 暖机之后两轮 initreg 必然都绿（不复位的寄存器都已写成确定值），所以')
    A('// "复位域对不对"只能靠**中途反复打异步复位**来测：复位后 req_valid / state /')
    A('// denied / corrupt / needFlushReg 等必须归 0，而 payload / slaveId / uncacheData')
    A('// 必须**保持不变** —— 任何一侧多复位或少复位都会当场失配。')
    A('//')
    A('// ★覆盖证据★')
    A('// tb 统计若干"有判别力的事件"计数（见 COVERAGE 段），任何一项为 0 都说明对应')
    A('// 机制根本没被激励到，这一轮 errors=0 不作数。')
    A('//')
    A('// 自动生成：verif/ut/UncacheEntry/gen.py —— 勿手改')
    A('// ' + '=' * 75)
    A('`timescale 1ns/1ps')
    A('')
    A('module tb;')
    A('')
    A(f'  localparam int NOUT = {len(outs)};   // 每个变体的输出端口数')
    A(f'  localparam int NOW  = {NOW};   // 打包后的总位宽')
    A('')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit   clk = 0;')
    A('  logic rst;')
    A("  logic cmp_en = 1'b0;   // 暖机结束前不比较（见文件头）")
    A('  int      errors = 0;')
    A('  longint  checks = 0;   // 变体-拍 数（每次比一整根 NOW 位向量）')
    A('  int unsigned warm_phase = 1;   // 0=正常随机 1=写 payload 2=写 slaveId 3=写 uncacheData')
    A('  int unsigned warm_mid = 0;')
    A('  localparam int RESET_PULSES = 20;')
    A('  longint cov_reset_pulses = 0;')
    A('')
    A('  always #5 clk = ~clk;')
    A('')
    A('  // --------------------------------------------------------------------------')
    A('  // 端口位图：失配时用它把出错的位翻译成端口名')
    A('  // --------------------------------------------------------------------------')
    A('  string port_of_bit [NOW];')
    A('  initial begin')
    for n, o, b in layout:
        A(f'    for (int i = 0; i < {b}; i++) port_of_bit[{o} + i] = "{n}";')
    A('  end')
    A('')
    A('  // --------------------------------------------------------------------------')
    A('  // 激励信号（一套，喂给全部 32 个实例）')
    A('  // --------------------------------------------------------------------------')
    for w, n in ins:
        if n in ('clock', 'reset'):
            continue
        A(f'  logic {w:<9} {n};')
    A('')
    A('  // --------------------------------------------------------------------------')
    A('  // 覆盖计数（每项必须 > 0）')
    A('  // --------------------------------------------------------------------------')
    for c in COVS[1:]:
        A(f'  longint {c[0]} = 0;')
    A('')
    A('  // --------------------------------------------------------------------------')
    A('  // 激励：negedge 驱动，避开与 DUT 采样沿的竞争')
    A('  // --------------------------------------------------------------------------')
    A('  always @(negedge clk) begin')
    A('    if (warm_phase != 0) drive_warm();')
    A('    else                 drive_random();')
    A('  end')
    A('')
    A('  // 暖机：定向写那些不复位的寄存器（见文件头）')
    A('  task automatic drive_warm();')
    A("    io_req_valid                 <= (warm_phase == 1);")
    A("    io_redirect_valid            <= 1'b0;")
    A("    io_redirect_bits_level       <= 1'b0;")
    A("    io_redirect_bits_robIdx_flag <= 1'b0;")
    A("    io_redirect_bits_robIdx_value<= 8'h0;")
    A("    io_req_bits_uop_robIdx_flag  <= 1'b0;")
    A("    io_req_bits_uop_robIdx_value <= 8'h0;")
    A("    io_rob_pendingMMIOld         <= 1'b0;")
    A("    io_rob_pendingPtr_flag       <= 1'b0;")
    A("    io_rob_pendingPtr_value      <= 8'h0;")
    A("    io_req_bits_nc               <= 1'b0;")
    A("    io_req_bits_mmio             <= 1'b1;")
    A("    io_mmioOut_ready             <= 1'b0;")
    A("    io_ncOut_ready               <= 1'b0;")
    A("    io_uncache_req_ready         <= 1'b0;")
    A("    io_uncache_idResp_valid      <= (warm_phase == 2);")
    A("    io_uncache_idResp_bits_mid   <= 7'(warm_mid);")
    A("    io_uncache_idResp_bits_sid   <= 4'($urandom());")
    A("    io_uncache_resp_valid        <= (warm_phase == 3);")
    A("    io_uncache_resp_bits_denied  <= 1'b0;")
    A("    io_uncache_resp_bits_corrupt <= 1'b0;")
    A('    // payload 其余字段随机即可（两侧同一套，写进去就一致）')
    for w, n in ins:
        if n in DIRECTED_IN:
            continue
        A(f'    {n} <= {rnd_expr(width_bits(w))};')
    A('  endtask')
    A('')
    A('  // 小池子：robIdx / pendingPtr / redirect.robIdx 都从这 8 个值里抽，')
    A('  // 否则 9 位指针相等这件事在 200k 拍里几乎不会发生（见文件头）。')
    A('  task automatic drive_random();')
    A("    io_req_valid            <= ($urandom_range(0, 99) < 35);")
    A("    io_redirect_valid       <= ($urandom_range(0, 99) < 12);")
    A("    io_redirect_bits_level  <= ($urandom_range(0, 99) < 50);")
    A("    io_redirect_bits_robIdx_flag  <= 1'($urandom());")
    A("    io_redirect_bits_robIdx_value <= 8'($urandom_range(0, 3));")
    A("    io_req_bits_uop_robIdx_flag   <= 1'($urandom());")
    A("    io_req_bits_uop_robIdx_value  <= 8'($urandom_range(0, 3));")
    A("    io_rob_pendingMMIOld    <= ($urandom_range(0, 99) < 60);")
    A("    io_rob_pendingPtr_flag  <= 1'($urandom());")
    A("    io_rob_pendingPtr_value <= 8'($urandom_range(0, 3));")
    A('    // nc / mmio 两条写回路各占一半；mmio 还要过 ROB 头这道闸。')
    A("    io_req_bits_nc          <= ($urandom_range(0, 99) < 50);")
    A("    io_req_bits_mmio        <= ($urandom_range(0, 99) < 70);")
    A("    io_mmioOut_ready        <= ($urandom_range(0, 99) < 55);")
    A("    io_ncOut_ready          <= ($urandom_range(0, 99) < 55);")
    A("    io_uncache_req_ready    <= ($urandom_range(0, 99) < 55);")
    A("    io_uncache_idResp_valid <= ($urandom_range(0, 99) < 40);")
    A('    // 0..17：0..15 各打中一个变体，16/17 是"谁都不认领"的对照。')
    A("    io_uncache_idResp_bits_mid  <= 7'($urandom_range(0, 17));")
    A("    io_uncache_idResp_bits_sid  <= 4'($urandom());")
    A("    io_uncache_resp_valid   <= ($urandom_range(0, 99) < 35);")
    A("    io_uncache_resp_bits_denied  <= ($urandom_range(0, 99) < 25);")
    A("    io_uncache_resp_bits_corrupt <= ($urandom_range(0, 99) < 25);")
    A('    // 其余 payload 字段全随机（它们只是被原样存下、原样吐出）')
    for w, n in ins:
        if n in DIRECTED_IN:
            continue
        A(f'    {n} <= {rnd_expr(width_bits(w))};')
    A('  endtask')
    A('')
    for mod in VARIANTS:
        p = pfx(mod)
        A('  // ' + '-' * 73)
        A(f'  // {mod}（ENTRY_ID = {ENTRY_ID[mod]}）')
        A('  // ' + '-' * 73)
        for side in ('g', 'x'):
            for w, n in outs:
                A(f'  wire {w:<9} {side}_{p}_{n};')
        for side, inst in (('g', mod), ('x', mod + '_xs')):
            A(f'  {inst} u_{side}_{p} (')
            conns = []
            # ★clock/reset 必须映到 tb 的 clk/rst★：第一次生成时忘了这层映射，
            # VCS 只给了两条 Warning-[IWNF]「implicit wire has no fanin」就过了 ——
            # 32 个 DUT 一个都没有时钟，跑起来照样 errors=0。隐式线网这个坑要盯死。
            tbname = {'clock': 'clk', 'reset': 'rst'}
            for d, w, n in PORTS:
                if d == 'input':
                    conns.append(f'    .{n:<52}({tbname.get(n, n)})')
                else:
                    conns.append(f'    .{n:<52}({side}_{p}_{n})')
            A(',\n'.join(conns))
            A('  );')
        for side in ('g', 'x'):
            A(f'  wire [NOW-1:0] {side}_{p}_all = {{')
            body = [f'    {side}_{p}_{n}' for n, _, _ in reversed(layout)]
            A(',\n'.join(body))
            A('  };')
        A('')
    A('  // --------------------------------------------------------------------------')
    A('  // 比对：每拍每变体比一根打包向量；只有失配才逐位扫描定位到端口')
    A('  // --------------------------------------------------------------------------')
    A('  task automatic report_diff(input string mod, input logic [NOW-1:0] g,')
    A('                             input logic [NOW-1:0] x);')
    A('    string last = "";')
    A('    for (int b = 0; b < NOW; b++)')
    A('      if (g[b] !== x[b] && port_of_bit[b] != last) begin')
    A('        last = port_of_bit[b];')
    A('        if (errors < 40)')
    A('          $display("MISMATCH t=%0t %s.%s (bit %0d) golden=%b xs=%b",')
    A('                   $time, mod, port_of_bit[b], b, g[b], x[b]);')
    A('      end')
    A('  endtask')
    A('')
    A('  always @(posedge clk) begin')
    A('    if (cmp_en && !rst) begin')
    for mod in VARIANTS:
        p = pfx(mod)
        A('      checks++;')
        A(f'      if (g_{p}_all !== x_{p}_all) begin')
        A('        errors++;')
        A(f'        report_diff("{mod}", g_{p}_all, x_{p}_all);')
        A('      end')
    A('    end')
    A('  end')
    A('')
    A('  // 覆盖统计用 golden 侧条目的层次引用（只用于计数，不参与判决）。')
    A('  always @(posedge clk) if (!rst && cmp_en) begin')
    for expr, cnt in COV_SAMPLES:
        A(f'    if ({expr}) {cnt}++;')
    A('  end')
    A('')
    A('  // --------------------------------------------------------------------------')
    A('  // 复位 / 暖机 / 收尾')
    A('  // --------------------------------------------------------------------------')
    A('  initial begin')
    A('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    A("    rst = 1'b1;")
    A('    warm_phase = 1;')
    A('    repeat (4) @(posedge clk);')
    A("    @(negedge clk) rst = 1'b0;")
    A('    // 1) 收请求：写满 190 个 payload 字段，并把 flushPipe/replayInst 压 0')
    A('    repeat (2) @(posedge clk);')
    A('    // 2) 16 拍 idResp：mid 依次取 0..15，让每个变体各认领一次写死 slaveId')
    A('    warm_phase = 2;')
    A('    for (int k = 0; k < 16; k++) begin')
    A('      warm_mid = k;')
    A('      @(posedge clk);')
    A('    end')
    A('    // 3) 一拍 resp：写死 uncacheData')
    A('    warm_phase = 3;')
    A('    repeat (2) @(posedge clk);')
    A('    warm_phase = 0;')
    A('    repeat (2) @(posedge clk);')
    A("    @(negedge clk) cmp_en = 1'b1;")
    A('    // ★中途反复打异步复位★：复位域的唯一把关手段（见文件头）。')
    A('    for (int k = 0; k < RESET_PULSES; k++) begin')
    A('      repeat (NCYCLES / RESET_PULSES) @(posedge clk);')
    A("      @(negedge clk) begin rst = 1'b1; cmp_en = 1'b0; end")
    A('      repeat (1 + (k % 3)) @(posedge clk);')
    A("      @(negedge clk) rst = 1'b0;")
    A('      repeat (2) @(posedge clk);')
    A("      @(negedge clk) cmp_en = 1'b1;")
    A('      cov_reset_pulses++;')
    A('    end')
    A('')
    A('    $display("--- COVERAGE (每项必须 > 0，否则该机制没被激励到) ---");')
    for name, desc in COVS:
        A(f'    $display("  %-46s: %0d", "{desc}", {name});')
    A('    $display("checks=%0d errors=%0d", checks, errors);')
    cond = ' &&\n        '.join(f'{n} > 0' for n, _ in COVS)
    A('    if (errors == 0 &&')
    A(f'        {cond})')
    A('      $display("TEST PASSED");')
    A('    else')
    A('      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);')
    A('    $finish;')
    A('  end')
    A('')
    A('endmodule')
    return '\n'.join(L) + '\n'


def pfx(mod):
    return 'e0' if mod == 'UncacheEntry' else 'e' + mod.split('_')[1]


# 覆盖点：(计数器名, 说明)
COVS = [
    ('cov_reset_pulses',   '中途异步复位次数（复位域的唯一把关手段）'),
    ('cov_enq_on_busy',    '收新请求压过在飞请求（golden XSError 条件）'),
    ('cov_state_req',      '走到 S_REQ'),
    ('cov_state_resp',     '走到 S_RESP'),
    ('cov_state_wait',     '走到 S_WAIT'),
    ('cov_uncache_req_fire', 'Uncache req 握手成交'),
    ('cov_mmio_wb',        'MMIO 写回成交(io_mmioOut fire)'),
    ('cov_nc_wb',          'NC 写回成交(io_ncOut fire)'),
    ('cov_slave_ack_e0',   '0 号条目认领 idResp'),
    ('cov_slave_ack_e15',  '15 号条目认领 idResp'),
    ('cov_slave_miss',     'idResp 有效但 mid 谁都不认领'),
    ('cov_flush_idle',     'S_IDLE/S_REQ 期间被 redirect 直接丢弃'),
    ('cov_flush_deferred', 'S_RESP 期间记账 need_flush_q，等 resp 才 flush'),
    ('cov_flush_wait',     'S_WAIT 期间被 redirect 打中'),
    ('cov_redirect_level', 'redirect level=1（精确冲刷，比相等）'),
    ('cov_resp_denied',    'resp 带 denied'),
    ('cov_resp_corrupt',   'resp 带 corrupt 且未 denied'),
    ('cov_mmio_head_wait', 'MMIO 已就绪但还不是 ROB 头（发不了车）'),
    ('cov_mmio_head_hit',  'MMIO 等到 ROB 头，发车'),
    ('cov_mmioselect',     'io_mmioSelect 抬起'),
]

# (采样表达式, 计数器)。层次引用只用于计数。
G0 = 'u_g_e0'
G15 = 'u_g_e15'
COV_SAMPLES = [
    (f'!{G0}.flush && io_req_valid && {G0}.req_valid', 'cov_enq_on_busy'),
    (f"{G0}.uncacheState == 2'h1", 'cov_state_req'),
    (f"{G0}.uncacheState == 2'h2", 'cov_state_resp'),
    (f"{G0}.uncacheState == 2'h3", 'cov_state_wait'),
    (f'io_uncache_req_ready && g_e0_io_uncache_req_valid', 'cov_uncache_req_fire'),
    (f'io_mmioOut_ready && g_e0_io_mmioOut_valid', 'cov_mmio_wb'),
    (f'io_ncOut_ready && g_e0_io_ncOut_valid', 'cov_nc_wb'),
    (f'{G0}.slaveAck', 'cov_slave_ack_e0'),
    (f'{G15}.slaveAck', 'cov_slave_ack_e15'),
    (f"io_uncache_idResp_valid && io_uncache_idResp_bits_mid > 7'd15", 'cov_slave_miss'),
    (f"{G0}.needFlush && {G0}.uncacheState inside {{2'h0, 2'h1}}", 'cov_flush_idle'),
    (f"{G0}.needFlushReg && {G0}.uncacheState == 2'h2", 'cov_flush_deferred'),
    (f"{G0}.needFlush && {G0}.uncacheState == 2'h3", 'cov_flush_wait'),
    (f'io_redirect_valid && io_redirect_bits_level', 'cov_redirect_level'),
    (f'io_uncache_resp_valid && io_uncache_resp_bits_denied', 'cov_resp_denied'),
    (f'io_uncache_resp_valid && io_uncache_resp_bits_corrupt && '
     f'!io_uncache_resp_bits_denied', 'cov_resp_corrupt'),
    (f"{G0}.uncacheState == 2'h0 && {G0}.req_valid && !{G0}.req_nc && "
     f'!({G0}.pendingld_last_REG && '
     f'{{{G0}.req_uop_robIdx_flag, {G0}.req_uop_robIdx_value}} == '
     f'{{{G0}.pendingPtr_next_r_flag, {G0}.pendingPtr_next_r_value}})', 'cov_mmio_head_wait'),
    (f"{G0}.uncacheState == 2'h0 && {G0}.req_valid && !{G0}.req_nc && "
     f'{G0}.pendingld_last_REG && '
     f'{{{G0}.req_uop_robIdx_flag, {G0}.req_uop_robIdx_value}} == '
     f'{{{G0}.pendingPtr_next_r_flag, {G0}.pendingPtr_next_r_value}}', 'cov_mmio_head_hit'),
    ('g_e0_io_mmioSelect', 'cov_mmioselect'),
]


# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()

    errs = check_family()
    if errs:
        for e in errs:
            print('FAMILY-CHECK FAILED: ' + e, file=sys.stderr)
        return 1
    print(f'family-check: {len(VARIANTS)}/{len(VARIANTS)} 变体确认为纯参数变体'
          f'（唯一差异 = idResp.mid 常数 = ENTRY_ID）')

    init_tables()
    outs = [
        (OUT / 'xs_UncacheEntry_core.sv', emit_core()),
        (HERE / 'tb.sv', emit_tb()),
    ]
    for m in VARIANTS:
        outs.append((OUT / f'{m}.sv', emit_wrapper(m)))

    # 导航块由 gen_file_nav.py 在生成之后插进 >1500 行的文件里，所以 --check 必须
    # 先把它剥掉再比，否则「刚跑完 gen.py」这件事自己就会被判成 STALE。
    sys.path.insert(0, str(REPO / 'scripts'))
    import gen_file_nav

    def strip_nav_text(t):
        return '\n'.join(gen_file_nav.strip_nav(t.splitlines())) + '\n'

    changed = []
    for path, text in outs:
        if args.check:
            if not path.exists() or strip_nav_text(path.read_text()) != text:
                changed.append(path)
        else:
            if not path.exists() or strip_nav_text(path.read_text()) != text:
                path.write_text(text)
                changed.append(path)
    if args.check:
        if changed:
            for p in changed:
                print(f'STALE: {p}', file=sys.stderr)
            return 1
        print('gen.py --check: 全部产物与生成器一致')
        return 0
    print(f'写出 {len(changed)} / {len(outs)} 个文件')

    # 大文件导航（>1500 行必须带，见 CONVENTIONS.md E 类）。
    # ★必须自己按行数筛★：gen_file_nav.py 只有在**不给文件名**时才按 --min-lines
    # 自己挑；显式给了文件名它就无条件插。第一版把 18 个文件全传了进去，于是
    # 16 个 1250 行的薄 wrapper 各得到一个**空导航块**（只有标题、0 条目）——
    # 可读性审计的 E 类只管 >1500 行的文件，所以它一声不响，但"写着有导航、
    # 里面什么都没有"比没有导航更误导人。
    NAV_MIN_LINES = 1500
    nav = REPO / 'scripts' / 'gen_file_nav.py'
    big = [str(p) for p, text in outs
           if p.suffix == '.sv' and p.parent == OUT
           and text.count('\n') + 1 > NAV_MIN_LINES]
    if nav.exists() and big:
        subprocess.run([sys.executable, str(nav)] + big, check=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
