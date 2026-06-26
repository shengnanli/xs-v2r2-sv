// 自动生成：scripts/gen_imsicgateway.py —— 勿手改
module IMSICGateWay_xs(
  input clock,
  input reset,
  input msiio_vld_req,
  input [10:0] msiio_data,
  output [7:0] msi_data_o,
  output [6:0] msi_valid_o
);
  xs_IMSICGateWay_core u_core (
    .clock(clock),
    .reset(reset),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data),
    .msi_data_o(msi_data_o),
    .msi_valid_o(msi_valid_o)
  );
endmodule
