// =============================================================================
//  DebugModule —— 香山 V2R2 调试子系统顶层装配 (可读重写核 xs_DebugModule_core)
// -----------------------------------------------------------------------------
//  源自 rocket-chip 的 DebugModule (src/main/scala/devices/debug/Debug.scala),
//  在香山 SoC 里实例化为顶层 module DebugModule (golden 274 行)。本模块是
//  **纯装配 glue**, 自身只有「1 个同步寄存器 + 内部 DMI 连线」, 真正的调试功能
//  全在它例化的两个大子模块里:
//
//    1) TLDebugModule  debug —— 调试模块主体 (黑盒)
//         · 内含 DM 寄存器组 (dmcontrol/dmstatus/abstractcs/command/...)、抽象命令
//           执行、program buffer、system bus access (SBA) master、per-hart reset 控制;
//         · 对 CPU 暴露 TileLink slave 口 (tl_in): CPU 经此读写 DM 寄存器;
//         · 对外暴露 TileLink master 口 (sb2tlOpt_out): SBA 直接访存;
//         · 跨三个时钟域: io_tl_clock (TL/CPU 侧)、io_debug_clock (DM 内核)、
//           io_dmi_dmiClock (= JTAG TCK, DMI 侧)。
//
//    2) DebugTransportModuleJTAG  dtm —— 调试传输模块 (黑盒)
//         · 一个标准 JTAG TAP: 把外部 JTAG 引脚 (TCK/TMS/TDI/TDO) 上扫描进来的
//           DTM 指令 (IDCODE / DTMCS / DMI) 译成 DMI 请求, 收 DMI 应答再移位回 TDO;
//         · 全程运行在 TCK 时钟域。
//
//  ---------------------------------------------------------------------------
//  DMI (Debug Module Interface) —— 两子模块之间的内部桥:
//    dtm  --req-->  debug   (req: addr/data/op, 见 debug_pkg::dmi_op_e)
//    debug --resp-> dtm     (resp: data/resp,   见 debug_pkg::dmi_resp_e)
//  请求方 (dtm) 给 req_valid + 收 req_ready; 应答方 (debug) 给 resp_valid + 收
//  resp_ready。DMI 跨 TCK<->DM 时钟域的同步在 TLDebugModule 内部完成 (本层只连线)。
//
//  ---------------------------------------------------------------------------
//  本层唯一的时序逻辑 —— hartIsInReset 同步寄存器:
//    外部 reset 控制器报告「hart 当前是否处于复位」(io_resetCtrl_hartIsInReset_0),
//    DM 需要据此判断 hart reset 是否已生效。该信号来自被复位的 hart 时钟域, 进 DM
//    前先用 io_clock (TL 时钟) 打一拍做同步/对齐, 再送进 TLDebugModule 的
//    io_hartIsInReset_0。这是整个 DebugModule 自身仅有的一个寄存器。
//
//  ---------------------------------------------------------------------------
//  验证: golden 同名 DebugModule 例化本核 (端口透传)。两个子模块为 golden 黑盒,
//  UT 双例化时两侧共用真实子模块 (逐拍比对验证 glue 连线与同步寄存器正确),
//  FM 时两子模块两侧都黑盒 (聚焦本层 glue 等价, 同 IMSIC 模式)。
// =============================================================================
module xs_DebugModule_core
  import debug_pkg::*;
(
  // ===========================================================================
  //  (A) DM 作为 master 的 system bus access 口 (sb2tlOpt_out, TileLink-UL)
  //      DM 通过此口直接读写主存/外设 (SBA)。A=请求(出), D=应答(入)。
  // ===========================================================================
  input         auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready,
  output        auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid,
  output [3:0]  auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode,
  output [2:0]  auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size,
  output [48:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address,
  output [7:0]  auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask,
  output [63:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data,
  output        auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready,
  input         auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid,
  input  [3:0]  auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode,
  input  [1:0]  auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param,
  input  [2:0]  auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size,
  input         auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink,
  input         auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied,
  input  [63:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data,
  input         auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt,

  // ===========================================================================
  //  (B) DM 作为 slave 的 CPU 访问口 (tl_in, TileLink-UL)
  //      CPU 经此口读写 DM 寄存器 / program buffer。A=请求(入), D=应答(出)。
  // ===========================================================================
  output        auto_debug_dmInner_dmInner_tl_in_a_ready,
  input         auto_debug_dmInner_dmInner_tl_in_a_valid,
  input  [3:0]  auto_debug_dmInner_dmInner_tl_in_a_bits_opcode,
  input  [1:0]  auto_debug_dmInner_dmInner_tl_in_a_bits_size,
  input  [14:0] auto_debug_dmInner_dmInner_tl_in_a_bits_source,
  input  [29:0] auto_debug_dmInner_dmInner_tl_in_a_bits_address,
  input  [7:0]  auto_debug_dmInner_dmInner_tl_in_a_bits_mask,
  input  [63:0] auto_debug_dmInner_dmInner_tl_in_a_bits_data,
  input         auto_debug_dmInner_dmInner_tl_in_d_ready,
  output        auto_debug_dmInner_dmInner_tl_in_d_valid,
  output [3:0]  auto_debug_dmInner_dmInner_tl_in_d_bits_opcode,
  output [1:0]  auto_debug_dmInner_dmInner_tl_in_d_bits_size,
  output [14:0] auto_debug_dmInner_dmInner_tl_in_d_bits_source,
  output [63:0] auto_debug_dmInner_dmInner_tl_in_d_bits_data,

  // ===========================================================================
  //  (C) DM 输出: 调试中断 (dmOuter 把 haltreq 转成中断送 hart)
  // ===========================================================================
  output        auto_debug_dmOuter_dmOuter_int_out_0,

  // ===========================================================================
  //  (D) hart reset 控制接口 (与 SoC 复位控制器对接)
  // ===========================================================================
  output        io_resetCtrl_hartResetReq_0,   // DM 请求复位 hart (ndmreset/hartreset)
  input         io_resetCtrl_hartIsInReset_0,   // hart 当前是否在复位 (来自 hart 时钟域)

  // ===========================================================================
  //  (E) JTAG / 调试 IO (走 TCK 时钟域)
  // ===========================================================================
  input         io_debugIO_clock,               // DM 内核时钟 (io_debug_clock)
  input         io_debugIO_reset,               // DM 内核复位
  input         io_debugIO_systemjtag_jtag_TCK,  // JTAG 测试时钟 (= DMI 时钟)
  input         io_debugIO_systemjtag_jtag_TMS,  // JTAG 模式选择
  input         io_debugIO_systemjtag_jtag_TDI,  // JTAG 数据输入
  output        io_debugIO_systemjtag_jtag_TDO_data,    // JTAG 数据输出
  output        io_debugIO_systemjtag_jtag_TDO_driven,  // TDO 三态使能 (1=本器件驱动)
  input         io_debugIO_systemjtag_reset,            // JTAG/DMI 复位 (类 TRST)
  input  [10:0] io_debugIO_systemjtag_mfr_id,           // IDCODE: 厂商号
  input  [15:0] io_debugIO_systemjtag_part_number,      // IDCODE: 器件号
  input  [3:0]  io_debugIO_systemjtag_version,          // IDCODE: 版本号
  output        io_debugIO_ndreset,             // non-debug-module reset 请求 (全系统复位)
  output        io_debugIO_dmactive,            // DM 当前是否激活
  input         io_debugIO_dmactiveAck,         // dmactive 跨域确认

  // ===========================================================================
  //  (F) TL / CPU 侧时钟复位
  // ===========================================================================
  input         io_clock,
  input         io_reset
);

  // ===========================================================================
  //  hartIsInReset 同步寄存器 (本层唯一时序逻辑)
  // ---------------------------------------------------------------------------
  //  hart 的「在复位」状态来自 hart 时钟域, 进 DM 之前用 TL 时钟打一拍对齐,
  //  避免直接把跨域电平喂给 TLDebugModule 内部的 hart-reset 状态机。
  // ===========================================================================
  reg hartIsInReset_sync;
  always @(posedge io_clock)
    hartIsInReset_sync <= io_resetCtrl_hartIsInReset_0;

  // ===========================================================================
  //  内部 DMI 总线 (dtm <-> debug)
  // ---------------------------------------------------------------------------
  //  dtm 是请求发起方 (req), debug 是应答方 (resp)。命名按数据流向, 不照抄
  //  golden 的 _dtm_io_* / _debug_io_* 临时网名。
  // ===========================================================================
  // dtm -> debug: DMI 请求
  wire                       dmi_req_valid;   // DTM 发出请求
  wire [DMI_ADDR_WIDTH-1:0]  dmi_req_addr;    // 目标 DM 寄存器地址
  wire [DMI_DATA_WIDTH-1:0]  dmi_req_data;    // 写数据 (读时无意义)
  wire [DMI_OP_WIDTH-1:0]    dmi_req_op;      // 操作码: NOP/READ/WRITE
  wire                       dmi_resp_ready;  // DTM 可收应答
  // debug -> dtm: DMI 握手与应答
  wire                       dmi_req_ready;   // DM 可收请求
  wire                       dmi_resp_valid;  // DM 给出应答
  wire [DMI_DATA_WIDTH-1:0]  dmi_resp_data;   // 读回数据
  wire [DMI_OP_WIDTH-1:0]    dmi_resp_resp;   // 应答状态 (SUCCESS/FAILED/BUSY)

  // ===========================================================================
  //  调试模块主体 (黑盒): TLDebugModule
  // ---------------------------------------------------------------------------
  //  端口连接说明:
  //    · io_tl_clock/reset  <- io_clock/io_reset            (CPU/TL 侧)
  //    · io_debug_clock/reset<- io_debugIO_clock/reset      (DM 内核侧)
  //    · io_dmi_dmiClock/Reset<- TCK / systemjtag_reset     (DMI 侧, 与 dtm 同域)
  //    · io_hartIsInReset_0  <- 上面打拍后的 hartIsInReset_sync
  // ===========================================================================
  TLDebugModule debug (
    .auto_dmInner_dmInner_sb2tlOpt_out_a_ready
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready),
    .auto_dmInner_dmInner_sb2tlOpt_out_a_valid
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid),
    .auto_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode),
    .auto_dmInner_dmInner_sb2tlOpt_out_a_bits_size
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size),
    .auto_dmInner_dmInner_sb2tlOpt_out_a_bits_address
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address),
    .auto_dmInner_dmInner_sb2tlOpt_out_a_bits_mask
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask),
    .auto_dmInner_dmInner_sb2tlOpt_out_a_bits_data
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_ready
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_valid
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_param
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_size
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_sink
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_denied
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_data
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data),
    .auto_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt
      (auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt),
    .auto_dmInner_dmInner_tl_in_a_ready
      (auto_debug_dmInner_dmInner_tl_in_a_ready),
    .auto_dmInner_dmInner_tl_in_a_valid
      (auto_debug_dmInner_dmInner_tl_in_a_valid),
    .auto_dmInner_dmInner_tl_in_a_bits_opcode
      (auto_debug_dmInner_dmInner_tl_in_a_bits_opcode),
    .auto_dmInner_dmInner_tl_in_a_bits_size
      (auto_debug_dmInner_dmInner_tl_in_a_bits_size),
    .auto_dmInner_dmInner_tl_in_a_bits_source
      (auto_debug_dmInner_dmInner_tl_in_a_bits_source),
    .auto_dmInner_dmInner_tl_in_a_bits_address
      (auto_debug_dmInner_dmInner_tl_in_a_bits_address),
    .auto_dmInner_dmInner_tl_in_a_bits_mask
      (auto_debug_dmInner_dmInner_tl_in_a_bits_mask),
    .auto_dmInner_dmInner_tl_in_a_bits_data
      (auto_debug_dmInner_dmInner_tl_in_a_bits_data),
    .auto_dmInner_dmInner_tl_in_d_ready
      (auto_debug_dmInner_dmInner_tl_in_d_ready),
    .auto_dmInner_dmInner_tl_in_d_valid
      (auto_debug_dmInner_dmInner_tl_in_d_valid),
    .auto_dmInner_dmInner_tl_in_d_bits_opcode
      (auto_debug_dmInner_dmInner_tl_in_d_bits_opcode),
    .auto_dmInner_dmInner_tl_in_d_bits_size
      (auto_debug_dmInner_dmInner_tl_in_d_bits_size),
    .auto_dmInner_dmInner_tl_in_d_bits_source
      (auto_debug_dmInner_dmInner_tl_in_d_bits_source),
    .auto_dmInner_dmInner_tl_in_d_bits_data
      (auto_debug_dmInner_dmInner_tl_in_d_bits_data),
    .auto_dmOuter_dmOuter_int_out_0
      (auto_debug_dmOuter_dmOuter_int_out_0),
    .io_debug_clock        (io_debugIO_clock),
    .io_debug_reset        (io_debugIO_reset),
    .io_tl_clock           (io_clock),
    .io_tl_reset           (io_reset),
    .io_ctrl_ndreset       (io_debugIO_ndreset),
    .io_ctrl_dmactive      (io_debugIO_dmactive),
    .io_ctrl_dmactiveAck   (io_debugIO_dmactiveAck),
    // DMI (debug 是应答方): 收 dtm 的 req, 回 resp
    .io_dmi_dmi_req_ready  (dmi_req_ready),
    .io_dmi_dmi_req_valid  (dmi_req_valid),
    .io_dmi_dmi_req_bits_addr (dmi_req_addr),
    .io_dmi_dmi_req_bits_data (dmi_req_data),
    .io_dmi_dmi_req_bits_op   (dmi_req_op),
    .io_dmi_dmi_resp_ready (dmi_resp_ready),
    .io_dmi_dmi_resp_valid (dmi_resp_valid),
    .io_dmi_dmi_resp_bits_data (dmi_resp_data),
    .io_dmi_dmi_resp_bits_resp (dmi_resp_resp),
    .io_dmi_dmiClock       (io_debugIO_systemjtag_jtag_TCK),
    .io_dmi_dmiReset       (io_debugIO_systemjtag_reset),
    .io_hartIsInReset_0    (hartIsInReset_sync),
    .io_hartResetReq_0     (io_resetCtrl_hartResetReq_0)
  );

  // ===========================================================================
  //  调试传输模块 / JTAG TAP (黑盒): DebugTransportModuleJTAG
  // ---------------------------------------------------------------------------
  //  全程 TCK 域。把 JTAG 扫描进来的 DTM 指令译成 DMI 请求 (req 方), 收 DMI 应答
  //  (resp), IDCODE 由 mfr_id/part_number/version 三段拼成。
  // ===========================================================================
  DebugTransportModuleJTAG dtm (
    .io_jtag_clock         (io_debugIO_systemjtag_jtag_TCK),
    .io_jtag_reset         (io_debugIO_systemjtag_reset),
    // DMI (dtm 是请求方): 发 req, 收 resp
    .io_dmi_req_ready      (dmi_req_ready),
    .io_dmi_req_valid      (dmi_req_valid),
    .io_dmi_req_bits_addr  (dmi_req_addr),
    .io_dmi_req_bits_data  (dmi_req_data),
    .io_dmi_req_bits_op    (dmi_req_op),
    .io_dmi_resp_ready     (dmi_resp_ready),
    .io_dmi_resp_valid     (dmi_resp_valid),
    .io_dmi_resp_bits_data (dmi_resp_data),
    .io_dmi_resp_bits_resp (dmi_resp_resp),
    .io_jtag_TMS           (io_debugIO_systemjtag_jtag_TMS),
    .io_jtag_TDI           (io_debugIO_systemjtag_jtag_TDI),
    .io_jtag_TDO_data      (io_debugIO_systemjtag_jtag_TDO_data),
    .io_jtag_TDO_driven    (io_debugIO_systemjtag_jtag_TDO_driven),
    .io_jtag_mfr_id        (io_debugIO_systemjtag_mfr_id),
    .io_jtag_part_number   (io_debugIO_systemjtag_part_number),
    .io_jtag_version       (io_debugIO_systemjtag_version)
  );

endmodule
