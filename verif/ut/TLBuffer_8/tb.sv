// TLBuffer_8 双例化逐拍比对: golden TLBuffer_8 vs 可读 TLBuffer_8_xs。
// 本轮 G0->G1 改的是**位宽**（source 2b -> 4b），光"逐拍比输出"不够：
// 若激励永远只用低位，把 source 写窄了也照样全绿。所以除比对外还守三个闸，
// 任一不满足即 FAIL：
//   1. source 取到过 >= 8 的值（A/D 两侧各计数）——G0 的 2 位 source 根本到不了这个区间；
//   2. source 每一位都被置 1 过（按位或 = 全 1）——最高位没翻过就等于没测最高位；
//   3. 真发生过反压拍（valid & ~ready）——TL 是握手协议，激励不能永远畅通。
// 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
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
  // 覆盖统计
  int a_fire = 0, d_fire = 0;              // 握手成功（valid & ready）的事务数
  int a_src_ge8 = 0, d_src_ge8 = 0;        // 其中 source >= 8（G0 的 2 位到不了的区间）
  int stall_cycles = 0;                    // 任一握手点 valid & ~ready 的拍数
  logic [3:0] a_src_or = '0, d_src_or = '0;   // source 取值的按位或
  always #5 clock = ~clock;

  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [2:0] auto_in_a_bits_param;
  logic [1:0] auto_in_a_bits_size;
  logic [3:0] auto_in_a_bits_source;
  logic [47:0] auto_in_a_bits_address;
  logic auto_in_a_bits_user_memPageType_NC;
  logic auto_in_a_bits_user_memBackType_MM;
  logic [7:0] auto_in_a_bits_mask;
  logic [63:0] auto_in_a_bits_data;
  logic auto_in_a_bits_corrupt;
  logic auto_in_d_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [1:0] g_auto_in_d_bits_param;
  wire [1:0] i_auto_in_d_bits_param;
  wire [1:0] g_auto_in_d_bits_size;
  wire [1:0] i_auto_in_d_bits_size;
  wire [3:0] g_auto_in_d_bits_source;
  wire [3:0] i_auto_in_d_bits_source;
  wire g_auto_in_d_bits_sink;
  wire i_auto_in_d_bits_sink;
  wire g_auto_in_d_bits_denied;
  wire i_auto_in_d_bits_denied;
  wire [63:0] g_auto_in_d_bits_data;
  wire [63:0] i_auto_in_d_bits_data;
  wire g_auto_in_d_bits_corrupt;
  wire i_auto_in_d_bits_corrupt;
  logic auto_out_a_ready;
  wire g_auto_out_a_valid;
  wire i_auto_out_a_valid;
  wire [3:0] g_auto_out_a_bits_opcode;
  wire [3:0] i_auto_out_a_bits_opcode;
  wire [2:0] g_auto_out_a_bits_param;
  wire [2:0] i_auto_out_a_bits_param;
  wire [1:0] g_auto_out_a_bits_size;
  wire [1:0] i_auto_out_a_bits_size;
  wire [3:0] g_auto_out_a_bits_source;
  wire [3:0] i_auto_out_a_bits_source;
  wire [47:0] g_auto_out_a_bits_address;
  wire [47:0] i_auto_out_a_bits_address;
  wire g_auto_out_a_bits_user_memPageType_NC;
  wire i_auto_out_a_bits_user_memPageType_NC;
  wire g_auto_out_a_bits_user_memBackType_MM;
  wire i_auto_out_a_bits_user_memBackType_MM;
  wire [7:0] g_auto_out_a_bits_mask;
  wire [7:0] i_auto_out_a_bits_mask;
  wire [63:0] g_auto_out_a_bits_data;
  wire [63:0] i_auto_out_a_bits_data;
  wire g_auto_out_a_bits_corrupt;
  wire i_auto_out_a_bits_corrupt;
  wire g_auto_out_d_ready;
  wire i_auto_out_d_ready;
  logic auto_out_d_valid;
  logic [3:0] auto_out_d_bits_opcode;
  logic [1:0] auto_out_d_bits_param;
  logic [1:0] auto_out_d_bits_size;
  logic [3:0] auto_out_d_bits_source;
  logic auto_out_d_bits_sink;
  logic auto_out_d_bits_denied;
  logic [63:0] auto_out_d_bits_data;
  logic auto_out_d_bits_corrupt;

  TLBuffer_8 u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC(auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM(auto_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(g_auto_in_d_bits_param),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_sink(g_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(g_auto_in_d_bits_denied),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_auto_in_d_bits_corrupt),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(g_auto_out_a_valid),
    .auto_out_a_bits_opcode(g_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(g_auto_out_a_bits_param),
    .auto_out_a_bits_size(g_auto_out_a_bits_size),
    .auto_out_a_bits_source(g_auto_out_a_bits_source),
    .auto_out_a_bits_address(g_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC(g_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM(g_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask(g_auto_out_a_bits_mask),
    .auto_out_a_bits_data(g_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(g_auto_out_a_bits_corrupt),
    .auto_out_d_ready(g_auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_param(auto_out_d_bits_param),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_sink(auto_out_d_bits_sink),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt)
  );

  TLBuffer_8_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_memPageType_NC(auto_in_a_bits_user_memPageType_NC),
    .auto_in_a_bits_user_memBackType_MM(auto_in_a_bits_user_memBackType_MM),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(i_auto_in_d_bits_param),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_sink(i_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(i_auto_in_d_bits_denied),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_auto_in_d_bits_corrupt),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(i_auto_out_a_valid),
    .auto_out_a_bits_opcode(i_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(i_auto_out_a_bits_param),
    .auto_out_a_bits_size(i_auto_out_a_bits_size),
    .auto_out_a_bits_source(i_auto_out_a_bits_source),
    .auto_out_a_bits_address(i_auto_out_a_bits_address),
    .auto_out_a_bits_user_memPageType_NC(i_auto_out_a_bits_user_memPageType_NC),
    .auto_out_a_bits_user_memBackType_MM(i_auto_out_a_bits_user_memBackType_MM),
    .auto_out_a_bits_mask(i_auto_out_a_bits_mask),
    .auto_out_a_bits_data(i_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(i_auto_out_a_bits_corrupt),
    .auto_out_d_ready(i_auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_param(auto_out_d_bits_param),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_sink(auto_out_d_bits_sink),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt)
  );

  task automatic drive_random_inputs();
    auto_in_a_valid <= $urandom_range(0, 1);
    auto_in_a_bits_opcode <= 4'({$urandom});
    auto_in_a_bits_param <= 3'({$urandom});
    auto_in_a_bits_size <= 2'({$urandom});
    auto_in_a_bits_source <= 4'({$urandom});
    auto_in_a_bits_address <= 48'({$urandom, $urandom});
    auto_in_a_bits_user_memPageType_NC <= $urandom_range(0, 1);
    auto_in_a_bits_user_memBackType_MM <= $urandom_range(0, 1);
    auto_in_a_bits_mask <= 8'({$urandom});
    auto_in_a_bits_data <= 64'({$urandom, $urandom});
    auto_in_a_bits_corrupt <= $urandom_range(0, 1);
    auto_in_d_ready <= $urandom_range(0, 1);
    auto_out_a_ready <= $urandom_range(0, 1);
    auto_out_d_valid <= $urandom_range(0, 1);
    auto_out_d_bits_opcode <= 4'({$urandom});
    auto_out_d_bits_param <= 2'({$urandom});
    auto_out_d_bits_size <= 2'({$urandom});
    auto_out_d_bits_source <= 4'({$urandom});
    auto_out_d_bits_sink <= $urandom_range(0, 1);
    auto_out_d_bits_denied <= $urandom_range(0, 1);
    auto_out_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_d_bits_corrupt <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_opcode)
    `CHECK(auto_in_d_bits_param)
    `CHECK(auto_in_d_bits_size)
    `CHECK(auto_in_d_bits_source)
    `CHECK(auto_in_d_bits_sink)
    `CHECK(auto_in_d_bits_denied)
    `CHECK(auto_in_d_bits_data)
    `CHECK(auto_in_d_bits_corrupt)
    `CHECK(auto_out_a_valid)
    `CHECK(auto_out_a_bits_opcode)
    `CHECK(auto_out_a_bits_param)
    `CHECK(auto_out_a_bits_size)
    `CHECK(auto_out_a_bits_source)
    `CHECK(auto_out_a_bits_address)
    `CHECK(auto_out_a_bits_user_memPageType_NC)
    `CHECK(auto_out_a_bits_user_memBackType_MM)
    `CHECK(auto_out_a_bits_mask)
    `CHECK(auto_out_a_bits_data)
    `CHECK(auto_out_a_bits_corrupt)
    `CHECK(auto_out_d_ready)
  endtask

  // 覆盖统计：在 posedge 之后的稳定点看握手与 source 取值（ready 取 golden 侧）。
  task automatic sample_coverage();
    if (auto_in_a_valid && g_auto_in_a_ready === 1'b1) begin
      a_fire++;
      a_src_or |= auto_in_a_bits_source;
      if (auto_in_a_bits_source >= 8) a_src_ge8++;
    end
    if (auto_out_d_valid && g_auto_out_d_ready === 1'b1) begin
      d_fire++;
      d_src_or |= auto_out_d_bits_source;
      if (auto_out_d_bits_source >= 8) d_src_ge8++;
    end
    if ((auto_in_a_valid  && g_auto_in_a_ready  === 1'b0)
     || (g_auto_out_a_valid === 1'b1 && !auto_out_a_ready)
     || (auto_out_d_valid && g_auto_out_d_ready === 1'b0)
     || (g_auto_in_d_valid  === 1'b1 && !auto_in_d_ready)) stall_cycles++;
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_param = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_user_memPageType_NC = '0;
    auto_in_a_bits_user_memBackType_MM = '0;
    auto_in_a_bits_mask = '0;
    auto_in_a_bits_data = '0;
    auto_in_a_bits_corrupt = '0;
    auto_in_d_ready = '0;
    auto_out_a_ready = '0;
    auto_out_d_valid = '0;
    auto_out_d_bits_opcode = '0;
    auto_out_d_bits_param = '0;
    auto_out_d_bits_size = '0;
    auto_out_d_bits_source = '0;
    auto_out_d_bits_sink = '0;
    auto_out_d_bits_denied = '0;
    auto_out_d_bits_data = '0;
    auto_out_d_bits_corrupt = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
      sample_coverage();
    end
    $display("TLBuffer_8 checks=%0d errors=%0d", checks, errors);
    $display("TLBuffer_8 coverage: a_fire=%0d a_src_ge8=%0d a_src_or=%0h | d_fire=%0d d_src_ge8=%0d d_src_or=%0h | stall_cycles=%0d",
             a_fire, a_src_ge8, a_src_or, d_fire, d_src_ge8, d_src_or, stall_cycles);
    if (a_src_ge8 == 0 || d_src_ge8 == 0) begin
      $display("COVERAGE HOLE: source 从未取到 >= 8 —— 加宽出来的高位根本没被激励打到");
      $display("TEST FAILED");
      $fatal(1);
    end
    if (!(&a_src_or) || !(&d_src_or)) begin
      $display("COVERAGE HOLE: source 有某些位从未置 1（a=%0h d=%0h, 期望 4 位全 1）",
               a_src_or, d_src_or);
      $display("TEST FAILED");
      $fatal(1);
    end
    if (stall_cycles == 0) begin
      $display("COVERAGE HOLE: 全程无反压拍 —— 握手路径没被压过");
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
