// =============================================================================
// xs_IssueQueueAluCsrFenceDiv_core —— 香山 V2R2 发射队列 AluCsrFenceDiv 变体 可读核
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/issue/IssueQueue.scala (class IssueQueue)
//
// 发射队列把条目阵列(EntriesAluCsrFenceDiv)包起来, 负责:
//   1) enq 分配   : 计算 enq ready(队列是否有空位/未被发射占用), 并把外部 uop
//                   字段折算成条目阵列的 enq.bits(srcState/dataSources 初值)。
//   2) FU busy 表 : 把 24 条目各自的 fuType 送进 FuBusyTableRead, 算出哪些条目
//                   因为功能单元忙而暂不可发射(busy mask)。
//   3) canIssue   : 条目自报 canIssue, 与 busy mask 相与, 再按每个发射端口能承担
//                   的功能单元筛(端口0 = CSR; 端口1 = ALU/Fence/Div)。
//   4) 年龄仲裁   : 三段年龄检测器(enq 2 路 / simp 6 路 / comp 16 路)在各自可发射
//                   集合里选最老的 one-hot; 复杂条目优先于简单条目优先于入队条目。
//   5) deq 发射   : 用三段 one-hot 对条目阵列做 Mux1H, 选出发射 uop 的 dataSources/
//                   loadDependency/exuSources, 经一拍 deqDelay 寄存器送往 DataPath。
//   6) wakeup     : 端口0 的发射结果进 MultiWakeupQueue 形成 wakeupToIQ 广播。
//   7) 统计       : validCntDeqVec(端口0 在队的同类 uop 数), 供上层背压参考。
//
// 本核把 IQ 的 enq/deq/wakeup/仲裁/统计胶合逻辑用可读结构重写; 5 个子模块
// (entries / FuBusyTableRead_23 / MultiWakeupQueue_2 / NewAgeDetector / AgeDetector
//  / AgeDetector_1)均作 golden 黑盒直接例化(端口已扁平), 由本核连线。
// =============================================================================
module xs_IssueQueueAluCsrFenceDiv_core import iq_acfd_pkg::*; (
  input         clock,
  input         reset,
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_level,
  output        io_enq_0_ready,
  input         io_enq_0_valid,
  input         io_enq_0_bits_ftqPtr_flag,
  input  [5:0]  io_enq_0_bits_ftqPtr_value,
  input  [3:0]  io_enq_0_bits_ftqOffset,
  input  [3:0]  io_enq_0_bits_srcType_0,
  input  [3:0]  io_enq_0_bits_srcType_1,
  input  [34:0] io_enq_0_bits_fuType,
  input  [8:0]  io_enq_0_bits_fuOpType,
  input         io_enq_0_bits_rfWen,
  input         io_enq_0_bits_flushPipe,
  input  [3:0]  io_enq_0_bits_selImm,
  input  [31:0] io_enq_0_bits_imm,
  input         io_enq_0_bits_srcState_0,
  input         io_enq_0_bits_srcState_1,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_0_0,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_0_1,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_0_2,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_1_0,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_1_1,
  input  [1:0]  io_enq_0_bits_srcLoadDependency_1_2,
  input  [7:0]  io_enq_0_bits_psrc_0,
  input  [7:0]  io_enq_0_bits_psrc_1,
  input  [7:0]  io_enq_0_bits_pdest,
  input         io_enq_0_bits_useRegCache_0,
  input         io_enq_0_bits_useRegCache_1,
  input  [4:0]  io_enq_0_bits_regCacheIdx_0,
  input  [4:0]  io_enq_0_bits_regCacheIdx_1,
  input         io_enq_0_bits_robIdx_flag,
  input  [7:0]  io_enq_0_bits_robIdx_value,
  output        io_enq_1_ready,
  input         io_enq_1_valid,
  input         io_enq_1_bits_ftqPtr_flag,
  input  [5:0]  io_enq_1_bits_ftqPtr_value,
  input  [3:0]  io_enq_1_bits_ftqOffset,
  input  [3:0]  io_enq_1_bits_srcType_0,
  input  [3:0]  io_enq_1_bits_srcType_1,
  input  [34:0] io_enq_1_bits_fuType,
  input  [8:0]  io_enq_1_bits_fuOpType,
  input         io_enq_1_bits_rfWen,
  input         io_enq_1_bits_flushPipe,
  input  [3:0]  io_enq_1_bits_selImm,
  input  [31:0] io_enq_1_bits_imm,
  input         io_enq_1_bits_srcState_0,
  input         io_enq_1_bits_srcState_1,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_0_0,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_0_1,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_0_2,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_1_0,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_1_1,
  input  [1:0]  io_enq_1_bits_srcLoadDependency_1_2,
  input  [7:0]  io_enq_1_bits_psrc_0,
  input  [7:0]  io_enq_1_bits_psrc_1,
  input  [7:0]  io_enq_1_bits_pdest,
  input         io_enq_1_bits_useRegCache_0,
  input         io_enq_1_bits_useRegCache_1,
  input  [4:0]  io_enq_1_bits_regCacheIdx_0,
  input  [4:0]  io_enq_1_bits_regCacheIdx_1,
  input         io_enq_1_bits_robIdx_flag,
  input  [7:0]  io_enq_1_bits_robIdx_value,
  input         io_og0Resp_0_valid,
  input         io_og0Resp_1_valid,
  input         io_og1Resp_0_valid,
  input         io_og1Resp_1_valid,
  input  [1:0]  io_og1Resp_1_bits_resp,
  input         io_wakeupFromWB_3_valid,
  input         io_wakeupFromWB_3_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_3_bits_pdest,
  input         io_wakeupFromWB_2_valid,
  input         io_wakeupFromWB_2_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_2_bits_pdest,
  input         io_wakeupFromWB_1_valid,
  input         io_wakeupFromWB_1_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_1_bits_pdest,
  input         io_wakeupFromWB_0_valid,
  input         io_wakeupFromWB_0_bits_rfWen,
  input  [7:0]  io_wakeupFromWB_0_bits_pdest,
  input         io_wakeupFromIQ_6_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_6_bits_pdest,
  input  [4:0]  io_wakeupFromIQ_6_bits_rcDest,
  input         io_wakeupFromIQ_5_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_5_bits_pdest,
  input  [4:0]  io_wakeupFromIQ_5_bits_rcDest,
  input         io_wakeupFromIQ_4_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_4_bits_pdest,
  input  [4:0]  io_wakeupFromIQ_4_bits_rcDest,
  input         io_wakeupFromIQ_3_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_3_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_3_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_3_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_3_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQ_3_bits_rcDest,
  input         io_wakeupFromIQ_2_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_2_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_2_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_2_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_2_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQ_2_bits_rcDest,
  input         io_wakeupFromIQ_1_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_1_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_1_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_1_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_1_bits_loadDependency_2,
  input         io_wakeupFromIQ_1_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQ_1_bits_rcDest,
  input         io_wakeupFromIQ_0_bits_rfWen,
  input  [7:0]  io_wakeupFromIQ_0_bits_pdest,
  input  [1:0]  io_wakeupFromIQ_0_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQ_0_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQ_0_bits_loadDependency_2,
  input         io_wakeupFromIQ_0_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQ_0_bits_rcDest,
  input         io_wakeupFromWBDelayed_3_valid,
  input         io_wakeupFromWBDelayed_3_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_3_bits_pdest,
  input         io_wakeupFromWBDelayed_2_valid,
  input         io_wakeupFromWBDelayed_2_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_2_bits_pdest,
  input         io_wakeupFromWBDelayed_1_valid,
  input         io_wakeupFromWBDelayed_1_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_1_bits_pdest,
  input         io_wakeupFromWBDelayed_0_valid,
  input         io_wakeupFromWBDelayed_0_bits_rfWen,
  input  [7:0]  io_wakeupFromWBDelayed_0_bits_pdest,
  input         io_wakeupFromIQDelayed_6_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_6_bits_pdest,
  input  [4:0]  io_wakeupFromIQDelayed_6_bits_rcDest,
  input         io_wakeupFromIQDelayed_5_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_5_bits_pdest,
  input  [4:0]  io_wakeupFromIQDelayed_5_bits_rcDest,
  input         io_wakeupFromIQDelayed_4_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_4_bits_pdest,
  input  [4:0]  io_wakeupFromIQDelayed_4_bits_rcDest,
  input         io_wakeupFromIQDelayed_3_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_3_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_3_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_3_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_3_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQDelayed_3_bits_rcDest,
  input         io_wakeupFromIQDelayed_2_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_2_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_2_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_2_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_2_bits_loadDependency_2,
  input  [4:0]  io_wakeupFromIQDelayed_2_bits_rcDest,
  input         io_wakeupFromIQDelayed_1_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_1_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_1_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_1_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_1_bits_loadDependency_2,
  input         io_wakeupFromIQDelayed_1_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQDelayed_1_bits_rcDest,
  input         io_wakeupFromIQDelayed_0_bits_rfWen,
  input  [7:0]  io_wakeupFromIQDelayed_0_bits_pdest,
  input  [1:0]  io_wakeupFromIQDelayed_0_bits_loadDependency_0,
  input  [1:0]  io_wakeupFromIQDelayed_0_bits_loadDependency_1,
  input  [1:0]  io_wakeupFromIQDelayed_0_bits_loadDependency_2,
  input         io_wakeupFromIQDelayed_0_bits_is0Lat,
  input  [4:0]  io_wakeupFromIQDelayed_0_bits_rcDest,
  input         io_og0Cancel_0,
  input         io_og0Cancel_2,
  input         io_og0Cancel_4,
  input         io_og0Cancel_6,
  input         io_ldCancel_0_ld2Cancel,
  input         io_ldCancel_1_ld2Cancel,
  input         io_ldCancel_2_ld2Cancel,
  input  [4:0]  io_replaceRCIdx_0,
  output        io_wakeupToIQ_0_valid,
  output        io_wakeupToIQ_0_bits_rfWen,
  output [7:0]  io_wakeupToIQ_0_bits_pdest,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependency_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependency_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependency_2,
  output [4:0]  io_wakeupToIQ_0_bits_rcDest,
  output [7:0]  io_wakeupToIQ_0_bits_pdestCopy_0,
  output [7:0]  io_wakeupToIQ_0_bits_pdestCopy_1,
  output [7:0]  io_wakeupToIQ_0_bits_pdestCopy_2,
  output [7:0]  io_wakeupToIQ_0_bits_pdestCopy_3,
  output [7:0]  io_wakeupToIQ_0_bits_pdestCopy_4,
  output [7:0]  io_wakeupToIQ_0_bits_pdestCopy_5,
  output        io_wakeupToIQ_0_bits_rfWenCopy_0,
  output        io_wakeupToIQ_0_bits_rfWenCopy_1,
  output        io_wakeupToIQ_0_bits_rfWenCopy_2,
  output        io_wakeupToIQ_0_bits_rfWenCopy_3,
  output        io_wakeupToIQ_0_bits_rfWenCopy_4,
  output        io_wakeupToIQ_0_bits_rfWenCopy_5,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_0_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_0_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_0_2,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_1_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_1_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_1_2,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_2_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_2_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_2_2,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_3_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_3_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_3_2,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_4_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_4_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_4_2,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_5_0,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_5_1,
  output [1:0]  io_wakeupToIQ_0_bits_loadDependencyCopy_5_2,
  output [4:0]  io_validCntDeqVec_0,
  input         io_deqDelay_1_ready,
  output        io_deqDelay_1_valid,
  output [7:0]  io_deqDelay_1_bits_rf_1_0_addr,
  output [7:0]  io_deqDelay_1_bits_rf_0_0_addr,
  output [4:0]  io_deqDelay_1_bits_rcIdx_0,
  output [4:0]  io_deqDelay_1_bits_rcIdx_1,
  output [34:0] io_deqDelay_1_bits_common_fuType,
  output [8:0]  io_deqDelay_1_bits_common_fuOpType,
  output [63:0] io_deqDelay_1_bits_common_imm,
  output        io_deqDelay_1_bits_common_robIdx_flag,
  output [7:0]  io_deqDelay_1_bits_common_robIdx_value,
  output [7:0]  io_deqDelay_1_bits_common_pdest,
  output        io_deqDelay_1_bits_common_rfWen,
  output        io_deqDelay_1_bits_common_flushPipe,
  output        io_deqDelay_1_bits_common_ftqIdx_flag,
  output [5:0]  io_deqDelay_1_bits_common_ftqIdx_value,
  output [3:0]  io_deqDelay_1_bits_common_ftqOffset,
  output [3:0]  io_deqDelay_1_bits_common_dataSources_0_value,
  output [3:0]  io_deqDelay_1_bits_common_dataSources_1_value,
  output [2:0]  io_deqDelay_1_bits_common_exuSources_0_value,
  output [2:0]  io_deqDelay_1_bits_common_exuSources_1_value,
  output [1:0]  io_deqDelay_1_bits_common_loadDependency_0,
  output [1:0]  io_deqDelay_1_bits_common_loadDependency_1,
  output [1:0]  io_deqDelay_1_bits_common_loadDependency_2,
  input         io_deqDelay_0_ready,
  output        io_deqDelay_0_valid,
  output [7:0]  io_deqDelay_0_bits_rf_1_0_addr,
  output [7:0]  io_deqDelay_0_bits_rf_0_0_addr,
  output [4:0]  io_deqDelay_0_bits_rcIdx_0,
  output [4:0]  io_deqDelay_0_bits_rcIdx_1,
  output [3:0]  io_deqDelay_0_bits_immType,
  output [34:0] io_deqDelay_0_bits_common_fuType,
  output [8:0]  io_deqDelay_0_bits_common_fuOpType,
  output [63:0] io_deqDelay_0_bits_common_imm,
  output        io_deqDelay_0_bits_common_robIdx_flag,
  output [7:0]  io_deqDelay_0_bits_common_robIdx_value,
  output [7:0]  io_deqDelay_0_bits_common_pdest,
  output        io_deqDelay_0_bits_common_rfWen,
  output [3:0]  io_deqDelay_0_bits_common_dataSources_0_value,
  output [3:0]  io_deqDelay_0_bits_common_dataSources_1_value,
  output [2:0]  io_deqDelay_0_bits_common_exuSources_0_value,
  output [2:0]  io_deqDelay_0_bits_common_exuSources_1_value,
  output [1:0]  io_deqDelay_0_bits_common_loadDependency_0,
  output [1:0]  io_deqDelay_0_bits_common_loadDependency_1,
  output [1:0]  io_deqDelay_0_bits_common_loadDependency_2
);

  // ===========================================================================
  // 发射端口承载 uop 公共字段(deqEntry → deqBeforeDly → deqDelay 寄存器)。
  // 用 struct 表达「一条选中发射 uop 的全部下游字段」, 替代 golden 几十条平铺 reg。
  // ===========================================================================
  typedef struct packed {
    logic [7:0]  rf_1_0_addr;   // 源1 物理寄存器号(rf read addr)
    logic [7:0]  rf_0_0_addr;   // 源0 物理寄存器号
    logic [4:0]  rc_idx_0;      // 源0 regCache 索引
    logic [4:0]  rc_idx_1;      // 源1 regCache 索引
    logic [34:0] fu_type;       // 功能单元 one-hot(只保留 5/6/8/9 位)
    logic [8:0]  fu_op_type;
    logic [63:0] imm;
    logic        rob_flag;
    logic [7:0]  rob_value;
    logic [7:0]  pdest;
    logic        rf_wen;
    logic        flush_pipe;    // 仅端口1(Fence)关心
    logic        ftq_flag;      // 仅端口1关心
    logic [5:0]  ftq_value;     // 仅端口1关心
    logic [3:0]  ftq_offset;    // 仅端口1关心
    logic [3:0]  imm_type;      // 仅端口0(selImm)关心
    logic [3:0]  ds0;           // dataSources 源0
    logic [3:0]  ds1;           // dataSources 源1
    logic [2:0]  exu0;          // exuSources 源0
    logic [2:0]  exu1;          // exuSources 源1
    logic [1:0]  ld0;           // loadDependency pipe0
    logic [1:0]  ld1;
    logic [1:0]  ld2;
  } deq_common_t;

  // ---- entries 黑盒输出线 ----
  wire [23:0] e_valid, e_issued, e_can_issue;
  wire [34:0] e_fu_type   [24];
  wire [3:0]  e_data_src  [24][2];
  wire [2:0]  e_exu_src   [24][2];
  wire [1:0]  e_load_dep  [24][3];
  wire [5:0]  e_simp_enq_sel [2];
  wire [15:0] e_comp_enq_sel [2];
  wire [1:0]  e_cancel_deq;
  // deqEntry 端口(端口0/1 各有不同子集; 用单独命名以匹配 golden 黑盒端口)
  wire        e_deq0_robflag, e_deq0_ft5, e_deq0_ft6, e_deq0_ft8, e_deq0_ft9;
  wire [7:0]  e_deq0_robval, e_deq0_s0psrc, e_deq0_s1psrc, e_deq0_pdest;
  wire [3:0]  e_deq0_s0type, e_deq0_s1type, e_deq0_selimm;
  wire [4:0]  e_deq0_s0rc, e_deq0_s1rc;
  wire [31:0] e_deq0_imm;
  wire [8:0]  e_deq0_fuop;
  wire        e_deq0_rfwen;
  wire        e_deq1_robflag, e_deq1_ft5, e_deq1_ft6, e_deq1_ft8, e_deq1_ft9;
  wire [7:0]  e_deq1_robval, e_deq1_s0psrc, e_deq1_s1psrc, e_deq1_pdest;
  wire [3:0]  e_deq1_s0type, e_deq1_s1type, e_deq1_ftqoff;
  wire [4:0]  e_deq1_s0rc, e_deq1_s1rc;
  wire [31:0] e_deq1_imm;
  wire [8:0]  e_deq1_fuop;
  wire        e_deq1_rfwen, e_deq1_flushpipe, e_deq1_ftqflag;
  wire [5:0]  e_deq1_ftqval;

  // ---- 年龄检测器输出 ----
  wire [1:0]  age_enq_out [2];   // NewAgeDetector: 入队 2 条目 one-hot
  wire [5:0]  age_simp_out [4];  // AgeDetector: simp 6 条目, 4 路(deq0/deq1/trans0/trans1)
  wire [15:0] age_comp_out [2];  // AgeDetector_1: comp 16 条目, 2 路(deq0/deq1)

  // ---- FU busy 表输出 ----
  wire [23:0] fu_busy_mask;
  // ---- wakeup 队列输出 ----
  wire        wkq_deq_valid, wkq_deq_rfwen;

  // ===========================================================================
  // 1. enq 分配: ready / s0_doEnq
  // ---------------------------------------------------------------------------
  // simpCanotIn: 6 个简单条目(idx2..7)里已占用 >=5 个 → 简单区将满, 不能再收。
  //   golden 用 6'h3E/3D/.../1F(各缺 1 位)与「全满」的并集表达。等价于「空位 <=1」。
  // enqHasValid/enqHasIssued: 入队条目(idx0/1)的占用/已发射情况。
  // ===========================================================================
  wire [5:0] simp_valid = e_valid[7:2];
  wire simpCanotIn =
    simp_valid == 6'h3E | simp_valid == 6'h3D | simp_valid == 6'h3B |
    simp_valid == 6'h37 | simp_valid == 6'h2F | simp_valid == 6'h1F |
    (&simp_valid);
  wire enqHasValid  = e_valid[0] | e_valid[1];
  wire enqHasIssued = (e_valid[0] & e_issued[0]) | (e_valid[1] & e_issued[1]);
  wire enq_ready = (~simpCanotIn | ~enqHasValid) & ~enqHasIssued;
  assign io_enq_0_ready = enq_ready;
  assign io_enq_1_ready = enq_ready;

  wire s0_doEnq_0 = io_enq_0_valid & enq_ready & ~io_flush_valid;
  wire s0_doEnq_1 = io_enq_1_valid & enq_ready & ~io_flush_valid;

  // enq.bits 折算: srcState/dataSources 初值由 srcType/psrc 决定(对照 golden 2255-2302)。
  //   psrc==0 视为已就绪的常零源; srcType[0]=reg(可被唤醒), [2]=imm/zero(立即就绪)。
  function automatic logic [3:0] enq_data_src(input logic [3:0] stype, input logic psrc_zero);
    if (stype[0] & psrc_zero)            enq_data_src = 4'h0;  // reg 源且 psrc=0 → 常零
    else if (stype == 4'h0)              enq_data_src = 4'h4;  // 纯 reg → 等 WB
    else if (stype[2] & psrc_zero)       enq_data_src = 4'h5;
    else                                 enq_data_src = 4'h8;  // imm/pc 等立即就绪
  endfunction
  function automatic logic enq_src_state(input logic [3:0] stype, input logic psrc_zero,
                                         input logic ext_state);
    enq_src_state = (stype[2] & psrc_zero) | ext_state;
  endfunction

  wire p0_0_zero = (io_enq_0_bits_psrc_0 == 8'h0);
  wire p0_1_zero = (io_enq_0_bits_psrc_1 == 8'h0);
  wire p1_0_zero = (io_enq_1_bits_psrc_0 == 8'h0);
  wire p1_1_zero = (io_enq_1_bits_psrc_1 == 8'h0);

  // ===========================================================================
  // 2. canIssue 合并 + FU busy 筛选 + 端口功能单元筛
  // ---------------------------------------------------------------------------
  //   canIssueMergeAllBusy_0 = canIssue & ~busyMask(端口0 走 busy 表);
  //   canIssueMergeAllBusy_1 = canIssue(端口1 不过 busy 表)。
  //   deqCanIssue_0 = merge0 & fuType[6](CSR);
  //   deqCanIssue_1 = merge1 & (fuType[5]|[8]|[9])(ALU/Fence/Div)。
  // ===========================================================================
  wire [23:0] canIssueVec = e_can_issue;
  wire [23:0] canIssueMergeAllBusy_0 = canIssueVec & ~fu_busy_mask;
  wire [23:0] canIssueMergeAllBusy_1 = canIssueVec;

  wire [23:0] port0_fu, port1_fu;
  genvar gi;
  generate
    for (gi = 0; gi < 24; gi++) begin : g_portfu
      assign port0_fu[gi] = e_fu_type[gi][FU_CSR];
      assign port1_fu[gi] = e_fu_type[gi][FU_ALU] | e_fu_type[gi][FU_DIV] | e_fu_type[gi][FU_FENCE];
    end
  endgenerate
  wire [23:0] deqCanIssue_0 = canIssueMergeAllBusy_0 & port0_fu;
  wire [23:0] deqCanIssue_1 = canIssueMergeAllBusy_1 & port1_fu;

  // 三段年龄请求: enq=[1:0], simp=[7:2], comp=[23:8]。
  wire [1:0]  enqReq_0  = deqCanIssue_0[1:0];
  wire [1:0]  enqReq_1  = deqCanIssue_1[1:0];
  wire [5:0]  simpReq_0 = deqCanIssue_0[7:2];
  wire [5:0]  simpReq_1 = deqCanIssue_1[7:2];
  wire [15:0] compReq_0 = deqCanIssue_0[23:8];
  wire [15:0] compReq_1 = deqCanIssue_1[23:8];

  // 转移请求(simp→comp): 简单条目有效且未发射 → 请求转移到复杂区。
  //   simpReq_2 给转移端口0; simpReq_3 = simpReq_2 & ~age 端口0选中(避免两路选同一条)。
  wire [5:0] requestForTrans;
  generate
    for (gi = 0; gi < 6; gi++) begin : g_trans
      assign requestForTrans[gi] = e_valid[2+gi] & ~e_issued[2+gi];
    end
  endgenerate
  wire [5:0] simpReq_2 = requestForTrans;
  wire [5:0] simpReq_3 = requestForTrans & ~age_simp_out[2];

  // ===========================================================================
  // 3. deq one-hot 选择
  // ---------------------------------------------------------------------------
  //   优先级: comp > simp > enq。若 comp 集合非空, 选 comp; 否则看 simp; 否则 enq。
  //   deqSelOH_T_2 = simp one-hot(仅当 comp 空时有效);
  //   deqSelOH_T_7 = enq one-hot(仅当 comp、simp 都空时有效)。
  // ===========================================================================
  wire deqValid_0 = (|compReq_0) | (|simpReq_0) | (|enqReq_0);
  wire deqValid_1 = (|compReq_1) | (|simpReq_1) | (|enqReq_1);

  wire [5:0] deqSimpOH_0 = {6{~(|compReq_0)}} & age_simp_out[0];
  wire [1:0] deqEnqOH_0  = {2{~(|compReq_0) & ~(|simpReq_0)}} & age_enq_out[0];
  wire [5:0] deqSimpOH_1 = {6{~(|compReq_1)}} & age_simp_out[1];
  wire [1:0] deqEnqOH_1  = {2{~(|compReq_1) & ~(|simpReq_1)}} & age_enq_out[1];

  // 24 位发射 one-hot(端口0/1): {comp[15:0], simp[5:0], enq[1:0]}。
  wire [23:0] deqSelOH_0 = {age_comp_out[0], deqSimpOH_0, deqEnqOH_0};
  wire [23:0] deqSelOH_1 = {age_comp_out[1], deqSimpOH_1, deqEnqOH_1};

  // ===========================================================================
  // 4. Mux1H: 用发射 one-hot 在 24 条目里选出 dataSources/loadDependency/exuSources
  // ---------------------------------------------------------------------------
  // 24-way one-hot 归约, 替代 golden 24 行平铺 OR。各发射端口对 2 个源做归约。
  // 用 always_comb 显式展开(对非局部 unpacked 数组保持完整敏感性)。
  // ===========================================================================
  logic [3:0] finalDataSources_0 [2];   // 端口0 两个源的 dataSources
  logic [3:0] finalDataSources_1 [2];   // 端口1
  logic [1:0] finalLoadDependency_0 [3]; // 端口0 三条 pipe 的 loadDependency
  logic [1:0] finalLoadDependency_1 [3]; // 端口1
  logic [2:0] finalExuSources_0 [2];     // 端口0 两个源的 exuSources
  logic [2:0] finalExuSources_1 [2];     // 端口1
  always_comb begin
    for (int s = 0; s < 2; s++) begin
      finalDataSources_0[s] = '0; finalDataSources_1[s] = '0;
      finalExuSources_0[s]  = '0; finalExuSources_1[s]  = '0;
      for (int k = 0; k < 24; k++) begin
        finalDataSources_0[s] |= ({4{deqSelOH_0[k]}} & e_data_src[k][s]);
        finalDataSources_1[s] |= ({4{deqSelOH_1[k]}} & e_data_src[k][s]);
        finalExuSources_0[s]  |= ({3{deqSelOH_0[k]}} & e_exu_src[k][s]);
        finalExuSources_1[s]  |= ({3{deqSelOH_1[k]}} & e_exu_src[k][s]);
      end
    end
    for (int p = 0; p < 3; p++) begin
      finalLoadDependency_0[p] = '0; finalLoadDependency_1[p] = '0;
      for (int k = 0; k < 24; k++) begin
        finalLoadDependency_0[p] |= ({2{deqSelOH_0[k]}} & e_load_dep[k][p]);
        finalLoadDependency_1[p] |= ({2{deqSelOH_1[k]}} & e_load_dep[k][p]);
      end
    end
  end
  wire [3:0] finalDataSources_0_0 = finalDataSources_0[0];
  wire [3:0] finalDataSources_0_1 = finalDataSources_0[1];
  wire [3:0] finalDataSources_1_0 = finalDataSources_1[0];
  wire [3:0] finalDataSources_1_1 = finalDataSources_1[1];
  wire [1:0] finalLoadDependency_0_0 = finalLoadDependency_0[0];
  wire [1:0] finalLoadDependency_0_1 = finalLoadDependency_0[1];
  wire [1:0] finalLoadDependency_0_2 = finalLoadDependency_0[2];

  // ===========================================================================
  // 5. deqBeforeDly: 选中且未被 cancelDeqVec 撤销 → 本拍真正发射
  // ===========================================================================
  wire deqBeforeDly_0_valid = deqValid_0 & ~e_cancel_deq[0];
  wire deqBeforeDly_1_valid = deqValid_1 & ~e_cancel_deq[1];

  // 端口0 fuType 重组(deqEntry 只给 5/6/8/9 位, 拼回 35 位 one-hot 形式)。
  wire [34:0] deqBeforeDly_0_fuType =
    {25'h0, e_deq0_ft9, e_deq0_ft8, 1'h0, e_deq0_ft6, e_deq0_ft5, 5'h0};

  // ===========================================================================
  // 6. deqDelay 寄存器: 发射 uop 经一拍寄存后送 DataPath。
  //   bits 部分仅在「队列非空」(|e_valid)时更新(golden 同款门控, 省功耗)。
  //   valid 每拍无条件更新为 deqBeforeDly_*_valid。
  // ===========================================================================
  deq_common_t d0, d1;
  reg          d0_valid, d1_valid;
  reg  [5:0]   validCntDeqVec0_reg;

  // 在队 CSR 类计数(popcount of e_valid[k] & fuType[k][6])。
  // 用 always_comb(而非 function 读模块级信号), 避免 FM 的 FMR_VLOG-091。
  logic [5:0] cnt_valid_csr;
  always_comb begin
    cnt_valid_csr = '0;
    for (int k = 0; k < 24; k++) cnt_valid_csr += 6'(e_valid[k] & e_fu_type[k][FU_CSR]);
  end

  always @(posedge clock) begin
    d1_valid <= deqBeforeDly_1_valid;
    if (|e_valid) begin
      d1.rf_1_0_addr <= e_deq1_s1psrc;
      d1.rf_0_0_addr <= e_deq1_s0psrc;
      d1.rc_idx_0    <= e_deq1_s0rc;
      d1.rc_idx_1    <= e_deq1_s1rc;
      d1.fu_type     <= {25'h0, e_deq1_ft9, e_deq1_ft8, 1'h0, e_deq1_ft6, e_deq1_ft5, 5'h0};
      d1.fu_op_type  <= e_deq1_fuop;
      d1.imm         <= {32'h0, e_deq1_imm};
      d1.rob_flag    <= e_deq1_robflag;
      d1.rob_value   <= e_deq1_robval;
      d1.pdest       <= e_deq1_pdest;
      d1.rf_wen      <= e_deq1_rfwen;
      d1.flush_pipe  <= e_deq1_flushpipe;
      d1.ftq_flag    <= e_deq1_ftqflag;
      d1.ftq_value   <= e_deq1_ftqval;
      d1.ftq_offset  <= e_deq1_ftqoff;
      d1.ds0         <= finalDataSources_1[0];
      d1.ds1         <= finalDataSources_1[1];
      d1.exu0        <= finalExuSources_1[0];
      d1.exu1        <= finalExuSources_1[1];
      d1.ld0         <= finalLoadDependency_1[0];
      d1.ld1         <= finalLoadDependency_1[1];
      d1.ld2         <= finalLoadDependency_1[2];
    end
    d0_valid <= deqBeforeDly_0_valid;
    if (|e_valid) begin
      d0.rf_1_0_addr <= e_deq0_s1psrc;
      d0.rf_0_0_addr <= e_deq0_s0psrc;
      d0.rc_idx_0    <= e_deq0_s0rc;
      d0.rc_idx_1    <= e_deq0_s1rc;
      d0.imm_type    <= e_deq0_selimm;
      d0.fu_type     <= deqBeforeDly_0_fuType;
      d0.fu_op_type  <= e_deq0_fuop;
      d0.imm         <= {32'h0, e_deq0_imm};
      d0.rob_flag    <= e_deq0_robflag;
      d0.rob_value   <= e_deq0_robval;
      d0.pdest       <= e_deq0_pdest;
      d0.rf_wen      <= e_deq0_rfwen;
      d0.ds0         <= finalDataSources_0[0];
      d0.ds1         <= finalDataSources_0[1];
      d0.exu0        <= finalExuSources_0[0];
      d0.exu1        <= finalExuSources_0[1];
      d0.ld0         <= finalLoadDependency_0[0];
      d0.ld1         <= finalLoadDependency_0[1];
      d0.ld2         <= finalLoadDependency_0[2];
    end
    // validCntDeqVec_0: 在队的「端口0 同类(CSR=fuType[6])」uop 数, 减去本拍出队消耗。
    validCntDeqVec0_reg <=
      6'(cnt_valid_csr - {5'h0, (io_deqDelay_0_ready & d0_valid)});
  end

  // deqDelay 输出绑定
  assign io_deqDelay_1_valid                       = d1_valid;
  assign io_deqDelay_1_bits_rf_1_0_addr            = d1.rf_1_0_addr;
  assign io_deqDelay_1_bits_rf_0_0_addr            = d1.rf_0_0_addr;
  assign io_deqDelay_1_bits_rcIdx_0                = d1.rc_idx_0;
  assign io_deqDelay_1_bits_rcIdx_1                = d1.rc_idx_1;
  assign io_deqDelay_1_bits_common_fuType          = d1.fu_type;
  assign io_deqDelay_1_bits_common_fuOpType        = d1.fu_op_type;
  assign io_deqDelay_1_bits_common_imm             = d1.imm;
  assign io_deqDelay_1_bits_common_robIdx_flag     = d1.rob_flag;
  assign io_deqDelay_1_bits_common_robIdx_value    = d1.rob_value;
  assign io_deqDelay_1_bits_common_pdest           = d1.pdest;
  assign io_deqDelay_1_bits_common_rfWen           = d1.rf_wen;
  assign io_deqDelay_1_bits_common_flushPipe       = d1.flush_pipe;
  assign io_deqDelay_1_bits_common_ftqIdx_flag     = d1.ftq_flag;
  assign io_deqDelay_1_bits_common_ftqIdx_value    = d1.ftq_value;
  assign io_deqDelay_1_bits_common_ftqOffset       = d1.ftq_offset;
  assign io_deqDelay_1_bits_common_dataSources_0_value = d1.ds0;
  assign io_deqDelay_1_bits_common_dataSources_1_value = d1.ds1;
  assign io_deqDelay_1_bits_common_exuSources_0_value  = d1.exu0;
  assign io_deqDelay_1_bits_common_exuSources_1_value  = d1.exu1;
  assign io_deqDelay_1_bits_common_loadDependency_0 = d1.ld0;
  assign io_deqDelay_1_bits_common_loadDependency_1 = d1.ld1;
  assign io_deqDelay_1_bits_common_loadDependency_2 = d1.ld2;

  assign io_deqDelay_0_valid                       = d0_valid;
  assign io_deqDelay_0_bits_rf_1_0_addr            = d0.rf_1_0_addr;
  assign io_deqDelay_0_bits_rf_0_0_addr            = d0.rf_0_0_addr;
  assign io_deqDelay_0_bits_rcIdx_0                = d0.rc_idx_0;
  assign io_deqDelay_0_bits_rcIdx_1                = d0.rc_idx_1;
  assign io_deqDelay_0_bits_immType                = d0.imm_type;
  assign io_deqDelay_0_bits_common_fuType          = d0.fu_type;
  assign io_deqDelay_0_bits_common_fuOpType        = d0.fu_op_type;
  assign io_deqDelay_0_bits_common_imm             = d0.imm;
  assign io_deqDelay_0_bits_common_robIdx_flag     = d0.rob_flag;
  assign io_deqDelay_0_bits_common_robIdx_value    = d0.rob_value;
  assign io_deqDelay_0_bits_common_pdest           = d0.pdest;
  assign io_deqDelay_0_bits_common_rfWen           = d0.rf_wen;
  assign io_deqDelay_0_bits_common_dataSources_0_value = d0.ds0;
  assign io_deqDelay_0_bits_common_dataSources_1_value = d0.ds1;
  assign io_deqDelay_0_bits_common_exuSources_0_value  = d0.exu0;
  assign io_deqDelay_0_bits_common_exuSources_1_value  = d0.exu1;
  assign io_deqDelay_0_bits_common_loadDependency_0 = d0.ld0;
  assign io_deqDelay_0_bits_common_loadDependency_1 = d0.ld1;
  assign io_deqDelay_0_bits_common_loadDependency_2 = d0.ld2;

  assign io_validCntDeqVec_0 = validCntDeqVec0_reg[4:0];

  // ===========================================================================
  // 7. wakeupToIQ: 端口0 发射结果进 MultiWakeupQueue, 形成 0 周期唤醒广播。
  //   rcDest 直接取 replaceRCIdx(本变体 regCache 重命名索引)。
  // ===========================================================================
  assign io_wakeupToIQ_0_valid       = wkq_deq_valid;
  assign io_wakeupToIQ_0_bits_rfWen  = wkq_deq_valid & wkq_deq_rfwen;
  assign io_wakeupToIQ_0_bits_rcDest = io_replaceRCIdx_0;

  // ===========================================================================
  // 8. 子模块例化(均为 golden 黑盒)
  // ===========================================================================
  EntriesAluCsrFenceDiv entries (
    .clock (clock), .reset (reset),
    .io_flush_valid (io_flush_valid),
    .io_flush_bits_robIdx_flag (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value (io_flush_bits_robIdx_value),
    .io_flush_bits_level (io_flush_bits_level),
    .io_enq_0_valid (s0_doEnq_0),
    .io_enq_0_bits_status_robIdx_flag (io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value (io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_status_fuType_5 (io_enq_0_bits_fuType[5]),
    .io_enq_0_bits_status_fuType_6 (io_enq_0_bits_fuType[6]),
    .io_enq_0_bits_status_fuType_8 (io_enq_0_bits_fuType[8]),
    .io_enq_0_bits_status_fuType_9 (io_enq_0_bits_fuType[9]),
    .io_enq_0_bits_status_srcStatus_0_psrc (io_enq_0_bits_psrc_0),
    .io_enq_0_bits_status_srcStatus_0_srcType (io_enq_0_bits_srcType_0),
    .io_enq_0_bits_status_srcStatus_0_srcState (enq_src_state(io_enq_0_bits_srcType_0, p0_0_zero, io_enq_0_bits_srcState_0)),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value (enq_data_src(io_enq_0_bits_srcType_0, p0_0_zero)),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0 ({io_enq_0_bits_srcLoadDependency_0_0[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1 ({io_enq_0_bits_srcLoadDependency_0_1[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2 ({io_enq_0_bits_srcLoadDependency_0_2[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_0_useRegCache (io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_status_srcStatus_0_regCacheIdx (io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_status_srcStatus_1_psrc (io_enq_0_bits_psrc_1),
    .io_enq_0_bits_status_srcStatus_1_srcType (io_enq_0_bits_srcType_1),
    .io_enq_0_bits_status_srcStatus_1_srcState (enq_src_state(io_enq_0_bits_srcType_1, p0_1_zero, io_enq_0_bits_srcState_1)),
    .io_enq_0_bits_status_srcStatus_1_dataSources_value (enq_data_src(io_enq_0_bits_srcType_1, p0_1_zero)),
    .io_enq_0_bits_status_srcStatus_1_srcLoadDependency_0 ({io_enq_0_bits_srcLoadDependency_1_0[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_1_srcLoadDependency_1 ({io_enq_0_bits_srcLoadDependency_1_1[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_1_srcLoadDependency_2 ({io_enq_0_bits_srcLoadDependency_1_2[0], 1'h0}),
    .io_enq_0_bits_status_srcStatus_1_useRegCache (io_enq_0_bits_useRegCache_1),
    .io_enq_0_bits_status_srcStatus_1_regCacheIdx (io_enq_0_bits_regCacheIdx_1),
    .io_enq_0_bits_imm (io_enq_0_bits_imm),
    .io_enq_0_bits_payload_ftqPtr_flag (io_enq_0_bits_ftqPtr_flag),
    .io_enq_0_bits_payload_ftqPtr_value (io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_payload_ftqOffset (io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_payload_fuOpType (io_enq_0_bits_fuOpType),
    .io_enq_0_bits_payload_rfWen (io_enq_0_bits_rfWen),
    .io_enq_0_bits_payload_flushPipe (io_enq_0_bits_flushPipe),
    .io_enq_0_bits_payload_selImm (io_enq_0_bits_selImm),
    .io_enq_0_bits_payload_srcLoadDependency_0_0 (io_enq_0_bits_srcLoadDependency_0_0),
    .io_enq_0_bits_payload_srcLoadDependency_0_1 (io_enq_0_bits_srcLoadDependency_0_1),
    .io_enq_0_bits_payload_srcLoadDependency_0_2 (io_enq_0_bits_srcLoadDependency_0_2),
    .io_enq_0_bits_payload_srcLoadDependency_1_0 (io_enq_0_bits_srcLoadDependency_1_0),
    .io_enq_0_bits_payload_srcLoadDependency_1_1 (io_enq_0_bits_srcLoadDependency_1_1),
    .io_enq_0_bits_payload_srcLoadDependency_1_2 (io_enq_0_bits_srcLoadDependency_1_2),
    .io_enq_0_bits_payload_pdest (io_enq_0_bits_pdest),
    .io_enq_1_valid (s0_doEnq_1),
    .io_enq_1_bits_status_robIdx_flag (io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_status_robIdx_value (io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_status_fuType_5 (io_enq_1_bits_fuType[5]),
    .io_enq_1_bits_status_fuType_6 (io_enq_1_bits_fuType[6]),
    .io_enq_1_bits_status_fuType_8 (io_enq_1_bits_fuType[8]),
    .io_enq_1_bits_status_fuType_9 (io_enq_1_bits_fuType[9]),
    .io_enq_1_bits_status_srcStatus_0_psrc (io_enq_1_bits_psrc_0),
    .io_enq_1_bits_status_srcStatus_0_srcType (io_enq_1_bits_srcType_0),
    .io_enq_1_bits_status_srcStatus_0_srcState (enq_src_state(io_enq_1_bits_srcType_0, p1_0_zero, io_enq_1_bits_srcState_0)),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value (enq_data_src(io_enq_1_bits_srcType_0, p1_0_zero)),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0 ({io_enq_1_bits_srcLoadDependency_0_0[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1 ({io_enq_1_bits_srcLoadDependency_0_1[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2 ({io_enq_1_bits_srcLoadDependency_0_2[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_0_useRegCache (io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_status_srcStatus_0_regCacheIdx (io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_status_srcStatus_1_psrc (io_enq_1_bits_psrc_1),
    .io_enq_1_bits_status_srcStatus_1_srcType (io_enq_1_bits_srcType_1),
    .io_enq_1_bits_status_srcStatus_1_srcState (enq_src_state(io_enq_1_bits_srcType_1, p1_1_zero, io_enq_1_bits_srcState_1)),
    .io_enq_1_bits_status_srcStatus_1_dataSources_value (enq_data_src(io_enq_1_bits_srcType_1, p1_1_zero)),
    .io_enq_1_bits_status_srcStatus_1_srcLoadDependency_0 ({io_enq_1_bits_srcLoadDependency_1_0[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_1_srcLoadDependency_1 ({io_enq_1_bits_srcLoadDependency_1_1[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_1_srcLoadDependency_2 ({io_enq_1_bits_srcLoadDependency_1_2[0], 1'h0}),
    .io_enq_1_bits_status_srcStatus_1_useRegCache (io_enq_1_bits_useRegCache_1),
    .io_enq_1_bits_status_srcStatus_1_regCacheIdx (io_enq_1_bits_regCacheIdx_1),
    .io_enq_1_bits_imm (io_enq_1_bits_imm),
    .io_enq_1_bits_payload_ftqPtr_flag (io_enq_1_bits_ftqPtr_flag),
    .io_enq_1_bits_payload_ftqPtr_value (io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_payload_ftqOffset (io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_payload_fuOpType (io_enq_1_bits_fuOpType),
    .io_enq_1_bits_payload_rfWen (io_enq_1_bits_rfWen),
    .io_enq_1_bits_payload_flushPipe (io_enq_1_bits_flushPipe),
    .io_enq_1_bits_payload_selImm (io_enq_1_bits_selImm),
    .io_enq_1_bits_payload_srcLoadDependency_0_0 (io_enq_1_bits_srcLoadDependency_0_0),
    .io_enq_1_bits_payload_srcLoadDependency_0_1 (io_enq_1_bits_srcLoadDependency_0_1),
    .io_enq_1_bits_payload_srcLoadDependency_0_2 (io_enq_1_bits_srcLoadDependency_0_2),
    .io_enq_1_bits_payload_srcLoadDependency_1_0 (io_enq_1_bits_srcLoadDependency_1_0),
    .io_enq_1_bits_payload_srcLoadDependency_1_1 (io_enq_1_bits_srcLoadDependency_1_1),
    .io_enq_1_bits_payload_srcLoadDependency_1_2 (io_enq_1_bits_srcLoadDependency_1_2),
    .io_enq_1_bits_payload_pdest (io_enq_1_bits_pdest),
    .io_og0Resp_0_valid (io_og0Resp_0_valid),
    .io_og0Resp_1_valid (io_og0Resp_1_valid),
    .io_og1Resp_0_valid (io_og1Resp_0_valid),
    .io_og1Resp_1_valid (io_og1Resp_1_valid),
    .io_og1Resp_1_bits_resp (io_og1Resp_1_bits_resp),
    .io_deqSelOH_0_valid (deqValid_0),
    .io_deqSelOH_0_bits (deqSelOH_0),
    .io_deqSelOH_1_valid (deqValid_1),
    .io_deqSelOH_1_bits (deqSelOH_1),
    .io_enqEntryOldestSel_0_bits (age_enq_out[0]),
    .io_enqEntryOldestSel_1_bits (age_enq_out[1]),
    .io_simpEntryOldestSel_0_valid (|simpReq_0),
    .io_simpEntryOldestSel_0_bits (age_simp_out[0]),
    .io_simpEntryOldestSel_1_valid (|simpReq_1),
    .io_simpEntryOldestSel_1_bits (age_simp_out[1]),
    .io_compEntryOldestSel_0_valid (|compReq_0),
    .io_compEntryOldestSel_0_bits (age_comp_out[0]),
    .io_compEntryOldestSel_1_valid (|compReq_1),
    .io_compEntryOldestSel_1_bits (age_comp_out[1]),
    .io_wakeUpFromWB_3_valid (io_wakeupFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_rfWen (io_wakeupFromWB_3_bits_rfWen),
    .io_wakeUpFromWB_3_bits_pdest (io_wakeupFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid (io_wakeupFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_rfWen (io_wakeupFromWB_2_bits_rfWen),
    .io_wakeUpFromWB_2_bits_pdest (io_wakeupFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid (io_wakeupFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_rfWen (io_wakeupFromWB_1_bits_rfWen),
    .io_wakeUpFromWB_1_bits_pdest (io_wakeupFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid (io_wakeupFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_rfWen (io_wakeupFromWB_0_bits_rfWen),
    .io_wakeUpFromWB_0_bits_pdest (io_wakeupFromWB_0_bits_pdest),
    .io_wakeUpFromIQ_6_bits_rfWen (io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeUpFromIQ_6_bits_pdest (io_wakeupFromIQ_6_bits_pdest),
    .io_wakeUpFromIQ_6_bits_rcDest (io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeUpFromIQ_5_bits_rfWen (io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeUpFromIQ_5_bits_pdest (io_wakeupFromIQ_5_bits_pdest),
    .io_wakeUpFromIQ_5_bits_rcDest (io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeUpFromIQ_4_bits_rfWen (io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeUpFromIQ_4_bits_pdest (io_wakeupFromIQ_4_bits_pdest),
    .io_wakeUpFromIQ_4_bits_rcDest (io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeUpFromIQ_3_bits_rfWen (io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeUpFromIQ_3_bits_pdest (io_wakeupFromIQ_3_bits_pdest),
    .io_wakeUpFromIQ_3_bits_loadDependency_0 (io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeUpFromIQ_3_bits_loadDependency_1 (io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeUpFromIQ_3_bits_loadDependency_2 (io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeUpFromIQ_3_bits_rcDest (io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeUpFromIQ_2_bits_rfWen (io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeUpFromIQ_2_bits_pdest (io_wakeupFromIQ_2_bits_pdest),
    .io_wakeUpFromIQ_2_bits_loadDependency_0 (io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeUpFromIQ_2_bits_loadDependency_1 (io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeUpFromIQ_2_bits_loadDependency_2 (io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeUpFromIQ_2_bits_rcDest (io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeUpFromIQ_1_bits_rfWen (io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeUpFromIQ_1_bits_pdest (io_wakeupFromIQ_1_bits_pdest),
    .io_wakeUpFromIQ_1_bits_loadDependency_0 (io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeUpFromIQ_1_bits_loadDependency_1 (io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeUpFromIQ_1_bits_loadDependency_2 (io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeUpFromIQ_1_bits_is0Lat (io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeUpFromIQ_1_bits_rcDest (io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeUpFromIQ_0_bits_rfWen (io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeUpFromIQ_0_bits_pdest (io_wakeupFromIQ_0_bits_pdest),
    .io_wakeUpFromIQ_0_bits_loadDependency_0 (io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeUpFromIQ_0_bits_loadDependency_1 (io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeUpFromIQ_0_bits_loadDependency_2 (io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeUpFromIQ_0_bits_is0Lat (io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeUpFromIQ_0_bits_rcDest (io_wakeupFromIQ_0_bits_rcDest),
    .io_wakeUpFromWBDelayed_3_valid (io_wakeupFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_rfWen (io_wakeupFromWBDelayed_3_bits_rfWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest (io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid (io_wakeupFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_rfWen (io_wakeupFromWBDelayed_2_bits_rfWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest (io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid (io_wakeupFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_rfWen (io_wakeupFromWBDelayed_1_bits_rfWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest (io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid (io_wakeupFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_rfWen (io_wakeupFromWBDelayed_0_bits_rfWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest (io_wakeupFromWBDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_rfWen (io_wakeupFromIQDelayed_6_bits_rfWen),
    .io_wakeUpFromIQDelayed_6_bits_pdest (io_wakeupFromIQDelayed_6_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_rcDest (io_wakeupFromIQDelayed_6_bits_rcDest),
    .io_wakeUpFromIQDelayed_5_bits_rfWen (io_wakeupFromIQDelayed_5_bits_rfWen),
    .io_wakeUpFromIQDelayed_5_bits_pdest (io_wakeupFromIQDelayed_5_bits_pdest),
    .io_wakeUpFromIQDelayed_5_bits_rcDest (io_wakeupFromIQDelayed_5_bits_rcDest),
    .io_wakeUpFromIQDelayed_4_bits_rfWen (io_wakeupFromIQDelayed_4_bits_rfWen),
    .io_wakeUpFromIQDelayed_4_bits_pdest (io_wakeupFromIQDelayed_4_bits_pdest),
    .io_wakeUpFromIQDelayed_4_bits_rcDest (io_wakeupFromIQDelayed_4_bits_rcDest),
    .io_wakeUpFromIQDelayed_3_bits_rfWen (io_wakeupFromIQDelayed_3_bits_rfWen),
    .io_wakeUpFromIQDelayed_3_bits_pdest (io_wakeupFromIQDelayed_3_bits_pdest),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_0 (io_wakeupFromIQDelayed_3_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_1 (io_wakeupFromIQDelayed_3_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_2 (io_wakeupFromIQDelayed_3_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_3_bits_rcDest (io_wakeupFromIQDelayed_3_bits_rcDest),
    .io_wakeUpFromIQDelayed_2_bits_rfWen (io_wakeupFromIQDelayed_2_bits_rfWen),
    .io_wakeUpFromIQDelayed_2_bits_pdest (io_wakeupFromIQDelayed_2_bits_pdest),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_0 (io_wakeupFromIQDelayed_2_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_1 (io_wakeupFromIQDelayed_2_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_2 (io_wakeupFromIQDelayed_2_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_2_bits_rcDest (io_wakeupFromIQDelayed_2_bits_rcDest),
    .io_wakeUpFromIQDelayed_1_bits_rfWen (io_wakeupFromIQDelayed_1_bits_rfWen),
    .io_wakeUpFromIQDelayed_1_bits_pdest (io_wakeupFromIQDelayed_1_bits_pdest),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_0 (io_wakeupFromIQDelayed_1_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_1 (io_wakeupFromIQDelayed_1_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_2 (io_wakeupFromIQDelayed_1_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_1_bits_is0Lat (io_wakeupFromIQDelayed_1_bits_is0Lat),
    .io_wakeUpFromIQDelayed_1_bits_rcDest (io_wakeupFromIQDelayed_1_bits_rcDest),
    .io_wakeUpFromIQDelayed_0_bits_rfWen (io_wakeupFromIQDelayed_0_bits_rfWen),
    .io_wakeUpFromIQDelayed_0_bits_pdest (io_wakeupFromIQDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_0 (io_wakeupFromIQDelayed_0_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_1 (io_wakeupFromIQDelayed_0_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_2 (io_wakeupFromIQDelayed_0_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_0_bits_is0Lat (io_wakeupFromIQDelayed_0_bits_is0Lat),
    .io_wakeUpFromIQDelayed_0_bits_rcDest (io_wakeupFromIQDelayed_0_bits_rcDest),
    .io_og0Cancel_0 (io_og0Cancel_0),
    .io_og0Cancel_2 (io_og0Cancel_2),
    .io_og0Cancel_4 (io_og0Cancel_4),
    .io_og0Cancel_6 (io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel (io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel (io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel (io_ldCancel_2_ld2Cancel),
    .io_valid (e_valid),
    .io_issued (e_issued),
    .io_canIssue (e_can_issue),
    .io_fuType_0 (e_fu_type[0]),   .io_fuType_1 (e_fu_type[1]),
    .io_fuType_2 (e_fu_type[2]),   .io_fuType_3 (e_fu_type[3]),
    .io_fuType_4 (e_fu_type[4]),   .io_fuType_5 (e_fu_type[5]),
    .io_fuType_6 (e_fu_type[6]),   .io_fuType_7 (e_fu_type[7]),
    .io_fuType_8 (e_fu_type[8]),   .io_fuType_9 (e_fu_type[9]),
    .io_fuType_10 (e_fu_type[10]), .io_fuType_11 (e_fu_type[11]),
    .io_fuType_12 (e_fu_type[12]), .io_fuType_13 (e_fu_type[13]),
    .io_fuType_14 (e_fu_type[14]), .io_fuType_15 (e_fu_type[15]),
    .io_fuType_16 (e_fu_type[16]), .io_fuType_17 (e_fu_type[17]),
    .io_fuType_18 (e_fu_type[18]), .io_fuType_19 (e_fu_type[19]),
    .io_fuType_20 (e_fu_type[20]), .io_fuType_21 (e_fu_type[21]),
    .io_fuType_22 (e_fu_type[22]), .io_fuType_23 (e_fu_type[23]),
    .io_dataSources_0_0_value (e_data_src[0][0]),   .io_dataSources_0_1_value (e_data_src[0][1]),
    .io_dataSources_1_0_value (e_data_src[1][0]),   .io_dataSources_1_1_value (e_data_src[1][1]),
    .io_dataSources_2_0_value (e_data_src[2][0]),   .io_dataSources_2_1_value (e_data_src[2][1]),
    .io_dataSources_3_0_value (e_data_src[3][0]),   .io_dataSources_3_1_value (e_data_src[3][1]),
    .io_dataSources_4_0_value (e_data_src[4][0]),   .io_dataSources_4_1_value (e_data_src[4][1]),
    .io_dataSources_5_0_value (e_data_src[5][0]),   .io_dataSources_5_1_value (e_data_src[5][1]),
    .io_dataSources_6_0_value (e_data_src[6][0]),   .io_dataSources_6_1_value (e_data_src[6][1]),
    .io_dataSources_7_0_value (e_data_src[7][0]),   .io_dataSources_7_1_value (e_data_src[7][1]),
    .io_dataSources_8_0_value (e_data_src[8][0]),   .io_dataSources_8_1_value (e_data_src[8][1]),
    .io_dataSources_9_0_value (e_data_src[9][0]),   .io_dataSources_9_1_value (e_data_src[9][1]),
    .io_dataSources_10_0_value (e_data_src[10][0]), .io_dataSources_10_1_value (e_data_src[10][1]),
    .io_dataSources_11_0_value (e_data_src[11][0]), .io_dataSources_11_1_value (e_data_src[11][1]),
    .io_dataSources_12_0_value (e_data_src[12][0]), .io_dataSources_12_1_value (e_data_src[12][1]),
    .io_dataSources_13_0_value (e_data_src[13][0]), .io_dataSources_13_1_value (e_data_src[13][1]),
    .io_dataSources_14_0_value (e_data_src[14][0]), .io_dataSources_14_1_value (e_data_src[14][1]),
    .io_dataSources_15_0_value (e_data_src[15][0]), .io_dataSources_15_1_value (e_data_src[15][1]),
    .io_dataSources_16_0_value (e_data_src[16][0]), .io_dataSources_16_1_value (e_data_src[16][1]),
    .io_dataSources_17_0_value (e_data_src[17][0]), .io_dataSources_17_1_value (e_data_src[17][1]),
    .io_dataSources_18_0_value (e_data_src[18][0]), .io_dataSources_18_1_value (e_data_src[18][1]),
    .io_dataSources_19_0_value (e_data_src[19][0]), .io_dataSources_19_1_value (e_data_src[19][1]),
    .io_dataSources_20_0_value (e_data_src[20][0]), .io_dataSources_20_1_value (e_data_src[20][1]),
    .io_dataSources_21_0_value (e_data_src[21][0]), .io_dataSources_21_1_value (e_data_src[21][1]),
    .io_dataSources_22_0_value (e_data_src[22][0]), .io_dataSources_22_1_value (e_data_src[22][1]),
    .io_dataSources_23_0_value (e_data_src[23][0]), .io_dataSources_23_1_value (e_data_src[23][1]),
    .io_loadDependency_0_0 (e_load_dep[0][0]),   .io_loadDependency_0_1 (e_load_dep[0][1]),   .io_loadDependency_0_2 (e_load_dep[0][2]),
    .io_loadDependency_1_0 (e_load_dep[1][0]),   .io_loadDependency_1_1 (e_load_dep[1][1]),   .io_loadDependency_1_2 (e_load_dep[1][2]),
    .io_loadDependency_2_0 (e_load_dep[2][0]),   .io_loadDependency_2_1 (e_load_dep[2][1]),   .io_loadDependency_2_2 (e_load_dep[2][2]),
    .io_loadDependency_3_0 (e_load_dep[3][0]),   .io_loadDependency_3_1 (e_load_dep[3][1]),   .io_loadDependency_3_2 (e_load_dep[3][2]),
    .io_loadDependency_4_0 (e_load_dep[4][0]),   .io_loadDependency_4_1 (e_load_dep[4][1]),   .io_loadDependency_4_2 (e_load_dep[4][2]),
    .io_loadDependency_5_0 (e_load_dep[5][0]),   .io_loadDependency_5_1 (e_load_dep[5][1]),   .io_loadDependency_5_2 (e_load_dep[5][2]),
    .io_loadDependency_6_0 (e_load_dep[6][0]),   .io_loadDependency_6_1 (e_load_dep[6][1]),   .io_loadDependency_6_2 (e_load_dep[6][2]),
    .io_loadDependency_7_0 (e_load_dep[7][0]),   .io_loadDependency_7_1 (e_load_dep[7][1]),   .io_loadDependency_7_2 (e_load_dep[7][2]),
    .io_loadDependency_8_0 (e_load_dep[8][0]),   .io_loadDependency_8_1 (e_load_dep[8][1]),   .io_loadDependency_8_2 (e_load_dep[8][2]),
    .io_loadDependency_9_0 (e_load_dep[9][0]),   .io_loadDependency_9_1 (e_load_dep[9][1]),   .io_loadDependency_9_2 (e_load_dep[9][2]),
    .io_loadDependency_10_0 (e_load_dep[10][0]), .io_loadDependency_10_1 (e_load_dep[10][1]), .io_loadDependency_10_2 (e_load_dep[10][2]),
    .io_loadDependency_11_0 (e_load_dep[11][0]), .io_loadDependency_11_1 (e_load_dep[11][1]), .io_loadDependency_11_2 (e_load_dep[11][2]),
    .io_loadDependency_12_0 (e_load_dep[12][0]), .io_loadDependency_12_1 (e_load_dep[12][1]), .io_loadDependency_12_2 (e_load_dep[12][2]),
    .io_loadDependency_13_0 (e_load_dep[13][0]), .io_loadDependency_13_1 (e_load_dep[13][1]), .io_loadDependency_13_2 (e_load_dep[13][2]),
    .io_loadDependency_14_0 (e_load_dep[14][0]), .io_loadDependency_14_1 (e_load_dep[14][1]), .io_loadDependency_14_2 (e_load_dep[14][2]),
    .io_loadDependency_15_0 (e_load_dep[15][0]), .io_loadDependency_15_1 (e_load_dep[15][1]), .io_loadDependency_15_2 (e_load_dep[15][2]),
    .io_loadDependency_16_0 (e_load_dep[16][0]), .io_loadDependency_16_1 (e_load_dep[16][1]), .io_loadDependency_16_2 (e_load_dep[16][2]),
    .io_loadDependency_17_0 (e_load_dep[17][0]), .io_loadDependency_17_1 (e_load_dep[17][1]), .io_loadDependency_17_2 (e_load_dep[17][2]),
    .io_loadDependency_18_0 (e_load_dep[18][0]), .io_loadDependency_18_1 (e_load_dep[18][1]), .io_loadDependency_18_2 (e_load_dep[18][2]),
    .io_loadDependency_19_0 (e_load_dep[19][0]), .io_loadDependency_19_1 (e_load_dep[19][1]), .io_loadDependency_19_2 (e_load_dep[19][2]),
    .io_loadDependency_20_0 (e_load_dep[20][0]), .io_loadDependency_20_1 (e_load_dep[20][1]), .io_loadDependency_20_2 (e_load_dep[20][2]),
    .io_loadDependency_21_0 (e_load_dep[21][0]), .io_loadDependency_21_1 (e_load_dep[21][1]), .io_loadDependency_21_2 (e_load_dep[21][2]),
    .io_loadDependency_22_0 (e_load_dep[22][0]), .io_loadDependency_22_1 (e_load_dep[22][1]), .io_loadDependency_22_2 (e_load_dep[22][2]),
    .io_loadDependency_23_0 (e_load_dep[23][0]), .io_loadDependency_23_1 (e_load_dep[23][1]), .io_loadDependency_23_2 (e_load_dep[23][2]),
    .io_exuSources_0_0_value (e_exu_src[0][0]),   .io_exuSources_0_1_value (e_exu_src[0][1]),
    .io_exuSources_1_0_value (e_exu_src[1][0]),   .io_exuSources_1_1_value (e_exu_src[1][1]),
    .io_exuSources_2_0_value (e_exu_src[2][0]),   .io_exuSources_2_1_value (e_exu_src[2][1]),
    .io_exuSources_3_0_value (e_exu_src[3][0]),   .io_exuSources_3_1_value (e_exu_src[3][1]),
    .io_exuSources_4_0_value (e_exu_src[4][0]),   .io_exuSources_4_1_value (e_exu_src[4][1]),
    .io_exuSources_5_0_value (e_exu_src[5][0]),   .io_exuSources_5_1_value (e_exu_src[5][1]),
    .io_exuSources_6_0_value (e_exu_src[6][0]),   .io_exuSources_6_1_value (e_exu_src[6][1]),
    .io_exuSources_7_0_value (e_exu_src[7][0]),   .io_exuSources_7_1_value (e_exu_src[7][1]),
    .io_exuSources_8_0_value (e_exu_src[8][0]),   .io_exuSources_8_1_value (e_exu_src[8][1]),
    .io_exuSources_9_0_value (e_exu_src[9][0]),   .io_exuSources_9_1_value (e_exu_src[9][1]),
    .io_exuSources_10_0_value (e_exu_src[10][0]), .io_exuSources_10_1_value (e_exu_src[10][1]),
    .io_exuSources_11_0_value (e_exu_src[11][0]), .io_exuSources_11_1_value (e_exu_src[11][1]),
    .io_exuSources_12_0_value (e_exu_src[12][0]), .io_exuSources_12_1_value (e_exu_src[12][1]),
    .io_exuSources_13_0_value (e_exu_src[13][0]), .io_exuSources_13_1_value (e_exu_src[13][1]),
    .io_exuSources_14_0_value (e_exu_src[14][0]), .io_exuSources_14_1_value (e_exu_src[14][1]),
    .io_exuSources_15_0_value (e_exu_src[15][0]), .io_exuSources_15_1_value (e_exu_src[15][1]),
    .io_exuSources_16_0_value (e_exu_src[16][0]), .io_exuSources_16_1_value (e_exu_src[16][1]),
    .io_exuSources_17_0_value (e_exu_src[17][0]), .io_exuSources_17_1_value (e_exu_src[17][1]),
    .io_exuSources_18_0_value (e_exu_src[18][0]), .io_exuSources_18_1_value (e_exu_src[18][1]),
    .io_exuSources_19_0_value (e_exu_src[19][0]), .io_exuSources_19_1_value (e_exu_src[19][1]),
    .io_exuSources_20_0_value (e_exu_src[20][0]), .io_exuSources_20_1_value (e_exu_src[20][1]),
    .io_exuSources_21_0_value (e_exu_src[21][0]), .io_exuSources_21_1_value (e_exu_src[21][1]),
    .io_exuSources_22_0_value (e_exu_src[22][0]), .io_exuSources_22_1_value (e_exu_src[22][1]),
    .io_exuSources_23_0_value (e_exu_src[23][0]), .io_exuSources_23_1_value (e_exu_src[23][1]),
    .io_deqEntry_0_bits_status_robIdx_flag (e_deq0_robflag),
    .io_deqEntry_0_bits_status_robIdx_value (e_deq0_robval),
    .io_deqEntry_0_bits_status_fuType_5 (e_deq0_ft5),
    .io_deqEntry_0_bits_status_fuType_6 (e_deq0_ft6),
    .io_deqEntry_0_bits_status_fuType_8 (e_deq0_ft8),
    .io_deqEntry_0_bits_status_fuType_9 (e_deq0_ft9),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc (e_deq0_s0psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType (e_deq0_s0type),
    .io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx (e_deq0_s0rc),
    .io_deqEntry_0_bits_status_srcStatus_1_psrc (e_deq0_s1psrc),
    .io_deqEntry_0_bits_status_srcStatus_1_srcType (e_deq0_s1type),
    .io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx (e_deq0_s1rc),
    .io_deqEntry_0_bits_imm (e_deq0_imm),
    .io_deqEntry_0_bits_payload_fuOpType (e_deq0_fuop),
    .io_deqEntry_0_bits_payload_rfWen (e_deq0_rfwen),
    .io_deqEntry_0_bits_payload_selImm (e_deq0_selimm),
    .io_deqEntry_0_bits_payload_pdest (e_deq0_pdest),
    .io_deqEntry_1_bits_status_robIdx_flag (e_deq1_robflag),
    .io_deqEntry_1_bits_status_robIdx_value (e_deq1_robval),
    .io_deqEntry_1_bits_status_fuType_5 (e_deq1_ft5),
    .io_deqEntry_1_bits_status_fuType_6 (e_deq1_ft6),
    .io_deqEntry_1_bits_status_fuType_8 (e_deq1_ft8),
    .io_deqEntry_1_bits_status_fuType_9 (e_deq1_ft9),
    .io_deqEntry_1_bits_status_srcStatus_0_psrc (e_deq1_s0psrc),
    .io_deqEntry_1_bits_status_srcStatus_0_srcType (e_deq1_s0type),
    .io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx (e_deq1_s0rc),
    .io_deqEntry_1_bits_status_srcStatus_1_psrc (e_deq1_s1psrc),
    .io_deqEntry_1_bits_status_srcStatus_1_srcType (e_deq1_s1type),
    .io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx (e_deq1_s1rc),
    .io_deqEntry_1_bits_imm (e_deq1_imm),
    .io_deqEntry_1_bits_payload_ftqPtr_flag (e_deq1_ftqflag),
    .io_deqEntry_1_bits_payload_ftqPtr_value (e_deq1_ftqval),
    .io_deqEntry_1_bits_payload_ftqOffset (e_deq1_ftqoff),
    .io_deqEntry_1_bits_payload_fuOpType (e_deq1_fuop),
    .io_deqEntry_1_bits_payload_rfWen (e_deq1_rfwen),
    .io_deqEntry_1_bits_payload_flushPipe (e_deq1_flushpipe),
    .io_deqEntry_1_bits_payload_pdest (e_deq1_pdest),
    .io_cancelDeqVec_0 (e_cancel_deq[0]),
    .io_cancelDeqVec_1 (e_cancel_deq[1]),
    .io_simpEntryDeqSelVec_0 (age_simp_out[2]),
    .io_simpEntryDeqSelVec_1 (age_simp_out[3]),
    .io_simpEntryEnqSelVec_0 (e_simp_enq_sel[0]),
    .io_simpEntryEnqSelVec_1 (e_simp_enq_sel[1]),
    .io_compEntryEnqSelVec_0 (e_comp_enq_sel[0]),
    .io_compEntryEnqSelVec_1 (e_comp_enq_sel[1])
  );

  FuBusyTableRead_23 intWbBusyTableRead_0 (
    .io_in_fuBusyTable      (1'h0),
    .io_in_fuTypeRegVec_0   (e_fu_type[0]),  .io_in_fuTypeRegVec_1  (e_fu_type[1]),
    .io_in_fuTypeRegVec_2   (e_fu_type[2]),  .io_in_fuTypeRegVec_3  (e_fu_type[3]),
    .io_in_fuTypeRegVec_4   (e_fu_type[4]),  .io_in_fuTypeRegVec_5  (e_fu_type[5]),
    .io_in_fuTypeRegVec_6   (e_fu_type[6]),  .io_in_fuTypeRegVec_7  (e_fu_type[7]),
    .io_in_fuTypeRegVec_8   (e_fu_type[8]),  .io_in_fuTypeRegVec_9  (e_fu_type[9]),
    .io_in_fuTypeRegVec_10  (e_fu_type[10]), .io_in_fuTypeRegVec_11 (e_fu_type[11]),
    .io_in_fuTypeRegVec_12  (e_fu_type[12]), .io_in_fuTypeRegVec_13 (e_fu_type[13]),
    .io_in_fuTypeRegVec_14  (e_fu_type[14]), .io_in_fuTypeRegVec_15 (e_fu_type[15]),
    .io_in_fuTypeRegVec_16  (e_fu_type[16]), .io_in_fuTypeRegVec_17 (e_fu_type[17]),
    .io_in_fuTypeRegVec_18  (e_fu_type[18]), .io_in_fuTypeRegVec_19 (e_fu_type[19]),
    .io_in_fuTypeRegVec_20  (e_fu_type[20]), .io_in_fuTypeRegVec_21 (e_fu_type[21]),
    .io_in_fuTypeRegVec_22  (e_fu_type[22]), .io_in_fuTypeRegVec_23 (e_fu_type[23]),
    .io_out_fuBusyTableMask (fu_busy_mask)
  );

  MultiWakeupQueue_2 wakeUpQueues_0 (
    .clock                              (clock),
    .io_enq_valid                       (deqBeforeDly_0_valid),
    .io_enq_bits_uop_fuType             (deqBeforeDly_0_fuType),
    .io_enq_bits_uop_pdest              (e_deq0_pdest),
    .io_enq_bits_uop_rfWen              (e_deq0_rfwen),
    .io_enq_bits_uop_loadDependency_0   (finalLoadDependency_0_0),
    .io_enq_bits_uop_loadDependency_1   (finalLoadDependency_0_1),
    .io_enq_bits_uop_loadDependency_2   (finalLoadDependency_0_2),
    .io_deq_valid                       (wkq_deq_valid),
    .io_deq_bits_pdestCopy_0            (io_wakeupToIQ_0_bits_pdestCopy_0),
    .io_deq_bits_pdestCopy_1            (io_wakeupToIQ_0_bits_pdestCopy_1),
    .io_deq_bits_pdestCopy_2            (io_wakeupToIQ_0_bits_pdestCopy_2),
    .io_deq_bits_pdestCopy_3            (io_wakeupToIQ_0_bits_pdestCopy_3),
    .io_deq_bits_pdestCopy_4            (io_wakeupToIQ_0_bits_pdestCopy_4),
    .io_deq_bits_pdestCopy_5            (io_wakeupToIQ_0_bits_pdestCopy_5),
    .io_deq_bits_rfWenCopy_0            (io_wakeupToIQ_0_bits_rfWenCopy_0),
    .io_deq_bits_rfWenCopy_1            (io_wakeupToIQ_0_bits_rfWenCopy_1),
    .io_deq_bits_rfWenCopy_2            (io_wakeupToIQ_0_bits_rfWenCopy_2),
    .io_deq_bits_rfWenCopy_3            (io_wakeupToIQ_0_bits_rfWenCopy_3),
    .io_deq_bits_rfWenCopy_4            (io_wakeupToIQ_0_bits_rfWenCopy_4),
    .io_deq_bits_rfWenCopy_5            (io_wakeupToIQ_0_bits_rfWenCopy_5),
    .io_deq_bits_loadDependencyCopy_0_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_0_0),
    .io_deq_bits_loadDependencyCopy_0_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_0_1),
    .io_deq_bits_loadDependencyCopy_0_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_0_2),
    .io_deq_bits_loadDependencyCopy_1_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_1_0),
    .io_deq_bits_loadDependencyCopy_1_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_1_1),
    .io_deq_bits_loadDependencyCopy_1_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_1_2),
    .io_deq_bits_loadDependencyCopy_2_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_2_0),
    .io_deq_bits_loadDependencyCopy_2_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_2_1),
    .io_deq_bits_loadDependencyCopy_2_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_2_2),
    .io_deq_bits_loadDependencyCopy_3_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_3_0),
    .io_deq_bits_loadDependencyCopy_3_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_3_1),
    .io_deq_bits_loadDependencyCopy_3_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_3_2),
    .io_deq_bits_loadDependencyCopy_4_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_4_0),
    .io_deq_bits_loadDependencyCopy_4_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_4_1),
    .io_deq_bits_loadDependencyCopy_4_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_4_2),
    .io_deq_bits_loadDependencyCopy_5_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_5_0),
    .io_deq_bits_loadDependencyCopy_5_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_5_1),
    .io_deq_bits_loadDependencyCopy_5_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_5_2),
    .io_deq_bits_pdest                  (io_wakeupToIQ_0_bits_pdest),
    .io_deq_bits_rfWen                  (wkq_deq_rfwen),
    .io_deq_bits_loadDependency_0       (io_wakeupToIQ_0_bits_loadDependency_0),
    .io_deq_bits_loadDependency_1       (io_wakeupToIQ_0_bits_loadDependency_1),
    .io_deq_bits_loadDependency_2       (io_wakeupToIQ_0_bits_loadDependency_2)
  );

  NewAgeDetector age (
    .clock (clock), .reset (reset),
    .io_enq_0 (s0_doEnq_0), .io_enq_1 (s0_doEnq_1),
    .io_canIssue_0 (enqReq_0), .io_canIssue_1 (enqReq_1),
    .io_out_0 (age_enq_out[0]), .io_out_1 (age_enq_out[1])
  );
  AgeDetector age_1 (
    .clock (clock), .reset (reset),
    .io_enq_0 (e_simp_enq_sel[0]), .io_enq_1 (e_simp_enq_sel[1]),
    .io_canIssue_0 (simpReq_0), .io_canIssue_1 (simpReq_1),
    .io_canIssue_2 (simpReq_2), .io_canIssue_3 (simpReq_3),
    .io_out_0 (age_simp_out[0]), .io_out_1 (age_simp_out[1]),
    .io_out_2 (age_simp_out[2]), .io_out_3 (age_simp_out[3])
  );
  AgeDetector_1 age_2 (
    .clock (clock), .reset (reset),
    .io_enq_0 (e_comp_enq_sel[0]), .io_enq_1 (e_comp_enq_sel[1]),
    .io_canIssue_0 (compReq_0), .io_canIssue_1 (compReq_1),
    .io_out_0 (age_comp_out[0]), .io_out_1 (age_comp_out[1])
  );
endmodule

// =============================================================================
// IssueQueueAluCsrFenceDiv —— golden 同名顶层。本变体 IQ 顶层端口与可读核完全一致
// (核已直接持平 golden 扁平接口), 故这里是纯穿透 wrapper, 仅做命名对齐。
// =============================================================================
module IssueQueueAluCsrFenceDiv (
  input         clock,
  input         reset,
`include "issuequeue_acfd_ports.svh"
);
`include "issuequeue_acfd_connect.svh"
endmodule
