// =============================================================================
// dtagarray_pkg —— DuplicatedTagArray（DCache 多副本 Tag 阵列）公共定义
// -----------------------------------------------------------------------------
// 对应 Chisel: xiangshan.cache.TagArray.scala 里的
//   class DuplicatedTagArray / class TagArray / class TagSRAMBank。
//
// 本包仅提供 DuplicatedTagArray 顶层自身要用到的「Tag ECC 编码」纯函数与位宽常量。
// 真正的存储体（TagArray → TagSRAMBank → SRAMTemplate_116 → 厂商宏）与 Mbist 分发树是独立签核的子模块，
// 由 wrapper 例化；可读核只负责「副本管理 + 读写路由 + 写入时算 Tag ECC」。
//
// 关于 Tag ECC（SECDED 单纠错双检错，rocket-chip SECDEDCode）：
//   · 物理 tag 宽 TAG_W=36（DCacheTagOffset..PAddrBits 的物理标签）。
//   · 校验码宽 ECC_W=7，合起来 encTag = {ecc[6:0], tag} 共 43bit 存进 SRAM。
//   · 写入路径在 DuplicatedTagArray 顶层算好 7bit ecc，再扇出给 4 个 TagArray 副本，
//     这样 4 份副本存的内容完全一致（多副本只是为多读口分流，存的是同一张 tag 表）。
//   · 读出路径直接把 SRAM 里的 43bit encTag 透传给上层（命中判定/纠错在 MetaArray 顶）。
// =============================================================================
package dtagarray_pkg;

  // ---- 位宽常量（本配置：DCacheWays=4, nSets=256, DCacheWayDiv=2）----
  localparam int READ_PORTS = 4;   // 读端口/副本数（DuplicatedTagArray(readPorts=4)）
  localparam int N_WAYS     = 4;   // 路数（way_en 4bit）
  localparam int IDX_W      = 8;   // 组索引位宽（256 组）
  localparam int TAG_W      = 36;  // 物理 tag 位宽
  localparam int ECC_W      = 7;   // SECDED 校验码位宽
  localparam int ENC_TAG_W  = TAG_W + ECC_W;  // = 43，SRAM 字宽

  // ---------------------------------------------------------------------------
  // SECDED(43,36) 校验码生成（与 rocket-chip SECDEDCode.encode 一致）
  //   ecc[5:0]：6 个奇偶校验位，每位是 tag 在某固定生成掩码上的 XOR 归约。
  //   ecc[6]  ：整体奇偶位 = 对 {ecc[5:0], tag} 全体再做一次 XOR（保证总奇偶，
  //            使其具备「双比特错检出」能力）。
  //   掩码取值与 golden 完全一致（这些是码字的生成矩阵常量，属设计常量非生成临时名）。
  // ---------------------------------------------------------------------------
  function automatic logic [ECC_W-1:0] tag_ecc_encode(input logic [TAG_W-1:0] tag);
    logic [5:0] p;        // 6 个奇偶校验位
    logic       overall;  // 整体奇偶位
    p[0] = ^(tag & 36'h556AAAD5B);
    p[1] = ^(tag & 36'h99B33366D);
    p[2] = ^(tag & 36'h1E3C3C78E);
    p[3] = ^(tag & 36'hE03FC07F0);
    p[4] = ^(tag & 36'h003FFF800);
    p[5] = ^(tag & 36'hFFC000000);
    overall = ^{p, tag};
    tag_ecc_encode = {overall, p};
  endfunction

endpackage

// =============================================================================
// xs_DuplicatedTagArray_core —— DCache 多副本 Tag 阵列（可读重写核）
// -----------------------------------------------------------------------------
// 对应 Chisel: xiangshan.cache.TagArray.scala  class DuplicatedTagArray(readPorts)
//
// 在 DCache 中的位置：
//   DCache 需要同时被多条流水查 tag——LoadPipe 有多条 load 通道、MainPipe 有
//   replace/probe/store 等通道，它们在同一拍都要读 tag 判命中。单口 tag SRAM 无法
//   多读，于是把整张 tag 表**复制 readPorts 份**（本配置 4 份），每份 = 一个 TagArray，
//   各自带一套读口，从而 readPorts 条流水可并行无冲突地读 tag。
//
//   · 读：第 i 条流水的读请求 read[i] 只送到第 i 份副本 array[i]，其 resp 即第 i 路结果。
//   · 写（refill 填入新 tag）：必须**同时写进全部 4 份副本**，保证多份内容一致。
//   · 4 份副本存的是**同一张 256 组 × 4 路的 tag 表**，差异仅在“谁来读”。
//
// 本核负责的“设计逻辑”（存储体 TagArray / DFT 分发 MbistPipeDcacheTag 是各自独立签核的子模块）：
//   1) 写入时计算 Tag 的 SECDED 校验码（7bit），与 36bit tag 拼成 43bit encTag；
//   2) 把写请求（idx/way_en/encTag）扇出到全部副本；
//   3) 把每个读端口路由到对应副本，并把副本的 resp 透传回对应输出口；
//   4) 暴露 readPorts 份 TagArray 子模块接口（wrapper 例化 TagArray 后回连）。
//
// TagArray 内部（rtl/memblock/TagArray.sv / TagSRAMBank.sv，不在本核实现）：
//   每个 TagArray = nWays/DCacheWayDiv = 2 个 TagSRAMBank，每 bank 管 DCacheWayDiv=2 路；
//   bank 内是单口 SRAMTemplate（深 256、宽 43），上电有逐组清零（rst_cnt）。
//   读延迟 1 拍：本核给出 read_valid/idx，下一拍 resp 出现在 tarr_resp。
//
// 注意端口裁剪（firtool 死代码消除的结果，需对齐）：
//   · 只有读端口 3 的 ready 被引出为 io_read_3_ready（其余副本 ready 上层不用）。
//   · 写口的 ready 恒 true，golden 顶层未引出端口（被裁掉）。
// =============================================================================

module xs_DuplicatedTagArray_core import dtagarray_pkg::*; (
  input  logic                       clock,
  input  logic                       reset,

  // ---- 读端口：READ_PORTS 条流水，各自一套 valid/idx ----
  input  logic                       io_read_valid [READ_PORTS],
  input  logic [IDX_W-1:0]           io_read_idx   [READ_PORTS],
  output logic                       io_read3_ready,              // 仅副本 3 的 ready 引出

  // ---- 读结果：每端口 N_WAYS 路 encTag（43bit），SRAM 同步读、晚 1 拍 ----
  output logic [ENC_TAG_W-1:0]       io_resp [READ_PORTS][N_WAYS],

  // ---- 写口（refill）：写一组的某些 way ----
  input  logic                       io_write_valid,
  input  logic [IDX_W-1:0]           io_write_idx,
  input  logic [N_WAYS-1:0]          io_write_way_en,
  input  logic [TAG_W-1:0]           io_write_tag,

  // ---- 与 READ_PORTS 份 TagArray 子模块的接口（wrapper 例化后回连）----
  // 读
  output logic                       tarr_read_valid [READ_PORTS],
  output logic [IDX_W-1:0]           tarr_read_idx   [READ_PORTS],
  input  logic                       tarr_read_ready [READ_PORTS],
  input  logic [ENC_TAG_W-1:0]       tarr_resp       [READ_PORTS][N_WAYS],
  // 写（全副本同写）
  output logic                       tarr_write_valid  [READ_PORTS],
  output logic [IDX_W-1:0]           tarr_write_idx    [READ_PORTS],
  output logic [N_WAYS-1:0]          tarr_write_way_en [READ_PORTS],
  output logic [TAG_W-1:0]           tarr_write_tag    [READ_PORTS],
  output logic [ECC_W-1:0]           tarr_write_ecc    [READ_PORTS]
);

  // ---------------------------------------------------------------------------
  // 写入：在顶层统一算一次 Tag ECC，再扇出给全部副本（保证各副本一致）
  // ---------------------------------------------------------------------------
  logic [ECC_W-1:0] write_ecc;
  always_comb write_ecc = tag_ecc_encode(io_write_tag);

  // ---------------------------------------------------------------------------
  // 副本路由：读各走各的副本；写广播到全部副本；resp 透传回对应端口
  // ---------------------------------------------------------------------------
  for (genvar p = 0; p < READ_PORTS; p++) begin : g_copy
    always_comb begin
      // 读：端口 p → 副本 p
      tarr_read_valid[p] = io_read_valid[p];
      tarr_read_idx[p]   = io_read_idx[p];
      // 写：广播（idx/way_en/tag/ecc 各副本相同）
      tarr_write_valid[p]  = io_write_valid;
      tarr_write_idx[p]    = io_write_idx;
      tarr_write_way_en[p] = io_write_way_en;
      tarr_write_tag[p]    = io_write_tag;
      tarr_write_ecc[p]    = write_ecc;
      // 读结果透传
      for (int w = 0; w < N_WAYS; w++)
        io_resp[p][w] = tarr_resp[p][w];
    end
  end

  // 只有副本 3 的读 ready 对外引出
  always_comb io_read3_ready = tarr_read_ready[READ_PORTS-1];

endmodule

// =============================================================================
// DuplicatedTagArray_wrapper —— golden 同名顶层（FM 对比 / ST 替换用）
// -----------------------------------------------------------------------------
// 端口与 golden DuplicatedTagArray 完全一致（扁平）。本 wrapper 是机械适配层：
//   · 例化 4 个 TagArray（rtl/memblock/TagArray.sv，array_0..3，每副本一套读口）；
//   · 例化 MbistPipeDcacheTag（rtl/dft/MbistPipeDcacheTag.sv），按 golden 拓扑把 8 条 childBd bore 链
//     连到 4 个副本（每副本 2 个 bore 子口，对应其 2 个 TagSRAMBank）；
//   · 把读/写/resp 路由与 Tag-ECC 计算交给可读核 xs_DuplicatedTagArray_core
//     （golden 在顶层内联算 ecc 并扇出，此处改由核统一处理）。
//   · sigFromSrams_bore_N（N=0..7）的 SRAM 旁带按 golden 映射：array_k 取 [2k,2k+1]。
//
// 命名同 golden（DuplicatedTagArray），供 FM/ST 直接对接。UT 用 _xs 镜像（见 variants）。
// =============================================================================

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module DuplicatedTagArray import dtagarray_pkg::*; (
  input         clock,
  input         reset,
  input         io_read_0_valid,
  input  [7:0]  io_read_0_bits_idx,
  input         io_read_1_valid,
  input  [7:0]  io_read_1_bits_idx,
  input         io_read_2_valid,
  input  [7:0]  io_read_2_bits_idx,
  output        io_read_3_ready,
  input         io_read_3_valid,
  input  [7:0]  io_read_3_bits_idx,
  output [42:0] io_resp_0_0,
  output [42:0] io_resp_0_1,
  output [42:0] io_resp_0_2,
  output [42:0] io_resp_0_3,
  output [42:0] io_resp_1_0,
  output [42:0] io_resp_1_1,
  output [42:0] io_resp_1_2,
  output [42:0] io_resp_1_3,
  output [42:0] io_resp_2_0,
  output [42:0] io_resp_2_1,
  output [42:0] io_resp_2_2,
  output [42:0] io_resp_2_3,
  output [42:0] io_resp_3_0,
  output [42:0] io_resp_3_1,
  output [42:0] io_resp_3_2,
  output [42:0] io_resp_3_3,
  input         io_write_valid,
  input  [7:0]  io_write_bits_idx,
  input  [3:0]  io_write_bits_way_en,
  input  [35:0] io_write_bits_tag,
  input  [5:0]  boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input  [1:0]  boreChildrenBd_bore_be,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [85:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  output [85:0] boreChildrenBd_bore_outdata,
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

  // ---------------------------------------------------------------------------
  // 可读核接口信号（struct/数组端口拆成局部变量再扁平连）
  // ---------------------------------------------------------------------------
  logic               core_read_valid [READ_PORTS];
  logic [IDX_W-1:0]   core_read_idx   [READ_PORTS];
  logic               core_read3_ready;
  logic [ENC_TAG_W-1:0] core_resp     [READ_PORTS][N_WAYS];

  logic               core_tarr_read_valid [READ_PORTS];
  logic [IDX_W-1:0]   core_tarr_read_idx   [READ_PORTS];
  logic               core_tarr_read_ready [READ_PORTS];
  logic [ENC_TAG_W-1:0] core_tarr_resp     [READ_PORTS][N_WAYS];
  logic               core_tarr_write_valid  [READ_PORTS];
  logic [IDX_W-1:0]   core_tarr_write_idx    [READ_PORTS];
  logic [N_WAYS-1:0]  core_tarr_write_way_en [READ_PORTS];
  logic [TAG_W-1:0]   core_tarr_write_tag    [READ_PORTS];
  logic [ECC_W-1:0]   core_tarr_write_ecc    [READ_PORTS];

  // 扁平 → 核数组
  assign core_read_valid[0] = io_read_0_valid;
  assign core_read_valid[1] = io_read_1_valid;
  assign core_read_valid[2] = io_read_2_valid;
  assign core_read_valid[3] = io_read_3_valid;
  assign core_read_idx[0]   = io_read_0_bits_idx;
  assign core_read_idx[1]   = io_read_1_bits_idx;
  assign core_read_idx[2]   = io_read_2_bits_idx;
  assign core_read_idx[3]   = io_read_3_bits_idx;
  assign io_read_3_ready    = core_read3_ready;

  assign io_resp_0_0 = core_resp[0][0];
  assign io_resp_0_1 = core_resp[0][1];
  assign io_resp_0_2 = core_resp[0][2];
  assign io_resp_0_3 = core_resp[0][3];
  assign io_resp_1_0 = core_resp[1][0];
  assign io_resp_1_1 = core_resp[1][1];
  assign io_resp_1_2 = core_resp[1][2];
  assign io_resp_1_3 = core_resp[1][3];
  assign io_resp_2_0 = core_resp[2][0];
  assign io_resp_2_1 = core_resp[2][1];
  assign io_resp_2_2 = core_resp[2][2];
  assign io_resp_2_3 = core_resp[2][3];
  assign io_resp_3_0 = core_resp[3][0];
  assign io_resp_3_1 = core_resp[3][1];
  assign io_resp_3_2 = core_resp[3][2];
  assign io_resp_3_3 = core_resp[3][3];

  xs_DuplicatedTagArray_core u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(core_read_valid), .io_read_idx(core_read_idx),
    .io_read3_ready(core_read3_ready), .io_resp(core_resp),
    .io_write_valid(io_write_valid), .io_write_idx(io_write_bits_idx),
    .io_write_way_en(io_write_bits_way_en), .io_write_tag(io_write_bits_tag),
    .tarr_read_valid(core_tarr_read_valid), .tarr_read_idx(core_tarr_read_idx),
    .tarr_read_ready(core_tarr_read_ready), .tarr_resp(core_tarr_resp),
    .tarr_write_valid(core_tarr_write_valid), .tarr_write_idx(core_tarr_write_idx),
    .tarr_write_way_en(core_tarr_write_way_en), .tarr_write_tag(core_tarr_write_tag),
    .tarr_write_ecc(core_tarr_write_ecc)
  );

  // ---------------------------------------------------------------------------
  // MBIST bore 链（8 条 childBd，对应 4 副本 × 2 TagSRAMBank），按 golden 拓扑
  // ---------------------------------------------------------------------------
  wire [8:0]  childBd_addr   [8];
  wire [8:0]  childBd_addr_rd[8];
  wire [85:0] childBd_wdata  [8];
  wire [1:0]  childBd_wmask  [8];
  wire        childBd_re     [8];
  wire        childBd_we     [8];
  wire [85:0] childBd_rdata  [8];
  wire        childBd_ack    [8];
  wire        childBd_selectedOH[8];
  wire [5:0]  childBd_array  [8];

  // sigFromSrams 旁带按组打包：8 组，每组 7 个标量
  wire [6:0] sig [8];
  assign sig[0] = {sigFromSrams_bore_cgen,   sigFromSrams_bore_ram_mcp_hold,   sigFromSrams_bore_ram_aux_ckbp,   sigFromSrams_bore_ram_aux_clk,   sigFromSrams_bore_ram_bp_clken,   sigFromSrams_bore_ram_bypass,   sigFromSrams_bore_ram_hold};
  assign sig[1] = {sigFromSrams_bore_1_cgen, sigFromSrams_bore_1_ram_mcp_hold, sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_aux_clk, sigFromSrams_bore_1_ram_bp_clken, sigFromSrams_bore_1_ram_bypass, sigFromSrams_bore_1_ram_hold};
  assign sig[2] = {sigFromSrams_bore_2_cgen, sigFromSrams_bore_2_ram_mcp_hold, sigFromSrams_bore_2_ram_aux_ckbp, sigFromSrams_bore_2_ram_aux_clk, sigFromSrams_bore_2_ram_bp_clken, sigFromSrams_bore_2_ram_bypass, sigFromSrams_bore_2_ram_hold};
  assign sig[3] = {sigFromSrams_bore_3_cgen, sigFromSrams_bore_3_ram_mcp_hold, sigFromSrams_bore_3_ram_aux_ckbp, sigFromSrams_bore_3_ram_aux_clk, sigFromSrams_bore_3_ram_bp_clken, sigFromSrams_bore_3_ram_bypass, sigFromSrams_bore_3_ram_hold};
  assign sig[4] = {sigFromSrams_bore_4_cgen, sigFromSrams_bore_4_ram_mcp_hold, sigFromSrams_bore_4_ram_aux_ckbp, sigFromSrams_bore_4_ram_aux_clk, sigFromSrams_bore_4_ram_bp_clken, sigFromSrams_bore_4_ram_bypass, sigFromSrams_bore_4_ram_hold};
  assign sig[5] = {sigFromSrams_bore_5_cgen, sigFromSrams_bore_5_ram_mcp_hold, sigFromSrams_bore_5_ram_aux_ckbp, sigFromSrams_bore_5_ram_aux_clk, sigFromSrams_bore_5_ram_bp_clken, sigFromSrams_bore_5_ram_bypass, sigFromSrams_bore_5_ram_hold};
  assign sig[6] = {sigFromSrams_bore_6_cgen, sigFromSrams_bore_6_ram_mcp_hold, sigFromSrams_bore_6_ram_aux_ckbp, sigFromSrams_bore_6_ram_aux_clk, sigFromSrams_bore_6_ram_bp_clken, sigFromSrams_bore_6_ram_bypass, sigFromSrams_bore_6_ram_hold};
  assign sig[7] = {sigFromSrams_bore_7_cgen, sigFromSrams_bore_7_ram_mcp_hold, sigFromSrams_bore_7_ram_aux_ckbp, sigFromSrams_bore_7_ram_aux_clk, sigFromSrams_bore_7_ram_bp_clken, sigFromSrams_bore_7_ram_bypass, sigFromSrams_bore_7_ram_hold};

  // 4 个 TagArray 副本：array_k 用 childBd[2k]/childBd[2k+1] 两条 bore 链，sig[2k]/sig[2k+1]
  for (genvar k = 0; k < READ_PORTS; k++) begin : g_tarr
    localparam int B0 = 2*k;
    localparam int B1 = 2*k+1;
    TagArray array_k (
      .clock(clock), .reset(reset),
      .io_read_ready       (core_tarr_read_ready[k]),
      .io_read_valid       (core_tarr_read_valid[k]),
      .io_read_bits_idx    (core_tarr_read_idx[k]),
      .io_resp_0           (core_tarr_resp[k][0]),
      .io_resp_1           (core_tarr_resp[k][1]),
      .io_resp_2           (core_tarr_resp[k][2]),
      .io_resp_3           (core_tarr_resp[k][3]),
      .io_write_valid      (core_tarr_write_valid[k]),
      .io_write_bits_idx   (core_tarr_write_idx[k]),
      .io_write_bits_way_en(core_tarr_write_way_en[k]),
      .io_write_bits_tag   (core_tarr_write_tag[k]),
      .io_write_bits_ecc   (core_tarr_write_ecc[k]),
      // bore 子口 0
      .boreChildrenBd_bore_addr       (childBd_addr[B0]),
      .boreChildrenBd_bore_addr_rd    (childBd_addr_rd[B0]),
      .boreChildrenBd_bore_wdata      (childBd_wdata[B0]),
      .boreChildrenBd_bore_wmask      (childBd_wmask[B0]),
      .boreChildrenBd_bore_re         (childBd_re[B0]),
      .boreChildrenBd_bore_we         (childBd_we[B0]),
      .boreChildrenBd_bore_rdata      (childBd_rdata[B0]),
      .boreChildrenBd_bore_ack        (childBd_ack[B0]),
      .boreChildrenBd_bore_selectedOH (childBd_selectedOH[B0]),
      .boreChildrenBd_bore_array      (childBd_array[B0]),
      // bore 子口 1
      .boreChildrenBd_bore_1_addr       (childBd_addr[B1]),
      .boreChildrenBd_bore_1_addr_rd    (childBd_addr_rd[B1]),
      .boreChildrenBd_bore_1_wdata      (childBd_wdata[B1]),
      .boreChildrenBd_bore_1_wmask      (childBd_wmask[B1]),
      .boreChildrenBd_bore_1_re         (childBd_re[B1]),
      .boreChildrenBd_bore_1_we         (childBd_we[B1]),
      .boreChildrenBd_bore_1_rdata      (childBd_rdata[B1]),
      .boreChildrenBd_bore_1_ack        (childBd_ack[B1]),
      .boreChildrenBd_bore_1_selectedOH (childBd_selectedOH[B1]),
      .boreChildrenBd_bore_1_array      (childBd_array[B1]),
      // SRAM 旁带（每副本 2 组）
      .sigFromSrams_bore_ram_hold     (sig[B0][0]),
      .sigFromSrams_bore_ram_bypass   (sig[B0][1]),
      .sigFromSrams_bore_ram_bp_clken (sig[B0][2]),
      .sigFromSrams_bore_ram_aux_clk  (sig[B0][3]),
      .sigFromSrams_bore_ram_aux_ckbp (sig[B0][4]),
      .sigFromSrams_bore_ram_mcp_hold (sig[B0][5]),
      .sigFromSrams_bore_cgen         (sig[B0][6]),
      .sigFromSrams_bore_1_ram_hold     (sig[B1][0]),
      .sigFromSrams_bore_1_ram_bypass   (sig[B1][1]),
      .sigFromSrams_bore_1_ram_bp_clken (sig[B1][2]),
      .sigFromSrams_bore_1_ram_aux_clk  (sig[B1][3]),
      .sigFromSrams_bore_1_ram_aux_ckbp (sig[B1][4]),
      .sigFromSrams_bore_1_ram_mcp_hold (sig[B1][5]),
      .sigFromSrams_bore_1_cgen         (sig[B1][6])
    );
  end

  // ---------------------------------------------------------------------------
  // MbistPipeDcacheTag：把顶层 bd_* 信号驱动 8 条 childBd（子模块，结构同 golden）
  // ---------------------------------------------------------------------------
  MbistPipeDcacheTag mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array  (boreChildrenBd_bore_array),
    .mbist_all    (boreChildrenBd_bore_all),
    .mbist_req    (boreChildrenBd_bore_req),
    .mbist_ack    (boreChildrenBd_bore_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen),
    .mbist_be     (boreChildrenBd_bore_be),
    .mbist_addr   (boreChildrenBd_bore_addr),
    .mbist_indata (boreChildrenBd_bore_indata),
    .mbist_readen (boreChildrenBd_bore_readen),
    .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_0_addr(childBd_addr[0]), .toSRAM_0_addr_rd(childBd_addr_rd[0]), .toSRAM_0_wdata(childBd_wdata[0]), .toSRAM_0_wmask(childBd_wmask[0]), .toSRAM_0_re(childBd_re[0]), .toSRAM_0_we(childBd_we[0]), .toSRAM_0_rdata(childBd_rdata[0]), .toSRAM_0_ack(childBd_ack[0]), .toSRAM_0_selectedOH(childBd_selectedOH[0]), .toSRAM_0_array(childBd_array[0]),
    .toSRAM_1_addr(childBd_addr[1]), .toSRAM_1_addr_rd(childBd_addr_rd[1]), .toSRAM_1_wdata(childBd_wdata[1]), .toSRAM_1_wmask(childBd_wmask[1]), .toSRAM_1_re(childBd_re[1]), .toSRAM_1_we(childBd_we[1]), .toSRAM_1_rdata(childBd_rdata[1]), .toSRAM_1_ack(childBd_ack[1]), .toSRAM_1_selectedOH(childBd_selectedOH[1]), .toSRAM_1_array(childBd_array[1]),
    .toSRAM_2_addr(childBd_addr[2]), .toSRAM_2_addr_rd(childBd_addr_rd[2]), .toSRAM_2_wdata(childBd_wdata[2]), .toSRAM_2_wmask(childBd_wmask[2]), .toSRAM_2_re(childBd_re[2]), .toSRAM_2_we(childBd_we[2]), .toSRAM_2_rdata(childBd_rdata[2]), .toSRAM_2_ack(childBd_ack[2]), .toSRAM_2_selectedOH(childBd_selectedOH[2]), .toSRAM_2_array(childBd_array[2]),
    .toSRAM_3_addr(childBd_addr[3]), .toSRAM_3_addr_rd(childBd_addr_rd[3]), .toSRAM_3_wdata(childBd_wdata[3]), .toSRAM_3_wmask(childBd_wmask[3]), .toSRAM_3_re(childBd_re[3]), .toSRAM_3_we(childBd_we[3]), .toSRAM_3_rdata(childBd_rdata[3]), .toSRAM_3_ack(childBd_ack[3]), .toSRAM_3_selectedOH(childBd_selectedOH[3]), .toSRAM_3_array(childBd_array[3]),
    .toSRAM_4_addr(childBd_addr[4]), .toSRAM_4_addr_rd(childBd_addr_rd[4]), .toSRAM_4_wdata(childBd_wdata[4]), .toSRAM_4_wmask(childBd_wmask[4]), .toSRAM_4_re(childBd_re[4]), .toSRAM_4_we(childBd_we[4]), .toSRAM_4_rdata(childBd_rdata[4]), .toSRAM_4_ack(childBd_ack[4]), .toSRAM_4_selectedOH(childBd_selectedOH[4]), .toSRAM_4_array(childBd_array[4]),
    .toSRAM_5_addr(childBd_addr[5]), .toSRAM_5_addr_rd(childBd_addr_rd[5]), .toSRAM_5_wdata(childBd_wdata[5]), .toSRAM_5_wmask(childBd_wmask[5]), .toSRAM_5_re(childBd_re[5]), .toSRAM_5_we(childBd_we[5]), .toSRAM_5_rdata(childBd_rdata[5]), .toSRAM_5_ack(childBd_ack[5]), .toSRAM_5_selectedOH(childBd_selectedOH[5]), .toSRAM_5_array(childBd_array[5]),
    .toSRAM_6_addr(childBd_addr[6]), .toSRAM_6_addr_rd(childBd_addr_rd[6]), .toSRAM_6_wdata(childBd_wdata[6]), .toSRAM_6_wmask(childBd_wmask[6]), .toSRAM_6_re(childBd_re[6]), .toSRAM_6_we(childBd_we[6]), .toSRAM_6_rdata(childBd_rdata[6]), .toSRAM_6_ack(childBd_ack[6]), .toSRAM_6_selectedOH(childBd_selectedOH[6]), .toSRAM_6_array(childBd_array[6]),
    .toSRAM_7_addr(childBd_addr[7]), .toSRAM_7_addr_rd(childBd_addr_rd[7]), .toSRAM_7_wdata(childBd_wdata[7]), .toSRAM_7_wmask(childBd_wmask[7]), .toSRAM_7_re(childBd_re[7]), .toSRAM_7_we(childBd_we[7]), .toSRAM_7_rdata(childBd_rdata[7]), .toSRAM_7_ack(childBd_ack[7]), .toSRAM_7_selectedOH(childBd_selectedOH[7]), .toSRAM_7_array(childBd_array[7])
  );

endmodule
