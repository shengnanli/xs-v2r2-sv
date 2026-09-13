// =============================================================================
//  OpenLLC.sv —— 外挂 L3 缓存（CHI home node）的顶层装配
// -----------------------------------------------------------------------------
//  位置：XSTop 之下、内存之上。OpenLLC 是香山外挂的独立 L3 IP：北侧(RN)经 CHI 接
//  core 集群，南侧(SN)经 NoSnp 端口接内存。本文件只写"装配"这一层。
//
//  核心机制：11 个子模块实例的互联布线 + 唯一一条时序 glue
//    io.l3Miss := RegNext(OR(4 个 slice 的 l3Miss))。
//  拓扑：
//    io.rn ─ rnLinkMonitor ─ mmioDiverger ─(cacheable)─ rnXbar ─ slices×4
//                                        └(uncacheable/MMIO)──┐
//    slices ─ snXbar ─(cacheable)─ mmioMerger ←───────────────┘ ─ snLinkMonitor ─ io.sn
//    topDown 读 slices.msStatus → io.debugTopDown.addrMatch
//
//  子模块（8 种类型 / 11 实例，本层全部当黑盒，UT/FM 两侧共用同一份 golden 定义）：
//    Slice_4×4（LLC slice：流水/目录/数据/MSHR/snoop filter）、RNXbar、SNXbar、
//    MMIODiverger、MMIOMerger、RNLinkMonitor、SNLinkMonitor、TopDownMonitor_1。
//
//  G0→G1：golden OpenLLC.sv 在 422 个 commit 里逐字节未动，本文件是上一轮可读核的
//  原样继承，只按单文件规范把 package / 核 / golden 同名层并进一个文件
//  （上一轮的 ports/decls/glue/inst/outassign 五个 .svh 片段已就地展开）。
//  注意：子模块的**内容**在 G1 变了（RNXbar/SNXbar 的孙子重编号等），但那是各自
//  目标的事；本层只依赖它们的端口，端口未变。
//
//  本文件导航
//    L37 §1 package openllc_pkg —— L3 边界结构常量（文档用）
//    L57 §2 可读核 xs_OpenLLC_core（端口表随后）
//    L129 §3 子模块输出 / 互联网声明
//    L1324 §4 l3Miss 汇聚寄存（本层唯一时序逻辑）
//    L1347 §5 11 子模块例化开始（mmioDiverger / mmioMerger）
//    L1875 §6 CHI 交叉开关例化（rnXbar / snXbar）
//    L2893 §7 LLC slice ×4 例化（slices_0..3）+ rnLinkMonitor
//    L3811 §8 顶层输出直通 assign
//    L3822 §9 golden 同名层 OpenLLC
// =============================================================================

// ---- §1 package openllc_pkg —— L3 边界结构常量（文档用） --------------------
package openllc_pkg;

  // ---- L3 装配结构常量(来自 LLCParam,仅作文档/可读性,核内不直接参数化展开)----
  localparam int NUM_RN  = 1;   // Request Node 数(接 core 集群);此配置 numRNs=1。
  localparam int BANKS   = 4;   // LLC bank 数 = slice 实例数。
  localparam int NUM_SN  = 1;   // Subordinate Node 数(接内存)。

  // ---- CHI 五通道 flit 位宽(来自 golden OpenLLC 端口,作可读性参考)----
  //   REQ=162b  RSP=73b  DAT=422b  SNP=115b(rx.snp,LLC->RN)
  localparam int CHI_REQ_W = 162;
  localparam int CHI_RSP_W = 73;
  localparam int CHI_DAT_W = 422;
  localparam int CHI_SNP_W = 115;

endpackage

// =============================================================================
//  可读核：端口表 / 互联网声明 / l3Miss glue / 11 子模块例化 / 输出直通
// =============================================================================
// ---- §2 可读核 xs_OpenLLC_core（端口表随后） --------------------
module xs_OpenLLC_core
  import openllc_pkg::*;
(
  input clock,
  input reset,
// 可读核端口表(与 golden OpenLLC 同名扁平端口,供 FM/ST 对接)。
// clock/reset 在核声明处单列,这里只列功能端口。
//   io_rn_0_*       北侧 CHI RN 端口(接 core 集群,tx=core->LLC, rx=LLC->core)
//   io_sn_*         南侧 CHI SN 端口(NoSnp,接内存)
//   io_debugTopDown_* 调试/性能监视接口
//   io_l3Miss       L3 整体 miss 指示(各 slice miss 汇聚一拍)
  input io_rn_0_txsactive,
  output io_rn_0_rxsactive,
  input io_rn_0_syscoreq,
  output io_rn_0_syscoack,
  input io_rn_0_tx_linkactivereq,
  output io_rn_0_tx_linkactiveack,
  input io_rn_0_tx_req_flitpend,
  input io_rn_0_tx_req_flitv,
  input [161:0] io_rn_0_tx_req_flit,
  output io_rn_0_tx_req_lcrdv,
  input io_rn_0_tx_rsp_flitpend,
  input io_rn_0_tx_rsp_flitv,
  input [72:0] io_rn_0_tx_rsp_flit,
  output io_rn_0_tx_rsp_lcrdv,
  input io_rn_0_tx_dat_flitpend,
  input io_rn_0_tx_dat_flitv,
  input [421:0] io_rn_0_tx_dat_flit,
  output io_rn_0_tx_dat_lcrdv,
  output io_rn_0_rx_linkactivereq,
  input io_rn_0_rx_linkactiveack,
  output io_rn_0_rx_rsp_flitpend,
  output io_rn_0_rx_rsp_flitv,
  output [72:0] io_rn_0_rx_rsp_flit,
  input io_rn_0_rx_rsp_lcrdv,
  output io_rn_0_rx_dat_flitpend,
  output io_rn_0_rx_dat_flitv,
  output [421:0] io_rn_0_rx_dat_flit,
  input io_rn_0_rx_dat_lcrdv,
  output io_rn_0_rx_snp_flitpend,
  output io_rn_0_rx_snp_flitv,
  output [114:0] io_rn_0_rx_snp_flit,
  input io_rn_0_rx_snp_lcrdv,
  output io_sn_txsactive,
  input io_sn_rxsactive,
  output io_sn_tx_linkactivereq,
  input io_sn_tx_linkactiveack,
  output io_sn_tx_req_flitpend,
  output io_sn_tx_req_flitv,
  output [161:0] io_sn_tx_req_flit,
  input io_sn_tx_req_lcrdv,
  output io_sn_tx_dat_flitpend,
  output io_sn_tx_dat_flitv,
  output [421:0] io_sn_tx_dat_flit,
  input io_sn_tx_dat_lcrdv,
  input io_sn_rx_linkactivereq,
  output io_sn_rx_linkactiveack,
  input io_sn_rx_rsp_flitpend,
  input io_sn_rx_rsp_flitv,
  input [72:0] io_sn_rx_rsp_flit,
  output io_sn_rx_rsp_lcrdv,
  input io_sn_rx_dat_flitpend,
  input io_sn_rx_dat_flitv,
  input [421:0] io_sn_rx_dat_flit,
  output io_sn_rx_dat_lcrdv,
  input io_debugTopDown_robHeadPaddr_0_valid,
  input [47:0] io_debugTopDown_robHeadPaddr_0_bits,
  output io_debugTopDown_addrMatch_0,
  output io_l3Miss
);

// ---- §3 子模块输出 / 互联网声明 --------------------
  // ===================================================================
  // 子模块黑盒输出/互联网声明(供 glue/inst/outassign 消费)。
  //   _<inst>_io_*  : 子模块输出引脚网(slice/xbar/linkmon/mmio 之间的 CHI 互联);
  //   _probe        : difftest/dontTouch 探针(topDown 的 addrMatch 镜像)。
  // ===================================================================
// 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。
//   _<inst>_io_*  : 子模块输出引脚网(slice/xbar/linkmon/mmio 之间的 CHI 互联);
//   _probe        : difftest/dontTouch 探针(_topDown 的 addrMatch 镜像)。
// 由 openllc_inst.svh 绑定子模块输出引脚,互联直连 / outassign 消费。

  logic _rnLinkMonitor_io_in_tx_req_valid;
  logic [3:0] _rnLinkMonitor_io_in_tx_req_bits_qos;
  logic [10:0] _rnLinkMonitor_io_in_tx_req_bits_tgtID;
  logic [10:0] _rnLinkMonitor_io_in_tx_req_bits_srcID;
  logic [11:0] _rnLinkMonitor_io_in_tx_req_bits_txnID;
  logic [10:0] _rnLinkMonitor_io_in_tx_req_bits_returnNID;
  logic _rnLinkMonitor_io_in_tx_req_bits_stashNIDValid;
  logic [11:0] _rnLinkMonitor_io_in_tx_req_bits_returnTxnID;
  logic [6:0] _rnLinkMonitor_io_in_tx_req_bits_opcode;
  logic [2:0] _rnLinkMonitor_io_in_tx_req_bits_size;
  logic [47:0] _rnLinkMonitor_io_in_tx_req_bits_addr;
  logic _rnLinkMonitor_io_in_tx_req_bits_ns;
  logic _rnLinkMonitor_io_in_tx_req_bits_likelyshared;
  logic _rnLinkMonitor_io_in_tx_req_bits_allowRetry;
  logic [1:0] _rnLinkMonitor_io_in_tx_req_bits_order;
  logic [3:0] _rnLinkMonitor_io_in_tx_req_bits_pCrdType;
  logic _rnLinkMonitor_io_in_tx_req_bits_memAttr_allocate;
  logic _rnLinkMonitor_io_in_tx_req_bits_memAttr_cacheable;
  logic _rnLinkMonitor_io_in_tx_req_bits_memAttr_device;
  logic _rnLinkMonitor_io_in_tx_req_bits_memAttr_ewa;
  logic _rnLinkMonitor_io_in_tx_req_bits_snpAttr;
  logic [7:0] _rnLinkMonitor_io_in_tx_req_bits_lpIDWithPadding;
  logic _rnLinkMonitor_io_in_tx_req_bits_snoopMe;
  logic _rnLinkMonitor_io_in_tx_req_bits_expCompAck;
  logic [1:0] _rnLinkMonitor_io_in_tx_req_bits_tagOp;
  logic _rnLinkMonitor_io_in_tx_req_bits_traceTag;
  logic _rnLinkMonitor_io_in_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] _rnLinkMonitor_io_in_tx_req_bits_mpam_partID;
  logic _rnLinkMonitor_io_in_tx_req_bits_mpam_mpamNS;
  logic [3:0] _rnLinkMonitor_io_in_tx_req_bits_rsvdc;
  logic _rnLinkMonitor_io_in_tx_rsp_valid;
  logic [10:0] _rnLinkMonitor_io_in_tx_rsp_bits_srcID;
  logic [11:0] _rnLinkMonitor_io_in_tx_rsp_bits_txnID;
  logic [4:0] _rnLinkMonitor_io_in_tx_rsp_bits_opcode;
  logic [11:0] _rnLinkMonitor_io_in_tx_rsp_bits_dbID;
  logic _rnLinkMonitor_io_in_tx_dat_valid;
  logic [3:0] _rnLinkMonitor_io_in_tx_dat_bits_qos;
  logic [10:0] _rnLinkMonitor_io_in_tx_dat_bits_tgtID;
  logic [10:0] _rnLinkMonitor_io_in_tx_dat_bits_srcID;
  logic [11:0] _rnLinkMonitor_io_in_tx_dat_bits_txnID;
  logic [10:0] _rnLinkMonitor_io_in_tx_dat_bits_homeNID;
  logic [3:0] _rnLinkMonitor_io_in_tx_dat_bits_opcode;
  logic [1:0] _rnLinkMonitor_io_in_tx_dat_bits_respErr;
  logic [2:0] _rnLinkMonitor_io_in_tx_dat_bits_resp;
  logic [3:0] _rnLinkMonitor_io_in_tx_dat_bits_dataSource;
  logic [2:0] _rnLinkMonitor_io_in_tx_dat_bits_cBusy;
  logic [11:0] _rnLinkMonitor_io_in_tx_dat_bits_dbID;
  logic [1:0] _rnLinkMonitor_io_in_tx_dat_bits_ccID;
  logic [1:0] _rnLinkMonitor_io_in_tx_dat_bits_dataID;
  logic [1:0] _rnLinkMonitor_io_in_tx_dat_bits_tagOp;
  logic [7:0] _rnLinkMonitor_io_in_tx_dat_bits_tag;
  logic [1:0] _rnLinkMonitor_io_in_tx_dat_bits_tu;
  logic _rnLinkMonitor_io_in_tx_dat_bits_traceTag;
  logic [3:0] _rnLinkMonitor_io_in_tx_dat_bits_rsvdc;
  logic [31:0] _rnLinkMonitor_io_in_tx_dat_bits_be;
  logic [255:0] _rnLinkMonitor_io_in_tx_dat_bits_data;
  logic [31:0] _rnLinkMonitor_io_in_tx_dat_bits_dataCheck;
  logic [3:0] _rnLinkMonitor_io_in_tx_dat_bits_poison;
  logic _rnLinkMonitor_io_in_rx_rsp_ready;
  logic _rnLinkMonitor_io_in_rx_dat_ready;
  logic _rnLinkMonitor_io_in_rx_snp_ready;
  logic _slices_3_io_in_tx_req_ready;
  logic _slices_3_io_in_rx_rsp_valid;
  logic [10:0] _slices_3_io_in_rx_rsp_bits_tgtID;
  logic [10:0] _slices_3_io_in_rx_rsp_bits_srcID;
  logic [11:0] _slices_3_io_in_rx_rsp_bits_txnID;
  logic [4:0] _slices_3_io_in_rx_rsp_bits_opcode;
  logic [2:0] _slices_3_io_in_rx_rsp_bits_resp;
  logic [2:0] _slices_3_io_in_rx_rsp_bits_fwdState;
  logic [11:0] _slices_3_io_in_rx_rsp_bits_dbID;
  logic [3:0] _slices_3_io_in_rx_rsp_bits_pCrdType;
  logic _slices_3_io_in_rx_dat_valid;
  logic [10:0] _slices_3_io_in_rx_dat_bits_tgtID;
  logic [10:0] _slices_3_io_in_rx_dat_bits_srcID;
  logic [11:0] _slices_3_io_in_rx_dat_bits_txnID;
  logic [10:0] _slices_3_io_in_rx_dat_bits_homeNID;
  logic [3:0] _slices_3_io_in_rx_dat_bits_opcode;
  logic [2:0] _slices_3_io_in_rx_dat_bits_resp;
  logic [3:0] _slices_3_io_in_rx_dat_bits_dataSource;
  logic [11:0] _slices_3_io_in_rx_dat_bits_dbID;
  logic [1:0] _slices_3_io_in_rx_dat_bits_dataID;
  logic [31:0] _slices_3_io_in_rx_dat_bits_be;
  logic [255:0] _slices_3_io_in_rx_dat_bits_data;
  logic [31:0] _slices_3_io_in_rx_dat_bits_dataCheck;
  logic _slices_3_io_in_rx_snp_valid;
  logic [11:0] _slices_3_io_in_rx_snp_bits_txnID;
  logic [10:0] _slices_3_io_in_rx_snp_bits_fwdNID;
  logic [11:0] _slices_3_io_in_rx_snp_bits_fwdTxnID;
  logic [4:0] _slices_3_io_in_rx_snp_bits_opcode;
  logic [44:0] _slices_3_io_in_rx_snp_bits_addr;
  logic _slices_3_io_in_rx_snp_bits_doNotGoToSD;
  logic _slices_3_io_in_rx_snp_bits_retToSrc;
  logic _slices_3_io_out_tx_req_valid;
  logic [10:0] _slices_3_io_out_tx_req_bits_tgtID;
  logic [10:0] _slices_3_io_out_tx_req_bits_srcID;
  logic [11:0] _slices_3_io_out_tx_req_bits_txnID;
  logic [6:0] _slices_3_io_out_tx_req_bits_opcode;
  logic [2:0] _slices_3_io_out_tx_req_bits_size;
  logic [47:0] _slices_3_io_out_tx_req_bits_addr;
  logic _slices_3_io_out_tx_req_bits_allowRetry;
  logic [1:0] _slices_3_io_out_tx_req_bits_order;
  logic [3:0] _slices_3_io_out_tx_req_bits_pCrdType;
  logic _slices_3_io_out_tx_req_bits_memAttr_allocate;
  logic _slices_3_io_out_tx_req_bits_memAttr_cacheable;
  logic _slices_3_io_out_tx_req_bits_memAttr_device;
  logic _slices_3_io_out_tx_req_bits_memAttr_ewa;
  logic _slices_3_io_out_tx_req_bits_snpAttr;
  logic _slices_3_io_out_tx_req_bits_expCompAck;
  logic _slices_3_io_out_tx_dat_valid;
  logic [10:0] _slices_3_io_out_tx_dat_bits_tgtID;
  logic [10:0] _slices_3_io_out_tx_dat_bits_srcID;
  logic [11:0] _slices_3_io_out_tx_dat_bits_txnID;
  logic [10:0] _slices_3_io_out_tx_dat_bits_homeNID;
  logic [3:0] _slices_3_io_out_tx_dat_bits_opcode;
  logic [2:0] _slices_3_io_out_tx_dat_bits_resp;
  logic [3:0] _slices_3_io_out_tx_dat_bits_dataSource;
  logic [11:0] _slices_3_io_out_tx_dat_bits_dbID;
  logic [1:0] _slices_3_io_out_tx_dat_bits_dataID;
  logic [31:0] _slices_3_io_out_tx_dat_bits_be;
  logic [255:0] _slices_3_io_out_tx_dat_bits_data;
  logic [31:0] _slices_3_io_out_tx_dat_bits_dataCheck;
  logic _slices_3_io_snpMask_0;
  logic _slices_3_io_msStatus_0_valid;
  logic [11:0] _slices_3_io_msStatus_0_bits_set;
  logic [27:0] _slices_3_io_msStatus_0_bits_tag;
  logic [6:0] _slices_3_io_msStatus_0_bits_opcode;
  logic _slices_3_io_msStatus_0_bits_is_miss;
  logic _slices_3_io_msStatus_1_valid;
  logic [11:0] _slices_3_io_msStatus_1_bits_set;
  logic [27:0] _slices_3_io_msStatus_1_bits_tag;
  logic [6:0] _slices_3_io_msStatus_1_bits_opcode;
  logic _slices_3_io_msStatus_1_bits_is_miss;
  logic _slices_3_io_msStatus_2_valid;
  logic [11:0] _slices_3_io_msStatus_2_bits_set;
  logic [27:0] _slices_3_io_msStatus_2_bits_tag;
  logic [6:0] _slices_3_io_msStatus_2_bits_opcode;
  logic _slices_3_io_msStatus_2_bits_is_miss;
  logic _slices_3_io_msStatus_3_valid;
  logic [11:0] _slices_3_io_msStatus_3_bits_set;
  logic [27:0] _slices_3_io_msStatus_3_bits_tag;
  logic [6:0] _slices_3_io_msStatus_3_bits_opcode;
  logic _slices_3_io_msStatus_3_bits_is_miss;
  logic _slices_3_io_msStatus_4_valid;
  logic [11:0] _slices_3_io_msStatus_4_bits_set;
  logic [27:0] _slices_3_io_msStatus_4_bits_tag;
  logic [6:0] _slices_3_io_msStatus_4_bits_opcode;
  logic _slices_3_io_msStatus_4_bits_is_miss;
  logic _slices_3_io_msStatus_5_valid;
  logic [11:0] _slices_3_io_msStatus_5_bits_set;
  logic [27:0] _slices_3_io_msStatus_5_bits_tag;
  logic [6:0] _slices_3_io_msStatus_5_bits_opcode;
  logic _slices_3_io_msStatus_5_bits_is_miss;
  logic _slices_3_io_msStatus_6_valid;
  logic [11:0] _slices_3_io_msStatus_6_bits_set;
  logic [27:0] _slices_3_io_msStatus_6_bits_tag;
  logic [6:0] _slices_3_io_msStatus_6_bits_opcode;
  logic _slices_3_io_msStatus_6_bits_is_miss;
  logic _slices_3_io_msStatus_7_valid;
  logic [11:0] _slices_3_io_msStatus_7_bits_set;
  logic [27:0] _slices_3_io_msStatus_7_bits_tag;
  logic [6:0] _slices_3_io_msStatus_7_bits_opcode;
  logic _slices_3_io_msStatus_7_bits_is_miss;
  logic _slices_3_io_msStatus_8_valid;
  logic [11:0] _slices_3_io_msStatus_8_bits_set;
  logic [27:0] _slices_3_io_msStatus_8_bits_tag;
  logic [6:0] _slices_3_io_msStatus_8_bits_opcode;
  logic _slices_3_io_msStatus_8_bits_is_miss;
  logic _slices_3_io_msStatus_9_valid;
  logic [11:0] _slices_3_io_msStatus_9_bits_set;
  logic [27:0] _slices_3_io_msStatus_9_bits_tag;
  logic [6:0] _slices_3_io_msStatus_9_bits_opcode;
  logic _slices_3_io_msStatus_9_bits_is_miss;
  logic _slices_3_io_msStatus_10_valid;
  logic [11:0] _slices_3_io_msStatus_10_bits_set;
  logic [27:0] _slices_3_io_msStatus_10_bits_tag;
  logic [6:0] _slices_3_io_msStatus_10_bits_opcode;
  logic _slices_3_io_msStatus_10_bits_is_miss;
  logic _slices_3_io_msStatus_11_valid;
  logic [11:0] _slices_3_io_msStatus_11_bits_set;
  logic [27:0] _slices_3_io_msStatus_11_bits_tag;
  logic [6:0] _slices_3_io_msStatus_11_bits_opcode;
  logic _slices_3_io_msStatus_11_bits_is_miss;
  logic _slices_3_io_msStatus_12_valid;
  logic [11:0] _slices_3_io_msStatus_12_bits_set;
  logic [27:0] _slices_3_io_msStatus_12_bits_tag;
  logic [6:0] _slices_3_io_msStatus_12_bits_opcode;
  logic _slices_3_io_msStatus_12_bits_is_miss;
  logic _slices_3_io_msStatus_13_valid;
  logic [11:0] _slices_3_io_msStatus_13_bits_set;
  logic [27:0] _slices_3_io_msStatus_13_bits_tag;
  logic [6:0] _slices_3_io_msStatus_13_bits_opcode;
  logic _slices_3_io_msStatus_13_bits_is_miss;
  logic _slices_3_io_msStatus_14_valid;
  logic [11:0] _slices_3_io_msStatus_14_bits_set;
  logic [27:0] _slices_3_io_msStatus_14_bits_tag;
  logic [6:0] _slices_3_io_msStatus_14_bits_opcode;
  logic _slices_3_io_msStatus_14_bits_is_miss;
  logic _slices_3_io_msStatus_15_valid;
  logic [11:0] _slices_3_io_msStatus_15_bits_set;
  logic [27:0] _slices_3_io_msStatus_15_bits_tag;
  logic [6:0] _slices_3_io_msStatus_15_bits_opcode;
  logic _slices_3_io_msStatus_15_bits_is_miss;
  logic _slices_3_io_l3Miss;
  logic _slices_2_io_in_tx_req_ready;
  logic _slices_2_io_in_rx_rsp_valid;
  logic [10:0] _slices_2_io_in_rx_rsp_bits_tgtID;
  logic [10:0] _slices_2_io_in_rx_rsp_bits_srcID;
  logic [11:0] _slices_2_io_in_rx_rsp_bits_txnID;
  logic [4:0] _slices_2_io_in_rx_rsp_bits_opcode;
  logic [2:0] _slices_2_io_in_rx_rsp_bits_resp;
  logic [2:0] _slices_2_io_in_rx_rsp_bits_fwdState;
  logic [11:0] _slices_2_io_in_rx_rsp_bits_dbID;
  logic [3:0] _slices_2_io_in_rx_rsp_bits_pCrdType;
  logic _slices_2_io_in_rx_dat_valid;
  logic [10:0] _slices_2_io_in_rx_dat_bits_tgtID;
  logic [10:0] _slices_2_io_in_rx_dat_bits_srcID;
  logic [11:0] _slices_2_io_in_rx_dat_bits_txnID;
  logic [10:0] _slices_2_io_in_rx_dat_bits_homeNID;
  logic [3:0] _slices_2_io_in_rx_dat_bits_opcode;
  logic [2:0] _slices_2_io_in_rx_dat_bits_resp;
  logic [3:0] _slices_2_io_in_rx_dat_bits_dataSource;
  logic [11:0] _slices_2_io_in_rx_dat_bits_dbID;
  logic [1:0] _slices_2_io_in_rx_dat_bits_dataID;
  logic [31:0] _slices_2_io_in_rx_dat_bits_be;
  logic [255:0] _slices_2_io_in_rx_dat_bits_data;
  logic [31:0] _slices_2_io_in_rx_dat_bits_dataCheck;
  logic _slices_2_io_in_rx_snp_valid;
  logic [11:0] _slices_2_io_in_rx_snp_bits_txnID;
  logic [10:0] _slices_2_io_in_rx_snp_bits_fwdNID;
  logic [11:0] _slices_2_io_in_rx_snp_bits_fwdTxnID;
  logic [4:0] _slices_2_io_in_rx_snp_bits_opcode;
  logic [44:0] _slices_2_io_in_rx_snp_bits_addr;
  logic _slices_2_io_in_rx_snp_bits_doNotGoToSD;
  logic _slices_2_io_in_rx_snp_bits_retToSrc;
  logic _slices_2_io_out_tx_req_valid;
  logic [10:0] _slices_2_io_out_tx_req_bits_tgtID;
  logic [10:0] _slices_2_io_out_tx_req_bits_srcID;
  logic [11:0] _slices_2_io_out_tx_req_bits_txnID;
  logic [6:0] _slices_2_io_out_tx_req_bits_opcode;
  logic [2:0] _slices_2_io_out_tx_req_bits_size;
  logic [47:0] _slices_2_io_out_tx_req_bits_addr;
  logic _slices_2_io_out_tx_req_bits_allowRetry;
  logic [1:0] _slices_2_io_out_tx_req_bits_order;
  logic [3:0] _slices_2_io_out_tx_req_bits_pCrdType;
  logic _slices_2_io_out_tx_req_bits_memAttr_allocate;
  logic _slices_2_io_out_tx_req_bits_memAttr_cacheable;
  logic _slices_2_io_out_tx_req_bits_memAttr_device;
  logic _slices_2_io_out_tx_req_bits_memAttr_ewa;
  logic _slices_2_io_out_tx_req_bits_snpAttr;
  logic _slices_2_io_out_tx_req_bits_expCompAck;
  logic _slices_2_io_out_tx_dat_valid;
  logic [10:0] _slices_2_io_out_tx_dat_bits_tgtID;
  logic [10:0] _slices_2_io_out_tx_dat_bits_srcID;
  logic [11:0] _slices_2_io_out_tx_dat_bits_txnID;
  logic [10:0] _slices_2_io_out_tx_dat_bits_homeNID;
  logic [3:0] _slices_2_io_out_tx_dat_bits_opcode;
  logic [2:0] _slices_2_io_out_tx_dat_bits_resp;
  logic [3:0] _slices_2_io_out_tx_dat_bits_dataSource;
  logic [11:0] _slices_2_io_out_tx_dat_bits_dbID;
  logic [1:0] _slices_2_io_out_tx_dat_bits_dataID;
  logic [31:0] _slices_2_io_out_tx_dat_bits_be;
  logic [255:0] _slices_2_io_out_tx_dat_bits_data;
  logic [31:0] _slices_2_io_out_tx_dat_bits_dataCheck;
  logic _slices_2_io_snpMask_0;
  logic _slices_2_io_msStatus_0_valid;
  logic [11:0] _slices_2_io_msStatus_0_bits_set;
  logic [27:0] _slices_2_io_msStatus_0_bits_tag;
  logic [6:0] _slices_2_io_msStatus_0_bits_opcode;
  logic _slices_2_io_msStatus_0_bits_is_miss;
  logic _slices_2_io_msStatus_1_valid;
  logic [11:0] _slices_2_io_msStatus_1_bits_set;
  logic [27:0] _slices_2_io_msStatus_1_bits_tag;
  logic [6:0] _slices_2_io_msStatus_1_bits_opcode;
  logic _slices_2_io_msStatus_1_bits_is_miss;
  logic _slices_2_io_msStatus_2_valid;
  logic [11:0] _slices_2_io_msStatus_2_bits_set;
  logic [27:0] _slices_2_io_msStatus_2_bits_tag;
  logic [6:0] _slices_2_io_msStatus_2_bits_opcode;
  logic _slices_2_io_msStatus_2_bits_is_miss;
  logic _slices_2_io_msStatus_3_valid;
  logic [11:0] _slices_2_io_msStatus_3_bits_set;
  logic [27:0] _slices_2_io_msStatus_3_bits_tag;
  logic [6:0] _slices_2_io_msStatus_3_bits_opcode;
  logic _slices_2_io_msStatus_3_bits_is_miss;
  logic _slices_2_io_msStatus_4_valid;
  logic [11:0] _slices_2_io_msStatus_4_bits_set;
  logic [27:0] _slices_2_io_msStatus_4_bits_tag;
  logic [6:0] _slices_2_io_msStatus_4_bits_opcode;
  logic _slices_2_io_msStatus_4_bits_is_miss;
  logic _slices_2_io_msStatus_5_valid;
  logic [11:0] _slices_2_io_msStatus_5_bits_set;
  logic [27:0] _slices_2_io_msStatus_5_bits_tag;
  logic [6:0] _slices_2_io_msStatus_5_bits_opcode;
  logic _slices_2_io_msStatus_5_bits_is_miss;
  logic _slices_2_io_msStatus_6_valid;
  logic [11:0] _slices_2_io_msStatus_6_bits_set;
  logic [27:0] _slices_2_io_msStatus_6_bits_tag;
  logic [6:0] _slices_2_io_msStatus_6_bits_opcode;
  logic _slices_2_io_msStatus_6_bits_is_miss;
  logic _slices_2_io_msStatus_7_valid;
  logic [11:0] _slices_2_io_msStatus_7_bits_set;
  logic [27:0] _slices_2_io_msStatus_7_bits_tag;
  logic [6:0] _slices_2_io_msStatus_7_bits_opcode;
  logic _slices_2_io_msStatus_7_bits_is_miss;
  logic _slices_2_io_msStatus_8_valid;
  logic [11:0] _slices_2_io_msStatus_8_bits_set;
  logic [27:0] _slices_2_io_msStatus_8_bits_tag;
  logic [6:0] _slices_2_io_msStatus_8_bits_opcode;
  logic _slices_2_io_msStatus_8_bits_is_miss;
  logic _slices_2_io_msStatus_9_valid;
  logic [11:0] _slices_2_io_msStatus_9_bits_set;
  logic [27:0] _slices_2_io_msStatus_9_bits_tag;
  logic [6:0] _slices_2_io_msStatus_9_bits_opcode;
  logic _slices_2_io_msStatus_9_bits_is_miss;
  logic _slices_2_io_msStatus_10_valid;
  logic [11:0] _slices_2_io_msStatus_10_bits_set;
  logic [27:0] _slices_2_io_msStatus_10_bits_tag;
  logic [6:0] _slices_2_io_msStatus_10_bits_opcode;
  logic _slices_2_io_msStatus_10_bits_is_miss;
  logic _slices_2_io_msStatus_11_valid;
  logic [11:0] _slices_2_io_msStatus_11_bits_set;
  logic [27:0] _slices_2_io_msStatus_11_bits_tag;
  logic [6:0] _slices_2_io_msStatus_11_bits_opcode;
  logic _slices_2_io_msStatus_11_bits_is_miss;
  logic _slices_2_io_msStatus_12_valid;
  logic [11:0] _slices_2_io_msStatus_12_bits_set;
  logic [27:0] _slices_2_io_msStatus_12_bits_tag;
  logic [6:0] _slices_2_io_msStatus_12_bits_opcode;
  logic _slices_2_io_msStatus_12_bits_is_miss;
  logic _slices_2_io_msStatus_13_valid;
  logic [11:0] _slices_2_io_msStatus_13_bits_set;
  logic [27:0] _slices_2_io_msStatus_13_bits_tag;
  logic [6:0] _slices_2_io_msStatus_13_bits_opcode;
  logic _slices_2_io_msStatus_13_bits_is_miss;
  logic _slices_2_io_msStatus_14_valid;
  logic [11:0] _slices_2_io_msStatus_14_bits_set;
  logic [27:0] _slices_2_io_msStatus_14_bits_tag;
  logic [6:0] _slices_2_io_msStatus_14_bits_opcode;
  logic _slices_2_io_msStatus_14_bits_is_miss;
  logic _slices_2_io_msStatus_15_valid;
  logic [11:0] _slices_2_io_msStatus_15_bits_set;
  logic [27:0] _slices_2_io_msStatus_15_bits_tag;
  logic [6:0] _slices_2_io_msStatus_15_bits_opcode;
  logic _slices_2_io_msStatus_15_bits_is_miss;
  logic _slices_2_io_l3Miss;
  logic _slices_1_io_in_tx_req_ready;
  logic _slices_1_io_in_rx_rsp_valid;
  logic [10:0] _slices_1_io_in_rx_rsp_bits_tgtID;
  logic [10:0] _slices_1_io_in_rx_rsp_bits_srcID;
  logic [11:0] _slices_1_io_in_rx_rsp_bits_txnID;
  logic [4:0] _slices_1_io_in_rx_rsp_bits_opcode;
  logic [2:0] _slices_1_io_in_rx_rsp_bits_resp;
  logic [2:0] _slices_1_io_in_rx_rsp_bits_fwdState;
  logic [11:0] _slices_1_io_in_rx_rsp_bits_dbID;
  logic [3:0] _slices_1_io_in_rx_rsp_bits_pCrdType;
  logic _slices_1_io_in_rx_dat_valid;
  logic [10:0] _slices_1_io_in_rx_dat_bits_tgtID;
  logic [10:0] _slices_1_io_in_rx_dat_bits_srcID;
  logic [11:0] _slices_1_io_in_rx_dat_bits_txnID;
  logic [10:0] _slices_1_io_in_rx_dat_bits_homeNID;
  logic [3:0] _slices_1_io_in_rx_dat_bits_opcode;
  logic [2:0] _slices_1_io_in_rx_dat_bits_resp;
  logic [3:0] _slices_1_io_in_rx_dat_bits_dataSource;
  logic [11:0] _slices_1_io_in_rx_dat_bits_dbID;
  logic [1:0] _slices_1_io_in_rx_dat_bits_dataID;
  logic [31:0] _slices_1_io_in_rx_dat_bits_be;
  logic [255:0] _slices_1_io_in_rx_dat_bits_data;
  logic [31:0] _slices_1_io_in_rx_dat_bits_dataCheck;
  logic _slices_1_io_in_rx_snp_valid;
  logic [11:0] _slices_1_io_in_rx_snp_bits_txnID;
  logic [10:0] _slices_1_io_in_rx_snp_bits_fwdNID;
  logic [11:0] _slices_1_io_in_rx_snp_bits_fwdTxnID;
  logic [4:0] _slices_1_io_in_rx_snp_bits_opcode;
  logic [44:0] _slices_1_io_in_rx_snp_bits_addr;
  logic _slices_1_io_in_rx_snp_bits_doNotGoToSD;
  logic _slices_1_io_in_rx_snp_bits_retToSrc;
  logic _slices_1_io_out_tx_req_valid;
  logic [10:0] _slices_1_io_out_tx_req_bits_tgtID;
  logic [10:0] _slices_1_io_out_tx_req_bits_srcID;
  logic [11:0] _slices_1_io_out_tx_req_bits_txnID;
  logic [6:0] _slices_1_io_out_tx_req_bits_opcode;
  logic [2:0] _slices_1_io_out_tx_req_bits_size;
  logic [47:0] _slices_1_io_out_tx_req_bits_addr;
  logic _slices_1_io_out_tx_req_bits_allowRetry;
  logic [1:0] _slices_1_io_out_tx_req_bits_order;
  logic [3:0] _slices_1_io_out_tx_req_bits_pCrdType;
  logic _slices_1_io_out_tx_req_bits_memAttr_allocate;
  logic _slices_1_io_out_tx_req_bits_memAttr_cacheable;
  logic _slices_1_io_out_tx_req_bits_memAttr_device;
  logic _slices_1_io_out_tx_req_bits_memAttr_ewa;
  logic _slices_1_io_out_tx_req_bits_snpAttr;
  logic _slices_1_io_out_tx_req_bits_expCompAck;
  logic _slices_1_io_out_tx_dat_valid;
  logic [10:0] _slices_1_io_out_tx_dat_bits_tgtID;
  logic [10:0] _slices_1_io_out_tx_dat_bits_srcID;
  logic [11:0] _slices_1_io_out_tx_dat_bits_txnID;
  logic [10:0] _slices_1_io_out_tx_dat_bits_homeNID;
  logic [3:0] _slices_1_io_out_tx_dat_bits_opcode;
  logic [2:0] _slices_1_io_out_tx_dat_bits_resp;
  logic [3:0] _slices_1_io_out_tx_dat_bits_dataSource;
  logic [11:0] _slices_1_io_out_tx_dat_bits_dbID;
  logic [1:0] _slices_1_io_out_tx_dat_bits_dataID;
  logic [31:0] _slices_1_io_out_tx_dat_bits_be;
  logic [255:0] _slices_1_io_out_tx_dat_bits_data;
  logic [31:0] _slices_1_io_out_tx_dat_bits_dataCheck;
  logic _slices_1_io_snpMask_0;
  logic _slices_1_io_msStatus_0_valid;
  logic [11:0] _slices_1_io_msStatus_0_bits_set;
  logic [27:0] _slices_1_io_msStatus_0_bits_tag;
  logic [6:0] _slices_1_io_msStatus_0_bits_opcode;
  logic _slices_1_io_msStatus_0_bits_is_miss;
  logic _slices_1_io_msStatus_1_valid;
  logic [11:0] _slices_1_io_msStatus_1_bits_set;
  logic [27:0] _slices_1_io_msStatus_1_bits_tag;
  logic [6:0] _slices_1_io_msStatus_1_bits_opcode;
  logic _slices_1_io_msStatus_1_bits_is_miss;
  logic _slices_1_io_msStatus_2_valid;
  logic [11:0] _slices_1_io_msStatus_2_bits_set;
  logic [27:0] _slices_1_io_msStatus_2_bits_tag;
  logic [6:0] _slices_1_io_msStatus_2_bits_opcode;
  logic _slices_1_io_msStatus_2_bits_is_miss;
  logic _slices_1_io_msStatus_3_valid;
  logic [11:0] _slices_1_io_msStatus_3_bits_set;
  logic [27:0] _slices_1_io_msStatus_3_bits_tag;
  logic [6:0] _slices_1_io_msStatus_3_bits_opcode;
  logic _slices_1_io_msStatus_3_bits_is_miss;
  logic _slices_1_io_msStatus_4_valid;
  logic [11:0] _slices_1_io_msStatus_4_bits_set;
  logic [27:0] _slices_1_io_msStatus_4_bits_tag;
  logic [6:0] _slices_1_io_msStatus_4_bits_opcode;
  logic _slices_1_io_msStatus_4_bits_is_miss;
  logic _slices_1_io_msStatus_5_valid;
  logic [11:0] _slices_1_io_msStatus_5_bits_set;
  logic [27:0] _slices_1_io_msStatus_5_bits_tag;
  logic [6:0] _slices_1_io_msStatus_5_bits_opcode;
  logic _slices_1_io_msStatus_5_bits_is_miss;
  logic _slices_1_io_msStatus_6_valid;
  logic [11:0] _slices_1_io_msStatus_6_bits_set;
  logic [27:0] _slices_1_io_msStatus_6_bits_tag;
  logic [6:0] _slices_1_io_msStatus_6_bits_opcode;
  logic _slices_1_io_msStatus_6_bits_is_miss;
  logic _slices_1_io_msStatus_7_valid;
  logic [11:0] _slices_1_io_msStatus_7_bits_set;
  logic [27:0] _slices_1_io_msStatus_7_bits_tag;
  logic [6:0] _slices_1_io_msStatus_7_bits_opcode;
  logic _slices_1_io_msStatus_7_bits_is_miss;
  logic _slices_1_io_msStatus_8_valid;
  logic [11:0] _slices_1_io_msStatus_8_bits_set;
  logic [27:0] _slices_1_io_msStatus_8_bits_tag;
  logic [6:0] _slices_1_io_msStatus_8_bits_opcode;
  logic _slices_1_io_msStatus_8_bits_is_miss;
  logic _slices_1_io_msStatus_9_valid;
  logic [11:0] _slices_1_io_msStatus_9_bits_set;
  logic [27:0] _slices_1_io_msStatus_9_bits_tag;
  logic [6:0] _slices_1_io_msStatus_9_bits_opcode;
  logic _slices_1_io_msStatus_9_bits_is_miss;
  logic _slices_1_io_msStatus_10_valid;
  logic [11:0] _slices_1_io_msStatus_10_bits_set;
  logic [27:0] _slices_1_io_msStatus_10_bits_tag;
  logic [6:0] _slices_1_io_msStatus_10_bits_opcode;
  logic _slices_1_io_msStatus_10_bits_is_miss;
  logic _slices_1_io_msStatus_11_valid;
  logic [11:0] _slices_1_io_msStatus_11_bits_set;
  logic [27:0] _slices_1_io_msStatus_11_bits_tag;
  logic [6:0] _slices_1_io_msStatus_11_bits_opcode;
  logic _slices_1_io_msStatus_11_bits_is_miss;
  logic _slices_1_io_msStatus_12_valid;
  logic [11:0] _slices_1_io_msStatus_12_bits_set;
  logic [27:0] _slices_1_io_msStatus_12_bits_tag;
  logic [6:0] _slices_1_io_msStatus_12_bits_opcode;
  logic _slices_1_io_msStatus_12_bits_is_miss;
  logic _slices_1_io_msStatus_13_valid;
  logic [11:0] _slices_1_io_msStatus_13_bits_set;
  logic [27:0] _slices_1_io_msStatus_13_bits_tag;
  logic [6:0] _slices_1_io_msStatus_13_bits_opcode;
  logic _slices_1_io_msStatus_13_bits_is_miss;
  logic _slices_1_io_msStatus_14_valid;
  logic [11:0] _slices_1_io_msStatus_14_bits_set;
  logic [27:0] _slices_1_io_msStatus_14_bits_tag;
  logic [6:0] _slices_1_io_msStatus_14_bits_opcode;
  logic _slices_1_io_msStatus_14_bits_is_miss;
  logic _slices_1_io_msStatus_15_valid;
  logic [11:0] _slices_1_io_msStatus_15_bits_set;
  logic [27:0] _slices_1_io_msStatus_15_bits_tag;
  logic [6:0] _slices_1_io_msStatus_15_bits_opcode;
  logic _slices_1_io_msStatus_15_bits_is_miss;
  logic _slices_1_io_l3Miss;
  logic _slices_0_io_in_tx_req_ready;
  logic _slices_0_io_in_rx_rsp_valid;
  logic [10:0] _slices_0_io_in_rx_rsp_bits_tgtID;
  logic [10:0] _slices_0_io_in_rx_rsp_bits_srcID;
  logic [11:0] _slices_0_io_in_rx_rsp_bits_txnID;
  logic [4:0] _slices_0_io_in_rx_rsp_bits_opcode;
  logic [2:0] _slices_0_io_in_rx_rsp_bits_resp;
  logic [2:0] _slices_0_io_in_rx_rsp_bits_fwdState;
  logic [11:0] _slices_0_io_in_rx_rsp_bits_dbID;
  logic [3:0] _slices_0_io_in_rx_rsp_bits_pCrdType;
  logic _slices_0_io_in_rx_dat_valid;
  logic [10:0] _slices_0_io_in_rx_dat_bits_tgtID;
  logic [10:0] _slices_0_io_in_rx_dat_bits_srcID;
  logic [11:0] _slices_0_io_in_rx_dat_bits_txnID;
  logic [10:0] _slices_0_io_in_rx_dat_bits_homeNID;
  logic [3:0] _slices_0_io_in_rx_dat_bits_opcode;
  logic [2:0] _slices_0_io_in_rx_dat_bits_resp;
  logic [3:0] _slices_0_io_in_rx_dat_bits_dataSource;
  logic [11:0] _slices_0_io_in_rx_dat_bits_dbID;
  logic [1:0] _slices_0_io_in_rx_dat_bits_dataID;
  logic [31:0] _slices_0_io_in_rx_dat_bits_be;
  logic [255:0] _slices_0_io_in_rx_dat_bits_data;
  logic [31:0] _slices_0_io_in_rx_dat_bits_dataCheck;
  logic _slices_0_io_in_rx_snp_valid;
  logic [11:0] _slices_0_io_in_rx_snp_bits_txnID;
  logic [10:0] _slices_0_io_in_rx_snp_bits_fwdNID;
  logic [11:0] _slices_0_io_in_rx_snp_bits_fwdTxnID;
  logic [4:0] _slices_0_io_in_rx_snp_bits_opcode;
  logic [44:0] _slices_0_io_in_rx_snp_bits_addr;
  logic _slices_0_io_in_rx_snp_bits_doNotGoToSD;
  logic _slices_0_io_in_rx_snp_bits_retToSrc;
  logic _slices_0_io_out_tx_req_valid;
  logic [10:0] _slices_0_io_out_tx_req_bits_tgtID;
  logic [10:0] _slices_0_io_out_tx_req_bits_srcID;
  logic [11:0] _slices_0_io_out_tx_req_bits_txnID;
  logic [6:0] _slices_0_io_out_tx_req_bits_opcode;
  logic [2:0] _slices_0_io_out_tx_req_bits_size;
  logic [47:0] _slices_0_io_out_tx_req_bits_addr;
  logic _slices_0_io_out_tx_req_bits_allowRetry;
  logic [1:0] _slices_0_io_out_tx_req_bits_order;
  logic [3:0] _slices_0_io_out_tx_req_bits_pCrdType;
  logic _slices_0_io_out_tx_req_bits_memAttr_allocate;
  logic _slices_0_io_out_tx_req_bits_memAttr_cacheable;
  logic _slices_0_io_out_tx_req_bits_memAttr_device;
  logic _slices_0_io_out_tx_req_bits_memAttr_ewa;
  logic _slices_0_io_out_tx_req_bits_snpAttr;
  logic _slices_0_io_out_tx_req_bits_expCompAck;
  logic _slices_0_io_out_tx_dat_valid;
  logic [10:0] _slices_0_io_out_tx_dat_bits_tgtID;
  logic [10:0] _slices_0_io_out_tx_dat_bits_srcID;
  logic [11:0] _slices_0_io_out_tx_dat_bits_txnID;
  logic [10:0] _slices_0_io_out_tx_dat_bits_homeNID;
  logic [3:0] _slices_0_io_out_tx_dat_bits_opcode;
  logic [2:0] _slices_0_io_out_tx_dat_bits_resp;
  logic [3:0] _slices_0_io_out_tx_dat_bits_dataSource;
  logic [11:0] _slices_0_io_out_tx_dat_bits_dbID;
  logic [1:0] _slices_0_io_out_tx_dat_bits_dataID;
  logic [31:0] _slices_0_io_out_tx_dat_bits_be;
  logic [255:0] _slices_0_io_out_tx_dat_bits_data;
  logic [31:0] _slices_0_io_out_tx_dat_bits_dataCheck;
  logic _slices_0_io_snpMask_0;
  logic _slices_0_io_msStatus_0_valid;
  logic [11:0] _slices_0_io_msStatus_0_bits_set;
  logic [27:0] _slices_0_io_msStatus_0_bits_tag;
  logic [6:0] _slices_0_io_msStatus_0_bits_opcode;
  logic _slices_0_io_msStatus_0_bits_is_miss;
  logic _slices_0_io_msStatus_1_valid;
  logic [11:0] _slices_0_io_msStatus_1_bits_set;
  logic [27:0] _slices_0_io_msStatus_1_bits_tag;
  logic [6:0] _slices_0_io_msStatus_1_bits_opcode;
  logic _slices_0_io_msStatus_1_bits_is_miss;
  logic _slices_0_io_msStatus_2_valid;
  logic [11:0] _slices_0_io_msStatus_2_bits_set;
  logic [27:0] _slices_0_io_msStatus_2_bits_tag;
  logic [6:0] _slices_0_io_msStatus_2_bits_opcode;
  logic _slices_0_io_msStatus_2_bits_is_miss;
  logic _slices_0_io_msStatus_3_valid;
  logic [11:0] _slices_0_io_msStatus_3_bits_set;
  logic [27:0] _slices_0_io_msStatus_3_bits_tag;
  logic [6:0] _slices_0_io_msStatus_3_bits_opcode;
  logic _slices_0_io_msStatus_3_bits_is_miss;
  logic _slices_0_io_msStatus_4_valid;
  logic [11:0] _slices_0_io_msStatus_4_bits_set;
  logic [27:0] _slices_0_io_msStatus_4_bits_tag;
  logic [6:0] _slices_0_io_msStatus_4_bits_opcode;
  logic _slices_0_io_msStatus_4_bits_is_miss;
  logic _slices_0_io_msStatus_5_valid;
  logic [11:0] _slices_0_io_msStatus_5_bits_set;
  logic [27:0] _slices_0_io_msStatus_5_bits_tag;
  logic [6:0] _slices_0_io_msStatus_5_bits_opcode;
  logic _slices_0_io_msStatus_5_bits_is_miss;
  logic _slices_0_io_msStatus_6_valid;
  logic [11:0] _slices_0_io_msStatus_6_bits_set;
  logic [27:0] _slices_0_io_msStatus_6_bits_tag;
  logic [6:0] _slices_0_io_msStatus_6_bits_opcode;
  logic _slices_0_io_msStatus_6_bits_is_miss;
  logic _slices_0_io_msStatus_7_valid;
  logic [11:0] _slices_0_io_msStatus_7_bits_set;
  logic [27:0] _slices_0_io_msStatus_7_bits_tag;
  logic [6:0] _slices_0_io_msStatus_7_bits_opcode;
  logic _slices_0_io_msStatus_7_bits_is_miss;
  logic _slices_0_io_msStatus_8_valid;
  logic [11:0] _slices_0_io_msStatus_8_bits_set;
  logic [27:0] _slices_0_io_msStatus_8_bits_tag;
  logic [6:0] _slices_0_io_msStatus_8_bits_opcode;
  logic _slices_0_io_msStatus_8_bits_is_miss;
  logic _slices_0_io_msStatus_9_valid;
  logic [11:0] _slices_0_io_msStatus_9_bits_set;
  logic [27:0] _slices_0_io_msStatus_9_bits_tag;
  logic [6:0] _slices_0_io_msStatus_9_bits_opcode;
  logic _slices_0_io_msStatus_9_bits_is_miss;
  logic _slices_0_io_msStatus_10_valid;
  logic [11:0] _slices_0_io_msStatus_10_bits_set;
  logic [27:0] _slices_0_io_msStatus_10_bits_tag;
  logic [6:0] _slices_0_io_msStatus_10_bits_opcode;
  logic _slices_0_io_msStatus_10_bits_is_miss;
  logic _slices_0_io_msStatus_11_valid;
  logic [11:0] _slices_0_io_msStatus_11_bits_set;
  logic [27:0] _slices_0_io_msStatus_11_bits_tag;
  logic [6:0] _slices_0_io_msStatus_11_bits_opcode;
  logic _slices_0_io_msStatus_11_bits_is_miss;
  logic _slices_0_io_msStatus_12_valid;
  logic [11:0] _slices_0_io_msStatus_12_bits_set;
  logic [27:0] _slices_0_io_msStatus_12_bits_tag;
  logic [6:0] _slices_0_io_msStatus_12_bits_opcode;
  logic _slices_0_io_msStatus_12_bits_is_miss;
  logic _slices_0_io_msStatus_13_valid;
  logic [11:0] _slices_0_io_msStatus_13_bits_set;
  logic [27:0] _slices_0_io_msStatus_13_bits_tag;
  logic [6:0] _slices_0_io_msStatus_13_bits_opcode;
  logic _slices_0_io_msStatus_13_bits_is_miss;
  logic _slices_0_io_msStatus_14_valid;
  logic [11:0] _slices_0_io_msStatus_14_bits_set;
  logic [27:0] _slices_0_io_msStatus_14_bits_tag;
  logic [6:0] _slices_0_io_msStatus_14_bits_opcode;
  logic _slices_0_io_msStatus_14_bits_is_miss;
  logic _slices_0_io_msStatus_15_valid;
  logic [11:0] _slices_0_io_msStatus_15_bits_set;
  logic [27:0] _slices_0_io_msStatus_15_bits_tag;
  logic [6:0] _slices_0_io_msStatus_15_bits_opcode;
  logic _slices_0_io_msStatus_15_bits_is_miss;
  logic _slices_0_io_l3Miss;
  logic _topDown_io_debugTopDown_addrMatch_0;
  logic _snLinkMonitor_io_in_tx_req_ready;
  logic _snLinkMonitor_io_in_tx_dat_ready;
  logic _snLinkMonitor_io_in_rx_rsp_valid;
  logic [3:0] _snLinkMonitor_io_in_rx_rsp_bits_qos;
  logic [10:0] _snLinkMonitor_io_in_rx_rsp_bits_tgtID;
  logic [10:0] _snLinkMonitor_io_in_rx_rsp_bits_srcID;
  logic [11:0] _snLinkMonitor_io_in_rx_rsp_bits_txnID;
  logic [4:0] _snLinkMonitor_io_in_rx_rsp_bits_opcode;
  logic [1:0] _snLinkMonitor_io_in_rx_rsp_bits_respErr;
  logic [2:0] _snLinkMonitor_io_in_rx_rsp_bits_resp;
  logic [2:0] _snLinkMonitor_io_in_rx_rsp_bits_fwdState;
  logic [2:0] _snLinkMonitor_io_in_rx_rsp_bits_cBusy;
  logic [11:0] _snLinkMonitor_io_in_rx_rsp_bits_dbID;
  logic [3:0] _snLinkMonitor_io_in_rx_rsp_bits_pCrdType;
  logic [1:0] _snLinkMonitor_io_in_rx_rsp_bits_tagOp;
  logic _snLinkMonitor_io_in_rx_rsp_bits_traceTag;
  logic _snLinkMonitor_io_in_rx_dat_valid;
  logic [3:0] _snLinkMonitor_io_in_rx_dat_bits_qos;
  logic [10:0] _snLinkMonitor_io_in_rx_dat_bits_tgtID;
  logic [10:0] _snLinkMonitor_io_in_rx_dat_bits_srcID;
  logic [11:0] _snLinkMonitor_io_in_rx_dat_bits_txnID;
  logic [10:0] _snLinkMonitor_io_in_rx_dat_bits_homeNID;
  logic [3:0] _snLinkMonitor_io_in_rx_dat_bits_opcode;
  logic [1:0] _snLinkMonitor_io_in_rx_dat_bits_respErr;
  logic [2:0] _snLinkMonitor_io_in_rx_dat_bits_resp;
  logic [3:0] _snLinkMonitor_io_in_rx_dat_bits_dataSource;
  logic [2:0] _snLinkMonitor_io_in_rx_dat_bits_cBusy;
  logic [11:0] _snLinkMonitor_io_in_rx_dat_bits_dbID;
  logic [1:0] _snLinkMonitor_io_in_rx_dat_bits_ccID;
  logic [1:0] _snLinkMonitor_io_in_rx_dat_bits_dataID;
  logic [1:0] _snLinkMonitor_io_in_rx_dat_bits_tagOp;
  logic [7:0] _snLinkMonitor_io_in_rx_dat_bits_tag;
  logic [1:0] _snLinkMonitor_io_in_rx_dat_bits_tu;
  logic _snLinkMonitor_io_in_rx_dat_bits_traceTag;
  logic [3:0] _snLinkMonitor_io_in_rx_dat_bits_rsvdc;
  logic [31:0] _snLinkMonitor_io_in_rx_dat_bits_be;
  logic [255:0] _snLinkMonitor_io_in_rx_dat_bits_data;
  logic [31:0] _snLinkMonitor_io_in_rx_dat_bits_dataCheck;
  logic [3:0] _snLinkMonitor_io_in_rx_dat_bits_poison;
  logic _snXbar_io_in_0_tx_req_ready;
  logic _snXbar_io_in_0_tx_dat_ready;
  logic _snXbar_io_in_0_rx_rsp_valid;
  logic [10:0] _snXbar_io_in_0_rx_rsp_bits_srcID;
  logic [11:0] _snXbar_io_in_0_rx_rsp_bits_txnID;
  logic [4:0] _snXbar_io_in_0_rx_rsp_bits_opcode;
  logic [11:0] _snXbar_io_in_0_rx_rsp_bits_dbID;
  logic _snXbar_io_in_0_rx_dat_valid;
  logic [10:0] _snXbar_io_in_0_rx_dat_bits_srcID;
  logic [11:0] _snXbar_io_in_0_rx_dat_bits_txnID;
  logic [3:0] _snXbar_io_in_0_rx_dat_bits_opcode;
  logic [2:0] _snXbar_io_in_0_rx_dat_bits_resp;
  logic [1:0] _snXbar_io_in_0_rx_dat_bits_dataID;
  logic [255:0] _snXbar_io_in_0_rx_dat_bits_data;
  logic _snXbar_io_in_1_tx_req_ready;
  logic _snXbar_io_in_1_tx_dat_ready;
  logic _snXbar_io_in_1_rx_rsp_valid;
  logic [10:0] _snXbar_io_in_1_rx_rsp_bits_srcID;
  logic [11:0] _snXbar_io_in_1_rx_rsp_bits_txnID;
  logic [4:0] _snXbar_io_in_1_rx_rsp_bits_opcode;
  logic [11:0] _snXbar_io_in_1_rx_rsp_bits_dbID;
  logic _snXbar_io_in_1_rx_dat_valid;
  logic [10:0] _snXbar_io_in_1_rx_dat_bits_srcID;
  logic [11:0] _snXbar_io_in_1_rx_dat_bits_txnID;
  logic [3:0] _snXbar_io_in_1_rx_dat_bits_opcode;
  logic [2:0] _snXbar_io_in_1_rx_dat_bits_resp;
  logic [1:0] _snXbar_io_in_1_rx_dat_bits_dataID;
  logic [255:0] _snXbar_io_in_1_rx_dat_bits_data;
  logic _snXbar_io_in_2_tx_req_ready;
  logic _snXbar_io_in_2_tx_dat_ready;
  logic _snXbar_io_in_2_rx_rsp_valid;
  logic [10:0] _snXbar_io_in_2_rx_rsp_bits_srcID;
  logic [11:0] _snXbar_io_in_2_rx_rsp_bits_txnID;
  logic [4:0] _snXbar_io_in_2_rx_rsp_bits_opcode;
  logic [11:0] _snXbar_io_in_2_rx_rsp_bits_dbID;
  logic _snXbar_io_in_2_rx_dat_valid;
  logic [10:0] _snXbar_io_in_2_rx_dat_bits_srcID;
  logic [11:0] _snXbar_io_in_2_rx_dat_bits_txnID;
  logic [3:0] _snXbar_io_in_2_rx_dat_bits_opcode;
  logic [2:0] _snXbar_io_in_2_rx_dat_bits_resp;
  logic [1:0] _snXbar_io_in_2_rx_dat_bits_dataID;
  logic [255:0] _snXbar_io_in_2_rx_dat_bits_data;
  logic _snXbar_io_in_3_tx_req_ready;
  logic _snXbar_io_in_3_tx_dat_ready;
  logic _snXbar_io_in_3_rx_rsp_valid;
  logic [10:0] _snXbar_io_in_3_rx_rsp_bits_srcID;
  logic [11:0] _snXbar_io_in_3_rx_rsp_bits_txnID;
  logic [4:0] _snXbar_io_in_3_rx_rsp_bits_opcode;
  logic [11:0] _snXbar_io_in_3_rx_rsp_bits_dbID;
  logic _snXbar_io_in_3_rx_dat_valid;
  logic [10:0] _snXbar_io_in_3_rx_dat_bits_srcID;
  logic [11:0] _snXbar_io_in_3_rx_dat_bits_txnID;
  logic [3:0] _snXbar_io_in_3_rx_dat_bits_opcode;
  logic [2:0] _snXbar_io_in_3_rx_dat_bits_resp;
  logic [1:0] _snXbar_io_in_3_rx_dat_bits_dataID;
  logic [255:0] _snXbar_io_in_3_rx_dat_bits_data;
  logic _snXbar_io_out_tx_req_valid;
  logic [10:0] _snXbar_io_out_tx_req_bits_tgtID;
  logic [10:0] _snXbar_io_out_tx_req_bits_srcID;
  logic [11:0] _snXbar_io_out_tx_req_bits_txnID;
  logic [6:0] _snXbar_io_out_tx_req_bits_opcode;
  logic [2:0] _snXbar_io_out_tx_req_bits_size;
  logic [47:0] _snXbar_io_out_tx_req_bits_addr;
  logic _snXbar_io_out_tx_req_bits_allowRetry;
  logic [1:0] _snXbar_io_out_tx_req_bits_order;
  logic [3:0] _snXbar_io_out_tx_req_bits_pCrdType;
  logic _snXbar_io_out_tx_req_bits_memAttr_allocate;
  logic _snXbar_io_out_tx_req_bits_memAttr_cacheable;
  logic _snXbar_io_out_tx_req_bits_memAttr_device;
  logic _snXbar_io_out_tx_req_bits_memAttr_ewa;
  logic _snXbar_io_out_tx_req_bits_snpAttr;
  logic _snXbar_io_out_tx_req_bits_expCompAck;
  logic _snXbar_io_out_tx_dat_valid;
  logic [10:0] _snXbar_io_out_tx_dat_bits_tgtID;
  logic [10:0] _snXbar_io_out_tx_dat_bits_srcID;
  logic [11:0] _snXbar_io_out_tx_dat_bits_txnID;
  logic [10:0] _snXbar_io_out_tx_dat_bits_homeNID;
  logic [3:0] _snXbar_io_out_tx_dat_bits_opcode;
  logic [2:0] _snXbar_io_out_tx_dat_bits_resp;
  logic [3:0] _snXbar_io_out_tx_dat_bits_dataSource;
  logic [11:0] _snXbar_io_out_tx_dat_bits_dbID;
  logic [1:0] _snXbar_io_out_tx_dat_bits_dataID;
  logic [31:0] _snXbar_io_out_tx_dat_bits_be;
  logic [255:0] _snXbar_io_out_tx_dat_bits_data;
  logic [31:0] _snXbar_io_out_tx_dat_bits_dataCheck;
  logic _snXbar_io_out_rx_rsp_ready;
  logic _snXbar_io_out_rx_dat_ready;
  logic _rnXbar_io_in_0_tx_req_ready;
  logic _rnXbar_io_in_0_tx_rsp_ready;
  logic _rnXbar_io_in_0_tx_dat_ready;
  logic _rnXbar_io_in_0_rx_rsp_valid;
  logic [3:0] _rnXbar_io_in_0_rx_rsp_bits_qos;
  logic [11:0] _rnXbar_io_in_0_rx_rsp_bits_txnID;
  logic [4:0] _rnXbar_io_in_0_rx_rsp_bits_opcode;
  logic [1:0] _rnXbar_io_in_0_rx_rsp_bits_respErr;
  logic [2:0] _rnXbar_io_in_0_rx_rsp_bits_resp;
  logic [2:0] _rnXbar_io_in_0_rx_rsp_bits_fwdState;
  logic [2:0] _rnXbar_io_in_0_rx_rsp_bits_cBusy;
  logic [11:0] _rnXbar_io_in_0_rx_rsp_bits_dbID;
  logic [3:0] _rnXbar_io_in_0_rx_rsp_bits_pCrdType;
  logic [1:0] _rnXbar_io_in_0_rx_rsp_bits_tagOp;
  logic _rnXbar_io_in_0_rx_rsp_bits_traceTag;
  logic _rnXbar_io_in_0_rx_dat_valid;
  logic [11:0] _rnXbar_io_in_0_rx_dat_bits_txnID;
  logic [10:0] _rnXbar_io_in_0_rx_dat_bits_homeNID;
  logic [3:0] _rnXbar_io_in_0_rx_dat_bits_opcode;
  logic [2:0] _rnXbar_io_in_0_rx_dat_bits_resp;
  logic [3:0] _rnXbar_io_in_0_rx_dat_bits_dataSource;
  logic [11:0] _rnXbar_io_in_0_rx_dat_bits_dbID;
  logic [1:0] _rnXbar_io_in_0_rx_dat_bits_dataID;
  logic [31:0] _rnXbar_io_in_0_rx_dat_bits_be;
  logic [255:0] _rnXbar_io_in_0_rx_dat_bits_data;
  logic [31:0] _rnXbar_io_in_0_rx_dat_bits_dataCheck;
  logic _rnXbar_io_in_0_rx_snp_valid;
  logic [11:0] _rnXbar_io_in_0_rx_snp_bits_txnID;
  logic [10:0] _rnXbar_io_in_0_rx_snp_bits_fwdNID;
  logic [11:0] _rnXbar_io_in_0_rx_snp_bits_fwdTxnID;
  logic [4:0] _rnXbar_io_in_0_rx_snp_bits_opcode;
  logic [44:0] _rnXbar_io_in_0_rx_snp_bits_addr;
  logic _rnXbar_io_in_0_rx_snp_bits_doNotGoToSD;
  logic _rnXbar_io_in_0_rx_snp_bits_retToSrc;
  logic _rnXbar_io_out_0_tx_req_valid;
  logic [10:0] _rnXbar_io_out_0_tx_req_bits_tgtID;
  logic [10:0] _rnXbar_io_out_0_tx_req_bits_srcID;
  logic [11:0] _rnXbar_io_out_0_tx_req_bits_txnID;
  logic [6:0] _rnXbar_io_out_0_tx_req_bits_opcode;
  logic [2:0] _rnXbar_io_out_0_tx_req_bits_size;
  logic [47:0] _rnXbar_io_out_0_tx_req_bits_addr;
  logic _rnXbar_io_out_0_tx_req_bits_allowRetry;
  logic [1:0] _rnXbar_io_out_0_tx_req_bits_order;
  logic [3:0] _rnXbar_io_out_0_tx_req_bits_pCrdType;
  logic _rnXbar_io_out_0_tx_req_bits_memAttr_allocate;
  logic _rnXbar_io_out_0_tx_req_bits_memAttr_cacheable;
  logic _rnXbar_io_out_0_tx_req_bits_memAttr_device;
  logic _rnXbar_io_out_0_tx_req_bits_memAttr_ewa;
  logic _rnXbar_io_out_0_tx_req_bits_snpAttr;
  logic _rnXbar_io_out_0_tx_req_bits_expCompAck;
  logic _rnXbar_io_out_0_tx_rsp_valid;
  logic [10:0] _rnXbar_io_out_0_tx_rsp_bits_srcID;
  logic [11:0] _rnXbar_io_out_0_tx_rsp_bits_txnID;
  logic [4:0] _rnXbar_io_out_0_tx_rsp_bits_opcode;
  logic [11:0] _rnXbar_io_out_0_tx_rsp_bits_dbID;
  logic _rnXbar_io_out_0_tx_dat_valid;
  logic [10:0] _rnXbar_io_out_0_tx_dat_bits_srcID;
  logic [11:0] _rnXbar_io_out_0_tx_dat_bits_txnID;
  logic [3:0] _rnXbar_io_out_0_tx_dat_bits_opcode;
  logic [2:0] _rnXbar_io_out_0_tx_dat_bits_resp;
  logic [1:0] _rnXbar_io_out_0_tx_dat_bits_dataID;
  logic [255:0] _rnXbar_io_out_0_tx_dat_bits_data;
  logic _rnXbar_io_out_0_rx_rsp_ready;
  logic _rnXbar_io_out_0_rx_dat_ready;
  logic _rnXbar_io_out_0_rx_snp_ready;
  logic _rnXbar_io_out_1_tx_req_valid;
  logic [10:0] _rnXbar_io_out_1_tx_req_bits_tgtID;
  logic [10:0] _rnXbar_io_out_1_tx_req_bits_srcID;
  logic [11:0] _rnXbar_io_out_1_tx_req_bits_txnID;
  logic [6:0] _rnXbar_io_out_1_tx_req_bits_opcode;
  logic [2:0] _rnXbar_io_out_1_tx_req_bits_size;
  logic [47:0] _rnXbar_io_out_1_tx_req_bits_addr;
  logic _rnXbar_io_out_1_tx_req_bits_allowRetry;
  logic [1:0] _rnXbar_io_out_1_tx_req_bits_order;
  logic [3:0] _rnXbar_io_out_1_tx_req_bits_pCrdType;
  logic _rnXbar_io_out_1_tx_req_bits_memAttr_allocate;
  logic _rnXbar_io_out_1_tx_req_bits_memAttr_cacheable;
  logic _rnXbar_io_out_1_tx_req_bits_memAttr_device;
  logic _rnXbar_io_out_1_tx_req_bits_memAttr_ewa;
  logic _rnXbar_io_out_1_tx_req_bits_snpAttr;
  logic _rnXbar_io_out_1_tx_req_bits_expCompAck;
  logic _rnXbar_io_out_1_tx_rsp_valid;
  logic [10:0] _rnXbar_io_out_1_tx_rsp_bits_srcID;
  logic [11:0] _rnXbar_io_out_1_tx_rsp_bits_txnID;
  logic [4:0] _rnXbar_io_out_1_tx_rsp_bits_opcode;
  logic [11:0] _rnXbar_io_out_1_tx_rsp_bits_dbID;
  logic _rnXbar_io_out_1_tx_dat_valid;
  logic [10:0] _rnXbar_io_out_1_tx_dat_bits_srcID;
  logic [11:0] _rnXbar_io_out_1_tx_dat_bits_txnID;
  logic [3:0] _rnXbar_io_out_1_tx_dat_bits_opcode;
  logic [2:0] _rnXbar_io_out_1_tx_dat_bits_resp;
  logic [1:0] _rnXbar_io_out_1_tx_dat_bits_dataID;
  logic [255:0] _rnXbar_io_out_1_tx_dat_bits_data;
  logic _rnXbar_io_out_1_rx_rsp_ready;
  logic _rnXbar_io_out_1_rx_dat_ready;
  logic _rnXbar_io_out_1_rx_snp_ready;
  logic _rnXbar_io_out_2_tx_req_valid;
  logic [10:0] _rnXbar_io_out_2_tx_req_bits_tgtID;
  logic [10:0] _rnXbar_io_out_2_tx_req_bits_srcID;
  logic [11:0] _rnXbar_io_out_2_tx_req_bits_txnID;
  logic [6:0] _rnXbar_io_out_2_tx_req_bits_opcode;
  logic [2:0] _rnXbar_io_out_2_tx_req_bits_size;
  logic [47:0] _rnXbar_io_out_2_tx_req_bits_addr;
  logic _rnXbar_io_out_2_tx_req_bits_allowRetry;
  logic [1:0] _rnXbar_io_out_2_tx_req_bits_order;
  logic [3:0] _rnXbar_io_out_2_tx_req_bits_pCrdType;
  logic _rnXbar_io_out_2_tx_req_bits_memAttr_allocate;
  logic _rnXbar_io_out_2_tx_req_bits_memAttr_cacheable;
  logic _rnXbar_io_out_2_tx_req_bits_memAttr_device;
  logic _rnXbar_io_out_2_tx_req_bits_memAttr_ewa;
  logic _rnXbar_io_out_2_tx_req_bits_snpAttr;
  logic _rnXbar_io_out_2_tx_req_bits_expCompAck;
  logic _rnXbar_io_out_2_tx_rsp_valid;
  logic [10:0] _rnXbar_io_out_2_tx_rsp_bits_srcID;
  logic [11:0] _rnXbar_io_out_2_tx_rsp_bits_txnID;
  logic [4:0] _rnXbar_io_out_2_tx_rsp_bits_opcode;
  logic [11:0] _rnXbar_io_out_2_tx_rsp_bits_dbID;
  logic _rnXbar_io_out_2_tx_dat_valid;
  logic [10:0] _rnXbar_io_out_2_tx_dat_bits_srcID;
  logic [11:0] _rnXbar_io_out_2_tx_dat_bits_txnID;
  logic [3:0] _rnXbar_io_out_2_tx_dat_bits_opcode;
  logic [2:0] _rnXbar_io_out_2_tx_dat_bits_resp;
  logic [1:0] _rnXbar_io_out_2_tx_dat_bits_dataID;
  logic [255:0] _rnXbar_io_out_2_tx_dat_bits_data;
  logic _rnXbar_io_out_2_rx_rsp_ready;
  logic _rnXbar_io_out_2_rx_dat_ready;
  logic _rnXbar_io_out_2_rx_snp_ready;
  logic _rnXbar_io_out_3_tx_req_valid;
  logic [10:0] _rnXbar_io_out_3_tx_req_bits_tgtID;
  logic [10:0] _rnXbar_io_out_3_tx_req_bits_srcID;
  logic [11:0] _rnXbar_io_out_3_tx_req_bits_txnID;
  logic [6:0] _rnXbar_io_out_3_tx_req_bits_opcode;
  logic [2:0] _rnXbar_io_out_3_tx_req_bits_size;
  logic [47:0] _rnXbar_io_out_3_tx_req_bits_addr;
  logic _rnXbar_io_out_3_tx_req_bits_allowRetry;
  logic [1:0] _rnXbar_io_out_3_tx_req_bits_order;
  logic [3:0] _rnXbar_io_out_3_tx_req_bits_pCrdType;
  logic _rnXbar_io_out_3_tx_req_bits_memAttr_allocate;
  logic _rnXbar_io_out_3_tx_req_bits_memAttr_cacheable;
  logic _rnXbar_io_out_3_tx_req_bits_memAttr_device;
  logic _rnXbar_io_out_3_tx_req_bits_memAttr_ewa;
  logic _rnXbar_io_out_3_tx_req_bits_snpAttr;
  logic _rnXbar_io_out_3_tx_req_bits_expCompAck;
  logic _rnXbar_io_out_3_tx_rsp_valid;
  logic [10:0] _rnXbar_io_out_3_tx_rsp_bits_srcID;
  logic [11:0] _rnXbar_io_out_3_tx_rsp_bits_txnID;
  logic [4:0] _rnXbar_io_out_3_tx_rsp_bits_opcode;
  logic [11:0] _rnXbar_io_out_3_tx_rsp_bits_dbID;
  logic _rnXbar_io_out_3_tx_dat_valid;
  logic [10:0] _rnXbar_io_out_3_tx_dat_bits_srcID;
  logic [11:0] _rnXbar_io_out_3_tx_dat_bits_txnID;
  logic [3:0] _rnXbar_io_out_3_tx_dat_bits_opcode;
  logic [2:0] _rnXbar_io_out_3_tx_dat_bits_resp;
  logic [1:0] _rnXbar_io_out_3_tx_dat_bits_dataID;
  logic [255:0] _rnXbar_io_out_3_tx_dat_bits_data;
  logic _rnXbar_io_out_3_rx_rsp_ready;
  logic _rnXbar_io_out_3_rx_dat_ready;
  logic _rnXbar_io_out_3_rx_snp_ready;
  logic _mmioMerger_io_in_cache_tx_req_ready;
  logic _mmioMerger_io_in_cache_tx_dat_ready;
  logic _mmioMerger_io_in_cache_rx_rsp_valid;
  logic [10:0] _mmioMerger_io_in_cache_rx_rsp_bits_srcID;
  logic [11:0] _mmioMerger_io_in_cache_rx_rsp_bits_txnID;
  logic [4:0] _mmioMerger_io_in_cache_rx_rsp_bits_opcode;
  logic [11:0] _mmioMerger_io_in_cache_rx_rsp_bits_dbID;
  logic _mmioMerger_io_in_cache_rx_dat_valid;
  logic [10:0] _mmioMerger_io_in_cache_rx_dat_bits_srcID;
  logic [11:0] _mmioMerger_io_in_cache_rx_dat_bits_txnID;
  logic [3:0] _mmioMerger_io_in_cache_rx_dat_bits_opcode;
  logic [2:0] _mmioMerger_io_in_cache_rx_dat_bits_resp;
  logic [1:0] _mmioMerger_io_in_cache_rx_dat_bits_dataID;
  logic [255:0] _mmioMerger_io_in_cache_rx_dat_bits_data;
  logic _mmioMerger_io_in_uncache_tx_req_ready;
  logic _mmioMerger_io_in_uncache_tx_dat_ready;
  logic _mmioMerger_io_in_uncache_rx_rsp_valid;
  logic [3:0] _mmioMerger_io_in_uncache_rx_rsp_bits_qos;
  logic [10:0] _mmioMerger_io_in_uncache_rx_rsp_bits_tgtID;
  logic [11:0] _mmioMerger_io_in_uncache_rx_rsp_bits_txnID;
  logic [4:0] _mmioMerger_io_in_uncache_rx_rsp_bits_opcode;
  logic [1:0] _mmioMerger_io_in_uncache_rx_rsp_bits_respErr;
  logic [2:0] _mmioMerger_io_in_uncache_rx_rsp_bits_resp;
  logic [2:0] _mmioMerger_io_in_uncache_rx_rsp_bits_fwdState;
  logic [2:0] _mmioMerger_io_in_uncache_rx_rsp_bits_cBusy;
  logic [11:0] _mmioMerger_io_in_uncache_rx_rsp_bits_dbID;
  logic [3:0] _mmioMerger_io_in_uncache_rx_rsp_bits_pCrdType;
  logic [1:0] _mmioMerger_io_in_uncache_rx_rsp_bits_tagOp;
  logic _mmioMerger_io_in_uncache_rx_rsp_bits_traceTag;
  logic _mmioMerger_io_in_uncache_rx_dat_valid;
  logic [3:0] _mmioMerger_io_in_uncache_rx_dat_bits_qos;
  logic [10:0] _mmioMerger_io_in_uncache_rx_dat_bits_tgtID;
  logic [11:0] _mmioMerger_io_in_uncache_rx_dat_bits_txnID;
  logic [10:0] _mmioMerger_io_in_uncache_rx_dat_bits_homeNID;
  logic [3:0] _mmioMerger_io_in_uncache_rx_dat_bits_opcode;
  logic [1:0] _mmioMerger_io_in_uncache_rx_dat_bits_respErr;
  logic [2:0] _mmioMerger_io_in_uncache_rx_dat_bits_resp;
  logic [3:0] _mmioMerger_io_in_uncache_rx_dat_bits_dataSource;
  logic [2:0] _mmioMerger_io_in_uncache_rx_dat_bits_cBusy;
  logic [11:0] _mmioMerger_io_in_uncache_rx_dat_bits_dbID;
  logic [1:0] _mmioMerger_io_in_uncache_rx_dat_bits_ccID;
  logic [1:0] _mmioMerger_io_in_uncache_rx_dat_bits_dataID;
  logic [1:0] _mmioMerger_io_in_uncache_rx_dat_bits_tagOp;
  logic [7:0] _mmioMerger_io_in_uncache_rx_dat_bits_tag;
  logic [1:0] _mmioMerger_io_in_uncache_rx_dat_bits_tu;
  logic _mmioMerger_io_in_uncache_rx_dat_bits_traceTag;
  logic [3:0] _mmioMerger_io_in_uncache_rx_dat_bits_rsvdc;
  logic [31:0] _mmioMerger_io_in_uncache_rx_dat_bits_be;
  logic [255:0] _mmioMerger_io_in_uncache_rx_dat_bits_data;
  logic [31:0] _mmioMerger_io_in_uncache_rx_dat_bits_dataCheck;
  logic [3:0] _mmioMerger_io_in_uncache_rx_dat_bits_poison;
  logic _mmioMerger_io_out_tx_req_valid;
  logic [3:0] _mmioMerger_io_out_tx_req_bits_qos;
  logic [10:0] _mmioMerger_io_out_tx_req_bits_tgtID;
  logic [10:0] _mmioMerger_io_out_tx_req_bits_srcID;
  logic [11:0] _mmioMerger_io_out_tx_req_bits_txnID;
  logic [10:0] _mmioMerger_io_out_tx_req_bits_returnNID;
  logic _mmioMerger_io_out_tx_req_bits_stashNIDValid;
  logic [11:0] _mmioMerger_io_out_tx_req_bits_returnTxnID;
  logic [6:0] _mmioMerger_io_out_tx_req_bits_opcode;
  logic [2:0] _mmioMerger_io_out_tx_req_bits_size;
  logic [47:0] _mmioMerger_io_out_tx_req_bits_addr;
  logic _mmioMerger_io_out_tx_req_bits_ns;
  logic _mmioMerger_io_out_tx_req_bits_likelyshared;
  logic _mmioMerger_io_out_tx_req_bits_allowRetry;
  logic [1:0] _mmioMerger_io_out_tx_req_bits_order;
  logic [3:0] _mmioMerger_io_out_tx_req_bits_pCrdType;
  logic _mmioMerger_io_out_tx_req_bits_memAttr_allocate;
  logic _mmioMerger_io_out_tx_req_bits_memAttr_cacheable;
  logic _mmioMerger_io_out_tx_req_bits_memAttr_device;
  logic _mmioMerger_io_out_tx_req_bits_memAttr_ewa;
  logic _mmioMerger_io_out_tx_req_bits_snpAttr;
  logic [7:0] _mmioMerger_io_out_tx_req_bits_lpIDWithPadding;
  logic _mmioMerger_io_out_tx_req_bits_snoopMe;
  logic _mmioMerger_io_out_tx_req_bits_expCompAck;
  logic [1:0] _mmioMerger_io_out_tx_req_bits_tagOp;
  logic _mmioMerger_io_out_tx_req_bits_traceTag;
  logic _mmioMerger_io_out_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] _mmioMerger_io_out_tx_req_bits_mpam_partID;
  logic _mmioMerger_io_out_tx_req_bits_mpam_mpamNS;
  logic [3:0] _mmioMerger_io_out_tx_req_bits_rsvdc;
  logic _mmioMerger_io_out_tx_dat_valid;
  logic [3:0] _mmioMerger_io_out_tx_dat_bits_qos;
  logic [10:0] _mmioMerger_io_out_tx_dat_bits_tgtID;
  logic [10:0] _mmioMerger_io_out_tx_dat_bits_srcID;
  logic [11:0] _mmioMerger_io_out_tx_dat_bits_txnID;
  logic [10:0] _mmioMerger_io_out_tx_dat_bits_homeNID;
  logic [3:0] _mmioMerger_io_out_tx_dat_bits_opcode;
  logic [1:0] _mmioMerger_io_out_tx_dat_bits_respErr;
  logic [2:0] _mmioMerger_io_out_tx_dat_bits_resp;
  logic [3:0] _mmioMerger_io_out_tx_dat_bits_dataSource;
  logic [2:0] _mmioMerger_io_out_tx_dat_bits_cBusy;
  logic [11:0] _mmioMerger_io_out_tx_dat_bits_dbID;
  logic [1:0] _mmioMerger_io_out_tx_dat_bits_ccID;
  logic [1:0] _mmioMerger_io_out_tx_dat_bits_dataID;
  logic [1:0] _mmioMerger_io_out_tx_dat_bits_tagOp;
  logic [7:0] _mmioMerger_io_out_tx_dat_bits_tag;
  logic [1:0] _mmioMerger_io_out_tx_dat_bits_tu;
  logic _mmioMerger_io_out_tx_dat_bits_traceTag;
  logic [3:0] _mmioMerger_io_out_tx_dat_bits_rsvdc;
  logic [31:0] _mmioMerger_io_out_tx_dat_bits_be;
  logic [255:0] _mmioMerger_io_out_tx_dat_bits_data;
  logic [31:0] _mmioMerger_io_out_tx_dat_bits_dataCheck;
  logic [3:0] _mmioMerger_io_out_tx_dat_bits_poison;
  logic _mmioMerger_io_out_rx_rsp_ready;
  logic _mmioMerger_io_out_rx_dat_ready;
  logic _mmioDiverger_io_in_0_tx_req_ready;
  logic _mmioDiverger_io_in_0_tx_rsp_ready;
  logic _mmioDiverger_io_in_0_tx_dat_ready;
  logic _mmioDiverger_io_in_0_rx_rsp_valid;
  logic [3:0] _mmioDiverger_io_in_0_rx_rsp_bits_qos;
  logic [11:0] _mmioDiverger_io_in_0_rx_rsp_bits_txnID;
  logic [4:0] _mmioDiverger_io_in_0_rx_rsp_bits_opcode;
  logic [1:0] _mmioDiverger_io_in_0_rx_rsp_bits_respErr;
  logic [2:0] _mmioDiverger_io_in_0_rx_rsp_bits_resp;
  logic [2:0] _mmioDiverger_io_in_0_rx_rsp_bits_fwdState;
  logic [2:0] _mmioDiverger_io_in_0_rx_rsp_bits_cBusy;
  logic [11:0] _mmioDiverger_io_in_0_rx_rsp_bits_dbID;
  logic [3:0] _mmioDiverger_io_in_0_rx_rsp_bits_pCrdType;
  logic [1:0] _mmioDiverger_io_in_0_rx_rsp_bits_tagOp;
  logic _mmioDiverger_io_in_0_rx_rsp_bits_traceTag;
  logic _mmioDiverger_io_in_0_rx_dat_valid;
  logic [3:0] _mmioDiverger_io_in_0_rx_dat_bits_qos;
  logic [11:0] _mmioDiverger_io_in_0_rx_dat_bits_txnID;
  logic [10:0] _mmioDiverger_io_in_0_rx_dat_bits_homeNID;
  logic [3:0] _mmioDiverger_io_in_0_rx_dat_bits_opcode;
  logic [1:0] _mmioDiverger_io_in_0_rx_dat_bits_respErr;
  logic [2:0] _mmioDiverger_io_in_0_rx_dat_bits_resp;
  logic [3:0] _mmioDiverger_io_in_0_rx_dat_bits_dataSource;
  logic [2:0] _mmioDiverger_io_in_0_rx_dat_bits_cBusy;
  logic [11:0] _mmioDiverger_io_in_0_rx_dat_bits_dbID;
  logic [1:0] _mmioDiverger_io_in_0_rx_dat_bits_ccID;
  logic [1:0] _mmioDiverger_io_in_0_rx_dat_bits_dataID;
  logic [1:0] _mmioDiverger_io_in_0_rx_dat_bits_tagOp;
  logic [7:0] _mmioDiverger_io_in_0_rx_dat_bits_tag;
  logic [1:0] _mmioDiverger_io_in_0_rx_dat_bits_tu;
  logic _mmioDiverger_io_in_0_rx_dat_bits_traceTag;
  logic [3:0] _mmioDiverger_io_in_0_rx_dat_bits_rsvdc;
  logic [31:0] _mmioDiverger_io_in_0_rx_dat_bits_be;
  logic [255:0] _mmioDiverger_io_in_0_rx_dat_bits_data;
  logic [31:0] _mmioDiverger_io_in_0_rx_dat_bits_dataCheck;
  logic [3:0] _mmioDiverger_io_in_0_rx_dat_bits_poison;
  logic _mmioDiverger_io_in_0_rx_snp_valid;
  logic [11:0] _mmioDiverger_io_in_0_rx_snp_bits_txnID;
  logic [10:0] _mmioDiverger_io_in_0_rx_snp_bits_fwdNID;
  logic [11:0] _mmioDiverger_io_in_0_rx_snp_bits_fwdTxnID;
  logic [4:0] _mmioDiverger_io_in_0_rx_snp_bits_opcode;
  logic [44:0] _mmioDiverger_io_in_0_rx_snp_bits_addr;
  logic _mmioDiverger_io_in_0_rx_snp_bits_doNotGoToSD;
  logic _mmioDiverger_io_in_0_rx_snp_bits_retToSrc;
  logic _mmioDiverger_io_out_cache_0_tx_req_valid;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_req_bits_qos;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_req_bits_tgtID;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_req_bits_srcID;
  logic [11:0] _mmioDiverger_io_out_cache_0_tx_req_bits_txnID;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_req_bits_returnNID;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_stashNIDValid;
  logic [11:0] _mmioDiverger_io_out_cache_0_tx_req_bits_returnTxnID;
  logic [6:0] _mmioDiverger_io_out_cache_0_tx_req_bits_opcode;
  logic [2:0] _mmioDiverger_io_out_cache_0_tx_req_bits_size;
  logic [47:0] _mmioDiverger_io_out_cache_0_tx_req_bits_addr;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_ns;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_likelyshared;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_allowRetry;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_req_bits_order;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_req_bits_pCrdType;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_allocate;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_cacheable;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_device;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_ewa;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_snpAttr;
  logic [7:0] _mmioDiverger_io_out_cache_0_tx_req_bits_lpIDWithPadding;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_snoopMe;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_expCompAck;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_req_bits_tagOp;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_traceTag;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] _mmioDiverger_io_out_cache_0_tx_req_bits_mpam_partID;
  logic _mmioDiverger_io_out_cache_0_tx_req_bits_mpam_mpamNS;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_req_bits_rsvdc;
  logic _mmioDiverger_io_out_cache_0_tx_rsp_valid;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_rsp_bits_srcID;
  logic [11:0] _mmioDiverger_io_out_cache_0_tx_rsp_bits_txnID;
  logic [4:0] _mmioDiverger_io_out_cache_0_tx_rsp_bits_opcode;
  logic [11:0] _mmioDiverger_io_out_cache_0_tx_rsp_bits_dbID;
  logic _mmioDiverger_io_out_cache_0_tx_dat_valid;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_qos;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_tgtID;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_srcID;
  logic [11:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_txnID;
  logic [10:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_homeNID;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_opcode;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_respErr;
  logic [2:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_resp;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_dataSource;
  logic [2:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_cBusy;
  logic [11:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_dbID;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_ccID;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_dataID;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_tagOp;
  logic [7:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_tag;
  logic [1:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_tu;
  logic _mmioDiverger_io_out_cache_0_tx_dat_bits_traceTag;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_rsvdc;
  logic [31:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_be;
  logic [255:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_data;
  logic [31:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_dataCheck;
  logic [3:0] _mmioDiverger_io_out_cache_0_tx_dat_bits_poison;
  logic _mmioDiverger_io_out_cache_0_rx_rsp_ready;
  logic _mmioDiverger_io_out_cache_0_rx_dat_ready;
  logic _mmioDiverger_io_out_cache_0_rx_snp_ready;
  logic _mmioDiverger_io_out_uncache_tx_req_valid;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_req_bits_qos;
  logic [10:0] _mmioDiverger_io_out_uncache_tx_req_bits_tgtID;
  logic [10:0] _mmioDiverger_io_out_uncache_tx_req_bits_srcID;
  logic [11:0] _mmioDiverger_io_out_uncache_tx_req_bits_txnID;
  logic [10:0] _mmioDiverger_io_out_uncache_tx_req_bits_returnNID;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_stashNIDValid;
  logic [11:0] _mmioDiverger_io_out_uncache_tx_req_bits_returnTxnID;
  logic [6:0] _mmioDiverger_io_out_uncache_tx_req_bits_opcode;
  logic [2:0] _mmioDiverger_io_out_uncache_tx_req_bits_size;
  logic [47:0] _mmioDiverger_io_out_uncache_tx_req_bits_addr;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_ns;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_likelyshared;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_allowRetry;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_req_bits_pCrdType;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_memAttr_allocate;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_memAttr_cacheable;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_memAttr_device;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_memAttr_ewa;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_snpAttr;
  logic [7:0] _mmioDiverger_io_out_uncache_tx_req_bits_lpIDWithPadding;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_snoopMe;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_expCompAck;
  logic [1:0] _mmioDiverger_io_out_uncache_tx_req_bits_tagOp;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_traceTag;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] _mmioDiverger_io_out_uncache_tx_req_bits_mpam_partID;
  logic _mmioDiverger_io_out_uncache_tx_req_bits_mpam_mpamNS;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_req_bits_rsvdc;
  logic _mmioDiverger_io_out_uncache_tx_dat_valid;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_dat_bits_qos;
  logic [10:0] _mmioDiverger_io_out_uncache_tx_dat_bits_tgtID;
  logic [10:0] _mmioDiverger_io_out_uncache_tx_dat_bits_srcID;
  logic [11:0] _mmioDiverger_io_out_uncache_tx_dat_bits_txnID;
  logic [10:0] _mmioDiverger_io_out_uncache_tx_dat_bits_homeNID;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_dat_bits_opcode;
  logic [1:0] _mmioDiverger_io_out_uncache_tx_dat_bits_respErr;
  logic [2:0] _mmioDiverger_io_out_uncache_tx_dat_bits_resp;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_dat_bits_dataSource;
  logic [2:0] _mmioDiverger_io_out_uncache_tx_dat_bits_cBusy;
  logic [11:0] _mmioDiverger_io_out_uncache_tx_dat_bits_dbID;
  logic [1:0] _mmioDiverger_io_out_uncache_tx_dat_bits_ccID;
  logic [1:0] _mmioDiverger_io_out_uncache_tx_dat_bits_dataID;
  logic [1:0] _mmioDiverger_io_out_uncache_tx_dat_bits_tagOp;
  logic [7:0] _mmioDiverger_io_out_uncache_tx_dat_bits_tag;
  logic [1:0] _mmioDiverger_io_out_uncache_tx_dat_bits_tu;
  logic _mmioDiverger_io_out_uncache_tx_dat_bits_traceTag;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_dat_bits_rsvdc;
  logic [31:0] _mmioDiverger_io_out_uncache_tx_dat_bits_be;
  logic [255:0] _mmioDiverger_io_out_uncache_tx_dat_bits_data;
  logic [31:0] _mmioDiverger_io_out_uncache_tx_dat_bits_dataCheck;
  logic [3:0] _mmioDiverger_io_out_uncache_tx_dat_bits_poison;
  logic _mmioDiverger_io_out_uncache_rx_rsp_ready;
  logic _mmioDiverger_io_out_uncache_rx_dat_ready;
  logic _probe;

  // ===================================================================
  // 顶层 glue(本层唯一时序逻辑):io.l3Miss := RegNext(OR(各 slice 的 l3Miss))。
  // ===================================================================
// ---- §4 l3Miss 汇聚寄存（本层唯一时序逻辑） --------------------
// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,原样保留)=====
// 本层唯一时序逻辑:io.l3Miss := RegNext(OR(各 slice 的 l3Miss))。
// 4 个 slice 的 l3Miss 按位或后打一拍寄存,作为 L3 整体 miss 指示输出。

  reg          io_l3Miss_REG;
  always @(posedge clock)
    io_l3Miss_REG <=
      |{_slices_0_io_l3Miss,
        _slices_1_io_l3Miss,
        _slices_2_io_l3Miss,
        _slices_3_io_l3Miss};

  // ===================================================================
  // 11 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_openllc.py 生成)。
  //   RN 侧:io.rn -> rnLinkMonitor -> mmioDiverger -(cache)-> rnXbar -> slices;
  //   SN 侧:slices -> snXbar -(cache)-> mmioMerger <-(uncache)- mmioDiverger ->
  //          snLinkMonitor -> io.sn;
  //   旁路:topDown(读 slice msStatus,产生 addrMatch)。
  // ===================================================================
// 11 子模块黑盒例化(8 种类型)+ 引脚连核内具名信号/互联网。
// 引脚 rhs:io_* 顶层端口 / _<inst>_io_* 互联网 / clock·reset 直连(无运算/无悬空)。

// ---- §5 11 子模块例化开始（mmioDiverger / mmioMerger） --------------------
  MMIODiverger mmioDiverger (
    .clock (clock),
    .reset (reset),
    .io_in_0_tx_req_ready (_mmioDiverger_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid (_rnLinkMonitor_io_in_tx_req_valid),
    .io_in_0_tx_req_bits_qos (_rnLinkMonitor_io_in_tx_req_bits_qos),
    .io_in_0_tx_req_bits_tgtID (_rnLinkMonitor_io_in_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID (_rnLinkMonitor_io_in_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID (_rnLinkMonitor_io_in_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_returnNID (_rnLinkMonitor_io_in_tx_req_bits_returnNID),
    .io_in_0_tx_req_bits_stashNIDValid (_rnLinkMonitor_io_in_tx_req_bits_stashNIDValid),
    .io_in_0_tx_req_bits_returnTxnID (_rnLinkMonitor_io_in_tx_req_bits_returnTxnID),
    .io_in_0_tx_req_bits_opcode (_rnLinkMonitor_io_in_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size (_rnLinkMonitor_io_in_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr (_rnLinkMonitor_io_in_tx_req_bits_addr),
    .io_in_0_tx_req_bits_ns (_rnLinkMonitor_io_in_tx_req_bits_ns),
    .io_in_0_tx_req_bits_likelyshared (_rnLinkMonitor_io_in_tx_req_bits_likelyshared),
    .io_in_0_tx_req_bits_allowRetry (_rnLinkMonitor_io_in_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order (_rnLinkMonitor_io_in_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType (_rnLinkMonitor_io_in_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate (_rnLinkMonitor_io_in_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable (_rnLinkMonitor_io_in_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device (_rnLinkMonitor_io_in_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa (_rnLinkMonitor_io_in_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr (_rnLinkMonitor_io_in_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_lpIDWithPadding (_rnLinkMonitor_io_in_tx_req_bits_lpIDWithPadding),
    .io_in_0_tx_req_bits_snoopMe (_rnLinkMonitor_io_in_tx_req_bits_snoopMe),
    .io_in_0_tx_req_bits_expCompAck (_rnLinkMonitor_io_in_tx_req_bits_expCompAck),
    .io_in_0_tx_req_bits_tagOp (_rnLinkMonitor_io_in_tx_req_bits_tagOp),
    .io_in_0_tx_req_bits_traceTag (_rnLinkMonitor_io_in_tx_req_bits_traceTag),
    .io_in_0_tx_req_bits_mpam_perfMonGroup (_rnLinkMonitor_io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_0_tx_req_bits_mpam_partID (_rnLinkMonitor_io_in_tx_req_bits_mpam_partID),
    .io_in_0_tx_req_bits_mpam_mpamNS (_rnLinkMonitor_io_in_tx_req_bits_mpam_mpamNS),
    .io_in_0_tx_req_bits_rsvdc (_rnLinkMonitor_io_in_tx_req_bits_rsvdc),
    .io_in_0_tx_rsp_ready (_mmioDiverger_io_in_0_tx_rsp_ready),
    .io_in_0_tx_rsp_valid (_rnLinkMonitor_io_in_tx_rsp_valid),
    .io_in_0_tx_rsp_bits_srcID (_rnLinkMonitor_io_in_tx_rsp_bits_srcID),
    .io_in_0_tx_rsp_bits_txnID (_rnLinkMonitor_io_in_tx_rsp_bits_txnID),
    .io_in_0_tx_rsp_bits_opcode (_rnLinkMonitor_io_in_tx_rsp_bits_opcode),
    .io_in_0_tx_rsp_bits_dbID (_rnLinkMonitor_io_in_tx_rsp_bits_dbID),
    .io_in_0_tx_dat_ready (_mmioDiverger_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid (_rnLinkMonitor_io_in_tx_dat_valid),
    .io_in_0_tx_dat_bits_qos (_rnLinkMonitor_io_in_tx_dat_bits_qos),
    .io_in_0_tx_dat_bits_tgtID (_rnLinkMonitor_io_in_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID (_rnLinkMonitor_io_in_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID (_rnLinkMonitor_io_in_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID (_rnLinkMonitor_io_in_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode (_rnLinkMonitor_io_in_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_respErr (_rnLinkMonitor_io_in_tx_dat_bits_respErr),
    .io_in_0_tx_dat_bits_resp (_rnLinkMonitor_io_in_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource (_rnLinkMonitor_io_in_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_cBusy (_rnLinkMonitor_io_in_tx_dat_bits_cBusy),
    .io_in_0_tx_dat_bits_dbID (_rnLinkMonitor_io_in_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_ccID (_rnLinkMonitor_io_in_tx_dat_bits_ccID),
    .io_in_0_tx_dat_bits_dataID (_rnLinkMonitor_io_in_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_tagOp (_rnLinkMonitor_io_in_tx_dat_bits_tagOp),
    .io_in_0_tx_dat_bits_tag (_rnLinkMonitor_io_in_tx_dat_bits_tag),
    .io_in_0_tx_dat_bits_tu (_rnLinkMonitor_io_in_tx_dat_bits_tu),
    .io_in_0_tx_dat_bits_traceTag (_rnLinkMonitor_io_in_tx_dat_bits_traceTag),
    .io_in_0_tx_dat_bits_rsvdc (_rnLinkMonitor_io_in_tx_dat_bits_rsvdc),
    .io_in_0_tx_dat_bits_be (_rnLinkMonitor_io_in_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data (_rnLinkMonitor_io_in_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck (_rnLinkMonitor_io_in_tx_dat_bits_dataCheck),
    .io_in_0_tx_dat_bits_poison (_rnLinkMonitor_io_in_tx_dat_bits_poison),
    .io_in_0_rx_rsp_ready (_rnLinkMonitor_io_in_rx_rsp_ready),
    .io_in_0_rx_rsp_valid (_mmioDiverger_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_qos (_mmioDiverger_io_in_0_rx_rsp_bits_qos),
    .io_in_0_rx_rsp_bits_txnID (_mmioDiverger_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode (_mmioDiverger_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_respErr (_mmioDiverger_io_in_0_rx_rsp_bits_respErr),
    .io_in_0_rx_rsp_bits_resp (_mmioDiverger_io_in_0_rx_rsp_bits_resp),
    .io_in_0_rx_rsp_bits_fwdState (_mmioDiverger_io_in_0_rx_rsp_bits_fwdState),
    .io_in_0_rx_rsp_bits_cBusy (_mmioDiverger_io_in_0_rx_rsp_bits_cBusy),
    .io_in_0_rx_rsp_bits_dbID (_mmioDiverger_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_rsp_bits_pCrdType (_mmioDiverger_io_in_0_rx_rsp_bits_pCrdType),
    .io_in_0_rx_rsp_bits_tagOp (_mmioDiverger_io_in_0_rx_rsp_bits_tagOp),
    .io_in_0_rx_rsp_bits_traceTag (_mmioDiverger_io_in_0_rx_rsp_bits_traceTag),
    .io_in_0_rx_dat_ready (_rnLinkMonitor_io_in_rx_dat_ready),
    .io_in_0_rx_dat_valid (_mmioDiverger_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_qos (_mmioDiverger_io_in_0_rx_dat_bits_qos),
    .io_in_0_rx_dat_bits_txnID (_mmioDiverger_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_homeNID (_mmioDiverger_io_in_0_rx_dat_bits_homeNID),
    .io_in_0_rx_dat_bits_opcode (_mmioDiverger_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_respErr (_mmioDiverger_io_in_0_rx_dat_bits_respErr),
    .io_in_0_rx_dat_bits_resp (_mmioDiverger_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataSource (_mmioDiverger_io_in_0_rx_dat_bits_dataSource),
    .io_in_0_rx_dat_bits_cBusy (_mmioDiverger_io_in_0_rx_dat_bits_cBusy),
    .io_in_0_rx_dat_bits_dbID (_mmioDiverger_io_in_0_rx_dat_bits_dbID),
    .io_in_0_rx_dat_bits_ccID (_mmioDiverger_io_in_0_rx_dat_bits_ccID),
    .io_in_0_rx_dat_bits_dataID (_mmioDiverger_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_tagOp (_mmioDiverger_io_in_0_rx_dat_bits_tagOp),
    .io_in_0_rx_dat_bits_tag (_mmioDiverger_io_in_0_rx_dat_bits_tag),
    .io_in_0_rx_dat_bits_tu (_mmioDiverger_io_in_0_rx_dat_bits_tu),
    .io_in_0_rx_dat_bits_traceTag (_mmioDiverger_io_in_0_rx_dat_bits_traceTag),
    .io_in_0_rx_dat_bits_rsvdc (_mmioDiverger_io_in_0_rx_dat_bits_rsvdc),
    .io_in_0_rx_dat_bits_be (_mmioDiverger_io_in_0_rx_dat_bits_be),
    .io_in_0_rx_dat_bits_data (_mmioDiverger_io_in_0_rx_dat_bits_data),
    .io_in_0_rx_dat_bits_dataCheck (_mmioDiverger_io_in_0_rx_dat_bits_dataCheck),
    .io_in_0_rx_dat_bits_poison (_mmioDiverger_io_in_0_rx_dat_bits_poison),
    .io_in_0_rx_snp_ready (_rnLinkMonitor_io_in_rx_snp_ready),
    .io_in_0_rx_snp_valid (_mmioDiverger_io_in_0_rx_snp_valid),
    .io_in_0_rx_snp_bits_txnID (_mmioDiverger_io_in_0_rx_snp_bits_txnID),
    .io_in_0_rx_snp_bits_fwdNID (_mmioDiverger_io_in_0_rx_snp_bits_fwdNID),
    .io_in_0_rx_snp_bits_fwdTxnID (_mmioDiverger_io_in_0_rx_snp_bits_fwdTxnID),
    .io_in_0_rx_snp_bits_opcode (_mmioDiverger_io_in_0_rx_snp_bits_opcode),
    .io_in_0_rx_snp_bits_addr (_mmioDiverger_io_in_0_rx_snp_bits_addr),
    .io_in_0_rx_snp_bits_doNotGoToSD (_mmioDiverger_io_in_0_rx_snp_bits_doNotGoToSD),
    .io_in_0_rx_snp_bits_retToSrc (_mmioDiverger_io_in_0_rx_snp_bits_retToSrc),
    .io_out_cache_0_tx_req_ready (_rnXbar_io_in_0_tx_req_ready),
    .io_out_cache_0_tx_req_valid (_mmioDiverger_io_out_cache_0_tx_req_valid),
    .io_out_cache_0_tx_req_bits_qos (_mmioDiverger_io_out_cache_0_tx_req_bits_qos),
    .io_out_cache_0_tx_req_bits_tgtID (_mmioDiverger_io_out_cache_0_tx_req_bits_tgtID),
    .io_out_cache_0_tx_req_bits_srcID (_mmioDiverger_io_out_cache_0_tx_req_bits_srcID),
    .io_out_cache_0_tx_req_bits_txnID (_mmioDiverger_io_out_cache_0_tx_req_bits_txnID),
    .io_out_cache_0_tx_req_bits_returnNID (_mmioDiverger_io_out_cache_0_tx_req_bits_returnNID),
    .io_out_cache_0_tx_req_bits_stashNIDValid (_mmioDiverger_io_out_cache_0_tx_req_bits_stashNIDValid),
    .io_out_cache_0_tx_req_bits_returnTxnID (_mmioDiverger_io_out_cache_0_tx_req_bits_returnTxnID),
    .io_out_cache_0_tx_req_bits_opcode (_mmioDiverger_io_out_cache_0_tx_req_bits_opcode),
    .io_out_cache_0_tx_req_bits_size (_mmioDiverger_io_out_cache_0_tx_req_bits_size),
    .io_out_cache_0_tx_req_bits_addr (_mmioDiverger_io_out_cache_0_tx_req_bits_addr),
    .io_out_cache_0_tx_req_bits_ns (_mmioDiverger_io_out_cache_0_tx_req_bits_ns),
    .io_out_cache_0_tx_req_bits_likelyshared (_mmioDiverger_io_out_cache_0_tx_req_bits_likelyshared),
    .io_out_cache_0_tx_req_bits_allowRetry (_mmioDiverger_io_out_cache_0_tx_req_bits_allowRetry),
    .io_out_cache_0_tx_req_bits_order (_mmioDiverger_io_out_cache_0_tx_req_bits_order),
    .io_out_cache_0_tx_req_bits_pCrdType (_mmioDiverger_io_out_cache_0_tx_req_bits_pCrdType),
    .io_out_cache_0_tx_req_bits_memAttr_allocate (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_allocate),
    .io_out_cache_0_tx_req_bits_memAttr_cacheable (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_cacheable),
    .io_out_cache_0_tx_req_bits_memAttr_device (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_device),
    .io_out_cache_0_tx_req_bits_memAttr_ewa (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_ewa),
    .io_out_cache_0_tx_req_bits_snpAttr (_mmioDiverger_io_out_cache_0_tx_req_bits_snpAttr),
    .io_out_cache_0_tx_req_bits_lpIDWithPadding (_mmioDiverger_io_out_cache_0_tx_req_bits_lpIDWithPadding),
    .io_out_cache_0_tx_req_bits_snoopMe (_mmioDiverger_io_out_cache_0_tx_req_bits_snoopMe),
    .io_out_cache_0_tx_req_bits_expCompAck (_mmioDiverger_io_out_cache_0_tx_req_bits_expCompAck),
    .io_out_cache_0_tx_req_bits_tagOp (_mmioDiverger_io_out_cache_0_tx_req_bits_tagOp),
    .io_out_cache_0_tx_req_bits_traceTag (_mmioDiverger_io_out_cache_0_tx_req_bits_traceTag),
    .io_out_cache_0_tx_req_bits_mpam_perfMonGroup (_mmioDiverger_io_out_cache_0_tx_req_bits_mpam_perfMonGroup),
    .io_out_cache_0_tx_req_bits_mpam_partID (_mmioDiverger_io_out_cache_0_tx_req_bits_mpam_partID),
    .io_out_cache_0_tx_req_bits_mpam_mpamNS (_mmioDiverger_io_out_cache_0_tx_req_bits_mpam_mpamNS),
    .io_out_cache_0_tx_req_bits_rsvdc (_mmioDiverger_io_out_cache_0_tx_req_bits_rsvdc),
    .io_out_cache_0_tx_rsp_ready (_rnXbar_io_in_0_tx_rsp_ready),
    .io_out_cache_0_tx_rsp_valid (_mmioDiverger_io_out_cache_0_tx_rsp_valid),
    .io_out_cache_0_tx_rsp_bits_srcID (_mmioDiverger_io_out_cache_0_tx_rsp_bits_srcID),
    .io_out_cache_0_tx_rsp_bits_txnID (_mmioDiverger_io_out_cache_0_tx_rsp_bits_txnID),
    .io_out_cache_0_tx_rsp_bits_opcode (_mmioDiverger_io_out_cache_0_tx_rsp_bits_opcode),
    .io_out_cache_0_tx_rsp_bits_dbID (_mmioDiverger_io_out_cache_0_tx_rsp_bits_dbID),
    .io_out_cache_0_tx_dat_ready (_rnXbar_io_in_0_tx_dat_ready),
    .io_out_cache_0_tx_dat_valid (_mmioDiverger_io_out_cache_0_tx_dat_valid),
    .io_out_cache_0_tx_dat_bits_qos (_mmioDiverger_io_out_cache_0_tx_dat_bits_qos),
    .io_out_cache_0_tx_dat_bits_tgtID (_mmioDiverger_io_out_cache_0_tx_dat_bits_tgtID),
    .io_out_cache_0_tx_dat_bits_srcID (_mmioDiverger_io_out_cache_0_tx_dat_bits_srcID),
    .io_out_cache_0_tx_dat_bits_txnID (_mmioDiverger_io_out_cache_0_tx_dat_bits_txnID),
    .io_out_cache_0_tx_dat_bits_homeNID (_mmioDiverger_io_out_cache_0_tx_dat_bits_homeNID),
    .io_out_cache_0_tx_dat_bits_opcode (_mmioDiverger_io_out_cache_0_tx_dat_bits_opcode),
    .io_out_cache_0_tx_dat_bits_respErr (_mmioDiverger_io_out_cache_0_tx_dat_bits_respErr),
    .io_out_cache_0_tx_dat_bits_resp (_mmioDiverger_io_out_cache_0_tx_dat_bits_resp),
    .io_out_cache_0_tx_dat_bits_dataSource (_mmioDiverger_io_out_cache_0_tx_dat_bits_dataSource),
    .io_out_cache_0_tx_dat_bits_cBusy (_mmioDiverger_io_out_cache_0_tx_dat_bits_cBusy),
    .io_out_cache_0_tx_dat_bits_dbID (_mmioDiverger_io_out_cache_0_tx_dat_bits_dbID),
    .io_out_cache_0_tx_dat_bits_ccID (_mmioDiverger_io_out_cache_0_tx_dat_bits_ccID),
    .io_out_cache_0_tx_dat_bits_dataID (_mmioDiverger_io_out_cache_0_tx_dat_bits_dataID),
    .io_out_cache_0_tx_dat_bits_tagOp (_mmioDiverger_io_out_cache_0_tx_dat_bits_tagOp),
    .io_out_cache_0_tx_dat_bits_tag (_mmioDiverger_io_out_cache_0_tx_dat_bits_tag),
    .io_out_cache_0_tx_dat_bits_tu (_mmioDiverger_io_out_cache_0_tx_dat_bits_tu),
    .io_out_cache_0_tx_dat_bits_traceTag (_mmioDiverger_io_out_cache_0_tx_dat_bits_traceTag),
    .io_out_cache_0_tx_dat_bits_rsvdc (_mmioDiverger_io_out_cache_0_tx_dat_bits_rsvdc),
    .io_out_cache_0_tx_dat_bits_be (_mmioDiverger_io_out_cache_0_tx_dat_bits_be),
    .io_out_cache_0_tx_dat_bits_data (_mmioDiverger_io_out_cache_0_tx_dat_bits_data),
    .io_out_cache_0_tx_dat_bits_dataCheck (_mmioDiverger_io_out_cache_0_tx_dat_bits_dataCheck),
    .io_out_cache_0_tx_dat_bits_poison (_mmioDiverger_io_out_cache_0_tx_dat_bits_poison),
    .io_out_cache_0_rx_rsp_ready (_mmioDiverger_io_out_cache_0_rx_rsp_ready),
    .io_out_cache_0_rx_rsp_valid (_rnXbar_io_in_0_rx_rsp_valid),
    .io_out_cache_0_rx_rsp_bits_qos (_rnXbar_io_in_0_rx_rsp_bits_qos),
    .io_out_cache_0_rx_rsp_bits_txnID (_rnXbar_io_in_0_rx_rsp_bits_txnID),
    .io_out_cache_0_rx_rsp_bits_opcode (_rnXbar_io_in_0_rx_rsp_bits_opcode),
    .io_out_cache_0_rx_rsp_bits_respErr (_rnXbar_io_in_0_rx_rsp_bits_respErr),
    .io_out_cache_0_rx_rsp_bits_resp (_rnXbar_io_in_0_rx_rsp_bits_resp),
    .io_out_cache_0_rx_rsp_bits_fwdState (_rnXbar_io_in_0_rx_rsp_bits_fwdState),
    .io_out_cache_0_rx_rsp_bits_cBusy (_rnXbar_io_in_0_rx_rsp_bits_cBusy),
    .io_out_cache_0_rx_rsp_bits_dbID (_rnXbar_io_in_0_rx_rsp_bits_dbID),
    .io_out_cache_0_rx_rsp_bits_pCrdType (_rnXbar_io_in_0_rx_rsp_bits_pCrdType),
    .io_out_cache_0_rx_rsp_bits_tagOp (_rnXbar_io_in_0_rx_rsp_bits_tagOp),
    .io_out_cache_0_rx_rsp_bits_traceTag (_rnXbar_io_in_0_rx_rsp_bits_traceTag),
    .io_out_cache_0_rx_dat_ready (_mmioDiverger_io_out_cache_0_rx_dat_ready),
    .io_out_cache_0_rx_dat_valid (_rnXbar_io_in_0_rx_dat_valid),
    .io_out_cache_0_rx_dat_bits_txnID (_rnXbar_io_in_0_rx_dat_bits_txnID),
    .io_out_cache_0_rx_dat_bits_homeNID (_rnXbar_io_in_0_rx_dat_bits_homeNID),
    .io_out_cache_0_rx_dat_bits_opcode (_rnXbar_io_in_0_rx_dat_bits_opcode),
    .io_out_cache_0_rx_dat_bits_resp (_rnXbar_io_in_0_rx_dat_bits_resp),
    .io_out_cache_0_rx_dat_bits_dataSource (_rnXbar_io_in_0_rx_dat_bits_dataSource),
    .io_out_cache_0_rx_dat_bits_dbID (_rnXbar_io_in_0_rx_dat_bits_dbID),
    .io_out_cache_0_rx_dat_bits_dataID (_rnXbar_io_in_0_rx_dat_bits_dataID),
    .io_out_cache_0_rx_dat_bits_be (_rnXbar_io_in_0_rx_dat_bits_be),
    .io_out_cache_0_rx_dat_bits_data (_rnXbar_io_in_0_rx_dat_bits_data),
    .io_out_cache_0_rx_dat_bits_dataCheck (_rnXbar_io_in_0_rx_dat_bits_dataCheck),
    .io_out_cache_0_rx_snp_ready (_mmioDiverger_io_out_cache_0_rx_snp_ready),
    .io_out_cache_0_rx_snp_valid (_rnXbar_io_in_0_rx_snp_valid),
    .io_out_cache_0_rx_snp_bits_txnID (_rnXbar_io_in_0_rx_snp_bits_txnID),
    .io_out_cache_0_rx_snp_bits_fwdNID (_rnXbar_io_in_0_rx_snp_bits_fwdNID),
    .io_out_cache_0_rx_snp_bits_fwdTxnID (_rnXbar_io_in_0_rx_snp_bits_fwdTxnID),
    .io_out_cache_0_rx_snp_bits_opcode (_rnXbar_io_in_0_rx_snp_bits_opcode),
    .io_out_cache_0_rx_snp_bits_addr (_rnXbar_io_in_0_rx_snp_bits_addr),
    .io_out_cache_0_rx_snp_bits_doNotGoToSD (_rnXbar_io_in_0_rx_snp_bits_doNotGoToSD),
    .io_out_cache_0_rx_snp_bits_retToSrc (_rnXbar_io_in_0_rx_snp_bits_retToSrc),
    .io_out_uncache_tx_req_ready (_mmioMerger_io_in_uncache_tx_req_ready),
    .io_out_uncache_tx_req_valid (_mmioDiverger_io_out_uncache_tx_req_valid),
    .io_out_uncache_tx_req_bits_qos (_mmioDiverger_io_out_uncache_tx_req_bits_qos),
    .io_out_uncache_tx_req_bits_tgtID (_mmioDiverger_io_out_uncache_tx_req_bits_tgtID),
    .io_out_uncache_tx_req_bits_srcID (_mmioDiverger_io_out_uncache_tx_req_bits_srcID),
    .io_out_uncache_tx_req_bits_txnID (_mmioDiverger_io_out_uncache_tx_req_bits_txnID),
    .io_out_uncache_tx_req_bits_returnNID (_mmioDiverger_io_out_uncache_tx_req_bits_returnNID),
    .io_out_uncache_tx_req_bits_stashNIDValid (_mmioDiverger_io_out_uncache_tx_req_bits_stashNIDValid),
    .io_out_uncache_tx_req_bits_returnTxnID (_mmioDiverger_io_out_uncache_tx_req_bits_returnTxnID),
    .io_out_uncache_tx_req_bits_opcode (_mmioDiverger_io_out_uncache_tx_req_bits_opcode),
    .io_out_uncache_tx_req_bits_size (_mmioDiverger_io_out_uncache_tx_req_bits_size),
    .io_out_uncache_tx_req_bits_addr (_mmioDiverger_io_out_uncache_tx_req_bits_addr),
    .io_out_uncache_tx_req_bits_ns (_mmioDiverger_io_out_uncache_tx_req_bits_ns),
    .io_out_uncache_tx_req_bits_likelyshared (_mmioDiverger_io_out_uncache_tx_req_bits_likelyshared),
    .io_out_uncache_tx_req_bits_allowRetry (_mmioDiverger_io_out_uncache_tx_req_bits_allowRetry),
    .io_out_uncache_tx_req_bits_pCrdType (_mmioDiverger_io_out_uncache_tx_req_bits_pCrdType),
    .io_out_uncache_tx_req_bits_memAttr_allocate (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_allocate),
    .io_out_uncache_tx_req_bits_memAttr_cacheable (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_cacheable),
    .io_out_uncache_tx_req_bits_memAttr_device (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_device),
    .io_out_uncache_tx_req_bits_memAttr_ewa (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_ewa),
    .io_out_uncache_tx_req_bits_snpAttr (_mmioDiverger_io_out_uncache_tx_req_bits_snpAttr),
    .io_out_uncache_tx_req_bits_lpIDWithPadding (_mmioDiverger_io_out_uncache_tx_req_bits_lpIDWithPadding),
    .io_out_uncache_tx_req_bits_snoopMe (_mmioDiverger_io_out_uncache_tx_req_bits_snoopMe),
    .io_out_uncache_tx_req_bits_expCompAck (_mmioDiverger_io_out_uncache_tx_req_bits_expCompAck),
    .io_out_uncache_tx_req_bits_tagOp (_mmioDiverger_io_out_uncache_tx_req_bits_tagOp),
    .io_out_uncache_tx_req_bits_traceTag (_mmioDiverger_io_out_uncache_tx_req_bits_traceTag),
    .io_out_uncache_tx_req_bits_mpam_perfMonGroup (_mmioDiverger_io_out_uncache_tx_req_bits_mpam_perfMonGroup),
    .io_out_uncache_tx_req_bits_mpam_partID (_mmioDiverger_io_out_uncache_tx_req_bits_mpam_partID),
    .io_out_uncache_tx_req_bits_mpam_mpamNS (_mmioDiverger_io_out_uncache_tx_req_bits_mpam_mpamNS),
    .io_out_uncache_tx_req_bits_rsvdc (_mmioDiverger_io_out_uncache_tx_req_bits_rsvdc),
    .io_out_uncache_tx_dat_ready (_mmioMerger_io_in_uncache_tx_dat_ready),
    .io_out_uncache_tx_dat_valid (_mmioDiverger_io_out_uncache_tx_dat_valid),
    .io_out_uncache_tx_dat_bits_qos (_mmioDiverger_io_out_uncache_tx_dat_bits_qos),
    .io_out_uncache_tx_dat_bits_tgtID (_mmioDiverger_io_out_uncache_tx_dat_bits_tgtID),
    .io_out_uncache_tx_dat_bits_srcID (_mmioDiverger_io_out_uncache_tx_dat_bits_srcID),
    .io_out_uncache_tx_dat_bits_txnID (_mmioDiverger_io_out_uncache_tx_dat_bits_txnID),
    .io_out_uncache_tx_dat_bits_homeNID (_mmioDiverger_io_out_uncache_tx_dat_bits_homeNID),
    .io_out_uncache_tx_dat_bits_opcode (_mmioDiverger_io_out_uncache_tx_dat_bits_opcode),
    .io_out_uncache_tx_dat_bits_respErr (_mmioDiverger_io_out_uncache_tx_dat_bits_respErr),
    .io_out_uncache_tx_dat_bits_resp (_mmioDiverger_io_out_uncache_tx_dat_bits_resp),
    .io_out_uncache_tx_dat_bits_dataSource (_mmioDiverger_io_out_uncache_tx_dat_bits_dataSource),
    .io_out_uncache_tx_dat_bits_cBusy (_mmioDiverger_io_out_uncache_tx_dat_bits_cBusy),
    .io_out_uncache_tx_dat_bits_dbID (_mmioDiverger_io_out_uncache_tx_dat_bits_dbID),
    .io_out_uncache_tx_dat_bits_ccID (_mmioDiverger_io_out_uncache_tx_dat_bits_ccID),
    .io_out_uncache_tx_dat_bits_dataID (_mmioDiverger_io_out_uncache_tx_dat_bits_dataID),
    .io_out_uncache_tx_dat_bits_tagOp (_mmioDiverger_io_out_uncache_tx_dat_bits_tagOp),
    .io_out_uncache_tx_dat_bits_tag (_mmioDiverger_io_out_uncache_tx_dat_bits_tag),
    .io_out_uncache_tx_dat_bits_tu (_mmioDiverger_io_out_uncache_tx_dat_bits_tu),
    .io_out_uncache_tx_dat_bits_traceTag (_mmioDiverger_io_out_uncache_tx_dat_bits_traceTag),
    .io_out_uncache_tx_dat_bits_rsvdc (_mmioDiverger_io_out_uncache_tx_dat_bits_rsvdc),
    .io_out_uncache_tx_dat_bits_be (_mmioDiverger_io_out_uncache_tx_dat_bits_be),
    .io_out_uncache_tx_dat_bits_data (_mmioDiverger_io_out_uncache_tx_dat_bits_data),
    .io_out_uncache_tx_dat_bits_dataCheck (_mmioDiverger_io_out_uncache_tx_dat_bits_dataCheck),
    .io_out_uncache_tx_dat_bits_poison (_mmioDiverger_io_out_uncache_tx_dat_bits_poison),
    .io_out_uncache_rx_rsp_ready (_mmioDiverger_io_out_uncache_rx_rsp_ready),
    .io_out_uncache_rx_rsp_valid (_mmioMerger_io_in_uncache_rx_rsp_valid),
    .io_out_uncache_rx_rsp_bits_qos (_mmioMerger_io_in_uncache_rx_rsp_bits_qos),
    .io_out_uncache_rx_rsp_bits_tgtID (_mmioMerger_io_in_uncache_rx_rsp_bits_tgtID),
    .io_out_uncache_rx_rsp_bits_txnID (_mmioMerger_io_in_uncache_rx_rsp_bits_txnID),
    .io_out_uncache_rx_rsp_bits_opcode (_mmioMerger_io_in_uncache_rx_rsp_bits_opcode),
    .io_out_uncache_rx_rsp_bits_respErr (_mmioMerger_io_in_uncache_rx_rsp_bits_respErr),
    .io_out_uncache_rx_rsp_bits_resp (_mmioMerger_io_in_uncache_rx_rsp_bits_resp),
    .io_out_uncache_rx_rsp_bits_fwdState (_mmioMerger_io_in_uncache_rx_rsp_bits_fwdState),
    .io_out_uncache_rx_rsp_bits_cBusy (_mmioMerger_io_in_uncache_rx_rsp_bits_cBusy),
    .io_out_uncache_rx_rsp_bits_dbID (_mmioMerger_io_in_uncache_rx_rsp_bits_dbID),
    .io_out_uncache_rx_rsp_bits_pCrdType (_mmioMerger_io_in_uncache_rx_rsp_bits_pCrdType),
    .io_out_uncache_rx_rsp_bits_tagOp (_mmioMerger_io_in_uncache_rx_rsp_bits_tagOp),
    .io_out_uncache_rx_rsp_bits_traceTag (_mmioMerger_io_in_uncache_rx_rsp_bits_traceTag),
    .io_out_uncache_rx_dat_ready (_mmioDiverger_io_out_uncache_rx_dat_ready),
    .io_out_uncache_rx_dat_valid (_mmioMerger_io_in_uncache_rx_dat_valid),
    .io_out_uncache_rx_dat_bits_qos (_mmioMerger_io_in_uncache_rx_dat_bits_qos),
    .io_out_uncache_rx_dat_bits_tgtID (_mmioMerger_io_in_uncache_rx_dat_bits_tgtID),
    .io_out_uncache_rx_dat_bits_txnID (_mmioMerger_io_in_uncache_rx_dat_bits_txnID),
    .io_out_uncache_rx_dat_bits_homeNID (_mmioMerger_io_in_uncache_rx_dat_bits_homeNID),
    .io_out_uncache_rx_dat_bits_opcode (_mmioMerger_io_in_uncache_rx_dat_bits_opcode),
    .io_out_uncache_rx_dat_bits_respErr (_mmioMerger_io_in_uncache_rx_dat_bits_respErr),
    .io_out_uncache_rx_dat_bits_resp (_mmioMerger_io_in_uncache_rx_dat_bits_resp),
    .io_out_uncache_rx_dat_bits_dataSource (_mmioMerger_io_in_uncache_rx_dat_bits_dataSource),
    .io_out_uncache_rx_dat_bits_cBusy (_mmioMerger_io_in_uncache_rx_dat_bits_cBusy),
    .io_out_uncache_rx_dat_bits_dbID (_mmioMerger_io_in_uncache_rx_dat_bits_dbID),
    .io_out_uncache_rx_dat_bits_ccID (_mmioMerger_io_in_uncache_rx_dat_bits_ccID),
    .io_out_uncache_rx_dat_bits_dataID (_mmioMerger_io_in_uncache_rx_dat_bits_dataID),
    .io_out_uncache_rx_dat_bits_tagOp (_mmioMerger_io_in_uncache_rx_dat_bits_tagOp),
    .io_out_uncache_rx_dat_bits_tag (_mmioMerger_io_in_uncache_rx_dat_bits_tag),
    .io_out_uncache_rx_dat_bits_tu (_mmioMerger_io_in_uncache_rx_dat_bits_tu),
    .io_out_uncache_rx_dat_bits_traceTag (_mmioMerger_io_in_uncache_rx_dat_bits_traceTag),
    .io_out_uncache_rx_dat_bits_rsvdc (_mmioMerger_io_in_uncache_rx_dat_bits_rsvdc),
    .io_out_uncache_rx_dat_bits_be (_mmioMerger_io_in_uncache_rx_dat_bits_be),
    .io_out_uncache_rx_dat_bits_data (_mmioMerger_io_in_uncache_rx_dat_bits_data),
    .io_out_uncache_rx_dat_bits_dataCheck (_mmioMerger_io_in_uncache_rx_dat_bits_dataCheck),
    .io_out_uncache_rx_dat_bits_poison (_mmioMerger_io_in_uncache_rx_dat_bits_poison)
  );
  MMIOMerger mmioMerger (
    .io_in_cache_tx_req_ready (_mmioMerger_io_in_cache_tx_req_ready),
    .io_in_cache_tx_req_valid (_snXbar_io_out_tx_req_valid),
    .io_in_cache_tx_req_bits_tgtID (_snXbar_io_out_tx_req_bits_tgtID),
    .io_in_cache_tx_req_bits_srcID (_snXbar_io_out_tx_req_bits_srcID),
    .io_in_cache_tx_req_bits_txnID (_snXbar_io_out_tx_req_bits_txnID),
    .io_in_cache_tx_req_bits_opcode (_snXbar_io_out_tx_req_bits_opcode),
    .io_in_cache_tx_req_bits_size (_snXbar_io_out_tx_req_bits_size),
    .io_in_cache_tx_req_bits_addr (_snXbar_io_out_tx_req_bits_addr),
    .io_in_cache_tx_req_bits_allowRetry (_snXbar_io_out_tx_req_bits_allowRetry),
    .io_in_cache_tx_req_bits_order (_snXbar_io_out_tx_req_bits_order),
    .io_in_cache_tx_req_bits_pCrdType (_snXbar_io_out_tx_req_bits_pCrdType),
    .io_in_cache_tx_req_bits_memAttr_allocate (_snXbar_io_out_tx_req_bits_memAttr_allocate),
    .io_in_cache_tx_req_bits_memAttr_cacheable (_snXbar_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_cache_tx_req_bits_memAttr_device (_snXbar_io_out_tx_req_bits_memAttr_device),
    .io_in_cache_tx_req_bits_memAttr_ewa (_snXbar_io_out_tx_req_bits_memAttr_ewa),
    .io_in_cache_tx_req_bits_snpAttr (_snXbar_io_out_tx_req_bits_snpAttr),
    .io_in_cache_tx_req_bits_expCompAck (_snXbar_io_out_tx_req_bits_expCompAck),
    .io_in_cache_tx_dat_ready (_mmioMerger_io_in_cache_tx_dat_ready),
    .io_in_cache_tx_dat_valid (_snXbar_io_out_tx_dat_valid),
    .io_in_cache_tx_dat_bits_tgtID (_snXbar_io_out_tx_dat_bits_tgtID),
    .io_in_cache_tx_dat_bits_srcID (_snXbar_io_out_tx_dat_bits_srcID),
    .io_in_cache_tx_dat_bits_txnID (_snXbar_io_out_tx_dat_bits_txnID),
    .io_in_cache_tx_dat_bits_homeNID (_snXbar_io_out_tx_dat_bits_homeNID),
    .io_in_cache_tx_dat_bits_opcode (_snXbar_io_out_tx_dat_bits_opcode),
    .io_in_cache_tx_dat_bits_resp (_snXbar_io_out_tx_dat_bits_resp),
    .io_in_cache_tx_dat_bits_dataSource (_snXbar_io_out_tx_dat_bits_dataSource),
    .io_in_cache_tx_dat_bits_dbID (_snXbar_io_out_tx_dat_bits_dbID),
    .io_in_cache_tx_dat_bits_dataID (_snXbar_io_out_tx_dat_bits_dataID),
    .io_in_cache_tx_dat_bits_be (_snXbar_io_out_tx_dat_bits_be),
    .io_in_cache_tx_dat_bits_data (_snXbar_io_out_tx_dat_bits_data),
    .io_in_cache_tx_dat_bits_dataCheck (_snXbar_io_out_tx_dat_bits_dataCheck),
    .io_in_cache_rx_rsp_ready (_snXbar_io_out_rx_rsp_ready),
    .io_in_cache_rx_rsp_valid (_mmioMerger_io_in_cache_rx_rsp_valid),
    .io_in_cache_rx_rsp_bits_srcID (_mmioMerger_io_in_cache_rx_rsp_bits_srcID),
    .io_in_cache_rx_rsp_bits_txnID (_mmioMerger_io_in_cache_rx_rsp_bits_txnID),
    .io_in_cache_rx_rsp_bits_opcode (_mmioMerger_io_in_cache_rx_rsp_bits_opcode),
    .io_in_cache_rx_rsp_bits_dbID (_mmioMerger_io_in_cache_rx_rsp_bits_dbID),
    .io_in_cache_rx_dat_ready (_snXbar_io_out_rx_dat_ready),
    .io_in_cache_rx_dat_valid (_mmioMerger_io_in_cache_rx_dat_valid),
    .io_in_cache_rx_dat_bits_srcID (_mmioMerger_io_in_cache_rx_dat_bits_srcID),
    .io_in_cache_rx_dat_bits_txnID (_mmioMerger_io_in_cache_rx_dat_bits_txnID),
    .io_in_cache_rx_dat_bits_opcode (_mmioMerger_io_in_cache_rx_dat_bits_opcode),
    .io_in_cache_rx_dat_bits_resp (_mmioMerger_io_in_cache_rx_dat_bits_resp),
    .io_in_cache_rx_dat_bits_dataID (_mmioMerger_io_in_cache_rx_dat_bits_dataID),
    .io_in_cache_rx_dat_bits_data (_mmioMerger_io_in_cache_rx_dat_bits_data),
    .io_in_uncache_tx_req_ready (_mmioMerger_io_in_uncache_tx_req_ready),
    .io_in_uncache_tx_req_valid (_mmioDiverger_io_out_uncache_tx_req_valid),
    .io_in_uncache_tx_req_bits_qos (_mmioDiverger_io_out_uncache_tx_req_bits_qos),
    .io_in_uncache_tx_req_bits_tgtID (_mmioDiverger_io_out_uncache_tx_req_bits_tgtID),
    .io_in_uncache_tx_req_bits_srcID (_mmioDiverger_io_out_uncache_tx_req_bits_srcID),
    .io_in_uncache_tx_req_bits_txnID (_mmioDiverger_io_out_uncache_tx_req_bits_txnID),
    .io_in_uncache_tx_req_bits_returnNID (_mmioDiverger_io_out_uncache_tx_req_bits_returnNID),
    .io_in_uncache_tx_req_bits_stashNIDValid (_mmioDiverger_io_out_uncache_tx_req_bits_stashNIDValid),
    .io_in_uncache_tx_req_bits_returnTxnID (_mmioDiverger_io_out_uncache_tx_req_bits_returnTxnID),
    .io_in_uncache_tx_req_bits_opcode (_mmioDiverger_io_out_uncache_tx_req_bits_opcode),
    .io_in_uncache_tx_req_bits_size (_mmioDiverger_io_out_uncache_tx_req_bits_size),
    .io_in_uncache_tx_req_bits_addr (_mmioDiverger_io_out_uncache_tx_req_bits_addr),
    .io_in_uncache_tx_req_bits_ns (_mmioDiverger_io_out_uncache_tx_req_bits_ns),
    .io_in_uncache_tx_req_bits_likelyshared (_mmioDiverger_io_out_uncache_tx_req_bits_likelyshared),
    .io_in_uncache_tx_req_bits_allowRetry (_mmioDiverger_io_out_uncache_tx_req_bits_allowRetry),
    .io_in_uncache_tx_req_bits_pCrdType (_mmioDiverger_io_out_uncache_tx_req_bits_pCrdType),
    .io_in_uncache_tx_req_bits_memAttr_allocate (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_allocate),
    .io_in_uncache_tx_req_bits_memAttr_cacheable (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_cacheable),
    .io_in_uncache_tx_req_bits_memAttr_device (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_device),
    .io_in_uncache_tx_req_bits_memAttr_ewa (_mmioDiverger_io_out_uncache_tx_req_bits_memAttr_ewa),
    .io_in_uncache_tx_req_bits_snpAttr (_mmioDiverger_io_out_uncache_tx_req_bits_snpAttr),
    .io_in_uncache_tx_req_bits_lpIDWithPadding (_mmioDiverger_io_out_uncache_tx_req_bits_lpIDWithPadding),
    .io_in_uncache_tx_req_bits_snoopMe (_mmioDiverger_io_out_uncache_tx_req_bits_snoopMe),
    .io_in_uncache_tx_req_bits_expCompAck (_mmioDiverger_io_out_uncache_tx_req_bits_expCompAck),
    .io_in_uncache_tx_req_bits_tagOp (_mmioDiverger_io_out_uncache_tx_req_bits_tagOp),
    .io_in_uncache_tx_req_bits_traceTag (_mmioDiverger_io_out_uncache_tx_req_bits_traceTag),
    .io_in_uncache_tx_req_bits_mpam_perfMonGroup (_mmioDiverger_io_out_uncache_tx_req_bits_mpam_perfMonGroup),
    .io_in_uncache_tx_req_bits_mpam_partID (_mmioDiverger_io_out_uncache_tx_req_bits_mpam_partID),
    .io_in_uncache_tx_req_bits_mpam_mpamNS (_mmioDiverger_io_out_uncache_tx_req_bits_mpam_mpamNS),
    .io_in_uncache_tx_req_bits_rsvdc (_mmioDiverger_io_out_uncache_tx_req_bits_rsvdc),
    .io_in_uncache_tx_dat_ready (_mmioMerger_io_in_uncache_tx_dat_ready),
    .io_in_uncache_tx_dat_valid (_mmioDiverger_io_out_uncache_tx_dat_valid),
    .io_in_uncache_tx_dat_bits_qos (_mmioDiverger_io_out_uncache_tx_dat_bits_qos),
    .io_in_uncache_tx_dat_bits_tgtID (_mmioDiverger_io_out_uncache_tx_dat_bits_tgtID),
    .io_in_uncache_tx_dat_bits_srcID (_mmioDiverger_io_out_uncache_tx_dat_bits_srcID),
    .io_in_uncache_tx_dat_bits_txnID (_mmioDiverger_io_out_uncache_tx_dat_bits_txnID),
    .io_in_uncache_tx_dat_bits_homeNID (_mmioDiverger_io_out_uncache_tx_dat_bits_homeNID),
    .io_in_uncache_tx_dat_bits_opcode (_mmioDiverger_io_out_uncache_tx_dat_bits_opcode),
    .io_in_uncache_tx_dat_bits_respErr (_mmioDiverger_io_out_uncache_tx_dat_bits_respErr),
    .io_in_uncache_tx_dat_bits_resp (_mmioDiverger_io_out_uncache_tx_dat_bits_resp),
    .io_in_uncache_tx_dat_bits_dataSource (_mmioDiverger_io_out_uncache_tx_dat_bits_dataSource),
    .io_in_uncache_tx_dat_bits_cBusy (_mmioDiverger_io_out_uncache_tx_dat_bits_cBusy),
    .io_in_uncache_tx_dat_bits_dbID (_mmioDiverger_io_out_uncache_tx_dat_bits_dbID),
    .io_in_uncache_tx_dat_bits_ccID (_mmioDiverger_io_out_uncache_tx_dat_bits_ccID),
    .io_in_uncache_tx_dat_bits_dataID (_mmioDiverger_io_out_uncache_tx_dat_bits_dataID),
    .io_in_uncache_tx_dat_bits_tagOp (_mmioDiverger_io_out_uncache_tx_dat_bits_tagOp),
    .io_in_uncache_tx_dat_bits_tag (_mmioDiverger_io_out_uncache_tx_dat_bits_tag),
    .io_in_uncache_tx_dat_bits_tu (_mmioDiverger_io_out_uncache_tx_dat_bits_tu),
    .io_in_uncache_tx_dat_bits_traceTag (_mmioDiverger_io_out_uncache_tx_dat_bits_traceTag),
    .io_in_uncache_tx_dat_bits_rsvdc (_mmioDiverger_io_out_uncache_tx_dat_bits_rsvdc),
    .io_in_uncache_tx_dat_bits_be (_mmioDiverger_io_out_uncache_tx_dat_bits_be),
    .io_in_uncache_tx_dat_bits_data (_mmioDiverger_io_out_uncache_tx_dat_bits_data),
    .io_in_uncache_tx_dat_bits_dataCheck (_mmioDiverger_io_out_uncache_tx_dat_bits_dataCheck),
    .io_in_uncache_tx_dat_bits_poison (_mmioDiverger_io_out_uncache_tx_dat_bits_poison),
    .io_in_uncache_rx_rsp_ready (_mmioDiverger_io_out_uncache_rx_rsp_ready),
    .io_in_uncache_rx_rsp_valid (_mmioMerger_io_in_uncache_rx_rsp_valid),
    .io_in_uncache_rx_rsp_bits_qos (_mmioMerger_io_in_uncache_rx_rsp_bits_qos),
    .io_in_uncache_rx_rsp_bits_tgtID (_mmioMerger_io_in_uncache_rx_rsp_bits_tgtID),
    .io_in_uncache_rx_rsp_bits_txnID (_mmioMerger_io_in_uncache_rx_rsp_bits_txnID),
    .io_in_uncache_rx_rsp_bits_opcode (_mmioMerger_io_in_uncache_rx_rsp_bits_opcode),
    .io_in_uncache_rx_rsp_bits_respErr (_mmioMerger_io_in_uncache_rx_rsp_bits_respErr),
    .io_in_uncache_rx_rsp_bits_resp (_mmioMerger_io_in_uncache_rx_rsp_bits_resp),
    .io_in_uncache_rx_rsp_bits_fwdState (_mmioMerger_io_in_uncache_rx_rsp_bits_fwdState),
    .io_in_uncache_rx_rsp_bits_cBusy (_mmioMerger_io_in_uncache_rx_rsp_bits_cBusy),
    .io_in_uncache_rx_rsp_bits_dbID (_mmioMerger_io_in_uncache_rx_rsp_bits_dbID),
    .io_in_uncache_rx_rsp_bits_pCrdType (_mmioMerger_io_in_uncache_rx_rsp_bits_pCrdType),
    .io_in_uncache_rx_rsp_bits_tagOp (_mmioMerger_io_in_uncache_rx_rsp_bits_tagOp),
    .io_in_uncache_rx_rsp_bits_traceTag (_mmioMerger_io_in_uncache_rx_rsp_bits_traceTag),
    .io_in_uncache_rx_dat_ready (_mmioDiverger_io_out_uncache_rx_dat_ready),
    .io_in_uncache_rx_dat_valid (_mmioMerger_io_in_uncache_rx_dat_valid),
    .io_in_uncache_rx_dat_bits_qos (_mmioMerger_io_in_uncache_rx_dat_bits_qos),
    .io_in_uncache_rx_dat_bits_tgtID (_mmioMerger_io_in_uncache_rx_dat_bits_tgtID),
    .io_in_uncache_rx_dat_bits_txnID (_mmioMerger_io_in_uncache_rx_dat_bits_txnID),
    .io_in_uncache_rx_dat_bits_homeNID (_mmioMerger_io_in_uncache_rx_dat_bits_homeNID),
    .io_in_uncache_rx_dat_bits_opcode (_mmioMerger_io_in_uncache_rx_dat_bits_opcode),
    .io_in_uncache_rx_dat_bits_respErr (_mmioMerger_io_in_uncache_rx_dat_bits_respErr),
    .io_in_uncache_rx_dat_bits_resp (_mmioMerger_io_in_uncache_rx_dat_bits_resp),
    .io_in_uncache_rx_dat_bits_dataSource (_mmioMerger_io_in_uncache_rx_dat_bits_dataSource),
    .io_in_uncache_rx_dat_bits_cBusy (_mmioMerger_io_in_uncache_rx_dat_bits_cBusy),
    .io_in_uncache_rx_dat_bits_dbID (_mmioMerger_io_in_uncache_rx_dat_bits_dbID),
    .io_in_uncache_rx_dat_bits_ccID (_mmioMerger_io_in_uncache_rx_dat_bits_ccID),
    .io_in_uncache_rx_dat_bits_dataID (_mmioMerger_io_in_uncache_rx_dat_bits_dataID),
    .io_in_uncache_rx_dat_bits_tagOp (_mmioMerger_io_in_uncache_rx_dat_bits_tagOp),
    .io_in_uncache_rx_dat_bits_tag (_mmioMerger_io_in_uncache_rx_dat_bits_tag),
    .io_in_uncache_rx_dat_bits_tu (_mmioMerger_io_in_uncache_rx_dat_bits_tu),
    .io_in_uncache_rx_dat_bits_traceTag (_mmioMerger_io_in_uncache_rx_dat_bits_traceTag),
    .io_in_uncache_rx_dat_bits_rsvdc (_mmioMerger_io_in_uncache_rx_dat_bits_rsvdc),
    .io_in_uncache_rx_dat_bits_be (_mmioMerger_io_in_uncache_rx_dat_bits_be),
    .io_in_uncache_rx_dat_bits_data (_mmioMerger_io_in_uncache_rx_dat_bits_data),
    .io_in_uncache_rx_dat_bits_dataCheck (_mmioMerger_io_in_uncache_rx_dat_bits_dataCheck),
    .io_in_uncache_rx_dat_bits_poison (_mmioMerger_io_in_uncache_rx_dat_bits_poison),
    .io_out_tx_req_ready (_snLinkMonitor_io_in_tx_req_ready),
    .io_out_tx_req_valid (_mmioMerger_io_out_tx_req_valid),
    .io_out_tx_req_bits_qos (_mmioMerger_io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_tgtID (_mmioMerger_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID (_mmioMerger_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID (_mmioMerger_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID (_mmioMerger_io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid (_mmioMerger_io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID (_mmioMerger_io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode (_mmioMerger_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size (_mmioMerger_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr (_mmioMerger_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns (_mmioMerger_io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared (_mmioMerger_io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry (_mmioMerger_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order (_mmioMerger_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType (_mmioMerger_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate (_mmioMerger_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable (_mmioMerger_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device (_mmioMerger_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa (_mmioMerger_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr (_mmioMerger_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding (_mmioMerger_io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe (_mmioMerger_io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck (_mmioMerger_io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp (_mmioMerger_io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag (_mmioMerger_io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup (_mmioMerger_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID (_mmioMerger_io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS (_mmioMerger_io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc (_mmioMerger_io_out_tx_req_bits_rsvdc),
    .io_out_tx_dat_ready (_snLinkMonitor_io_in_tx_dat_ready),
    .io_out_tx_dat_valid (_mmioMerger_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_qos (_mmioMerger_io_out_tx_dat_bits_qos),
    .io_out_tx_dat_bits_tgtID (_mmioMerger_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID (_mmioMerger_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID (_mmioMerger_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID (_mmioMerger_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode (_mmioMerger_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr (_mmioMerger_io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp (_mmioMerger_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource (_mmioMerger_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_cBusy (_mmioMerger_io_out_tx_dat_bits_cBusy),
    .io_out_tx_dat_bits_dbID (_mmioMerger_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID (_mmioMerger_io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID (_mmioMerger_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_tagOp (_mmioMerger_io_out_tx_dat_bits_tagOp),
    .io_out_tx_dat_bits_tag (_mmioMerger_io_out_tx_dat_bits_tag),
    .io_out_tx_dat_bits_tu (_mmioMerger_io_out_tx_dat_bits_tu),
    .io_out_tx_dat_bits_traceTag (_mmioMerger_io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_rsvdc (_mmioMerger_io_out_tx_dat_bits_rsvdc),
    .io_out_tx_dat_bits_be (_mmioMerger_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data (_mmioMerger_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck (_mmioMerger_io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison (_mmioMerger_io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_ready (_mmioMerger_io_out_rx_rsp_ready),
    .io_out_rx_rsp_valid (_snLinkMonitor_io_in_rx_rsp_valid),
    .io_out_rx_rsp_bits_qos (_snLinkMonitor_io_in_rx_rsp_bits_qos),
    .io_out_rx_rsp_bits_tgtID (_snLinkMonitor_io_in_rx_rsp_bits_tgtID),
    .io_out_rx_rsp_bits_srcID (_snLinkMonitor_io_in_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID (_snLinkMonitor_io_in_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode (_snLinkMonitor_io_in_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr (_snLinkMonitor_io_in_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp (_snLinkMonitor_io_in_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_fwdState (_snLinkMonitor_io_in_rx_rsp_bits_fwdState),
    .io_out_rx_rsp_bits_cBusy (_snLinkMonitor_io_in_rx_rsp_bits_cBusy),
    .io_out_rx_rsp_bits_dbID (_snLinkMonitor_io_in_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType (_snLinkMonitor_io_in_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_tagOp (_snLinkMonitor_io_in_rx_rsp_bits_tagOp),
    .io_out_rx_rsp_bits_traceTag (_snLinkMonitor_io_in_rx_rsp_bits_traceTag),
    .io_out_rx_dat_ready (_mmioMerger_io_out_rx_dat_ready),
    .io_out_rx_dat_valid (_snLinkMonitor_io_in_rx_dat_valid),
    .io_out_rx_dat_bits_qos (_snLinkMonitor_io_in_rx_dat_bits_qos),
    .io_out_rx_dat_bits_tgtID (_snLinkMonitor_io_in_rx_dat_bits_tgtID),
    .io_out_rx_dat_bits_srcID (_snLinkMonitor_io_in_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID (_snLinkMonitor_io_in_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID (_snLinkMonitor_io_in_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode (_snLinkMonitor_io_in_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr (_snLinkMonitor_io_in_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp (_snLinkMonitor_io_in_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataSource (_snLinkMonitor_io_in_rx_dat_bits_dataSource),
    .io_out_rx_dat_bits_cBusy (_snLinkMonitor_io_in_rx_dat_bits_cBusy),
    .io_out_rx_dat_bits_dbID (_snLinkMonitor_io_in_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_ccID (_snLinkMonitor_io_in_rx_dat_bits_ccID),
    .io_out_rx_dat_bits_dataID (_snLinkMonitor_io_in_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_tagOp (_snLinkMonitor_io_in_rx_dat_bits_tagOp),
    .io_out_rx_dat_bits_tag (_snLinkMonitor_io_in_rx_dat_bits_tag),
    .io_out_rx_dat_bits_tu (_snLinkMonitor_io_in_rx_dat_bits_tu),
    .io_out_rx_dat_bits_traceTag (_snLinkMonitor_io_in_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_rsvdc (_snLinkMonitor_io_in_rx_dat_bits_rsvdc),
    .io_out_rx_dat_bits_be (_snLinkMonitor_io_in_rx_dat_bits_be),
    .io_out_rx_dat_bits_data (_snLinkMonitor_io_in_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck (_snLinkMonitor_io_in_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison (_snLinkMonitor_io_in_rx_dat_bits_poison)
  );
// ---- §6 CHI 交叉开关例化（rnXbar / snXbar） --------------------
  RNXbar rnXbar (
    .clock (clock),
    .reset (reset),
    .io_in_0_tx_req_ready (_rnXbar_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid (_mmioDiverger_io_out_cache_0_tx_req_valid),
    .io_in_0_tx_req_bits_qos (_mmioDiverger_io_out_cache_0_tx_req_bits_qos),
    .io_in_0_tx_req_bits_tgtID (_mmioDiverger_io_out_cache_0_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID (_mmioDiverger_io_out_cache_0_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID (_mmioDiverger_io_out_cache_0_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_returnNID (_mmioDiverger_io_out_cache_0_tx_req_bits_returnNID),
    .io_in_0_tx_req_bits_stashNIDValid (_mmioDiverger_io_out_cache_0_tx_req_bits_stashNIDValid),
    .io_in_0_tx_req_bits_returnTxnID (_mmioDiverger_io_out_cache_0_tx_req_bits_returnTxnID),
    .io_in_0_tx_req_bits_opcode (_mmioDiverger_io_out_cache_0_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size (_mmioDiverger_io_out_cache_0_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr (_mmioDiverger_io_out_cache_0_tx_req_bits_addr),
    .io_in_0_tx_req_bits_ns (_mmioDiverger_io_out_cache_0_tx_req_bits_ns),
    .io_in_0_tx_req_bits_likelyshared (_mmioDiverger_io_out_cache_0_tx_req_bits_likelyshared),
    .io_in_0_tx_req_bits_allowRetry (_mmioDiverger_io_out_cache_0_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order (_mmioDiverger_io_out_cache_0_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType (_mmioDiverger_io_out_cache_0_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa (_mmioDiverger_io_out_cache_0_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr (_mmioDiverger_io_out_cache_0_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_lpIDWithPadding (_mmioDiverger_io_out_cache_0_tx_req_bits_lpIDWithPadding),
    .io_in_0_tx_req_bits_snoopMe (_mmioDiverger_io_out_cache_0_tx_req_bits_snoopMe),
    .io_in_0_tx_req_bits_expCompAck (_mmioDiverger_io_out_cache_0_tx_req_bits_expCompAck),
    .io_in_0_tx_req_bits_tagOp (_mmioDiverger_io_out_cache_0_tx_req_bits_tagOp),
    .io_in_0_tx_req_bits_traceTag (_mmioDiverger_io_out_cache_0_tx_req_bits_traceTag),
    .io_in_0_tx_req_bits_mpam_perfMonGroup (_mmioDiverger_io_out_cache_0_tx_req_bits_mpam_perfMonGroup),
    .io_in_0_tx_req_bits_mpam_partID (_mmioDiverger_io_out_cache_0_tx_req_bits_mpam_partID),
    .io_in_0_tx_req_bits_mpam_mpamNS (_mmioDiverger_io_out_cache_0_tx_req_bits_mpam_mpamNS),
    .io_in_0_tx_req_bits_rsvdc (_mmioDiverger_io_out_cache_0_tx_req_bits_rsvdc),
    .io_in_0_tx_rsp_ready (_rnXbar_io_in_0_tx_rsp_ready),
    .io_in_0_tx_rsp_valid (_mmioDiverger_io_out_cache_0_tx_rsp_valid),
    .io_in_0_tx_rsp_bits_srcID (_mmioDiverger_io_out_cache_0_tx_rsp_bits_srcID),
    .io_in_0_tx_rsp_bits_txnID (_mmioDiverger_io_out_cache_0_tx_rsp_bits_txnID),
    .io_in_0_tx_rsp_bits_opcode (_mmioDiverger_io_out_cache_0_tx_rsp_bits_opcode),
    .io_in_0_tx_rsp_bits_dbID (_mmioDiverger_io_out_cache_0_tx_rsp_bits_dbID),
    .io_in_0_tx_dat_ready (_rnXbar_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid (_mmioDiverger_io_out_cache_0_tx_dat_valid),
    .io_in_0_tx_dat_bits_qos (_mmioDiverger_io_out_cache_0_tx_dat_bits_qos),
    .io_in_0_tx_dat_bits_tgtID (_mmioDiverger_io_out_cache_0_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID (_mmioDiverger_io_out_cache_0_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID (_mmioDiverger_io_out_cache_0_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID (_mmioDiverger_io_out_cache_0_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode (_mmioDiverger_io_out_cache_0_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_respErr (_mmioDiverger_io_out_cache_0_tx_dat_bits_respErr),
    .io_in_0_tx_dat_bits_resp (_mmioDiverger_io_out_cache_0_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource (_mmioDiverger_io_out_cache_0_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_cBusy (_mmioDiverger_io_out_cache_0_tx_dat_bits_cBusy),
    .io_in_0_tx_dat_bits_dbID (_mmioDiverger_io_out_cache_0_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_ccID (_mmioDiverger_io_out_cache_0_tx_dat_bits_ccID),
    .io_in_0_tx_dat_bits_dataID (_mmioDiverger_io_out_cache_0_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_tagOp (_mmioDiverger_io_out_cache_0_tx_dat_bits_tagOp),
    .io_in_0_tx_dat_bits_tag (_mmioDiverger_io_out_cache_0_tx_dat_bits_tag),
    .io_in_0_tx_dat_bits_tu (_mmioDiverger_io_out_cache_0_tx_dat_bits_tu),
    .io_in_0_tx_dat_bits_traceTag (_mmioDiverger_io_out_cache_0_tx_dat_bits_traceTag),
    .io_in_0_tx_dat_bits_rsvdc (_mmioDiverger_io_out_cache_0_tx_dat_bits_rsvdc),
    .io_in_0_tx_dat_bits_be (_mmioDiverger_io_out_cache_0_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data (_mmioDiverger_io_out_cache_0_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck (_mmioDiverger_io_out_cache_0_tx_dat_bits_dataCheck),
    .io_in_0_tx_dat_bits_poison (_mmioDiverger_io_out_cache_0_tx_dat_bits_poison),
    .io_in_0_rx_rsp_ready (_mmioDiverger_io_out_cache_0_rx_rsp_ready),
    .io_in_0_rx_rsp_valid (_rnXbar_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_qos (_rnXbar_io_in_0_rx_rsp_bits_qos),
    .io_in_0_rx_rsp_bits_txnID (_rnXbar_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode (_rnXbar_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_respErr (_rnXbar_io_in_0_rx_rsp_bits_respErr),
    .io_in_0_rx_rsp_bits_resp (_rnXbar_io_in_0_rx_rsp_bits_resp),
    .io_in_0_rx_rsp_bits_fwdState (_rnXbar_io_in_0_rx_rsp_bits_fwdState),
    .io_in_0_rx_rsp_bits_cBusy (_rnXbar_io_in_0_rx_rsp_bits_cBusy),
    .io_in_0_rx_rsp_bits_dbID (_rnXbar_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_rsp_bits_pCrdType (_rnXbar_io_in_0_rx_rsp_bits_pCrdType),
    .io_in_0_rx_rsp_bits_tagOp (_rnXbar_io_in_0_rx_rsp_bits_tagOp),
    .io_in_0_rx_rsp_bits_traceTag (_rnXbar_io_in_0_rx_rsp_bits_traceTag),
    .io_in_0_rx_dat_ready (_mmioDiverger_io_out_cache_0_rx_dat_ready),
    .io_in_0_rx_dat_valid (_rnXbar_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_txnID (_rnXbar_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_homeNID (_rnXbar_io_in_0_rx_dat_bits_homeNID),
    .io_in_0_rx_dat_bits_opcode (_rnXbar_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_resp (_rnXbar_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataSource (_rnXbar_io_in_0_rx_dat_bits_dataSource),
    .io_in_0_rx_dat_bits_dbID (_rnXbar_io_in_0_rx_dat_bits_dbID),
    .io_in_0_rx_dat_bits_dataID (_rnXbar_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_be (_rnXbar_io_in_0_rx_dat_bits_be),
    .io_in_0_rx_dat_bits_data (_rnXbar_io_in_0_rx_dat_bits_data),
    .io_in_0_rx_dat_bits_dataCheck (_rnXbar_io_in_0_rx_dat_bits_dataCheck),
    .io_in_0_rx_snp_ready (_mmioDiverger_io_out_cache_0_rx_snp_ready),
    .io_in_0_rx_snp_valid (_rnXbar_io_in_0_rx_snp_valid),
    .io_in_0_rx_snp_bits_txnID (_rnXbar_io_in_0_rx_snp_bits_txnID),
    .io_in_0_rx_snp_bits_fwdNID (_rnXbar_io_in_0_rx_snp_bits_fwdNID),
    .io_in_0_rx_snp_bits_fwdTxnID (_rnXbar_io_in_0_rx_snp_bits_fwdTxnID),
    .io_in_0_rx_snp_bits_opcode (_rnXbar_io_in_0_rx_snp_bits_opcode),
    .io_in_0_rx_snp_bits_addr (_rnXbar_io_in_0_rx_snp_bits_addr),
    .io_in_0_rx_snp_bits_doNotGoToSD (_rnXbar_io_in_0_rx_snp_bits_doNotGoToSD),
    .io_in_0_rx_snp_bits_retToSrc (_rnXbar_io_in_0_rx_snp_bits_retToSrc),
    .io_out_0_tx_req_ready (_slices_0_io_in_tx_req_ready),
    .io_out_0_tx_req_valid (_rnXbar_io_out_0_tx_req_valid),
    .io_out_0_tx_req_bits_tgtID (_rnXbar_io_out_0_tx_req_bits_tgtID),
    .io_out_0_tx_req_bits_srcID (_rnXbar_io_out_0_tx_req_bits_srcID),
    .io_out_0_tx_req_bits_txnID (_rnXbar_io_out_0_tx_req_bits_txnID),
    .io_out_0_tx_req_bits_opcode (_rnXbar_io_out_0_tx_req_bits_opcode),
    .io_out_0_tx_req_bits_size (_rnXbar_io_out_0_tx_req_bits_size),
    .io_out_0_tx_req_bits_addr (_rnXbar_io_out_0_tx_req_bits_addr),
    .io_out_0_tx_req_bits_allowRetry (_rnXbar_io_out_0_tx_req_bits_allowRetry),
    .io_out_0_tx_req_bits_order (_rnXbar_io_out_0_tx_req_bits_order),
    .io_out_0_tx_req_bits_pCrdType (_rnXbar_io_out_0_tx_req_bits_pCrdType),
    .io_out_0_tx_req_bits_memAttr_allocate (_rnXbar_io_out_0_tx_req_bits_memAttr_allocate),
    .io_out_0_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_0_tx_req_bits_memAttr_cacheable),
    .io_out_0_tx_req_bits_memAttr_device (_rnXbar_io_out_0_tx_req_bits_memAttr_device),
    .io_out_0_tx_req_bits_memAttr_ewa (_rnXbar_io_out_0_tx_req_bits_memAttr_ewa),
    .io_out_0_tx_req_bits_snpAttr (_rnXbar_io_out_0_tx_req_bits_snpAttr),
    .io_out_0_tx_req_bits_expCompAck (_rnXbar_io_out_0_tx_req_bits_expCompAck),
    .io_out_0_tx_rsp_valid (_rnXbar_io_out_0_tx_rsp_valid),
    .io_out_0_tx_rsp_bits_srcID (_rnXbar_io_out_0_tx_rsp_bits_srcID),
    .io_out_0_tx_rsp_bits_txnID (_rnXbar_io_out_0_tx_rsp_bits_txnID),
    .io_out_0_tx_rsp_bits_opcode (_rnXbar_io_out_0_tx_rsp_bits_opcode),
    .io_out_0_tx_rsp_bits_dbID (_rnXbar_io_out_0_tx_rsp_bits_dbID),
    .io_out_0_tx_dat_valid (_rnXbar_io_out_0_tx_dat_valid),
    .io_out_0_tx_dat_bits_srcID (_rnXbar_io_out_0_tx_dat_bits_srcID),
    .io_out_0_tx_dat_bits_txnID (_rnXbar_io_out_0_tx_dat_bits_txnID),
    .io_out_0_tx_dat_bits_opcode (_rnXbar_io_out_0_tx_dat_bits_opcode),
    .io_out_0_tx_dat_bits_resp (_rnXbar_io_out_0_tx_dat_bits_resp),
    .io_out_0_tx_dat_bits_dataID (_rnXbar_io_out_0_tx_dat_bits_dataID),
    .io_out_0_tx_dat_bits_data (_rnXbar_io_out_0_tx_dat_bits_data),
    .io_out_0_rx_rsp_ready (_rnXbar_io_out_0_rx_rsp_ready),
    .io_out_0_rx_rsp_valid (_slices_0_io_in_rx_rsp_valid),
    .io_out_0_rx_rsp_bits_tgtID (_slices_0_io_in_rx_rsp_bits_tgtID),
    .io_out_0_rx_rsp_bits_srcID (_slices_0_io_in_rx_rsp_bits_srcID),
    .io_out_0_rx_rsp_bits_txnID (_slices_0_io_in_rx_rsp_bits_txnID),
    .io_out_0_rx_rsp_bits_opcode (_slices_0_io_in_rx_rsp_bits_opcode),
    .io_out_0_rx_rsp_bits_resp (_slices_0_io_in_rx_rsp_bits_resp),
    .io_out_0_rx_rsp_bits_fwdState (_slices_0_io_in_rx_rsp_bits_fwdState),
    .io_out_0_rx_rsp_bits_dbID (_slices_0_io_in_rx_rsp_bits_dbID),
    .io_out_0_rx_rsp_bits_pCrdType (_slices_0_io_in_rx_rsp_bits_pCrdType),
    .io_out_0_rx_dat_ready (_rnXbar_io_out_0_rx_dat_ready),
    .io_out_0_rx_dat_valid (_slices_0_io_in_rx_dat_valid),
    .io_out_0_rx_dat_bits_tgtID (_slices_0_io_in_rx_dat_bits_tgtID),
    .io_out_0_rx_dat_bits_srcID (_slices_0_io_in_rx_dat_bits_srcID),
    .io_out_0_rx_dat_bits_txnID (_slices_0_io_in_rx_dat_bits_txnID),
    .io_out_0_rx_dat_bits_homeNID (_slices_0_io_in_rx_dat_bits_homeNID),
    .io_out_0_rx_dat_bits_opcode (_slices_0_io_in_rx_dat_bits_opcode),
    .io_out_0_rx_dat_bits_resp (_slices_0_io_in_rx_dat_bits_resp),
    .io_out_0_rx_dat_bits_dataSource (_slices_0_io_in_rx_dat_bits_dataSource),
    .io_out_0_rx_dat_bits_dbID (_slices_0_io_in_rx_dat_bits_dbID),
    .io_out_0_rx_dat_bits_dataID (_slices_0_io_in_rx_dat_bits_dataID),
    .io_out_0_rx_dat_bits_be (_slices_0_io_in_rx_dat_bits_be),
    .io_out_0_rx_dat_bits_data (_slices_0_io_in_rx_dat_bits_data),
    .io_out_0_rx_dat_bits_dataCheck (_slices_0_io_in_rx_dat_bits_dataCheck),
    .io_out_0_rx_snp_ready (_rnXbar_io_out_0_rx_snp_ready),
    .io_out_0_rx_snp_valid (_slices_0_io_in_rx_snp_valid),
    .io_out_0_rx_snp_bits_txnID (_slices_0_io_in_rx_snp_bits_txnID),
    .io_out_0_rx_snp_bits_fwdNID (_slices_0_io_in_rx_snp_bits_fwdNID),
    .io_out_0_rx_snp_bits_fwdTxnID (_slices_0_io_in_rx_snp_bits_fwdTxnID),
    .io_out_0_rx_snp_bits_opcode (_slices_0_io_in_rx_snp_bits_opcode),
    .io_out_0_rx_snp_bits_addr (_slices_0_io_in_rx_snp_bits_addr),
    .io_out_0_rx_snp_bits_doNotGoToSD (_slices_0_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_0_rx_snp_bits_retToSrc (_slices_0_io_in_rx_snp_bits_retToSrc),
    .io_out_1_tx_req_ready (_slices_1_io_in_tx_req_ready),
    .io_out_1_tx_req_valid (_rnXbar_io_out_1_tx_req_valid),
    .io_out_1_tx_req_bits_tgtID (_rnXbar_io_out_1_tx_req_bits_tgtID),
    .io_out_1_tx_req_bits_srcID (_rnXbar_io_out_1_tx_req_bits_srcID),
    .io_out_1_tx_req_bits_txnID (_rnXbar_io_out_1_tx_req_bits_txnID),
    .io_out_1_tx_req_bits_opcode (_rnXbar_io_out_1_tx_req_bits_opcode),
    .io_out_1_tx_req_bits_size (_rnXbar_io_out_1_tx_req_bits_size),
    .io_out_1_tx_req_bits_addr (_rnXbar_io_out_1_tx_req_bits_addr),
    .io_out_1_tx_req_bits_allowRetry (_rnXbar_io_out_1_tx_req_bits_allowRetry),
    .io_out_1_tx_req_bits_order (_rnXbar_io_out_1_tx_req_bits_order),
    .io_out_1_tx_req_bits_pCrdType (_rnXbar_io_out_1_tx_req_bits_pCrdType),
    .io_out_1_tx_req_bits_memAttr_allocate (_rnXbar_io_out_1_tx_req_bits_memAttr_allocate),
    .io_out_1_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_1_tx_req_bits_memAttr_cacheable),
    .io_out_1_tx_req_bits_memAttr_device (_rnXbar_io_out_1_tx_req_bits_memAttr_device),
    .io_out_1_tx_req_bits_memAttr_ewa (_rnXbar_io_out_1_tx_req_bits_memAttr_ewa),
    .io_out_1_tx_req_bits_snpAttr (_rnXbar_io_out_1_tx_req_bits_snpAttr),
    .io_out_1_tx_req_bits_expCompAck (_rnXbar_io_out_1_tx_req_bits_expCompAck),
    .io_out_1_tx_rsp_valid (_rnXbar_io_out_1_tx_rsp_valid),
    .io_out_1_tx_rsp_bits_srcID (_rnXbar_io_out_1_tx_rsp_bits_srcID),
    .io_out_1_tx_rsp_bits_txnID (_rnXbar_io_out_1_tx_rsp_bits_txnID),
    .io_out_1_tx_rsp_bits_opcode (_rnXbar_io_out_1_tx_rsp_bits_opcode),
    .io_out_1_tx_rsp_bits_dbID (_rnXbar_io_out_1_tx_rsp_bits_dbID),
    .io_out_1_tx_dat_valid (_rnXbar_io_out_1_tx_dat_valid),
    .io_out_1_tx_dat_bits_srcID (_rnXbar_io_out_1_tx_dat_bits_srcID),
    .io_out_1_tx_dat_bits_txnID (_rnXbar_io_out_1_tx_dat_bits_txnID),
    .io_out_1_tx_dat_bits_opcode (_rnXbar_io_out_1_tx_dat_bits_opcode),
    .io_out_1_tx_dat_bits_resp (_rnXbar_io_out_1_tx_dat_bits_resp),
    .io_out_1_tx_dat_bits_dataID (_rnXbar_io_out_1_tx_dat_bits_dataID),
    .io_out_1_tx_dat_bits_data (_rnXbar_io_out_1_tx_dat_bits_data),
    .io_out_1_rx_rsp_ready (_rnXbar_io_out_1_rx_rsp_ready),
    .io_out_1_rx_rsp_valid (_slices_1_io_in_rx_rsp_valid),
    .io_out_1_rx_rsp_bits_tgtID (_slices_1_io_in_rx_rsp_bits_tgtID),
    .io_out_1_rx_rsp_bits_srcID (_slices_1_io_in_rx_rsp_bits_srcID),
    .io_out_1_rx_rsp_bits_txnID (_slices_1_io_in_rx_rsp_bits_txnID),
    .io_out_1_rx_rsp_bits_opcode (_slices_1_io_in_rx_rsp_bits_opcode),
    .io_out_1_rx_rsp_bits_resp (_slices_1_io_in_rx_rsp_bits_resp),
    .io_out_1_rx_rsp_bits_fwdState (_slices_1_io_in_rx_rsp_bits_fwdState),
    .io_out_1_rx_rsp_bits_dbID (_slices_1_io_in_rx_rsp_bits_dbID),
    .io_out_1_rx_rsp_bits_pCrdType (_slices_1_io_in_rx_rsp_bits_pCrdType),
    .io_out_1_rx_dat_ready (_rnXbar_io_out_1_rx_dat_ready),
    .io_out_1_rx_dat_valid (_slices_1_io_in_rx_dat_valid),
    .io_out_1_rx_dat_bits_tgtID (_slices_1_io_in_rx_dat_bits_tgtID),
    .io_out_1_rx_dat_bits_srcID (_slices_1_io_in_rx_dat_bits_srcID),
    .io_out_1_rx_dat_bits_txnID (_slices_1_io_in_rx_dat_bits_txnID),
    .io_out_1_rx_dat_bits_homeNID (_slices_1_io_in_rx_dat_bits_homeNID),
    .io_out_1_rx_dat_bits_opcode (_slices_1_io_in_rx_dat_bits_opcode),
    .io_out_1_rx_dat_bits_resp (_slices_1_io_in_rx_dat_bits_resp),
    .io_out_1_rx_dat_bits_dataSource (_slices_1_io_in_rx_dat_bits_dataSource),
    .io_out_1_rx_dat_bits_dbID (_slices_1_io_in_rx_dat_bits_dbID),
    .io_out_1_rx_dat_bits_dataID (_slices_1_io_in_rx_dat_bits_dataID),
    .io_out_1_rx_dat_bits_be (_slices_1_io_in_rx_dat_bits_be),
    .io_out_1_rx_dat_bits_data (_slices_1_io_in_rx_dat_bits_data),
    .io_out_1_rx_dat_bits_dataCheck (_slices_1_io_in_rx_dat_bits_dataCheck),
    .io_out_1_rx_snp_ready (_rnXbar_io_out_1_rx_snp_ready),
    .io_out_1_rx_snp_valid (_slices_1_io_in_rx_snp_valid),
    .io_out_1_rx_snp_bits_txnID (_slices_1_io_in_rx_snp_bits_txnID),
    .io_out_1_rx_snp_bits_fwdNID (_slices_1_io_in_rx_snp_bits_fwdNID),
    .io_out_1_rx_snp_bits_fwdTxnID (_slices_1_io_in_rx_snp_bits_fwdTxnID),
    .io_out_1_rx_snp_bits_opcode (_slices_1_io_in_rx_snp_bits_opcode),
    .io_out_1_rx_snp_bits_addr (_slices_1_io_in_rx_snp_bits_addr),
    .io_out_1_rx_snp_bits_doNotGoToSD (_slices_1_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_1_rx_snp_bits_retToSrc (_slices_1_io_in_rx_snp_bits_retToSrc),
    .io_out_2_tx_req_ready (_slices_2_io_in_tx_req_ready),
    .io_out_2_tx_req_valid (_rnXbar_io_out_2_tx_req_valid),
    .io_out_2_tx_req_bits_tgtID (_rnXbar_io_out_2_tx_req_bits_tgtID),
    .io_out_2_tx_req_bits_srcID (_rnXbar_io_out_2_tx_req_bits_srcID),
    .io_out_2_tx_req_bits_txnID (_rnXbar_io_out_2_tx_req_bits_txnID),
    .io_out_2_tx_req_bits_opcode (_rnXbar_io_out_2_tx_req_bits_opcode),
    .io_out_2_tx_req_bits_size (_rnXbar_io_out_2_tx_req_bits_size),
    .io_out_2_tx_req_bits_addr (_rnXbar_io_out_2_tx_req_bits_addr),
    .io_out_2_tx_req_bits_allowRetry (_rnXbar_io_out_2_tx_req_bits_allowRetry),
    .io_out_2_tx_req_bits_order (_rnXbar_io_out_2_tx_req_bits_order),
    .io_out_2_tx_req_bits_pCrdType (_rnXbar_io_out_2_tx_req_bits_pCrdType),
    .io_out_2_tx_req_bits_memAttr_allocate (_rnXbar_io_out_2_tx_req_bits_memAttr_allocate),
    .io_out_2_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_2_tx_req_bits_memAttr_cacheable),
    .io_out_2_tx_req_bits_memAttr_device (_rnXbar_io_out_2_tx_req_bits_memAttr_device),
    .io_out_2_tx_req_bits_memAttr_ewa (_rnXbar_io_out_2_tx_req_bits_memAttr_ewa),
    .io_out_2_tx_req_bits_snpAttr (_rnXbar_io_out_2_tx_req_bits_snpAttr),
    .io_out_2_tx_req_bits_expCompAck (_rnXbar_io_out_2_tx_req_bits_expCompAck),
    .io_out_2_tx_rsp_valid (_rnXbar_io_out_2_tx_rsp_valid),
    .io_out_2_tx_rsp_bits_srcID (_rnXbar_io_out_2_tx_rsp_bits_srcID),
    .io_out_2_tx_rsp_bits_txnID (_rnXbar_io_out_2_tx_rsp_bits_txnID),
    .io_out_2_tx_rsp_bits_opcode (_rnXbar_io_out_2_tx_rsp_bits_opcode),
    .io_out_2_tx_rsp_bits_dbID (_rnXbar_io_out_2_tx_rsp_bits_dbID),
    .io_out_2_tx_dat_valid (_rnXbar_io_out_2_tx_dat_valid),
    .io_out_2_tx_dat_bits_srcID (_rnXbar_io_out_2_tx_dat_bits_srcID),
    .io_out_2_tx_dat_bits_txnID (_rnXbar_io_out_2_tx_dat_bits_txnID),
    .io_out_2_tx_dat_bits_opcode (_rnXbar_io_out_2_tx_dat_bits_opcode),
    .io_out_2_tx_dat_bits_resp (_rnXbar_io_out_2_tx_dat_bits_resp),
    .io_out_2_tx_dat_bits_dataID (_rnXbar_io_out_2_tx_dat_bits_dataID),
    .io_out_2_tx_dat_bits_data (_rnXbar_io_out_2_tx_dat_bits_data),
    .io_out_2_rx_rsp_ready (_rnXbar_io_out_2_rx_rsp_ready),
    .io_out_2_rx_rsp_valid (_slices_2_io_in_rx_rsp_valid),
    .io_out_2_rx_rsp_bits_tgtID (_slices_2_io_in_rx_rsp_bits_tgtID),
    .io_out_2_rx_rsp_bits_srcID (_slices_2_io_in_rx_rsp_bits_srcID),
    .io_out_2_rx_rsp_bits_txnID (_slices_2_io_in_rx_rsp_bits_txnID),
    .io_out_2_rx_rsp_bits_opcode (_slices_2_io_in_rx_rsp_bits_opcode),
    .io_out_2_rx_rsp_bits_resp (_slices_2_io_in_rx_rsp_bits_resp),
    .io_out_2_rx_rsp_bits_fwdState (_slices_2_io_in_rx_rsp_bits_fwdState),
    .io_out_2_rx_rsp_bits_dbID (_slices_2_io_in_rx_rsp_bits_dbID),
    .io_out_2_rx_rsp_bits_pCrdType (_slices_2_io_in_rx_rsp_bits_pCrdType),
    .io_out_2_rx_dat_ready (_rnXbar_io_out_2_rx_dat_ready),
    .io_out_2_rx_dat_valid (_slices_2_io_in_rx_dat_valid),
    .io_out_2_rx_dat_bits_tgtID (_slices_2_io_in_rx_dat_bits_tgtID),
    .io_out_2_rx_dat_bits_srcID (_slices_2_io_in_rx_dat_bits_srcID),
    .io_out_2_rx_dat_bits_txnID (_slices_2_io_in_rx_dat_bits_txnID),
    .io_out_2_rx_dat_bits_homeNID (_slices_2_io_in_rx_dat_bits_homeNID),
    .io_out_2_rx_dat_bits_opcode (_slices_2_io_in_rx_dat_bits_opcode),
    .io_out_2_rx_dat_bits_resp (_slices_2_io_in_rx_dat_bits_resp),
    .io_out_2_rx_dat_bits_dataSource (_slices_2_io_in_rx_dat_bits_dataSource),
    .io_out_2_rx_dat_bits_dbID (_slices_2_io_in_rx_dat_bits_dbID),
    .io_out_2_rx_dat_bits_dataID (_slices_2_io_in_rx_dat_bits_dataID),
    .io_out_2_rx_dat_bits_be (_slices_2_io_in_rx_dat_bits_be),
    .io_out_2_rx_dat_bits_data (_slices_2_io_in_rx_dat_bits_data),
    .io_out_2_rx_dat_bits_dataCheck (_slices_2_io_in_rx_dat_bits_dataCheck),
    .io_out_2_rx_snp_ready (_rnXbar_io_out_2_rx_snp_ready),
    .io_out_2_rx_snp_valid (_slices_2_io_in_rx_snp_valid),
    .io_out_2_rx_snp_bits_txnID (_slices_2_io_in_rx_snp_bits_txnID),
    .io_out_2_rx_snp_bits_fwdNID (_slices_2_io_in_rx_snp_bits_fwdNID),
    .io_out_2_rx_snp_bits_fwdTxnID (_slices_2_io_in_rx_snp_bits_fwdTxnID),
    .io_out_2_rx_snp_bits_opcode (_slices_2_io_in_rx_snp_bits_opcode),
    .io_out_2_rx_snp_bits_addr (_slices_2_io_in_rx_snp_bits_addr),
    .io_out_2_rx_snp_bits_doNotGoToSD (_slices_2_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_2_rx_snp_bits_retToSrc (_slices_2_io_in_rx_snp_bits_retToSrc),
    .io_out_3_tx_req_ready (_slices_3_io_in_tx_req_ready),
    .io_out_3_tx_req_valid (_rnXbar_io_out_3_tx_req_valid),
    .io_out_3_tx_req_bits_tgtID (_rnXbar_io_out_3_tx_req_bits_tgtID),
    .io_out_3_tx_req_bits_srcID (_rnXbar_io_out_3_tx_req_bits_srcID),
    .io_out_3_tx_req_bits_txnID (_rnXbar_io_out_3_tx_req_bits_txnID),
    .io_out_3_tx_req_bits_opcode (_rnXbar_io_out_3_tx_req_bits_opcode),
    .io_out_3_tx_req_bits_size (_rnXbar_io_out_3_tx_req_bits_size),
    .io_out_3_tx_req_bits_addr (_rnXbar_io_out_3_tx_req_bits_addr),
    .io_out_3_tx_req_bits_allowRetry (_rnXbar_io_out_3_tx_req_bits_allowRetry),
    .io_out_3_tx_req_bits_order (_rnXbar_io_out_3_tx_req_bits_order),
    .io_out_3_tx_req_bits_pCrdType (_rnXbar_io_out_3_tx_req_bits_pCrdType),
    .io_out_3_tx_req_bits_memAttr_allocate (_rnXbar_io_out_3_tx_req_bits_memAttr_allocate),
    .io_out_3_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_3_tx_req_bits_memAttr_cacheable),
    .io_out_3_tx_req_bits_memAttr_device (_rnXbar_io_out_3_tx_req_bits_memAttr_device),
    .io_out_3_tx_req_bits_memAttr_ewa (_rnXbar_io_out_3_tx_req_bits_memAttr_ewa),
    .io_out_3_tx_req_bits_snpAttr (_rnXbar_io_out_3_tx_req_bits_snpAttr),
    .io_out_3_tx_req_bits_expCompAck (_rnXbar_io_out_3_tx_req_bits_expCompAck),
    .io_out_3_tx_rsp_valid (_rnXbar_io_out_3_tx_rsp_valid),
    .io_out_3_tx_rsp_bits_srcID (_rnXbar_io_out_3_tx_rsp_bits_srcID),
    .io_out_3_tx_rsp_bits_txnID (_rnXbar_io_out_3_tx_rsp_bits_txnID),
    .io_out_3_tx_rsp_bits_opcode (_rnXbar_io_out_3_tx_rsp_bits_opcode),
    .io_out_3_tx_rsp_bits_dbID (_rnXbar_io_out_3_tx_rsp_bits_dbID),
    .io_out_3_tx_dat_valid (_rnXbar_io_out_3_tx_dat_valid),
    .io_out_3_tx_dat_bits_srcID (_rnXbar_io_out_3_tx_dat_bits_srcID),
    .io_out_3_tx_dat_bits_txnID (_rnXbar_io_out_3_tx_dat_bits_txnID),
    .io_out_3_tx_dat_bits_opcode (_rnXbar_io_out_3_tx_dat_bits_opcode),
    .io_out_3_tx_dat_bits_resp (_rnXbar_io_out_3_tx_dat_bits_resp),
    .io_out_3_tx_dat_bits_dataID (_rnXbar_io_out_3_tx_dat_bits_dataID),
    .io_out_3_tx_dat_bits_data (_rnXbar_io_out_3_tx_dat_bits_data),
    .io_out_3_rx_rsp_ready (_rnXbar_io_out_3_rx_rsp_ready),
    .io_out_3_rx_rsp_valid (_slices_3_io_in_rx_rsp_valid),
    .io_out_3_rx_rsp_bits_tgtID (_slices_3_io_in_rx_rsp_bits_tgtID),
    .io_out_3_rx_rsp_bits_srcID (_slices_3_io_in_rx_rsp_bits_srcID),
    .io_out_3_rx_rsp_bits_txnID (_slices_3_io_in_rx_rsp_bits_txnID),
    .io_out_3_rx_rsp_bits_opcode (_slices_3_io_in_rx_rsp_bits_opcode),
    .io_out_3_rx_rsp_bits_resp (_slices_3_io_in_rx_rsp_bits_resp),
    .io_out_3_rx_rsp_bits_fwdState (_slices_3_io_in_rx_rsp_bits_fwdState),
    .io_out_3_rx_rsp_bits_dbID (_slices_3_io_in_rx_rsp_bits_dbID),
    .io_out_3_rx_rsp_bits_pCrdType (_slices_3_io_in_rx_rsp_bits_pCrdType),
    .io_out_3_rx_dat_ready (_rnXbar_io_out_3_rx_dat_ready),
    .io_out_3_rx_dat_valid (_slices_3_io_in_rx_dat_valid),
    .io_out_3_rx_dat_bits_tgtID (_slices_3_io_in_rx_dat_bits_tgtID),
    .io_out_3_rx_dat_bits_srcID (_slices_3_io_in_rx_dat_bits_srcID),
    .io_out_3_rx_dat_bits_txnID (_slices_3_io_in_rx_dat_bits_txnID),
    .io_out_3_rx_dat_bits_homeNID (_slices_3_io_in_rx_dat_bits_homeNID),
    .io_out_3_rx_dat_bits_opcode (_slices_3_io_in_rx_dat_bits_opcode),
    .io_out_3_rx_dat_bits_resp (_slices_3_io_in_rx_dat_bits_resp),
    .io_out_3_rx_dat_bits_dataSource (_slices_3_io_in_rx_dat_bits_dataSource),
    .io_out_3_rx_dat_bits_dbID (_slices_3_io_in_rx_dat_bits_dbID),
    .io_out_3_rx_dat_bits_dataID (_slices_3_io_in_rx_dat_bits_dataID),
    .io_out_3_rx_dat_bits_be (_slices_3_io_in_rx_dat_bits_be),
    .io_out_3_rx_dat_bits_data (_slices_3_io_in_rx_dat_bits_data),
    .io_out_3_rx_dat_bits_dataCheck (_slices_3_io_in_rx_dat_bits_dataCheck),
    .io_out_3_rx_snp_ready (_rnXbar_io_out_3_rx_snp_ready),
    .io_out_3_rx_snp_valid (_slices_3_io_in_rx_snp_valid),
    .io_out_3_rx_snp_bits_txnID (_slices_3_io_in_rx_snp_bits_txnID),
    .io_out_3_rx_snp_bits_fwdNID (_slices_3_io_in_rx_snp_bits_fwdNID),
    .io_out_3_rx_snp_bits_fwdTxnID (_slices_3_io_in_rx_snp_bits_fwdTxnID),
    .io_out_3_rx_snp_bits_opcode (_slices_3_io_in_rx_snp_bits_opcode),
    .io_out_3_rx_snp_bits_addr (_slices_3_io_in_rx_snp_bits_addr),
    .io_out_3_rx_snp_bits_doNotGoToSD (_slices_3_io_in_rx_snp_bits_doNotGoToSD),
    .io_out_3_rx_snp_bits_retToSrc (_slices_3_io_in_rx_snp_bits_retToSrc),
    .io_snpMasks_0_0 (_slices_0_io_snpMask_0),
    .io_snpMasks_1_0 (_slices_1_io_snpMask_0),
    .io_snpMasks_2_0 (_slices_2_io_snpMask_0),
    .io_snpMasks_3_0 (_slices_3_io_snpMask_0)
  );
  SNXbar snXbar (
    .clock (clock),
    .reset (reset),
    .io_in_0_tx_req_ready (_snXbar_io_in_0_tx_req_ready),
    .io_in_0_tx_req_valid (_slices_0_io_out_tx_req_valid),
    .io_in_0_tx_req_bits_tgtID (_slices_0_io_out_tx_req_bits_tgtID),
    .io_in_0_tx_req_bits_srcID (_slices_0_io_out_tx_req_bits_srcID),
    .io_in_0_tx_req_bits_txnID (_slices_0_io_out_tx_req_bits_txnID),
    .io_in_0_tx_req_bits_opcode (_slices_0_io_out_tx_req_bits_opcode),
    .io_in_0_tx_req_bits_size (_slices_0_io_out_tx_req_bits_size),
    .io_in_0_tx_req_bits_addr (_slices_0_io_out_tx_req_bits_addr),
    .io_in_0_tx_req_bits_allowRetry (_slices_0_io_out_tx_req_bits_allowRetry),
    .io_in_0_tx_req_bits_order (_slices_0_io_out_tx_req_bits_order),
    .io_in_0_tx_req_bits_pCrdType (_slices_0_io_out_tx_req_bits_pCrdType),
    .io_in_0_tx_req_bits_memAttr_allocate (_slices_0_io_out_tx_req_bits_memAttr_allocate),
    .io_in_0_tx_req_bits_memAttr_cacheable (_slices_0_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_0_tx_req_bits_memAttr_device (_slices_0_io_out_tx_req_bits_memAttr_device),
    .io_in_0_tx_req_bits_memAttr_ewa (_slices_0_io_out_tx_req_bits_memAttr_ewa),
    .io_in_0_tx_req_bits_snpAttr (_slices_0_io_out_tx_req_bits_snpAttr),
    .io_in_0_tx_req_bits_expCompAck (_slices_0_io_out_tx_req_bits_expCompAck),
    .io_in_0_tx_dat_ready (_snXbar_io_in_0_tx_dat_ready),
    .io_in_0_tx_dat_valid (_slices_0_io_out_tx_dat_valid),
    .io_in_0_tx_dat_bits_tgtID (_slices_0_io_out_tx_dat_bits_tgtID),
    .io_in_0_tx_dat_bits_srcID (_slices_0_io_out_tx_dat_bits_srcID),
    .io_in_0_tx_dat_bits_txnID (_slices_0_io_out_tx_dat_bits_txnID),
    .io_in_0_tx_dat_bits_homeNID (_slices_0_io_out_tx_dat_bits_homeNID),
    .io_in_0_tx_dat_bits_opcode (_slices_0_io_out_tx_dat_bits_opcode),
    .io_in_0_tx_dat_bits_resp (_slices_0_io_out_tx_dat_bits_resp),
    .io_in_0_tx_dat_bits_dataSource (_slices_0_io_out_tx_dat_bits_dataSource),
    .io_in_0_tx_dat_bits_dbID (_slices_0_io_out_tx_dat_bits_dbID),
    .io_in_0_tx_dat_bits_dataID (_slices_0_io_out_tx_dat_bits_dataID),
    .io_in_0_tx_dat_bits_be (_slices_0_io_out_tx_dat_bits_be),
    .io_in_0_tx_dat_bits_data (_slices_0_io_out_tx_dat_bits_data),
    .io_in_0_tx_dat_bits_dataCheck (_slices_0_io_out_tx_dat_bits_dataCheck),
    .io_in_0_rx_rsp_valid (_snXbar_io_in_0_rx_rsp_valid),
    .io_in_0_rx_rsp_bits_srcID (_snXbar_io_in_0_rx_rsp_bits_srcID),
    .io_in_0_rx_rsp_bits_txnID (_snXbar_io_in_0_rx_rsp_bits_txnID),
    .io_in_0_rx_rsp_bits_opcode (_snXbar_io_in_0_rx_rsp_bits_opcode),
    .io_in_0_rx_rsp_bits_dbID (_snXbar_io_in_0_rx_rsp_bits_dbID),
    .io_in_0_rx_dat_valid (_snXbar_io_in_0_rx_dat_valid),
    .io_in_0_rx_dat_bits_srcID (_snXbar_io_in_0_rx_dat_bits_srcID),
    .io_in_0_rx_dat_bits_txnID (_snXbar_io_in_0_rx_dat_bits_txnID),
    .io_in_0_rx_dat_bits_opcode (_snXbar_io_in_0_rx_dat_bits_opcode),
    .io_in_0_rx_dat_bits_resp (_snXbar_io_in_0_rx_dat_bits_resp),
    .io_in_0_rx_dat_bits_dataID (_snXbar_io_in_0_rx_dat_bits_dataID),
    .io_in_0_rx_dat_bits_data (_snXbar_io_in_0_rx_dat_bits_data),
    .io_in_1_tx_req_ready (_snXbar_io_in_1_tx_req_ready),
    .io_in_1_tx_req_valid (_slices_1_io_out_tx_req_valid),
    .io_in_1_tx_req_bits_tgtID (_slices_1_io_out_tx_req_bits_tgtID),
    .io_in_1_tx_req_bits_srcID (_slices_1_io_out_tx_req_bits_srcID),
    .io_in_1_tx_req_bits_txnID (_slices_1_io_out_tx_req_bits_txnID),
    .io_in_1_tx_req_bits_opcode (_slices_1_io_out_tx_req_bits_opcode),
    .io_in_1_tx_req_bits_size (_slices_1_io_out_tx_req_bits_size),
    .io_in_1_tx_req_bits_addr (_slices_1_io_out_tx_req_bits_addr),
    .io_in_1_tx_req_bits_allowRetry (_slices_1_io_out_tx_req_bits_allowRetry),
    .io_in_1_tx_req_bits_order (_slices_1_io_out_tx_req_bits_order),
    .io_in_1_tx_req_bits_pCrdType (_slices_1_io_out_tx_req_bits_pCrdType),
    .io_in_1_tx_req_bits_memAttr_allocate (_slices_1_io_out_tx_req_bits_memAttr_allocate),
    .io_in_1_tx_req_bits_memAttr_cacheable (_slices_1_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_1_tx_req_bits_memAttr_device (_slices_1_io_out_tx_req_bits_memAttr_device),
    .io_in_1_tx_req_bits_memAttr_ewa (_slices_1_io_out_tx_req_bits_memAttr_ewa),
    .io_in_1_tx_req_bits_snpAttr (_slices_1_io_out_tx_req_bits_snpAttr),
    .io_in_1_tx_req_bits_expCompAck (_slices_1_io_out_tx_req_bits_expCompAck),
    .io_in_1_tx_dat_ready (_snXbar_io_in_1_tx_dat_ready),
    .io_in_1_tx_dat_valid (_slices_1_io_out_tx_dat_valid),
    .io_in_1_tx_dat_bits_tgtID (_slices_1_io_out_tx_dat_bits_tgtID),
    .io_in_1_tx_dat_bits_srcID (_slices_1_io_out_tx_dat_bits_srcID),
    .io_in_1_tx_dat_bits_txnID (_slices_1_io_out_tx_dat_bits_txnID),
    .io_in_1_tx_dat_bits_homeNID (_slices_1_io_out_tx_dat_bits_homeNID),
    .io_in_1_tx_dat_bits_opcode (_slices_1_io_out_tx_dat_bits_opcode),
    .io_in_1_tx_dat_bits_resp (_slices_1_io_out_tx_dat_bits_resp),
    .io_in_1_tx_dat_bits_dataSource (_slices_1_io_out_tx_dat_bits_dataSource),
    .io_in_1_tx_dat_bits_dbID (_slices_1_io_out_tx_dat_bits_dbID),
    .io_in_1_tx_dat_bits_dataID (_slices_1_io_out_tx_dat_bits_dataID),
    .io_in_1_tx_dat_bits_be (_slices_1_io_out_tx_dat_bits_be),
    .io_in_1_tx_dat_bits_data (_slices_1_io_out_tx_dat_bits_data),
    .io_in_1_tx_dat_bits_dataCheck (_slices_1_io_out_tx_dat_bits_dataCheck),
    .io_in_1_rx_rsp_valid (_snXbar_io_in_1_rx_rsp_valid),
    .io_in_1_rx_rsp_bits_srcID (_snXbar_io_in_1_rx_rsp_bits_srcID),
    .io_in_1_rx_rsp_bits_txnID (_snXbar_io_in_1_rx_rsp_bits_txnID),
    .io_in_1_rx_rsp_bits_opcode (_snXbar_io_in_1_rx_rsp_bits_opcode),
    .io_in_1_rx_rsp_bits_dbID (_snXbar_io_in_1_rx_rsp_bits_dbID),
    .io_in_1_rx_dat_valid (_snXbar_io_in_1_rx_dat_valid),
    .io_in_1_rx_dat_bits_srcID (_snXbar_io_in_1_rx_dat_bits_srcID),
    .io_in_1_rx_dat_bits_txnID (_snXbar_io_in_1_rx_dat_bits_txnID),
    .io_in_1_rx_dat_bits_opcode (_snXbar_io_in_1_rx_dat_bits_opcode),
    .io_in_1_rx_dat_bits_resp (_snXbar_io_in_1_rx_dat_bits_resp),
    .io_in_1_rx_dat_bits_dataID (_snXbar_io_in_1_rx_dat_bits_dataID),
    .io_in_1_rx_dat_bits_data (_snXbar_io_in_1_rx_dat_bits_data),
    .io_in_2_tx_req_ready (_snXbar_io_in_2_tx_req_ready),
    .io_in_2_tx_req_valid (_slices_2_io_out_tx_req_valid),
    .io_in_2_tx_req_bits_tgtID (_slices_2_io_out_tx_req_bits_tgtID),
    .io_in_2_tx_req_bits_srcID (_slices_2_io_out_tx_req_bits_srcID),
    .io_in_2_tx_req_bits_txnID (_slices_2_io_out_tx_req_bits_txnID),
    .io_in_2_tx_req_bits_opcode (_slices_2_io_out_tx_req_bits_opcode),
    .io_in_2_tx_req_bits_size (_slices_2_io_out_tx_req_bits_size),
    .io_in_2_tx_req_bits_addr (_slices_2_io_out_tx_req_bits_addr),
    .io_in_2_tx_req_bits_allowRetry (_slices_2_io_out_tx_req_bits_allowRetry),
    .io_in_2_tx_req_bits_order (_slices_2_io_out_tx_req_bits_order),
    .io_in_2_tx_req_bits_pCrdType (_slices_2_io_out_tx_req_bits_pCrdType),
    .io_in_2_tx_req_bits_memAttr_allocate (_slices_2_io_out_tx_req_bits_memAttr_allocate),
    .io_in_2_tx_req_bits_memAttr_cacheable (_slices_2_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_2_tx_req_bits_memAttr_device (_slices_2_io_out_tx_req_bits_memAttr_device),
    .io_in_2_tx_req_bits_memAttr_ewa (_slices_2_io_out_tx_req_bits_memAttr_ewa),
    .io_in_2_tx_req_bits_snpAttr (_slices_2_io_out_tx_req_bits_snpAttr),
    .io_in_2_tx_req_bits_expCompAck (_slices_2_io_out_tx_req_bits_expCompAck),
    .io_in_2_tx_dat_ready (_snXbar_io_in_2_tx_dat_ready),
    .io_in_2_tx_dat_valid (_slices_2_io_out_tx_dat_valid),
    .io_in_2_tx_dat_bits_tgtID (_slices_2_io_out_tx_dat_bits_tgtID),
    .io_in_2_tx_dat_bits_srcID (_slices_2_io_out_tx_dat_bits_srcID),
    .io_in_2_tx_dat_bits_txnID (_slices_2_io_out_tx_dat_bits_txnID),
    .io_in_2_tx_dat_bits_homeNID (_slices_2_io_out_tx_dat_bits_homeNID),
    .io_in_2_tx_dat_bits_opcode (_slices_2_io_out_tx_dat_bits_opcode),
    .io_in_2_tx_dat_bits_resp (_slices_2_io_out_tx_dat_bits_resp),
    .io_in_2_tx_dat_bits_dataSource (_slices_2_io_out_tx_dat_bits_dataSource),
    .io_in_2_tx_dat_bits_dbID (_slices_2_io_out_tx_dat_bits_dbID),
    .io_in_2_tx_dat_bits_dataID (_slices_2_io_out_tx_dat_bits_dataID),
    .io_in_2_tx_dat_bits_be (_slices_2_io_out_tx_dat_bits_be),
    .io_in_2_tx_dat_bits_data (_slices_2_io_out_tx_dat_bits_data),
    .io_in_2_tx_dat_bits_dataCheck (_slices_2_io_out_tx_dat_bits_dataCheck),
    .io_in_2_rx_rsp_valid (_snXbar_io_in_2_rx_rsp_valid),
    .io_in_2_rx_rsp_bits_srcID (_snXbar_io_in_2_rx_rsp_bits_srcID),
    .io_in_2_rx_rsp_bits_txnID (_snXbar_io_in_2_rx_rsp_bits_txnID),
    .io_in_2_rx_rsp_bits_opcode (_snXbar_io_in_2_rx_rsp_bits_opcode),
    .io_in_2_rx_rsp_bits_dbID (_snXbar_io_in_2_rx_rsp_bits_dbID),
    .io_in_2_rx_dat_valid (_snXbar_io_in_2_rx_dat_valid),
    .io_in_2_rx_dat_bits_srcID (_snXbar_io_in_2_rx_dat_bits_srcID),
    .io_in_2_rx_dat_bits_txnID (_snXbar_io_in_2_rx_dat_bits_txnID),
    .io_in_2_rx_dat_bits_opcode (_snXbar_io_in_2_rx_dat_bits_opcode),
    .io_in_2_rx_dat_bits_resp (_snXbar_io_in_2_rx_dat_bits_resp),
    .io_in_2_rx_dat_bits_dataID (_snXbar_io_in_2_rx_dat_bits_dataID),
    .io_in_2_rx_dat_bits_data (_snXbar_io_in_2_rx_dat_bits_data),
    .io_in_3_tx_req_ready (_snXbar_io_in_3_tx_req_ready),
    .io_in_3_tx_req_valid (_slices_3_io_out_tx_req_valid),
    .io_in_3_tx_req_bits_tgtID (_slices_3_io_out_tx_req_bits_tgtID),
    .io_in_3_tx_req_bits_srcID (_slices_3_io_out_tx_req_bits_srcID),
    .io_in_3_tx_req_bits_txnID (_slices_3_io_out_tx_req_bits_txnID),
    .io_in_3_tx_req_bits_opcode (_slices_3_io_out_tx_req_bits_opcode),
    .io_in_3_tx_req_bits_size (_slices_3_io_out_tx_req_bits_size),
    .io_in_3_tx_req_bits_addr (_slices_3_io_out_tx_req_bits_addr),
    .io_in_3_tx_req_bits_allowRetry (_slices_3_io_out_tx_req_bits_allowRetry),
    .io_in_3_tx_req_bits_order (_slices_3_io_out_tx_req_bits_order),
    .io_in_3_tx_req_bits_pCrdType (_slices_3_io_out_tx_req_bits_pCrdType),
    .io_in_3_tx_req_bits_memAttr_allocate (_slices_3_io_out_tx_req_bits_memAttr_allocate),
    .io_in_3_tx_req_bits_memAttr_cacheable (_slices_3_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_3_tx_req_bits_memAttr_device (_slices_3_io_out_tx_req_bits_memAttr_device),
    .io_in_3_tx_req_bits_memAttr_ewa (_slices_3_io_out_tx_req_bits_memAttr_ewa),
    .io_in_3_tx_req_bits_snpAttr (_slices_3_io_out_tx_req_bits_snpAttr),
    .io_in_3_tx_req_bits_expCompAck (_slices_3_io_out_tx_req_bits_expCompAck),
    .io_in_3_tx_dat_ready (_snXbar_io_in_3_tx_dat_ready),
    .io_in_3_tx_dat_valid (_slices_3_io_out_tx_dat_valid),
    .io_in_3_tx_dat_bits_tgtID (_slices_3_io_out_tx_dat_bits_tgtID),
    .io_in_3_tx_dat_bits_srcID (_slices_3_io_out_tx_dat_bits_srcID),
    .io_in_3_tx_dat_bits_txnID (_slices_3_io_out_tx_dat_bits_txnID),
    .io_in_3_tx_dat_bits_homeNID (_slices_3_io_out_tx_dat_bits_homeNID),
    .io_in_3_tx_dat_bits_opcode (_slices_3_io_out_tx_dat_bits_opcode),
    .io_in_3_tx_dat_bits_resp (_slices_3_io_out_tx_dat_bits_resp),
    .io_in_3_tx_dat_bits_dataSource (_slices_3_io_out_tx_dat_bits_dataSource),
    .io_in_3_tx_dat_bits_dbID (_slices_3_io_out_tx_dat_bits_dbID),
    .io_in_3_tx_dat_bits_dataID (_slices_3_io_out_tx_dat_bits_dataID),
    .io_in_3_tx_dat_bits_be (_slices_3_io_out_tx_dat_bits_be),
    .io_in_3_tx_dat_bits_data (_slices_3_io_out_tx_dat_bits_data),
    .io_in_3_tx_dat_bits_dataCheck (_slices_3_io_out_tx_dat_bits_dataCheck),
    .io_in_3_rx_rsp_valid (_snXbar_io_in_3_rx_rsp_valid),
    .io_in_3_rx_rsp_bits_srcID (_snXbar_io_in_3_rx_rsp_bits_srcID),
    .io_in_3_rx_rsp_bits_txnID (_snXbar_io_in_3_rx_rsp_bits_txnID),
    .io_in_3_rx_rsp_bits_opcode (_snXbar_io_in_3_rx_rsp_bits_opcode),
    .io_in_3_rx_rsp_bits_dbID (_snXbar_io_in_3_rx_rsp_bits_dbID),
    .io_in_3_rx_dat_valid (_snXbar_io_in_3_rx_dat_valid),
    .io_in_3_rx_dat_bits_srcID (_snXbar_io_in_3_rx_dat_bits_srcID),
    .io_in_3_rx_dat_bits_txnID (_snXbar_io_in_3_rx_dat_bits_txnID),
    .io_in_3_rx_dat_bits_opcode (_snXbar_io_in_3_rx_dat_bits_opcode),
    .io_in_3_rx_dat_bits_resp (_snXbar_io_in_3_rx_dat_bits_resp),
    .io_in_3_rx_dat_bits_dataID (_snXbar_io_in_3_rx_dat_bits_dataID),
    .io_in_3_rx_dat_bits_data (_snXbar_io_in_3_rx_dat_bits_data),
    .io_out_tx_req_ready (_mmioMerger_io_in_cache_tx_req_ready),
    .io_out_tx_req_valid (_snXbar_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID (_snXbar_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID (_snXbar_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID (_snXbar_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode (_snXbar_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size (_snXbar_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr (_snXbar_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry (_snXbar_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order (_snXbar_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType (_snXbar_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate (_snXbar_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable (_snXbar_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device (_snXbar_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa (_snXbar_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr (_snXbar_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck (_snXbar_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready (_mmioMerger_io_in_cache_tx_dat_ready),
    .io_out_tx_dat_valid (_snXbar_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID (_snXbar_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID (_snXbar_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID (_snXbar_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID (_snXbar_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode (_snXbar_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp (_snXbar_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource (_snXbar_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID (_snXbar_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID (_snXbar_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be (_snXbar_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data (_snXbar_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck (_snXbar_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_ready (_snXbar_io_out_rx_rsp_ready),
    .io_out_rx_rsp_valid (_mmioMerger_io_in_cache_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID (_mmioMerger_io_in_cache_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID (_mmioMerger_io_in_cache_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode (_mmioMerger_io_in_cache_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID (_mmioMerger_io_in_cache_rx_rsp_bits_dbID),
    .io_out_rx_dat_ready (_snXbar_io_out_rx_dat_ready),
    .io_out_rx_dat_valid (_mmioMerger_io_in_cache_rx_dat_valid),
    .io_out_rx_dat_bits_srcID (_mmioMerger_io_in_cache_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID (_mmioMerger_io_in_cache_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode (_mmioMerger_io_in_cache_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp (_mmioMerger_io_in_cache_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID (_mmioMerger_io_in_cache_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data (_mmioMerger_io_in_cache_rx_dat_bits_data)
  );
  SNLinkMonitor snLinkMonitor (
    .clock (clock),
    .reset (reset),
    .io_in_tx_req_ready (_snLinkMonitor_io_in_tx_req_ready),
    .io_in_tx_req_valid (_mmioMerger_io_out_tx_req_valid),
    .io_in_tx_req_bits_qos (_mmioMerger_io_out_tx_req_bits_qos),
    .io_in_tx_req_bits_tgtID (_mmioMerger_io_out_tx_req_bits_tgtID),
    .io_in_tx_req_bits_srcID (_mmioMerger_io_out_tx_req_bits_srcID),
    .io_in_tx_req_bits_txnID (_mmioMerger_io_out_tx_req_bits_txnID),
    .io_in_tx_req_bits_returnNID (_mmioMerger_io_out_tx_req_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid (_mmioMerger_io_out_tx_req_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID (_mmioMerger_io_out_tx_req_bits_returnTxnID),
    .io_in_tx_req_bits_opcode (_mmioMerger_io_out_tx_req_bits_opcode),
    .io_in_tx_req_bits_size (_mmioMerger_io_out_tx_req_bits_size),
    .io_in_tx_req_bits_addr (_mmioMerger_io_out_tx_req_bits_addr),
    .io_in_tx_req_bits_ns (_mmioMerger_io_out_tx_req_bits_ns),
    .io_in_tx_req_bits_likelyshared (_mmioMerger_io_out_tx_req_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry (_mmioMerger_io_out_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order (_mmioMerger_io_out_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType (_mmioMerger_io_out_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate (_mmioMerger_io_out_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable (_mmioMerger_io_out_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device (_mmioMerger_io_out_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa (_mmioMerger_io_out_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr (_mmioMerger_io_out_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding (_mmioMerger_io_out_tx_req_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe (_mmioMerger_io_out_tx_req_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck (_mmioMerger_io_out_tx_req_bits_expCompAck),
    .io_in_tx_req_bits_tagOp (_mmioMerger_io_out_tx_req_bits_tagOp),
    .io_in_tx_req_bits_traceTag (_mmioMerger_io_out_tx_req_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup (_mmioMerger_io_out_tx_req_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID (_mmioMerger_io_out_tx_req_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS (_mmioMerger_io_out_tx_req_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc (_mmioMerger_io_out_tx_req_bits_rsvdc),
    .io_in_tx_dat_ready (_snLinkMonitor_io_in_tx_dat_ready),
    .io_in_tx_dat_valid (_mmioMerger_io_out_tx_dat_valid),
    .io_in_tx_dat_bits_qos (_mmioMerger_io_out_tx_dat_bits_qos),
    .io_in_tx_dat_bits_tgtID (_mmioMerger_io_out_tx_dat_bits_tgtID),
    .io_in_tx_dat_bits_srcID (_mmioMerger_io_out_tx_dat_bits_srcID),
    .io_in_tx_dat_bits_txnID (_mmioMerger_io_out_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_homeNID (_mmioMerger_io_out_tx_dat_bits_homeNID),
    .io_in_tx_dat_bits_opcode (_mmioMerger_io_out_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_respErr (_mmioMerger_io_out_tx_dat_bits_respErr),
    .io_in_tx_dat_bits_resp (_mmioMerger_io_out_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataSource (_mmioMerger_io_out_tx_dat_bits_dataSource),
    .io_in_tx_dat_bits_cBusy (_mmioMerger_io_out_tx_dat_bits_cBusy),
    .io_in_tx_dat_bits_dbID (_mmioMerger_io_out_tx_dat_bits_dbID),
    .io_in_tx_dat_bits_ccID (_mmioMerger_io_out_tx_dat_bits_ccID),
    .io_in_tx_dat_bits_dataID (_mmioMerger_io_out_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_tagOp (_mmioMerger_io_out_tx_dat_bits_tagOp),
    .io_in_tx_dat_bits_tag (_mmioMerger_io_out_tx_dat_bits_tag),
    .io_in_tx_dat_bits_tu (_mmioMerger_io_out_tx_dat_bits_tu),
    .io_in_tx_dat_bits_traceTag (_mmioMerger_io_out_tx_dat_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc (_mmioMerger_io_out_tx_dat_bits_rsvdc),
    .io_in_tx_dat_bits_be (_mmioMerger_io_out_tx_dat_bits_be),
    .io_in_tx_dat_bits_data (_mmioMerger_io_out_tx_dat_bits_data),
    .io_in_tx_dat_bits_dataCheck (_mmioMerger_io_out_tx_dat_bits_dataCheck),
    .io_in_tx_dat_bits_poison (_mmioMerger_io_out_tx_dat_bits_poison),
    .io_in_rx_rsp_ready (_mmioMerger_io_out_rx_rsp_ready),
    .io_in_rx_rsp_valid (_snLinkMonitor_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos (_snLinkMonitor_io_in_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_tgtID (_snLinkMonitor_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID (_snLinkMonitor_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID (_snLinkMonitor_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode (_snLinkMonitor_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr (_snLinkMonitor_io_in_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp (_snLinkMonitor_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState (_snLinkMonitor_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy (_snLinkMonitor_io_in_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID (_snLinkMonitor_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType (_snLinkMonitor_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp (_snLinkMonitor_io_in_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag (_snLinkMonitor_io_in_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready (_mmioMerger_io_out_rx_dat_ready),
    .io_in_rx_dat_valid (_snLinkMonitor_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_qos (_snLinkMonitor_io_in_rx_dat_bits_qos),
    .io_in_rx_dat_bits_tgtID (_snLinkMonitor_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID (_snLinkMonitor_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID (_snLinkMonitor_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID (_snLinkMonitor_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode (_snLinkMonitor_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr (_snLinkMonitor_io_in_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp (_snLinkMonitor_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource (_snLinkMonitor_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy (_snLinkMonitor_io_in_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID (_snLinkMonitor_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID (_snLinkMonitor_io_in_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID (_snLinkMonitor_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp (_snLinkMonitor_io_in_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag (_snLinkMonitor_io_in_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu (_snLinkMonitor_io_in_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag (_snLinkMonitor_io_in_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc (_snLinkMonitor_io_in_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be (_snLinkMonitor_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data (_snLinkMonitor_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck (_snLinkMonitor_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison (_snLinkMonitor_io_in_rx_dat_bits_poison),
    .io_out_txsactive (io_sn_txsactive),
    .io_out_rxsactive (io_sn_rxsactive),
    .io_out_tx_linkactivereq (io_sn_tx_linkactivereq),
    .io_out_tx_linkactiveack (io_sn_tx_linkactiveack),
    .io_out_tx_req_flitpend (io_sn_tx_req_flitpend),
    .io_out_tx_req_flitv (io_sn_tx_req_flitv),
    .io_out_tx_req_flit (io_sn_tx_req_flit),
    .io_out_tx_req_lcrdv (io_sn_tx_req_lcrdv),
    .io_out_tx_dat_flitpend (io_sn_tx_dat_flitpend),
    .io_out_tx_dat_flitv (io_sn_tx_dat_flitv),
    .io_out_tx_dat_flit (io_sn_tx_dat_flit),
    .io_out_tx_dat_lcrdv (io_sn_tx_dat_lcrdv),
    .io_out_rx_linkactivereq (io_sn_rx_linkactivereq),
    .io_out_rx_linkactiveack (io_sn_rx_linkactiveack),
    .io_out_rx_rsp_flitpend (io_sn_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv (io_sn_rx_rsp_flitv),
    .io_out_rx_rsp_flit (io_sn_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv (io_sn_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend (io_sn_rx_dat_flitpend),
    .io_out_rx_dat_flitv (io_sn_rx_dat_flitv),
    .io_out_rx_dat_flit (io_sn_rx_dat_flit),
    .io_out_rx_dat_lcrdv (io_sn_rx_dat_lcrdv)
  );
  TopDownMonitor_1 topDown (
    .io_msStatus_0_0_valid (_slices_0_io_msStatus_0_valid),
    .io_msStatus_0_0_bits_set (_slices_0_io_msStatus_0_bits_set),
    .io_msStatus_0_0_bits_tag (_slices_0_io_msStatus_0_bits_tag),
    .io_msStatus_0_0_bits_opcode (_slices_0_io_msStatus_0_bits_opcode),
    .io_msStatus_0_0_bits_is_miss (_slices_0_io_msStatus_0_bits_is_miss),
    .io_msStatus_0_1_valid (_slices_0_io_msStatus_1_valid),
    .io_msStatus_0_1_bits_set (_slices_0_io_msStatus_1_bits_set),
    .io_msStatus_0_1_bits_tag (_slices_0_io_msStatus_1_bits_tag),
    .io_msStatus_0_1_bits_opcode (_slices_0_io_msStatus_1_bits_opcode),
    .io_msStatus_0_1_bits_is_miss (_slices_0_io_msStatus_1_bits_is_miss),
    .io_msStatus_0_2_valid (_slices_0_io_msStatus_2_valid),
    .io_msStatus_0_2_bits_set (_slices_0_io_msStatus_2_bits_set),
    .io_msStatus_0_2_bits_tag (_slices_0_io_msStatus_2_bits_tag),
    .io_msStatus_0_2_bits_opcode (_slices_0_io_msStatus_2_bits_opcode),
    .io_msStatus_0_2_bits_is_miss (_slices_0_io_msStatus_2_bits_is_miss),
    .io_msStatus_0_3_valid (_slices_0_io_msStatus_3_valid),
    .io_msStatus_0_3_bits_set (_slices_0_io_msStatus_3_bits_set),
    .io_msStatus_0_3_bits_tag (_slices_0_io_msStatus_3_bits_tag),
    .io_msStatus_0_3_bits_opcode (_slices_0_io_msStatus_3_bits_opcode),
    .io_msStatus_0_3_bits_is_miss (_slices_0_io_msStatus_3_bits_is_miss),
    .io_msStatus_0_4_valid (_slices_0_io_msStatus_4_valid),
    .io_msStatus_0_4_bits_set (_slices_0_io_msStatus_4_bits_set),
    .io_msStatus_0_4_bits_tag (_slices_0_io_msStatus_4_bits_tag),
    .io_msStatus_0_4_bits_opcode (_slices_0_io_msStatus_4_bits_opcode),
    .io_msStatus_0_4_bits_is_miss (_slices_0_io_msStatus_4_bits_is_miss),
    .io_msStatus_0_5_valid (_slices_0_io_msStatus_5_valid),
    .io_msStatus_0_5_bits_set (_slices_0_io_msStatus_5_bits_set),
    .io_msStatus_0_5_bits_tag (_slices_0_io_msStatus_5_bits_tag),
    .io_msStatus_0_5_bits_opcode (_slices_0_io_msStatus_5_bits_opcode),
    .io_msStatus_0_5_bits_is_miss (_slices_0_io_msStatus_5_bits_is_miss),
    .io_msStatus_0_6_valid (_slices_0_io_msStatus_6_valid),
    .io_msStatus_0_6_bits_set (_slices_0_io_msStatus_6_bits_set),
    .io_msStatus_0_6_bits_tag (_slices_0_io_msStatus_6_bits_tag),
    .io_msStatus_0_6_bits_opcode (_slices_0_io_msStatus_6_bits_opcode),
    .io_msStatus_0_6_bits_is_miss (_slices_0_io_msStatus_6_bits_is_miss),
    .io_msStatus_0_7_valid (_slices_0_io_msStatus_7_valid),
    .io_msStatus_0_7_bits_set (_slices_0_io_msStatus_7_bits_set),
    .io_msStatus_0_7_bits_tag (_slices_0_io_msStatus_7_bits_tag),
    .io_msStatus_0_7_bits_opcode (_slices_0_io_msStatus_7_bits_opcode),
    .io_msStatus_0_7_bits_is_miss (_slices_0_io_msStatus_7_bits_is_miss),
    .io_msStatus_0_8_valid (_slices_0_io_msStatus_8_valid),
    .io_msStatus_0_8_bits_set (_slices_0_io_msStatus_8_bits_set),
    .io_msStatus_0_8_bits_tag (_slices_0_io_msStatus_8_bits_tag),
    .io_msStatus_0_8_bits_opcode (_slices_0_io_msStatus_8_bits_opcode),
    .io_msStatus_0_8_bits_is_miss (_slices_0_io_msStatus_8_bits_is_miss),
    .io_msStatus_0_9_valid (_slices_0_io_msStatus_9_valid),
    .io_msStatus_0_9_bits_set (_slices_0_io_msStatus_9_bits_set),
    .io_msStatus_0_9_bits_tag (_slices_0_io_msStatus_9_bits_tag),
    .io_msStatus_0_9_bits_opcode (_slices_0_io_msStatus_9_bits_opcode),
    .io_msStatus_0_9_bits_is_miss (_slices_0_io_msStatus_9_bits_is_miss),
    .io_msStatus_0_10_valid (_slices_0_io_msStatus_10_valid),
    .io_msStatus_0_10_bits_set (_slices_0_io_msStatus_10_bits_set),
    .io_msStatus_0_10_bits_tag (_slices_0_io_msStatus_10_bits_tag),
    .io_msStatus_0_10_bits_opcode (_slices_0_io_msStatus_10_bits_opcode),
    .io_msStatus_0_10_bits_is_miss (_slices_0_io_msStatus_10_bits_is_miss),
    .io_msStatus_0_11_valid (_slices_0_io_msStatus_11_valid),
    .io_msStatus_0_11_bits_set (_slices_0_io_msStatus_11_bits_set),
    .io_msStatus_0_11_bits_tag (_slices_0_io_msStatus_11_bits_tag),
    .io_msStatus_0_11_bits_opcode (_slices_0_io_msStatus_11_bits_opcode),
    .io_msStatus_0_11_bits_is_miss (_slices_0_io_msStatus_11_bits_is_miss),
    .io_msStatus_0_12_valid (_slices_0_io_msStatus_12_valid),
    .io_msStatus_0_12_bits_set (_slices_0_io_msStatus_12_bits_set),
    .io_msStatus_0_12_bits_tag (_slices_0_io_msStatus_12_bits_tag),
    .io_msStatus_0_12_bits_opcode (_slices_0_io_msStatus_12_bits_opcode),
    .io_msStatus_0_12_bits_is_miss (_slices_0_io_msStatus_12_bits_is_miss),
    .io_msStatus_0_13_valid (_slices_0_io_msStatus_13_valid),
    .io_msStatus_0_13_bits_set (_slices_0_io_msStatus_13_bits_set),
    .io_msStatus_0_13_bits_tag (_slices_0_io_msStatus_13_bits_tag),
    .io_msStatus_0_13_bits_opcode (_slices_0_io_msStatus_13_bits_opcode),
    .io_msStatus_0_13_bits_is_miss (_slices_0_io_msStatus_13_bits_is_miss),
    .io_msStatus_0_14_valid (_slices_0_io_msStatus_14_valid),
    .io_msStatus_0_14_bits_set (_slices_0_io_msStatus_14_bits_set),
    .io_msStatus_0_14_bits_tag (_slices_0_io_msStatus_14_bits_tag),
    .io_msStatus_0_14_bits_opcode (_slices_0_io_msStatus_14_bits_opcode),
    .io_msStatus_0_14_bits_is_miss (_slices_0_io_msStatus_14_bits_is_miss),
    .io_msStatus_0_15_valid (_slices_0_io_msStatus_15_valid),
    .io_msStatus_0_15_bits_set (_slices_0_io_msStatus_15_bits_set),
    .io_msStatus_0_15_bits_tag (_slices_0_io_msStatus_15_bits_tag),
    .io_msStatus_0_15_bits_opcode (_slices_0_io_msStatus_15_bits_opcode),
    .io_msStatus_0_15_bits_is_miss (_slices_0_io_msStatus_15_bits_is_miss),
    .io_msStatus_1_0_valid (_slices_1_io_msStatus_0_valid),
    .io_msStatus_1_0_bits_set (_slices_1_io_msStatus_0_bits_set),
    .io_msStatus_1_0_bits_tag (_slices_1_io_msStatus_0_bits_tag),
    .io_msStatus_1_0_bits_opcode (_slices_1_io_msStatus_0_bits_opcode),
    .io_msStatus_1_0_bits_is_miss (_slices_1_io_msStatus_0_bits_is_miss),
    .io_msStatus_1_1_valid (_slices_1_io_msStatus_1_valid),
    .io_msStatus_1_1_bits_set (_slices_1_io_msStatus_1_bits_set),
    .io_msStatus_1_1_bits_tag (_slices_1_io_msStatus_1_bits_tag),
    .io_msStatus_1_1_bits_opcode (_slices_1_io_msStatus_1_bits_opcode),
    .io_msStatus_1_1_bits_is_miss (_slices_1_io_msStatus_1_bits_is_miss),
    .io_msStatus_1_2_valid (_slices_1_io_msStatus_2_valid),
    .io_msStatus_1_2_bits_set (_slices_1_io_msStatus_2_bits_set),
    .io_msStatus_1_2_bits_tag (_slices_1_io_msStatus_2_bits_tag),
    .io_msStatus_1_2_bits_opcode (_slices_1_io_msStatus_2_bits_opcode),
    .io_msStatus_1_2_bits_is_miss (_slices_1_io_msStatus_2_bits_is_miss),
    .io_msStatus_1_3_valid (_slices_1_io_msStatus_3_valid),
    .io_msStatus_1_3_bits_set (_slices_1_io_msStatus_3_bits_set),
    .io_msStatus_1_3_bits_tag (_slices_1_io_msStatus_3_bits_tag),
    .io_msStatus_1_3_bits_opcode (_slices_1_io_msStatus_3_bits_opcode),
    .io_msStatus_1_3_bits_is_miss (_slices_1_io_msStatus_3_bits_is_miss),
    .io_msStatus_1_4_valid (_slices_1_io_msStatus_4_valid),
    .io_msStatus_1_4_bits_set (_slices_1_io_msStatus_4_bits_set),
    .io_msStatus_1_4_bits_tag (_slices_1_io_msStatus_4_bits_tag),
    .io_msStatus_1_4_bits_opcode (_slices_1_io_msStatus_4_bits_opcode),
    .io_msStatus_1_4_bits_is_miss (_slices_1_io_msStatus_4_bits_is_miss),
    .io_msStatus_1_5_valid (_slices_1_io_msStatus_5_valid),
    .io_msStatus_1_5_bits_set (_slices_1_io_msStatus_5_bits_set),
    .io_msStatus_1_5_bits_tag (_slices_1_io_msStatus_5_bits_tag),
    .io_msStatus_1_5_bits_opcode (_slices_1_io_msStatus_5_bits_opcode),
    .io_msStatus_1_5_bits_is_miss (_slices_1_io_msStatus_5_bits_is_miss),
    .io_msStatus_1_6_valid (_slices_1_io_msStatus_6_valid),
    .io_msStatus_1_6_bits_set (_slices_1_io_msStatus_6_bits_set),
    .io_msStatus_1_6_bits_tag (_slices_1_io_msStatus_6_bits_tag),
    .io_msStatus_1_6_bits_opcode (_slices_1_io_msStatus_6_bits_opcode),
    .io_msStatus_1_6_bits_is_miss (_slices_1_io_msStatus_6_bits_is_miss),
    .io_msStatus_1_7_valid (_slices_1_io_msStatus_7_valid),
    .io_msStatus_1_7_bits_set (_slices_1_io_msStatus_7_bits_set),
    .io_msStatus_1_7_bits_tag (_slices_1_io_msStatus_7_bits_tag),
    .io_msStatus_1_7_bits_opcode (_slices_1_io_msStatus_7_bits_opcode),
    .io_msStatus_1_7_bits_is_miss (_slices_1_io_msStatus_7_bits_is_miss),
    .io_msStatus_1_8_valid (_slices_1_io_msStatus_8_valid),
    .io_msStatus_1_8_bits_set (_slices_1_io_msStatus_8_bits_set),
    .io_msStatus_1_8_bits_tag (_slices_1_io_msStatus_8_bits_tag),
    .io_msStatus_1_8_bits_opcode (_slices_1_io_msStatus_8_bits_opcode),
    .io_msStatus_1_8_bits_is_miss (_slices_1_io_msStatus_8_bits_is_miss),
    .io_msStatus_1_9_valid (_slices_1_io_msStatus_9_valid),
    .io_msStatus_1_9_bits_set (_slices_1_io_msStatus_9_bits_set),
    .io_msStatus_1_9_bits_tag (_slices_1_io_msStatus_9_bits_tag),
    .io_msStatus_1_9_bits_opcode (_slices_1_io_msStatus_9_bits_opcode),
    .io_msStatus_1_9_bits_is_miss (_slices_1_io_msStatus_9_bits_is_miss),
    .io_msStatus_1_10_valid (_slices_1_io_msStatus_10_valid),
    .io_msStatus_1_10_bits_set (_slices_1_io_msStatus_10_bits_set),
    .io_msStatus_1_10_bits_tag (_slices_1_io_msStatus_10_bits_tag),
    .io_msStatus_1_10_bits_opcode (_slices_1_io_msStatus_10_bits_opcode),
    .io_msStatus_1_10_bits_is_miss (_slices_1_io_msStatus_10_bits_is_miss),
    .io_msStatus_1_11_valid (_slices_1_io_msStatus_11_valid),
    .io_msStatus_1_11_bits_set (_slices_1_io_msStatus_11_bits_set),
    .io_msStatus_1_11_bits_tag (_slices_1_io_msStatus_11_bits_tag),
    .io_msStatus_1_11_bits_opcode (_slices_1_io_msStatus_11_bits_opcode),
    .io_msStatus_1_11_bits_is_miss (_slices_1_io_msStatus_11_bits_is_miss),
    .io_msStatus_1_12_valid (_slices_1_io_msStatus_12_valid),
    .io_msStatus_1_12_bits_set (_slices_1_io_msStatus_12_bits_set),
    .io_msStatus_1_12_bits_tag (_slices_1_io_msStatus_12_bits_tag),
    .io_msStatus_1_12_bits_opcode (_slices_1_io_msStatus_12_bits_opcode),
    .io_msStatus_1_12_bits_is_miss (_slices_1_io_msStatus_12_bits_is_miss),
    .io_msStatus_1_13_valid (_slices_1_io_msStatus_13_valid),
    .io_msStatus_1_13_bits_set (_slices_1_io_msStatus_13_bits_set),
    .io_msStatus_1_13_bits_tag (_slices_1_io_msStatus_13_bits_tag),
    .io_msStatus_1_13_bits_opcode (_slices_1_io_msStatus_13_bits_opcode),
    .io_msStatus_1_13_bits_is_miss (_slices_1_io_msStatus_13_bits_is_miss),
    .io_msStatus_1_14_valid (_slices_1_io_msStatus_14_valid),
    .io_msStatus_1_14_bits_set (_slices_1_io_msStatus_14_bits_set),
    .io_msStatus_1_14_bits_tag (_slices_1_io_msStatus_14_bits_tag),
    .io_msStatus_1_14_bits_opcode (_slices_1_io_msStatus_14_bits_opcode),
    .io_msStatus_1_14_bits_is_miss (_slices_1_io_msStatus_14_bits_is_miss),
    .io_msStatus_1_15_valid (_slices_1_io_msStatus_15_valid),
    .io_msStatus_1_15_bits_set (_slices_1_io_msStatus_15_bits_set),
    .io_msStatus_1_15_bits_tag (_slices_1_io_msStatus_15_bits_tag),
    .io_msStatus_1_15_bits_opcode (_slices_1_io_msStatus_15_bits_opcode),
    .io_msStatus_1_15_bits_is_miss (_slices_1_io_msStatus_15_bits_is_miss),
    .io_msStatus_2_0_valid (_slices_2_io_msStatus_0_valid),
    .io_msStatus_2_0_bits_set (_slices_2_io_msStatus_0_bits_set),
    .io_msStatus_2_0_bits_tag (_slices_2_io_msStatus_0_bits_tag),
    .io_msStatus_2_0_bits_opcode (_slices_2_io_msStatus_0_bits_opcode),
    .io_msStatus_2_0_bits_is_miss (_slices_2_io_msStatus_0_bits_is_miss),
    .io_msStatus_2_1_valid (_slices_2_io_msStatus_1_valid),
    .io_msStatus_2_1_bits_set (_slices_2_io_msStatus_1_bits_set),
    .io_msStatus_2_1_bits_tag (_slices_2_io_msStatus_1_bits_tag),
    .io_msStatus_2_1_bits_opcode (_slices_2_io_msStatus_1_bits_opcode),
    .io_msStatus_2_1_bits_is_miss (_slices_2_io_msStatus_1_bits_is_miss),
    .io_msStatus_2_2_valid (_slices_2_io_msStatus_2_valid),
    .io_msStatus_2_2_bits_set (_slices_2_io_msStatus_2_bits_set),
    .io_msStatus_2_2_bits_tag (_slices_2_io_msStatus_2_bits_tag),
    .io_msStatus_2_2_bits_opcode (_slices_2_io_msStatus_2_bits_opcode),
    .io_msStatus_2_2_bits_is_miss (_slices_2_io_msStatus_2_bits_is_miss),
    .io_msStatus_2_3_valid (_slices_2_io_msStatus_3_valid),
    .io_msStatus_2_3_bits_set (_slices_2_io_msStatus_3_bits_set),
    .io_msStatus_2_3_bits_tag (_slices_2_io_msStatus_3_bits_tag),
    .io_msStatus_2_3_bits_opcode (_slices_2_io_msStatus_3_bits_opcode),
    .io_msStatus_2_3_bits_is_miss (_slices_2_io_msStatus_3_bits_is_miss),
    .io_msStatus_2_4_valid (_slices_2_io_msStatus_4_valid),
    .io_msStatus_2_4_bits_set (_slices_2_io_msStatus_4_bits_set),
    .io_msStatus_2_4_bits_tag (_slices_2_io_msStatus_4_bits_tag),
    .io_msStatus_2_4_bits_opcode (_slices_2_io_msStatus_4_bits_opcode),
    .io_msStatus_2_4_bits_is_miss (_slices_2_io_msStatus_4_bits_is_miss),
    .io_msStatus_2_5_valid (_slices_2_io_msStatus_5_valid),
    .io_msStatus_2_5_bits_set (_slices_2_io_msStatus_5_bits_set),
    .io_msStatus_2_5_bits_tag (_slices_2_io_msStatus_5_bits_tag),
    .io_msStatus_2_5_bits_opcode (_slices_2_io_msStatus_5_bits_opcode),
    .io_msStatus_2_5_bits_is_miss (_slices_2_io_msStatus_5_bits_is_miss),
    .io_msStatus_2_6_valid (_slices_2_io_msStatus_6_valid),
    .io_msStatus_2_6_bits_set (_slices_2_io_msStatus_6_bits_set),
    .io_msStatus_2_6_bits_tag (_slices_2_io_msStatus_6_bits_tag),
    .io_msStatus_2_6_bits_opcode (_slices_2_io_msStatus_6_bits_opcode),
    .io_msStatus_2_6_bits_is_miss (_slices_2_io_msStatus_6_bits_is_miss),
    .io_msStatus_2_7_valid (_slices_2_io_msStatus_7_valid),
    .io_msStatus_2_7_bits_set (_slices_2_io_msStatus_7_bits_set),
    .io_msStatus_2_7_bits_tag (_slices_2_io_msStatus_7_bits_tag),
    .io_msStatus_2_7_bits_opcode (_slices_2_io_msStatus_7_bits_opcode),
    .io_msStatus_2_7_bits_is_miss (_slices_2_io_msStatus_7_bits_is_miss),
    .io_msStatus_2_8_valid (_slices_2_io_msStatus_8_valid),
    .io_msStatus_2_8_bits_set (_slices_2_io_msStatus_8_bits_set),
    .io_msStatus_2_8_bits_tag (_slices_2_io_msStatus_8_bits_tag),
    .io_msStatus_2_8_bits_opcode (_slices_2_io_msStatus_8_bits_opcode),
    .io_msStatus_2_8_bits_is_miss (_slices_2_io_msStatus_8_bits_is_miss),
    .io_msStatus_2_9_valid (_slices_2_io_msStatus_9_valid),
    .io_msStatus_2_9_bits_set (_slices_2_io_msStatus_9_bits_set),
    .io_msStatus_2_9_bits_tag (_slices_2_io_msStatus_9_bits_tag),
    .io_msStatus_2_9_bits_opcode (_slices_2_io_msStatus_9_bits_opcode),
    .io_msStatus_2_9_bits_is_miss (_slices_2_io_msStatus_9_bits_is_miss),
    .io_msStatus_2_10_valid (_slices_2_io_msStatus_10_valid),
    .io_msStatus_2_10_bits_set (_slices_2_io_msStatus_10_bits_set),
    .io_msStatus_2_10_bits_tag (_slices_2_io_msStatus_10_bits_tag),
    .io_msStatus_2_10_bits_opcode (_slices_2_io_msStatus_10_bits_opcode),
    .io_msStatus_2_10_bits_is_miss (_slices_2_io_msStatus_10_bits_is_miss),
    .io_msStatus_2_11_valid (_slices_2_io_msStatus_11_valid),
    .io_msStatus_2_11_bits_set (_slices_2_io_msStatus_11_bits_set),
    .io_msStatus_2_11_bits_tag (_slices_2_io_msStatus_11_bits_tag),
    .io_msStatus_2_11_bits_opcode (_slices_2_io_msStatus_11_bits_opcode),
    .io_msStatus_2_11_bits_is_miss (_slices_2_io_msStatus_11_bits_is_miss),
    .io_msStatus_2_12_valid (_slices_2_io_msStatus_12_valid),
    .io_msStatus_2_12_bits_set (_slices_2_io_msStatus_12_bits_set),
    .io_msStatus_2_12_bits_tag (_slices_2_io_msStatus_12_bits_tag),
    .io_msStatus_2_12_bits_opcode (_slices_2_io_msStatus_12_bits_opcode),
    .io_msStatus_2_12_bits_is_miss (_slices_2_io_msStatus_12_bits_is_miss),
    .io_msStatus_2_13_valid (_slices_2_io_msStatus_13_valid),
    .io_msStatus_2_13_bits_set (_slices_2_io_msStatus_13_bits_set),
    .io_msStatus_2_13_bits_tag (_slices_2_io_msStatus_13_bits_tag),
    .io_msStatus_2_13_bits_opcode (_slices_2_io_msStatus_13_bits_opcode),
    .io_msStatus_2_13_bits_is_miss (_slices_2_io_msStatus_13_bits_is_miss),
    .io_msStatus_2_14_valid (_slices_2_io_msStatus_14_valid),
    .io_msStatus_2_14_bits_set (_slices_2_io_msStatus_14_bits_set),
    .io_msStatus_2_14_bits_tag (_slices_2_io_msStatus_14_bits_tag),
    .io_msStatus_2_14_bits_opcode (_slices_2_io_msStatus_14_bits_opcode),
    .io_msStatus_2_14_bits_is_miss (_slices_2_io_msStatus_14_bits_is_miss),
    .io_msStatus_2_15_valid (_slices_2_io_msStatus_15_valid),
    .io_msStatus_2_15_bits_set (_slices_2_io_msStatus_15_bits_set),
    .io_msStatus_2_15_bits_tag (_slices_2_io_msStatus_15_bits_tag),
    .io_msStatus_2_15_bits_opcode (_slices_2_io_msStatus_15_bits_opcode),
    .io_msStatus_2_15_bits_is_miss (_slices_2_io_msStatus_15_bits_is_miss),
    .io_msStatus_3_0_valid (_slices_3_io_msStatus_0_valid),
    .io_msStatus_3_0_bits_set (_slices_3_io_msStatus_0_bits_set),
    .io_msStatus_3_0_bits_tag (_slices_3_io_msStatus_0_bits_tag),
    .io_msStatus_3_0_bits_opcode (_slices_3_io_msStatus_0_bits_opcode),
    .io_msStatus_3_0_bits_is_miss (_slices_3_io_msStatus_0_bits_is_miss),
    .io_msStatus_3_1_valid (_slices_3_io_msStatus_1_valid),
    .io_msStatus_3_1_bits_set (_slices_3_io_msStatus_1_bits_set),
    .io_msStatus_3_1_bits_tag (_slices_3_io_msStatus_1_bits_tag),
    .io_msStatus_3_1_bits_opcode (_slices_3_io_msStatus_1_bits_opcode),
    .io_msStatus_3_1_bits_is_miss (_slices_3_io_msStatus_1_bits_is_miss),
    .io_msStatus_3_2_valid (_slices_3_io_msStatus_2_valid),
    .io_msStatus_3_2_bits_set (_slices_3_io_msStatus_2_bits_set),
    .io_msStatus_3_2_bits_tag (_slices_3_io_msStatus_2_bits_tag),
    .io_msStatus_3_2_bits_opcode (_slices_3_io_msStatus_2_bits_opcode),
    .io_msStatus_3_2_bits_is_miss (_slices_3_io_msStatus_2_bits_is_miss),
    .io_msStatus_3_3_valid (_slices_3_io_msStatus_3_valid),
    .io_msStatus_3_3_bits_set (_slices_3_io_msStatus_3_bits_set),
    .io_msStatus_3_3_bits_tag (_slices_3_io_msStatus_3_bits_tag),
    .io_msStatus_3_3_bits_opcode (_slices_3_io_msStatus_3_bits_opcode),
    .io_msStatus_3_3_bits_is_miss (_slices_3_io_msStatus_3_bits_is_miss),
    .io_msStatus_3_4_valid (_slices_3_io_msStatus_4_valid),
    .io_msStatus_3_4_bits_set (_slices_3_io_msStatus_4_bits_set),
    .io_msStatus_3_4_bits_tag (_slices_3_io_msStatus_4_bits_tag),
    .io_msStatus_3_4_bits_opcode (_slices_3_io_msStatus_4_bits_opcode),
    .io_msStatus_3_4_bits_is_miss (_slices_3_io_msStatus_4_bits_is_miss),
    .io_msStatus_3_5_valid (_slices_3_io_msStatus_5_valid),
    .io_msStatus_3_5_bits_set (_slices_3_io_msStatus_5_bits_set),
    .io_msStatus_3_5_bits_tag (_slices_3_io_msStatus_5_bits_tag),
    .io_msStatus_3_5_bits_opcode (_slices_3_io_msStatus_5_bits_opcode),
    .io_msStatus_3_5_bits_is_miss (_slices_3_io_msStatus_5_bits_is_miss),
    .io_msStatus_3_6_valid (_slices_3_io_msStatus_6_valid),
    .io_msStatus_3_6_bits_set (_slices_3_io_msStatus_6_bits_set),
    .io_msStatus_3_6_bits_tag (_slices_3_io_msStatus_6_bits_tag),
    .io_msStatus_3_6_bits_opcode (_slices_3_io_msStatus_6_bits_opcode),
    .io_msStatus_3_6_bits_is_miss (_slices_3_io_msStatus_6_bits_is_miss),
    .io_msStatus_3_7_valid (_slices_3_io_msStatus_7_valid),
    .io_msStatus_3_7_bits_set (_slices_3_io_msStatus_7_bits_set),
    .io_msStatus_3_7_bits_tag (_slices_3_io_msStatus_7_bits_tag),
    .io_msStatus_3_7_bits_opcode (_slices_3_io_msStatus_7_bits_opcode),
    .io_msStatus_3_7_bits_is_miss (_slices_3_io_msStatus_7_bits_is_miss),
    .io_msStatus_3_8_valid (_slices_3_io_msStatus_8_valid),
    .io_msStatus_3_8_bits_set (_slices_3_io_msStatus_8_bits_set),
    .io_msStatus_3_8_bits_tag (_slices_3_io_msStatus_8_bits_tag),
    .io_msStatus_3_8_bits_opcode (_slices_3_io_msStatus_8_bits_opcode),
    .io_msStatus_3_8_bits_is_miss (_slices_3_io_msStatus_8_bits_is_miss),
    .io_msStatus_3_9_valid (_slices_3_io_msStatus_9_valid),
    .io_msStatus_3_9_bits_set (_slices_3_io_msStatus_9_bits_set),
    .io_msStatus_3_9_bits_tag (_slices_3_io_msStatus_9_bits_tag),
    .io_msStatus_3_9_bits_opcode (_slices_3_io_msStatus_9_bits_opcode),
    .io_msStatus_3_9_bits_is_miss (_slices_3_io_msStatus_9_bits_is_miss),
    .io_msStatus_3_10_valid (_slices_3_io_msStatus_10_valid),
    .io_msStatus_3_10_bits_set (_slices_3_io_msStatus_10_bits_set),
    .io_msStatus_3_10_bits_tag (_slices_3_io_msStatus_10_bits_tag),
    .io_msStatus_3_10_bits_opcode (_slices_3_io_msStatus_10_bits_opcode),
    .io_msStatus_3_10_bits_is_miss (_slices_3_io_msStatus_10_bits_is_miss),
    .io_msStatus_3_11_valid (_slices_3_io_msStatus_11_valid),
    .io_msStatus_3_11_bits_set (_slices_3_io_msStatus_11_bits_set),
    .io_msStatus_3_11_bits_tag (_slices_3_io_msStatus_11_bits_tag),
    .io_msStatus_3_11_bits_opcode (_slices_3_io_msStatus_11_bits_opcode),
    .io_msStatus_3_11_bits_is_miss (_slices_3_io_msStatus_11_bits_is_miss),
    .io_msStatus_3_12_valid (_slices_3_io_msStatus_12_valid),
    .io_msStatus_3_12_bits_set (_slices_3_io_msStatus_12_bits_set),
    .io_msStatus_3_12_bits_tag (_slices_3_io_msStatus_12_bits_tag),
    .io_msStatus_3_12_bits_opcode (_slices_3_io_msStatus_12_bits_opcode),
    .io_msStatus_3_12_bits_is_miss (_slices_3_io_msStatus_12_bits_is_miss),
    .io_msStatus_3_13_valid (_slices_3_io_msStatus_13_valid),
    .io_msStatus_3_13_bits_set (_slices_3_io_msStatus_13_bits_set),
    .io_msStatus_3_13_bits_tag (_slices_3_io_msStatus_13_bits_tag),
    .io_msStatus_3_13_bits_opcode (_slices_3_io_msStatus_13_bits_opcode),
    .io_msStatus_3_13_bits_is_miss (_slices_3_io_msStatus_13_bits_is_miss),
    .io_msStatus_3_14_valid (_slices_3_io_msStatus_14_valid),
    .io_msStatus_3_14_bits_set (_slices_3_io_msStatus_14_bits_set),
    .io_msStatus_3_14_bits_tag (_slices_3_io_msStatus_14_bits_tag),
    .io_msStatus_3_14_bits_opcode (_slices_3_io_msStatus_14_bits_opcode),
    .io_msStatus_3_14_bits_is_miss (_slices_3_io_msStatus_14_bits_is_miss),
    .io_msStatus_3_15_valid (_slices_3_io_msStatus_15_valid),
    .io_msStatus_3_15_bits_set (_slices_3_io_msStatus_15_bits_set),
    .io_msStatus_3_15_bits_tag (_slices_3_io_msStatus_15_bits_tag),
    .io_msStatus_3_15_bits_opcode (_slices_3_io_msStatus_15_bits_opcode),
    .io_msStatus_3_15_bits_is_miss (_slices_3_io_msStatus_15_bits_is_miss),
    .io_debugTopDown_robHeadPaddr_0_valid (io_debugTopDown_robHeadPaddr_0_valid),
    .io_debugTopDown_robHeadPaddr_0_bits (io_debugTopDown_robHeadPaddr_0_bits),
    .io_debugTopDown_addrMatch_0 (_topDown_io_debugTopDown_addrMatch_0)
  );
// ---- §7 LLC slice ×4 例化（slices_0..3）+ rnLinkMonitor --------------------
  Slice_4 slices_0 (
    .clock (clock),
    .reset (reset),
    .io_in_tx_req_ready (_slices_0_io_in_tx_req_ready),
    .io_in_tx_req_valid (_rnXbar_io_out_0_tx_req_valid),
    .io_in_tx_req_bits_tgtID (_rnXbar_io_out_0_tx_req_bits_tgtID),
    .io_in_tx_req_bits_srcID (_rnXbar_io_out_0_tx_req_bits_srcID),
    .io_in_tx_req_bits_txnID (_rnXbar_io_out_0_tx_req_bits_txnID),
    .io_in_tx_req_bits_opcode (_rnXbar_io_out_0_tx_req_bits_opcode),
    .io_in_tx_req_bits_size (_rnXbar_io_out_0_tx_req_bits_size),
    .io_in_tx_req_bits_addr (_rnXbar_io_out_0_tx_req_bits_addr),
    .io_in_tx_req_bits_allowRetry (_rnXbar_io_out_0_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order (_rnXbar_io_out_0_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType (_rnXbar_io_out_0_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate (_rnXbar_io_out_0_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_0_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device (_rnXbar_io_out_0_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa (_rnXbar_io_out_0_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr (_rnXbar_io_out_0_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_expCompAck (_rnXbar_io_out_0_tx_req_bits_expCompAck),
    .io_in_tx_rsp_valid (_rnXbar_io_out_0_tx_rsp_valid),
    .io_in_tx_rsp_bits_srcID (_rnXbar_io_out_0_tx_rsp_bits_srcID),
    .io_in_tx_rsp_bits_txnID (_rnXbar_io_out_0_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode (_rnXbar_io_out_0_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_dbID (_rnXbar_io_out_0_tx_rsp_bits_dbID),
    .io_in_tx_dat_valid (_rnXbar_io_out_0_tx_dat_valid),
    .io_in_tx_dat_bits_srcID (_rnXbar_io_out_0_tx_dat_bits_srcID),
    .io_in_tx_dat_bits_txnID (_rnXbar_io_out_0_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_opcode (_rnXbar_io_out_0_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_resp (_rnXbar_io_out_0_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataID (_rnXbar_io_out_0_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_data (_rnXbar_io_out_0_tx_dat_bits_data),
    .io_in_rx_rsp_ready (_rnXbar_io_out_0_rx_rsp_ready),
    .io_in_rx_rsp_valid (_slices_0_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_tgtID (_slices_0_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID (_slices_0_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID (_slices_0_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode (_slices_0_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_resp (_slices_0_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState (_slices_0_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_dbID (_slices_0_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType (_slices_0_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_dat_ready (_rnXbar_io_out_0_rx_dat_ready),
    .io_in_rx_dat_valid (_slices_0_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_tgtID (_slices_0_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID (_slices_0_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID (_slices_0_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID (_slices_0_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode (_slices_0_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_resp (_slices_0_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource (_slices_0_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_dbID (_slices_0_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_dataID (_slices_0_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_be (_slices_0_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data (_slices_0_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck (_slices_0_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_snp_ready (_rnXbar_io_out_0_rx_snp_ready),
    .io_in_rx_snp_valid (_slices_0_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_txnID (_slices_0_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID (_slices_0_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID (_slices_0_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode (_slices_0_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr (_slices_0_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_doNotGoToSD (_slices_0_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc (_slices_0_io_in_rx_snp_bits_retToSrc),
    .io_out_tx_req_ready (_snXbar_io_in_0_tx_req_ready),
    .io_out_tx_req_valid (_slices_0_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID (_slices_0_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID (_slices_0_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID (_slices_0_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode (_slices_0_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size (_slices_0_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr (_slices_0_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry (_slices_0_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order (_slices_0_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType (_slices_0_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate (_slices_0_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable (_slices_0_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device (_slices_0_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa (_slices_0_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr (_slices_0_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck (_slices_0_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready (_snXbar_io_in_0_tx_dat_ready),
    .io_out_tx_dat_valid (_slices_0_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID (_slices_0_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID (_slices_0_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID (_slices_0_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID (_slices_0_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode (_slices_0_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp (_slices_0_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource (_slices_0_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID (_slices_0_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID (_slices_0_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be (_slices_0_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data (_slices_0_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck (_slices_0_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_valid (_snXbar_io_in_0_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID (_snXbar_io_in_0_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID (_snXbar_io_in_0_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode (_snXbar_io_in_0_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID (_snXbar_io_in_0_rx_rsp_bits_dbID),
    .io_out_rx_dat_valid (_snXbar_io_in_0_rx_dat_valid),
    .io_out_rx_dat_bits_srcID (_snXbar_io_in_0_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID (_snXbar_io_in_0_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode (_snXbar_io_in_0_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp (_snXbar_io_in_0_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID (_snXbar_io_in_0_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data (_snXbar_io_in_0_rx_dat_bits_data),
    .io_snpMask_0 (_slices_0_io_snpMask_0),
    .io_msStatus_0_valid (_slices_0_io_msStatus_0_valid),
    .io_msStatus_0_bits_set (_slices_0_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_tag (_slices_0_io_msStatus_0_bits_tag),
    .io_msStatus_0_bits_opcode (_slices_0_io_msStatus_0_bits_opcode),
    .io_msStatus_0_bits_is_miss (_slices_0_io_msStatus_0_bits_is_miss),
    .io_msStatus_1_valid (_slices_0_io_msStatus_1_valid),
    .io_msStatus_1_bits_set (_slices_0_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_tag (_slices_0_io_msStatus_1_bits_tag),
    .io_msStatus_1_bits_opcode (_slices_0_io_msStatus_1_bits_opcode),
    .io_msStatus_1_bits_is_miss (_slices_0_io_msStatus_1_bits_is_miss),
    .io_msStatus_2_valid (_slices_0_io_msStatus_2_valid),
    .io_msStatus_2_bits_set (_slices_0_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_tag (_slices_0_io_msStatus_2_bits_tag),
    .io_msStatus_2_bits_opcode (_slices_0_io_msStatus_2_bits_opcode),
    .io_msStatus_2_bits_is_miss (_slices_0_io_msStatus_2_bits_is_miss),
    .io_msStatus_3_valid (_slices_0_io_msStatus_3_valid),
    .io_msStatus_3_bits_set (_slices_0_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_tag (_slices_0_io_msStatus_3_bits_tag),
    .io_msStatus_3_bits_opcode (_slices_0_io_msStatus_3_bits_opcode),
    .io_msStatus_3_bits_is_miss (_slices_0_io_msStatus_3_bits_is_miss),
    .io_msStatus_4_valid (_slices_0_io_msStatus_4_valid),
    .io_msStatus_4_bits_set (_slices_0_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_tag (_slices_0_io_msStatus_4_bits_tag),
    .io_msStatus_4_bits_opcode (_slices_0_io_msStatus_4_bits_opcode),
    .io_msStatus_4_bits_is_miss (_slices_0_io_msStatus_4_bits_is_miss),
    .io_msStatus_5_valid (_slices_0_io_msStatus_5_valid),
    .io_msStatus_5_bits_set (_slices_0_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_tag (_slices_0_io_msStatus_5_bits_tag),
    .io_msStatus_5_bits_opcode (_slices_0_io_msStatus_5_bits_opcode),
    .io_msStatus_5_bits_is_miss (_slices_0_io_msStatus_5_bits_is_miss),
    .io_msStatus_6_valid (_slices_0_io_msStatus_6_valid),
    .io_msStatus_6_bits_set (_slices_0_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_tag (_slices_0_io_msStatus_6_bits_tag),
    .io_msStatus_6_bits_opcode (_slices_0_io_msStatus_6_bits_opcode),
    .io_msStatus_6_bits_is_miss (_slices_0_io_msStatus_6_bits_is_miss),
    .io_msStatus_7_valid (_slices_0_io_msStatus_7_valid),
    .io_msStatus_7_bits_set (_slices_0_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_tag (_slices_0_io_msStatus_7_bits_tag),
    .io_msStatus_7_bits_opcode (_slices_0_io_msStatus_7_bits_opcode),
    .io_msStatus_7_bits_is_miss (_slices_0_io_msStatus_7_bits_is_miss),
    .io_msStatus_8_valid (_slices_0_io_msStatus_8_valid),
    .io_msStatus_8_bits_set (_slices_0_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_tag (_slices_0_io_msStatus_8_bits_tag),
    .io_msStatus_8_bits_opcode (_slices_0_io_msStatus_8_bits_opcode),
    .io_msStatus_8_bits_is_miss (_slices_0_io_msStatus_8_bits_is_miss),
    .io_msStatus_9_valid (_slices_0_io_msStatus_9_valid),
    .io_msStatus_9_bits_set (_slices_0_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_tag (_slices_0_io_msStatus_9_bits_tag),
    .io_msStatus_9_bits_opcode (_slices_0_io_msStatus_9_bits_opcode),
    .io_msStatus_9_bits_is_miss (_slices_0_io_msStatus_9_bits_is_miss),
    .io_msStatus_10_valid (_slices_0_io_msStatus_10_valid),
    .io_msStatus_10_bits_set (_slices_0_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_tag (_slices_0_io_msStatus_10_bits_tag),
    .io_msStatus_10_bits_opcode (_slices_0_io_msStatus_10_bits_opcode),
    .io_msStatus_10_bits_is_miss (_slices_0_io_msStatus_10_bits_is_miss),
    .io_msStatus_11_valid (_slices_0_io_msStatus_11_valid),
    .io_msStatus_11_bits_set (_slices_0_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_tag (_slices_0_io_msStatus_11_bits_tag),
    .io_msStatus_11_bits_opcode (_slices_0_io_msStatus_11_bits_opcode),
    .io_msStatus_11_bits_is_miss (_slices_0_io_msStatus_11_bits_is_miss),
    .io_msStatus_12_valid (_slices_0_io_msStatus_12_valid),
    .io_msStatus_12_bits_set (_slices_0_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_tag (_slices_0_io_msStatus_12_bits_tag),
    .io_msStatus_12_bits_opcode (_slices_0_io_msStatus_12_bits_opcode),
    .io_msStatus_12_bits_is_miss (_slices_0_io_msStatus_12_bits_is_miss),
    .io_msStatus_13_valid (_slices_0_io_msStatus_13_valid),
    .io_msStatus_13_bits_set (_slices_0_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_tag (_slices_0_io_msStatus_13_bits_tag),
    .io_msStatus_13_bits_opcode (_slices_0_io_msStatus_13_bits_opcode),
    .io_msStatus_13_bits_is_miss (_slices_0_io_msStatus_13_bits_is_miss),
    .io_msStatus_14_valid (_slices_0_io_msStatus_14_valid),
    .io_msStatus_14_bits_set (_slices_0_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_tag (_slices_0_io_msStatus_14_bits_tag),
    .io_msStatus_14_bits_opcode (_slices_0_io_msStatus_14_bits_opcode),
    .io_msStatus_14_bits_is_miss (_slices_0_io_msStatus_14_bits_is_miss),
    .io_msStatus_15_valid (_slices_0_io_msStatus_15_valid),
    .io_msStatus_15_bits_set (_slices_0_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_tag (_slices_0_io_msStatus_15_bits_tag),
    .io_msStatus_15_bits_opcode (_slices_0_io_msStatus_15_bits_opcode),
    .io_msStatus_15_bits_is_miss (_slices_0_io_msStatus_15_bits_is_miss),
    .io_l3Miss (_slices_0_io_l3Miss)
  );
  Slice_4 slices_1 (
    .clock (clock),
    .reset (reset),
    .io_in_tx_req_ready (_slices_1_io_in_tx_req_ready),
    .io_in_tx_req_valid (_rnXbar_io_out_1_tx_req_valid),
    .io_in_tx_req_bits_tgtID (_rnXbar_io_out_1_tx_req_bits_tgtID),
    .io_in_tx_req_bits_srcID (_rnXbar_io_out_1_tx_req_bits_srcID),
    .io_in_tx_req_bits_txnID (_rnXbar_io_out_1_tx_req_bits_txnID),
    .io_in_tx_req_bits_opcode (_rnXbar_io_out_1_tx_req_bits_opcode),
    .io_in_tx_req_bits_size (_rnXbar_io_out_1_tx_req_bits_size),
    .io_in_tx_req_bits_addr (_rnXbar_io_out_1_tx_req_bits_addr),
    .io_in_tx_req_bits_allowRetry (_rnXbar_io_out_1_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order (_rnXbar_io_out_1_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType (_rnXbar_io_out_1_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate (_rnXbar_io_out_1_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_1_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device (_rnXbar_io_out_1_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa (_rnXbar_io_out_1_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr (_rnXbar_io_out_1_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_expCompAck (_rnXbar_io_out_1_tx_req_bits_expCompAck),
    .io_in_tx_rsp_valid (_rnXbar_io_out_1_tx_rsp_valid),
    .io_in_tx_rsp_bits_srcID (_rnXbar_io_out_1_tx_rsp_bits_srcID),
    .io_in_tx_rsp_bits_txnID (_rnXbar_io_out_1_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode (_rnXbar_io_out_1_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_dbID (_rnXbar_io_out_1_tx_rsp_bits_dbID),
    .io_in_tx_dat_valid (_rnXbar_io_out_1_tx_dat_valid),
    .io_in_tx_dat_bits_srcID (_rnXbar_io_out_1_tx_dat_bits_srcID),
    .io_in_tx_dat_bits_txnID (_rnXbar_io_out_1_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_opcode (_rnXbar_io_out_1_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_resp (_rnXbar_io_out_1_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataID (_rnXbar_io_out_1_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_data (_rnXbar_io_out_1_tx_dat_bits_data),
    .io_in_rx_rsp_ready (_rnXbar_io_out_1_rx_rsp_ready),
    .io_in_rx_rsp_valid (_slices_1_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_tgtID (_slices_1_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID (_slices_1_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID (_slices_1_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode (_slices_1_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_resp (_slices_1_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState (_slices_1_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_dbID (_slices_1_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType (_slices_1_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_dat_ready (_rnXbar_io_out_1_rx_dat_ready),
    .io_in_rx_dat_valid (_slices_1_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_tgtID (_slices_1_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID (_slices_1_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID (_slices_1_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID (_slices_1_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode (_slices_1_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_resp (_slices_1_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource (_slices_1_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_dbID (_slices_1_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_dataID (_slices_1_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_be (_slices_1_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data (_slices_1_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck (_slices_1_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_snp_ready (_rnXbar_io_out_1_rx_snp_ready),
    .io_in_rx_snp_valid (_slices_1_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_txnID (_slices_1_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID (_slices_1_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID (_slices_1_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode (_slices_1_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr (_slices_1_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_doNotGoToSD (_slices_1_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc (_slices_1_io_in_rx_snp_bits_retToSrc),
    .io_out_tx_req_ready (_snXbar_io_in_1_tx_req_ready),
    .io_out_tx_req_valid (_slices_1_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID (_slices_1_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID (_slices_1_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID (_slices_1_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode (_slices_1_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size (_slices_1_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr (_slices_1_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry (_slices_1_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order (_slices_1_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType (_slices_1_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate (_slices_1_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable (_slices_1_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device (_slices_1_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa (_slices_1_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr (_slices_1_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck (_slices_1_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready (_snXbar_io_in_1_tx_dat_ready),
    .io_out_tx_dat_valid (_slices_1_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID (_slices_1_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID (_slices_1_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID (_slices_1_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID (_slices_1_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode (_slices_1_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp (_slices_1_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource (_slices_1_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID (_slices_1_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID (_slices_1_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be (_slices_1_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data (_slices_1_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck (_slices_1_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_valid (_snXbar_io_in_1_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID (_snXbar_io_in_1_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID (_snXbar_io_in_1_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode (_snXbar_io_in_1_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID (_snXbar_io_in_1_rx_rsp_bits_dbID),
    .io_out_rx_dat_valid (_snXbar_io_in_1_rx_dat_valid),
    .io_out_rx_dat_bits_srcID (_snXbar_io_in_1_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID (_snXbar_io_in_1_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode (_snXbar_io_in_1_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp (_snXbar_io_in_1_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID (_snXbar_io_in_1_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data (_snXbar_io_in_1_rx_dat_bits_data),
    .io_snpMask_0 (_slices_1_io_snpMask_0),
    .io_msStatus_0_valid (_slices_1_io_msStatus_0_valid),
    .io_msStatus_0_bits_set (_slices_1_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_tag (_slices_1_io_msStatus_0_bits_tag),
    .io_msStatus_0_bits_opcode (_slices_1_io_msStatus_0_bits_opcode),
    .io_msStatus_0_bits_is_miss (_slices_1_io_msStatus_0_bits_is_miss),
    .io_msStatus_1_valid (_slices_1_io_msStatus_1_valid),
    .io_msStatus_1_bits_set (_slices_1_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_tag (_slices_1_io_msStatus_1_bits_tag),
    .io_msStatus_1_bits_opcode (_slices_1_io_msStatus_1_bits_opcode),
    .io_msStatus_1_bits_is_miss (_slices_1_io_msStatus_1_bits_is_miss),
    .io_msStatus_2_valid (_slices_1_io_msStatus_2_valid),
    .io_msStatus_2_bits_set (_slices_1_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_tag (_slices_1_io_msStatus_2_bits_tag),
    .io_msStatus_2_bits_opcode (_slices_1_io_msStatus_2_bits_opcode),
    .io_msStatus_2_bits_is_miss (_slices_1_io_msStatus_2_bits_is_miss),
    .io_msStatus_3_valid (_slices_1_io_msStatus_3_valid),
    .io_msStatus_3_bits_set (_slices_1_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_tag (_slices_1_io_msStatus_3_bits_tag),
    .io_msStatus_3_bits_opcode (_slices_1_io_msStatus_3_bits_opcode),
    .io_msStatus_3_bits_is_miss (_slices_1_io_msStatus_3_bits_is_miss),
    .io_msStatus_4_valid (_slices_1_io_msStatus_4_valid),
    .io_msStatus_4_bits_set (_slices_1_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_tag (_slices_1_io_msStatus_4_bits_tag),
    .io_msStatus_4_bits_opcode (_slices_1_io_msStatus_4_bits_opcode),
    .io_msStatus_4_bits_is_miss (_slices_1_io_msStatus_4_bits_is_miss),
    .io_msStatus_5_valid (_slices_1_io_msStatus_5_valid),
    .io_msStatus_5_bits_set (_slices_1_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_tag (_slices_1_io_msStatus_5_bits_tag),
    .io_msStatus_5_bits_opcode (_slices_1_io_msStatus_5_bits_opcode),
    .io_msStatus_5_bits_is_miss (_slices_1_io_msStatus_5_bits_is_miss),
    .io_msStatus_6_valid (_slices_1_io_msStatus_6_valid),
    .io_msStatus_6_bits_set (_slices_1_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_tag (_slices_1_io_msStatus_6_bits_tag),
    .io_msStatus_6_bits_opcode (_slices_1_io_msStatus_6_bits_opcode),
    .io_msStatus_6_bits_is_miss (_slices_1_io_msStatus_6_bits_is_miss),
    .io_msStatus_7_valid (_slices_1_io_msStatus_7_valid),
    .io_msStatus_7_bits_set (_slices_1_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_tag (_slices_1_io_msStatus_7_bits_tag),
    .io_msStatus_7_bits_opcode (_slices_1_io_msStatus_7_bits_opcode),
    .io_msStatus_7_bits_is_miss (_slices_1_io_msStatus_7_bits_is_miss),
    .io_msStatus_8_valid (_slices_1_io_msStatus_8_valid),
    .io_msStatus_8_bits_set (_slices_1_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_tag (_slices_1_io_msStatus_8_bits_tag),
    .io_msStatus_8_bits_opcode (_slices_1_io_msStatus_8_bits_opcode),
    .io_msStatus_8_bits_is_miss (_slices_1_io_msStatus_8_bits_is_miss),
    .io_msStatus_9_valid (_slices_1_io_msStatus_9_valid),
    .io_msStatus_9_bits_set (_slices_1_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_tag (_slices_1_io_msStatus_9_bits_tag),
    .io_msStatus_9_bits_opcode (_slices_1_io_msStatus_9_bits_opcode),
    .io_msStatus_9_bits_is_miss (_slices_1_io_msStatus_9_bits_is_miss),
    .io_msStatus_10_valid (_slices_1_io_msStatus_10_valid),
    .io_msStatus_10_bits_set (_slices_1_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_tag (_slices_1_io_msStatus_10_bits_tag),
    .io_msStatus_10_bits_opcode (_slices_1_io_msStatus_10_bits_opcode),
    .io_msStatus_10_bits_is_miss (_slices_1_io_msStatus_10_bits_is_miss),
    .io_msStatus_11_valid (_slices_1_io_msStatus_11_valid),
    .io_msStatus_11_bits_set (_slices_1_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_tag (_slices_1_io_msStatus_11_bits_tag),
    .io_msStatus_11_bits_opcode (_slices_1_io_msStatus_11_bits_opcode),
    .io_msStatus_11_bits_is_miss (_slices_1_io_msStatus_11_bits_is_miss),
    .io_msStatus_12_valid (_slices_1_io_msStatus_12_valid),
    .io_msStatus_12_bits_set (_slices_1_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_tag (_slices_1_io_msStatus_12_bits_tag),
    .io_msStatus_12_bits_opcode (_slices_1_io_msStatus_12_bits_opcode),
    .io_msStatus_12_bits_is_miss (_slices_1_io_msStatus_12_bits_is_miss),
    .io_msStatus_13_valid (_slices_1_io_msStatus_13_valid),
    .io_msStatus_13_bits_set (_slices_1_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_tag (_slices_1_io_msStatus_13_bits_tag),
    .io_msStatus_13_bits_opcode (_slices_1_io_msStatus_13_bits_opcode),
    .io_msStatus_13_bits_is_miss (_slices_1_io_msStatus_13_bits_is_miss),
    .io_msStatus_14_valid (_slices_1_io_msStatus_14_valid),
    .io_msStatus_14_bits_set (_slices_1_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_tag (_slices_1_io_msStatus_14_bits_tag),
    .io_msStatus_14_bits_opcode (_slices_1_io_msStatus_14_bits_opcode),
    .io_msStatus_14_bits_is_miss (_slices_1_io_msStatus_14_bits_is_miss),
    .io_msStatus_15_valid (_slices_1_io_msStatus_15_valid),
    .io_msStatus_15_bits_set (_slices_1_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_tag (_slices_1_io_msStatus_15_bits_tag),
    .io_msStatus_15_bits_opcode (_slices_1_io_msStatus_15_bits_opcode),
    .io_msStatus_15_bits_is_miss (_slices_1_io_msStatus_15_bits_is_miss),
    .io_l3Miss (_slices_1_io_l3Miss)
  );
  Slice_4 slices_2 (
    .clock (clock),
    .reset (reset),
    .io_in_tx_req_ready (_slices_2_io_in_tx_req_ready),
    .io_in_tx_req_valid (_rnXbar_io_out_2_tx_req_valid),
    .io_in_tx_req_bits_tgtID (_rnXbar_io_out_2_tx_req_bits_tgtID),
    .io_in_tx_req_bits_srcID (_rnXbar_io_out_2_tx_req_bits_srcID),
    .io_in_tx_req_bits_txnID (_rnXbar_io_out_2_tx_req_bits_txnID),
    .io_in_tx_req_bits_opcode (_rnXbar_io_out_2_tx_req_bits_opcode),
    .io_in_tx_req_bits_size (_rnXbar_io_out_2_tx_req_bits_size),
    .io_in_tx_req_bits_addr (_rnXbar_io_out_2_tx_req_bits_addr),
    .io_in_tx_req_bits_allowRetry (_rnXbar_io_out_2_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order (_rnXbar_io_out_2_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType (_rnXbar_io_out_2_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate (_rnXbar_io_out_2_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_2_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device (_rnXbar_io_out_2_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa (_rnXbar_io_out_2_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr (_rnXbar_io_out_2_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_expCompAck (_rnXbar_io_out_2_tx_req_bits_expCompAck),
    .io_in_tx_rsp_valid (_rnXbar_io_out_2_tx_rsp_valid),
    .io_in_tx_rsp_bits_srcID (_rnXbar_io_out_2_tx_rsp_bits_srcID),
    .io_in_tx_rsp_bits_txnID (_rnXbar_io_out_2_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode (_rnXbar_io_out_2_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_dbID (_rnXbar_io_out_2_tx_rsp_bits_dbID),
    .io_in_tx_dat_valid (_rnXbar_io_out_2_tx_dat_valid),
    .io_in_tx_dat_bits_srcID (_rnXbar_io_out_2_tx_dat_bits_srcID),
    .io_in_tx_dat_bits_txnID (_rnXbar_io_out_2_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_opcode (_rnXbar_io_out_2_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_resp (_rnXbar_io_out_2_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataID (_rnXbar_io_out_2_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_data (_rnXbar_io_out_2_tx_dat_bits_data),
    .io_in_rx_rsp_ready (_rnXbar_io_out_2_rx_rsp_ready),
    .io_in_rx_rsp_valid (_slices_2_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_tgtID (_slices_2_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID (_slices_2_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID (_slices_2_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode (_slices_2_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_resp (_slices_2_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState (_slices_2_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_dbID (_slices_2_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType (_slices_2_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_dat_ready (_rnXbar_io_out_2_rx_dat_ready),
    .io_in_rx_dat_valid (_slices_2_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_tgtID (_slices_2_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID (_slices_2_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID (_slices_2_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID (_slices_2_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode (_slices_2_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_resp (_slices_2_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource (_slices_2_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_dbID (_slices_2_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_dataID (_slices_2_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_be (_slices_2_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data (_slices_2_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck (_slices_2_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_snp_ready (_rnXbar_io_out_2_rx_snp_ready),
    .io_in_rx_snp_valid (_slices_2_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_txnID (_slices_2_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID (_slices_2_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID (_slices_2_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode (_slices_2_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr (_slices_2_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_doNotGoToSD (_slices_2_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc (_slices_2_io_in_rx_snp_bits_retToSrc),
    .io_out_tx_req_ready (_snXbar_io_in_2_tx_req_ready),
    .io_out_tx_req_valid (_slices_2_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID (_slices_2_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID (_slices_2_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID (_slices_2_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode (_slices_2_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size (_slices_2_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr (_slices_2_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry (_slices_2_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order (_slices_2_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType (_slices_2_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate (_slices_2_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable (_slices_2_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device (_slices_2_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa (_slices_2_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr (_slices_2_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck (_slices_2_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready (_snXbar_io_in_2_tx_dat_ready),
    .io_out_tx_dat_valid (_slices_2_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID (_slices_2_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID (_slices_2_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID (_slices_2_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID (_slices_2_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode (_slices_2_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp (_slices_2_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource (_slices_2_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID (_slices_2_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID (_slices_2_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be (_slices_2_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data (_slices_2_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck (_slices_2_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_valid (_snXbar_io_in_2_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID (_snXbar_io_in_2_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID (_snXbar_io_in_2_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode (_snXbar_io_in_2_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID (_snXbar_io_in_2_rx_rsp_bits_dbID),
    .io_out_rx_dat_valid (_snXbar_io_in_2_rx_dat_valid),
    .io_out_rx_dat_bits_srcID (_snXbar_io_in_2_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID (_snXbar_io_in_2_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode (_snXbar_io_in_2_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp (_snXbar_io_in_2_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID (_snXbar_io_in_2_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data (_snXbar_io_in_2_rx_dat_bits_data),
    .io_snpMask_0 (_slices_2_io_snpMask_0),
    .io_msStatus_0_valid (_slices_2_io_msStatus_0_valid),
    .io_msStatus_0_bits_set (_slices_2_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_tag (_slices_2_io_msStatus_0_bits_tag),
    .io_msStatus_0_bits_opcode (_slices_2_io_msStatus_0_bits_opcode),
    .io_msStatus_0_bits_is_miss (_slices_2_io_msStatus_0_bits_is_miss),
    .io_msStatus_1_valid (_slices_2_io_msStatus_1_valid),
    .io_msStatus_1_bits_set (_slices_2_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_tag (_slices_2_io_msStatus_1_bits_tag),
    .io_msStatus_1_bits_opcode (_slices_2_io_msStatus_1_bits_opcode),
    .io_msStatus_1_bits_is_miss (_slices_2_io_msStatus_1_bits_is_miss),
    .io_msStatus_2_valid (_slices_2_io_msStatus_2_valid),
    .io_msStatus_2_bits_set (_slices_2_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_tag (_slices_2_io_msStatus_2_bits_tag),
    .io_msStatus_2_bits_opcode (_slices_2_io_msStatus_2_bits_opcode),
    .io_msStatus_2_bits_is_miss (_slices_2_io_msStatus_2_bits_is_miss),
    .io_msStatus_3_valid (_slices_2_io_msStatus_3_valid),
    .io_msStatus_3_bits_set (_slices_2_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_tag (_slices_2_io_msStatus_3_bits_tag),
    .io_msStatus_3_bits_opcode (_slices_2_io_msStatus_3_bits_opcode),
    .io_msStatus_3_bits_is_miss (_slices_2_io_msStatus_3_bits_is_miss),
    .io_msStatus_4_valid (_slices_2_io_msStatus_4_valid),
    .io_msStatus_4_bits_set (_slices_2_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_tag (_slices_2_io_msStatus_4_bits_tag),
    .io_msStatus_4_bits_opcode (_slices_2_io_msStatus_4_bits_opcode),
    .io_msStatus_4_bits_is_miss (_slices_2_io_msStatus_4_bits_is_miss),
    .io_msStatus_5_valid (_slices_2_io_msStatus_5_valid),
    .io_msStatus_5_bits_set (_slices_2_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_tag (_slices_2_io_msStatus_5_bits_tag),
    .io_msStatus_5_bits_opcode (_slices_2_io_msStatus_5_bits_opcode),
    .io_msStatus_5_bits_is_miss (_slices_2_io_msStatus_5_bits_is_miss),
    .io_msStatus_6_valid (_slices_2_io_msStatus_6_valid),
    .io_msStatus_6_bits_set (_slices_2_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_tag (_slices_2_io_msStatus_6_bits_tag),
    .io_msStatus_6_bits_opcode (_slices_2_io_msStatus_6_bits_opcode),
    .io_msStatus_6_bits_is_miss (_slices_2_io_msStatus_6_bits_is_miss),
    .io_msStatus_7_valid (_slices_2_io_msStatus_7_valid),
    .io_msStatus_7_bits_set (_slices_2_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_tag (_slices_2_io_msStatus_7_bits_tag),
    .io_msStatus_7_bits_opcode (_slices_2_io_msStatus_7_bits_opcode),
    .io_msStatus_7_bits_is_miss (_slices_2_io_msStatus_7_bits_is_miss),
    .io_msStatus_8_valid (_slices_2_io_msStatus_8_valid),
    .io_msStatus_8_bits_set (_slices_2_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_tag (_slices_2_io_msStatus_8_bits_tag),
    .io_msStatus_8_bits_opcode (_slices_2_io_msStatus_8_bits_opcode),
    .io_msStatus_8_bits_is_miss (_slices_2_io_msStatus_8_bits_is_miss),
    .io_msStatus_9_valid (_slices_2_io_msStatus_9_valid),
    .io_msStatus_9_bits_set (_slices_2_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_tag (_slices_2_io_msStatus_9_bits_tag),
    .io_msStatus_9_bits_opcode (_slices_2_io_msStatus_9_bits_opcode),
    .io_msStatus_9_bits_is_miss (_slices_2_io_msStatus_9_bits_is_miss),
    .io_msStatus_10_valid (_slices_2_io_msStatus_10_valid),
    .io_msStatus_10_bits_set (_slices_2_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_tag (_slices_2_io_msStatus_10_bits_tag),
    .io_msStatus_10_bits_opcode (_slices_2_io_msStatus_10_bits_opcode),
    .io_msStatus_10_bits_is_miss (_slices_2_io_msStatus_10_bits_is_miss),
    .io_msStatus_11_valid (_slices_2_io_msStatus_11_valid),
    .io_msStatus_11_bits_set (_slices_2_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_tag (_slices_2_io_msStatus_11_bits_tag),
    .io_msStatus_11_bits_opcode (_slices_2_io_msStatus_11_bits_opcode),
    .io_msStatus_11_bits_is_miss (_slices_2_io_msStatus_11_bits_is_miss),
    .io_msStatus_12_valid (_slices_2_io_msStatus_12_valid),
    .io_msStatus_12_bits_set (_slices_2_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_tag (_slices_2_io_msStatus_12_bits_tag),
    .io_msStatus_12_bits_opcode (_slices_2_io_msStatus_12_bits_opcode),
    .io_msStatus_12_bits_is_miss (_slices_2_io_msStatus_12_bits_is_miss),
    .io_msStatus_13_valid (_slices_2_io_msStatus_13_valid),
    .io_msStatus_13_bits_set (_slices_2_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_tag (_slices_2_io_msStatus_13_bits_tag),
    .io_msStatus_13_bits_opcode (_slices_2_io_msStatus_13_bits_opcode),
    .io_msStatus_13_bits_is_miss (_slices_2_io_msStatus_13_bits_is_miss),
    .io_msStatus_14_valid (_slices_2_io_msStatus_14_valid),
    .io_msStatus_14_bits_set (_slices_2_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_tag (_slices_2_io_msStatus_14_bits_tag),
    .io_msStatus_14_bits_opcode (_slices_2_io_msStatus_14_bits_opcode),
    .io_msStatus_14_bits_is_miss (_slices_2_io_msStatus_14_bits_is_miss),
    .io_msStatus_15_valid (_slices_2_io_msStatus_15_valid),
    .io_msStatus_15_bits_set (_slices_2_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_tag (_slices_2_io_msStatus_15_bits_tag),
    .io_msStatus_15_bits_opcode (_slices_2_io_msStatus_15_bits_opcode),
    .io_msStatus_15_bits_is_miss (_slices_2_io_msStatus_15_bits_is_miss),
    .io_l3Miss (_slices_2_io_l3Miss)
  );
  Slice_4 slices_3 (
    .clock (clock),
    .reset (reset),
    .io_in_tx_req_ready (_slices_3_io_in_tx_req_ready),
    .io_in_tx_req_valid (_rnXbar_io_out_3_tx_req_valid),
    .io_in_tx_req_bits_tgtID (_rnXbar_io_out_3_tx_req_bits_tgtID),
    .io_in_tx_req_bits_srcID (_rnXbar_io_out_3_tx_req_bits_srcID),
    .io_in_tx_req_bits_txnID (_rnXbar_io_out_3_tx_req_bits_txnID),
    .io_in_tx_req_bits_opcode (_rnXbar_io_out_3_tx_req_bits_opcode),
    .io_in_tx_req_bits_size (_rnXbar_io_out_3_tx_req_bits_size),
    .io_in_tx_req_bits_addr (_rnXbar_io_out_3_tx_req_bits_addr),
    .io_in_tx_req_bits_allowRetry (_rnXbar_io_out_3_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order (_rnXbar_io_out_3_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType (_rnXbar_io_out_3_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate (_rnXbar_io_out_3_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable (_rnXbar_io_out_3_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device (_rnXbar_io_out_3_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa (_rnXbar_io_out_3_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr (_rnXbar_io_out_3_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_expCompAck (_rnXbar_io_out_3_tx_req_bits_expCompAck),
    .io_in_tx_rsp_valid (_rnXbar_io_out_3_tx_rsp_valid),
    .io_in_tx_rsp_bits_srcID (_rnXbar_io_out_3_tx_rsp_bits_srcID),
    .io_in_tx_rsp_bits_txnID (_rnXbar_io_out_3_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode (_rnXbar_io_out_3_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_dbID (_rnXbar_io_out_3_tx_rsp_bits_dbID),
    .io_in_tx_dat_valid (_rnXbar_io_out_3_tx_dat_valid),
    .io_in_tx_dat_bits_srcID (_rnXbar_io_out_3_tx_dat_bits_srcID),
    .io_in_tx_dat_bits_txnID (_rnXbar_io_out_3_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_opcode (_rnXbar_io_out_3_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_resp (_rnXbar_io_out_3_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataID (_rnXbar_io_out_3_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_data (_rnXbar_io_out_3_tx_dat_bits_data),
    .io_in_rx_rsp_ready (_rnXbar_io_out_3_rx_rsp_ready),
    .io_in_rx_rsp_valid (_slices_3_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_tgtID (_slices_3_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID (_slices_3_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID (_slices_3_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode (_slices_3_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_resp (_slices_3_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState (_slices_3_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_dbID (_slices_3_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType (_slices_3_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_dat_ready (_rnXbar_io_out_3_rx_dat_ready),
    .io_in_rx_dat_valid (_slices_3_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_tgtID (_slices_3_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID (_slices_3_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID (_slices_3_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID (_slices_3_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode (_slices_3_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_resp (_slices_3_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource (_slices_3_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_dbID (_slices_3_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_dataID (_slices_3_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_be (_slices_3_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data (_slices_3_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck (_slices_3_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_snp_ready (_rnXbar_io_out_3_rx_snp_ready),
    .io_in_rx_snp_valid (_slices_3_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_txnID (_slices_3_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID (_slices_3_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID (_slices_3_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode (_slices_3_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr (_slices_3_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_doNotGoToSD (_slices_3_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc (_slices_3_io_in_rx_snp_bits_retToSrc),
    .io_out_tx_req_ready (_snXbar_io_in_3_tx_req_ready),
    .io_out_tx_req_valid (_slices_3_io_out_tx_req_valid),
    .io_out_tx_req_bits_tgtID (_slices_3_io_out_tx_req_bits_tgtID),
    .io_out_tx_req_bits_srcID (_slices_3_io_out_tx_req_bits_srcID),
    .io_out_tx_req_bits_txnID (_slices_3_io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_opcode (_slices_3_io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_size (_slices_3_io_out_tx_req_bits_size),
    .io_out_tx_req_bits_addr (_slices_3_io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_allowRetry (_slices_3_io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order (_slices_3_io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType (_slices_3_io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate (_slices_3_io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable (_slices_3_io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device (_slices_3_io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa (_slices_3_io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr (_slices_3_io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_expCompAck (_slices_3_io_out_tx_req_bits_expCompAck),
    .io_out_tx_dat_ready (_snXbar_io_in_3_tx_dat_ready),
    .io_out_tx_dat_valid (_slices_3_io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID (_slices_3_io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_srcID (_slices_3_io_out_tx_dat_bits_srcID),
    .io_out_tx_dat_bits_txnID (_slices_3_io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID (_slices_3_io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode (_slices_3_io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_resp (_slices_3_io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource (_slices_3_io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID (_slices_3_io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_dataID (_slices_3_io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_be (_slices_3_io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data (_slices_3_io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck (_slices_3_io_out_tx_dat_bits_dataCheck),
    .io_out_rx_rsp_valid (_snXbar_io_in_3_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID (_snXbar_io_in_3_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID (_snXbar_io_in_3_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode (_snXbar_io_in_3_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_dbID (_snXbar_io_in_3_rx_rsp_bits_dbID),
    .io_out_rx_dat_valid (_snXbar_io_in_3_rx_dat_valid),
    .io_out_rx_dat_bits_srcID (_snXbar_io_in_3_rx_dat_bits_srcID),
    .io_out_rx_dat_bits_txnID (_snXbar_io_in_3_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_opcode (_snXbar_io_in_3_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_resp (_snXbar_io_in_3_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dataID (_snXbar_io_in_3_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_data (_snXbar_io_in_3_rx_dat_bits_data),
    .io_snpMask_0 (_slices_3_io_snpMask_0),
    .io_msStatus_0_valid (_slices_3_io_msStatus_0_valid),
    .io_msStatus_0_bits_set (_slices_3_io_msStatus_0_bits_set),
    .io_msStatus_0_bits_tag (_slices_3_io_msStatus_0_bits_tag),
    .io_msStatus_0_bits_opcode (_slices_3_io_msStatus_0_bits_opcode),
    .io_msStatus_0_bits_is_miss (_slices_3_io_msStatus_0_bits_is_miss),
    .io_msStatus_1_valid (_slices_3_io_msStatus_1_valid),
    .io_msStatus_1_bits_set (_slices_3_io_msStatus_1_bits_set),
    .io_msStatus_1_bits_tag (_slices_3_io_msStatus_1_bits_tag),
    .io_msStatus_1_bits_opcode (_slices_3_io_msStatus_1_bits_opcode),
    .io_msStatus_1_bits_is_miss (_slices_3_io_msStatus_1_bits_is_miss),
    .io_msStatus_2_valid (_slices_3_io_msStatus_2_valid),
    .io_msStatus_2_bits_set (_slices_3_io_msStatus_2_bits_set),
    .io_msStatus_2_bits_tag (_slices_3_io_msStatus_2_bits_tag),
    .io_msStatus_2_bits_opcode (_slices_3_io_msStatus_2_bits_opcode),
    .io_msStatus_2_bits_is_miss (_slices_3_io_msStatus_2_bits_is_miss),
    .io_msStatus_3_valid (_slices_3_io_msStatus_3_valid),
    .io_msStatus_3_bits_set (_slices_3_io_msStatus_3_bits_set),
    .io_msStatus_3_bits_tag (_slices_3_io_msStatus_3_bits_tag),
    .io_msStatus_3_bits_opcode (_slices_3_io_msStatus_3_bits_opcode),
    .io_msStatus_3_bits_is_miss (_slices_3_io_msStatus_3_bits_is_miss),
    .io_msStatus_4_valid (_slices_3_io_msStatus_4_valid),
    .io_msStatus_4_bits_set (_slices_3_io_msStatus_4_bits_set),
    .io_msStatus_4_bits_tag (_slices_3_io_msStatus_4_bits_tag),
    .io_msStatus_4_bits_opcode (_slices_3_io_msStatus_4_bits_opcode),
    .io_msStatus_4_bits_is_miss (_slices_3_io_msStatus_4_bits_is_miss),
    .io_msStatus_5_valid (_slices_3_io_msStatus_5_valid),
    .io_msStatus_5_bits_set (_slices_3_io_msStatus_5_bits_set),
    .io_msStatus_5_bits_tag (_slices_3_io_msStatus_5_bits_tag),
    .io_msStatus_5_bits_opcode (_slices_3_io_msStatus_5_bits_opcode),
    .io_msStatus_5_bits_is_miss (_slices_3_io_msStatus_5_bits_is_miss),
    .io_msStatus_6_valid (_slices_3_io_msStatus_6_valid),
    .io_msStatus_6_bits_set (_slices_3_io_msStatus_6_bits_set),
    .io_msStatus_6_bits_tag (_slices_3_io_msStatus_6_bits_tag),
    .io_msStatus_6_bits_opcode (_slices_3_io_msStatus_6_bits_opcode),
    .io_msStatus_6_bits_is_miss (_slices_3_io_msStatus_6_bits_is_miss),
    .io_msStatus_7_valid (_slices_3_io_msStatus_7_valid),
    .io_msStatus_7_bits_set (_slices_3_io_msStatus_7_bits_set),
    .io_msStatus_7_bits_tag (_slices_3_io_msStatus_7_bits_tag),
    .io_msStatus_7_bits_opcode (_slices_3_io_msStatus_7_bits_opcode),
    .io_msStatus_7_bits_is_miss (_slices_3_io_msStatus_7_bits_is_miss),
    .io_msStatus_8_valid (_slices_3_io_msStatus_8_valid),
    .io_msStatus_8_bits_set (_slices_3_io_msStatus_8_bits_set),
    .io_msStatus_8_bits_tag (_slices_3_io_msStatus_8_bits_tag),
    .io_msStatus_8_bits_opcode (_slices_3_io_msStatus_8_bits_opcode),
    .io_msStatus_8_bits_is_miss (_slices_3_io_msStatus_8_bits_is_miss),
    .io_msStatus_9_valid (_slices_3_io_msStatus_9_valid),
    .io_msStatus_9_bits_set (_slices_3_io_msStatus_9_bits_set),
    .io_msStatus_9_bits_tag (_slices_3_io_msStatus_9_bits_tag),
    .io_msStatus_9_bits_opcode (_slices_3_io_msStatus_9_bits_opcode),
    .io_msStatus_9_bits_is_miss (_slices_3_io_msStatus_9_bits_is_miss),
    .io_msStatus_10_valid (_slices_3_io_msStatus_10_valid),
    .io_msStatus_10_bits_set (_slices_3_io_msStatus_10_bits_set),
    .io_msStatus_10_bits_tag (_slices_3_io_msStatus_10_bits_tag),
    .io_msStatus_10_bits_opcode (_slices_3_io_msStatus_10_bits_opcode),
    .io_msStatus_10_bits_is_miss (_slices_3_io_msStatus_10_bits_is_miss),
    .io_msStatus_11_valid (_slices_3_io_msStatus_11_valid),
    .io_msStatus_11_bits_set (_slices_3_io_msStatus_11_bits_set),
    .io_msStatus_11_bits_tag (_slices_3_io_msStatus_11_bits_tag),
    .io_msStatus_11_bits_opcode (_slices_3_io_msStatus_11_bits_opcode),
    .io_msStatus_11_bits_is_miss (_slices_3_io_msStatus_11_bits_is_miss),
    .io_msStatus_12_valid (_slices_3_io_msStatus_12_valid),
    .io_msStatus_12_bits_set (_slices_3_io_msStatus_12_bits_set),
    .io_msStatus_12_bits_tag (_slices_3_io_msStatus_12_bits_tag),
    .io_msStatus_12_bits_opcode (_slices_3_io_msStatus_12_bits_opcode),
    .io_msStatus_12_bits_is_miss (_slices_3_io_msStatus_12_bits_is_miss),
    .io_msStatus_13_valid (_slices_3_io_msStatus_13_valid),
    .io_msStatus_13_bits_set (_slices_3_io_msStatus_13_bits_set),
    .io_msStatus_13_bits_tag (_slices_3_io_msStatus_13_bits_tag),
    .io_msStatus_13_bits_opcode (_slices_3_io_msStatus_13_bits_opcode),
    .io_msStatus_13_bits_is_miss (_slices_3_io_msStatus_13_bits_is_miss),
    .io_msStatus_14_valid (_slices_3_io_msStatus_14_valid),
    .io_msStatus_14_bits_set (_slices_3_io_msStatus_14_bits_set),
    .io_msStatus_14_bits_tag (_slices_3_io_msStatus_14_bits_tag),
    .io_msStatus_14_bits_opcode (_slices_3_io_msStatus_14_bits_opcode),
    .io_msStatus_14_bits_is_miss (_slices_3_io_msStatus_14_bits_is_miss),
    .io_msStatus_15_valid (_slices_3_io_msStatus_15_valid),
    .io_msStatus_15_bits_set (_slices_3_io_msStatus_15_bits_set),
    .io_msStatus_15_bits_tag (_slices_3_io_msStatus_15_bits_tag),
    .io_msStatus_15_bits_opcode (_slices_3_io_msStatus_15_bits_opcode),
    .io_msStatus_15_bits_is_miss (_slices_3_io_msStatus_15_bits_is_miss),
    .io_l3Miss (_slices_3_io_l3Miss)
  );
  RNLinkMonitor rnLinkMonitor (
    .clock (clock),
    .reset (reset),
    .io_in_tx_req_ready (_mmioDiverger_io_in_0_tx_req_ready),
    .io_in_tx_req_valid (_rnLinkMonitor_io_in_tx_req_valid),
    .io_in_tx_req_bits_qos (_rnLinkMonitor_io_in_tx_req_bits_qos),
    .io_in_tx_req_bits_tgtID (_rnLinkMonitor_io_in_tx_req_bits_tgtID),
    .io_in_tx_req_bits_srcID (_rnLinkMonitor_io_in_tx_req_bits_srcID),
    .io_in_tx_req_bits_txnID (_rnLinkMonitor_io_in_tx_req_bits_txnID),
    .io_in_tx_req_bits_returnNID (_rnLinkMonitor_io_in_tx_req_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid (_rnLinkMonitor_io_in_tx_req_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID (_rnLinkMonitor_io_in_tx_req_bits_returnTxnID),
    .io_in_tx_req_bits_opcode (_rnLinkMonitor_io_in_tx_req_bits_opcode),
    .io_in_tx_req_bits_size (_rnLinkMonitor_io_in_tx_req_bits_size),
    .io_in_tx_req_bits_addr (_rnLinkMonitor_io_in_tx_req_bits_addr),
    .io_in_tx_req_bits_ns (_rnLinkMonitor_io_in_tx_req_bits_ns),
    .io_in_tx_req_bits_likelyshared (_rnLinkMonitor_io_in_tx_req_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry (_rnLinkMonitor_io_in_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order (_rnLinkMonitor_io_in_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType (_rnLinkMonitor_io_in_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate (_rnLinkMonitor_io_in_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable (_rnLinkMonitor_io_in_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device (_rnLinkMonitor_io_in_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa (_rnLinkMonitor_io_in_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr (_rnLinkMonitor_io_in_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding (_rnLinkMonitor_io_in_tx_req_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe (_rnLinkMonitor_io_in_tx_req_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck (_rnLinkMonitor_io_in_tx_req_bits_expCompAck),
    .io_in_tx_req_bits_tagOp (_rnLinkMonitor_io_in_tx_req_bits_tagOp),
    .io_in_tx_req_bits_traceTag (_rnLinkMonitor_io_in_tx_req_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup (_rnLinkMonitor_io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID (_rnLinkMonitor_io_in_tx_req_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS (_rnLinkMonitor_io_in_tx_req_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc (_rnLinkMonitor_io_in_tx_req_bits_rsvdc),
    .io_in_tx_rsp_ready (_mmioDiverger_io_in_0_tx_rsp_ready),
    .io_in_tx_rsp_valid (_rnLinkMonitor_io_in_tx_rsp_valid),
    .io_in_tx_rsp_bits_srcID (_rnLinkMonitor_io_in_tx_rsp_bits_srcID),
    .io_in_tx_rsp_bits_txnID (_rnLinkMonitor_io_in_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode (_rnLinkMonitor_io_in_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_dbID (_rnLinkMonitor_io_in_tx_rsp_bits_dbID),
    .io_in_tx_dat_ready (_mmioDiverger_io_in_0_tx_dat_ready),
    .io_in_tx_dat_valid (_rnLinkMonitor_io_in_tx_dat_valid),
    .io_in_tx_dat_bits_qos (_rnLinkMonitor_io_in_tx_dat_bits_qos),
    .io_in_tx_dat_bits_tgtID (_rnLinkMonitor_io_in_tx_dat_bits_tgtID),
    .io_in_tx_dat_bits_srcID (_rnLinkMonitor_io_in_tx_dat_bits_srcID),
    .io_in_tx_dat_bits_txnID (_rnLinkMonitor_io_in_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_homeNID (_rnLinkMonitor_io_in_tx_dat_bits_homeNID),
    .io_in_tx_dat_bits_opcode (_rnLinkMonitor_io_in_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_respErr (_rnLinkMonitor_io_in_tx_dat_bits_respErr),
    .io_in_tx_dat_bits_resp (_rnLinkMonitor_io_in_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataSource (_rnLinkMonitor_io_in_tx_dat_bits_dataSource),
    .io_in_tx_dat_bits_cBusy (_rnLinkMonitor_io_in_tx_dat_bits_cBusy),
    .io_in_tx_dat_bits_dbID (_rnLinkMonitor_io_in_tx_dat_bits_dbID),
    .io_in_tx_dat_bits_ccID (_rnLinkMonitor_io_in_tx_dat_bits_ccID),
    .io_in_tx_dat_bits_dataID (_rnLinkMonitor_io_in_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_tagOp (_rnLinkMonitor_io_in_tx_dat_bits_tagOp),
    .io_in_tx_dat_bits_tag (_rnLinkMonitor_io_in_tx_dat_bits_tag),
    .io_in_tx_dat_bits_tu (_rnLinkMonitor_io_in_tx_dat_bits_tu),
    .io_in_tx_dat_bits_traceTag (_rnLinkMonitor_io_in_tx_dat_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc (_rnLinkMonitor_io_in_tx_dat_bits_rsvdc),
    .io_in_tx_dat_bits_be (_rnLinkMonitor_io_in_tx_dat_bits_be),
    .io_in_tx_dat_bits_data (_rnLinkMonitor_io_in_tx_dat_bits_data),
    .io_in_tx_dat_bits_dataCheck (_rnLinkMonitor_io_in_tx_dat_bits_dataCheck),
    .io_in_tx_dat_bits_poison (_rnLinkMonitor_io_in_tx_dat_bits_poison),
    .io_in_rx_rsp_ready (_rnLinkMonitor_io_in_rx_rsp_ready),
    .io_in_rx_rsp_valid (_mmioDiverger_io_in_0_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos (_mmioDiverger_io_in_0_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_txnID (_mmioDiverger_io_in_0_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode (_mmioDiverger_io_in_0_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr (_mmioDiverger_io_in_0_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp (_mmioDiverger_io_in_0_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState (_mmioDiverger_io_in_0_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy (_mmioDiverger_io_in_0_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID (_mmioDiverger_io_in_0_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType (_mmioDiverger_io_in_0_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp (_mmioDiverger_io_in_0_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag (_mmioDiverger_io_in_0_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready (_rnLinkMonitor_io_in_rx_dat_ready),
    .io_in_rx_dat_valid (_mmioDiverger_io_in_0_rx_dat_valid),
    .io_in_rx_dat_bits_qos (_mmioDiverger_io_in_0_rx_dat_bits_qos),
    .io_in_rx_dat_bits_txnID (_mmioDiverger_io_in_0_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID (_mmioDiverger_io_in_0_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode (_mmioDiverger_io_in_0_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr (_mmioDiverger_io_in_0_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp (_mmioDiverger_io_in_0_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource (_mmioDiverger_io_in_0_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy (_mmioDiverger_io_in_0_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID (_mmioDiverger_io_in_0_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID (_mmioDiverger_io_in_0_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID (_mmioDiverger_io_in_0_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp (_mmioDiverger_io_in_0_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag (_mmioDiverger_io_in_0_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu (_mmioDiverger_io_in_0_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag (_mmioDiverger_io_in_0_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc (_mmioDiverger_io_in_0_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be (_mmioDiverger_io_in_0_rx_dat_bits_be),
    .io_in_rx_dat_bits_data (_mmioDiverger_io_in_0_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck (_mmioDiverger_io_in_0_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison (_mmioDiverger_io_in_0_rx_dat_bits_poison),
    .io_in_rx_snp_ready (_rnLinkMonitor_io_in_rx_snp_ready),
    .io_in_rx_snp_valid (_mmioDiverger_io_in_0_rx_snp_valid),
    .io_in_rx_snp_bits_txnID (_mmioDiverger_io_in_0_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID (_mmioDiverger_io_in_0_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID (_mmioDiverger_io_in_0_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode (_mmioDiverger_io_in_0_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr (_mmioDiverger_io_in_0_rx_snp_bits_addr),
    .io_in_rx_snp_bits_doNotGoToSD (_mmioDiverger_io_in_0_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc (_mmioDiverger_io_in_0_rx_snp_bits_retToSrc),
    .io_out_txsactive (io_rn_0_txsactive),
    .io_out_rxsactive (io_rn_0_rxsactive),
    .io_out_syscoreq (io_rn_0_syscoreq),
    .io_out_syscoack (io_rn_0_syscoack),
    .io_out_tx_linkactivereq (io_rn_0_tx_linkactivereq),
    .io_out_tx_linkactiveack (io_rn_0_tx_linkactiveack),
    .io_out_tx_req_flitpend (io_rn_0_tx_req_flitpend),
    .io_out_tx_req_flitv (io_rn_0_tx_req_flitv),
    .io_out_tx_req_flit (io_rn_0_tx_req_flit),
    .io_out_tx_req_lcrdv (io_rn_0_tx_req_lcrdv),
    .io_out_tx_rsp_flitpend (io_rn_0_tx_rsp_flitpend),
    .io_out_tx_rsp_flitv (io_rn_0_tx_rsp_flitv),
    .io_out_tx_rsp_flit (io_rn_0_tx_rsp_flit),
    .io_out_tx_rsp_lcrdv (io_rn_0_tx_rsp_lcrdv),
    .io_out_tx_dat_flitpend (io_rn_0_tx_dat_flitpend),
    .io_out_tx_dat_flitv (io_rn_0_tx_dat_flitv),
    .io_out_tx_dat_flit (io_rn_0_tx_dat_flit),
    .io_out_tx_dat_lcrdv (io_rn_0_tx_dat_lcrdv),
    .io_out_rx_linkactivereq (io_rn_0_rx_linkactivereq),
    .io_out_rx_linkactiveack (io_rn_0_rx_linkactiveack),
    .io_out_rx_rsp_flitpend (io_rn_0_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv (io_rn_0_rx_rsp_flitv),
    .io_out_rx_rsp_flit (io_rn_0_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv (io_rn_0_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend (io_rn_0_rx_dat_flitpend),
    .io_out_rx_dat_flitv (io_rn_0_rx_dat_flitv),
    .io_out_rx_dat_flit (io_rn_0_rx_dat_flit),
    .io_out_rx_dat_lcrdv (io_rn_0_rx_dat_lcrdv),
    .io_out_rx_snp_flitpend (io_rn_0_rx_snp_flitpend),
    .io_out_rx_snp_flitv (io_rn_0_rx_snp_flitv),
    .io_out_rx_snp_flit (io_rn_0_rx_snp_flit),
    .io_out_rx_snp_lcrdv (io_rn_0_rx_snp_lcrdv)
  );

  // ===================================================================
  // 顶层 io 输出 assign + probe(共 3 条,全部纯连线):
  //   _probe = topDown.addrMatch(difftest 探针);
  //   io_debugTopDown_addrMatch_0 = topDown.addrMatch;
  //   io_l3Miss = io_l3Miss_REG(打拍后的 l3Miss)。
  // ===================================================================
// 顶层 io 输出 assign + probe(共 3 条,全部纯连线无运算)。
//   _probe                      : difftest/dontTouch 探针(topDown.addrMatch 镜像);
//   io_debugTopDown_addrMatch_0 : topDown 输出直通;
//   io_l3Miss                   : 打拍后的 l3Miss 输出。

// ---- §8 顶层输出直通 assign --------------------
  assign _probe = _topDown_io_debugTopDown_addrMatch_0;
  assign io_debugTopDown_addrMatch_0 = _topDown_io_debugTopDown_addrMatch_0;
  assign io_l3Miss = io_l3Miss_REG;

endmodule

// ---------------------------------------------------------------------------
//  golden 同名层：端口与 G1 golden OpenLLC.sv 逐位同名同宽，只做扁平适配。
// ---------------------------------------------------------------------------
// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_OpenLLC_core。
// ---- §9 golden 同名层 OpenLLC --------------------
module OpenLLC(
  input  clock,
  input  reset,
  input  io_rn_0_txsactive,
  output  io_rn_0_rxsactive,
  input  io_rn_0_syscoreq,
  output  io_rn_0_syscoack,
  input  io_rn_0_tx_linkactivereq,
  output  io_rn_0_tx_linkactiveack,
  input  io_rn_0_tx_req_flitpend,
  input  io_rn_0_tx_req_flitv,
  input  [161:0] io_rn_0_tx_req_flit,
  output  io_rn_0_tx_req_lcrdv,
  input  io_rn_0_tx_rsp_flitpend,
  input  io_rn_0_tx_rsp_flitv,
  input  [72:0] io_rn_0_tx_rsp_flit,
  output  io_rn_0_tx_rsp_lcrdv,
  input  io_rn_0_tx_dat_flitpend,
  input  io_rn_0_tx_dat_flitv,
  input  [421:0] io_rn_0_tx_dat_flit,
  output  io_rn_0_tx_dat_lcrdv,
  output  io_rn_0_rx_linkactivereq,
  input  io_rn_0_rx_linkactiveack,
  output  io_rn_0_rx_rsp_flitpend,
  output  io_rn_0_rx_rsp_flitv,
  output  [72:0] io_rn_0_rx_rsp_flit,
  input  io_rn_0_rx_rsp_lcrdv,
  output  io_rn_0_rx_dat_flitpend,
  output  io_rn_0_rx_dat_flitv,
  output  [421:0] io_rn_0_rx_dat_flit,
  input  io_rn_0_rx_dat_lcrdv,
  output  io_rn_0_rx_snp_flitpend,
  output  io_rn_0_rx_snp_flitv,
  output  [114:0] io_rn_0_rx_snp_flit,
  input  io_rn_0_rx_snp_lcrdv,
  output  io_sn_txsactive,
  input  io_sn_rxsactive,
  output  io_sn_tx_linkactivereq,
  input  io_sn_tx_linkactiveack,
  output  io_sn_tx_req_flitpend,
  output  io_sn_tx_req_flitv,
  output  [161:0] io_sn_tx_req_flit,
  input  io_sn_tx_req_lcrdv,
  output  io_sn_tx_dat_flitpend,
  output  io_sn_tx_dat_flitv,
  output  [421:0] io_sn_tx_dat_flit,
  input  io_sn_tx_dat_lcrdv,
  input  io_sn_rx_linkactivereq,
  output  io_sn_rx_linkactiveack,
  input  io_sn_rx_rsp_flitpend,
  input  io_sn_rx_rsp_flitv,
  input  [72:0] io_sn_rx_rsp_flit,
  output  io_sn_rx_rsp_lcrdv,
  input  io_sn_rx_dat_flitpend,
  input  io_sn_rx_dat_flitv,
  input  [421:0] io_sn_rx_dat_flit,
  output  io_sn_rx_dat_lcrdv,
  input  io_debugTopDown_robHeadPaddr_0_valid,
  input  [47:0] io_debugTopDown_robHeadPaddr_0_bits,
  output  io_debugTopDown_addrMatch_0,
  output  io_l3Miss
);
  xs_OpenLLC_core u_core (
    .clock(clock),
    .reset(reset),
    .io_rn_0_txsactive(io_rn_0_txsactive),
    .io_rn_0_rxsactive(io_rn_0_rxsactive),
    .io_rn_0_syscoreq(io_rn_0_syscoreq),
    .io_rn_0_syscoack(io_rn_0_syscoack),
    .io_rn_0_tx_linkactivereq(io_rn_0_tx_linkactivereq),
    .io_rn_0_tx_linkactiveack(io_rn_0_tx_linkactiveack),
    .io_rn_0_tx_req_flitpend(io_rn_0_tx_req_flitpend),
    .io_rn_0_tx_req_flitv(io_rn_0_tx_req_flitv),
    .io_rn_0_tx_req_flit(io_rn_0_tx_req_flit),
    .io_rn_0_tx_req_lcrdv(io_rn_0_tx_req_lcrdv),
    .io_rn_0_tx_rsp_flitpend(io_rn_0_tx_rsp_flitpend),
    .io_rn_0_tx_rsp_flitv(io_rn_0_tx_rsp_flitv),
    .io_rn_0_tx_rsp_flit(io_rn_0_tx_rsp_flit),
    .io_rn_0_tx_rsp_lcrdv(io_rn_0_tx_rsp_lcrdv),
    .io_rn_0_tx_dat_flitpend(io_rn_0_tx_dat_flitpend),
    .io_rn_0_tx_dat_flitv(io_rn_0_tx_dat_flitv),
    .io_rn_0_tx_dat_flit(io_rn_0_tx_dat_flit),
    .io_rn_0_tx_dat_lcrdv(io_rn_0_tx_dat_lcrdv),
    .io_rn_0_rx_linkactivereq(io_rn_0_rx_linkactivereq),
    .io_rn_0_rx_linkactiveack(io_rn_0_rx_linkactiveack),
    .io_rn_0_rx_rsp_flitpend(io_rn_0_rx_rsp_flitpend),
    .io_rn_0_rx_rsp_flitv(io_rn_0_rx_rsp_flitv),
    .io_rn_0_rx_rsp_flit(io_rn_0_rx_rsp_flit),
    .io_rn_0_rx_rsp_lcrdv(io_rn_0_rx_rsp_lcrdv),
    .io_rn_0_rx_dat_flitpend(io_rn_0_rx_dat_flitpend),
    .io_rn_0_rx_dat_flitv(io_rn_0_rx_dat_flitv),
    .io_rn_0_rx_dat_flit(io_rn_0_rx_dat_flit),
    .io_rn_0_rx_dat_lcrdv(io_rn_0_rx_dat_lcrdv),
    .io_rn_0_rx_snp_flitpend(io_rn_0_rx_snp_flitpend),
    .io_rn_0_rx_snp_flitv(io_rn_0_rx_snp_flitv),
    .io_rn_0_rx_snp_flit(io_rn_0_rx_snp_flit),
    .io_rn_0_rx_snp_lcrdv(io_rn_0_rx_snp_lcrdv),
    .io_sn_txsactive(io_sn_txsactive),
    .io_sn_rxsactive(io_sn_rxsactive),
    .io_sn_tx_linkactivereq(io_sn_tx_linkactivereq),
    .io_sn_tx_linkactiveack(io_sn_tx_linkactiveack),
    .io_sn_tx_req_flitpend(io_sn_tx_req_flitpend),
    .io_sn_tx_req_flitv(io_sn_tx_req_flitv),
    .io_sn_tx_req_flit(io_sn_tx_req_flit),
    .io_sn_tx_req_lcrdv(io_sn_tx_req_lcrdv),
    .io_sn_tx_dat_flitpend(io_sn_tx_dat_flitpend),
    .io_sn_tx_dat_flitv(io_sn_tx_dat_flitv),
    .io_sn_tx_dat_flit(io_sn_tx_dat_flit),
    .io_sn_tx_dat_lcrdv(io_sn_tx_dat_lcrdv),
    .io_sn_rx_linkactivereq(io_sn_rx_linkactivereq),
    .io_sn_rx_linkactiveack(io_sn_rx_linkactiveack),
    .io_sn_rx_rsp_flitpend(io_sn_rx_rsp_flitpend),
    .io_sn_rx_rsp_flitv(io_sn_rx_rsp_flitv),
    .io_sn_rx_rsp_flit(io_sn_rx_rsp_flit),
    .io_sn_rx_rsp_lcrdv(io_sn_rx_rsp_lcrdv),
    .io_sn_rx_dat_flitpend(io_sn_rx_dat_flitpend),
    .io_sn_rx_dat_flitv(io_sn_rx_dat_flitv),
    .io_sn_rx_dat_flit(io_sn_rx_dat_flit),
    .io_sn_rx_dat_lcrdv(io_sn_rx_dat_lcrdv),
    .io_debugTopDown_robHeadPaddr_0_valid(io_debugTopDown_robHeadPaddr_0_valid),
    .io_debugTopDown_robHeadPaddr_0_bits(io_debugTopDown_robHeadPaddr_0_bits),
    .io_debugTopDown_addrMatch_0(io_debugTopDown_addrMatch_0),
    .io_l3Miss(io_l3Miss)
  );
endmodule
