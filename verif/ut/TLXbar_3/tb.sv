// 自动生成：scripts/gen_tlxbar3.py —— 勿手改
// TLXbar_3 双例化逐拍比对: golden TLXbar_3 vs 可读 TLXbar_3_xs。
// 激励: A 通道地址偏向设备区间 (0x40-0x57) 以覆盖两条路由; D 通道两从口
// valid/data 随机 (覆盖 round-robin 仲裁两路争用)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
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

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [8:0] auto_in_a_bits_address;
  logic [31:0] auto_in_a_bits_data;
  logic auto_in_d_ready;
  logic auto_out_1_a_ready;
  logic auto_out_1_d_valid;
  logic [31:0] auto_out_1_d_bits_data;
  logic auto_out_0_a_ready;
  logic auto_out_0_d_valid;
  logic auto_out_0_d_bits_denied;
  logic [31:0] auto_out_0_d_bits_data;
  logic auto_out_0_d_bits_corrupt;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire g_auto_in_d_bits_denied;
  wire i_auto_in_d_bits_denied;
  wire [31:0] g_auto_in_d_bits_data;
  wire [31:0] i_auto_in_d_bits_data;
  wire g_auto_in_d_bits_corrupt;
  wire i_auto_in_d_bits_corrupt;
  wire g_auto_out_1_a_valid;
  wire i_auto_out_1_a_valid;
  wire [3:0] g_auto_out_1_a_bits_opcode;
  wire [3:0] i_auto_out_1_a_bits_opcode;
  wire [6:0] g_auto_out_1_a_bits_address;
  wire [6:0] i_auto_out_1_a_bits_address;
  wire [31:0] g_auto_out_1_a_bits_data;
  wire [31:0] i_auto_out_1_a_bits_data;
  wire g_auto_out_1_d_ready;
  wire i_auto_out_1_d_ready;
  wire g_auto_out_0_a_valid;
  wire i_auto_out_0_a_valid;
  wire [3:0] g_auto_out_0_a_bits_opcode;
  wire [3:0] i_auto_out_0_a_bits_opcode;
  wire [8:0] g_auto_out_0_a_bits_address;
  wire [8:0] i_auto_out_0_a_bits_address;
  wire [31:0] g_auto_out_0_a_bits_data;
  wire [31:0] i_auto_out_0_a_bits_data;
  wire g_auto_out_0_d_ready;
  wire i_auto_out_0_d_ready;

  TLXbar_3 u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_denied(g_auto_in_d_bits_denied),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_auto_in_d_bits_corrupt),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(g_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(g_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_address(g_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_data(g_auto_out_1_a_bits_data),
    .auto_out_1_d_ready(g_auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(g_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(g_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_address(g_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_data(g_auto_out_0_a_bits_data),
    .auto_out_0_d_ready(g_auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_denied(auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_data(auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(auto_out_0_d_bits_corrupt)
  );

  TLXbar_3_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_denied(i_auto_in_d_bits_denied),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_auto_in_d_bits_corrupt),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(i_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(i_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_address(i_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_data(i_auto_out_1_a_bits_data),
    .auto_out_1_d_ready(i_auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(i_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(i_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_address(i_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_data(i_auto_out_0_a_bits_data),
    .auto_out_0_d_ready(i_auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_denied(auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_data(auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(auto_out_0_d_bits_corrupt)
  );

  task automatic drive_random_inputs();
    auto_in_a_valid <= $urandom_range(0, 1);
    auto_in_a_bits_opcode <= 4'({$urandom});
    if ($urandom_range(0, 1))
      auto_in_a_bits_address <= 9'(9'h40 + $urandom_range(0, 31));
    else
      auto_in_a_bits_address <= 9'({$urandom});
    auto_in_a_bits_data <= 32'({$urandom});
    auto_in_d_ready <= $urandom_range(0, 1);
    auto_out_1_a_ready <= $urandom_range(0, 1);
    auto_out_1_d_valid <= $urandom_range(0, 1);
    auto_out_1_d_bits_data <= 32'({$urandom});
    auto_out_0_a_ready <= $urandom_range(0, 1);
    auto_out_0_d_valid <= $urandom_range(0, 1);
    auto_out_0_d_bits_denied <= $urandom_range(0, 1);
    auto_out_0_d_bits_data <= 32'({$urandom});
    auto_out_0_d_bits_corrupt <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_denied)
    `CHECK(auto_in_d_bits_data)
    `CHECK(auto_in_d_bits_corrupt)
    `CHECK(auto_out_1_a_valid)
    `CHECK(auto_out_1_a_bits_opcode)
    `CHECK(auto_out_1_a_bits_address)
    `CHECK(auto_out_1_a_bits_data)
    `CHECK(auto_out_1_d_ready)
    `CHECK(auto_out_0_a_valid)
    `CHECK(auto_out_0_a_bits_opcode)
    `CHECK(auto_out_0_a_bits_address)
    `CHECK(auto_out_0_a_bits_data)
    `CHECK(auto_out_0_d_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_data = '0;
    auto_in_d_ready = '0;
    auto_out_1_a_ready = '0;
    auto_out_1_d_valid = '0;
    auto_out_1_d_bits_data = '0;
    auto_out_0_a_ready = '0;
    auto_out_0_d_valid = '0;
    auto_out_0_d_bits_denied = '0;
    auto_out_0_d_bits_data = '0;
    auto_out_0_d_bits_corrupt = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("TLXbar_3 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
