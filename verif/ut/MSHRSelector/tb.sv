// 自动生成：scripts/gen_mshrselector.py —— 勿手改
// MSHRSelector 双例化逐拍比对：golden MSHRSelector vs 可读重写 MSHRSelector_xs。
// 纯组合优先选择器：15 个 idle 输入随机，比对 16 位 one-hot 输出 io_out_bits。
// 激励混合：全随机 idle + 偏向稀疏 (单/双 idle) 以覆盖各优先级分支。
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

  logic [14:0] idle_vec;   // 打包 15 个 idle 输入

  logic io_idle_0;
  logic io_idle_1;
  logic io_idle_2;
  logic io_idle_3;
  logic io_idle_4;
  logic io_idle_5;
  logic io_idle_6;
  logic io_idle_7;
  logic io_idle_8;
  logic io_idle_9;
  logic io_idle_10;
  logic io_idle_11;
  logic io_idle_12;
  logic io_idle_13;
  logic io_idle_14;
  wire [15:0] g_io_out_bits;
  wire [15:0] i_io_out_bits;

  MSHRSelector u_g (
    .io_idle_0(io_idle_0),
    .io_idle_1(io_idle_1),
    .io_idle_2(io_idle_2),
    .io_idle_3(io_idle_3),
    .io_idle_4(io_idle_4),
    .io_idle_5(io_idle_5),
    .io_idle_6(io_idle_6),
    .io_idle_7(io_idle_7),
    .io_idle_8(io_idle_8),
    .io_idle_9(io_idle_9),
    .io_idle_10(io_idle_10),
    .io_idle_11(io_idle_11),
    .io_idle_12(io_idle_12),
    .io_idle_13(io_idle_13),
    .io_idle_14(io_idle_14),
    .io_out_bits(g_io_out_bits)
  );

  MSHRSelector_xs u_i (
    .io_idle_0(io_idle_0),
    .io_idle_1(io_idle_1),
    .io_idle_2(io_idle_2),
    .io_idle_3(io_idle_3),
    .io_idle_4(io_idle_4),
    .io_idle_5(io_idle_5),
    .io_idle_6(io_idle_6),
    .io_idle_7(io_idle_7),
    .io_idle_8(io_idle_8),
    .io_idle_9(io_idle_9),
    .io_idle_10(io_idle_10),
    .io_idle_11(io_idle_11),
    .io_idle_12(io_idle_12),
    .io_idle_13(io_idle_13),
    .io_idle_14(io_idle_14),
    .io_out_bits(i_io_out_bits)
  );

  // 按概率生成 idle 向量：稀疏 (强调优先级链尾) / 稠密 / 全随机混合
  function automatic logic [14:0] pick_idle();
    logic [14:0] v;
    case ($urandom_range(0, 3))
      0: begin  // 单个 idle (随机下标)
        v = 15'h0;
        v[$urandom_range(0, 14)] = 1'b1;
      end
      1: begin  // 全不空闲 -> 命中兜底槽 (输出应为 16'h8000)
        v = 15'h0;
      end
      2: v = 15'($urandom) & 15'($urandom);  // 稀疏随机
      default: v = 15'($urandom);            // 全随机
    endcase
    return v;
  endfunction

  task automatic drive_random_inputs();
    idle_vec = pick_idle();
    io_idle_0 = idle_vec[0];
    io_idle_1 = idle_vec[1];
    io_idle_2 = idle_vec[2];
    io_idle_3 = idle_vec[3];
    io_idle_4 = idle_vec[4];
    io_idle_5 = idle_vec[5];
    io_idle_6 = idle_vec[6];
    io_idle_7 = idle_vec[7];
    io_idle_8 = idle_vec[8];
    io_idle_9 = idle_vec[9];
    io_idle_10 = idle_vec[10];
    io_idle_11 = idle_vec[11];
    io_idle_12 = idle_vec[12];
    io_idle_13 = idle_vec[13];
    io_idle_14 = idle_vec[14];
  endtask

  task automatic check_outputs();
    `CHECK(io_out_bits)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_idle_0 = '0;
    io_idle_1 = '0;
    io_idle_2 = '0;
    io_idle_3 = '0;
    io_idle_4 = '0;
    io_idle_5 = '0;
    io_idle_6 = '0;
    io_idle_7 = '0;
    io_idle_8 = '0;
    io_idle_9 = '0;
    io_idle_10 = '0;
    io_idle_11 = '0;
    io_idle_12 = '0;
    io_idle_13 = '0;
    io_idle_14 = '0;
    repeat (4) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("MSHRSelector checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
