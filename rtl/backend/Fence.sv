// =============================================================================
// fence_pkg —— Fence 功能单元（栅栏单元）的类型与常量定义
//
// 对应 Chisel: xiangshan.backend.fu.Fence / FenceOpType（package.scala）
//
// Fence FU 处理三类“屏障/同步”指令，它们都不产生数据结果，而是通过
// 一个小状态机，在流水排空（store buffer 清空）后向外部各部件发出 flush 脉冲：
//   - fence        ：内存屏障（RVI），实际只需排空 sbuffer，不发额外 flush
//   - fence.i      ：取指屏障，需 flush icache（fencei 信号）
//   - sfence.vma   ：刷新 TLB（sfence.valid 信号），supervisor 地址翻译屏障
//   - hfence.vvma  ：刷新 VS 级 TLB（hv），H 扩展
//   - hfence.gvma  ：刷新 G 级 TLB（hg），H 扩展
//   - nofence      ：占位（Svinval 扩展用），什么都不做
//
// 设计要点：所有 flush（sbuffer/tlb/icache）信号都是“某个状态下拉高一拍”的脉冲，
// 下游部件必须随时能接收 flush。状态机走完后回到 idle 并在出口握手写回 ROB。
// =============================================================================
package fence_pkg;

  // ---------------------------------------------------------------------------
  // FenceOpType —— fuOpType 编码（9 位端口，但有效编码仅低 5 位）
  // 与 Scala object FenceOpType 完全一致：
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
  // 状态机状态 —— 与 Scala 的 Enum(6) 同序同义：
  //   s_idle    : 初始态，可纳新请求；in.ready 仅此态为 1
  //   s_wait    : 拉高 sbuffer flush，等 store buffer 排空（sbIsEmpty）
  //   s_tlb     : 发 sfence（刷 TLB），停留一拍
  //   s_icache  : 发 fencei（刷 icache），停留一拍
  //   s_fence   : 普通 fence 的占位态（仅为时序，不发额外 flush），停留一拍
  //   s_nofence : Svinval 占位态，停留一拍
  // 注意编码必须与 golden 完全一致（FM/Ut 双例化按值比对状态相关输出）：
  //   idle=0 wait=1 tlb=2 icache=3 fence=4 nofence=5
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
  // 入口 uop 中需要在 fire 拍锁存、供状态机及写回使用的字段。
  // （golden 把这些字段散成一堆 uop_ctrl_* / uop_data_imm 标量寄存器，这里聚合成
  //  一个 struct，语义更清晰：它就是“当前正在处理的这条 fence 指令”。）
  // ---------------------------------------------------------------------------
  // 立即数只有低 10 位在本单元被读：imm[4:0] 判 sfence.rs1(=x0)、imm[9:5] 判 sfence.rs2(=x0)。
  // 高 54 位在 Fence 内从不被读（golden 也只读低 10 位），故锁存宽度收窄到实际读取范围，
  // 避免存 54 位从不使用的死寄存器（cone-dead 推断伪影）。
  localparam int unsigned IMM_USED_W = 10;

  typedef struct packed {
    logic [FUOPTYPE_W-1:0]  fuOpType;     // 决定走哪条 flush 分支
    logic                   robIdx_flag;  // ROB 指针（写回定位）
    logic [7:0]             robIdx_value;
    logic [7:0]             pdest;        // 物理目的寄存器（fence 无结果，仍透传）
    logic                   flushPipe;    // 是否需要 flush 流水（透传到 sfence/out）
    logic [IMM_USED_W-1:0]  imm;          // 立即数低 10 位：sfence rs1/rs2 判定（高位从不读，不存）
  } fence_uop_t;

  // sfence 目标：地址页只需低 50 位（虚地址页 io_fenceio_sfence_bits_addr[49:0]），
  // asid/vmid 只需低 16 位（io_fenceio_sfence_bits_id[15:0]）。src 输入是 64 位，
  // 但本单元只读这些低位，故锁存宽度按读取范围收窄。
  localparam int unsigned SFENCE_ADDR_W = 50;
  localparam int unsigned SFENCE_ID_W   = 16;

endpackage

// =============================================================================
// xs_Fence_core —— 栅栏单元（Fence FU）可读核
//
// 对应 Chisel: xiangshan.backend.fu.Fence（class Fence extends FuncUnit）
//
// 在后端的位置：属于整数 ExuBlock 里的一个 FU 叶子。Scheduler 发射一条
// fence/fence.i/sfence.vma/hfence/nofence 微操作进来（io_in），本单元用一个
// 6 态状态机驱动外部 flush，并在完成后从 io_out 写回 ROB（无数据结果）。
//
// ┌──────────── 数据流与时序 ────────────────────────────────────────────────┐
// │  发射进来(in.fire) ─► 锁存 uop/sfence地址 ─► s_wait 拉 sbuffer.flushSb    │
// │       └─ 等 sbIsEmpty ─► 按 op 分流到 s_tlb / s_icache / s_fence /        │
// │            s_nofence（各停留一拍并发对应 flush）─► 回 s_idle 并 out.valid  │
// └──────────────────────────────────────────────────────────────────────────┘
//
// 关键设计点（“为什么”）：
//  1. 必须先排空 store buffer 再 flush：fence 语义要求之前的 store 对后续可见，
//     icache/TLB flush 也需在内存写回落定后进行，故 s_wait 先等 sbIsEmpty。
//  2. flush 信号都是“某状态下的一拍脉冲”（组合自 state），下游随时可收。
//  3. s_fence/s_nofence 是“什么都不做”的占位态：把“等排空”与“写回”分成两拍，
//     是为时序优化（避免 in.fire 当拍就拉出口握手的长组合路径）/扩展占位。
//  4. 出口写回无异常、无数据（res.data=0，exceptionVec=0），仅透传 robIdx/pdest/
//     flushPipe 与 perf 调试信息。
//
// payload 用打包总线表示，扁平 golden 端口由外层 wrapper / UT 变体适配。
// =============================================================================

module xs_Fence_core
  import fence_pkg::*;
(
  input  logic        clock,
  input  logic        reset,        // 异步高有效，仅复位 state

  // ---- 入口（发射） ----
  output logic        in_ready,     // 仅 s_idle 接收
  input  logic        in_valid,
  input  fence_uop_t  in_uop,       // 锁存字段（fuOpType/robIdx/pdest/flushPipe/imm）
  input  logic [63:0] in_src0,      // sfence 目标地址来源（rs1 值）
  input  logic [63:0] in_src1,      // sfence asid/vmid 来源（rs2 值）

  // ---- 出口（写回 ROB，无数据） ----
  input  logic        out_ready,
  output logic        out_valid,
  output fence_uop_t  out_uop,      // 透传锁存的 robIdx/pdest/flushPipe（其余字段忽略）

  // ---- 对外 flush / sfence 接口 ----
  output logic        sbuffer_flushSb,   // s_wait：请求 store buffer 排空
  input  logic        sbuffer_sbIsEmpty, // store buffer 已空
  output logic        fencei,            // s_icache：flush icache 脉冲

  output logic        sfence_valid,      // s_tlb 且为 sfence/hfence 时拉高
  output logic        sfence_rs1,        // imm[4:0]==0 → rs1=x0（刷整 TLB）
  output logic        sfence_rs2,        // imm[9:5]==0 → rs2=x0（不限 asid）
  output logic [49:0] sfence_addr,       // 锁存的 src0 低 50 位（虚地址页）
  output logic [15:0] sfence_id,         // 锁存的 src1 低 16 位（asid/vmid）
  output logic        sfence_flushPipe,
  output logic        sfence_hv,         // hfence.vvma
  output logic        sfence_hg          // hfence.gvma
);

  // ---------------------------------------------------------------------------
  // 入口握手 / 锁存
  // ---------------------------------------------------------------------------
  fence_state_e state;

  // in.fire：仅在 s_idle 接收新请求（与 golden 一致）
  assign in_ready = (state == S_IDLE);
  logic in_fire;
  assign in_fire = in_ready & in_valid;

  // 在 fire 拍锁存“当前处理的这条 fence”及 sfence 地址/id。
  // 地址/id 只锁存实际会被读的低位（addr 低 50 位、id 低 16 位；高位 Fence 从不读，
  // 存了就是 cone-dead 死寄存器），故存储宽度按读取范围收窄，输入在锁存处即切片。
  fence_uop_t                    uop;
  logic [SFENCE_ADDR_W-1:0]      sfence_addr_r;
  logic [SFENCE_ID_W-1:0]        sfence_id_r;

  always_ff @(posedge clock) begin
    if (in_fire) begin
      uop           <= in_uop;
      sfence_addr_r <= in_src0[SFENCE_ADDR_W-1:0];
      sfence_id_r   <= in_src1[SFENCE_ID_W-1:0];
    end
  end

  // 当前指令操作码（便于按 enum 名分流，可读）
  fence_op_e func;
  assign func = fence_op_e'(uop.fuOpType);

  // ---------------------------------------------------------------------------
  // flush 分类判定（纯函数：op → 走哪条排空后的分支）
  //   把 golden 散落的 (op==sfence|hv|hg) 等组合判断收敛成命名函数，表意清晰。
  // ---------------------------------------------------------------------------
  function automatic logic is_tlb_op(fence_op_e op);
    // sfence.vma / hfence.vvma / hfence.gvma 都走刷 TLB 分支
    return (op == OP_SFENCE) | (op == OP_HFENCE_V) | (op == OP_HFENCE_G);
  endfunction

  // ---------------------------------------------------------------------------
  // 状态机
  // 规则（与 Scala when 链严格对应，用 priority case 避免 X 与重叠歧义）：
  //   - 非 idle 且非 wait（即处于某个“干活一拍”态）→ 下拍无条件回 idle（最高优先）
  //   - s_wait 且 sbIsEmpty：按 op 分流到 tlb/icache/fence/nofence
  //   - s_idle 且 in_valid：进 s_wait
  //   - 否则保持
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= S_IDLE;
    end else begin
      priority case (1'b1)
        // “干活态”停留一拍后回 idle —— 对应 (state =/= idle && state =/= wait)
        ((state != S_IDLE) && (state != S_WAIT)): state <= S_IDLE;

        // s_wait：store buffer 排空后按 op 分流
        ((state == S_WAIT) && sbuffer_sbIsEmpty): begin
          priority case (1'b1)
            (func == OP_FENCEI ): state <= S_ICACHE;
            is_tlb_op(func)      : state <= S_TLB;
            (func == OP_FENCE  ): state <= S_FENCE;
            (func == OP_NOFENCE): state <= S_NOFENCE;
            default             : state <= S_WAIT;  // 未知 op：继续等（保持）
          endcase
        end

        // 接收新请求
        ((state == S_IDLE) && in_valid): state <= S_WAIT;

        default: state <= state;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // 对外 flush / sfence 输出（全部组合自 state + 锁存 uop）
  // ---------------------------------------------------------------------------
  assign sbuffer_flushSb = (state == S_WAIT);    // 等排空期间持续拉高
  assign fencei          = (state == S_ICACHE);  // 刷 icache 一拍脉冲

  assign sfence_valid    = (state == S_TLB) & is_tlb_op(func);
  assign sfence_rs1      = (uop.imm[4:0] == 5'h0);   // rs1==x0 → 刷整个地址空间
  assign sfence_rs2      = (uop.imm[9:5] == 5'h0);   // rs2==x0 → 不限定 asid/vmid
  assign sfence_addr     = sfence_addr_r;            // 已是 50 位（低虚地址页）
  assign sfence_id       = sfence_id_r;              // 已是 16 位（asid/vmid）
  assign sfence_flushPipe= uop.flushPipe;
  assign sfence_hv       = (func == OP_HFENCE_V);
  assign sfence_hg       = (func == OP_HFENCE_G);

  // ---------------------------------------------------------------------------
  // 出口握手 / 写回（无数据结果）
  //   out_valid：处于某个“干活态”（非 idle 非 wait）即写回。
  // ---------------------------------------------------------------------------
  assign out_valid = (state != S_IDLE) & (state != S_WAIT);

  // 透传锁存字段；res.data/异常恒 0 在 wrapper 处补齐（核只产出写回必需字段）
  always_comb begin
    out_uop              = '0;
    out_uop.robIdx_flag  = uop.robIdx_flag;
    out_uop.robIdx_value = uop.robIdx_value;
    out_uop.pdest        = uop.pdest;
    out_uop.flushPipe    = uop.flushPipe;
  end

`ifndef SYNTHESIS
  // 出口拉高时下游必须能收（Scala 同名 assert）
  always @(posedge clock) begin
    if (!reset) assert (!out_valid || out_ready)
      else $error("Fence: when out_valid, out_ready must be true");
  end
`endif

endmodule

// =============================================================================
// Fence —— golden 同名扁平端口包装层（机械适配，供 FM 等价比对 / ST 替换）
//
// 职责：把 golden（firtool）展平的 io_* 标量端口拼成 fence_pkg 的 struct，例化可读核
// xs_Fence_core，再把核输出拆回扁平端口。本层不含微架构逻辑，只做端口拼装与
// 几个恒定值（res.data=0、perfDebugInfo 透传）的补齐。
// =============================================================================

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

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
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_flushPipe,
  output [63:0] io_out_bits_res_data,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
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

  // 入口字段 → struct
  fence_uop_t in_uop;
  assign in_uop.fuOpType     = io_in_bits_ctrl_fuOpType;
  assign in_uop.robIdx_flag  = io_in_bits_ctrl_robIdx_flag;
  assign in_uop.robIdx_value = io_in_bits_ctrl_robIdx_value;
  assign in_uop.pdest        = io_in_bits_ctrl_pdest;
  assign in_uop.flushPipe    = io_in_bits_ctrl_flushPipe;
  assign in_uop.imm          = io_in_bits_data_imm[IMM_USED_W-1:0]; // 仅低 10 位被 sfence 判定读取

  fence_uop_t out_uop;

  xs_Fence_core u_core (
    .clock            (clock),
    .reset            (reset),
    .in_ready         (io_in_ready),
    .in_valid         (io_in_valid),
    .in_uop           (in_uop),
    .in_src0          (io_in_bits_data_src_0),
    .in_src1          (io_in_bits_data_src_1),
    .out_ready        (io_out_ready),
    .out_valid        (io_out_valid),
    .out_uop          (out_uop),
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

  // 出口 struct → 扁平端口（res.data 恒 0，perf 信息直透）
  assign io_out_bits_ctrl_robIdx_flag  = out_uop.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = out_uop.robIdx_value;
  assign io_out_bits_ctrl_pdest        = out_uop.pdest;
  assign io_out_bits_ctrl_flushPipe    = out_uop.flushPipe;
  assign io_out_bits_res_data          = 64'h0;
  assign io_out_bits_perfDebugInfo_enqRsTime   = io_in_bits_perfDebugInfo_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime  = io_in_bits_perfDebugInfo_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime   = io_in_bits_perfDebugInfo_issueTime;

endmodule
