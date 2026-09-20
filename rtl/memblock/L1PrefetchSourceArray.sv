// =============================================================================
// L1PrefetchSourceArray —— L1 DCache「这条 cacheline 最初由谁预取进来」阵列（薄 wrapper）
//
// 对应 Chisel: AsynchronousMetaArray.scala  class L1PrefetchSourceArray
// 例化处:     DCacheWrapper.scala:1022  DCache.prefetchArray
//               new L1PrefetchSourceArray(readPorts = PrefetchArrayReadPort = 5,
//                                         writePorts = 1 + LoadPipelineWidth = 4)
//
// 它在 DCache 里干什么：每路存 3 位 L1PfSource（是 stream / stride / SMS / 还是
//   根本不是预取引入的）。配合 accessArray 的"访问过没有"，PrefetcherMonitor 就能
//   分档统计每个预取器的好坏（DCacheWrapper.scala:1197-1201）。
//   3 条 load 流水各一个写口 + mainPipe 一个写口（coh 变 Nothing 时清预取标记）。
//
// 本变体在家族里的位置（差异维度见 xs_l1_meta_array_core.sv 文件头的对照表）：
//   DATA_W=3  读口 5  写口 4  ★旁路只看 S1，没有 S0 那条★
//   ★写口 0/1/2 数据被常数折叠为 3'h1★
//
//   ★只有 S1 旁路★：这不是被优化掉的。Chisel 里这个 class 的旁路只写了 S1 一条
//     when（AsynchronousMetaArray.scala:287-291），而 L1ErrorMetaArray 写了 S1、S0
//     两条。所以同拍发起的写不会被转发给读口 —— 是设计如此，照抄。
//   ★常数折叠★：0/1/2 号写口来自 load 流水的 prefetch_flag_write，source 端在
//     DCache 里恒为常数 1；firtool 跨模块传播后删掉了这三个口的数据端口。
//
// golden 11923 行；真逻辑是 Chisel 的 59 行（AsynchronousMetaArray.scala:269-327）。
// 逻辑全部在参数化核 xs_l1_meta_array_core（同目录）；本文件只做端口展平与改名。
// =============================================================================
module L1PrefetchSourceArray(
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
  output [2:0] io_resp_0_0,
  output [2:0] io_resp_0_1,
  output [2:0] io_resp_0_2,
  output [2:0] io_resp_0_3,
  output [2:0] io_resp_1_0,
  output [2:0] io_resp_1_1,
  output [2:0] io_resp_1_2,
  output [2:0] io_resp_1_3,
  output [2:0] io_resp_2_0,
  output [2:0] io_resp_2_1,
  output [2:0] io_resp_2_2,
  output [2:0] io_resp_2_3,
  output [2:0] io_resp_3_0,
  output [2:0] io_resp_3_1,
  output [2:0] io_resp_3_2,
  output [2:0] io_resp_3_3,
  output [2:0] io_resp_4_0,
  output [2:0] io_resp_4_1,
  output [2:0] io_resp_4_2,
  output [2:0] io_resp_4_3,
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
  input  [2:0] io_write_3_bits_source
);
  logic       rvalid [5];
  logic [7:0] ridx   [5];
  logic [2:0] resp   [5][4];
  logic       wvalid [4];
  logic [7:0] widx   [4];
  logic [3:0] wen    [4];
  logic [2:0] wdata  [4];

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
    wdata[0]  = 3'h1;  // 常数口: 核按 WDATA_IS_CONST 走常数, 不看这个值; 这里驱成同一常数只为读起来一目了然
    wvalid[1] = io_write_1_valid;
    widx[1]   = io_write_1_bits_idx;
    wen[1]    = io_write_1_bits_way_en;
    wdata[1]  = 3'h1;  // 常数口: 核按 WDATA_IS_CONST 走常数, 不看这个值; 这里驱成同一常数只为读起来一目了然
    wvalid[2] = io_write_2_valid;
    widx[2]   = io_write_2_bits_idx;
    wen[2]    = io_write_2_bits_way_en;
    wdata[2]  = 3'h1;  // 常数口: 核按 WDATA_IS_CONST 走常数, 不看这个值; 这里驱成同一常数只为读起来一目了然
    wvalid[3] = io_write_3_valid;
    widx[3]   = io_write_3_bits_idx;
    wen[3]    = io_write_3_bits_way_en;
    wdata[3]  = io_write_3_bits_source;
  end

  xs_l1_meta_array_core #(
    .N_SETS(256), .IDX_BITS(8), .N_WAYS(4), .DATA_W(3),
    .READ_PORTS(5), .WRITE_PORTS(4),
    .HAS_BYPASS(1'b1), .BYPASS_S0(1'b0),
    .WDATA_IS_CONST(32'h7), .WDATA_CONST(3'h1)
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
