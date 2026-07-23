// =============================================================================
// xs_SCTable_core —— SC（Statistical Corrector，统计校正预测器）的一张计数表核
//
// 对应 Chisel: xiangshan.frontend.SCTable（SC.scala，SCTable extends XSModule）
//
// 【它在 BPU 的位置：TAGE-SC 中的 "SC"】
//   香山主方向预测器是 TAGE-SC-L。TAGE 用多张带 tag 的表给出方向 + 置信度；SC
//   则是一组「无 tag、用带符号饱和计数器累加的统计表」，对 TAGE 的方向做**置信校正**：
//   把若干张 SC 表（本模块是其中一张）在命中行的计数器按权重求和，与一个阈值比较，
//   若总和足够强地反对 TAGE 的方向，就翻转最终预测。SC 擅长纠正 TAGE 偶尔过度自信
//   但实际是「弱偏置 / 受长历史影响」的分支。
//
//   一张 SCTable 的职责很轻量：
//     预测 (s0→s1)：用 (PC, 折叠历史) 索引到一行，读出该行 4 个 6-bit 计数器，
//                   按"取指块内第几条分支 + TAGE 当时的方向"选出 2 个交给 SC 顶层求和。
//     更新 (commit)：用 (PC, 全局历史) 索引到同一行，对被更新分支对应的那个计数器
//                   做带符号饱和 ±1。
//
// 【表的物理组织：4 way、按 (分支位置, TAGE 方向) 编址】
//   一行存 4 个计数器，下标含义是 {分支在块内是高半(pc[1]) 还是低半, TAGE 当时预测的方向}：
//     way0 = (低半分支, TAGE=not-taken)   way1 = (低半分支, TAGE=taken)
//     way2 = (高半分支, TAGE=not-taken)   way3 = (高半分支, TAGE=taken)
//   为什么按 TAGE 方向分桶：SC 学的是"在 TAGE 给出某方向的前提下，真实方向偏向哪边"
//   这一**条件统计量**，所以同一 PC 行要为 TAGE 的两种判断各留一个计数器。
//   为什么按高/低半分桶：一个取指块最多含 2 条条件分支（pc[1]=0/1 两个 2 字节槽），
//   两条分支各自独立统计。预测时一次读出全部 4 个，s1 再用 pc[1] 选出本块这 2 条用的桶。
//
// 【计数器编码：6-bit 带符号饱和，范围 [0x20(最负) .. 0x1F(最正)]】
//   计数器是补码风格的有符号数。taken 推向更正(+1)，not-taken 推向更负(-1)；
//   到 0x1F 再 taken 不再增（封顶），到 0x20 再 not-taken 不再减（封底）。
//
// 【写旁路 WrBypass：消除"连续更新同一行"的写后读冒险】
//   计数表存在双口 SRAM 里，写入要下一拍才能读回。SC 对同一 PC 行可能连续 commit，
//   若每次都读 io_update_oldCtrs（来自更早的预测快照）会丢掉刚写进去的增量。故为每条
//   逻辑分支配一个 WrBypass（16 项小缓存），暂存最近写过的行的新计数值；更新取 oldCtr
//   时优先用 WrBypass 命中值，没命中才退回 io_update_oldCtrs。
//
// 【与 golden 的端口/索引差异（4 个变体）】
//   firtool 把 SCTable 按"读折叠历史长度 + 索引折叠方式"单态化成 SCTable/_1/_2/_3。
//   本核用参数 IDX_SCHEME 选择 4 种索引方案（见下 localparam 注释），HIST_W 给读侧
//   折叠历史输入位宽。除索引外 4 个变体逻辑完全一致，故共用此核。
//
// 【DFT/MBIST】
//   boreChildrenBd_*/sigFromSrams_* 是 MBIST/DFT 旁路链，对功能输出 io_resp_ctrs 无影响。
//   本核例化 golden 同名 MBIST 流水寄存器 (xs_MbistPipeSc_core) 把顶层 mbist 端口接到
//   SRAM 子模块的 bore 口，原样穿透；功能逻辑与之解耦。
// =============================================================================
module xs_SCTable_core #(
  // ---- 索引方案选择（4 个 golden 变体一一对应）----
  //   0 (SCTable)  : 无折叠历史。read setIdx = pc[8:1]；write setIdx = pc[8:1]
  //   1 (SCTable_1): 4-bit 折叠历史只异或低 4 位 idx。
  //                  read  = {pc[8:5], pc[4:1] ^ fh[3:0]}
  //                  write = {pc[8:5], pc[4:1] ^ ghist[3:0]}
  //   2 (SCTable_2): 8-bit 折叠历史（histLen=11 折到 8 位，有一处自异或对折）。
  //                  read  = pc[8:1] ^ fh[7:0]
  //                  write = pc[8:1] ^ {ghist[7:2], ghist[1:0] ^ ghist[9:8]}
  //   3 (SCTable_3): 8-bit 折叠历史（histLen=16 折到 8 位，两段直接异或）。
  //                  read  = pc[8:1] ^ fh[7:0]
  //                  write = pc[8:1] ^ ghist[7:0] ^ ghist[15:8]
  parameter int unsigned IDX_SCHEME = 0,
  parameter int unsigned HIST_W     = 1,    // 读侧折叠历史输入位宽（变体 0 不用，置 1 占位）
  parameter int unsigned MBIST_ARRAY_ID = 7'h42,  // MBIST array ID（4 变体 0x42/3/4/5）

  // ---- 固定结构参数（不要外部覆盖）----
  parameter int unsigned PC_W       = 50,   // 取指 PC 位宽 (VAddrBits)
  parameter int unsigned GHIST_W    = 256,  // 原始全局历史位宽（更新侧重算索引用）
  parameter int unsigned IDX_W      = 8,    // SRAM 行地址位宽（256 行）
  parameter int unsigned NUM_BR     = 2,    // 一个取指块的逻辑分支数（高/低半各一）
  parameter int unsigned NUM_WAY    = 4,    // 一行的计数器个数 = NUM_BR × 2(TAGE方向)
  parameter int unsigned CTR_W      = 6,    // 计数器位宽（6-bit 带符号饱和）
  parameter int unsigned BORE_AW    = 9     // MBIST bore 地址宽
)(
  input  logic                clock,
  input  logic                reset,

  // ---- 预测请求 (s0) ----
  input  logic                io_req_valid,
  input  logic [PC_W-1:0]     io_req_bits_pc,
  input  logic [HIST_W-1:0]   io_req_folded_hist,   // 读侧折叠历史（变体 0 不接，悬空 0）

  // ---- 预测响应 (s1)：2 条逻辑分支，每条给出选中的那对计数器 (NT 桶, T 桶) ----
  output logic [CTR_W-1:0]    io_resp_ctrs_0_0,
  output logic [CTR_W-1:0]    io_resp_ctrs_0_1,
  output logic [CTR_W-1:0]    io_resp_ctrs_1_0,
  output logic [CTR_W-1:0]    io_resp_ctrs_1_1,

  // ---- 更新 (commit) ----
  input  logic [PC_W-1:0]     io_update_pc,
  input  logic [GHIST_W-1:0]  io_update_ghist,      // 更新侧重算索引用的全局历史
  input  logic                io_update_mask_0,     // 逻辑分支 0 本次是否更新
  input  logic                io_update_mask_1,     // 逻辑分支 1 本次是否更新
  input  logic [CTR_W-1:0]    io_update_oldCtrs_0,  // 预测时快照的旧计数器（WrBypass 未命中时用）
  input  logic [CTR_W-1:0]    io_update_oldCtrs_1,
  input  logic                io_update_tagePreds_0,// 该分支 TAGE 当时的方向（选 way 用）
  input  logic                io_update_tagePreds_1,
  input  logic                io_update_takens_0,   // 该分支本次真实方向
  input  logic                io_update_takens_1,

  // ---- DFT/MBIST 旁路（顶层 mbist 端口；功能无关，穿到 SRAM bore 口）----
  input  logic [6:0]          boreChildrenBd_bore_array,
  input  logic                boreChildrenBd_bore_all,
  input  logic                boreChildrenBd_bore_req,
  output logic                boreChildrenBd_bore_ack,
  input  logic                boreChildrenBd_bore_writeen,
  input  logic [3:0]          boreChildrenBd_bore_be,
  input  logic [BORE_AW-1:0]  boreChildrenBd_bore_addr,
  input  logic [23:0]         boreChildrenBd_bore_indata,
  input  logic                boreChildrenBd_bore_readen,
  input  logic [BORE_AW-1:0]  boreChildrenBd_bore_addr_rd,
  output logic [23:0]         boreChildrenBd_bore_outdata,

  // sigFromSrams：SRAM 的 DFT 时钟控制，原样透传 SRAM 黑盒
  input  logic                sigFromSrams_bore_ram_hold,
  input  logic                sigFromSrams_bore_ram_bypass,
  input  logic                sigFromSrams_bore_ram_bp_clken,
  input  logic                sigFromSrams_bore_ram_aux_clk,
  input  logic                sigFromSrams_bore_ram_aux_ckbp,
  input  logic                sigFromSrams_bore_ram_mcp_hold,
  input  logic                sigFromSrams_bore_cgen
);

  // way 下标符号常量（{分支高/低半, TAGE方向}）
  localparam int unsigned W_LO_NT = 0;  // 低半分支, TAGE not-taken
  localparam int unsigned W_LO_T  = 1;  // 低半分支, TAGE taken
  localparam int unsigned W_HI_NT = 2;  // 高半分支, TAGE not-taken
  localparam int unsigned W_HI_T  = 3;  // 高半分支, TAGE taken

  localparam logic [CTR_W-1:0] CTR_MAX = 6'h1F;  // 最正（封顶）
  localparam logic [CTR_W-1:0] CTR_MIN = 6'h20;  // 最负（封底）

  // ===========================================================================
  // 纯函数
  // ===========================================================================

  // 6-bit 带符号饱和计数器更新：taken → +1（封顶 0x1F），not-taken → -1（封底 0x20）
  function automatic logic [CTR_W-1:0] ctr_update(input logic [CTR_W-1:0] c, input logic taken);
    if (c == CTR_MAX && taken)        ctr_update = CTR_MAX;
    else if (c == CTR_MIN && ~taken)  ctr_update = CTR_MIN;
    else                              ctr_update = taken ? (c + 6'h1) : (c - 6'h1);
  endfunction

  // 读侧行索引：由 (pc, 折叠历史) 按变体方案算出
  //   fh8 = 折叠历史零扩展到 8 位（变体 0 的 HIST_W=1 时高位补 0，避免越界 slice 警告；
  //   该路径在方案 0 下根本不被选中）。
  function automatic logic [IDX_W-1:0] read_idx(
      input logic [PC_W-1:0] pc, input logic [7:0] fh8);
    case (IDX_SCHEME)
      1:       read_idx = {pc[8:5], pc[4:1] ^ fh8[3:0]};
      2:       read_idx = pc[8:1] ^ fh8[7:0];
      3:       read_idx = pc[8:1] ^ fh8[7:0];
      default: read_idx = pc[8:1];                       // 方案 0：无历史
    endcase
  endfunction

  // 更新侧行索引：由 (pc, 原始全局历史) 现场折叠重算（更新拿不到折叠快照）
  function automatic logic [IDX_W-1:0] write_idx(
      input logic [PC_W-1:0] pc, input logic [GHIST_W-1:0] gh);
    case (IDX_SCHEME)
      1:       write_idx = {pc[8:5], pc[4:1] ^ gh[3:0]};
      2:       write_idx = pc[8:1] ^ {gh[7:2], gh[1:0] ^ gh[9:8]};
      3:       write_idx = pc[8:1] ^ gh[7:0] ^ gh[15:8];
      default: write_idx = pc[8:1];
    endcase
  endfunction

  // ===========================================================================
  // S0：读请求索引；S1：锁存 pc 供输出选择
  //   读地址当拍送 SRAM；读数据下一拍(s1)出。s1_pc 用来在 s1 用 pc[1] 选高/低半桶。
  // ===========================================================================
  logic [IDX_W-1:0] s0_read_idx;
  logic [7:0]       req_fh8;          // 折叠历史零扩展到 8 位
  always_comb begin
    req_fh8 = '0;
    req_fh8[HIST_W-1:0] = io_req_folded_hist;
  end
  assign s0_read_idx = read_idx(io_req_bits_pc, req_fh8);

  logic [PC_W-1:0] s1_pc;
  always_ff @(posedge clock) begin
    if (io_req_valid) s1_pc <= io_req_bits_pc;
  end

  // ===========================================================================
  // 更新逻辑
  // ===========================================================================
  wire upd_lo = ~io_update_pc[1];   // 逻辑分支 0 落在低半(1)还是高半，取决于 pc[1]
  wire upd_hi =  io_update_pc[1];
  logic [IDX_W-1:0] upd_idx;
  assign upd_idx = write_idx(io_update_pc, io_update_ghist);

  // ---- 写 way 掩码：把 (逻辑分支 0/1) 映射到 4 个 way ----
  //   逻辑分支 0(io_*_0) 的物理半区由 pc[1] 决定：pc[1]=0→低半, pc[1]=1→高半；
  //   逻辑分支 1(io_*_1) 取相反半。再叠加各自 TAGE 方向选 NT/T 桶。
  wire way_mask_0 =  // 低半, TAGE not-taken
      (io_update_mask_0 & upd_lo & ~io_update_tagePreds_0)
    | (io_update_mask_1 & upd_hi & ~io_update_tagePreds_1);
  wire way_mask_1 =  // 低半, TAGE taken
      (io_update_mask_0 & upd_lo &  io_update_tagePreds_0)
    | (io_update_mask_1 & upd_hi &  io_update_tagePreds_1);
  wire way_mask_2 =  // 高半, TAGE not-taken
      (io_update_mask_0 & upd_hi & ~io_update_tagePreds_0)
    | (io_update_mask_1 & upd_lo & ~io_update_tagePreds_1);
  wire way_mask_3 =  // 高半, TAGE taken
      (io_update_mask_0 & upd_hi &  io_update_tagePreds_0)
    | (io_update_mask_1 & upd_lo &  io_update_tagePreds_1);
  wire [NUM_WAY-1:0] upd_way_mask = {way_mask_3, way_mask_2, way_mask_1, way_mask_0};

  // ---- WrBypass 反馈（声明在前；下面例化驱动）----
  //   每条逻辑分支一个 WrBypass，缓存最近写过该行的 2 个计数器（data_0=NT 桶, data_1=T 桶）。
  logic              wrbp_hit   [NUM_BR];
  logic              wrbp_v0    [NUM_BR];   // data_0(NT 桶) 有效
  logic [CTR_W-1:0]  wrbp_d0    [NUM_BR];
  logic              wrbp_v1    [NUM_BR];   // data_1(T 桶) 有效
  logic [CTR_W-1:0]  wrbp_d1    [NUM_BR];

  // ---- 取某条逻辑分支的旧计数器：优先 WrBypass，未命中退回 io_update_oldCtrs ----
  //   每条逻辑分支选用一个 WrBypass 实例（分支 0 用 0/1 取决于 upd_lo；分支 1 相反），
  //   并据该分支 TAGE 方向 ctr_pos 选 T 桶(data_1)/NT 桶(data_0)。
  //   命中条件 = WrBypass 命中 且 选中桶的 valid 置位；否则退回 io_update_oldCtrs。
  //   （展开成纯组合表达式而非读非局部信号的函数，与 golden 同构、避免 FMR_VLOG-091）

  // 分支 0：upd_lo=1 用实例 0，否则用实例 1
  wire             b0_hit = upd_lo ? wrbp_hit[0] : wrbp_hit[1];
  wire             ctrPos = (~io_update_pc[1] & io_update_tagePreds_0)   // 该分支 TAGE 方向
                          | ( io_update_pc[1] & io_update_tagePreds_1);
  wire             b0_vld = ctrPos ? (upd_lo ? wrbp_v1[0] : wrbp_v1[1])
                                   : (upd_lo ? wrbp_v0[0] : wrbp_v0[1]);
  wire [CTR_W-1:0] b0_bp  = ctrPos ? (upd_lo ? wrbp_d1[0] : wrbp_d1[1])
                                   : (upd_lo ? wrbp_d0[0] : wrbp_d0[1]);
  wire [CTR_W-1:0] b0_fb  = upd_lo ? io_update_oldCtrs_0 : io_update_oldCtrs_1;
  wire [CTR_W-1:0] oldCtr0 = (b0_hit & b0_vld) ? b0_bp : b0_fb;
  wire             taken0  = (~io_update_pc[1] & io_update_takens_0)
                           | ( io_update_pc[1] & io_update_takens_1);
  wire [CTR_W-1:0] wdata0  = ctr_update(oldCtr0, taken0);

  // 分支 1：落在与分支 0 相反的半区（upd_hi=1 用实例 0，否则实例 1）
  wire             b1_hit = upd_hi ? wrbp_hit[0] : wrbp_hit[1];
  wire             ctrPos_1 = ( io_update_pc[1] & io_update_tagePreds_0)
                            | (~io_update_pc[1] & io_update_tagePreds_1);
  wire             b1_vld = ctrPos_1 ? (upd_hi ? wrbp_v1[0] : wrbp_v1[1])
                                     : (upd_hi ? wrbp_v0[0] : wrbp_v0[1]);
  wire [CTR_W-1:0] b1_bp  = ctrPos_1 ? (upd_hi ? wrbp_d1[0] : wrbp_d1[1])
                                     : (upd_hi ? wrbp_d0[0] : wrbp_d0[1]);
  wire [CTR_W-1:0] b1_fb  = upd_hi ? io_update_oldCtrs_0 : io_update_oldCtrs_1;
  wire [CTR_W-1:0] oldCtr1 = (b1_hit & b1_vld) ? b1_bp : b1_fb;
  wire             taken1  = ( io_update_pc[1] & io_update_takens_0)
                           | (~io_update_pc[1] & io_update_takens_1);
  wire [CTR_W-1:0] wdata1  = ctr_update(oldCtr1, taken1);

  // ---- SRAM 写数据：way0/1(低半) 用 wdata0，way2/3(高半) 用 wdata1 ----
  //   同一半区 NT/T 两 way 写同值，实际写哪个 way 由 upd_way_mask 选。
  wire             sram_w_valid = io_update_mask_0 | io_update_mask_1;

  // ===========================================================================
  // 双口计数表 SRAM（golden 同名子模块 SRAMTemplate_66，可信黑盒）
  //   读：s0 送地址，s1 出 4 个 way 的计数器。写：commit 拍按 upd_way_mask 写。
  // ===========================================================================
  logic [CTR_W-1:0] r_resp [NUM_WAY];

  // MBIST → SRAM bore 的中间线
  logic [BORE_AW-1:0] childBd_addr, childBd_addr_rd;
  logic [23:0]        childBd_wdata, childBd_rdata;
  logic [3:0]         childBd_wmask;
  logic               childBd_re, childBd_we, childBd_ack, childBd_selectedOH;
  logic [6:0]         childBd_array;

  SRAMTemplate_66 table_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_req_valid),
    .io_r_req_bits_setIdx           (s0_read_idx),
    .io_r_resp_data_0               (r_resp[0]),
    .io_r_resp_data_1               (r_resp[1]),
    .io_r_resp_data_2               (r_resp[2]),
    .io_r_resp_data_3               (r_resp[3]),
    .io_w_req_valid                 (sram_w_valid),
    .io_w_req_bits_setIdx           (upd_idx),
    .io_w_req_bits_data_0           (wdata0),   // → way0 (低半 NT)
    .io_w_req_bits_data_1           (wdata0),   // → way1 (低半 T)
    .io_w_req_bits_data_2           (wdata1),   // → way2 (高半 NT)
    .io_w_req_bits_data_3           (wdata1),   // → way3 (高半 T)
    .io_w_req_bits_waymask          (upd_way_mask),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr       (childBd_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_wdata),
    .boreChildrenBd_bore_wmask      (childBd_wmask),
    .boreChildrenBd_bore_re         (childBd_re),
    .boreChildrenBd_bore_we         (childBd_we),
    .boreChildrenBd_bore_rdata      (childBd_rdata),
    .boreChildrenBd_bore_ack        (childBd_ack),
    .boreChildrenBd_bore_selectedOH (childBd_selectedOH),
    .boreChildrenBd_bore_array      (childBd_array)
  );

  // ===========================================================================
  // MBIST 流水寄存（DFT 链；把顶层 mbist 端口接到 SRAM bore 口，原样穿透）
  // ===========================================================================
  xs_MbistPipeSc_core #(.ARRAY_ID(MBIST_ARRAY_ID)) mbistPl (
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
    .toSRAM_0_addr       (childBd_addr),
    .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),
    .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),
    .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),
    .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH),
    .toSRAM_0_array      (childBd_array)
  );

  // ===========================================================================
  // 写旁路 WrBypass（每逻辑分支一个，16 项 × 2 way × 6-bit；golden 同名 WrBypass_33）
  //   实例 0 缓存逻辑分支 0 写的行；实例 1 缓存逻辑分支 1。每个实例的两 way 对应
  //   该逻辑分支落点半区的 (NT 桶, T 桶)。写数据两 way 同值，由 way_mask 选其一。
  // ===========================================================================
  WrBypass_33 wrbypasses_0 (
    .clock               (clock),
    .reset               (reset),
    .io_wen              (io_update_mask_0),
    .io_write_idx        (upd_idx),
    .io_write_data_0     (upd_lo ? wdata0 : wdata1),
    .io_write_data_1     (upd_lo ? wdata0 : wdata1),
    .io_write_way_mask_0 (upd_lo ? way_mask_0 : way_mask_2),  // 该分支落点的 NT 桶
    .io_write_way_mask_1 (upd_lo ? way_mask_1 : way_mask_3),  // 该分支落点的 T 桶
    .io_hit              (wrbp_hit[0]),
    .io_hit_data_0_valid (wrbp_v0[0]),
    .io_hit_data_0_bits  (wrbp_d0[0]),
    .io_hit_data_1_valid (wrbp_v1[0]),
    .io_hit_data_1_bits  (wrbp_d1[0])
  );
  WrBypass_33 wrbypasses_1 (
    .clock               (clock),
    .reset               (reset),
    .io_wen              (io_update_mask_1),
    .io_write_idx        (upd_idx),
    .io_write_data_0     (upd_hi ? wdata0 : wdata1),
    .io_write_data_1     (upd_hi ? wdata0 : wdata1),
    .io_write_way_mask_0 (upd_hi ? way_mask_0 : way_mask_2),
    .io_write_way_mask_1 (upd_hi ? way_mask_1 : way_mask_3),
    .io_hit              (wrbp_hit[1]),
    .io_hit_data_0_valid (wrbp_v0[1]),
    .io_hit_data_0_bits  (wrbp_d0[1]),
    .io_hit_data_1_valid (wrbp_v1[1]),
    .io_hit_data_1_bits  (wrbp_d1[1])
  );

  // ===========================================================================
  // S1 响应选择：用 s1_pc[1] 把 4 个 way 选成 2 条逻辑分支各一对 (NT 桶, T 桶)
  //   逻辑分支 0(resp_0) = 落在 pc[1] 半区的桶；逻辑分支 1(resp_1) = 相反半区。
  //   每条给出 {_0=NT 桶, _1=T 桶} 两个计数器，交给 SC 顶层据 TAGE 方向择一加权。
  // ===========================================================================
  assign io_resp_ctrs_0_0 = s1_pc[1] ? r_resp[W_HI_NT] : r_resp[W_LO_NT];
  assign io_resp_ctrs_0_1 = s1_pc[1] ? r_resp[W_HI_T]  : r_resp[W_LO_T];
  assign io_resp_ctrs_1_0 = s1_pc[1] ? r_resp[W_LO_NT] : r_resp[W_HI_NT];
  assign io_resp_ctrs_1_1 = s1_pc[1] ? r_resp[W_LO_T]  : r_resp[W_HI_T];

endmodule


// =============================================================================
// xs_MbistPipeSc_core —— SC 表的 MBIST 流水寄存器（DFT 链路，golden MbistPipeSc 系列）
//
//   纯 DFT 基础设施，与分支预测功能无关。它在测试模式下把 BPU 顶层广播来的 mbist
//   总线（boreChildrenBd）一拍寄存后转发给本表的 SRAM bore 口，并把 SRAM 读回数据
//   送回 mbist 总线。只在被本表的 array ID(ARRAY_ID) 选中或 "all" 广播时才真正驱动
//   SRAM（doSpread）；否则 SRAM 侧地址/读写使能保持 0，避免误触发。
//
//   4 个变体只差一个常量 array ID（0x42/0x43/0x44/0x45），参数化为 ARRAY_ID。
// =============================================================================
module xs_MbistPipeSc_core #(
  parameter int unsigned ARRAY_ID = 7'h42
)(
  input  logic        clock,
  input  logic        reset,
  // ---- 上游 mbist 总线 ----
  input  logic [6:0]  mbist_array,
  input  logic        mbist_all,
  input  logic        mbist_req,
  output logic        mbist_ack,
  input  logic        mbist_writeen,
  input  logic [3:0]  mbist_be,
  input  logic [8:0]  mbist_addr,
  input  logic [23:0] mbist_indata,
  input  logic        mbist_readen,
  input  logic [8:0]  mbist_addr_rd,
  output logic [23:0] mbist_outdata,
  // ---- 下游到 SRAM bore 口 ----
  output logic [8:0]  toSRAM_0_addr,
  output logic [8:0]  toSRAM_0_addr_rd,
  output logic [23:0] toSRAM_0_wdata,
  output logic [3:0]  toSRAM_0_wmask,
  output logic        toSRAM_0_re,
  output logic        toSRAM_0_we,
  input  logic [23:0] toSRAM_0_rdata,
  output logic        toSRAM_0_ack,
  output logic        toSRAM_0_selectedOH,
  output logic [6:0]  toSRAM_0_array
);
  // 一拍寄存的 mbist 控制/数据
  logic [6:0]  array_q;
  logic        req_q, all_q, wen_q, ren_q;
  logic [3:0]  be_q;
  logic [7:0]  addr_q, addr_rd_q;  // MBIST 地址仅 8 位有效(SC SRAM<=256行); bit8 无扇出不存
  logic [23:0] data_in_q;

  // 本表是否被选中（array 命中本表 ID）/ 是否要把请求扩散到 SRAM
  wire selected  = (array_q == ARRAY_ID[6:0]);
  wire do_spread = selected | all_q;
  // 本拍是否激活（命中本表或全局广播）—— 决定是否锁存上游总线
  wire activated = mbist_all | (mbist_req & (mbist_array == ARRAY_ID[6:0]));

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      array_q   <= 7'h0;
      req_q     <= 1'b0;
      all_q     <= 1'b0;
      wen_q     <= 1'b0;
      be_q      <= 4'h0;
      addr_q    <= 8'h0;
      data_in_q <= 24'h0;
      ren_q     <= 1'b0;
      addr_rd_q <= 8'h0;
    end else begin
      if (activated) begin
        array_q <= mbist_array;
        all_q   <= mbist_all;
        wen_q   <= mbist_writeen;
        ren_q   <= mbist_readen;
      end
      req_q <= mbist_req;
      if (activated & (mbist_readen | mbist_writeen)) begin
        be_q      <= mbist_be;
        addr_q    <= mbist_addr[7:0];
        data_in_q <= mbist_indata;
        addr_rd_q <= mbist_addr_rd[7:0];
      end
    end
  end

  assign mbist_ack           = req_q;
  assign mbist_outdata       = selected ? toSRAM_0_rdata : 24'h0;
  assign toSRAM_0_addr       = do_spread ? {1'b0, addr_q}    : 9'h0;
  assign toSRAM_0_addr_rd    = do_spread ? {1'b0, addr_rd_q} : 9'h0;
  assign toSRAM_0_wdata      = data_in_q;
  assign toSRAM_0_wmask      = be_q;
  assign toSRAM_0_re         = do_spread & ren_q;
  assign toSRAM_0_we         = do_spread & wen_q;
  assign toSRAM_0_ack        = req_q;
  assign toSRAM_0_selectedOH = all_q | ~req_q | selected;
  assign toSRAM_0_array      = array_q;
endmodule
