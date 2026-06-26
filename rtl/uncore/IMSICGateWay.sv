// =============================================================================
//  IMSICGateWay —— IMSIC 的 MSI 入口握手块 (可读重写核 xs_IMSICGateWay_core)
// -----------------------------------------------------------------------------
//  功能 (源自 ChiselAIA src/main/scala/IMSIC.scala，class IMSICGateWay)：
//    接收上游投递的一条 MSI(消息中断)，在请求上升沿锁存中断源号、并把目标中断
//    文件号 one-hot 展开成单拍写选通。详见 imsic_pkg.sv 注释。
//
//  数据通路：
//    1) 请求 msiio_vld_req 异步进入，先过 3 级异步复位同步链 → req_synced；
//    2) msi_vld_ack_cpu 寄存器跟随 req_synced(打一拍)，二者相与求上升沿
//         vld_rise = req_synced & ~msi_vld_ack_cpu；
//    3) 上升沿拍：msi_data_catch <= msiio_data[7:0]（锁存源号）；
//                 msi_intf_valids <= (1<<msiio_data[10:8]) 的低 7 位（one-hot 选通）；
//       非上升沿拍：msi_intf_valids <= 0（单拍脉冲，源号保持）。
//
//  与 golden 对照：msi_vld_ack_cpu/msi_data_catch/msi_intf_valids 三个寄存器
//  语义、复位值、时序逐一对应；one-hot 展开取 8 位左移结果的低 7 位。
//  3 级同步链按名例化 golden 子模块 AsyncResetSynchronizerShiftReg_w1_d3_i0
//  (UT 编入真实链，FM 当黑盒)。
// =============================================================================
module xs_IMSICGateWay_core
  import imsic_pkg::*;
(
  input  logic                            clock,
  input  logic                            reset,

  // 上游 MSI 投递总线
  input  logic                            msiio_vld_req,  // 请求有效 (异步)
  input  logic [IMSIC_MSI_INFO_WIDTH-1:0] msiio_data,     // {文件号[10:8], 源号[7:0]}

  // 输出
  output logic [IMSIC_INT_SRC_WIDTH-1:0]  msi_data_o,     // 锁存的中断源号
  output logic [IMSIC_INT_FILES_NUM-1:0]  msi_valid_o     // 各中断文件单拍写选通
);

  // ===========================================================================
  //  3 级异步复位同步链 (跨时钟域)：按名例化 golden 子模块，保持黑盒
  // ===========================================================================
  logic req_synced;  // golden: _msi_vld_req_cpu_chain_io_q
  AsyncResetSynchronizerShiftReg_w1_d3_i0 msi_vld_req_cpu_chain (
    .clock (clock),
    .reset (reset),
    .io_d  (msiio_vld_req),
    .io_q  (req_synced)
  );

  // ===========================================================================
  //  状态寄存器
  // ===========================================================================
  logic                            msi_vld_ack_cpu;  // 同步后请求打一拍 (用于沿检测)
  logic [IMSIC_INT_SRC_WIDTH-1:0]  msi_data_catch;   // 锁存的中断源号
  logic [IMSIC_INT_FILES_NUM-1:0]  msi_intf_valids;  // one-hot 写选通脉冲

  // 同步后请求的上升沿：本拍高、上一拍 ack 低
  wire vld_rise = req_synced & ~msi_vld_ack_cpu;

  // 目标文件号 one-hot 展开：1 左移 msiio_data[10:8]，取低 IMSIC_INT_FILES_NUM 位。
  // 左移结果用 8 位 (与 golden 一致：1 个文件号最大值 7 → 1<<7 需 8 位)。
  wire [IMSIC_INT_SRC_WIDTH-1:0] onehot_full =
    IMSIC_INT_SRC_WIDTH'(8'h1 << msiio_data[IMSIC_FILE_SEL_MSB:IMSIC_FILE_SEL_LSB]);

  // ===========================================================================
  //  时序 (异步复位，与 golden posedge reset 一致)
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      msi_vld_ack_cpu <= 1'b0;
      msi_data_catch  <= '0;
      msi_intf_valids <= '0;
    end else begin
      msi_vld_ack_cpu <= req_synced;                  // 跟随同步后请求
      if (vld_rise)
        msi_data_catch <= msiio_data[IMSIC_INT_SRC_WIDTH-1:0];
      // 上升沿拍输出 one-hot 选通，否则清 0 (单拍脉冲)
      msi_intf_valids <= vld_rise ? onehot_full[IMSIC_INT_FILES_NUM-1:0]
                                  : {IMSIC_INT_FILES_NUM{1'b0}};
    end
  end

  // ===========================================================================
  //  输出
  // ===========================================================================
  assign msi_data_o  = msi_data_catch;
  assign msi_valid_o = msi_intf_valids;

endmodule
