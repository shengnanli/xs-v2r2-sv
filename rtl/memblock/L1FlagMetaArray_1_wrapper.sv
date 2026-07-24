// 自动生成：scripts/gen_l1metaarray.py —— 勿手改
// L1 元数据阵列 golden 同名 / xs 变体扁平包装：扁平端口 <-> 可读核数组端口。
module L1FlagMetaArray_1 import xs_l1metaarray_pkg::*; (
  input clock,
  input reset,
  input io_read_0_valid,
  input [7:0] io_read_0_bits_idx,
  input io_read_1_valid,
  input [7:0] io_read_1_bits_idx,
  input io_read_2_valid,
  input [7:0] io_read_2_bits_idx,
  input io_read_3_valid,
  input [7:0] io_read_3_bits_idx,
  input io_read_4_valid,
  input [7:0] io_read_4_bits_idx,
  output io_resp_0_0,
  output io_resp_0_1,
  output io_resp_0_2,
  output io_resp_0_3,
  output io_resp_1_0,
  output io_resp_1_1,
  output io_resp_1_2,
  output io_resp_1_3,
  output io_resp_2_0,
  output io_resp_2_1,
  output io_resp_2_2,
  output io_resp_2_3,
  output io_resp_3_0,
  output io_resp_3_1,
  output io_resp_3_2,
  output io_resp_3_3,
  output io_resp_4_0,
  output io_resp_4_1,
  output io_resp_4_2,
  output io_resp_4_3,
  input io_write_0_valid,
  input [7:0] io_write_0_bits_idx,
  input [3:0] io_write_0_bits_way_en,
  input io_write_1_valid,
  input [7:0] io_write_1_bits_idx,
  input [3:0] io_write_1_bits_way_en,
  input io_write_2_valid,
  input [7:0] io_write_2_bits_idx,
  input [3:0] io_write_2_bits_way_en,
  input io_write_3_valid,
  input [7:0] io_write_3_bits_idx,
  input [3:0] io_write_3_bits_way_en,
  input io_write_3_bits_flag
);
  logic                rvalid [5];
  logic [7:0] ridx   [5];
  logic                wvalid [4];
  logic [7:0] widx   [4];
  logic [3:0]   wen    [4];
  logic                resp   [5][4];
  logic                wdata  [4];
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
    wdata[0] = 1'b1;  // 父模块 tie-off：写口0 恒写 flag=1
    wvalid[1] = io_write_1_valid;
    widx[1]   = io_write_1_bits_idx;
    wen[1]    = io_write_1_bits_way_en;
    wdata[1] = 1'b1;  // 父模块 tie-off：写口1 恒写 flag=1
    wvalid[2] = io_write_2_valid;
    widx[2]   = io_write_2_bits_idx;
    wen[2]    = io_write_2_bits_way_en;
    wdata[2] = 1'b1;  // 父模块 tie-off：写口2 恒写 flag=1
    wvalid[3] = io_write_3_valid;
    widx[3]   = io_write_3_bits_idx;
    wen[3]    = io_write_3_bits_way_en;
    wdata[3] = io_write_3_bits_flag;
  end
  // 写口 0/1/2 的 flag 被父模块 tie-off 为常量 1（见上 wdata[0..2]=1'b1），写口 3 为真实 flag。
  // 与 golden 一致：常量口不生成 s1_way_wdata 寄存器。
  xs_L1FlagMetaArray_core #(
    .READ_PORTS(5), .WRITE_PORTS(4),
    .WDATA_CONST_MASK(4'b0111), .WDATA_CONST_VAL(4'b0111)
  ) u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),
    .io_write_valid(wvalid), .io_write_idx(widx),
    .io_write_way_en(wen), .io_write_flag(wdata)
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
