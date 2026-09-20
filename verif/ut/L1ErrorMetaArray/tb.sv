// tb.sv —— L1ErrorMetaArray 双例化逐拍比对 UT
//
// golden L1ErrorMetaArray 与重写 L1ErrorMetaArray_xs（derive_ut_impl.py 从
// rtl/memblock/L1ErrorMetaArray.sv 派生改名）同激励并跑，逐拍比全部 32 个输出。
//
// ★暖机（warm-up）为什么必须有★：本模块只有 meta_array 是异步复位的；S1 在途写
//   寄存器(s1_way_wen/waddr/wdata)与读流水寄存器(sel_r/bypass_r/read_idx_r)golden
//   侧都**没有复位**。带 +vcs+initreg+random 时两侧拿到的上电随机值互不相同，若一
//   上来就比对会报出与设计无关的假失配（$isunknown 挡不住——initreg 给的是确定值，
//   不是 X）。所以先跑 WARMUP 拍，用「写口 way_en=4'hf + 四个读口同 idx」把这三组
//   寄存器全部写成确定值：way_en 全 1 让 4 个 way 的 s1_* 都被使能；读写同 idx 让
//   16 个 (读口,way) 对的 bypass 判定全部命中，从而给 bypass_r 上使能。
//   暖机之后两侧状态完全一致，比对才有意义。$isunknown 守卫保留作第二道网。
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
  logic       io_write_0_valid;
  logic [7:0] io_write_0_bits_idx;
  logic [3:0] io_write_0_bits_way_en;
  logic       io_write_0_bits_error_tl_denied;
  logic       io_write_0_bits_error_tl_corrupt;

  wire g_io_resp_0_0_tl_denied;  wire i_io_resp_0_0_tl_denied;
  wire g_io_resp_0_0_tl_corrupt;  wire i_io_resp_0_0_tl_corrupt;
  wire g_io_resp_0_1_tl_denied;  wire i_io_resp_0_1_tl_denied;
  wire g_io_resp_0_1_tl_corrupt;  wire i_io_resp_0_1_tl_corrupt;
  wire g_io_resp_0_2_tl_denied;  wire i_io_resp_0_2_tl_denied;
  wire g_io_resp_0_2_tl_corrupt;  wire i_io_resp_0_2_tl_corrupt;
  wire g_io_resp_0_3_tl_denied;  wire i_io_resp_0_3_tl_denied;
  wire g_io_resp_0_3_tl_corrupt;  wire i_io_resp_0_3_tl_corrupt;
  wire g_io_resp_1_0_tl_denied;  wire i_io_resp_1_0_tl_denied;
  wire g_io_resp_1_0_tl_corrupt;  wire i_io_resp_1_0_tl_corrupt;
  wire g_io_resp_1_1_tl_denied;  wire i_io_resp_1_1_tl_denied;
  wire g_io_resp_1_1_tl_corrupt;  wire i_io_resp_1_1_tl_corrupt;
  wire g_io_resp_1_2_tl_denied;  wire i_io_resp_1_2_tl_denied;
  wire g_io_resp_1_2_tl_corrupt;  wire i_io_resp_1_2_tl_corrupt;
  wire g_io_resp_1_3_tl_denied;  wire i_io_resp_1_3_tl_denied;
  wire g_io_resp_1_3_tl_corrupt;  wire i_io_resp_1_3_tl_corrupt;
  wire g_io_resp_2_0_tl_denied;  wire i_io_resp_2_0_tl_denied;
  wire g_io_resp_2_0_tl_corrupt;  wire i_io_resp_2_0_tl_corrupt;
  wire g_io_resp_2_1_tl_denied;  wire i_io_resp_2_1_tl_denied;
  wire g_io_resp_2_1_tl_corrupt;  wire i_io_resp_2_1_tl_corrupt;
  wire g_io_resp_2_2_tl_denied;  wire i_io_resp_2_2_tl_denied;
  wire g_io_resp_2_2_tl_corrupt;  wire i_io_resp_2_2_tl_corrupt;
  wire g_io_resp_2_3_tl_denied;  wire i_io_resp_2_3_tl_denied;
  wire g_io_resp_2_3_tl_corrupt;  wire i_io_resp_2_3_tl_corrupt;
  wire g_io_resp_3_0_tl_denied;  wire i_io_resp_3_0_tl_denied;
  wire g_io_resp_3_0_tl_corrupt;  wire i_io_resp_3_0_tl_corrupt;
  wire g_io_resp_3_1_tl_denied;  wire i_io_resp_3_1_tl_denied;
  wire g_io_resp_3_1_tl_corrupt;  wire i_io_resp_3_1_tl_corrupt;
  wire g_io_resp_3_2_tl_denied;  wire i_io_resp_3_2_tl_denied;
  wire g_io_resp_3_2_tl_corrupt;  wire i_io_resp_3_2_tl_corrupt;
  wire g_io_resp_3_3_tl_denied;  wire i_io_resp_3_3_tl_denied;
  wire g_io_resp_3_3_tl_corrupt;  wire i_io_resp_3_3_tl_corrupt;

  L1ErrorMetaArray u_g_ (
    .clock(clock), .reset(reset),
    .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx),
    .io_write_0_valid(io_write_0_valid), .io_write_0_bits_idx(io_write_0_bits_idx), .io_write_0_bits_way_en(io_write_0_bits_way_en), .io_write_0_bits_error_tl_denied(io_write_0_bits_error_tl_denied), .io_write_0_bits_error_tl_corrupt(io_write_0_bits_error_tl_corrupt),
    .io_resp_0_0_tl_denied(g_io_resp_0_0_tl_denied), .io_resp_0_0_tl_corrupt(g_io_resp_0_0_tl_corrupt), .io_resp_0_1_tl_denied(g_io_resp_0_1_tl_denied), .io_resp_0_1_tl_corrupt(g_io_resp_0_1_tl_corrupt), .io_resp_0_2_tl_denied(g_io_resp_0_2_tl_denied), .io_resp_0_2_tl_corrupt(g_io_resp_0_2_tl_corrupt), .io_resp_0_3_tl_denied(g_io_resp_0_3_tl_denied), .io_resp_0_3_tl_corrupt(g_io_resp_0_3_tl_corrupt), .io_resp_1_0_tl_denied(g_io_resp_1_0_tl_denied), .io_resp_1_0_tl_corrupt(g_io_resp_1_0_tl_corrupt), .io_resp_1_1_tl_denied(g_io_resp_1_1_tl_denied), .io_resp_1_1_tl_corrupt(g_io_resp_1_1_tl_corrupt), .io_resp_1_2_tl_denied(g_io_resp_1_2_tl_denied), .io_resp_1_2_tl_corrupt(g_io_resp_1_2_tl_corrupt), .io_resp_1_3_tl_denied(g_io_resp_1_3_tl_denied), .io_resp_1_3_tl_corrupt(g_io_resp_1_3_tl_corrupt), .io_resp_2_0_tl_denied(g_io_resp_2_0_tl_denied), .io_resp_2_0_tl_corrupt(g_io_resp_2_0_tl_corrupt), .io_resp_2_1_tl_denied(g_io_resp_2_1_tl_denied), .io_resp_2_1_tl_corrupt(g_io_resp_2_1_tl_corrupt), .io_resp_2_2_tl_denied(g_io_resp_2_2_tl_denied), .io_resp_2_2_tl_corrupt(g_io_resp_2_2_tl_corrupt), .io_resp_2_3_tl_denied(g_io_resp_2_3_tl_denied), .io_resp_2_3_tl_corrupt(g_io_resp_2_3_tl_corrupt), .io_resp_3_0_tl_denied(g_io_resp_3_0_tl_denied), .io_resp_3_0_tl_corrupt(g_io_resp_3_0_tl_corrupt), .io_resp_3_1_tl_denied(g_io_resp_3_1_tl_denied), .io_resp_3_1_tl_corrupt(g_io_resp_3_1_tl_corrupt), .io_resp_3_2_tl_denied(g_io_resp_3_2_tl_denied), .io_resp_3_2_tl_corrupt(g_io_resp_3_2_tl_corrupt), .io_resp_3_3_tl_denied(g_io_resp_3_3_tl_denied), .io_resp_3_3_tl_corrupt(g_io_resp_3_3_tl_corrupt)
  );
  L1ErrorMetaArray_xs u_i_ (
    .clock(clock), .reset(reset),
    .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx),
    .io_write_0_valid(io_write_0_valid), .io_write_0_bits_idx(io_write_0_bits_idx), .io_write_0_bits_way_en(io_write_0_bits_way_en), .io_write_0_bits_error_tl_denied(io_write_0_bits_error_tl_denied), .io_write_0_bits_error_tl_corrupt(io_write_0_bits_error_tl_corrupt),
    .io_resp_0_0_tl_denied(i_io_resp_0_0_tl_denied), .io_resp_0_0_tl_corrupt(i_io_resp_0_0_tl_corrupt), .io_resp_0_1_tl_denied(i_io_resp_0_1_tl_denied), .io_resp_0_1_tl_corrupt(i_io_resp_0_1_tl_corrupt), .io_resp_0_2_tl_denied(i_io_resp_0_2_tl_denied), .io_resp_0_2_tl_corrupt(i_io_resp_0_2_tl_corrupt), .io_resp_0_3_tl_denied(i_io_resp_0_3_tl_denied), .io_resp_0_3_tl_corrupt(i_io_resp_0_3_tl_corrupt), .io_resp_1_0_tl_denied(i_io_resp_1_0_tl_denied), .io_resp_1_0_tl_corrupt(i_io_resp_1_0_tl_corrupt), .io_resp_1_1_tl_denied(i_io_resp_1_1_tl_denied), .io_resp_1_1_tl_corrupt(i_io_resp_1_1_tl_corrupt), .io_resp_1_2_tl_denied(i_io_resp_1_2_tl_denied), .io_resp_1_2_tl_corrupt(i_io_resp_1_2_tl_corrupt), .io_resp_1_3_tl_denied(i_io_resp_1_3_tl_denied), .io_resp_1_3_tl_corrupt(i_io_resp_1_3_tl_corrupt), .io_resp_2_0_tl_denied(i_io_resp_2_0_tl_denied), .io_resp_2_0_tl_corrupt(i_io_resp_2_0_tl_corrupt), .io_resp_2_1_tl_denied(i_io_resp_2_1_tl_denied), .io_resp_2_1_tl_corrupt(i_io_resp_2_1_tl_corrupt), .io_resp_2_2_tl_denied(i_io_resp_2_2_tl_denied), .io_resp_2_2_tl_corrupt(i_io_resp_2_2_tl_corrupt), .io_resp_2_3_tl_denied(i_io_resp_2_3_tl_denied), .io_resp_2_3_tl_corrupt(i_io_resp_2_3_tl_corrupt), .io_resp_3_0_tl_denied(i_io_resp_3_0_tl_denied), .io_resp_3_0_tl_corrupt(i_io_resp_3_0_tl_corrupt), .io_resp_3_1_tl_denied(i_io_resp_3_1_tl_denied), .io_resp_3_1_tl_corrupt(i_io_resp_3_1_tl_corrupt), .io_resp_3_2_tl_denied(i_io_resp_3_2_tl_denied), .io_resp_3_2_tl_corrupt(i_io_resp_3_2_tl_corrupt), .io_resp_3_3_tl_denied(i_io_resp_3_3_tl_denied), .io_resp_3_3_tl_corrupt(i_io_resp_3_3_tl_corrupt)
  );

  task automatic do_check(int t);
    checks++;
    if (!$isunknown(g_io_resp_0_0_tl_denied) && (g_io_resp_0_0_tl_denied !== i_io_resp_0_0_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_0_tl_denied g=%b i=%b", t, g_io_resp_0_0_tl_denied, i_io_resp_0_0_tl_denied); end
    if (!$isunknown(g_io_resp_0_0_tl_corrupt) && (g_io_resp_0_0_tl_corrupt !== i_io_resp_0_0_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_0_tl_corrupt g=%b i=%b", t, g_io_resp_0_0_tl_corrupt, i_io_resp_0_0_tl_corrupt); end
    if (!$isunknown(g_io_resp_0_1_tl_denied) && (g_io_resp_0_1_tl_denied !== i_io_resp_0_1_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_1_tl_denied g=%b i=%b", t, g_io_resp_0_1_tl_denied, i_io_resp_0_1_tl_denied); end
    if (!$isunknown(g_io_resp_0_1_tl_corrupt) && (g_io_resp_0_1_tl_corrupt !== i_io_resp_0_1_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_1_tl_corrupt g=%b i=%b", t, g_io_resp_0_1_tl_corrupt, i_io_resp_0_1_tl_corrupt); end
    if (!$isunknown(g_io_resp_0_2_tl_denied) && (g_io_resp_0_2_tl_denied !== i_io_resp_0_2_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_2_tl_denied g=%b i=%b", t, g_io_resp_0_2_tl_denied, i_io_resp_0_2_tl_denied); end
    if (!$isunknown(g_io_resp_0_2_tl_corrupt) && (g_io_resp_0_2_tl_corrupt !== i_io_resp_0_2_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_2_tl_corrupt g=%b i=%b", t, g_io_resp_0_2_tl_corrupt, i_io_resp_0_2_tl_corrupt); end
    if (!$isunknown(g_io_resp_0_3_tl_denied) && (g_io_resp_0_3_tl_denied !== i_io_resp_0_3_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_3_tl_denied g=%b i=%b", t, g_io_resp_0_3_tl_denied, i_io_resp_0_3_tl_denied); end
    if (!$isunknown(g_io_resp_0_3_tl_corrupt) && (g_io_resp_0_3_tl_corrupt !== i_io_resp_0_3_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_0_3_tl_corrupt g=%b i=%b", t, g_io_resp_0_3_tl_corrupt, i_io_resp_0_3_tl_corrupt); end
    if (!$isunknown(g_io_resp_1_0_tl_denied) && (g_io_resp_1_0_tl_denied !== i_io_resp_1_0_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_0_tl_denied g=%b i=%b", t, g_io_resp_1_0_tl_denied, i_io_resp_1_0_tl_denied); end
    if (!$isunknown(g_io_resp_1_0_tl_corrupt) && (g_io_resp_1_0_tl_corrupt !== i_io_resp_1_0_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_0_tl_corrupt g=%b i=%b", t, g_io_resp_1_0_tl_corrupt, i_io_resp_1_0_tl_corrupt); end
    if (!$isunknown(g_io_resp_1_1_tl_denied) && (g_io_resp_1_1_tl_denied !== i_io_resp_1_1_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_1_tl_denied g=%b i=%b", t, g_io_resp_1_1_tl_denied, i_io_resp_1_1_tl_denied); end
    if (!$isunknown(g_io_resp_1_1_tl_corrupt) && (g_io_resp_1_1_tl_corrupt !== i_io_resp_1_1_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_1_tl_corrupt g=%b i=%b", t, g_io_resp_1_1_tl_corrupt, i_io_resp_1_1_tl_corrupt); end
    if (!$isunknown(g_io_resp_1_2_tl_denied) && (g_io_resp_1_2_tl_denied !== i_io_resp_1_2_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_2_tl_denied g=%b i=%b", t, g_io_resp_1_2_tl_denied, i_io_resp_1_2_tl_denied); end
    if (!$isunknown(g_io_resp_1_2_tl_corrupt) && (g_io_resp_1_2_tl_corrupt !== i_io_resp_1_2_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_2_tl_corrupt g=%b i=%b", t, g_io_resp_1_2_tl_corrupt, i_io_resp_1_2_tl_corrupt); end
    if (!$isunknown(g_io_resp_1_3_tl_denied) && (g_io_resp_1_3_tl_denied !== i_io_resp_1_3_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_3_tl_denied g=%b i=%b", t, g_io_resp_1_3_tl_denied, i_io_resp_1_3_tl_denied); end
    if (!$isunknown(g_io_resp_1_3_tl_corrupt) && (g_io_resp_1_3_tl_corrupt !== i_io_resp_1_3_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_1_3_tl_corrupt g=%b i=%b", t, g_io_resp_1_3_tl_corrupt, i_io_resp_1_3_tl_corrupt); end
    if (!$isunknown(g_io_resp_2_0_tl_denied) && (g_io_resp_2_0_tl_denied !== i_io_resp_2_0_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_0_tl_denied g=%b i=%b", t, g_io_resp_2_0_tl_denied, i_io_resp_2_0_tl_denied); end
    if (!$isunknown(g_io_resp_2_0_tl_corrupt) && (g_io_resp_2_0_tl_corrupt !== i_io_resp_2_0_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_0_tl_corrupt g=%b i=%b", t, g_io_resp_2_0_tl_corrupt, i_io_resp_2_0_tl_corrupt); end
    if (!$isunknown(g_io_resp_2_1_tl_denied) && (g_io_resp_2_1_tl_denied !== i_io_resp_2_1_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_1_tl_denied g=%b i=%b", t, g_io_resp_2_1_tl_denied, i_io_resp_2_1_tl_denied); end
    if (!$isunknown(g_io_resp_2_1_tl_corrupt) && (g_io_resp_2_1_tl_corrupt !== i_io_resp_2_1_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_1_tl_corrupt g=%b i=%b", t, g_io_resp_2_1_tl_corrupt, i_io_resp_2_1_tl_corrupt); end
    if (!$isunknown(g_io_resp_2_2_tl_denied) && (g_io_resp_2_2_tl_denied !== i_io_resp_2_2_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_2_tl_denied g=%b i=%b", t, g_io_resp_2_2_tl_denied, i_io_resp_2_2_tl_denied); end
    if (!$isunknown(g_io_resp_2_2_tl_corrupt) && (g_io_resp_2_2_tl_corrupt !== i_io_resp_2_2_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_2_tl_corrupt g=%b i=%b", t, g_io_resp_2_2_tl_corrupt, i_io_resp_2_2_tl_corrupt); end
    if (!$isunknown(g_io_resp_2_3_tl_denied) && (g_io_resp_2_3_tl_denied !== i_io_resp_2_3_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_3_tl_denied g=%b i=%b", t, g_io_resp_2_3_tl_denied, i_io_resp_2_3_tl_denied); end
    if (!$isunknown(g_io_resp_2_3_tl_corrupt) && (g_io_resp_2_3_tl_corrupt !== i_io_resp_2_3_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_2_3_tl_corrupt g=%b i=%b", t, g_io_resp_2_3_tl_corrupt, i_io_resp_2_3_tl_corrupt); end
    if (!$isunknown(g_io_resp_3_0_tl_denied) && (g_io_resp_3_0_tl_denied !== i_io_resp_3_0_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_0_tl_denied g=%b i=%b", t, g_io_resp_3_0_tl_denied, i_io_resp_3_0_tl_denied); end
    if (!$isunknown(g_io_resp_3_0_tl_corrupt) && (g_io_resp_3_0_tl_corrupt !== i_io_resp_3_0_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_0_tl_corrupt g=%b i=%b", t, g_io_resp_3_0_tl_corrupt, i_io_resp_3_0_tl_corrupt); end
    if (!$isunknown(g_io_resp_3_1_tl_denied) && (g_io_resp_3_1_tl_denied !== i_io_resp_3_1_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_1_tl_denied g=%b i=%b", t, g_io_resp_3_1_tl_denied, i_io_resp_3_1_tl_denied); end
    if (!$isunknown(g_io_resp_3_1_tl_corrupt) && (g_io_resp_3_1_tl_corrupt !== i_io_resp_3_1_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_1_tl_corrupt g=%b i=%b", t, g_io_resp_3_1_tl_corrupt, i_io_resp_3_1_tl_corrupt); end
    if (!$isunknown(g_io_resp_3_2_tl_denied) && (g_io_resp_3_2_tl_denied !== i_io_resp_3_2_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_2_tl_denied g=%b i=%b", t, g_io_resp_3_2_tl_denied, i_io_resp_3_2_tl_denied); end
    if (!$isunknown(g_io_resp_3_2_tl_corrupt) && (g_io_resp_3_2_tl_corrupt !== i_io_resp_3_2_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_2_tl_corrupt g=%b i=%b", t, g_io_resp_3_2_tl_corrupt, i_io_resp_3_2_tl_corrupt); end
    if (!$isunknown(g_io_resp_3_3_tl_denied) && (g_io_resp_3_3_tl_denied !== i_io_resp_3_3_tl_denied)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_3_tl_denied g=%b i=%b", t, g_io_resp_3_3_tl_denied, i_io_resp_3_3_tl_denied); end
    if (!$isunknown(g_io_resp_3_3_tl_corrupt) && (g_io_resp_3_3_tl_corrupt !== i_io_resp_3_3_tl_corrupt)) begin errors++;
      if (errors<=60) $display("vec %0d io_resp_3_3_tl_corrupt g=%b i=%b", t, g_io_resp_3_3_tl_corrupt, i_io_resp_3_3_tl_corrupt); end
  endtask

  // 随机激励：idx 大多压在 0..15 这个小窗口里，好让读写冲突/在途写转发频繁发生；
  // 少量全量程 0..255 覆盖寄存器堆的其余深度。
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
    io_write_0_valid = ($urandom_range(0,2) == 0);
    io_write_0_bits_idx = rand_idx();
    io_write_0_bits_way_en = 4'($urandom);
    io_write_0_bits_error_tl_denied  = 1'($urandom);
    io_write_0_bits_error_tl_corrupt = 1'($urandom);
  endtask

  // 暖机激励：写口开 way_en=4'hf，四个读口与写口同 idx，把全部无复位寄存器写实
  task automatic drive_warmup(int k);
    io_read_0_valid    = 1'b1;
    io_read_0_bits_idx = 8'(k);
    io_read_1_valid    = 1'b1;
    io_read_1_bits_idx = 8'(k);
    io_read_2_valid    = 1'b1;
    io_read_2_bits_idx = 8'(k);
    io_read_3_valid    = 1'b1;
    io_read_3_bits_idx = 8'(k);
    io_write_0_valid = 1'b1;
    io_write_0_bits_idx = 8'(k);
    io_write_0_bits_way_en = 4'hf;
    io_write_0_bits_error_tl_denied  = 1'b1;
    io_write_0_bits_error_tl_corrupt = 1'b1;
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NVEC)) ;
    reset = 1;
    io_read_0_valid = 0;  io_read_0_bits_idx = 0;
    io_read_1_valid = 0;  io_read_1_bits_idx = 0;
    io_read_2_valid = 0;  io_read_2_bits_idx = 0;
    io_read_3_valid = 0;  io_read_3_bits_idx = 0;
    io_write_0_valid = 0;  io_write_0_bits_idx = 0;  io_write_0_bits_way_en = 0;
    io_write_0_bits_error_tl_denied = 0;  io_write_0_bits_error_tl_corrupt = 0;
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
