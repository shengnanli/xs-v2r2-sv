// Fence.sv —— 后端整数 ExuBlock 里的「栅栏功能单元」（Fence FU），单文件重写
//
// 对应 Chisel: xiangshan.backend.fu.Fence（class Fence extends FuncUnit）
// golden 对照: G1-canonical/golden-rtl/Fence.sv（kunminghu-v2 @b36a1a2a5）
//
// 【在后端的位置】Scheduler 把一条屏障类指令发射进来（io_in），本单元不算任何
// 数据结果，而是用一个 6 态状态机按顺序向外部部件发 flush 请求，全部做完后从
// io_out 写回 ROB（res.data 恒 0）。它是整个流水线里唯一能"命令外设排空"的 FU。
//
// 【管哪五类指令】fuOpType 的五个合法编码（另有 nofence 占位，共 6 个）：
//   fence      (0x10) 内存屏障，只要 store buffer 排空即完成，不发额外 flush
//   sfence.vma (0x11) 刷 TLB，id 字段送 ASID
//   fence.i    (0x12) 刷 icache（fencei 脉冲）
//   hfence.vvma(0x13) 刷 VS 级 TLB（hv=1），H 扩展，id 字段送 ASID
//   hfence.gvma(0x14) 刷 G 级 TLB（hg=1），H 扩展，id 字段送 **VMID**
//   nofence    (0x00) Svinval 扩展占位，走一遍状态机但什么都不刷
//
// 【核心机制】in.fire 时把这条指令整条锁存下来（单条目，in.ready 只在 idle 为 1，
// 所以同时最多在飞一条）→ s_wait 持续拉 sbuffer.flushSb 并等 sbIsEmpty →
// 按 op 分流到 s_tlb/s_icache/s_fence/s_nofence 停留一拍并发对应 flush →
// 下一拍无条件回 s_idle，回 idle 的那一拍之前（即处于"干活态"时）out.valid=1。
// 先排空 store buffer 再 flush 是语义要求：fence 要让先前的 store 对后续可见，
// TLB/icache 的失效也必须在写回落定之后做才不会把旧数据重新捞回来。
//
// 【G1 相对 G0 的改动】（G0 = 上一轮基线；实测 diff 只有三处，全部在下方注释处标 ★）
//  1. ★真逻辑修正★ sfence id 寄存器由 64 位收窄为 16 位，且 hfence.gvma 走
//     "VMID 只有 14 位、高 2 位补零"的特例（见 SFENCE_ID 一节）。
//  2. 端口扩容：perfDebugInfo 从 3 个字段（enqRs/select/issue）扩到 10 个，
//     并新增 debug_seqNum（seqNum/uopIdx）。这些全是**纯组合直通**，不打拍。
//  3. 其余（状态机、握手、sfence 其他字段）逐字未变；G0 已有 in_ready/out_ready，
//     并非本轮新增。
// =============================================================================
package fence_pkg;

  // ---------------------------------------------------------------------------
  // FenceOpType —— fuOpType 编码（端口 9 位，有效编码只用低 5 位）
  // 与 Scala object FenceOpType（xiangshan/package.scala）完全一致：
  //   fence  = 5'b10000  sfence = 5'b10001  fencei = 5'b10010
  //   hfence_v=5'b10011  hfence_g=5'b10100  nofence= 5'b00000
  // ---------------------------------------------------------------------------
  localparam int unsigned FUOPTYPE_W = 9;

  typedef enum logic [FUOPTYPE_W-1:0] {
    OP_NOFENCE  = 9'h00,
    OP_FENCE    = 9'h10,
    OP_SFENCE   = 9'h11,
    OP_FENCEI   = 9'h12,
    OP_HFENCE_V = 9'h13,
    OP_HFENCE_G = 9'h14
  } fence_op_e;

  // ---------------------------------------------------------------------------
  // 状态机状态 —— 与 Scala 的 Enum(6) 同序同义（编码必须逐值对齐 golden，
  // 因为 UT/FM 都按状态派生出的输出值比对）：
  //   s_idle   =0 初始态，可纳新请求；in.ready 仅此态为 1
  //   s_wait   =1 拉高 sbuffer.flushSb，等 store buffer 排空（sbIsEmpty）
  //   s_tlb    =2 发 sfence（刷 TLB），停留一拍
  //   s_icache =3 发 fencei（刷 icache），停留一拍
  //   s_fence  =4 普通 fence 的"什么都不做"态（拆两拍是为时序），停留一拍
  //   s_nofence=5 Svinval 占位态，停留一拍
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    S_IDLE    = 3'h0,
    S_WAIT    = 3'h1,
    S_TLB     = 3'h2,
    S_ICACHE  = 3'h3,
    S_FENCE   = 3'h4,
    S_NOFENCE = 3'h5
  } fence_state_e;

  // ---------------------------------------------------------------------------
  // sfence 请求里两个"标识符"字段的宽度，来自 Parameters.scala 的 coreParams：
  //   AsidLength = 16   sfence.vma / hfence.vvma 的 ASID
  //   VmidLength = 14   hfence.gvma 的 VMID（RISC-V H 扩展只定义 14 位）
  // 输出端口 io_fenceio_sfence_bits_id 宽 16 位，按较宽的 ASID 定宽。
  // ---------------------------------------------------------------------------
  localparam int unsigned ASID_LEN     = 16;
  localparam int unsigned VMID_LEN     = 14;
  localparam int unsigned SFENCE_ID_W  = ASID_LEN;

  // sfence 目标地址只用虚地址页的低 50 位（端口 io_..._addr 宽 50）。
  localparam int unsigned SFENCE_ADDR_W = 50;

  // 立即数只有低 10 位在本单元被读：imm[4:0] 判 sfence.rs1(=x0)、imm[9:5] 判 rs2(=x0)。
  // 高 54 位在 Fence 内从不被读（golden 把 64 位全存进 uop_data_imm，高位是
  // cone-dead 死寄存器），故锁存宽度收窄到实际读取范围。
  localparam int unsigned IMM_USED_W = 10;

  // ---------------------------------------------------------------------------
  // 入口 uop 中需要在 fire 拍锁存、供状态机与写回使用的字段。
  // （golden 把这些散成一堆 uop_ctrl_* / uop_data_imm 标量寄存器，这里聚合成一个
  //  struct：它就是"当前正在处理的这条 fence 指令"。）
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [FUOPTYPE_W-1:0]  fuOpType;     // 决定走哪条 flush 分支
    logic                   robIdx_flag;  // ROB 指针（写回定位）
    logic [7:0]             robIdx_value;
    logic [7:0]             pdest;        // 物理目的寄存器（fence 无结果，仍透传）
    logic                   flushPipe;    // 是否需要 flush 流水（送 sfence 与 out）
    logic [IMM_USED_W-1:0]  imm;          // 立即数低 10 位：sfence rs1/rs2 判定
  } fence_uop_t;

  // ---------------------------------------------------------------------------
  // 性能/调试时间戳包（XSBundle 的 PerfDebugInfo）与指令序号包（debug_seqNum）。
  // 本单元对它们不做任何运算，见核内 "调试信息直通" 一节。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic        eliminatedMove;          // 该 uop 是否被 move elimination 消掉
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } perf_debug_info_t;

  typedef struct packed {
    logic [55:0] seqNum;                  // 全局指令序号（difftest/波形定位用）
    logic [7:0]  uopIdx;                  // 同一条指令拆出的第几个 uop
  } debug_seq_num_t;

endpackage

// =============================================================================
// xs_Fence_core —— 栅栏单元可读核（真逻辑都在这里）
//
// 单条目、非流水：in.ready 只在 s_idle 为 1，所以任一时刻最多一条 fence 在飞，
// 不需要 buffer/队列，也就没有 back-pressure 逻辑 —— out.valid 拉高时下游必须
// 无条件接收（见文件末的 assert，与 Scala 同名断言对应）。
//
// 数据流：
//   in.fire ─► 锁存 uop / sfence 地址 / sfence id ─► S_WAIT 拉 flushSb 等排空
//            └─ sbIsEmpty ─► 按 op 进 S_TLB / S_ICACHE / S_FENCE / S_NOFENCE
//                            （停留一拍 + 发对应 flush + out.valid）─► S_IDLE
// =============================================================================
module xs_Fence_core
  import fence_pkg::*;
(
  input  logic             clock,
  input  logic             reset,        // 异步高有效，仅复位 state

  // ---- 入口（发射） ----
  output logic             in_ready,     // 仅 s_idle 接收
  input  logic             in_valid,
  input  fence_uop_t       in_uop,       // fuOpType/robIdx/pdest/flushPipe/imm
  input  logic [63:0]      in_src0,      // rs1 值：sfence 目标虚地址
  input  logic [63:0]      in_src1,      // rs2 值：sfence 的 ASID / VMID
  input  perf_debug_info_t in_perf,      // 调试时间戳（本单元只直通）
  input  debug_seq_num_t   in_seq_num,   // 指令序号（本单元只直通）

  // ---- 出口（写回 ROB，无数据结果） ----
  input  logic             out_ready,
  output logic             out_valid,
  output fence_uop_t       out_uop,      // 透传锁存的 robIdx/pdest/flushPipe
  output logic [63:0]      out_res_data, // 恒 0：fence 不产生结果
  output perf_debug_info_t out_perf,
  output debug_seq_num_t   out_seq_num,

  // ---- 对外 flush / sfence 接口 ----
  output logic             sbuffer_flushSb,   // s_wait：请求 store buffer 排空
  input  logic             sbuffer_sbIsEmpty, // store buffer 已空
  output logic             fencei,            // s_icache：flush icache 脉冲

  output logic             sfence_valid,      // s_tlb 且为 sfence/hfence 时拉高
  output logic             sfence_rs1,        // imm[4:0]==0 → rs1=x0（刷整地址空间）
  output logic             sfence_rs2,        // imm[9:5]==0 → rs2=x0（不限 asid/vmid）
  output logic [SFENCE_ADDR_W-1:0] sfence_addr, // 锁存的 src0 低 50 位（虚地址页）
  output logic [SFENCE_ID_W-1:0]   sfence_id,   // 锁存的 ASID 或补零后的 VMID
  output logic             sfence_flushPipe,
  output logic             sfence_hv,         // hfence.vvma
  output logic             sfence_hg          // hfence.gvma
);

  // ---------------------------------------------------------------------------
  // 入口握手
  // ---------------------------------------------------------------------------
  fence_state_e state;

  assign in_ready = (state == S_IDLE);   // 单条目：只在 idle 收新请求

  logic in_fire;
  assign in_fire = in_ready & in_valid;

  // 入口那条指令的操作码（还没锁存，用于下面 SFENCE_ID 的选择）
  fence_op_e in_func;
  assign in_func = fence_op_e'(in_uop.fuOpType);

  // ---------------------------------------------------------------------------
  // SFENCE_ID —— ★G1 真逻辑修正：hfence.gvma 的 VMID 只有 14 位★
  //
  // sfence 请求的 id 字段复用同一根 16 位线，但语义随指令而变：
  //   sfence.vma / hfence.vvma → 送 **ASID**，RISC-V 特权规范定义 16 位（AsidLength）
  //   hfence.gvma              → 送 **VMID**，H 扩展只定义 14 位（VmidLength）
  // 所以 hfence.gvma 必须只取 rs2 的低 14 位、高 2 位补零。G0 的做法是把 rs2 的
  // 低 16 位（甚至整 64 位）原样存下再截断，于是当软件在 rs2 的 bit[15:14] 留下
  // 非零垃圾时，TLB 侧的 VMID 比较会拿到寄生位、把不该失效的表项漏掉或多刷。
  // G1 在**锁存处**就按指令类型把 VMID 补零修掉了这个问题。
  //
  // 注意选择用的是"入口这拍的 fuOpType"（in_func），不是锁存后的 uop.fuOpType ——
  // 两者在 in_fire 那一拍同值，但写成入口侧才与 golden 的组合锥一致。
  // 对应 golden: io_fenceio_sfence_bits_id_r 的 always_ff 赋值
  // ---------------------------------------------------------------------------
  logic [SFENCE_ID_W-1:0] fence_asid;   // sfence.vma / hfence.vvma 用
  logic [SFENCE_ID_W-1:0] fence_vmid;   // hfence.gvma 用（高 2 位强制 0）
  logic [SFENCE_ID_W-1:0] fence_id_next;

  assign fence_asid    = in_src1[ASID_LEN-1:0];
  assign fence_vmid    = {{(ASID_LEN - VMID_LEN){1'b0}}, in_src1[VMID_LEN-1:0]};
  assign fence_id_next = (in_func == OP_HFENCE_G) ? fence_vmid : fence_asid;

  // ---------------------------------------------------------------------------
  // fire 拍锁存"当前处理的这条 fence"
  // 地址/立即数只锁存实际会被读的低位（addr 低 50 位、imm 低 10 位）。golden 存的
  // 是完整 64 位，其高位无任何扇出（cone-dead）；这里按读取范围定宽，读者一眼能
  // 看出"只有这些位有用"。无复位（与 golden 同：只有 state 有复位）。
  // ---------------------------------------------------------------------------
  fence_uop_t                   uop;
  logic [SFENCE_ADDR_W-1:0]     sfence_addr_r;
  logic [SFENCE_ID_W-1:0]       sfence_id_r;

  always_ff @(posedge clock) begin
    if (in_fire) begin
      uop           <= in_uop;
      sfence_addr_r <= in_src0[SFENCE_ADDR_W-1:0];
      sfence_id_r   <= fence_id_next;
    end
  end

  // 正在处理的这条指令的操作码（按 enum 名分流，比裸编码可读）
  fence_op_e func;
  assign func = fence_op_e'(uop.fuOpType);

  // ---------------------------------------------------------------------------
  // flush 分类判定：哪些 op 在排空后要去刷 TLB
  //   把 golden 里散落三处的 (op==sfence | op==hv | op==hg) 收敛成一个具名函数。
  // ---------------------------------------------------------------------------
  function automatic logic is_tlb_op(fence_op_e op);
    // sfence.vma / hfence.vvma / hfence.gvma 都走刷 TLB 分支
    return (op == OP_SFENCE) | (op == OP_HFENCE_V) | (op == OP_HFENCE_G);
  endfunction

  // ---------------------------------------------------------------------------
  // 状态机（与 Scala 的 when 链严格对应；Chisel 后写的 when 优先级更高，
  // 所以"回 idle"那条是最高优先）：
  //   1. 非 idle 且非 wait（处于某个"干活一拍"态）→ 下拍无条件回 idle
  //   2. s_wait 且 sbIsEmpty → 按 op 分流（四个分支彼此互斥）
  //   3. s_idle 且 in_valid  → 进 s_wait
  //   4. 否则保持（含 s_wait 但 sbuffer 未空、或 op 是非法编码）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= S_IDLE;
    end else begin
      priority case (1'b1)
        // "干活态"停留一拍后回 idle —— 对应 Scala (state =/= idle && state =/= wait)
        ((state != S_IDLE) && (state != S_WAIT)): state <= S_IDLE;

        // s_wait：store buffer 排空后按 op 分流
        ((state == S_WAIT) && sbuffer_sbIsEmpty): begin
          priority case (1'b1)
            (func == OP_FENCEI ): state <= S_ICACHE;
            is_tlb_op(func)     : state <= S_TLB;
            (func == OP_FENCE  ): state <= S_FENCE;
            (func == OP_NOFENCE): state <= S_NOFENCE;
            default             : state <= S_WAIT;  // 非法编码：卡在 wait（同 golden）
          endcase
        end

        // 接收新请求
        ((state == S_IDLE) && in_valid): state <= S_WAIT;

        default: state <= state;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // 对外 flush / sfence 输出（全部组合自 state + 锁存的 uop）
  // 这些是"某状态下的一拍脉冲"，下游 sbuffer/TLB/icache 必须随时能收 flush。
  // ---------------------------------------------------------------------------
  assign sbuffer_flushSb  = (state == S_WAIT);    // 等排空期间持续拉高
  assign fencei           = (state == S_ICACHE);  // 刷 icache 一拍脉冲

  assign sfence_valid     = (state == S_TLB) & is_tlb_op(func);
  assign sfence_rs1       = (uop.imm[4:0] == 5'h0);  // rs1==x0 → 刷整个地址空间
  assign sfence_rs2       = (uop.imm[9:5] == 5'h0);  // rs2==x0 → 不限定 asid/vmid
  assign sfence_addr      = sfence_addr_r;
  assign sfence_id        = sfence_id_r;             // ASID，或补零后的 VMID
  assign sfence_flushPipe = uop.flushPipe;
  assign sfence_hv        = (func == OP_HFENCE_V);
  assign sfence_hg        = (func == OP_HFENCE_G);

  // ---------------------------------------------------------------------------
  // 出口握手 / 写回（无数据结果）
  //   out_valid：处于某个"干活态"（非 idle 非 wait）即写回，正好一拍。
  // ---------------------------------------------------------------------------
  assign out_valid    = (state != S_IDLE) & (state != S_WAIT);
  assign out_res_data = 64'h0;   // fence 类指令不产生结果

  // 写回只需要 ROB 定位与 flushPipe；其余字段置 0（golden 对应端口也只有这几根）
  always_comb begin
    out_uop              = '0;
    out_uop.robIdx_flag  = uop.robIdx_flag;
    out_uop.robIdx_value = uop.robIdx_value;
    out_uop.pdest        = uop.pdest;
    out_uop.flushPipe    = uop.flushPipe;
  end

  // ---------------------------------------------------------------------------
  // 调试信息直通（G1 新增字段都在这里）
  //
  // perfDebugInfo 与 debug_seqNum 是**纯组合直通**：out 端看到的是 in 端口**当拍**
  // 的值，而不是 in_fire 那拍锁存下来的那条指令的值。因为 out.valid 至少比 in.fire
  // 晚两拍，这中间入口的 in.bits 很可能已经换成别的指令了 —— 也就是说写回带出去的
  // 时间戳/序号可能根本不属于正在写回的这条 fence。
  // 这是 FuncUnit 基类 `io.out.bits.perfDebugInfo := io.in.bits.perfDebugInfo` 的
  // 直接后果，对 perf 计数器/波形标注来说是已知的不精确（这些信号不参与任何功能
  // 逻辑），香山就这么写的。本重写按 bug-for-bug 原则照搬，不"顺手修好"。
  // ---------------------------------------------------------------------------
  assign out_perf    = in_perf;
  assign out_seq_num = in_seq_num;

`ifndef SYNTHESIS
  // 单条目、无 back-pressure：出口拉高时下游必须能收（Scala 同名 assert）。
  always @(posedge clock) begin
    if (!reset) assert (!out_valid || out_ready)
      else $error("Fence: when fence is out valid, out ready should always be true");
  end
`endif

endmodule

// =============================================================================
// Fence —— golden 同名扁平端口层：把 firtool 展平的 io_* 标量端口拼成
// fence_pkg 的 struct，例化可读核 xs_Fence_core，再把核输出拆回扁平端口。
// 本层是机械改名/拼装（供 FM 等价比对与整芯片替换用），微架构逻辑一律在核里。
// 端口顺序与位宽逐条对齐 G1 golden。
// =============================================================================
module Fence
  import fence_pkg::*;
(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_flushPipe,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_data_imm,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_flushPipe,
  output [63:0] io_out_bits_res_data,
  output        io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_bits_debug_seqNum_uopIdx,
  output        io_fenceio_sfence_valid,
  output        io_fenceio_sfence_bits_rs1,
  output        io_fenceio_sfence_bits_rs2,
  output [49:0] io_fenceio_sfence_bits_addr,
  output [15:0] io_fenceio_sfence_bits_id,
  output        io_fenceio_sfence_bits_flushPipe,
  output        io_fenceio_sfence_bits_hv,
  output        io_fenceio_sfence_bits_hg,
  output        io_fenceio_fencei,
  output        io_fenceio_sbuffer_flushSb,
  input         io_fenceio_sbuffer_sbIsEmpty
);

  // 入口扁平端口 → struct
  fence_uop_t in_uop;
  assign in_uop.fuOpType     = io_in_bits_ctrl_fuOpType;
  assign in_uop.robIdx_flag  = io_in_bits_ctrl_robIdx_flag;
  assign in_uop.robIdx_value = io_in_bits_ctrl_robIdx_value;
  assign in_uop.pdest        = io_in_bits_ctrl_pdest;
  assign in_uop.flushPipe    = io_in_bits_ctrl_flushPipe;
  assign in_uop.imm          = io_in_bits_data_imm[IMM_USED_W-1:0]; // 仅低 10 位被读

  perf_debug_info_t in_perf;
  assign in_perf.eliminatedMove         = io_in_bits_perfDebugInfo_eliminatedMove;
  assign in_perf.renameTime             = io_in_bits_perfDebugInfo_renameTime;
  assign in_perf.dispatchTime           = io_in_bits_perfDebugInfo_dispatchTime;
  assign in_perf.enqRsTime              = io_in_bits_perfDebugInfo_enqRsTime;
  assign in_perf.selectTime             = io_in_bits_perfDebugInfo_selectTime;
  assign in_perf.issueTime              = io_in_bits_perfDebugInfo_issueTime;
  assign in_perf.writebackTime          = io_in_bits_perfDebugInfo_writebackTime;
  assign in_perf.runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  assign in_perf.tlbFirstReqTime        = io_in_bits_perfDebugInfo_tlbFirstReqTime;
  assign in_perf.tlbRespTime            = io_in_bits_perfDebugInfo_tlbRespTime;

  debug_seq_num_t in_seq_num;
  assign in_seq_num.seqNum = io_in_bits_debug_seqNum_seqNum;
  assign in_seq_num.uopIdx = io_in_bits_debug_seqNum_uopIdx;

  fence_uop_t       out_uop;
  perf_debug_info_t out_perf;
  debug_seq_num_t   out_seq_num;

  xs_Fence_core u_core (
    .clock            (clock),
    .reset            (reset),
    .in_ready         (io_in_ready),
    .in_valid         (io_in_valid),
    .in_uop           (in_uop),
    .in_src0          (io_in_bits_data_src_0),
    .in_src1          (io_in_bits_data_src_1),
    .in_perf          (in_perf),
    .in_seq_num       (in_seq_num),
    .out_ready        (io_out_ready),
    .out_valid        (io_out_valid),
    .out_uop          (out_uop),
    .out_res_data     (io_out_bits_res_data),
    .out_perf         (out_perf),
    .out_seq_num      (out_seq_num),
    .sbuffer_flushSb  (io_fenceio_sbuffer_flushSb),
    .sbuffer_sbIsEmpty(io_fenceio_sbuffer_sbIsEmpty),
    .fencei           (io_fenceio_fencei),
    .sfence_valid     (io_fenceio_sfence_valid),
    .sfence_rs1       (io_fenceio_sfence_bits_rs1),
    .sfence_rs2       (io_fenceio_sfence_bits_rs2),
    .sfence_addr      (io_fenceio_sfence_bits_addr),
    .sfence_id        (io_fenceio_sfence_bits_id),
    .sfence_flushPipe (io_fenceio_sfence_bits_flushPipe),
    .sfence_hv        (io_fenceio_sfence_bits_hv),
    .sfence_hg        (io_fenceio_sfence_bits_hg)
  );

  // 出口 struct → 扁平端口
  assign io_out_bits_ctrl_robIdx_flag  = out_uop.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = out_uop.robIdx_value;
  assign io_out_bits_ctrl_pdest        = out_uop.pdest;
  assign io_out_bits_ctrl_flushPipe    = out_uop.flushPipe;

  assign io_out_bits_perfDebugInfo_eliminatedMove         = out_perf.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = out_perf.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = out_perf.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = out_perf.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = out_perf.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = out_perf.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = out_perf.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = out_perf.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = out_perf.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = out_perf.tlbRespTime;

  assign io_out_bits_debug_seqNum_seqNum = out_seq_num.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx = out_seq_num.uopIdx;

endmodule
