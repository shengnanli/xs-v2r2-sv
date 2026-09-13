// IMSICGateWay 双例化逐拍比对：golden IMSICGateWay vs 可读重写 IMSICGateWay_xs。
//
// 激励：随机驱动 msiio_vld_req / msiio_data；req 在 0/1 间随机翻转以产生
// 上升沿 (锁存) 与非上升沿 (清脉冲) 两类拍。两侧共享真实 3 级同步链。
//
// ★ 覆盖闸 (本轮事故形态的对策) ★
// G0->G1 这一轮 IMSICGateWay 变的是 geilen 5→7，推出 msiio_data 11→12 位、
// msi_valid_o 7→9 位。位宽写回旧值时逻辑一行不错，只驱动低位的 tb 照样
// errors=0 —— 只有 FM 才炸。所以本 tb 在收尾处强制要求：
//   · 文件号字段 msiio_data[11:8] 的每一位都被置过 1（含最高位 bit11）；
//   · 锁存拍里文件号 >= 8 的次数非零（加宽出来的那一位真的走过数据通路）；
//   · golden msi_valid_o 的第 8 位（新增的最高位）真的被观测到 1；
//   · 新增端口 msiio_vld_ack 的 0/1 两态都被观测到。
// 任一为 0 判 COVERAGE HOLE → TEST FAILED，不允许"没打到就算过"。
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

  // 覆盖计数
  int unsigned latch_cnt      = 0;  // 观测到 msi_valid_o 非零的拍数（= one-hot 选通拍）
  int unsigned filesel_ge8    = 0;  // 驱动的文件号 >= 8（即 msiio_data[11]=1）的拍数
  logic [3:0]  filesel_or     = '0; // 文件号字段各位的并集
  logic [11:0] data_or        = '0; // msiio_data 各位的并集
  logic [8:0]  valid_or       = '0; // golden msi_valid_o 各位的并集（含新增 bit8）
  int unsigned valid_bit8_cnt = 0;  // golden msi_valid_o[8] 命中次数
  int unsigned ack_hi         = 0;  // msiio_vld_ack 观测到 1 的拍数
  int unsigned ack_lo         = 0;  // msiio_vld_ack 观测到 0 的拍数

  logic msiio_vld_req;
  logic [11:0] msiio_data;
  wire g_msiio_vld_ack;
  wire i_msiio_vld_ack;
  wire [7:0] g_msi_data_o;
  wire [7:0] i_msi_data_o;
  wire [8:0] g_msi_valid_o;
  wire [8:0] i_msi_valid_o;

  IMSICGateWay u_g (
    .clock(clock),
    .reset(reset),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data),
    .msiio_vld_ack(g_msiio_vld_ack),
    .msi_data_o(g_msi_data_o),
    .msi_valid_o(g_msi_valid_o)
  );

  IMSICGateWay_xs u_i (
    .clock(clock),
    .reset(reset),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data),
    .msiio_vld_ack(i_msiio_vld_ack),
    .msi_data_o(i_msi_data_o),
    .msi_valid_o(i_msi_valid_o)
  );

  task automatic drive_random_inputs();
    // req 大多保持、偶尔翻转，制造稀疏上升沿；data 全随机（12 位，含新增的 bit11）
    if ($urandom_range(0, 2) == 0) msiio_vld_req = ~msiio_vld_req;
    msiio_data = 12'($urandom);
    // 偶尔把文件号钉在合法范围外/边界上，压一压 one-hot 截断分支
    if ($urandom_range(0, 15) == 0) msiio_data[11:8] = 4'($urandom_range(8, 15));
  endtask

  task automatic check_outputs();
    `CHECK(msiio_vld_ack)
    `CHECK(msi_data_o)
    `CHECK(msi_valid_o)
  endtask

  // 覆盖统计：在 posedge 后的稳定点采样激励与 golden 输出。
  task automatic sample_coverage();
    data_or    |= msiio_data;
    filesel_or |= msiio_data[11:8];
    if (msiio_data[11:8] >= 4'd8) filesel_ge8++;
    if (!$isunknown(g_msi_valid_o)) begin
      valid_or |= g_msi_valid_o;
      if (|g_msi_valid_o) latch_cnt++;
      if (g_msi_valid_o[8]) valid_bit8_cnt++;
    end
    if (!$isunknown(g_msiio_vld_ack)) begin
      if (g_msiio_vld_ack) ack_hi++; else ack_lo++;
    end
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
      sample_coverage();
    end
    $display("IMSICGateWay checks=%0d errors=%0d", checks, errors);
    $display("IMSICGateWay coverage: latch=%0d filesel_ge8=%0d filesel_or=%0h data_or=%0h | valid_or=%0h valid_bit8=%0d | ack_hi=%0d ack_lo=%0d",
             latch_cnt, filesel_ge8, filesel_or, data_or, valid_or, valid_bit8_cnt, ack_hi, ack_lo);
    if (filesel_ge8 == 0 || !(&filesel_or)) begin
      $display("COVERAGE HOLE: msiio_data[11:8] 未取全（ge8=%0d or=%0h，期望 4 位全 1）—— 加宽出来的高位没被激励打到",
               filesel_ge8, filesel_or);
      $display("TEST FAILED");
      $fatal(1);
    end
    if (!(&data_or)) begin
      $display("COVERAGE HOLE: msiio_data 有位从未置 1（or=%0h，期望 12 位全 1）", data_or);
      $display("TEST FAILED");
      $fatal(1);
    end
    if (valid_bit8_cnt == 0 || !(&valid_or)) begin
      $display("COVERAGE HOLE: msi_valid_o 未取全（bit8=%0d or=%0h，期望 9 位全 1）—— 新增的最高位没被观测到",
               valid_bit8_cnt, valid_or);
      $display("TEST FAILED");
      $fatal(1);
    end
    if (ack_hi == 0 || ack_lo == 0) begin
      $display("COVERAGE HOLE: msiio_vld_ack 只观测到单一取值（hi=%0d lo=%0d）—— 新增端口没被真正激励",
               ack_hi, ack_lo);
      $display("TEST FAILED");
      $fatal(1);
    end
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
