// 自动生成：scripts/gen_predecode.py —— 勿手改
module PreDecode(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [15:0] io_in_bits_data_0,
  input  [15:0] io_in_bits_data_1,
  input  [15:0] io_in_bits_data_2,
  input  [15:0] io_in_bits_data_3,
  input  [15:0] io_in_bits_data_4,
  input  [15:0] io_in_bits_data_5,
  input  [15:0] io_in_bits_data_6,
  input  [15:0] io_in_bits_data_7,
  input  [15:0] io_in_bits_data_8,
  input  [15:0] io_in_bits_data_9,
  input  [15:0] io_in_bits_data_10,
  input  [15:0] io_in_bits_data_11,
  input  [15:0] io_in_bits_data_12,
  input  [15:0] io_in_bits_data_13,
  input  [15:0] io_in_bits_data_14,
  input  [15:0] io_in_bits_data_15,
  input  [15:0] io_in_bits_data_16,
  output io_out_pd_0_isRVC,
  output [1:0] io_out_pd_0_brType,
  output io_out_pd_0_isCall,
  output io_out_pd_0_isRet,
  output io_out_pd_1_valid,
  output io_out_pd_1_isRVC,
  output [1:0] io_out_pd_1_brType,
  output io_out_pd_1_isCall,
  output io_out_pd_1_isRet,
  output io_out_pd_2_valid,
  output io_out_pd_2_isRVC,
  output [1:0] io_out_pd_2_brType,
  output io_out_pd_2_isCall,
  output io_out_pd_2_isRet,
  output io_out_pd_3_valid,
  output io_out_pd_3_isRVC,
  output [1:0] io_out_pd_3_brType,
  output io_out_pd_3_isCall,
  output io_out_pd_3_isRet,
  output io_out_pd_4_valid,
  output io_out_pd_4_isRVC,
  output [1:0] io_out_pd_4_brType,
  output io_out_pd_4_isCall,
  output io_out_pd_4_isRet,
  output io_out_pd_5_valid,
  output io_out_pd_5_isRVC,
  output [1:0] io_out_pd_5_brType,
  output io_out_pd_5_isCall,
  output io_out_pd_5_isRet,
  output io_out_pd_6_valid,
  output io_out_pd_6_isRVC,
  output [1:0] io_out_pd_6_brType,
  output io_out_pd_6_isCall,
  output io_out_pd_6_isRet,
  output io_out_pd_7_valid,
  output io_out_pd_7_isRVC,
  output [1:0] io_out_pd_7_brType,
  output io_out_pd_7_isCall,
  output io_out_pd_7_isRet,
  output io_out_pd_8_valid,
  output io_out_pd_8_isRVC,
  output [1:0] io_out_pd_8_brType,
  output io_out_pd_8_isCall,
  output io_out_pd_8_isRet,
  output io_out_pd_9_valid,
  output io_out_pd_9_isRVC,
  output [1:0] io_out_pd_9_brType,
  output io_out_pd_9_isCall,
  output io_out_pd_9_isRet,
  output io_out_pd_10_valid,
  output io_out_pd_10_isRVC,
  output [1:0] io_out_pd_10_brType,
  output io_out_pd_10_isCall,
  output io_out_pd_10_isRet,
  output io_out_pd_11_valid,
  output io_out_pd_11_isRVC,
  output [1:0] io_out_pd_11_brType,
  output io_out_pd_11_isCall,
  output io_out_pd_11_isRet,
  output io_out_pd_12_valid,
  output io_out_pd_12_isRVC,
  output [1:0] io_out_pd_12_brType,
  output io_out_pd_12_isCall,
  output io_out_pd_12_isRet,
  output io_out_pd_13_valid,
  output io_out_pd_13_isRVC,
  output [1:0] io_out_pd_13_brType,
  output io_out_pd_13_isCall,
  output io_out_pd_13_isRet,
  output io_out_pd_14_valid,
  output io_out_pd_14_isRVC,
  output [1:0] io_out_pd_14_brType,
  output io_out_pd_14_isCall,
  output io_out_pd_14_isRet,
  output io_out_pd_15_valid,
  output io_out_pd_15_isRVC,
  output [1:0] io_out_pd_15_brType,
  output io_out_pd_15_isCall,
  output io_out_pd_15_isRet,
  output io_out_hasHalfValid_2,
  output io_out_hasHalfValid_3,
  output io_out_hasHalfValid_4,
  output io_out_hasHalfValid_5,
  output io_out_hasHalfValid_6,
  output io_out_hasHalfValid_7,
  output io_out_hasHalfValid_8,
  output io_out_hasHalfValid_9,
  output io_out_hasHalfValid_10,
  output io_out_hasHalfValid_11,
  output io_out_hasHalfValid_12,
  output io_out_hasHalfValid_13,
  output io_out_hasHalfValid_14,
  output io_out_hasHalfValid_15,
  output [31:0] io_out_instr_0,
  output [31:0] io_out_instr_1,
  output [31:0] io_out_instr_2,
  output [31:0] io_out_instr_3,
  output [31:0] io_out_instr_4,
  output [31:0] io_out_instr_5,
  output [31:0] io_out_instr_6,
  output [31:0] io_out_instr_7,
  output [31:0] io_out_instr_8,
  output [31:0] io_out_instr_9,
  output [31:0] io_out_instr_10,
  output [31:0] io_out_instr_11,
  output [31:0] io_out_instr_12,
  output [31:0] io_out_instr_13,
  output [31:0] io_out_instr_14,
  output [31:0] io_out_instr_15,
  output [63:0] io_out_jumpOffset_0,
  output [63:0] io_out_jumpOffset_1,
  output [63:0] io_out_jumpOffset_2,
  output [63:0] io_out_jumpOffset_3,
  output [63:0] io_out_jumpOffset_4,
  output [63:0] io_out_jumpOffset_5,
  output [63:0] io_out_jumpOffset_6,
  output [63:0] io_out_jumpOffset_7,
  output [63:0] io_out_jumpOffset_8,
  output [63:0] io_out_jumpOffset_9,
  output [63:0] io_out_jumpOffset_10,
  output [63:0] io_out_jumpOffset_11,
  output [63:0] io_out_jumpOffset_12,
  output [63:0] io_out_jumpOffset_13,
  output [63:0] io_out_jumpOffset_14,
  output [63:0] io_out_jumpOffset_15
);
  wire [16:0][15:0] data_arr;
  assign data_arr[0] = io_in_bits_data_0;
  assign data_arr[1] = io_in_bits_data_1;
  assign data_arr[2] = io_in_bits_data_2;
  assign data_arr[3] = io_in_bits_data_3;
  assign data_arr[4] = io_in_bits_data_4;
  assign data_arr[5] = io_in_bits_data_5;
  assign data_arr[6] = io_in_bits_data_6;
  assign data_arr[7] = io_in_bits_data_7;
  assign data_arr[8] = io_in_bits_data_8;
  assign data_arr[9] = io_in_bits_data_9;
  assign data_arr[10] = io_in_bits_data_10;
  assign data_arr[11] = io_in_bits_data_11;
  assign data_arr[12] = io_in_bits_data_12;
  assign data_arr[13] = io_in_bits_data_13;
  assign data_arr[14] = io_in_bits_data_14;
  assign data_arr[15] = io_in_bits_data_15;
  assign data_arr[16] = io_in_bits_data_16;
  wire [15:0]       c_valid, c_isRVC, c_isCall, c_isRet, c_hasHalfValid;
  wire [15:0][1:0]  c_brType;
  wire [15:0][31:0] c_instr;
  wire [15:0][63:0] c_jumpOffset;
  xs_PreDecode_core #(.PW(16), .XLEN(64)) u_core (
    .io_data(data_arr),
    .pd_valid(c_valid), .pd_isRVC(c_isRVC), .pd_brType(c_brType),
    .pd_isCall(c_isCall), .pd_isRet(c_isRet), .hasHalfValid(c_hasHalfValid),
    .instr(c_instr), .jumpOffset(c_jumpOffset)
  );
  assign io_out_pd_0_isRVC = c_isRVC[0];
  assign io_out_pd_0_brType = c_brType[0];
  assign io_out_pd_0_isCall = c_isCall[0];
  assign io_out_pd_0_isRet = c_isRet[0];
  assign io_out_pd_1_valid = c_valid[1];
  assign io_out_pd_1_isRVC = c_isRVC[1];
  assign io_out_pd_1_brType = c_brType[1];
  assign io_out_pd_1_isCall = c_isCall[1];
  assign io_out_pd_1_isRet = c_isRet[1];
  assign io_out_pd_2_valid = c_valid[2];
  assign io_out_pd_2_isRVC = c_isRVC[2];
  assign io_out_pd_2_brType = c_brType[2];
  assign io_out_pd_2_isCall = c_isCall[2];
  assign io_out_pd_2_isRet = c_isRet[2];
  assign io_out_pd_3_valid = c_valid[3];
  assign io_out_pd_3_isRVC = c_isRVC[3];
  assign io_out_pd_3_brType = c_brType[3];
  assign io_out_pd_3_isCall = c_isCall[3];
  assign io_out_pd_3_isRet = c_isRet[3];
  assign io_out_pd_4_valid = c_valid[4];
  assign io_out_pd_4_isRVC = c_isRVC[4];
  assign io_out_pd_4_brType = c_brType[4];
  assign io_out_pd_4_isCall = c_isCall[4];
  assign io_out_pd_4_isRet = c_isRet[4];
  assign io_out_pd_5_valid = c_valid[5];
  assign io_out_pd_5_isRVC = c_isRVC[5];
  assign io_out_pd_5_brType = c_brType[5];
  assign io_out_pd_5_isCall = c_isCall[5];
  assign io_out_pd_5_isRet = c_isRet[5];
  assign io_out_pd_6_valid = c_valid[6];
  assign io_out_pd_6_isRVC = c_isRVC[6];
  assign io_out_pd_6_brType = c_brType[6];
  assign io_out_pd_6_isCall = c_isCall[6];
  assign io_out_pd_6_isRet = c_isRet[6];
  assign io_out_pd_7_valid = c_valid[7];
  assign io_out_pd_7_isRVC = c_isRVC[7];
  assign io_out_pd_7_brType = c_brType[7];
  assign io_out_pd_7_isCall = c_isCall[7];
  assign io_out_pd_7_isRet = c_isRet[7];
  assign io_out_pd_8_valid = c_valid[8];
  assign io_out_pd_8_isRVC = c_isRVC[8];
  assign io_out_pd_8_brType = c_brType[8];
  assign io_out_pd_8_isCall = c_isCall[8];
  assign io_out_pd_8_isRet = c_isRet[8];
  assign io_out_pd_9_valid = c_valid[9];
  assign io_out_pd_9_isRVC = c_isRVC[9];
  assign io_out_pd_9_brType = c_brType[9];
  assign io_out_pd_9_isCall = c_isCall[9];
  assign io_out_pd_9_isRet = c_isRet[9];
  assign io_out_pd_10_valid = c_valid[10];
  assign io_out_pd_10_isRVC = c_isRVC[10];
  assign io_out_pd_10_brType = c_brType[10];
  assign io_out_pd_10_isCall = c_isCall[10];
  assign io_out_pd_10_isRet = c_isRet[10];
  assign io_out_pd_11_valid = c_valid[11];
  assign io_out_pd_11_isRVC = c_isRVC[11];
  assign io_out_pd_11_brType = c_brType[11];
  assign io_out_pd_11_isCall = c_isCall[11];
  assign io_out_pd_11_isRet = c_isRet[11];
  assign io_out_pd_12_valid = c_valid[12];
  assign io_out_pd_12_isRVC = c_isRVC[12];
  assign io_out_pd_12_brType = c_brType[12];
  assign io_out_pd_12_isCall = c_isCall[12];
  assign io_out_pd_12_isRet = c_isRet[12];
  assign io_out_pd_13_valid = c_valid[13];
  assign io_out_pd_13_isRVC = c_isRVC[13];
  assign io_out_pd_13_brType = c_brType[13];
  assign io_out_pd_13_isCall = c_isCall[13];
  assign io_out_pd_13_isRet = c_isRet[13];
  assign io_out_pd_14_valid = c_valid[14];
  assign io_out_pd_14_isRVC = c_isRVC[14];
  assign io_out_pd_14_brType = c_brType[14];
  assign io_out_pd_14_isCall = c_isCall[14];
  assign io_out_pd_14_isRet = c_isRet[14];
  assign io_out_pd_15_valid = c_valid[15];
  assign io_out_pd_15_isRVC = c_isRVC[15];
  assign io_out_pd_15_brType = c_brType[15];
  assign io_out_pd_15_isCall = c_isCall[15];
  assign io_out_pd_15_isRet = c_isRet[15];
  assign io_out_hasHalfValid_2 = c_hasHalfValid[2];
  assign io_out_hasHalfValid_3 = c_hasHalfValid[3];
  assign io_out_hasHalfValid_4 = c_hasHalfValid[4];
  assign io_out_hasHalfValid_5 = c_hasHalfValid[5];
  assign io_out_hasHalfValid_6 = c_hasHalfValid[6];
  assign io_out_hasHalfValid_7 = c_hasHalfValid[7];
  assign io_out_hasHalfValid_8 = c_hasHalfValid[8];
  assign io_out_hasHalfValid_9 = c_hasHalfValid[9];
  assign io_out_hasHalfValid_10 = c_hasHalfValid[10];
  assign io_out_hasHalfValid_11 = c_hasHalfValid[11];
  assign io_out_hasHalfValid_12 = c_hasHalfValid[12];
  assign io_out_hasHalfValid_13 = c_hasHalfValid[13];
  assign io_out_hasHalfValid_14 = c_hasHalfValid[14];
  assign io_out_hasHalfValid_15 = c_hasHalfValid[15];
  assign io_out_instr_0 = c_instr[0];
  assign io_out_instr_1 = c_instr[1];
  assign io_out_instr_2 = c_instr[2];
  assign io_out_instr_3 = c_instr[3];
  assign io_out_instr_4 = c_instr[4];
  assign io_out_instr_5 = c_instr[5];
  assign io_out_instr_6 = c_instr[6];
  assign io_out_instr_7 = c_instr[7];
  assign io_out_instr_8 = c_instr[8];
  assign io_out_instr_9 = c_instr[9];
  assign io_out_instr_10 = c_instr[10];
  assign io_out_instr_11 = c_instr[11];
  assign io_out_instr_12 = c_instr[12];
  assign io_out_instr_13 = c_instr[13];
  assign io_out_instr_14 = c_instr[14];
  assign io_out_instr_15 = c_instr[15];
  assign io_out_jumpOffset_0 = c_jumpOffset[0];
  assign io_out_jumpOffset_1 = c_jumpOffset[1];
  assign io_out_jumpOffset_2 = c_jumpOffset[2];
  assign io_out_jumpOffset_3 = c_jumpOffset[3];
  assign io_out_jumpOffset_4 = c_jumpOffset[4];
  assign io_out_jumpOffset_5 = c_jumpOffset[5];
  assign io_out_jumpOffset_6 = c_jumpOffset[6];
  assign io_out_jumpOffset_7 = c_jumpOffset[7];
  assign io_out_jumpOffset_8 = c_jumpOffset[8];
  assign io_out_jumpOffset_9 = c_jumpOffset[9];
  assign io_out_jumpOffset_10 = c_jumpOffset[10];
  assign io_out_jumpOffset_11 = c_jumpOffset[11];
  assign io_out_jumpOffset_12 = c_jumpOffset[12];
  assign io_out_jumpOffset_13 = c_jumpOffset[13];
  assign io_out_jumpOffset_14 = c_jumpOffset[14];
  assign io_out_jumpOffset_15 = c_jumpOffset[15];
endmodule
