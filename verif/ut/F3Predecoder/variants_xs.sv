// 自动生成：scripts/gen_f3predecoder.py —— 勿手改
module F3Predecoder_xs(
  input  [31:0] io_in_instr_0,
  input  [31:0] io_in_instr_1,
  input  [31:0] io_in_instr_2,
  input  [31:0] io_in_instr_3,
  input  [31:0] io_in_instr_4,
  input  [31:0] io_in_instr_5,
  input  [31:0] io_in_instr_6,
  input  [31:0] io_in_instr_7,
  input  [31:0] io_in_instr_8,
  input  [31:0] io_in_instr_9,
  input  [31:0] io_in_instr_10,
  input  [31:0] io_in_instr_11,
  input  [31:0] io_in_instr_12,
  input  [31:0] io_in_instr_13,
  input  [31:0] io_in_instr_14,
  input  [31:0] io_in_instr_15,
  output [1:0] io_out_pd_0_brType,
  output io_out_pd_0_isCall,
  output io_out_pd_0_isRet,
  output [1:0] io_out_pd_1_brType,
  output io_out_pd_1_isCall,
  output io_out_pd_1_isRet,
  output [1:0] io_out_pd_2_brType,
  output io_out_pd_2_isCall,
  output io_out_pd_2_isRet,
  output [1:0] io_out_pd_3_brType,
  output io_out_pd_3_isCall,
  output io_out_pd_3_isRet,
  output [1:0] io_out_pd_4_brType,
  output io_out_pd_4_isCall,
  output io_out_pd_4_isRet,
  output [1:0] io_out_pd_5_brType,
  output io_out_pd_5_isCall,
  output io_out_pd_5_isRet,
  output [1:0] io_out_pd_6_brType,
  output io_out_pd_6_isCall,
  output io_out_pd_6_isRet,
  output [1:0] io_out_pd_7_brType,
  output io_out_pd_7_isCall,
  output io_out_pd_7_isRet,
  output [1:0] io_out_pd_8_brType,
  output io_out_pd_8_isCall,
  output io_out_pd_8_isRet,
  output [1:0] io_out_pd_9_brType,
  output io_out_pd_9_isCall,
  output io_out_pd_9_isRet,
  output [1:0] io_out_pd_10_brType,
  output io_out_pd_10_isCall,
  output io_out_pd_10_isRet,
  output [1:0] io_out_pd_11_brType,
  output io_out_pd_11_isCall,
  output io_out_pd_11_isRet,
  output [1:0] io_out_pd_12_brType,
  output io_out_pd_12_isCall,
  output io_out_pd_12_isRet,
  output [1:0] io_out_pd_13_brType,
  output io_out_pd_13_isCall,
  output io_out_pd_13_isRet,
  output [1:0] io_out_pd_14_brType,
  output io_out_pd_14_isCall,
  output io_out_pd_14_isRet,
  output [1:0] io_out_pd_15_brType,
  output io_out_pd_15_isCall,
  output io_out_pd_15_isRet
);
  wire [15:0][31:0] instr_arr;
  assign instr_arr[0] = io_in_instr_0;
  assign instr_arr[1] = io_in_instr_1;
  assign instr_arr[2] = io_in_instr_2;
  assign instr_arr[3] = io_in_instr_3;
  assign instr_arr[4] = io_in_instr_4;
  assign instr_arr[5] = io_in_instr_5;
  assign instr_arr[6] = io_in_instr_6;
  assign instr_arr[7] = io_in_instr_7;
  assign instr_arr[8] = io_in_instr_8;
  assign instr_arr[9] = io_in_instr_9;
  assign instr_arr[10] = io_in_instr_10;
  assign instr_arr[11] = io_in_instr_11;
  assign instr_arr[12] = io_in_instr_12;
  assign instr_arr[13] = io_in_instr_13;
  assign instr_arr[14] = io_in_instr_14;
  assign instr_arr[15] = io_in_instr_15;
  wire [15:0][1:0] c_brType;
  wire [15:0]      c_isCall, c_isRet;
  xs_F3Predecoder_core #(.PW(16)) u_core (
    .io_instr(instr_arr), .pd_brType(c_brType),
    .pd_isCall(c_isCall), .pd_isRet(c_isRet)
  );
  assign io_out_pd_0_brType = c_brType[0];
  assign io_out_pd_0_isCall = c_isCall[0];
  assign io_out_pd_0_isRet = c_isRet[0];
  assign io_out_pd_1_brType = c_brType[1];
  assign io_out_pd_1_isCall = c_isCall[1];
  assign io_out_pd_1_isRet = c_isRet[1];
  assign io_out_pd_2_brType = c_brType[2];
  assign io_out_pd_2_isCall = c_isCall[2];
  assign io_out_pd_2_isRet = c_isRet[2];
  assign io_out_pd_3_brType = c_brType[3];
  assign io_out_pd_3_isCall = c_isCall[3];
  assign io_out_pd_3_isRet = c_isRet[3];
  assign io_out_pd_4_brType = c_brType[4];
  assign io_out_pd_4_isCall = c_isCall[4];
  assign io_out_pd_4_isRet = c_isRet[4];
  assign io_out_pd_5_brType = c_brType[5];
  assign io_out_pd_5_isCall = c_isCall[5];
  assign io_out_pd_5_isRet = c_isRet[5];
  assign io_out_pd_6_brType = c_brType[6];
  assign io_out_pd_6_isCall = c_isCall[6];
  assign io_out_pd_6_isRet = c_isRet[6];
  assign io_out_pd_7_brType = c_brType[7];
  assign io_out_pd_7_isCall = c_isCall[7];
  assign io_out_pd_7_isRet = c_isRet[7];
  assign io_out_pd_8_brType = c_brType[8];
  assign io_out_pd_8_isCall = c_isCall[8];
  assign io_out_pd_8_isRet = c_isRet[8];
  assign io_out_pd_9_brType = c_brType[9];
  assign io_out_pd_9_isCall = c_isCall[9];
  assign io_out_pd_9_isRet = c_isRet[9];
  assign io_out_pd_10_brType = c_brType[10];
  assign io_out_pd_10_isCall = c_isCall[10];
  assign io_out_pd_10_isRet = c_isRet[10];
  assign io_out_pd_11_brType = c_brType[11];
  assign io_out_pd_11_isCall = c_isCall[11];
  assign io_out_pd_11_isRet = c_isRet[11];
  assign io_out_pd_12_brType = c_brType[12];
  assign io_out_pd_12_isCall = c_isCall[12];
  assign io_out_pd_12_isRet = c_isRet[12];
  assign io_out_pd_13_brType = c_brType[13];
  assign io_out_pd_13_isCall = c_isCall[13];
  assign io_out_pd_13_isRet = c_isRet[13];
  assign io_out_pd_14_brType = c_brType[14];
  assign io_out_pd_14_isCall = c_isCall[14];
  assign io_out_pd_14_isRet = c_isRet[14];
  assign io_out_pd_15_brType = c_brType[15];
  assign io_out_pd_15_isCall = c_isCall[15];
  assign io_out_pd_15_isRet = c_isRet[15];
endmodule
