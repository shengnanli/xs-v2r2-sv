// NewPipelineConnectPipe_34.sv — MemBlock 里"其它 store 输出"回 Backend 的单拍流水缓冲。
// 例化点（G1 golden，唯一一处）：MemBlock.inner_otherStoutConnect —— 非普通 store 流水线
//   （原子/CMO/misalign 等）的 store 写回结果，经本级送回后端写回网络。
// 本变体参数与规模：payload = 46 字段 / 760 位（24 位异常向量 + trigger + rfWen/flushPipe
//   + pdest/robIdx/sqIdx + 完整 debugInfo 时间戳束 + 64 位 data + debug_isMMIO）；
//   模块端口 99 个（51 输入 / 48 输出）；golden 模块体 422 行。
// ★本变体没有 io_isFlush 端口★：golden 的 valid 次态是
//   valid' = fire | ~rightOutFire & valid，没有冲刷项。所以例化共享核时把
//   io_isFlush 恒接 1'b0，与 golden 逐位等价。
// 家族关系：与全族共用一个核 xs_PipelineConnect（rtl/common/PipelineConnect.sv），
//   本文件只提供本变体的 payload 字段表与打包/拆包，不复制任何核逻辑。
// 时序（逐字段从 G1 golden 机械核实）：**没有任何组合直通字段**，全部 RegEnable 打拍；
//   唯一的组合输出是 io_in_ready = io_out_ready | ~valid。
// ★名字警告★：本变体在 G0(v2r2) 里叫 NewPipelineConnectPipe_32（71 端口），
//   G1 编号平移 +2 且 payload 从 32 字段/231 位扩到 46 字段/760 位。
//   判据是例化坑位集合相等，见 scripts/check_name_collisions.py。

module NewPipelineConnectPipe_34 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic io_in_bits_uop_exceptionVec_0,
  input  logic io_in_bits_uop_exceptionVec_1,
  input  logic io_in_bits_uop_exceptionVec_2,
  input  logic io_in_bits_uop_exceptionVec_3,
  input  logic io_in_bits_uop_exceptionVec_4,
  input  logic io_in_bits_uop_exceptionVec_5,
  input  logic io_in_bits_uop_exceptionVec_6,
  input  logic io_in_bits_uop_exceptionVec_7,
  input  logic io_in_bits_uop_exceptionVec_8,
  input  logic io_in_bits_uop_exceptionVec_9,
  input  logic io_in_bits_uop_exceptionVec_10,
  input  logic io_in_bits_uop_exceptionVec_11,
  input  logic io_in_bits_uop_exceptionVec_12,
  input  logic io_in_bits_uop_exceptionVec_13,
  input  logic io_in_bits_uop_exceptionVec_14,
  input  logic io_in_bits_uop_exceptionVec_15,
  input  logic io_in_bits_uop_exceptionVec_16,
  input  logic io_in_bits_uop_exceptionVec_17,
  input  logic io_in_bits_uop_exceptionVec_18,
  input  logic io_in_bits_uop_exceptionVec_19,
  input  logic io_in_bits_uop_exceptionVec_20,
  input  logic io_in_bits_uop_exceptionVec_21,
  input  logic io_in_bits_uop_exceptionVec_22,
  input  logic io_in_bits_uop_exceptionVec_23,
  input  logic [3:0] io_in_bits_uop_trigger,
  input  logic io_in_bits_uop_rfWen,
  input  logic io_in_bits_uop_flushPipe,
  input  logic [7:0] io_in_bits_uop_pdest,
  input  logic io_in_bits_uop_robIdx_flag,
  input  logic [7:0] io_in_bits_uop_robIdx_value,
  input  logic io_in_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0] io_in_bits_uop_debugInfo_renameTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_writebackTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0] io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0] io_in_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0] io_in_bits_uop_debug_seqNum_uopIdx,
  input  logic io_in_bits_uop_sqIdx_flag,
  input  logic [5:0] io_in_bits_uop_sqIdx_value,
  input  logic [63:0] io_in_bits_data,
  input  logic io_in_bits_debug_isMMIO,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic io_out_bits_uop_exceptionVec_0,
  output logic io_out_bits_uop_exceptionVec_1,
  output logic io_out_bits_uop_exceptionVec_2,
  output logic io_out_bits_uop_exceptionVec_3,
  output logic io_out_bits_uop_exceptionVec_4,
  output logic io_out_bits_uop_exceptionVec_5,
  output logic io_out_bits_uop_exceptionVec_6,
  output logic io_out_bits_uop_exceptionVec_7,
  output logic io_out_bits_uop_exceptionVec_8,
  output logic io_out_bits_uop_exceptionVec_9,
  output logic io_out_bits_uop_exceptionVec_10,
  output logic io_out_bits_uop_exceptionVec_11,
  output logic io_out_bits_uop_exceptionVec_12,
  output logic io_out_bits_uop_exceptionVec_13,
  output logic io_out_bits_uop_exceptionVec_14,
  output logic io_out_bits_uop_exceptionVec_15,
  output logic io_out_bits_uop_exceptionVec_16,
  output logic io_out_bits_uop_exceptionVec_17,
  output logic io_out_bits_uop_exceptionVec_18,
  output logic io_out_bits_uop_exceptionVec_19,
  output logic io_out_bits_uop_exceptionVec_20,
  output logic io_out_bits_uop_exceptionVec_21,
  output logic io_out_bits_uop_exceptionVec_22,
  output logic io_out_bits_uop_exceptionVec_23,
  output logic [3:0] io_out_bits_uop_trigger,
  output logic io_out_bits_uop_rfWen,
  output logic io_out_bits_uop_flushPipe,
  output logic [7:0] io_out_bits_uop_pdest,
  output logic io_out_bits_uop_robIdx_flag,
  output logic [7:0] io_out_bits_uop_robIdx_value,
  output logic io_out_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0] io_out_bits_uop_debugInfo_renameTime,
  output logic [63:0] io_out_bits_uop_debugInfo_dispatchTime,
  output logic [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output logic [63:0] io_out_bits_uop_debugInfo_selectTime,
  output logic [63:0] io_out_bits_uop_debugInfo_issueTime,
  output logic [63:0] io_out_bits_uop_debugInfo_writebackTime,
  output logic [63:0] io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0] io_out_bits_uop_debug_seqNum_seqNum,
  output logic [7:0] io_out_bits_uop_debug_seqNum_uopIdx,
  output logic io_out_bits_uop_sqIdx_flag,
  output logic [5:0] io_out_bits_uop_sqIdx_value,
  output logic [63:0] io_out_bits_data,
  output logic io_out_bits_debug_isMMIO,
  input  logic io_rightOutFire
);

  // ---------------------------------------------------------------------------
  // 本变体的 payload 布局。用 packed struct 而不是手工位切片：入口打包与出口拆包
  // 都按同一组成员名访问，"字段错位"在结构上就不可能发生（这一族历史上正是
  // 手工切片 + 照抄错基线的端口表而集体配错）。成员顺序照 G1 golden 端口表，
  // 顺序本身不影响功能——核只把 payload 当一坨位搬运。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    // uop.exceptionVec：异常向量，本变体导出 24 号位全体（0~23）
    logic           uop_exceptionVec_0;
    logic           uop_exceptionVec_1;
    logic           uop_exceptionVec_2;
    logic           uop_exceptionVec_3;
    logic           uop_exceptionVec_4;
    logic           uop_exceptionVec_5;
    logic           uop_exceptionVec_6;
    logic           uop_exceptionVec_7;
    logic           uop_exceptionVec_8;
    logic           uop_exceptionVec_9;
    logic           uop_exceptionVec_10;
    logic           uop_exceptionVec_11;
    logic           uop_exceptionVec_12;
    logic           uop_exceptionVec_13;
    logic           uop_exceptionVec_14;
    logic           uop_exceptionVec_15;
    logic           uop_exceptionVec_16;
    logic           uop_exceptionVec_17;
    logic           uop_exceptionVec_18;
    logic           uop_exceptionVec_19;
    logic           uop_exceptionVec_20;
    logic           uop_exceptionVec_21;
    logic           uop_exceptionVec_22;
    logic           uop_exceptionVec_23;
    // uop：微操作本身的控制位
    logic [3:0]     uop_trigger;
    logic           uop_rfWen;
    logic           uop_flushPipe;
    logic [7:0]     uop_pdest;
    // uop.robIdx：ROB 表项指针（flag = 回绕位）
    logic           uop_robIdx_flag;
    logic [7:0]     uop_robIdx_value;
    // uop.debugInfo：性能剖析时间戳。**随流水打拍透传，不是组合直通**
    logic           uop_debugInfo_eliminatedMove;
    logic [63:0]    uop_debugInfo_renameTime;
    logic [63:0]    uop_debugInfo_dispatchTime;
    logic [63:0]    uop_debugInfo_enqRsTime;
    logic [63:0]    uop_debugInfo_selectTime;
    logic [63:0]    uop_debugInfo_issueTime;
    logic [63:0]    uop_debugInfo_writebackTime;
    logic [63:0]    uop_debugInfo_runahead_checkpoint_id;
    logic [63:0]    uop_debugInfo_tlbFirstReqTime;
    logic [63:0]    uop_debugInfo_tlbRespTime;
    // uop.debug.seqNum：调试用指令序号
    logic [55:0]    uop_debug_seqNum_seqNum;
    logic [7:0]     uop_debug_seqNum_uopIdx;
    // uop.sqIdx：store queue 指针（flag = 回绕位）
    logic           uop_sqIdx_flag;
    logic [5:0]     uop_sqIdx_value;
    // 本级自己的数据字段（不属于 uop 束）
    logic [63:0]    data;
    logic           debug_isMMIO;
  } payload_t;

  // G1 golden 该变体所有 io_in_bits_* 的位宽之和。传给共享核做防呆：
  // 核里的 initial 会校验 DATA_WIDTH（= $bits(payload_t)）与它相等。
  // ★这个参数必须显式传★——核给了默认值 PAYLOAD_W_G1 = DATA_WIDTH，省略即等于不校验。
  localparam int unsigned PAYLOAD_W_G1 = 760;

  payload_t in_payload, out_payload;

  // 入口打包：端口 -> struct 成员（同名逐项）
  always_comb begin
    in_payload.uop_exceptionVec_0                   = io_in_bits_uop_exceptionVec_0;
    in_payload.uop_exceptionVec_1                   = io_in_bits_uop_exceptionVec_1;
    in_payload.uop_exceptionVec_2                   = io_in_bits_uop_exceptionVec_2;
    in_payload.uop_exceptionVec_3                   = io_in_bits_uop_exceptionVec_3;
    in_payload.uop_exceptionVec_4                   = io_in_bits_uop_exceptionVec_4;
    in_payload.uop_exceptionVec_5                   = io_in_bits_uop_exceptionVec_5;
    in_payload.uop_exceptionVec_6                   = io_in_bits_uop_exceptionVec_6;
    in_payload.uop_exceptionVec_7                   = io_in_bits_uop_exceptionVec_7;
    in_payload.uop_exceptionVec_8                   = io_in_bits_uop_exceptionVec_8;
    in_payload.uop_exceptionVec_9                   = io_in_bits_uop_exceptionVec_9;
    in_payload.uop_exceptionVec_10                  = io_in_bits_uop_exceptionVec_10;
    in_payload.uop_exceptionVec_11                  = io_in_bits_uop_exceptionVec_11;
    in_payload.uop_exceptionVec_12                  = io_in_bits_uop_exceptionVec_12;
    in_payload.uop_exceptionVec_13                  = io_in_bits_uop_exceptionVec_13;
    in_payload.uop_exceptionVec_14                  = io_in_bits_uop_exceptionVec_14;
    in_payload.uop_exceptionVec_15                  = io_in_bits_uop_exceptionVec_15;
    in_payload.uop_exceptionVec_16                  = io_in_bits_uop_exceptionVec_16;
    in_payload.uop_exceptionVec_17                  = io_in_bits_uop_exceptionVec_17;
    in_payload.uop_exceptionVec_18                  = io_in_bits_uop_exceptionVec_18;
    in_payload.uop_exceptionVec_19                  = io_in_bits_uop_exceptionVec_19;
    in_payload.uop_exceptionVec_20                  = io_in_bits_uop_exceptionVec_20;
    in_payload.uop_exceptionVec_21                  = io_in_bits_uop_exceptionVec_21;
    in_payload.uop_exceptionVec_22                  = io_in_bits_uop_exceptionVec_22;
    in_payload.uop_exceptionVec_23                  = io_in_bits_uop_exceptionVec_23;
    in_payload.uop_trigger                          = io_in_bits_uop_trigger;
    in_payload.uop_rfWen                            = io_in_bits_uop_rfWen;
    in_payload.uop_flushPipe                        = io_in_bits_uop_flushPipe;
    in_payload.uop_pdest                            = io_in_bits_uop_pdest;
    in_payload.uop_robIdx_flag                      = io_in_bits_uop_robIdx_flag;
    in_payload.uop_robIdx_value                     = io_in_bits_uop_robIdx_value;
    in_payload.uop_debugInfo_eliminatedMove         = io_in_bits_uop_debugInfo_eliminatedMove;
    in_payload.uop_debugInfo_renameTime             = io_in_bits_uop_debugInfo_renameTime;
    in_payload.uop_debugInfo_dispatchTime           = io_in_bits_uop_debugInfo_dispatchTime;
    in_payload.uop_debugInfo_enqRsTime              = io_in_bits_uop_debugInfo_enqRsTime;
    in_payload.uop_debugInfo_selectTime             = io_in_bits_uop_debugInfo_selectTime;
    in_payload.uop_debugInfo_issueTime              = io_in_bits_uop_debugInfo_issueTime;
    in_payload.uop_debugInfo_writebackTime          = io_in_bits_uop_debugInfo_writebackTime;
    in_payload.uop_debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in_payload.uop_debugInfo_tlbFirstReqTime        = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in_payload.uop_debugInfo_tlbRespTime            = io_in_bits_uop_debugInfo_tlbRespTime;
    in_payload.uop_debug_seqNum_seqNum              = io_in_bits_uop_debug_seqNum_seqNum;
    in_payload.uop_debug_seqNum_uopIdx              = io_in_bits_uop_debug_seqNum_uopIdx;
    in_payload.uop_sqIdx_flag                       = io_in_bits_uop_sqIdx_flag;
    in_payload.uop_sqIdx_value                      = io_in_bits_uop_sqIdx_value;
    in_payload.data                                 = io_in_bits_data;
    in_payload.debug_isMMIO                         = io_in_bits_debug_isMMIO;
  end

  // 出口拆包：struct 成员 -> 端口（同名逐项）
  assign io_out_bits_uop_exceptionVec_0                   = out_payload.uop_exceptionVec_0;
  assign io_out_bits_uop_exceptionVec_1                   = out_payload.uop_exceptionVec_1;
  assign io_out_bits_uop_exceptionVec_2                   = out_payload.uop_exceptionVec_2;
  assign io_out_bits_uop_exceptionVec_3                   = out_payload.uop_exceptionVec_3;
  assign io_out_bits_uop_exceptionVec_4                   = out_payload.uop_exceptionVec_4;
  assign io_out_bits_uop_exceptionVec_5                   = out_payload.uop_exceptionVec_5;
  assign io_out_bits_uop_exceptionVec_6                   = out_payload.uop_exceptionVec_6;
  assign io_out_bits_uop_exceptionVec_7                   = out_payload.uop_exceptionVec_7;
  assign io_out_bits_uop_exceptionVec_8                   = out_payload.uop_exceptionVec_8;
  assign io_out_bits_uop_exceptionVec_9                   = out_payload.uop_exceptionVec_9;
  assign io_out_bits_uop_exceptionVec_10                  = out_payload.uop_exceptionVec_10;
  assign io_out_bits_uop_exceptionVec_11                  = out_payload.uop_exceptionVec_11;
  assign io_out_bits_uop_exceptionVec_12                  = out_payload.uop_exceptionVec_12;
  assign io_out_bits_uop_exceptionVec_13                  = out_payload.uop_exceptionVec_13;
  assign io_out_bits_uop_exceptionVec_14                  = out_payload.uop_exceptionVec_14;
  assign io_out_bits_uop_exceptionVec_15                  = out_payload.uop_exceptionVec_15;
  assign io_out_bits_uop_exceptionVec_16                  = out_payload.uop_exceptionVec_16;
  assign io_out_bits_uop_exceptionVec_17                  = out_payload.uop_exceptionVec_17;
  assign io_out_bits_uop_exceptionVec_18                  = out_payload.uop_exceptionVec_18;
  assign io_out_bits_uop_exceptionVec_19                  = out_payload.uop_exceptionVec_19;
  assign io_out_bits_uop_exceptionVec_20                  = out_payload.uop_exceptionVec_20;
  assign io_out_bits_uop_exceptionVec_21                  = out_payload.uop_exceptionVec_21;
  assign io_out_bits_uop_exceptionVec_22                  = out_payload.uop_exceptionVec_22;
  assign io_out_bits_uop_exceptionVec_23                  = out_payload.uop_exceptionVec_23;
  assign io_out_bits_uop_trigger                          = out_payload.uop_trigger;
  assign io_out_bits_uop_rfWen                            = out_payload.uop_rfWen;
  assign io_out_bits_uop_flushPipe                        = out_payload.uop_flushPipe;
  assign io_out_bits_uop_pdest                            = out_payload.uop_pdest;
  assign io_out_bits_uop_robIdx_flag                      = out_payload.uop_robIdx_flag;
  assign io_out_bits_uop_robIdx_value                     = out_payload.uop_robIdx_value;
  assign io_out_bits_uop_debugInfo_eliminatedMove         = out_payload.uop_debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime             = out_payload.uop_debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime           = out_payload.uop_debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime              = out_payload.uop_debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime             = out_payload.uop_debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime              = out_payload.uop_debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime          = out_payload.uop_debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out_payload.uop_debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime        = out_payload.uop_debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime            = out_payload.uop_debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum              = out_payload.uop_debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx              = out_payload.uop_debug_seqNum_uopIdx;
  assign io_out_bits_uop_sqIdx_flag                       = out_payload.uop_sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value                      = out_payload.uop_sqIdx_value;
  assign io_out_bits_data                                 = out_payload.data;
  assign io_out_bits_debug_isMMIO                         = out_payload.debug_isMMIO;

  // ---------------------------------------------------------------------------
  // elaborate 期位宽不变式。
  //
  // 本轮反复出事的形态是「逻辑全对、只有某个字段位宽停在旧基线」：随机激励未必
  // 打到高位，UT 照样 errors=0，要等 FM 才炸。这里把它提前到 time 0。
  // 判据：入口端口位宽之和 == 出口端口位宽之和 == PAYLOAD_W_G1 == $bits(payload_t)。
  // 任何一个端口或 struct 成员的位宽被改动，这四个数就不再相等（后两项由共享核
  // 里的 initial 负责）。「两处互相抵消的改动」逃得过位宽和，但逃不过
  // scripts/port_contract_lint.py（逐端口比 G1 golden）与 UT 的逐拍输出比对。
  // ---------------------------------------------------------------------------
  localparam int unsigned IN_PORT_BITS =
   $bits(io_in_bits_uop_exceptionVec_0) + $bits(io_in_bits_uop_exceptionVec_1) + $bits(io_in_bits_uop_exceptionVec_2) + $bits(io_in_bits_uop_exceptionVec_3) +
   $bits(io_in_bits_uop_exceptionVec_4) + $bits(io_in_bits_uop_exceptionVec_5) + $bits(io_in_bits_uop_exceptionVec_6) + $bits(io_in_bits_uop_exceptionVec_7) +
   $bits(io_in_bits_uop_exceptionVec_8) + $bits(io_in_bits_uop_exceptionVec_9) + $bits(io_in_bits_uop_exceptionVec_10) + $bits(io_in_bits_uop_exceptionVec_11) +
   $bits(io_in_bits_uop_exceptionVec_12) + $bits(io_in_bits_uop_exceptionVec_13) + $bits(io_in_bits_uop_exceptionVec_14) + $bits(io_in_bits_uop_exceptionVec_15) +
   $bits(io_in_bits_uop_exceptionVec_16) + $bits(io_in_bits_uop_exceptionVec_17) + $bits(io_in_bits_uop_exceptionVec_18) + $bits(io_in_bits_uop_exceptionVec_19) +
   $bits(io_in_bits_uop_exceptionVec_20) + $bits(io_in_bits_uop_exceptionVec_21) + $bits(io_in_bits_uop_exceptionVec_22) + $bits(io_in_bits_uop_exceptionVec_23) +
   $bits(io_in_bits_uop_trigger) + $bits(io_in_bits_uop_rfWen) + $bits(io_in_bits_uop_flushPipe) + $bits(io_in_bits_uop_pdest) +
   $bits(io_in_bits_uop_robIdx_flag) + $bits(io_in_bits_uop_robIdx_value) + $bits(io_in_bits_uop_debugInfo_eliminatedMove) + $bits(io_in_bits_uop_debugInfo_renameTime) +
   $bits(io_in_bits_uop_debugInfo_dispatchTime) + $bits(io_in_bits_uop_debugInfo_enqRsTime) + $bits(io_in_bits_uop_debugInfo_selectTime) + $bits(io_in_bits_uop_debugInfo_issueTime) +
   $bits(io_in_bits_uop_debugInfo_writebackTime) + $bits(io_in_bits_uop_debugInfo_runahead_checkpoint_id) + $bits(io_in_bits_uop_debugInfo_tlbFirstReqTime) + $bits(io_in_bits_uop_debugInfo_tlbRespTime) +
   $bits(io_in_bits_uop_debug_seqNum_seqNum) + $bits(io_in_bits_uop_debug_seqNum_uopIdx) + $bits(io_in_bits_uop_sqIdx_flag) + $bits(io_in_bits_uop_sqIdx_value) +
   $bits(io_in_bits_data) + $bits(io_in_bits_debug_isMMIO);
  localparam int unsigned OUT_PORT_BITS =
   $bits(io_out_bits_uop_exceptionVec_0) + $bits(io_out_bits_uop_exceptionVec_1) + $bits(io_out_bits_uop_exceptionVec_2) + $bits(io_out_bits_uop_exceptionVec_3) +
   $bits(io_out_bits_uop_exceptionVec_4) + $bits(io_out_bits_uop_exceptionVec_5) + $bits(io_out_bits_uop_exceptionVec_6) + $bits(io_out_bits_uop_exceptionVec_7) +
   $bits(io_out_bits_uop_exceptionVec_8) + $bits(io_out_bits_uop_exceptionVec_9) + $bits(io_out_bits_uop_exceptionVec_10) + $bits(io_out_bits_uop_exceptionVec_11) +
   $bits(io_out_bits_uop_exceptionVec_12) + $bits(io_out_bits_uop_exceptionVec_13) + $bits(io_out_bits_uop_exceptionVec_14) + $bits(io_out_bits_uop_exceptionVec_15) +
   $bits(io_out_bits_uop_exceptionVec_16) + $bits(io_out_bits_uop_exceptionVec_17) + $bits(io_out_bits_uop_exceptionVec_18) + $bits(io_out_bits_uop_exceptionVec_19) +
   $bits(io_out_bits_uop_exceptionVec_20) + $bits(io_out_bits_uop_exceptionVec_21) + $bits(io_out_bits_uop_exceptionVec_22) + $bits(io_out_bits_uop_exceptionVec_23) +
   $bits(io_out_bits_uop_trigger) + $bits(io_out_bits_uop_rfWen) + $bits(io_out_bits_uop_flushPipe) + $bits(io_out_bits_uop_pdest) +
   $bits(io_out_bits_uop_robIdx_flag) + $bits(io_out_bits_uop_robIdx_value) + $bits(io_out_bits_uop_debugInfo_eliminatedMove) + $bits(io_out_bits_uop_debugInfo_renameTime) +
   $bits(io_out_bits_uop_debugInfo_dispatchTime) + $bits(io_out_bits_uop_debugInfo_enqRsTime) + $bits(io_out_bits_uop_debugInfo_selectTime) + $bits(io_out_bits_uop_debugInfo_issueTime) +
   $bits(io_out_bits_uop_debugInfo_writebackTime) + $bits(io_out_bits_uop_debugInfo_runahead_checkpoint_id) + $bits(io_out_bits_uop_debugInfo_tlbFirstReqTime) + $bits(io_out_bits_uop_debugInfo_tlbRespTime) +
   $bits(io_out_bits_uop_debug_seqNum_seqNum) + $bits(io_out_bits_uop_debug_seqNum_uopIdx) + $bits(io_out_bits_uop_sqIdx_flag) + $bits(io_out_bits_uop_sqIdx_value) +
   $bits(io_out_bits_data) + $bits(io_out_bits_debug_isMMIO);

  initial begin
    if (IN_PORT_BITS != PAYLOAD_W_G1)
      $fatal(1, "NewPipelineConnectPipe_34: 入口端口位宽之和 %0d != G1 golden 的 %0d 位",
             IN_PORT_BITS, PAYLOAD_W_G1);
    if (OUT_PORT_BITS != PAYLOAD_W_G1)
      $fatal(1, "NewPipelineConnectPipe_34: 出口端口位宽之和 %0d != G1 golden 的 %0d 位",
             OUT_PORT_BITS, PAYLOAD_W_G1);
  end

  // 共享核：本文件不含任何流水/握手逻辑，全部在 xs_PipelineConnect 里。
  // 本变体 golden 无 io_isFlush（valid 次态没有冲刷项），故核的 io_isFlush 恒接 0。
  xs_PipelineConnect #(
    .DATA_WIDTH   ($bits(payload_t)),
    .PAYLOAD_W_G1 (PAYLOAD_W_G1)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_in_ready     (io_in_ready),
    .io_in_valid     (io_in_valid),
    .io_in_bits      (in_payload),
    .io_out_ready    (io_out_ready),
    .io_out_valid    (io_out_valid),
    .io_out_bits     (out_payload),
    .io_rightOutFire (io_rightOutFire),
    .io_isFlush      (1'b0)
  );

endmodule
