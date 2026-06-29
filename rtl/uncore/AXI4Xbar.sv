// =============================================================================
//  AXI4Xbar —— 香山 V2R2 大 AXI4 交叉开关 (可读重写核 xs_AXI4Xbar_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip AXI4Xbar (src/main/scala/amba/axi4/Xbar.scala): 2 主口
//  (auto_in_0 / auto_in_1) × 2 从口 (auto_out_0=MEM / auto_out_1=MMIO)。从设计意图
//  重写 (非照抄 firtool 展平后的 6596 行逐位地址掩码与 _T_/_GEN_ 临时名)。
//
//  本核覆盖"多主 AXI 交叉开关"四块核心机制 (详见 axi4xbar_pkg 头注释):
//    [A] ID indexer/yanker: 上行把主口号前缀进 7 位宽 ID (in_0={1'b0,id6} 落[0,64);
//        in_1={2'b10,id5} 落[64,96)); 下行据 ID 高位 (id[6]/id[6:5]) 还原目标主口并把
//        ID 裁回各主口原宽 (in_0 取[5:0], in_1 取[4:0])。
//    [B] 8 把 2 路 round-robin 仲裁器: 每从口 AW/AR 各一把 (源=2 主口), 每主口 R/B 各
//        一把 (源=2 从口); idle 寄存器在下游 stall 时锁定当拍胜者维持选择稳定。
//    [C] per-ID 顺序保持 (FIFO map): in_0 维护 64 个 ID 的 count/last, in_1 维护 32 个;
//        放行门 = (count==0 | last==目标从口) & count!=7; 防同 ID 响应跨从口交错。
//    [D] AW/W 同步: 每主口 awIn 队列记 AW 命中从口供 W 跟随; 每从口 awOut 队列记 AW 仲裁
//        胜出主口供 W 反选 (黑盒 Queue2_UInt2, flow=true, 深度 2)。
//
//  从口字段差异 (按 golden 例化): out_0(MEM) 地址 48 位 + 有 burst/qos; out_1(MMIO)
//  地址 49 位 + 无 burst/qos。主口侧字段差异: in_0 无 cache (输出 cache 默认 4'h2),
//  in_1 有 cache; 响应通道 (R/B) 主口侧无 ready 端口 (恒就绪) 且无 resp 字段。
//
//  验证: golden 同名 AXI4Xbar 例化本核 + 黑盒 Queue2_UInt2/ram_2x2; UT 双例化逐拍比对
//  全部输出 (两主口随机 AW/AR/W + 随机响应 + 地址偏向两从口区 + 多 ID 并发); FM 证等价。
// =============================================================================
module xs_AXI4Xbar_core
  import axi4xbar_pkg::*;
(
  input          clock,
  input          reset,
  output         auto_in_1_aw_ready,
  input          auto_in_1_aw_valid,
  input  [4:0]   auto_in_1_aw_bits_id,
  input  [48:0]  auto_in_1_aw_bits_addr,
  input  [7:0]   auto_in_1_aw_bits_len,
  input  [2:0]   auto_in_1_aw_bits_size,
  input  [1:0]   auto_in_1_aw_bits_burst,
  input  [3:0]   auto_in_1_aw_bits_cache,
  input  [3:0]   auto_in_1_aw_bits_qos,
  output         auto_in_1_w_ready,
  input          auto_in_1_w_valid,
  input  [255:0] auto_in_1_w_bits_data,
  input  [31:0]  auto_in_1_w_bits_strb,
  input          auto_in_1_w_bits_last,
  output         auto_in_1_b_valid,
  output [4:0]   auto_in_1_b_bits_id,
  output         auto_in_1_ar_ready,
  input          auto_in_1_ar_valid,
  input  [4:0]   auto_in_1_ar_bits_id,
  input  [48:0]  auto_in_1_ar_bits_addr,
  input  [7:0]   auto_in_1_ar_bits_len,
  input  [2:0]   auto_in_1_ar_bits_size,
  input  [1:0]   auto_in_1_ar_bits_burst,
  input  [3:0]   auto_in_1_ar_bits_cache,
  input  [3:0]   auto_in_1_ar_bits_qos,
  output         auto_in_1_r_valid,
  output [4:0]   auto_in_1_r_bits_id,
  output [255:0] auto_in_1_r_bits_data,
  output         auto_in_1_r_bits_last,
  output         auto_in_0_aw_ready,
  input          auto_in_0_aw_valid,
  input  [5:0]   auto_in_0_aw_bits_id,
  input  [48:0]  auto_in_0_aw_bits_addr,
  input  [7:0]   auto_in_0_aw_bits_len,
  input  [2:0]   auto_in_0_aw_bits_size,
  input  [1:0]   auto_in_0_aw_bits_burst,
  input  [3:0]   auto_in_0_aw_bits_qos,
  output         auto_in_0_w_ready,
  input          auto_in_0_w_valid,
  input  [255:0] auto_in_0_w_bits_data,
  input  [31:0]  auto_in_0_w_bits_strb,
  input          auto_in_0_w_bits_last,
  output         auto_in_0_b_valid,
  output [5:0]   auto_in_0_b_bits_id,
  output         auto_in_0_ar_ready,
  input          auto_in_0_ar_valid,
  input  [5:0]   auto_in_0_ar_bits_id,
  input  [48:0]  auto_in_0_ar_bits_addr,
  input  [7:0]   auto_in_0_ar_bits_len,
  input  [2:0]   auto_in_0_ar_bits_size,
  input  [1:0]   auto_in_0_ar_bits_burst,
  input  [3:0]   auto_in_0_ar_bits_qos,
  output         auto_in_0_r_valid,
  output [5:0]   auto_in_0_r_bits_id,
  output [255:0] auto_in_0_r_bits_data,
  output         auto_in_0_r_bits_last,
  input          auto_out_1_aw_ready,
  output         auto_out_1_aw_valid,
  output [6:0]   auto_out_1_aw_bits_id,
  output [48:0]  auto_out_1_aw_bits_addr,
  output [7:0]   auto_out_1_aw_bits_len,
  output [2:0]   auto_out_1_aw_bits_size,
  output [3:0]   auto_out_1_aw_bits_cache,
  output [2:0]   auto_out_1_aw_bits_prot,
  input          auto_out_1_w_ready,
  output         auto_out_1_w_valid,
  output [255:0] auto_out_1_w_bits_data,
  output [31:0]  auto_out_1_w_bits_strb,
  output         auto_out_1_w_bits_last,
  output         auto_out_1_b_ready,
  input          auto_out_1_b_valid,
  input  [6:0]   auto_out_1_b_bits_id,
  input          auto_out_1_ar_ready,
  output         auto_out_1_ar_valid,
  output [6:0]   auto_out_1_ar_bits_id,
  output [48:0]  auto_out_1_ar_bits_addr,
  output [7:0]   auto_out_1_ar_bits_len,
  output [2:0]   auto_out_1_ar_bits_size,
  output [3:0]   auto_out_1_ar_bits_cache,
  output [2:0]   auto_out_1_ar_bits_prot,
  output         auto_out_1_r_ready,
  input          auto_out_1_r_valid,
  input  [6:0]   auto_out_1_r_bits_id,
  input  [255:0] auto_out_1_r_bits_data,
  input          auto_out_1_r_bits_last,
  input          auto_out_0_aw_ready,
  output         auto_out_0_aw_valid,
  output [6:0]   auto_out_0_aw_bits_id,
  output [47:0]  auto_out_0_aw_bits_addr,
  output [7:0]   auto_out_0_aw_bits_len,
  output [2:0]   auto_out_0_aw_bits_size,
  output [1:0]   auto_out_0_aw_bits_burst,
  output [3:0]   auto_out_0_aw_bits_cache,
  output [2:0]   auto_out_0_aw_bits_prot,
  output [3:0]   auto_out_0_aw_bits_qos,
  input          auto_out_0_w_ready,
  output         auto_out_0_w_valid,
  output [255:0] auto_out_0_w_bits_data,
  output [31:0]  auto_out_0_w_bits_strb,
  output         auto_out_0_w_bits_last,
  output         auto_out_0_b_ready,
  input          auto_out_0_b_valid,
  input  [6:0]   auto_out_0_b_bits_id,
  input          auto_out_0_ar_ready,
  output         auto_out_0_ar_valid,
  output [6:0]   auto_out_0_ar_bits_id,
  output [47:0]  auto_out_0_ar_bits_addr,
  output [7:0]   auto_out_0_ar_bits_len,
  output [2:0]   auto_out_0_ar_bits_size,
  output [1:0]   auto_out_0_ar_bits_burst,
  output [3:0]   auto_out_0_ar_bits_cache,
  output [2:0]   auto_out_0_ar_bits_prot,
  output [3:0]   auto_out_0_ar_bits_qos,
  output         auto_out_0_r_ready,
  input          auto_out_0_r_valid,
  input  [6:0]   auto_out_0_r_bits_id,
  input  [255:0] auto_out_0_r_bits_data,
  input          auto_out_0_r_bits_last
);

  // ===========================================================================
  //  [A] 地址译码 + ID indexer (主口号前缀)
  // ===========================================================================
  // 每个上行通道译码命中哪个从口 (mem=out_0, mmio=out_1)。
  wire reqAR0_mem  = dec_mem (auto_in_0_ar_bits_addr);
  wire reqAR0_mmio = dec_mmio(auto_in_0_ar_bits_addr);
  wire reqAW0_mem  = dec_mem (auto_in_0_aw_bits_addr);
  wire reqAW0_mmio = dec_mmio(auto_in_0_aw_bits_addr);
  wire reqAR1_mem  = dec_mem (auto_in_1_ar_bits_addr);
  wire reqAR1_mmio = dec_mmio(auto_in_1_ar_bits_addr);
  wire reqAW1_mem  = dec_mem (auto_in_1_aw_bits_addr);
  wire reqAW1_mmio = dec_mmio(auto_in_1_aw_bits_addr);

  // 目标从口 tag (0=mem / 1=mmio): OHToUInt({mmio,mem}) = mmio 命中位。
  wire arTag0 = reqAR0_mmio;
  wire awTag0 = reqAW0_mmio;
  wire arTag1 = reqAR1_mmio;
  wire awTag1 = reqAW1_mmio;

  // ID indexer: 7 位宽 ID = {主口号前缀, 原 ID}。
  wire [6:0] in0_aw_id7 = {1'b0,  auto_in_0_aw_bits_id};   // 主口 0 → [0,64)
  wire [6:0] in0_ar_id7 = {1'b0,  auto_in_0_ar_bits_id};
  wire [6:0] in1_aw_id7 = {2'b10, auto_in_1_aw_bits_id};   // 主口 1 → [64,96)
  wire [6:0] in1_ar_id7 = {2'b10, auto_in_1_ar_bits_id};

  // ===========================================================================
  //  [C] per-ID FIFO map 寄存器 (主口 0: 64 个 ID; 主口 1: 32 个 ID)
  // ===========================================================================
  reg  [2:0] ar0_count [NID0];  reg ar0_last [NID0];
  reg  [2:0] aw0_count [NID0];  reg aw0_last [NID0];
  reg  [2:0] ar1_count [NID1];  reg ar1_last [NID1];
  reg  [2:0] aw1_count [NID1];  reg aw1_last [NID1];

  // 放行向量: 第 k 位 = 该 ID 当前是否允许下发新请求。
  logic [NID0-1:0] allowAR0, allowAW0;
  logic [NID1-1:0] allowAR1, allowAW1;
  always_comb begin
    for (int k = 0; k < NID0; k++) begin
      allowAR0[k] = (ar0_count[k] == 3'h0 | ar0_last[k] == arTag0) & (ar0_count[k] != 3'(FLIGHT));
      allowAW0[k] = (aw0_count[k] == 3'h0 | aw0_last[k] == awTag0) & (aw0_count[k] != 3'(FLIGHT));
    end
    for (int k = 0; k < NID1; k++) begin
      allowAR1[k] = (ar1_count[k] == 3'h0 | ar1_last[k] == arTag1) & (ar1_count[k] != 3'(FLIGHT));
      allowAW1[k] = (aw1_count[k] == 3'h0 | aw1_last[k] == awTag1) & (aw1_count[k] != 3'(FLIGHT));
    end
  end

  // ===========================================================================
  //  [D] AW/W 同步队列 (黑盒 Queue2_UInt2, flow=true, 深度 2)
  //    awIn_x : 主口 x 的 AW 命中从口 one-hot {mmio,mem}, 供该主口 W 跟随。
  //    awOut_x: 从口 x 的 AW 仲裁胜出主口 one-hot {in1,in0}, 供该从口 W 反选。
  // ===========================================================================
  wire       awIn0_enq_ready, awIn0_deq_valid;  wire [1:0] awIn0_deq;
  wire       awIn1_enq_ready, awIn1_deq_valid;  wire [1:0] awIn1_deq;
  wire       awOut0_enq_ready, awOut0_deq_valid; wire [1:0] awOut0_deq;
  wire       awOut1_enq_ready, awOut1_deq_valid; wire [1:0] awOut1_deq;

  // latched: 吸收"AW 已入队但下游尚未接收"的握手错拍 (与 golden latched/_1/_2/_3 同义)。
  reg latched, latched_1, latched_2, latched_3;

  // ---------------------------------------------------------------------------
  //  上行请求 valid (经 FIFO map 放行门 + AW 入队就绪门)
  // ---------------------------------------------------------------------------
  wire in0_ar_valid = auto_in_0_ar_valid & allowAR0[auto_in_0_ar_bits_id];
  wire in1_ar_valid = auto_in_1_ar_valid & allowAR1[auto_in_1_ar_bits_id];
  wire in0_aw_valid = auto_in_0_aw_valid & (latched   | awIn0_enq_ready) & allowAW0[auto_in_0_aw_bits_id];
  wire in1_aw_valid = auto_in_1_aw_valid & (latched_1 | awIn1_enq_ready) & allowAW1[auto_in_1_aw_bits_id];

  // ===========================================================================
  //  [B] 8 把 2 路 round-robin 仲裁器 —— 寄存器与组合结果
  // ===========================================================================
  reg        a_idle  [NARB];
  reg  [1:0] a_mask  [NARB];
  reg  [1:0] a_state [NARB];   // {state_src1, state_src0}

  logic [1:0] a_v      [NARB];  // 两源请求 {src1, src0}
  logic [1:0] a_readys [NARB];  // 本轮授权
  logic [1:0] a_winner [NARB];  // 胜者 = 授权 & 请求
  logic [1:0] a_mux    [NARB];  // muxState = idle?winner:state (供载荷 Mux1H)
  logic [1:0] a_allow  [NARB];  // allowed = idle?readys:state (供源 ready)
  logic       a_any    [NARB];  // 任一源有请求
  logic       a_sink   [NARB];  // sink.valid

  // 各仲裁器两源请求位 (fanout 过滤): 上行 = 主口请求 & 该从口命中; 下行 = 从口响应 & ID 归属。
  always_comb begin
    // 从口 0 / 1 的 AW、AR 仲裁: 源 0=主口0, 源 1=主口1
    a_v[AW_O0] = {in1_aw_valid & reqAW1_mem,  in0_aw_valid & reqAW0_mem};
    a_v[AW_O1] = {in1_aw_valid & reqAW1_mmio, in0_aw_valid & reqAW0_mmio};
    a_v[AR_O0] = {in1_ar_valid & reqAR1_mem,  in0_ar_valid & reqAR0_mem};
    a_v[AR_O1] = {in1_ar_valid & reqAR1_mmio, in0_ar_valid & reqAR0_mmio};
    // 主口 0 / 1 的 R、B 仲裁: 源 0=从口0, 源 1=从口1; ID 归属由响应 ID 高位决定
    a_v[R_I0]  = {auto_out_1_r_valid & ~auto_out_1_r_bits_id[6],
                  auto_out_0_r_valid & ~auto_out_0_r_bits_id[6]};
    a_v[R_I1]  = {auto_out_1_r_valid & (auto_out_1_r_bits_id[6:5] == 2'h2),
                  auto_out_0_r_valid & (auto_out_0_r_bits_id[6:5] == 2'h2)};
    a_v[B_I0]  = {auto_out_1_b_valid & ~auto_out_1_b_bits_id[6],
                  auto_out_0_b_valid & ~auto_out_0_b_bits_id[6]};
    a_v[B_I1]  = {auto_out_1_b_valid & (auto_out_1_b_bits_id[6:5] == 2'h2),
                  auto_out_0_b_valid & (auto_out_0_b_bits_id[6:5] == 2'h2)};
    // 通用 2 路 round-robin 求值 (前缀 OR + idle 锁定)
    for (int i = 0; i < NARB; i++) begin
      a_readys[i] = rr2(a_v[i], a_mask[i]);
      a_winner[i] = a_readys[i] & a_v[i];
      a_mux[i]    = a_idle[i] ? a_winner[i] : a_state[i];
      a_allow[i]  = a_idle[i] ? a_readys[i] : a_state[i];
      a_any[i]    = |a_v[i];
      a_sink[i]   = a_idle[i] ? a_any[i]
                              : (a_state[i][0] & a_v[i][0]) | (a_state[i][1] & a_v[i][1]);
    end
  end

  // ===========================================================================
  //  下行响应载荷 (R/B): 据仲裁 muxState 选从口, 并把 7 位 ID 裁回主口原宽 (yanker)
  // ===========================================================================
  // 主口 0: ID 裁到 [5:0]
  wire [5:0] in0_r_id = (a_mux[R_I0][0] ? auto_out_0_r_bits_id[5:0] : 6'h0)
                      | (a_mux[R_I0][1] ? auto_out_1_r_bits_id[5:0] : 6'h0);
  wire       in0_r_last = (a_mux[R_I0][0] & auto_out_0_r_bits_last)
                        | (a_mux[R_I0][1] & auto_out_1_r_bits_last);
  wire [5:0] in0_b_id = (a_mux[B_I0][0] ? auto_out_0_b_bits_id[5:0] : 6'h0)
                      | (a_mux[B_I0][1] ? auto_out_1_b_bits_id[5:0] : 6'h0);
  // 主口 1: ID 裁到 [4:0]
  wire [4:0] in1_r_id = (a_mux[R_I1][0] ? auto_out_0_r_bits_id[4:0] : 5'h0)
                      | (a_mux[R_I1][1] ? auto_out_1_r_bits_id[4:0] : 5'h0);
  wire       in1_r_last = (a_mux[R_I1][0] & auto_out_0_r_bits_last)
                        | (a_mux[R_I1][1] & auto_out_1_r_bits_last);
  wire [4:0] in1_b_id = (a_mux[B_I1][0] ? auto_out_0_b_bits_id[4:0] : 5'h0)
                      | (a_mux[B_I1][1] ? auto_out_1_b_bits_id[4:0] : 5'h0);

  // ===========================================================================
  //  从口侧 AW/AR/W 就绪 (含 latched 与 awOut 队列), 上行 nodeIn ready
  // ===========================================================================
  wire out0_aw_ready = auto_out_0_aw_ready & (latched_2 | awOut0_enq_ready);
  wire out1_aw_ready = auto_out_1_aw_ready & (latched_3 | awOut1_enq_ready);
  wire out0_w_ready  = auto_out_0_w_ready & awOut0_deq_valid;
  wire out1_w_ready  = auto_out_1_w_ready & awOut1_deq_valid;

  // 各仲裁器 sink.fire (AW/AR 看下游 ready; R/B 主口侧恒就绪 → = sink.valid)
  logic a_fire [NARB];
  always_comb begin
    a_fire[AW_O0] = out0_aw_ready & a_sink[AW_O0];
    a_fire[AR_O0] = auto_out_0_ar_ready & a_sink[AR_O0];
    a_fire[AW_O1] = out1_aw_ready & a_sink[AW_O1];
    a_fire[AR_O1] = auto_out_1_ar_ready & a_sink[AR_O1];
    a_fire[R_I0]  = a_sink[R_I0];
    a_fire[B_I0]  = a_sink[B_I0];
    a_fire[R_I1]  = a_sink[R_I1];
    a_fire[B_I1]  = a_sink[B_I1];
  end

  // AR: 主口的 ar.ready = 命中从口的 (从口 ar_ready & 该主口被仲裁授权) 之或, 再 & 本主口放行向量。
  wire portsAR_in0 = (reqAR0_mem  & auto_out_0_ar_ready & a_allow[AR_O0][0])
                   | (reqAR0_mmio & auto_out_1_ar_ready & a_allow[AR_O1][0]);
  wire portsAR_in1 = (reqAR1_mem  & auto_out_0_ar_ready & a_allow[AR_O0][1])
                   | (reqAR1_mmio & auto_out_1_ar_ready & a_allow[AR_O1][1]);
  wire nodeIn0_ar_ready = portsAR_in0 & allowAR0[auto_in_0_ar_bits_id];
  wire nodeIn1_ar_ready = portsAR_in1 & allowAR1[auto_in_1_ar_bits_id];

  // AW: 同 AR, 但还需 & AW 入队就绪门 (latched | enq_ready)。
  wire portsAW_in0 = (reqAW0_mem  & out0_aw_ready & a_allow[AW_O0][0])
                   | (reqAW0_mmio & out1_aw_ready & a_allow[AW_O1][0]);
  wire portsAW_in1 = (reqAW1_mem  & out0_aw_ready & a_allow[AW_O0][1])
                   | (reqAW1_mmio & out1_aw_ready & a_allow[AW_O1][1]);
  wire nodeIn0_aw_ready = portsAW_in0 & (latched   | awIn0_enq_ready) & allowAW0[auto_in_0_aw_bits_id];
  wire nodeIn1_aw_ready = portsAW_in1 & (latched_1 | awIn1_enq_ready) & allowAW1[auto_in_1_aw_bits_id];

  // W: 主口 W 跟随 awIn 队首路由, 落到的从口须 w_ready 且该从口 awOut 已选中本主口。
  wire portsW_in0 = (awIn0_deq[0] & out0_w_ready & awOut0_deq[0])
                  | (awIn0_deq[1] & out1_w_ready & awOut1_deq[0]);
  wire portsW_in1 = (awIn1_deq[0] & out0_w_ready & awOut0_deq[1])
                  | (awIn1_deq[1] & out1_w_ready & awOut1_deq[1]);
  wire in0_w_valid = auto_in_0_w_valid & awIn0_deq_valid;
  wire in1_w_valid = auto_in_1_w_valid & awIn1_deq_valid;

  // ===========================================================================
  //  从口侧 W 通道选择 (按 awOut 队首选中的主口)
  // ===========================================================================
  wire out0_w_valid = (awOut0_deq[0] & in0_w_valid & awIn0_deq[0])
                    | (awOut0_deq[1] & in1_w_valid & awIn1_deq[0]);
  wire out0_w_last  = (awOut0_deq[0] & auto_in_0_w_bits_last)
                    | (awOut0_deq[1] & auto_in_1_w_bits_last);
  wire out1_w_valid = (awOut1_deq[0] & in0_w_valid & awIn0_deq[1])
                    | (awOut1_deq[1] & in1_w_valid & awIn1_deq[1]);
  wire out1_w_last  = (awOut1_deq[0] & auto_in_0_w_bits_last)
                    | (awOut1_deq[1] & auto_in_1_w_bits_last);

  // ===========================================================================
  //  上行下发到从口 AW / AR (载荷按仲裁 muxState 做 Mux1H; 字段缺省按 golden 常量)
  // ===========================================================================
  // ---- 从口 0 (MEM): 地址截 48 位, 含 burst/qos ----
  assign auto_out_0_aw_valid     = a_sink[AW_O0] & (latched_2 | awOut0_enq_ready);
  assign auto_out_0_aw_bits_id   = (a_mux[AW_O0][0] ? in0_aw_id7 : 7'h0) | (a_mux[AW_O0][1] ? in1_aw_id7 : 7'h0);
  assign auto_out_0_aw_bits_addr = (a_mux[AW_O0][0] ? auto_in_0_aw_bits_addr[47:0] : 48'h0)
                                 | (a_mux[AW_O0][1] ? auto_in_1_aw_bits_addr[47:0] : 48'h0);
  assign auto_out_0_aw_bits_len  = (a_mux[AW_O0][0] ? auto_in_0_aw_bits_len : 8'h0) | (a_mux[AW_O0][1] ? auto_in_1_aw_bits_len : 8'h0);
  assign auto_out_0_aw_bits_size = (a_mux[AW_O0][0] ? auto_in_0_aw_bits_size : 3'h0) | (a_mux[AW_O0][1] ? auto_in_1_aw_bits_size : 3'h0);
  assign auto_out_0_aw_bits_burst= (a_mux[AW_O0][0] ? auto_in_0_aw_bits_burst : 2'h0) | (a_mux[AW_O0][1] ? auto_in_1_aw_bits_burst : 2'h0);
  assign auto_out_0_aw_bits_cache= {2'h0, a_mux[AW_O0][0], 1'h0} | (a_mux[AW_O0][1] ? auto_in_1_aw_bits_cache : 4'h0); // in_0 无 cache → 4'h2
  assign auto_out_0_aw_bits_prot = {1'h0, a_mux[AW_O0][0] | a_mux[AW_O0][1], 1'h0};                                   // 主口无 prot → 3'h2
  assign auto_out_0_aw_bits_qos  = (a_mux[AW_O0][0] ? auto_in_0_aw_bits_qos : 4'h0) | (a_mux[AW_O0][1] ? auto_in_1_aw_bits_qos : 4'h0);

  assign auto_out_0_ar_valid     = a_sink[AR_O0];
  assign auto_out_0_ar_bits_id   = (a_mux[AR_O0][0] ? in0_ar_id7 : 7'h0) | (a_mux[AR_O0][1] ? in1_ar_id7 : 7'h0);
  assign auto_out_0_ar_bits_addr = (a_mux[AR_O0][0] ? auto_in_0_ar_bits_addr[47:0] : 48'h0)
                                 | (a_mux[AR_O0][1] ? auto_in_1_ar_bits_addr[47:0] : 48'h0);
  assign auto_out_0_ar_bits_len  = (a_mux[AR_O0][0] ? auto_in_0_ar_bits_len : 8'h0) | (a_mux[AR_O0][1] ? auto_in_1_ar_bits_len : 8'h0);
  assign auto_out_0_ar_bits_size = (a_mux[AR_O0][0] ? auto_in_0_ar_bits_size : 3'h0) | (a_mux[AR_O0][1] ? auto_in_1_ar_bits_size : 3'h0);
  assign auto_out_0_ar_bits_burst= (a_mux[AR_O0][0] ? auto_in_0_ar_bits_burst : 2'h0) | (a_mux[AR_O0][1] ? auto_in_1_ar_bits_burst : 2'h0);
  assign auto_out_0_ar_bits_cache= {2'h0, a_mux[AR_O0][0], 1'h0} | (a_mux[AR_O0][1] ? auto_in_1_ar_bits_cache : 4'h0);
  assign auto_out_0_ar_bits_prot = {1'h0, a_mux[AR_O0][0] | a_mux[AR_O0][1], 1'h0};
  assign auto_out_0_ar_bits_qos  = (a_mux[AR_O0][0] ? auto_in_0_ar_bits_qos : 4'h0) | (a_mux[AR_O0][1] ? auto_in_1_ar_bits_qos : 4'h0);

  // ---- 从口 1 (MMIO): 地址全 49 位, 无 burst/qos ----
  assign auto_out_1_aw_valid     = a_sink[AW_O1] & (latched_3 | awOut1_enq_ready);
  assign auto_out_1_aw_bits_id   = (a_mux[AW_O1][0] ? in0_aw_id7 : 7'h0) | (a_mux[AW_O1][1] ? in1_aw_id7 : 7'h0);
  assign auto_out_1_aw_bits_addr = (a_mux[AW_O1][0] ? auto_in_0_aw_bits_addr : 49'h0) | (a_mux[AW_O1][1] ? auto_in_1_aw_bits_addr : 49'h0);
  assign auto_out_1_aw_bits_len  = (a_mux[AW_O1][0] ? auto_in_0_aw_bits_len : 8'h0) | (a_mux[AW_O1][1] ? auto_in_1_aw_bits_len : 8'h0);
  assign auto_out_1_aw_bits_size = (a_mux[AW_O1][0] ? auto_in_0_aw_bits_size : 3'h0) | (a_mux[AW_O1][1] ? auto_in_1_aw_bits_size : 3'h0);
  assign auto_out_1_aw_bits_cache= {2'h0, a_mux[AW_O1][0], 1'h0} | (a_mux[AW_O1][1] ? auto_in_1_aw_bits_cache : 4'h0);
  assign auto_out_1_aw_bits_prot = {1'h0, a_mux[AW_O1][0] | a_mux[AW_O1][1], 1'h0};

  assign auto_out_1_ar_valid     = a_sink[AR_O1];
  assign auto_out_1_ar_bits_id   = (a_mux[AR_O1][0] ? in0_ar_id7 : 7'h0) | (a_mux[AR_O1][1] ? in1_ar_id7 : 7'h0);
  assign auto_out_1_ar_bits_addr = (a_mux[AR_O1][0] ? auto_in_0_ar_bits_addr : 49'h0) | (a_mux[AR_O1][1] ? auto_in_1_ar_bits_addr : 49'h0);
  assign auto_out_1_ar_bits_len  = (a_mux[AR_O1][0] ? auto_in_0_ar_bits_len : 8'h0) | (a_mux[AR_O1][1] ? auto_in_1_ar_bits_len : 8'h0);
  assign auto_out_1_ar_bits_size = (a_mux[AR_O1][0] ? auto_in_0_ar_bits_size : 3'h0) | (a_mux[AR_O1][1] ? auto_in_1_ar_bits_size : 3'h0);
  assign auto_out_1_ar_bits_cache= {2'h0, a_mux[AR_O1][0], 1'h0} | (a_mux[AR_O1][1] ? auto_in_1_ar_bits_cache : 4'h0);
  assign auto_out_1_ar_bits_prot = {1'h0, a_mux[AR_O1][0] | a_mux[AR_O1][1], 1'h0};

  // ===========================================================================
  //  从口侧 W 下发 (按 awOut 队首选中的主口广播数据/strb/last)
  // ===========================================================================
  assign auto_out_0_w_valid     = out0_w_valid & awOut0_deq_valid;
  assign auto_out_0_w_bits_data = (awOut0_deq[0] ? auto_in_0_w_bits_data : 256'h0) | (awOut0_deq[1] ? auto_in_1_w_bits_data : 256'h0);
  assign auto_out_0_w_bits_strb = (awOut0_deq[0] ? auto_in_0_w_bits_strb : 32'h0)  | (awOut0_deq[1] ? auto_in_1_w_bits_strb : 32'h0);
  assign auto_out_0_w_bits_last = out0_w_last;
  assign auto_out_1_w_valid     = out1_w_valid & awOut1_deq_valid;
  assign auto_out_1_w_bits_data = (awOut1_deq[0] ? auto_in_0_w_bits_data : 256'h0) | (awOut1_deq[1] ? auto_in_1_w_bits_data : 256'h0);
  assign auto_out_1_w_bits_strb = (awOut1_deq[0] ? auto_in_0_w_bits_strb : 32'h0)  | (awOut1_deq[1] ? auto_in_1_w_bits_strb : 32'h0);
  assign auto_out_1_w_bits_last = out1_w_last;

  // ===========================================================================
  //  从口侧 R / B 就绪 (响应据 ID 路由到目标主口, 取该主口对应仲裁器的 allowed)
  // ===========================================================================
  assign auto_out_0_r_ready = (~auto_out_0_r_bits_id[6] & a_allow[R_I0][0])
                            | ((auto_out_0_r_bits_id[6:5] == 2'h2) & a_allow[R_I1][0]);
  assign auto_out_1_r_ready = (~auto_out_1_r_bits_id[6] & a_allow[R_I0][1])
                            | ((auto_out_1_r_bits_id[6:5] == 2'h2) & a_allow[R_I1][1]);
  assign auto_out_0_b_ready = (~auto_out_0_b_bits_id[6] & a_allow[B_I0][0])
                            | ((auto_out_0_b_bits_id[6:5] == 2'h2) & a_allow[B_I1][0]);
  assign auto_out_1_b_ready = (~auto_out_1_b_bits_id[6] & a_allow[B_I0][1])
                            | ((auto_out_1_b_bits_id[6:5] == 2'h2) & a_allow[B_I1][1]);

  // ===========================================================================
  //  上行主口握手输出 + 下行响应输出
  // ===========================================================================
  assign auto_in_0_ar_ready   = nodeIn0_ar_ready;
  assign auto_in_0_aw_ready   = nodeIn0_aw_ready;
  assign auto_in_0_w_ready    = portsW_in0 & awIn0_deq_valid;
  assign auto_in_0_r_valid    = a_sink[R_I0];
  assign auto_in_0_r_bits_id  = in0_r_id;
  assign auto_in_0_r_bits_data= (a_mux[R_I0][0] ? auto_out_0_r_bits_data : 256'h0) | (a_mux[R_I0][1] ? auto_out_1_r_bits_data : 256'h0);
  assign auto_in_0_r_bits_last= in0_r_last;
  assign auto_in_0_b_valid    = a_sink[B_I0];
  assign auto_in_0_b_bits_id  = in0_b_id;

  assign auto_in_1_ar_ready   = nodeIn1_ar_ready;
  assign auto_in_1_aw_ready   = nodeIn1_aw_ready;
  assign auto_in_1_w_ready    = portsW_in1 & awIn1_deq_valid;
  assign auto_in_1_r_valid    = a_sink[R_I1];
  assign auto_in_1_r_bits_id  = in1_r_id;
  assign auto_in_1_r_bits_data= (a_mux[R_I1][0] ? auto_out_0_r_bits_data : 256'h0) | (a_mux[R_I1][1] ? auto_out_1_r_bits_data : 256'h0);
  assign auto_in_1_r_bits_last= in1_r_last;
  assign auto_in_1_b_valid    = a_sink[B_I1];
  assign auto_in_1_b_bits_id  = in1_b_id;

  // ===========================================================================
  //  AW/W 同步队列例化 (黑盒 Queue2_UInt2)
  // ===========================================================================
  Queue2_UInt2 awIn_0 (
    .clock(clock), .reset(reset),
    .io_enq_ready(awIn0_enq_ready),
    .io_enq_valid(auto_in_0_aw_valid & ~latched),
    .io_enq_bits ({reqAW0_mmio, reqAW0_mem}),
    .io_deq_ready(auto_in_0_w_valid & auto_in_0_w_bits_last & portsW_in0),
    .io_deq_valid(awIn0_deq_valid),
    .io_deq_bits (awIn0_deq)
  );
  Queue2_UInt2 awIn_1 (
    .clock(clock), .reset(reset),
    .io_enq_ready(awIn1_enq_ready),
    .io_enq_valid(auto_in_1_aw_valid & ~latched_1),
    .io_enq_bits ({reqAW1_mmio, reqAW1_mem}),
    .io_deq_ready(auto_in_1_w_valid & auto_in_1_w_bits_last & portsW_in1),
    .io_deq_valid(awIn1_deq_valid),
    .io_deq_bits (awIn1_deq)
  );
  Queue2_UInt2 awOut_0 (
    .clock(clock), .reset(reset),
    .io_enq_ready(awOut0_enq_ready),
    .io_enq_valid(a_sink[AW_O0] & ~latched_2),
    .io_enq_bits (a_mux[AW_O0]),                 // {muxState_in1, muxState_in0}
    .io_deq_ready(out0_w_valid & out0_w_last & auto_out_0_w_ready),
    .io_deq_valid(awOut0_deq_valid),
    .io_deq_bits (awOut0_deq)
  );
  Queue2_UInt2 awOut_1 (
    .clock(clock), .reset(reset),
    .io_enq_ready(awOut1_enq_ready),
    .io_enq_valid(a_sink[AW_O1] & ~latched_3),
    .io_enq_bits (a_mux[AW_O1]),
    .io_deq_ready(out1_w_valid & out1_w_last & auto_out_1_w_ready),
    .io_deq_valid(awOut1_deq_valid),
    .io_deq_bits (awOut1_deq)
  );

  // ===========================================================================
  //  [C] FIFO map 计数/锁定的请求·响应 fire (驱动 count ± 与 last 更新)
  // ===========================================================================
  wire ar0_fire = nodeIn0_ar_ready & auto_in_0_ar_valid;   // 主口 0 AR 请求 fire
  wire aw0_fire = nodeIn0_aw_ready & auto_in_0_aw_valid;
  wire ar1_fire = nodeIn1_ar_ready & auto_in_1_ar_valid;
  wire aw1_fire = nodeIn1_aw_ready & auto_in_1_aw_valid;

  logic [NID0-1:0] ar0_reqf, ar0_respf, aw0_reqf, aw0_respf;
  logic [NID1-1:0] ar1_reqf, ar1_respf, aw1_reqf, aw1_respf;
  always_comb begin
    for (int k = 0; k < NID0; k++) begin
      ar0_reqf[k]  = (auto_in_0_ar_bits_id == k[5:0]) & ar0_fire;
      aw0_reqf[k]  = (auto_in_0_aw_bits_id == k[5:0]) & aw0_fire;
      ar0_respf[k] = (in0_r_id == k[5:0]) & a_sink[R_I0] & in0_r_last;  // 读末拍出飞
      aw0_respf[k] = (in0_b_id == k[5:0]) & a_sink[B_I0];               // 写 B 出飞
    end
    for (int k = 0; k < NID1; k++) begin
      ar1_reqf[k]  = (auto_in_1_ar_bits_id == k[4:0]) & ar1_fire;
      aw1_reqf[k]  = (auto_in_1_aw_bits_id == k[4:0]) & aw1_fire;
      ar1_respf[k] = (in1_r_id == k[4:0]) & a_sink[R_I1] & in1_r_last;
      aw1_respf[k] = (in1_b_id == k[4:0]) & a_sink[B_I1];
    end
  end

  // ===========================================================================
  //  时序 (异步复位, 同 golden): FIFO map count + latched + 仲裁器 idle/mask/state
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < NID0; i++) begin ar0_count[i] <= 3'h0; aw0_count[i] <= 3'h0; end
      for (int i = 0; i < NID1; i++) begin ar1_count[i] <= 3'h0; aw1_count[i] <= 3'h0; end
      latched <= 1'b0; latched_1 <= 1'b0; latched_2 <= 1'b0; latched_3 <= 1'b0;
      for (int i = 0; i < NARB; i++) begin
        a_idle[i] <= 1'b1; a_mask[i] <= 2'b11; a_state[i] <= 2'b00;
      end
    end else begin
      for (int i = 0; i < NID0; i++) begin
        ar0_count[i] <= ar0_count[i] + 3'(ar0_reqf[i]) - 3'(ar0_respf[i]);
        aw0_count[i] <= aw0_count[i] + 3'(aw0_reqf[i]) - 3'(aw0_respf[i]);
      end
      for (int i = 0; i < NID1; i++) begin
        ar1_count[i] <= ar1_count[i] + 3'(ar1_reqf[i]) - 3'(ar1_respf[i]);
        aw1_count[i] <= aw1_count[i] + 3'(aw1_reqf[i]) - 3'(aw1_respf[i]);
      end
      // latched: ~(本主/从口 AW fire) & (本拍入队完成 | 维持) —— AW 入队与下发的握手错拍吸收
      latched   <= ~(portsAW_in0 & in0_aw_valid) & ((awIn0_enq_ready & (auto_in_0_aw_valid & ~latched))   | latched);
      latched_1 <= ~(portsAW_in1 & in1_aw_valid) & ((awIn1_enq_ready & (auto_in_1_aw_valid & ~latched_1)) | latched_1);
      latched_2 <= ~(out0_aw_ready & a_sink[AW_O0]) & ((awOut0_enq_ready & (a_sink[AW_O0] & ~latched_2)) | latched_2);
      latched_3 <= ~(out1_aw_ready & a_sink[AW_O1]) & ((awOut1_enq_ready & (a_sink[AW_O1] & ~latched_3)) | latched_3);
      // 8 把仲裁器: idle=sink.fire时回 idle, 否则有请求即占用; mask/state 在 idle 拍锁定胜者
      for (int i = 0; i < NARB; i++) begin
        a_idle[i] <= a_fire[i] | (~a_any[i] & a_idle[i]);
        if (a_idle[i] & (|a_v[i])) a_mask[i] <= leftor2(a_winner[i]);
        if (a_idle[i])             a_state[i] <= a_winner[i];
      end
    end
  end

  // ===========================================================================
  //  per-ID last 锁定 (无 reset, 同 golden: 仅在该 ID 请求 fire 时记下目标从口)
  // ===========================================================================
  always_ff @(posedge clock) begin
    for (int i = 0; i < NID0; i++) begin
      if (ar0_reqf[i]) ar0_last[i] <= arTag0;
      if (aw0_reqf[i]) aw0_last[i] <= awTag0;
    end
    for (int i = 0; i < NID1; i++) begin
      if (ar1_reqf[i]) ar1_last[i] <= arTag1;
      if (aw1_reqf[i]) aw1_last[i] <= awTag1;
    end
  end

endmodule
