// 负测台：证明 xs_IndexableCAMTemplate_core 的端口契约不变式真会拦下错参数。
// 这里复制 IndexableCAMTemplate_33 的 golden 端口表（8 位键 / 16 项 / 4 位索引），
// 但故意把传给核的参数抄成基础变体的 (ENTRY_WIDTH=9, NUM_ENTRIES=8)。
// 期望：core 里的 initial 不变式在 time 0 $fatal；若跑到 NEGTEST_UNREACHED 就说明
// 不变式形同虚设，Makefile 的 negtest 目标会判 FAIL。
module neg_cam_wrong_params(
  input        clock,
  input  [7:0] io_r_req_0_idx,
  output [15:0] io_r_resp,
  input        io_w_valid,
  input  [7:0] io_w_bits_data_idx,
  input  [3:0] io_w_bits_index
);
  logic [7:0] match8;
  xs_IndexableCAMTemplate_core #(
    .ENTRY_WIDTH(9), .NUM_ENTRIES(8),          // <-- 抄错：本应是 (8, 16)
    .PORT_KEY_W($bits(io_r_req_0_idx)), .PORT_IDX_W($bits(io_w_bits_index))
  ) u_core (
    .clock  (clock),
    .r_key  ({1'b0, io_r_req_0_idx}),
    .r_match(match8),
    .w_valid(io_w_valid),
    .w_key  ({1'b0, io_w_bits_data_idx}),
    .w_index(io_w_bits_index[2:0])
  );
  assign io_r_resp = {8'h0, match8};
endmodule

module neg_tb;
  bit clock = 0;
  wire [15:0] resp;
  neg_cam_wrong_params u_dut (
    .clock(clock), .io_r_req_0_idx(8'h0), .io_r_resp(resp),
    .io_w_valid(1'b0), .io_w_bits_data_idx(8'h0), .io_w_bits_index(4'h0)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下错参数");
    $finish;
  end
endmodule
