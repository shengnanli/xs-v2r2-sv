// 自动生成:scripts/gen_coupledl2.py —— 勿手改(顶层 glue 为从 firtool 意图的具名可读重写)

// 23 子模块类型黑盒 stub(空体,所有 output 驱 0)。
// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。

module Arbiter4_L2CacheErrorInfo(
  input  io_in_0_valid,
  input  io_in_0_bits_valid,
  input  [45:0] io_in_0_bits_address,
  input  io_in_1_valid,
  input  io_in_1_bits_valid,
  input  [45:0] io_in_1_bits_address,
  input  io_in_2_valid,
  input  io_in_2_bits_valid,
  input  [45:0] io_in_2_bits_address,
  input  io_in_3_valid,
  input  io_in_3_bits_valid,
  input  [45:0] io_in_3_bits_address,
  output  io_out_valid,
  output  io_out_bits_valid,
  output  [45:0] io_out_bits_address
);
  assign io_out_valid = '0;
  assign io_out_bits_valid = '0;
  assign io_out_bits_address = '0;
endmodule

module Arbiter4_L2ToL1Hint(
  output  io_in_0_ready,
  input  io_in_0_valid,
  input  [31:0] io_in_0_bits_sourceId,
  input  io_in_0_bits_isKeyword,
  output  io_in_1_ready,
  input  io_in_1_valid,
  input  [31:0] io_in_1_bits_sourceId,
  input  io_in_1_bits_isKeyword,
  output  io_in_2_ready,
  input  io_in_2_valid,
  input  [31:0] io_in_2_bits_sourceId,
  input  io_in_2_bits_isKeyword,
  output  io_in_3_ready,
  input  io_in_3_valid,
  input  [31:0] io_in_3_bits_sourceId,
  input  io_in_3_bits_isKeyword,
  input  io_out_ready,
  output  io_out_valid,
  output  [31:0] io_out_bits_sourceId,
  output  io_out_bits_isKeyword,
  output  [1:0] io_chosen
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_sourceId = '0;
  assign io_out_bits_isKeyword = '0;
  assign io_chosen = '0;
endmodule

module FastArbiter_1(
  input  clock,
  input  reset,
  output  io_in_0_ready,
  input  io_in_0_valid,
  input  [32:0] io_in_0_bits_tag,
  input  [8:0] io_in_0_bits_set,
  input  io_in_0_bits_needT,
  input  [6:0] io_in_0_bits_source,
  input  [43:0] io_in_0_bits_vaddr,
  input  [4:0] io_in_0_bits_reqsource,
  output  io_in_1_ready,
  input  io_in_1_valid,
  input  [32:0] io_in_1_bits_tag,
  input  [8:0] io_in_1_bits_set,
  input  io_in_1_bits_needT,
  input  [6:0] io_in_1_bits_source,
  input  [43:0] io_in_1_bits_vaddr,
  input  [4:0] io_in_1_bits_reqsource,
  output  io_in_2_ready,
  input  io_in_2_valid,
  input  [32:0] io_in_2_bits_tag,
  input  [8:0] io_in_2_bits_set,
  input  io_in_2_bits_needT,
  input  [6:0] io_in_2_bits_source,
  input  [43:0] io_in_2_bits_vaddr,
  input  [4:0] io_in_2_bits_reqsource,
  output  io_in_3_ready,
  input  io_in_3_valid,
  input  [32:0] io_in_3_bits_tag,
  input  [8:0] io_in_3_bits_set,
  input  io_in_3_bits_needT,
  input  [6:0] io_in_3_bits_source,
  input  [43:0] io_in_3_bits_vaddr,
  input  [4:0] io_in_3_bits_reqsource,
  input  io_out_ready,
  output  io_out_valid,
  output  [32:0] io_out_bits_tag,
  output  [8:0] io_out_bits_set,
  output  io_out_bits_needT,
  output  [6:0] io_out_bits_source,
  output  [43:0] io_out_bits_vaddr,
  output  [4:0] io_out_bits_reqsource
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_tag = '0;
  assign io_out_bits_set = '0;
  assign io_out_bits_needT = '0;
  assign io_out_bits_source = '0;
  assign io_out_bits_vaddr = '0;
  assign io_out_bits_reqsource = '0;
endmodule

module FastArbiter_2(
  input  clock,
  input  reset,
  output  io_in_0_ready,
  input  io_in_0_valid,
  input  [4:0] io_in_0_bits_pfSource,
  output  io_in_1_ready,
  input  io_in_1_valid,
  input  [4:0] io_in_1_bits_pfSource,
  output  io_in_2_ready,
  input  io_in_2_valid,
  input  [4:0] io_in_2_bits_pfSource,
  output  io_in_3_ready,
  input  io_in_3_valid,
  input  [4:0] io_in_3_bits_pfSource,
  input  io_out_ready,
  output  io_out_valid,
  output  [4:0] io_out_bits_pfSource
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_pfSource = '0;
endmodule

module FastArbiter_27(
  input  clock,
  input  reset,
  output  io_in_0_ready,
  input  io_in_0_valid,
  input  [3:0] io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_tgtID,
  input  [11:0] io_in_0_bits_txnID,
  input  [4:0] io_in_0_bits_opcode,
  input  [1:0] io_in_0_bits_respErr,
  input  [2:0] io_in_0_bits_resp,
  input  [2:0] io_in_0_bits_fwdState,
  input  [2:0] io_in_0_bits_cBusy,
  input  [11:0] io_in_0_bits_dbID,
  input  [3:0] io_in_0_bits_pCrdType,
  input  [1:0] io_in_0_bits_tagOp,
  input  io_in_0_bits_traceTag,
  output  io_in_1_ready,
  input  io_in_1_valid,
  input  [3:0] io_in_1_bits_qos,
  input  [10:0] io_in_1_bits_tgtID,
  input  [11:0] io_in_1_bits_txnID,
  input  [4:0] io_in_1_bits_opcode,
  input  [1:0] io_in_1_bits_respErr,
  input  [2:0] io_in_1_bits_resp,
  input  [2:0] io_in_1_bits_fwdState,
  input  [2:0] io_in_1_bits_cBusy,
  input  [11:0] io_in_1_bits_dbID,
  input  [3:0] io_in_1_bits_pCrdType,
  input  [1:0] io_in_1_bits_tagOp,
  input  io_in_1_bits_traceTag,
  output  io_in_2_ready,
  input  io_in_2_valid,
  input  [3:0] io_in_2_bits_qos,
  input  [10:0] io_in_2_bits_tgtID,
  input  [11:0] io_in_2_bits_txnID,
  input  [4:0] io_in_2_bits_opcode,
  input  [1:0] io_in_2_bits_respErr,
  input  [2:0] io_in_2_bits_resp,
  input  [2:0] io_in_2_bits_fwdState,
  input  [2:0] io_in_2_bits_cBusy,
  input  [11:0] io_in_2_bits_dbID,
  input  [3:0] io_in_2_bits_pCrdType,
  input  [1:0] io_in_2_bits_tagOp,
  input  io_in_2_bits_traceTag,
  output  io_in_3_ready,
  input  io_in_3_valid,
  input  [3:0] io_in_3_bits_qos,
  input  [10:0] io_in_3_bits_tgtID,
  input  [11:0] io_in_3_bits_txnID,
  input  [4:0] io_in_3_bits_opcode,
  input  [1:0] io_in_3_bits_respErr,
  input  [2:0] io_in_3_bits_resp,
  input  [2:0] io_in_3_bits_fwdState,
  input  [2:0] io_in_3_bits_cBusy,
  input  [11:0] io_in_3_bits_dbID,
  input  [3:0] io_in_3_bits_pCrdType,
  input  [1:0] io_in_3_bits_tagOp,
  input  io_in_3_bits_traceTag,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_tgtID,
  output  [11:0] io_out_bits_txnID,
  output  [4:0] io_out_bits_opcode,
  output  [1:0] io_out_bits_respErr,
  output  [2:0] io_out_bits_resp,
  output  [2:0] io_out_bits_fwdState,
  output  [2:0] io_out_bits_cBusy,
  output  [11:0] io_out_bits_dbID,
  output  [3:0] io_out_bits_pCrdType,
  output  [1:0] io_out_bits_tagOp,
  output  io_out_bits_traceTag,
  output  [1:0] io_chosen
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_respErr = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_fwdState = '0;
  assign io_out_bits_cBusy = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_pCrdType = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_traceTag = '0;
  assign io_chosen = '0;
endmodule

module FastArbiter_28(
  input  clock,
  input  reset,
  output  io_in_0_ready,
  input  io_in_0_valid,
  input  [10:0] io_in_0_bits_tgtID,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_homeNID,
  input  [3:0] io_in_0_bits_opcode,
  input  [1:0] io_in_0_bits_respErr,
  input  [2:0] io_in_0_bits_resp,
  input  [3:0] io_in_0_bits_dataSource,
  input  [11:0] io_in_0_bits_dbID,
  input  [1:0] io_in_0_bits_ccID,
  input  [1:0] io_in_0_bits_dataID,
  input  io_in_0_bits_traceTag,
  input  [31:0] io_in_0_bits_be,
  input  [255:0] io_in_0_bits_data,
  input  [31:0] io_in_0_bits_dataCheck,
  input  [3:0] io_in_0_bits_poison,
  output  io_in_1_ready,
  input  io_in_1_valid,
  input  [10:0] io_in_1_bits_tgtID,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_homeNID,
  input  [3:0] io_in_1_bits_opcode,
  input  [1:0] io_in_1_bits_respErr,
  input  [2:0] io_in_1_bits_resp,
  input  [3:0] io_in_1_bits_dataSource,
  input  [11:0] io_in_1_bits_dbID,
  input  [1:0] io_in_1_bits_ccID,
  input  [1:0] io_in_1_bits_dataID,
  input  io_in_1_bits_traceTag,
  input  [31:0] io_in_1_bits_be,
  input  [255:0] io_in_1_bits_data,
  input  [31:0] io_in_1_bits_dataCheck,
  input  [3:0] io_in_1_bits_poison,
  output  io_in_2_ready,
  input  io_in_2_valid,
  input  [10:0] io_in_2_bits_tgtID,
  input  [11:0] io_in_2_bits_txnID,
  input  [10:0] io_in_2_bits_homeNID,
  input  [3:0] io_in_2_bits_opcode,
  input  [1:0] io_in_2_bits_respErr,
  input  [2:0] io_in_2_bits_resp,
  input  [3:0] io_in_2_bits_dataSource,
  input  [11:0] io_in_2_bits_dbID,
  input  [1:0] io_in_2_bits_ccID,
  input  [1:0] io_in_2_bits_dataID,
  input  io_in_2_bits_traceTag,
  input  [31:0] io_in_2_bits_be,
  input  [255:0] io_in_2_bits_data,
  input  [31:0] io_in_2_bits_dataCheck,
  input  [3:0] io_in_2_bits_poison,
  output  io_in_3_ready,
  input  io_in_3_valid,
  input  [10:0] io_in_3_bits_tgtID,
  input  [11:0] io_in_3_bits_txnID,
  input  [10:0] io_in_3_bits_homeNID,
  input  [3:0] io_in_3_bits_opcode,
  input  [1:0] io_in_3_bits_respErr,
  input  [2:0] io_in_3_bits_resp,
  input  [3:0] io_in_3_bits_dataSource,
  input  [11:0] io_in_3_bits_dbID,
  input  [1:0] io_in_3_bits_ccID,
  input  [1:0] io_in_3_bits_dataID,
  input  io_in_3_bits_traceTag,
  input  [31:0] io_in_3_bits_be,
  input  [255:0] io_in_3_bits_data,
  input  [31:0] io_in_3_bits_dataCheck,
  input  [3:0] io_in_3_bits_poison,
  output  io_in_4_ready,
  input  io_in_4_valid,
  input  [3:0] io_in_4_bits_qos,
  input  [10:0] io_in_4_bits_tgtID,
  input  [11:0] io_in_4_bits_txnID,
  input  [10:0] io_in_4_bits_homeNID,
  input  [3:0] io_in_4_bits_opcode,
  input  [1:0] io_in_4_bits_respErr,
  input  [2:0] io_in_4_bits_resp,
  input  [3:0] io_in_4_bits_dataSource,
  input  [2:0] io_in_4_bits_cBusy,
  input  [11:0] io_in_4_bits_dbID,
  input  [1:0] io_in_4_bits_ccID,
  input  [1:0] io_in_4_bits_dataID,
  input  [1:0] io_in_4_bits_tagOp,
  input  [7:0] io_in_4_bits_tag,
  input  [1:0] io_in_4_bits_tu,
  input  io_in_4_bits_traceTag,
  input  [3:0] io_in_4_bits_rsvdc,
  input  [31:0] io_in_4_bits_be,
  input  [255:0] io_in_4_bits_data,
  input  [31:0] io_in_4_bits_dataCheck,
  input  [3:0] io_in_4_bits_poison,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_tgtID,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_homeNID,
  output  [3:0] io_out_bits_opcode,
  output  [1:0] io_out_bits_respErr,
  output  [2:0] io_out_bits_resp,
  output  [3:0] io_out_bits_dataSource,
  output  [2:0] io_out_bits_cBusy,
  output  [11:0] io_out_bits_dbID,
  output  [1:0] io_out_bits_ccID,
  output  [1:0] io_out_bits_dataID,
  output  [1:0] io_out_bits_tagOp,
  output  [7:0] io_out_bits_tag,
  output  [1:0] io_out_bits_tu,
  output  io_out_bits_traceTag,
  output  [3:0] io_out_bits_rsvdc,
  output  [31:0] io_out_bits_be,
  output  [255:0] io_out_bits_data,
  output  [31:0] io_out_bits_dataCheck,
  output  [3:0] io_out_bits_poison
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_in_4_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_homeNID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_respErr = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_dataSource = '0;
  assign io_out_bits_cBusy = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_ccID = '0;
  assign io_out_bits_dataID = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_tag = '0;
  assign io_out_bits_tu = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_rsvdc = '0;
  assign io_out_bits_be = '0;
  assign io_out_bits_data = '0;
  assign io_out_bits_dataCheck = '0;
  assign io_out_bits_poison = '0;
endmodule

module FastArbiter_29(
  input  clock,
  input  reset,
  output  io_in_0_ready,
  input  io_in_0_valid,
  output  io_in_1_ready,
  input  io_in_1_valid,
  output  io_in_2_ready,
  input  io_in_2_valid,
  output  io_in_3_ready,
  input  io_in_3_valid,
  output  io_in_4_ready,
  input  io_in_4_valid,
  output  io_in_5_ready,
  input  io_in_5_valid,
  output  io_in_6_ready,
  input  io_in_6_valid,
  output  io_in_7_ready,
  input  io_in_7_valid,
  output  io_in_8_ready,
  input  io_in_8_valid,
  output  io_in_9_ready,
  input  io_in_9_valid,
  output  io_in_10_ready,
  input  io_in_10_valid,
  output  io_in_11_ready,
  input  io_in_11_valid,
  output  io_in_12_ready,
  input  io_in_12_valid,
  output  io_in_13_ready,
  input  io_in_13_valid,
  output  io_in_14_ready,
  input  io_in_14_valid,
  output  io_in_15_ready,
  input  io_in_15_valid,
  output  io_in_16_ready,
  input  io_in_16_valid,
  output  io_in_17_ready,
  input  io_in_17_valid,
  output  io_in_18_ready,
  input  io_in_18_valid,
  output  io_in_19_ready,
  input  io_in_19_valid,
  output  io_in_20_ready,
  input  io_in_20_valid,
  output  io_in_21_ready,
  input  io_in_21_valid,
  output  io_in_22_ready,
  input  io_in_22_valid,
  output  io_in_23_ready,
  input  io_in_23_valid,
  output  io_in_24_ready,
  input  io_in_24_valid,
  output  io_in_25_ready,
  input  io_in_25_valid,
  output  io_in_26_ready,
  input  io_in_26_valid,
  output  io_in_27_ready,
  input  io_in_27_valid,
  output  io_in_28_ready,
  input  io_in_28_valid,
  output  io_in_29_ready,
  input  io_in_29_valid,
  output  io_in_30_ready,
  input  io_in_30_valid,
  output  io_in_31_ready,
  input  io_in_31_valid,
  output  io_in_32_ready,
  input  io_in_32_valid,
  output  io_in_33_ready,
  input  io_in_33_valid,
  output  io_in_34_ready,
  input  io_in_34_valid,
  output  io_in_35_ready,
  input  io_in_35_valid,
  output  io_in_36_ready,
  input  io_in_36_valid,
  output  io_in_37_ready,
  input  io_in_37_valid,
  output  io_in_38_ready,
  input  io_in_38_valid,
  output  io_in_39_ready,
  input  io_in_39_valid,
  output  io_in_40_ready,
  input  io_in_40_valid,
  output  io_in_41_ready,
  input  io_in_41_valid,
  output  io_in_42_ready,
  input  io_in_42_valid,
  output  io_in_43_ready,
  input  io_in_43_valid,
  output  io_in_44_ready,
  input  io_in_44_valid,
  output  io_in_45_ready,
  input  io_in_45_valid,
  output  io_in_46_ready,
  input  io_in_46_valid,
  output  io_in_47_ready,
  input  io_in_47_valid,
  output  io_in_48_ready,
  input  io_in_48_valid,
  output  io_in_49_ready,
  input  io_in_49_valid,
  output  io_in_50_ready,
  input  io_in_50_valid,
  output  io_in_51_ready,
  input  io_in_51_valid,
  output  io_in_52_ready,
  input  io_in_52_valid,
  output  io_in_53_ready,
  input  io_in_53_valid,
  output  io_in_54_ready,
  input  io_in_54_valid,
  output  io_in_55_ready,
  input  io_in_55_valid,
  output  io_in_56_ready,
  input  io_in_56_valid,
  output  io_in_57_ready,
  input  io_in_57_valid,
  output  io_in_58_ready,
  input  io_in_58_valid,
  output  io_in_59_ready,
  input  io_in_59_valid,
  output  io_in_60_ready,
  input  io_in_60_valid,
  output  io_in_61_ready,
  input  io_in_61_valid,
  output  io_in_62_ready,
  input  io_in_62_valid,
  output  io_in_63_ready,
  input  io_in_63_valid,
  output  io_in_64_ready,
  input  io_in_64_valid,
  output  io_in_65_ready,
  input  io_in_65_valid,
  output  io_in_66_ready,
  input  io_in_66_valid,
  output  io_in_67_ready,
  input  io_in_67_valid,
  output  io_in_68_ready,
  input  io_in_68_valid,
  output  io_in_69_ready,
  input  io_in_69_valid,
  output  io_in_70_ready,
  input  io_in_70_valid,
  output  io_in_71_ready,
  input  io_in_71_valid,
  output  io_out_valid
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_in_4_ready = '0;
  assign io_in_5_ready = '0;
  assign io_in_6_ready = '0;
  assign io_in_7_ready = '0;
  assign io_in_8_ready = '0;
  assign io_in_9_ready = '0;
  assign io_in_10_ready = '0;
  assign io_in_11_ready = '0;
  assign io_in_12_ready = '0;
  assign io_in_13_ready = '0;
  assign io_in_14_ready = '0;
  assign io_in_15_ready = '0;
  assign io_in_16_ready = '0;
  assign io_in_17_ready = '0;
  assign io_in_18_ready = '0;
  assign io_in_19_ready = '0;
  assign io_in_20_ready = '0;
  assign io_in_21_ready = '0;
  assign io_in_22_ready = '0;
  assign io_in_23_ready = '0;
  assign io_in_24_ready = '0;
  assign io_in_25_ready = '0;
  assign io_in_26_ready = '0;
  assign io_in_27_ready = '0;
  assign io_in_28_ready = '0;
  assign io_in_29_ready = '0;
  assign io_in_30_ready = '0;
  assign io_in_31_ready = '0;
  assign io_in_32_ready = '0;
  assign io_in_33_ready = '0;
  assign io_in_34_ready = '0;
  assign io_in_35_ready = '0;
  assign io_in_36_ready = '0;
  assign io_in_37_ready = '0;
  assign io_in_38_ready = '0;
  assign io_in_39_ready = '0;
  assign io_in_40_ready = '0;
  assign io_in_41_ready = '0;
  assign io_in_42_ready = '0;
  assign io_in_43_ready = '0;
  assign io_in_44_ready = '0;
  assign io_in_45_ready = '0;
  assign io_in_46_ready = '0;
  assign io_in_47_ready = '0;
  assign io_in_48_ready = '0;
  assign io_in_49_ready = '0;
  assign io_in_50_ready = '0;
  assign io_in_51_ready = '0;
  assign io_in_52_ready = '0;
  assign io_in_53_ready = '0;
  assign io_in_54_ready = '0;
  assign io_in_55_ready = '0;
  assign io_in_56_ready = '0;
  assign io_in_57_ready = '0;
  assign io_in_58_ready = '0;
  assign io_in_59_ready = '0;
  assign io_in_60_ready = '0;
  assign io_in_61_ready = '0;
  assign io_in_62_ready = '0;
  assign io_in_63_ready = '0;
  assign io_in_64_ready = '0;
  assign io_in_65_ready = '0;
  assign io_in_66_ready = '0;
  assign io_in_67_ready = '0;
  assign io_in_68_ready = '0;
  assign io_in_69_ready = '0;
  assign io_in_70_ready = '0;
  assign io_in_71_ready = '0;
  assign io_out_valid = '0;
endmodule

module L2Cache(
  input  clock,
  input  reset,
  input  [5:0] mbist_array,
  input  mbist_all,
  input  mbist_req,
  output  mbist_ack,
  input  mbist_writeen,
  input  [7:0] mbist_be,
  input  [12:0] mbist_addr,
  input  [103:0] mbist_indata,
  input  mbist_readen,
  input  [12:0] mbist_addr_rd,
  output  [103:0] mbist_outdata,
  output  toNextPipeline_0_array,
  output  toNextPipeline_0_all,
  output  toNextPipeline_0_req,
  input  toNextPipeline_0_ack,
  output  toNextPipeline_0_writeen,
  output  toNextPipeline_0_be,
  output  [8:0] toNextPipeline_0_addr,
  output  [12:0] toNextPipeline_0_indata,
  output  toNextPipeline_0_readen,
  output  [8:0] toNextPipeline_0_addr_rd,
  input  [12:0] toNextPipeline_0_outdata,
  output  [4:0] toNextPipeline_1_array,
  output  toNextPipeline_1_all,
  output  toNextPipeline_1_req,
  input  toNextPipeline_1_ack,
  output  toNextPipeline_1_writeen,
  output  [7:0] toNextPipeline_1_be,
  output  [12:0] toNextPipeline_1_addr,
  output  [103:0] toNextPipeline_1_indata,
  output  toNextPipeline_1_readen,
  output  [12:0] toNextPipeline_1_addr_rd,
  input  [103:0] toNextPipeline_1_outdata,
  output  [4:0] toNextPipeline_2_array,
  output  toNextPipeline_2_all,
  output  toNextPipeline_2_req,
  input  toNextPipeline_2_ack,
  output  toNextPipeline_2_writeen,
  output  [7:0] toNextPipeline_2_be,
  output  [12:0] toNextPipeline_2_addr,
  output  [103:0] toNextPipeline_2_indata,
  output  toNextPipeline_2_readen,
  output  [12:0] toNextPipeline_2_addr_rd,
  input  [103:0] toNextPipeline_2_outdata,
  output  [5:0] toNextPipeline_3_array,
  output  toNextPipeline_3_all,
  output  toNextPipeline_3_req,
  input  toNextPipeline_3_ack,
  output  toNextPipeline_3_writeen,
  output  [7:0] toNextPipeline_3_be,
  output  [12:0] toNextPipeline_3_addr,
  output  [103:0] toNextPipeline_3_indata,
  output  toNextPipeline_3_readen,
  output  [12:0] toNextPipeline_3_addr_rd,
  input  [103:0] toNextPipeline_3_outdata,
  output  [5:0] toNextPipeline_4_array,
  output  toNextPipeline_4_all,
  output  toNextPipeline_4_req,
  input  toNextPipeline_4_ack,
  output  toNextPipeline_4_writeen,
  output  [7:0] toNextPipeline_4_be,
  output  [12:0] toNextPipeline_4_addr,
  output  [103:0] toNextPipeline_4_indata,
  output  toNextPipeline_4_readen,
  output  [12:0] toNextPipeline_4_addr_rd,
  input  [103:0] toNextPipeline_4_outdata
);
  assign mbist_ack = '0;
  assign mbist_outdata = '0;
  assign toNextPipeline_0_array = '0;
  assign toNextPipeline_0_all = '0;
  assign toNextPipeline_0_req = '0;
  assign toNextPipeline_0_writeen = '0;
  assign toNextPipeline_0_be = '0;
  assign toNextPipeline_0_addr = '0;
  assign toNextPipeline_0_indata = '0;
  assign toNextPipeline_0_readen = '0;
  assign toNextPipeline_0_addr_rd = '0;
  assign toNextPipeline_1_array = '0;
  assign toNextPipeline_1_all = '0;
  assign toNextPipeline_1_req = '0;
  assign toNextPipeline_1_writeen = '0;
  assign toNextPipeline_1_be = '0;
  assign toNextPipeline_1_addr = '0;
  assign toNextPipeline_1_indata = '0;
  assign toNextPipeline_1_readen = '0;
  assign toNextPipeline_1_addr_rd = '0;
  assign toNextPipeline_2_array = '0;
  assign toNextPipeline_2_all = '0;
  assign toNextPipeline_2_req = '0;
  assign toNextPipeline_2_writeen = '0;
  assign toNextPipeline_2_be = '0;
  assign toNextPipeline_2_addr = '0;
  assign toNextPipeline_2_indata = '0;
  assign toNextPipeline_2_readen = '0;
  assign toNextPipeline_2_addr_rd = '0;
  assign toNextPipeline_3_array = '0;
  assign toNextPipeline_3_all = '0;
  assign toNextPipeline_3_req = '0;
  assign toNextPipeline_3_writeen = '0;
  assign toNextPipeline_3_be = '0;
  assign toNextPipeline_3_addr = '0;
  assign toNextPipeline_3_indata = '0;
  assign toNextPipeline_3_readen = '0;
  assign toNextPipeline_3_addr_rd = '0;
  assign toNextPipeline_4_array = '0;
  assign toNextPipeline_4_all = '0;
  assign toNextPipeline_4_req = '0;
  assign toNextPipeline_4_writeen = '0;
  assign toNextPipeline_4_be = '0;
  assign toNextPipeline_4_addr = '0;
  assign toNextPipeline_4_indata = '0;
  assign toNextPipeline_4_readen = '0;
  assign toNextPipeline_4_addr_rd = '0;
endmodule

module LinkMonitor(
  input  clock,
  input  reset,
  output  io_in_tx_req_ready,
  input  io_in_tx_req_valid,
  input  [3:0] io_in_tx_req_bits_qos,
  input  [10:0] io_in_tx_req_bits_tgtID,
  input  [11:0] io_in_tx_req_bits_txnID,
  input  [10:0] io_in_tx_req_bits_returnNID,
  input  io_in_tx_req_bits_stashNIDValid,
  input  [11:0] io_in_tx_req_bits_returnTxnID,
  input  [6:0] io_in_tx_req_bits_opcode,
  input  [2:0] io_in_tx_req_bits_size,
  input  [47:0] io_in_tx_req_bits_addr,
  input  io_in_tx_req_bits_ns,
  input  io_in_tx_req_bits_likelyshared,
  input  io_in_tx_req_bits_allowRetry,
  input  [1:0] io_in_tx_req_bits_order,
  input  [3:0] io_in_tx_req_bits_pCrdType,
  input  io_in_tx_req_bits_memAttr_allocate,
  input  io_in_tx_req_bits_memAttr_cacheable,
  input  io_in_tx_req_bits_memAttr_device,
  input  io_in_tx_req_bits_memAttr_ewa,
  input  io_in_tx_req_bits_snpAttr,
  input  [7:0] io_in_tx_req_bits_lpIDWithPadding,
  input  io_in_tx_req_bits_snoopMe,
  input  io_in_tx_req_bits_expCompAck,
  input  [1:0] io_in_tx_req_bits_tagOp,
  input  io_in_tx_req_bits_traceTag,
  input  io_in_tx_req_bits_mpam_perfMonGroup,
  input  [8:0] io_in_tx_req_bits_mpam_partID,
  input  io_in_tx_req_bits_mpam_mpamNS,
  input  [3:0] io_in_tx_req_bits_rsvdc,
  output  io_in_tx_rsp_ready,
  input  io_in_tx_rsp_valid,
  input  [3:0] io_in_tx_rsp_bits_qos,
  input  [10:0] io_in_tx_rsp_bits_tgtID,
  input  [11:0] io_in_tx_rsp_bits_txnID,
  input  [4:0] io_in_tx_rsp_bits_opcode,
  input  [1:0] io_in_tx_rsp_bits_respErr,
  input  [2:0] io_in_tx_rsp_bits_resp,
  input  [2:0] io_in_tx_rsp_bits_fwdState,
  input  [2:0] io_in_tx_rsp_bits_cBusy,
  input  [11:0] io_in_tx_rsp_bits_dbID,
  input  [3:0] io_in_tx_rsp_bits_pCrdType,
  input  [1:0] io_in_tx_rsp_bits_tagOp,
  input  io_in_tx_rsp_bits_traceTag,
  output  io_in_tx_dat_ready,
  input  io_in_tx_dat_valid,
  input  [3:0] io_in_tx_dat_bits_qos,
  input  [10:0] io_in_tx_dat_bits_tgtID,
  input  [11:0] io_in_tx_dat_bits_txnID,
  input  [10:0] io_in_tx_dat_bits_homeNID,
  input  [3:0] io_in_tx_dat_bits_opcode,
  input  [1:0] io_in_tx_dat_bits_respErr,
  input  [2:0] io_in_tx_dat_bits_resp,
  input  [3:0] io_in_tx_dat_bits_dataSource,
  input  [2:0] io_in_tx_dat_bits_cBusy,
  input  [11:0] io_in_tx_dat_bits_dbID,
  input  [1:0] io_in_tx_dat_bits_ccID,
  input  [1:0] io_in_tx_dat_bits_dataID,
  input  [1:0] io_in_tx_dat_bits_tagOp,
  input  [7:0] io_in_tx_dat_bits_tag,
  input  [1:0] io_in_tx_dat_bits_tu,
  input  io_in_tx_dat_bits_traceTag,
  input  [3:0] io_in_tx_dat_bits_rsvdc,
  input  [31:0] io_in_tx_dat_bits_be,
  input  [255:0] io_in_tx_dat_bits_data,
  input  [31:0] io_in_tx_dat_bits_dataCheck,
  input  [3:0] io_in_tx_dat_bits_poison,
  input  io_in_rx_rsp_ready,
  output  io_in_rx_rsp_valid,
  output  [3:0] io_in_rx_rsp_bits_qos,
  output  [10:0] io_in_rx_rsp_bits_tgtID,
  output  [10:0] io_in_rx_rsp_bits_srcID,
  output  [11:0] io_in_rx_rsp_bits_txnID,
  output  [4:0] io_in_rx_rsp_bits_opcode,
  output  [1:0] io_in_rx_rsp_bits_respErr,
  output  [2:0] io_in_rx_rsp_bits_resp,
  output  [2:0] io_in_rx_rsp_bits_fwdState,
  output  [2:0] io_in_rx_rsp_bits_cBusy,
  output  [11:0] io_in_rx_rsp_bits_dbID,
  output  [3:0] io_in_rx_rsp_bits_pCrdType,
  output  [1:0] io_in_rx_rsp_bits_tagOp,
  output  io_in_rx_rsp_bits_traceTag,
  input  io_in_rx_dat_ready,
  output  io_in_rx_dat_valid,
  output  [3:0] io_in_rx_dat_bits_qos,
  output  [10:0] io_in_rx_dat_bits_tgtID,
  output  [10:0] io_in_rx_dat_bits_srcID,
  output  [11:0] io_in_rx_dat_bits_txnID,
  output  [10:0] io_in_rx_dat_bits_homeNID,
  output  [3:0] io_in_rx_dat_bits_opcode,
  output  [1:0] io_in_rx_dat_bits_respErr,
  output  [2:0] io_in_rx_dat_bits_resp,
  output  [3:0] io_in_rx_dat_bits_dataSource,
  output  [2:0] io_in_rx_dat_bits_cBusy,
  output  [11:0] io_in_rx_dat_bits_dbID,
  output  [1:0] io_in_rx_dat_bits_ccID,
  output  [1:0] io_in_rx_dat_bits_dataID,
  output  [1:0] io_in_rx_dat_bits_tagOp,
  output  [7:0] io_in_rx_dat_bits_tag,
  output  [1:0] io_in_rx_dat_bits_tu,
  output  io_in_rx_dat_bits_traceTag,
  output  [3:0] io_in_rx_dat_bits_rsvdc,
  output  [31:0] io_in_rx_dat_bits_be,
  output  [255:0] io_in_rx_dat_bits_data,
  output  [31:0] io_in_rx_dat_bits_dataCheck,
  output  [3:0] io_in_rx_dat_bits_poison,
  input  io_in_rx_snp_ready,
  output  io_in_rx_snp_valid,
  output  [3:0] io_in_rx_snp_bits_qos,
  output  [10:0] io_in_rx_snp_bits_srcID,
  output  [11:0] io_in_rx_snp_bits_txnID,
  output  [10:0] io_in_rx_snp_bits_fwdNID,
  output  [11:0] io_in_rx_snp_bits_fwdTxnID,
  output  [4:0] io_in_rx_snp_bits_opcode,
  output  [44:0] io_in_rx_snp_bits_addr,
  output  io_in_rx_snp_bits_ns,
  output  io_in_rx_snp_bits_doNotGoToSD,
  output  io_in_rx_snp_bits_retToSrc,
  output  io_in_rx_snp_bits_traceTag,
  output  io_in_rx_snp_bits_mpam_perfMonGroup,
  output  [8:0] io_in_rx_snp_bits_mpam_partID,
  output  io_in_rx_snp_bits_mpam_mpamNS,
  output  io_out_txsactive,
  input  io_out_rxsactive,
  output  io_out_syscoreq,
  input  io_out_syscoack,
  output  io_out_tx_linkactivereq,
  input  io_out_tx_linkactiveack,
  output  io_out_tx_req_flitpend,
  output  io_out_tx_req_flitv,
  output  [161:0] io_out_tx_req_flit,
  input  io_out_tx_req_lcrdv,
  output  io_out_tx_rsp_flitpend,
  output  io_out_tx_rsp_flitv,
  output  [72:0] io_out_tx_rsp_flit,
  input  io_out_tx_rsp_lcrdv,
  output  io_out_tx_dat_flitpend,
  output  io_out_tx_dat_flitv,
  output  [421:0] io_out_tx_dat_flit,
  input  io_out_tx_dat_lcrdv,
  input  io_out_rx_linkactivereq,
  output  io_out_rx_linkactiveack,
  input  io_out_rx_rsp_flitpend,
  input  io_out_rx_rsp_flitv,
  input  [72:0] io_out_rx_rsp_flit,
  output  io_out_rx_rsp_lcrdv,
  input  io_out_rx_dat_flitpend,
  input  io_out_rx_dat_flitv,
  input  [421:0] io_out_rx_dat_flit,
  output  io_out_rx_dat_lcrdv,
  input  io_out_rx_snp_flitpend,
  input  io_out_rx_snp_flitv,
  input  [114:0] io_out_rx_snp_flit,
  output  io_out_rx_snp_lcrdv,
  input  [10:0] io_nodeID
);
  assign io_in_tx_req_ready = '0;
  assign io_in_tx_rsp_ready = '0;
  assign io_in_tx_dat_ready = '0;
  assign io_in_rx_rsp_valid = '0;
  assign io_in_rx_rsp_bits_qos = '0;
  assign io_in_rx_rsp_bits_tgtID = '0;
  assign io_in_rx_rsp_bits_srcID = '0;
  assign io_in_rx_rsp_bits_txnID = '0;
  assign io_in_rx_rsp_bits_opcode = '0;
  assign io_in_rx_rsp_bits_respErr = '0;
  assign io_in_rx_rsp_bits_resp = '0;
  assign io_in_rx_rsp_bits_fwdState = '0;
  assign io_in_rx_rsp_bits_cBusy = '0;
  assign io_in_rx_rsp_bits_dbID = '0;
  assign io_in_rx_rsp_bits_pCrdType = '0;
  assign io_in_rx_rsp_bits_tagOp = '0;
  assign io_in_rx_rsp_bits_traceTag = '0;
  assign io_in_rx_dat_valid = '0;
  assign io_in_rx_dat_bits_qos = '0;
  assign io_in_rx_dat_bits_tgtID = '0;
  assign io_in_rx_dat_bits_srcID = '0;
  assign io_in_rx_dat_bits_txnID = '0;
  assign io_in_rx_dat_bits_homeNID = '0;
  assign io_in_rx_dat_bits_opcode = '0;
  assign io_in_rx_dat_bits_respErr = '0;
  assign io_in_rx_dat_bits_resp = '0;
  assign io_in_rx_dat_bits_dataSource = '0;
  assign io_in_rx_dat_bits_cBusy = '0;
  assign io_in_rx_dat_bits_dbID = '0;
  assign io_in_rx_dat_bits_ccID = '0;
  assign io_in_rx_dat_bits_dataID = '0;
  assign io_in_rx_dat_bits_tagOp = '0;
  assign io_in_rx_dat_bits_tag = '0;
  assign io_in_rx_dat_bits_tu = '0;
  assign io_in_rx_dat_bits_traceTag = '0;
  assign io_in_rx_dat_bits_rsvdc = '0;
  assign io_in_rx_dat_bits_be = '0;
  assign io_in_rx_dat_bits_data = '0;
  assign io_in_rx_dat_bits_dataCheck = '0;
  assign io_in_rx_dat_bits_poison = '0;
  assign io_in_rx_snp_valid = '0;
  assign io_in_rx_snp_bits_qos = '0;
  assign io_in_rx_snp_bits_srcID = '0;
  assign io_in_rx_snp_bits_txnID = '0;
  assign io_in_rx_snp_bits_fwdNID = '0;
  assign io_in_rx_snp_bits_fwdTxnID = '0;
  assign io_in_rx_snp_bits_opcode = '0;
  assign io_in_rx_snp_bits_addr = '0;
  assign io_in_rx_snp_bits_ns = '0;
  assign io_in_rx_snp_bits_doNotGoToSD = '0;
  assign io_in_rx_snp_bits_retToSrc = '0;
  assign io_in_rx_snp_bits_traceTag = '0;
  assign io_in_rx_snp_bits_mpam_perfMonGroup = '0;
  assign io_in_rx_snp_bits_mpam_partID = '0;
  assign io_in_rx_snp_bits_mpam_mpamNS = '0;
  assign io_out_txsactive = '0;
  assign io_out_syscoreq = '0;
  assign io_out_tx_linkactivereq = '0;
  assign io_out_tx_req_flitpend = '0;
  assign io_out_tx_req_flitv = '0;
  assign io_out_tx_req_flit = '0;
  assign io_out_tx_rsp_flitpend = '0;
  assign io_out_tx_rsp_flitv = '0;
  assign io_out_tx_rsp_flit = '0;
  assign io_out_tx_dat_flitpend = '0;
  assign io_out_tx_dat_flitv = '0;
  assign io_out_tx_dat_flit = '0;
  assign io_out_rx_linkactiveack = '0;
  assign io_out_rx_rsp_lcrdv = '0;
  assign io_out_rx_dat_lcrdv = '0;
  assign io_out_rx_snp_lcrdv = '0;
endmodule

module MMIOBridge(
  input  clock,
  input  reset,
  output  auto_mmio_in_a_ready,
  input  auto_mmio_in_a_valid,
  input  [3:0] auto_mmio_in_a_bits_opcode,
  input  [2:0] auto_mmio_in_a_bits_param,
  input  [1:0] auto_mmio_in_a_bits_size,
  input  [2:0] auto_mmio_in_a_bits_source,
  input  [47:0] auto_mmio_in_a_bits_address,
  input  auto_mmio_in_a_bits_user_memBackType_MM,
  input  auto_mmio_in_a_bits_user_memPageType_NC,
  input  [7:0] auto_mmio_in_a_bits_mask,
  input  [63:0] auto_mmio_in_a_bits_data,
  input  auto_mmio_in_a_bits_corrupt,
  input  auto_mmio_in_d_ready,
  output  auto_mmio_in_d_valid,
  output  [3:0] auto_mmio_in_d_bits_opcode,
  output  [1:0] auto_mmio_in_d_bits_param,
  output  [1:0] auto_mmio_in_d_bits_size,
  output  [2:0] auto_mmio_in_d_bits_source,
  output  auto_mmio_in_d_bits_sink,
  output  auto_mmio_in_d_bits_denied,
  output  [63:0] auto_mmio_in_d_bits_data,
  output  auto_mmio_in_d_bits_corrupt,
  input  io_tx_req_ready,
  output  io_tx_req_valid,
  output  [3:0] io_tx_req_bits_qos,
  output  [10:0] io_tx_req_bits_tgtID,
  output  [10:0] io_tx_req_bits_srcID,
  output  [11:0] io_tx_req_bits_txnID,
  output  [10:0] io_tx_req_bits_returnNID,
  output  io_tx_req_bits_stashNIDValid,
  output  [11:0] io_tx_req_bits_returnTxnID,
  output  [6:0] io_tx_req_bits_opcode,
  output  [2:0] io_tx_req_bits_size,
  output  [47:0] io_tx_req_bits_addr,
  output  io_tx_req_bits_ns,
  output  io_tx_req_bits_likelyshared,
  output  io_tx_req_bits_allowRetry,
  output  [1:0] io_tx_req_bits_order,
  output  [3:0] io_tx_req_bits_pCrdType,
  output  io_tx_req_bits_memAttr_allocate,
  output  io_tx_req_bits_memAttr_cacheable,
  output  io_tx_req_bits_memAttr_device,
  output  io_tx_req_bits_memAttr_ewa,
  output  io_tx_req_bits_snpAttr,
  output  [7:0] io_tx_req_bits_lpIDWithPadding,
  output  io_tx_req_bits_snoopMe,
  output  io_tx_req_bits_expCompAck,
  output  [1:0] io_tx_req_bits_tagOp,
  output  io_tx_req_bits_traceTag,
  output  io_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_tx_req_bits_mpam_partID,
  output  io_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_tx_req_bits_rsvdc,
  input  io_tx_dat_ready,
  output  io_tx_dat_valid,
  output  [3:0] io_tx_dat_bits_qos,
  output  [10:0] io_tx_dat_bits_tgtID,
  output  [10:0] io_tx_dat_bits_srcID,
  output  [11:0] io_tx_dat_bits_txnID,
  output  [10:0] io_tx_dat_bits_homeNID,
  output  [3:0] io_tx_dat_bits_opcode,
  output  [1:0] io_tx_dat_bits_respErr,
  output  [2:0] io_tx_dat_bits_resp,
  output  [3:0] io_tx_dat_bits_dataSource,
  output  [2:0] io_tx_dat_bits_cBusy,
  output  [11:0] io_tx_dat_bits_dbID,
  output  [1:0] io_tx_dat_bits_ccID,
  output  [1:0] io_tx_dat_bits_dataID,
  output  [1:0] io_tx_dat_bits_tagOp,
  output  [7:0] io_tx_dat_bits_tag,
  output  [1:0] io_tx_dat_bits_tu,
  output  io_tx_dat_bits_traceTag,
  output  [3:0] io_tx_dat_bits_rsvdc,
  output  [31:0] io_tx_dat_bits_be,
  output  [255:0] io_tx_dat_bits_data,
  output  [31:0] io_tx_dat_bits_dataCheck,
  output  [3:0] io_tx_dat_bits_poison,
  output  io_rx_rsp_ready,
  input  io_rx_rsp_valid,
  input  [3:0] io_rx_rsp_bits_qos,
  input  [10:0] io_rx_rsp_bits_tgtID,
  input  [10:0] io_rx_rsp_bits_srcID,
  input  [11:0] io_rx_rsp_bits_txnID,
  input  [4:0] io_rx_rsp_bits_opcode,
  input  [1:0] io_rx_rsp_bits_respErr,
  input  [2:0] io_rx_rsp_bits_resp,
  input  [2:0] io_rx_rsp_bits_fwdState,
  input  [2:0] io_rx_rsp_bits_cBusy,
  input  [11:0] io_rx_rsp_bits_dbID,
  input  [3:0] io_rx_rsp_bits_pCrdType,
  input  [1:0] io_rx_rsp_bits_tagOp,
  input  io_rx_rsp_bits_traceTag,
  output  io_rx_dat_ready,
  input  io_rx_dat_valid,
  input  [3:0] io_rx_dat_bits_qos,
  input  [10:0] io_rx_dat_bits_tgtID,
  input  [10:0] io_rx_dat_bits_srcID,
  input  [11:0] io_rx_dat_bits_txnID,
  input  [10:0] io_rx_dat_bits_homeNID,
  input  [3:0] io_rx_dat_bits_opcode,
  input  [1:0] io_rx_dat_bits_respErr,
  input  [2:0] io_rx_dat_bits_resp,
  input  [3:0] io_rx_dat_bits_dataSource,
  input  [2:0] io_rx_dat_bits_cBusy,
  input  [11:0] io_rx_dat_bits_dbID,
  input  [1:0] io_rx_dat_bits_ccID,
  input  [1:0] io_rx_dat_bits_dataID,
  input  [1:0] io_rx_dat_bits_tagOp,
  input  [7:0] io_rx_dat_bits_tag,
  input  [1:0] io_rx_dat_bits_tu,
  input  io_rx_dat_bits_traceTag,
  input  [3:0] io_rx_dat_bits_rsvdc,
  input  [31:0] io_rx_dat_bits_be,
  input  [255:0] io_rx_dat_bits_data,
  input  [31:0] io_rx_dat_bits_dataCheck,
  input  [3:0] io_rx_dat_bits_poison,
  output  io_pCrd_0_query_valid,
  output  [3:0] io_pCrd_0_query_bits_pCrdType,
  output  [10:0] io_pCrd_0_query_bits_srcID,
  input  io_pCrd_0_grant,
  output  io_pCrd_1_query_valid,
  output  [3:0] io_pCrd_1_query_bits_pCrdType,
  output  [10:0] io_pCrd_1_query_bits_srcID,
  input  io_pCrd_1_grant,
  output  io_pCrd_2_query_valid,
  output  [3:0] io_pCrd_2_query_bits_pCrdType,
  output  [10:0] io_pCrd_2_query_bits_srcID,
  input  io_pCrd_2_grant,
  output  io_pCrd_3_query_valid,
  output  [3:0] io_pCrd_3_query_bits_pCrdType,
  output  [10:0] io_pCrd_3_query_bits_srcID,
  input  io_pCrd_3_grant,
  output  io_pCrd_4_query_valid,
  output  [3:0] io_pCrd_4_query_bits_pCrdType,
  output  [10:0] io_pCrd_4_query_bits_srcID,
  input  io_pCrd_4_grant,
  output  io_pCrd_5_query_valid,
  output  [3:0] io_pCrd_5_query_bits_pCrdType,
  output  [10:0] io_pCrd_5_query_bits_srcID,
  input  io_pCrd_5_grant,
  output  io_pCrd_6_query_valid,
  output  [3:0] io_pCrd_6_query_bits_pCrdType,
  output  [10:0] io_pCrd_6_query_bits_srcID,
  input  io_pCrd_6_grant,
  output  io_pCrd_7_query_valid,
  output  [3:0] io_pCrd_7_query_bits_pCrdType,
  output  [10:0] io_pCrd_7_query_bits_srcID,
  input  io_pCrd_7_grant
);
  assign auto_mmio_in_a_ready = '0;
  assign auto_mmio_in_d_valid = '0;
  assign auto_mmio_in_d_bits_opcode = '0;
  assign auto_mmio_in_d_bits_param = '0;
  assign auto_mmio_in_d_bits_size = '0;
  assign auto_mmio_in_d_bits_source = '0;
  assign auto_mmio_in_d_bits_sink = '0;
  assign auto_mmio_in_d_bits_denied = '0;
  assign auto_mmio_in_d_bits_data = '0;
  assign auto_mmio_in_d_bits_corrupt = '0;
  assign io_tx_req_valid = '0;
  assign io_tx_req_bits_qos = '0;
  assign io_tx_req_bits_tgtID = '0;
  assign io_tx_req_bits_srcID = '0;
  assign io_tx_req_bits_txnID = '0;
  assign io_tx_req_bits_returnNID = '0;
  assign io_tx_req_bits_stashNIDValid = '0;
  assign io_tx_req_bits_returnTxnID = '0;
  assign io_tx_req_bits_opcode = '0;
  assign io_tx_req_bits_size = '0;
  assign io_tx_req_bits_addr = '0;
  assign io_tx_req_bits_ns = '0;
  assign io_tx_req_bits_likelyshared = '0;
  assign io_tx_req_bits_allowRetry = '0;
  assign io_tx_req_bits_order = '0;
  assign io_tx_req_bits_pCrdType = '0;
  assign io_tx_req_bits_memAttr_allocate = '0;
  assign io_tx_req_bits_memAttr_cacheable = '0;
  assign io_tx_req_bits_memAttr_device = '0;
  assign io_tx_req_bits_memAttr_ewa = '0;
  assign io_tx_req_bits_snpAttr = '0;
  assign io_tx_req_bits_lpIDWithPadding = '0;
  assign io_tx_req_bits_snoopMe = '0;
  assign io_tx_req_bits_expCompAck = '0;
  assign io_tx_req_bits_tagOp = '0;
  assign io_tx_req_bits_traceTag = '0;
  assign io_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_tx_req_bits_mpam_partID = '0;
  assign io_tx_req_bits_mpam_mpamNS = '0;
  assign io_tx_req_bits_rsvdc = '0;
  assign io_tx_dat_valid = '0;
  assign io_tx_dat_bits_qos = '0;
  assign io_tx_dat_bits_tgtID = '0;
  assign io_tx_dat_bits_srcID = '0;
  assign io_tx_dat_bits_txnID = '0;
  assign io_tx_dat_bits_homeNID = '0;
  assign io_tx_dat_bits_opcode = '0;
  assign io_tx_dat_bits_respErr = '0;
  assign io_tx_dat_bits_resp = '0;
  assign io_tx_dat_bits_dataSource = '0;
  assign io_tx_dat_bits_cBusy = '0;
  assign io_tx_dat_bits_dbID = '0;
  assign io_tx_dat_bits_ccID = '0;
  assign io_tx_dat_bits_dataID = '0;
  assign io_tx_dat_bits_tagOp = '0;
  assign io_tx_dat_bits_tag = '0;
  assign io_tx_dat_bits_tu = '0;
  assign io_tx_dat_bits_traceTag = '0;
  assign io_tx_dat_bits_rsvdc = '0;
  assign io_tx_dat_bits_be = '0;
  assign io_tx_dat_bits_data = '0;
  assign io_tx_dat_bits_dataCheck = '0;
  assign io_tx_dat_bits_poison = '0;
  assign io_rx_rsp_ready = '0;
  assign io_rx_dat_ready = '0;
  assign io_pCrd_0_query_valid = '0;
  assign io_pCrd_0_query_bits_pCrdType = '0;
  assign io_pCrd_0_query_bits_srcID = '0;
  assign io_pCrd_1_query_valid = '0;
  assign io_pCrd_1_query_bits_pCrdType = '0;
  assign io_pCrd_1_query_bits_srcID = '0;
  assign io_pCrd_2_query_valid = '0;
  assign io_pCrd_2_query_bits_pCrdType = '0;
  assign io_pCrd_2_query_bits_srcID = '0;
  assign io_pCrd_3_query_valid = '0;
  assign io_pCrd_3_query_bits_pCrdType = '0;
  assign io_pCrd_3_query_bits_srcID = '0;
  assign io_pCrd_4_query_valid = '0;
  assign io_pCrd_4_query_bits_pCrdType = '0;
  assign io_pCrd_4_query_bits_srcID = '0;
  assign io_pCrd_5_query_valid = '0;
  assign io_pCrd_5_query_bits_pCrdType = '0;
  assign io_pCrd_5_query_bits_srcID = '0;
  assign io_pCrd_6_query_valid = '0;
  assign io_pCrd_6_query_bits_pCrdType = '0;
  assign io_pCrd_6_query_bits_srcID = '0;
  assign io_pCrd_7_query_valid = '0;
  assign io_pCrd_7_query_bits_pCrdType = '0;
  assign io_pCrd_7_query_bits_srcID = '0;
endmodule

module MbistIntfL2(
  output  [5:0] toPipeline_0_array,
  output  toPipeline_0_all,
  output  toPipeline_0_req,
  input  toPipeline_0_ack,
  output  toPipeline_0_writeen,
  output  [7:0] toPipeline_0_be,
  output  [12:0] toPipeline_0_addr,
  output  [103:0] toPipeline_0_indata,
  output  toPipeline_0_readen,
  output  [12:0] toPipeline_0_addr_rd,
  input  [103:0] toPipeline_0_outdata,
  input  [5:0] mbist_array,
  input  mbist_all,
  input  mbist_req,
  output  mbist_ack,
  input  mbist_writeen,
  input  [7:0] mbist_be,
  input  [12:0] mbist_addr,
  input  [103:0] mbist_indata,
  input  mbist_readen,
  input  [12:0] mbist_addr_rd,
  output  [103:0] mbist_outdata
);
  assign toPipeline_0_array = '0;
  assign toPipeline_0_all = '0;
  assign toPipeline_0_req = '0;
  assign toPipeline_0_writeen = '0;
  assign toPipeline_0_be = '0;
  assign toPipeline_0_addr = '0;
  assign toPipeline_0_indata = '0;
  assign toPipeline_0_readen = '0;
  assign toPipeline_0_addr_rd = '0;
  assign mbist_ack = '0;
  assign mbist_outdata = '0;
endmodule

module Pipeline_10(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [31:0] io_in_bits,
  output  io_out_valid,
  output  [31:0] io_out_bits
);
  assign io_out_valid = '0;
  assign io_out_bits = '0;
endmodule

module Pipeline_11(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [31:0] io_in_bits,
  output  io_out_valid,
  output  [31:0] io_out_bits
);
  assign io_out_valid = '0;
  assign io_out_bits = '0;
endmodule

module Pipeline_2(
  input  clock,
  input  reset,
  output  io_in_ready,
  input  io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0] io_in_bits_set,
  input  io_in_bits_needT,
  input  [6:0] io_in_bits_source,
  input  [43:0] io_in_bits_vaddr,
  input  io_in_bits_hit,
  input  io_in_bits_prefetched,
  input  [2:0] io_in_bits_pfsource,
  input  [4:0] io_in_bits_reqsource,
  input  io_out_ready,
  output  io_out_valid,
  output  [32:0] io_out_bits_tag,
  output  [8:0] io_out_bits_set,
  output  io_out_bits_needT,
  output  [6:0] io_out_bits_source,
  output  [43:0] io_out_bits_vaddr,
  output  [4:0] io_out_bits_reqsource
);
  assign io_in_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_tag = '0;
  assign io_out_bits_set = '0;
  assign io_out_bits_needT = '0;
  assign io_out_bits_source = '0;
  assign io_out_bits_vaddr = '0;
  assign io_out_bits_reqsource = '0;
endmodule

module Pipeline_3(
  input  clock,
  input  reset,
  output  io_in_ready,
  input  io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0] io_in_bits_set,
  input  [43:0] io_in_bits_vaddr,
  input  [4:0] io_in_bits_pfSource,
  input  io_out_ready,
  output  io_out_valid,
  output  [4:0] io_out_bits_pfSource
);
  assign io_in_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_pfSource = '0;
endmodule

module Prefetcher(
  input  clock,
  input  reset,
  output  io_train_ready,
  input  io_train_valid,
  input  [32:0] io_train_bits_tag,
  input  [8:0] io_train_bits_set,
  input  io_train_bits_needT,
  input  [6:0] io_train_bits_source,
  input  [43:0] io_train_bits_vaddr,
  input  [4:0] io_train_bits_reqsource,
  output  io_tlb_req_req_valid,
  output  [49:0] io_tlb_req_req_bits_vaddr,
  output  [2:0] io_tlb_req_req_bits_cmd,
  output  io_tlb_req_req_bits_kill,
  output  io_tlb_req_req_bits_no_translate,
  input  io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0] io_tlb_req_resp_bits_pbmt,
  input  io_tlb_req_resp_bits_miss,
  input  io_tlb_req_resp_bits_excp_0_gpf_ld,
  input  io_tlb_req_resp_bits_excp_0_pf_ld,
  input  io_tlb_req_resp_bits_excp_0_af_ld,
  input  io_tlb_req_pmp_resp_ld,
  input  io_tlb_req_pmp_resp_mmio,
  input  io_req_ready,
  output  io_req_valid,
  output  [32:0] io_req_bits_tag,
  output  [8:0] io_req_bits_set,
  output  [43:0] io_req_bits_vaddr,
  output  io_req_bits_needT,
  output  [6:0] io_req_bits_source,
  output  [4:0] io_req_bits_pfSource,
  output  io_resp_ready,
  input  io_resp_valid,
  input  [4:0] io_resp_bits_pfSource,
  input  io_recv_addr_valid,
  input  [63:0] io_recv_addr_bits_addr,
  input  [4:0] io_recv_addr_bits_pfSource,
  input  pfCtrlFromCore_l2_pf_master_en,
  input  pfCtrlFromCore_l2_pf_recv_en,
  input  pfCtrlFromCore_l2_pbop_en,
  input  pfCtrlFromCore_l2_vbop_en,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  boreChildrenBd_bore_be,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [12:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  output  [12:0] boreChildrenBd_bore_outdata
);
  assign io_train_ready = '0;
  assign io_tlb_req_req_valid = '0;
  assign io_tlb_req_req_bits_vaddr = '0;
  assign io_tlb_req_req_bits_cmd = '0;
  assign io_tlb_req_req_bits_kill = '0;
  assign io_tlb_req_req_bits_no_translate = '0;
  assign io_req_valid = '0;
  assign io_req_bits_tag = '0;
  assign io_req_bits_set = '0;
  assign io_req_bits_vaddr = '0;
  assign io_req_bits_needT = '0;
  assign io_req_bits_source = '0;
  assign io_req_bits_pfSource = '0;
  assign io_resp_ready = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module Queue72_CoupledL2Imp_Anon(
  input  clock,
  input  reset,
  output  io_enq_ready,
  input  io_enq_valid,
  input  [3:0] io_enq_bits_pCrdType,
  input  [10:0] io_enq_bits_srcID,
  input  io_deq_ready,
  output  io_deq_valid,
  output  [3:0] io_deq_bits_pCrdType,
  output  [10:0] io_deq_bits_srcID
);
  assign io_enq_ready = '0;
  assign io_deq_valid = '0;
  assign io_deq_bits_pCrdType = '0;
  assign io_deq_bits_srcID = '0;
endmodule

module RRArbiterInit_18(
  input  clock,
  input  reset,
  output  io_in_0_ready,
  input  io_in_0_valid,
  input  [3:0] io_in_0_bits_qos,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_returnNID,
  input  io_in_0_bits_stashNIDValid,
  input  [11:0] io_in_0_bits_returnTxnID,
  input  [6:0] io_in_0_bits_opcode,
  input  [47:0] io_in_0_bits_addr,
  input  io_in_0_bits_ns,
  input  io_in_0_bits_likelyshared,
  input  io_in_0_bits_allowRetry,
  input  [1:0] io_in_0_bits_order,
  input  [3:0] io_in_0_bits_pCrdType,
  input  io_in_0_bits_memAttr_allocate,
  input  io_in_0_bits_memAttr_cacheable,
  input  io_in_0_bits_memAttr_device,
  input  io_in_0_bits_memAttr_ewa,
  input  io_in_0_bits_snpAttr,
  input  [7:0] io_in_0_bits_lpIDWithPadding,
  input  io_in_0_bits_snoopMe,
  input  io_in_0_bits_expCompAck,
  input  [1:0] io_in_0_bits_tagOp,
  input  io_in_0_bits_traceTag,
  input  io_in_0_bits_mpam_perfMonGroup,
  input  [8:0] io_in_0_bits_mpam_partID,
  input  io_in_0_bits_mpam_mpamNS,
  input  [3:0] io_in_0_bits_rsvdc,
  output  io_in_1_ready,
  input  io_in_1_valid,
  input  [3:0] io_in_1_bits_qos,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_returnNID,
  input  io_in_1_bits_stashNIDValid,
  input  [11:0] io_in_1_bits_returnTxnID,
  input  [6:0] io_in_1_bits_opcode,
  input  [47:0] io_in_1_bits_addr,
  input  io_in_1_bits_ns,
  input  io_in_1_bits_likelyshared,
  input  io_in_1_bits_allowRetry,
  input  [1:0] io_in_1_bits_order,
  input  [3:0] io_in_1_bits_pCrdType,
  input  io_in_1_bits_memAttr_allocate,
  input  io_in_1_bits_memAttr_cacheable,
  input  io_in_1_bits_memAttr_device,
  input  io_in_1_bits_memAttr_ewa,
  input  io_in_1_bits_snpAttr,
  input  [7:0] io_in_1_bits_lpIDWithPadding,
  input  io_in_1_bits_snoopMe,
  input  io_in_1_bits_expCompAck,
  input  [1:0] io_in_1_bits_tagOp,
  input  io_in_1_bits_traceTag,
  input  io_in_1_bits_mpam_perfMonGroup,
  input  [8:0] io_in_1_bits_mpam_partID,
  input  io_in_1_bits_mpam_mpamNS,
  input  [3:0] io_in_1_bits_rsvdc,
  output  io_in_2_ready,
  input  io_in_2_valid,
  input  [3:0] io_in_2_bits_qos,
  input  [11:0] io_in_2_bits_txnID,
  input  [10:0] io_in_2_bits_returnNID,
  input  io_in_2_bits_stashNIDValid,
  input  [11:0] io_in_2_bits_returnTxnID,
  input  [6:0] io_in_2_bits_opcode,
  input  [47:0] io_in_2_bits_addr,
  input  io_in_2_bits_ns,
  input  io_in_2_bits_likelyshared,
  input  io_in_2_bits_allowRetry,
  input  [1:0] io_in_2_bits_order,
  input  [3:0] io_in_2_bits_pCrdType,
  input  io_in_2_bits_memAttr_allocate,
  input  io_in_2_bits_memAttr_cacheable,
  input  io_in_2_bits_memAttr_device,
  input  io_in_2_bits_memAttr_ewa,
  input  io_in_2_bits_snpAttr,
  input  [7:0] io_in_2_bits_lpIDWithPadding,
  input  io_in_2_bits_snoopMe,
  input  io_in_2_bits_expCompAck,
  input  [1:0] io_in_2_bits_tagOp,
  input  io_in_2_bits_traceTag,
  input  io_in_2_bits_mpam_perfMonGroup,
  input  [8:0] io_in_2_bits_mpam_partID,
  input  io_in_2_bits_mpam_mpamNS,
  input  [3:0] io_in_2_bits_rsvdc,
  output  io_in_3_ready,
  input  io_in_3_valid,
  input  [3:0] io_in_3_bits_qos,
  input  [11:0] io_in_3_bits_txnID,
  input  [10:0] io_in_3_bits_returnNID,
  input  io_in_3_bits_stashNIDValid,
  input  [11:0] io_in_3_bits_returnTxnID,
  input  [6:0] io_in_3_bits_opcode,
  input  [47:0] io_in_3_bits_addr,
  input  io_in_3_bits_ns,
  input  io_in_3_bits_likelyshared,
  input  io_in_3_bits_allowRetry,
  input  [1:0] io_in_3_bits_order,
  input  [3:0] io_in_3_bits_pCrdType,
  input  io_in_3_bits_memAttr_allocate,
  input  io_in_3_bits_memAttr_cacheable,
  input  io_in_3_bits_memAttr_device,
  input  io_in_3_bits_memAttr_ewa,
  input  io_in_3_bits_snpAttr,
  input  [7:0] io_in_3_bits_lpIDWithPadding,
  input  io_in_3_bits_snoopMe,
  input  io_in_3_bits_expCompAck,
  input  [1:0] io_in_3_bits_tagOp,
  input  io_in_3_bits_traceTag,
  input  io_in_3_bits_mpam_perfMonGroup,
  input  [8:0] io_in_3_bits_mpam_partID,
  input  io_in_3_bits_mpam_mpamNS,
  input  [3:0] io_in_3_bits_rsvdc,
  output  io_in_4_ready,
  input  io_in_4_valid,
  input  [3:0] io_in_4_bits_qos,
  input  [10:0] io_in_4_bits_tgtID,
  input  [11:0] io_in_4_bits_txnID,
  input  [10:0] io_in_4_bits_returnNID,
  input  io_in_4_bits_stashNIDValid,
  input  [11:0] io_in_4_bits_returnTxnID,
  input  [6:0] io_in_4_bits_opcode,
  input  [2:0] io_in_4_bits_size,
  input  [47:0] io_in_4_bits_addr,
  input  io_in_4_bits_ns,
  input  io_in_4_bits_likelyshared,
  input  io_in_4_bits_allowRetry,
  input  [1:0] io_in_4_bits_order,
  input  [3:0] io_in_4_bits_pCrdType,
  input  io_in_4_bits_memAttr_allocate,
  input  io_in_4_bits_memAttr_cacheable,
  input  io_in_4_bits_memAttr_device,
  input  io_in_4_bits_memAttr_ewa,
  input  io_in_4_bits_snpAttr,
  input  [7:0] io_in_4_bits_lpIDWithPadding,
  input  io_in_4_bits_snoopMe,
  input  io_in_4_bits_expCompAck,
  input  [1:0] io_in_4_bits_tagOp,
  input  io_in_4_bits_traceTag,
  input  io_in_4_bits_mpam_perfMonGroup,
  input  [8:0] io_in_4_bits_mpam_partID,
  input  io_in_4_bits_mpam_mpamNS,
  input  [3:0] io_in_4_bits_rsvdc,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_tgtID,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_returnNID,
  output  io_out_bits_stashNIDValid,
  output  [11:0] io_out_bits_returnTxnID,
  output  [6:0] io_out_bits_opcode,
  output  [2:0] io_out_bits_size,
  output  [47:0] io_out_bits_addr,
  output  io_out_bits_ns,
  output  io_out_bits_likelyshared,
  output  io_out_bits_allowRetry,
  output  [1:0] io_out_bits_order,
  output  [3:0] io_out_bits_pCrdType,
  output  io_out_bits_memAttr_allocate,
  output  io_out_bits_memAttr_cacheable,
  output  io_out_bits_memAttr_device,
  output  io_out_bits_memAttr_ewa,
  output  io_out_bits_snpAttr,
  output  [7:0] io_out_bits_lpIDWithPadding,
  output  io_out_bits_snoopMe,
  output  io_out_bits_expCompAck,
  output  [1:0] io_out_bits_tagOp,
  output  io_out_bits_traceTag,
  output  io_out_bits_mpam_perfMonGroup,
  output  [8:0] io_out_bits_mpam_partID,
  output  io_out_bits_mpam_mpamNS,
  output  [3:0] io_out_bits_rsvdc,
  output  [2:0] io_chosen
);
  assign io_in_0_ready = '0;
  assign io_in_1_ready = '0;
  assign io_in_2_ready = '0;
  assign io_in_3_ready = '0;
  assign io_in_4_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_returnNID = '0;
  assign io_out_bits_stashNIDValid = '0;
  assign io_out_bits_returnTxnID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_size = '0;
  assign io_out_bits_addr = '0;
  assign io_out_bits_ns = '0;
  assign io_out_bits_likelyshared = '0;
  assign io_out_bits_allowRetry = '0;
  assign io_out_bits_order = '0;
  assign io_out_bits_pCrdType = '0;
  assign io_out_bits_memAttr_allocate = '0;
  assign io_out_bits_memAttr_cacheable = '0;
  assign io_out_bits_memAttr_device = '0;
  assign io_out_bits_memAttr_ewa = '0;
  assign io_out_bits_snpAttr = '0;
  assign io_out_bits_lpIDWithPadding = '0;
  assign io_out_bits_snoopMe = '0;
  assign io_out_bits_expCompAck = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_mpam_perfMonGroup = '0;
  assign io_out_bits_mpam_partID = '0;
  assign io_out_bits_mpam_mpamNS = '0;
  assign io_out_bits_rsvdc = '0;
  assign io_chosen = '0;
endmodule

module Slice(
  input  clock,
  input  reset,
  output  io_in_a_ready,
  input  io_in_a_valid,
  input  [3:0] io_in_a_bits_opcode,
  input  [2:0] io_in_a_bits_param,
  input  [2:0] io_in_a_bits_size,
  input  [6:0] io_in_a_bits_source,
  input  [47:0] io_in_a_bits_address,
  input  [4:0] io_in_a_bits_user_reqSource,
  input  [1:0] io_in_a_bits_user_alias,
  input  [43:0] io_in_a_bits_user_vaddr,
  input  io_in_a_bits_user_needHint,
  input  io_in_a_bits_echo_isKeyword,
  input  io_in_a_bits_corrupt,
  input  io_in_b_ready,
  output  io_in_b_valid,
  output  [2:0] io_in_b_bits_opcode,
  output  [1:0] io_in_b_bits_param,
  output  [47:0] io_in_b_bits_address,
  output  [255:0] io_in_b_bits_data,
  output  io_in_c_ready,
  input  io_in_c_valid,
  input  [2:0] io_in_c_bits_opcode,
  input  [2:0] io_in_c_bits_param,
  input  [2:0] io_in_c_bits_size,
  input  [6:0] io_in_c_bits_source,
  input  [47:0] io_in_c_bits_address,
  input  [255:0] io_in_c_bits_data,
  input  io_in_c_bits_corrupt,
  input  io_in_d_ready,
  output  io_in_d_valid,
  output  [3:0] io_in_d_bits_opcode,
  output  [1:0] io_in_d_bits_param,
  output  [6:0] io_in_d_bits_source,
  output  [7:0] io_in_d_bits_sink,
  output  io_in_d_bits_denied,
  output  io_in_d_bits_echo_isKeyword,
  output  [255:0] io_in_d_bits_data,
  output  io_in_d_bits_corrupt,
  input  io_in_e_valid,
  input  [7:0] io_in_e_bits_sink,
  input  io_l1Hint_ready,
  output  io_l1Hint_valid,
  output  [31:0] io_l1Hint_bits_sourceId,
  output  io_l1Hint_bits_isKeyword,
  input  io_prefetch_train_ready,
  output  io_prefetch_train_valid,
  output  [32:0] io_prefetch_train_bits_tag,
  output  [8:0] io_prefetch_train_bits_set,
  output  io_prefetch_train_bits_needT,
  output  [6:0] io_prefetch_train_bits_source,
  output  [43:0] io_prefetch_train_bits_vaddr,
  output  io_prefetch_train_bits_hit,
  output  io_prefetch_train_bits_prefetched,
  output  [2:0] io_prefetch_train_bits_pfsource,
  output  [4:0] io_prefetch_train_bits_reqsource,
  output  io_prefetch_req_ready,
  input  io_prefetch_req_valid,
  input  [32:0] io_prefetch_req_bits_tag,
  input  [8:0] io_prefetch_req_bits_set,
  input  [43:0] io_prefetch_req_bits_vaddr,
  input  io_prefetch_req_bits_needT,
  input  [6:0] io_prefetch_req_bits_source,
  input  [4:0] io_prefetch_req_bits_pfSource,
  input  io_prefetch_resp_ready,
  output  io_prefetch_resp_valid,
  output  [32:0] io_prefetch_resp_bits_tag,
  output  [8:0] io_prefetch_resp_bits_set,
  output  [43:0] io_prefetch_resp_bits_vaddr,
  output  [4:0] io_prefetch_resp_bits_pfSource,
  output  io_dirResult_valid,
  output  io_dirResult_bits_hit,
  output  io_dirResult_bits_meta_prefetch,
  output  [2:0] io_dirResult_bits_meta_prefetchSrc,
  output  [2:0] io_dirResult_bits_replacerInfo_channel,
  output  [4:0] io_dirResult_bits_replacerInfo_reqSource,
  output  io_latePF,
  output  io_error_valid,
  output  io_error_bits_valid,
  output  [45:0] io_error_bits_address,
  output  io_l2Miss,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [3:0] io_out_tx_req_bits_qos,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [10:0] io_out_tx_req_bits_returnNID,
  output  io_out_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_tx_req_bits_returnTxnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_ns,
  output  io_out_tx_req_bits_likelyshared,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  [7:0] io_out_tx_req_bits_lpIDWithPadding,
  output  io_out_tx_req_bits_snoopMe,
  output  io_out_tx_req_bits_expCompAck,
  output  [1:0] io_out_tx_req_bits_tagOp,
  output  io_out_tx_req_bits_traceTag,
  output  io_out_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_tx_req_bits_mpam_partID,
  output  io_out_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_tx_req_bits_rsvdc,
  input  io_out_tx_rsp_ready,
  output  io_out_tx_rsp_valid,
  output  [3:0] io_out_tx_rsp_bits_qos,
  output  [10:0] io_out_tx_rsp_bits_tgtID,
  output  [11:0] io_out_tx_rsp_bits_txnID,
  output  [4:0] io_out_tx_rsp_bits_opcode,
  output  [1:0] io_out_tx_rsp_bits_respErr,
  output  [2:0] io_out_tx_rsp_bits_resp,
  output  [2:0] io_out_tx_rsp_bits_fwdState,
  output  [2:0] io_out_tx_rsp_bits_cBusy,
  output  [11:0] io_out_tx_rsp_bits_dbID,
  output  [3:0] io_out_tx_rsp_bits_pCrdType,
  output  [1:0] io_out_tx_rsp_bits_tagOp,
  output  io_out_tx_rsp_bits_traceTag,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [1:0] io_out_tx_dat_bits_respErr,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_ccID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  io_out_tx_dat_bits_traceTag,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  output  [3:0] io_out_tx_dat_bits_poison,
  input  io_out_rx_rsp_valid,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [1:0] io_out_rx_rsp_bits_respErr,
  input  [2:0] io_out_rx_rsp_bits_resp,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  input  [3:0] io_out_rx_rsp_bits_pCrdType,
  input  io_out_rx_rsp_bits_traceTag,
  input  io_out_rx_dat_valid,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [10:0] io_out_rx_dat_bits_homeNID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [1:0] io_out_rx_dat_bits_respErr,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [11:0] io_out_rx_dat_bits_dbID,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  io_out_rx_dat_bits_traceTag,
  input  [255:0] io_out_rx_dat_bits_data,
  input  [31:0] io_out_rx_dat_bits_dataCheck,
  input  [3:0] io_out_rx_dat_bits_poison,
  output  io_out_rx_snp_ready,
  input  io_out_rx_snp_valid,
  input  [3:0] io_out_rx_snp_bits_qos,
  input  [10:0] io_out_rx_snp_bits_srcID,
  input  [11:0] io_out_rx_snp_bits_txnID,
  input  [10:0] io_out_rx_snp_bits_fwdNID,
  input  [11:0] io_out_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_rx_snp_bits_opcode,
  input  [44:0] io_out_rx_snp_bits_addr,
  input  io_out_rx_snp_bits_ns,
  input  io_out_rx_snp_bits_doNotGoToSD,
  input  io_out_rx_snp_bits_retToSrc,
  input  io_out_rx_snp_bits_traceTag,
  input  io_out_rx_snp_bits_mpam_perfMonGroup,
  input  [8:0] io_out_rx_snp_bits_mpam_partID,
  input  io_out_rx_snp_bits_mpam_mpamNS,
  output  io_pCrd_0_query_valid,
  output  [3:0] io_pCrd_0_query_bits_pCrdType,
  output  [10:0] io_pCrd_0_query_bits_srcID,
  input  io_pCrd_0_grant,
  output  io_pCrd_1_query_valid,
  output  [3:0] io_pCrd_1_query_bits_pCrdType,
  output  [10:0] io_pCrd_1_query_bits_srcID,
  input  io_pCrd_1_grant,
  output  io_pCrd_2_query_valid,
  output  [3:0] io_pCrd_2_query_bits_pCrdType,
  output  [10:0] io_pCrd_2_query_bits_srcID,
  input  io_pCrd_2_grant,
  output  io_pCrd_3_query_valid,
  output  [3:0] io_pCrd_3_query_bits_pCrdType,
  output  [10:0] io_pCrd_3_query_bits_srcID,
  input  io_pCrd_3_grant,
  output  io_pCrd_4_query_valid,
  output  [3:0] io_pCrd_4_query_bits_pCrdType,
  output  [10:0] io_pCrd_4_query_bits_srcID,
  input  io_pCrd_4_grant,
  output  io_pCrd_5_query_valid,
  output  [3:0] io_pCrd_5_query_bits_pCrdType,
  output  [10:0] io_pCrd_5_query_bits_srcID,
  input  io_pCrd_5_grant,
  output  io_pCrd_6_query_valid,
  output  [3:0] io_pCrd_6_query_bits_pCrdType,
  output  [10:0] io_pCrd_6_query_bits_srcID,
  input  io_pCrd_6_grant,
  output  io_pCrd_7_query_valid,
  output  [3:0] io_pCrd_7_query_bits_pCrdType,
  output  [10:0] io_pCrd_7_query_bits_srcID,
  input  io_pCrd_7_grant,
  output  io_pCrd_8_query_valid,
  output  [3:0] io_pCrd_8_query_bits_pCrdType,
  output  [10:0] io_pCrd_8_query_bits_srcID,
  input  io_pCrd_8_grant,
  output  io_pCrd_9_query_valid,
  output  [3:0] io_pCrd_9_query_bits_pCrdType,
  output  [10:0] io_pCrd_9_query_bits_srcID,
  input  io_pCrd_9_grant,
  output  io_pCrd_10_query_valid,
  output  [3:0] io_pCrd_10_query_bits_pCrdType,
  output  [10:0] io_pCrd_10_query_bits_srcID,
  input  io_pCrd_10_grant,
  output  io_pCrd_11_query_valid,
  output  [3:0] io_pCrd_11_query_bits_pCrdType,
  output  [10:0] io_pCrd_11_query_bits_srcID,
  input  io_pCrd_11_grant,
  output  io_pCrd_12_query_valid,
  output  [3:0] io_pCrd_12_query_bits_pCrdType,
  output  [10:0] io_pCrd_12_query_bits_srcID,
  input  io_pCrd_12_grant,
  output  io_pCrd_13_query_valid,
  output  [3:0] io_pCrd_13_query_bits_pCrdType,
  output  [10:0] io_pCrd_13_query_bits_srcID,
  input  io_pCrd_13_grant,
  output  io_pCrd_14_query_valid,
  output  [3:0] io_pCrd_14_query_bits_pCrdType,
  output  [10:0] io_pCrd_14_query_bits_srcID,
  input  io_pCrd_14_grant,
  output  io_pCrd_15_query_valid,
  output  [3:0] io_pCrd_15_query_bits_pCrdType,
  output  [10:0] io_pCrd_15_query_bits_srcID,
  input  io_pCrd_15_grant,
  output  io_msStatus_0_valid,
  output  [2:0] io_msStatus_0_bits_channel,
  output  [8:0] io_msStatus_0_bits_set,
  output  [30:0] io_msStatus_0_bits_reqTag,
  output  io_msStatus_0_bits_is_miss,
  output  io_msStatus_0_bits_is_prefetch,
  output  io_msStatus_1_valid,
  output  [2:0] io_msStatus_1_bits_channel,
  output  [8:0] io_msStatus_1_bits_set,
  output  [30:0] io_msStatus_1_bits_reqTag,
  output  io_msStatus_1_bits_is_miss,
  output  io_msStatus_1_bits_is_prefetch,
  output  io_msStatus_2_valid,
  output  [2:0] io_msStatus_2_bits_channel,
  output  [8:0] io_msStatus_2_bits_set,
  output  [30:0] io_msStatus_2_bits_reqTag,
  output  io_msStatus_2_bits_is_miss,
  output  io_msStatus_2_bits_is_prefetch,
  output  io_msStatus_3_valid,
  output  [2:0] io_msStatus_3_bits_channel,
  output  [8:0] io_msStatus_3_bits_set,
  output  [30:0] io_msStatus_3_bits_reqTag,
  output  io_msStatus_3_bits_is_miss,
  output  io_msStatus_3_bits_is_prefetch,
  output  io_msStatus_4_valid,
  output  [2:0] io_msStatus_4_bits_channel,
  output  [8:0] io_msStatus_4_bits_set,
  output  [30:0] io_msStatus_4_bits_reqTag,
  output  io_msStatus_4_bits_is_miss,
  output  io_msStatus_4_bits_is_prefetch,
  output  io_msStatus_5_valid,
  output  [2:0] io_msStatus_5_bits_channel,
  output  [8:0] io_msStatus_5_bits_set,
  output  [30:0] io_msStatus_5_bits_reqTag,
  output  io_msStatus_5_bits_is_miss,
  output  io_msStatus_5_bits_is_prefetch,
  output  io_msStatus_6_valid,
  output  [2:0] io_msStatus_6_bits_channel,
  output  [8:0] io_msStatus_6_bits_set,
  output  [30:0] io_msStatus_6_bits_reqTag,
  output  io_msStatus_6_bits_is_miss,
  output  io_msStatus_6_bits_is_prefetch,
  output  io_msStatus_7_valid,
  output  [2:0] io_msStatus_7_bits_channel,
  output  [8:0] io_msStatus_7_bits_set,
  output  [30:0] io_msStatus_7_bits_reqTag,
  output  io_msStatus_7_bits_is_miss,
  output  io_msStatus_7_bits_is_prefetch,
  output  io_msStatus_8_valid,
  output  [2:0] io_msStatus_8_bits_channel,
  output  [8:0] io_msStatus_8_bits_set,
  output  [30:0] io_msStatus_8_bits_reqTag,
  output  io_msStatus_8_bits_is_miss,
  output  io_msStatus_8_bits_is_prefetch,
  output  io_msStatus_9_valid,
  output  [2:0] io_msStatus_9_bits_channel,
  output  [8:0] io_msStatus_9_bits_set,
  output  [30:0] io_msStatus_9_bits_reqTag,
  output  io_msStatus_9_bits_is_miss,
  output  io_msStatus_9_bits_is_prefetch,
  output  io_msStatus_10_valid,
  output  [2:0] io_msStatus_10_bits_channel,
  output  [8:0] io_msStatus_10_bits_set,
  output  [30:0] io_msStatus_10_bits_reqTag,
  output  io_msStatus_10_bits_is_miss,
  output  io_msStatus_10_bits_is_prefetch,
  output  io_msStatus_11_valid,
  output  [2:0] io_msStatus_11_bits_channel,
  output  [8:0] io_msStatus_11_bits_set,
  output  [30:0] io_msStatus_11_bits_reqTag,
  output  io_msStatus_11_bits_is_miss,
  output  io_msStatus_11_bits_is_prefetch,
  output  io_msStatus_12_valid,
  output  [2:0] io_msStatus_12_bits_channel,
  output  [8:0] io_msStatus_12_bits_set,
  output  [30:0] io_msStatus_12_bits_reqTag,
  output  io_msStatus_12_bits_is_miss,
  output  io_msStatus_12_bits_is_prefetch,
  output  io_msStatus_13_valid,
  output  [2:0] io_msStatus_13_bits_channel,
  output  [8:0] io_msStatus_13_bits_set,
  output  [30:0] io_msStatus_13_bits_reqTag,
  output  io_msStatus_13_bits_is_miss,
  output  io_msStatus_13_bits_is_prefetch,
  output  io_msStatus_14_valid,
  output  [2:0] io_msStatus_14_bits_channel,
  output  [8:0] io_msStatus_14_bits_set,
  output  [30:0] io_msStatus_14_bits_reqTag,
  output  io_msStatus_14_bits_is_miss,
  output  io_msStatus_14_bits_is_prefetch,
  output  io_msStatus_15_valid,
  output  [2:0] io_msStatus_15_bits_channel,
  output  [8:0] io_msStatus_15_bits_set,
  output  [30:0] io_msStatus_15_bits_reqTag,
  output  io_msStatus_15_bits_is_miss,
  output  io_msStatus_15_bits_is_prefetch,
  output  [5:0] io_perf_0_value,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_3_value,
  output  [5:0] io_perf_4_value,
  output  [5:0] io_perf_5_value,
  output  [5:0] io_perf_6_value,
  output  [5:0] io_perf_7_value,
  output  [5:0] io_perf_8_value,
  output  [5:0] io_perf_9_value,
  output  [5:0] io_perf_10_value,
  output  [5:0] io_perf_11_value,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  [4:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [7:0] boreChildrenBd_bore_be,
  input  [12:0] boreChildrenBd_bore_addr,
  input  [103:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [12:0] boreChildrenBd_bore_addr_rd,
  output  [103:0] boreChildrenBd_bore_outdata
);
  assign io_in_a_ready = '0;
  assign io_in_b_valid = '0;
  assign io_in_b_bits_opcode = '0;
  assign io_in_b_bits_param = '0;
  assign io_in_b_bits_address = '0;
  assign io_in_b_bits_data = '0;
  assign io_in_c_ready = '0;
  assign io_in_d_valid = '0;
  assign io_in_d_bits_opcode = '0;
  assign io_in_d_bits_param = '0;
  assign io_in_d_bits_source = '0;
  assign io_in_d_bits_sink = '0;
  assign io_in_d_bits_denied = '0;
  assign io_in_d_bits_echo_isKeyword = '0;
  assign io_in_d_bits_data = '0;
  assign io_in_d_bits_corrupt = '0;
  assign io_l1Hint_valid = '0;
  assign io_l1Hint_bits_sourceId = '0;
  assign io_l1Hint_bits_isKeyword = '0;
  assign io_prefetch_train_valid = '0;
  assign io_prefetch_train_bits_tag = '0;
  assign io_prefetch_train_bits_set = '0;
  assign io_prefetch_train_bits_needT = '0;
  assign io_prefetch_train_bits_source = '0;
  assign io_prefetch_train_bits_vaddr = '0;
  assign io_prefetch_train_bits_hit = '0;
  assign io_prefetch_train_bits_prefetched = '0;
  assign io_prefetch_train_bits_pfsource = '0;
  assign io_prefetch_train_bits_reqsource = '0;
  assign io_prefetch_req_ready = '0;
  assign io_prefetch_resp_valid = '0;
  assign io_prefetch_resp_bits_tag = '0;
  assign io_prefetch_resp_bits_set = '0;
  assign io_prefetch_resp_bits_vaddr = '0;
  assign io_prefetch_resp_bits_pfSource = '0;
  assign io_dirResult_valid = '0;
  assign io_dirResult_bits_hit = '0;
  assign io_dirResult_bits_meta_prefetch = '0;
  assign io_dirResult_bits_meta_prefetchSrc = '0;
  assign io_dirResult_bits_replacerInfo_channel = '0;
  assign io_dirResult_bits_replacerInfo_reqSource = '0;
  assign io_latePF = '0;
  assign io_error_valid = '0;
  assign io_error_bits_valid = '0;
  assign io_error_bits_address = '0;
  assign io_l2Miss = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_qos = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_returnNID = '0;
  assign io_out_tx_req_bits_stashNIDValid = '0;
  assign io_out_tx_req_bits_returnTxnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_ns = '0;
  assign io_out_tx_req_bits_likelyshared = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_tx_req_bits_snoopMe = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_req_bits_tagOp = '0;
  assign io_out_tx_req_bits_traceTag = '0;
  assign io_out_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_tx_req_bits_mpam_partID = '0;
  assign io_out_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_tx_req_bits_rsvdc = '0;
  assign io_out_tx_rsp_valid = '0;
  assign io_out_tx_rsp_bits_qos = '0;
  assign io_out_tx_rsp_bits_tgtID = '0;
  assign io_out_tx_rsp_bits_txnID = '0;
  assign io_out_tx_rsp_bits_opcode = '0;
  assign io_out_tx_rsp_bits_respErr = '0;
  assign io_out_tx_rsp_bits_resp = '0;
  assign io_out_tx_rsp_bits_fwdState = '0;
  assign io_out_tx_rsp_bits_cBusy = '0;
  assign io_out_tx_rsp_bits_dbID = '0;
  assign io_out_tx_rsp_bits_pCrdType = '0;
  assign io_out_tx_rsp_bits_tagOp = '0;
  assign io_out_tx_rsp_bits_traceTag = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_respErr = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_ccID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_traceTag = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_out_tx_dat_bits_poison = '0;
  assign io_out_rx_snp_ready = '0;
  assign io_pCrd_0_query_valid = '0;
  assign io_pCrd_0_query_bits_pCrdType = '0;
  assign io_pCrd_0_query_bits_srcID = '0;
  assign io_pCrd_1_query_valid = '0;
  assign io_pCrd_1_query_bits_pCrdType = '0;
  assign io_pCrd_1_query_bits_srcID = '0;
  assign io_pCrd_2_query_valid = '0;
  assign io_pCrd_2_query_bits_pCrdType = '0;
  assign io_pCrd_2_query_bits_srcID = '0;
  assign io_pCrd_3_query_valid = '0;
  assign io_pCrd_3_query_bits_pCrdType = '0;
  assign io_pCrd_3_query_bits_srcID = '0;
  assign io_pCrd_4_query_valid = '0;
  assign io_pCrd_4_query_bits_pCrdType = '0;
  assign io_pCrd_4_query_bits_srcID = '0;
  assign io_pCrd_5_query_valid = '0;
  assign io_pCrd_5_query_bits_pCrdType = '0;
  assign io_pCrd_5_query_bits_srcID = '0;
  assign io_pCrd_6_query_valid = '0;
  assign io_pCrd_6_query_bits_pCrdType = '0;
  assign io_pCrd_6_query_bits_srcID = '0;
  assign io_pCrd_7_query_valid = '0;
  assign io_pCrd_7_query_bits_pCrdType = '0;
  assign io_pCrd_7_query_bits_srcID = '0;
  assign io_pCrd_8_query_valid = '0;
  assign io_pCrd_8_query_bits_pCrdType = '0;
  assign io_pCrd_8_query_bits_srcID = '0;
  assign io_pCrd_9_query_valid = '0;
  assign io_pCrd_9_query_bits_pCrdType = '0;
  assign io_pCrd_9_query_bits_srcID = '0;
  assign io_pCrd_10_query_valid = '0;
  assign io_pCrd_10_query_bits_pCrdType = '0;
  assign io_pCrd_10_query_bits_srcID = '0;
  assign io_pCrd_11_query_valid = '0;
  assign io_pCrd_11_query_bits_pCrdType = '0;
  assign io_pCrd_11_query_bits_srcID = '0;
  assign io_pCrd_12_query_valid = '0;
  assign io_pCrd_12_query_bits_pCrdType = '0;
  assign io_pCrd_12_query_bits_srcID = '0;
  assign io_pCrd_13_query_valid = '0;
  assign io_pCrd_13_query_bits_pCrdType = '0;
  assign io_pCrd_13_query_bits_srcID = '0;
  assign io_pCrd_14_query_valid = '0;
  assign io_pCrd_14_query_bits_pCrdType = '0;
  assign io_pCrd_14_query_bits_srcID = '0;
  assign io_pCrd_15_query_valid = '0;
  assign io_pCrd_15_query_bits_pCrdType = '0;
  assign io_pCrd_15_query_bits_srcID = '0;
  assign io_msStatus_0_valid = '0;
  assign io_msStatus_0_bits_channel = '0;
  assign io_msStatus_0_bits_set = '0;
  assign io_msStatus_0_bits_reqTag = '0;
  assign io_msStatus_0_bits_is_miss = '0;
  assign io_msStatus_0_bits_is_prefetch = '0;
  assign io_msStatus_1_valid = '0;
  assign io_msStatus_1_bits_channel = '0;
  assign io_msStatus_1_bits_set = '0;
  assign io_msStatus_1_bits_reqTag = '0;
  assign io_msStatus_1_bits_is_miss = '0;
  assign io_msStatus_1_bits_is_prefetch = '0;
  assign io_msStatus_2_valid = '0;
  assign io_msStatus_2_bits_channel = '0;
  assign io_msStatus_2_bits_set = '0;
  assign io_msStatus_2_bits_reqTag = '0;
  assign io_msStatus_2_bits_is_miss = '0;
  assign io_msStatus_2_bits_is_prefetch = '0;
  assign io_msStatus_3_valid = '0;
  assign io_msStatus_3_bits_channel = '0;
  assign io_msStatus_3_bits_set = '0;
  assign io_msStatus_3_bits_reqTag = '0;
  assign io_msStatus_3_bits_is_miss = '0;
  assign io_msStatus_3_bits_is_prefetch = '0;
  assign io_msStatus_4_valid = '0;
  assign io_msStatus_4_bits_channel = '0;
  assign io_msStatus_4_bits_set = '0;
  assign io_msStatus_4_bits_reqTag = '0;
  assign io_msStatus_4_bits_is_miss = '0;
  assign io_msStatus_4_bits_is_prefetch = '0;
  assign io_msStatus_5_valid = '0;
  assign io_msStatus_5_bits_channel = '0;
  assign io_msStatus_5_bits_set = '0;
  assign io_msStatus_5_bits_reqTag = '0;
  assign io_msStatus_5_bits_is_miss = '0;
  assign io_msStatus_5_bits_is_prefetch = '0;
  assign io_msStatus_6_valid = '0;
  assign io_msStatus_6_bits_channel = '0;
  assign io_msStatus_6_bits_set = '0;
  assign io_msStatus_6_bits_reqTag = '0;
  assign io_msStatus_6_bits_is_miss = '0;
  assign io_msStatus_6_bits_is_prefetch = '0;
  assign io_msStatus_7_valid = '0;
  assign io_msStatus_7_bits_channel = '0;
  assign io_msStatus_7_bits_set = '0;
  assign io_msStatus_7_bits_reqTag = '0;
  assign io_msStatus_7_bits_is_miss = '0;
  assign io_msStatus_7_bits_is_prefetch = '0;
  assign io_msStatus_8_valid = '0;
  assign io_msStatus_8_bits_channel = '0;
  assign io_msStatus_8_bits_set = '0;
  assign io_msStatus_8_bits_reqTag = '0;
  assign io_msStatus_8_bits_is_miss = '0;
  assign io_msStatus_8_bits_is_prefetch = '0;
  assign io_msStatus_9_valid = '0;
  assign io_msStatus_9_bits_channel = '0;
  assign io_msStatus_9_bits_set = '0;
  assign io_msStatus_9_bits_reqTag = '0;
  assign io_msStatus_9_bits_is_miss = '0;
  assign io_msStatus_9_bits_is_prefetch = '0;
  assign io_msStatus_10_valid = '0;
  assign io_msStatus_10_bits_channel = '0;
  assign io_msStatus_10_bits_set = '0;
  assign io_msStatus_10_bits_reqTag = '0;
  assign io_msStatus_10_bits_is_miss = '0;
  assign io_msStatus_10_bits_is_prefetch = '0;
  assign io_msStatus_11_valid = '0;
  assign io_msStatus_11_bits_channel = '0;
  assign io_msStatus_11_bits_set = '0;
  assign io_msStatus_11_bits_reqTag = '0;
  assign io_msStatus_11_bits_is_miss = '0;
  assign io_msStatus_11_bits_is_prefetch = '0;
  assign io_msStatus_12_valid = '0;
  assign io_msStatus_12_bits_channel = '0;
  assign io_msStatus_12_bits_set = '0;
  assign io_msStatus_12_bits_reqTag = '0;
  assign io_msStatus_12_bits_is_miss = '0;
  assign io_msStatus_12_bits_is_prefetch = '0;
  assign io_msStatus_13_valid = '0;
  assign io_msStatus_13_bits_channel = '0;
  assign io_msStatus_13_bits_set = '0;
  assign io_msStatus_13_bits_reqTag = '0;
  assign io_msStatus_13_bits_is_miss = '0;
  assign io_msStatus_13_bits_is_prefetch = '0;
  assign io_msStatus_14_valid = '0;
  assign io_msStatus_14_bits_channel = '0;
  assign io_msStatus_14_bits_set = '0;
  assign io_msStatus_14_bits_reqTag = '0;
  assign io_msStatus_14_bits_is_miss = '0;
  assign io_msStatus_14_bits_is_prefetch = '0;
  assign io_msStatus_15_valid = '0;
  assign io_msStatus_15_bits_channel = '0;
  assign io_msStatus_15_bits_set = '0;
  assign io_msStatus_15_bits_reqTag = '0;
  assign io_msStatus_15_bits_is_miss = '0;
  assign io_msStatus_15_bits_is_prefetch = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;
  assign io_perf_8_value = '0;
  assign io_perf_9_value = '0;
  assign io_perf_10_value = '0;
  assign io_perf_11_value = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module Slice_1(
  input  clock,
  input  reset,
  output  io_in_a_ready,
  input  io_in_a_valid,
  input  [3:0] io_in_a_bits_opcode,
  input  [2:0] io_in_a_bits_param,
  input  [2:0] io_in_a_bits_size,
  input  [6:0] io_in_a_bits_source,
  input  [47:0] io_in_a_bits_address,
  input  [4:0] io_in_a_bits_user_reqSource,
  input  [1:0] io_in_a_bits_user_alias,
  input  [43:0] io_in_a_bits_user_vaddr,
  input  io_in_a_bits_user_needHint,
  input  io_in_a_bits_echo_isKeyword,
  input  io_in_a_bits_corrupt,
  input  io_in_b_ready,
  output  io_in_b_valid,
  output  [2:0] io_in_b_bits_opcode,
  output  [1:0] io_in_b_bits_param,
  output  [47:0] io_in_b_bits_address,
  output  [255:0] io_in_b_bits_data,
  output  io_in_c_ready,
  input  io_in_c_valid,
  input  [2:0] io_in_c_bits_opcode,
  input  [2:0] io_in_c_bits_param,
  input  [2:0] io_in_c_bits_size,
  input  [6:0] io_in_c_bits_source,
  input  [47:0] io_in_c_bits_address,
  input  [255:0] io_in_c_bits_data,
  input  io_in_c_bits_corrupt,
  input  io_in_d_ready,
  output  io_in_d_valid,
  output  [3:0] io_in_d_bits_opcode,
  output  [1:0] io_in_d_bits_param,
  output  [6:0] io_in_d_bits_source,
  output  [7:0] io_in_d_bits_sink,
  output  io_in_d_bits_denied,
  output  io_in_d_bits_echo_isKeyword,
  output  [255:0] io_in_d_bits_data,
  output  io_in_d_bits_corrupt,
  input  io_in_e_valid,
  input  [7:0] io_in_e_bits_sink,
  input  io_l1Hint_ready,
  output  io_l1Hint_valid,
  output  [31:0] io_l1Hint_bits_sourceId,
  output  io_l1Hint_bits_isKeyword,
  input  io_prefetch_train_ready,
  output  io_prefetch_train_valid,
  output  [32:0] io_prefetch_train_bits_tag,
  output  [8:0] io_prefetch_train_bits_set,
  output  io_prefetch_train_bits_needT,
  output  [6:0] io_prefetch_train_bits_source,
  output  [43:0] io_prefetch_train_bits_vaddr,
  output  io_prefetch_train_bits_hit,
  output  io_prefetch_train_bits_prefetched,
  output  [2:0] io_prefetch_train_bits_pfsource,
  output  [4:0] io_prefetch_train_bits_reqsource,
  output  io_prefetch_req_ready,
  input  io_prefetch_req_valid,
  input  [32:0] io_prefetch_req_bits_tag,
  input  [8:0] io_prefetch_req_bits_set,
  input  [43:0] io_prefetch_req_bits_vaddr,
  input  io_prefetch_req_bits_needT,
  input  [6:0] io_prefetch_req_bits_source,
  input  [4:0] io_prefetch_req_bits_pfSource,
  input  io_prefetch_resp_ready,
  output  io_prefetch_resp_valid,
  output  [32:0] io_prefetch_resp_bits_tag,
  output  [8:0] io_prefetch_resp_bits_set,
  output  [43:0] io_prefetch_resp_bits_vaddr,
  output  [4:0] io_prefetch_resp_bits_pfSource,
  output  io_dirResult_valid,
  output  io_dirResult_bits_hit,
  output  io_dirResult_bits_meta_prefetch,
  output  [2:0] io_dirResult_bits_meta_prefetchSrc,
  output  [2:0] io_dirResult_bits_replacerInfo_channel,
  output  [4:0] io_dirResult_bits_replacerInfo_reqSource,
  output  io_latePF,
  output  io_error_valid,
  output  io_error_bits_valid,
  output  [45:0] io_error_bits_address,
  output  io_l2Miss,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [3:0] io_out_tx_req_bits_qos,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [10:0] io_out_tx_req_bits_returnNID,
  output  io_out_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_tx_req_bits_returnTxnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_ns,
  output  io_out_tx_req_bits_likelyshared,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  [7:0] io_out_tx_req_bits_lpIDWithPadding,
  output  io_out_tx_req_bits_snoopMe,
  output  io_out_tx_req_bits_expCompAck,
  output  [1:0] io_out_tx_req_bits_tagOp,
  output  io_out_tx_req_bits_traceTag,
  output  io_out_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_tx_req_bits_mpam_partID,
  output  io_out_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_tx_req_bits_rsvdc,
  input  io_out_tx_rsp_ready,
  output  io_out_tx_rsp_valid,
  output  [3:0] io_out_tx_rsp_bits_qos,
  output  [10:0] io_out_tx_rsp_bits_tgtID,
  output  [11:0] io_out_tx_rsp_bits_txnID,
  output  [4:0] io_out_tx_rsp_bits_opcode,
  output  [1:0] io_out_tx_rsp_bits_respErr,
  output  [2:0] io_out_tx_rsp_bits_resp,
  output  [2:0] io_out_tx_rsp_bits_fwdState,
  output  [2:0] io_out_tx_rsp_bits_cBusy,
  output  [11:0] io_out_tx_rsp_bits_dbID,
  output  [3:0] io_out_tx_rsp_bits_pCrdType,
  output  [1:0] io_out_tx_rsp_bits_tagOp,
  output  io_out_tx_rsp_bits_traceTag,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [1:0] io_out_tx_dat_bits_respErr,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_ccID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  io_out_tx_dat_bits_traceTag,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  output  [3:0] io_out_tx_dat_bits_poison,
  input  io_out_rx_rsp_valid,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [1:0] io_out_rx_rsp_bits_respErr,
  input  [2:0] io_out_rx_rsp_bits_resp,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  input  [3:0] io_out_rx_rsp_bits_pCrdType,
  input  io_out_rx_rsp_bits_traceTag,
  input  io_out_rx_dat_valid,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [10:0] io_out_rx_dat_bits_homeNID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [1:0] io_out_rx_dat_bits_respErr,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [11:0] io_out_rx_dat_bits_dbID,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  io_out_rx_dat_bits_traceTag,
  input  [255:0] io_out_rx_dat_bits_data,
  input  [31:0] io_out_rx_dat_bits_dataCheck,
  input  [3:0] io_out_rx_dat_bits_poison,
  output  io_out_rx_snp_ready,
  input  io_out_rx_snp_valid,
  input  [3:0] io_out_rx_snp_bits_qos,
  input  [10:0] io_out_rx_snp_bits_srcID,
  input  [11:0] io_out_rx_snp_bits_txnID,
  input  [10:0] io_out_rx_snp_bits_fwdNID,
  input  [11:0] io_out_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_rx_snp_bits_opcode,
  input  [44:0] io_out_rx_snp_bits_addr,
  input  io_out_rx_snp_bits_ns,
  input  io_out_rx_snp_bits_doNotGoToSD,
  input  io_out_rx_snp_bits_retToSrc,
  input  io_out_rx_snp_bits_traceTag,
  input  io_out_rx_snp_bits_mpam_perfMonGroup,
  input  [8:0] io_out_rx_snp_bits_mpam_partID,
  input  io_out_rx_snp_bits_mpam_mpamNS,
  output  io_pCrd_0_query_valid,
  output  [3:0] io_pCrd_0_query_bits_pCrdType,
  output  [10:0] io_pCrd_0_query_bits_srcID,
  input  io_pCrd_0_grant,
  output  io_pCrd_1_query_valid,
  output  [3:0] io_pCrd_1_query_bits_pCrdType,
  output  [10:0] io_pCrd_1_query_bits_srcID,
  input  io_pCrd_1_grant,
  output  io_pCrd_2_query_valid,
  output  [3:0] io_pCrd_2_query_bits_pCrdType,
  output  [10:0] io_pCrd_2_query_bits_srcID,
  input  io_pCrd_2_grant,
  output  io_pCrd_3_query_valid,
  output  [3:0] io_pCrd_3_query_bits_pCrdType,
  output  [10:0] io_pCrd_3_query_bits_srcID,
  input  io_pCrd_3_grant,
  output  io_pCrd_4_query_valid,
  output  [3:0] io_pCrd_4_query_bits_pCrdType,
  output  [10:0] io_pCrd_4_query_bits_srcID,
  input  io_pCrd_4_grant,
  output  io_pCrd_5_query_valid,
  output  [3:0] io_pCrd_5_query_bits_pCrdType,
  output  [10:0] io_pCrd_5_query_bits_srcID,
  input  io_pCrd_5_grant,
  output  io_pCrd_6_query_valid,
  output  [3:0] io_pCrd_6_query_bits_pCrdType,
  output  [10:0] io_pCrd_6_query_bits_srcID,
  input  io_pCrd_6_grant,
  output  io_pCrd_7_query_valid,
  output  [3:0] io_pCrd_7_query_bits_pCrdType,
  output  [10:0] io_pCrd_7_query_bits_srcID,
  input  io_pCrd_7_grant,
  output  io_pCrd_8_query_valid,
  output  [3:0] io_pCrd_8_query_bits_pCrdType,
  output  [10:0] io_pCrd_8_query_bits_srcID,
  input  io_pCrd_8_grant,
  output  io_pCrd_9_query_valid,
  output  [3:0] io_pCrd_9_query_bits_pCrdType,
  output  [10:0] io_pCrd_9_query_bits_srcID,
  input  io_pCrd_9_grant,
  output  io_pCrd_10_query_valid,
  output  [3:0] io_pCrd_10_query_bits_pCrdType,
  output  [10:0] io_pCrd_10_query_bits_srcID,
  input  io_pCrd_10_grant,
  output  io_pCrd_11_query_valid,
  output  [3:0] io_pCrd_11_query_bits_pCrdType,
  output  [10:0] io_pCrd_11_query_bits_srcID,
  input  io_pCrd_11_grant,
  output  io_pCrd_12_query_valid,
  output  [3:0] io_pCrd_12_query_bits_pCrdType,
  output  [10:0] io_pCrd_12_query_bits_srcID,
  input  io_pCrd_12_grant,
  output  io_pCrd_13_query_valid,
  output  [3:0] io_pCrd_13_query_bits_pCrdType,
  output  [10:0] io_pCrd_13_query_bits_srcID,
  input  io_pCrd_13_grant,
  output  io_pCrd_14_query_valid,
  output  [3:0] io_pCrd_14_query_bits_pCrdType,
  output  [10:0] io_pCrd_14_query_bits_srcID,
  input  io_pCrd_14_grant,
  output  io_pCrd_15_query_valid,
  output  [3:0] io_pCrd_15_query_bits_pCrdType,
  output  [10:0] io_pCrd_15_query_bits_srcID,
  input  io_pCrd_15_grant,
  output  io_msStatus_0_valid,
  output  [2:0] io_msStatus_0_bits_channel,
  output  [8:0] io_msStatus_0_bits_set,
  output  [30:0] io_msStatus_0_bits_reqTag,
  output  io_msStatus_0_bits_is_miss,
  output  io_msStatus_0_bits_is_prefetch,
  output  io_msStatus_1_valid,
  output  [2:0] io_msStatus_1_bits_channel,
  output  [8:0] io_msStatus_1_bits_set,
  output  [30:0] io_msStatus_1_bits_reqTag,
  output  io_msStatus_1_bits_is_miss,
  output  io_msStatus_1_bits_is_prefetch,
  output  io_msStatus_2_valid,
  output  [2:0] io_msStatus_2_bits_channel,
  output  [8:0] io_msStatus_2_bits_set,
  output  [30:0] io_msStatus_2_bits_reqTag,
  output  io_msStatus_2_bits_is_miss,
  output  io_msStatus_2_bits_is_prefetch,
  output  io_msStatus_3_valid,
  output  [2:0] io_msStatus_3_bits_channel,
  output  [8:0] io_msStatus_3_bits_set,
  output  [30:0] io_msStatus_3_bits_reqTag,
  output  io_msStatus_3_bits_is_miss,
  output  io_msStatus_3_bits_is_prefetch,
  output  io_msStatus_4_valid,
  output  [2:0] io_msStatus_4_bits_channel,
  output  [8:0] io_msStatus_4_bits_set,
  output  [30:0] io_msStatus_4_bits_reqTag,
  output  io_msStatus_4_bits_is_miss,
  output  io_msStatus_4_bits_is_prefetch,
  output  io_msStatus_5_valid,
  output  [2:0] io_msStatus_5_bits_channel,
  output  [8:0] io_msStatus_5_bits_set,
  output  [30:0] io_msStatus_5_bits_reqTag,
  output  io_msStatus_5_bits_is_miss,
  output  io_msStatus_5_bits_is_prefetch,
  output  io_msStatus_6_valid,
  output  [2:0] io_msStatus_6_bits_channel,
  output  [8:0] io_msStatus_6_bits_set,
  output  [30:0] io_msStatus_6_bits_reqTag,
  output  io_msStatus_6_bits_is_miss,
  output  io_msStatus_6_bits_is_prefetch,
  output  io_msStatus_7_valid,
  output  [2:0] io_msStatus_7_bits_channel,
  output  [8:0] io_msStatus_7_bits_set,
  output  [30:0] io_msStatus_7_bits_reqTag,
  output  io_msStatus_7_bits_is_miss,
  output  io_msStatus_7_bits_is_prefetch,
  output  io_msStatus_8_valid,
  output  [2:0] io_msStatus_8_bits_channel,
  output  [8:0] io_msStatus_8_bits_set,
  output  [30:0] io_msStatus_8_bits_reqTag,
  output  io_msStatus_8_bits_is_miss,
  output  io_msStatus_8_bits_is_prefetch,
  output  io_msStatus_9_valid,
  output  [2:0] io_msStatus_9_bits_channel,
  output  [8:0] io_msStatus_9_bits_set,
  output  [30:0] io_msStatus_9_bits_reqTag,
  output  io_msStatus_9_bits_is_miss,
  output  io_msStatus_9_bits_is_prefetch,
  output  io_msStatus_10_valid,
  output  [2:0] io_msStatus_10_bits_channel,
  output  [8:0] io_msStatus_10_bits_set,
  output  [30:0] io_msStatus_10_bits_reqTag,
  output  io_msStatus_10_bits_is_miss,
  output  io_msStatus_10_bits_is_prefetch,
  output  io_msStatus_11_valid,
  output  [2:0] io_msStatus_11_bits_channel,
  output  [8:0] io_msStatus_11_bits_set,
  output  [30:0] io_msStatus_11_bits_reqTag,
  output  io_msStatus_11_bits_is_miss,
  output  io_msStatus_11_bits_is_prefetch,
  output  io_msStatus_12_valid,
  output  [2:0] io_msStatus_12_bits_channel,
  output  [8:0] io_msStatus_12_bits_set,
  output  [30:0] io_msStatus_12_bits_reqTag,
  output  io_msStatus_12_bits_is_miss,
  output  io_msStatus_12_bits_is_prefetch,
  output  io_msStatus_13_valid,
  output  [2:0] io_msStatus_13_bits_channel,
  output  [8:0] io_msStatus_13_bits_set,
  output  [30:0] io_msStatus_13_bits_reqTag,
  output  io_msStatus_13_bits_is_miss,
  output  io_msStatus_13_bits_is_prefetch,
  output  io_msStatus_14_valid,
  output  [2:0] io_msStatus_14_bits_channel,
  output  [8:0] io_msStatus_14_bits_set,
  output  [30:0] io_msStatus_14_bits_reqTag,
  output  io_msStatus_14_bits_is_miss,
  output  io_msStatus_14_bits_is_prefetch,
  output  io_msStatus_15_valid,
  output  [2:0] io_msStatus_15_bits_channel,
  output  [8:0] io_msStatus_15_bits_set,
  output  [30:0] io_msStatus_15_bits_reqTag,
  output  io_msStatus_15_bits_is_miss,
  output  io_msStatus_15_bits_is_prefetch,
  output  [5:0] io_perf_0_value,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_3_value,
  output  [5:0] io_perf_4_value,
  output  [5:0] io_perf_5_value,
  output  [5:0] io_perf_6_value,
  output  [5:0] io_perf_7_value,
  output  [5:0] io_perf_8_value,
  output  [5:0] io_perf_9_value,
  output  [5:0] io_perf_10_value,
  output  [5:0] io_perf_11_value,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  [4:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [7:0] boreChildrenBd_bore_be,
  input  [12:0] boreChildrenBd_bore_addr,
  input  [103:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [12:0] boreChildrenBd_bore_addr_rd,
  output  [103:0] boreChildrenBd_bore_outdata
);
  assign io_in_a_ready = '0;
  assign io_in_b_valid = '0;
  assign io_in_b_bits_opcode = '0;
  assign io_in_b_bits_param = '0;
  assign io_in_b_bits_address = '0;
  assign io_in_b_bits_data = '0;
  assign io_in_c_ready = '0;
  assign io_in_d_valid = '0;
  assign io_in_d_bits_opcode = '0;
  assign io_in_d_bits_param = '0;
  assign io_in_d_bits_source = '0;
  assign io_in_d_bits_sink = '0;
  assign io_in_d_bits_denied = '0;
  assign io_in_d_bits_echo_isKeyword = '0;
  assign io_in_d_bits_data = '0;
  assign io_in_d_bits_corrupt = '0;
  assign io_l1Hint_valid = '0;
  assign io_l1Hint_bits_sourceId = '0;
  assign io_l1Hint_bits_isKeyword = '0;
  assign io_prefetch_train_valid = '0;
  assign io_prefetch_train_bits_tag = '0;
  assign io_prefetch_train_bits_set = '0;
  assign io_prefetch_train_bits_needT = '0;
  assign io_prefetch_train_bits_source = '0;
  assign io_prefetch_train_bits_vaddr = '0;
  assign io_prefetch_train_bits_hit = '0;
  assign io_prefetch_train_bits_prefetched = '0;
  assign io_prefetch_train_bits_pfsource = '0;
  assign io_prefetch_train_bits_reqsource = '0;
  assign io_prefetch_req_ready = '0;
  assign io_prefetch_resp_valid = '0;
  assign io_prefetch_resp_bits_tag = '0;
  assign io_prefetch_resp_bits_set = '0;
  assign io_prefetch_resp_bits_vaddr = '0;
  assign io_prefetch_resp_bits_pfSource = '0;
  assign io_dirResult_valid = '0;
  assign io_dirResult_bits_hit = '0;
  assign io_dirResult_bits_meta_prefetch = '0;
  assign io_dirResult_bits_meta_prefetchSrc = '0;
  assign io_dirResult_bits_replacerInfo_channel = '0;
  assign io_dirResult_bits_replacerInfo_reqSource = '0;
  assign io_latePF = '0;
  assign io_error_valid = '0;
  assign io_error_bits_valid = '0;
  assign io_error_bits_address = '0;
  assign io_l2Miss = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_qos = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_returnNID = '0;
  assign io_out_tx_req_bits_stashNIDValid = '0;
  assign io_out_tx_req_bits_returnTxnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_ns = '0;
  assign io_out_tx_req_bits_likelyshared = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_tx_req_bits_snoopMe = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_req_bits_tagOp = '0;
  assign io_out_tx_req_bits_traceTag = '0;
  assign io_out_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_tx_req_bits_mpam_partID = '0;
  assign io_out_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_tx_req_bits_rsvdc = '0;
  assign io_out_tx_rsp_valid = '0;
  assign io_out_tx_rsp_bits_qos = '0;
  assign io_out_tx_rsp_bits_tgtID = '0;
  assign io_out_tx_rsp_bits_txnID = '0;
  assign io_out_tx_rsp_bits_opcode = '0;
  assign io_out_tx_rsp_bits_respErr = '0;
  assign io_out_tx_rsp_bits_resp = '0;
  assign io_out_tx_rsp_bits_fwdState = '0;
  assign io_out_tx_rsp_bits_cBusy = '0;
  assign io_out_tx_rsp_bits_dbID = '0;
  assign io_out_tx_rsp_bits_pCrdType = '0;
  assign io_out_tx_rsp_bits_tagOp = '0;
  assign io_out_tx_rsp_bits_traceTag = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_respErr = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_ccID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_traceTag = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_out_tx_dat_bits_poison = '0;
  assign io_out_rx_snp_ready = '0;
  assign io_pCrd_0_query_valid = '0;
  assign io_pCrd_0_query_bits_pCrdType = '0;
  assign io_pCrd_0_query_bits_srcID = '0;
  assign io_pCrd_1_query_valid = '0;
  assign io_pCrd_1_query_bits_pCrdType = '0;
  assign io_pCrd_1_query_bits_srcID = '0;
  assign io_pCrd_2_query_valid = '0;
  assign io_pCrd_2_query_bits_pCrdType = '0;
  assign io_pCrd_2_query_bits_srcID = '0;
  assign io_pCrd_3_query_valid = '0;
  assign io_pCrd_3_query_bits_pCrdType = '0;
  assign io_pCrd_3_query_bits_srcID = '0;
  assign io_pCrd_4_query_valid = '0;
  assign io_pCrd_4_query_bits_pCrdType = '0;
  assign io_pCrd_4_query_bits_srcID = '0;
  assign io_pCrd_5_query_valid = '0;
  assign io_pCrd_5_query_bits_pCrdType = '0;
  assign io_pCrd_5_query_bits_srcID = '0;
  assign io_pCrd_6_query_valid = '0;
  assign io_pCrd_6_query_bits_pCrdType = '0;
  assign io_pCrd_6_query_bits_srcID = '0;
  assign io_pCrd_7_query_valid = '0;
  assign io_pCrd_7_query_bits_pCrdType = '0;
  assign io_pCrd_7_query_bits_srcID = '0;
  assign io_pCrd_8_query_valid = '0;
  assign io_pCrd_8_query_bits_pCrdType = '0;
  assign io_pCrd_8_query_bits_srcID = '0;
  assign io_pCrd_9_query_valid = '0;
  assign io_pCrd_9_query_bits_pCrdType = '0;
  assign io_pCrd_9_query_bits_srcID = '0;
  assign io_pCrd_10_query_valid = '0;
  assign io_pCrd_10_query_bits_pCrdType = '0;
  assign io_pCrd_10_query_bits_srcID = '0;
  assign io_pCrd_11_query_valid = '0;
  assign io_pCrd_11_query_bits_pCrdType = '0;
  assign io_pCrd_11_query_bits_srcID = '0;
  assign io_pCrd_12_query_valid = '0;
  assign io_pCrd_12_query_bits_pCrdType = '0;
  assign io_pCrd_12_query_bits_srcID = '0;
  assign io_pCrd_13_query_valid = '0;
  assign io_pCrd_13_query_bits_pCrdType = '0;
  assign io_pCrd_13_query_bits_srcID = '0;
  assign io_pCrd_14_query_valid = '0;
  assign io_pCrd_14_query_bits_pCrdType = '0;
  assign io_pCrd_14_query_bits_srcID = '0;
  assign io_pCrd_15_query_valid = '0;
  assign io_pCrd_15_query_bits_pCrdType = '0;
  assign io_pCrd_15_query_bits_srcID = '0;
  assign io_msStatus_0_valid = '0;
  assign io_msStatus_0_bits_channel = '0;
  assign io_msStatus_0_bits_set = '0;
  assign io_msStatus_0_bits_reqTag = '0;
  assign io_msStatus_0_bits_is_miss = '0;
  assign io_msStatus_0_bits_is_prefetch = '0;
  assign io_msStatus_1_valid = '0;
  assign io_msStatus_1_bits_channel = '0;
  assign io_msStatus_1_bits_set = '0;
  assign io_msStatus_1_bits_reqTag = '0;
  assign io_msStatus_1_bits_is_miss = '0;
  assign io_msStatus_1_bits_is_prefetch = '0;
  assign io_msStatus_2_valid = '0;
  assign io_msStatus_2_bits_channel = '0;
  assign io_msStatus_2_bits_set = '0;
  assign io_msStatus_2_bits_reqTag = '0;
  assign io_msStatus_2_bits_is_miss = '0;
  assign io_msStatus_2_bits_is_prefetch = '0;
  assign io_msStatus_3_valid = '0;
  assign io_msStatus_3_bits_channel = '0;
  assign io_msStatus_3_bits_set = '0;
  assign io_msStatus_3_bits_reqTag = '0;
  assign io_msStatus_3_bits_is_miss = '0;
  assign io_msStatus_3_bits_is_prefetch = '0;
  assign io_msStatus_4_valid = '0;
  assign io_msStatus_4_bits_channel = '0;
  assign io_msStatus_4_bits_set = '0;
  assign io_msStatus_4_bits_reqTag = '0;
  assign io_msStatus_4_bits_is_miss = '0;
  assign io_msStatus_4_bits_is_prefetch = '0;
  assign io_msStatus_5_valid = '0;
  assign io_msStatus_5_bits_channel = '0;
  assign io_msStatus_5_bits_set = '0;
  assign io_msStatus_5_bits_reqTag = '0;
  assign io_msStatus_5_bits_is_miss = '0;
  assign io_msStatus_5_bits_is_prefetch = '0;
  assign io_msStatus_6_valid = '0;
  assign io_msStatus_6_bits_channel = '0;
  assign io_msStatus_6_bits_set = '0;
  assign io_msStatus_6_bits_reqTag = '0;
  assign io_msStatus_6_bits_is_miss = '0;
  assign io_msStatus_6_bits_is_prefetch = '0;
  assign io_msStatus_7_valid = '0;
  assign io_msStatus_7_bits_channel = '0;
  assign io_msStatus_7_bits_set = '0;
  assign io_msStatus_7_bits_reqTag = '0;
  assign io_msStatus_7_bits_is_miss = '0;
  assign io_msStatus_7_bits_is_prefetch = '0;
  assign io_msStatus_8_valid = '0;
  assign io_msStatus_8_bits_channel = '0;
  assign io_msStatus_8_bits_set = '0;
  assign io_msStatus_8_bits_reqTag = '0;
  assign io_msStatus_8_bits_is_miss = '0;
  assign io_msStatus_8_bits_is_prefetch = '0;
  assign io_msStatus_9_valid = '0;
  assign io_msStatus_9_bits_channel = '0;
  assign io_msStatus_9_bits_set = '0;
  assign io_msStatus_9_bits_reqTag = '0;
  assign io_msStatus_9_bits_is_miss = '0;
  assign io_msStatus_9_bits_is_prefetch = '0;
  assign io_msStatus_10_valid = '0;
  assign io_msStatus_10_bits_channel = '0;
  assign io_msStatus_10_bits_set = '0;
  assign io_msStatus_10_bits_reqTag = '0;
  assign io_msStatus_10_bits_is_miss = '0;
  assign io_msStatus_10_bits_is_prefetch = '0;
  assign io_msStatus_11_valid = '0;
  assign io_msStatus_11_bits_channel = '0;
  assign io_msStatus_11_bits_set = '0;
  assign io_msStatus_11_bits_reqTag = '0;
  assign io_msStatus_11_bits_is_miss = '0;
  assign io_msStatus_11_bits_is_prefetch = '0;
  assign io_msStatus_12_valid = '0;
  assign io_msStatus_12_bits_channel = '0;
  assign io_msStatus_12_bits_set = '0;
  assign io_msStatus_12_bits_reqTag = '0;
  assign io_msStatus_12_bits_is_miss = '0;
  assign io_msStatus_12_bits_is_prefetch = '0;
  assign io_msStatus_13_valid = '0;
  assign io_msStatus_13_bits_channel = '0;
  assign io_msStatus_13_bits_set = '0;
  assign io_msStatus_13_bits_reqTag = '0;
  assign io_msStatus_13_bits_is_miss = '0;
  assign io_msStatus_13_bits_is_prefetch = '0;
  assign io_msStatus_14_valid = '0;
  assign io_msStatus_14_bits_channel = '0;
  assign io_msStatus_14_bits_set = '0;
  assign io_msStatus_14_bits_reqTag = '0;
  assign io_msStatus_14_bits_is_miss = '0;
  assign io_msStatus_14_bits_is_prefetch = '0;
  assign io_msStatus_15_valid = '0;
  assign io_msStatus_15_bits_channel = '0;
  assign io_msStatus_15_bits_set = '0;
  assign io_msStatus_15_bits_reqTag = '0;
  assign io_msStatus_15_bits_is_miss = '0;
  assign io_msStatus_15_bits_is_prefetch = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;
  assign io_perf_8_value = '0;
  assign io_perf_9_value = '0;
  assign io_perf_10_value = '0;
  assign io_perf_11_value = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module Slice_2(
  input  clock,
  input  reset,
  output  io_in_a_ready,
  input  io_in_a_valid,
  input  [3:0] io_in_a_bits_opcode,
  input  [2:0] io_in_a_bits_param,
  input  [2:0] io_in_a_bits_size,
  input  [6:0] io_in_a_bits_source,
  input  [47:0] io_in_a_bits_address,
  input  [4:0] io_in_a_bits_user_reqSource,
  input  [1:0] io_in_a_bits_user_alias,
  input  [43:0] io_in_a_bits_user_vaddr,
  input  io_in_a_bits_user_needHint,
  input  io_in_a_bits_echo_isKeyword,
  input  io_in_a_bits_corrupt,
  input  io_in_b_ready,
  output  io_in_b_valid,
  output  [2:0] io_in_b_bits_opcode,
  output  [1:0] io_in_b_bits_param,
  output  [47:0] io_in_b_bits_address,
  output  [255:0] io_in_b_bits_data,
  output  io_in_c_ready,
  input  io_in_c_valid,
  input  [2:0] io_in_c_bits_opcode,
  input  [2:0] io_in_c_bits_param,
  input  [2:0] io_in_c_bits_size,
  input  [6:0] io_in_c_bits_source,
  input  [47:0] io_in_c_bits_address,
  input  [255:0] io_in_c_bits_data,
  input  io_in_c_bits_corrupt,
  input  io_in_d_ready,
  output  io_in_d_valid,
  output  [3:0] io_in_d_bits_opcode,
  output  [1:0] io_in_d_bits_param,
  output  [6:0] io_in_d_bits_source,
  output  [7:0] io_in_d_bits_sink,
  output  io_in_d_bits_denied,
  output  io_in_d_bits_echo_isKeyword,
  output  [255:0] io_in_d_bits_data,
  output  io_in_d_bits_corrupt,
  input  io_in_e_valid,
  input  [7:0] io_in_e_bits_sink,
  input  io_l1Hint_ready,
  output  io_l1Hint_valid,
  output  [31:0] io_l1Hint_bits_sourceId,
  output  io_l1Hint_bits_isKeyword,
  input  io_prefetch_train_ready,
  output  io_prefetch_train_valid,
  output  [32:0] io_prefetch_train_bits_tag,
  output  [8:0] io_prefetch_train_bits_set,
  output  io_prefetch_train_bits_needT,
  output  [6:0] io_prefetch_train_bits_source,
  output  [43:0] io_prefetch_train_bits_vaddr,
  output  io_prefetch_train_bits_hit,
  output  io_prefetch_train_bits_prefetched,
  output  [2:0] io_prefetch_train_bits_pfsource,
  output  [4:0] io_prefetch_train_bits_reqsource,
  output  io_prefetch_req_ready,
  input  io_prefetch_req_valid,
  input  [32:0] io_prefetch_req_bits_tag,
  input  [8:0] io_prefetch_req_bits_set,
  input  [43:0] io_prefetch_req_bits_vaddr,
  input  io_prefetch_req_bits_needT,
  input  [6:0] io_prefetch_req_bits_source,
  input  [4:0] io_prefetch_req_bits_pfSource,
  input  io_prefetch_resp_ready,
  output  io_prefetch_resp_valid,
  output  [32:0] io_prefetch_resp_bits_tag,
  output  [8:0] io_prefetch_resp_bits_set,
  output  [43:0] io_prefetch_resp_bits_vaddr,
  output  [4:0] io_prefetch_resp_bits_pfSource,
  output  io_dirResult_valid,
  output  io_dirResult_bits_hit,
  output  io_dirResult_bits_meta_prefetch,
  output  [2:0] io_dirResult_bits_meta_prefetchSrc,
  output  [2:0] io_dirResult_bits_replacerInfo_channel,
  output  [4:0] io_dirResult_bits_replacerInfo_reqSource,
  output  io_latePF,
  output  io_error_valid,
  output  io_error_bits_valid,
  output  [45:0] io_error_bits_address,
  output  io_l2Miss,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [3:0] io_out_tx_req_bits_qos,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [10:0] io_out_tx_req_bits_returnNID,
  output  io_out_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_tx_req_bits_returnTxnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_ns,
  output  io_out_tx_req_bits_likelyshared,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  [7:0] io_out_tx_req_bits_lpIDWithPadding,
  output  io_out_tx_req_bits_snoopMe,
  output  io_out_tx_req_bits_expCompAck,
  output  [1:0] io_out_tx_req_bits_tagOp,
  output  io_out_tx_req_bits_traceTag,
  output  io_out_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_tx_req_bits_mpam_partID,
  output  io_out_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_tx_req_bits_rsvdc,
  input  io_out_tx_rsp_ready,
  output  io_out_tx_rsp_valid,
  output  [3:0] io_out_tx_rsp_bits_qos,
  output  [10:0] io_out_tx_rsp_bits_tgtID,
  output  [11:0] io_out_tx_rsp_bits_txnID,
  output  [4:0] io_out_tx_rsp_bits_opcode,
  output  [1:0] io_out_tx_rsp_bits_respErr,
  output  [2:0] io_out_tx_rsp_bits_resp,
  output  [2:0] io_out_tx_rsp_bits_fwdState,
  output  [2:0] io_out_tx_rsp_bits_cBusy,
  output  [11:0] io_out_tx_rsp_bits_dbID,
  output  [3:0] io_out_tx_rsp_bits_pCrdType,
  output  [1:0] io_out_tx_rsp_bits_tagOp,
  output  io_out_tx_rsp_bits_traceTag,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [1:0] io_out_tx_dat_bits_respErr,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_ccID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  io_out_tx_dat_bits_traceTag,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  output  [3:0] io_out_tx_dat_bits_poison,
  input  io_out_rx_rsp_valid,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [1:0] io_out_rx_rsp_bits_respErr,
  input  [2:0] io_out_rx_rsp_bits_resp,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  input  [3:0] io_out_rx_rsp_bits_pCrdType,
  input  io_out_rx_rsp_bits_traceTag,
  input  io_out_rx_dat_valid,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [10:0] io_out_rx_dat_bits_homeNID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [1:0] io_out_rx_dat_bits_respErr,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [11:0] io_out_rx_dat_bits_dbID,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  io_out_rx_dat_bits_traceTag,
  input  [255:0] io_out_rx_dat_bits_data,
  input  [31:0] io_out_rx_dat_bits_dataCheck,
  input  [3:0] io_out_rx_dat_bits_poison,
  output  io_out_rx_snp_ready,
  input  io_out_rx_snp_valid,
  input  [3:0] io_out_rx_snp_bits_qos,
  input  [10:0] io_out_rx_snp_bits_srcID,
  input  [11:0] io_out_rx_snp_bits_txnID,
  input  [10:0] io_out_rx_snp_bits_fwdNID,
  input  [11:0] io_out_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_rx_snp_bits_opcode,
  input  [44:0] io_out_rx_snp_bits_addr,
  input  io_out_rx_snp_bits_ns,
  input  io_out_rx_snp_bits_doNotGoToSD,
  input  io_out_rx_snp_bits_retToSrc,
  input  io_out_rx_snp_bits_traceTag,
  input  io_out_rx_snp_bits_mpam_perfMonGroup,
  input  [8:0] io_out_rx_snp_bits_mpam_partID,
  input  io_out_rx_snp_bits_mpam_mpamNS,
  output  io_pCrd_0_query_valid,
  output  [3:0] io_pCrd_0_query_bits_pCrdType,
  output  [10:0] io_pCrd_0_query_bits_srcID,
  input  io_pCrd_0_grant,
  output  io_pCrd_1_query_valid,
  output  [3:0] io_pCrd_1_query_bits_pCrdType,
  output  [10:0] io_pCrd_1_query_bits_srcID,
  input  io_pCrd_1_grant,
  output  io_pCrd_2_query_valid,
  output  [3:0] io_pCrd_2_query_bits_pCrdType,
  output  [10:0] io_pCrd_2_query_bits_srcID,
  input  io_pCrd_2_grant,
  output  io_pCrd_3_query_valid,
  output  [3:0] io_pCrd_3_query_bits_pCrdType,
  output  [10:0] io_pCrd_3_query_bits_srcID,
  input  io_pCrd_3_grant,
  output  io_pCrd_4_query_valid,
  output  [3:0] io_pCrd_4_query_bits_pCrdType,
  output  [10:0] io_pCrd_4_query_bits_srcID,
  input  io_pCrd_4_grant,
  output  io_pCrd_5_query_valid,
  output  [3:0] io_pCrd_5_query_bits_pCrdType,
  output  [10:0] io_pCrd_5_query_bits_srcID,
  input  io_pCrd_5_grant,
  output  io_pCrd_6_query_valid,
  output  [3:0] io_pCrd_6_query_bits_pCrdType,
  output  [10:0] io_pCrd_6_query_bits_srcID,
  input  io_pCrd_6_grant,
  output  io_pCrd_7_query_valid,
  output  [3:0] io_pCrd_7_query_bits_pCrdType,
  output  [10:0] io_pCrd_7_query_bits_srcID,
  input  io_pCrd_7_grant,
  output  io_pCrd_8_query_valid,
  output  [3:0] io_pCrd_8_query_bits_pCrdType,
  output  [10:0] io_pCrd_8_query_bits_srcID,
  input  io_pCrd_8_grant,
  output  io_pCrd_9_query_valid,
  output  [3:0] io_pCrd_9_query_bits_pCrdType,
  output  [10:0] io_pCrd_9_query_bits_srcID,
  input  io_pCrd_9_grant,
  output  io_pCrd_10_query_valid,
  output  [3:0] io_pCrd_10_query_bits_pCrdType,
  output  [10:0] io_pCrd_10_query_bits_srcID,
  input  io_pCrd_10_grant,
  output  io_pCrd_11_query_valid,
  output  [3:0] io_pCrd_11_query_bits_pCrdType,
  output  [10:0] io_pCrd_11_query_bits_srcID,
  input  io_pCrd_11_grant,
  output  io_pCrd_12_query_valid,
  output  [3:0] io_pCrd_12_query_bits_pCrdType,
  output  [10:0] io_pCrd_12_query_bits_srcID,
  input  io_pCrd_12_grant,
  output  io_pCrd_13_query_valid,
  output  [3:0] io_pCrd_13_query_bits_pCrdType,
  output  [10:0] io_pCrd_13_query_bits_srcID,
  input  io_pCrd_13_grant,
  output  io_pCrd_14_query_valid,
  output  [3:0] io_pCrd_14_query_bits_pCrdType,
  output  [10:0] io_pCrd_14_query_bits_srcID,
  input  io_pCrd_14_grant,
  output  io_pCrd_15_query_valid,
  output  [3:0] io_pCrd_15_query_bits_pCrdType,
  output  [10:0] io_pCrd_15_query_bits_srcID,
  input  io_pCrd_15_grant,
  output  io_msStatus_0_valid,
  output  [2:0] io_msStatus_0_bits_channel,
  output  [8:0] io_msStatus_0_bits_set,
  output  [30:0] io_msStatus_0_bits_reqTag,
  output  io_msStatus_0_bits_is_miss,
  output  io_msStatus_0_bits_is_prefetch,
  output  io_msStatus_1_valid,
  output  [2:0] io_msStatus_1_bits_channel,
  output  [8:0] io_msStatus_1_bits_set,
  output  [30:0] io_msStatus_1_bits_reqTag,
  output  io_msStatus_1_bits_is_miss,
  output  io_msStatus_1_bits_is_prefetch,
  output  io_msStatus_2_valid,
  output  [2:0] io_msStatus_2_bits_channel,
  output  [8:0] io_msStatus_2_bits_set,
  output  [30:0] io_msStatus_2_bits_reqTag,
  output  io_msStatus_2_bits_is_miss,
  output  io_msStatus_2_bits_is_prefetch,
  output  io_msStatus_3_valid,
  output  [2:0] io_msStatus_3_bits_channel,
  output  [8:0] io_msStatus_3_bits_set,
  output  [30:0] io_msStatus_3_bits_reqTag,
  output  io_msStatus_3_bits_is_miss,
  output  io_msStatus_3_bits_is_prefetch,
  output  io_msStatus_4_valid,
  output  [2:0] io_msStatus_4_bits_channel,
  output  [8:0] io_msStatus_4_bits_set,
  output  [30:0] io_msStatus_4_bits_reqTag,
  output  io_msStatus_4_bits_is_miss,
  output  io_msStatus_4_bits_is_prefetch,
  output  io_msStatus_5_valid,
  output  [2:0] io_msStatus_5_bits_channel,
  output  [8:0] io_msStatus_5_bits_set,
  output  [30:0] io_msStatus_5_bits_reqTag,
  output  io_msStatus_5_bits_is_miss,
  output  io_msStatus_5_bits_is_prefetch,
  output  io_msStatus_6_valid,
  output  [2:0] io_msStatus_6_bits_channel,
  output  [8:0] io_msStatus_6_bits_set,
  output  [30:0] io_msStatus_6_bits_reqTag,
  output  io_msStatus_6_bits_is_miss,
  output  io_msStatus_6_bits_is_prefetch,
  output  io_msStatus_7_valid,
  output  [2:0] io_msStatus_7_bits_channel,
  output  [8:0] io_msStatus_7_bits_set,
  output  [30:0] io_msStatus_7_bits_reqTag,
  output  io_msStatus_7_bits_is_miss,
  output  io_msStatus_7_bits_is_prefetch,
  output  io_msStatus_8_valid,
  output  [2:0] io_msStatus_8_bits_channel,
  output  [8:0] io_msStatus_8_bits_set,
  output  [30:0] io_msStatus_8_bits_reqTag,
  output  io_msStatus_8_bits_is_miss,
  output  io_msStatus_8_bits_is_prefetch,
  output  io_msStatus_9_valid,
  output  [2:0] io_msStatus_9_bits_channel,
  output  [8:0] io_msStatus_9_bits_set,
  output  [30:0] io_msStatus_9_bits_reqTag,
  output  io_msStatus_9_bits_is_miss,
  output  io_msStatus_9_bits_is_prefetch,
  output  io_msStatus_10_valid,
  output  [2:0] io_msStatus_10_bits_channel,
  output  [8:0] io_msStatus_10_bits_set,
  output  [30:0] io_msStatus_10_bits_reqTag,
  output  io_msStatus_10_bits_is_miss,
  output  io_msStatus_10_bits_is_prefetch,
  output  io_msStatus_11_valid,
  output  [2:0] io_msStatus_11_bits_channel,
  output  [8:0] io_msStatus_11_bits_set,
  output  [30:0] io_msStatus_11_bits_reqTag,
  output  io_msStatus_11_bits_is_miss,
  output  io_msStatus_11_bits_is_prefetch,
  output  io_msStatus_12_valid,
  output  [2:0] io_msStatus_12_bits_channel,
  output  [8:0] io_msStatus_12_bits_set,
  output  [30:0] io_msStatus_12_bits_reqTag,
  output  io_msStatus_12_bits_is_miss,
  output  io_msStatus_12_bits_is_prefetch,
  output  io_msStatus_13_valid,
  output  [2:0] io_msStatus_13_bits_channel,
  output  [8:0] io_msStatus_13_bits_set,
  output  [30:0] io_msStatus_13_bits_reqTag,
  output  io_msStatus_13_bits_is_miss,
  output  io_msStatus_13_bits_is_prefetch,
  output  io_msStatus_14_valid,
  output  [2:0] io_msStatus_14_bits_channel,
  output  [8:0] io_msStatus_14_bits_set,
  output  [30:0] io_msStatus_14_bits_reqTag,
  output  io_msStatus_14_bits_is_miss,
  output  io_msStatus_14_bits_is_prefetch,
  output  io_msStatus_15_valid,
  output  [2:0] io_msStatus_15_bits_channel,
  output  [8:0] io_msStatus_15_bits_set,
  output  [30:0] io_msStatus_15_bits_reqTag,
  output  io_msStatus_15_bits_is_miss,
  output  io_msStatus_15_bits_is_prefetch,
  output  [5:0] io_perf_0_value,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_3_value,
  output  [5:0] io_perf_4_value,
  output  [5:0] io_perf_5_value,
  output  [5:0] io_perf_6_value,
  output  [5:0] io_perf_7_value,
  output  [5:0] io_perf_8_value,
  output  [5:0] io_perf_9_value,
  output  [5:0] io_perf_10_value,
  output  [5:0] io_perf_11_value,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  [5:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [7:0] boreChildrenBd_bore_be,
  input  [12:0] boreChildrenBd_bore_addr,
  input  [103:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [12:0] boreChildrenBd_bore_addr_rd,
  output  [103:0] boreChildrenBd_bore_outdata
);
  assign io_in_a_ready = '0;
  assign io_in_b_valid = '0;
  assign io_in_b_bits_opcode = '0;
  assign io_in_b_bits_param = '0;
  assign io_in_b_bits_address = '0;
  assign io_in_b_bits_data = '0;
  assign io_in_c_ready = '0;
  assign io_in_d_valid = '0;
  assign io_in_d_bits_opcode = '0;
  assign io_in_d_bits_param = '0;
  assign io_in_d_bits_source = '0;
  assign io_in_d_bits_sink = '0;
  assign io_in_d_bits_denied = '0;
  assign io_in_d_bits_echo_isKeyword = '0;
  assign io_in_d_bits_data = '0;
  assign io_in_d_bits_corrupt = '0;
  assign io_l1Hint_valid = '0;
  assign io_l1Hint_bits_sourceId = '0;
  assign io_l1Hint_bits_isKeyword = '0;
  assign io_prefetch_train_valid = '0;
  assign io_prefetch_train_bits_tag = '0;
  assign io_prefetch_train_bits_set = '0;
  assign io_prefetch_train_bits_needT = '0;
  assign io_prefetch_train_bits_source = '0;
  assign io_prefetch_train_bits_vaddr = '0;
  assign io_prefetch_train_bits_hit = '0;
  assign io_prefetch_train_bits_prefetched = '0;
  assign io_prefetch_train_bits_pfsource = '0;
  assign io_prefetch_train_bits_reqsource = '0;
  assign io_prefetch_req_ready = '0;
  assign io_prefetch_resp_valid = '0;
  assign io_prefetch_resp_bits_tag = '0;
  assign io_prefetch_resp_bits_set = '0;
  assign io_prefetch_resp_bits_vaddr = '0;
  assign io_prefetch_resp_bits_pfSource = '0;
  assign io_dirResult_valid = '0;
  assign io_dirResult_bits_hit = '0;
  assign io_dirResult_bits_meta_prefetch = '0;
  assign io_dirResult_bits_meta_prefetchSrc = '0;
  assign io_dirResult_bits_replacerInfo_channel = '0;
  assign io_dirResult_bits_replacerInfo_reqSource = '0;
  assign io_latePF = '0;
  assign io_error_valid = '0;
  assign io_error_bits_valid = '0;
  assign io_error_bits_address = '0;
  assign io_l2Miss = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_qos = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_returnNID = '0;
  assign io_out_tx_req_bits_stashNIDValid = '0;
  assign io_out_tx_req_bits_returnTxnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_ns = '0;
  assign io_out_tx_req_bits_likelyshared = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_tx_req_bits_snoopMe = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_req_bits_tagOp = '0;
  assign io_out_tx_req_bits_traceTag = '0;
  assign io_out_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_tx_req_bits_mpam_partID = '0;
  assign io_out_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_tx_req_bits_rsvdc = '0;
  assign io_out_tx_rsp_valid = '0;
  assign io_out_tx_rsp_bits_qos = '0;
  assign io_out_tx_rsp_bits_tgtID = '0;
  assign io_out_tx_rsp_bits_txnID = '0;
  assign io_out_tx_rsp_bits_opcode = '0;
  assign io_out_tx_rsp_bits_respErr = '0;
  assign io_out_tx_rsp_bits_resp = '0;
  assign io_out_tx_rsp_bits_fwdState = '0;
  assign io_out_tx_rsp_bits_cBusy = '0;
  assign io_out_tx_rsp_bits_dbID = '0;
  assign io_out_tx_rsp_bits_pCrdType = '0;
  assign io_out_tx_rsp_bits_tagOp = '0;
  assign io_out_tx_rsp_bits_traceTag = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_respErr = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_ccID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_traceTag = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_out_tx_dat_bits_poison = '0;
  assign io_out_rx_snp_ready = '0;
  assign io_pCrd_0_query_valid = '0;
  assign io_pCrd_0_query_bits_pCrdType = '0;
  assign io_pCrd_0_query_bits_srcID = '0;
  assign io_pCrd_1_query_valid = '0;
  assign io_pCrd_1_query_bits_pCrdType = '0;
  assign io_pCrd_1_query_bits_srcID = '0;
  assign io_pCrd_2_query_valid = '0;
  assign io_pCrd_2_query_bits_pCrdType = '0;
  assign io_pCrd_2_query_bits_srcID = '0;
  assign io_pCrd_3_query_valid = '0;
  assign io_pCrd_3_query_bits_pCrdType = '0;
  assign io_pCrd_3_query_bits_srcID = '0;
  assign io_pCrd_4_query_valid = '0;
  assign io_pCrd_4_query_bits_pCrdType = '0;
  assign io_pCrd_4_query_bits_srcID = '0;
  assign io_pCrd_5_query_valid = '0;
  assign io_pCrd_5_query_bits_pCrdType = '0;
  assign io_pCrd_5_query_bits_srcID = '0;
  assign io_pCrd_6_query_valid = '0;
  assign io_pCrd_6_query_bits_pCrdType = '0;
  assign io_pCrd_6_query_bits_srcID = '0;
  assign io_pCrd_7_query_valid = '0;
  assign io_pCrd_7_query_bits_pCrdType = '0;
  assign io_pCrd_7_query_bits_srcID = '0;
  assign io_pCrd_8_query_valid = '0;
  assign io_pCrd_8_query_bits_pCrdType = '0;
  assign io_pCrd_8_query_bits_srcID = '0;
  assign io_pCrd_9_query_valid = '0;
  assign io_pCrd_9_query_bits_pCrdType = '0;
  assign io_pCrd_9_query_bits_srcID = '0;
  assign io_pCrd_10_query_valid = '0;
  assign io_pCrd_10_query_bits_pCrdType = '0;
  assign io_pCrd_10_query_bits_srcID = '0;
  assign io_pCrd_11_query_valid = '0;
  assign io_pCrd_11_query_bits_pCrdType = '0;
  assign io_pCrd_11_query_bits_srcID = '0;
  assign io_pCrd_12_query_valid = '0;
  assign io_pCrd_12_query_bits_pCrdType = '0;
  assign io_pCrd_12_query_bits_srcID = '0;
  assign io_pCrd_13_query_valid = '0;
  assign io_pCrd_13_query_bits_pCrdType = '0;
  assign io_pCrd_13_query_bits_srcID = '0;
  assign io_pCrd_14_query_valid = '0;
  assign io_pCrd_14_query_bits_pCrdType = '0;
  assign io_pCrd_14_query_bits_srcID = '0;
  assign io_pCrd_15_query_valid = '0;
  assign io_pCrd_15_query_bits_pCrdType = '0;
  assign io_pCrd_15_query_bits_srcID = '0;
  assign io_msStatus_0_valid = '0;
  assign io_msStatus_0_bits_channel = '0;
  assign io_msStatus_0_bits_set = '0;
  assign io_msStatus_0_bits_reqTag = '0;
  assign io_msStatus_0_bits_is_miss = '0;
  assign io_msStatus_0_bits_is_prefetch = '0;
  assign io_msStatus_1_valid = '0;
  assign io_msStatus_1_bits_channel = '0;
  assign io_msStatus_1_bits_set = '0;
  assign io_msStatus_1_bits_reqTag = '0;
  assign io_msStatus_1_bits_is_miss = '0;
  assign io_msStatus_1_bits_is_prefetch = '0;
  assign io_msStatus_2_valid = '0;
  assign io_msStatus_2_bits_channel = '0;
  assign io_msStatus_2_bits_set = '0;
  assign io_msStatus_2_bits_reqTag = '0;
  assign io_msStatus_2_bits_is_miss = '0;
  assign io_msStatus_2_bits_is_prefetch = '0;
  assign io_msStatus_3_valid = '0;
  assign io_msStatus_3_bits_channel = '0;
  assign io_msStatus_3_bits_set = '0;
  assign io_msStatus_3_bits_reqTag = '0;
  assign io_msStatus_3_bits_is_miss = '0;
  assign io_msStatus_3_bits_is_prefetch = '0;
  assign io_msStatus_4_valid = '0;
  assign io_msStatus_4_bits_channel = '0;
  assign io_msStatus_4_bits_set = '0;
  assign io_msStatus_4_bits_reqTag = '0;
  assign io_msStatus_4_bits_is_miss = '0;
  assign io_msStatus_4_bits_is_prefetch = '0;
  assign io_msStatus_5_valid = '0;
  assign io_msStatus_5_bits_channel = '0;
  assign io_msStatus_5_bits_set = '0;
  assign io_msStatus_5_bits_reqTag = '0;
  assign io_msStatus_5_bits_is_miss = '0;
  assign io_msStatus_5_bits_is_prefetch = '0;
  assign io_msStatus_6_valid = '0;
  assign io_msStatus_6_bits_channel = '0;
  assign io_msStatus_6_bits_set = '0;
  assign io_msStatus_6_bits_reqTag = '0;
  assign io_msStatus_6_bits_is_miss = '0;
  assign io_msStatus_6_bits_is_prefetch = '0;
  assign io_msStatus_7_valid = '0;
  assign io_msStatus_7_bits_channel = '0;
  assign io_msStatus_7_bits_set = '0;
  assign io_msStatus_7_bits_reqTag = '0;
  assign io_msStatus_7_bits_is_miss = '0;
  assign io_msStatus_7_bits_is_prefetch = '0;
  assign io_msStatus_8_valid = '0;
  assign io_msStatus_8_bits_channel = '0;
  assign io_msStatus_8_bits_set = '0;
  assign io_msStatus_8_bits_reqTag = '0;
  assign io_msStatus_8_bits_is_miss = '0;
  assign io_msStatus_8_bits_is_prefetch = '0;
  assign io_msStatus_9_valid = '0;
  assign io_msStatus_9_bits_channel = '0;
  assign io_msStatus_9_bits_set = '0;
  assign io_msStatus_9_bits_reqTag = '0;
  assign io_msStatus_9_bits_is_miss = '0;
  assign io_msStatus_9_bits_is_prefetch = '0;
  assign io_msStatus_10_valid = '0;
  assign io_msStatus_10_bits_channel = '0;
  assign io_msStatus_10_bits_set = '0;
  assign io_msStatus_10_bits_reqTag = '0;
  assign io_msStatus_10_bits_is_miss = '0;
  assign io_msStatus_10_bits_is_prefetch = '0;
  assign io_msStatus_11_valid = '0;
  assign io_msStatus_11_bits_channel = '0;
  assign io_msStatus_11_bits_set = '0;
  assign io_msStatus_11_bits_reqTag = '0;
  assign io_msStatus_11_bits_is_miss = '0;
  assign io_msStatus_11_bits_is_prefetch = '0;
  assign io_msStatus_12_valid = '0;
  assign io_msStatus_12_bits_channel = '0;
  assign io_msStatus_12_bits_set = '0;
  assign io_msStatus_12_bits_reqTag = '0;
  assign io_msStatus_12_bits_is_miss = '0;
  assign io_msStatus_12_bits_is_prefetch = '0;
  assign io_msStatus_13_valid = '0;
  assign io_msStatus_13_bits_channel = '0;
  assign io_msStatus_13_bits_set = '0;
  assign io_msStatus_13_bits_reqTag = '0;
  assign io_msStatus_13_bits_is_miss = '0;
  assign io_msStatus_13_bits_is_prefetch = '0;
  assign io_msStatus_14_valid = '0;
  assign io_msStatus_14_bits_channel = '0;
  assign io_msStatus_14_bits_set = '0;
  assign io_msStatus_14_bits_reqTag = '0;
  assign io_msStatus_14_bits_is_miss = '0;
  assign io_msStatus_14_bits_is_prefetch = '0;
  assign io_msStatus_15_valid = '0;
  assign io_msStatus_15_bits_channel = '0;
  assign io_msStatus_15_bits_set = '0;
  assign io_msStatus_15_bits_reqTag = '0;
  assign io_msStatus_15_bits_is_miss = '0;
  assign io_msStatus_15_bits_is_prefetch = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;
  assign io_perf_8_value = '0;
  assign io_perf_9_value = '0;
  assign io_perf_10_value = '0;
  assign io_perf_11_value = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module Slice_3(
  input  clock,
  input  reset,
  output  io_in_a_ready,
  input  io_in_a_valid,
  input  [3:0] io_in_a_bits_opcode,
  input  [2:0] io_in_a_bits_param,
  input  [2:0] io_in_a_bits_size,
  input  [6:0] io_in_a_bits_source,
  input  [47:0] io_in_a_bits_address,
  input  [4:0] io_in_a_bits_user_reqSource,
  input  [1:0] io_in_a_bits_user_alias,
  input  [43:0] io_in_a_bits_user_vaddr,
  input  io_in_a_bits_user_needHint,
  input  io_in_a_bits_echo_isKeyword,
  input  io_in_a_bits_corrupt,
  input  io_in_b_ready,
  output  io_in_b_valid,
  output  [2:0] io_in_b_bits_opcode,
  output  [1:0] io_in_b_bits_param,
  output  [47:0] io_in_b_bits_address,
  output  [255:0] io_in_b_bits_data,
  output  io_in_c_ready,
  input  io_in_c_valid,
  input  [2:0] io_in_c_bits_opcode,
  input  [2:0] io_in_c_bits_param,
  input  [2:0] io_in_c_bits_size,
  input  [6:0] io_in_c_bits_source,
  input  [47:0] io_in_c_bits_address,
  input  [255:0] io_in_c_bits_data,
  input  io_in_c_bits_corrupt,
  input  io_in_d_ready,
  output  io_in_d_valid,
  output  [3:0] io_in_d_bits_opcode,
  output  [1:0] io_in_d_bits_param,
  output  [6:0] io_in_d_bits_source,
  output  [7:0] io_in_d_bits_sink,
  output  io_in_d_bits_denied,
  output  io_in_d_bits_echo_isKeyword,
  output  [255:0] io_in_d_bits_data,
  output  io_in_d_bits_corrupt,
  input  io_in_e_valid,
  input  [7:0] io_in_e_bits_sink,
  input  io_l1Hint_ready,
  output  io_l1Hint_valid,
  output  [31:0] io_l1Hint_bits_sourceId,
  output  io_l1Hint_bits_isKeyword,
  input  io_prefetch_train_ready,
  output  io_prefetch_train_valid,
  output  [32:0] io_prefetch_train_bits_tag,
  output  [8:0] io_prefetch_train_bits_set,
  output  io_prefetch_train_bits_needT,
  output  [6:0] io_prefetch_train_bits_source,
  output  [43:0] io_prefetch_train_bits_vaddr,
  output  io_prefetch_train_bits_hit,
  output  io_prefetch_train_bits_prefetched,
  output  [2:0] io_prefetch_train_bits_pfsource,
  output  [4:0] io_prefetch_train_bits_reqsource,
  output  io_prefetch_req_ready,
  input  io_prefetch_req_valid,
  input  [32:0] io_prefetch_req_bits_tag,
  input  [8:0] io_prefetch_req_bits_set,
  input  [43:0] io_prefetch_req_bits_vaddr,
  input  io_prefetch_req_bits_needT,
  input  [6:0] io_prefetch_req_bits_source,
  input  [4:0] io_prefetch_req_bits_pfSource,
  input  io_prefetch_resp_ready,
  output  io_prefetch_resp_valid,
  output  [32:0] io_prefetch_resp_bits_tag,
  output  [8:0] io_prefetch_resp_bits_set,
  output  [43:0] io_prefetch_resp_bits_vaddr,
  output  [4:0] io_prefetch_resp_bits_pfSource,
  output  io_dirResult_valid,
  output  io_dirResult_bits_hit,
  output  io_dirResult_bits_meta_prefetch,
  output  [2:0] io_dirResult_bits_meta_prefetchSrc,
  output  [2:0] io_dirResult_bits_replacerInfo_channel,
  output  [4:0] io_dirResult_bits_replacerInfo_reqSource,
  output  io_latePF,
  output  io_error_valid,
  output  io_error_bits_valid,
  output  [45:0] io_error_bits_address,
  output  io_l2Miss,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [3:0] io_out_tx_req_bits_qos,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [10:0] io_out_tx_req_bits_returnNID,
  output  io_out_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_tx_req_bits_returnTxnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_ns,
  output  io_out_tx_req_bits_likelyshared,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  [7:0] io_out_tx_req_bits_lpIDWithPadding,
  output  io_out_tx_req_bits_snoopMe,
  output  io_out_tx_req_bits_expCompAck,
  output  [1:0] io_out_tx_req_bits_tagOp,
  output  io_out_tx_req_bits_traceTag,
  output  io_out_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_tx_req_bits_mpam_partID,
  output  io_out_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_tx_req_bits_rsvdc,
  input  io_out_tx_rsp_ready,
  output  io_out_tx_rsp_valid,
  output  [3:0] io_out_tx_rsp_bits_qos,
  output  [10:0] io_out_tx_rsp_bits_tgtID,
  output  [11:0] io_out_tx_rsp_bits_txnID,
  output  [4:0] io_out_tx_rsp_bits_opcode,
  output  [1:0] io_out_tx_rsp_bits_respErr,
  output  [2:0] io_out_tx_rsp_bits_resp,
  output  [2:0] io_out_tx_rsp_bits_fwdState,
  output  [2:0] io_out_tx_rsp_bits_cBusy,
  output  [11:0] io_out_tx_rsp_bits_dbID,
  output  [3:0] io_out_tx_rsp_bits_pCrdType,
  output  [1:0] io_out_tx_rsp_bits_tagOp,
  output  io_out_tx_rsp_bits_traceTag,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [1:0] io_out_tx_dat_bits_respErr,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_ccID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  io_out_tx_dat_bits_traceTag,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  output  [3:0] io_out_tx_dat_bits_poison,
  input  io_out_rx_rsp_valid,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [1:0] io_out_rx_rsp_bits_respErr,
  input  [2:0] io_out_rx_rsp_bits_resp,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  input  [3:0] io_out_rx_rsp_bits_pCrdType,
  input  io_out_rx_rsp_bits_traceTag,
  input  io_out_rx_dat_valid,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [10:0] io_out_rx_dat_bits_homeNID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [1:0] io_out_rx_dat_bits_respErr,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [11:0] io_out_rx_dat_bits_dbID,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  io_out_rx_dat_bits_traceTag,
  input  [255:0] io_out_rx_dat_bits_data,
  input  [31:0] io_out_rx_dat_bits_dataCheck,
  input  [3:0] io_out_rx_dat_bits_poison,
  output  io_out_rx_snp_ready,
  input  io_out_rx_snp_valid,
  input  [3:0] io_out_rx_snp_bits_qos,
  input  [10:0] io_out_rx_snp_bits_srcID,
  input  [11:0] io_out_rx_snp_bits_txnID,
  input  [10:0] io_out_rx_snp_bits_fwdNID,
  input  [11:0] io_out_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_rx_snp_bits_opcode,
  input  [44:0] io_out_rx_snp_bits_addr,
  input  io_out_rx_snp_bits_ns,
  input  io_out_rx_snp_bits_doNotGoToSD,
  input  io_out_rx_snp_bits_retToSrc,
  input  io_out_rx_snp_bits_traceTag,
  input  io_out_rx_snp_bits_mpam_perfMonGroup,
  input  [8:0] io_out_rx_snp_bits_mpam_partID,
  input  io_out_rx_snp_bits_mpam_mpamNS,
  output  io_pCrd_0_query_valid,
  output  [3:0] io_pCrd_0_query_bits_pCrdType,
  output  [10:0] io_pCrd_0_query_bits_srcID,
  input  io_pCrd_0_grant,
  output  io_pCrd_1_query_valid,
  output  [3:0] io_pCrd_1_query_bits_pCrdType,
  output  [10:0] io_pCrd_1_query_bits_srcID,
  input  io_pCrd_1_grant,
  output  io_pCrd_2_query_valid,
  output  [3:0] io_pCrd_2_query_bits_pCrdType,
  output  [10:0] io_pCrd_2_query_bits_srcID,
  input  io_pCrd_2_grant,
  output  io_pCrd_3_query_valid,
  output  [3:0] io_pCrd_3_query_bits_pCrdType,
  output  [10:0] io_pCrd_3_query_bits_srcID,
  input  io_pCrd_3_grant,
  output  io_pCrd_4_query_valid,
  output  [3:0] io_pCrd_4_query_bits_pCrdType,
  output  [10:0] io_pCrd_4_query_bits_srcID,
  input  io_pCrd_4_grant,
  output  io_pCrd_5_query_valid,
  output  [3:0] io_pCrd_5_query_bits_pCrdType,
  output  [10:0] io_pCrd_5_query_bits_srcID,
  input  io_pCrd_5_grant,
  output  io_pCrd_6_query_valid,
  output  [3:0] io_pCrd_6_query_bits_pCrdType,
  output  [10:0] io_pCrd_6_query_bits_srcID,
  input  io_pCrd_6_grant,
  output  io_pCrd_7_query_valid,
  output  [3:0] io_pCrd_7_query_bits_pCrdType,
  output  [10:0] io_pCrd_7_query_bits_srcID,
  input  io_pCrd_7_grant,
  output  io_pCrd_8_query_valid,
  output  [3:0] io_pCrd_8_query_bits_pCrdType,
  output  [10:0] io_pCrd_8_query_bits_srcID,
  input  io_pCrd_8_grant,
  output  io_pCrd_9_query_valid,
  output  [3:0] io_pCrd_9_query_bits_pCrdType,
  output  [10:0] io_pCrd_9_query_bits_srcID,
  input  io_pCrd_9_grant,
  output  io_pCrd_10_query_valid,
  output  [3:0] io_pCrd_10_query_bits_pCrdType,
  output  [10:0] io_pCrd_10_query_bits_srcID,
  input  io_pCrd_10_grant,
  output  io_pCrd_11_query_valid,
  output  [3:0] io_pCrd_11_query_bits_pCrdType,
  output  [10:0] io_pCrd_11_query_bits_srcID,
  input  io_pCrd_11_grant,
  output  io_pCrd_12_query_valid,
  output  [3:0] io_pCrd_12_query_bits_pCrdType,
  output  [10:0] io_pCrd_12_query_bits_srcID,
  input  io_pCrd_12_grant,
  output  io_pCrd_13_query_valid,
  output  [3:0] io_pCrd_13_query_bits_pCrdType,
  output  [10:0] io_pCrd_13_query_bits_srcID,
  input  io_pCrd_13_grant,
  output  io_pCrd_14_query_valid,
  output  [3:0] io_pCrd_14_query_bits_pCrdType,
  output  [10:0] io_pCrd_14_query_bits_srcID,
  input  io_pCrd_14_grant,
  output  io_pCrd_15_query_valid,
  output  [3:0] io_pCrd_15_query_bits_pCrdType,
  output  [10:0] io_pCrd_15_query_bits_srcID,
  input  io_pCrd_15_grant,
  output  io_msStatus_0_valid,
  output  [2:0] io_msStatus_0_bits_channel,
  output  [8:0] io_msStatus_0_bits_set,
  output  [30:0] io_msStatus_0_bits_reqTag,
  output  io_msStatus_0_bits_is_miss,
  output  io_msStatus_0_bits_is_prefetch,
  output  io_msStatus_1_valid,
  output  [2:0] io_msStatus_1_bits_channel,
  output  [8:0] io_msStatus_1_bits_set,
  output  [30:0] io_msStatus_1_bits_reqTag,
  output  io_msStatus_1_bits_is_miss,
  output  io_msStatus_1_bits_is_prefetch,
  output  io_msStatus_2_valid,
  output  [2:0] io_msStatus_2_bits_channel,
  output  [8:0] io_msStatus_2_bits_set,
  output  [30:0] io_msStatus_2_bits_reqTag,
  output  io_msStatus_2_bits_is_miss,
  output  io_msStatus_2_bits_is_prefetch,
  output  io_msStatus_3_valid,
  output  [2:0] io_msStatus_3_bits_channel,
  output  [8:0] io_msStatus_3_bits_set,
  output  [30:0] io_msStatus_3_bits_reqTag,
  output  io_msStatus_3_bits_is_miss,
  output  io_msStatus_3_bits_is_prefetch,
  output  io_msStatus_4_valid,
  output  [2:0] io_msStatus_4_bits_channel,
  output  [8:0] io_msStatus_4_bits_set,
  output  [30:0] io_msStatus_4_bits_reqTag,
  output  io_msStatus_4_bits_is_miss,
  output  io_msStatus_4_bits_is_prefetch,
  output  io_msStatus_5_valid,
  output  [2:0] io_msStatus_5_bits_channel,
  output  [8:0] io_msStatus_5_bits_set,
  output  [30:0] io_msStatus_5_bits_reqTag,
  output  io_msStatus_5_bits_is_miss,
  output  io_msStatus_5_bits_is_prefetch,
  output  io_msStatus_6_valid,
  output  [2:0] io_msStatus_6_bits_channel,
  output  [8:0] io_msStatus_6_bits_set,
  output  [30:0] io_msStatus_6_bits_reqTag,
  output  io_msStatus_6_bits_is_miss,
  output  io_msStatus_6_bits_is_prefetch,
  output  io_msStatus_7_valid,
  output  [2:0] io_msStatus_7_bits_channel,
  output  [8:0] io_msStatus_7_bits_set,
  output  [30:0] io_msStatus_7_bits_reqTag,
  output  io_msStatus_7_bits_is_miss,
  output  io_msStatus_7_bits_is_prefetch,
  output  io_msStatus_8_valid,
  output  [2:0] io_msStatus_8_bits_channel,
  output  [8:0] io_msStatus_8_bits_set,
  output  [30:0] io_msStatus_8_bits_reqTag,
  output  io_msStatus_8_bits_is_miss,
  output  io_msStatus_8_bits_is_prefetch,
  output  io_msStatus_9_valid,
  output  [2:0] io_msStatus_9_bits_channel,
  output  [8:0] io_msStatus_9_bits_set,
  output  [30:0] io_msStatus_9_bits_reqTag,
  output  io_msStatus_9_bits_is_miss,
  output  io_msStatus_9_bits_is_prefetch,
  output  io_msStatus_10_valid,
  output  [2:0] io_msStatus_10_bits_channel,
  output  [8:0] io_msStatus_10_bits_set,
  output  [30:0] io_msStatus_10_bits_reqTag,
  output  io_msStatus_10_bits_is_miss,
  output  io_msStatus_10_bits_is_prefetch,
  output  io_msStatus_11_valid,
  output  [2:0] io_msStatus_11_bits_channel,
  output  [8:0] io_msStatus_11_bits_set,
  output  [30:0] io_msStatus_11_bits_reqTag,
  output  io_msStatus_11_bits_is_miss,
  output  io_msStatus_11_bits_is_prefetch,
  output  io_msStatus_12_valid,
  output  [2:0] io_msStatus_12_bits_channel,
  output  [8:0] io_msStatus_12_bits_set,
  output  [30:0] io_msStatus_12_bits_reqTag,
  output  io_msStatus_12_bits_is_miss,
  output  io_msStatus_12_bits_is_prefetch,
  output  io_msStatus_13_valid,
  output  [2:0] io_msStatus_13_bits_channel,
  output  [8:0] io_msStatus_13_bits_set,
  output  [30:0] io_msStatus_13_bits_reqTag,
  output  io_msStatus_13_bits_is_miss,
  output  io_msStatus_13_bits_is_prefetch,
  output  io_msStatus_14_valid,
  output  [2:0] io_msStatus_14_bits_channel,
  output  [8:0] io_msStatus_14_bits_set,
  output  [30:0] io_msStatus_14_bits_reqTag,
  output  io_msStatus_14_bits_is_miss,
  output  io_msStatus_14_bits_is_prefetch,
  output  io_msStatus_15_valid,
  output  [2:0] io_msStatus_15_bits_channel,
  output  [8:0] io_msStatus_15_bits_set,
  output  [30:0] io_msStatus_15_bits_reqTag,
  output  io_msStatus_15_bits_is_miss,
  output  io_msStatus_15_bits_is_prefetch,
  output  [5:0] io_perf_0_value,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_3_value,
  output  [5:0] io_perf_4_value,
  output  [5:0] io_perf_5_value,
  output  [5:0] io_perf_6_value,
  output  [5:0] io_perf_7_value,
  output  [5:0] io_perf_8_value,
  output  [5:0] io_perf_9_value,
  output  [5:0] io_perf_10_value,
  output  [5:0] io_perf_11_value,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  [5:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [7:0] boreChildrenBd_bore_be,
  input  [12:0] boreChildrenBd_bore_addr,
  input  [103:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [12:0] boreChildrenBd_bore_addr_rd,
  output  [103:0] boreChildrenBd_bore_outdata
);
  assign io_in_a_ready = '0;
  assign io_in_b_valid = '0;
  assign io_in_b_bits_opcode = '0;
  assign io_in_b_bits_param = '0;
  assign io_in_b_bits_address = '0;
  assign io_in_b_bits_data = '0;
  assign io_in_c_ready = '0;
  assign io_in_d_valid = '0;
  assign io_in_d_bits_opcode = '0;
  assign io_in_d_bits_param = '0;
  assign io_in_d_bits_source = '0;
  assign io_in_d_bits_sink = '0;
  assign io_in_d_bits_denied = '0;
  assign io_in_d_bits_echo_isKeyword = '0;
  assign io_in_d_bits_data = '0;
  assign io_in_d_bits_corrupt = '0;
  assign io_l1Hint_valid = '0;
  assign io_l1Hint_bits_sourceId = '0;
  assign io_l1Hint_bits_isKeyword = '0;
  assign io_prefetch_train_valid = '0;
  assign io_prefetch_train_bits_tag = '0;
  assign io_prefetch_train_bits_set = '0;
  assign io_prefetch_train_bits_needT = '0;
  assign io_prefetch_train_bits_source = '0;
  assign io_prefetch_train_bits_vaddr = '0;
  assign io_prefetch_train_bits_hit = '0;
  assign io_prefetch_train_bits_prefetched = '0;
  assign io_prefetch_train_bits_pfsource = '0;
  assign io_prefetch_train_bits_reqsource = '0;
  assign io_prefetch_req_ready = '0;
  assign io_prefetch_resp_valid = '0;
  assign io_prefetch_resp_bits_tag = '0;
  assign io_prefetch_resp_bits_set = '0;
  assign io_prefetch_resp_bits_vaddr = '0;
  assign io_prefetch_resp_bits_pfSource = '0;
  assign io_dirResult_valid = '0;
  assign io_dirResult_bits_hit = '0;
  assign io_dirResult_bits_meta_prefetch = '0;
  assign io_dirResult_bits_meta_prefetchSrc = '0;
  assign io_dirResult_bits_replacerInfo_channel = '0;
  assign io_dirResult_bits_replacerInfo_reqSource = '0;
  assign io_latePF = '0;
  assign io_error_valid = '0;
  assign io_error_bits_valid = '0;
  assign io_error_bits_address = '0;
  assign io_l2Miss = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_qos = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_returnNID = '0;
  assign io_out_tx_req_bits_stashNIDValid = '0;
  assign io_out_tx_req_bits_returnTxnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_ns = '0;
  assign io_out_tx_req_bits_likelyshared = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_tx_req_bits_snoopMe = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_req_bits_tagOp = '0;
  assign io_out_tx_req_bits_traceTag = '0;
  assign io_out_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_tx_req_bits_mpam_partID = '0;
  assign io_out_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_tx_req_bits_rsvdc = '0;
  assign io_out_tx_rsp_valid = '0;
  assign io_out_tx_rsp_bits_qos = '0;
  assign io_out_tx_rsp_bits_tgtID = '0;
  assign io_out_tx_rsp_bits_txnID = '0;
  assign io_out_tx_rsp_bits_opcode = '0;
  assign io_out_tx_rsp_bits_respErr = '0;
  assign io_out_tx_rsp_bits_resp = '0;
  assign io_out_tx_rsp_bits_fwdState = '0;
  assign io_out_tx_rsp_bits_cBusy = '0;
  assign io_out_tx_rsp_bits_dbID = '0;
  assign io_out_tx_rsp_bits_pCrdType = '0;
  assign io_out_tx_rsp_bits_tagOp = '0;
  assign io_out_tx_rsp_bits_traceTag = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_respErr = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_ccID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_traceTag = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_out_tx_dat_bits_poison = '0;
  assign io_out_rx_snp_ready = '0;
  assign io_pCrd_0_query_valid = '0;
  assign io_pCrd_0_query_bits_pCrdType = '0;
  assign io_pCrd_0_query_bits_srcID = '0;
  assign io_pCrd_1_query_valid = '0;
  assign io_pCrd_1_query_bits_pCrdType = '0;
  assign io_pCrd_1_query_bits_srcID = '0;
  assign io_pCrd_2_query_valid = '0;
  assign io_pCrd_2_query_bits_pCrdType = '0;
  assign io_pCrd_2_query_bits_srcID = '0;
  assign io_pCrd_3_query_valid = '0;
  assign io_pCrd_3_query_bits_pCrdType = '0;
  assign io_pCrd_3_query_bits_srcID = '0;
  assign io_pCrd_4_query_valid = '0;
  assign io_pCrd_4_query_bits_pCrdType = '0;
  assign io_pCrd_4_query_bits_srcID = '0;
  assign io_pCrd_5_query_valid = '0;
  assign io_pCrd_5_query_bits_pCrdType = '0;
  assign io_pCrd_5_query_bits_srcID = '0;
  assign io_pCrd_6_query_valid = '0;
  assign io_pCrd_6_query_bits_pCrdType = '0;
  assign io_pCrd_6_query_bits_srcID = '0;
  assign io_pCrd_7_query_valid = '0;
  assign io_pCrd_7_query_bits_pCrdType = '0;
  assign io_pCrd_7_query_bits_srcID = '0;
  assign io_pCrd_8_query_valid = '0;
  assign io_pCrd_8_query_bits_pCrdType = '0;
  assign io_pCrd_8_query_bits_srcID = '0;
  assign io_pCrd_9_query_valid = '0;
  assign io_pCrd_9_query_bits_pCrdType = '0;
  assign io_pCrd_9_query_bits_srcID = '0;
  assign io_pCrd_10_query_valid = '0;
  assign io_pCrd_10_query_bits_pCrdType = '0;
  assign io_pCrd_10_query_bits_srcID = '0;
  assign io_pCrd_11_query_valid = '0;
  assign io_pCrd_11_query_bits_pCrdType = '0;
  assign io_pCrd_11_query_bits_srcID = '0;
  assign io_pCrd_12_query_valid = '0;
  assign io_pCrd_12_query_bits_pCrdType = '0;
  assign io_pCrd_12_query_bits_srcID = '0;
  assign io_pCrd_13_query_valid = '0;
  assign io_pCrd_13_query_bits_pCrdType = '0;
  assign io_pCrd_13_query_bits_srcID = '0;
  assign io_pCrd_14_query_valid = '0;
  assign io_pCrd_14_query_bits_pCrdType = '0;
  assign io_pCrd_14_query_bits_srcID = '0;
  assign io_pCrd_15_query_valid = '0;
  assign io_pCrd_15_query_bits_pCrdType = '0;
  assign io_pCrd_15_query_bits_srcID = '0;
  assign io_msStatus_0_valid = '0;
  assign io_msStatus_0_bits_channel = '0;
  assign io_msStatus_0_bits_set = '0;
  assign io_msStatus_0_bits_reqTag = '0;
  assign io_msStatus_0_bits_is_miss = '0;
  assign io_msStatus_0_bits_is_prefetch = '0;
  assign io_msStatus_1_valid = '0;
  assign io_msStatus_1_bits_channel = '0;
  assign io_msStatus_1_bits_set = '0;
  assign io_msStatus_1_bits_reqTag = '0;
  assign io_msStatus_1_bits_is_miss = '0;
  assign io_msStatus_1_bits_is_prefetch = '0;
  assign io_msStatus_2_valid = '0;
  assign io_msStatus_2_bits_channel = '0;
  assign io_msStatus_2_bits_set = '0;
  assign io_msStatus_2_bits_reqTag = '0;
  assign io_msStatus_2_bits_is_miss = '0;
  assign io_msStatus_2_bits_is_prefetch = '0;
  assign io_msStatus_3_valid = '0;
  assign io_msStatus_3_bits_channel = '0;
  assign io_msStatus_3_bits_set = '0;
  assign io_msStatus_3_bits_reqTag = '0;
  assign io_msStatus_3_bits_is_miss = '0;
  assign io_msStatus_3_bits_is_prefetch = '0;
  assign io_msStatus_4_valid = '0;
  assign io_msStatus_4_bits_channel = '0;
  assign io_msStatus_4_bits_set = '0;
  assign io_msStatus_4_bits_reqTag = '0;
  assign io_msStatus_4_bits_is_miss = '0;
  assign io_msStatus_4_bits_is_prefetch = '0;
  assign io_msStatus_5_valid = '0;
  assign io_msStatus_5_bits_channel = '0;
  assign io_msStatus_5_bits_set = '0;
  assign io_msStatus_5_bits_reqTag = '0;
  assign io_msStatus_5_bits_is_miss = '0;
  assign io_msStatus_5_bits_is_prefetch = '0;
  assign io_msStatus_6_valid = '0;
  assign io_msStatus_6_bits_channel = '0;
  assign io_msStatus_6_bits_set = '0;
  assign io_msStatus_6_bits_reqTag = '0;
  assign io_msStatus_6_bits_is_miss = '0;
  assign io_msStatus_6_bits_is_prefetch = '0;
  assign io_msStatus_7_valid = '0;
  assign io_msStatus_7_bits_channel = '0;
  assign io_msStatus_7_bits_set = '0;
  assign io_msStatus_7_bits_reqTag = '0;
  assign io_msStatus_7_bits_is_miss = '0;
  assign io_msStatus_7_bits_is_prefetch = '0;
  assign io_msStatus_8_valid = '0;
  assign io_msStatus_8_bits_channel = '0;
  assign io_msStatus_8_bits_set = '0;
  assign io_msStatus_8_bits_reqTag = '0;
  assign io_msStatus_8_bits_is_miss = '0;
  assign io_msStatus_8_bits_is_prefetch = '0;
  assign io_msStatus_9_valid = '0;
  assign io_msStatus_9_bits_channel = '0;
  assign io_msStatus_9_bits_set = '0;
  assign io_msStatus_9_bits_reqTag = '0;
  assign io_msStatus_9_bits_is_miss = '0;
  assign io_msStatus_9_bits_is_prefetch = '0;
  assign io_msStatus_10_valid = '0;
  assign io_msStatus_10_bits_channel = '0;
  assign io_msStatus_10_bits_set = '0;
  assign io_msStatus_10_bits_reqTag = '0;
  assign io_msStatus_10_bits_is_miss = '0;
  assign io_msStatus_10_bits_is_prefetch = '0;
  assign io_msStatus_11_valid = '0;
  assign io_msStatus_11_bits_channel = '0;
  assign io_msStatus_11_bits_set = '0;
  assign io_msStatus_11_bits_reqTag = '0;
  assign io_msStatus_11_bits_is_miss = '0;
  assign io_msStatus_11_bits_is_prefetch = '0;
  assign io_msStatus_12_valid = '0;
  assign io_msStatus_12_bits_channel = '0;
  assign io_msStatus_12_bits_set = '0;
  assign io_msStatus_12_bits_reqTag = '0;
  assign io_msStatus_12_bits_is_miss = '0;
  assign io_msStatus_12_bits_is_prefetch = '0;
  assign io_msStatus_13_valid = '0;
  assign io_msStatus_13_bits_channel = '0;
  assign io_msStatus_13_bits_set = '0;
  assign io_msStatus_13_bits_reqTag = '0;
  assign io_msStatus_13_bits_is_miss = '0;
  assign io_msStatus_13_bits_is_prefetch = '0;
  assign io_msStatus_14_valid = '0;
  assign io_msStatus_14_bits_channel = '0;
  assign io_msStatus_14_bits_set = '0;
  assign io_msStatus_14_bits_reqTag = '0;
  assign io_msStatus_14_bits_is_miss = '0;
  assign io_msStatus_14_bits_is_prefetch = '0;
  assign io_msStatus_15_valid = '0;
  assign io_msStatus_15_bits_channel = '0;
  assign io_msStatus_15_bits_set = '0;
  assign io_msStatus_15_bits_reqTag = '0;
  assign io_msStatus_15_bits_is_miss = '0;
  assign io_msStatus_15_bits_is_prefetch = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;
  assign io_perf_8_value = '0;
  assign io_perf_9_value = '0;
  assign io_perf_10_value = '0;
  assign io_perf_11_value = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module TopDownMonitor(
  input  io_dirResult_0_valid,
  input  io_dirResult_0_bits_hit,
  input  io_dirResult_0_bits_meta_prefetch,
  input  [2:0] io_dirResult_0_bits_meta_prefetchSrc,
  input  [2:0] io_dirResult_0_bits_replacerInfo_channel,
  input  [4:0] io_dirResult_0_bits_replacerInfo_reqSource,
  input  io_dirResult_1_valid,
  input  io_dirResult_1_bits_hit,
  input  io_dirResult_1_bits_meta_prefetch,
  input  [2:0] io_dirResult_1_bits_meta_prefetchSrc,
  input  [2:0] io_dirResult_1_bits_replacerInfo_channel,
  input  [4:0] io_dirResult_1_bits_replacerInfo_reqSource,
  input  io_dirResult_2_valid,
  input  io_dirResult_2_bits_hit,
  input  io_dirResult_2_bits_meta_prefetch,
  input  [2:0] io_dirResult_2_bits_meta_prefetchSrc,
  input  [2:0] io_dirResult_2_bits_replacerInfo_channel,
  input  [4:0] io_dirResult_2_bits_replacerInfo_reqSource,
  input  io_dirResult_3_valid,
  input  io_dirResult_3_bits_hit,
  input  io_dirResult_3_bits_meta_prefetch,
  input  [2:0] io_dirResult_3_bits_meta_prefetchSrc,
  input  [2:0] io_dirResult_3_bits_replacerInfo_channel,
  input  [4:0] io_dirResult_3_bits_replacerInfo_reqSource,
  input  io_msStatus_0_0_valid,
  input  [2:0] io_msStatus_0_0_bits_channel,
  input  [8:0] io_msStatus_0_0_bits_set,
  input  [30:0] io_msStatus_0_0_bits_reqTag,
  input  io_msStatus_0_0_bits_is_miss,
  input  io_msStatus_0_0_bits_is_prefetch,
  input  io_msStatus_0_1_valid,
  input  [2:0] io_msStatus_0_1_bits_channel,
  input  [8:0] io_msStatus_0_1_bits_set,
  input  [30:0] io_msStatus_0_1_bits_reqTag,
  input  io_msStatus_0_1_bits_is_miss,
  input  io_msStatus_0_1_bits_is_prefetch,
  input  io_msStatus_0_2_valid,
  input  [2:0] io_msStatus_0_2_bits_channel,
  input  [8:0] io_msStatus_0_2_bits_set,
  input  [30:0] io_msStatus_0_2_bits_reqTag,
  input  io_msStatus_0_2_bits_is_miss,
  input  io_msStatus_0_2_bits_is_prefetch,
  input  io_msStatus_0_3_valid,
  input  [2:0] io_msStatus_0_3_bits_channel,
  input  [8:0] io_msStatus_0_3_bits_set,
  input  [30:0] io_msStatus_0_3_bits_reqTag,
  input  io_msStatus_0_3_bits_is_miss,
  input  io_msStatus_0_3_bits_is_prefetch,
  input  io_msStatus_0_4_valid,
  input  [2:0] io_msStatus_0_4_bits_channel,
  input  [8:0] io_msStatus_0_4_bits_set,
  input  [30:0] io_msStatus_0_4_bits_reqTag,
  input  io_msStatus_0_4_bits_is_miss,
  input  io_msStatus_0_4_bits_is_prefetch,
  input  io_msStatus_0_5_valid,
  input  [2:0] io_msStatus_0_5_bits_channel,
  input  [8:0] io_msStatus_0_5_bits_set,
  input  [30:0] io_msStatus_0_5_bits_reqTag,
  input  io_msStatus_0_5_bits_is_miss,
  input  io_msStatus_0_5_bits_is_prefetch,
  input  io_msStatus_0_6_valid,
  input  [2:0] io_msStatus_0_6_bits_channel,
  input  [8:0] io_msStatus_0_6_bits_set,
  input  [30:0] io_msStatus_0_6_bits_reqTag,
  input  io_msStatus_0_6_bits_is_miss,
  input  io_msStatus_0_6_bits_is_prefetch,
  input  io_msStatus_0_7_valid,
  input  [2:0] io_msStatus_0_7_bits_channel,
  input  [8:0] io_msStatus_0_7_bits_set,
  input  [30:0] io_msStatus_0_7_bits_reqTag,
  input  io_msStatus_0_7_bits_is_miss,
  input  io_msStatus_0_7_bits_is_prefetch,
  input  io_msStatus_0_8_valid,
  input  [2:0] io_msStatus_0_8_bits_channel,
  input  [8:0] io_msStatus_0_8_bits_set,
  input  [30:0] io_msStatus_0_8_bits_reqTag,
  input  io_msStatus_0_8_bits_is_miss,
  input  io_msStatus_0_8_bits_is_prefetch,
  input  io_msStatus_0_9_valid,
  input  [2:0] io_msStatus_0_9_bits_channel,
  input  [8:0] io_msStatus_0_9_bits_set,
  input  [30:0] io_msStatus_0_9_bits_reqTag,
  input  io_msStatus_0_9_bits_is_miss,
  input  io_msStatus_0_9_bits_is_prefetch,
  input  io_msStatus_0_10_valid,
  input  [2:0] io_msStatus_0_10_bits_channel,
  input  [8:0] io_msStatus_0_10_bits_set,
  input  [30:0] io_msStatus_0_10_bits_reqTag,
  input  io_msStatus_0_10_bits_is_miss,
  input  io_msStatus_0_10_bits_is_prefetch,
  input  io_msStatus_0_11_valid,
  input  [2:0] io_msStatus_0_11_bits_channel,
  input  [8:0] io_msStatus_0_11_bits_set,
  input  [30:0] io_msStatus_0_11_bits_reqTag,
  input  io_msStatus_0_11_bits_is_miss,
  input  io_msStatus_0_11_bits_is_prefetch,
  input  io_msStatus_0_12_valid,
  input  [2:0] io_msStatus_0_12_bits_channel,
  input  [8:0] io_msStatus_0_12_bits_set,
  input  [30:0] io_msStatus_0_12_bits_reqTag,
  input  io_msStatus_0_12_bits_is_miss,
  input  io_msStatus_0_12_bits_is_prefetch,
  input  io_msStatus_0_13_valid,
  input  [2:0] io_msStatus_0_13_bits_channel,
  input  [8:0] io_msStatus_0_13_bits_set,
  input  [30:0] io_msStatus_0_13_bits_reqTag,
  input  io_msStatus_0_13_bits_is_miss,
  input  io_msStatus_0_13_bits_is_prefetch,
  input  io_msStatus_0_14_valid,
  input  [2:0] io_msStatus_0_14_bits_channel,
  input  [8:0] io_msStatus_0_14_bits_set,
  input  [30:0] io_msStatus_0_14_bits_reqTag,
  input  io_msStatus_0_14_bits_is_miss,
  input  io_msStatus_0_14_bits_is_prefetch,
  input  io_msStatus_0_15_valid,
  input  [2:0] io_msStatus_0_15_bits_channel,
  input  [8:0] io_msStatus_0_15_bits_set,
  input  [30:0] io_msStatus_0_15_bits_reqTag,
  input  io_msStatus_0_15_bits_is_miss,
  input  io_msStatus_0_15_bits_is_prefetch,
  input  io_msStatus_1_0_valid,
  input  [2:0] io_msStatus_1_0_bits_channel,
  input  [8:0] io_msStatus_1_0_bits_set,
  input  [30:0] io_msStatus_1_0_bits_reqTag,
  input  io_msStatus_1_0_bits_is_miss,
  input  io_msStatus_1_0_bits_is_prefetch,
  input  io_msStatus_1_1_valid,
  input  [2:0] io_msStatus_1_1_bits_channel,
  input  [8:0] io_msStatus_1_1_bits_set,
  input  [30:0] io_msStatus_1_1_bits_reqTag,
  input  io_msStatus_1_1_bits_is_miss,
  input  io_msStatus_1_1_bits_is_prefetch,
  input  io_msStatus_1_2_valid,
  input  [2:0] io_msStatus_1_2_bits_channel,
  input  [8:0] io_msStatus_1_2_bits_set,
  input  [30:0] io_msStatus_1_2_bits_reqTag,
  input  io_msStatus_1_2_bits_is_miss,
  input  io_msStatus_1_2_bits_is_prefetch,
  input  io_msStatus_1_3_valid,
  input  [2:0] io_msStatus_1_3_bits_channel,
  input  [8:0] io_msStatus_1_3_bits_set,
  input  [30:0] io_msStatus_1_3_bits_reqTag,
  input  io_msStatus_1_3_bits_is_miss,
  input  io_msStatus_1_3_bits_is_prefetch,
  input  io_msStatus_1_4_valid,
  input  [2:0] io_msStatus_1_4_bits_channel,
  input  [8:0] io_msStatus_1_4_bits_set,
  input  [30:0] io_msStatus_1_4_bits_reqTag,
  input  io_msStatus_1_4_bits_is_miss,
  input  io_msStatus_1_4_bits_is_prefetch,
  input  io_msStatus_1_5_valid,
  input  [2:0] io_msStatus_1_5_bits_channel,
  input  [8:0] io_msStatus_1_5_bits_set,
  input  [30:0] io_msStatus_1_5_bits_reqTag,
  input  io_msStatus_1_5_bits_is_miss,
  input  io_msStatus_1_5_bits_is_prefetch,
  input  io_msStatus_1_6_valid,
  input  [2:0] io_msStatus_1_6_bits_channel,
  input  [8:0] io_msStatus_1_6_bits_set,
  input  [30:0] io_msStatus_1_6_bits_reqTag,
  input  io_msStatus_1_6_bits_is_miss,
  input  io_msStatus_1_6_bits_is_prefetch,
  input  io_msStatus_1_7_valid,
  input  [2:0] io_msStatus_1_7_bits_channel,
  input  [8:0] io_msStatus_1_7_bits_set,
  input  [30:0] io_msStatus_1_7_bits_reqTag,
  input  io_msStatus_1_7_bits_is_miss,
  input  io_msStatus_1_7_bits_is_prefetch,
  input  io_msStatus_1_8_valid,
  input  [2:0] io_msStatus_1_8_bits_channel,
  input  [8:0] io_msStatus_1_8_bits_set,
  input  [30:0] io_msStatus_1_8_bits_reqTag,
  input  io_msStatus_1_8_bits_is_miss,
  input  io_msStatus_1_8_bits_is_prefetch,
  input  io_msStatus_1_9_valid,
  input  [2:0] io_msStatus_1_9_bits_channel,
  input  [8:0] io_msStatus_1_9_bits_set,
  input  [30:0] io_msStatus_1_9_bits_reqTag,
  input  io_msStatus_1_9_bits_is_miss,
  input  io_msStatus_1_9_bits_is_prefetch,
  input  io_msStatus_1_10_valid,
  input  [2:0] io_msStatus_1_10_bits_channel,
  input  [8:0] io_msStatus_1_10_bits_set,
  input  [30:0] io_msStatus_1_10_bits_reqTag,
  input  io_msStatus_1_10_bits_is_miss,
  input  io_msStatus_1_10_bits_is_prefetch,
  input  io_msStatus_1_11_valid,
  input  [2:0] io_msStatus_1_11_bits_channel,
  input  [8:0] io_msStatus_1_11_bits_set,
  input  [30:0] io_msStatus_1_11_bits_reqTag,
  input  io_msStatus_1_11_bits_is_miss,
  input  io_msStatus_1_11_bits_is_prefetch,
  input  io_msStatus_1_12_valid,
  input  [2:0] io_msStatus_1_12_bits_channel,
  input  [8:0] io_msStatus_1_12_bits_set,
  input  [30:0] io_msStatus_1_12_bits_reqTag,
  input  io_msStatus_1_12_bits_is_miss,
  input  io_msStatus_1_12_bits_is_prefetch,
  input  io_msStatus_1_13_valid,
  input  [2:0] io_msStatus_1_13_bits_channel,
  input  [8:0] io_msStatus_1_13_bits_set,
  input  [30:0] io_msStatus_1_13_bits_reqTag,
  input  io_msStatus_1_13_bits_is_miss,
  input  io_msStatus_1_13_bits_is_prefetch,
  input  io_msStatus_1_14_valid,
  input  [2:0] io_msStatus_1_14_bits_channel,
  input  [8:0] io_msStatus_1_14_bits_set,
  input  [30:0] io_msStatus_1_14_bits_reqTag,
  input  io_msStatus_1_14_bits_is_miss,
  input  io_msStatus_1_14_bits_is_prefetch,
  input  io_msStatus_1_15_valid,
  input  [2:0] io_msStatus_1_15_bits_channel,
  input  [8:0] io_msStatus_1_15_bits_set,
  input  [30:0] io_msStatus_1_15_bits_reqTag,
  input  io_msStatus_1_15_bits_is_miss,
  input  io_msStatus_1_15_bits_is_prefetch,
  input  io_msStatus_2_0_valid,
  input  [2:0] io_msStatus_2_0_bits_channel,
  input  [8:0] io_msStatus_2_0_bits_set,
  input  [30:0] io_msStatus_2_0_bits_reqTag,
  input  io_msStatus_2_0_bits_is_miss,
  input  io_msStatus_2_0_bits_is_prefetch,
  input  io_msStatus_2_1_valid,
  input  [2:0] io_msStatus_2_1_bits_channel,
  input  [8:0] io_msStatus_2_1_bits_set,
  input  [30:0] io_msStatus_2_1_bits_reqTag,
  input  io_msStatus_2_1_bits_is_miss,
  input  io_msStatus_2_1_bits_is_prefetch,
  input  io_msStatus_2_2_valid,
  input  [2:0] io_msStatus_2_2_bits_channel,
  input  [8:0] io_msStatus_2_2_bits_set,
  input  [30:0] io_msStatus_2_2_bits_reqTag,
  input  io_msStatus_2_2_bits_is_miss,
  input  io_msStatus_2_2_bits_is_prefetch,
  input  io_msStatus_2_3_valid,
  input  [2:0] io_msStatus_2_3_bits_channel,
  input  [8:0] io_msStatus_2_3_bits_set,
  input  [30:0] io_msStatus_2_3_bits_reqTag,
  input  io_msStatus_2_3_bits_is_miss,
  input  io_msStatus_2_3_bits_is_prefetch,
  input  io_msStatus_2_4_valid,
  input  [2:0] io_msStatus_2_4_bits_channel,
  input  [8:0] io_msStatus_2_4_bits_set,
  input  [30:0] io_msStatus_2_4_bits_reqTag,
  input  io_msStatus_2_4_bits_is_miss,
  input  io_msStatus_2_4_bits_is_prefetch,
  input  io_msStatus_2_5_valid,
  input  [2:0] io_msStatus_2_5_bits_channel,
  input  [8:0] io_msStatus_2_5_bits_set,
  input  [30:0] io_msStatus_2_5_bits_reqTag,
  input  io_msStatus_2_5_bits_is_miss,
  input  io_msStatus_2_5_bits_is_prefetch,
  input  io_msStatus_2_6_valid,
  input  [2:0] io_msStatus_2_6_bits_channel,
  input  [8:0] io_msStatus_2_6_bits_set,
  input  [30:0] io_msStatus_2_6_bits_reqTag,
  input  io_msStatus_2_6_bits_is_miss,
  input  io_msStatus_2_6_bits_is_prefetch,
  input  io_msStatus_2_7_valid,
  input  [2:0] io_msStatus_2_7_bits_channel,
  input  [8:0] io_msStatus_2_7_bits_set,
  input  [30:0] io_msStatus_2_7_bits_reqTag,
  input  io_msStatus_2_7_bits_is_miss,
  input  io_msStatus_2_7_bits_is_prefetch,
  input  io_msStatus_2_8_valid,
  input  [2:0] io_msStatus_2_8_bits_channel,
  input  [8:0] io_msStatus_2_8_bits_set,
  input  [30:0] io_msStatus_2_8_bits_reqTag,
  input  io_msStatus_2_8_bits_is_miss,
  input  io_msStatus_2_8_bits_is_prefetch,
  input  io_msStatus_2_9_valid,
  input  [2:0] io_msStatus_2_9_bits_channel,
  input  [8:0] io_msStatus_2_9_bits_set,
  input  [30:0] io_msStatus_2_9_bits_reqTag,
  input  io_msStatus_2_9_bits_is_miss,
  input  io_msStatus_2_9_bits_is_prefetch,
  input  io_msStatus_2_10_valid,
  input  [2:0] io_msStatus_2_10_bits_channel,
  input  [8:0] io_msStatus_2_10_bits_set,
  input  [30:0] io_msStatus_2_10_bits_reqTag,
  input  io_msStatus_2_10_bits_is_miss,
  input  io_msStatus_2_10_bits_is_prefetch,
  input  io_msStatus_2_11_valid,
  input  [2:0] io_msStatus_2_11_bits_channel,
  input  [8:0] io_msStatus_2_11_bits_set,
  input  [30:0] io_msStatus_2_11_bits_reqTag,
  input  io_msStatus_2_11_bits_is_miss,
  input  io_msStatus_2_11_bits_is_prefetch,
  input  io_msStatus_2_12_valid,
  input  [2:0] io_msStatus_2_12_bits_channel,
  input  [8:0] io_msStatus_2_12_bits_set,
  input  [30:0] io_msStatus_2_12_bits_reqTag,
  input  io_msStatus_2_12_bits_is_miss,
  input  io_msStatus_2_12_bits_is_prefetch,
  input  io_msStatus_2_13_valid,
  input  [2:0] io_msStatus_2_13_bits_channel,
  input  [8:0] io_msStatus_2_13_bits_set,
  input  [30:0] io_msStatus_2_13_bits_reqTag,
  input  io_msStatus_2_13_bits_is_miss,
  input  io_msStatus_2_13_bits_is_prefetch,
  input  io_msStatus_2_14_valid,
  input  [2:0] io_msStatus_2_14_bits_channel,
  input  [8:0] io_msStatus_2_14_bits_set,
  input  [30:0] io_msStatus_2_14_bits_reqTag,
  input  io_msStatus_2_14_bits_is_miss,
  input  io_msStatus_2_14_bits_is_prefetch,
  input  io_msStatus_2_15_valid,
  input  [2:0] io_msStatus_2_15_bits_channel,
  input  [8:0] io_msStatus_2_15_bits_set,
  input  [30:0] io_msStatus_2_15_bits_reqTag,
  input  io_msStatus_2_15_bits_is_miss,
  input  io_msStatus_2_15_bits_is_prefetch,
  input  io_msStatus_3_0_valid,
  input  [2:0] io_msStatus_3_0_bits_channel,
  input  [8:0] io_msStatus_3_0_bits_set,
  input  [30:0] io_msStatus_3_0_bits_reqTag,
  input  io_msStatus_3_0_bits_is_miss,
  input  io_msStatus_3_0_bits_is_prefetch,
  input  io_msStatus_3_1_valid,
  input  [2:0] io_msStatus_3_1_bits_channel,
  input  [8:0] io_msStatus_3_1_bits_set,
  input  [30:0] io_msStatus_3_1_bits_reqTag,
  input  io_msStatus_3_1_bits_is_miss,
  input  io_msStatus_3_1_bits_is_prefetch,
  input  io_msStatus_3_2_valid,
  input  [2:0] io_msStatus_3_2_bits_channel,
  input  [8:0] io_msStatus_3_2_bits_set,
  input  [30:0] io_msStatus_3_2_bits_reqTag,
  input  io_msStatus_3_2_bits_is_miss,
  input  io_msStatus_3_2_bits_is_prefetch,
  input  io_msStatus_3_3_valid,
  input  [2:0] io_msStatus_3_3_bits_channel,
  input  [8:0] io_msStatus_3_3_bits_set,
  input  [30:0] io_msStatus_3_3_bits_reqTag,
  input  io_msStatus_3_3_bits_is_miss,
  input  io_msStatus_3_3_bits_is_prefetch,
  input  io_msStatus_3_4_valid,
  input  [2:0] io_msStatus_3_4_bits_channel,
  input  [8:0] io_msStatus_3_4_bits_set,
  input  [30:0] io_msStatus_3_4_bits_reqTag,
  input  io_msStatus_3_4_bits_is_miss,
  input  io_msStatus_3_4_bits_is_prefetch,
  input  io_msStatus_3_5_valid,
  input  [2:0] io_msStatus_3_5_bits_channel,
  input  [8:0] io_msStatus_3_5_bits_set,
  input  [30:0] io_msStatus_3_5_bits_reqTag,
  input  io_msStatus_3_5_bits_is_miss,
  input  io_msStatus_3_5_bits_is_prefetch,
  input  io_msStatus_3_6_valid,
  input  [2:0] io_msStatus_3_6_bits_channel,
  input  [8:0] io_msStatus_3_6_bits_set,
  input  [30:0] io_msStatus_3_6_bits_reqTag,
  input  io_msStatus_3_6_bits_is_miss,
  input  io_msStatus_3_6_bits_is_prefetch,
  input  io_msStatus_3_7_valid,
  input  [2:0] io_msStatus_3_7_bits_channel,
  input  [8:0] io_msStatus_3_7_bits_set,
  input  [30:0] io_msStatus_3_7_bits_reqTag,
  input  io_msStatus_3_7_bits_is_miss,
  input  io_msStatus_3_7_bits_is_prefetch,
  input  io_msStatus_3_8_valid,
  input  [2:0] io_msStatus_3_8_bits_channel,
  input  [8:0] io_msStatus_3_8_bits_set,
  input  [30:0] io_msStatus_3_8_bits_reqTag,
  input  io_msStatus_3_8_bits_is_miss,
  input  io_msStatus_3_8_bits_is_prefetch,
  input  io_msStatus_3_9_valid,
  input  [2:0] io_msStatus_3_9_bits_channel,
  input  [8:0] io_msStatus_3_9_bits_set,
  input  [30:0] io_msStatus_3_9_bits_reqTag,
  input  io_msStatus_3_9_bits_is_miss,
  input  io_msStatus_3_9_bits_is_prefetch,
  input  io_msStatus_3_10_valid,
  input  [2:0] io_msStatus_3_10_bits_channel,
  input  [8:0] io_msStatus_3_10_bits_set,
  input  [30:0] io_msStatus_3_10_bits_reqTag,
  input  io_msStatus_3_10_bits_is_miss,
  input  io_msStatus_3_10_bits_is_prefetch,
  input  io_msStatus_3_11_valid,
  input  [2:0] io_msStatus_3_11_bits_channel,
  input  [8:0] io_msStatus_3_11_bits_set,
  input  [30:0] io_msStatus_3_11_bits_reqTag,
  input  io_msStatus_3_11_bits_is_miss,
  input  io_msStatus_3_11_bits_is_prefetch,
  input  io_msStatus_3_12_valid,
  input  [2:0] io_msStatus_3_12_bits_channel,
  input  [8:0] io_msStatus_3_12_bits_set,
  input  [30:0] io_msStatus_3_12_bits_reqTag,
  input  io_msStatus_3_12_bits_is_miss,
  input  io_msStatus_3_12_bits_is_prefetch,
  input  io_msStatus_3_13_valid,
  input  [2:0] io_msStatus_3_13_bits_channel,
  input  [8:0] io_msStatus_3_13_bits_set,
  input  [30:0] io_msStatus_3_13_bits_reqTag,
  input  io_msStatus_3_13_bits_is_miss,
  input  io_msStatus_3_13_bits_is_prefetch,
  input  io_msStatus_3_14_valid,
  input  [2:0] io_msStatus_3_14_bits_channel,
  input  [8:0] io_msStatus_3_14_bits_set,
  input  [30:0] io_msStatus_3_14_bits_reqTag,
  input  io_msStatus_3_14_bits_is_miss,
  input  io_msStatus_3_14_bits_is_prefetch,
  input  io_msStatus_3_15_valid,
  input  [2:0] io_msStatus_3_15_bits_channel,
  input  [8:0] io_msStatus_3_15_bits_set,
  input  [30:0] io_msStatus_3_15_bits_reqTag,
  input  io_msStatus_3_15_bits_is_miss,
  input  io_msStatus_3_15_bits_is_prefetch,
  input  io_latePF_0,
  input  io_latePF_1,
  input  io_latePF_2,
  input  io_latePF_3,
  input  io_debugTopDown_robHeadPaddr_valid,
  input  [35:0] io_debugTopDown_robHeadPaddr_bits,
  output  io_debugTopDown_l2MissMatch
);
  assign io_debugTopDown_l2MissMatch = '0;
endmodule

