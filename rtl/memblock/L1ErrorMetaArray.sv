// =============================================================================
// L1ErrorMetaArray —— L1 DCache 错误(TLError)元数据阵列：记录每条 cacheline 上一次
//                     访问带回来的 TileLink 错误位 {denied, corrupt}（薄 wrapper）
//
// 对应 Chisel: AsynchronousMetaArray.scala  class L1ErrorMetaArray
// 例化处:     DCacheWrapper.scala:1021  DCache.errorArray
//               new L1ErrorMetaArray(readPorts = LoadPipelineWidth + 1 = 4,
//                                    writePorts = 1, enableBypass = true)
//
// 它在 DCache 里干什么：TileLink 的 D 通道响应带 denied（请求被拒，地址不可访问）
//   与 corrupt（数据损坏）两个标志。refill 一条 cacheline 时把这两位记在 (set, way)
//   上；之后命中这条线的 load 把它们跟数据一起送回 LSU，转成访存异常/硬件错误上报。
//   3 条 load 流水 + 1 条 main pipe 共 4 个读口，mainPipe 的 error_flag_write 是唯一写口。
//   本阵列不做 tag 命中判断：读只给 idx，一次返回该 set 全部 4 路。
//
// 本变体在家族里的位置（差异维度见 xs_l1_meta_array_core.sv 文件头的对照表）：
//   DATA_W=2（denied/corrupt 两位）  读口 4  写口 1  旁路 S1+S0  无常数折叠写口
//   ——三个变体里只有它带 S0 旁路，也只有它的写口数据端一个都没被常数折叠。
//
// golden 14951 行的来历：firtool 把 1024 个条目逐条展平（2048 条 reg 声明、
//   8 条 256 位 concat 向量、一个含 4096 条非阻塞赋值的 always 块、4197 行随机
//   初始化块）。真逻辑是 Chisel 的 66 行（AsynchronousMetaArray.scala:197-262）。
//
// 逻辑全部在参数化核 xs_l1_meta_array_core（同目录）；本文件只做端口展平与改名。
// =============================================================================
module L1ErrorMetaArray(
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
  output       io_resp_0_0_tl_denied,
  output       io_resp_0_0_tl_corrupt,
  output       io_resp_0_1_tl_denied,
  output       io_resp_0_1_tl_corrupt,
  output       io_resp_0_2_tl_denied,
  output       io_resp_0_2_tl_corrupt,
  output       io_resp_0_3_tl_denied,
  output       io_resp_0_3_tl_corrupt,
  output       io_resp_1_0_tl_denied,
  output       io_resp_1_0_tl_corrupt,
  output       io_resp_1_1_tl_denied,
  output       io_resp_1_1_tl_corrupt,
  output       io_resp_1_2_tl_denied,
  output       io_resp_1_2_tl_corrupt,
  output       io_resp_1_3_tl_denied,
  output       io_resp_1_3_tl_corrupt,
  output       io_resp_2_0_tl_denied,
  output       io_resp_2_0_tl_corrupt,
  output       io_resp_2_1_tl_denied,
  output       io_resp_2_1_tl_corrupt,
  output       io_resp_2_2_tl_denied,
  output       io_resp_2_2_tl_corrupt,
  output       io_resp_2_3_tl_denied,
  output       io_resp_2_3_tl_corrupt,
  output       io_resp_3_0_tl_denied,
  output       io_resp_3_0_tl_corrupt,
  output       io_resp_3_1_tl_denied,
  output       io_resp_3_1_tl_corrupt,
  output       io_resp_3_2_tl_denied,
  output       io_resp_3_2_tl_corrupt,
  output       io_resp_3_3_tl_denied,
  output       io_resp_3_3_tl_corrupt,
  input        io_write_0_valid,
  input  [7:0] io_write_0_bits_idx,
  input  [3:0] io_write_0_bits_way_en,
  input        io_write_0_bits_error_tl_denied,
  input        io_write_0_bits_error_tl_corrupt
);
  logic       rvalid [4];
  logic [7:0] ridx   [4];
  logic [1:0] resp   [4][4];
  logic       wvalid [1];
  logic [7:0] widx   [1];
  logic [3:0] wen    [1];
  logic [1:0] wdata  [1];

  always_comb begin
    rvalid[0] = io_read_0_valid;
    ridx[0]   = io_read_0_bits_idx;
    rvalid[1] = io_read_1_valid;
    ridx[1]   = io_read_1_bits_idx;
    rvalid[2] = io_read_2_valid;
    ridx[2]   = io_read_2_bits_idx;
    rvalid[3] = io_read_3_valid;
    ridx[3]   = io_read_3_bits_idx;
    wvalid[0] = io_write_0_valid;
    widx[0]   = io_write_0_bits_idx;
    wen[0]    = io_write_0_bits_way_en;
    wdata[0]  = {io_write_0_bits_error_tl_denied, io_write_0_bits_error_tl_corrupt};
  end

  xs_l1_meta_array_core #(
    .N_SETS(256), .IDX_BITS(8), .N_WAYS(4), .DATA_W(2),
    .READ_PORTS(4), .WRITE_PORTS(1),
    .HAS_BYPASS(1'b1), .BYPASS_S0(1'b1),
    .WDATA_IS_CONST(32'h0), .WDATA_CONST(2'b00)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),
    .io_write_valid(wvalid), .io_write_idx(widx),
    .io_write_way_en(wen), .io_write_data(wdata)
  );

  assign io_resp_0_0_tl_denied = resp[0][0][1];
  assign io_resp_0_0_tl_corrupt = resp[0][0][0];
  assign io_resp_0_1_tl_denied = resp[0][1][1];
  assign io_resp_0_1_tl_corrupt = resp[0][1][0];
  assign io_resp_0_2_tl_denied = resp[0][2][1];
  assign io_resp_0_2_tl_corrupt = resp[0][2][0];
  assign io_resp_0_3_tl_denied = resp[0][3][1];
  assign io_resp_0_3_tl_corrupt = resp[0][3][0];
  assign io_resp_1_0_tl_denied = resp[1][0][1];
  assign io_resp_1_0_tl_corrupt = resp[1][0][0];
  assign io_resp_1_1_tl_denied = resp[1][1][1];
  assign io_resp_1_1_tl_corrupt = resp[1][1][0];
  assign io_resp_1_2_tl_denied = resp[1][2][1];
  assign io_resp_1_2_tl_corrupt = resp[1][2][0];
  assign io_resp_1_3_tl_denied = resp[1][3][1];
  assign io_resp_1_3_tl_corrupt = resp[1][3][0];
  assign io_resp_2_0_tl_denied = resp[2][0][1];
  assign io_resp_2_0_tl_corrupt = resp[2][0][0];
  assign io_resp_2_1_tl_denied = resp[2][1][1];
  assign io_resp_2_1_tl_corrupt = resp[2][1][0];
  assign io_resp_2_2_tl_denied = resp[2][2][1];
  assign io_resp_2_2_tl_corrupt = resp[2][2][0];
  assign io_resp_2_3_tl_denied = resp[2][3][1];
  assign io_resp_2_3_tl_corrupt = resp[2][3][0];
  assign io_resp_3_0_tl_denied = resp[3][0][1];
  assign io_resp_3_0_tl_corrupt = resp[3][0][0];
  assign io_resp_3_1_tl_denied = resp[3][1][1];
  assign io_resp_3_1_tl_corrupt = resp[3][1][0];
  assign io_resp_3_2_tl_denied = resp[3][2][1];
  assign io_resp_3_2_tl_corrupt = resp[3][2][0];
  assign io_resp_3_3_tl_denied = resp[3][3][1];
  assign io_resp_3_3_tl_corrupt = resp[3][3][0];
endmodule
