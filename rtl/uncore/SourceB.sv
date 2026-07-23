// =============================================================================
//  SourceB —— coupledL2 (tl2chi) 向上层发 Probe 的 B 通道源 可读重写核
//          (xs_SourceB_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/SourceB.scala
//  4 表项 probe 缓冲: 收 MSHR 投来的 SourceBReq, 经 FastArbiter 轮询发到上层 cache。
//  关键: 若同地址 (set+tag) 的 Grant 尚未收到 GrantAck (grantStatus 命中), 则该 Probe
//  暂不就绪(rdy=0), 待对应 grantStatus 失效后再 RegNext 置就绪 —— 防 Probe 抢跑 Grant。
//
//  单态化 (firtool SourceB.sv): entries=4, grantBufInflightSize=16,
//    SourceBReq = {tag[30:0], set[8:0], opcode[2:0], param[1:0], alias[1:0]}。
//  FastArbiter_6 (4 入 1 出轮询仲裁) 为黑盒, 在 golden 同名 wrapper 内例化; 本核暴露
//    与其对接的 in_k(valid/bits)/in_k_ready 端口, 出口 io_sourceB 由 wrapper 直接接仲裁器。
//
//  ===== X 铁律 =====
//    复位后 4 表项 valid=0 门控仲裁输入; waitG[3:0] 索引恒在 [0,15]; 优先编码对齐 golden。
// =============================================================================
module xs_SourceB_core (
  input  logic        clock,
  input  logic        reset,

  // ---- io.task (Flipped DecoupledIO SourceBReq, MSHR 投来的 Probe 请求) ----
  output logic        io_task_ready,
  input  logic        io_task_valid,
  input  logic [30:0] io_task_bits_tag,
  input  logic [8:0]  io_task_bits_set,
  input  logic [2:0]  io_task_bits_opcode,
  input  logic [1:0]  io_task_bits_param,
  input  logic [1:0]  io_task_bits_alias,

  // ---- io.grantStatus (16 路在途 Grant 状态, 用于同地址冲突判定) ----
  input  logic        io_grantStatus_0_valid,  input  logic [8:0] io_grantStatus_0_set,  input  logic [30:0] io_grantStatus_0_tag,
  input  logic        io_grantStatus_1_valid,  input  logic [8:0] io_grantStatus_1_set,  input  logic [30:0] io_grantStatus_1_tag,
  input  logic        io_grantStatus_2_valid,  input  logic [8:0] io_grantStatus_2_set,  input  logic [30:0] io_grantStatus_2_tag,
  input  logic        io_grantStatus_3_valid,  input  logic [8:0] io_grantStatus_3_set,  input  logic [30:0] io_grantStatus_3_tag,
  input  logic        io_grantStatus_4_valid,  input  logic [8:0] io_grantStatus_4_set,  input  logic [30:0] io_grantStatus_4_tag,
  input  logic        io_grantStatus_5_valid,  input  logic [8:0] io_grantStatus_5_set,  input  logic [30:0] io_grantStatus_5_tag,
  input  logic        io_grantStatus_6_valid,  input  logic [8:0] io_grantStatus_6_set,  input  logic [30:0] io_grantStatus_6_tag,
  input  logic        io_grantStatus_7_valid,  input  logic [8:0] io_grantStatus_7_set,  input  logic [30:0] io_grantStatus_7_tag,
  input  logic        io_grantStatus_8_valid,  input  logic [8:0] io_grantStatus_8_set,  input  logic [30:0] io_grantStatus_8_tag,
  input  logic        io_grantStatus_9_valid,  input  logic [8:0] io_grantStatus_9_set,  input  logic [30:0] io_grantStatus_9_tag,
  input  logic        io_grantStatus_10_valid, input  logic [8:0] io_grantStatus_10_set, input  logic [30:0] io_grantStatus_10_tag,
  input  logic        io_grantStatus_11_valid, input  logic [8:0] io_grantStatus_11_set, input  logic [30:0] io_grantStatus_11_tag,
  input  logic        io_grantStatus_12_valid, input  logic [8:0] io_grantStatus_12_set, input  logic [30:0] io_grantStatus_12_tag,
  input  logic        io_grantStatus_13_valid, input  logic [8:0] io_grantStatus_13_set, input  logic [30:0] io_grantStatus_13_tag,
  input  logic        io_grantStatus_14_valid, input  logic [8:0] io_grantStatus_14_set, input  logic [30:0] io_grantStatus_14_tag,
  input  logic        io_grantStatus_15_valid, input  logic [8:0] io_grantStatus_15_set, input  logic [30:0] io_grantStatus_15_tag,

  // ---- 与 FastArbiter_6 黑盒对接 ----
  input  logic        arb_in_0_ready, arb_in_1_ready, arb_in_2_ready, arb_in_3_ready,
  output logic        arb_in_0_valid, arb_in_1_valid, arb_in_2_valid, arb_in_3_valid,
  output logic [30:0] arb_in_0_tag, arb_in_1_tag, arb_in_2_tag, arb_in_3_tag,
  output logic [8:0]  arb_in_0_set, arb_in_1_set, arb_in_2_set, arb_in_3_set,
  output logic [2:0]  arb_in_0_opcode, arb_in_1_opcode, arb_in_2_opcode, arb_in_3_opcode,
  output logic [1:0]  arb_in_0_param, arb_in_1_param, arb_in_2_param, arb_in_3_param,
  output logic [1:0]  arb_in_0_alias, arb_in_1_alias, arb_in_2_alias, arb_in_3_alias
);

  localparam int ENTRIES = 4;

  // probe 表项
  logic        probes_valid  [ENTRIES];
  logic        probes_rdy    [ENTRIES];
  logic [3:0]  probes_waitG  [ENTRIES];  // 4 位真实所需(索引 16 项), golden 冗余高 3 位为 cone-dead
  logic [30:0] probes_tag    [ENTRIES];
  logic [8:0]  probes_set    [ENTRIES];
  logic [2:0]  probes_opcode [ENTRIES];
  logic [1:0]  probes_param  [ENTRIES];
  logic [1:0]  probes_alias  [ENTRIES];

  // 16 路 grantStatus valid 打包 (按 waitG 索引)
  logic [15:0] gsValid;
  assign gsValid = {io_grantStatus_15_valid, io_grantStatus_14_valid, io_grantStatus_13_valid, io_grantStatus_12_valid,
                    io_grantStatus_11_valid, io_grantStatus_10_valid, io_grantStatus_9_valid,  io_grantStatus_8_valid,
                    io_grantStatus_7_valid,  io_grantStatus_6_valid,  io_grantStatus_5_valid,  io_grantStatus_4_valid,
                    io_grantStatus_3_valid,  io_grantStatus_2_valid,  io_grantStatus_1_valid,  io_grantStatus_0_valid};

  // ===== 同地址冲突判定 =====
  function automatic logic cmp(input logic v, input logic [8:0] s, input logic [30:0] t,
                               input logic [8:0] qs, input logic [30:0] qt);
    cmp = v & (s == qs) & (t == qt);
  endfunction
  logic [15:0] conflictMask;
  always_comb begin
    conflictMask[0]  = cmp(io_grantStatus_0_valid,  io_grantStatus_0_set,  io_grantStatus_0_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[1]  = cmp(io_grantStatus_1_valid,  io_grantStatus_1_set,  io_grantStatus_1_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[2]  = cmp(io_grantStatus_2_valid,  io_grantStatus_2_set,  io_grantStatus_2_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[3]  = cmp(io_grantStatus_3_valid,  io_grantStatus_3_set,  io_grantStatus_3_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[4]  = cmp(io_grantStatus_4_valid,  io_grantStatus_4_set,  io_grantStatus_4_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[5]  = cmp(io_grantStatus_5_valid,  io_grantStatus_5_set,  io_grantStatus_5_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[6]  = cmp(io_grantStatus_6_valid,  io_grantStatus_6_set,  io_grantStatus_6_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[7]  = cmp(io_grantStatus_7_valid,  io_grantStatus_7_set,  io_grantStatus_7_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[8]  = cmp(io_grantStatus_8_valid,  io_grantStatus_8_set,  io_grantStatus_8_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[9]  = cmp(io_grantStatus_9_valid,  io_grantStatus_9_set,  io_grantStatus_9_tag,  io_task_bits_set, io_task_bits_tag);
    conflictMask[10] = cmp(io_grantStatus_10_valid, io_grantStatus_10_set, io_grantStatus_10_tag, io_task_bits_set, io_task_bits_tag);
    conflictMask[11] = cmp(io_grantStatus_11_valid, io_grantStatus_11_set, io_grantStatus_11_tag, io_task_bits_set, io_task_bits_tag);
    conflictMask[12] = cmp(io_grantStatus_12_valid, io_grantStatus_12_set, io_grantStatus_12_tag, io_task_bits_set, io_task_bits_tag);
    conflictMask[13] = cmp(io_grantStatus_13_valid, io_grantStatus_13_set, io_grantStatus_13_tag, io_task_bits_set, io_task_bits_tag);
    conflictMask[14] = cmp(io_grantStatus_14_valid, io_grantStatus_14_set, io_grantStatus_14_tag, io_task_bits_set, io_task_bits_tag);
    conflictMask[15] = cmp(io_grantStatus_15_valid, io_grantStatus_15_set, io_grantStatus_15_tag, io_task_bits_set, io_task_bits_tag);
  end
  logic conflict;
  assign conflict = |conflictMask;

  // OHToUInt(conflictMask): one-hot → 4-bit 索引 (assert PopCount<=1 保证 one-hot)
  // golden waitG 声明为 sourceIdBits(7)位, 但仅低 4 位被读(索引 16 项 grantStatus),
  // 高 3 位恒为 OHToUInt 补零→死位. 本核化简 waitG 至真实所需 4 位(class-3 缩尺寸),
  // 使 impl clean; golden 冗余高位为 golden-only cone-dead。
  function automatic logic [3:0] oh16_to_idx(input logic [15:0] m);
    logic [3:0] r;
    r[0] = |(m & 16'b1010101010101010);
    r[1] = |(m & 16'b1100110011001100);
    r[2] = |(m & 16'b1111000011110000);
    r[3] = |(m & 16'b1111111100000000);
    oh16_to_idx = r;
  endfunction
  logic [3:0] waitG_new;
  assign waitG_new = oh16_to_idx(conflictMask);

  // ===== 分配 =====
  logic full, alloc;
  assign full = probes_valid[0] & probes_valid[1] & probes_valid[2] & probes_valid[3];
  assign io_task_ready = ~full;
  assign alloc = ~full & io_task_valid;
  // insertIdx = PriorityEncoder(~valid): 取最低无效表项
  logic [1:0] insertIdx;
  assign insertIdx = ~probes_valid[0] ? 2'h0 :
                     ~probes_valid[1] ? 2'h1 :
                     ~probes_valid[2] ? 2'h2 : 2'h3;

  // ===== 仲裁输入: valid = valid & rdy ; bits = task ; fire 时清表项 =====
  logic [ENTRIES-1:0] in_valid, in_ready, in_fire;
  assign in_valid = {probes_valid[3] & probes_rdy[3], probes_valid[2] & probes_rdy[2],
                     probes_valid[1] & probes_rdy[1], probes_valid[0] & probes_rdy[0]};
  assign in_ready = {arb_in_3_ready, arb_in_2_ready, arb_in_1_ready, arb_in_0_ready};
  assign in_fire  = in_valid & in_ready;

  assign {arb_in_3_valid, arb_in_2_valid, arb_in_1_valid, arb_in_0_valid} = in_valid;
  assign arb_in_0_tag = probes_tag[0]; assign arb_in_1_tag = probes_tag[1];
  assign arb_in_2_tag = probes_tag[2]; assign arb_in_3_tag = probes_tag[3];
  assign arb_in_0_set = probes_set[0]; assign arb_in_1_set = probes_set[1];
  assign arb_in_2_set = probes_set[2]; assign arb_in_3_set = probes_set[3];
  assign arb_in_0_opcode = probes_opcode[0]; assign arb_in_1_opcode = probes_opcode[1];
  assign arb_in_2_opcode = probes_opcode[2]; assign arb_in_3_opcode = probes_opcode[3];
  assign arb_in_0_param = probes_param[0]; assign arb_in_1_param = probes_param[1];
  assign arb_in_2_param = probes_param[2]; assign arb_in_3_param = probes_param[3];
  assign arb_in_0_alias = probes_alias[0]; assign arb_in_1_alias = probes_alias[1];
  assign arb_in_2_alias = probes_alias[2]; assign arb_in_3_alias = probes_alias[3];

  // per-entry alloc select (组合量, 单列 always_comb —— 勿放 always_ff 内否则被
  // FM 每 generate 迭代各推成死寄存器 allocK_reg)
  logic [ENTRIES-1:0] allocOH;
  always_comb begin
    for (int k = 0; k < ENTRIES; k++)
      allocOH[k] = alloc & (insertIdx == k[1:0]);
  end

  // ===== 时序更新 =====
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < ENTRIES; k++) begin
        probes_valid[k] <= 1'b0; probes_rdy[k] <= 1'b0; probes_waitG[k] <= 4'h0;
        probes_tag[k] <= '0; probes_set[k] <= '0; probes_opcode[k] <= '0;
        probes_param[k] <= '0; probes_alias[k] <= '0;
      end
    end else begin
      for (int k = 0; k < ENTRIES; k++) begin
        // valid: fire 清零; 否则 alloc 置位; 否则保持
        probes_valid[k] <= ~in_fire[k] & (allocOH[k] | probes_valid[k]);
        // rdy: 等待的 grantStatus 失效 → 置就绪(=1); 否则 alloc 时取 ~conflict, 否则保持
        probes_rdy[k] <= (probes_valid[k] & ~gsValid[probes_waitG[k]]) |
                         (allocOH[k] ? ~conflict : probes_rdy[k]);
        if (allocOH[k]) begin
          probes_waitG[k]  <= waitG_new;
          probes_tag[k]    <= io_task_bits_tag;
          probes_set[k]    <= io_task_bits_set;
          probes_opcode[k] <= io_task_bits_opcode;
          probes_param[k]  <= io_task_bits_param;
          probes_alias[k]  <= io_task_bits_alias;
        end
      end
    end
  end

endmodule
