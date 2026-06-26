// =============================================================================
//  CLINT 类型/常量包 (clint_pkg)
// -----------------------------------------------------------------------------
//  CLINT (Core-Local Interruptor) 是 RISC-V 的核内中断控制器，挂在 TileLink
//  总线上，对外产生两类中断 + 提供 64 位实时计数器：
//    int_out_0 = msip (机器软件中断 MSIP / IPI)
//    int_out_1 = mtip (机器定时中断，= time >= mtimecmp)
//  寄存器映射 (相对基址，本实例 beatBytes=8、单 hart)：
//    0x0000  msip      (bit0 = ipi，软件写 1 触发软件中断)
//    0x4000  mtimecmp  (64 位定时比较值)
//    0xbff8  mtime     (64 位实时计数，rtcTick 每拍 +1)
//
//  golden 用 TLRegisterNode/regmap 综合出的扁平命名对照：
//    golden time_0 == 本核 mtime；golden pad == 本核 mtimecmp；golden ipi_0 == ipi
//
//  地址解码：总线给到本设备的是设备内 30 位字节地址 (address[29:0])，
//  region = address[15:14] 选大区，address[13:3] 在区内选 8 字节槽：
//    region 2'h0 + slot 0          -> msip
//    region 2'h1 + slot 0          -> mtimecmp
//    region 2'h2 + slot all-ones   -> mtime  (0xbff8 的 [13:3] 为 11 位全 1)
//  本实例 intStages=0，故中断输出为组合直出，无移位寄存器级。
// =============================================================================
package clint_pkg;
  // ---- 数据/地址位宽 (与本 CLINT 实例化端口一致) ----
  localparam int CLINT_TIME_BITS    = 64;  // mtime / mtimecmp 位宽
  localparam int CLINT_DATA_BITS    = 64;  // TileLink beat 数据位宽 (beatBytes=8)
  localparam int CLINT_MASK_BITS    = 8;   // 每字节一个写选通
  localparam int CLINT_ADDR_BITS    = 30;  // 设备内字节地址位宽
  localparam int CLINT_SOURCE_BITS  = 15;  // TileLink source id 位宽

  // ---- TileLink A 通道 opcode (只关心是否为读) ----
  localparam logic [3:0] TL_A_GET = 4'h4;  // Get = 读请求；其余视为写 (Put*)

  // ---- 地址区域编码 address[15:14] ----
  localparam logic [1:0] REGION_MSIP     = 2'h0;  // 0x0000 区
  localparam logic [1:0] REGION_TIMECMP  = 2'h1;  // 0x4000 区
  localparam logic [1:0] REGION_TIME     = 2'h2;  // 0x8000 区 (mtime 在 0xbff8)
endpackage
