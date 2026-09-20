// =============================================================================
// L1FlagMetaArray —— L1 DCache「这条 cacheline 被访问过」标志阵列（薄 wrapper）
//
// 对应 Chisel: AsynchronousMetaArray.scala  class L1FlagMetaArray
// 例化处:     DCacheWrapper.scala:1023  DCache.accessArray
//               new L1FlagMetaArray(readPorts = AccessArrayReadPort = 5,
//                                   writePorts = LoadPipelineWidth + 1 = 4)
//               —— enableBypass **没传**，取默认值 false。
//
// 它在 DCache 里干什么：给预取器算准确率。prefetchArray 记"这条线是被谁预取进来的"，
//   本阵列记"它后来到底被用过没有"；PrefetcherMonitor 拿两者一起判 good/bad prefetch
//   （DCacheWrapper.scala:1197-1201）。3 条 load 流水各一个写口（命中即置位）+
//   mainPipe 一个写口（可清位）；读口 5 个 = 3 load + 1 mainPipe + 1 预取器专用。
//
// 本变体在家族里的位置（差异维度见 xs_l1_meta_array_core.sv 文件头的对照表）：
//   DATA_W=1  读口 5  写口 4  ★无旁路★  ★写口 0/1/2 数据被常数折叠为 1'b1★
//
//   ★无旁路不是被优化掉的，是设计就没有★：Chisel 的 enableBypass 默认 false，
//     DCache 例化时也没传 true，于是 resp 直接取 meta_array(RegEnable(idx))，
//     连旁路判定表达式都成了死码被 firtool 消掉。存的是"访问过没有"，读到旧值
//     只让预取统计差一拍，没有功能影响。
//   ★常数折叠★：0/1/2 号写口来自三条 load 流水的 access_flag_write，数据端在
//     DCache 里恒为 true.B（命中就置位）。firtool 跨模块传播后把这三个口的数据
//     端口整个删掉 —— golden 端口表里确实只有 io_write_3_bits_flag。
//
// golden 12691 行；真逻辑是 Chisel 的 62 行（AsynchronousMetaArray.scala:126-195）。
// 逻辑全部在参数化核 xs_l1_meta_array_core（同目录）；本文件只做端口展平与改名。
// =============================================================================
module L1FlagMetaArray(
  input        clock,
  input        reset,
  input        io_read_0_valid,
  input  [7:0] io_read_0_bits_idx,
  input        io_read_1_valid,
  input  [7:0] io_read_1_bits_idx,
  input        io_read_2_valid,
  input  [7:0] io_read_2_bits_idx,
  input        io_read_3_valid,
  input  [7:0] io_read_3_bits_idx,
  input        io_read_4_valid,
  input  [7:0] io_read_4_bits_idx,
  output       io_resp_0_0,
  output       io_resp_0_1,
  output       io_resp_0_2,
  output       io_resp_0_3,
  output       io_resp_1_0,
  output       io_resp_1_1,
  output       io_resp_1_2,
  output       io_resp_1_3,
  output       io_resp_2_0,
  output       io_resp_2_1,
  output       io_resp_2_2,
  output       io_resp_2_3,
  output       io_resp_3_0,
  output       io_resp_3_1,
  output       io_resp_3_2,
  output       io_resp_3_3,
  output       io_resp_4_0,
  output       io_resp_4_1,
  output       io_resp_4_2,
  output       io_resp_4_3,
  input        io_write_0_valid,
  input  [7:0] io_write_0_bits_idx,
  input  [3:0] io_write_0_bits_way_en,
  input        io_write_1_valid,
  input  [7:0] io_write_1_bits_idx,
  input  [3:0] io_write_1_bits_way_en,
  input        io_write_2_valid,
  input  [7:0] io_write_2_bits_idx,
  input  [3:0] io_write_2_bits_way_en,
  input        io_write_3_valid,
  input  [7:0] io_write_3_bits_idx,
  input  [3:0] io_write_3_bits_way_en,
  input        io_write_3_bits_flag
);
  logic       rvalid [5];
  logic [7:0] ridx   [5];
  logic [0:0] resp   [5][4];
  logic       wvalid [4];
  logic [7:0] widx   [4];
  logic [3:0] wen    [4];
  logic [0:0] wdata  [4];

  always_comb begin
    rvalid[0] = io_read_0_valid;
    ridx[0]   = io_read_0_bits_idx;
    rvalid[1] = io_read_1_valid;
    ridx[1]   = io_read_1_bits_idx;
    rvalid[2] = io_read_2_valid;
    ridx[2]   = io_read_2_bits_idx;
    rvalid[3] = io_read_3_valid;
    ridx[3]   = io_read_3_bits_idx;
    rvalid[4] = io_read_4_valid;
    ridx[4]   = io_read_4_bits_idx;
    wvalid[0] = io_write_0_valid;
    widx[0]   = io_write_0_bits_idx;
    wen[0]    = io_write_0_bits_way_en;
    wdata[0]  = 1'b1;  // 常数口: 核按 WDATA_IS_CONST 走常数, 不看这个值; 这里驱成同一常数只为读起来一目了然
    wvalid[1] = io_write_1_valid;
    widx[1]   = io_write_1_bits_idx;
    wen[1]    = io_write_1_bits_way_en;
    wdata[1]  = 1'b1;  // 常数口: 核按 WDATA_IS_CONST 走常数, 不看这个值; 这里驱成同一常数只为读起来一目了然
    wvalid[2] = io_write_2_valid;
    widx[2]   = io_write_2_bits_idx;
    wen[2]    = io_write_2_bits_way_en;
    wdata[2]  = 1'b1;  // 常数口: 核按 WDATA_IS_CONST 走常数, 不看这个值; 这里驱成同一常数只为读起来一目了然
    wvalid[3] = io_write_3_valid;
    widx[3]   = io_write_3_bits_idx;
    wen[3]    = io_write_3_bits_way_en;
    wdata[3]  = io_write_3_bits_flag;
  end

  xs_l1_meta_array_core #(
    .N_SETS(256), .IDX_BITS(8), .N_WAYS(4), .DATA_W(1),
    .READ_PORTS(5), .WRITE_PORTS(4),
    .HAS_BYPASS(1'b0), .BYPASS_S0(1'b0),
    .WDATA_IS_CONST(32'h7), .WDATA_CONST(1'b1)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),
    .io_write_valid(wvalid), .io_write_idx(widx),
    .io_write_way_en(wen), .io_write_data(wdata)
  );

  assign io_resp_0_0 = resp[0][0];
  assign io_resp_0_1 = resp[0][1];
  assign io_resp_0_2 = resp[0][2];
  assign io_resp_0_3 = resp[0][3];
  assign io_resp_1_0 = resp[1][0];
  assign io_resp_1_1 = resp[1][1];
  assign io_resp_1_2 = resp[1][2];
  assign io_resp_1_3 = resp[1][3];
  assign io_resp_2_0 = resp[2][0];
  assign io_resp_2_1 = resp[2][1];
  assign io_resp_2_2 = resp[2][2];
  assign io_resp_2_3 = resp[2][3];
  assign io_resp_3_0 = resp[3][0];
  assign io_resp_3_1 = resp[3][1];
  assign io_resp_3_2 = resp[3][2];
  assign io_resp_3_3 = resp[3][3];
  assign io_resp_4_0 = resp[4][0];
  assign io_resp_4_1 = resp[4][1];
  assign io_resp_4_2 = resp[4][2];
  assign io_resp_4_3 = resp[4][3];
endmodule
