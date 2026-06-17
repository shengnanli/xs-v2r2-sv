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

  // 在 fire 拍锁存“当前处理的这条 fence”及 sfence 地址/id
  fence_uop_t  uop;
  logic [63:0] sfence_addr_r;
  logic [63:0] sfence_id_r;

  always_ff @(posedge clock) begin
    if (in_fire) begin
      uop           <= in_uop;
      sfence_addr_r <= in_src0;
      sfence_id_r   <= in_src1;
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
  assign sfence_addr     = sfence_addr_r[49:0];
  assign sfence_id       = sfence_id_r[15:0];
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
