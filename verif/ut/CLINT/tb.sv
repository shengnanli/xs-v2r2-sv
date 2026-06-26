// 自动生成：scripts/gen_clint.py —— 勿手改
// CLINT 双例化逐拍比对：golden CLINT vs 可读重写 CLINT_xs。
// 激励含 TileLink A 随机请求 + io_rtcTick；为提高地址命中率，
// 地址在合法寄存器槽 (msip/mtimecmp/mtime) 与全随机之间混合采样。
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

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [1:0] auto_in_a_bits_size;
  logic [14:0] auto_in_a_bits_source;
  logic [29:0] auto_in_a_bits_address;
  logic [7:0] auto_in_a_bits_mask;
  logic [63:0] auto_in_a_bits_data;
  logic auto_in_d_ready;
  logic io_rtcTick;
  wire g_auto_int_out_0;
  wire i_auto_int_out_0;
  wire g_auto_int_out_1;
  wire i_auto_int_out_1;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [1:0] g_auto_in_d_bits_size;
  wire [1:0] i_auto_in_d_bits_size;
  wire [14:0] g_auto_in_d_bits_source;
  wire [14:0] i_auto_in_d_bits_source;
  wire [63:0] g_auto_in_d_bits_data;
  wire [63:0] i_auto_in_d_bits_data;
  wire g_io_time_valid;
  wire i_io_time_valid;
  wire [63:0] g_io_time_bits;
  wire [63:0] i_io_time_bits;

  CLINT u_g (
    .clock(clock),
    .reset(reset),
    .auto_int_out_0(g_auto_int_out_0),
    .auto_int_out_1(g_auto_int_out_1),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .io_rtcTick(io_rtcTick),
    .io_time_valid(g_io_time_valid),
    .io_time_bits(g_io_time_bits)
  );

  CLINT_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_int_out_0(i_auto_int_out_0),
    .auto_int_out_1(i_auto_int_out_1),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .io_rtcTick(io_rtcTick),
    .io_time_valid(i_io_time_valid),
    .io_time_bits(i_io_time_bits)
  );

  // 合法寄存器字节偏移 (设备内地址)；偏移在 [15:14]/[13:3] 上有意义
  localparam logic [29:0] OFF_MSIP    = 30'h0000;
  localparam logic [29:0] OFF_TIMECMP = 30'h4000;
  localparam logic [29:0] OFF_TIME    = 30'hbff8;

  function automatic logic [29:0] pick_addr();
    case ($urandom_range(0, 3))
      0: return OFF_MSIP;
      1: return OFF_TIMECMP;
      2: return OFF_TIME;
      default: return 30'($urandom);  // 全随机：覆盖未命中路径
    endcase
  endfunction

  task automatic drive_random_inputs();
    auto_in_a_valid = $urandom_range(0, 1);
    auto_in_a_bits_opcode = ($urandom_range(0,1)) ? 4'h4 : 4'($urandom_range(0,1));
    auto_in_a_bits_size = 2'({$urandom});
    auto_in_a_bits_source = 15'({$urandom});
    auto_in_a_bits_address = pick_addr();
    auto_in_a_bits_mask = 8'({$urandom});
    auto_in_a_bits_data = 64'({$urandom, $urandom});
    auto_in_d_ready = $urandom_range(0, 1);
    io_rtcTick = ($urandom_range(0, 3) != 0);
  endtask

  task automatic check_outputs();
    `CHECK(auto_int_out_0)
    `CHECK(auto_int_out_1)
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_opcode)
    `CHECK(auto_in_d_bits_size)
    `CHECK(auto_in_d_bits_source)
    `CHECK(auto_in_d_bits_data)
    `CHECK(io_time_valid)
    `CHECK(io_time_bits)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_mask = '0;
    auto_in_a_bits_data = '0;
    auto_in_d_ready = '0;
    io_rtcTick = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("CLINT checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
