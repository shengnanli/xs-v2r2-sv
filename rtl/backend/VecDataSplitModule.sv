// VecDataSplitModule.sv — parallel byte, halfword, word, and doubleword views.
// Every output is a direct little-endian slice of the 128-bit input lane.
// No state or child module exists; this is a pure combinational leaf.
module VecDataSplitModule(
  input  [127:0] io_inVecData,
  output [7:0]   io_outVec8b_0,
  output [7:0]   io_outVec8b_1,
  output [7:0]   io_outVec8b_2,
  output [7:0]   io_outVec8b_3,
  output [7:0]   io_outVec8b_4,
  output [7:0]   io_outVec8b_5,
  output [7:0]   io_outVec8b_6,
  output [7:0]   io_outVec8b_7,
  output [7:0]   io_outVec8b_8,
  output [7:0]   io_outVec8b_9,
  output [7:0]   io_outVec8b_10,
  output [7:0]   io_outVec8b_11,
  output [7:0]   io_outVec8b_12,
  output [7:0]   io_outVec8b_13,
  output [7:0]   io_outVec8b_14,
  output [7:0]   io_outVec8b_15,
  output [15:0]  io_outVec16b_0,
  output [15:0]  io_outVec16b_1,
  output [15:0]  io_outVec16b_2,
  output [15:0]  io_outVec16b_3,
  output [15:0]  io_outVec16b_4,
  output [15:0]  io_outVec16b_5,
  output [15:0]  io_outVec16b_6,
  output [15:0]  io_outVec16b_7,
  output [31:0]  io_outVec32b_0,
  output [31:0]  io_outVec32b_1,
  output [31:0]  io_outVec32b_2,
  output [31:0]  io_outVec32b_3,
  output [63:0]  io_outVec64b_0,
  output [63:0]  io_outVec64b_1
);

  assign io_outVec8b_0 = io_inVecData[7:0];
  assign io_outVec8b_1 = io_inVecData[15:8];
  assign io_outVec8b_2 = io_inVecData[23:16];
  assign io_outVec8b_3 = io_inVecData[31:24];
  assign io_outVec8b_4 = io_inVecData[39:32];
  assign io_outVec8b_5 = io_inVecData[47:40];
  assign io_outVec8b_6 = io_inVecData[55:48];
  assign io_outVec8b_7 = io_inVecData[63:56];
  assign io_outVec8b_8 = io_inVecData[71:64];
  assign io_outVec8b_9 = io_inVecData[79:72];
  assign io_outVec8b_10 = io_inVecData[87:80];
  assign io_outVec8b_11 = io_inVecData[95:88];
  assign io_outVec8b_12 = io_inVecData[103:96];
  assign io_outVec8b_13 = io_inVecData[111:104];
  assign io_outVec8b_14 = io_inVecData[119:112];
  assign io_outVec8b_15 = io_inVecData[127:120];
  assign io_outVec16b_0 = io_inVecData[15:0];
  assign io_outVec16b_1 = io_inVecData[31:16];
  assign io_outVec16b_2 = io_inVecData[47:32];
  assign io_outVec16b_3 = io_inVecData[63:48];
  assign io_outVec16b_4 = io_inVecData[79:64];
  assign io_outVec16b_5 = io_inVecData[95:80];
  assign io_outVec16b_6 = io_inVecData[111:96];
  assign io_outVec16b_7 = io_inVecData[127:112];
  assign io_outVec32b_0 = io_inVecData[31:0];
  assign io_outVec32b_1 = io_inVecData[63:32];
  assign io_outVec32b_2 = io_inVecData[95:64];
  assign io_outVec32b_3 = io_inVecData[127:96];
  assign io_outVec64b_0 = io_inVecData[63:0];
  assign io_outVec64b_1 = io_inVecData[127:64];
endmodule
