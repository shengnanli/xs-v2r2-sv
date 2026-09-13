// =============================================================================
// TageBTable.sv —— TAGE 方向预测器的「基预测器」(base / bimodal table)
//
// 对应 Chisel: xiangshan.frontend.TageBTable (Tage.scala, class TageBTable)
// 本文件含: package tage_btable_pkg → xs_TageBTable_core → golden 同名 wrapper TageBTable
//
// 【它在前端预测流水里的位置】
//   香山 BPU 是「多组件覆盖式(overriding)」预测器: uFTB/FTB 出 s1 快速预测,
//   TAGE-SC 与 ITTAGE 在 s2/s3 用更长历史覆盖它。TAGE 本身 =
//        1 个基预测器 (本模块) + 4 张带 tag 的历史表 (TageTable/_1/_2/_3)
//   4 张标签表按几何递增的历史长度索引; 只要有一张命中, 它就当 provider 出方向。
//   **一张都不命中时, 方向就由本模块给出** —— 所以它是 TAGE 的兜底 (altpred 之底),
//   也是刚上电、历史尚未训练起来时唯一有效的预测来源。
//
//        s0: io_req(pc) ──idx=pc[11:1]──▶ 选 bank, 读 SRAM ──┐
//                                                            ▼ s1
//                                    io_s1_cnt[2] (两条分支槽各一个 2 位计数器)
//                                    io_s1_resp_valid (本拍读是否有效)
//        commit: io_update_{pc,mask,cnt,takens} ──▶ 饱和计数 ±1 ──▶ 写回 SRAM
//
// 【表怎么索引】
//   BtSize = 2048 项, 每项 = numBr(=2) 个 2 位饱和计数器 —— 一个取指块最多预测
//   2 条条件分支, 两条各占一个 way。索引不含任何历史 (这正是"bimodal"的含义):
//        idx = pc[11:1]                  (log2(2048)=11 位, instOffsetBits=1 因为有 RVC)
//   物理上 2048 项拆成 nBanks=2 个 bank, 各 1024 项:
//        bank = idx[0]  (= pc[1])        row = idx[10:1] (= pc[11:2])
//   每个 bank 是一块 FoldedSRAMTemplate_20 (单口, 512 深 × 折叠 2 → 1024 行 × 2 way)。
//
// 【为什么要分 bank —— 本轮 G1 相对 G0 的真实改动】
//   SRAM 是**单口**的: 同一拍读和写只能二选一。G0 里 base table 是一整块 SRAM,
//   任何一次更新都会挡住那一拍的预测读。G1 把它按 idx[0] 拆成两个 bank:
//   读 bank 与写 bank 不同就互不干扰, 只有落到同一个 bank 才冲突。冲突时不阻塞流水,
//   而是让这次读作废 —— 这就是新增的 io_s1_resp_valid 端口:
//        s0_invalid_by_conflict = 「本拍要读的 bank 正在被写」
//        io_s1_resp_valid       = ~RegEnable(s0_invalid_by_conflict, s0_fire)
//   上层看到 s1_resp_valid=0 就知道这拍基预测不可信 (Chisel 侧还记了一个
//   tage_base_table_bank_conflict 性能计数器)。
//   G0→G1 端口表因此多了 io_s1_resp_valid, 且 MBIST bore 组从 2 组变 4 组
//   (bt 由 1 块变 2 块, 每块 2 个物理 SRAM), wdata/wmask 位宽随之减半。
//
// 【什么时候更新 / 更新什么】
//   指令提交时上层送来 update_pc + 每条分支槽的 (mask, cnt, takens):
//     - mask[l] : 这条槽这次要不要更新
//     - cnt[l]  : 预测时读到的旧计数 (上层带下来的)
//     - takens[l]: 实际方向
//   新值 = 2 位饱和更新: taken 则 +1 封顶 3, not-taken 则 -1 封底 0。
//   写回时 setIdx = update_pc[11:2], waymask 只打开被更新的那 (些) way。
//
// 【两个必须照搬的细节】
//   1) 上电清表 (doing_reset/resetRow): SRAM 没有复位, 所以复位后自己扫 1024 行,
//      每行两个 way 都写成 2'b2 = **弱 taken**。扫表期间 io_req_ready=0, 上层不许发请求;
//      扫表的写占用了两个 bank 的写口, 因此 doing_reset 也算进 bank 写使能。
//   2) 逻辑槽 ⇄ 物理 way 的重排 (get_phy_br_idx): phy = idx[0] ^ lgc。
//      也就是 idx[0]=1 的取指块把两条分支槽在 SRAM 里对调存放。目的是别让"第 0 条分支"
//      永远压在 way0 上 —— 相邻取指块错开, 两个 way 的利用率更均衡。异或自反, 读回时
//      用同一个式子还原。注意 WrBypass 存的是**逻辑槽**视角, SRAM 存的是**物理 way**
//      视角, 两侧各转一次, 转错就是静默的预测质量下降 (功能仿真不一定看得出来)。
//
// 【写旁路 WrBypass_32】
//   连续两次更新同一 idx 时, 第一次的写还没能被第二次的"读旧值"看到 (上层送来的 cnt
//   是预测时刻的陈旧值)。WrBypass 是一个 8 项小 CAM, 按 idx 记住最近写下去的计数,
//   命中就用它当 old_ctr, 保证连续更新按序累加而不是互相覆盖。
//
// 【子模块 (本目标之外, 各自独立签核)】
//   FoldedSRAMTemplate_20 × 2  —— 计数器阵列, 每 bank 一块 (WORKING_PASS)
//   WrBypass_32           × 1  —— 8 项写旁路 CAM (REVALIDATED_PASS)
//   bore*/sigFromSrams* 端口是 MBIST/DFT 旁路与时钟控制, 对功能无影响, 原样透传给 SRAM。
// =============================================================================

package tage_btable_pkg;
  // ---- 规模 (Tage.scala: trait TBTParams / class TageBTable) ----
  localparam int unsigned PC_W        = 50;                   // VAddrBits
  localparam int unsigned INST_OFF    = 1;                     // instOffsetBits (RVC → 2 字节)
  localparam int unsigned BT_SIZE     = 2048;                  // BtSize: 表项总数
  localparam int unsigned NUM_BR      = 2;                     // 一个取指块的分支槽数
  localparam int unsigned N_BANKS     = 2;                     // 物理 bank 数
  localparam int unsigned CTR_W       = 2;                     // 饱和计数器位宽
  localparam int unsigned IDX_W       = 11;                    // log2(BT_SIZE)
  localparam int unsigned ROW_W       = 10;                    // log2(BT_SIZE/N_BANKS)
  localparam int unsigned SRAM_SPLITS = 2;                     // 每 bank 的物理 SRAM 数(setSplit=2)

  // 上电清表写入的初值: 2'b10 = 弱 taken
  localparam logic [CTR_W-1:0] CTR_WEAK_TAKEN = 2'd2;
  // 清表扫到的最后一行
  localparam logic [ROW_W-1:0] ROW_LAST       = ROW_W'(BT_SIZE/N_BANKS - 1);

  // ---- MBIST bore 旁路的位宽 (由 FoldedSRAMTemplate_20 的端口定死) ----
  localparam int unsigned BORE_AW   = 9;
  localparam int unsigned BORE_DW   = 8;
  localparam int unsigned BORE_MW   = 4;
  localparam int unsigned BORE_ARRW = 7;
endpackage


// -----------------------------------------------------------------------------
// 可读核
// -----------------------------------------------------------------------------
module xs_TageBTable_core
  import tage_btable_pkg::*;
(
  input  logic                   clock,
  input  logic                   reset,

  // ---- s0 预测请求 (Decoupled, ready 只在上电清表期间拉低) ----
  output logic                   io_req_ready,
  input  logic                   io_req_valid,
  input  logic [PC_W-1:0]        io_req_bits,                 // s0_pc

  // ---- s1 预测响应: 每条逻辑分支槽一个 2 位计数器 ----
  output logic [CTR_W-1:0]       io_s1_cnt [NUM_BR],
  output logic                   io_s1_resp_valid,            // 0 = 这拍读被 bank 冲突作废

  // ---- commit 更新 (逻辑分支槽视角) ----
  input  logic                   io_update_mask   [NUM_BR],
  input  logic [PC_W-1:0]        io_update_pc,
  input  logic [CTR_W-1:0]       io_update_cnt    [NUM_BR],
  input  logic                   io_update_takens [NUM_BR],

  // ---- MBIST/DFT 透传: [bank][该 bank 内的物理 SRAM] ----
  input  logic [BORE_AW-1:0]     bore_addr       [N_BANKS][SRAM_SPLITS],
  input  logic [BORE_AW-1:0]     bore_addr_rd    [N_BANKS][SRAM_SPLITS],
  input  logic [BORE_DW-1:0]     bore_wdata      [N_BANKS][SRAM_SPLITS],
  input  logic [BORE_MW-1:0]     bore_wmask      [N_BANKS][SRAM_SPLITS],
  input  logic                   bore_re         [N_BANKS][SRAM_SPLITS],
  input  logic                   bore_we         [N_BANKS][SRAM_SPLITS],
  output logic [BORE_DW-1:0]     bore_rdata      [N_BANKS][SRAM_SPLITS],
  input  logic                   bore_ack        [N_BANKS][SRAM_SPLITS],
  input  logic                   bore_selectedOH [N_BANKS][SRAM_SPLITS],
  input  logic [BORE_ARRW-1:0]   bore_array      [N_BANKS][SRAM_SPLITS],
  // DFT 时钟控制, 7 位打包 {cgen, mcp_hold, aux_ckbp, aux_clk, bp_clken, bypass, hold}
  input  logic [6:0]             sig_sram        [N_BANKS][SRAM_SPLITS]
);

  // ===========================================================================
  // 纯函数
  // ===========================================================================

  // 2 位饱和更新: taken 加一封顶, not-taken 减一封底 (Tage.scala: satUpdate)
  function automatic logic [CTR_W-1:0] sat_update(input logic [CTR_W-1:0] c,
                                                  input logic             taken);
    if (taken) sat_update = (&c)      ? c : CTR_W'(c + 1'b1);
    else       sat_update = (c == '0) ? c : CTR_W'(c - 1'b1);
  endfunction

  // 逻辑槽 ⇄ 物理 way 重排 (get_phy_br_idx / get_lgc_br_idx):
  //   phy = idx[0] ^ lgc。numBr=2 时就是"idx[0]=1 则两个槽对调"。
  //   异或自反 ⇒ 正反两个方向共用这一个函数。
  function automatic logic [NUM_BR-1:0] swap_bits(input logic sw,
                                                  input logic [NUM_BR-1:0] v);
    swap_bits = sw ? {v[0], v[1]} : v;
  endfunction

  function automatic logic [NUM_BR*CTR_W-1:0] swap_ctrs(input logic sw,
                                                        input logic [NUM_BR*CTR_W-1:0] v);
    swap_ctrs = sw ? {v[CTR_W-1:0], v[NUM_BR*CTR_W-1:CTR_W]} : v;
  endfunction

  // ===========================================================================
  // 索引拆分: idx = pc[11:1]; bank = idx[0]; row = idx[10:1]
  // ===========================================================================
  wire [IDX_W-1:0] s0_idx  = io_req_bits[INST_OFF +: IDX_W];
  wire             s0_bank = s0_idx[0];
  wire [ROW_W-1:0] s0_row  = s0_idx[IDX_W-1:1];

  wire [IDX_W-1:0] u_idx   = io_update_pc[INST_OFF +: IDX_W];
  wire             u_bank  = u_idx[0];
  wire [ROW_W-1:0] u_row   = u_idx[IDX_W-1:1];

  // bank 独热选择
  wire [N_BANKS-1:0] bank_sel_req = s0_bank ? 2'b10 : 2'b01;
  wire [N_BANKS-1:0] bank_sel_upd = u_bank  ? 2'b10 : 2'b01;

  // ===========================================================================
  // 上电清表: SRAM 无复位, 复位后自扫 1024 行, 每行两个 way 都写弱 taken
  // ===========================================================================
  logic             doing_reset;
  logic [ROW_W-1:0] resetRow;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      doing_reset <= 1'b1;
      resetRow    <= '0;
    end else begin
      // 扫到最后一行就结束; resetRow 只在扫表期间自增
      doing_reset <= (resetRow != ROW_LAST) & doing_reset;
      resetRow    <= resetRow + {{(ROW_W-1){1'b0}}, doing_reset};
    end
  end

  assign io_req_ready = ~doing_reset;

  // ===========================================================================
  // 更新路径 (组合): 逻辑槽 → 物理 way, 取旧值 (优先写旁路) → 饱和更新
  // ===========================================================================
  wire u_swap = u_idx[0];   // == u_bank; 命名上区分"选 bank"与"槽重排"两种用途

  // 写旁路反馈 (逻辑槽视角), 声明在例化之前
  logic                       wrb_hit;
  wire  [NUM_BR-1:0]          wrb_hit_valid_l;
  wire  [NUM_BR*CTR_W-1:0]    wrb_hit_data_l;

  wire  [NUM_BR-1:0]          upd_mask_l  = {io_update_mask[1],   io_update_mask[0]};
  wire  [NUM_BR-1:0]          upd_taken_l = {io_update_takens[1], io_update_takens[0]};
  wire  [NUM_BR*CTR_W-1:0]    upd_cnt_l   = {io_update_cnt[1],    io_update_cnt[0]};

  // 同一次更新在物理 way 视角下的四份数据
  wire  [NUM_BR-1:0]          upd_mask_p  = swap_bits(u_swap, upd_mask_l);
  wire  [NUM_BR-1:0]          upd_taken_p = swap_bits(u_swap, upd_taken_l);
  wire  [NUM_BR*CTR_W-1:0]    upd_cnt_p   = swap_ctrs(u_swap, upd_cnt_l);
  wire  [NUM_BR-1:0]          wrb_v_p     = swap_bits(u_swap, wrb_hit_valid_l);
  wire  [NUM_BR*CTR_W-1:0]    wrb_d_p     = swap_ctrs(u_swap, wrb_hit_data_l);

  wire                        upd_wen_any = upd_mask_l != '0;

  logic [CTR_W-1:0] old_ctr [NUM_BR];   // 物理 way 视角
  logic [CTR_W-1:0] new_ctr [NUM_BR];

  always_comb begin
    for (int p = 0; p < NUM_BR; p++) begin
      // 旧值来源: 写旁路里有更新的就用它, 否则用上层随 update 带下来的 cnt
      old_ctr[p] = (wrb_hit & wrb_v_p[p]) ? wrb_d_p[p*CTR_W +: CTR_W]
                                          : upd_cnt_p[p*CTR_W +: CTR_W];
      new_ctr[p] = sat_update(old_ctr[p], upd_taken_p[p]);
    end
  end

  // ===========================================================================
  // SRAM bank: 读端口 (s0) 与写端口 (更新 / 清表) —— 同 bank 同拍冲突 ⇒ 读作废
  // ===========================================================================
  wire [N_BANKS-1:0] bank_wen = ({N_BANKS{upd_wen_any}} & bank_sel_upd)
                              | {N_BANKS{doing_reset}};

  // 本拍要读的那个 bank 正好在写 ⇒ 这次读的数据不可用
  wire s0_invalid_by_conflict = |(bank_sel_req & bank_wen);

  // 写口共用: 清表时地址走 resetRow、数据写弱 taken、两个 way 全开
  wire [ROW_W-1:0]   w_row     = doing_reset ? resetRow       : u_row;
  wire [CTR_W-1:0]   w_data_0  = doing_reset ? CTR_WEAK_TAKEN : new_ctr[0];
  wire [CTR_W-1:0]   w_data_1  = doing_reset ? CTR_WEAK_TAKEN : new_ctr[1];
  wire [NUM_BR-1:0]  w_waymask = doing_reset ? {NUM_BR{1'b1}} : upd_mask_p;

  logic [CTR_W-1:0] bt_rdata [N_BANKS][NUM_BR];   // [bank][物理 way]

  for (genvar b = 0; b < N_BANKS; b++) begin : g_bank
    FoldedSRAMTemplate_20 bt (
      .clock                            (clock),
      .reset                            (reset),
      .io_r_req_valid                   (io_req_valid & bank_sel_req[b]),
      .io_r_req_bits_setIdx             (s0_row),
      .io_r_resp_data_0                 (bt_rdata[b][0]),
      .io_r_resp_data_1                 (bt_rdata[b][1]),
      .io_w_req_valid                   (bank_wen[b]),
      .io_w_req_bits_setIdx             (w_row),
      .io_w_req_bits_data_0             (w_data_0),
      .io_w_req_bits_data_1             (w_data_1),
      .io_w_req_bits_waymask            (w_waymask),
      // --- MBIST/DFT 透传: 本 bank 内两个物理 SRAM 各一组 ---
      .boreChildrenBd_bore_addr         (bore_addr      [b][0]),
      .boreChildrenBd_bore_addr_rd      (bore_addr_rd   [b][0]),
      .boreChildrenBd_bore_wdata        (bore_wdata     [b][0]),
      .boreChildrenBd_bore_wmask        (bore_wmask     [b][0]),
      .boreChildrenBd_bore_re           (bore_re        [b][0]),
      .boreChildrenBd_bore_we           (bore_we        [b][0]),
      .boreChildrenBd_bore_rdata        (bore_rdata     [b][0]),
      .boreChildrenBd_bore_ack          (bore_ack       [b][0]),
      .boreChildrenBd_bore_selectedOH   (bore_selectedOH[b][0]),
      .boreChildrenBd_bore_array        (bore_array     [b][0]),
      .boreChildrenBd_bore_1_addr       (bore_addr      [b][1]),
      .boreChildrenBd_bore_1_addr_rd    (bore_addr_rd   [b][1]),
      .boreChildrenBd_bore_1_wdata      (bore_wdata     [b][1]),
      .boreChildrenBd_bore_1_wmask      (bore_wmask     [b][1]),
      .boreChildrenBd_bore_1_re         (bore_re        [b][1]),
      .boreChildrenBd_bore_1_we         (bore_we        [b][1]),
      .boreChildrenBd_bore_1_rdata      (bore_rdata     [b][1]),
      .boreChildrenBd_bore_1_ack        (bore_ack       [b][1]),
      .boreChildrenBd_bore_1_selectedOH (bore_selectedOH[b][1]),
      .boreChildrenBd_bore_1_array      (bore_array     [b][1]),
      .sigFromSrams_bore_ram_hold       (sig_sram[b][0][0]),
      .sigFromSrams_bore_ram_bypass     (sig_sram[b][0][1]),
      .sigFromSrams_bore_ram_bp_clken   (sig_sram[b][0][2]),
      .sigFromSrams_bore_ram_aux_clk    (sig_sram[b][0][3]),
      .sigFromSrams_bore_ram_aux_ckbp   (sig_sram[b][0][4]),
      .sigFromSrams_bore_ram_mcp_hold   (sig_sram[b][0][5]),
      .sigFromSrams_bore_cgen           (sig_sram[b][0][6]),
      .sigFromSrams_bore_1_ram_hold     (sig_sram[b][1][0]),
      .sigFromSrams_bore_1_ram_bypass   (sig_sram[b][1][1]),
      .sigFromSrams_bore_1_ram_bp_clken (sig_sram[b][1][2]),
      .sigFromSrams_bore_1_ram_aux_clk  (sig_sram[b][1][3]),
      .sigFromSrams_bore_1_ram_aux_ckbp (sig_sram[b][1][4]),
      .sigFromSrams_bore_1_ram_mcp_hold (sig_sram[b][1][5]),
      .sigFromSrams_bore_1_cgen         (sig_sram[b][1][6])
    );
  end

  // ===========================================================================
  // 写旁路: 8 项小 CAM, 按 idx 记住最近写下去的计数 (逻辑槽视角)
  // ===========================================================================
  wire [NUM_BR*CTR_W-1:0] wrb_wdata_l = swap_ctrs(u_swap, {new_ctr[1], new_ctr[0]});

  WrBypass_32 wrbypass (
    .clock               (clock),
    .reset               (reset),
    .io_wen              (upd_wen_any),
    .io_write_idx        (u_idx),
    .io_write_data_0     (wrb_wdata_l[CTR_W-1:0]),
    .io_write_data_1     (wrb_wdata_l[NUM_BR*CTR_W-1:CTR_W]),
    .io_write_way_mask_0 (io_update_mask[0]),
    .io_write_way_mask_1 (io_update_mask[1]),
    .io_hit              (wrb_hit),
    .io_hit_data_0_valid (wrb_hit_valid_l[0]),
    .io_hit_data_0_bits  (wrb_hit_data_l[CTR_W-1:0]),
    .io_hit_data_1_valid (wrb_hit_valid_l[1]),
    .io_hit_data_1_bits  (wrb_hit_data_l[NUM_BR*CTR_W-1:CTR_W])
  );

  // ===========================================================================
  // s0 → s1 流水寄存器 (随请求打拍, 无复位) 与 s1 输出
  // ===========================================================================
  logic                s1_invalid_by_conflict;
  logic [N_BANKS-1:0]  s1_bank_1h;
  logic [IDX_W-1:0]    s1_idx;

  always_ff @(posedge clock) begin
    if (io_req_valid) begin
      s1_invalid_by_conflict <= s0_invalid_by_conflict;
      s1_bank_1h             <= bank_sel_req;
      s1_idx                 <= s0_idx;
    end
  end

  // Mux1H: 只有被选中的 bank 的读数据参与
  logic [CTR_W-1:0] s1_read [NUM_BR];   // 物理 way 视角
  always_comb begin
    for (int w = 0; w < NUM_BR; w++) begin
      s1_read[w] = '0;
      for (int b = 0; b < N_BANKS; b++)
        s1_read[w] |= {CTR_W{s1_bank_1h[b]}} & bt_rdata[b][w];
    end
  end

  // 物理 way → 逻辑分支槽 (与更新侧同一个重排, 用 s1 那拍锁存的 idx[0])
  wire                    s1_swap    = s1_idx[0];
  wire [NUM_BR*CTR_W-1:0] s1_cnt_lgc = swap_ctrs(s1_swap, {s1_read[1], s1_read[0]});

  always_comb begin
    for (int l = 0; l < NUM_BR; l++)
      io_s1_cnt[l] = s1_cnt_lgc[l*CTR_W +: CTR_W];
  end

  assign io_s1_resp_valid = ~s1_invalid_by_conflict;

endmodule


// -----------------------------------------------------------------------------
// golden 同名 wrapper —— 端口与 G1 golden TageBTable 逐位同名同序, 只做展平/打包
// -----------------------------------------------------------------------------
module TageBTable(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [49:0] io_req_bits,
  output [1:0]  io_s1_cnt_0,
  output [1:0]  io_s1_cnt_1,
  output        io_s1_resp_valid,
  input         io_update_mask_0,
  input         io_update_mask_1,
  input  [49:0] io_update_pc,
  input  [1:0]  io_update_cnt_0,
  input  [1:0]  io_update_cnt_1,
  input         io_update_takens_0,
  input         io_update_takens_1,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [7:0]  boreChildrenBd_bore_wdata,
  input  [3:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [7:0]  boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array,
  input  [8:0]  boreChildrenBd_bore_1_addr,
  input  [8:0]  boreChildrenBd_bore_1_addr_rd,
  input  [7:0]  boreChildrenBd_bore_1_wdata,
  input  [3:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [7:0]  boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [6:0]  boreChildrenBd_bore_1_array,
  input  [8:0]  boreChildrenBd_bore_2_addr,
  input  [8:0]  boreChildrenBd_bore_2_addr_rd,
  input  [7:0]  boreChildrenBd_bore_2_wdata,
  input  [3:0]  boreChildrenBd_bore_2_wmask,
  input         boreChildrenBd_bore_2_re,
  input         boreChildrenBd_bore_2_we,
  output [7:0]  boreChildrenBd_bore_2_rdata,
  input         boreChildrenBd_bore_2_ack,
  input         boreChildrenBd_bore_2_selectedOH,
  input  [6:0]  boreChildrenBd_bore_2_array,
  input  [8:0]  boreChildrenBd_bore_3_addr,
  input  [8:0]  boreChildrenBd_bore_3_addr_rd,
  input  [7:0]  boreChildrenBd_bore_3_wdata,
  input  [3:0]  boreChildrenBd_bore_3_wmask,
  input         boreChildrenBd_bore_3_re,
  input         boreChildrenBd_bore_3_we,
  output [7:0]  boreChildrenBd_bore_3_rdata,
  input         boreChildrenBd_bore_3_ack,
  input         boreChildrenBd_bore_3_selectedOH,
  input  [6:0]  boreChildrenBd_bore_3_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,
  input         sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken,
  input         sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp,
  input         sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,
  input         sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken,
  input         sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp,
  input         sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen
);

  // golden 的 4 组 bore / 4 组 sigFromSrams 按 {bt_0.split0, bt_0.split1, bt_1.split0, bt_1.split1}
  // 排列, 这里打包成核里的 [bank][split] 二维数组。
  logic [tage_btable_pkg::BORE_AW-1:0]   bb_addr    [2][2];
  logic [tage_btable_pkg::BORE_AW-1:0]   bb_addr_rd [2][2];
  logic [tage_btable_pkg::BORE_DW-1:0]   bb_wdata   [2][2];
  logic [tage_btable_pkg::BORE_MW-1:0]   bb_wmask   [2][2];
  logic                                  bb_re      [2][2];
  logic                                  bb_we      [2][2];
  logic [tage_btable_pkg::BORE_DW-1:0]   bb_rdata   [2][2];
  logic                                  bb_ack     [2][2];
  logic                                  bb_sel     [2][2];
  logic [tage_btable_pkg::BORE_ARRW-1:0] bb_array   [2][2];
  logic [6:0]                            bb_sig     [2][2];

  // golden 组 0 (boreChildrenBd_bore) → bt_0 的第 0 块物理 SRAM
  assign bb_addr[0][0]    = boreChildrenBd_bore_addr;
  assign bb_addr_rd[0][0] = boreChildrenBd_bore_addr_rd;
  assign bb_wdata[0][0]   = boreChildrenBd_bore_wdata;
  assign bb_wmask[0][0]   = boreChildrenBd_bore_wmask;
  assign bb_re[0][0]      = boreChildrenBd_bore_re;
  assign bb_we[0][0]      = boreChildrenBd_bore_we;
  assign bb_ack[0][0]     = boreChildrenBd_bore_ack;
  assign bb_sel[0][0]     = boreChildrenBd_bore_selectedOH;
  assign bb_array[0][0]   = boreChildrenBd_bore_array;
  assign boreChildrenBd_bore_rdata = bb_rdata[0][0];
  assign bb_sig[0][0]     = {sigFromSrams_bore_cgen,
                                sigFromSrams_bore_ram_mcp_hold,
                                sigFromSrams_bore_ram_aux_ckbp,
                                sigFromSrams_bore_ram_aux_clk,
                                sigFromSrams_bore_ram_bp_clken,
                                sigFromSrams_bore_ram_bypass,
                                sigFromSrams_bore_ram_hold};

  // golden 组 1 (boreChildrenBd_bore_1) → bt_0 的第 1 块物理 SRAM
  assign bb_addr[0][1]    = boreChildrenBd_bore_1_addr;
  assign bb_addr_rd[0][1] = boreChildrenBd_bore_1_addr_rd;
  assign bb_wdata[0][1]   = boreChildrenBd_bore_1_wdata;
  assign bb_wmask[0][1]   = boreChildrenBd_bore_1_wmask;
  assign bb_re[0][1]      = boreChildrenBd_bore_1_re;
  assign bb_we[0][1]      = boreChildrenBd_bore_1_we;
  assign bb_ack[0][1]     = boreChildrenBd_bore_1_ack;
  assign bb_sel[0][1]     = boreChildrenBd_bore_1_selectedOH;
  assign bb_array[0][1]   = boreChildrenBd_bore_1_array;
  assign boreChildrenBd_bore_1_rdata = bb_rdata[0][1];
  assign bb_sig[0][1]     = {sigFromSrams_bore_1_cgen,
                                sigFromSrams_bore_1_ram_mcp_hold,
                                sigFromSrams_bore_1_ram_aux_ckbp,
                                sigFromSrams_bore_1_ram_aux_clk,
                                sigFromSrams_bore_1_ram_bp_clken,
                                sigFromSrams_bore_1_ram_bypass,
                                sigFromSrams_bore_1_ram_hold};

  // golden 组 2 (boreChildrenBd_bore_2) → bt_1 的第 0 块物理 SRAM
  assign bb_addr[1][0]    = boreChildrenBd_bore_2_addr;
  assign bb_addr_rd[1][0] = boreChildrenBd_bore_2_addr_rd;
  assign bb_wdata[1][0]   = boreChildrenBd_bore_2_wdata;
  assign bb_wmask[1][0]   = boreChildrenBd_bore_2_wmask;
  assign bb_re[1][0]      = boreChildrenBd_bore_2_re;
  assign bb_we[1][0]      = boreChildrenBd_bore_2_we;
  assign bb_ack[1][0]     = boreChildrenBd_bore_2_ack;
  assign bb_sel[1][0]     = boreChildrenBd_bore_2_selectedOH;
  assign bb_array[1][0]   = boreChildrenBd_bore_2_array;
  assign boreChildrenBd_bore_2_rdata = bb_rdata[1][0];
  assign bb_sig[1][0]     = {sigFromSrams_bore_2_cgen,
                                sigFromSrams_bore_2_ram_mcp_hold,
                                sigFromSrams_bore_2_ram_aux_ckbp,
                                sigFromSrams_bore_2_ram_aux_clk,
                                sigFromSrams_bore_2_ram_bp_clken,
                                sigFromSrams_bore_2_ram_bypass,
                                sigFromSrams_bore_2_ram_hold};

  // golden 组 3 (boreChildrenBd_bore_3) → bt_1 的第 1 块物理 SRAM
  assign bb_addr[1][1]    = boreChildrenBd_bore_3_addr;
  assign bb_addr_rd[1][1] = boreChildrenBd_bore_3_addr_rd;
  assign bb_wdata[1][1]   = boreChildrenBd_bore_3_wdata;
  assign bb_wmask[1][1]   = boreChildrenBd_bore_3_wmask;
  assign bb_re[1][1]      = boreChildrenBd_bore_3_re;
  assign bb_we[1][1]      = boreChildrenBd_bore_3_we;
  assign bb_ack[1][1]     = boreChildrenBd_bore_3_ack;
  assign bb_sel[1][1]     = boreChildrenBd_bore_3_selectedOH;
  assign bb_array[1][1]   = boreChildrenBd_bore_3_array;
  assign boreChildrenBd_bore_3_rdata = bb_rdata[1][1];
  assign bb_sig[1][1]     = {sigFromSrams_bore_3_cgen,
                                sigFromSrams_bore_3_ram_mcp_hold,
                                sigFromSrams_bore_3_ram_aux_ckbp,
                                sigFromSrams_bore_3_ram_aux_clk,
                                sigFromSrams_bore_3_ram_bp_clken,
                                sigFromSrams_bore_3_ram_bypass,
                                sigFromSrams_bore_3_ram_hold};

  // 逻辑分支槽向量 ⇄ golden 的 _0/_1 扁平端口
  logic [tage_btable_pkg::CTR_W-1:0] s1_cnt      [tage_btable_pkg::NUM_BR];
  logic                              upd_mask    [tage_btable_pkg::NUM_BR];
  logic [tage_btable_pkg::CTR_W-1:0] upd_cnt     [tage_btable_pkg::NUM_BR];
  logic                              upd_takens  [tage_btable_pkg::NUM_BR];
  assign upd_mask[0]   = io_update_mask_0;   assign upd_mask[1]   = io_update_mask_1;
  assign upd_cnt[0]    = io_update_cnt_0;    assign upd_cnt[1]    = io_update_cnt_1;
  assign upd_takens[0] = io_update_takens_0; assign upd_takens[1] = io_update_takens_1;
  assign io_s1_cnt_0   = s1_cnt[0];          assign io_s1_cnt_1   = s1_cnt[1];

  xs_TageBTable_core u_core (
    .clock            (clock),
    .reset            (reset),
    .io_req_ready     (io_req_ready),
    .io_req_valid     (io_req_valid),
    .io_req_bits      (io_req_bits),
    .io_s1_cnt        (s1_cnt),
    .io_s1_resp_valid (io_s1_resp_valid),
    .io_update_mask   (upd_mask),
    .io_update_pc     (io_update_pc),
    .io_update_cnt    (upd_cnt),
    .io_update_takens (upd_takens),
    .bore_addr        (bb_addr),
    .bore_addr_rd     (bb_addr_rd),
    .bore_wdata       (bb_wdata),
    .bore_wmask       (bb_wmask),
    .bore_re          (bb_re),
    .bore_we          (bb_we),
    .bore_rdata       (bb_rdata),
    .bore_ack         (bb_ack),
    .bore_selectedOH  (bb_sel),
    .bore_array       (bb_array),
    .sig_sram         (bb_sig)
  );

endmodule
