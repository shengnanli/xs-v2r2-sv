// tb.sv —— L1PrefetchSourceArray 双例化逐拍比对 UT
//
// golden L1PrefetchSourceArray 与重写 L1PrefetchSourceArray_xs（derive_ut_impl.py 从
// rtl/memblock/L1PrefetchSourceArray.sv 派生改名）同激励并跑，逐拍比全部 20 个输出。
//
// ★暖机（warm-up）为什么必须有★：本族只有 meta_array 是异步复位的；S1 在途写寄存器
//   与读流水寄存器 golden 侧都没有复位。带 +vcs+initreg+random 时两侧拿到的上电随机值
//   互不相同，一上来就比会报出与设计无关的假失配（$isunknown 挡不住——initreg 给的是
//   确定值不是 X）。暖机用「全部写口 way_en=4'hf + 全部读口与写口同 idx」把这些寄存器
//   全部写成确定值：way_en 全 1 让 4 路的 s1_* 都被使能，读写同 idx 让旁路判定命中，
//   从而给 bypass_r 上使能。$isunknown 守卫保留作第二道网。
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  localparam int WARMUP = 8;
  int errors = 0, checks = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;

  logic       io_read_0_valid;
  logic [7:0] io_read_0_bits_idx;
  logic       io_read_1_valid;
  logic [7:0] io_read_1_bits_idx;
  logic       io_read_2_valid;
  logic [7:0] io_read_2_bits_idx;
  logic       io_read_3_valid;
  logic [7:0] io_read_3_bits_idx;
  logic       io_read_4_valid;
  logic [7:0] io_read_4_bits_idx;
  logic       io_write_0_valid;
  logic [7:0] io_write_0_bits_idx;
  logic [3:0] io_write_0_bits_way_en;
  logic       io_write_1_valid;
  logic [7:0] io_write_1_bits_idx;
  logic [3:0] io_write_1_bits_way_en;
  logic       io_write_2_valid;
  logic [7:0] io_write_2_bits_idx;
  logic [3:0] io_write_2_bits_way_en;
  logic       io_write_3_valid;
  logic [7:0] io_write_3_bits_idx;
  logic [3:0] io_write_3_bits_way_en;
  logic [2:0] io_write_3_bits_source;

  wire [2:0] g_io_resp_0_0;  wire [2:0] i_io_resp_0_0;
  wire [2:0] g_io_resp_0_1;  wire [2:0] i_io_resp_0_1;
  wire [2:0] g_io_resp_0_2;  wire [2:0] i_io_resp_0_2;
  wire [2:0] g_io_resp_0_3;  wire [2:0] i_io_resp_0_3;
  wire [2:0] g_io_resp_1_0;  wire [2:0] i_io_resp_1_0;
  wire [2:0] g_io_resp_1_1;  wire [2:0] i_io_resp_1_1;
  wire [2:0] g_io_resp_1_2;  wire [2:0] i_io_resp_1_2;
  wire [2:0] g_io_resp_1_3;  wire [2:0] i_io_resp_1_3;
  wire [2:0] g_io_resp_2_0;  wire [2:0] i_io_resp_2_0;
  wire [2:0] g_io_resp_2_1;  wire [2:0] i_io_resp_2_1;
  wire [2:0] g_io_resp_2_2;  wire [2:0] i_io_resp_2_2;
  wire [2:0] g_io_resp_2_3;  wire [2:0] i_io_resp_2_3;
  wire [2:0] g_io_resp_3_0;  wire [2:0] i_io_resp_3_0;
  wire [2:0] g_io_resp_3_1;  wire [2:0] i_io_resp_3_1;
  wire [2:0] g_io_resp_3_2;  wire [2:0] i_io_resp_3_2;
  wire [2:0] g_io_resp_3_3;  wire [2:0] i_io_resp_3_3;
  wire [2:0] g_io_resp_4_0;  wire [2:0] i_io_resp_4_0;
  wire [2:0] g_io_resp_4_1;  wire [2:0] i_io_resp_4_1;
  wire [2:0] g_io_resp_4_2;  wire [2:0] i_io_resp_4_2;
  wire [2:0] g_io_resp_4_3;  wire [2:0] i_io_resp_4_3;

  L1PrefetchSourceArray u_g_ (
    .clock(clock), .reset(reset),
    .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx), .io_read_4_valid(io_read_4_valid), .io_read_4_bits_idx(io_read_4_bits_idx), .io_write_0_valid(io_write_0_valid), .io_write_0_bits_idx(io_write_0_bits_idx), .io_write_0_bits_way_en(io_write_0_bits_way_en), .io_write_1_valid(io_write_1_valid), .io_write_1_bits_idx(io_write_1_bits_idx), .io_write_1_bits_way_en(io_write_1_bits_way_en), .io_write_2_valid(io_write_2_valid), .io_write_2_bits_idx(io_write_2_bits_idx), .io_write_2_bits_way_en(io_write_2_bits_way_en), .io_write_3_valid(io_write_3_valid), .io_write_3_bits_idx(io_write_3_bits_idx), .io_write_3_bits_way_en(io_write_3_bits_way_en), .io_write_3_bits_source(io_write_3_bits_source),
    .io_resp_0_0(g_io_resp_0_0), .io_resp_0_1(g_io_resp_0_1), .io_resp_0_2(g_io_resp_0_2), .io_resp_0_3(g_io_resp_0_3), .io_resp_1_0(g_io_resp_1_0), .io_resp_1_1(g_io_resp_1_1), .io_resp_1_2(g_io_resp_1_2), .io_resp_1_3(g_io_resp_1_3), .io_resp_2_0(g_io_resp_2_0), .io_resp_2_1(g_io_resp_2_1), .io_resp_2_2(g_io_resp_2_2), .io_resp_2_3(g_io_resp_2_3), .io_resp_3_0(g_io_resp_3_0), .io_resp_3_1(g_io_resp_3_1), .io_resp_3_2(g_io_resp_3_2), .io_resp_3_3(g_io_resp_3_3), .io_resp_4_0(g_io_resp_4_0), .io_resp_4_1(g_io_resp_4_1), .io_resp_4_2(g_io_resp_4_2), .io_resp_4_3(g_io_resp_4_3)
  );
  L1PrefetchSourceArray_xs u_i_ (
    .clock(clock), .reset(reset),
    .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx), .io_read_4_valid(io_read_4_valid), .io_read_4_bits_idx(io_read_4_bits_idx), .io_write_0_valid(io_write_0_valid), .io_write_0_bits_idx(io_write_0_bits_idx), .io_write_0_bits_way_en(io_write_0_bits_way_en), .io_write_1_valid(io_write_1_valid), .io_write_1_bits_idx(io_write_1_bits_idx), .io_write_1_bits_way_en(io_write_1_bits_way_en), .io_write_2_valid(io_write_2_valid), .io_write_2_bits_idx(io_write_2_bits_idx), .io_write_2_bits_way_en(io_write_2_bits_way_en), .io_write_3_valid(io_write_3_valid), .io_write_3_bits_idx(io_write_3_bits_idx), .io_write_3_bits_way_en(io_write_3_bits_way_en), .io_write_3_bits_source(io_write_3_bits_source),
    .io_resp_0_0(i_io_resp_0_0), .io_resp_0_1(i_io_resp_0_1), .io_resp_0_2(i_io_resp_0_2), .io_resp_0_3(i_io_resp_0_3), .io_resp_1_0(i_io_resp_1_0), .io_resp_1_1(i_io_resp_1_1), .io_resp_1_2(i_io_resp_1_2), .io_resp_1_3(i_io_resp_1_3), .io_resp_2_0(i_io_resp_2_0), .io_resp_2_1(i_io_resp_2_1), .io_resp_2_2(i_io_resp_2_2), .io_resp_2_3(i_io_resp_2_3), .io_resp_3_0(i_io_resp_3_0), .io_resp_3_1(i_io_resp_3_1), .io_resp_3_2(i_io_resp_3_2), .io_resp_3_3(i_io_resp_3_3), .io_resp_4_0(i_io_resp_4_0), .io_resp_4_1(i_io_resp_4_1), .io_resp_4_2(i_io_resp_4_2), .io_resp_4_3(i_io_resp_4_3)
  );

  task automatic do_check(int t);
    checks++;
    if (!$isunknown(g_io_resp_0_0) && (g_io_resp_0_0 !== i_io_resp_0_0)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_0 g=%h i=%h", t, g_io_resp_0_0, i_io_resp_0_0); end
    if (!$isunknown(g_io_resp_0_1) && (g_io_resp_0_1 !== i_io_resp_0_1)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_1 g=%h i=%h", t, g_io_resp_0_1, i_io_resp_0_1); end
    if (!$isunknown(g_io_resp_0_2) && (g_io_resp_0_2 !== i_io_resp_0_2)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_2 g=%h i=%h", t, g_io_resp_0_2, i_io_resp_0_2); end
    if (!$isunknown(g_io_resp_0_3) && (g_io_resp_0_3 !== i_io_resp_0_3)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_3 g=%h i=%h", t, g_io_resp_0_3, i_io_resp_0_3); end
    if (!$isunknown(g_io_resp_1_0) && (g_io_resp_1_0 !== i_io_resp_1_0)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_0 g=%h i=%h", t, g_io_resp_1_0, i_io_resp_1_0); end
    if (!$isunknown(g_io_resp_1_1) && (g_io_resp_1_1 !== i_io_resp_1_1)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_1 g=%h i=%h", t, g_io_resp_1_1, i_io_resp_1_1); end
    if (!$isunknown(g_io_resp_1_2) && (g_io_resp_1_2 !== i_io_resp_1_2)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_2 g=%h i=%h", t, g_io_resp_1_2, i_io_resp_1_2); end
    if (!$isunknown(g_io_resp_1_3) && (g_io_resp_1_3 !== i_io_resp_1_3)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_3 g=%h i=%h", t, g_io_resp_1_3, i_io_resp_1_3); end
    if (!$isunknown(g_io_resp_2_0) && (g_io_resp_2_0 !== i_io_resp_2_0)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_0 g=%h i=%h", t, g_io_resp_2_0, i_io_resp_2_0); end
    if (!$isunknown(g_io_resp_2_1) && (g_io_resp_2_1 !== i_io_resp_2_1)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_1 g=%h i=%h", t, g_io_resp_2_1, i_io_resp_2_1); end
    if (!$isunknown(g_io_resp_2_2) && (g_io_resp_2_2 !== i_io_resp_2_2)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_2 g=%h i=%h", t, g_io_resp_2_2, i_io_resp_2_2); end
    if (!$isunknown(g_io_resp_2_3) && (g_io_resp_2_3 !== i_io_resp_2_3)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_3 g=%h i=%h", t, g_io_resp_2_3, i_io_resp_2_3); end
    if (!$isunknown(g_io_resp_3_0) && (g_io_resp_3_0 !== i_io_resp_3_0)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_0 g=%h i=%h", t, g_io_resp_3_0, i_io_resp_3_0); end
    if (!$isunknown(g_io_resp_3_1) && (g_io_resp_3_1 !== i_io_resp_3_1)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_1 g=%h i=%h", t, g_io_resp_3_1, i_io_resp_3_1); end
    if (!$isunknown(g_io_resp_3_2) && (g_io_resp_3_2 !== i_io_resp_3_2)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_2 g=%h i=%h", t, g_io_resp_3_2, i_io_resp_3_2); end
    if (!$isunknown(g_io_resp_3_3) && (g_io_resp_3_3 !== i_io_resp_3_3)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_3 g=%h i=%h", t, g_io_resp_3_3, i_io_resp_3_3); end
    if (!$isunknown(g_io_resp_4_0) && (g_io_resp_4_0 !== i_io_resp_4_0)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_4_0 g=%h i=%h", t, g_io_resp_4_0, i_io_resp_4_0); end
    if (!$isunknown(g_io_resp_4_1) && (g_io_resp_4_1 !== i_io_resp_4_1)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_4_1 g=%h i=%h", t, g_io_resp_4_1, i_io_resp_4_1); end
    if (!$isunknown(g_io_resp_4_2) && (g_io_resp_4_2 !== i_io_resp_4_2)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_4_2 g=%h i=%h", t, g_io_resp_4_2, i_io_resp_4_2); end
    if (!$isunknown(g_io_resp_4_3) && (g_io_resp_4_3 !== i_io_resp_4_3)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_4_3 g=%h i=%h", t, g_io_resp_4_3, i_io_resp_4_3); end
  endtask

  // idx 大多压在 0..15 的小窗口里，好让读写冲突/在途写转发频繁发生；
  // 四分之一走全量程 0..255 覆盖寄存器堆其余深度。
  function automatic logic [7:0] rand_idx();
    return ($urandom_range(0,3) == 0) ? 8'($urandom) : 8'($urandom_range(0,15));
  endfunction

  task automatic drive_random();
    io_read_0_valid    = $urandom_range(0,1);
    io_read_0_bits_idx = rand_idx();
    io_read_1_valid    = $urandom_range(0,1);
    io_read_1_bits_idx = rand_idx();
    io_read_2_valid    = $urandom_range(0,1);
    io_read_2_bits_idx = rand_idx();
    io_read_3_valid    = $urandom_range(0,1);
    io_read_3_bits_idx = rand_idx();
    io_read_4_valid    = $urandom_range(0,1);
    io_read_4_bits_idx = rand_idx();
    io_write_0_valid = ($urandom_range(0,2) == 0);
    io_write_0_bits_idx = rand_idx();
    io_write_0_bits_way_en = 4'($urandom);
    io_write_1_valid = ($urandom_range(0,2) == 0);
    io_write_1_bits_idx = rand_idx();
    io_write_1_bits_way_en = 4'($urandom);
    io_write_2_valid = ($urandom_range(0,2) == 0);
    io_write_2_bits_idx = rand_idx();
    io_write_2_bits_way_en = 4'($urandom);
    io_write_3_valid = ($urandom_range(0,2) == 0);
    io_write_3_bits_idx = rand_idx();
    io_write_3_bits_way_en = 4'($urandom);
    io_write_3_bits_source = 3'($urandom);
  endtask

  task automatic drive_warmup(int k);
    io_read_0_valid    = 1'b1;
    io_read_0_bits_idx = 8'(k);
    io_read_1_valid    = 1'b1;
    io_read_1_bits_idx = 8'(k);
    io_read_2_valid    = 1'b1;
    io_read_2_bits_idx = 8'(k);
    io_read_3_valid    = 1'b1;
    io_read_3_bits_idx = 8'(k);
    io_read_4_valid    = 1'b1;
    io_read_4_bits_idx = 8'(k);
    io_write_0_valid = 1'b1;
    io_write_0_bits_idx = 8'(k);
    io_write_0_bits_way_en = 4'hf;
    io_write_1_valid = 1'b1;
    io_write_1_bits_idx = 8'(k);
    io_write_1_bits_way_en = 4'hf;
    io_write_2_valid = 1'b1;
    io_write_2_bits_idx = 8'(k);
    io_write_2_bits_way_en = 4'hf;
    io_write_3_valid = 1'b1;
    io_write_3_bits_idx = 8'(k);
    io_write_3_bits_way_en = 4'hf;
    io_write_3_bits_source = '1;
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NVEC)) ;
    reset = 1;
    io_read_0_valid = 0;  io_read_0_bits_idx = 0;
    io_read_1_valid = 0;  io_read_1_bits_idx = 0;
    io_read_2_valid = 0;  io_read_2_bits_idx = 0;
    io_read_3_valid = 0;  io_read_3_bits_idx = 0;
    io_read_4_valid = 0;  io_read_4_bits_idx = 0;
    io_write_0_valid = 0;  io_write_0_bits_idx = 0;  io_write_0_bits_way_en = 0;
    io_write_1_valid = 0;  io_write_1_bits_idx = 0;  io_write_1_bits_way_en = 0;
    io_write_2_valid = 0;  io_write_2_bits_idx = 0;  io_write_2_bits_way_en = 0;
    io_write_3_valid = 0;  io_write_3_bits_idx = 0;  io_write_3_bits_way_en = 0;
    io_write_3_bits_source = 0;
    repeat (3) @(posedge clock); #1; reset = 0;
    @(posedge clock);
    for (int k = 0; k < WARMUP; k++) begin
      drive_warmup(k);
      @(posedge clock); #1;
    end
    for (int t = 0; t < NVEC; t++) begin
      drive_random();
      @(posedge clock); #1;
      do_check(t);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
