// =============================================================================
// FTBBank（golden 同名顶层 wrapper）—— 机械端口适配层
//
// 作用：把可读核 xs_FTBBank 的 struct/数组端口拆成 golden 扁平端口，并在内部例化
//       golden 同名 SRAM bank（SplittedSRAMTemplate_2）。供 FM 等价比对与 ST 替换。
//
// 本层只做端口搬运，不含算法逻辑（算法全在 xs_FTBBank 与 SRAM 内）。
//
// 关于 MBIST / bore 扫描链：
//   golden FTBBank 内还例化了一个 MbistPipeFtb，把模块级 boreChildrenBd_bore_*
//   （MbistPipe 形态：array/all/req/writeen/be/addr/indata/readen/addr_rd/outdata）
//   翻译成 SRAM 的 8 套 bore（addr/wdata/.../rdata）。这条扫描链对 FTB 的功能输出
//   （read_resp/hits/update_hits 等）无任何影响，是可测性逻辑。本工程以学习微架构为
//   目的，不重写 MBIST：故这里把 SRAM 的 8 套 bore 就地 tie-off，并把模块级的
//   bore 输出 tie 0。FM 对 MBIST 路径为不可判/不匹配的 unread 点（文档已注明）。
// =============================================================================
module FTBBank_xs
  import xs_ftb_pkg::*;
(
  input         clock,
  input         reset,
  input         io_s1_fire,
  output        io_req_pc_ready,
  input         io_req_pc_valid,
  input  [49:0] io_req_pc_bits,
  output        io_read_resp_isCall,
  output        io_read_resp_isRet,
  output        io_read_resp_isJalr,
  output        io_read_resp_valid,
  output [3:0]  io_read_resp_brSlots_0_offset,
  output        io_read_resp_brSlots_0_sharing,
  output        io_read_resp_brSlots_0_valid,
  output [11:0] io_read_resp_brSlots_0_lower,
  output [1:0]  io_read_resp_brSlots_0_tarStat,
  output [3:0]  io_read_resp_tailSlot_offset,
  output        io_read_resp_tailSlot_sharing,
  output        io_read_resp_tailSlot_valid,
  output [19:0] io_read_resp_tailSlot_lower,
  output [1:0]  io_read_resp_tailSlot_tarStat,
  output [3:0]  io_read_resp_pftAddr,
  output        io_read_resp_carry,
  output        io_read_resp_last_may_be_rvi_call,
  output        io_read_resp_strong_bias_0,
  output        io_read_resp_strong_bias_1,
  output        io_read_hits_valid,
  output [1:0]  io_read_hits_bits,
  output        io_read_multi_entry_isCall,
  output        io_read_multi_entry_isRet,
  output        io_read_multi_entry_isJalr,
  output        io_read_multi_entry_valid,
  output [3:0]  io_read_multi_entry_brSlots_0_offset,
  output        io_read_multi_entry_brSlots_0_sharing,
  output        io_read_multi_entry_brSlots_0_valid,
  output [11:0] io_read_multi_entry_brSlots_0_lower,
  output [1:0]  io_read_multi_entry_brSlots_0_tarStat,
  output [3:0]  io_read_multi_entry_tailSlot_offset,
  output        io_read_multi_entry_tailSlot_sharing,
  output        io_read_multi_entry_tailSlot_valid,
  output [19:0] io_read_multi_entry_tailSlot_lower,
  output [1:0]  io_read_multi_entry_tailSlot_tarStat,
  output [3:0]  io_read_multi_entry_pftAddr,
  output        io_read_multi_entry_carry,
  output        io_read_multi_entry_last_may_be_rvi_call,
  output        io_read_multi_entry_strong_bias_0,
  output        io_read_multi_entry_strong_bias_1,
  output        io_read_multi_hits_valid,
  output [1:0]  io_read_multi_hits_bits,
  input         io_u_req_pc_valid,
  input  [49:0] io_u_req_pc_bits,
  output        io_update_hits_valid,
  output [1:0]  io_update_hits_bits,
  input         io_update_access,
  input  [49:0] io_update_pc,
  input         io_update_write_data_valid,
  input         io_update_write_data_bits_entry_isCall,
  input         io_update_write_data_bits_entry_isRet,
  input         io_update_write_data_bits_entry_isJalr,
  input         io_update_write_data_bits_entry_valid,
  input  [3:0]  io_update_write_data_bits_entry_brSlots_0_offset,
  input         io_update_write_data_bits_entry_brSlots_0_sharing,
  input         io_update_write_data_bits_entry_brSlots_0_valid,
  input  [11:0] io_update_write_data_bits_entry_brSlots_0_lower,
  input  [1:0]  io_update_write_data_bits_entry_brSlots_0_tarStat,
  input  [3:0]  io_update_write_data_bits_entry_tailSlot_offset,
  input         io_update_write_data_bits_entry_tailSlot_sharing,
  input         io_update_write_data_bits_entry_tailSlot_valid,
  input  [19:0] io_update_write_data_bits_entry_tailSlot_lower,
  input  [1:0]  io_update_write_data_bits_entry_tailSlot_tarStat,
  input  [3:0]  io_update_write_data_bits_entry_pftAddr,
  input         io_update_write_data_bits_entry_carry,
  input         io_update_write_data_bits_entry_last_may_be_rvi_call,
  input         io_update_write_data_bits_entry_strong_bias_0,
  input         io_update_write_data_bits_entry_strong_bias_1,
  input  [19:0] io_update_write_data_bits_tag,
  input  [1:0]  io_update_write_way,
  input         io_update_write_alloc,
  input  [5:0]  boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input  [3:0]  boreChildrenBd_bore_be,
  input  [9:0]  boreChildrenBd_bore_addr,
  input  [39:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [9:0]  boreChildrenBd_bore_addr_rd,
  output [39:0] boreChildrenBd_bore_outdata,
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
  input         sigFromSrams_bore_3_cgen,
  input         sigFromSrams_bore_4_ram_hold,
  input         sigFromSrams_bore_4_ram_bypass,
  input         sigFromSrams_bore_4_ram_bp_clken,
  input         sigFromSrams_bore_4_ram_aux_clk,
  input         sigFromSrams_bore_4_ram_aux_ckbp,
  input         sigFromSrams_bore_4_ram_mcp_hold,
  input         sigFromSrams_bore_4_cgen,
  input         sigFromSrams_bore_5_ram_hold,
  input         sigFromSrams_bore_5_ram_bypass,
  input         sigFromSrams_bore_5_ram_bp_clken,
  input         sigFromSrams_bore_5_ram_aux_clk,
  input         sigFromSrams_bore_5_ram_aux_ckbp,
  input         sigFromSrams_bore_5_ram_mcp_hold,
  input         sigFromSrams_bore_5_cgen,
  input         sigFromSrams_bore_6_ram_hold,
  input         sigFromSrams_bore_6_ram_bypass,
  input         sigFromSrams_bore_6_ram_bp_clken,
  input         sigFromSrams_bore_6_ram_aux_clk,
  input         sigFromSrams_bore_6_ram_aux_ckbp,
  input         sigFromSrams_bore_6_ram_mcp_hold,
  input         sigFromSrams_bore_6_cgen,
  input         sigFromSrams_bore_7_ram_hold,
  input         sigFromSrams_bore_7_ram_bypass,
  input         sigFromSrams_bore_7_ram_bp_clken,
  input         sigFromSrams_bore_7_ram_aux_clk,
  input         sigFromSrams_bore_7_ram_aux_ckbp,
  input         sigFromSrams_bore_7_ram_mcp_hold,
  input         sigFromSrams_bore_7_cgen
);

  // ---- 扁平更新写条目 → struct ----
  ftb_entry_t update_write_entry;
  always_comb begin
    update_write_entry = '0;
    update_write_entry.valid                = io_update_write_data_bits_entry_valid;
    update_write_entry.isCall               = io_update_write_data_bits_entry_isCall;
    update_write_entry.isRet                = io_update_write_data_bits_entry_isRet;
    update_write_entry.isJalr               = io_update_write_data_bits_entry_isJalr;
    update_write_entry.brSlot.offset        = io_update_write_data_bits_entry_brSlots_0_offset;
    update_write_entry.brSlot.sharing       = io_update_write_data_bits_entry_brSlots_0_sharing;
    update_write_entry.brSlot.valid         = io_update_write_data_bits_entry_brSlots_0_valid;
    update_write_entry.brSlot.lower         = {{(20-12){1'b0}}, io_update_write_data_bits_entry_brSlots_0_lower};
    update_write_entry.brSlot.tarStat       = io_update_write_data_bits_entry_brSlots_0_tarStat;
    update_write_entry.tailSlot.offset      = io_update_write_data_bits_entry_tailSlot_offset;
    update_write_entry.tailSlot.sharing     = io_update_write_data_bits_entry_tailSlot_sharing;
    update_write_entry.tailSlot.valid       = io_update_write_data_bits_entry_tailSlot_valid;
    update_write_entry.tailSlot.lower       = io_update_write_data_bits_entry_tailSlot_lower;
    update_write_entry.tailSlot.tarStat     = io_update_write_data_bits_entry_tailSlot_tarStat;
    update_write_entry.pftAddr              = io_update_write_data_bits_entry_pftAddr;
    update_write_entry.carry                = io_update_write_data_bits_entry_carry;
    update_write_entry.last_may_be_rvi_call = io_update_write_data_bits_entry_last_may_be_rvi_call;
    update_write_entry.strong_bias          = {io_update_write_data_bits_entry_strong_bias_1,
                                               io_update_write_data_bits_entry_strong_bias_0};
  end

  // ---- 核 ↔ SRAM 之间的连线 ----
  logic             sram_r_req_valid;
  logic [8:0]       sram_r_req_setIdx;
  logic             sram_r_req_ready;
  ftb_entry_t       sram_r_entry [4];
  logic [19:0]      sram_r_tag   [4];
  logic             sram_w_req_valid;
  logic [8:0]       sram_w_req_setIdx;
  ftb_entry_t       sram_w_entry;
  logic [19:0]      sram_w_tag;
  logic [3:0]       sram_w_waymask;

  // ---- 核输出结构体 → 扁平端口 ----
  ftb_entry_t read_resp, read_multi_entry;

  assign io_read_resp_isCall               = read_resp.isCall;
  assign io_read_resp_isRet                = read_resp.isRet;
  assign io_read_resp_isJalr               = read_resp.isJalr;
  assign io_read_resp_valid                = read_resp.valid;
  assign io_read_resp_brSlots_0_offset     = read_resp.brSlot.offset;
  assign io_read_resp_brSlots_0_sharing    = read_resp.brSlot.sharing;
  assign io_read_resp_brSlots_0_valid      = read_resp.brSlot.valid;
  assign io_read_resp_brSlots_0_lower      = read_resp.brSlot.lower[11:0];
  assign io_read_resp_brSlots_0_tarStat    = read_resp.brSlot.tarStat;
  assign io_read_resp_tailSlot_offset      = read_resp.tailSlot.offset;
  assign io_read_resp_tailSlot_sharing     = read_resp.tailSlot.sharing;
  assign io_read_resp_tailSlot_valid       = read_resp.tailSlot.valid;
  assign io_read_resp_tailSlot_lower       = read_resp.tailSlot.lower;
  assign io_read_resp_tailSlot_tarStat     = read_resp.tailSlot.tarStat;
  assign io_read_resp_pftAddr              = read_resp.pftAddr;
  assign io_read_resp_carry                = read_resp.carry;
  assign io_read_resp_last_may_be_rvi_call = read_resp.last_may_be_rvi_call;
  assign io_read_resp_strong_bias_0        = read_resp.strong_bias[0];
  assign io_read_resp_strong_bias_1        = read_resp.strong_bias[1];

  assign io_read_multi_entry_isCall               = read_multi_entry.isCall;
  assign io_read_multi_entry_isRet                = read_multi_entry.isRet;
  assign io_read_multi_entry_isJalr               = read_multi_entry.isJalr;
  assign io_read_multi_entry_valid                = read_multi_entry.valid;
  assign io_read_multi_entry_brSlots_0_offset     = read_multi_entry.brSlot.offset;
  assign io_read_multi_entry_brSlots_0_sharing    = read_multi_entry.brSlot.sharing;
  assign io_read_multi_entry_brSlots_0_valid      = read_multi_entry.brSlot.valid;
  assign io_read_multi_entry_brSlots_0_lower      = read_multi_entry.brSlot.lower[11:0];
  assign io_read_multi_entry_brSlots_0_tarStat    = read_multi_entry.brSlot.tarStat;
  assign io_read_multi_entry_tailSlot_offset      = read_multi_entry.tailSlot.offset;
  assign io_read_multi_entry_tailSlot_sharing     = read_multi_entry.tailSlot.sharing;
  assign io_read_multi_entry_tailSlot_valid       = read_multi_entry.tailSlot.valid;
  assign io_read_multi_entry_tailSlot_lower       = read_multi_entry.tailSlot.lower;
  assign io_read_multi_entry_tailSlot_tarStat     = read_multi_entry.tailSlot.tarStat;
  assign io_read_multi_entry_pftAddr              = read_multi_entry.pftAddr;
  assign io_read_multi_entry_carry                = read_multi_entry.carry;
  assign io_read_multi_entry_last_may_be_rvi_call = read_multi_entry.last_may_be_rvi_call;
  assign io_read_multi_entry_strong_bias_0        = read_multi_entry.strong_bias[0];
  assign io_read_multi_entry_strong_bias_1        = read_multi_entry.strong_bias[1];

  // ---- 可读核 ----
  xs_FTBBank u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_s1_fire             (io_s1_fire),
    .io_req_pc_ready        (io_req_pc_ready),
    .io_req_pc_valid        (io_req_pc_valid),
    .io_req_pc_bits         (io_req_pc_bits),
    .read_resp              (read_resp),
    .io_read_hits_valid     (io_read_hits_valid),
    .io_read_hits_bits      (io_read_hits_bits),
    .read_multi_entry       (read_multi_entry),
    .io_read_multi_hits_valid(io_read_multi_hits_valid),
    .io_read_multi_hits_bits (io_read_multi_hits_bits),
    .io_u_req_pc_valid      (io_u_req_pc_valid),
    .io_u_req_pc_bits       (io_u_req_pc_bits),
    .io_update_hits_valid   (io_update_hits_valid),
    .io_update_hits_bits    (io_update_hits_bits),
    .io_update_access       (io_update_access),
    .io_update_pc           (io_update_pc),
    .io_update_write_data_valid(io_update_write_data_valid),
    .update_write_entry     (update_write_entry),
    .update_write_tag       (io_update_write_data_bits_tag),
    .io_update_write_way    (io_update_write_way),
    .io_update_write_alloc  (io_update_write_alloc),
    .sram_r_req_valid       (sram_r_req_valid),
    .sram_r_req_setIdx      (sram_r_req_setIdx),
    .sram_r_req_ready       (sram_r_req_ready),
    .sram_r_entry           (sram_r_entry),
    .sram_r_tag             (sram_r_tag),
    .sram_w_req_valid       (sram_w_req_valid),
    .sram_w_req_setIdx      (sram_w_req_setIdx),
    .sram_w_entry           (sram_w_entry),
    .sram_w_tag             (sram_w_tag),
    .sram_w_waymask         (sram_w_waymask)
  );

  // ---- golden 同名 SRAM bank：扁平端口 ↔ 核的 struct 数组 ----
  `define XS_SRAM_RD(N) \
    .io_r_resp_data_``N``_entry_isCall(sram_r_entry[N].isCall), \
    .io_r_resp_data_``N``_entry_isRet(sram_r_entry[N].isRet), \
    .io_r_resp_data_``N``_entry_isJalr(sram_r_entry[N].isJalr), \
    .io_r_resp_data_``N``_entry_valid(sram_r_entry[N].valid), \
    .io_r_resp_data_``N``_entry_brSlots_0_offset(sram_r_entry[N].brSlot.offset), \
    .io_r_resp_data_``N``_entry_brSlots_0_sharing(sram_r_entry[N].brSlot.sharing), \
    .io_r_resp_data_``N``_entry_brSlots_0_valid(sram_r_entry[N].brSlot.valid), \
    .io_r_resp_data_``N``_entry_brSlots_0_lower(sram_r_entry[N].brSlot.lower[11:0]), \
    .io_r_resp_data_``N``_entry_brSlots_0_tarStat(sram_r_entry[N].brSlot.tarStat), \
    .io_r_resp_data_``N``_entry_tailSlot_offset(sram_r_entry[N].tailSlot.offset), \
    .io_r_resp_data_``N``_entry_tailSlot_sharing(sram_r_entry[N].tailSlot.sharing), \
    .io_r_resp_data_``N``_entry_tailSlot_valid(sram_r_entry[N].tailSlot.valid), \
    .io_r_resp_data_``N``_entry_tailSlot_lower(sram_r_entry[N].tailSlot.lower), \
    .io_r_resp_data_``N``_entry_tailSlot_tarStat(sram_r_entry[N].tailSlot.tarStat), \
    .io_r_resp_data_``N``_entry_pftAddr(sram_r_entry[N].pftAddr), \
    .io_r_resp_data_``N``_entry_carry(sram_r_entry[N].carry), \
    .io_r_resp_data_``N``_entry_last_may_be_rvi_call(sram_r_entry[N].last_may_be_rvi_call), \
    .io_r_resp_data_``N``_entry_strong_bias_0(sram_r_entry[N].strong_bias[0]), \
    .io_r_resp_data_``N``_entry_strong_bias_1(sram_r_entry[N].strong_bias[1]), \
    .io_r_resp_data_``N``_tag(sram_r_tag[N])
  // 写口：4 路同条目/同 tag（waymask 选实际写入路）。brSlot.lower 取低 12 位。
  `define XS_SRAM_WR(N) \
    .io_w_req_bits_data_``N``_entry_isCall(sram_w_entry.isCall), \
    .io_w_req_bits_data_``N``_entry_isRet(sram_w_entry.isRet), \
    .io_w_req_bits_data_``N``_entry_isJalr(sram_w_entry.isJalr), \
    .io_w_req_bits_data_``N``_entry_valid(sram_w_entry.valid), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_offset(sram_w_entry.brSlot.offset), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_sharing(sram_w_entry.brSlot.sharing), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_valid(sram_w_entry.brSlot.valid), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_lower(sram_w_entry.brSlot.lower[11:0]), \
    .io_w_req_bits_data_``N``_entry_brSlots_0_tarStat(sram_w_entry.brSlot.tarStat), \
    .io_w_req_bits_data_``N``_entry_tailSlot_offset(sram_w_entry.tailSlot.offset), \
    .io_w_req_bits_data_``N``_entry_tailSlot_sharing(sram_w_entry.tailSlot.sharing), \
    .io_w_req_bits_data_``N``_entry_tailSlot_valid(sram_w_entry.tailSlot.valid), \
    .io_w_req_bits_data_``N``_entry_tailSlot_lower(sram_w_entry.tailSlot.lower), \
    .io_w_req_bits_data_``N``_entry_tailSlot_tarStat(sram_w_entry.tailSlot.tarStat), \
    .io_w_req_bits_data_``N``_entry_pftAddr(sram_w_entry.pftAddr), \
    .io_w_req_bits_data_``N``_entry_carry(sram_w_entry.carry), \
    .io_w_req_bits_data_``N``_entry_last_may_be_rvi_call(sram_w_entry.last_may_be_rvi_call), \
    .io_w_req_bits_data_``N``_entry_strong_bias_0(sram_w_entry.strong_bias[0]), \
    .io_w_req_bits_data_``N``_entry_strong_bias_1(sram_w_entry.strong_bias[1]), \
    .io_w_req_bits_data_``N``_tag(sram_w_tag)

  // ===== MBIST / bore 扫描链：与 golden 完全相同的机械接线（MbistPipeFtb 黑盒） =====
  // golden 把模块级 boreChildrenBd_bore_*（MbistPipe 形态）经 MbistPipeFtb 翻译成 SRAM
  // 的 8 套 bore（childBd_*）。这段对 FTB 功能输出无影响，纯 DFT；原样保留以使 FM 两侧
  // 黑盒实例（SplittedSRAMTemplate_2 / MbistPipeFtb）的连接一致。
  wire [39:0]       bd_outdata;
  wire              bd_ack;
  wire [39:0]       childBd_7_rdata, childBd_6_rdata, childBd_5_rdata, childBd_4_rdata;
  wire [39:0]       childBd_3_rdata, childBd_2_rdata, childBd_1_rdata, childBd_rdata;
  wire [5:0]        bd_array   = boreChildrenBd_bore_array;
  wire              bd_all     = boreChildrenBd_bore_all;
  wire              bd_req     = boreChildrenBd_bore_req;
  wire              bd_writeen = boreChildrenBd_bore_writeen;
  wire [3:0]        bd_be      = boreChildrenBd_bore_be;
  wire [9:0]        bd_addr    = boreChildrenBd_bore_addr;
  wire [39:0]       bd_indata  = boreChildrenBd_bore_indata;
  wire              bd_readen  = boreChildrenBd_bore_readen;
  wire [9:0]        bd_addr_rd = boreChildrenBd_bore_addr_rd;
  wire [9:0]        childBd_addr, childBd_addr_rd;     wire [39:0] childBd_wdata;
  wire [3:0]        childBd_wmask;  wire childBd_re, childBd_we, childBd_ack, childBd_selectedOH;
  wire [5:0]        childBd_array;
  wire [9:0]        childBd_1_addr, childBd_1_addr_rd; wire [39:0] childBd_1_wdata;
  wire [3:0]        childBd_1_wmask; wire childBd_1_re, childBd_1_we, childBd_1_ack, childBd_1_selectedOH;
  wire [5:0]        childBd_1_array;
  wire [9:0]        childBd_2_addr, childBd_2_addr_rd; wire [39:0] childBd_2_wdata;
  wire [3:0]        childBd_2_wmask; wire childBd_2_re, childBd_2_we, childBd_2_ack, childBd_2_selectedOH;
  wire [5:0]        childBd_2_array;
  wire [9:0]        childBd_3_addr, childBd_3_addr_rd; wire [39:0] childBd_3_wdata;
  wire [3:0]        childBd_3_wmask; wire childBd_3_re, childBd_3_we, childBd_3_ack, childBd_3_selectedOH;
  wire [5:0]        childBd_3_array;
  wire [9:0]        childBd_4_addr, childBd_4_addr_rd; wire [39:0] childBd_4_wdata;
  wire [3:0]        childBd_4_wmask; wire childBd_4_re, childBd_4_we, childBd_4_ack, childBd_4_selectedOH;
  wire [5:0]        childBd_4_array;
  wire [9:0]        childBd_5_addr, childBd_5_addr_rd; wire [39:0] childBd_5_wdata;
  wire [3:0]        childBd_5_wmask; wire childBd_5_re, childBd_5_we, childBd_5_ack, childBd_5_selectedOH;
  wire [5:0]        childBd_5_array;
  wire [9:0]        childBd_6_addr, childBd_6_addr_rd; wire [39:0] childBd_6_wdata;
  wire [3:0]        childBd_6_wmask; wire childBd_6_re, childBd_6_we, childBd_6_ack, childBd_6_selectedOH;
  wire [5:0]        childBd_6_array;
  wire [9:0]        childBd_7_addr, childBd_7_addr_rd; wire [39:0] childBd_7_wdata;
  wire [3:0]        childBd_7_wmask; wire childBd_7_re, childBd_7_we, childBd_7_ack, childBd_7_selectedOH;
  wire [5:0]        childBd_7_array;

  SplittedSRAMTemplate_2 ftb (
    .clock                 (clock),
    .reset                 (reset),
    .io_r_req_ready        (sram_r_req_ready),
    .io_r_req_valid        (sram_r_req_valid),
    .io_r_req_bits_setIdx  (sram_r_req_setIdx),
    `XS_SRAM_RD(0), `XS_SRAM_RD(1), `XS_SRAM_RD(2), `XS_SRAM_RD(3),
    .io_w_req_valid        (sram_w_req_valid),
    .io_w_req_bits_setIdx  (sram_w_req_setIdx),
    `XS_SRAM_WR(0), `XS_SRAM_WR(1), `XS_SRAM_WR(2), `XS_SRAM_WR(3),
    .io_w_req_bits_waymask (sram_w_waymask),
    .boreChildrenBd_bore_addr                        (childBd_addr),
    .boreChildrenBd_bore_addr_rd                     (childBd_addr_rd),
    .boreChildrenBd_bore_wdata                       (childBd_wdata),
    .boreChildrenBd_bore_wmask                       (childBd_wmask),
    .boreChildrenBd_bore_re                          (childBd_re),
    .boreChildrenBd_bore_we                          (childBd_we),
    .boreChildrenBd_bore_rdata                       (childBd_rdata),
    .boreChildrenBd_bore_ack                         (childBd_ack),
    .boreChildrenBd_bore_selectedOH                  (childBd_selectedOH),
    .boreChildrenBd_bore_array                       (childBd_array),
    .boreChildrenBd_bore_1_addr                      (childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd                   (childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata                     (childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask                     (childBd_1_wmask),
    .boreChildrenBd_bore_1_re                        (childBd_1_re),
    .boreChildrenBd_bore_1_we                        (childBd_1_we),
    .boreChildrenBd_bore_1_rdata                     (childBd_1_rdata),
    .boreChildrenBd_bore_1_ack                       (childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH                (childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array                     (childBd_1_array),
    .boreChildrenBd_bore_2_addr                      (childBd_2_addr),
    .boreChildrenBd_bore_2_addr_rd                   (childBd_2_addr_rd),
    .boreChildrenBd_bore_2_wdata                     (childBd_2_wdata),
    .boreChildrenBd_bore_2_wmask                     (childBd_2_wmask),
    .boreChildrenBd_bore_2_re                        (childBd_2_re),
    .boreChildrenBd_bore_2_we                        (childBd_2_we),
    .boreChildrenBd_bore_2_rdata                     (childBd_2_rdata),
    .boreChildrenBd_bore_2_ack                       (childBd_2_ack),
    .boreChildrenBd_bore_2_selectedOH                (childBd_2_selectedOH),
    .boreChildrenBd_bore_2_array                     (childBd_2_array),
    .boreChildrenBd_bore_3_addr                      (childBd_3_addr),
    .boreChildrenBd_bore_3_addr_rd                   (childBd_3_addr_rd),
    .boreChildrenBd_bore_3_wdata                     (childBd_3_wdata),
    .boreChildrenBd_bore_3_wmask                     (childBd_3_wmask),
    .boreChildrenBd_bore_3_re                        (childBd_3_re),
    .boreChildrenBd_bore_3_we                        (childBd_3_we),
    .boreChildrenBd_bore_3_rdata                     (childBd_3_rdata),
    .boreChildrenBd_bore_3_ack                       (childBd_3_ack),
    .boreChildrenBd_bore_3_selectedOH                (childBd_3_selectedOH),
    .boreChildrenBd_bore_3_array                     (childBd_3_array),
    .boreChildrenBd_bore_4_addr                      (childBd_4_addr),
    .boreChildrenBd_bore_4_addr_rd                   (childBd_4_addr_rd),
    .boreChildrenBd_bore_4_wdata                     (childBd_4_wdata),
    .boreChildrenBd_bore_4_wmask                     (childBd_4_wmask),
    .boreChildrenBd_bore_4_re                        (childBd_4_re),
    .boreChildrenBd_bore_4_we                        (childBd_4_we),
    .boreChildrenBd_bore_4_rdata                     (childBd_4_rdata),
    .boreChildrenBd_bore_4_ack                       (childBd_4_ack),
    .boreChildrenBd_bore_4_selectedOH                (childBd_4_selectedOH),
    .boreChildrenBd_bore_4_array                     (childBd_4_array),
    .boreChildrenBd_bore_5_addr                      (childBd_5_addr),
    .boreChildrenBd_bore_5_addr_rd                   (childBd_5_addr_rd),
    .boreChildrenBd_bore_5_wdata                     (childBd_5_wdata),
    .boreChildrenBd_bore_5_wmask                     (childBd_5_wmask),
    .boreChildrenBd_bore_5_re                        (childBd_5_re),
    .boreChildrenBd_bore_5_we                        (childBd_5_we),
    .boreChildrenBd_bore_5_rdata                     (childBd_5_rdata),
    .boreChildrenBd_bore_5_ack                       (childBd_5_ack),
    .boreChildrenBd_bore_5_selectedOH                (childBd_5_selectedOH),
    .boreChildrenBd_bore_5_array                     (childBd_5_array),
    .boreChildrenBd_bore_6_addr                      (childBd_6_addr),
    .boreChildrenBd_bore_6_addr_rd                   (childBd_6_addr_rd),
    .boreChildrenBd_bore_6_wdata                     (childBd_6_wdata),
    .boreChildrenBd_bore_6_wmask                     (childBd_6_wmask),
    .boreChildrenBd_bore_6_re                        (childBd_6_re),
    .boreChildrenBd_bore_6_we                        (childBd_6_we),
    .boreChildrenBd_bore_6_rdata                     (childBd_6_rdata),
    .boreChildrenBd_bore_6_ack                       (childBd_6_ack),
    .boreChildrenBd_bore_6_selectedOH                (childBd_6_selectedOH),
    .boreChildrenBd_bore_6_array                     (childBd_6_array),
    .boreChildrenBd_bore_7_addr                      (childBd_7_addr),
    .boreChildrenBd_bore_7_addr_rd                   (childBd_7_addr_rd),
    .boreChildrenBd_bore_7_wdata                     (childBd_7_wdata),
    .boreChildrenBd_bore_7_wmask                     (childBd_7_wmask),
    .boreChildrenBd_bore_7_re                        (childBd_7_re),
    .boreChildrenBd_bore_7_we                        (childBd_7_we),
    .boreChildrenBd_bore_7_rdata                     (childBd_7_rdata),
    .boreChildrenBd_bore_7_ack                       (childBd_7_ack),
    .boreChildrenBd_bore_7_selectedOH                (childBd_7_selectedOH),
    .boreChildrenBd_bore_7_array                     (childBd_7_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold   (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen       (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold   (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen       (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold   (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen       (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold   (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen       (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold   (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen       (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold   (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen       (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold   (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen       (sigFromSrams_bore_7_cgen)
  );

  // MbistPipeFtb（黑盒）：把模块级 MbistPipe 接口翻译成 SRAM 的 8 套 childBd（与 golden 同）
  MbistPipeFtb mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (bd_array),
    .mbist_all           (bd_all),
    .mbist_req           (bd_req),
    .mbist_ack           (bd_ack),
    .mbist_writeen       (bd_writeen),
    .mbist_be            (bd_be),
    .mbist_addr          (bd_addr),
    .mbist_indata        (bd_indata),
    .mbist_readen        (bd_readen),
    .mbist_addr_rd       (bd_addr_rd),
    .mbist_outdata       (bd_outdata),
    .toSRAM_0_addr       (childBd_addr),       .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),      .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),         .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),      .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH), .toSRAM_0_array      (childBd_array),
    .toSRAM_1_addr       (childBd_1_addr),     .toSRAM_1_addr_rd    (childBd_1_addr_rd),
    .toSRAM_1_wdata      (childBd_1_wdata),    .toSRAM_1_wmask      (childBd_1_wmask),
    .toSRAM_1_re         (childBd_1_re),       .toSRAM_1_we         (childBd_1_we),
    .toSRAM_1_rdata      (childBd_1_rdata),    .toSRAM_1_ack        (childBd_1_ack),
    .toSRAM_1_selectedOH (childBd_1_selectedOH),.toSRAM_1_array     (childBd_1_array),
    .toSRAM_2_addr       (childBd_2_addr),     .toSRAM_2_addr_rd    (childBd_2_addr_rd),
    .toSRAM_2_wdata      (childBd_2_wdata),    .toSRAM_2_wmask      (childBd_2_wmask),
    .toSRAM_2_re         (childBd_2_re),       .toSRAM_2_we         (childBd_2_we),
    .toSRAM_2_rdata      (childBd_2_rdata),    .toSRAM_2_ack        (childBd_2_ack),
    .toSRAM_2_selectedOH (childBd_2_selectedOH),.toSRAM_2_array     (childBd_2_array),
    .toSRAM_3_addr       (childBd_3_addr),     .toSRAM_3_addr_rd    (childBd_3_addr_rd),
    .toSRAM_3_wdata      (childBd_3_wdata),    .toSRAM_3_wmask      (childBd_3_wmask),
    .toSRAM_3_re         (childBd_3_re),       .toSRAM_3_we         (childBd_3_we),
    .toSRAM_3_rdata      (childBd_3_rdata),    .toSRAM_3_ack        (childBd_3_ack),
    .toSRAM_3_selectedOH (childBd_3_selectedOH),.toSRAM_3_array     (childBd_3_array),
    .toSRAM_4_addr       (childBd_4_addr),     .toSRAM_4_addr_rd    (childBd_4_addr_rd),
    .toSRAM_4_wdata      (childBd_4_wdata),    .toSRAM_4_wmask      (childBd_4_wmask),
    .toSRAM_4_re         (childBd_4_re),       .toSRAM_4_we         (childBd_4_we),
    .toSRAM_4_rdata      (childBd_4_rdata),    .toSRAM_4_ack        (childBd_4_ack),
    .toSRAM_4_selectedOH (childBd_4_selectedOH),.toSRAM_4_array     (childBd_4_array),
    .toSRAM_5_addr       (childBd_5_addr),     .toSRAM_5_addr_rd    (childBd_5_addr_rd),
    .toSRAM_5_wdata      (childBd_5_wdata),    .toSRAM_5_wmask      (childBd_5_wmask),
    .toSRAM_5_re         (childBd_5_re),       .toSRAM_5_we         (childBd_5_we),
    .toSRAM_5_rdata      (childBd_5_rdata),    .toSRAM_5_ack        (childBd_5_ack),
    .toSRAM_5_selectedOH (childBd_5_selectedOH),.toSRAM_5_array     (childBd_5_array),
    .toSRAM_6_addr       (childBd_6_addr),     .toSRAM_6_addr_rd    (childBd_6_addr_rd),
    .toSRAM_6_wdata      (childBd_6_wdata),    .toSRAM_6_wmask      (childBd_6_wmask),
    .toSRAM_6_re         (childBd_6_re),       .toSRAM_6_we         (childBd_6_we),
    .toSRAM_6_rdata      (childBd_6_rdata),    .toSRAM_6_ack        (childBd_6_ack),
    .toSRAM_6_selectedOH (childBd_6_selectedOH),.toSRAM_6_array     (childBd_6_array),
    .toSRAM_7_addr       (childBd_7_addr),     .toSRAM_7_addr_rd    (childBd_7_addr_rd),
    .toSRAM_7_wdata      (childBd_7_wdata),    .toSRAM_7_wmask      (childBd_7_wmask),
    .toSRAM_7_re         (childBd_7_re),       .toSRAM_7_we         (childBd_7_we),
    .toSRAM_7_rdata      (childBd_7_rdata),    .toSRAM_7_ack        (childBd_7_ack),
    .toSRAM_7_selectedOH (childBd_7_selectedOH),.toSRAM_7_array     (childBd_7_array)
  );

  assign boreChildrenBd_bore_ack     = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;

endmodule
