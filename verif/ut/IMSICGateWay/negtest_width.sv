// negtest_width —— xs_IMSICGateWay_core 宽度等式自检的**必失败负测**。
//
// 目的：证明核里那几条宽度等式确实有牙齿。本 tb 故意把源头参数写回 G0 旧值
// （geilen = 5 ⇒ intFilesNum=7 ⇒ INTP_FILE_WIDTH=3 ⇒ MSI_INFO_WIDTH=11），
// 而"从 golden 现读的常量"（msiio_data 12 位 / msi_valid_o 9 位 / one-hot 移位
// 16 位）保持不动 —— 等式立刻不成立，核必须 $fatal。
//
// 判据（见 Makefile 的 negtest 目标）：本 tb **必须** 以非零退出码结束，且日志里
// 出现 "xs_IMSICGateWay_core:" 的宽度报错。如果它跑到 "NEGTEST ESCAPED" 那一行，
// 说明自检形同虚设，负测判失败。
`timescale 1ns/1ps
module tb;
  bit clock = 0;
  bit reset = 1;
  always #5 clock = ~clock;

  // G0 旧参数下的端口宽度：MSI_INFO_WIDTH = 8+3 = 11，intFilesNum = 7
  logic        msiio_vld_req = 1'b0;
  logic [10:0] msiio_data    = '0;
  wire         msiio_vld_ack;
  wire [7:0]   msi_data_o;
  wire [6:0]   msi_valid_o;

  xs_IMSICGateWay_core #(.GEILEN(5)) u_bad (
    .clock         (clock),
    .reset         (reset),
    .msiio_vld_req (msiio_vld_req),
    .msiio_data    (msiio_data),
    .msiio_vld_ack (msiio_vld_ack),
    .msi_data_o    (msi_data_o),
    .msi_valid_o   (msi_valid_o)
  );

  initial begin
    #100;
    $display("NEGTEST ESCAPED: 参数写回 G0 旧值(geilen=5) 却没有触发宽度自检 $fatal");
    $fatal(0);  // 退出码 0 —— 让 Makefile 的负测判据把"逃逸"判成失败
  end
endmodule
