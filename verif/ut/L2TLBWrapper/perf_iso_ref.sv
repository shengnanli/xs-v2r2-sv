// 隔离 FM 反证（ref 侧）：golden 风格的 19 路 perf 2 级流水，逐字段平铺。
// 用真实 primary input（perf_in_<i>）驱动，无任何黑盒。与本核 perf 流水做 FM，
// 验证「脱离内层 L2TLB 黑盒后，两种写法形式化等价」，从而坐实 fmbb 的 20 个
// 失败点是黑盒对称性消解假阳性，而非逻辑不等价。
module perf_iso(
  input         clock,
  input         reset,
  input  [5:0]  perf_in_0,  input [5:0] perf_in_1,  input [5:0] perf_in_2,
  input  [5:0]  perf_in_3,  input [5:0] perf_in_4,  input [5:0] perf_in_5,
  input  [5:0]  perf_in_6,  input [5:0] perf_in_7,  input [5:0] perf_in_8,
  input  [5:0]  perf_in_9,  input [5:0] perf_in_10, input [5:0] perf_in_11,
  input  [5:0]  perf_in_12, input [5:0] perf_in_13, input [5:0] perf_in_14,
  input  [5:0]  perf_in_15, input [5:0] perf_in_16, input [5:0] perf_in_17,
  input  [5:0]  perf_in_18,
  output [5:0]  io_perf_0_value,  output [5:0] io_perf_1_value,  output [5:0] io_perf_2_value,
  output [5:0]  io_perf_3_value,  output [5:0] io_perf_4_value,  output [5:0] io_perf_5_value,
  output [5:0]  io_perf_6_value,  output [5:0] io_perf_7_value,  output [5:0] io_perf_8_value,
  output [5:0]  io_perf_9_value,  output [5:0] io_perf_10_value, output [5:0] io_perf_11_value,
  output [5:0]  io_perf_12_value, output [5:0] io_perf_13_value, output [5:0] io_perf_14_value,
  output [5:0]  io_perf_15_value, output [5:0] io_perf_16_value, output [5:0] io_perf_17_value,
  output [5:0]  io_perf_18_value
);
  reg [5:0] s1 [0:18];
  reg [5:0] s2 [0:18];
  wire [5:0] pin [0:18];
  assign pin[0]=perf_in_0;   assign pin[1]=perf_in_1;   assign pin[2]=perf_in_2;
  assign pin[3]=perf_in_3;   assign pin[4]=perf_in_4;   assign pin[5]=perf_in_5;
  assign pin[6]=perf_in_6;   assign pin[7]=perf_in_7;   assign pin[8]=perf_in_8;
  assign pin[9]=perf_in_9;   assign pin[10]=perf_in_10; assign pin[11]=perf_in_11;
  assign pin[12]=perf_in_12; assign pin[13]=perf_in_13; assign pin[14]=perf_in_14;
  assign pin[15]=perf_in_15; assign pin[16]=perf_in_16; assign pin[17]=perf_in_17;
  assign pin[18]=perf_in_18;
  integer k;
  always @(posedge clock) begin
    if (reset) begin
      for (k=0;k<19;k=k+1) begin s1[k]<=6'd0; s2[k]<=6'd0; end
    end else begin
      for (k=0;k<19;k=k+1) begin s2[k]<=s1[k]; s1[k]<=pin[k]; end
    end
  end
  assign io_perf_0_value=s2[0];   assign io_perf_1_value=s2[1];   assign io_perf_2_value=s2[2];
  assign io_perf_3_value=s2[3];   assign io_perf_4_value=s2[4];   assign io_perf_5_value=s2[5];
  assign io_perf_6_value=s2[6];   assign io_perf_7_value=s2[7];   assign io_perf_8_value=s2[8];
  assign io_perf_9_value=s2[9];   assign io_perf_10_value=s2[10]; assign io_perf_11_value=s2[11];
  assign io_perf_12_value=s2[12]; assign io_perf_13_value=s2[13]; assign io_perf_14_value=s2[14];
  assign io_perf_15_value=s2[15]; assign io_perf_16_value=s2[16]; assign io_perf_17_value=s2[17];
  assign io_perf_18_value=s2[18];
endmodule
