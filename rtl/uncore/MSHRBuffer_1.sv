// MSHRBuffer_1.sv —— L2 slice 的 releaseBuf：3 个写口、全部整块写（无 beatMask）。
//
// 与 refillBuf（MSHRBuffer）是同一个 Chisel 类 coupledL2.MSHRBuffer(wPorts=3) 的单态化，
// 逻辑全在 rtl/uncore/MSHRBuffer.sv 的 xs_MSHRBuffer_core（机制讲在那里的文件头）；
// 本文件只设 N_WPORT=3 并把 beatMask 接成全 1（golden 里 firtool 已把它折叠成常量 2'h3）。

module MSHRBuffer_1 (
  input  logic         clock,
  input  logic         reset,
  input  logic         io_r_valid,
  input  logic [7:0]   io_r_bits_id,
  output logic [511:0] io_resp_data_data,
  input  logic         io_w_0_valid,
  input  logic [7:0]   io_w_0_bits_id,
  input  logic [511:0] io_w_0_bits_data_data,
  input  logic         io_w_1_valid,
  input  logic [7:0]   io_w_1_bits_id,
  input  logic [511:0] io_w_1_bits_data_data,
  input  logic         io_w_2_valid,
  input  logic [7:0]   io_w_2_bits_id,
  input  logic [511:0] io_w_2_bits_data_data
);

  xs_MSHRBuffer_core #(.N_WPORT(3)) u_core (
    .clock   (clock),
    .reset   (reset),
    .r_valid (io_r_valid),
    .r_id    (io_r_bits_id),
    .r_data  (io_resp_data_data),
    .w_valid ('{io_w_0_valid, io_w_1_valid, io_w_2_valid}),
    .w_id    ('{io_w_0_bits_id, io_w_1_bits_id, io_w_2_bits_id}),
    .w_data  ('{io_w_0_bits_data_data, io_w_1_bits_data_data, io_w_2_bits_data_data}),
    .w_mask  ('{2'b11, 2'b11, 2'b11})
  );

endmodule
