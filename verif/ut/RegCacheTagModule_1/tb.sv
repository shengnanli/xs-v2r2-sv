// 自动生成：scripts/gen_zj_ut.py RegCacheTagModule_1 —— 勿手改
// RegCacheTagModule_1 双例化逐拍比对：golden RegCacheTagModule_1 vs 重写 RegCacheTagModule_1_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 200000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 200000;
  localparam int unsigned MIN_TOGGLED = 84;
  localparam int unsigned MIN_FIRES   = 0;
  localparam int unsigned N_OUT       = 84;

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
  logic io_writePorts_0_wen;
  logic [3:0] io_writePorts_0_addr;
  logic [7:0] io_writePorts_0_tag;
  logic [1:0] io_writePorts_0_loadDependency_1;
  logic [1:0] io_writePorts_0_loadDependency_2;
  logic io_writePorts_1_wen;
  logic [3:0] io_writePorts_1_addr;
  logic [7:0] io_writePorts_1_tag;
  logic [1:0] io_writePorts_1_loadDependency_0;
  logic [1:0] io_writePorts_1_loadDependency_2;
  logic io_writePorts_2_wen;
  logic [3:0] io_writePorts_2_addr;
  logic [7:0] io_writePorts_2_tag;
  logic [1:0] io_writePorts_2_loadDependency_0;
  logic [1:0] io_writePorts_2_loadDependency_1;
  logic io_cancelVec_0;
  logic io_cancelVec_1;
  logic io_cancelVec_2;
  logic io_cancelVec_3;
  logic io_cancelVec_4;
  logic io_cancelVec_5;
  logic io_cancelVec_6;
  logic io_cancelVec_7;
  logic io_cancelVec_8;
  logic io_cancelVec_9;
  logic io_cancelVec_10;
  logic io_cancelVec_11;

  wire g_io_readPorts_0_valid;
  wire i_io_readPorts_0_valid;
  wire [3:0] g_io_readPorts_0_addr;
  wire [3:0] i_io_readPorts_0_addr;
  wire g_io_readPorts_1_valid;
  wire i_io_readPorts_1_valid;
  wire [3:0] g_io_readPorts_1_addr;
  wire [3:0] i_io_readPorts_1_addr;
  wire g_io_readPorts_2_valid;
  wire i_io_readPorts_2_valid;
  wire [3:0] g_io_readPorts_2_addr;
  wire [3:0] i_io_readPorts_2_addr;
  wire g_io_readPorts_3_valid;
  wire i_io_readPorts_3_valid;
  wire [3:0] g_io_readPorts_3_addr;
  wire [3:0] i_io_readPorts_3_addr;
  wire g_io_readPorts_4_valid;
  wire i_io_readPorts_4_valid;
  wire [3:0] g_io_readPorts_4_addr;
  wire [3:0] i_io_readPorts_4_addr;
  wire g_io_readPorts_5_valid;
  wire i_io_readPorts_5_valid;
  wire [3:0] g_io_readPorts_5_addr;
  wire [3:0] i_io_readPorts_5_addr;
  wire g_io_readPorts_6_valid;
  wire i_io_readPorts_6_valid;
  wire [3:0] g_io_readPorts_6_addr;
  wire [3:0] i_io_readPorts_6_addr;
  wire g_io_readPorts_7_valid;
  wire i_io_readPorts_7_valid;
  wire [3:0] g_io_readPorts_7_addr;
  wire [3:0] i_io_readPorts_7_addr;
  wire g_io_readPorts_8_valid;
  wire i_io_readPorts_8_valid;
  wire [3:0] g_io_readPorts_8_addr;
  wire [3:0] i_io_readPorts_8_addr;
  wire g_io_readPorts_9_valid;
  wire i_io_readPorts_9_valid;
  wire [3:0] g_io_readPorts_9_addr;
  wire [3:0] i_io_readPorts_9_addr;
  wire g_io_readPorts_10_valid;
  wire i_io_readPorts_10_valid;
  wire [3:0] g_io_readPorts_10_addr;
  wire [3:0] i_io_readPorts_10_addr;
  wire g_io_readPorts_11_valid;
  wire i_io_readPorts_11_valid;
  wire [3:0] g_io_readPorts_11_addr;
  wire [3:0] i_io_readPorts_11_addr;
  wire g_io_validVec_0;
  wire i_io_validVec_0;
  wire g_io_validVec_1;
  wire i_io_validVec_1;
  wire g_io_validVec_2;
  wire i_io_validVec_2;
  wire g_io_validVec_3;
  wire i_io_validVec_3;
  wire g_io_validVec_4;
  wire i_io_validVec_4;
  wire g_io_validVec_5;
  wire i_io_validVec_5;
  wire g_io_validVec_6;
  wire i_io_validVec_6;
  wire g_io_validVec_7;
  wire i_io_validVec_7;
  wire g_io_validVec_8;
  wire i_io_validVec_8;
  wire g_io_validVec_9;
  wire i_io_validVec_9;
  wire g_io_validVec_10;
  wire i_io_validVec_10;
  wire g_io_validVec_11;
  wire i_io_validVec_11;
  wire [7:0] g_io_tagVec_0;
  wire [7:0] i_io_tagVec_0;
  wire [7:0] g_io_tagVec_1;
  wire [7:0] i_io_tagVec_1;
  wire [7:0] g_io_tagVec_2;
  wire [7:0] i_io_tagVec_2;
  wire [7:0] g_io_tagVec_3;
  wire [7:0] i_io_tagVec_3;
  wire [7:0] g_io_tagVec_4;
  wire [7:0] i_io_tagVec_4;
  wire [7:0] g_io_tagVec_5;
  wire [7:0] i_io_tagVec_5;
  wire [7:0] g_io_tagVec_6;
  wire [7:0] i_io_tagVec_6;
  wire [7:0] g_io_tagVec_7;
  wire [7:0] i_io_tagVec_7;
  wire [7:0] g_io_tagVec_8;
  wire [7:0] i_io_tagVec_8;
  wire [7:0] g_io_tagVec_9;
  wire [7:0] i_io_tagVec_9;
  wire [7:0] g_io_tagVec_10;
  wire [7:0] i_io_tagVec_10;
  wire [7:0] g_io_tagVec_11;
  wire [7:0] i_io_tagVec_11;
  wire [1:0] g_io_loadDependencyVec_0_0;
  wire [1:0] i_io_loadDependencyVec_0_0;
  wire [1:0] g_io_loadDependencyVec_0_1;
  wire [1:0] i_io_loadDependencyVec_0_1;
  wire [1:0] g_io_loadDependencyVec_0_2;
  wire [1:0] i_io_loadDependencyVec_0_2;
  wire [1:0] g_io_loadDependencyVec_1_0;
  wire [1:0] i_io_loadDependencyVec_1_0;
  wire [1:0] g_io_loadDependencyVec_1_1;
  wire [1:0] i_io_loadDependencyVec_1_1;
  wire [1:0] g_io_loadDependencyVec_1_2;
  wire [1:0] i_io_loadDependencyVec_1_2;
  wire [1:0] g_io_loadDependencyVec_2_0;
  wire [1:0] i_io_loadDependencyVec_2_0;
  wire [1:0] g_io_loadDependencyVec_2_1;
  wire [1:0] i_io_loadDependencyVec_2_1;
  wire [1:0] g_io_loadDependencyVec_2_2;
  wire [1:0] i_io_loadDependencyVec_2_2;
  wire [1:0] g_io_loadDependencyVec_3_0;
  wire [1:0] i_io_loadDependencyVec_3_0;
  wire [1:0] g_io_loadDependencyVec_3_1;
  wire [1:0] i_io_loadDependencyVec_3_1;
  wire [1:0] g_io_loadDependencyVec_3_2;
  wire [1:0] i_io_loadDependencyVec_3_2;
  wire [1:0] g_io_loadDependencyVec_4_0;
  wire [1:0] i_io_loadDependencyVec_4_0;
  wire [1:0] g_io_loadDependencyVec_4_1;
  wire [1:0] i_io_loadDependencyVec_4_1;
  wire [1:0] g_io_loadDependencyVec_4_2;
  wire [1:0] i_io_loadDependencyVec_4_2;
  wire [1:0] g_io_loadDependencyVec_5_0;
  wire [1:0] i_io_loadDependencyVec_5_0;
  wire [1:0] g_io_loadDependencyVec_5_1;
  wire [1:0] i_io_loadDependencyVec_5_1;
  wire [1:0] g_io_loadDependencyVec_5_2;
  wire [1:0] i_io_loadDependencyVec_5_2;
  wire [1:0] g_io_loadDependencyVec_6_0;
  wire [1:0] i_io_loadDependencyVec_6_0;
  wire [1:0] g_io_loadDependencyVec_6_1;
  wire [1:0] i_io_loadDependencyVec_6_1;
  wire [1:0] g_io_loadDependencyVec_6_2;
  wire [1:0] i_io_loadDependencyVec_6_2;
  wire [1:0] g_io_loadDependencyVec_7_0;
  wire [1:0] i_io_loadDependencyVec_7_0;
  wire [1:0] g_io_loadDependencyVec_7_1;
  wire [1:0] i_io_loadDependencyVec_7_1;
  wire [1:0] g_io_loadDependencyVec_7_2;
  wire [1:0] i_io_loadDependencyVec_7_2;
  wire [1:0] g_io_loadDependencyVec_8_0;
  wire [1:0] i_io_loadDependencyVec_8_0;
  wire [1:0] g_io_loadDependencyVec_8_1;
  wire [1:0] i_io_loadDependencyVec_8_1;
  wire [1:0] g_io_loadDependencyVec_8_2;
  wire [1:0] i_io_loadDependencyVec_8_2;
  wire [1:0] g_io_loadDependencyVec_9_0;
  wire [1:0] i_io_loadDependencyVec_9_0;
  wire [1:0] g_io_loadDependencyVec_9_1;
  wire [1:0] i_io_loadDependencyVec_9_1;
  wire [1:0] g_io_loadDependencyVec_9_2;
  wire [1:0] i_io_loadDependencyVec_9_2;
  wire [1:0] g_io_loadDependencyVec_10_0;
  wire [1:0] i_io_loadDependencyVec_10_0;
  wire [1:0] g_io_loadDependencyVec_10_1;
  wire [1:0] i_io_loadDependencyVec_10_1;
  wire [1:0] g_io_loadDependencyVec_10_2;
  wire [1:0] i_io_loadDependencyVec_10_2;
  wire [1:0] g_io_loadDependencyVec_11_0;
  wire [1:0] i_io_loadDependencyVec_11_0;
  wire [1:0] g_io_loadDependencyVec_11_1;
  wire [1:0] i_io_loadDependencyVec_11_1;
  wire [1:0] g_io_loadDependencyVec_11_2;
  wire [1:0] i_io_loadDependencyVec_11_2;

  logic p_io_readPorts_0_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_0_valid;
  logic [3:0] p_io_readPorts_0_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_0_addr;
  logic p_io_readPorts_1_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_1_valid;
  logic [3:0] p_io_readPorts_1_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_1_addr;
  logic p_io_readPorts_2_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_2_valid;
  logic [3:0] p_io_readPorts_2_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_2_addr;
  logic p_io_readPorts_3_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_3_valid;
  logic [3:0] p_io_readPorts_3_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_3_addr;
  logic p_io_readPorts_4_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_4_valid;
  logic [3:0] p_io_readPorts_4_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_4_addr;
  logic p_io_readPorts_5_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_5_valid;
  logic [3:0] p_io_readPorts_5_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_5_addr;
  logic p_io_readPorts_6_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_6_valid;
  logic [3:0] p_io_readPorts_6_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_6_addr;
  logic p_io_readPorts_7_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_7_valid;
  logic [3:0] p_io_readPorts_7_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_7_addr;
  logic p_io_readPorts_8_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_8_valid;
  logic [3:0] p_io_readPorts_8_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_8_addr;
  logic p_io_readPorts_9_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_9_valid;
  logic [3:0] p_io_readPorts_9_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_9_addr;
  logic p_io_readPorts_10_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_10_valid;
  logic [3:0] p_io_readPorts_10_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_10_addr;
  logic p_io_readPorts_11_valid;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_11_valid;
  logic [3:0] p_io_readPorts_11_addr;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_11_addr;
  logic p_io_validVec_0;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_0;
  logic p_io_validVec_1;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_1;
  logic p_io_validVec_2;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_2;
  logic p_io_validVec_3;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_3;
  logic p_io_validVec_4;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_4;
  logic p_io_validVec_5;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_5;
  logic p_io_validVec_6;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_6;
  logic p_io_validVec_7;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_7;
  logic p_io_validVec_8;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_8;
  logic p_io_validVec_9;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_9;
  logic p_io_validVec_10;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_10;
  logic p_io_validVec_11;   // 上一拍值（toggle 统计）
  bit tog_io_validVec_11;
  logic [7:0] p_io_tagVec_0;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_0;
  logic [7:0] p_io_tagVec_1;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_1;
  logic [7:0] p_io_tagVec_2;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_2;
  logic [7:0] p_io_tagVec_3;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_3;
  logic [7:0] p_io_tagVec_4;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_4;
  logic [7:0] p_io_tagVec_5;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_5;
  logic [7:0] p_io_tagVec_6;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_6;
  logic [7:0] p_io_tagVec_7;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_7;
  logic [7:0] p_io_tagVec_8;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_8;
  logic [7:0] p_io_tagVec_9;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_9;
  logic [7:0] p_io_tagVec_10;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_10;
  logic [7:0] p_io_tagVec_11;   // 上一拍值（toggle 统计）
  bit tog_io_tagVec_11;
  logic [1:0] p_io_loadDependencyVec_0_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_0_0;
  logic [1:0] p_io_loadDependencyVec_0_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_0_1;
  logic [1:0] p_io_loadDependencyVec_0_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_0_2;
  logic [1:0] p_io_loadDependencyVec_1_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_1_0;
  logic [1:0] p_io_loadDependencyVec_1_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_1_1;
  logic [1:0] p_io_loadDependencyVec_1_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_1_2;
  logic [1:0] p_io_loadDependencyVec_2_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_2_0;
  logic [1:0] p_io_loadDependencyVec_2_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_2_1;
  logic [1:0] p_io_loadDependencyVec_2_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_2_2;
  logic [1:0] p_io_loadDependencyVec_3_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_3_0;
  logic [1:0] p_io_loadDependencyVec_3_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_3_1;
  logic [1:0] p_io_loadDependencyVec_3_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_3_2;
  logic [1:0] p_io_loadDependencyVec_4_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_4_0;
  logic [1:0] p_io_loadDependencyVec_4_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_4_1;
  logic [1:0] p_io_loadDependencyVec_4_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_4_2;
  logic [1:0] p_io_loadDependencyVec_5_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_5_0;
  logic [1:0] p_io_loadDependencyVec_5_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_5_1;
  logic [1:0] p_io_loadDependencyVec_5_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_5_2;
  logic [1:0] p_io_loadDependencyVec_6_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_6_0;
  logic [1:0] p_io_loadDependencyVec_6_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_6_1;
  logic [1:0] p_io_loadDependencyVec_6_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_6_2;
  logic [1:0] p_io_loadDependencyVec_7_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_7_0;
  logic [1:0] p_io_loadDependencyVec_7_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_7_1;
  logic [1:0] p_io_loadDependencyVec_7_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_7_2;
  logic [1:0] p_io_loadDependencyVec_8_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_8_0;
  logic [1:0] p_io_loadDependencyVec_8_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_8_1;
  logic [1:0] p_io_loadDependencyVec_8_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_8_2;
  logic [1:0] p_io_loadDependencyVec_9_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_9_0;
  logic [1:0] p_io_loadDependencyVec_9_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_9_1;
  logic [1:0] p_io_loadDependencyVec_9_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_9_2;
  logic [1:0] p_io_loadDependencyVec_10_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_10_0;
  logic [1:0] p_io_loadDependencyVec_10_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_10_1;
  logic [1:0] p_io_loadDependencyVec_10_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_10_2;
  logic [1:0] p_io_loadDependencyVec_11_0;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_11_0;
  logic [1:0] p_io_loadDependencyVec_11_1;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_11_1;
  logic [1:0] p_io_loadDependencyVec_11_2;   // 上一拍值（toggle 统计）
  bit tog_io_loadDependencyVec_11_2;

  RegCacheTagModule_1 u_g (
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
    .io_writePorts_0_wen(io_writePorts_0_wen),
    .io_writePorts_0_addr(io_writePorts_0_addr),
    .io_writePorts_0_tag(io_writePorts_0_tag),
    .io_writePorts_0_loadDependency_1(io_writePorts_0_loadDependency_1),
    .io_writePorts_0_loadDependency_2(io_writePorts_0_loadDependency_2),
    .io_writePorts_1_wen(io_writePorts_1_wen),
    .io_writePorts_1_addr(io_writePorts_1_addr),
    .io_writePorts_1_tag(io_writePorts_1_tag),
    .io_writePorts_1_loadDependency_0(io_writePorts_1_loadDependency_0),
    .io_writePorts_1_loadDependency_2(io_writePorts_1_loadDependency_2),
    .io_writePorts_2_wen(io_writePorts_2_wen),
    .io_writePorts_2_addr(io_writePorts_2_addr),
    .io_writePorts_2_tag(io_writePorts_2_tag),
    .io_writePorts_2_loadDependency_0(io_writePorts_2_loadDependency_0),
    .io_writePorts_2_loadDependency_1(io_writePorts_2_loadDependency_1),
    .io_cancelVec_0(io_cancelVec_0),
    .io_cancelVec_1(io_cancelVec_1),
    .io_cancelVec_2(io_cancelVec_2),
    .io_cancelVec_3(io_cancelVec_3),
    .io_cancelVec_4(io_cancelVec_4),
    .io_cancelVec_5(io_cancelVec_5),
    .io_cancelVec_6(io_cancelVec_6),
    .io_cancelVec_7(io_cancelVec_7),
    .io_cancelVec_8(io_cancelVec_8),
    .io_cancelVec_9(io_cancelVec_9),
    .io_cancelVec_10(io_cancelVec_10),
    .io_cancelVec_11(io_cancelVec_11),
    .io_validVec_0(g_io_validVec_0),
    .io_validVec_1(g_io_validVec_1),
    .io_validVec_2(g_io_validVec_2),
    .io_validVec_3(g_io_validVec_3),
    .io_validVec_4(g_io_validVec_4),
    .io_validVec_5(g_io_validVec_5),
    .io_validVec_6(g_io_validVec_6),
    .io_validVec_7(g_io_validVec_7),
    .io_validVec_8(g_io_validVec_8),
    .io_validVec_9(g_io_validVec_9),
    .io_validVec_10(g_io_validVec_10),
    .io_validVec_11(g_io_validVec_11),
    .io_tagVec_0(g_io_tagVec_0),
    .io_tagVec_1(g_io_tagVec_1),
    .io_tagVec_2(g_io_tagVec_2),
    .io_tagVec_3(g_io_tagVec_3),
    .io_tagVec_4(g_io_tagVec_4),
    .io_tagVec_5(g_io_tagVec_5),
    .io_tagVec_6(g_io_tagVec_6),
    .io_tagVec_7(g_io_tagVec_7),
    .io_tagVec_8(g_io_tagVec_8),
    .io_tagVec_9(g_io_tagVec_9),
    .io_tagVec_10(g_io_tagVec_10),
    .io_tagVec_11(g_io_tagVec_11),
    .io_loadDependencyVec_0_0(g_io_loadDependencyVec_0_0),
    .io_loadDependencyVec_0_1(g_io_loadDependencyVec_0_1),
    .io_loadDependencyVec_0_2(g_io_loadDependencyVec_0_2),
    .io_loadDependencyVec_1_0(g_io_loadDependencyVec_1_0),
    .io_loadDependencyVec_1_1(g_io_loadDependencyVec_1_1),
    .io_loadDependencyVec_1_2(g_io_loadDependencyVec_1_2),
    .io_loadDependencyVec_2_0(g_io_loadDependencyVec_2_0),
    .io_loadDependencyVec_2_1(g_io_loadDependencyVec_2_1),
    .io_loadDependencyVec_2_2(g_io_loadDependencyVec_2_2),
    .io_loadDependencyVec_3_0(g_io_loadDependencyVec_3_0),
    .io_loadDependencyVec_3_1(g_io_loadDependencyVec_3_1),
    .io_loadDependencyVec_3_2(g_io_loadDependencyVec_3_2),
    .io_loadDependencyVec_4_0(g_io_loadDependencyVec_4_0),
    .io_loadDependencyVec_4_1(g_io_loadDependencyVec_4_1),
    .io_loadDependencyVec_4_2(g_io_loadDependencyVec_4_2),
    .io_loadDependencyVec_5_0(g_io_loadDependencyVec_5_0),
    .io_loadDependencyVec_5_1(g_io_loadDependencyVec_5_1),
    .io_loadDependencyVec_5_2(g_io_loadDependencyVec_5_2),
    .io_loadDependencyVec_6_0(g_io_loadDependencyVec_6_0),
    .io_loadDependencyVec_6_1(g_io_loadDependencyVec_6_1),
    .io_loadDependencyVec_6_2(g_io_loadDependencyVec_6_2),
    .io_loadDependencyVec_7_0(g_io_loadDependencyVec_7_0),
    .io_loadDependencyVec_7_1(g_io_loadDependencyVec_7_1),
    .io_loadDependencyVec_7_2(g_io_loadDependencyVec_7_2),
    .io_loadDependencyVec_8_0(g_io_loadDependencyVec_8_0),
    .io_loadDependencyVec_8_1(g_io_loadDependencyVec_8_1),
    .io_loadDependencyVec_8_2(g_io_loadDependencyVec_8_2),
    .io_loadDependencyVec_9_0(g_io_loadDependencyVec_9_0),
    .io_loadDependencyVec_9_1(g_io_loadDependencyVec_9_1),
    .io_loadDependencyVec_9_2(g_io_loadDependencyVec_9_2),
    .io_loadDependencyVec_10_0(g_io_loadDependencyVec_10_0),
    .io_loadDependencyVec_10_1(g_io_loadDependencyVec_10_1),
    .io_loadDependencyVec_10_2(g_io_loadDependencyVec_10_2),
    .io_loadDependencyVec_11_0(g_io_loadDependencyVec_11_0),
    .io_loadDependencyVec_11_1(g_io_loadDependencyVec_11_1),
    .io_loadDependencyVec_11_2(g_io_loadDependencyVec_11_2)
  );
  RegCacheTagModule_1_xs u_i (
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
    .io_writePorts_0_wen(io_writePorts_0_wen),
    .io_writePorts_0_addr(io_writePorts_0_addr),
    .io_writePorts_0_tag(io_writePorts_0_tag),
    .io_writePorts_0_loadDependency_1(io_writePorts_0_loadDependency_1),
    .io_writePorts_0_loadDependency_2(io_writePorts_0_loadDependency_2),
    .io_writePorts_1_wen(io_writePorts_1_wen),
    .io_writePorts_1_addr(io_writePorts_1_addr),
    .io_writePorts_1_tag(io_writePorts_1_tag),
    .io_writePorts_1_loadDependency_0(io_writePorts_1_loadDependency_0),
    .io_writePorts_1_loadDependency_2(io_writePorts_1_loadDependency_2),
    .io_writePorts_2_wen(io_writePorts_2_wen),
    .io_writePorts_2_addr(io_writePorts_2_addr),
    .io_writePorts_2_tag(io_writePorts_2_tag),
    .io_writePorts_2_loadDependency_0(io_writePorts_2_loadDependency_0),
    .io_writePorts_2_loadDependency_1(io_writePorts_2_loadDependency_1),
    .io_cancelVec_0(io_cancelVec_0),
    .io_cancelVec_1(io_cancelVec_1),
    .io_cancelVec_2(io_cancelVec_2),
    .io_cancelVec_3(io_cancelVec_3),
    .io_cancelVec_4(io_cancelVec_4),
    .io_cancelVec_5(io_cancelVec_5),
    .io_cancelVec_6(io_cancelVec_6),
    .io_cancelVec_7(io_cancelVec_7),
    .io_cancelVec_8(io_cancelVec_8),
    .io_cancelVec_9(io_cancelVec_9),
    .io_cancelVec_10(io_cancelVec_10),
    .io_cancelVec_11(io_cancelVec_11),
    .io_validVec_0(i_io_validVec_0),
    .io_validVec_1(i_io_validVec_1),
    .io_validVec_2(i_io_validVec_2),
    .io_validVec_3(i_io_validVec_3),
    .io_validVec_4(i_io_validVec_4),
    .io_validVec_5(i_io_validVec_5),
    .io_validVec_6(i_io_validVec_6),
    .io_validVec_7(i_io_validVec_7),
    .io_validVec_8(i_io_validVec_8),
    .io_validVec_9(i_io_validVec_9),
    .io_validVec_10(i_io_validVec_10),
    .io_validVec_11(i_io_validVec_11),
    .io_tagVec_0(i_io_tagVec_0),
    .io_tagVec_1(i_io_tagVec_1),
    .io_tagVec_2(i_io_tagVec_2),
    .io_tagVec_3(i_io_tagVec_3),
    .io_tagVec_4(i_io_tagVec_4),
    .io_tagVec_5(i_io_tagVec_5),
    .io_tagVec_6(i_io_tagVec_6),
    .io_tagVec_7(i_io_tagVec_7),
    .io_tagVec_8(i_io_tagVec_8),
    .io_tagVec_9(i_io_tagVec_9),
    .io_tagVec_10(i_io_tagVec_10),
    .io_tagVec_11(i_io_tagVec_11),
    .io_loadDependencyVec_0_0(i_io_loadDependencyVec_0_0),
    .io_loadDependencyVec_0_1(i_io_loadDependencyVec_0_1),
    .io_loadDependencyVec_0_2(i_io_loadDependencyVec_0_2),
    .io_loadDependencyVec_1_0(i_io_loadDependencyVec_1_0),
    .io_loadDependencyVec_1_1(i_io_loadDependencyVec_1_1),
    .io_loadDependencyVec_1_2(i_io_loadDependencyVec_1_2),
    .io_loadDependencyVec_2_0(i_io_loadDependencyVec_2_0),
    .io_loadDependencyVec_2_1(i_io_loadDependencyVec_2_1),
    .io_loadDependencyVec_2_2(i_io_loadDependencyVec_2_2),
    .io_loadDependencyVec_3_0(i_io_loadDependencyVec_3_0),
    .io_loadDependencyVec_3_1(i_io_loadDependencyVec_3_1),
    .io_loadDependencyVec_3_2(i_io_loadDependencyVec_3_2),
    .io_loadDependencyVec_4_0(i_io_loadDependencyVec_4_0),
    .io_loadDependencyVec_4_1(i_io_loadDependencyVec_4_1),
    .io_loadDependencyVec_4_2(i_io_loadDependencyVec_4_2),
    .io_loadDependencyVec_5_0(i_io_loadDependencyVec_5_0),
    .io_loadDependencyVec_5_1(i_io_loadDependencyVec_5_1),
    .io_loadDependencyVec_5_2(i_io_loadDependencyVec_5_2),
    .io_loadDependencyVec_6_0(i_io_loadDependencyVec_6_0),
    .io_loadDependencyVec_6_1(i_io_loadDependencyVec_6_1),
    .io_loadDependencyVec_6_2(i_io_loadDependencyVec_6_2),
    .io_loadDependencyVec_7_0(i_io_loadDependencyVec_7_0),
    .io_loadDependencyVec_7_1(i_io_loadDependencyVec_7_1),
    .io_loadDependencyVec_7_2(i_io_loadDependencyVec_7_2),
    .io_loadDependencyVec_8_0(i_io_loadDependencyVec_8_0),
    .io_loadDependencyVec_8_1(i_io_loadDependencyVec_8_1),
    .io_loadDependencyVec_8_2(i_io_loadDependencyVec_8_2),
    .io_loadDependencyVec_9_0(i_io_loadDependencyVec_9_0),
    .io_loadDependencyVec_9_1(i_io_loadDependencyVec_9_1),
    .io_loadDependencyVec_9_2(i_io_loadDependencyVec_9_2),
    .io_loadDependencyVec_10_0(i_io_loadDependencyVec_10_0),
    .io_loadDependencyVec_10_1(i_io_loadDependencyVec_10_1),
    .io_loadDependencyVec_10_2(i_io_loadDependencyVec_10_2),
    .io_loadDependencyVec_11_0(i_io_loadDependencyVec_11_0),
    .io_loadDependencyVec_11_1(i_io_loadDependencyVec_11_1),
    .io_loadDependencyVec_11_2(i_io_loadDependencyVec_11_2)
  );

  task automatic drive_random();
    io_readPorts_0_ren = $urandom % 2;
    io_readPorts_0_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_1_ren = $urandom % 2;
    io_readPorts_1_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_2_ren = $urandom % 2;
    io_readPorts_2_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_3_ren = $urandom % 2;
    io_readPorts_3_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_4_ren = $urandom % 2;
    io_readPorts_4_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_5_ren = $urandom % 2;
    io_readPorts_5_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_6_ren = $urandom % 2;
    io_readPorts_6_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_7_ren = $urandom % 2;
    io_readPorts_7_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_8_ren = $urandom % 2;
    io_readPorts_8_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_9_ren = $urandom % 2;
    io_readPorts_9_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_10_ren = $urandom % 2;
    io_readPorts_10_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_readPorts_11_ren = $urandom % 2;
    io_readPorts_11_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_writePorts_0_wen = $urandom % 2;
    io_writePorts_0_addr = rnd(4);
    io_writePorts_0_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_writePorts_0_loadDependency_1 = rnd(2);
    io_writePorts_0_loadDependency_2 = rnd(2);
    io_writePorts_1_wen = $urandom % 2;
    io_writePorts_1_addr = rnd(4);
    io_writePorts_1_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_writePorts_1_loadDependency_0 = rnd(2);
    io_writePorts_1_loadDependency_2 = rnd(2);
    io_writePorts_2_wen = $urandom % 2;
    io_writePorts_2_addr = rnd(4);
    io_writePorts_2_tag = $urandom_range(0, $urandom % 8);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_writePorts_2_loadDependency_0 = rnd(2);
    io_writePorts_2_loadDependency_1 = rnd(2);
    io_cancelVec_0 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_1 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_2 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_3 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_4 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_5 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_6 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_7 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_8 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_9 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_10 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_cancelVec_11 = $urandom_range(0, ($urandom % 8) == 0);   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
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
    if (!$isunknown(g_io_validVec_0)) begin
      checks++;
      if (g_io_validVec_0 !== i_io_validVec_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_0 g=%0h i=%0h", $time, g_io_validVec_0, i_io_validVec_0);
      end
    end
    if (!$isunknown(g_io_validVec_1)) begin
      checks++;
      if (g_io_validVec_1 !== i_io_validVec_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_1 g=%0h i=%0h", $time, g_io_validVec_1, i_io_validVec_1);
      end
    end
    if (!$isunknown(g_io_validVec_2)) begin
      checks++;
      if (g_io_validVec_2 !== i_io_validVec_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_2 g=%0h i=%0h", $time, g_io_validVec_2, i_io_validVec_2);
      end
    end
    if (!$isunknown(g_io_validVec_3)) begin
      checks++;
      if (g_io_validVec_3 !== i_io_validVec_3) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_3 g=%0h i=%0h", $time, g_io_validVec_3, i_io_validVec_3);
      end
    end
    if (!$isunknown(g_io_validVec_4)) begin
      checks++;
      if (g_io_validVec_4 !== i_io_validVec_4) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_4 g=%0h i=%0h", $time, g_io_validVec_4, i_io_validVec_4);
      end
    end
    if (!$isunknown(g_io_validVec_5)) begin
      checks++;
      if (g_io_validVec_5 !== i_io_validVec_5) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_5 g=%0h i=%0h", $time, g_io_validVec_5, i_io_validVec_5);
      end
    end
    if (!$isunknown(g_io_validVec_6)) begin
      checks++;
      if (g_io_validVec_6 !== i_io_validVec_6) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_6 g=%0h i=%0h", $time, g_io_validVec_6, i_io_validVec_6);
      end
    end
    if (!$isunknown(g_io_validVec_7)) begin
      checks++;
      if (g_io_validVec_7 !== i_io_validVec_7) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_7 g=%0h i=%0h", $time, g_io_validVec_7, i_io_validVec_7);
      end
    end
    if (!$isunknown(g_io_validVec_8)) begin
      checks++;
      if (g_io_validVec_8 !== i_io_validVec_8) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_8 g=%0h i=%0h", $time, g_io_validVec_8, i_io_validVec_8);
      end
    end
    if (!$isunknown(g_io_validVec_9)) begin
      checks++;
      if (g_io_validVec_9 !== i_io_validVec_9) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_9 g=%0h i=%0h", $time, g_io_validVec_9, i_io_validVec_9);
      end
    end
    if (!$isunknown(g_io_validVec_10)) begin
      checks++;
      if (g_io_validVec_10 !== i_io_validVec_10) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_10 g=%0h i=%0h", $time, g_io_validVec_10, i_io_validVec_10);
      end
    end
    if (!$isunknown(g_io_validVec_11)) begin
      checks++;
      if (g_io_validVec_11 !== i_io_validVec_11) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_validVec_11 g=%0h i=%0h", $time, g_io_validVec_11, i_io_validVec_11);
      end
    end
    if (!$isunknown(g_io_tagVec_0)) begin
      checks++;
      if (g_io_tagVec_0 !== i_io_tagVec_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_0 g=%0h i=%0h", $time, g_io_tagVec_0, i_io_tagVec_0);
      end
    end
    if (!$isunknown(g_io_tagVec_1)) begin
      checks++;
      if (g_io_tagVec_1 !== i_io_tagVec_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_1 g=%0h i=%0h", $time, g_io_tagVec_1, i_io_tagVec_1);
      end
    end
    if (!$isunknown(g_io_tagVec_2)) begin
      checks++;
      if (g_io_tagVec_2 !== i_io_tagVec_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_2 g=%0h i=%0h", $time, g_io_tagVec_2, i_io_tagVec_2);
      end
    end
    if (!$isunknown(g_io_tagVec_3)) begin
      checks++;
      if (g_io_tagVec_3 !== i_io_tagVec_3) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_3 g=%0h i=%0h", $time, g_io_tagVec_3, i_io_tagVec_3);
      end
    end
    if (!$isunknown(g_io_tagVec_4)) begin
      checks++;
      if (g_io_tagVec_4 !== i_io_tagVec_4) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_4 g=%0h i=%0h", $time, g_io_tagVec_4, i_io_tagVec_4);
      end
    end
    if (!$isunknown(g_io_tagVec_5)) begin
      checks++;
      if (g_io_tagVec_5 !== i_io_tagVec_5) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_5 g=%0h i=%0h", $time, g_io_tagVec_5, i_io_tagVec_5);
      end
    end
    if (!$isunknown(g_io_tagVec_6)) begin
      checks++;
      if (g_io_tagVec_6 !== i_io_tagVec_6) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_6 g=%0h i=%0h", $time, g_io_tagVec_6, i_io_tagVec_6);
      end
    end
    if (!$isunknown(g_io_tagVec_7)) begin
      checks++;
      if (g_io_tagVec_7 !== i_io_tagVec_7) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_7 g=%0h i=%0h", $time, g_io_tagVec_7, i_io_tagVec_7);
      end
    end
    if (!$isunknown(g_io_tagVec_8)) begin
      checks++;
      if (g_io_tagVec_8 !== i_io_tagVec_8) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_8 g=%0h i=%0h", $time, g_io_tagVec_8, i_io_tagVec_8);
      end
    end
    if (!$isunknown(g_io_tagVec_9)) begin
      checks++;
      if (g_io_tagVec_9 !== i_io_tagVec_9) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_9 g=%0h i=%0h", $time, g_io_tagVec_9, i_io_tagVec_9);
      end
    end
    if (!$isunknown(g_io_tagVec_10)) begin
      checks++;
      if (g_io_tagVec_10 !== i_io_tagVec_10) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_10 g=%0h i=%0h", $time, g_io_tagVec_10, i_io_tagVec_10);
      end
    end
    if (!$isunknown(g_io_tagVec_11)) begin
      checks++;
      if (g_io_tagVec_11 !== i_io_tagVec_11) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_tagVec_11 g=%0h i=%0h", $time, g_io_tagVec_11, i_io_tagVec_11);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_0_0)) begin
      checks++;
      if (g_io_loadDependencyVec_0_0 !== i_io_loadDependencyVec_0_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_0_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_0_0, i_io_loadDependencyVec_0_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_0_1)) begin
      checks++;
      if (g_io_loadDependencyVec_0_1 !== i_io_loadDependencyVec_0_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_0_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_0_1, i_io_loadDependencyVec_0_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_0_2)) begin
      checks++;
      if (g_io_loadDependencyVec_0_2 !== i_io_loadDependencyVec_0_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_0_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_0_2, i_io_loadDependencyVec_0_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_1_0)) begin
      checks++;
      if (g_io_loadDependencyVec_1_0 !== i_io_loadDependencyVec_1_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_1_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_1_0, i_io_loadDependencyVec_1_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_1_1)) begin
      checks++;
      if (g_io_loadDependencyVec_1_1 !== i_io_loadDependencyVec_1_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_1_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_1_1, i_io_loadDependencyVec_1_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_1_2)) begin
      checks++;
      if (g_io_loadDependencyVec_1_2 !== i_io_loadDependencyVec_1_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_1_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_1_2, i_io_loadDependencyVec_1_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_2_0)) begin
      checks++;
      if (g_io_loadDependencyVec_2_0 !== i_io_loadDependencyVec_2_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_2_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_2_0, i_io_loadDependencyVec_2_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_2_1)) begin
      checks++;
      if (g_io_loadDependencyVec_2_1 !== i_io_loadDependencyVec_2_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_2_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_2_1, i_io_loadDependencyVec_2_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_2_2)) begin
      checks++;
      if (g_io_loadDependencyVec_2_2 !== i_io_loadDependencyVec_2_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_2_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_2_2, i_io_loadDependencyVec_2_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_3_0)) begin
      checks++;
      if (g_io_loadDependencyVec_3_0 !== i_io_loadDependencyVec_3_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_3_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_3_0, i_io_loadDependencyVec_3_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_3_1)) begin
      checks++;
      if (g_io_loadDependencyVec_3_1 !== i_io_loadDependencyVec_3_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_3_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_3_1, i_io_loadDependencyVec_3_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_3_2)) begin
      checks++;
      if (g_io_loadDependencyVec_3_2 !== i_io_loadDependencyVec_3_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_3_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_3_2, i_io_loadDependencyVec_3_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_4_0)) begin
      checks++;
      if (g_io_loadDependencyVec_4_0 !== i_io_loadDependencyVec_4_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_4_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_4_0, i_io_loadDependencyVec_4_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_4_1)) begin
      checks++;
      if (g_io_loadDependencyVec_4_1 !== i_io_loadDependencyVec_4_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_4_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_4_1, i_io_loadDependencyVec_4_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_4_2)) begin
      checks++;
      if (g_io_loadDependencyVec_4_2 !== i_io_loadDependencyVec_4_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_4_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_4_2, i_io_loadDependencyVec_4_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_5_0)) begin
      checks++;
      if (g_io_loadDependencyVec_5_0 !== i_io_loadDependencyVec_5_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_5_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_5_0, i_io_loadDependencyVec_5_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_5_1)) begin
      checks++;
      if (g_io_loadDependencyVec_5_1 !== i_io_loadDependencyVec_5_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_5_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_5_1, i_io_loadDependencyVec_5_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_5_2)) begin
      checks++;
      if (g_io_loadDependencyVec_5_2 !== i_io_loadDependencyVec_5_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_5_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_5_2, i_io_loadDependencyVec_5_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_6_0)) begin
      checks++;
      if (g_io_loadDependencyVec_6_0 !== i_io_loadDependencyVec_6_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_6_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_6_0, i_io_loadDependencyVec_6_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_6_1)) begin
      checks++;
      if (g_io_loadDependencyVec_6_1 !== i_io_loadDependencyVec_6_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_6_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_6_1, i_io_loadDependencyVec_6_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_6_2)) begin
      checks++;
      if (g_io_loadDependencyVec_6_2 !== i_io_loadDependencyVec_6_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_6_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_6_2, i_io_loadDependencyVec_6_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_7_0)) begin
      checks++;
      if (g_io_loadDependencyVec_7_0 !== i_io_loadDependencyVec_7_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_7_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_7_0, i_io_loadDependencyVec_7_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_7_1)) begin
      checks++;
      if (g_io_loadDependencyVec_7_1 !== i_io_loadDependencyVec_7_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_7_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_7_1, i_io_loadDependencyVec_7_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_7_2)) begin
      checks++;
      if (g_io_loadDependencyVec_7_2 !== i_io_loadDependencyVec_7_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_7_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_7_2, i_io_loadDependencyVec_7_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_8_0)) begin
      checks++;
      if (g_io_loadDependencyVec_8_0 !== i_io_loadDependencyVec_8_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_8_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_8_0, i_io_loadDependencyVec_8_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_8_1)) begin
      checks++;
      if (g_io_loadDependencyVec_8_1 !== i_io_loadDependencyVec_8_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_8_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_8_1, i_io_loadDependencyVec_8_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_8_2)) begin
      checks++;
      if (g_io_loadDependencyVec_8_2 !== i_io_loadDependencyVec_8_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_8_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_8_2, i_io_loadDependencyVec_8_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_9_0)) begin
      checks++;
      if (g_io_loadDependencyVec_9_0 !== i_io_loadDependencyVec_9_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_9_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_9_0, i_io_loadDependencyVec_9_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_9_1)) begin
      checks++;
      if (g_io_loadDependencyVec_9_1 !== i_io_loadDependencyVec_9_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_9_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_9_1, i_io_loadDependencyVec_9_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_9_2)) begin
      checks++;
      if (g_io_loadDependencyVec_9_2 !== i_io_loadDependencyVec_9_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_9_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_9_2, i_io_loadDependencyVec_9_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_10_0)) begin
      checks++;
      if (g_io_loadDependencyVec_10_0 !== i_io_loadDependencyVec_10_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_10_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_10_0, i_io_loadDependencyVec_10_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_10_1)) begin
      checks++;
      if (g_io_loadDependencyVec_10_1 !== i_io_loadDependencyVec_10_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_10_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_10_1, i_io_loadDependencyVec_10_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_10_2)) begin
      checks++;
      if (g_io_loadDependencyVec_10_2 !== i_io_loadDependencyVec_10_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_10_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_10_2, i_io_loadDependencyVec_10_2);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_11_0)) begin
      checks++;
      if (g_io_loadDependencyVec_11_0 !== i_io_loadDependencyVec_11_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_11_0 g=%0h i=%0h", $time, g_io_loadDependencyVec_11_0, i_io_loadDependencyVec_11_0);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_11_1)) begin
      checks++;
      if (g_io_loadDependencyVec_11_1 !== i_io_loadDependencyVec_11_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_11_1 g=%0h i=%0h", $time, g_io_loadDependencyVec_11_1, i_io_loadDependencyVec_11_1);
      end
    end
    if (!$isunknown(g_io_loadDependencyVec_11_2)) begin
      checks++;
      if (g_io_loadDependencyVec_11_2 !== i_io_loadDependencyVec_11_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_loadDependencyVec_11_2 g=%0h i=%0h", $time, g_io_loadDependencyVec_11_2, i_io_loadDependencyVec_11_2);
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
    if (g_io_validVec_0 !== p_io_validVec_0) tog_io_validVec_0 = 1'b1;
    p_io_validVec_0 = g_io_validVec_0;
    if (g_io_validVec_1 !== p_io_validVec_1) tog_io_validVec_1 = 1'b1;
    p_io_validVec_1 = g_io_validVec_1;
    if (g_io_validVec_2 !== p_io_validVec_2) tog_io_validVec_2 = 1'b1;
    p_io_validVec_2 = g_io_validVec_2;
    if (g_io_validVec_3 !== p_io_validVec_3) tog_io_validVec_3 = 1'b1;
    p_io_validVec_3 = g_io_validVec_3;
    if (g_io_validVec_4 !== p_io_validVec_4) tog_io_validVec_4 = 1'b1;
    p_io_validVec_4 = g_io_validVec_4;
    if (g_io_validVec_5 !== p_io_validVec_5) tog_io_validVec_5 = 1'b1;
    p_io_validVec_5 = g_io_validVec_5;
    if (g_io_validVec_6 !== p_io_validVec_6) tog_io_validVec_6 = 1'b1;
    p_io_validVec_6 = g_io_validVec_6;
    if (g_io_validVec_7 !== p_io_validVec_7) tog_io_validVec_7 = 1'b1;
    p_io_validVec_7 = g_io_validVec_7;
    if (g_io_validVec_8 !== p_io_validVec_8) tog_io_validVec_8 = 1'b1;
    p_io_validVec_8 = g_io_validVec_8;
    if (g_io_validVec_9 !== p_io_validVec_9) tog_io_validVec_9 = 1'b1;
    p_io_validVec_9 = g_io_validVec_9;
    if (g_io_validVec_10 !== p_io_validVec_10) tog_io_validVec_10 = 1'b1;
    p_io_validVec_10 = g_io_validVec_10;
    if (g_io_validVec_11 !== p_io_validVec_11) tog_io_validVec_11 = 1'b1;
    p_io_validVec_11 = g_io_validVec_11;
    if (g_io_tagVec_0 !== p_io_tagVec_0) tog_io_tagVec_0 = 1'b1;
    p_io_tagVec_0 = g_io_tagVec_0;
    if (g_io_tagVec_1 !== p_io_tagVec_1) tog_io_tagVec_1 = 1'b1;
    p_io_tagVec_1 = g_io_tagVec_1;
    if (g_io_tagVec_2 !== p_io_tagVec_2) tog_io_tagVec_2 = 1'b1;
    p_io_tagVec_2 = g_io_tagVec_2;
    if (g_io_tagVec_3 !== p_io_tagVec_3) tog_io_tagVec_3 = 1'b1;
    p_io_tagVec_3 = g_io_tagVec_3;
    if (g_io_tagVec_4 !== p_io_tagVec_4) tog_io_tagVec_4 = 1'b1;
    p_io_tagVec_4 = g_io_tagVec_4;
    if (g_io_tagVec_5 !== p_io_tagVec_5) tog_io_tagVec_5 = 1'b1;
    p_io_tagVec_5 = g_io_tagVec_5;
    if (g_io_tagVec_6 !== p_io_tagVec_6) tog_io_tagVec_6 = 1'b1;
    p_io_tagVec_6 = g_io_tagVec_6;
    if (g_io_tagVec_7 !== p_io_tagVec_7) tog_io_tagVec_7 = 1'b1;
    p_io_tagVec_7 = g_io_tagVec_7;
    if (g_io_tagVec_8 !== p_io_tagVec_8) tog_io_tagVec_8 = 1'b1;
    p_io_tagVec_8 = g_io_tagVec_8;
    if (g_io_tagVec_9 !== p_io_tagVec_9) tog_io_tagVec_9 = 1'b1;
    p_io_tagVec_9 = g_io_tagVec_9;
    if (g_io_tagVec_10 !== p_io_tagVec_10) tog_io_tagVec_10 = 1'b1;
    p_io_tagVec_10 = g_io_tagVec_10;
    if (g_io_tagVec_11 !== p_io_tagVec_11) tog_io_tagVec_11 = 1'b1;
    p_io_tagVec_11 = g_io_tagVec_11;
    if (g_io_loadDependencyVec_0_0 !== p_io_loadDependencyVec_0_0) tog_io_loadDependencyVec_0_0 = 1'b1;
    p_io_loadDependencyVec_0_0 = g_io_loadDependencyVec_0_0;
    if (g_io_loadDependencyVec_0_1 !== p_io_loadDependencyVec_0_1) tog_io_loadDependencyVec_0_1 = 1'b1;
    p_io_loadDependencyVec_0_1 = g_io_loadDependencyVec_0_1;
    if (g_io_loadDependencyVec_0_2 !== p_io_loadDependencyVec_0_2) tog_io_loadDependencyVec_0_2 = 1'b1;
    p_io_loadDependencyVec_0_2 = g_io_loadDependencyVec_0_2;
    if (g_io_loadDependencyVec_1_0 !== p_io_loadDependencyVec_1_0) tog_io_loadDependencyVec_1_0 = 1'b1;
    p_io_loadDependencyVec_1_0 = g_io_loadDependencyVec_1_0;
    if (g_io_loadDependencyVec_1_1 !== p_io_loadDependencyVec_1_1) tog_io_loadDependencyVec_1_1 = 1'b1;
    p_io_loadDependencyVec_1_1 = g_io_loadDependencyVec_1_1;
    if (g_io_loadDependencyVec_1_2 !== p_io_loadDependencyVec_1_2) tog_io_loadDependencyVec_1_2 = 1'b1;
    p_io_loadDependencyVec_1_2 = g_io_loadDependencyVec_1_2;
    if (g_io_loadDependencyVec_2_0 !== p_io_loadDependencyVec_2_0) tog_io_loadDependencyVec_2_0 = 1'b1;
    p_io_loadDependencyVec_2_0 = g_io_loadDependencyVec_2_0;
    if (g_io_loadDependencyVec_2_1 !== p_io_loadDependencyVec_2_1) tog_io_loadDependencyVec_2_1 = 1'b1;
    p_io_loadDependencyVec_2_1 = g_io_loadDependencyVec_2_1;
    if (g_io_loadDependencyVec_2_2 !== p_io_loadDependencyVec_2_2) tog_io_loadDependencyVec_2_2 = 1'b1;
    p_io_loadDependencyVec_2_2 = g_io_loadDependencyVec_2_2;
    if (g_io_loadDependencyVec_3_0 !== p_io_loadDependencyVec_3_0) tog_io_loadDependencyVec_3_0 = 1'b1;
    p_io_loadDependencyVec_3_0 = g_io_loadDependencyVec_3_0;
    if (g_io_loadDependencyVec_3_1 !== p_io_loadDependencyVec_3_1) tog_io_loadDependencyVec_3_1 = 1'b1;
    p_io_loadDependencyVec_3_1 = g_io_loadDependencyVec_3_1;
    if (g_io_loadDependencyVec_3_2 !== p_io_loadDependencyVec_3_2) tog_io_loadDependencyVec_3_2 = 1'b1;
    p_io_loadDependencyVec_3_2 = g_io_loadDependencyVec_3_2;
    if (g_io_loadDependencyVec_4_0 !== p_io_loadDependencyVec_4_0) tog_io_loadDependencyVec_4_0 = 1'b1;
    p_io_loadDependencyVec_4_0 = g_io_loadDependencyVec_4_0;
    if (g_io_loadDependencyVec_4_1 !== p_io_loadDependencyVec_4_1) tog_io_loadDependencyVec_4_1 = 1'b1;
    p_io_loadDependencyVec_4_1 = g_io_loadDependencyVec_4_1;
    if (g_io_loadDependencyVec_4_2 !== p_io_loadDependencyVec_4_2) tog_io_loadDependencyVec_4_2 = 1'b1;
    p_io_loadDependencyVec_4_2 = g_io_loadDependencyVec_4_2;
    if (g_io_loadDependencyVec_5_0 !== p_io_loadDependencyVec_5_0) tog_io_loadDependencyVec_5_0 = 1'b1;
    p_io_loadDependencyVec_5_0 = g_io_loadDependencyVec_5_0;
    if (g_io_loadDependencyVec_5_1 !== p_io_loadDependencyVec_5_1) tog_io_loadDependencyVec_5_1 = 1'b1;
    p_io_loadDependencyVec_5_1 = g_io_loadDependencyVec_5_1;
    if (g_io_loadDependencyVec_5_2 !== p_io_loadDependencyVec_5_2) tog_io_loadDependencyVec_5_2 = 1'b1;
    p_io_loadDependencyVec_5_2 = g_io_loadDependencyVec_5_2;
    if (g_io_loadDependencyVec_6_0 !== p_io_loadDependencyVec_6_0) tog_io_loadDependencyVec_6_0 = 1'b1;
    p_io_loadDependencyVec_6_0 = g_io_loadDependencyVec_6_0;
    if (g_io_loadDependencyVec_6_1 !== p_io_loadDependencyVec_6_1) tog_io_loadDependencyVec_6_1 = 1'b1;
    p_io_loadDependencyVec_6_1 = g_io_loadDependencyVec_6_1;
    if (g_io_loadDependencyVec_6_2 !== p_io_loadDependencyVec_6_2) tog_io_loadDependencyVec_6_2 = 1'b1;
    p_io_loadDependencyVec_6_2 = g_io_loadDependencyVec_6_2;
    if (g_io_loadDependencyVec_7_0 !== p_io_loadDependencyVec_7_0) tog_io_loadDependencyVec_7_0 = 1'b1;
    p_io_loadDependencyVec_7_0 = g_io_loadDependencyVec_7_0;
    if (g_io_loadDependencyVec_7_1 !== p_io_loadDependencyVec_7_1) tog_io_loadDependencyVec_7_1 = 1'b1;
    p_io_loadDependencyVec_7_1 = g_io_loadDependencyVec_7_1;
    if (g_io_loadDependencyVec_7_2 !== p_io_loadDependencyVec_7_2) tog_io_loadDependencyVec_7_2 = 1'b1;
    p_io_loadDependencyVec_7_2 = g_io_loadDependencyVec_7_2;
    if (g_io_loadDependencyVec_8_0 !== p_io_loadDependencyVec_8_0) tog_io_loadDependencyVec_8_0 = 1'b1;
    p_io_loadDependencyVec_8_0 = g_io_loadDependencyVec_8_0;
    if (g_io_loadDependencyVec_8_1 !== p_io_loadDependencyVec_8_1) tog_io_loadDependencyVec_8_1 = 1'b1;
    p_io_loadDependencyVec_8_1 = g_io_loadDependencyVec_8_1;
    if (g_io_loadDependencyVec_8_2 !== p_io_loadDependencyVec_8_2) tog_io_loadDependencyVec_8_2 = 1'b1;
    p_io_loadDependencyVec_8_2 = g_io_loadDependencyVec_8_2;
    if (g_io_loadDependencyVec_9_0 !== p_io_loadDependencyVec_9_0) tog_io_loadDependencyVec_9_0 = 1'b1;
    p_io_loadDependencyVec_9_0 = g_io_loadDependencyVec_9_0;
    if (g_io_loadDependencyVec_9_1 !== p_io_loadDependencyVec_9_1) tog_io_loadDependencyVec_9_1 = 1'b1;
    p_io_loadDependencyVec_9_1 = g_io_loadDependencyVec_9_1;
    if (g_io_loadDependencyVec_9_2 !== p_io_loadDependencyVec_9_2) tog_io_loadDependencyVec_9_2 = 1'b1;
    p_io_loadDependencyVec_9_2 = g_io_loadDependencyVec_9_2;
    if (g_io_loadDependencyVec_10_0 !== p_io_loadDependencyVec_10_0) tog_io_loadDependencyVec_10_0 = 1'b1;
    p_io_loadDependencyVec_10_0 = g_io_loadDependencyVec_10_0;
    if (g_io_loadDependencyVec_10_1 !== p_io_loadDependencyVec_10_1) tog_io_loadDependencyVec_10_1 = 1'b1;
    p_io_loadDependencyVec_10_1 = g_io_loadDependencyVec_10_1;
    if (g_io_loadDependencyVec_10_2 !== p_io_loadDependencyVec_10_2) tog_io_loadDependencyVec_10_2 = 1'b1;
    p_io_loadDependencyVec_10_2 = g_io_loadDependencyVec_10_2;
    if (g_io_loadDependencyVec_11_0 !== p_io_loadDependencyVec_11_0) tog_io_loadDependencyVec_11_0 = 1'b1;
    p_io_loadDependencyVec_11_0 = g_io_loadDependencyVec_11_0;
    if (g_io_loadDependencyVec_11_1 !== p_io_loadDependencyVec_11_1) tog_io_loadDependencyVec_11_1 = 1'b1;
    p_io_loadDependencyVec_11_1 = g_io_loadDependencyVec_11_1;
    if (g_io_loadDependencyVec_11_2 !== p_io_loadDependencyVec_11_2) tog_io_loadDependencyVec_11_2 = 1'b1;
    p_io_loadDependencyVec_11_2 = g_io_loadDependencyVec_11_2;
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
    io_writePorts_0_wen = '0;
    io_writePorts_0_addr = '0;
    io_writePorts_0_tag = '0;
    io_writePorts_0_loadDependency_1 = '0;
    io_writePorts_0_loadDependency_2 = '0;
    io_writePorts_1_wen = '0;
    io_writePorts_1_addr = '0;
    io_writePorts_1_tag = '0;
    io_writePorts_1_loadDependency_0 = '0;
    io_writePorts_1_loadDependency_2 = '0;
    io_writePorts_2_wen = '0;
    io_writePorts_2_addr = '0;
    io_writePorts_2_tag = '0;
    io_writePorts_2_loadDependency_0 = '0;
    io_writePorts_2_loadDependency_1 = '0;
    io_cancelVec_0 = '0;
    io_cancelVec_1 = '0;
    io_cancelVec_2 = '0;
    io_cancelVec_3 = '0;
    io_cancelVec_4 = '0;
    io_cancelVec_5 = '0;
    io_cancelVec_6 = '0;
    io_cancelVec_7 = '0;
    io_cancelVec_8 = '0;
    io_cancelVec_9 = '0;
    io_cancelVec_10 = '0;
    io_cancelVec_11 = '0;
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
    p_io_validVec_0 = '0; tog_io_validVec_0 = 1'b0;
    p_io_validVec_1 = '0; tog_io_validVec_1 = 1'b0;
    p_io_validVec_2 = '0; tog_io_validVec_2 = 1'b0;
    p_io_validVec_3 = '0; tog_io_validVec_3 = 1'b0;
    p_io_validVec_4 = '0; tog_io_validVec_4 = 1'b0;
    p_io_validVec_5 = '0; tog_io_validVec_5 = 1'b0;
    p_io_validVec_6 = '0; tog_io_validVec_6 = 1'b0;
    p_io_validVec_7 = '0; tog_io_validVec_7 = 1'b0;
    p_io_validVec_8 = '0; tog_io_validVec_8 = 1'b0;
    p_io_validVec_9 = '0; tog_io_validVec_9 = 1'b0;
    p_io_validVec_10 = '0; tog_io_validVec_10 = 1'b0;
    p_io_validVec_11 = '0; tog_io_validVec_11 = 1'b0;
    p_io_tagVec_0 = '0; tog_io_tagVec_0 = 1'b0;
    p_io_tagVec_1 = '0; tog_io_tagVec_1 = 1'b0;
    p_io_tagVec_2 = '0; tog_io_tagVec_2 = 1'b0;
    p_io_tagVec_3 = '0; tog_io_tagVec_3 = 1'b0;
    p_io_tagVec_4 = '0; tog_io_tagVec_4 = 1'b0;
    p_io_tagVec_5 = '0; tog_io_tagVec_5 = 1'b0;
    p_io_tagVec_6 = '0; tog_io_tagVec_6 = 1'b0;
    p_io_tagVec_7 = '0; tog_io_tagVec_7 = 1'b0;
    p_io_tagVec_8 = '0; tog_io_tagVec_8 = 1'b0;
    p_io_tagVec_9 = '0; tog_io_tagVec_9 = 1'b0;
    p_io_tagVec_10 = '0; tog_io_tagVec_10 = 1'b0;
    p_io_tagVec_11 = '0; tog_io_tagVec_11 = 1'b0;
    p_io_loadDependencyVec_0_0 = '0; tog_io_loadDependencyVec_0_0 = 1'b0;
    p_io_loadDependencyVec_0_1 = '0; tog_io_loadDependencyVec_0_1 = 1'b0;
    p_io_loadDependencyVec_0_2 = '0; tog_io_loadDependencyVec_0_2 = 1'b0;
    p_io_loadDependencyVec_1_0 = '0; tog_io_loadDependencyVec_1_0 = 1'b0;
    p_io_loadDependencyVec_1_1 = '0; tog_io_loadDependencyVec_1_1 = 1'b0;
    p_io_loadDependencyVec_1_2 = '0; tog_io_loadDependencyVec_1_2 = 1'b0;
    p_io_loadDependencyVec_2_0 = '0; tog_io_loadDependencyVec_2_0 = 1'b0;
    p_io_loadDependencyVec_2_1 = '0; tog_io_loadDependencyVec_2_1 = 1'b0;
    p_io_loadDependencyVec_2_2 = '0; tog_io_loadDependencyVec_2_2 = 1'b0;
    p_io_loadDependencyVec_3_0 = '0; tog_io_loadDependencyVec_3_0 = 1'b0;
    p_io_loadDependencyVec_3_1 = '0; tog_io_loadDependencyVec_3_1 = 1'b0;
    p_io_loadDependencyVec_3_2 = '0; tog_io_loadDependencyVec_3_2 = 1'b0;
    p_io_loadDependencyVec_4_0 = '0; tog_io_loadDependencyVec_4_0 = 1'b0;
    p_io_loadDependencyVec_4_1 = '0; tog_io_loadDependencyVec_4_1 = 1'b0;
    p_io_loadDependencyVec_4_2 = '0; tog_io_loadDependencyVec_4_2 = 1'b0;
    p_io_loadDependencyVec_5_0 = '0; tog_io_loadDependencyVec_5_0 = 1'b0;
    p_io_loadDependencyVec_5_1 = '0; tog_io_loadDependencyVec_5_1 = 1'b0;
    p_io_loadDependencyVec_5_2 = '0; tog_io_loadDependencyVec_5_2 = 1'b0;
    p_io_loadDependencyVec_6_0 = '0; tog_io_loadDependencyVec_6_0 = 1'b0;
    p_io_loadDependencyVec_6_1 = '0; tog_io_loadDependencyVec_6_1 = 1'b0;
    p_io_loadDependencyVec_6_2 = '0; tog_io_loadDependencyVec_6_2 = 1'b0;
    p_io_loadDependencyVec_7_0 = '0; tog_io_loadDependencyVec_7_0 = 1'b0;
    p_io_loadDependencyVec_7_1 = '0; tog_io_loadDependencyVec_7_1 = 1'b0;
    p_io_loadDependencyVec_7_2 = '0; tog_io_loadDependencyVec_7_2 = 1'b0;
    p_io_loadDependencyVec_8_0 = '0; tog_io_loadDependencyVec_8_0 = 1'b0;
    p_io_loadDependencyVec_8_1 = '0; tog_io_loadDependencyVec_8_1 = 1'b0;
    p_io_loadDependencyVec_8_2 = '0; tog_io_loadDependencyVec_8_2 = 1'b0;
    p_io_loadDependencyVec_9_0 = '0; tog_io_loadDependencyVec_9_0 = 1'b0;
    p_io_loadDependencyVec_9_1 = '0; tog_io_loadDependencyVec_9_1 = 1'b0;
    p_io_loadDependencyVec_9_2 = '0; tog_io_loadDependencyVec_9_2 = 1'b0;
    p_io_loadDependencyVec_10_0 = '0; tog_io_loadDependencyVec_10_0 = 1'b0;
    p_io_loadDependencyVec_10_1 = '0; tog_io_loadDependencyVec_10_1 = 1'b0;
    p_io_loadDependencyVec_10_2 = '0; tog_io_loadDependencyVec_10_2 = 1'b0;
    p_io_loadDependencyVec_11_0 = '0; tog_io_loadDependencyVec_11_0 = 1'b0;
    p_io_loadDependencyVec_11_1 = '0; tog_io_loadDependencyVec_11_1 = 1'b0;
    p_io_loadDependencyVec_11_2 = '0; tog_io_loadDependencyVec_11_2 = 1'b0;
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
    if (tog_io_validVec_0) toggled++; else $display("COV: output io_validVec_0 never toggled");
    if (tog_io_validVec_1) toggled++; else $display("COV: output io_validVec_1 never toggled");
    if (tog_io_validVec_2) toggled++; else $display("COV: output io_validVec_2 never toggled");
    if (tog_io_validVec_3) toggled++; else $display("COV: output io_validVec_3 never toggled");
    if (tog_io_validVec_4) toggled++; else $display("COV: output io_validVec_4 never toggled");
    if (tog_io_validVec_5) toggled++; else $display("COV: output io_validVec_5 never toggled");
    if (tog_io_validVec_6) toggled++; else $display("COV: output io_validVec_6 never toggled");
    if (tog_io_validVec_7) toggled++; else $display("COV: output io_validVec_7 never toggled");
    if (tog_io_validVec_8) toggled++; else $display("COV: output io_validVec_8 never toggled");
    if (tog_io_validVec_9) toggled++; else $display("COV: output io_validVec_9 never toggled");
    if (tog_io_validVec_10) toggled++; else $display("COV: output io_validVec_10 never toggled");
    if (tog_io_validVec_11) toggled++; else $display("COV: output io_validVec_11 never toggled");
    if (tog_io_tagVec_0) toggled++; else $display("COV: output io_tagVec_0 never toggled");
    if (tog_io_tagVec_1) toggled++; else $display("COV: output io_tagVec_1 never toggled");
    if (tog_io_tagVec_2) toggled++; else $display("COV: output io_tagVec_2 never toggled");
    if (tog_io_tagVec_3) toggled++; else $display("COV: output io_tagVec_3 never toggled");
    if (tog_io_tagVec_4) toggled++; else $display("COV: output io_tagVec_4 never toggled");
    if (tog_io_tagVec_5) toggled++; else $display("COV: output io_tagVec_5 never toggled");
    if (tog_io_tagVec_6) toggled++; else $display("COV: output io_tagVec_6 never toggled");
    if (tog_io_tagVec_7) toggled++; else $display("COV: output io_tagVec_7 never toggled");
    if (tog_io_tagVec_8) toggled++; else $display("COV: output io_tagVec_8 never toggled");
    if (tog_io_tagVec_9) toggled++; else $display("COV: output io_tagVec_9 never toggled");
    if (tog_io_tagVec_10) toggled++; else $display("COV: output io_tagVec_10 never toggled");
    if (tog_io_tagVec_11) toggled++; else $display("COV: output io_tagVec_11 never toggled");
    if (tog_io_loadDependencyVec_0_0) toggled++; else $display("COV: output io_loadDependencyVec_0_0 never toggled");
    if (tog_io_loadDependencyVec_0_1) toggled++; else $display("COV: output io_loadDependencyVec_0_1 never toggled");
    if (tog_io_loadDependencyVec_0_2) toggled++; else $display("COV: output io_loadDependencyVec_0_2 never toggled");
    if (tog_io_loadDependencyVec_1_0) toggled++; else $display("COV: output io_loadDependencyVec_1_0 never toggled");
    if (tog_io_loadDependencyVec_1_1) toggled++; else $display("COV: output io_loadDependencyVec_1_1 never toggled");
    if (tog_io_loadDependencyVec_1_2) toggled++; else $display("COV: output io_loadDependencyVec_1_2 never toggled");
    if (tog_io_loadDependencyVec_2_0) toggled++; else $display("COV: output io_loadDependencyVec_2_0 never toggled");
    if (tog_io_loadDependencyVec_2_1) toggled++; else $display("COV: output io_loadDependencyVec_2_1 never toggled");
    if (tog_io_loadDependencyVec_2_2) toggled++; else $display("COV: output io_loadDependencyVec_2_2 never toggled");
    if (tog_io_loadDependencyVec_3_0) toggled++; else $display("COV: output io_loadDependencyVec_3_0 never toggled");
    if (tog_io_loadDependencyVec_3_1) toggled++; else $display("COV: output io_loadDependencyVec_3_1 never toggled");
    if (tog_io_loadDependencyVec_3_2) toggled++; else $display("COV: output io_loadDependencyVec_3_2 never toggled");
    if (tog_io_loadDependencyVec_4_0) toggled++; else $display("COV: output io_loadDependencyVec_4_0 never toggled");
    if (tog_io_loadDependencyVec_4_1) toggled++; else $display("COV: output io_loadDependencyVec_4_1 never toggled");
    if (tog_io_loadDependencyVec_4_2) toggled++; else $display("COV: output io_loadDependencyVec_4_2 never toggled");
    if (tog_io_loadDependencyVec_5_0) toggled++; else $display("COV: output io_loadDependencyVec_5_0 never toggled");
    if (tog_io_loadDependencyVec_5_1) toggled++; else $display("COV: output io_loadDependencyVec_5_1 never toggled");
    if (tog_io_loadDependencyVec_5_2) toggled++; else $display("COV: output io_loadDependencyVec_5_2 never toggled");
    if (tog_io_loadDependencyVec_6_0) toggled++; else $display("COV: output io_loadDependencyVec_6_0 never toggled");
    if (tog_io_loadDependencyVec_6_1) toggled++; else $display("COV: output io_loadDependencyVec_6_1 never toggled");
    if (tog_io_loadDependencyVec_6_2) toggled++; else $display("COV: output io_loadDependencyVec_6_2 never toggled");
    if (tog_io_loadDependencyVec_7_0) toggled++; else $display("COV: output io_loadDependencyVec_7_0 never toggled");
    if (tog_io_loadDependencyVec_7_1) toggled++; else $display("COV: output io_loadDependencyVec_7_1 never toggled");
    if (tog_io_loadDependencyVec_7_2) toggled++; else $display("COV: output io_loadDependencyVec_7_2 never toggled");
    if (tog_io_loadDependencyVec_8_0) toggled++; else $display("COV: output io_loadDependencyVec_8_0 never toggled");
    if (tog_io_loadDependencyVec_8_1) toggled++; else $display("COV: output io_loadDependencyVec_8_1 never toggled");
    if (tog_io_loadDependencyVec_8_2) toggled++; else $display("COV: output io_loadDependencyVec_8_2 never toggled");
    if (tog_io_loadDependencyVec_9_0) toggled++; else $display("COV: output io_loadDependencyVec_9_0 never toggled");
    if (tog_io_loadDependencyVec_9_1) toggled++; else $display("COV: output io_loadDependencyVec_9_1 never toggled");
    if (tog_io_loadDependencyVec_9_2) toggled++; else $display("COV: output io_loadDependencyVec_9_2 never toggled");
    if (tog_io_loadDependencyVec_10_0) toggled++; else $display("COV: output io_loadDependencyVec_10_0 never toggled");
    if (tog_io_loadDependencyVec_10_1) toggled++; else $display("COV: output io_loadDependencyVec_10_1 never toggled");
    if (tog_io_loadDependencyVec_10_2) toggled++; else $display("COV: output io_loadDependencyVec_10_2 never toggled");
    if (tog_io_loadDependencyVec_11_0) toggled++; else $display("COV: output io_loadDependencyVec_11_0 never toggled");
    if (tog_io_loadDependencyVec_11_1) toggled++; else $display("COV: output io_loadDependencyVec_11_1 never toggled");
    if (tog_io_loadDependencyVec_11_2) toggled++; else $display("COV: output io_loadDependencyVec_11_2 never toggled");
    $display("RegCacheTagModule_1 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
