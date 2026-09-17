// 自动生成：scripts/gen_zj_ut.py RegCacheTagTable —— 勿手改
// RegCacheTagTable 双例化逐拍比对：golden RegCacheTagTable vs 重写 RegCacheTagTable_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 200000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 200000;
  localparam int unsigned MIN_TOGGLED = 24;
  localparam int unsigned MIN_FIRES   = 0;
  localparam int unsigned N_OUT       = 24;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_readPorts_0_ren;
  logic [7:0] io_readPorts_0_tag;
  logic io_readPorts_1_ren;
  logic [7:0] io_readPorts_1_tag;
  logic io_readPorts_2_ren;
  logic [7:0] io_readPorts_2_tag;
  logic io_readPorts_3_ren;
  logic [7:0] io_readPorts_3_tag;
  logic io_readPorts_4_ren;
  logic [7:0] io_readPorts_4_tag;
  logic io_readPorts_5_ren;
  logic [7:0] io_readPorts_5_tag;
  logic io_readPorts_6_ren;
  logic [7:0] io_readPorts_6_tag;
  logic io_readPorts_7_ren;
  logic [7:0] io_readPorts_7_tag;
  logic io_readPorts_8_ren;
  logic [7:0] io_readPorts_8_tag;
  logic io_readPorts_9_ren;
  logic [7:0] io_readPorts_9_tag;
  logic io_readPorts_10_ren;
  logic [7:0] io_readPorts_10_tag;
  logic io_readPorts_11_ren;
  logic [7:0] io_readPorts_11_tag;
  logic io_wakeupFromIQ_6_valid;
  logic io_wakeupFromIQ_6_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_6_bits_pdest;
  logic [1:0] io_wakeupFromIQ_6_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_6_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_6_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_6_bits_rcDest;
  logic io_wakeupFromIQ_5_valid;
  logic io_wakeupFromIQ_5_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_5_bits_pdest;
  logic [1:0] io_wakeupFromIQ_5_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_5_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_5_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_5_bits_rcDest;
  logic io_wakeupFromIQ_4_valid;
  logic io_wakeupFromIQ_4_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_4_bits_pdest;
  logic [1:0] io_wakeupFromIQ_4_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_4_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_4_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_4_bits_rcDest;
  logic io_wakeupFromIQ_3_valid;
  logic io_wakeupFromIQ_3_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_3_bits_pdest;
  logic [1:0] io_wakeupFromIQ_3_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_3_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_3_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_3_bits_rcDest;
  logic io_wakeupFromIQ_2_valid;
  logic io_wakeupFromIQ_2_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_2_bits_pdest;
  logic [1:0] io_wakeupFromIQ_2_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_2_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_2_bits_loadDependency_2;
  logic [4:0] io_wakeupFromIQ_2_bits_rcDest;
  logic io_wakeupFromIQ_1_valid;
  logic io_wakeupFromIQ_1_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_1_bits_pdest;
  logic [1:0] io_wakeupFromIQ_1_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_1_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_1_bits_loadDependency_2;
  logic io_wakeupFromIQ_1_bits_is0Lat;
  logic [4:0] io_wakeupFromIQ_1_bits_rcDest;
  logic io_wakeupFromIQ_0_valid;
  logic io_wakeupFromIQ_0_bits_rfWen;
  logic [7:0] io_wakeupFromIQ_0_bits_pdest;
  logic [1:0] io_wakeupFromIQ_0_bits_loadDependency_0;
  logic [1:0] io_wakeupFromIQ_0_bits_loadDependency_1;
  logic [1:0] io_wakeupFromIQ_0_bits_loadDependency_2;
  logic io_wakeupFromIQ_0_bits_is0Lat;
  logic [4:0] io_wakeupFromIQ_0_bits_rcDest;
  logic io_allocPregs_0_valid;
  logic [7:0] io_allocPregs_0_bits;
  logic io_allocPregs_1_valid;
  logic [7:0] io_allocPregs_1_bits;
  logic io_allocPregs_2_valid;
  logic [7:0] io_allocPregs_2_bits;
  logic io_allocPregs_3_valid;
  logic [7:0] io_allocPregs_3_bits;
  logic io_allocPregs_4_valid;
  logic [7:0] io_allocPregs_4_bits;
  logic io_allocPregs_5_valid;
  logic [7:0] io_allocPregs_5_bits;
  logic io_og0Cancel_0;
  logic io_og0Cancel_2;
  logic io_og0Cancel_4;
  logic io_og0Cancel_6;
  logic io_ldCancel_0_ld2Cancel;
  logic io_ldCancel_1_ld2Cancel;
  logic io_ldCancel_2_ld2Cancel;

  wire g_io_readPorts_0_valid;
  wire i_io_readPorts_0_valid;
  wire [4:0] g_io_readPorts_0_addr;
  wire [4:0] i_io_readPorts_0_addr;
  wire g_io_readPorts_1_valid;
  wire i_io_readPorts_1_valid;
  wire [4:0] g_io_readPorts_1_addr;
  wire [4:0] i_io_readPorts_1_addr;
  wire g_io_readPorts_2_valid;
  wire i_io_readPorts_2_valid;
  wire [4:0] g_io_readPorts_2_addr;
  wire [4:0] i_io_readPorts_2_addr;
  wire g_io_readPorts_3_valid;
  wire i_io_readPorts_3_valid;
  wire [4:0] g_io_readPorts_3_addr;
  wire [4:0] i_io_readPorts_3_addr;
  wire g_io_readPorts_4_valid;
  wire i_io_readPorts_4_valid;
  wire [4:0] g_io_readPorts_4_addr;
  wire [4:0] i_io_readPorts_4_addr;
  wire g_io_readPorts_5_valid;
  wire i_io_readPorts_5_valid;
  wire [4:0] g_io_readPorts_5_addr;
  wire [4:0] i_io_readPorts_5_addr;
  wire g_io_readPorts_6_valid;
  wire i_io_readPorts_6_valid;
  wire [4:0] g_io_readPorts_6_addr;
  wire [4:0] i_io_readPorts_6_addr;
  wire g_io_readPorts_7_valid;
  wire i_io_readPorts_7_valid;
  wire [4:0] g_io_readPorts_7_addr;
  wire [4:0] i_io_readPorts_7_addr;
  wire g_io_readPorts_8_valid;
  wire i_io_readPorts_8_valid;
  wire [4:0] g_io_readPorts_8_addr;
  wire [4:0] i_io_readPorts_8_addr;
  wire g_io_readPorts_9_valid;
  wire i_io_readPorts_9_valid;
  wire [4:0] g_io_readPorts_9_addr;
  wire [4:0] i_io_readPorts_9_addr;
  wire g_io_readPorts_10_valid;
  wire i_io_readPorts_10_valid;
  wire [4:0] g_io_readPorts_10_addr;
  wire [4:0] i_io_readPorts_10_addr;
  wire g_io_readPorts_11_valid;
  wire i_io_readPorts_11_valid;
  wire [4:0] g_io_readPorts_11_addr;
  wire [4:0] i_io_readPorts_11_addr;

  logic p_io_readPorts_0_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_0_valid;
  logic [4:0] p_io_readPorts_0_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_0_addr;
  logic p_io_readPorts_1_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_1_valid;
  logic [4:0] p_io_readPorts_1_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_1_addr;
  logic p_io_readPorts_2_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_2_valid;
  logic [4:0] p_io_readPorts_2_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_2_addr;
  logic p_io_readPorts_3_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_3_valid;
  logic [4:0] p_io_readPorts_3_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_3_addr;
  logic p_io_readPorts_4_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_4_valid;
  logic [4:0] p_io_readPorts_4_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_4_addr;
  logic p_io_readPorts_5_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_5_valid;
  logic [4:0] p_io_readPorts_5_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_5_addr;
  logic p_io_readPorts_6_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_6_valid;
  logic [4:0] p_io_readPorts_6_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_6_addr;
  logic p_io_readPorts_7_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_7_valid;
  logic [4:0] p_io_readPorts_7_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_7_addr;
  logic p_io_readPorts_8_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_8_valid;
  logic [4:0] p_io_readPorts_8_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_8_addr;
  logic p_io_readPorts_9_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_9_valid;
  logic [4:0] p_io_readPorts_9_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_9_addr;
  logic p_io_readPorts_10_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_10_valid;
  logic [4:0] p_io_readPorts_10_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_10_addr;
  logic p_io_readPorts_11_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_11_valid;
  logic [4:0] p_io_readPorts_11_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_11_addr;

  RegCacheTagTable u_g (
    .clock(clock),
    .reset(reset),
    .io_readPorts_0_ren(io_readPorts_0_ren),
    .io_readPorts_0_tag(io_readPorts_0_tag),
    .io_readPorts_0_valid(g_io_readPorts_0_valid),
    .io_readPorts_0_addr(g_io_readPorts_0_addr),
    .io_readPorts_1_ren(io_readPorts_1_ren),
    .io_readPorts_1_tag(io_readPorts_1_tag),
    .io_readPorts_1_valid(g_io_readPorts_1_valid),
    .io_readPorts_1_addr(g_io_readPorts_1_addr),
    .io_readPorts_2_ren(io_readPorts_2_ren),
    .io_readPorts_2_tag(io_readPorts_2_tag),
    .io_readPorts_2_valid(g_io_readPorts_2_valid),
    .io_readPorts_2_addr(g_io_readPorts_2_addr),
    .io_readPorts_3_ren(io_readPorts_3_ren),
    .io_readPorts_3_tag(io_readPorts_3_tag),
    .io_readPorts_3_valid(g_io_readPorts_3_valid),
    .io_readPorts_3_addr(g_io_readPorts_3_addr),
    .io_readPorts_4_ren(io_readPorts_4_ren),
    .io_readPorts_4_tag(io_readPorts_4_tag),
    .io_readPorts_4_valid(g_io_readPorts_4_valid),
    .io_readPorts_4_addr(g_io_readPorts_4_addr),
    .io_readPorts_5_ren(io_readPorts_5_ren),
    .io_readPorts_5_tag(io_readPorts_5_tag),
    .io_readPorts_5_valid(g_io_readPorts_5_valid),
    .io_readPorts_5_addr(g_io_readPorts_5_addr),
    .io_readPorts_6_ren(io_readPorts_6_ren),
    .io_readPorts_6_tag(io_readPorts_6_tag),
    .io_readPorts_6_valid(g_io_readPorts_6_valid),
    .io_readPorts_6_addr(g_io_readPorts_6_addr),
    .io_readPorts_7_ren(io_readPorts_7_ren),
    .io_readPorts_7_tag(io_readPorts_7_tag),
    .io_readPorts_7_valid(g_io_readPorts_7_valid),
    .io_readPorts_7_addr(g_io_readPorts_7_addr),
    .io_readPorts_8_ren(io_readPorts_8_ren),
    .io_readPorts_8_tag(io_readPorts_8_tag),
    .io_readPorts_8_valid(g_io_readPorts_8_valid),
    .io_readPorts_8_addr(g_io_readPorts_8_addr),
    .io_readPorts_9_ren(io_readPorts_9_ren),
    .io_readPorts_9_tag(io_readPorts_9_tag),
    .io_readPorts_9_valid(g_io_readPorts_9_valid),
    .io_readPorts_9_addr(g_io_readPorts_9_addr),
    .io_readPorts_10_ren(io_readPorts_10_ren),
    .io_readPorts_10_tag(io_readPorts_10_tag),
    .io_readPorts_10_valid(g_io_readPorts_10_valid),
    .io_readPorts_10_addr(g_io_readPorts_10_addr),
    .io_readPorts_11_ren(io_readPorts_11_ren),
    .io_readPorts_11_tag(io_readPorts_11_tag),
    .io_readPorts_11_valid(g_io_readPorts_11_valid),
    .io_readPorts_11_addr(g_io_readPorts_11_addr),
    .io_wakeupFromIQ_6_valid(io_wakeupFromIQ_6_valid),
    .io_wakeupFromIQ_6_bits_rfWen(io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeupFromIQ_6_bits_pdest(io_wakeupFromIQ_6_bits_pdest),
    .io_wakeupFromIQ_6_bits_loadDependency_0(io_wakeupFromIQ_6_bits_loadDependency_0),
    .io_wakeupFromIQ_6_bits_loadDependency_1(io_wakeupFromIQ_6_bits_loadDependency_1),
    .io_wakeupFromIQ_6_bits_loadDependency_2(io_wakeupFromIQ_6_bits_loadDependency_2),
    .io_wakeupFromIQ_6_bits_rcDest(io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeupFromIQ_5_valid(io_wakeupFromIQ_5_valid),
    .io_wakeupFromIQ_5_bits_rfWen(io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeupFromIQ_5_bits_pdest(io_wakeupFromIQ_5_bits_pdest),
    .io_wakeupFromIQ_5_bits_loadDependency_0(io_wakeupFromIQ_5_bits_loadDependency_0),
    .io_wakeupFromIQ_5_bits_loadDependency_1(io_wakeupFromIQ_5_bits_loadDependency_1),
    .io_wakeupFromIQ_5_bits_loadDependency_2(io_wakeupFromIQ_5_bits_loadDependency_2),
    .io_wakeupFromIQ_5_bits_rcDest(io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeupFromIQ_4_valid(io_wakeupFromIQ_4_valid),
    .io_wakeupFromIQ_4_bits_rfWen(io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeupFromIQ_4_bits_pdest(io_wakeupFromIQ_4_bits_pdest),
    .io_wakeupFromIQ_4_bits_loadDependency_0(io_wakeupFromIQ_4_bits_loadDependency_0),
    .io_wakeupFromIQ_4_bits_loadDependency_1(io_wakeupFromIQ_4_bits_loadDependency_1),
    .io_wakeupFromIQ_4_bits_loadDependency_2(io_wakeupFromIQ_4_bits_loadDependency_2),
    .io_wakeupFromIQ_4_bits_rcDest(io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeupFromIQ_3_valid(io_wakeupFromIQ_3_valid),
    .io_wakeupFromIQ_3_bits_rfWen(io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeupFromIQ_3_bits_pdest(io_wakeupFromIQ_3_bits_pdest),
    .io_wakeupFromIQ_3_bits_loadDependency_0(io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeupFromIQ_3_bits_loadDependency_1(io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeupFromIQ_3_bits_loadDependency_2(io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeupFromIQ_3_bits_rcDest(io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeupFromIQ_2_valid(io_wakeupFromIQ_2_valid),
    .io_wakeupFromIQ_2_bits_rfWen(io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeupFromIQ_2_bits_pdest(io_wakeupFromIQ_2_bits_pdest),
    .io_wakeupFromIQ_2_bits_loadDependency_0(io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeupFromIQ_2_bits_loadDependency_1(io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeupFromIQ_2_bits_loadDependency_2(io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeupFromIQ_2_bits_rcDest(io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeupFromIQ_1_valid(io_wakeupFromIQ_1_valid),
    .io_wakeupFromIQ_1_bits_rfWen(io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeupFromIQ_1_bits_pdest(io_wakeupFromIQ_1_bits_pdest),
    .io_wakeupFromIQ_1_bits_loadDependency_0(io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeupFromIQ_1_bits_loadDependency_1(io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeupFromIQ_1_bits_loadDependency_2(io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeupFromIQ_1_bits_is0Lat(io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeupFromIQ_1_bits_rcDest(io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeupFromIQ_0_valid(io_wakeupFromIQ_0_valid),
    .io_wakeupFromIQ_0_bits_rfWen(io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeupFromIQ_0_bits_pdest(io_wakeupFromIQ_0_bits_pdest),
    .io_wakeupFromIQ_0_bits_loadDependency_0(io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeupFromIQ_0_bits_loadDependency_1(io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeupFromIQ_0_bits_loadDependency_2(io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeupFromIQ_0_bits_is0Lat(io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeupFromIQ_0_bits_rcDest(io_wakeupFromIQ_0_bits_rcDest),
    .io_allocPregs_0_valid(io_allocPregs_0_valid),
    .io_allocPregs_0_bits(io_allocPregs_0_bits),
    .io_allocPregs_1_valid(io_allocPregs_1_valid),
    .io_allocPregs_1_bits(io_allocPregs_1_bits),
    .io_allocPregs_2_valid(io_allocPregs_2_valid),
    .io_allocPregs_2_bits(io_allocPregs_2_bits),
    .io_allocPregs_3_valid(io_allocPregs_3_valid),
    .io_allocPregs_3_bits(io_allocPregs_3_bits),
    .io_allocPregs_4_valid(io_allocPregs_4_valid),
    .io_allocPregs_4_bits(io_allocPregs_4_bits),
    .io_allocPregs_5_valid(io_allocPregs_5_valid),
    .io_allocPregs_5_bits(io_allocPregs_5_bits),
    .io_og0Cancel_0(io_og0Cancel_0),
    .io_og0Cancel_2(io_og0Cancel_2),
    .io_og0Cancel_4(io_og0Cancel_4),
    .io_og0Cancel_6(io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel(io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel(io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel(io_ldCancel_2_ld2Cancel)
  );
  RegCacheTagTable_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_readPorts_0_ren(io_readPorts_0_ren),
    .io_readPorts_0_tag(io_readPorts_0_tag),
    .io_readPorts_0_valid(i_io_readPorts_0_valid),
    .io_readPorts_0_addr(i_io_readPorts_0_addr),
    .io_readPorts_1_ren(io_readPorts_1_ren),
    .io_readPorts_1_tag(io_readPorts_1_tag),
    .io_readPorts_1_valid(i_io_readPorts_1_valid),
    .io_readPorts_1_addr(i_io_readPorts_1_addr),
    .io_readPorts_2_ren(io_readPorts_2_ren),
    .io_readPorts_2_tag(io_readPorts_2_tag),
    .io_readPorts_2_valid(i_io_readPorts_2_valid),
    .io_readPorts_2_addr(i_io_readPorts_2_addr),
    .io_readPorts_3_ren(io_readPorts_3_ren),
    .io_readPorts_3_tag(io_readPorts_3_tag),
    .io_readPorts_3_valid(i_io_readPorts_3_valid),
    .io_readPorts_3_addr(i_io_readPorts_3_addr),
    .io_readPorts_4_ren(io_readPorts_4_ren),
    .io_readPorts_4_tag(io_readPorts_4_tag),
    .io_readPorts_4_valid(i_io_readPorts_4_valid),
    .io_readPorts_4_addr(i_io_readPorts_4_addr),
    .io_readPorts_5_ren(io_readPorts_5_ren),
    .io_readPorts_5_tag(io_readPorts_5_tag),
    .io_readPorts_5_valid(i_io_readPorts_5_valid),
    .io_readPorts_5_addr(i_io_readPorts_5_addr),
    .io_readPorts_6_ren(io_readPorts_6_ren),
    .io_readPorts_6_tag(io_readPorts_6_tag),
    .io_readPorts_6_valid(i_io_readPorts_6_valid),
    .io_readPorts_6_addr(i_io_readPorts_6_addr),
    .io_readPorts_7_ren(io_readPorts_7_ren),
    .io_readPorts_7_tag(io_readPorts_7_tag),
    .io_readPorts_7_valid(i_io_readPorts_7_valid),
    .io_readPorts_7_addr(i_io_readPorts_7_addr),
    .io_readPorts_8_ren(io_readPorts_8_ren),
    .io_readPorts_8_tag(io_readPorts_8_tag),
    .io_readPorts_8_valid(i_io_readPorts_8_valid),
    .io_readPorts_8_addr(i_io_readPorts_8_addr),
    .io_readPorts_9_ren(io_readPorts_9_ren),
    .io_readPorts_9_tag(io_readPorts_9_tag),
    .io_readPorts_9_valid(i_io_readPorts_9_valid),
    .io_readPorts_9_addr(i_io_readPorts_9_addr),
    .io_readPorts_10_ren(io_readPorts_10_ren),
    .io_readPorts_10_tag(io_readPorts_10_tag),
    .io_readPorts_10_valid(i_io_readPorts_10_valid),
    .io_readPorts_10_addr(i_io_readPorts_10_addr),
    .io_readPorts_11_ren(io_readPorts_11_ren),
    .io_readPorts_11_tag(io_readPorts_11_tag),
    .io_readPorts_11_valid(i_io_readPorts_11_valid),
    .io_readPorts_11_addr(i_io_readPorts_11_addr),
    .io_wakeupFromIQ_6_valid(io_wakeupFromIQ_6_valid),
    .io_wakeupFromIQ_6_bits_rfWen(io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeupFromIQ_6_bits_pdest(io_wakeupFromIQ_6_bits_pdest),
    .io_wakeupFromIQ_6_bits_loadDependency_0(io_wakeupFromIQ_6_bits_loadDependency_0),
    .io_wakeupFromIQ_6_bits_loadDependency_1(io_wakeupFromIQ_6_bits_loadDependency_1),
    .io_wakeupFromIQ_6_bits_loadDependency_2(io_wakeupFromIQ_6_bits_loadDependency_2),
    .io_wakeupFromIQ_6_bits_rcDest(io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeupFromIQ_5_valid(io_wakeupFromIQ_5_valid),
    .io_wakeupFromIQ_5_bits_rfWen(io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeupFromIQ_5_bits_pdest(io_wakeupFromIQ_5_bits_pdest),
    .io_wakeupFromIQ_5_bits_loadDependency_0(io_wakeupFromIQ_5_bits_loadDependency_0),
    .io_wakeupFromIQ_5_bits_loadDependency_1(io_wakeupFromIQ_5_bits_loadDependency_1),
    .io_wakeupFromIQ_5_bits_loadDependency_2(io_wakeupFromIQ_5_bits_loadDependency_2),
    .io_wakeupFromIQ_5_bits_rcDest(io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeupFromIQ_4_valid(io_wakeupFromIQ_4_valid),
    .io_wakeupFromIQ_4_bits_rfWen(io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeupFromIQ_4_bits_pdest(io_wakeupFromIQ_4_bits_pdest),
    .io_wakeupFromIQ_4_bits_loadDependency_0(io_wakeupFromIQ_4_bits_loadDependency_0),
    .io_wakeupFromIQ_4_bits_loadDependency_1(io_wakeupFromIQ_4_bits_loadDependency_1),
    .io_wakeupFromIQ_4_bits_loadDependency_2(io_wakeupFromIQ_4_bits_loadDependency_2),
    .io_wakeupFromIQ_4_bits_rcDest(io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeupFromIQ_3_valid(io_wakeupFromIQ_3_valid),
    .io_wakeupFromIQ_3_bits_rfWen(io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeupFromIQ_3_bits_pdest(io_wakeupFromIQ_3_bits_pdest),
    .io_wakeupFromIQ_3_bits_loadDependency_0(io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeupFromIQ_3_bits_loadDependency_1(io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeupFromIQ_3_bits_loadDependency_2(io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeupFromIQ_3_bits_rcDest(io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeupFromIQ_2_valid(io_wakeupFromIQ_2_valid),
    .io_wakeupFromIQ_2_bits_rfWen(io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeupFromIQ_2_bits_pdest(io_wakeupFromIQ_2_bits_pdest),
    .io_wakeupFromIQ_2_bits_loadDependency_0(io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeupFromIQ_2_bits_loadDependency_1(io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeupFromIQ_2_bits_loadDependency_2(io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeupFromIQ_2_bits_rcDest(io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeupFromIQ_1_valid(io_wakeupFromIQ_1_valid),
    .io_wakeupFromIQ_1_bits_rfWen(io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeupFromIQ_1_bits_pdest(io_wakeupFromIQ_1_bits_pdest),
    .io_wakeupFromIQ_1_bits_loadDependency_0(io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeupFromIQ_1_bits_loadDependency_1(io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeupFromIQ_1_bits_loadDependency_2(io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeupFromIQ_1_bits_is0Lat(io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeupFromIQ_1_bits_rcDest(io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeupFromIQ_0_valid(io_wakeupFromIQ_0_valid),
    .io_wakeupFromIQ_0_bits_rfWen(io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeupFromIQ_0_bits_pdest(io_wakeupFromIQ_0_bits_pdest),
    .io_wakeupFromIQ_0_bits_loadDependency_0(io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeupFromIQ_0_bits_loadDependency_1(io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeupFromIQ_0_bits_loadDependency_2(io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeupFromIQ_0_bits_is0Lat(io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeupFromIQ_0_bits_rcDest(io_wakeupFromIQ_0_bits_rcDest),
    .io_allocPregs_0_valid(io_allocPregs_0_valid),
    .io_allocPregs_0_bits(io_allocPregs_0_bits),
    .io_allocPregs_1_valid(io_allocPregs_1_valid),
    .io_allocPregs_1_bits(io_allocPregs_1_bits),
    .io_allocPregs_2_valid(io_allocPregs_2_valid),
    .io_allocPregs_2_bits(io_allocPregs_2_bits),
    .io_allocPregs_3_valid(io_allocPregs_3_valid),
    .io_allocPregs_3_bits(io_allocPregs_3_bits),
    .io_allocPregs_4_valid(io_allocPregs_4_valid),
    .io_allocPregs_4_bits(io_allocPregs_4_bits),
    .io_allocPregs_5_valid(io_allocPregs_5_valid),
    .io_allocPregs_5_bits(io_allocPregs_5_bits),
    .io_og0Cancel_0(io_og0Cancel_0),
    .io_og0Cancel_2(io_og0Cancel_2),
    .io_og0Cancel_4(io_og0Cancel_4),
    .io_og0Cancel_6(io_og0Cancel_6),
    .io_ldCancel_0_ld2Cancel(io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel(io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld2Cancel(io_ldCancel_2_ld2Cancel)
  );

  task automatic drive_random();
    io_readPorts_0_ren = $urandom % 2;
    io_readPorts_0_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_1_ren = $urandom % 2;
    io_readPorts_1_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_2_ren = $urandom % 2;
    io_readPorts_2_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_3_ren = $urandom % 2;
    io_readPorts_3_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_4_ren = $urandom % 2;
    io_readPorts_4_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_5_ren = $urandom % 2;
    io_readPorts_5_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_6_ren = $urandom % 2;
    io_readPorts_6_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_7_ren = $urandom % 2;
    io_readPorts_7_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_8_ren = $urandom % 2;
    io_readPorts_8_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_9_ren = $urandom % 2;
    io_readPorts_9_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_10_ren = $urandom % 2;
    io_readPorts_10_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_11_ren = $urandom % 2;
    io_readPorts_11_tag = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_6_valid = $urandom % 2;
    io_wakeupFromIQ_6_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_6_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_6_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_6_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_6_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_6_bits_rcDest = rnd(5);
    io_wakeupFromIQ_5_valid = $urandom % 2;
    io_wakeupFromIQ_5_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_5_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_5_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_5_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_5_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_5_bits_rcDest = rnd(5);
    io_wakeupFromIQ_4_valid = $urandom % 2;
    io_wakeupFromIQ_4_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_4_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_4_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_4_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_4_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_4_bits_rcDest = rnd(5);
    io_wakeupFromIQ_3_valid = $urandom % 2;
    io_wakeupFromIQ_3_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_3_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_3_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_3_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_3_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_3_bits_rcDest = rnd(5);
    io_wakeupFromIQ_2_valid = $urandom % 2;
    io_wakeupFromIQ_2_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_2_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_2_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_2_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_2_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_2_bits_rcDest = rnd(5);
    io_wakeupFromIQ_1_valid = $urandom % 2;
    io_wakeupFromIQ_1_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_1_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_1_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_1_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_1_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_1_bits_is0Lat = $urandom % 2;
    io_wakeupFromIQ_1_bits_rcDest = rnd(5);
    io_wakeupFromIQ_0_valid = $urandom % 2;
    io_wakeupFromIQ_0_bits_rfWen = $urandom % 2;
    io_wakeupFromIQ_0_bits_pdest = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_wakeupFromIQ_0_bits_loadDependency_0 = rnd(2);
    io_wakeupFromIQ_0_bits_loadDependency_1 = rnd(2);
    io_wakeupFromIQ_0_bits_loadDependency_2 = rnd(2);
    io_wakeupFromIQ_0_bits_is0Lat = $urandom % 2;
    io_wakeupFromIQ_0_bits_rcDest = rnd(5);
    io_allocPregs_0_valid = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_0_bits = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_1_valid = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_1_bits = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_2_valid = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_2_bits = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_3_valid = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_3_bits = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_4_valid = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_4_bits = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_5_valid = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_allocPregs_5_bits = $urandom_range(0, $urandom % 16);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_og0Cancel_0 = $urandom_range(0, ($urandom % 4) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_og0Cancel_2 = $urandom_range(0, ($urandom % 4) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_og0Cancel_4 = $urandom_range(0, ($urandom % 4) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_og0Cancel_6 = $urandom_range(0, ($urandom % 4) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_ldCancel_0_ld2Cancel = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_ldCancel_1_ld2Cancel = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_ldCancel_2_ld2Cancel = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_readPorts_0_valid)) begin
      checks++;
      if (g_io_readPorts_0_valid !== i_io_readPorts_0_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_0_valid g=%0h i=%0h", $time, g_io_readPorts_0_valid, i_io_readPorts_0_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_0_addr)) begin
      checks++;
      if (g_io_readPorts_0_addr !== i_io_readPorts_0_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_0_addr g=%0h i=%0h", $time, g_io_readPorts_0_addr, i_io_readPorts_0_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_1_valid)) begin
      checks++;
      if (g_io_readPorts_1_valid !== i_io_readPorts_1_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_1_valid g=%0h i=%0h", $time, g_io_readPorts_1_valid, i_io_readPorts_1_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_1_addr)) begin
      checks++;
      if (g_io_readPorts_1_addr !== i_io_readPorts_1_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_1_addr g=%0h i=%0h", $time, g_io_readPorts_1_addr, i_io_readPorts_1_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_2_valid)) begin
      checks++;
      if (g_io_readPorts_2_valid !== i_io_readPorts_2_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_2_valid g=%0h i=%0h", $time, g_io_readPorts_2_valid, i_io_readPorts_2_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_2_addr)) begin
      checks++;
      if (g_io_readPorts_2_addr !== i_io_readPorts_2_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_2_addr g=%0h i=%0h", $time, g_io_readPorts_2_addr, i_io_readPorts_2_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_3_valid)) begin
      checks++;
      if (g_io_readPorts_3_valid !== i_io_readPorts_3_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_3_valid g=%0h i=%0h", $time, g_io_readPorts_3_valid, i_io_readPorts_3_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_3_addr)) begin
      checks++;
      if (g_io_readPorts_3_addr !== i_io_readPorts_3_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_3_addr g=%0h i=%0h", $time, g_io_readPorts_3_addr, i_io_readPorts_3_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_4_valid)) begin
      checks++;
      if (g_io_readPorts_4_valid !== i_io_readPorts_4_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_4_valid g=%0h i=%0h", $time, g_io_readPorts_4_valid, i_io_readPorts_4_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_4_addr)) begin
      checks++;
      if (g_io_readPorts_4_addr !== i_io_readPorts_4_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_4_addr g=%0h i=%0h", $time, g_io_readPorts_4_addr, i_io_readPorts_4_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_5_valid)) begin
      checks++;
      if (g_io_readPorts_5_valid !== i_io_readPorts_5_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_5_valid g=%0h i=%0h", $time, g_io_readPorts_5_valid, i_io_readPorts_5_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_5_addr)) begin
      checks++;
      if (g_io_readPorts_5_addr !== i_io_readPorts_5_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_5_addr g=%0h i=%0h", $time, g_io_readPorts_5_addr, i_io_readPorts_5_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_6_valid)) begin
      checks++;
      if (g_io_readPorts_6_valid !== i_io_readPorts_6_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_6_valid g=%0h i=%0h", $time, g_io_readPorts_6_valid, i_io_readPorts_6_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_6_addr)) begin
      checks++;
      if (g_io_readPorts_6_addr !== i_io_readPorts_6_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_6_addr g=%0h i=%0h", $time, g_io_readPorts_6_addr, i_io_readPorts_6_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_7_valid)) begin
      checks++;
      if (g_io_readPorts_7_valid !== i_io_readPorts_7_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_7_valid g=%0h i=%0h", $time, g_io_readPorts_7_valid, i_io_readPorts_7_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_7_addr)) begin
      checks++;
      if (g_io_readPorts_7_addr !== i_io_readPorts_7_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_7_addr g=%0h i=%0h", $time, g_io_readPorts_7_addr, i_io_readPorts_7_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_8_valid)) begin
      checks++;
      if (g_io_readPorts_8_valid !== i_io_readPorts_8_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_8_valid g=%0h i=%0h", $time, g_io_readPorts_8_valid, i_io_readPorts_8_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_8_addr)) begin
      checks++;
      if (g_io_readPorts_8_addr !== i_io_readPorts_8_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_8_addr g=%0h i=%0h", $time, g_io_readPorts_8_addr, i_io_readPorts_8_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_9_valid)) begin
      checks++;
      if (g_io_readPorts_9_valid !== i_io_readPorts_9_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_9_valid g=%0h i=%0h", $time, g_io_readPorts_9_valid, i_io_readPorts_9_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_9_addr)) begin
      checks++;
      if (g_io_readPorts_9_addr !== i_io_readPorts_9_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_9_addr g=%0h i=%0h", $time, g_io_readPorts_9_addr, i_io_readPorts_9_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_10_valid)) begin
      checks++;
      if (g_io_readPorts_10_valid !== i_io_readPorts_10_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_10_valid g=%0h i=%0h", $time, g_io_readPorts_10_valid, i_io_readPorts_10_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_10_addr)) begin
      checks++;
      if (g_io_readPorts_10_addr !== i_io_readPorts_10_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_10_addr g=%0h i=%0h", $time, g_io_readPorts_10_addr, i_io_readPorts_10_addr);
      end
    end
    if (!$isunknown(g_io_readPorts_11_valid)) begin
      checks++;
      if (g_io_readPorts_11_valid !== i_io_readPorts_11_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_11_valid g=%0h i=%0h", $time, g_io_readPorts_11_valid, i_io_readPorts_11_valid);
      end
    end
    if (!$isunknown(g_io_readPorts_11_addr)) begin
      checks++;
      if (g_io_readPorts_11_addr !== i_io_readPorts_11_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_11_addr g=%0h i=%0h", $time, g_io_readPorts_11_addr, i_io_readPorts_11_addr);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_readPorts_0_valid !== p_io_readPorts_0_valid) tog_io_readPorts_0_valid = 1'b1;
    p_io_readPorts_0_valid = g_io_readPorts_0_valid;
    if (g_io_readPorts_0_addr !== p_io_readPorts_0_addr) tog_io_readPorts_0_addr = 1'b1;
    p_io_readPorts_0_addr = g_io_readPorts_0_addr;
    if (g_io_readPorts_1_valid !== p_io_readPorts_1_valid) tog_io_readPorts_1_valid = 1'b1;
    p_io_readPorts_1_valid = g_io_readPorts_1_valid;
    if (g_io_readPorts_1_addr !== p_io_readPorts_1_addr) tog_io_readPorts_1_addr = 1'b1;
    p_io_readPorts_1_addr = g_io_readPorts_1_addr;
    if (g_io_readPorts_2_valid !== p_io_readPorts_2_valid) tog_io_readPorts_2_valid = 1'b1;
    p_io_readPorts_2_valid = g_io_readPorts_2_valid;
    if (g_io_readPorts_2_addr !== p_io_readPorts_2_addr) tog_io_readPorts_2_addr = 1'b1;
    p_io_readPorts_2_addr = g_io_readPorts_2_addr;
    if (g_io_readPorts_3_valid !== p_io_readPorts_3_valid) tog_io_readPorts_3_valid = 1'b1;
    p_io_readPorts_3_valid = g_io_readPorts_3_valid;
    if (g_io_readPorts_3_addr !== p_io_readPorts_3_addr) tog_io_readPorts_3_addr = 1'b1;
    p_io_readPorts_3_addr = g_io_readPorts_3_addr;
    if (g_io_readPorts_4_valid !== p_io_readPorts_4_valid) tog_io_readPorts_4_valid = 1'b1;
    p_io_readPorts_4_valid = g_io_readPorts_4_valid;
    if (g_io_readPorts_4_addr !== p_io_readPorts_4_addr) tog_io_readPorts_4_addr = 1'b1;
    p_io_readPorts_4_addr = g_io_readPorts_4_addr;
    if (g_io_readPorts_5_valid !== p_io_readPorts_5_valid) tog_io_readPorts_5_valid = 1'b1;
    p_io_readPorts_5_valid = g_io_readPorts_5_valid;
    if (g_io_readPorts_5_addr !== p_io_readPorts_5_addr) tog_io_readPorts_5_addr = 1'b1;
    p_io_readPorts_5_addr = g_io_readPorts_5_addr;
    if (g_io_readPorts_6_valid !== p_io_readPorts_6_valid) tog_io_readPorts_6_valid = 1'b1;
    p_io_readPorts_6_valid = g_io_readPorts_6_valid;
    if (g_io_readPorts_6_addr !== p_io_readPorts_6_addr) tog_io_readPorts_6_addr = 1'b1;
    p_io_readPorts_6_addr = g_io_readPorts_6_addr;
    if (g_io_readPorts_7_valid !== p_io_readPorts_7_valid) tog_io_readPorts_7_valid = 1'b1;
    p_io_readPorts_7_valid = g_io_readPorts_7_valid;
    if (g_io_readPorts_7_addr !== p_io_readPorts_7_addr) tog_io_readPorts_7_addr = 1'b1;
    p_io_readPorts_7_addr = g_io_readPorts_7_addr;
    if (g_io_readPorts_8_valid !== p_io_readPorts_8_valid) tog_io_readPorts_8_valid = 1'b1;
    p_io_readPorts_8_valid = g_io_readPorts_8_valid;
    if (g_io_readPorts_8_addr !== p_io_readPorts_8_addr) tog_io_readPorts_8_addr = 1'b1;
    p_io_readPorts_8_addr = g_io_readPorts_8_addr;
    if (g_io_readPorts_9_valid !== p_io_readPorts_9_valid) tog_io_readPorts_9_valid = 1'b1;
    p_io_readPorts_9_valid = g_io_readPorts_9_valid;
    if (g_io_readPorts_9_addr !== p_io_readPorts_9_addr) tog_io_readPorts_9_addr = 1'b1;
    p_io_readPorts_9_addr = g_io_readPorts_9_addr;
    if (g_io_readPorts_10_valid !== p_io_readPorts_10_valid) tog_io_readPorts_10_valid = 1'b1;
    p_io_readPorts_10_valid = g_io_readPorts_10_valid;
    if (g_io_readPorts_10_addr !== p_io_readPorts_10_addr) tog_io_readPorts_10_addr = 1'b1;
    p_io_readPorts_10_addr = g_io_readPorts_10_addr;
    if (g_io_readPorts_11_valid !== p_io_readPorts_11_valid) tog_io_readPorts_11_valid = 1'b1;
    p_io_readPorts_11_valid = g_io_readPorts_11_valid;
    if (g_io_readPorts_11_addr !== p_io_readPorts_11_addr) tog_io_readPorts_11_addr = 1'b1;
    p_io_readPorts_11_addr = g_io_readPorts_11_addr;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_readPorts_0_ren = '0;
    io_readPorts_0_tag = '0;
    io_readPorts_1_ren = '0;
    io_readPorts_1_tag = '0;
    io_readPorts_2_ren = '0;
    io_readPorts_2_tag = '0;
    io_readPorts_3_ren = '0;
    io_readPorts_3_tag = '0;
    io_readPorts_4_ren = '0;
    io_readPorts_4_tag = '0;
    io_readPorts_5_ren = '0;
    io_readPorts_5_tag = '0;
    io_readPorts_6_ren = '0;
    io_readPorts_6_tag = '0;
    io_readPorts_7_ren = '0;
    io_readPorts_7_tag = '0;
    io_readPorts_8_ren = '0;
    io_readPorts_8_tag = '0;
    io_readPorts_9_ren = '0;
    io_readPorts_9_tag = '0;
    io_readPorts_10_ren = '0;
    io_readPorts_10_tag = '0;
    io_readPorts_11_ren = '0;
    io_readPorts_11_tag = '0;
    io_wakeupFromIQ_6_valid = '0;
    io_wakeupFromIQ_6_bits_rfWen = '0;
    io_wakeupFromIQ_6_bits_pdest = '0;
    io_wakeupFromIQ_6_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_6_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_6_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_6_bits_rcDest = '0;
    io_wakeupFromIQ_5_valid = '0;
    io_wakeupFromIQ_5_bits_rfWen = '0;
    io_wakeupFromIQ_5_bits_pdest = '0;
    io_wakeupFromIQ_5_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_5_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_5_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_5_bits_rcDest = '0;
    io_wakeupFromIQ_4_valid = '0;
    io_wakeupFromIQ_4_bits_rfWen = '0;
    io_wakeupFromIQ_4_bits_pdest = '0;
    io_wakeupFromIQ_4_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_4_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_4_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_4_bits_rcDest = '0;
    io_wakeupFromIQ_3_valid = '0;
    io_wakeupFromIQ_3_bits_rfWen = '0;
    io_wakeupFromIQ_3_bits_pdest = '0;
    io_wakeupFromIQ_3_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_3_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_3_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_3_bits_rcDest = '0;
    io_wakeupFromIQ_2_valid = '0;
    io_wakeupFromIQ_2_bits_rfWen = '0;
    io_wakeupFromIQ_2_bits_pdest = '0;
    io_wakeupFromIQ_2_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_2_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_2_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_2_bits_rcDest = '0;
    io_wakeupFromIQ_1_valid = '0;
    io_wakeupFromIQ_1_bits_rfWen = '0;
    io_wakeupFromIQ_1_bits_pdest = '0;
    io_wakeupFromIQ_1_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_1_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_1_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_1_bits_is0Lat = '0;
    io_wakeupFromIQ_1_bits_rcDest = '0;
    io_wakeupFromIQ_0_valid = '0;
    io_wakeupFromIQ_0_bits_rfWen = '0;
    io_wakeupFromIQ_0_bits_pdest = '0;
    io_wakeupFromIQ_0_bits_loadDependency_0 = '0;
    io_wakeupFromIQ_0_bits_loadDependency_1 = '0;
    io_wakeupFromIQ_0_bits_loadDependency_2 = '0;
    io_wakeupFromIQ_0_bits_is0Lat = '0;
    io_wakeupFromIQ_0_bits_rcDest = '0;
    io_allocPregs_0_valid = '0;
    io_allocPregs_0_bits = '0;
    io_allocPregs_1_valid = '0;
    io_allocPregs_1_bits = '0;
    io_allocPregs_2_valid = '0;
    io_allocPregs_2_bits = '0;
    io_allocPregs_3_valid = '0;
    io_allocPregs_3_bits = '0;
    io_allocPregs_4_valid = '0;
    io_allocPregs_4_bits = '0;
    io_allocPregs_5_valid = '0;
    io_allocPregs_5_bits = '0;
    io_og0Cancel_0 = '0;
    io_og0Cancel_2 = '0;
    io_og0Cancel_4 = '0;
    io_og0Cancel_6 = '0;
    io_ldCancel_0_ld2Cancel = '0;
    io_ldCancel_1_ld2Cancel = '0;
    io_ldCancel_2_ld2Cancel = '0;
    p_io_readPorts_0_valid = '0; tog_io_readPorts_0_valid = 1'b0;
    p_io_readPorts_0_addr = '0; tog_io_readPorts_0_addr = 1'b0;
    p_io_readPorts_1_valid = '0; tog_io_readPorts_1_valid = 1'b0;
    p_io_readPorts_1_addr = '0; tog_io_readPorts_1_addr = 1'b0;
    p_io_readPorts_2_valid = '0; tog_io_readPorts_2_valid = 1'b0;
    p_io_readPorts_2_addr = '0; tog_io_readPorts_2_addr = 1'b0;
    p_io_readPorts_3_valid = '0; tog_io_readPorts_3_valid = 1'b0;
    p_io_readPorts_3_addr = '0; tog_io_readPorts_3_addr = 1'b0;
    p_io_readPorts_4_valid = '0; tog_io_readPorts_4_valid = 1'b0;
    p_io_readPorts_4_addr = '0; tog_io_readPorts_4_addr = 1'b0;
    p_io_readPorts_5_valid = '0; tog_io_readPorts_5_valid = 1'b0;
    p_io_readPorts_5_addr = '0; tog_io_readPorts_5_addr = 1'b0;
    p_io_readPorts_6_valid = '0; tog_io_readPorts_6_valid = 1'b0;
    p_io_readPorts_6_addr = '0; tog_io_readPorts_6_addr = 1'b0;
    p_io_readPorts_7_valid = '0; tog_io_readPorts_7_valid = 1'b0;
    p_io_readPorts_7_addr = '0; tog_io_readPorts_7_addr = 1'b0;
    p_io_readPorts_8_valid = '0; tog_io_readPorts_8_valid = 1'b0;
    p_io_readPorts_8_addr = '0; tog_io_readPorts_8_addr = 1'b0;
    p_io_readPorts_9_valid = '0; tog_io_readPorts_9_valid = 1'b0;
    p_io_readPorts_9_addr = '0; tog_io_readPorts_9_addr = 1'b0;
    p_io_readPorts_10_valid = '0; tog_io_readPorts_10_valid = 1'b0;
    p_io_readPorts_10_addr = '0; tog_io_readPorts_10_addr = 1'b0;
    p_io_readPorts_11_valid = '0; tog_io_readPorts_11_valid = 1'b0;
    p_io_readPorts_11_addr = '0; tog_io_readPorts_11_addr = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_readPorts_0_valid) toggled++; else $display("COV: output io_readPorts_0_valid never toggled");
    if (tog_io_readPorts_0_addr) toggled++; else $display("COV: output io_readPorts_0_addr never toggled");
    if (tog_io_readPorts_1_valid) toggled++; else $display("COV: output io_readPorts_1_valid never toggled");
    if (tog_io_readPorts_1_addr) toggled++; else $display("COV: output io_readPorts_1_addr never toggled");
    if (tog_io_readPorts_2_valid) toggled++; else $display("COV: output io_readPorts_2_valid never toggled");
    if (tog_io_readPorts_2_addr) toggled++; else $display("COV: output io_readPorts_2_addr never toggled");
    if (tog_io_readPorts_3_valid) toggled++; else $display("COV: output io_readPorts_3_valid never toggled");
    if (tog_io_readPorts_3_addr) toggled++; else $display("COV: output io_readPorts_3_addr never toggled");
    if (tog_io_readPorts_4_valid) toggled++; else $display("COV: output io_readPorts_4_valid never toggled");
    if (tog_io_readPorts_4_addr) toggled++; else $display("COV: output io_readPorts_4_addr never toggled");
    if (tog_io_readPorts_5_valid) toggled++; else $display("COV: output io_readPorts_5_valid never toggled");
    if (tog_io_readPorts_5_addr) toggled++; else $display("COV: output io_readPorts_5_addr never toggled");
    if (tog_io_readPorts_6_valid) toggled++; else $display("COV: output io_readPorts_6_valid never toggled");
    if (tog_io_readPorts_6_addr) toggled++; else $display("COV: output io_readPorts_6_addr never toggled");
    if (tog_io_readPorts_7_valid) toggled++; else $display("COV: output io_readPorts_7_valid never toggled");
    if (tog_io_readPorts_7_addr) toggled++; else $display("COV: output io_readPorts_7_addr never toggled");
    if (tog_io_readPorts_8_valid) toggled++; else $display("COV: output io_readPorts_8_valid never toggled");
    if (tog_io_readPorts_8_addr) toggled++; else $display("COV: output io_readPorts_8_addr never toggled");
    if (tog_io_readPorts_9_valid) toggled++; else $display("COV: output io_readPorts_9_valid never toggled");
    if (tog_io_readPorts_9_addr) toggled++; else $display("COV: output io_readPorts_9_addr never toggled");
    if (tog_io_readPorts_10_valid) toggled++; else $display("COV: output io_readPorts_10_valid never toggled");
    if (tog_io_readPorts_10_addr) toggled++; else $display("COV: output io_readPorts_10_addr never toggled");
    if (tog_io_readPorts_11_valid) toggled++; else $display("COV: output io_readPorts_11_valid never toggled");
    if (tog_io_readPorts_11_addr) toggled++; else $display("COV: output io_readPorts_11_addr never toggled");
    $display("RegCacheTagTable checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
