// =============================================================================
// SCTable.sv —— SC（Statistical Corrector，统计校正器）的一张计数器表
//
// 在 BPU 里的位置：Tage_SC 内部有 4 张 SCTable（SCTable / _1 / _2 / _3），历史长度
// 分别为 0 / 4 / 10 / 16。TAGE 给出预测后，SC 把 4 张表里对应条目的有符号计数器
// 求和，与 TAGE provider 计数器一起和阈值比较，决定是否推翻 TAGE 的方向。
// 本模块只是"一张表"：s0 发读、s1 出两条分支 × 两路（按 TAGE 预测方向选路）的
// 6 位有符号计数器；update 口把上层算好的 oldCtr 做饱和 ±1 写回。
//
// 结构（对着 Chisel src/main/scala/xiangshan/frontend/SC.scala class SCTable 读）：
//   · 表 = 256 行 × 4 路（2 条分支槽 × {TAGE 预测不跳, 跳} 两路）× 6 位有符号计数器。
//     按行号最低位拆成 2 个 bank（SRAMTemplate_68，各 128 set × 4 way，单口、带复位清零），
//     bank 号 = idx[0]，bank 内 set = idx[7:1]。
//   · 行号 idx = ((pc >> 1) ^ 折叠历史)[7:0]；HIST_LEN=0 的那张不异或历史。
//     读用上层送来的折叠历史（io_req_bits_folded_hist_*），写用 update.ghist 现场折叠。
//   · 分支槽"物理/逻辑"换位：一个取指块里两条分支槽的物理位置按 pc[1] 交换
//     （get_phy_br_idx = lidx ^ pc[1]）。读出时按 s1_pc[1] 换回逻辑顺序，
//     写入时按 update_pc[1] 换到物理顺序。★注意：这里用的是未哈希的 pc[1]，
//     而 bank 选择用的是哈希后的 idx[0]——两者在 HIST_LEN>0 的表里不是同一位，照搬★。
//   · 读写冲突：单口 SRAM 同拍写优先，被写 bank 的读请求作废；s0 记下
//     "本拍读的 bank 正在被写"，s1 把输出计数器全部清 0（等价于"不提供信息"）。
//   · 写旁路：每条逻辑分支一份 WrBypass_33（16 项，按 8 位行号 CAM，每项 2 路），
//     连续更新同一行时用旁路里的最新值代替 update.oldCtrs（后者是预测时读到的旧值）。
//
// 流水：
//   §1 s0 —— 算行号/bank，发 SRAM 读；判本拍读写冲突。
//   §2 s1 —— 选 bank、换回逻辑分支顺序、冲突则清零 -> io_resp_ctrs。
//   §3 update —— 算物理路掩码、旧值（旁路优先）饱和 ±1、写 SRAM 与写旁路。
//
// 复位域（与 golden 逐一对齐）：s1_idx / s1_resp_invalid_by_conflict / s1_pc 都是
// RegEnable(io.req.valid)，无复位。★s1_pc 存满 50 位但只有 [1] 被读★（golden 就是这样），
// 其余 49 位两侧都是无读者的死寄存器，照搬不删（FM 侧走 vmucp 对称死位证明）。
//
// 本文件：package sctable_pkg + 参数化核 xs_SCTable_core + 历史长度 0 那一档的
// golden 同名 wrapper SCTable。另外三档的薄 wrapper 在 SCTable_1/_2/_3.sv。
// wrapper 只做端口展平与 MBIST 流水（MbistPipeSc_N，各档只差 MBIST 阵列编号）例化，
// 由 scripts/gen_sctable.py 从 G1 golden 端口表生成（GENERATED 区）。
// =============================================================================
package sctable_pkg;

  localparam int unsigned CTR_W   = 6;     // SC 计数器位宽（有符号）
  localparam int unsigned IDX_W   = 8;     // 行号位宽：256 行
  localparam int unsigned SET_W   = 7;     // bank 内 set 号：128 set
  localparam int unsigned NUM_BR  = 2;     // 每个取指块的分支槽数
  localparam int unsigned NUM_BANK = 2;

  // MBIST 流水送到一个 SRAM 的测试口（MbistPipeSc_N.toSRAM_k_* 方向）
  typedef struct packed {
    logic [7:0]  addr;
    logic [7:0]  addr_rd;
    logic [23:0] wdata;
    logic [3:0]  wmask;
    logic        re;
    logic        we;
    logic        ack;
    logic        selectedOH;
    logic [6:0]  array;
  } sc_mbist_req_t;

  // SRAM 宏的广播控制位（sigFromSrams_bore_*）
  typedef struct packed {
    logic ram_hold;
    logic ram_bypass;
    logic ram_bp_clken;
    logic ram_aux_clk;
    logic ram_aux_ckbp;
    logic ram_mcp_hold;
    logic cgen;
  } sc_sram_bcast_t;

  // 6 位有符号饱和计数器 ±1（BPU.scala signedSatUpdate）：
  // 已在 +31 且跳 -> 停在 +31；已在 -32 且不跳 -> 停在 -32；否则跳 +1 / 不跳 -1。
  function automatic logic [CTR_W-1:0] sat_update(input logic [CTR_W-1:0] old, input logic taken);
    if (old == 6'h1F && taken)       return 6'h1F;
    else if (old == 6'h20 && !taken) return 6'h20;
    else if (taken)                  return old + 6'd1;
    else                             return old - 6'd1;
  endfunction

endpackage

module xs_SCTable_core
  import sctable_pkg::*;
#(
  parameter int unsigned HIST_LEN = 0,                               // 本表用多长的全局历史
  parameter int unsigned FH_W     = (HIST_LEN < 8) ? HIST_LEN : 8,   // 折叠后位宽 = min(8, HIST_LEN)
  parameter int unsigned FH_PORT_W = (FH_W == 0) ? 1 : FH_W          // 端口至少 1 位（HIST_LEN=0 时不读）
)(
  input  logic                  clock,
  input  logic                  reset,
  // ---- 预测读 ----
  input  logic                  req_valid,
  input  logic [49:0]           req_pc,
  input  logic [FH_PORT_W-1:0]  req_folded_hist,
  output logic [CTR_W-1:0]      resp_ctrs [NUM_BR][2],    // [逻辑分支][0:TAGE 预测不跳 / 1:跳]
  // ---- 更新 ----
  input  logic [49:0]           update_pc,
  input  logic [255:0]          update_ghist,
  input  logic [NUM_BR-1:0]     update_mask,
  input  logic [CTR_W-1:0]      update_old_ctrs [NUM_BR],
  input  logic [NUM_BR-1:0]     update_tage_preds,
  input  logic [NUM_BR-1:0]     update_takens,
  // ---- 两个 SRAM bank 的 MBIST / 广播口（由 wrapper 接 MbistPipeSc_N）----
  input  sc_mbist_req_t         mbist_req   [NUM_BANK],
  output logic [23:0]           mbist_rdata [NUM_BANK],
  input  sc_sram_bcast_t        sram_bcast  [NUM_BANK]
);

  // 行号 = ((pc >> 1) ^ 折叠历史)[7:0]
  function automatic logic [IDX_W-1:0] row_index(input logic [49:0] pc, input logic [7:0] fh);
    return pc[IDX_W:1] ^ fh;
  endfunction

  // compute_folded_ghist(ghist, 8)：取低 HIST_LEN 位，按 8 位一段异或折叠
  function automatic logic [7:0] fold_ghist(input logic [255:0] ghist);
    logic [7:0] acc;
    acc = '0;
    for (int unsigned i = 0; i < HIST_LEN; i++)
      acc[i % 8] = acc[i % 8] ^ ghist[i];
    return acc;
  endfunction

  // 预测读用的折叠历史（上层已折好），零扩到 8 位
  logic [7:0] req_fh;
  if (HIST_LEN == 0) begin : g_no_hist
    assign req_fh = '0;
  end else begin : g_hist
    assign req_fh = 8'(req_folded_hist);
  end

  // ---------------------------------------------------------------------------
  // SRAM 与写旁路的连线
  // ---------------------------------------------------------------------------
  logic                bank_rd_valid [NUM_BANK];
  logic [SET_W-1:0]    bank_rd_set;
  logic [CTR_W-1:0]    bank_rd_data  [NUM_BANK][2*NUM_BR];   // [bank][物理路 = 2*物理分支 + 方向]
  logic                bank_wr_valid [NUM_BANK];
  logic [SET_W-1:0]    bank_wr_set;
  logic [CTR_W-1:0]    wr_data_phys  [NUM_BR];               // 按物理分支槽排的新计数器
  logic [2*NUM_BR-1:0] wr_way_mask;                          // 物理路写掩码

  logic                byp_hit       [NUM_BR];               // 按逻辑分支
  logic                byp_valid     [NUM_BR][2];
  logic [CTR_W-1:0]    byp_ctr       [NUM_BR][2];

  // ===========================================================================
  // §1 s0：算行号与 bank，发 SRAM 读；判"本拍读的 bank 正被写"
  // ===========================================================================
  logic [IDX_W-1:0] s0_idx;
  logic             s0_bank;
  logic             s0_invalid_by_conflict;

  assign s0_idx      = row_index(req_pc, req_fh);
  assign s0_bank     = s0_idx[0];
  assign bank_rd_set = s0_idx[IDX_W-1:1];
  for (genvar b = 0; b < NUM_BANK; b++) begin : g_rd_valid
    assign bank_rd_valid[b] = req_valid && (s0_bank == 1'(b));
  end
  // 单口 SRAM 写优先：本拍要读的那个 bank 若同时在写，读出无效
  assign s0_invalid_by_conflict = bank_wr_valid[s0_bank];

  // ===========================================================================
  // §2 s1：选 bank、换回逻辑分支顺序、冲突清零
  // ===========================================================================
  logic [IDX_W-1:0] s1_idx;
  logic             s1_resp_invalid_by_conflict;
  logic [49:0]      s1_pc;                     // 只读 [1]；其余位照 golden 存着

  always_ff @(posedge clock) begin
    if (req_valid) begin
      s1_idx                      <= s0_idx;
      s1_resp_invalid_by_conflict <= s0_invalid_by_conflict;
      s1_pc                       <= req_pc;
    end
  end

  for (genvar br = 0; br < NUM_BR; br++) begin : g_resp
    // 逻辑分支 br 在物理槽 br ^ pc[1]
    logic phys_br;
    assign phys_br = 1'(br) ^ s1_pc[1];
    for (genvar dir = 0; dir < 2; dir++) begin : g_dir
      assign resp_ctrs[br][dir] = s1_resp_invalid_by_conflict
                                    ? '0
                                    : bank_rd_data[s1_idx[0]][2*phys_br + dir];
    end
  end

  // ===========================================================================
  // §3 update：物理路掩码 -> 旧值（旁路优先）-> 饱和 ±1 -> 写 SRAM / 写旁路
  // ===========================================================================
  logic [IDX_W-1:0] update_idx;
  logic             update_bank;
  logic             update_any;

  assign update_idx  = row_index(update_pc, fold_ghist(update_ghist));
  assign update_bank = update_idx[0];
  assign update_any  = |update_mask;
  assign bank_wr_set = update_idx[IDX_W-1:1];
  for (genvar b = 0; b < NUM_BANK; b++) begin : g_wr_valid
    assign bank_wr_valid[b] = update_any && (update_bank == 1'(b));
  end

  // 物理路 2*pi+dir 被写 <=> 有某条逻辑分支 li 要更新、它落在物理槽 pi、TAGE 预测方向 = dir
  for (genvar pi = 0; pi < NUM_BR; pi++) begin : g_way_mask
    for (genvar dir = 0; dir < 2; dir++) begin : g_dir
      always_comb begin
        wr_way_mask[2*pi + dir] = 1'b0;
        for (int li = 0; li < NUM_BR; li++)
          if (update_mask[li] && ((1'(li) ^ update_pc[1]) == 1'(pi)) && (update_tage_preds[li] == 1'(dir)))
            wr_way_mask[2*pi + dir] = 1'b1;
      end
    end
  end

  // 每个物理槽：找到落在这里的逻辑分支，取它的旧值（写旁路命中且该路有效则用旁路值）
  for (genvar pi = 0; pi < NUM_BR; pi++) begin : g_wdata
    logic             lidx;
    logic             ctr_pos;
    logic [CTR_W-1:0] old_ctr;
    assign lidx    = 1'(pi) ^ update_pc[1];
    assign ctr_pos = update_tage_preds[lidx];
    assign old_ctr = (byp_hit[lidx] && byp_valid[lidx][ctr_pos]) ? byp_ctr[lidx][ctr_pos]
                                                                 : update_old_ctrs[lidx];
    assign wr_data_phys[pi] = sat_update(old_ctr, update_takens[lidx]);
  end

  // ---------------------------------------------------------------------------
  // 两个 SRAM bank：同一份写数据（每个物理槽复制到两路）、同一个写掩码
  // ---------------------------------------------------------------------------
  for (genvar b = 0; b < NUM_BANK; b++) begin : g_bank
    SRAMTemplate_68 u_table (
      .clock                          (clock),
      .reset                          (reset),
      .io_r_req_valid                 (bank_rd_valid[b]),
      .io_r_req_bits_setIdx           (bank_rd_set),
      .io_r_resp_data_0               (bank_rd_data[b][0]),
      .io_r_resp_data_1               (bank_rd_data[b][1]),
      .io_r_resp_data_2               (bank_rd_data[b][2]),
      .io_r_resp_data_3               (bank_rd_data[b][3]),
      .io_w_req_valid                 (bank_wr_valid[b]),
      .io_w_req_bits_setIdx           (bank_wr_set),
      .io_w_req_bits_data_0           (wr_data_phys[0]),
      .io_w_req_bits_data_1           (wr_data_phys[0]),
      .io_w_req_bits_data_2           (wr_data_phys[1]),
      .io_w_req_bits_data_3           (wr_data_phys[1]),
      .io_w_req_bits_waymask          (wr_way_mask),
      .io_broadcast_ram_hold          (sram_bcast[b].ram_hold),
      .io_broadcast_ram_bypass        (sram_bcast[b].ram_bypass),
      .io_broadcast_ram_bp_clken      (sram_bcast[b].ram_bp_clken),
      .io_broadcast_ram_aux_clk       (sram_bcast[b].ram_aux_clk),
      .io_broadcast_ram_aux_ckbp      (sram_bcast[b].ram_aux_ckbp),
      .io_broadcast_ram_mcp_hold      (sram_bcast[b].ram_mcp_hold),
      .io_broadcast_ram_ctl           (64'h0),
      .io_broadcast_cgen              (sram_bcast[b].cgen),
      .boreChildrenBd_bore_addr       (mbist_req[b].addr),
      .boreChildrenBd_bore_addr_rd    (mbist_req[b].addr_rd),
      .boreChildrenBd_bore_wdata      (mbist_req[b].wdata),
      .boreChildrenBd_bore_wmask      (mbist_req[b].wmask),
      .boreChildrenBd_bore_re         (mbist_req[b].re),
      .boreChildrenBd_bore_we         (mbist_req[b].we),
      .boreChildrenBd_bore_rdata      (mbist_rdata[b]),
      .boreChildrenBd_bore_ack        (mbist_req[b].ack),
      .boreChildrenBd_bore_selectedOH (mbist_req[b].selectedOH),
      .boreChildrenBd_bore_array      (mbist_req[b].array)
    );
  end

  // ---------------------------------------------------------------------------
  // 写旁路：按逻辑分支一份；写入的是该分支所在物理槽的新值与路掩码
  // ---------------------------------------------------------------------------
  for (genvar li = 0; li < NUM_BR; li++) begin : g_wrbypass
    logic pidx;
    assign pidx = 1'(li) ^ update_pc[1];
    WrBypass_33 u_wrbypass (
      .clock               (clock),
      .reset               (reset),
      .io_wen              (update_mask[li]),
      .io_write_idx        (update_idx),
      .io_write_data_0     (wr_data_phys[pidx]),
      .io_write_data_1     (wr_data_phys[pidx]),
      .io_write_way_mask_0 (wr_way_mask[2*pidx]),
      .io_write_way_mask_1 (wr_way_mask[2*pidx + 1]),
      .io_hit              (byp_hit[li]),
      .io_hit_data_0_valid (byp_valid[li][0]),
      .io_hit_data_0_bits  (byp_ctr[li][0]),
      .io_hit_data_1_valid (byp_valid[li][1]),
      .io_hit_data_1_bits  (byp_ctr[li][1])
    );
  end

endmodule

// BEGIN GENERATED(sctable_wrapper) —— scripts/gen_sctable.py 生成，勿手改
module SCTable
  import sctable_pkg::*;
(
  input  clock,
  input  reset,
  input  io_req_valid,
  input  [49:0] io_req_bits_pc,
  output [5:0] io_resp_ctrs_0_0,
  output [5:0] io_resp_ctrs_0_1,
  output [5:0] io_resp_ctrs_1_0,
  output [5:0] io_resp_ctrs_1_1,
  input  [49:0] io_update_pc,
  input  io_update_mask_0,
  input  io_update_mask_1,
  input  [5:0] io_update_oldCtrs_0,
  input  [5:0] io_update_oldCtrs_1,
  input  io_update_tagePreds_0,
  input  io_update_tagePreds_1,
  input  io_update_takens_0,
  input  io_update_takens_1,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [3:0] boreChildrenBd_bore_be,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [23:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  output [23:0] boreChildrenBd_bore_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen
);

  logic [CTR_W-1:0] resp_ctrs [NUM_BR][2];
  logic [CTR_W-1:0] update_old_ctrs [NUM_BR];
  sc_mbist_req_t    mbist_req   [NUM_BANK];
  logic [23:0]      mbist_rdata [NUM_BANK];
  sc_sram_bcast_t   sram_bcast  [NUM_BANK];

  // SRAM 宏广播控制位：bank 0 = sigFromSrams_bore_*，bank 1 = sigFromSrams_bore_1_*
  assign sram_bcast[0] = '{
    ram_hold: sigFromSrams_bore_ram_hold,
    ram_bypass: sigFromSrams_bore_ram_bypass,
    ram_bp_clken: sigFromSrams_bore_ram_bp_clken,
    ram_aux_clk: sigFromSrams_bore_ram_aux_clk,
    ram_aux_ckbp: sigFromSrams_bore_ram_aux_ckbp,
    ram_mcp_hold: sigFromSrams_bore_ram_mcp_hold,
    cgen: sigFromSrams_bore_cgen
  };
  assign sram_bcast[1] = '{
    ram_hold: sigFromSrams_bore_1_ram_hold,
    ram_bypass: sigFromSrams_bore_1_ram_bypass,
    ram_bp_clken: sigFromSrams_bore_1_ram_bp_clken,
    ram_aux_clk: sigFromSrams_bore_1_ram_aux_clk,
    ram_aux_ckbp: sigFromSrams_bore_1_ram_aux_ckbp,
    ram_mcp_hold: sigFromSrams_bore_1_ram_mcp_hold,
    cgen: sigFromSrams_bore_1_cgen
  };
  assign update_old_ctrs[0] = io_update_oldCtrs_0;
  assign update_old_ctrs[1] = io_update_oldCtrs_1;

  xs_SCTable_core #(
    .HIST_LEN (0)
  ) u_core (
    .clock             (clock),
    .reset             (reset),
    .req_valid         (io_req_valid),
    .req_pc            (io_req_bits_pc),
    .req_folded_hist   (1'b0),
    .resp_ctrs         (resp_ctrs),
    .update_pc         (io_update_pc),
    .update_ghist      (256'h0),
    .update_mask       ({io_update_mask_1, io_update_mask_0}),
    .update_old_ctrs   (update_old_ctrs),
    .update_tage_preds ({io_update_tagePreds_1, io_update_tagePreds_0}),
    .update_takens     ({io_update_takens_1, io_update_takens_0}),
    .mbist_req         (mbist_req),
    .mbist_rdata       (mbist_rdata),
    .sram_bcast        (sram_bcast)
  );

  assign io_resp_ctrs_0_0 = resp_ctrs[0][0];
  assign io_resp_ctrs_0_1 = resp_ctrs[0][1];
  assign io_resp_ctrs_1_0 = resp_ctrs[1][0];
  assign io_resp_ctrs_1_1 = resp_ctrs[1][1];

  // MBIST 流水：把顶层 boreChildrenBd 测试口分发到两个 SRAM bank
  MbistPipeSc mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (boreChildrenBd_bore_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr       (mbist_req[0].addr),
    .toSRAM_0_addr_rd    (mbist_req[0].addr_rd),
    .toSRAM_0_wdata      (mbist_req[0].wdata),
    .toSRAM_0_wmask      (mbist_req[0].wmask),
    .toSRAM_0_re         (mbist_req[0].re),
    .toSRAM_0_we         (mbist_req[0].we),
    .toSRAM_0_ack        (mbist_req[0].ack),
    .toSRAM_0_selectedOH (mbist_req[0].selectedOH),
    .toSRAM_0_array      (mbist_req[0].array),
    .toSRAM_0_rdata      (mbist_rdata[0]),
    .toSRAM_1_addr       (mbist_req[1].addr),
    .toSRAM_1_addr_rd    (mbist_req[1].addr_rd),
    .toSRAM_1_wdata      (mbist_req[1].wdata),
    .toSRAM_1_wmask      (mbist_req[1].wmask),
    .toSRAM_1_re         (mbist_req[1].re),
    .toSRAM_1_we         (mbist_req[1].we),
    .toSRAM_1_ack        (mbist_req[1].ack),
    .toSRAM_1_selectedOH (mbist_req[1].selectedOH),
    .toSRAM_1_array      (mbist_req[1].array),
    .toSRAM_1_rdata      (mbist_rdata[1])
  );

endmodule
// END GENERATED(sctable_wrapper)
