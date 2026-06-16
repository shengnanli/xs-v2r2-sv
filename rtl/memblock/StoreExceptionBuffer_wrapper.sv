// 自动生成：scripts/gen_storeexceptionbuffer.py —— 勿手改
// golden 同名 wrapper：把扁平 golden 端口打包成 xs_StoreExceptionBuffer_core 的 struct/数组端口。
// golden firtool 对部分入口做了死代码消除，缺失输入按 golden 折叠的常量补齐：
//   · isHyper          缺于入口 4,5,6      → 补 0
//   · gpaddr/isForVS…  缺于入口 6           → 补 0
//   · vaNeedExt        缺于入口 6           → 补 1（golden 折成常量 1）
//   · 入口 6 仅有 excVec_19（hardwareError），其余异常位补 0
module StoreExceptionBuffer(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_storeAddrIn_0_valid,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_0_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_0_bits_uop_uopIdx,
  input         io_storeAddrIn_0_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_0_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_0_bits_fullva,
  input         io_storeAddrIn_0_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_0_bits_gpaddr,
  input         io_storeAddrIn_0_bits_isHyper,
  input         io_storeAddrIn_0_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_1_valid,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_1_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_1_bits_uop_uopIdx,
  input         io_storeAddrIn_1_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_1_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_1_bits_fullva,
  input         io_storeAddrIn_1_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_1_bits_gpaddr,
  input         io_storeAddrIn_1_bits_isHyper,
  input         io_storeAddrIn_1_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_2_valid,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_2_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_2_bits_uop_uopIdx,
  input         io_storeAddrIn_2_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_2_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_2_bits_fullva,
  input         io_storeAddrIn_2_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_2_bits_gpaddr,
  input         io_storeAddrIn_2_bits_isHyper,
  input         io_storeAddrIn_2_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_3_valid,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_3_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_3_bits_uop_uopIdx,
  input         io_storeAddrIn_3_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_3_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_3_bits_fullva,
  input         io_storeAddrIn_3_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_3_bits_gpaddr,
  input         io_storeAddrIn_3_bits_isHyper,
  input         io_storeAddrIn_3_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_4_valid,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_4_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_4_bits_uop_uopIdx,
  input         io_storeAddrIn_4_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_4_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_4_bits_fullva,
  input         io_storeAddrIn_4_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_4_bits_gpaddr,
  input         io_storeAddrIn_4_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_5_valid,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_3,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_6,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_7,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_15,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_19,
  input         io_storeAddrIn_5_bits_uop_exceptionVec_23,
  input  [6:0]  io_storeAddrIn_5_bits_uop_uopIdx,
  input         io_storeAddrIn_5_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_5_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_5_bits_fullva,
  input         io_storeAddrIn_5_bits_vaNeedExt,
  input  [63:0] io_storeAddrIn_5_bits_gpaddr,
  input         io_storeAddrIn_5_bits_isForVSnonLeafPTE,
  input         io_storeAddrIn_6_valid,
  input         io_storeAddrIn_6_bits_uop_exceptionVec_19,
  input  [6:0]  io_storeAddrIn_6_bits_uop_uopIdx,
  input         io_storeAddrIn_6_bits_uop_robIdx_flag,
  input  [7:0]  io_storeAddrIn_6_bits_uop_robIdx_value,
  input  [63:0] io_storeAddrIn_6_bits_fullva,
  output [63:0] io_exceptionAddr_vaddr,
  output        io_exceptionAddr_vaNeedExt,
  output        io_exceptionAddr_isHyper,
  output [63:0] io_exceptionAddr_gpaddr,
  output        io_exceptionAddr_isForVSnonLeafPTE
);
  import exceptionbuffer_pkg::*;

  logic     [6:0]        v;
  rob_ptr_t [6:0]        robIdx;
  logic [6:0][6:0]       uopIdx;
  logic [6:0][5:0]       excVec;    // 顺序 {23,19,15,7,6,3}；用 |orR，顺序无关
  logic [6:0][63:0]      fullva, gpaddr;
  logic [6:0]            vaNeedExt, isHyper, isForVSnonLeafPTE;

  assign v = {io_storeAddrIn_6_valid, io_storeAddrIn_5_valid, io_storeAddrIn_4_valid,
              io_storeAddrIn_3_valid, io_storeAddrIn_2_valid, io_storeAddrIn_1_valid,
              io_storeAddrIn_0_valid};

  assign robIdx[0] = '{flag:io_storeAddrIn_0_bits_uop_robIdx_flag, value:io_storeAddrIn_0_bits_uop_robIdx_value};
  assign robIdx[1] = '{flag:io_storeAddrIn_1_bits_uop_robIdx_flag, value:io_storeAddrIn_1_bits_uop_robIdx_value};
  assign robIdx[2] = '{flag:io_storeAddrIn_2_bits_uop_robIdx_flag, value:io_storeAddrIn_2_bits_uop_robIdx_value};
  assign robIdx[3] = '{flag:io_storeAddrIn_3_bits_uop_robIdx_flag, value:io_storeAddrIn_3_bits_uop_robIdx_value};
  assign robIdx[4] = '{flag:io_storeAddrIn_4_bits_uop_robIdx_flag, value:io_storeAddrIn_4_bits_uop_robIdx_value};
  assign robIdx[5] = '{flag:io_storeAddrIn_5_bits_uop_robIdx_flag, value:io_storeAddrIn_5_bits_uop_robIdx_value};
  assign robIdx[6] = '{flag:io_storeAddrIn_6_bits_uop_robIdx_flag, value:io_storeAddrIn_6_bits_uop_robIdx_value};

  assign uopIdx[0] = io_storeAddrIn_0_bits_uop_uopIdx;
  assign uopIdx[1] = io_storeAddrIn_1_bits_uop_uopIdx;
  assign uopIdx[2] = io_storeAddrIn_2_bits_uop_uopIdx;
  assign uopIdx[3] = io_storeAddrIn_3_bits_uop_uopIdx;
  assign uopIdx[4] = io_storeAddrIn_4_bits_uop_uopIdx;
  assign uopIdx[5] = io_storeAddrIn_5_bits_uop_uopIdx;
  assign uopIdx[6] = io_storeAddrIn_6_bits_uop_uopIdx;

  assign excVec[0] = {io_storeAddrIn_0_bits_uop_exceptionVec_23, io_storeAddrIn_0_bits_uop_exceptionVec_19, io_storeAddrIn_0_bits_uop_exceptionVec_15, io_storeAddrIn_0_bits_uop_exceptionVec_7, io_storeAddrIn_0_bits_uop_exceptionVec_6, io_storeAddrIn_0_bits_uop_exceptionVec_3};
  assign excVec[1] = {io_storeAddrIn_1_bits_uop_exceptionVec_23, io_storeAddrIn_1_bits_uop_exceptionVec_19, io_storeAddrIn_1_bits_uop_exceptionVec_15, io_storeAddrIn_1_bits_uop_exceptionVec_7, io_storeAddrIn_1_bits_uop_exceptionVec_6, io_storeAddrIn_1_bits_uop_exceptionVec_3};
  assign excVec[2] = {io_storeAddrIn_2_bits_uop_exceptionVec_23, io_storeAddrIn_2_bits_uop_exceptionVec_19, io_storeAddrIn_2_bits_uop_exceptionVec_15, io_storeAddrIn_2_bits_uop_exceptionVec_7, io_storeAddrIn_2_bits_uop_exceptionVec_6, io_storeAddrIn_2_bits_uop_exceptionVec_3};
  assign excVec[3] = {io_storeAddrIn_3_bits_uop_exceptionVec_23, io_storeAddrIn_3_bits_uop_exceptionVec_19, io_storeAddrIn_3_bits_uop_exceptionVec_15, io_storeAddrIn_3_bits_uop_exceptionVec_7, io_storeAddrIn_3_bits_uop_exceptionVec_6, io_storeAddrIn_3_bits_uop_exceptionVec_3};
  assign excVec[4] = {io_storeAddrIn_4_bits_uop_exceptionVec_23, io_storeAddrIn_4_bits_uop_exceptionVec_19, io_storeAddrIn_4_bits_uop_exceptionVec_15, io_storeAddrIn_4_bits_uop_exceptionVec_7, io_storeAddrIn_4_bits_uop_exceptionVec_6, io_storeAddrIn_4_bits_uop_exceptionVec_3};
  assign excVec[5] = {io_storeAddrIn_5_bits_uop_exceptionVec_23, io_storeAddrIn_5_bits_uop_exceptionVec_19, io_storeAddrIn_5_bits_uop_exceptionVec_15, io_storeAddrIn_5_bits_uop_exceptionVec_7, io_storeAddrIn_5_bits_uop_exceptionVec_6, io_storeAddrIn_5_bits_uop_exceptionVec_3};
  // 入口 6（SoC 非数据错误）：仅 hardwareError(bit19)，其余补 0
  assign excVec[6] = {1'b0, io_storeAddrIn_6_bits_uop_exceptionVec_19, 1'b0, 1'b0, 1'b0, 1'b0};

  assign fullva[0] = io_storeAddrIn_0_bits_fullva;
  assign fullva[1] = io_storeAddrIn_1_bits_fullva;
  assign fullva[2] = io_storeAddrIn_2_bits_fullva;
  assign fullva[3] = io_storeAddrIn_3_bits_fullva;
  assign fullva[4] = io_storeAddrIn_4_bits_fullva;
  assign fullva[5] = io_storeAddrIn_5_bits_fullva;
  assign fullva[6] = io_storeAddrIn_6_bits_fullva;

  assign gpaddr[0] = io_storeAddrIn_0_bits_gpaddr;
  assign gpaddr[1] = io_storeAddrIn_1_bits_gpaddr;
  assign gpaddr[2] = io_storeAddrIn_2_bits_gpaddr;
  assign gpaddr[3] = io_storeAddrIn_3_bits_gpaddr;
  assign gpaddr[4] = io_storeAddrIn_4_bits_gpaddr;
  assign gpaddr[5] = io_storeAddrIn_5_bits_gpaddr;
  assign gpaddr[6] = 64'h0;   // 入口 6 无 gpaddr（golden 折 0）

  // vaNeedExt：入口 6 无端口 → 折常量 1
  assign vaNeedExt = {1'b1, io_storeAddrIn_5_bits_vaNeedExt, io_storeAddrIn_4_bits_vaNeedExt,
                      io_storeAddrIn_3_bits_vaNeedExt, io_storeAddrIn_2_bits_vaNeedExt,
                      io_storeAddrIn_1_bits_vaNeedExt, io_storeAddrIn_0_bits_vaNeedExt};
  // isHyper：入口 4,5,6 无端口 → 折 0
  assign isHyper = {1'b0, 1'b0, 1'b0,
                    io_storeAddrIn_3_bits_isHyper, io_storeAddrIn_2_bits_isHyper,
                    io_storeAddrIn_1_bits_isHyper, io_storeAddrIn_0_bits_isHyper};
  // isForVSnonLeafPTE：入口 6 无端口 → 折 0
  assign isForVSnonLeafPTE = {1'b0, io_storeAddrIn_5_bits_isForVSnonLeafPTE,
                              io_storeAddrIn_4_bits_isForVSnonLeafPTE, io_storeAddrIn_3_bits_isForVSnonLeafPTE,
                              io_storeAddrIn_2_bits_isForVSnonLeafPTE, io_storeAddrIn_1_bits_isForVSnonLeafPTE,
                              io_storeAddrIn_0_bits_isForVSnonLeafPTE};

  xs_StoreExceptionBuffer_core #(.ENQ_NUM(7)) u_core (
    .clock(clock), .reset(reset),
    .redirect_valid (io_redirect_valid),
    .redirect_robIdx('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}),
    .redirect_level (io_redirect_bits_level),
    .req_valid             (v),
    .req_robIdx            (robIdx),
    .req_uopIdx            (uopIdx),
    .req_excVec            (excVec),
    .req_fullva            (fullva),
    .req_vaNeedExt         (vaNeedExt),
    .req_gpaddr            (gpaddr),
    .req_isHyper           (isHyper),
    .req_isForVSnonLeafPTE (isForVSnonLeafPTE),
    .exc_vaddr             (io_exceptionAddr_vaddr),
    .exc_vaNeedExt         (io_exceptionAddr_vaNeedExt),
    .exc_isHyper           (io_exceptionAddr_isHyper),
    .exc_gpaddr            (io_exceptionAddr_gpaddr),
    .exc_isForVSnonLeafPTE (io_exceptionAddr_isForVSnonLeafPTE)
  );
endmodule
