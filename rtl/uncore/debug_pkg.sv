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
