// 自动生成：scripts/gen_lqexceptionbuffer.py —— 勿手改
// UT 用 _xs 别名：扁平端口打包成 struct/数组后例化可读核 xs_LqExceptionBuffer_core。
module LqExceptionBuffer_xs(
  input clock, input reset,
  input io_redirect_valid,
  input io_redirect_bits_robIdx_flag,
  input [7:0] io_redirect_bits_robIdx_value,
  input io_redirect_bits_level,
  input io_req_0_valid,
  input io_req_0_bits_uop_exceptionVec_3,
  input io_req_0_bits_uop_exceptionVec_4,
  input io_req_0_bits_uop_exceptionVec_5,
  input io_req_0_bits_uop_exceptionVec_13,
  input io_req_0_bits_uop_exceptionVec_19,
  input io_req_0_bits_uop_exceptionVec_21,
  input [6:0] io_req_0_bits_uop_uopIdx,
  input io_req_0_bits_uop_robIdx_flag,
  input [7:0] io_req_0_bits_uop_robIdx_value,
  input [63:0] io_req_0_bits_fullva,
  input io_req_0_bits_vaNeedExt,
  input [63:0] io_req_0_bits_gpaddr,
  input io_req_0_bits_isHyper,
  input io_req_0_bits_isForVSnonLeafPTE,
  input io_req_1_valid,
  input io_req_1_bits_uop_exceptionVec_3,
  input io_req_1_bits_uop_exceptionVec_4,
  input io_req_1_bits_uop_exceptionVec_5,
  input io_req_1_bits_uop_exceptionVec_13,
  input io_req_1_bits_uop_exceptionVec_19,
  input io_req_1_bits_uop_exceptionVec_21,
  input [6:0] io_req_1_bits_uop_uopIdx,
  input io_req_1_bits_uop_robIdx_flag,
  input [7:0] io_req_1_bits_uop_robIdx_value,
  input [63:0] io_req_1_bits_fullva,
  input io_req_1_bits_vaNeedExt,
  input [63:0] io_req_1_bits_gpaddr,
  input io_req_1_bits_isHyper,
  input io_req_1_bits_isForVSnonLeafPTE,
  input io_req_2_valid,
  input io_req_2_bits_uop_exceptionVec_3,
  input io_req_2_bits_uop_exceptionVec_4,
  input io_req_2_bits_uop_exceptionVec_5,
  input io_req_2_bits_uop_exceptionVec_13,
  input io_req_2_bits_uop_exceptionVec_19,
  input io_req_2_bits_uop_exceptionVec_21,
  input [6:0] io_req_2_bits_uop_uopIdx,
  input io_req_2_bits_uop_robIdx_flag,
  input [7:0] io_req_2_bits_uop_robIdx_value,
  input [63:0] io_req_2_bits_fullva,
  input io_req_2_bits_vaNeedExt,
  input [63:0] io_req_2_bits_gpaddr,
  input io_req_2_bits_isHyper,
  input io_req_2_bits_isForVSnonLeafPTE,
  input io_req_3_valid,
  input io_req_3_bits_uop_exceptionVec_3,
  input io_req_3_bits_uop_exceptionVec_4,
  input io_req_3_bits_uop_exceptionVec_5,
  input io_req_3_bits_uop_exceptionVec_13,
  input io_req_3_bits_uop_exceptionVec_19,
  input io_req_3_bits_uop_exceptionVec_21,
  input [6:0] io_req_3_bits_uop_uopIdx,
  input io_req_3_bits_uop_robIdx_flag,
  input [7:0] io_req_3_bits_uop_robIdx_value,
  input [63:0] io_req_3_bits_fullva,
  input io_req_3_bits_vaNeedExt,
  input [63:0] io_req_3_bits_gpaddr,
  input io_req_4_valid,
  input io_req_4_bits_uop_exceptionVec_3,
  input io_req_4_bits_uop_exceptionVec_4,
  input io_req_4_bits_uop_exceptionVec_5,
  input io_req_4_bits_uop_exceptionVec_13,
  input io_req_4_bits_uop_exceptionVec_19,
  input io_req_4_bits_uop_exceptionVec_21,
  input [6:0] io_req_4_bits_uop_uopIdx,
  input io_req_4_bits_uop_robIdx_flag,
  input [7:0] io_req_4_bits_uop_robIdx_value,
  input [63:0] io_req_4_bits_fullva,
  input io_req_4_bits_vaNeedExt,
  input [63:0] io_req_4_bits_gpaddr,
  input io_req_5_valid,
  input io_req_5_bits_uop_exceptionVec_3,
  input io_req_5_bits_uop_exceptionVec_4,
  input io_req_5_bits_uop_exceptionVec_5,
  input io_req_5_bits_uop_exceptionVec_13,
  input io_req_5_bits_uop_exceptionVec_19,
  input io_req_5_bits_uop_exceptionVec_21,
  input [6:0] io_req_5_bits_uop_uopIdx,
  input io_req_5_bits_uop_robIdx_flag,
  input [7:0] io_req_5_bits_uop_robIdx_value,
  input [63:0] io_req_5_bits_fullva,
  input [63:0] io_req_5_bits_gpaddr,
  input io_req_5_bits_isHyper,
  input io_req_5_bits_isForVSnonLeafPTE,
  output [63:0] io_exceptionAddr_vaddr,
  output io_exceptionAddr_vaNeedExt,
  output io_exceptionAddr_isHyper,
  output [63:0] io_exceptionAddr_gpaddr,
  output io_exceptionAddr_isForVSnonLeafPTE
);
  import exceptionbuffer_pkg::*;
  logic [5:0] v;
  rob_ptr_t [5:0] robIdx;
  logic [5:0][6:0] uopIdx;
  logic [5:0][5:0] excVec;
  logic [5:0][63:0] fullva, gpaddr;
  logic [5:0] vaNeedExt, isHyper, isForVSnonLeafPTE;
  assign v = {io_req_5_valid,io_req_4_valid,io_req_3_valid,io_req_2_valid,io_req_1_valid,io_req_0_valid};
  assign robIdx[0] = '{flag:io_req_0_bits_uop_robIdx_flag, value:io_req_0_bits_uop_robIdx_value};
  assign robIdx[1] = '{flag:io_req_1_bits_uop_robIdx_flag, value:io_req_1_bits_uop_robIdx_value};
  assign robIdx[2] = '{flag:io_req_2_bits_uop_robIdx_flag, value:io_req_2_bits_uop_robIdx_value};
  assign robIdx[3] = '{flag:io_req_3_bits_uop_robIdx_flag, value:io_req_3_bits_uop_robIdx_value};
  assign robIdx[4] = '{flag:io_req_4_bits_uop_robIdx_flag, value:io_req_4_bits_uop_robIdx_value};
  assign robIdx[5] = '{flag:io_req_5_bits_uop_robIdx_flag, value:io_req_5_bits_uop_robIdx_value};
  assign uopIdx[0] = io_req_0_bits_uop_uopIdx;
  assign uopIdx[1] = io_req_1_bits_uop_uopIdx;
  assign uopIdx[2] = io_req_2_bits_uop_uopIdx;
  assign uopIdx[3] = io_req_3_bits_uop_uopIdx;
  assign uopIdx[4] = io_req_4_bits_uop_uopIdx;
  assign uopIdx[5] = io_req_5_bits_uop_uopIdx;
  assign excVec[0] = {io_req_0_bits_uop_exceptionVec_21,io_req_0_bits_uop_exceptionVec_19,io_req_0_bits_uop_exceptionVec_13,io_req_0_bits_uop_exceptionVec_5,io_req_0_bits_uop_exceptionVec_4,io_req_0_bits_uop_exceptionVec_3};
  assign excVec[1] = {io_req_1_bits_uop_exceptionVec_21,io_req_1_bits_uop_exceptionVec_19,io_req_1_bits_uop_exceptionVec_13,io_req_1_bits_uop_exceptionVec_5,io_req_1_bits_uop_exceptionVec_4,io_req_1_bits_uop_exceptionVec_3};
  assign excVec[2] = {io_req_2_bits_uop_exceptionVec_21,io_req_2_bits_uop_exceptionVec_19,io_req_2_bits_uop_exceptionVec_13,io_req_2_bits_uop_exceptionVec_5,io_req_2_bits_uop_exceptionVec_4,io_req_2_bits_uop_exceptionVec_3};
  assign excVec[3] = {io_req_3_bits_uop_exceptionVec_21,io_req_3_bits_uop_exceptionVec_19,io_req_3_bits_uop_exceptionVec_13,io_req_3_bits_uop_exceptionVec_5,io_req_3_bits_uop_exceptionVec_4,io_req_3_bits_uop_exceptionVec_3};
  assign excVec[4] = {io_req_4_bits_uop_exceptionVec_21,io_req_4_bits_uop_exceptionVec_19,io_req_4_bits_uop_exceptionVec_13,io_req_4_bits_uop_exceptionVec_5,io_req_4_bits_uop_exceptionVec_4,io_req_4_bits_uop_exceptionVec_3};
  assign excVec[5] = {io_req_5_bits_uop_exceptionVec_21,io_req_5_bits_uop_exceptionVec_19,io_req_5_bits_uop_exceptionVec_13,io_req_5_bits_uop_exceptionVec_5,io_req_5_bits_uop_exceptionVec_4,io_req_5_bits_uop_exceptionVec_3};
  assign fullva[0] = io_req_0_bits_fullva;
  assign fullva[1] = io_req_1_bits_fullva;
  assign fullva[2] = io_req_2_bits_fullva;
  assign fullva[3] = io_req_3_bits_fullva;
  assign fullva[4] = io_req_4_bits_fullva;
  assign fullva[5] = io_req_5_bits_fullva;
  assign gpaddr[0] = io_req_0_bits_gpaddr;
  assign gpaddr[1] = io_req_1_bits_gpaddr;
  assign gpaddr[2] = io_req_2_bits_gpaddr;
  assign gpaddr[3] = io_req_3_bits_gpaddr;
  assign gpaddr[4] = io_req_4_bits_gpaddr;
  assign gpaddr[5] = io_req_5_bits_gpaddr;
  assign vaNeedExt = {1'b1,io_req_4_bits_vaNeedExt,io_req_3_bits_vaNeedExt,io_req_2_bits_vaNeedExt,io_req_1_bits_vaNeedExt,io_req_0_bits_vaNeedExt};
  assign isHyper = {io_req_5_bits_isHyper,1'b0,1'b0,io_req_2_bits_isHyper,io_req_1_bits_isHyper,io_req_0_bits_isHyper};
  assign isForVSnonLeafPTE = {io_req_5_bits_isForVSnonLeafPTE,1'b0,1'b0,io_req_2_bits_isForVSnonLeafPTE,io_req_1_bits_isForVSnonLeafPTE,io_req_0_bits_isForVSnonLeafPTE};
  xs_LqExceptionBuffer_core #(.ENQ_NUM(6)) u_core (
    .clock(clock), .reset(reset),
    .redirect_valid(io_redirect_valid),
    .redirect_robIdx('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}),
    .redirect_level(io_redirect_bits_level),
    .req_valid(v), .req_robIdx(robIdx), .req_uopIdx(uopIdx), .req_excVec(excVec),
    .req_fullva(fullva), .req_vaNeedExt(vaNeedExt), .req_gpaddr(gpaddr),
    .req_isHyper(isHyper), .req_isForVSnonLeafPTE(isForVSnonLeafPTE),
    .exc_vaddr(io_exceptionAddr_vaddr), .exc_vaNeedExt(io_exceptionAddr_vaNeedExt),
    .exc_isHyper(io_exceptionAddr_isHyper), .exc_gpaddr(io_exceptionAddr_gpaddr),
    .exc_isForVSnonLeafPTE(io_exceptionAddr_isForVSnonLeafPTE)
  );
endmodule
