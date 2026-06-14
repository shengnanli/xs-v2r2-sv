// =============================================================================
// xs_ICacheMainPipe_core —— ICache 主流水（取指数据通路 3 级流水 s0/s1/s2）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheMainPipe
//
// 三级流水（每级一拍寄存器，标准 valid/ready 反压）：
//   s0：接收 FTQ 取指请求 + WayLookup 的 way 命中/TLB 信息；向数据 SRAM
//       (dataArray.toIData) 发读请求；更新替换器 touch。
//   s1：PMP 检查；锁存数据 SRAM 读回（带 MSHR 旁路 DataHoldBypass）；
//       做 metaArray ECC 检查；监听 MSHR 回填命中。
//   s2：数据 ECC 检查；缺失/ECC 损坏时向 MSHR 发再取请求（经 2 路 Arbiter）；
//       合并异常；向 IFU 返回取指结果；上报 BEU error；性能计数。
//
// 双取指端口 PortNumber=2（vaddr/ptag/exception/pbmt/waymask 各两份，端口 1 仅在
// doubleline 跨行时有效）。数据 512bit 分 8 个 64bit bank（ICacheDataBanks=8）。
//
// 寄存器命名完全沿用 golden（s1_*/s2_*/REG*/io_*_REG 等），便于 Formality 按名
// 匹配；内部组合信号用可读命名。子模块 Arbiter2_ICacheMissReq（2 路组合仲裁）直接
// 内联（toMSHRArbiter_*）。
// =============================================================================
module xs_ICacheMainPipe_core (
  input  logic         clock,
  input  logic         reset,

  // ---- dataArray：向数据 SRAM 发读请求（partWayNum=4 个口 + 末口给主流水）----
  output logic         io_dataArray_toIData_0_valid,
  output logic [7:0]   io_dataArray_toIData_0_bits_vSetIdx_0,
  output logic [7:0]   io_dataArray_toIData_0_bits_vSetIdx_1,
  output logic         io_dataArray_toIData_0_bits_waymask_0_0,
  output logic         io_dataArray_toIData_0_bits_waymask_0_1,
  output logic         io_dataArray_toIData_0_bits_waymask_0_2,
  output logic         io_dataArray_toIData_0_bits_waymask_0_3,
  output logic         io_dataArray_toIData_0_bits_waymask_1_0,
  output logic         io_dataArray_toIData_0_bits_waymask_1_1,
  output logic         io_dataArray_toIData_0_bits_waymask_1_2,
  output logic         io_dataArray_toIData_0_bits_waymask_1_3,
  output logic [5:0]   io_dataArray_toIData_0_bits_blkOffset,
  output logic         io_dataArray_toIData_1_valid,
  output logic [7:0]   io_dataArray_toIData_1_bits_vSetIdx_0,
  output logic [7:0]   io_dataArray_toIData_1_bits_vSetIdx_1,
  output logic         io_dataArray_toIData_2_valid,
  output logic [7:0]   io_dataArray_toIData_2_bits_vSetIdx_0,
  output logic [7:0]   io_dataArray_toIData_2_bits_vSetIdx_1,
  input  logic         io_dataArray_toIData_3_ready,
  output logic         io_dataArray_toIData_3_valid,
  output logic [7:0]   io_dataArray_toIData_3_bits_vSetIdx_0,
  output logic [7:0]   io_dataArray_toIData_3_bits_vSetIdx_1,
  input  logic [63:0]  io_dataArray_fromIData_datas_0,
  input  logic [63:0]  io_dataArray_fromIData_datas_1,
  input  logic [63:0]  io_dataArray_fromIData_datas_2,
  input  logic [63:0]  io_dataArray_fromIData_datas_3,
  input  logic [63:0]  io_dataArray_fromIData_datas_4,
  input  logic [63:0]  io_dataArray_fromIData_datas_5,
  input  logic [63:0]  io_dataArray_fromIData_datas_6,
  input  logic [63:0]  io_dataArray_fromIData_datas_7,
  input  logic         io_dataArray_fromIData_codes_0,
  input  logic         io_dataArray_fromIData_codes_1,
  input  logic         io_dataArray_fromIData_codes_2,
  input  logic         io_dataArray_fromIData_codes_3,
  input  logic         io_dataArray_fromIData_codes_4,
  input  logic         io_dataArray_fromIData_codes_5,
  input  logic         io_dataArray_fromIData_codes_6,
  input  logic         io_dataArray_fromIData_codes_7,

  // ---- metaArray flush（ECC 损坏后清表准备重取）----
  output logic         io_metaArrayFlush_0_valid,
  output logic [7:0]   io_metaArrayFlush_0_bits_virIdx,
  output logic [3:0]   io_metaArrayFlush_0_bits_waymask,
  output logic         io_metaArrayFlush_1_valid,
  output logic [7:0]   io_metaArrayFlush_1_bits_virIdx,
  output logic [3:0]   io_metaArrayFlush_1_bits_waymask,

  // ---- replacer touch ----
  output logic         io_touch_0_valid,
  output logic [7:0]   io_touch_0_bits_vSetIdx,
  output logic [1:0]   io_touch_0_bits_way,
  output logic         io_touch_1_valid,
  output logic [7:0]   io_touch_1_bits_vSetIdx,
  output logic [1:0]   io_touch_1_bits_way,

  // ---- wayLookup 读出（way 命中 + TLB 信息）----
  output logic         io_wayLookupRead_ready,
  input  logic         io_wayLookupRead_valid,
  input  logic [7:0]   io_wayLookupRead_bits_entry_vSetIdx_0,
  input  logic [7:0]   io_wayLookupRead_bits_entry_vSetIdx_1,
  input  logic [3:0]   io_wayLookupRead_bits_entry_waymask_0,
  input  logic [3:0]   io_wayLookupRead_bits_entry_waymask_1,
  input  logic [35:0]  io_wayLookupRead_bits_entry_ptag_0,
  input  logic [35:0]  io_wayLookupRead_bits_entry_ptag_1,
  input  logic [1:0]   io_wayLookupRead_bits_entry_itlb_exception_0,
  input  logic [1:0]   io_wayLookupRead_bits_entry_itlb_exception_1,
  input  logic [1:0]   io_wayLookupRead_bits_entry_itlb_pbmt_0,
  input  logic [1:0]   io_wayLookupRead_bits_entry_itlb_pbmt_1,
  input  logic         io_wayLookupRead_bits_entry_meta_codes_0,
  input  logic         io_wayLookupRead_bits_entry_meta_codes_1,
  input  logic [55:0]  io_wayLookupRead_bits_gpf_gpaddr,
  input  logic         io_wayLookupRead_bits_gpf_isForVSnonLeafPTE,

  // ---- MSHR（miss 处理）----
  input  logic         io_mshr_req_ready,
  output logic         io_mshr_req_valid,
  output logic [41:0]  io_mshr_req_bits_blkPaddr,
  output logic [7:0]   io_mshr_req_bits_vSetIdx,
  input  logic         io_mshr_resp_valid,
  input  logic [41:0]  io_mshr_resp_bits_blkPaddr,
  input  logic [7:0]   io_mshr_resp_bits_vSetIdx,
  input  logic [511:0] io_mshr_resp_bits_data,
  input  logic         io_mshr_resp_bits_corrupt,

  input  logic         io_ecc_enable,

  // ---- FTQ 取指请求 ----
  output logic         io_fetch_req_ready,
  input  logic         io_fetch_req_valid,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_0_startAddr,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_0_nextlineStart,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_1_startAddr,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_1_nextlineStart,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_2_startAddr,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_2_nextlineStart,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_3_startAddr,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_3_nextlineStart,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_4_startAddr,
  input  logic [49:0]  io_fetch_req_bits_pcMemRead_4_nextlineStart,
  input  logic         io_fetch_req_bits_readValid_0,
  input  logic         io_fetch_req_bits_readValid_1,
  input  logic         io_fetch_req_bits_readValid_2,
  input  logic         io_fetch_req_bits_readValid_3,
  input  logic         io_fetch_req_bits_readValid_4,
  input  logic         io_fetch_req_bits_backendException,

  // ---- 向 IFU 返回取指结果 ----
  output logic         io_fetch_resp_valid,
  output logic         io_fetch_resp_bits_doubleline,
  output logic [49:0]  io_fetch_resp_bits_vaddr_0,
  output logic [49:0]  io_fetch_resp_bits_vaddr_1,
  output logic [511:0] io_fetch_resp_bits_data,
  output logic [47:0]  io_fetch_resp_bits_paddr_0,
  output logic [1:0]   io_fetch_resp_bits_exception_0,
  output logic [1:0]   io_fetch_resp_bits_exception_1,
  output logic         io_fetch_resp_bits_pmp_mmio_0,
  output logic         io_fetch_resp_bits_pmp_mmio_1,
  output logic [1:0]   io_fetch_resp_bits_itlb_pbmt_0,
  output logic [1:0]   io_fetch_resp_bits_itlb_pbmt_1,
  output logic         io_fetch_resp_bits_backendException,
  output logic [55:0]  io_fetch_resp_bits_gpaddr,
  output logic         io_fetch_resp_bits_isForVSnonLeafPTE,
  output logic         io_fetch_topdownIcacheMiss,
  output logic         io_fetch_topdownItlbMiss,

  input  logic         io_flush,

  // ---- PMP ----
  output logic [47:0]  io_pmp_0_req_bits_addr,
  input  logic         io_pmp_0_resp_instr,
  input  logic         io_pmp_0_resp_mmio,
  output logic [47:0]  io_pmp_1_req_bits_addr,
  input  logic         io_pmp_1_resp_instr,
  input  logic         io_pmp_1_resp_mmio,

  input  logic         io_respStall,

  // ---- BEU error 上报 ----
  output logic         io_errors_0_valid,
  output logic [47:0]  io_errors_0_bits_paddr,
  output logic         io_errors_0_bits_report_to_beu,
  output logic         io_errors_1_valid,
  output logic [47:0]  io_errors_1_bits_paddr,
  output logic         io_errors_1_bits_report_to_beu,

  // ---- 性能信息 ----
  output logic         io_perfInfo_only_0_hit,
  output logic         io_perfInfo_only_0_miss,
  output logic         io_perfInfo_hit_0_hit_1,
  output logic         io_perfInfo_hit_0_miss_1,
  output logic         io_perfInfo_miss_0_hit_1,
  output logic         io_perfInfo_miss_0_miss_1,
  output logic         io_perfInfo_hit_0_except_1,
  output logic         io_perfInfo_miss_0_except_1,
  output logic         io_perfInfo_except_0,
  output logic         io_perfInfo_bank_hit_0,
  output logic         io_perfInfo_bank_hit_1,
  output logic         io_perfInfo_hit
);

  // ===========================================================================
  // 流水控制信号（前向声明）
  // ===========================================================================
  logic s1_ready, s2_ready, s0_can_go;

  // ===========================================================================
  // FTQ fire 间隔直方图计数器（仅性能统计，会影响一个 32bit 寄存器）
  // ===========================================================================
  reg  [31:0] cntFtqFireInterval;
  wire        x3_probe = s0_can_go & io_fetch_req_valid;  // = fromFtq.fire 的近似（s0_can_go & valid）

  // s0_can_go：数据 SRAM 末口 ready & wayLookup 有效 & s1 可前进
  assign s0_can_go = io_dataArray_toIData_3_ready & io_wayLookupRead_valid & s1_ready;
  wire   s0_fire   = io_fetch_req_valid & s0_can_go & ~io_flush;

  // ===========================================================================
  // s1 级寄存器
  // ===========================================================================
  reg         s1_valid;
  reg  [49:0] s1_req_vaddr_0, s1_req_vaddr_1;
  reg  [35:0] s1_req_ptags_0, s1_req_ptags_1;
  reg  [55:0] s1_req_gpaddr;
  reg         s1_req_isForVSnonLeafPTE;
  reg         s1_doubleline;
  reg         s1_SRAMhits_0, s1_SRAMhits_1;
  reg  [1:0]  s1_itlb_exception_0, s1_itlb_exception_1;
  reg         s1_backendException;
  reg  [1:0]  s1_itlb_pbmt_0, s1_itlb_pbmt_1;
  reg         s1_waymasks_0_0, s1_waymasks_0_1, s1_waymasks_0_2, s1_waymasks_0_3;
  reg         s1_waymasks_1_0, s1_waymasks_1_1, s1_waymasks_1_2, s1_waymasks_1_3;
  reg         s1_meta_codes_0, s1_meta_codes_1;

  // RegNext(s0_fire) 的各路复制（touch/hits/datas/codes 的使能寄存器）
  reg         io_touch_0_valid_REG, io_touch_1_valid_REG;
  reg         s1_hits_REG, s1_hits_REG_1;       // RegNext(s0_fire)
  reg         s1_hits_valid, s1_hits_valid_1;   // ValidHoldBypass 状态

  // ===========================================================================
  // s1 MSHR 回填命中判定（端口 0/1）
  //   getPhyTagFromBlk(blkPaddr) = blkPaddr[41:6]
  // ===========================================================================
  wire s1_bankMSHRHit_7 =  // 端口 0 MSHR 命中（变量名沿用 golden）
    s1_valid & (s1_req_vaddr_0[13:6] == io_mshr_resp_bits_vSetIdx)
    & (s1_req_ptags_0 == io_mshr_resp_bits_blkPaddr[41:6]) & io_mshr_resp_valid
    & ~io_mshr_resp_bits_corrupt;
  wire s1_MSHR_hits_1 =    // 端口 1 MSHR 命中（需 doubleline）
    s1_valid & (s1_req_vaddr_1[13:6] == io_mshr_resp_bits_vSetIdx)
    & (s1_req_ptags_1 == io_mshr_resp_bits_blkPaddr[41:6]) & io_mshr_resp_valid
    & ~io_mshr_resp_bits_corrupt & s1_doubleline;

  // 每个数据 bank 由哪个端口的 MSHR 命中覆盖：bankIdx>=bankIdxLow 用端口0，否则端口1
  // bankIdxLow = offset >> 3 = vaddr[5:3]
  wire s1_bankMSHRHit_0 =
    (s1_req_vaddr_0[5:3] == 3'h0) & s1_bankMSHRHit_7 | (|s1_req_vaddr_0[5:3]) & s1_MSHR_hits_1;
  wire s1_bankMSHRHit_1 =
    (s1_req_vaddr_0[5:3] < 3'h2) & s1_bankMSHRHit_7 | (|s1_req_vaddr_0[5:4]) & s1_MSHR_hits_1;
  wire s1_bankMSHRHit_2 =
    (s1_req_vaddr_0[5:3] < 3'h3) & s1_bankMSHRHit_7 | (s1_req_vaddr_0[5:3] > 3'h2) & s1_MSHR_hits_1;
  wire s1_bankMSHRHit_3 =
    ~s1_req_vaddr_0[5] & s1_bankMSHRHit_7 | s1_req_vaddr_0[5] & s1_MSHR_hits_1;
  wire s1_bankMSHRHit_4 =
    (s1_req_vaddr_0[5:3] < 3'h5) & s1_bankMSHRHit_7 | (s1_req_vaddr_0[5:3] > 3'h4) & s1_MSHR_hits_1;
  wire s1_bankMSHRHit_5 =
    (s1_req_vaddr_0[5:4] != 2'h3) & s1_bankMSHRHit_7 | (s1_req_vaddr_0[5:3] > 3'h5) & s1_MSHR_hits_1;
  wire s1_bankMSHRHit_6 =
    (s1_req_vaddr_0[5:3] != 3'h7) & s1_bankMSHRHit_7 | (&s1_req_vaddr_0[5:3]) & s1_MSHR_hits_1;

  // ---- s1 数据 DataHoldBypass：MSHR 命中取回填数据，否则取 SRAM；用 r/REG 锁存 ----
  reg  [63:0] s1_datas_r,   s1_datas_r_1, s1_datas_r_2, s1_datas_r_3,
              s1_datas_r_4, s1_datas_r_5, s1_datas_r_6, s1_datas_r_7;
  reg         s1_datas_REG,   s1_datas_REG_1, s1_datas_REG_2, s1_datas_REG_3,
              s1_datas_REG_4, s1_datas_REG_5, s1_datas_REG_6, s1_datas_REG_7;
  wire [63:0] _s1_datas_T    = s1_bankMSHRHit_0 ? io_mshr_resp_bits_data[63:0]    : io_dataArray_fromIData_datas_0;
  wire [63:0] _s1_datas_T_3  = s1_bankMSHRHit_1 ? io_mshr_resp_bits_data[127:64]  : io_dataArray_fromIData_datas_1;
  wire [63:0] _s1_datas_T_6  = s1_bankMSHRHit_2 ? io_mshr_resp_bits_data[191:128] : io_dataArray_fromIData_datas_2;
  wire [63:0] _s1_datas_T_9  = s1_bankMSHRHit_3 ? io_mshr_resp_bits_data[255:192] : io_dataArray_fromIData_datas_3;
  wire [63:0] _s1_datas_T_12 = s1_bankMSHRHit_4 ? io_mshr_resp_bits_data[319:256] : io_dataArray_fromIData_datas_4;
  wire [63:0] _s1_datas_T_15 = s1_bankMSHRHit_5 ? io_mshr_resp_bits_data[383:320] : io_dataArray_fromIData_datas_5;
  wire [63:0] _s1_datas_T_18 = s1_bankMSHRHit_6 ? io_mshr_resp_bits_data[447:384] : io_dataArray_fromIData_datas_6;
  wire [63:0] _s1_datas_T_21 = s1_bankMSHRHit_7 ? io_mshr_resp_bits_data[511:448] : io_dataArray_fromIData_datas_7;
  // hold enable = 本拍 MSHR 命中 或 上一拍 s0_fire（数据有效）
  wire _s1_datas_T_1  = s1_bankMSHRHit_0 | s1_datas_REG;
  wire _s1_datas_T_4  = s1_bankMSHRHit_1 | s1_datas_REG_1;
  wire _s1_datas_T_7  = s1_bankMSHRHit_2 | s1_datas_REG_2;
  wire _s1_datas_T_10 = s1_bankMSHRHit_3 | s1_datas_REG_3;
  wire _s1_datas_T_13 = s1_bankMSHRHit_4 | s1_datas_REG_4;
  wire _s1_datas_T_16 = s1_bankMSHRHit_5 | s1_datas_REG_5;
  wire _s1_datas_T_19 = s1_bankMSHRHit_6 | s1_datas_REG_6;
  wire _s1_datas_T_22 = s1_bankMSHRHit_7 | s1_datas_REG_7;

  // ---- s1 data_is_from_MSHR：本 bank 数据是否来自 MSHR（同样 HoldBypass）----
  reg  s1_data_is_from_MSHR_r,   s1_data_is_from_MSHR_r_1, s1_data_is_from_MSHR_r_2, s1_data_is_from_MSHR_r_3,
       s1_data_is_from_MSHR_r_4, s1_data_is_from_MSHR_r_5, s1_data_is_from_MSHR_r_6, s1_data_is_from_MSHR_r_7;
  reg  s1_data_is_from_MSHR_REG,   s1_data_is_from_MSHR_REG_1, s1_data_is_from_MSHR_REG_2, s1_data_is_from_MSHR_REG_3,
       s1_data_is_from_MSHR_REG_4, s1_data_is_from_MSHR_REG_5, s1_data_is_from_MSHR_REG_6, s1_data_is_from_MSHR_REG_7;
  wire _s1_data_is_from_MSHR_T    = s1_bankMSHRHit_0 | s1_data_is_from_MSHR_REG;
  wire _s1_data_is_from_MSHR_T_2  = s1_bankMSHRHit_1 | s1_data_is_from_MSHR_REG_1;
  wire _s1_data_is_from_MSHR_T_4  = s1_bankMSHRHit_2 | s1_data_is_from_MSHR_REG_2;
  wire _s1_data_is_from_MSHR_T_6  = s1_bankMSHRHit_3 | s1_data_is_from_MSHR_REG_3;
  wire _s1_data_is_from_MSHR_T_8  = s1_bankMSHRHit_4 | s1_data_is_from_MSHR_REG_4;
  wire _s1_data_is_from_MSHR_T_10 = s1_bankMSHRHit_5 | s1_data_is_from_MSHR_REG_5;
  wire _s1_data_is_from_MSHR_T_12 = s1_bankMSHRHit_6 | s1_data_is_from_MSHR_REG_6;
  wire _s1_data_is_from_MSHR_T_14 = s1_bankMSHRHit_7 | s1_data_is_from_MSHR_REG_7;

  // ---- s1 codes DataHoldBypass（ECC code 来自 SRAM，按 RegNext(s0_fire) 锁存）----
  reg  s1_codes_REG;
  reg  s1_codes_r_0, s1_codes_r_1, s1_codes_r_2, s1_codes_r_3,
       s1_codes_r_4, s1_codes_r_5, s1_codes_r_6, s1_codes_r_7;

  assign s1_ready = s2_ready | ~s1_valid;
  wire   s1_fire  = s1_valid & s2_ready & ~io_flush;

  // ===========================================================================
  // s2 级寄存器
  // ===========================================================================
  reg         s2_valid;
  reg  [49:0] s2_req_vaddr_0, s2_req_vaddr_1;
  reg  [35:0] s2_req_ptags_0, s2_req_ptags_1;
  reg  [55:0] s2_req_gpaddr;
  reg         s2_req_isForVSnonLeafPTE;
  reg         s2_doubleline;
  reg  [1:0]  s2_exception_0, s2_exception_1;
  reg         s2_backendException;
  reg         s2_pmp_mmio_0, s2_pmp_mmio_1;
  reg  [1:0]  s2_itlb_pbmt_0, s2_itlb_pbmt_1;
  reg         s2_waymasks_0_0, s2_waymasks_0_1, s2_waymasks_0_2, s2_waymasks_0_3;
  reg         s2_waymasks_1_0, s2_waymasks_1_1, s2_waymasks_1_2, s2_waymasks_1_3;
  reg         s2_SRAMhits_0, s2_SRAMhits_1;
  reg         s2_codes_0, s2_codes_1, s2_codes_2, s2_codes_3,
              s2_codes_4, s2_codes_5, s2_codes_6, s2_codes_7;
  reg         s2_hits_0, s2_hits_1;
  reg  [63:0] s2_datas_0, s2_datas_1, s2_datas_2, s2_datas_3,
              s2_datas_4, s2_datas_5, s2_datas_6, s2_datas_7;
  reg         s2_data_is_from_MSHR_0, s2_data_is_from_MSHR_1, s2_data_is_from_MSHR_2, s2_data_is_from_MSHR_3,
              s2_data_is_from_MSHR_4, s2_data_is_from_MSHR_5, s2_data_is_from_MSHR_6, s2_data_is_from_MSHR_7;
  reg         s2_meta_corrupt_0, s2_meta_corrupt_1;
  reg         s2_l2_corrupt_0, s2_l2_corrupt_1;
  reg         s2_has_send_0, s2_has_send_1;

  wire [47:0] s2_req_paddr_0 = {s2_req_ptags_0, s2_req_vaddr_0[11:0]};
  wire [47:0] s2_req_paddr_1 = {s2_req_ptags_1, s2_req_vaddr_1[11:0]};

  // 各种 RegNext(s1_fire) 复制（error/flush valid 的延迟使能）
  reg io_errors_0_valid_REG, io_errors_0_bits_report_to_beu_REG;
  reg io_errors_1_valid_REG, io_errors_1_bits_report_to_beu_REG;
  reg io_metaArrayFlush_0_valid_REG, io_metaArrayFlush_1_valid_REG;
  reg REG, REG_1, REG_2, REG_3;     // RegNext(s1_fire) 给 data/meta corrupt error 用
  reg REG_4, REG_5;                  // RegNext(s2_fire & s2_l2_corrupt)
  reg [47:0] io_errors_0_bits_paddr_REG, io_errors_1_bits_paddr_REG;

  // ===========================================================================
  // s2 bankSel：把 512bit 数据按 offset 选出本次取指占用的 8 个 bank（每端口）。
  // 与 golden 一致：bankIdxLow=vaddr[5:3]（含进位扩展），bankIdxHigh=vaddr[5:0]+0x20。
  // sel_0..7 → 端口 0；sel_8..14 + (&high[6:3]) → 端口 1。
  // ===========================================================================
  wire [3:0] s2_bankSel_bankIdxLow      = {1'h0, s2_req_vaddr_0[5:3]};
  wire [6:0] _s2_bankSel_bankIdxHigh_T_1 = 7'({1'h0, s2_req_vaddr_0[5:0]} + 7'h20);
  wire s2_bankSel_bankSel_0  = s2_req_vaddr_0[5:3] == 3'h0;
  wire s2_bankSel_bankSel_1  = (s2_bankSel_bankIdxLow < 4'h2) & (|_s2_bankSel_bankIdxHigh_T_1[6:3]);
  wire s2_bankSel_bankSel_2  = (s2_bankSel_bankIdxLow < 4'h3) & (|_s2_bankSel_bankIdxHigh_T_1[6:4]);
  wire s2_bankSel_bankSel_3  = (s2_bankSel_bankIdxLow < 4'h4) & (_s2_bankSel_bankIdxHigh_T_1[6:3] > 4'h2);
  wire s2_bankSel_bankSel_4  = (s2_bankSel_bankIdxLow < 4'h5) & (|_s2_bankSel_bankIdxHigh_T_1[6:5]);
  wire s2_bankSel_bankSel_5  = (s2_bankSel_bankIdxLow < 4'h6) & (_s2_bankSel_bankIdxHigh_T_1[6:3] > 4'h4);
  wire s2_bankSel_bankSel_6  = (s2_bankSel_bankIdxLow < 4'h7) & (_s2_bankSel_bankIdxHigh_T_1[6:3] > 4'h5);
  wire s2_bankSel_bankSel_7  = _s2_bankSel_bankIdxHigh_T_1[6:3] > 4'h6;
  wire s2_bankSel_bankSel_8  = (s2_bankSel_bankIdxLow < 4'h9) & _s2_bankSel_bankIdxHigh_T_1[6];
  wire s2_bankSel_bankSel_9  = (s2_bankSel_bankIdxLow < 4'hA) & (_s2_bankSel_bankIdxHigh_T_1[6:3] > 4'h8);
  wire s2_bankSel_bankSel_10 = (s2_bankSel_bankIdxLow < 4'hB) & (_s2_bankSel_bankIdxHigh_T_1[6:3] > 4'h9);
  wire s2_bankSel_bankSel_11 = _s2_bankSel_bankIdxHigh_T_1[6:3] > 4'hA;
  wire s2_bankSel_bankSel_12 = (s2_bankSel_bankIdxLow < 4'hD) & (_s2_bankSel_bankIdxHigh_T_1[6:3] > 4'hB);
  wire s2_bankSel_bankSel_13 = _s2_bankSel_bankIdxHigh_T_1[6:3] > 4'hC;
  wire s2_bankSel_bankSel_14 = _s2_bankSel_bankIdxHigh_T_1[6:3] > 4'hD;

  // ---- s2 数据 ECC 校验：每 bank parity（^data != code），叠加 bankSel/SRAMhit/非MSHR ----
  wire s2_bank_corrupt_0 = (^s2_datas_0) != s2_codes_0;
  wire s2_bank_corrupt_1 = (^s2_datas_1) != s2_codes_1;
  wire s2_bank_corrupt_2 = (^s2_datas_2) != s2_codes_2;
  wire s2_bank_corrupt_3 = (^s2_datas_3) != s2_codes_3;
  wire s2_bank_corrupt_4 = (^s2_datas_4) != s2_codes_4;
  wire s2_bank_corrupt_5 = (^s2_datas_5) != s2_codes_5;
  wire s2_bank_corrupt_6 = (^s2_datas_6) != s2_codes_6;
  wire s2_bank_corrupt_7 = (^s2_datas_7) != s2_codes_7;

  wire s2_data_corrupt_0 =
    io_ecc_enable
    & (s2_bank_corrupt_0 & s2_bankSel_bankSel_0 & ~s2_data_is_from_MSHR_0
     | s2_bank_corrupt_1 & s2_bankSel_bankSel_1 & ~s2_data_is_from_MSHR_1
     | s2_bank_corrupt_2 & s2_bankSel_bankSel_2 & ~s2_data_is_from_MSHR_2
     | s2_bank_corrupt_3 & s2_bankSel_bankSel_3 & ~s2_data_is_from_MSHR_3
     | s2_bank_corrupt_4 & s2_bankSel_bankSel_4 & ~s2_data_is_from_MSHR_4
     | s2_bank_corrupt_5 & s2_bankSel_bankSel_5 & ~s2_data_is_from_MSHR_5
     | s2_bank_corrupt_6 & s2_bankSel_bankSel_6 & ~s2_data_is_from_MSHR_6
     | s2_bank_corrupt_7 & s2_bankSel_bankSel_7 & ~s2_data_is_from_MSHR_7)
    & s2_SRAMhits_0;
  wire s2_data_corrupt_1 =
    io_ecc_enable
    & (s2_bank_corrupt_0 & s2_bankSel_bankSel_8  & ~s2_data_is_from_MSHR_0
     | s2_bank_corrupt_1 & s2_bankSel_bankSel_9  & ~s2_data_is_from_MSHR_1
     | s2_bank_corrupt_2 & s2_bankSel_bankSel_10 & ~s2_data_is_from_MSHR_2
     | s2_bank_corrupt_3 & s2_bankSel_bankSel_11 & ~s2_data_is_from_MSHR_3
     | s2_bank_corrupt_4 & s2_bankSel_bankSel_12 & ~s2_data_is_from_MSHR_4
     | s2_bank_corrupt_5 & s2_bankSel_bankSel_13 & ~s2_data_is_from_MSHR_5
     | s2_bank_corrupt_6 & s2_bankSel_bankSel_14 & ~s2_data_is_from_MSHR_6
     | s2_bank_corrupt_7 & (&_s2_bankSel_bankIdxHigh_T_1[6:3]) & ~s2_data_is_from_MSHR_7)
    & s2_SRAMhits_1;

  wire s2_corrupt_refetch_0 = s2_meta_corrupt_0 | s2_data_corrupt_0;
  wire s2_corrupt_refetch_1 = s2_meta_corrupt_1 | s2_data_corrupt_1;

  // l2 corrupt error 的二级延迟（RegNext(s2_fire & s2_l2_corrupt)）
  wire _GEN   = s2_data_corrupt_0 & REG;
  wire _GEN_0 = s2_data_corrupt_1 & REG_1;
  wire _GEN_1 = s2_meta_corrupt_0 & REG_2;
  wire _GEN_2 = s2_meta_corrupt_1 & REG_3;

  // mmio = pmp_mmio | Pbmt.isUncache(pbmt)（pbmt==1(NC) 或 ==2(IO)）
  wire s2_mmio_0 = s2_pmp_mmio_0 | (s2_itlb_pbmt_0 == 2'h1) | (s2_itlb_pbmt_0 == 2'h2);

  // should_fetch：未命中或需重取 & 无异常 & 非 mmio（端口 1 还需 doubleline 且端口 0 无异常）
  wire s2_should_fetch_0 =
    (~s2_hits_0 | s2_corrupt_refetch_0) & (s2_exception_0 == 2'h0) & ~s2_mmio_0;
  wire s2_should_fetch_1 =
    (~s2_hits_1 | s2_corrupt_refetch_1) & s2_doubleline
    & ~((|s2_exception_0) | (|s2_exception_1)) & ~s2_mmio_0
    & ~(s2_pmp_mmio_1 | (s2_itlb_pbmt_1 == 2'h1) | (s2_itlb_pbmt_1 == 2'h2));

  wire _toMSHRArbiter_io_in_0_valid_T_4 = s2_valid & s2_should_fetch_0 & ~s2_has_send_0 & ~io_flush;
  wire _toMSHRArbiter_io_in_1_valid_T_4 = s2_valid & s2_should_fetch_1 & ~s2_has_send_1 & ~io_flush;

  // ---- 内联 2 路 Arbiter（Arbiter2_ICacheMissReq）：端口 0 优先 ----
  wire _toMSHRArbiter_io_out_valid = _toMSHRArbiter_io_in_0_valid_T_4 | _toMSHRArbiter_io_in_1_valid_T_4;
  wire _toMSHRArbiter_io_in_0_ready = io_mshr_req_ready;
  wire _toMSHRArbiter_io_in_1_ready = ~_toMSHRArbiter_io_in_0_valid_T_4 & io_mshr_req_ready;
  wire _GEN_3 = _toMSHRArbiter_io_out_valid & ~io_mshr_req_ready;  // 保留以匹配 golden 命名

  wire io_fetch_topdownIcacheMiss_0 = s2_should_fetch_0 | s2_should_fetch_1;
  assign s2_ready = (~io_fetch_topdownIcacheMiss_0 & ~io_respStall) | ~s2_valid;
  wire   s2_fire  = s2_valid & ~io_fetch_topdownIcacheMiss_0 & ~io_respStall & ~io_flush;

  wire _GEN_4 = s2_valid & io_fetch_topdownIcacheMiss_0;  // 保留命名
  wire _GEN_5 = io_fetch_req_valid & ~s0_fire;            // = topdownItlbMiss

  // ---- s1 meta ECC：hit_num（waymask popcount）；hit 一路但 parity 不符 或 命中多路 → corrupt ----
  wire [2:0] s1_meta_corrupt_hit_num =
    3'({1'h0, 2'({1'h0, s1_waymasks_0_0} + {1'h0, s1_waymasks_0_1})}
     + {1'h0, 2'({1'h0, s1_waymasks_0_2} + {1'h0, s1_waymasks_0_3})});
  wire [2:0] s1_meta_corrupt_hit_num_1 =
    3'({1'h0, 2'({1'h0, s1_waymasks_1_0} + {1'h0, s1_waymasks_1_1})}
     + {1'h0, 2'({1'h0, s1_waymasks_1_2} + {1'h0, s1_waymasks_1_3})});

  // ValidHoldBypass 命中：MSHR 命中或（RegNext(s0_fire) & SRAMhit），fire/flush 清
  wire _s1_hits_T_1 = s1_bankMSHRHit_7 | (s1_hits_REG & s1_SRAMhits_0);
  wire _s1_hits_T_4 = s1_MSHR_hits_1 | (s1_hits_REG_1 & s1_SRAMhits_1);
  wire _s1_hits_T_5 = s1_fire | io_flush;

  // ===========================================================================
  // s2 MSHR 回填命中（s2 级；不关心 corrupt）
  // ===========================================================================
  wire s2_bankMSHRHit_7 =
    s2_valid & (s2_req_vaddr_0[13:6] == io_mshr_resp_bits_vSetIdx)
    & (s2_req_ptags_0 == io_mshr_resp_bits_blkPaddr[41:6]) & io_mshr_resp_valid;
  wire s2_MSHR_hits_1 =
    s2_valid & (s2_req_vaddr_1[13:6] == io_mshr_resp_bits_vSetIdx)
    & (s2_req_ptags_1 == io_mshr_resp_bits_blkPaddr[41:6]) & io_mshr_resp_valid
    & s2_doubleline;
  wire s2_bankMSHRHit_0 =
    (s2_req_vaddr_0[5:3] == 3'h0) & s2_bankMSHRHit_7 | (|s2_req_vaddr_0[5:3]) & s2_MSHR_hits_1;
  wire s2_bankMSHRHit_1 =
    (s2_req_vaddr_0[5:3] < 3'h2) & s2_bankMSHRHit_7 | (|s2_req_vaddr_0[5:4]) & s2_MSHR_hits_1;
  wire s2_bankMSHRHit_2 =
    (s2_req_vaddr_0[5:3] < 3'h3) & s2_bankMSHRHit_7 | (s2_req_vaddr_0[5:3] > 3'h2) & s2_MSHR_hits_1;
  wire s2_bankMSHRHit_3 =
    ~s2_req_vaddr_0[5] & s2_bankMSHRHit_7 | s2_req_vaddr_0[5] & s2_MSHR_hits_1;
  wire s2_bankMSHRHit_4 =
    (s2_req_vaddr_0[5:3] < 3'h5) & s2_bankMSHRHit_7 | (s2_req_vaddr_0[5:3] > 3'h4) & s2_MSHR_hits_1;
  wire s2_bankMSHRHit_5 =
    (s2_req_vaddr_0[5:4] != 2'h3) & s2_bankMSHRHit_7 | (s2_req_vaddr_0[5:3] > 3'h5) & s2_MSHR_hits_1;
  wire s2_bankMSHRHit_6 =
    (s2_req_vaddr_0[5:3] != 3'h7) & s2_bankMSHRHit_7 | (&s2_req_vaddr_0[5:3]) & s2_MSHR_hits_1;

  // ===========================================================================
  // 时序逻辑（主 always_ff，带异步复位）—— 与 golden 主 always 块对齐
  // ===========================================================================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      cntFtqFireInterval <= 32'h0;
      s1_valid <= 1'h0;
      s1_req_vaddr_0 <= 50'h0;  s1_req_vaddr_1 <= 50'h0;
      s1_req_ptags_0 <= 36'h0;  s1_req_ptags_1 <= 36'h0;
      s1_req_gpaddr <= 56'h0;   s1_req_isForVSnonLeafPTE <= 1'h0;
      s1_doubleline <= 1'h0;
      s1_SRAMhits_0 <= 1'h0;    s1_SRAMhits_1 <= 1'h0;
      s1_itlb_exception_0 <= 2'h0; s1_itlb_exception_1 <= 2'h0;
      s1_backendException <= 1'h0;
      s1_itlb_pbmt_0 <= 2'h0;   s1_itlb_pbmt_1 <= 2'h0;
      s1_waymasks_0_0 <= 1'h0;  s1_waymasks_0_1 <= 1'h0;  s1_waymasks_0_2 <= 1'h0;  s1_waymasks_0_3 <= 1'h0;
      s1_waymasks_1_0 <= 1'h0;  s1_waymasks_1_1 <= 1'h0;  s1_waymasks_1_2 <= 1'h0;  s1_waymasks_1_3 <= 1'h0;
      s1_meta_codes_0 <= 1'h0;  s1_meta_codes_1 <= 1'h0;
      s1_hits_valid <= 1'h0;    s1_hits_valid_1 <= 1'h0;
      s2_valid <= 1'h0;
      s2_req_vaddr_0 <= 50'h0;  s2_req_vaddr_1 <= 50'h0;
      s2_req_ptags_0 <= 36'h0;  s2_req_ptags_1 <= 36'h0;
      s2_req_gpaddr <= 56'h0;   s2_req_isForVSnonLeafPTE <= 1'h0;
      s2_doubleline <= 1'h0;
      s2_exception_0 <= 2'h0;   s2_exception_1 <= 2'h0;
      s2_backendException <= 1'h0;
      s2_pmp_mmio_0 <= 1'h0;    s2_pmp_mmio_1 <= 1'h0;
      s2_itlb_pbmt_0 <= 2'h0;   s2_itlb_pbmt_1 <= 2'h0;
      s2_waymasks_0_0 <= 1'h0;  s2_waymasks_0_1 <= 1'h0;  s2_waymasks_0_2 <= 1'h0;  s2_waymasks_0_3 <= 1'h0;
      s2_waymasks_1_0 <= 1'h0;  s2_waymasks_1_1 <= 1'h0;  s2_waymasks_1_2 <= 1'h0;  s2_waymasks_1_3 <= 1'h0;
      s2_SRAMhits_0 <= 1'h0;    s2_SRAMhits_1 <= 1'h0;
      s2_codes_0 <= 1'h0; s2_codes_1 <= 1'h0; s2_codes_2 <= 1'h0; s2_codes_3 <= 1'h0;
      s2_codes_4 <= 1'h0; s2_codes_5 <= 1'h0; s2_codes_6 <= 1'h0; s2_codes_7 <= 1'h0;
      s2_hits_0 <= 1'h0; s2_hits_1 <= 1'h0;
      s2_datas_0 <= 64'h0; s2_datas_1 <= 64'h0; s2_datas_2 <= 64'h0; s2_datas_3 <= 64'h0;
      s2_datas_4 <= 64'h0; s2_datas_5 <= 64'h0; s2_datas_6 <= 64'h0; s2_datas_7 <= 64'h0;
      s2_data_is_from_MSHR_0 <= 1'h0; s2_data_is_from_MSHR_1 <= 1'h0;
      s2_data_is_from_MSHR_2 <= 1'h0; s2_data_is_from_MSHR_3 <= 1'h0;
      s2_data_is_from_MSHR_4 <= 1'h0; s2_data_is_from_MSHR_5 <= 1'h0;
      s2_data_is_from_MSHR_6 <= 1'h0; s2_data_is_from_MSHR_7 <= 1'h0;
      s2_meta_corrupt_0 <= 1'h0; s2_meta_corrupt_1 <= 1'h0;
      s2_l2_corrupt_0 <= 1'h0;   s2_l2_corrupt_1 <= 1'h0;
      s2_has_send_0 <= 1'h0;     s2_has_send_1 <= 1'h0;
    end
    else begin
      // FTQ fire 间隔计数
      if (x3_probe) cntFtqFireInterval <= 32'h1;
      else          cntFtqFireInterval <= 32'(cntFtqFireInterval + 32'h1);

      // ---- s1 valid：s0_fire 置位，s1_fire 清；io_flush 强清 ----
      s1_valid <= ~io_flush & (s0_fire | (~s1_fire & s1_valid));
      // ---- s0_fire 时锁存请求/wayLookup 信息到 s1 ----
      if (s0_fire) begin
        s1_req_vaddr_0 <= io_fetch_req_bits_pcMemRead_4_startAddr;
        s1_req_vaddr_1 <= io_fetch_req_bits_pcMemRead_4_nextlineStart;
        s1_req_ptags_0 <= io_wayLookupRead_bits_entry_ptag_0;
        s1_req_ptags_1 <= io_wayLookupRead_bits_entry_ptag_1;
        s1_req_gpaddr <= io_wayLookupRead_bits_gpf_gpaddr;
        s1_req_isForVSnonLeafPTE <= io_wayLookupRead_bits_gpf_isForVSnonLeafPTE;
        s1_doubleline <= io_fetch_req_bits_readValid_4 & io_fetch_req_bits_pcMemRead_4_startAddr[5];
        s1_SRAMhits_0 <= |io_wayLookupRead_bits_entry_waymask_0;
        s1_SRAMhits_1 <= |io_wayLookupRead_bits_entry_waymask_1;
        s1_itlb_exception_0 <= io_wayLookupRead_bits_entry_itlb_exception_0;
        s1_itlb_exception_1 <= io_wayLookupRead_bits_entry_itlb_exception_1;
        s1_backendException <= io_fetch_req_bits_backendException;
        s1_itlb_pbmt_0 <= io_wayLookupRead_bits_entry_itlb_pbmt_0;
        s1_itlb_pbmt_1 <= io_wayLookupRead_bits_entry_itlb_pbmt_1;
        s1_waymasks_0_0 <= io_wayLookupRead_bits_entry_waymask_0[0];
        s1_waymasks_0_1 <= io_wayLookupRead_bits_entry_waymask_0[1];
        s1_waymasks_0_2 <= io_wayLookupRead_bits_entry_waymask_0[2];
        s1_waymasks_0_3 <= io_wayLookupRead_bits_entry_waymask_0[3];
        s1_waymasks_1_0 <= io_wayLookupRead_bits_entry_waymask_1[0];
        s1_waymasks_1_1 <= io_wayLookupRead_bits_entry_waymask_1[1];
        s1_waymasks_1_2 <= io_wayLookupRead_bits_entry_waymask_1[2];
        s1_waymasks_1_3 <= io_wayLookupRead_bits_entry_waymask_1[3];
        s1_meta_codes_0 <= io_wayLookupRead_bits_entry_meta_codes_0;
        s1_meta_codes_1 <= io_wayLookupRead_bits_entry_meta_codes_1;
      end
      // ---- s1 hits ValidHoldBypass 状态 ----
      s1_hits_valid   <= ~_s1_hits_T_5 & (_s1_hits_T_1 | s1_hits_valid);
      s1_hits_valid_1 <= ~_s1_hits_T_5 & (_s1_hits_T_4 | s1_hits_valid_1);

      // ---- s2 valid ----
      s2_valid <= ~io_flush & (s1_fire | (~s2_fire & s2_valid));
      if (s1_fire) begin
        // s1 -> s2 流转
        s2_req_vaddr_0 <= s1_req_vaddr_0;  s2_req_vaddr_1 <= s1_req_vaddr_1;
        s2_req_ptags_0 <= s1_req_ptags_0;  s2_req_ptags_1 <= s1_req_ptags_1;
        s2_req_gpaddr <= s1_req_gpaddr;    s2_req_isForVSnonLeafPTE <= s1_req_isForVSnonLeafPTE;
        s2_doubleline <= s1_doubleline;
        // exception = itlb 优先，否则 pmp instr af（fromPMPResp）
        s2_exception_0 <= (|s1_itlb_exception_0) ? s1_itlb_exception_0 : {2{io_pmp_0_resp_instr}};
        s2_exception_1 <= (|s1_itlb_exception_1) ? s1_itlb_exception_1 : {2{io_pmp_1_resp_instr}};
        s2_backendException <= s1_backendException;
        s2_pmp_mmio_0 <= io_pmp_0_resp_mmio;  s2_pmp_mmio_1 <= io_pmp_1_resp_mmio;
        s2_itlb_pbmt_0 <= s1_itlb_pbmt_0;     s2_itlb_pbmt_1 <= s1_itlb_pbmt_1;
        s2_waymasks_0_0 <= s1_waymasks_0_0; s2_waymasks_0_1 <= s1_waymasks_0_1;
        s2_waymasks_0_2 <= s1_waymasks_0_2; s2_waymasks_0_3 <= s1_waymasks_0_3;
        s2_waymasks_1_0 <= s1_waymasks_1_0; s2_waymasks_1_1 <= s1_waymasks_1_1;
        s2_waymasks_1_2 <= s1_waymasks_1_2; s2_waymasks_1_3 <= s1_waymasks_1_3;
        s2_SRAMhits_0 <= s1_SRAMhits_0;     s2_SRAMhits_1 <= s1_SRAMhits_1;
        // codes：DataHoldBypass 解开（s1_codes_REG=RegNext(s0_fire) 时取 SRAM，否则取 r）
        s2_codes_0 <= s1_codes_REG ? io_dataArray_fromIData_codes_0 : s1_codes_r_0;
        s2_codes_1 <= s1_codes_REG ? io_dataArray_fromIData_codes_1 : s1_codes_r_1;
        s2_codes_2 <= s1_codes_REG ? io_dataArray_fromIData_codes_2 : s1_codes_r_2;
        s2_codes_3 <= s1_codes_REG ? io_dataArray_fromIData_codes_3 : s1_codes_r_3;
        s2_codes_4 <= s1_codes_REG ? io_dataArray_fromIData_codes_4 : s1_codes_r_4;
        s2_codes_5 <= s1_codes_REG ? io_dataArray_fromIData_codes_5 : s1_codes_r_5;
        s2_codes_6 <= s1_codes_REG ? io_dataArray_fromIData_codes_6 : s1_codes_r_6;
        s2_codes_7 <= s1_codes_REG ? io_dataArray_fromIData_codes_7 : s1_codes_r_7;
        s2_hits_0 <= s1_hits_valid   | _s1_hits_T_1;
        s2_hits_1 <= s1_hits_valid_1 | _s1_hits_T_4;
        s2_datas_0 <= _s1_datas_T_1  ? _s1_datas_T    : s1_datas_r;
        s2_datas_1 <= _s1_datas_T_4  ? _s1_datas_T_3  : s1_datas_r_1;
        s2_datas_2 <= _s1_datas_T_7  ? _s1_datas_T_6  : s1_datas_r_2;
        s2_datas_3 <= _s1_datas_T_10 ? _s1_datas_T_9  : s1_datas_r_3;
        s2_datas_4 <= _s1_datas_T_13 ? _s1_datas_T_12 : s1_datas_r_4;
        s2_datas_5 <= _s1_datas_T_16 ? _s1_datas_T_15 : s1_datas_r_5;
        s2_datas_6 <= _s1_datas_T_19 ? _s1_datas_T_18 : s1_datas_r_6;
        s2_datas_7 <= _s1_datas_T_22 ? _s1_datas_T_21 : s1_datas_r_7;
        s2_data_is_from_MSHR_0 <= _s1_data_is_from_MSHR_T    ? s1_bankMSHRHit_0 : s1_data_is_from_MSHR_r;
        s2_data_is_from_MSHR_1 <= _s1_data_is_from_MSHR_T_2  ? s1_bankMSHRHit_1 : s1_data_is_from_MSHR_r_1;
        s2_data_is_from_MSHR_2 <= _s1_data_is_from_MSHR_T_4  ? s1_bankMSHRHit_2 : s1_data_is_from_MSHR_r_2;
        s2_data_is_from_MSHR_3 <= _s1_data_is_from_MSHR_T_6  ? s1_bankMSHRHit_3 : s1_data_is_from_MSHR_r_3;
        s2_data_is_from_MSHR_4 <= _s1_data_is_from_MSHR_T_8  ? s1_bankMSHRHit_4 : s1_data_is_from_MSHR_r_4;
        s2_data_is_from_MSHR_5 <= _s1_data_is_from_MSHR_T_10 ? s1_bankMSHRHit_5 : s1_data_is_from_MSHR_r_5;
        s2_data_is_from_MSHR_6 <= _s1_data_is_from_MSHR_T_12 ? s1_bankMSHRHit_6 : s1_data_is_from_MSHR_r_6;
        s2_data_is_from_MSHR_7 <= _s1_data_is_from_MSHR_T_14 ? s1_bankMSHRHit_7 : s1_data_is_from_MSHR_r_7;
        // meta ECC corrupt（来自 s1）
        s2_meta_corrupt_0 <=
          io_ecc_enable
          & (((^s1_req_ptags_0) != s1_meta_codes_0) & (s1_meta_corrupt_hit_num == 3'h1)
           | (|s1_meta_corrupt_hit_num[2:1]));
        s2_meta_corrupt_1 <=
          io_ecc_enable
          & (((^s1_req_ptags_1) != s1_meta_codes_1) & (s1_meta_corrupt_hit_num_1 == 3'h1)
           | (|s1_meta_corrupt_hit_num_1[2:1]));
      end
      else begin
        // s2 停留期间：监听 MSHR 回填，更新 hit/data/from_MSHR/meta_corrupt
        s2_hits_0 <= s2_bankMSHRHit_7 | s2_hits_0;
        s2_hits_1 <= s2_MSHR_hits_1   | s2_hits_1;
        if (s2_bankMSHRHit_0) s2_datas_0 <= io_mshr_resp_bits_data[63:0];
        if (s2_bankMSHRHit_1) s2_datas_1 <= io_mshr_resp_bits_data[127:64];
        if (s2_bankMSHRHit_2) s2_datas_2 <= io_mshr_resp_bits_data[191:128];
        if (s2_bankMSHRHit_3) s2_datas_3 <= io_mshr_resp_bits_data[255:192];
        if (s2_bankMSHRHit_4) s2_datas_4 <= io_mshr_resp_bits_data[319:256];
        if (s2_bankMSHRHit_5) s2_datas_5 <= io_mshr_resp_bits_data[383:320];
        if (s2_bankMSHRHit_6) s2_datas_6 <= io_mshr_resp_bits_data[447:384];
        if (s2_bankMSHRHit_7) s2_datas_7 <= io_mshr_resp_bits_data[511:448];
        s2_data_is_from_MSHR_0 <= s2_bankMSHRHit_0 | s2_data_is_from_MSHR_0;
        s2_data_is_from_MSHR_1 <= s2_bankMSHRHit_1 | s2_data_is_from_MSHR_1;
        s2_data_is_from_MSHR_2 <= s2_bankMSHRHit_2 | s2_data_is_from_MSHR_2;
        s2_data_is_from_MSHR_3 <= s2_bankMSHRHit_3 | s2_data_is_from_MSHR_3;
        s2_data_is_from_MSHR_4 <= s2_bankMSHRHit_4 | s2_data_is_from_MSHR_4;
        s2_data_is_from_MSHR_5 <= s2_bankMSHRHit_5 | s2_data_is_from_MSHR_5;
        s2_data_is_from_MSHR_6 <= s2_bankMSHRHit_6 | s2_data_is_from_MSHR_6;
        s2_data_is_from_MSHR_7 <= s2_bankMSHRHit_7 | s2_data_is_from_MSHR_7;
        s2_meta_corrupt_0 <= ~s2_bankMSHRHit_7 & s2_meta_corrupt_0;
        s2_meta_corrupt_1 <= ~s2_MSHR_hits_1   & s2_meta_corrupt_1;
      end
      // l2 corrupt：s1_fire 清；s2 MSHR 命中时取 resp corrupt 位
      s2_l2_corrupt_0 <= ~s1_fire & (s2_bankMSHRHit_7 ? io_mshr_resp_bits_corrupt : s2_l2_corrupt_0);
      s2_l2_corrupt_1 <= ~s1_fire & (s2_MSHR_hits_1   ? io_mshr_resp_bits_corrupt : s2_l2_corrupt_1);
      // has_send：避免向 MSHR 发重复请求
      s2_has_send_0 <= ~s1_fire & ((_toMSHRArbiter_io_in_0_ready & _toMSHRArbiter_io_in_0_valid_T_4) | s2_has_send_0);
      s2_has_send_1 <= ~s1_fire & ((_toMSHRArbiter_io_in_1_ready & _toMSHRArbiter_io_in_1_valid_T_4) | s2_has_send_1);
    end
  end

  // ===========================================================================
  // 同步寄存器（无复位）—— 与 golden 第二个 always @(posedge clock) 块对齐
  // 主要是各 RegNext(s0_fire)/RegNext(s1_fire) 使能寄存器 + DataHoldBypass 锁存
  // ===========================================================================
  always @(posedge clock) begin
    io_touch_0_valid_REG <= s0_fire;
    io_touch_1_valid_REG <= s0_fire;
    s1_hits_REG   <= s0_fire;
    s1_hits_REG_1 <= s0_fire;
    s1_datas_REG <= s0_fire;
    if (_s1_datas_T_1)  s1_datas_r   <= _s1_datas_T;
    s1_datas_REG_1 <= s0_fire;
    if (_s1_datas_T_4)  s1_datas_r_1 <= _s1_datas_T_3;
    s1_datas_REG_2 <= s0_fire;
    if (_s1_datas_T_7)  s1_datas_r_2 <= _s1_datas_T_6;
    s1_datas_REG_3 <= s0_fire;
    if (_s1_datas_T_10) s1_datas_r_3 <= _s1_datas_T_9;
    s1_datas_REG_4 <= s0_fire;
    if (_s1_datas_T_13) s1_datas_r_4 <= _s1_datas_T_12;
    s1_datas_REG_5 <= s0_fire;
    if (_s1_datas_T_16) s1_datas_r_5 <= _s1_datas_T_15;
    s1_datas_REG_6 <= s0_fire;
    if (_s1_datas_T_19) s1_datas_r_6 <= _s1_datas_T_18;
    s1_datas_REG_7 <= s0_fire;
    if (_s1_datas_T_22) s1_datas_r_7 <= _s1_datas_T_21;
    s1_data_is_from_MSHR_REG <= s0_fire;
    if (_s1_data_is_from_MSHR_T)    s1_data_is_from_MSHR_r   <= s1_bankMSHRHit_0;
    s1_data_is_from_MSHR_REG_1 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_2)  s1_data_is_from_MSHR_r_1 <= s1_bankMSHRHit_1;
    s1_data_is_from_MSHR_REG_2 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_4)  s1_data_is_from_MSHR_r_2 <= s1_bankMSHRHit_2;
    s1_data_is_from_MSHR_REG_3 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_6)  s1_data_is_from_MSHR_r_3 <= s1_bankMSHRHit_3;
    s1_data_is_from_MSHR_REG_4 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_8)  s1_data_is_from_MSHR_r_4 <= s1_bankMSHRHit_4;
    s1_data_is_from_MSHR_REG_5 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_10) s1_data_is_from_MSHR_r_5 <= s1_bankMSHRHit_5;
    s1_data_is_from_MSHR_REG_6 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_12) s1_data_is_from_MSHR_r_6 <= s1_bankMSHRHit_6;
    s1_data_is_from_MSHR_REG_7 <= s0_fire;
    if (_s1_data_is_from_MSHR_T_14) s1_data_is_from_MSHR_r_7 <= s1_bankMSHRHit_7;
    s1_codes_REG <= s0_fire;
    if (s1_codes_REG) begin
      s1_codes_r_0 <= io_dataArray_fromIData_codes_0;
      s1_codes_r_1 <= io_dataArray_fromIData_codes_1;
      s1_codes_r_2 <= io_dataArray_fromIData_codes_2;
      s1_codes_r_3 <= io_dataArray_fromIData_codes_3;
      s1_codes_r_4 <= io_dataArray_fromIData_codes_4;
      s1_codes_r_5 <= io_dataArray_fromIData_codes_5;
      s1_codes_r_6 <= io_dataArray_fromIData_codes_6;
      s1_codes_r_7 <= io_dataArray_fromIData_codes_7;
    end
    io_errors_0_valid_REG <= s1_fire;
    io_errors_0_bits_report_to_beu_REG <= s1_fire;
    io_errors_1_valid_REG <= s1_fire;
    io_errors_1_bits_report_to_beu_REG <= s1_fire;
    io_metaArrayFlush_0_valid_REG <= s1_fire;
    io_metaArrayFlush_1_valid_REG <= s1_fire;
    REG   <= s1_fire;
    REG_1 <= s1_fire;
    REG_2 <= s1_fire;
    REG_3 <= s1_fire;
    REG_4 <= s2_fire & s2_l2_corrupt_0;
    io_errors_0_bits_paddr_REG <= s2_req_paddr_0;
    REG_5 <= s2_fire & s2_l2_corrupt_1;
    io_errors_1_bits_paddr_REG <= s2_req_paddr_1;
  end

  // ===========================================================================
  // s0 组合输出：数据 SRAM 读请求（4 个 partWay 口）
  // ===========================================================================
  assign io_dataArray_toIData_0_valid          = io_fetch_req_bits_readValid_0;
  assign io_dataArray_toIData_0_bits_vSetIdx_0  = io_fetch_req_bits_pcMemRead_0_startAddr[13:6];
  assign io_dataArray_toIData_0_bits_vSetIdx_1  = io_fetch_req_bits_pcMemRead_0_nextlineStart[13:6];
  assign io_dataArray_toIData_0_bits_waymask_0_0 = io_wayLookupRead_bits_entry_waymask_0[0];
  assign io_dataArray_toIData_0_bits_waymask_0_1 = io_wayLookupRead_bits_entry_waymask_0[1];
  assign io_dataArray_toIData_0_bits_waymask_0_2 = io_wayLookupRead_bits_entry_waymask_0[2];
  assign io_dataArray_toIData_0_bits_waymask_0_3 = io_wayLookupRead_bits_entry_waymask_0[3];
  assign io_dataArray_toIData_0_bits_waymask_1_0 = io_wayLookupRead_bits_entry_waymask_1[0];
  assign io_dataArray_toIData_0_bits_waymask_1_1 = io_wayLookupRead_bits_entry_waymask_1[1];
  assign io_dataArray_toIData_0_bits_waymask_1_2 = io_wayLookupRead_bits_entry_waymask_1[2];
  assign io_dataArray_toIData_0_bits_waymask_1_3 = io_wayLookupRead_bits_entry_waymask_1[3];
  assign io_dataArray_toIData_0_bits_blkOffset   = io_fetch_req_bits_pcMemRead_0_startAddr[5:0];
  assign io_dataArray_toIData_1_valid          = io_fetch_req_bits_readValid_1;
  assign io_dataArray_toIData_1_bits_vSetIdx_0  = io_fetch_req_bits_pcMemRead_1_startAddr[13:6];
  assign io_dataArray_toIData_1_bits_vSetIdx_1  = io_fetch_req_bits_pcMemRead_1_nextlineStart[13:6];
  assign io_dataArray_toIData_2_valid          = io_fetch_req_bits_readValid_2;
  assign io_dataArray_toIData_2_bits_vSetIdx_0  = io_fetch_req_bits_pcMemRead_2_startAddr[13:6];
  assign io_dataArray_toIData_2_bits_vSetIdx_1  = io_fetch_req_bits_pcMemRead_2_nextlineStart[13:6];
  assign io_dataArray_toIData_3_valid          = io_fetch_req_bits_readValid_3;
  assign io_dataArray_toIData_3_bits_vSetIdx_0  = io_fetch_req_bits_pcMemRead_3_startAddr[13:6];
  assign io_dataArray_toIData_3_bits_vSetIdx_1  = io_fetch_req_bits_pcMemRead_3_nextlineStart[13:6];

  // ===========================================================================
  // metaArray flush（ECC 损坏后）
  // ===========================================================================
  assign io_metaArrayFlush_0_valid       = s2_corrupt_refetch_0 & io_metaArrayFlush_0_valid_REG;
  assign io_metaArrayFlush_0_bits_virIdx = s2_req_vaddr_0[13:6];
  assign io_metaArrayFlush_0_bits_waymask =
    s2_meta_corrupt_0 ? 4'hF : {s2_waymasks_0_3, s2_waymasks_0_2, s2_waymasks_0_1, s2_waymasks_0_0};
  assign io_metaArrayFlush_1_valid       = s2_corrupt_refetch_1 & io_metaArrayFlush_1_valid_REG;
  assign io_metaArrayFlush_1_bits_virIdx = s2_req_vaddr_1[13:6];
  assign io_metaArrayFlush_1_bits_waymask =
    s2_meta_corrupt_1 ? 4'hF : {s2_waymasks_1_3, s2_waymasks_1_2, s2_waymasks_1_1, s2_waymasks_1_0};

  // ===========================================================================
  // replacer touch（s1 命中时；way = OHToUInt(waymask)）
  // ===========================================================================
  assign io_touch_0_valid       = io_touch_0_valid_REG & s1_SRAMhits_0;
  assign io_touch_0_bits_vSetIdx = s1_req_vaddr_0[13:6];
  assign io_touch_0_bits_way     = {|{s1_waymasks_0_3, s1_waymasks_0_2}, s1_waymasks_0_3 | s1_waymasks_0_1};
  assign io_touch_1_valid       = io_touch_1_valid_REG & s1_SRAMhits_1 & s1_doubleline;
  assign io_touch_1_bits_vSetIdx = s1_req_vaddr_1[13:6];
  assign io_touch_1_bits_way     = {|{s1_waymasks_1_3, s1_waymasks_1_2}, s1_waymasks_1_3 | s1_waymasks_1_1};

  assign io_wayLookupRead_ready = s0_fire;
  assign io_mshr_req_valid      = _toMSHRArbiter_io_out_valid;
  // 内联 Arbiter 输出：端口 0 优先
  assign io_mshr_req_bits_blkPaddr =
    _toMSHRArbiter_io_in_0_valid_T_4 ? {s2_req_ptags_0, s2_req_vaddr_0[11:6]}
                                     : {s2_req_ptags_1, s2_req_vaddr_1[11:6]};
  assign io_mshr_req_bits_vSetIdx =
    _toMSHRArbiter_io_in_0_valid_T_4 ? s2_req_vaddr_0[13:6] : s2_req_vaddr_1[13:6];

  assign io_fetch_req_ready = s0_can_go;

  // ===========================================================================
  // 向 IFU 返回取指结果
  // ===========================================================================
  assign io_fetch_resp_valid           = s2_fire;
  assign io_fetch_resp_bits_doubleline = s2_doubleline;
  assign io_fetch_resp_bits_vaddr_0    = s2_req_vaddr_0;
  assign io_fetch_resp_bits_vaddr_1    = s2_req_vaddr_1;
  assign io_fetch_resp_bits_data =
    {s2_datas_7, s2_datas_6, s2_datas_5, s2_datas_4,
     s2_datas_3, s2_datas_2, s2_datas_1, s2_datas_0};
  assign io_fetch_resp_bits_paddr_0 = s2_req_paddr_0;
  // exception = itlb/pmp 优先，否则 l2 corrupt → af
  assign io_fetch_resp_bits_exception_0 = (|s2_exception_0) ? s2_exception_0 : {2{s2_l2_corrupt_0}};
  assign io_fetch_resp_bits_exception_1 =
    s2_doubleline ? ((|s2_exception_1) ? s2_exception_1 : {2{s2_l2_corrupt_1}}) : 2'h0;
  assign io_fetch_resp_bits_pmp_mmio_0 = s2_pmp_mmio_0;
  assign io_fetch_resp_bits_pmp_mmio_1 = s2_doubleline & s2_pmp_mmio_1;
  assign io_fetch_resp_bits_itlb_pbmt_0 = s2_itlb_pbmt_0;
  assign io_fetch_resp_bits_itlb_pbmt_1 = s2_doubleline ? s2_itlb_pbmt_1 : 2'h0;
  assign io_fetch_resp_bits_backendException = s2_backendException;
  assign io_fetch_resp_bits_gpaddr = s2_req_gpaddr;
  assign io_fetch_resp_bits_isForVSnonLeafPTE = s2_req_isForVSnonLeafPTE;
  assign io_fetch_topdownIcacheMiss = io_fetch_topdownIcacheMiss_0;
  assign io_fetch_topdownItlbMiss   = io_fetch_req_valid & ~s0_fire;

  // ===========================================================================
  // PMP 请求地址（s1 paddr）
  // ===========================================================================
  assign io_pmp_0_req_bits_addr = {s1_req_ptags_0, s1_req_vaddr_0[11:0]};
  assign io_pmp_1_req_bits_addr = {s1_req_ptags_1, s1_req_vaddr_1[11:0]};

  // ===========================================================================
  // BEU error 上报：REG_4/5 为 l2 corrupt 的二级延迟（优先），否则 meta/data corrupt
  // ===========================================================================
  assign io_errors_0_valid = REG_4 | (s2_corrupt_refetch_0 & io_errors_0_valid_REG);
  assign io_errors_0_bits_paddr = REG_4 ? io_errors_0_bits_paddr_REG : s2_req_paddr_0;
  assign io_errors_0_bits_report_to_beu = ~REG_4 & s2_corrupt_refetch_0 & io_errors_0_bits_report_to_beu_REG;
  assign io_errors_1_valid = REG_5 | (s2_corrupt_refetch_1 & io_errors_1_valid_REG);
  assign io_errors_1_bits_paddr = REG_5 ? io_errors_1_bits_paddr_REG : s2_req_paddr_1;
  assign io_errors_1_bits_report_to_beu = ~REG_5 & s2_corrupt_refetch_1 & io_errors_1_bits_report_to_beu_REG;

  // ===========================================================================
  // 性能信息
  // ===========================================================================
  assign io_perfInfo_only_0_hit      = s2_hits_0 & ~s2_doubleline;
  assign io_perfInfo_only_0_miss     = ~s2_hits_0 & ~s2_doubleline;
  assign io_perfInfo_hit_0_hit_1     = s2_hits_0 & s2_hits_1 & s2_doubleline;
  assign io_perfInfo_hit_0_miss_1    = s2_hits_0 & ~s2_hits_1 & s2_doubleline;
  assign io_perfInfo_miss_0_hit_1    = ~s2_hits_0 & s2_hits_1 & s2_doubleline;
  assign io_perfInfo_miss_0_miss_1   = ~s2_hits_0 & ~s2_hits_1 & s2_doubleline;
  assign io_perfInfo_hit_0_except_1  = s2_hits_0 & (|s2_exception_1) & s2_doubleline;
  assign io_perfInfo_miss_0_except_1 = ~s2_hits_0 & (|s2_exception_1) & s2_doubleline;
  assign io_perfInfo_except_0        = |s2_exception_0;
  assign io_perfInfo_bank_hit_0      = s2_hits_0;
  assign io_perfInfo_bank_hit_1      = s2_hits_1 & s2_doubleline;
  assign io_perfInfo_hit             = s2_hits_0 & (~s2_doubleline | s2_hits_1);

  // 保留与 golden 同名的中间信号（_GEN* 在 golden 中曾被断言/裁剪用，这里只为可读性留注释）
  wire _unused = |{_GEN, _GEN_0, _GEN_1, _GEN_2, _GEN_3, _GEN_4, _GEN_5};

endmodule
