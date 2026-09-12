// 自动生成：scripts/gen_imsicgateway.py —— 勿手改
// IMSICGateWay 双例化逐拍比对：golden IMSICGateWay vs 可读重写 IMSICGateWay_xs。
// 激励：随机驱动 msiio_vld_req / msiio_data；req 在 0/1 间随机翻转以产生
// 上升沿 (锁存) 与非上升沿 (清脉冲) 两类拍。两侧共享真实 3 级同步链。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 20) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic msiio_vld_req;
  logic [10:0] msiio_data;
  wire [7:0] g_msi_data_o;
  wire [7:0] i_msi_data_o;
  wire [6:0] g_msi_valid_o;
  wire [6:0] i_msi_valid_o;

  IMSICGateWay u_g (
    .clock(clock),
    .reset(reset),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data),
    .msi_data_o(g_msi_data_o),
    .msi_valid_o(g_msi_valid_o)
  );

  IMSICGateWay_xs u_i (
    .clock(clock),
    .reset(reset),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data),
    .msi_data_o(i_msi_data_o),
    .msi_valid_o(i_msi_valid_o)
  );

  task automatic drive_random_inputs();
    // req 大多保持、偶尔翻转，制造稀疏上升沿；data 全随机
    if ($urandom_range(0, 2) == 0) msiio_vld_req = ~msiio_vld_req;
    msiio_data = 11'($urandom);
  endtask

  task automatic check_outputs();
    `CHECK(msi_data_o)
    `CHECK(msi_valid_o)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    msiio_vld_req = '0;
    msiio_data = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("IMSICGateWay checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
