// =============================================================================
// TageBTable —— TAGE 的「基预测器」(bimodal base table)
//
// 对应 Chisel: xiangshan.frontend.TageBTable（Tage.scala，class TageBTable）
//
// 【它在 BPU 的位置】
//   TAGE = 1 个基预测器 + N 张标签表(TageTable)。基预测器就是本模块：一张按 PC 直接索引的
//   2bit 饱和计数器表，给出"默认方向"。当所有 TageTable 都不命中时，用基预测器的方向(altpred)。
//
// 【结构】
//   - 2048 行 × 2 way × 2bit。每次预测取一行的 2 个计数器，对应一个取指块里的 2 个分支槽。
//   - 索引 = PC[11:1]（11 位 = 2048 行）。读延迟 1 拍，故把读索引寄存成 s1_idx。
//   - **分支槽↔物理way 交织**：用 PC[1]（即 idx[0]）决定逻辑分支槽映射到哪个物理 way：
//        物理 way w  ←→  逻辑分支槽 (w ^ pc_bit)
//     （让相邻取指块的同号分支落到不同 way，减少别名冲突）。读出与写入两侧都按此交织。
//   - **2bit 饱和计数**：taken 则 +1（封顶 3），not-taken 则 -1（封底 0）；最高位即方向。
//   - **WrBypass 写旁路**：更新与读取/再更新可能撞在同一行同一拍（SRAM 1 拍延迟），
//     用 WrBypass 缓存最近写入的计数值，使"读到的旧值 oldCtr"优先取旁路里的最新值。
//   - **上电清零**：doing_reset 期间逐行写 2'b10（弱 taken）作为初值。
//
// 存储 FoldedSRAMTemplate_20 与 WrBypass_32 为已验证子模块（FM 当黑盒）。
// =============================================================================
module TageBTable(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [49:0] io_req_bits,            // 预测请求 PC
  output [1:0]  io_s1_cnt_0,            // s1 读出：分支槽 0 的 2bit 计数
  output [1:0]  io_s1_cnt_1,            // s1 读出：分支槽 1
  input         io_update_mask_0,       // 更新：各槽是否更新
  input         io_update_mask_1,
  input  [49:0] io_update_pc,
  input  [1:0]  io_update_cnt_0,        // 更新：各槽的旧计数（来自 commit）
  input  [1:0]  io_update_cnt_1,
  input         io_update_takens_0,     // 更新：各槽的真实方向
  input         io_update_takens_1,
  input  [8:0]  boreChildrenBd_bore_addr, boreChildrenBd_bore_addr_rd,
  input  [15:0] boreChildrenBd_bore_wdata,
  input  [7:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re, boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack, boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array,
  input  [8:0]  boreChildrenBd_bore_1_addr, boreChildrenBd_bore_1_addr_rd,
  input  [15:0] boreChildrenBd_bore_1_wdata,
  input  [7:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re, boreChildrenBd_bore_1_we,
  output [15:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack, boreChildrenBd_bore_1_selectedOH,
  input  [6:0]  boreChildrenBd_bore_1_array,
  input         sigFromSrams_bore_ram_hold, sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken, sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp, sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold, sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken, sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen
);
  // ---- 上电清零：逐行（0..2047）写弱 taken 初值 ----
  reg         doing_reset;
  reg  [10:0] resetRow;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin doing_reset <= 1'b1; resetRow <= 11'h0; end
    else begin
      doing_reset <= (resetRow != 11'h7FF) & doing_reset;
      resetRow    <= resetRow + {10'h0, doing_reset};
    end
  end
  assign io_req_ready = ~doing_reset;

  // ---- 索引：PC[11:1]；读索引寄存一拍对齐 SRAM 读延迟 ----
  wire [10:0] r_idx = io_req_bits[11:1];
  wire [10:0] w_idx = io_update_pc[11:1];
  reg  [10:0] s1_idx;
  always_ff @(posedge clock) if (io_req_valid) s1_idx <= r_idx;

  // ---- 2bit 饱和计数器更新（纯函数）----
  function automatic logic [1:0] sat_update(input logic [1:0] c, input logic taken);
    if (taken) sat_update = (&c)      ? c : c + 2'h1;
    else       sat_update = (c == '0) ? c : c - 2'h1;
  endfunction

  // ---- 把更新输入收进按"逻辑分支槽"索引的数组 ----
  wire        upc_bit = io_update_pc[1];          // 决定 slot↔way 交织
  wire        upd_mask  [2]; assign upd_mask[0]  = io_update_mask_0;  assign upd_mask[1]  = io_update_mask_1;
  wire [1:0]  upd_cnt   [2]; assign upd_cnt[0]   = io_update_cnt_0;   assign upd_cnt[1]   = io_update_cnt_1;
  wire        upd_taken [2]; assign upd_taken[0] = io_update_takens_0;assign upd_taken[1] = io_update_takens_1;

  // ---- WrBypass 命中数据（按逻辑分支槽）----
  wire        wb_hit;
  wire        wb_valid [2];
  wire [1:0]  wb_bits  [2];

  // ---- 按物理 way 计算 new 计数；物理 way w 对应逻辑槽 (w ^ upc_bit) ----
  wire [1:0]  newCtr [2];
  wire        phys_waymask_arr [2];   // 每物理 way 1 位写使能
  genvar w;
  generate for (w = 0; w < 2; w++) begin : g_way
    wire        slot   = w[0] ^ upc_bit;                       // 该物理 way 服务的逻辑分支槽
    // 旧值优先取 WrBypass 里最近写入值，否则取 commit 传入的旧计数
    wire [1:0]  oldCtr = (wb_hit & wb_valid[slot]) ? wb_bits[slot] : upd_cnt[slot];
    assign newCtr[w]          = sat_update(oldCtr, upd_taken[slot]);
    assign phys_waymask_arr[w] = upd_mask[slot];               // 该 way 是否被本次更新写
  end endgenerate
  wire [1:0] phys_waymask = {phys_waymask_arr[1], phys_waymask_arr[0]};
  wire       any_update   = io_update_mask_0 | io_update_mask_1;

  // ---- 存储：FoldedSRAMTemplate_20（2048×2×2，内部折叠到 Splitted_23）----
  wire [1:0] bt_rd_0, bt_rd_1;
  FoldedSRAMTemplate_20 bt (
    .clock(clock), .reset(reset),
    .io_r_req_valid(io_req_valid), .io_r_req_bits_setIdx(r_idx),
    .io_r_resp_data_0(bt_rd_0), .io_r_resp_data_1(bt_rd_1),
    .io_w_req_valid(any_update | doing_reset),
    .io_w_req_bits_setIdx(doing_reset ? resetRow : w_idx),
    .io_w_req_bits_data_0(doing_reset ? 2'h2 : newCtr[0]),
    .io_w_req_bits_data_1(doing_reset ? 2'h2 : newCtr[1]),
    .io_w_req_bits_waymask(doing_reset ? 2'h3 : phys_waymask),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen)
  );

  // ---- 写旁路：缓存最近写入计数（按逻辑分支槽存）----
  WrBypass_32 wrbypass (
    .clock(clock), .reset(reset),
    .io_wen(any_update),
    .io_write_idx(w_idx),
    .io_write_data_0(upc_bit ? newCtr[1] : newCtr[0]),  // slot0 ← 物理 way (0^upc_bit)=way upc_bit
    .io_write_data_1(upc_bit ? newCtr[0] : newCtr[1]),  // slot1 ← 物理 way (1^upc_bit)
    .io_write_way_mask_0(io_update_mask_0),
    .io_write_way_mask_1(io_update_mask_1),
    .io_hit(wb_hit),
    .io_hit_data_0_valid(wb_valid[0]), .io_hit_data_0_bits(wb_bits[0]),
    .io_hit_data_1_valid(wb_valid[1]), .io_hit_data_1_bits(wb_bits[1])
  );

  // ---- 读响应：按 s1_idx[0] 把物理 way 反交织回逻辑分支槽 ----
  assign io_s1_cnt_0 = s1_idx[0] ? bt_rd_1 : bt_rd_0;
  assign io_s1_cnt_1 = s1_idx[0] ? bt_rd_0 : bt_rd_1;
endmodule
