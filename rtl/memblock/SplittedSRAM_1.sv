// SplittedSRAM_1.sv —— PtwCache 的 l1：level-1 非叶 PTE 扇区缓存（SplittedSRAM 家族变体，规模 4 set × 2 way × 393 bit/entry）。
// 本变体参数：tagLen=24、hasPerm=false、ReservedBits=2、waySplit=1、dataSplit=1
//   ⇒ 拆成 1 块内层 SRAM，每块 2 路 × 393 bit（无拆分，整条 entry 一块）。
// 本层无任何寄存器：只做 PtwEntries 的打包/切分/归并，存储与读时序在内层
// SRAMTemplate_* 及其下的厂商 SRAM 宏里。核体见 SplittedSRAM_ptw_core.sv。
// 自动生成：scripts/gen_splittedsram.py（端口表与内层例化连线逐字取自 G1 golden）—— 勿手改。

module SplittedSRAM_1(
  input          clock,
  input          reset,
  input          io_r_req_valid,
  input  [1:0]   io_r_req_bits_setIdx,
  output [23:0]  io_r_resp_data_0_entries_tag,
  output [15:0]  io_r_resp_data_0_entries_asid,
  output [13:0]  io_r_resp_data_0_entries_vmid,
  output [1:0]   io_r_resp_data_0_entries_pbmts_0,
  output [1:0]   io_r_resp_data_0_entries_pbmts_1,
  output [1:0]   io_r_resp_data_0_entries_pbmts_2,
  output [1:0]   io_r_resp_data_0_entries_pbmts_3,
  output [1:0]   io_r_resp_data_0_entries_pbmts_4,
  output [1:0]   io_r_resp_data_0_entries_pbmts_5,
  output [1:0]   io_r_resp_data_0_entries_pbmts_6,
  output [1:0]   io_r_resp_data_0_entries_pbmts_7,
  output [37:0]  io_r_resp_data_0_entries_ppns_0,
  output [37:0]  io_r_resp_data_0_entries_ppns_1,
  output [37:0]  io_r_resp_data_0_entries_ppns_2,
  output [37:0]  io_r_resp_data_0_entries_ppns_3,
  output [37:0]  io_r_resp_data_0_entries_ppns_4,
  output [37:0]  io_r_resp_data_0_entries_ppns_5,
  output [37:0]  io_r_resp_data_0_entries_ppns_6,
  output [37:0]  io_r_resp_data_0_entries_ppns_7,
  output         io_r_resp_data_0_entries_vs_0,
  output         io_r_resp_data_0_entries_vs_1,
  output         io_r_resp_data_0_entries_vs_2,
  output         io_r_resp_data_0_entries_vs_3,
  output         io_r_resp_data_0_entries_vs_4,
  output         io_r_resp_data_0_entries_vs_5,
  output         io_r_resp_data_0_entries_vs_6,
  output         io_r_resp_data_0_entries_vs_7,
  output         io_r_resp_data_0_entries_prefetch,
  output [23:0]  io_r_resp_data_1_entries_tag,
  output [15:0]  io_r_resp_data_1_entries_asid,
  output [13:0]  io_r_resp_data_1_entries_vmid,
  output [1:0]   io_r_resp_data_1_entries_pbmts_0,
  output [1:0]   io_r_resp_data_1_entries_pbmts_1,
  output [1:0]   io_r_resp_data_1_entries_pbmts_2,
  output [1:0]   io_r_resp_data_1_entries_pbmts_3,
  output [1:0]   io_r_resp_data_1_entries_pbmts_4,
  output [1:0]   io_r_resp_data_1_entries_pbmts_5,
  output [1:0]   io_r_resp_data_1_entries_pbmts_6,
  output [1:0]   io_r_resp_data_1_entries_pbmts_7,
  output [37:0]  io_r_resp_data_1_entries_ppns_0,
  output [37:0]  io_r_resp_data_1_entries_ppns_1,
  output [37:0]  io_r_resp_data_1_entries_ppns_2,
  output [37:0]  io_r_resp_data_1_entries_ppns_3,
  output [37:0]  io_r_resp_data_1_entries_ppns_4,
  output [37:0]  io_r_resp_data_1_entries_ppns_5,
  output [37:0]  io_r_resp_data_1_entries_ppns_6,
  output [37:0]  io_r_resp_data_1_entries_ppns_7,
  output         io_r_resp_data_1_entries_vs_0,
  output         io_r_resp_data_1_entries_vs_1,
  output         io_r_resp_data_1_entries_vs_2,
  output         io_r_resp_data_1_entries_vs_3,
  output         io_r_resp_data_1_entries_vs_4,
  output         io_r_resp_data_1_entries_vs_5,
  output         io_r_resp_data_1_entries_vs_6,
  output         io_r_resp_data_1_entries_vs_7,
  output         io_r_resp_data_1_entries_prefetch,
  input          io_w_req_valid,
  input  [1:0]   io_w_req_bits_setIdx,
  input  [23:0]  io_w_req_bits_data_0_entries_tag,
  input  [15:0]  io_w_req_bits_data_0_entries_asid,
  input  [13:0]  io_w_req_bits_data_0_entries_vmid,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_0,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_1,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_2,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_3,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_4,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_5,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_6,
  input  [1:0]   io_w_req_bits_data_0_entries_pbmts_7,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_0,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_1,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_2,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_3,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_4,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_5,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_6,
  input  [37:0]  io_w_req_bits_data_0_entries_ppns_7,
  input          io_w_req_bits_data_0_entries_vs_0,
  input          io_w_req_bits_data_0_entries_vs_1,
  input          io_w_req_bits_data_0_entries_vs_2,
  input          io_w_req_bits_data_0_entries_vs_3,
  input          io_w_req_bits_data_0_entries_vs_4,
  input          io_w_req_bits_data_0_entries_vs_5,
  input          io_w_req_bits_data_0_entries_vs_6,
  input          io_w_req_bits_data_0_entries_vs_7,
  input          io_w_req_bits_data_0_entries_prefetch,
  input  [23:0]  io_w_req_bits_data_1_entries_tag,
  input  [15:0]  io_w_req_bits_data_1_entries_asid,
  input  [13:0]  io_w_req_bits_data_1_entries_vmid,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_0,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_1,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_2,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_3,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_4,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_5,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_6,
  input  [1:0]   io_w_req_bits_data_1_entries_pbmts_7,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_0,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_1,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_2,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_3,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_4,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_5,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_6,
  input  [37:0]  io_w_req_bits_data_1_entries_ppns_7,
  input          io_w_req_bits_data_1_entries_vs_0,
  input          io_w_req_bits_data_1_entries_vs_1,
  input          io_w_req_bits_data_1_entries_vs_2,
  input          io_w_req_bits_data_1_entries_vs_3,
  input          io_w_req_bits_data_1_entries_vs_4,
  input          io_w_req_bits_data_1_entries_vs_5,
  input          io_w_req_bits_data_1_entries_vs_6,
  input          io_w_req_bits_data_1_entries_vs_7,
  input          io_w_req_bits_data_1_entries_prefetch,
  input  [1:0]   io_w_req_bits_waymask,
  input  [2:0]   boreChildrenBd_bore_addr,
  input  [2:0]   boreChildrenBd_bore_addr_rd,
  input  [130:0] boreChildrenBd_bore_wdata,
  input          boreChildrenBd_bore_wmask,
  input          boreChildrenBd_bore_re,
  input          boreChildrenBd_bore_we,
  output [130:0] boreChildrenBd_bore_rdata,
  input          boreChildrenBd_bore_ack,
  input  [5:0]   boreChildrenBd_bore_selectedOH,
  input  [5:0]   boreChildrenBd_bore_array,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen
);

  // --------------------------------------------------------------------------
  // 参数与阵列侧总线
  // --------------------------------------------------------------------------
  localparam int NUM        = 8;
  localparam int TAG_W      = 24;
  localparam int ASID_W     = 16;
  localparam int VMID_W     = 14;
  localparam int PBMT_W     = 2;
  localparam int PPN_W      = 38;
  localparam int PERM_W     = 7;
  localparam int WAY        = 2;
  localparam int WAY_SPLIT  = 1;
  localparam int DATA_SPLIT = 1;
  localparam int WAY_PER    = WAY / WAY_SPLIT;          // = 2
  localparam int NARR       = WAY_SPLIT * DATA_SPLIT;   // = 1
  localparam int SLICE_W    = 393;                // = ENTRY_W(393) / DATA_SPLIT

  // 阵列侧总线：下标 n = way 组号 * DATA_SPLIT + data 段号，
  // 与 golden 的实例名 array_0_<组>_<段>、bore 编号 boreChildrenBd_bore_<n> 同序。
  wire [NARR-1:0][WAY_PER-1:0]              arr_waymask;
  wire [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_wdata;
  wire [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_rdata;

  // 写入的 PtwEntries 字段，按 [路][Vec 下标] 聚成数组（核的位向量口按此序）
  wire [WAY-1:0][TAG_W-1:0]            wr_tag;
  wire [WAY-1:0][ASID_W-1:0]           wr_asid;
  wire [WAY-1:0][VMID_W-1:0]           wr_vmid;
  wire [WAY-1:0][NUM-1:0][PBMT_W-1:0]  wr_pbmt;
  wire [WAY-1:0][NUM-1:0][PPN_W-1:0]   wr_ppn;
  wire [WAY-1:0][NUM-1:0]              wr_vs;
  wire [WAY-1:0][NUM-1:0]              wr_onlypf;
  wire [WAY-1:0][NUM-1:0][PERM_W-1:0]  wr_perm;
  wire [WAY-1:0]                       wr_pref;

  // 读出的 PtwEntries 字段，按 [路][Vec 下标] 聚成数组（核的位向量口按此序）
  wire [WAY-1:0][TAG_W-1:0]            rd_tag;
  wire [WAY-1:0][ASID_W-1:0]           rd_asid;
  wire [WAY-1:0][VMID_W-1:0]           rd_vmid;
  wire [WAY-1:0][NUM-1:0][PBMT_W-1:0]  rd_pbmt;
  wire [WAY-1:0][NUM-1:0][PPN_W-1:0]   rd_ppn;
  wire [WAY-1:0][NUM-1:0]              rd_vs;
  wire [WAY-1:0][NUM-1:0]              rd_onlypf;
  wire [WAY-1:0][NUM-1:0][PERM_W-1:0]  rd_perm;
  wire [WAY-1:0]                       rd_pref;

  // --------------------------------------------------------------------------
  // 打包/切分核 u_core：写侧接线（路号高者在高位、Vec 下标大者在高位）
  // 写侧字段收集：golden 的扁平端口 → [路][下标] 数组
  assign wr_tag [0] = io_w_req_bits_data_0_entries_tag;
  assign wr_asid[0] = io_w_req_bits_data_0_entries_asid;
  assign wr_vmid[0] = io_w_req_bits_data_0_entries_vmid;
  assign wr_pref[0] = io_w_req_bits_data_0_entries_prefetch;
  assign wr_pbmt[0][0] = io_w_req_bits_data_0_entries_pbmts_0;
  assign wr_pbmt[0][1] = io_w_req_bits_data_0_entries_pbmts_1;
  assign wr_pbmt[0][2] = io_w_req_bits_data_0_entries_pbmts_2;
  assign wr_pbmt[0][3] = io_w_req_bits_data_0_entries_pbmts_3;
  assign wr_pbmt[0][4] = io_w_req_bits_data_0_entries_pbmts_4;
  assign wr_pbmt[0][5] = io_w_req_bits_data_0_entries_pbmts_5;
  assign wr_pbmt[0][6] = io_w_req_bits_data_0_entries_pbmts_6;
  assign wr_pbmt[0][7] = io_w_req_bits_data_0_entries_pbmts_7;
  assign wr_ppn [0][0] = io_w_req_bits_data_0_entries_ppns_0;
  assign wr_ppn [0][1] = io_w_req_bits_data_0_entries_ppns_1;
  assign wr_ppn [0][2] = io_w_req_bits_data_0_entries_ppns_2;
  assign wr_ppn [0][3] = io_w_req_bits_data_0_entries_ppns_3;
  assign wr_ppn [0][4] = io_w_req_bits_data_0_entries_ppns_4;
  assign wr_ppn [0][5] = io_w_req_bits_data_0_entries_ppns_5;
  assign wr_ppn [0][6] = io_w_req_bits_data_0_entries_ppns_6;
  assign wr_ppn [0][7] = io_w_req_bits_data_0_entries_ppns_7;
  assign wr_vs  [0][0] = io_w_req_bits_data_0_entries_vs_0;
  assign wr_vs  [0][1] = io_w_req_bits_data_0_entries_vs_1;
  assign wr_vs  [0][2] = io_w_req_bits_data_0_entries_vs_2;
  assign wr_vs  [0][3] = io_w_req_bits_data_0_entries_vs_3;
  assign wr_vs  [0][4] = io_w_req_bits_data_0_entries_vs_4;
  assign wr_vs  [0][5] = io_w_req_bits_data_0_entries_vs_5;
  assign wr_vs  [0][6] = io_w_req_bits_data_0_entries_vs_6;
  assign wr_vs  [0][7] = io_w_req_bits_data_0_entries_vs_7;
  // l1 的 PtwEntries 没有 perms；onlypf 虽在 bundle 里但 PtwCache 不写也不读，
  //   golden 的写拼接里就是一串 0（8'h0），读侧连端口都被 firtool 消掉了。
  assign wr_onlypf[0] = '0;
  assign wr_perm[0] = '0;
  assign wr_tag [1] = io_w_req_bits_data_1_entries_tag;
  assign wr_asid[1] = io_w_req_bits_data_1_entries_asid;
  assign wr_vmid[1] = io_w_req_bits_data_1_entries_vmid;
  assign wr_pref[1] = io_w_req_bits_data_1_entries_prefetch;
  assign wr_pbmt[1][0] = io_w_req_bits_data_1_entries_pbmts_0;
  assign wr_pbmt[1][1] = io_w_req_bits_data_1_entries_pbmts_1;
  assign wr_pbmt[1][2] = io_w_req_bits_data_1_entries_pbmts_2;
  assign wr_pbmt[1][3] = io_w_req_bits_data_1_entries_pbmts_3;
  assign wr_pbmt[1][4] = io_w_req_bits_data_1_entries_pbmts_4;
  assign wr_pbmt[1][5] = io_w_req_bits_data_1_entries_pbmts_5;
  assign wr_pbmt[1][6] = io_w_req_bits_data_1_entries_pbmts_6;
  assign wr_pbmt[1][7] = io_w_req_bits_data_1_entries_pbmts_7;
  assign wr_ppn [1][0] = io_w_req_bits_data_1_entries_ppns_0;
  assign wr_ppn [1][1] = io_w_req_bits_data_1_entries_ppns_1;
  assign wr_ppn [1][2] = io_w_req_bits_data_1_entries_ppns_2;
  assign wr_ppn [1][3] = io_w_req_bits_data_1_entries_ppns_3;
  assign wr_ppn [1][4] = io_w_req_bits_data_1_entries_ppns_4;
  assign wr_ppn [1][5] = io_w_req_bits_data_1_entries_ppns_5;
  assign wr_ppn [1][6] = io_w_req_bits_data_1_entries_ppns_6;
  assign wr_ppn [1][7] = io_w_req_bits_data_1_entries_ppns_7;
  assign wr_vs  [1][0] = io_w_req_bits_data_1_entries_vs_0;
  assign wr_vs  [1][1] = io_w_req_bits_data_1_entries_vs_1;
  assign wr_vs  [1][2] = io_w_req_bits_data_1_entries_vs_2;
  assign wr_vs  [1][3] = io_w_req_bits_data_1_entries_vs_3;
  assign wr_vs  [1][4] = io_w_req_bits_data_1_entries_vs_4;
  assign wr_vs  [1][5] = io_w_req_bits_data_1_entries_vs_5;
  assign wr_vs  [1][6] = io_w_req_bits_data_1_entries_vs_6;
  assign wr_vs  [1][7] = io_w_req_bits_data_1_entries_vs_7;
  // l1 的 PtwEntries 没有 perms；onlypf 虽在 bundle 里但 PtwCache 不写也不读，
  //   golden 的写拼接里就是一串 0（8'h0），读侧连端口都被 firtool 消掉了。
  assign wr_onlypf[1] = '0;
  assign wr_perm[1] = '0;

  // --------------------------------------------------------------------------
  xs_SplittedSRAM_ptw_core #(
    .NUM(NUM), .TAG_W(TAG_W), .ASID_W(ASID_W), .VMID_W(VMID_W),
    .PBMT_W(PBMT_W), .PPN_W(PPN_W), .PERM_W(PERM_W),
    .HAS_PERM(0), .RSVD_W(2),
    .WAY(WAY), .WAY_SPLIT(WAY_SPLIT), .DATA_SPLIT(DATA_SPLIT)
  ) u_core (
    .w_tag       (wr_tag),
    .w_asid      (wr_asid),
    .w_vmid      (wr_vmid),
    .w_pbmts     (wr_pbmt),
    .w_ppns      (wr_ppn),
    .w_vs        (wr_vs),
    .w_onlypf    (wr_onlypf),
    .w_perms     (wr_perm),
    .w_prefetch  (wr_pref),
    .w_waymask   (io_w_req_bits_waymask),
    .r_tag       (rd_tag),
    .r_asid      (rd_asid),
    .r_vmid      (rd_vmid),
    .r_pbmts     (rd_pbmt),
    .r_ppns      (rd_ppn),
    .r_vs        (rd_vs),
    .r_onlypf    (rd_onlypf),
    .r_perms     (rd_perm),
    .r_prefetch  (rd_pref),
    .arr_waymask (arr_waymask),
    .arr_wdata   (arr_wdata),
    .arr_rdata   (arr_rdata)
  );

  // --------------------------------------------------------------------------
  // 1 块内层 SRAM：每块自带一套 MBIST bore 与 sigFromSrams 广播
  // ★是分份不是共用★：编号照 golden 原样，抄错一根就是静默的真 bug。
  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  // 内层 SRAM #0：array_0_0_0（way 组 0，data 段 0，bore/sigFromSrams 编号 0）
  // --------------------------------------------------------------------------
  SRAMTemplate_128 array_0_0_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (arr_rdata[0][0]),
    .io_r_resp_data_1               (arr_rdata[0][1]),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (arr_wdata[0][0]),
    .io_w_req_bits_data_1           (arr_wdata[0][1]),
    .io_w_req_bits_waymask          (arr_waymask[0]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array)
  );

  // --------------------------------------------------------------------------
  // 读出回填：把核给出的 struct 字段摊回 golden 的扁平输出端口
  // --------------------------------------------------------------------------
  assign io_r_resp_data_0_entries_tag = rd_tag[0];
  assign io_r_resp_data_0_entries_asid = rd_asid[0];
  assign io_r_resp_data_0_entries_vmid = rd_vmid[0];
  assign io_r_resp_data_0_entries_pbmts_0 = rd_pbmt[0][0];
  assign io_r_resp_data_0_entries_pbmts_1 = rd_pbmt[0][1];
  assign io_r_resp_data_0_entries_pbmts_2 = rd_pbmt[0][2];
  assign io_r_resp_data_0_entries_pbmts_3 = rd_pbmt[0][3];
  assign io_r_resp_data_0_entries_pbmts_4 = rd_pbmt[0][4];
  assign io_r_resp_data_0_entries_pbmts_5 = rd_pbmt[0][5];
  assign io_r_resp_data_0_entries_pbmts_6 = rd_pbmt[0][6];
  assign io_r_resp_data_0_entries_pbmts_7 = rd_pbmt[0][7];
  assign io_r_resp_data_0_entries_ppns_0 = rd_ppn[0][0];
  assign io_r_resp_data_0_entries_ppns_1 = rd_ppn[0][1];
  assign io_r_resp_data_0_entries_ppns_2 = rd_ppn[0][2];
  assign io_r_resp_data_0_entries_ppns_3 = rd_ppn[0][3];
  assign io_r_resp_data_0_entries_ppns_4 = rd_ppn[0][4];
  assign io_r_resp_data_0_entries_ppns_5 = rd_ppn[0][5];
  assign io_r_resp_data_0_entries_ppns_6 = rd_ppn[0][6];
  assign io_r_resp_data_0_entries_ppns_7 = rd_ppn[0][7];
  assign io_r_resp_data_0_entries_vs_0 = rd_vs[0][0];
  assign io_r_resp_data_0_entries_vs_1 = rd_vs[0][1];
  assign io_r_resp_data_0_entries_vs_2 = rd_vs[0][2];
  assign io_r_resp_data_0_entries_vs_3 = rd_vs[0][3];
  assign io_r_resp_data_0_entries_vs_4 = rd_vs[0][4];
  assign io_r_resp_data_0_entries_vs_5 = rd_vs[0][5];
  assign io_r_resp_data_0_entries_vs_6 = rd_vs[0][6];
  assign io_r_resp_data_0_entries_vs_7 = rd_vs[0][7];
  assign io_r_resp_data_0_entries_prefetch = rd_pref[0];
  assign io_r_resp_data_1_entries_tag = rd_tag[1];
  assign io_r_resp_data_1_entries_asid = rd_asid[1];
  assign io_r_resp_data_1_entries_vmid = rd_vmid[1];
  assign io_r_resp_data_1_entries_pbmts_0 = rd_pbmt[1][0];
  assign io_r_resp_data_1_entries_pbmts_1 = rd_pbmt[1][1];
  assign io_r_resp_data_1_entries_pbmts_2 = rd_pbmt[1][2];
  assign io_r_resp_data_1_entries_pbmts_3 = rd_pbmt[1][3];
  assign io_r_resp_data_1_entries_pbmts_4 = rd_pbmt[1][4];
  assign io_r_resp_data_1_entries_pbmts_5 = rd_pbmt[1][5];
  assign io_r_resp_data_1_entries_pbmts_6 = rd_pbmt[1][6];
  assign io_r_resp_data_1_entries_pbmts_7 = rd_pbmt[1][7];
  assign io_r_resp_data_1_entries_ppns_0 = rd_ppn[1][0];
  assign io_r_resp_data_1_entries_ppns_1 = rd_ppn[1][1];
  assign io_r_resp_data_1_entries_ppns_2 = rd_ppn[1][2];
  assign io_r_resp_data_1_entries_ppns_3 = rd_ppn[1][3];
  assign io_r_resp_data_1_entries_ppns_4 = rd_ppn[1][4];
  assign io_r_resp_data_1_entries_ppns_5 = rd_ppn[1][5];
  assign io_r_resp_data_1_entries_ppns_6 = rd_ppn[1][6];
  assign io_r_resp_data_1_entries_ppns_7 = rd_ppn[1][7];
  assign io_r_resp_data_1_entries_vs_0 = rd_vs[1][0];
  assign io_r_resp_data_1_entries_vs_1 = rd_vs[1][1];
  assign io_r_resp_data_1_entries_vs_2 = rd_vs[1][2];
  assign io_r_resp_data_1_entries_vs_3 = rd_vs[1][3];
  assign io_r_resp_data_1_entries_vs_4 = rd_vs[1][4];
  assign io_r_resp_data_1_entries_vs_5 = rd_vs[1][5];
  assign io_r_resp_data_1_entries_vs_6 = rd_vs[1][6];
  assign io_r_resp_data_1_entries_vs_7 = rd_vs[1][7];
  assign io_r_resp_data_1_entries_prefetch = rd_pref[1];
endmodule
