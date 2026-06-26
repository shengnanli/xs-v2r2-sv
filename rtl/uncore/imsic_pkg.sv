// =============================================================================
//  IMSIC 类型/常量包 (imsic_pkg)
// -----------------------------------------------------------------------------
//  IMSIC (Incoming MSI Controller) 是 RISC-V AIA 架构里接收 MSI(消息中断)的
//  核内中断文件控制器。本包目前服务于 IMSICGateWay —— IMSIC 的 MSI 入口握手块。
//
//  IMSICGateWay 语义 (源自 ChiselAIA src/main/scala/IMSIC.scala, class IMSICGateWay)：
//    上游 (axireg) 通过 msiio 总线投递一条 MSI：
//      msiio_vld_req       : 请求有效 (异步，先经 3 级同步器打入本时钟域)
//      msiio_data[10:0]    : MSI 信息 = {目标中断文件号[10:8], 中断源号[7:0]}
//    本块在"同步后请求"的上升沿 (req & ~ack) 锁存：
//      msi_data_catch      : 锁存中断源号 msiio_data[7:0]
//      msi_intf_valids     : 把目标文件号 one-hot 展开 (1<<msiio_data[10:8])，
//                            取低 intFilesNum(=7) 位，作为各中断文件的写选通脉冲
//    非上升沿拍 msi_intf_valids 清 0 (单拍脉冲)。msi_vld_ack_cpu 跟随同步后请求，
//    用于上升沿检测 (Chisel 里还驱动 msiio.vld_ack，但该输出被 firtool 裁剪掉)。
//
//  本实例参数 (对照 golden IMSICGateWay.sv 端口)：
//    imsicIntSrcWidth = 8   (msi_data_o / 中断源号位宽，msiio_data[7:0])
//    intFilesNum      = 7   (msi_valid_o 位宽 = 中断文件数 m/s/vs..)
//    INTP_FILE_WIDTH  = 3   (文件号位宽，msiio_data[10:8])
//    MSI_INFO_WIDTH   = 11  (msiio_data 总位宽 = 8 + 3)
//
//  子模块：MSI 请求经一条 3 级异步复位同步链 (AsyncResetSynchronizerShiftReg_
//  w1_d3_i0) 进入本时钟域，本核按名例化该链 (UT 编入真实链，FM 视作黑盒)。
// =============================================================================
package imsic_pkg;
  localparam int IMSIC_INT_SRC_WIDTH = 8;   // 中断源号位宽 (msi_data_o)
  localparam int IMSIC_INT_FILES_NUM = 7;   // 中断文件数 (msi_valid_o)
  localparam int IMSIC_FILE_SEL_LSB  = 8;   // 文件号在 msiio_data 中的起始位
  localparam int IMSIC_FILE_SEL_MSB  = 10;  // 文件号在 msiio_data 中的结束位
  localparam int IMSIC_MSI_INFO_WIDTH = 11; // msiio_data 位宽 = 源号 + 文件号
endpackage
