// =============================================================================
//  debug_pkg —— RISC-V 调试子系统 (Debug Module) 常量与协议类型
// -----------------------------------------------------------------------------
//  供 xs_DebugModule_core 使用。DebugModule 本体是「纯装配 glue」: 它把
//  TLDebugModule (调试模块主体, 含 DM 寄存器 / 抽象命令 / system bus access /
//  hart reset 控制) 与 DebugTransportModuleJTAG (DTM, 把 JTAG TAP 译成 DMI 事务)
//  拼在一起, 中间用 DMI (Debug Module Interface) 总线相连。
//
//  本包只收纳两条总线的「位宽」与「操作码枚举」, 让 glue 里的内部连线自带语义,
//  不掺任何功能逻辑 (功能都在被黑盒的两个子模块内)。
// =============================================================================
package debug_pkg;

  // ---------------------------------------------------------------------------
  //  DMI (Debug Module Interface) —— DTM 与 DM 之间的内部请求/应答总线。
  //  RISC-V External Debug Support 规定: DMI 请求 = {address, data, op},
  //  应答 = {data, op(此处复用为 resp 状态码)}。
  //  本实现 DM 地址空间 7 位 (128 个 DMI 寄存器), 数据 32 位。
  // ---------------------------------------------------------------------------
  localparam int DMI_ADDR_WIDTH = 7;    // DMI 寄存器地址宽 (abstract/dmcontrol/... 选址)
  localparam int DMI_DATA_WIDTH = 32;   // DMI 数据宽 (每个 DM 寄存器 32 位)
  localparam int DMI_OP_WIDTH   = 2;    // 请求 op / 应答 resp 均为 2 位

  // DMI 请求操作码 (req.op): 见调试规范 dtm 的 dmi 寄存器定义。
  typedef enum logic [DMI_OP_WIDTH-1:0] {
    DMI_OP_NOP   = 2'd0,  // 空操作 (仅用于读回上一次应答)
    DMI_OP_READ  = 2'd1,  // 读 DM 寄存器
    DMI_OP_WRITE = 2'd2   // 写 DM 寄存器
  } dmi_op_e;

  // DMI 应答状态码 (resp.resp): DTM 据此决定是否回 sticky error / busy。
  typedef enum logic [DMI_OP_WIDTH-1:0] {
    DMI_RESP_SUCCESS = 2'd0,  // 成功
    DMI_RESP_FAILED  = 2'd2,  // 失败 (访问非法地址等)
    DMI_RESP_BUSY    = 2'd3   // 忙 (上一次访问尚未完成)
  } dmi_resp_e;

  // ---------------------------------------------------------------------------
  //  JTAG IDCODE 三段 (由顶层常量送入 DTM, 拼成 32 位 IDCODE 寄存器):
  //    {version[3:0], part_number[15:0], mfr_id[10:0], 1'b1}
  // ---------------------------------------------------------------------------
  localparam int JTAG_MFR_ID_WIDTH      = 11;  // JEDEC 厂商号
  localparam int JTAG_PART_NUMBER_WIDTH = 16;  // 器件号
  localparam int JTAG_VERSION_WIDTH     = 4;   // 版本号

  // ---------------------------------------------------------------------------
  //  DM 对外两条 TileLink 总线的载荷位宽 (仅用于内部连线声明的自文档化):
  //    sb2tlOpt : DM 作为 master 发起的 system bus access (SBA) -> 主存/外设;
  //    tl_in    : DM 作为 slave 被 CPU 访问 (CPU 通过此口读写 DM 寄存器 / program buffer)。
  // ---------------------------------------------------------------------------
  localparam int SB_ADDR_WIDTH   = 49;  // SBA A 通道地址宽 (物理地址空间)
  localparam int SB_DATA_WIDTH   = 64;  // SBA 数据宽
  localparam int TLIN_SRC_WIDTH  = 15;  // slave 口 source id 宽
  localparam int TLIN_ADDR_WIDTH = 30;  // slave 口地址宽 (DM 寄存器映射窗口)

endpackage

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

// 自动生成：xs-v2r2-sv/scripts/gen_debugmodule.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module DebugModule(
  input auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready,
  output auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid,
  output [3:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode,
  output [2:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size,
  output [48:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address,
  output [7:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask,
  output [63:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data,
  output auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready,
  input auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid,
  input [3:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode,
  input [1:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param,
  input [2:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size,
  input auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink,
  input auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied,
  input [63:0] auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data,
  input auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt,
  output auto_debug_dmInner_dmInner_tl_in_a_ready,
  input auto_debug_dmInner_dmInner_tl_in_a_valid,
  input [3:0] auto_debug_dmInner_dmInner_tl_in_a_bits_opcode,
  input [1:0] auto_debug_dmInner_dmInner_tl_in_a_bits_size,
  input [14:0] auto_debug_dmInner_dmInner_tl_in_a_bits_source,
  input [29:0] auto_debug_dmInner_dmInner_tl_in_a_bits_address,
  input [7:0] auto_debug_dmInner_dmInner_tl_in_a_bits_mask,
  input [63:0] auto_debug_dmInner_dmInner_tl_in_a_bits_data,
  input auto_debug_dmInner_dmInner_tl_in_d_ready,
  output auto_debug_dmInner_dmInner_tl_in_d_valid,
  output [3:0] auto_debug_dmInner_dmInner_tl_in_d_bits_opcode,
  output [1:0] auto_debug_dmInner_dmInner_tl_in_d_bits_size,
  output [14:0] auto_debug_dmInner_dmInner_tl_in_d_bits_source,
  output [63:0] auto_debug_dmInner_dmInner_tl_in_d_bits_data,
  output auto_debug_dmOuter_dmOuter_int_out_0,
  output io_resetCtrl_hartResetReq_0,
  input io_resetCtrl_hartIsInReset_0,
  input io_debugIO_clock,
  input io_debugIO_reset,
  input io_debugIO_systemjtag_jtag_TCK,
  input io_debugIO_systemjtag_jtag_TMS,
  input io_debugIO_systemjtag_jtag_TDI,
  output io_debugIO_systemjtag_jtag_TDO_data,
  output io_debugIO_systemjtag_jtag_TDO_driven,
  input io_debugIO_systemjtag_reset,
  input [10:0] io_debugIO_systemjtag_mfr_id,
  input [15:0] io_debugIO_systemjtag_part_number,
  input [3:0] io_debugIO_systemjtag_version,
  output io_debugIO_ndreset,
  output io_debugIO_dmactive,
  input io_debugIO_dmactiveAck,
  input io_clock,
  input io_reset
);
  xs_DebugModule_core u_core (
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_ready),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_valid),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_opcode),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_size),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_address),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_mask),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data(auto_debug_dmInner_dmInner_sb2tlOpt_out_a_bits_data),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_ready),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_valid),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_opcode),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_param),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_size),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_sink),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_denied),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_data),
    .auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt(auto_debug_dmInner_dmInner_sb2tlOpt_out_d_bits_corrupt),
    .auto_debug_dmInner_dmInner_tl_in_a_ready(auto_debug_dmInner_dmInner_tl_in_a_ready),
    .auto_debug_dmInner_dmInner_tl_in_a_valid(auto_debug_dmInner_dmInner_tl_in_a_valid),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_opcode(auto_debug_dmInner_dmInner_tl_in_a_bits_opcode),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_size(auto_debug_dmInner_dmInner_tl_in_a_bits_size),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_source(auto_debug_dmInner_dmInner_tl_in_a_bits_source),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_address(auto_debug_dmInner_dmInner_tl_in_a_bits_address),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_mask(auto_debug_dmInner_dmInner_tl_in_a_bits_mask),
    .auto_debug_dmInner_dmInner_tl_in_a_bits_data(auto_debug_dmInner_dmInner_tl_in_a_bits_data),
    .auto_debug_dmInner_dmInner_tl_in_d_ready(auto_debug_dmInner_dmInner_tl_in_d_ready),
    .auto_debug_dmInner_dmInner_tl_in_d_valid(auto_debug_dmInner_dmInner_tl_in_d_valid),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_opcode(auto_debug_dmInner_dmInner_tl_in_d_bits_opcode),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_size(auto_debug_dmInner_dmInner_tl_in_d_bits_size),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_source(auto_debug_dmInner_dmInner_tl_in_d_bits_source),
    .auto_debug_dmInner_dmInner_tl_in_d_bits_data(auto_debug_dmInner_dmInner_tl_in_d_bits_data),
    .auto_debug_dmOuter_dmOuter_int_out_0(auto_debug_dmOuter_dmOuter_int_out_0),
    .io_resetCtrl_hartResetReq_0(io_resetCtrl_hartResetReq_0),
    .io_resetCtrl_hartIsInReset_0(io_resetCtrl_hartIsInReset_0),
    .io_debugIO_clock(io_debugIO_clock),
    .io_debugIO_reset(io_debugIO_reset),
    .io_debugIO_systemjtag_jtag_TCK(io_debugIO_systemjtag_jtag_TCK),
    .io_debugIO_systemjtag_jtag_TMS(io_debugIO_systemjtag_jtag_TMS),
    .io_debugIO_systemjtag_jtag_TDI(io_debugIO_systemjtag_jtag_TDI),
    .io_debugIO_systemjtag_jtag_TDO_data(io_debugIO_systemjtag_jtag_TDO_data),
    .io_debugIO_systemjtag_jtag_TDO_driven(io_debugIO_systemjtag_jtag_TDO_driven),
    .io_debugIO_systemjtag_reset(io_debugIO_systemjtag_reset),
    .io_debugIO_systemjtag_mfr_id(io_debugIO_systemjtag_mfr_id),
    .io_debugIO_systemjtag_part_number(io_debugIO_systemjtag_part_number),
    .io_debugIO_systemjtag_version(io_debugIO_systemjtag_version),
    .io_debugIO_ndreset(io_debugIO_ndreset),
    .io_debugIO_dmactive(io_debugIO_dmactive),
    .io_debugIO_dmactiveAck(io_debugIO_dmactiveAck),
    .io_clock(io_clock),
    .io_reset(io_reset)
  );
endmodule
