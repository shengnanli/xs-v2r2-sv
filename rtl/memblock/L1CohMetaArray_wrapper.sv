// 自动生成：scripts/gen_l1metaarray.py —— 勿手改
// L1 元数据阵列 golden 同名 / xs 变体扁平包装：扁平端口 <-> 可读核数组端口。
module L1CohMetaArray import xs_l1metaarray_pkg::*; (
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
  output [1:0] io_resp_0_0_coh_state,
  output [1:0] io_resp_0_1_coh_state,
  output [1:0] io_resp_0_2_coh_state,
  output [1:0] io_resp_0_3_coh_state,
  output [1:0] io_resp_1_0_coh_state,
  output [1:0] io_resp_1_1_coh_state,
  output [1:0] io_resp_1_2_coh_state,
  output [1:0] io_resp_1_3_coh_state,
  output [1:0] io_resp_2_0_coh_state,
  output [1:0] io_resp_2_1_coh_state,
  output [1:0] io_resp_2_2_coh_state,
  output [1:0] io_resp_2_3_coh_state,
  output [1:0] io_resp_3_0_coh_state,
  output [1:0] io_resp_3_1_coh_state,
  output [1:0] io_resp_3_2_coh_state,
  output [1:0] io_resp_3_3_coh_state,
  input io_write_0_valid,
  input [7:0] io_write_0_bits_idx,
  input [3:0] io_write_0_bits_way_en,
  input [1:0] io_write_0_bits_meta_coh_state
);
  logic                rvalid [4];
  logic [7:0] ridx   [4];
  logic                wvalid [1];
  logic [7:0] widx   [1];
  logic [3:0]   wen    [1];
  meta_coh_t           resp   [4][4];
  meta_coh_t           wdata  [1];
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
    wdata[0].coh_state = io_write_0_bits_meta_coh_state;
  end
  xs_L1CohMetaArray_core #(.READ_PORTS(4), .WRITE_PORTS(1)) u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),
    .io_write_valid(wvalid), .io_write_idx(widx),
    .io_write_way_en(wen), .io_write_meta(wdata)
  );
  assign io_resp_0_0_coh_state = resp[0][0].coh_state;
  assign io_resp_0_1_coh_state = resp[0][1].coh_state;
  assign io_resp_0_2_coh_state = resp[0][2].coh_state;
  assign io_resp_0_3_coh_state = resp[0][3].coh_state;
  assign io_resp_1_0_coh_state = resp[1][0].coh_state;
  assign io_resp_1_1_coh_state = resp[1][1].coh_state;
  assign io_resp_1_2_coh_state = resp[1][2].coh_state;
  assign io_resp_1_3_coh_state = resp[1][3].coh_state;
  assign io_resp_2_0_coh_state = resp[2][0].coh_state;
  assign io_resp_2_1_coh_state = resp[2][1].coh_state;
  assign io_resp_2_2_coh_state = resp[2][2].coh_state;
  assign io_resp_2_3_coh_state = resp[2][3].coh_state;
  assign io_resp_3_0_coh_state = resp[3][0].coh_state;
  assign io_resp_3_1_coh_state = resp[3][1].coh_state;
  assign io_resp_3_2_coh_state = resp[3][2].coh_state;
  assign io_resp_3_3_coh_state = resp[3][3].coh_state;
endmodule
