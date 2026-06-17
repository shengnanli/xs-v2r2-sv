// 自动生成:scripts/gen_datapath.py —— 勿手改(逻辑为从设计意图的可读重写)

// =====================================================================
// 五条数据流的可读重写(从 DataPath.scala 设计意图重新实现)。
// 索引:g=全局 EXU 索引(0..26);src/k=源序号。各域读数据/读地址数组、写口流水、
// 黑盒例化见 datapath_connect.svh。所有判定用 datapath_pkg 纯函数,无 golden 临时名。
// =====================================================================

// === 数据流 2:读口仲裁请求(s0)===
//   每源 valid = IQ.valid & 该源 dataSources.readReg(ds_read_reg=value[3]),
//   addr = uop.rf[src].addr;按域送 5 个 RFReadArbiter(黑盒)。
  // -- Int 域读请求(arbiter io_in[g][sub][src])--
  assign int_rdreq_valid_0_0_0 = io_fromIntIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_0_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_0_0_0  = io_fromIntIQ_0_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_0_0_1 = io_fromIntIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_0_0_bits_common_dataSources_1_value);
  assign int_rdreq_addr_0_0_1  = io_fromIntIQ_0_0_bits_rf_1_0_addr;
  assign int_rdreq_valid_0_1_0 = io_fromIntIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_0_1_bits_common_dataSources_0_value);
  assign int_rdreq_addr_0_1_0  = io_fromIntIQ_0_1_bits_rf_0_0_addr;
  assign int_rdreq_valid_0_1_1 = io_fromIntIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_0_1_bits_common_dataSources_1_value);
  assign int_rdreq_addr_0_1_1  = io_fromIntIQ_0_1_bits_rf_1_0_addr;
  assign int_rdreq_valid_1_0_0 = io_fromIntIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_1_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_1_0_0  = io_fromIntIQ_1_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_1_0_1 = io_fromIntIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_1_0_bits_common_dataSources_1_value);
  assign int_rdreq_addr_1_0_1  = io_fromIntIQ_1_0_bits_rf_1_0_addr;
  assign int_rdreq_valid_1_1_0 = io_fromIntIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_1_1_bits_common_dataSources_0_value);
  assign int_rdreq_addr_1_1_0  = io_fromIntIQ_1_1_bits_rf_0_0_addr;
  assign int_rdreq_valid_1_1_1 = io_fromIntIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_1_1_bits_common_dataSources_1_value);
  assign int_rdreq_addr_1_1_1  = io_fromIntIQ_1_1_bits_rf_1_0_addr;
  assign int_rdreq_valid_2_0_0 = io_fromIntIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_2_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_2_0_0  = io_fromIntIQ_2_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_2_0_1 = io_fromIntIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_2_0_bits_common_dataSources_1_value);
  assign int_rdreq_addr_2_0_1  = io_fromIntIQ_2_0_bits_rf_1_0_addr;
  assign int_rdreq_valid_2_1_0 = io_fromIntIQ_2_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_2_1_bits_common_dataSources_0_value);
  assign int_rdreq_addr_2_1_0  = io_fromIntIQ_2_1_bits_rf_0_0_addr;
  assign int_rdreq_valid_2_1_1 = io_fromIntIQ_2_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_2_1_bits_common_dataSources_1_value);
  assign int_rdreq_addr_2_1_1  = io_fromIntIQ_2_1_bits_rf_1_0_addr;
  assign int_rdreq_valid_3_0_0 = io_fromIntIQ_3_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_3_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_3_0_0  = io_fromIntIQ_3_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_3_0_1 = io_fromIntIQ_3_0_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_3_0_bits_common_dataSources_1_value);
  assign int_rdreq_addr_3_0_1  = io_fromIntIQ_3_0_bits_rf_1_0_addr;
  assign int_rdreq_valid_3_1_0 = io_fromIntIQ_3_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_3_1_bits_common_dataSources_0_value);
  assign int_rdreq_addr_3_1_0  = io_fromIntIQ_3_1_bits_rf_0_0_addr;
  assign int_rdreq_valid_3_1_1 = io_fromIntIQ_3_1_valid & datapath_pkg::ds_read_reg(io_fromIntIQ_3_1_bits_common_dataSources_1_value);
  assign int_rdreq_addr_3_1_1  = io_fromIntIQ_3_1_bits_rf_1_0_addr;
  assign int_rdreq_valid_10_0_0 = io_fromMemIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_0_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_10_0_0  = io_fromMemIQ_0_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_11_0_0 = io_fromMemIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_1_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_11_0_0  = io_fromMemIQ_1_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_12_0_0 = io_fromMemIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_2_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_12_0_0  = io_fromMemIQ_2_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_13_0_0 = io_fromMemIQ_3_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_3_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_13_0_0  = io_fromMemIQ_3_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_14_0_0 = io_fromMemIQ_4_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_4_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_14_0_0  = io_fromMemIQ_4_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_17_0_0 = io_fromMemIQ_7_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_7_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_17_0_0  = io_fromMemIQ_7_0_bits_rf_0_0_addr;
  assign int_rdreq_valid_18_0_0 = io_fromMemIQ_8_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_8_0_bits_common_dataSources_0_value);
  assign int_rdreq_addr_18_0_0  = io_fromMemIQ_8_0_bits_rf_0_0_addr;
  // -- Fp 域读请求(arbiter io_in[g][sub][src])--
  assign fp_rdreq_valid_4_0_0 = io_fromFpIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_0_0_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_4_0_0  = io_fromFpIQ_0_0_bits_rf_0_0_addr;
  assign fp_rdreq_valid_4_0_1 = io_fromFpIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_0_0_bits_common_dataSources_1_value);
  assign fp_rdreq_addr_4_0_1  = io_fromFpIQ_0_0_bits_rf_1_0_addr;
  assign fp_rdreq_valid_4_0_2 = io_fromFpIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_0_0_bits_common_dataSources_2_value);
  assign fp_rdreq_addr_4_0_2  = io_fromFpIQ_0_0_bits_rf_2_0_addr;
  assign fp_rdreq_valid_4_1_0 = io_fromFpIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_0_1_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_4_1_0  = io_fromFpIQ_0_1_bits_rf_0_0_addr;
  assign fp_rdreq_valid_4_1_1 = io_fromFpIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_0_1_bits_common_dataSources_1_value);
  assign fp_rdreq_addr_4_1_1  = io_fromFpIQ_0_1_bits_rf_1_0_addr;
  assign fp_rdreq_valid_5_0_0 = io_fromFpIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_1_0_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_5_0_0  = io_fromFpIQ_1_0_bits_rf_0_0_addr;
  assign fp_rdreq_valid_5_0_1 = io_fromFpIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_1_0_bits_common_dataSources_1_value);
  assign fp_rdreq_addr_5_0_1  = io_fromFpIQ_1_0_bits_rf_1_0_addr;
  assign fp_rdreq_valid_5_0_2 = io_fromFpIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_1_0_bits_common_dataSources_2_value);
  assign fp_rdreq_addr_5_0_2  = io_fromFpIQ_1_0_bits_rf_2_0_addr;
  assign fp_rdreq_valid_5_1_0 = io_fromFpIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_1_1_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_5_1_0  = io_fromFpIQ_1_1_bits_rf_0_0_addr;
  assign fp_rdreq_valid_5_1_1 = io_fromFpIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_1_1_bits_common_dataSources_1_value);
  assign fp_rdreq_addr_5_1_1  = io_fromFpIQ_1_1_bits_rf_1_0_addr;
  assign fp_rdreq_valid_6_0_0 = io_fromFpIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_2_0_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_6_0_0  = io_fromFpIQ_2_0_bits_rf_0_0_addr;
  assign fp_rdreq_valid_6_0_1 = io_fromFpIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_2_0_bits_common_dataSources_1_value);
  assign fp_rdreq_addr_6_0_1  = io_fromFpIQ_2_0_bits_rf_1_0_addr;
  assign fp_rdreq_valid_6_0_2 = io_fromFpIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromFpIQ_2_0_bits_common_dataSources_2_value);
  assign fp_rdreq_addr_6_0_2  = io_fromFpIQ_2_0_bits_rf_2_0_addr;
  assign fp_rdreq_valid_17_0_0 = io_fromMemIQ_7_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_7_0_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_17_0_0  = io_fromMemIQ_7_0_bits_rf_0_0_addr;
  assign fp_rdreq_valid_18_0_0 = io_fromMemIQ_8_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_8_0_bits_common_dataSources_0_value);
  assign fp_rdreq_addr_18_0_0  = io_fromMemIQ_8_0_bits_rf_0_0_addr;
  // -- Vf 域读请求(arbiter io_in[g][sub][src])--
  assign vf_rdreq_valid_7_0_0 = io_fromVfIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_7_0_0  = io_fromVfIQ_0_0_bits_rf_0_0_addr;
  assign vf_rdreq_valid_7_0_1 = io_fromVfIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_7_0_1  = io_fromVfIQ_0_0_bits_rf_1_0_addr;
  assign vf_rdreq_valid_7_0_2 = io_fromVfIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_7_0_2  = io_fromVfIQ_0_0_bits_rf_2_0_addr;
  assign vf_rdreq_valid_7_1_0 = io_fromVfIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_7_1_0  = io_fromVfIQ_0_1_bits_rf_0_0_addr;
  assign vf_rdreq_valid_7_1_1 = io_fromVfIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_7_1_1  = io_fromVfIQ_0_1_bits_rf_1_0_addr;
  assign vf_rdreq_valid_7_1_2 = io_fromVfIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_7_1_2  = io_fromVfIQ_0_1_bits_rf_2_0_addr;
  assign vf_rdreq_valid_8_0_0 = io_fromVfIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_8_0_0  = io_fromVfIQ_1_0_bits_rf_0_0_addr;
  assign vf_rdreq_valid_8_0_1 = io_fromVfIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_8_0_1  = io_fromVfIQ_1_0_bits_rf_1_0_addr;
  assign vf_rdreq_valid_8_0_2 = io_fromVfIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_8_0_2  = io_fromVfIQ_1_0_bits_rf_2_0_addr;
  assign vf_rdreq_valid_8_1_0 = io_fromVfIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_8_1_0  = io_fromVfIQ_1_1_bits_rf_0_0_addr;
  assign vf_rdreq_valid_8_1_1 = io_fromVfIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_8_1_1  = io_fromVfIQ_1_1_bits_rf_1_0_addr;
  assign vf_rdreq_valid_8_1_2 = io_fromVfIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_8_1_2  = io_fromVfIQ_1_1_bits_rf_2_0_addr;
  assign vf_rdreq_valid_9_0_0 = io_fromVfIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_9_0_0  = io_fromVfIQ_2_0_bits_rf_0_0_addr;
  assign vf_rdreq_valid_9_0_1 = io_fromVfIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_9_0_1  = io_fromVfIQ_2_0_bits_rf_1_0_addr;
  assign vf_rdreq_valid_9_0_2 = io_fromVfIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_9_0_2  = io_fromVfIQ_2_0_bits_rf_2_0_addr;
  assign vf_rdreq_valid_15_0_0 = io_fromMemIQ_5_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_15_0_0  = io_fromMemIQ_5_0_bits_rf_0_0_addr;
  assign vf_rdreq_valid_15_0_1 = io_fromMemIQ_5_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_15_0_1  = io_fromMemIQ_5_0_bits_rf_1_0_addr;
  assign vf_rdreq_valid_15_0_2 = io_fromMemIQ_5_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_15_0_2  = io_fromMemIQ_5_0_bits_rf_2_0_addr;
  assign vf_rdreq_valid_16_0_0 = io_fromMemIQ_6_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_0_value);
  assign vf_rdreq_addr_16_0_0  = io_fromMemIQ_6_0_bits_rf_0_0_addr;
  assign vf_rdreq_valid_16_0_1 = io_fromMemIQ_6_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_1_value);
  assign vf_rdreq_addr_16_0_1  = io_fromMemIQ_6_0_bits_rf_1_0_addr;
  assign vf_rdreq_valid_16_0_2 = io_fromMemIQ_6_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_2_value);
  assign vf_rdreq_addr_16_0_2  = io_fromMemIQ_6_0_bits_rf_2_0_addr;
  // -- V0 域读请求(arbiter io_in[g][sub][src])--
  assign v0_rdreq_valid_7_0_3 = io_fromVfIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_7_0_3  = io_fromVfIQ_0_0_bits_rf_3_0_addr[4:0];
  assign v0_rdreq_valid_7_1_3 = io_fromVfIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_7_1_3  = io_fromVfIQ_0_1_bits_rf_3_0_addr[4:0];
  assign v0_rdreq_valid_8_0_3 = io_fromVfIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_8_0_3  = io_fromVfIQ_1_0_bits_rf_3_0_addr[4:0];
  assign v0_rdreq_valid_8_1_3 = io_fromVfIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_8_1_3  = io_fromVfIQ_1_1_bits_rf_3_0_addr[4:0];
  assign v0_rdreq_valid_9_0_3 = io_fromVfIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_9_0_3  = io_fromVfIQ_2_0_bits_rf_3_0_addr[4:0];
  assign v0_rdreq_valid_15_0_3 = io_fromMemIQ_5_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_15_0_3  = io_fromMemIQ_5_0_bits_rf_3_0_addr[4:0];
  assign v0_rdreq_valid_16_0_3 = io_fromMemIQ_6_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_3_value);
  assign v0_rdreq_addr_16_0_3  = io_fromMemIQ_6_0_bits_rf_3_0_addr[4:0];
  // -- Vl 域读请求(arbiter io_in[g][sub][src])--
  assign vl_rdreq_valid_7_0_4 = io_fromVfIQ_0_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_7_0_4  = io_fromVfIQ_0_0_bits_rf_4_0_addr[4:0];
  assign vl_rdreq_valid_7_1_4 = io_fromVfIQ_0_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_7_1_4  = io_fromVfIQ_0_1_bits_rf_4_0_addr[4:0];
  assign vl_rdreq_valid_8_0_4 = io_fromVfIQ_1_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_8_0_4  = io_fromVfIQ_1_0_bits_rf_4_0_addr[4:0];
  assign vl_rdreq_valid_8_1_4 = io_fromVfIQ_1_1_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_8_1_4  = io_fromVfIQ_1_1_bits_rf_4_0_addr[4:0];
  assign vl_rdreq_valid_9_0_4 = io_fromVfIQ_2_0_valid & datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_9_0_4  = io_fromVfIQ_2_0_bits_rf_4_0_addr[4:0];
  assign vl_rdreq_valid_15_0_4 = io_fromMemIQ_5_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_15_0_4  = io_fromMemIQ_5_0_bits_rf_4_0_addr[4:0];
  assign vl_rdreq_valid_16_0_4 = io_fromMemIQ_6_0_valid & datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_4_value);
  assign vl_rdreq_addr_16_0_4  = io_fromMemIQ_6_0_bits_rf_4_0_addr[4:0];

// === 数据流 1:写回源 -> 写口流水寄存器 ===
//   addr/data 打一拍对齐(RegEnable wen),wen 打一拍(RegNext)。向量域 wen 复制
//   到各 split。各 *_wr_q 由 connect 接到对应域 RegFile 写口,vecExcp 例外写在
//   connect 以更高优先级覆盖。
  // -- Int 写口流水(8 路, addr=8b data=64b;*_wr_*_q 在 decls 声明)--
  for (genvar wp = 0; wp < 8; wp++) begin : g_int_wr
    always_ff @(posedge clock) begin
      int_wr_wen_q[wp] <= int_wb_wen[wp];               // RegNext(wen)
      if (int_wb_wen[wp]) begin
        int_wr_addr_q[wp] <= int_wb_addr[wp];          // RegEnable(addr,wen)
        int_wr_data_q[wp] <= int_wb_data[wp];          // RegEnable(data,wen)
      end
    end
  end
  // -- Fp 写口流水(6 路, addr=8b data=64b;*_wr_*_q 在 decls 声明)--
  for (genvar wp = 0; wp < 6; wp++) begin : g_fp_wr
    always_ff @(posedge clock) begin
      fp_wr_wen_q[wp] <= fp_wb_wen[wp];               // RegNext(wen)
      if (fp_wb_wen[wp]) begin
        fp_wr_addr_q[wp] <= fp_wb_addr[wp];          // RegEnable(addr,wen)
        fp_wr_data_q[wp] <= fp_wb_data[wp];          // RegEnable(data,wen)
      end
    end
  end
  // -- Vf 写口流水(6 路, addr=7b data=128b;*_wr_*_q 在 decls 声明)--
  for (genvar wp = 0; wp < 6; wp++) begin : g_vf_wr
    always_ff @(posedge clock) begin
      vf_wr_wen_q[wp] <= vf_wb_wen[wp];               // RegNext(wen)
      if (vf_wb_wen[wp]) begin
        vf_wr_addr_q[wp] <= vf_wb_addr[wp];          // RegEnable(addr,wen)
        vf_wr_data_q[wp] <= vf_wb_data[wp];          // RegEnable(data,wen)
      end
    end
  end
  // -- V0 写口流水(6 路, addr=5b data=128b;*_wr_*_q 在 decls 声明)--
  for (genvar wp = 0; wp < 6; wp++) begin : g_v0_wr
    always_ff @(posedge clock) begin
      v0_wr_wen_q[wp] <= v0_wb_wen[wp];               // RegNext(wen)
      if (v0_wb_wen[wp]) begin
        v0_wr_addr_q[wp] <= v0_wb_addr[wp];          // RegEnable(addr,wen)
        v0_wr_data_q[wp] <= v0_wb_data[wp];          // RegEnable(data,wen)
      end
    end
  end
  // -- Vl 写口流水(4 路, addr=5b data=8b;*_wr_*_q 在 decls 声明)--
  for (genvar wp = 0; wp < 4; wp++) begin : g_vl_wr
    always_ff @(posedge clock) begin
      vl_wr_wen_q[wp] <= vl_wb_wen[wp];               // RegNext(wen)
      if (vl_wb_wen[wp]) begin
        vl_wr_addr_q[wp] <= vl_wb_addr[wp];          // RegEnable(addr,wen)
        vl_wr_data_q[wp] <= vl_wb_data[wp];          // RegEnable(data,wen)
      end
    end
  end

// === 数据流 3:s0->s1 流水(ready / notBlock / s1_valid / ctrl 寄存)===
//   notBlock = srcNotBlock & 各域写口冲突 notBlock;
//   srcNotBlock = AND_src(!该源 readReg | 该源在 5 域 arbiter 全抢到读口);
//   s0.ready = notBlock & !s0_cancel;
//   s1_valid <= s0.fire & !s1_flush & !s0_ldCancel;
//   s1_ctrl  <= fromIQ.common(when s0.valid);loadDependency 老化为 {ld[0],1'b0}。
  // EXU g0.0 (Int IQ0.0)
  assign notBlock_0_0 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_0_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_0_0_0 & fp_rdarb_rdy_0_0_0 & vf_rdarb_rdy_0_0_0 & v0_rdarb_rdy_0_0_0 & vl_rdarb_rdy_0_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_0_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_0_0_1 & fp_rdarb_rdy_0_0_1 & vf_rdarb_rdy_0_0_1 & v0_rdarb_rdy_0_0_1 & vl_rdarb_rdy_0_0_1))) &
      int_wbrdy_0_0 & fp_wbrdy_0_0 & vf_wbrdy_0_0 & v0_wbrdy_0_0 & vl_wbrdy_0_0;
  assign io_fromIntIQ_0_0_ready = notBlock_0_0 & ~s0_cancel_0_0;
  assign s1_flush_0_0 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_0_0_bits_common_robIdx_flag, io_fromIntIQ_0_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_0_0_bits_common_robIdx_flag, io_fromIntIQ_0_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_0_0 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_0_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_0_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_0_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_0_0 = io_fromIntIQ_0_0_valid & io_fromIntIQ_0_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_0_0 <= 1'b0;
    else s1_valid_0_0 <= fromIQ_fire_0_0 & ~s1_flush_0_0 & ~s0_ldCancel_0_0;
  end

  // EXU g0.1 (Int IQ0.1)
  assign notBlock_0_1 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_0_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_0_1_0 & fp_rdarb_rdy_0_1_0 & vf_rdarb_rdy_0_1_0 & v0_rdarb_rdy_0_1_0 & vl_rdarb_rdy_0_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_0_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_0_1_1 & fp_rdarb_rdy_0_1_1 & vf_rdarb_rdy_0_1_1 & v0_rdarb_rdy_0_1_1 & vl_rdarb_rdy_0_1_1))) &
      int_wbrdy_0_1 & fp_wbrdy_0_1 & vf_wbrdy_0_1 & v0_wbrdy_0_1 & vl_wbrdy_0_1;
  assign io_fromIntIQ_0_1_ready = notBlock_0_1 & ~s0_cancel_0_1;
  assign s1_flush_0_1 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_0_1_bits_common_robIdx_flag, io_fromIntIQ_0_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_0_1_bits_common_robIdx_flag, io_fromIntIQ_0_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_0_1 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_0_1_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_0_1_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_0_1_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_0_1 = io_fromIntIQ_0_1_valid & io_fromIntIQ_0_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_0_1 <= 1'b0;
    else s1_valid_0_1 <= fromIQ_fire_0_1 & ~s1_flush_0_1 & ~s0_ldCancel_0_1;
  end

  // EXU g1.0 (Int IQ1.0)
  assign notBlock_1_0 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_1_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_1_0_0 & fp_rdarb_rdy_1_0_0 & vf_rdarb_rdy_1_0_0 & v0_rdarb_rdy_1_0_0 & vl_rdarb_rdy_1_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_1_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_1_0_1 & fp_rdarb_rdy_1_0_1 & vf_rdarb_rdy_1_0_1 & v0_rdarb_rdy_1_0_1 & vl_rdarb_rdy_1_0_1))) &
      int_wbrdy_1_0 & fp_wbrdy_1_0 & vf_wbrdy_1_0 & v0_wbrdy_1_0 & vl_wbrdy_1_0;
  assign io_fromIntIQ_1_0_ready = notBlock_1_0 & ~s0_cancel_1_0;
  assign s1_flush_1_0 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_1_0_bits_common_robIdx_flag, io_fromIntIQ_1_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_1_0_bits_common_robIdx_flag, io_fromIntIQ_1_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_1_0 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_1_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_1_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_1_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_1_0 = io_fromIntIQ_1_0_valid & io_fromIntIQ_1_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_1_0 <= 1'b0;
    else s1_valid_1_0 <= fromIQ_fire_1_0 & ~s1_flush_1_0 & ~s0_ldCancel_1_0;
  end

  // EXU g1.1 (Int IQ1.1)
  assign notBlock_1_1 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_1_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_1_1_0 & fp_rdarb_rdy_1_1_0 & vf_rdarb_rdy_1_1_0 & v0_rdarb_rdy_1_1_0 & vl_rdarb_rdy_1_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_1_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_1_1_1 & fp_rdarb_rdy_1_1_1 & vf_rdarb_rdy_1_1_1 & v0_rdarb_rdy_1_1_1 & vl_rdarb_rdy_1_1_1))) &
      int_wbrdy_1_1 & fp_wbrdy_1_1 & vf_wbrdy_1_1 & v0_wbrdy_1_1 & vl_wbrdy_1_1;
  assign io_fromIntIQ_1_1_ready = notBlock_1_1 & ~s0_cancel_1_1;
  assign s1_flush_1_1 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_1_1_bits_common_robIdx_flag, io_fromIntIQ_1_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_1_1_bits_common_robIdx_flag, io_fromIntIQ_1_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_1_1 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_1_1_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_1_1_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_1_1_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_1_1 = io_fromIntIQ_1_1_valid & io_fromIntIQ_1_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_1_1 <= 1'b0;
    else s1_valid_1_1 <= fromIQ_fire_1_1 & ~s1_flush_1_1 & ~s0_ldCancel_1_1;
  end

  // EXU g2.0 (Int IQ2.0)
  assign notBlock_2_0 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_2_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_2_0_0 & fp_rdarb_rdy_2_0_0 & vf_rdarb_rdy_2_0_0 & v0_rdarb_rdy_2_0_0 & vl_rdarb_rdy_2_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_2_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_2_0_1 & fp_rdarb_rdy_2_0_1 & vf_rdarb_rdy_2_0_1 & v0_rdarb_rdy_2_0_1 & vl_rdarb_rdy_2_0_1))) &
      int_wbrdy_2_0 & fp_wbrdy_2_0 & vf_wbrdy_2_0 & v0_wbrdy_2_0 & vl_wbrdy_2_0;
  assign io_fromIntIQ_2_0_ready = notBlock_2_0 & ~s0_cancel_2_0;
  assign s1_flush_2_0 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_2_0_bits_common_robIdx_flag, io_fromIntIQ_2_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_2_0_bits_common_robIdx_flag, io_fromIntIQ_2_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_2_0 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_2_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_2_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_2_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_2_0 = io_fromIntIQ_2_0_valid & io_fromIntIQ_2_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_2_0 <= 1'b0;
    else s1_valid_2_0 <= fromIQ_fire_2_0 & ~s1_flush_2_0 & ~s0_ldCancel_2_0;
  end

  // EXU g2.1 (Int IQ2.1)
  assign notBlock_2_1 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_2_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_2_1_0 & fp_rdarb_rdy_2_1_0 & vf_rdarb_rdy_2_1_0 & v0_rdarb_rdy_2_1_0 & vl_rdarb_rdy_2_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_2_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_2_1_1 & fp_rdarb_rdy_2_1_1 & vf_rdarb_rdy_2_1_1 & v0_rdarb_rdy_2_1_1 & vl_rdarb_rdy_2_1_1))) &
      int_wbrdy_2_1 & fp_wbrdy_2_1 & vf_wbrdy_2_1 & v0_wbrdy_2_1 & vl_wbrdy_2_1;
  assign io_fromIntIQ_2_1_ready = notBlock_2_1 & ~s0_cancel_2_1;
  assign s1_flush_2_1 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_2_1_bits_common_robIdx_flag, io_fromIntIQ_2_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_2_1_bits_common_robIdx_flag, io_fromIntIQ_2_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_2_1 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_2_1_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_2_1_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_2_1_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_2_1 = io_fromIntIQ_2_1_valid & io_fromIntIQ_2_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_2_1 <= 1'b0;
    else s1_valid_2_1 <= fromIQ_fire_2_1 & ~s1_flush_2_1 & ~s0_ldCancel_2_1;
  end

  // EXU g3.0 (Int IQ3.0)
  assign notBlock_3_0 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_3_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_3_0_0 & fp_rdarb_rdy_3_0_0 & vf_rdarb_rdy_3_0_0 & v0_rdarb_rdy_3_0_0 & vl_rdarb_rdy_3_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_3_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_3_0_1 & fp_rdarb_rdy_3_0_1 & vf_rdarb_rdy_3_0_1 & v0_rdarb_rdy_3_0_1 & vl_rdarb_rdy_3_0_1))) &
      int_wbrdy_3_0 & fp_wbrdy_3_0 & vf_wbrdy_3_0 & v0_wbrdy_3_0 & vl_wbrdy_3_0;
  assign io_fromIntIQ_3_0_ready = notBlock_3_0 & ~s0_cancel_3_0;
  assign s1_flush_3_0 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_3_0_bits_common_robIdx_flag, io_fromIntIQ_3_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_3_0_bits_common_robIdx_flag, io_fromIntIQ_3_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_3_0 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_3_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_3_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_3_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_3_0 = io_fromIntIQ_3_0_valid & io_fromIntIQ_3_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_3_0 <= 1'b0;
    else s1_valid_3_0 <= fromIQ_fire_3_0 & ~s1_flush_3_0 & ~s0_ldCancel_3_0;
  end

  // EXU g3.1 (Int IQ3.1)
  assign notBlock_3_1 = ((~datapath_pkg::ds_read_reg(io_fromIntIQ_3_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_3_1_0 & fp_rdarb_rdy_3_1_0 & vf_rdarb_rdy_3_1_0 & v0_rdarb_rdy_3_1_0 & vl_rdarb_rdy_3_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromIntIQ_3_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_3_1_1 & fp_rdarb_rdy_3_1_1 & vf_rdarb_rdy_3_1_1 & v0_rdarb_rdy_3_1_1 & vl_rdarb_rdy_3_1_1))) &
      int_wbrdy_3_1 & fp_wbrdy_3_1 & vf_wbrdy_3_1 & v0_wbrdy_3_1 & vl_wbrdy_3_1;
  assign io_fromIntIQ_3_1_ready = notBlock_3_1 & ~s0_cancel_3_1;
  assign s1_flush_3_1 =
      datapath_pkg::rob_need_flush(io_fromIntIQ_3_1_bits_common_robIdx_flag, io_fromIntIQ_3_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromIntIQ_3_1_bits_common_robIdx_flag, io_fromIntIQ_3_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_3_1 = (io_ldCancel_0_ld2Cancel & io_fromIntIQ_3_1_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromIntIQ_3_1_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromIntIQ_3_1_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_3_1 = io_fromIntIQ_3_1_valid & io_fromIntIQ_3_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_3_1 <= 1'b0;
    else s1_valid_3_1 <= fromIQ_fire_3_1 & ~s1_flush_3_1 & ~s0_ldCancel_3_1;
  end

  // EXU g4.0 (Fp IQ0.0)
  assign notBlock_4_0 = ((~datapath_pkg::ds_read_reg(io_fromFpIQ_0_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_4_0_0 & fp_rdarb_rdy_4_0_0 & vf_rdarb_rdy_4_0_0 & v0_rdarb_rdy_4_0_0 & vl_rdarb_rdy_4_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_0_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_4_0_1 & fp_rdarb_rdy_4_0_1 & vf_rdarb_rdy_4_0_1 & v0_rdarb_rdy_4_0_1 & vl_rdarb_rdy_4_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_0_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_4_0_2 & fp_rdarb_rdy_4_0_2 & vf_rdarb_rdy_4_0_2 & v0_rdarb_rdy_4_0_2 & vl_rdarb_rdy_4_0_2))) &
      int_wbrdy_4_0 & fp_wbrdy_4_0 & vf_wbrdy_4_0 & v0_wbrdy_4_0 & vl_wbrdy_4_0;
  assign io_fromFpIQ_0_0_ready = notBlock_4_0 & ~s0_cancel_4_0;
  assign s1_flush_4_0 =
      datapath_pkg::rob_need_flush(io_fromFpIQ_0_0_bits_common_robIdx_flag, io_fromFpIQ_0_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromFpIQ_0_0_bits_common_robIdx_flag, io_fromFpIQ_0_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_4_0 = 1'b0;
  assign fromIQ_fire_4_0 = io_fromFpIQ_0_0_valid & io_fromFpIQ_0_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_4_0 <= 1'b0;
    else s1_valid_4_0 <= fromIQ_fire_4_0 & ~s1_flush_4_0 & ~s0_ldCancel_4_0;
  end

  // EXU g4.1 (Fp IQ0.1)
  assign notBlock_4_1 = ((~datapath_pkg::ds_read_reg(io_fromFpIQ_0_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_4_1_0 & fp_rdarb_rdy_4_1_0 & vf_rdarb_rdy_4_1_0 & v0_rdarb_rdy_4_1_0 & vl_rdarb_rdy_4_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_0_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_4_1_1 & fp_rdarb_rdy_4_1_1 & vf_rdarb_rdy_4_1_1 & v0_rdarb_rdy_4_1_1 & vl_rdarb_rdy_4_1_1))) &
      int_wbrdy_4_1 & fp_wbrdy_4_1 & vf_wbrdy_4_1 & v0_wbrdy_4_1 & vl_wbrdy_4_1;
  assign io_fromFpIQ_0_1_ready = notBlock_4_1 & ~s0_cancel_4_1;
  assign s1_flush_4_1 =
      datapath_pkg::rob_need_flush(io_fromFpIQ_0_1_bits_common_robIdx_flag, io_fromFpIQ_0_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromFpIQ_0_1_bits_common_robIdx_flag, io_fromFpIQ_0_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_4_1 = 1'b0;
  assign fromIQ_fire_4_1 = io_fromFpIQ_0_1_valid & io_fromFpIQ_0_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_4_1 <= 1'b0;
    else s1_valid_4_1 <= fromIQ_fire_4_1 & ~s1_flush_4_1 & ~s0_ldCancel_4_1;
  end

  // EXU g5.0 (Fp IQ1.0)
  assign notBlock_5_0 = ((~datapath_pkg::ds_read_reg(io_fromFpIQ_1_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_5_0_0 & fp_rdarb_rdy_5_0_0 & vf_rdarb_rdy_5_0_0 & v0_rdarb_rdy_5_0_0 & vl_rdarb_rdy_5_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_1_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_5_0_1 & fp_rdarb_rdy_5_0_1 & vf_rdarb_rdy_5_0_1 & v0_rdarb_rdy_5_0_1 & vl_rdarb_rdy_5_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_1_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_5_0_2 & fp_rdarb_rdy_5_0_2 & vf_rdarb_rdy_5_0_2 & v0_rdarb_rdy_5_0_2 & vl_rdarb_rdy_5_0_2))) &
      int_wbrdy_5_0 & fp_wbrdy_5_0 & vf_wbrdy_5_0 & v0_wbrdy_5_0 & vl_wbrdy_5_0;
  assign io_fromFpIQ_1_0_ready = notBlock_5_0 & ~s0_cancel_5_0;
  assign s1_flush_5_0 =
      datapath_pkg::rob_need_flush(io_fromFpIQ_1_0_bits_common_robIdx_flag, io_fromFpIQ_1_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromFpIQ_1_0_bits_common_robIdx_flag, io_fromFpIQ_1_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_5_0 = 1'b0;
  assign fromIQ_fire_5_0 = io_fromFpIQ_1_0_valid & io_fromFpIQ_1_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_5_0 <= 1'b0;
    else s1_valid_5_0 <= fromIQ_fire_5_0 & ~s1_flush_5_0 & ~s0_ldCancel_5_0;
  end

  // EXU g5.1 (Fp IQ1.1)
  assign notBlock_5_1 = ((~datapath_pkg::ds_read_reg(io_fromFpIQ_1_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_5_1_0 & fp_rdarb_rdy_5_1_0 & vf_rdarb_rdy_5_1_0 & v0_rdarb_rdy_5_1_0 & vl_rdarb_rdy_5_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_1_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_5_1_1 & fp_rdarb_rdy_5_1_1 & vf_rdarb_rdy_5_1_1 & v0_rdarb_rdy_5_1_1 & vl_rdarb_rdy_5_1_1))) &
      int_wbrdy_5_1 & fp_wbrdy_5_1 & vf_wbrdy_5_1 & v0_wbrdy_5_1 & vl_wbrdy_5_1;
  assign io_fromFpIQ_1_1_ready = notBlock_5_1 & ~s0_cancel_5_1;
  assign s1_flush_5_1 =
      datapath_pkg::rob_need_flush(io_fromFpIQ_1_1_bits_common_robIdx_flag, io_fromFpIQ_1_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromFpIQ_1_1_bits_common_robIdx_flag, io_fromFpIQ_1_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_5_1 = 1'b0;
  assign fromIQ_fire_5_1 = io_fromFpIQ_1_1_valid & io_fromFpIQ_1_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_5_1 <= 1'b0;
    else s1_valid_5_1 <= fromIQ_fire_5_1 & ~s1_flush_5_1 & ~s0_ldCancel_5_1;
  end

  // EXU g6.0 (Fp IQ2.0)
  assign notBlock_6_0 = ((~datapath_pkg::ds_read_reg(io_fromFpIQ_2_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_6_0_0 & fp_rdarb_rdy_6_0_0 & vf_rdarb_rdy_6_0_0 & v0_rdarb_rdy_6_0_0 & vl_rdarb_rdy_6_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_2_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_6_0_1 & fp_rdarb_rdy_6_0_1 & vf_rdarb_rdy_6_0_1 & v0_rdarb_rdy_6_0_1 & vl_rdarb_rdy_6_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromFpIQ_2_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_6_0_2 & fp_rdarb_rdy_6_0_2 & vf_rdarb_rdy_6_0_2 & v0_rdarb_rdy_6_0_2 & vl_rdarb_rdy_6_0_2))) &
      int_wbrdy_6_0 & fp_wbrdy_6_0 & vf_wbrdy_6_0 & v0_wbrdy_6_0 & vl_wbrdy_6_0;
  assign io_fromFpIQ_2_0_ready = notBlock_6_0 & ~s0_cancel_6_0;
  assign s1_flush_6_0 =
      datapath_pkg::rob_need_flush(io_fromFpIQ_2_0_bits_common_robIdx_flag, io_fromFpIQ_2_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromFpIQ_2_0_bits_common_robIdx_flag, io_fromFpIQ_2_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_6_0 = 1'b0;
  assign fromIQ_fire_6_0 = io_fromFpIQ_2_0_valid & io_fromFpIQ_2_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_6_0 <= 1'b0;
    else s1_valid_6_0 <= fromIQ_fire_6_0 & ~s1_flush_6_0 & ~s0_ldCancel_6_0;
  end

  // EXU g7.0 (Vf IQ0.0)
  assign notBlock_7_0 = ((~datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_7_0_0 & fp_rdarb_rdy_7_0_0 & vf_rdarb_rdy_7_0_0 & v0_rdarb_rdy_7_0_0 & vl_rdarb_rdy_7_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_7_0_1 & fp_rdarb_rdy_7_0_1 & vf_rdarb_rdy_7_0_1 & v0_rdarb_rdy_7_0_1 & vl_rdarb_rdy_7_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_7_0_2 & fp_rdarb_rdy_7_0_2 & vf_rdarb_rdy_7_0_2 & v0_rdarb_rdy_7_0_2 & vl_rdarb_rdy_7_0_2)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_3_value) | (int_rdarb_rdy_7_0_3 & fp_rdarb_rdy_7_0_3 & vf_rdarb_rdy_7_0_3 & v0_rdarb_rdy_7_0_3 & vl_rdarb_rdy_7_0_3)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_0_bits_common_dataSources_4_value) | (int_rdarb_rdy_7_0_4 & fp_rdarb_rdy_7_0_4 & vf_rdarb_rdy_7_0_4 & v0_rdarb_rdy_7_0_4 & vl_rdarb_rdy_7_0_4))) &
      int_wbrdy_7_0 & fp_wbrdy_7_0 & vf_wbrdy_7_0 & v0_wbrdy_7_0 & vl_wbrdy_7_0;
  assign io_fromVfIQ_0_0_ready = notBlock_7_0 & ~s0_cancel_7_0;
  assign s1_flush_7_0 =
      datapath_pkg::rob_need_flush(io_fromVfIQ_0_0_bits_common_robIdx_flag, io_fromVfIQ_0_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromVfIQ_0_0_bits_common_robIdx_flag, io_fromVfIQ_0_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_7_0 = 1'b0;
  assign fromIQ_fire_7_0 = io_fromVfIQ_0_0_valid & io_fromVfIQ_0_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_7_0 <= 1'b0;
    else s1_valid_7_0 <= fromIQ_fire_7_0 & ~s1_flush_7_0 & ~s0_ldCancel_7_0;
  end

  // EXU g7.1 (Vf IQ0.1)
  assign notBlock_7_1 = ((~datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_7_1_0 & fp_rdarb_rdy_7_1_0 & vf_rdarb_rdy_7_1_0 & v0_rdarb_rdy_7_1_0 & vl_rdarb_rdy_7_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_7_1_1 & fp_rdarb_rdy_7_1_1 & vf_rdarb_rdy_7_1_1 & v0_rdarb_rdy_7_1_1 & vl_rdarb_rdy_7_1_1)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_2_value) | (int_rdarb_rdy_7_1_2 & fp_rdarb_rdy_7_1_2 & vf_rdarb_rdy_7_1_2 & v0_rdarb_rdy_7_1_2 & vl_rdarb_rdy_7_1_2)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_3_value) | (int_rdarb_rdy_7_1_3 & fp_rdarb_rdy_7_1_3 & vf_rdarb_rdy_7_1_3 & v0_rdarb_rdy_7_1_3 & vl_rdarb_rdy_7_1_3)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_0_1_bits_common_dataSources_4_value) | (int_rdarb_rdy_7_1_4 & fp_rdarb_rdy_7_1_4 & vf_rdarb_rdy_7_1_4 & v0_rdarb_rdy_7_1_4 & vl_rdarb_rdy_7_1_4))) &
      int_wbrdy_7_1 & fp_wbrdy_7_1 & vf_wbrdy_7_1 & v0_wbrdy_7_1 & vl_wbrdy_7_1;
  assign io_fromVfIQ_0_1_ready = notBlock_7_1 & ~s0_cancel_7_1;
  assign s1_flush_7_1 =
      datapath_pkg::rob_need_flush(io_fromVfIQ_0_1_bits_common_robIdx_flag, io_fromVfIQ_0_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromVfIQ_0_1_bits_common_robIdx_flag, io_fromVfIQ_0_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_7_1 = 1'b0;
  assign fromIQ_fire_7_1 = io_fromVfIQ_0_1_valid & io_fromVfIQ_0_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_7_1 <= 1'b0;
    else s1_valid_7_1 <= fromIQ_fire_7_1 & ~s1_flush_7_1 & ~s0_ldCancel_7_1;
  end

  // EXU g8.0 (Vf IQ1.0)
  assign notBlock_8_0 = ((~datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_8_0_0 & fp_rdarb_rdy_8_0_0 & vf_rdarb_rdy_8_0_0 & v0_rdarb_rdy_8_0_0 & vl_rdarb_rdy_8_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_8_0_1 & fp_rdarb_rdy_8_0_1 & vf_rdarb_rdy_8_0_1 & v0_rdarb_rdy_8_0_1 & vl_rdarb_rdy_8_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_8_0_2 & fp_rdarb_rdy_8_0_2 & vf_rdarb_rdy_8_0_2 & v0_rdarb_rdy_8_0_2 & vl_rdarb_rdy_8_0_2)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_3_value) | (int_rdarb_rdy_8_0_3 & fp_rdarb_rdy_8_0_3 & vf_rdarb_rdy_8_0_3 & v0_rdarb_rdy_8_0_3 & vl_rdarb_rdy_8_0_3)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_0_bits_common_dataSources_4_value) | (int_rdarb_rdy_8_0_4 & fp_rdarb_rdy_8_0_4 & vf_rdarb_rdy_8_0_4 & v0_rdarb_rdy_8_0_4 & vl_rdarb_rdy_8_0_4))) &
      int_wbrdy_8_0 & fp_wbrdy_8_0 & vf_wbrdy_8_0 & v0_wbrdy_8_0 & vl_wbrdy_8_0;
  assign io_fromVfIQ_1_0_ready = notBlock_8_0 & ~s0_cancel_8_0;
  assign s1_flush_8_0 =
      datapath_pkg::rob_need_flush(io_fromVfIQ_1_0_bits_common_robIdx_flag, io_fromVfIQ_1_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromVfIQ_1_0_bits_common_robIdx_flag, io_fromVfIQ_1_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_8_0 = 1'b0;
  assign fromIQ_fire_8_0 = io_fromVfIQ_1_0_valid & io_fromVfIQ_1_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_8_0 <= 1'b0;
    else s1_valid_8_0 <= fromIQ_fire_8_0 & ~s1_flush_8_0 & ~s0_ldCancel_8_0;
  end

  // EXU g8.1 (Vf IQ1.1)
  assign notBlock_8_1 = ((~datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_0_value) | (int_rdarb_rdy_8_1_0 & fp_rdarb_rdy_8_1_0 & vf_rdarb_rdy_8_1_0 & v0_rdarb_rdy_8_1_0 & vl_rdarb_rdy_8_1_0)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_1_value) | (int_rdarb_rdy_8_1_1 & fp_rdarb_rdy_8_1_1 & vf_rdarb_rdy_8_1_1 & v0_rdarb_rdy_8_1_1 & vl_rdarb_rdy_8_1_1)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_2_value) | (int_rdarb_rdy_8_1_2 & fp_rdarb_rdy_8_1_2 & vf_rdarb_rdy_8_1_2 & v0_rdarb_rdy_8_1_2 & vl_rdarb_rdy_8_1_2)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_3_value) | (int_rdarb_rdy_8_1_3 & fp_rdarb_rdy_8_1_3 & vf_rdarb_rdy_8_1_3 & v0_rdarb_rdy_8_1_3 & vl_rdarb_rdy_8_1_3)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_1_1_bits_common_dataSources_4_value) | (int_rdarb_rdy_8_1_4 & fp_rdarb_rdy_8_1_4 & vf_rdarb_rdy_8_1_4 & v0_rdarb_rdy_8_1_4 & vl_rdarb_rdy_8_1_4))) &
      int_wbrdy_8_1 & fp_wbrdy_8_1 & vf_wbrdy_8_1 & v0_wbrdy_8_1 & vl_wbrdy_8_1;
  assign io_fromVfIQ_1_1_ready = notBlock_8_1 & ~s0_cancel_8_1;
  assign s1_flush_8_1 =
      datapath_pkg::rob_need_flush(io_fromVfIQ_1_1_bits_common_robIdx_flag, io_fromVfIQ_1_1_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromVfIQ_1_1_bits_common_robIdx_flag, io_fromVfIQ_1_1_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_8_1 = 1'b0;
  assign fromIQ_fire_8_1 = io_fromVfIQ_1_1_valid & io_fromVfIQ_1_1_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_8_1 <= 1'b0;
    else s1_valid_8_1 <= fromIQ_fire_8_1 & ~s1_flush_8_1 & ~s0_ldCancel_8_1;
  end

  // EXU g9.0 (Vf IQ2.0)
  assign notBlock_9_0 = ((~datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_9_0_0 & fp_rdarb_rdy_9_0_0 & vf_rdarb_rdy_9_0_0 & v0_rdarb_rdy_9_0_0 & vl_rdarb_rdy_9_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_9_0_1 & fp_rdarb_rdy_9_0_1 & vf_rdarb_rdy_9_0_1 & v0_rdarb_rdy_9_0_1 & vl_rdarb_rdy_9_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_9_0_2 & fp_rdarb_rdy_9_0_2 & vf_rdarb_rdy_9_0_2 & v0_rdarb_rdy_9_0_2 & vl_rdarb_rdy_9_0_2)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_3_value) | (int_rdarb_rdy_9_0_3 & fp_rdarb_rdy_9_0_3 & vf_rdarb_rdy_9_0_3 & v0_rdarb_rdy_9_0_3 & vl_rdarb_rdy_9_0_3)) &
        (~datapath_pkg::ds_read_reg(io_fromVfIQ_2_0_bits_common_dataSources_4_value) | (int_rdarb_rdy_9_0_4 & fp_rdarb_rdy_9_0_4 & vf_rdarb_rdy_9_0_4 & v0_rdarb_rdy_9_0_4 & vl_rdarb_rdy_9_0_4))) &
      int_wbrdy_9_0 & fp_wbrdy_9_0 & vf_wbrdy_9_0 & v0_wbrdy_9_0 & vl_wbrdy_9_0;
  assign io_fromVfIQ_2_0_ready = notBlock_9_0 & ~s0_cancel_9_0;
  assign s1_flush_9_0 =
      datapath_pkg::rob_need_flush(io_fromVfIQ_2_0_bits_common_robIdx_flag, io_fromVfIQ_2_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromVfIQ_2_0_bits_common_robIdx_flag, io_fromVfIQ_2_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_9_0 = 1'b0;
  assign fromIQ_fire_9_0 = io_fromVfIQ_2_0_valid & io_fromVfIQ_2_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_9_0 <= 1'b0;
    else s1_valid_9_0 <= fromIQ_fire_9_0 & ~s1_flush_9_0 & ~s0_ldCancel_9_0;
  end

  // EXU g10.0 (Mem IQ0.0)
  assign notBlock_10_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_0_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_10_0_0 & fp_rdarb_rdy_10_0_0 & vf_rdarb_rdy_10_0_0 & v0_rdarb_rdy_10_0_0 & vl_rdarb_rdy_10_0_0))) &
      int_wbrdy_10_0 & fp_wbrdy_10_0 & vf_wbrdy_10_0 & v0_wbrdy_10_0 & vl_wbrdy_10_0;
  assign io_fromMemIQ_0_0_ready = notBlock_10_0 & ~s0_cancel_10_0;
  assign s1_flush_10_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_0_0_bits_common_robIdx_flag, io_fromMemIQ_0_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_0_0_bits_common_robIdx_flag, io_fromMemIQ_0_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_10_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_0_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_0_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_0_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_10_0 = io_fromMemIQ_0_0_valid & io_fromMemIQ_0_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_10_0 <= 1'b0;
    else s1_valid_10_0 <= fromIQ_fire_10_0 & ~s1_flush_10_0 & ~s0_ldCancel_10_0;
  end

  // EXU g11.0 (Mem IQ1.0)
  assign notBlock_11_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_1_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_11_0_0 & fp_rdarb_rdy_11_0_0 & vf_rdarb_rdy_11_0_0 & v0_rdarb_rdy_11_0_0 & vl_rdarb_rdy_11_0_0))) &
      int_wbrdy_11_0 & fp_wbrdy_11_0 & vf_wbrdy_11_0 & v0_wbrdy_11_0 & vl_wbrdy_11_0;
  assign io_fromMemIQ_1_0_ready = notBlock_11_0 & ~s0_cancel_11_0;
  assign s1_flush_11_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_1_0_bits_common_robIdx_flag, io_fromMemIQ_1_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_1_0_bits_common_robIdx_flag, io_fromMemIQ_1_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_11_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_1_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_1_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_1_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_11_0 = io_fromMemIQ_1_0_valid & io_fromMemIQ_1_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_11_0 <= 1'b0;
    else s1_valid_11_0 <= fromIQ_fire_11_0 & ~s1_flush_11_0 & ~s0_ldCancel_11_0;
  end

  // EXU g12.0 (Mem IQ2.0)
  assign notBlock_12_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_2_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_12_0_0 & fp_rdarb_rdy_12_0_0 & vf_rdarb_rdy_12_0_0 & v0_rdarb_rdy_12_0_0 & vl_rdarb_rdy_12_0_0))) &
      int_wbrdy_12_0 & fp_wbrdy_12_0 & vf_wbrdy_12_0 & v0_wbrdy_12_0 & vl_wbrdy_12_0;
  assign io_fromMemIQ_2_0_ready = notBlock_12_0 & ~s0_cancel_12_0;
  assign s1_flush_12_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_2_0_bits_common_robIdx_flag, io_fromMemIQ_2_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_2_0_bits_common_robIdx_flag, io_fromMemIQ_2_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_12_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_2_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_2_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_2_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_12_0 = io_fromMemIQ_2_0_valid & io_fromMemIQ_2_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_12_0 <= 1'b0;
    else s1_valid_12_0 <= fromIQ_fire_12_0 & ~s1_flush_12_0 & ~s0_ldCancel_12_0;
  end

  // EXU g13.0 (Mem IQ3.0)
  assign notBlock_13_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_3_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_13_0_0 & fp_rdarb_rdy_13_0_0 & vf_rdarb_rdy_13_0_0 & v0_rdarb_rdy_13_0_0 & vl_rdarb_rdy_13_0_0))) &
      int_wbrdy_13_0 & fp_wbrdy_13_0 & vf_wbrdy_13_0 & v0_wbrdy_13_0 & vl_wbrdy_13_0;
  assign io_fromMemIQ_3_0_ready = notBlock_13_0 & ~s0_cancel_13_0;
  assign s1_flush_13_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_3_0_bits_common_robIdx_flag, io_fromMemIQ_3_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_3_0_bits_common_robIdx_flag, io_fromMemIQ_3_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_13_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_3_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_3_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_3_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_13_0 = io_fromMemIQ_3_0_valid & io_fromMemIQ_3_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_13_0 <= 1'b0;
    else s1_valid_13_0 <= fromIQ_fire_13_0 & ~s1_flush_13_0 & ~s0_ldCancel_13_0;
  end

  // EXU g14.0 (Mem IQ4.0)
  assign notBlock_14_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_4_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_14_0_0 & fp_rdarb_rdy_14_0_0 & vf_rdarb_rdy_14_0_0 & v0_rdarb_rdy_14_0_0 & vl_rdarb_rdy_14_0_0))) &
      int_wbrdy_14_0 & fp_wbrdy_14_0 & vf_wbrdy_14_0 & v0_wbrdy_14_0 & vl_wbrdy_14_0;
  assign io_fromMemIQ_4_0_ready = notBlock_14_0 & ~s0_cancel_14_0;
  assign s1_flush_14_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_4_0_bits_common_robIdx_flag, io_fromMemIQ_4_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_4_0_bits_common_robIdx_flag, io_fromMemIQ_4_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_14_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_4_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_4_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_4_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_14_0 = io_fromMemIQ_4_0_valid & io_fromMemIQ_4_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_14_0 <= 1'b0;
    else s1_valid_14_0 <= fromIQ_fire_14_0 & ~s1_flush_14_0 & ~s0_ldCancel_14_0;
  end

  // EXU g15.0 (Mem IQ5.0)
  assign notBlock_15_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_15_0_0 & fp_rdarb_rdy_15_0_0 & vf_rdarb_rdy_15_0_0 & v0_rdarb_rdy_15_0_0 & vl_rdarb_rdy_15_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_15_0_1 & fp_rdarb_rdy_15_0_1 & vf_rdarb_rdy_15_0_1 & v0_rdarb_rdy_15_0_1 & vl_rdarb_rdy_15_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_15_0_2 & fp_rdarb_rdy_15_0_2 & vf_rdarb_rdy_15_0_2 & v0_rdarb_rdy_15_0_2 & vl_rdarb_rdy_15_0_2)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_3_value) | (int_rdarb_rdy_15_0_3 & fp_rdarb_rdy_15_0_3 & vf_rdarb_rdy_15_0_3 & v0_rdarb_rdy_15_0_3 & vl_rdarb_rdy_15_0_3)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_5_0_bits_common_dataSources_4_value) | (int_rdarb_rdy_15_0_4 & fp_rdarb_rdy_15_0_4 & vf_rdarb_rdy_15_0_4 & v0_rdarb_rdy_15_0_4 & vl_rdarb_rdy_15_0_4))) &
      int_wbrdy_15_0 & fp_wbrdy_15_0 & vf_wbrdy_15_0 & v0_wbrdy_15_0 & vl_wbrdy_15_0;
  assign io_fromMemIQ_5_0_ready = notBlock_15_0 & ~s0_cancel_15_0;
  assign s1_flush_15_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_5_0_bits_common_robIdx_flag, io_fromMemIQ_5_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_5_0_bits_common_robIdx_flag, io_fromMemIQ_5_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_15_0 = 1'b0;
  assign fromIQ_fire_15_0 = io_fromMemIQ_5_0_valid & io_fromMemIQ_5_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_15_0 <= 1'b0;
    else s1_valid_15_0 <= fromIQ_fire_15_0 & ~s1_flush_15_0 & ~s0_ldCancel_15_0;
  end

  // EXU g16.0 (Mem IQ6.0)
  assign notBlock_16_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_16_0_0 & fp_rdarb_rdy_16_0_0 & vf_rdarb_rdy_16_0_0 & v0_rdarb_rdy_16_0_0 & vl_rdarb_rdy_16_0_0)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_1_value) | (int_rdarb_rdy_16_0_1 & fp_rdarb_rdy_16_0_1 & vf_rdarb_rdy_16_0_1 & v0_rdarb_rdy_16_0_1 & vl_rdarb_rdy_16_0_1)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_2_value) | (int_rdarb_rdy_16_0_2 & fp_rdarb_rdy_16_0_2 & vf_rdarb_rdy_16_0_2 & v0_rdarb_rdy_16_0_2 & vl_rdarb_rdy_16_0_2)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_3_value) | (int_rdarb_rdy_16_0_3 & fp_rdarb_rdy_16_0_3 & vf_rdarb_rdy_16_0_3 & v0_rdarb_rdy_16_0_3 & vl_rdarb_rdy_16_0_3)) &
        (~datapath_pkg::ds_read_reg(io_fromMemIQ_6_0_bits_common_dataSources_4_value) | (int_rdarb_rdy_16_0_4 & fp_rdarb_rdy_16_0_4 & vf_rdarb_rdy_16_0_4 & v0_rdarb_rdy_16_0_4 & vl_rdarb_rdy_16_0_4))) &
      int_wbrdy_16_0 & fp_wbrdy_16_0 & vf_wbrdy_16_0 & v0_wbrdy_16_0 & vl_wbrdy_16_0;
  assign io_fromMemIQ_6_0_ready = notBlock_16_0 & ~s0_cancel_16_0;
  assign s1_flush_16_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_6_0_bits_common_robIdx_flag, io_fromMemIQ_6_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_6_0_bits_common_robIdx_flag, io_fromMemIQ_6_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_16_0 = 1'b0;
  assign fromIQ_fire_16_0 = io_fromMemIQ_6_0_valid & io_fromMemIQ_6_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_16_0 <= 1'b0;
    else s1_valid_16_0 <= fromIQ_fire_16_0 & ~s1_flush_16_0 & ~s0_ldCancel_16_0;
  end

  // EXU g17.0 (Mem IQ7.0)
  assign notBlock_17_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_7_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_17_0_0 & fp_rdarb_rdy_17_0_0 & vf_rdarb_rdy_17_0_0 & v0_rdarb_rdy_17_0_0 & vl_rdarb_rdy_17_0_0))) &
      int_wbrdy_17_0 & fp_wbrdy_17_0 & vf_wbrdy_17_0 & v0_wbrdy_17_0 & vl_wbrdy_17_0;
  assign io_fromMemIQ_7_0_ready = notBlock_17_0 & ~s0_cancel_17_0;
  assign s1_flush_17_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_7_0_bits_common_robIdx_flag, io_fromMemIQ_7_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_7_0_bits_common_robIdx_flag, io_fromMemIQ_7_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_17_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_7_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_7_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_7_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_17_0 = io_fromMemIQ_7_0_valid & io_fromMemIQ_7_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_17_0 <= 1'b0;
    else s1_valid_17_0 <= fromIQ_fire_17_0 & ~s1_flush_17_0 & ~s0_ldCancel_17_0;
  end

  // EXU g18.0 (Mem IQ8.0)
  assign notBlock_18_0 = ((~datapath_pkg::ds_read_reg(io_fromMemIQ_8_0_bits_common_dataSources_0_value) | (int_rdarb_rdy_18_0_0 & fp_rdarb_rdy_18_0_0 & vf_rdarb_rdy_18_0_0 & v0_rdarb_rdy_18_0_0 & vl_rdarb_rdy_18_0_0))) &
      int_wbrdy_18_0 & fp_wbrdy_18_0 & vf_wbrdy_18_0 & v0_wbrdy_18_0 & vl_wbrdy_18_0;
  assign io_fromMemIQ_8_0_ready = notBlock_18_0 & ~s0_cancel_18_0;
  assign s1_flush_18_0 =
      datapath_pkg::rob_need_flush(io_fromMemIQ_8_0_bits_common_robIdx_flag, io_fromMemIQ_8_0_bits_common_robIdx_value, flush_now) |
      datapath_pkg::rob_need_flush(io_fromMemIQ_8_0_bits_common_robIdx_flag, io_fromMemIQ_8_0_bits_common_robIdx_value, flush_q);
  assign s0_ldCancel_18_0 = (io_ldCancel_0_ld2Cancel & io_fromMemIQ_8_0_bits_common_loadDependency_0[1]) | (io_ldCancel_1_ld2Cancel & io_fromMemIQ_8_0_bits_common_loadDependency_1[1]) | (io_ldCancel_2_ld2Cancel & io_fromMemIQ_8_0_bits_common_loadDependency_2[1]);
  assign fromIQ_fire_18_0 = io_fromMemIQ_8_0_valid & io_fromMemIQ_8_0_ready;
  always_ff @(posedge clock) begin
    if (reset) s1_valid_18_0 <= 1'b0;
    else s1_valid_18_0 <= fromIQ_fire_18_0 & ~s1_flush_18_0 & ~s0_ldCancel_18_0;
  end

// === 数据流 4:s1 操作数选择(读出 -> EXU src)===
//   多数端口某源固定读一个域 -> 直连该域读数据;访存 STD 等某源可读 int|fp ->
//   按 s1 寄存的 srcType 2 路 Mux1H(sel_src_intfp)。pc/target 从 fromPcTargetMem 取。
  assign io_toIntExu_0_0_bits_src_0 = int_rdata[0];
  assign io_toIntExu_0_0_bits_src_1 = int_rdata[1];
  assign io_toIntExu_0_1_bits_src_0 = int_rdata[6];
  assign io_toIntExu_0_1_bits_src_1 = int_rdata[7];
  assign io_toIntExu_0_1_bits_pc = io_fromPcTargetMem_toDataPathPC_0;
  assign io_toIntExu_0_1_bits_predictInfo_target = io_fromPcTargetMem_toDataPathTargetPC_0;
  assign io_toIntExu_1_0_bits_src_0 = int_rdata[2];
  assign io_toIntExu_1_0_bits_src_1 = int_rdata[3];
  assign io_toIntExu_1_1_bits_src_0 = int_rdata[4];
  assign io_toIntExu_1_1_bits_src_1 = int_rdata[5];
  assign io_toIntExu_1_1_bits_pc = io_fromPcTargetMem_toDataPathPC_1;
  assign io_toIntExu_1_1_bits_predictInfo_target = io_fromPcTargetMem_toDataPathTargetPC_1;
  assign io_toIntExu_2_0_bits_src_0 = int_rdata[4];
  assign io_toIntExu_2_0_bits_src_1 = int_rdata[5];
  assign io_toIntExu_2_1_bits_src_0 = int_rdata[2];
  assign io_toIntExu_2_1_bits_src_1 = int_rdata[3];
  assign io_toIntExu_2_1_bits_pc = io_fromPcTargetMem_toDataPathPC_2;
  assign io_toIntExu_2_1_bits_predictInfo_target = io_fromPcTargetMem_toDataPathTargetPC_2;
  assign io_toIntExu_3_0_bits_src_0 = int_rdata[6];
  assign io_toIntExu_3_0_bits_src_1 = int_rdata[7];
  assign io_toIntExu_3_1_bits_src_0 = int_rdata[0];
  assign io_toIntExu_3_1_bits_src_1 = int_rdata[1];
  assign io_toFpExu_0_0_bits_src_0 = fp_rdata[0];
  assign io_toFpExu_0_0_bits_src_1 = fp_rdata[1];
  assign io_toFpExu_0_0_bits_src_2 = fp_rdata[2];
  assign io_toFpExu_0_1_bits_src_0 = fp_rdata[2];
  assign io_toFpExu_0_1_bits_src_1 = fp_rdata[5];
  assign io_toFpExu_1_0_bits_src_0 = fp_rdata[3];
  assign io_toFpExu_1_0_bits_src_1 = fp_rdata[4];
  assign io_toFpExu_1_0_bits_src_2 = fp_rdata[5];
  assign io_toFpExu_1_1_bits_src_0 = fp_rdata[8];
  assign io_toFpExu_1_1_bits_src_1 = fp_rdata[9];
  assign io_toFpExu_2_0_bits_src_0 = fp_rdata[6];
  assign io_toFpExu_2_0_bits_src_1 = fp_rdata[7];
  assign io_toFpExu_2_0_bits_src_2 = fp_rdata[8];
  assign io_toVecExu_0_0_bits_src_0 = vf_rdata[0];
  assign io_toVecExu_0_0_bits_src_1 = vf_rdata[1];
  assign io_toVecExu_0_0_bits_src_2 = vf_rdata[2];
  assign io_toVecExu_0_0_bits_src_3 = v0_rdata[0];
  assign io_toVecExu_0_0_bits_src_4 = {120'h0, vl_rdata[0][7:0]};
  assign io_toVecExu_0_1_bits_src_0 = vf_rdata[0];
  assign io_toVecExu_0_1_bits_src_1 = vf_rdata[1];
  assign io_toVecExu_0_1_bits_src_2 = vf_rdata[2];
  assign io_toVecExu_0_1_bits_src_3 = v0_rdata[0];
  assign io_toVecExu_0_1_bits_src_4 = {120'h0, vl_rdata[0][7:0]};
  assign io_toVecExu_1_0_bits_src_0 = vf_rdata[3];
  assign io_toVecExu_1_0_bits_src_1 = vf_rdata[4];
  assign io_toVecExu_1_0_bits_src_2 = vf_rdata[5];
  assign io_toVecExu_1_0_bits_src_3 = v0_rdata[1];
  assign io_toVecExu_1_0_bits_src_4 = {120'h0, vl_rdata[1][7:0]};
  assign io_toVecExu_1_1_bits_src_0 = vf_rdata[3];
  assign io_toVecExu_1_1_bits_src_1 = vf_rdata[4];
  assign io_toVecExu_1_1_bits_src_2 = vf_rdata[5];
  assign io_toVecExu_1_1_bits_src_3 = v0_rdata[1];
  assign io_toVecExu_1_1_bits_src_4 = {120'h0, vl_rdata[1][7:0]};
  assign io_toVecExu_2_0_bits_src_0 = vf_rdata[3];
  assign io_toVecExu_2_0_bits_src_1 = vf_rdata[4];
  assign io_toVecExu_2_0_bits_src_2 = vf_rdata[5];
  assign io_toVecExu_2_0_bits_src_3 = v0_rdata[1];
  assign io_toVecExu_2_0_bits_src_4 = {120'h0, vl_rdata[1][7:0]};
  assign io_toMemExu_0_0_bits_src_0 = int_rdata[7];
  assign io_toMemExu_1_0_bits_src_0 = int_rdata[6];
  assign io_toMemExu_2_0_bits_src_0 = int_rdata[8];
  assign io_toMemExu_2_0_bits_pc = io_fromPcTargetMem_toDataPathPC_3;
  assign io_toMemExu_3_0_bits_src_0 = int_rdata[9];
  assign io_toMemExu_3_0_bits_pc = io_fromPcTargetMem_toDataPathPC_4;
  assign io_toMemExu_4_0_bits_src_0 = int_rdata[10];
  assign io_toMemExu_4_0_bits_pc = io_fromPcTargetMem_toDataPathPC_5;
  assign io_toMemExu_5_0_bits_src_0 = vf_rdata[6];
  assign io_toMemExu_5_0_bits_src_1 = vf_rdata[7];
  assign io_toMemExu_5_0_bits_src_2 = vf_rdata[8];
  assign io_toMemExu_5_0_bits_src_3 = v0_rdata[2];
  assign io_toMemExu_5_0_bits_src_4 = {120'h0, vl_rdata[2][7:0]};
  assign io_toMemExu_6_0_bits_src_0 = vf_rdata[9];
  assign io_toMemExu_6_0_bits_src_1 = vf_rdata[10];
  assign io_toMemExu_6_0_bits_src_2 = vf_rdata[11];
  assign io_toMemExu_6_0_bits_src_3 = v0_rdata[3];
  assign io_toMemExu_6_0_bits_src_4 = {120'h0, vl_rdata[3][7:0]};
  // g17.0 src0: STD 类端口,按 srcType 选 int|fp(2 路 Mux1H)
  assign io_toMemExu_7_0_bits_src_0 = datapath_pkg::sel_src_intfp(s1_srctype_17_0_0, int_rdata[5], fp_rdata[9]);
  // g18.0 src0: STD 类端口,按 srcType 选 int|fp(2 路 Mux1H)
  assign io_toMemExu_8_0_bits_src_0 = datapath_pkg::sel_src_intfp(s1_srctype_18_0_0, int_rdata[3], fp_rdata[10]);

// === 数据流 3 输出级:s1 寄存器 -> EXU(valid + 控制字段)===
//   toExu.valid = s1_valid;toExu.bits.<ctrl> = s1_ctrl(s0->s1 寄存的控制字段);
//   perfDebugInfo 在 DataPath 不产生,置 0(由更上游 perf 统计填)。
  // EXU g0.0 -> IntExu_0_0 输出
  assign io_toIntExu_0_0_valid = s1_valid_0_0;
  assign io_toIntExu_0_0_bits_fuType = s1_ctrl_0_0_fuType;
  assign io_toIntExu_0_0_bits_fuOpType = s1_ctrl_0_0_fuOpType;
  assign io_toIntExu_0_0_bits_robIdx_flag = s1_ctrl_0_0_robIdx_flag;
  assign io_toIntExu_0_0_bits_robIdx_value = s1_ctrl_0_0_robIdx_value;
  assign io_toIntExu_0_0_bits_pdest = s1_ctrl_0_0_pdest;
  assign io_toIntExu_0_0_bits_rfWen = s1_ctrl_0_0_rfWen;
  assign io_toIntExu_0_0_bits_dataSources_0_value = s1_ctrl_0_0_dataSources_0_value;
  assign io_toIntExu_0_0_bits_dataSources_1_value = s1_ctrl_0_0_dataSources_1_value;
  assign io_toIntExu_0_0_bits_exuSources_0_value = s1_ctrl_0_0_exuSources_0_value;
  assign io_toIntExu_0_0_bits_exuSources_1_value = s1_ctrl_0_0_exuSources_1_value;
  assign io_toIntExu_0_0_bits_loadDependency_0 = s1_ctrl_0_0_loadDependency_0;
  assign io_toIntExu_0_0_bits_loadDependency_1 = s1_ctrl_0_0_loadDependency_1;
  assign io_toIntExu_0_0_bits_loadDependency_2 = s1_ctrl_0_0_loadDependency_2;
  assign io_toIntExu_0_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_0_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_0_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g0.1 -> IntExu_0_1 输出
  assign io_toIntExu_0_1_valid = s1_valid_0_1;
  assign io_toIntExu_0_1_bits_fuType = s1_ctrl_0_1_fuType;
  assign io_toIntExu_0_1_bits_fuOpType = s1_ctrl_0_1_fuOpType;
  assign io_toIntExu_0_1_bits_robIdx_flag = s1_ctrl_0_1_robIdx_flag;
  assign io_toIntExu_0_1_bits_robIdx_value = s1_ctrl_0_1_robIdx_value;
  assign io_toIntExu_0_1_bits_pdest = s1_ctrl_0_1_pdest;
  assign io_toIntExu_0_1_bits_rfWen = s1_ctrl_0_1_rfWen;
  assign io_toIntExu_0_1_bits_preDecode_isRVC = s1_ctrl_0_1_preDecode_isRVC;
  assign io_toIntExu_0_1_bits_ftqIdx_flag = s1_ctrl_0_1_ftqIdx_flag;
  assign io_toIntExu_0_1_bits_ftqIdx_value = s1_ctrl_0_1_ftqIdx_value;
  assign io_toIntExu_0_1_bits_ftqOffset = s1_ctrl_0_1_ftqOffset;
  assign io_toIntExu_0_1_bits_predictInfo_taken = s1_ctrl_0_1_predictInfo_taken;
  assign io_toIntExu_0_1_bits_dataSources_0_value = s1_ctrl_0_1_dataSources_0_value;
  assign io_toIntExu_0_1_bits_dataSources_1_value = s1_ctrl_0_1_dataSources_1_value;
  assign io_toIntExu_0_1_bits_exuSources_0_value = s1_ctrl_0_1_exuSources_0_value;
  assign io_toIntExu_0_1_bits_exuSources_1_value = s1_ctrl_0_1_exuSources_1_value;
  assign io_toIntExu_0_1_bits_loadDependency_0 = s1_ctrl_0_1_loadDependency_0;
  assign io_toIntExu_0_1_bits_loadDependency_1 = s1_ctrl_0_1_loadDependency_1;
  assign io_toIntExu_0_1_bits_loadDependency_2 = s1_ctrl_0_1_loadDependency_2;
  assign io_toIntExu_0_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_0_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_0_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g1.0 -> IntExu_1_0 输出
  assign io_toIntExu_1_0_valid = s1_valid_1_0;
  assign io_toIntExu_1_0_bits_fuType = s1_ctrl_1_0_fuType;
  assign io_toIntExu_1_0_bits_fuOpType = s1_ctrl_1_0_fuOpType;
  assign io_toIntExu_1_0_bits_robIdx_flag = s1_ctrl_1_0_robIdx_flag;
  assign io_toIntExu_1_0_bits_robIdx_value = s1_ctrl_1_0_robIdx_value;
  assign io_toIntExu_1_0_bits_pdest = s1_ctrl_1_0_pdest;
  assign io_toIntExu_1_0_bits_rfWen = s1_ctrl_1_0_rfWen;
  assign io_toIntExu_1_0_bits_dataSources_0_value = s1_ctrl_1_0_dataSources_0_value;
  assign io_toIntExu_1_0_bits_dataSources_1_value = s1_ctrl_1_0_dataSources_1_value;
  assign io_toIntExu_1_0_bits_exuSources_0_value = s1_ctrl_1_0_exuSources_0_value;
  assign io_toIntExu_1_0_bits_exuSources_1_value = s1_ctrl_1_0_exuSources_1_value;
  assign io_toIntExu_1_0_bits_loadDependency_0 = s1_ctrl_1_0_loadDependency_0;
  assign io_toIntExu_1_0_bits_loadDependency_1 = s1_ctrl_1_0_loadDependency_1;
  assign io_toIntExu_1_0_bits_loadDependency_2 = s1_ctrl_1_0_loadDependency_2;
  assign io_toIntExu_1_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_1_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_1_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g1.1 -> IntExu_1_1 输出
  assign io_toIntExu_1_1_valid = s1_valid_1_1;
  assign io_toIntExu_1_1_bits_fuType = s1_ctrl_1_1_fuType;
  assign io_toIntExu_1_1_bits_fuOpType = s1_ctrl_1_1_fuOpType;
  assign io_toIntExu_1_1_bits_robIdx_flag = s1_ctrl_1_1_robIdx_flag;
  assign io_toIntExu_1_1_bits_robIdx_value = s1_ctrl_1_1_robIdx_value;
  assign io_toIntExu_1_1_bits_pdest = s1_ctrl_1_1_pdest;
  assign io_toIntExu_1_1_bits_rfWen = s1_ctrl_1_1_rfWen;
  assign io_toIntExu_1_1_bits_preDecode_isRVC = s1_ctrl_1_1_preDecode_isRVC;
  assign io_toIntExu_1_1_bits_ftqIdx_flag = s1_ctrl_1_1_ftqIdx_flag;
  assign io_toIntExu_1_1_bits_ftqIdx_value = s1_ctrl_1_1_ftqIdx_value;
  assign io_toIntExu_1_1_bits_ftqOffset = s1_ctrl_1_1_ftqOffset;
  assign io_toIntExu_1_1_bits_predictInfo_taken = s1_ctrl_1_1_predictInfo_taken;
  assign io_toIntExu_1_1_bits_dataSources_0_value = s1_ctrl_1_1_dataSources_0_value;
  assign io_toIntExu_1_1_bits_dataSources_1_value = s1_ctrl_1_1_dataSources_1_value;
  assign io_toIntExu_1_1_bits_exuSources_0_value = s1_ctrl_1_1_exuSources_0_value;
  assign io_toIntExu_1_1_bits_exuSources_1_value = s1_ctrl_1_1_exuSources_1_value;
  assign io_toIntExu_1_1_bits_loadDependency_0 = s1_ctrl_1_1_loadDependency_0;
  assign io_toIntExu_1_1_bits_loadDependency_1 = s1_ctrl_1_1_loadDependency_1;
  assign io_toIntExu_1_1_bits_loadDependency_2 = s1_ctrl_1_1_loadDependency_2;
  assign io_toIntExu_1_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_1_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_1_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g2.0 -> IntExu_2_0 输出
  assign io_toIntExu_2_0_valid = s1_valid_2_0;
  assign io_toIntExu_2_0_bits_fuType = s1_ctrl_2_0_fuType;
  assign io_toIntExu_2_0_bits_fuOpType = s1_ctrl_2_0_fuOpType;
  assign io_toIntExu_2_0_bits_robIdx_flag = s1_ctrl_2_0_robIdx_flag;
  assign io_toIntExu_2_0_bits_robIdx_value = s1_ctrl_2_0_robIdx_value;
  assign io_toIntExu_2_0_bits_pdest = s1_ctrl_2_0_pdest;
  assign io_toIntExu_2_0_bits_rfWen = s1_ctrl_2_0_rfWen;
  assign io_toIntExu_2_0_bits_dataSources_0_value = s1_ctrl_2_0_dataSources_0_value;
  assign io_toIntExu_2_0_bits_dataSources_1_value = s1_ctrl_2_0_dataSources_1_value;
  assign io_toIntExu_2_0_bits_exuSources_0_value = s1_ctrl_2_0_exuSources_0_value;
  assign io_toIntExu_2_0_bits_exuSources_1_value = s1_ctrl_2_0_exuSources_1_value;
  assign io_toIntExu_2_0_bits_loadDependency_0 = s1_ctrl_2_0_loadDependency_0;
  assign io_toIntExu_2_0_bits_loadDependency_1 = s1_ctrl_2_0_loadDependency_1;
  assign io_toIntExu_2_0_bits_loadDependency_2 = s1_ctrl_2_0_loadDependency_2;
  assign io_toIntExu_2_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_2_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_2_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g2.1 -> IntExu_2_1 输出
  assign io_toIntExu_2_1_valid = s1_valid_2_1;
  assign io_toIntExu_2_1_bits_fuType = s1_ctrl_2_1_fuType;
  assign io_toIntExu_2_1_bits_fuOpType = s1_ctrl_2_1_fuOpType;
  assign io_toIntExu_2_1_bits_robIdx_flag = s1_ctrl_2_1_robIdx_flag;
  assign io_toIntExu_2_1_bits_robIdx_value = s1_ctrl_2_1_robIdx_value;
  assign io_toIntExu_2_1_bits_pdest = s1_ctrl_2_1_pdest;
  assign io_toIntExu_2_1_bits_rfWen = s1_ctrl_2_1_rfWen;
  assign io_toIntExu_2_1_bits_fpWen = s1_ctrl_2_1_fpWen;
  assign io_toIntExu_2_1_bits_vecWen = s1_ctrl_2_1_vecWen;
  assign io_toIntExu_2_1_bits_v0Wen = s1_ctrl_2_1_v0Wen;
  assign io_toIntExu_2_1_bits_vlWen = s1_ctrl_2_1_vlWen;
  assign io_toIntExu_2_1_bits_fpu_typeTagOut = s1_ctrl_2_1_fpu_typeTagOut;
  assign io_toIntExu_2_1_bits_fpu_wflags = s1_ctrl_2_1_fpu_wflags;
  assign io_toIntExu_2_1_bits_fpu_typ = s1_ctrl_2_1_fpu_typ;
  assign io_toIntExu_2_1_bits_fpu_rm = s1_ctrl_2_1_fpu_rm;
  assign io_toIntExu_2_1_bits_preDecode_isRVC = s1_ctrl_2_1_preDecode_isRVC;
  assign io_toIntExu_2_1_bits_ftqIdx_flag = s1_ctrl_2_1_ftqIdx_flag;
  assign io_toIntExu_2_1_bits_ftqIdx_value = s1_ctrl_2_1_ftqIdx_value;
  assign io_toIntExu_2_1_bits_ftqOffset = s1_ctrl_2_1_ftqOffset;
  assign io_toIntExu_2_1_bits_predictInfo_taken = s1_ctrl_2_1_predictInfo_taken;
  assign io_toIntExu_2_1_bits_dataSources_0_value = s1_ctrl_2_1_dataSources_0_value;
  assign io_toIntExu_2_1_bits_dataSources_1_value = s1_ctrl_2_1_dataSources_1_value;
  assign io_toIntExu_2_1_bits_exuSources_0_value = s1_ctrl_2_1_exuSources_0_value;
  assign io_toIntExu_2_1_bits_exuSources_1_value = s1_ctrl_2_1_exuSources_1_value;
  assign io_toIntExu_2_1_bits_loadDependency_0 = s1_ctrl_2_1_loadDependency_0;
  assign io_toIntExu_2_1_bits_loadDependency_1 = s1_ctrl_2_1_loadDependency_1;
  assign io_toIntExu_2_1_bits_loadDependency_2 = s1_ctrl_2_1_loadDependency_2;
  assign io_toIntExu_2_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_2_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_2_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g3.0 -> IntExu_3_0 输出
  assign io_toIntExu_3_0_valid = s1_valid_3_0;
  assign io_toIntExu_3_0_bits_fuType = s1_ctrl_3_0_fuType;
  assign io_toIntExu_3_0_bits_fuOpType = s1_ctrl_3_0_fuOpType;
  assign io_toIntExu_3_0_bits_robIdx_flag = s1_ctrl_3_0_robIdx_flag;
  assign io_toIntExu_3_0_bits_robIdx_value = s1_ctrl_3_0_robIdx_value;
  assign io_toIntExu_3_0_bits_pdest = s1_ctrl_3_0_pdest;
  assign io_toIntExu_3_0_bits_rfWen = s1_ctrl_3_0_rfWen;
  assign io_toIntExu_3_0_bits_dataSources_0_value = s1_ctrl_3_0_dataSources_0_value;
  assign io_toIntExu_3_0_bits_dataSources_1_value = s1_ctrl_3_0_dataSources_1_value;
  assign io_toIntExu_3_0_bits_exuSources_0_value = s1_ctrl_3_0_exuSources_0_value;
  assign io_toIntExu_3_0_bits_exuSources_1_value = s1_ctrl_3_0_exuSources_1_value;
  assign io_toIntExu_3_0_bits_loadDependency_0 = s1_ctrl_3_0_loadDependency_0;
  assign io_toIntExu_3_0_bits_loadDependency_1 = s1_ctrl_3_0_loadDependency_1;
  assign io_toIntExu_3_0_bits_loadDependency_2 = s1_ctrl_3_0_loadDependency_2;
  assign io_toIntExu_3_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_3_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_3_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g3.1 -> IntExu_3_1 输出
  assign io_toIntExu_3_1_valid = s1_valid_3_1;
  assign io_toIntExu_3_1_bits_fuType = s1_ctrl_3_1_fuType;
  assign io_toIntExu_3_1_bits_fuOpType = s1_ctrl_3_1_fuOpType;
  assign io_toIntExu_3_1_bits_imm = s1_ctrl_3_1_imm;
  assign io_toIntExu_3_1_bits_robIdx_flag = s1_ctrl_3_1_robIdx_flag;
  assign io_toIntExu_3_1_bits_robIdx_value = s1_ctrl_3_1_robIdx_value;
  assign io_toIntExu_3_1_bits_pdest = s1_ctrl_3_1_pdest;
  assign io_toIntExu_3_1_bits_rfWen = s1_ctrl_3_1_rfWen;
  assign io_toIntExu_3_1_bits_flushPipe = s1_ctrl_3_1_flushPipe;
  assign io_toIntExu_3_1_bits_ftqIdx_flag = s1_ctrl_3_1_ftqIdx_flag;
  assign io_toIntExu_3_1_bits_ftqIdx_value = s1_ctrl_3_1_ftqIdx_value;
  assign io_toIntExu_3_1_bits_ftqOffset = s1_ctrl_3_1_ftqOffset;
  assign io_toIntExu_3_1_bits_dataSources_0_value = s1_ctrl_3_1_dataSources_0_value;
  assign io_toIntExu_3_1_bits_dataSources_1_value = s1_ctrl_3_1_dataSources_1_value;
  assign io_toIntExu_3_1_bits_exuSources_0_value = s1_ctrl_3_1_exuSources_0_value;
  assign io_toIntExu_3_1_bits_exuSources_1_value = s1_ctrl_3_1_exuSources_1_value;
  assign io_toIntExu_3_1_bits_loadDependency_0 = s1_ctrl_3_1_loadDependency_0;
  assign io_toIntExu_3_1_bits_loadDependency_1 = s1_ctrl_3_1_loadDependency_1;
  assign io_toIntExu_3_1_bits_loadDependency_2 = s1_ctrl_3_1_loadDependency_2;
  assign io_toIntExu_3_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toIntExu_3_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toIntExu_3_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g4.0 -> FpExu_0_0 输出
  assign io_toFpExu_0_0_valid = s1_valid_4_0;
  assign io_toFpExu_0_0_bits_fuType = s1_ctrl_4_0_fuType;
  assign io_toFpExu_0_0_bits_fuOpType = s1_ctrl_4_0_fuOpType;
  assign io_toFpExu_0_0_bits_robIdx_flag = s1_ctrl_4_0_robIdx_flag;
  assign io_toFpExu_0_0_bits_robIdx_value = s1_ctrl_4_0_robIdx_value;
  assign io_toFpExu_0_0_bits_pdest = s1_ctrl_4_0_pdest;
  assign io_toFpExu_0_0_bits_rfWen = s1_ctrl_4_0_rfWen;
  assign io_toFpExu_0_0_bits_fpWen = s1_ctrl_4_0_fpWen;
  assign io_toFpExu_0_0_bits_vecWen = s1_ctrl_4_0_vecWen;
  assign io_toFpExu_0_0_bits_v0Wen = s1_ctrl_4_0_v0Wen;
  assign io_toFpExu_0_0_bits_fpu_wflags = s1_ctrl_4_0_fpu_wflags;
  assign io_toFpExu_0_0_bits_fpu_fmt = s1_ctrl_4_0_fpu_fmt;
  assign io_toFpExu_0_0_bits_fpu_rm = s1_ctrl_4_0_fpu_rm;
  assign io_toFpExu_0_0_bits_dataSources_0_value = s1_ctrl_4_0_dataSources_0_value;
  assign io_toFpExu_0_0_bits_dataSources_1_value = s1_ctrl_4_0_dataSources_1_value;
  assign io_toFpExu_0_0_bits_dataSources_2_value = s1_ctrl_4_0_dataSources_2_value;
  assign io_toFpExu_0_0_bits_exuSources_0_value = s1_ctrl_4_0_exuSources_0_value;
  assign io_toFpExu_0_0_bits_exuSources_1_value = s1_ctrl_4_0_exuSources_1_value;
  assign io_toFpExu_0_0_bits_exuSources_2_value = s1_ctrl_4_0_exuSources_2_value;
  assign io_toFpExu_0_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toFpExu_0_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toFpExu_0_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g4.1 -> FpExu_0_1 输出
  assign io_toFpExu_0_1_valid = s1_valid_4_1;
  assign io_toFpExu_0_1_bits_fuType = s1_ctrl_4_1_fuType;
  assign io_toFpExu_0_1_bits_fuOpType = s1_ctrl_4_1_fuOpType;
  assign io_toFpExu_0_1_bits_robIdx_flag = s1_ctrl_4_1_robIdx_flag;
  assign io_toFpExu_0_1_bits_robIdx_value = s1_ctrl_4_1_robIdx_value;
  assign io_toFpExu_0_1_bits_pdest = s1_ctrl_4_1_pdest;
  assign io_toFpExu_0_1_bits_fpWen = s1_ctrl_4_1_fpWen;
  assign io_toFpExu_0_1_bits_fpu_wflags = s1_ctrl_4_1_fpu_wflags;
  assign io_toFpExu_0_1_bits_fpu_fmt = s1_ctrl_4_1_fpu_fmt;
  assign io_toFpExu_0_1_bits_fpu_rm = s1_ctrl_4_1_fpu_rm;
  assign io_toFpExu_0_1_bits_dataSources_0_value = s1_ctrl_4_1_dataSources_0_value;
  assign io_toFpExu_0_1_bits_dataSources_1_value = s1_ctrl_4_1_dataSources_1_value;
  assign io_toFpExu_0_1_bits_exuSources_0_value = s1_ctrl_4_1_exuSources_0_value;
  assign io_toFpExu_0_1_bits_exuSources_1_value = s1_ctrl_4_1_exuSources_1_value;
  assign io_toFpExu_0_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toFpExu_0_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toFpExu_0_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g5.0 -> FpExu_1_0 输出
  assign io_toFpExu_1_0_valid = s1_valid_5_0;
  assign io_toFpExu_1_0_bits_fuType = s1_ctrl_5_0_fuType;
  assign io_toFpExu_1_0_bits_fuOpType = s1_ctrl_5_0_fuOpType;
  assign io_toFpExu_1_0_bits_robIdx_flag = s1_ctrl_5_0_robIdx_flag;
  assign io_toFpExu_1_0_bits_robIdx_value = s1_ctrl_5_0_robIdx_value;
  assign io_toFpExu_1_0_bits_pdest = s1_ctrl_5_0_pdest;
  assign io_toFpExu_1_0_bits_rfWen = s1_ctrl_5_0_rfWen;
  assign io_toFpExu_1_0_bits_fpWen = s1_ctrl_5_0_fpWen;
  assign io_toFpExu_1_0_bits_fpu_wflags = s1_ctrl_5_0_fpu_wflags;
  assign io_toFpExu_1_0_bits_fpu_fmt = s1_ctrl_5_0_fpu_fmt;
  assign io_toFpExu_1_0_bits_fpu_rm = s1_ctrl_5_0_fpu_rm;
  assign io_toFpExu_1_0_bits_dataSources_0_value = s1_ctrl_5_0_dataSources_0_value;
  assign io_toFpExu_1_0_bits_dataSources_1_value = s1_ctrl_5_0_dataSources_1_value;
  assign io_toFpExu_1_0_bits_dataSources_2_value = s1_ctrl_5_0_dataSources_2_value;
  assign io_toFpExu_1_0_bits_exuSources_0_value = s1_ctrl_5_0_exuSources_0_value;
  assign io_toFpExu_1_0_bits_exuSources_1_value = s1_ctrl_5_0_exuSources_1_value;
  assign io_toFpExu_1_0_bits_exuSources_2_value = s1_ctrl_5_0_exuSources_2_value;
  assign io_toFpExu_1_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toFpExu_1_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toFpExu_1_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g5.1 -> FpExu_1_1 输出
  assign io_toFpExu_1_1_valid = s1_valid_5_1;
  assign io_toFpExu_1_1_bits_fuType = s1_ctrl_5_1_fuType;
  assign io_toFpExu_1_1_bits_fuOpType = s1_ctrl_5_1_fuOpType;
  assign io_toFpExu_1_1_bits_robIdx_flag = s1_ctrl_5_1_robIdx_flag;
  assign io_toFpExu_1_1_bits_robIdx_value = s1_ctrl_5_1_robIdx_value;
  assign io_toFpExu_1_1_bits_pdest = s1_ctrl_5_1_pdest;
  assign io_toFpExu_1_1_bits_fpWen = s1_ctrl_5_1_fpWen;
  assign io_toFpExu_1_1_bits_fpu_wflags = s1_ctrl_5_1_fpu_wflags;
  assign io_toFpExu_1_1_bits_fpu_fmt = s1_ctrl_5_1_fpu_fmt;
  assign io_toFpExu_1_1_bits_fpu_rm = s1_ctrl_5_1_fpu_rm;
  assign io_toFpExu_1_1_bits_dataSources_0_value = s1_ctrl_5_1_dataSources_0_value;
  assign io_toFpExu_1_1_bits_dataSources_1_value = s1_ctrl_5_1_dataSources_1_value;
  assign io_toFpExu_1_1_bits_exuSources_0_value = s1_ctrl_5_1_exuSources_0_value;
  assign io_toFpExu_1_1_bits_exuSources_1_value = s1_ctrl_5_1_exuSources_1_value;
  assign io_toFpExu_1_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toFpExu_1_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toFpExu_1_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g6.0 -> FpExu_2_0 输出
  assign io_toFpExu_2_0_valid = s1_valid_6_0;
  assign io_toFpExu_2_0_bits_fuType = s1_ctrl_6_0_fuType;
  assign io_toFpExu_2_0_bits_fuOpType = s1_ctrl_6_0_fuOpType;
  assign io_toFpExu_2_0_bits_robIdx_flag = s1_ctrl_6_0_robIdx_flag;
  assign io_toFpExu_2_0_bits_robIdx_value = s1_ctrl_6_0_robIdx_value;
  assign io_toFpExu_2_0_bits_pdest = s1_ctrl_6_0_pdest;
  assign io_toFpExu_2_0_bits_rfWen = s1_ctrl_6_0_rfWen;
  assign io_toFpExu_2_0_bits_fpWen = s1_ctrl_6_0_fpWen;
  assign io_toFpExu_2_0_bits_fpu_wflags = s1_ctrl_6_0_fpu_wflags;
  assign io_toFpExu_2_0_bits_fpu_fmt = s1_ctrl_6_0_fpu_fmt;
  assign io_toFpExu_2_0_bits_fpu_rm = s1_ctrl_6_0_fpu_rm;
  assign io_toFpExu_2_0_bits_dataSources_0_value = s1_ctrl_6_0_dataSources_0_value;
  assign io_toFpExu_2_0_bits_dataSources_1_value = s1_ctrl_6_0_dataSources_1_value;
  assign io_toFpExu_2_0_bits_dataSources_2_value = s1_ctrl_6_0_dataSources_2_value;
  assign io_toFpExu_2_0_bits_exuSources_0_value = s1_ctrl_6_0_exuSources_0_value;
  assign io_toFpExu_2_0_bits_exuSources_1_value = s1_ctrl_6_0_exuSources_1_value;
  assign io_toFpExu_2_0_bits_exuSources_2_value = s1_ctrl_6_0_exuSources_2_value;
  assign io_toFpExu_2_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toFpExu_2_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toFpExu_2_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g7.0 -> VecExu_0_0 输出
  assign io_toVecExu_0_0_valid = s1_valid_7_0;
  assign io_toVecExu_0_0_bits_fuType = s1_ctrl_7_0_fuType;
  assign io_toVecExu_0_0_bits_fuOpType = s1_ctrl_7_0_fuOpType;
  assign io_toVecExu_0_0_bits_robIdx_flag = s1_ctrl_7_0_robIdx_flag;
  assign io_toVecExu_0_0_bits_robIdx_value = s1_ctrl_7_0_robIdx_value;
  assign io_toVecExu_0_0_bits_pdest = s1_ctrl_7_0_pdest;
  assign io_toVecExu_0_0_bits_vecWen = s1_ctrl_7_0_vecWen;
  assign io_toVecExu_0_0_bits_v0Wen = s1_ctrl_7_0_v0Wen;
  assign io_toVecExu_0_0_bits_fpu_wflags = s1_ctrl_7_0_fpu_wflags;
  assign io_toVecExu_0_0_bits_vpu_vma = s1_ctrl_7_0_vpu_vma;
  assign io_toVecExu_0_0_bits_vpu_vta = s1_ctrl_7_0_vpu_vta;
  assign io_toVecExu_0_0_bits_vpu_vsew = s1_ctrl_7_0_vpu_vsew;
  assign io_toVecExu_0_0_bits_vpu_vlmul = s1_ctrl_7_0_vpu_vlmul;
  assign io_toVecExu_0_0_bits_vpu_vm = s1_ctrl_7_0_vpu_vm;
  assign io_toVecExu_0_0_bits_vpu_vstart = s1_ctrl_7_0_vpu_vstart;
  assign io_toVecExu_0_0_bits_vpu_vuopIdx = s1_ctrl_7_0_vpu_vuopIdx;
  assign io_toVecExu_0_0_bits_vpu_isExt = s1_ctrl_7_0_vpu_isExt;
  assign io_toVecExu_0_0_bits_vpu_isNarrow = s1_ctrl_7_0_vpu_isNarrow;
  assign io_toVecExu_0_0_bits_vpu_isDstMask = s1_ctrl_7_0_vpu_isDstMask;
  assign io_toVecExu_0_0_bits_vpu_isOpMask = s1_ctrl_7_0_vpu_isOpMask;
  assign io_toVecExu_0_0_bits_dataSources_0_value = s1_ctrl_7_0_dataSources_0_value;
  assign io_toVecExu_0_0_bits_dataSources_1_value = s1_ctrl_7_0_dataSources_1_value;
  assign io_toVecExu_0_0_bits_dataSources_2_value = s1_ctrl_7_0_dataSources_2_value;
  assign io_toVecExu_0_0_bits_dataSources_3_value = s1_ctrl_7_0_dataSources_3_value;
  assign io_toVecExu_0_0_bits_dataSources_4_value = s1_ctrl_7_0_dataSources_4_value;
  assign io_toVecExu_0_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toVecExu_0_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toVecExu_0_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g7.1 -> VecExu_0_1 输出
  assign io_toVecExu_0_1_valid = s1_valid_7_1;
  assign io_toVecExu_0_1_bits_fuType = s1_ctrl_7_1_fuType;
  assign io_toVecExu_0_1_bits_fuOpType = s1_ctrl_7_1_fuOpType;
  assign io_toVecExu_0_1_bits_robIdx_flag = s1_ctrl_7_1_robIdx_flag;
  assign io_toVecExu_0_1_bits_robIdx_value = s1_ctrl_7_1_robIdx_value;
  assign io_toVecExu_0_1_bits_pdest = s1_ctrl_7_1_pdest;
  assign io_toVecExu_0_1_bits_rfWen = s1_ctrl_7_1_rfWen;
  assign io_toVecExu_0_1_bits_fpWen = s1_ctrl_7_1_fpWen;
  assign io_toVecExu_0_1_bits_vecWen = s1_ctrl_7_1_vecWen;
  assign io_toVecExu_0_1_bits_v0Wen = s1_ctrl_7_1_v0Wen;
  assign io_toVecExu_0_1_bits_vlWen = s1_ctrl_7_1_vlWen;
  assign io_toVecExu_0_1_bits_fpu_wflags = s1_ctrl_7_1_fpu_wflags;
  assign io_toVecExu_0_1_bits_vpu_vma = s1_ctrl_7_1_vpu_vma;
  assign io_toVecExu_0_1_bits_vpu_vta = s1_ctrl_7_1_vpu_vta;
  assign io_toVecExu_0_1_bits_vpu_vsew = s1_ctrl_7_1_vpu_vsew;
  assign io_toVecExu_0_1_bits_vpu_vlmul = s1_ctrl_7_1_vpu_vlmul;
  assign io_toVecExu_0_1_bits_vpu_vm = s1_ctrl_7_1_vpu_vm;
  assign io_toVecExu_0_1_bits_vpu_vstart = s1_ctrl_7_1_vpu_vstart;
  assign io_toVecExu_0_1_bits_vpu_fpu_isFoldTo1_2 = s1_ctrl_7_1_vpu_fpu_isFoldTo1_2;
  assign io_toVecExu_0_1_bits_vpu_fpu_isFoldTo1_4 = s1_ctrl_7_1_vpu_fpu_isFoldTo1_4;
  assign io_toVecExu_0_1_bits_vpu_fpu_isFoldTo1_8 = s1_ctrl_7_1_vpu_fpu_isFoldTo1_8;
  assign io_toVecExu_0_1_bits_vpu_vuopIdx = s1_ctrl_7_1_vpu_vuopIdx;
  assign io_toVecExu_0_1_bits_vpu_lastUop = s1_ctrl_7_1_vpu_lastUop;
  assign io_toVecExu_0_1_bits_vpu_isNarrow = s1_ctrl_7_1_vpu_isNarrow;
  assign io_toVecExu_0_1_bits_vpu_isDstMask = s1_ctrl_7_1_vpu_isDstMask;
  assign io_toVecExu_0_1_bits_dataSources_0_value = s1_ctrl_7_1_dataSources_0_value;
  assign io_toVecExu_0_1_bits_dataSources_1_value = s1_ctrl_7_1_dataSources_1_value;
  assign io_toVecExu_0_1_bits_dataSources_2_value = s1_ctrl_7_1_dataSources_2_value;
  assign io_toVecExu_0_1_bits_dataSources_3_value = s1_ctrl_7_1_dataSources_3_value;
  assign io_toVecExu_0_1_bits_dataSources_4_value = s1_ctrl_7_1_dataSources_4_value;
  assign io_toVecExu_0_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toVecExu_0_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toVecExu_0_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g8.0 -> VecExu_1_0 输出
  assign io_toVecExu_1_0_valid = s1_valid_8_0;
  assign io_toVecExu_1_0_bits_fuType = s1_ctrl_8_0_fuType;
  assign io_toVecExu_1_0_bits_fuOpType = s1_ctrl_8_0_fuOpType;
  assign io_toVecExu_1_0_bits_robIdx_flag = s1_ctrl_8_0_robIdx_flag;
  assign io_toVecExu_1_0_bits_robIdx_value = s1_ctrl_8_0_robIdx_value;
  assign io_toVecExu_1_0_bits_pdest = s1_ctrl_8_0_pdest;
  assign io_toVecExu_1_0_bits_vecWen = s1_ctrl_8_0_vecWen;
  assign io_toVecExu_1_0_bits_v0Wen = s1_ctrl_8_0_v0Wen;
  assign io_toVecExu_1_0_bits_fpu_wflags = s1_ctrl_8_0_fpu_wflags;
  assign io_toVecExu_1_0_bits_vpu_vma = s1_ctrl_8_0_vpu_vma;
  assign io_toVecExu_1_0_bits_vpu_vta = s1_ctrl_8_0_vpu_vta;
  assign io_toVecExu_1_0_bits_vpu_vsew = s1_ctrl_8_0_vpu_vsew;
  assign io_toVecExu_1_0_bits_vpu_vlmul = s1_ctrl_8_0_vpu_vlmul;
  assign io_toVecExu_1_0_bits_vpu_vm = s1_ctrl_8_0_vpu_vm;
  assign io_toVecExu_1_0_bits_vpu_vstart = s1_ctrl_8_0_vpu_vstart;
  assign io_toVecExu_1_0_bits_vpu_vuopIdx = s1_ctrl_8_0_vpu_vuopIdx;
  assign io_toVecExu_1_0_bits_vpu_isExt = s1_ctrl_8_0_vpu_isExt;
  assign io_toVecExu_1_0_bits_vpu_isNarrow = s1_ctrl_8_0_vpu_isNarrow;
  assign io_toVecExu_1_0_bits_vpu_isDstMask = s1_ctrl_8_0_vpu_isDstMask;
  assign io_toVecExu_1_0_bits_vpu_isOpMask = s1_ctrl_8_0_vpu_isOpMask;
  assign io_toVecExu_1_0_bits_dataSources_0_value = s1_ctrl_8_0_dataSources_0_value;
  assign io_toVecExu_1_0_bits_dataSources_1_value = s1_ctrl_8_0_dataSources_1_value;
  assign io_toVecExu_1_0_bits_dataSources_2_value = s1_ctrl_8_0_dataSources_2_value;
  assign io_toVecExu_1_0_bits_dataSources_3_value = s1_ctrl_8_0_dataSources_3_value;
  assign io_toVecExu_1_0_bits_dataSources_4_value = s1_ctrl_8_0_dataSources_4_value;
  assign io_toVecExu_1_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toVecExu_1_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toVecExu_1_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g8.1 -> VecExu_1_1 输出
  assign io_toVecExu_1_1_valid = s1_valid_8_1;
  assign io_toVecExu_1_1_bits_fuType = s1_ctrl_8_1_fuType;
  assign io_toVecExu_1_1_bits_fuOpType = s1_ctrl_8_1_fuOpType;
  assign io_toVecExu_1_1_bits_robIdx_flag = s1_ctrl_8_1_robIdx_flag;
  assign io_toVecExu_1_1_bits_robIdx_value = s1_ctrl_8_1_robIdx_value;
  assign io_toVecExu_1_1_bits_pdest = s1_ctrl_8_1_pdest;
  assign io_toVecExu_1_1_bits_fpWen = s1_ctrl_8_1_fpWen;
  assign io_toVecExu_1_1_bits_vecWen = s1_ctrl_8_1_vecWen;
  assign io_toVecExu_1_1_bits_v0Wen = s1_ctrl_8_1_v0Wen;
  assign io_toVecExu_1_1_bits_fpu_wflags = s1_ctrl_8_1_fpu_wflags;
  assign io_toVecExu_1_1_bits_vpu_vma = s1_ctrl_8_1_vpu_vma;
  assign io_toVecExu_1_1_bits_vpu_vta = s1_ctrl_8_1_vpu_vta;
  assign io_toVecExu_1_1_bits_vpu_vsew = s1_ctrl_8_1_vpu_vsew;
  assign io_toVecExu_1_1_bits_vpu_vlmul = s1_ctrl_8_1_vpu_vlmul;
  assign io_toVecExu_1_1_bits_vpu_vm = s1_ctrl_8_1_vpu_vm;
  assign io_toVecExu_1_1_bits_vpu_vstart = s1_ctrl_8_1_vpu_vstart;
  assign io_toVecExu_1_1_bits_vpu_fpu_isFoldTo1_2 = s1_ctrl_8_1_vpu_fpu_isFoldTo1_2;
  assign io_toVecExu_1_1_bits_vpu_fpu_isFoldTo1_4 = s1_ctrl_8_1_vpu_fpu_isFoldTo1_4;
  assign io_toVecExu_1_1_bits_vpu_fpu_isFoldTo1_8 = s1_ctrl_8_1_vpu_fpu_isFoldTo1_8;
  assign io_toVecExu_1_1_bits_vpu_vuopIdx = s1_ctrl_8_1_vpu_vuopIdx;
  assign io_toVecExu_1_1_bits_vpu_lastUop = s1_ctrl_8_1_vpu_lastUop;
  assign io_toVecExu_1_1_bits_vpu_isNarrow = s1_ctrl_8_1_vpu_isNarrow;
  assign io_toVecExu_1_1_bits_vpu_isDstMask = s1_ctrl_8_1_vpu_isDstMask;
  assign io_toVecExu_1_1_bits_dataSources_0_value = s1_ctrl_8_1_dataSources_0_value;
  assign io_toVecExu_1_1_bits_dataSources_1_value = s1_ctrl_8_1_dataSources_1_value;
  assign io_toVecExu_1_1_bits_dataSources_2_value = s1_ctrl_8_1_dataSources_2_value;
  assign io_toVecExu_1_1_bits_dataSources_3_value = s1_ctrl_8_1_dataSources_3_value;
  assign io_toVecExu_1_1_bits_dataSources_4_value = s1_ctrl_8_1_dataSources_4_value;
  assign io_toVecExu_1_1_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toVecExu_1_1_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toVecExu_1_1_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g9.0 -> VecExu_2_0 输出
  assign io_toVecExu_2_0_valid = s1_valid_9_0;
  assign io_toVecExu_2_0_bits_fuType = s1_ctrl_9_0_fuType;
  assign io_toVecExu_2_0_bits_fuOpType = s1_ctrl_9_0_fuOpType;
  assign io_toVecExu_2_0_bits_robIdx_flag = s1_ctrl_9_0_robIdx_flag;
  assign io_toVecExu_2_0_bits_robIdx_value = s1_ctrl_9_0_robIdx_value;
  assign io_toVecExu_2_0_bits_pdest = s1_ctrl_9_0_pdest;
  assign io_toVecExu_2_0_bits_vecWen = s1_ctrl_9_0_vecWen;
  assign io_toVecExu_2_0_bits_v0Wen = s1_ctrl_9_0_v0Wen;
  assign io_toVecExu_2_0_bits_fpu_wflags = s1_ctrl_9_0_fpu_wflags;
  assign io_toVecExu_2_0_bits_vpu_vma = s1_ctrl_9_0_vpu_vma;
  assign io_toVecExu_2_0_bits_vpu_vta = s1_ctrl_9_0_vpu_vta;
  assign io_toVecExu_2_0_bits_vpu_vsew = s1_ctrl_9_0_vpu_vsew;
  assign io_toVecExu_2_0_bits_vpu_vlmul = s1_ctrl_9_0_vpu_vlmul;
  assign io_toVecExu_2_0_bits_vpu_vm = s1_ctrl_9_0_vpu_vm;
  assign io_toVecExu_2_0_bits_vpu_vstart = s1_ctrl_9_0_vpu_vstart;
  assign io_toVecExu_2_0_bits_vpu_vuopIdx = s1_ctrl_9_0_vpu_vuopIdx;
  assign io_toVecExu_2_0_bits_vpu_isExt = s1_ctrl_9_0_vpu_isExt;
  assign io_toVecExu_2_0_bits_vpu_isNarrow = s1_ctrl_9_0_vpu_isNarrow;
  assign io_toVecExu_2_0_bits_vpu_isDstMask = s1_ctrl_9_0_vpu_isDstMask;
  assign io_toVecExu_2_0_bits_vpu_isOpMask = s1_ctrl_9_0_vpu_isOpMask;
  assign io_toVecExu_2_0_bits_dataSources_0_value = s1_ctrl_9_0_dataSources_0_value;
  assign io_toVecExu_2_0_bits_dataSources_1_value = s1_ctrl_9_0_dataSources_1_value;
  assign io_toVecExu_2_0_bits_dataSources_2_value = s1_ctrl_9_0_dataSources_2_value;
  assign io_toVecExu_2_0_bits_dataSources_3_value = s1_ctrl_9_0_dataSources_3_value;
  assign io_toVecExu_2_0_bits_dataSources_4_value = s1_ctrl_9_0_dataSources_4_value;
  assign io_toVecExu_2_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toVecExu_2_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toVecExu_2_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g10.0 -> MemExu_0_0 输出
  assign io_toMemExu_0_0_valid = s1_valid_10_0;
  assign io_toMemExu_0_0_bits_fuType = s1_ctrl_10_0_fuType;
  assign io_toMemExu_0_0_bits_fuOpType = s1_ctrl_10_0_fuOpType;
  assign io_toMemExu_0_0_bits_imm = s1_ctrl_10_0_imm;
  assign io_toMemExu_0_0_bits_robIdx_flag = s1_ctrl_10_0_robIdx_flag;
  assign io_toMemExu_0_0_bits_robIdx_value = s1_ctrl_10_0_robIdx_value;
  assign io_toMemExu_0_0_bits_isFirstIssue = s1_ctrl_10_0_isFirstIssue;
  assign io_toMemExu_0_0_bits_pdest = s1_ctrl_10_0_pdest;
  assign io_toMemExu_0_0_bits_rfWen = s1_ctrl_10_0_rfWen;
  assign io_toMemExu_0_0_bits_ftqIdx_value = s1_ctrl_10_0_ftqIdx_value;
  assign io_toMemExu_0_0_bits_ftqOffset = s1_ctrl_10_0_ftqOffset;
  assign io_toMemExu_0_0_bits_sqIdx_flag = s1_ctrl_10_0_sqIdx_flag;
  assign io_toMemExu_0_0_bits_sqIdx_value = s1_ctrl_10_0_sqIdx_value;
  assign io_toMemExu_0_0_bits_dataSources_0_value = s1_ctrl_10_0_dataSources_0_value;
  assign io_toMemExu_0_0_bits_exuSources_0_value = s1_ctrl_10_0_exuSources_0_value;
  assign io_toMemExu_0_0_bits_loadDependency_0 = s1_ctrl_10_0_loadDependency_0;
  assign io_toMemExu_0_0_bits_loadDependency_1 = s1_ctrl_10_0_loadDependency_1;
  assign io_toMemExu_0_0_bits_loadDependency_2 = s1_ctrl_10_0_loadDependency_2;
  assign io_toMemExu_0_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_0_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_0_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g11.0 -> MemExu_1_0 输出
  assign io_toMemExu_1_0_valid = s1_valid_11_0;
  assign io_toMemExu_1_0_bits_fuType = s1_ctrl_11_0_fuType;
  assign io_toMemExu_1_0_bits_fuOpType = s1_ctrl_11_0_fuOpType;
  assign io_toMemExu_1_0_bits_imm = s1_ctrl_11_0_imm;
  assign io_toMemExu_1_0_bits_robIdx_flag = s1_ctrl_11_0_robIdx_flag;
  assign io_toMemExu_1_0_bits_robIdx_value = s1_ctrl_11_0_robIdx_value;
  assign io_toMemExu_1_0_bits_isFirstIssue = s1_ctrl_11_0_isFirstIssue;
  assign io_toMemExu_1_0_bits_pdest = s1_ctrl_11_0_pdest;
  assign io_toMemExu_1_0_bits_rfWen = s1_ctrl_11_0_rfWen;
  assign io_toMemExu_1_0_bits_ftqIdx_value = s1_ctrl_11_0_ftqIdx_value;
  assign io_toMemExu_1_0_bits_ftqOffset = s1_ctrl_11_0_ftqOffset;
  assign io_toMemExu_1_0_bits_sqIdx_flag = s1_ctrl_11_0_sqIdx_flag;
  assign io_toMemExu_1_0_bits_sqIdx_value = s1_ctrl_11_0_sqIdx_value;
  assign io_toMemExu_1_0_bits_dataSources_0_value = s1_ctrl_11_0_dataSources_0_value;
  assign io_toMemExu_1_0_bits_exuSources_0_value = s1_ctrl_11_0_exuSources_0_value;
  assign io_toMemExu_1_0_bits_loadDependency_0 = s1_ctrl_11_0_loadDependency_0;
  assign io_toMemExu_1_0_bits_loadDependency_1 = s1_ctrl_11_0_loadDependency_1;
  assign io_toMemExu_1_0_bits_loadDependency_2 = s1_ctrl_11_0_loadDependency_2;
  assign io_toMemExu_1_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_1_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_1_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g12.0 -> MemExu_2_0 输出
  assign io_toMemExu_2_0_valid = s1_valid_12_0;
  assign io_toMemExu_2_0_bits_fuType = s1_ctrl_12_0_fuType;
  assign io_toMemExu_2_0_bits_fuOpType = s1_ctrl_12_0_fuOpType;
  assign io_toMemExu_2_0_bits_imm = s1_ctrl_12_0_imm;
  assign io_toMemExu_2_0_bits_robIdx_flag = s1_ctrl_12_0_robIdx_flag;
  assign io_toMemExu_2_0_bits_robIdx_value = s1_ctrl_12_0_robIdx_value;
  assign io_toMemExu_2_0_bits_pdest = s1_ctrl_12_0_pdest;
  assign io_toMemExu_2_0_bits_rfWen = s1_ctrl_12_0_rfWen;
  assign io_toMemExu_2_0_bits_fpWen = s1_ctrl_12_0_fpWen;
  assign io_toMemExu_2_0_bits_preDecode_isRVC = s1_ctrl_12_0_preDecode_isRVC;
  assign io_toMemExu_2_0_bits_ftqIdx_flag = s1_ctrl_12_0_ftqIdx_flag;
  assign io_toMemExu_2_0_bits_ftqIdx_value = s1_ctrl_12_0_ftqIdx_value;
  assign io_toMemExu_2_0_bits_ftqOffset = s1_ctrl_12_0_ftqOffset;
  assign io_toMemExu_2_0_bits_loadWaitBit = s1_ctrl_12_0_loadWaitBit;
  assign io_toMemExu_2_0_bits_waitForRobIdx_flag = s1_ctrl_12_0_waitForRobIdx_flag;
  assign io_toMemExu_2_0_bits_waitForRobIdx_value = s1_ctrl_12_0_waitForRobIdx_value;
  assign io_toMemExu_2_0_bits_storeSetHit = s1_ctrl_12_0_storeSetHit;
  assign io_toMemExu_2_0_bits_loadWaitStrict = s1_ctrl_12_0_loadWaitStrict;
  assign io_toMemExu_2_0_bits_sqIdx_flag = s1_ctrl_12_0_sqIdx_flag;
  assign io_toMemExu_2_0_bits_sqIdx_value = s1_ctrl_12_0_sqIdx_value;
  assign io_toMemExu_2_0_bits_lqIdx_flag = s1_ctrl_12_0_lqIdx_flag;
  assign io_toMemExu_2_0_bits_lqIdx_value = s1_ctrl_12_0_lqIdx_value;
  assign io_toMemExu_2_0_bits_dataSources_0_value = s1_ctrl_12_0_dataSources_0_value;
  assign io_toMemExu_2_0_bits_exuSources_0_value = s1_ctrl_12_0_exuSources_0_value;
  assign io_toMemExu_2_0_bits_loadDependency_0 = s1_ctrl_12_0_loadDependency_0;
  assign io_toMemExu_2_0_bits_loadDependency_1 = s1_ctrl_12_0_loadDependency_1;
  assign io_toMemExu_2_0_bits_loadDependency_2 = s1_ctrl_12_0_loadDependency_2;
  assign io_toMemExu_2_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_2_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_2_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g13.0 -> MemExu_3_0 输出
  assign io_toMemExu_3_0_valid = s1_valid_13_0;
  assign io_toMemExu_3_0_bits_fuType = s1_ctrl_13_0_fuType;
  assign io_toMemExu_3_0_bits_fuOpType = s1_ctrl_13_0_fuOpType;
  assign io_toMemExu_3_0_bits_imm = s1_ctrl_13_0_imm;
  assign io_toMemExu_3_0_bits_robIdx_flag = s1_ctrl_13_0_robIdx_flag;
  assign io_toMemExu_3_0_bits_robIdx_value = s1_ctrl_13_0_robIdx_value;
  assign io_toMemExu_3_0_bits_pdest = s1_ctrl_13_0_pdest;
  assign io_toMemExu_3_0_bits_rfWen = s1_ctrl_13_0_rfWen;
  assign io_toMemExu_3_0_bits_fpWen = s1_ctrl_13_0_fpWen;
  assign io_toMemExu_3_0_bits_preDecode_isRVC = s1_ctrl_13_0_preDecode_isRVC;
  assign io_toMemExu_3_0_bits_ftqIdx_flag = s1_ctrl_13_0_ftqIdx_flag;
  assign io_toMemExu_3_0_bits_ftqIdx_value = s1_ctrl_13_0_ftqIdx_value;
  assign io_toMemExu_3_0_bits_ftqOffset = s1_ctrl_13_0_ftqOffset;
  assign io_toMemExu_3_0_bits_loadWaitBit = s1_ctrl_13_0_loadWaitBit;
  assign io_toMemExu_3_0_bits_waitForRobIdx_flag = s1_ctrl_13_0_waitForRobIdx_flag;
  assign io_toMemExu_3_0_bits_waitForRobIdx_value = s1_ctrl_13_0_waitForRobIdx_value;
  assign io_toMemExu_3_0_bits_storeSetHit = s1_ctrl_13_0_storeSetHit;
  assign io_toMemExu_3_0_bits_loadWaitStrict = s1_ctrl_13_0_loadWaitStrict;
  assign io_toMemExu_3_0_bits_sqIdx_flag = s1_ctrl_13_0_sqIdx_flag;
  assign io_toMemExu_3_0_bits_sqIdx_value = s1_ctrl_13_0_sqIdx_value;
  assign io_toMemExu_3_0_bits_lqIdx_flag = s1_ctrl_13_0_lqIdx_flag;
  assign io_toMemExu_3_0_bits_lqIdx_value = s1_ctrl_13_0_lqIdx_value;
  assign io_toMemExu_3_0_bits_dataSources_0_value = s1_ctrl_13_0_dataSources_0_value;
  assign io_toMemExu_3_0_bits_exuSources_0_value = s1_ctrl_13_0_exuSources_0_value;
  assign io_toMemExu_3_0_bits_loadDependency_0 = s1_ctrl_13_0_loadDependency_0;
  assign io_toMemExu_3_0_bits_loadDependency_1 = s1_ctrl_13_0_loadDependency_1;
  assign io_toMemExu_3_0_bits_loadDependency_2 = s1_ctrl_13_0_loadDependency_2;
  assign io_toMemExu_3_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_3_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_3_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g14.0 -> MemExu_4_0 输出
  assign io_toMemExu_4_0_valid = s1_valid_14_0;
  assign io_toMemExu_4_0_bits_fuType = s1_ctrl_14_0_fuType;
  assign io_toMemExu_4_0_bits_fuOpType = s1_ctrl_14_0_fuOpType;
  assign io_toMemExu_4_0_bits_imm = s1_ctrl_14_0_imm;
  assign io_toMemExu_4_0_bits_robIdx_flag = s1_ctrl_14_0_robIdx_flag;
  assign io_toMemExu_4_0_bits_robIdx_value = s1_ctrl_14_0_robIdx_value;
  assign io_toMemExu_4_0_bits_pdest = s1_ctrl_14_0_pdest;
  assign io_toMemExu_4_0_bits_rfWen = s1_ctrl_14_0_rfWen;
  assign io_toMemExu_4_0_bits_fpWen = s1_ctrl_14_0_fpWen;
  assign io_toMemExu_4_0_bits_preDecode_isRVC = s1_ctrl_14_0_preDecode_isRVC;
  assign io_toMemExu_4_0_bits_ftqIdx_flag = s1_ctrl_14_0_ftqIdx_flag;
  assign io_toMemExu_4_0_bits_ftqIdx_value = s1_ctrl_14_0_ftqIdx_value;
  assign io_toMemExu_4_0_bits_ftqOffset = s1_ctrl_14_0_ftqOffset;
  assign io_toMemExu_4_0_bits_loadWaitBit = s1_ctrl_14_0_loadWaitBit;
  assign io_toMemExu_4_0_bits_waitForRobIdx_flag = s1_ctrl_14_0_waitForRobIdx_flag;
  assign io_toMemExu_4_0_bits_waitForRobIdx_value = s1_ctrl_14_0_waitForRobIdx_value;
  assign io_toMemExu_4_0_bits_storeSetHit = s1_ctrl_14_0_storeSetHit;
  assign io_toMemExu_4_0_bits_loadWaitStrict = s1_ctrl_14_0_loadWaitStrict;
  assign io_toMemExu_4_0_bits_sqIdx_flag = s1_ctrl_14_0_sqIdx_flag;
  assign io_toMemExu_4_0_bits_sqIdx_value = s1_ctrl_14_0_sqIdx_value;
  assign io_toMemExu_4_0_bits_lqIdx_flag = s1_ctrl_14_0_lqIdx_flag;
  assign io_toMemExu_4_0_bits_lqIdx_value = s1_ctrl_14_0_lqIdx_value;
  assign io_toMemExu_4_0_bits_dataSources_0_value = s1_ctrl_14_0_dataSources_0_value;
  assign io_toMemExu_4_0_bits_exuSources_0_value = s1_ctrl_14_0_exuSources_0_value;
  assign io_toMemExu_4_0_bits_loadDependency_0 = s1_ctrl_14_0_loadDependency_0;
  assign io_toMemExu_4_0_bits_loadDependency_1 = s1_ctrl_14_0_loadDependency_1;
  assign io_toMemExu_4_0_bits_loadDependency_2 = s1_ctrl_14_0_loadDependency_2;
  assign io_toMemExu_4_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_4_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_4_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g15.0 -> MemExu_5_0 输出
  assign io_toMemExu_5_0_valid = s1_valid_15_0;
  assign io_toMemExu_5_0_bits_fuType = s1_ctrl_15_0_fuType;
  assign io_toMemExu_5_0_bits_fuOpType = s1_ctrl_15_0_fuOpType;
  assign io_toMemExu_5_0_bits_robIdx_flag = s1_ctrl_15_0_robIdx_flag;
  assign io_toMemExu_5_0_bits_robIdx_value = s1_ctrl_15_0_robIdx_value;
  assign io_toMemExu_5_0_bits_pdest = s1_ctrl_15_0_pdest;
  assign io_toMemExu_5_0_bits_vecWen = s1_ctrl_15_0_vecWen;
  assign io_toMemExu_5_0_bits_v0Wen = s1_ctrl_15_0_v0Wen;
  assign io_toMemExu_5_0_bits_vlWen = s1_ctrl_15_0_vlWen;
  assign io_toMemExu_5_0_bits_vpu_vma = s1_ctrl_15_0_vpu_vma;
  assign io_toMemExu_5_0_bits_vpu_vta = s1_ctrl_15_0_vpu_vta;
  assign io_toMemExu_5_0_bits_vpu_vsew = s1_ctrl_15_0_vpu_vsew;
  assign io_toMemExu_5_0_bits_vpu_vlmul = s1_ctrl_15_0_vpu_vlmul;
  assign io_toMemExu_5_0_bits_vpu_vm = s1_ctrl_15_0_vpu_vm;
  assign io_toMemExu_5_0_bits_vpu_vstart = s1_ctrl_15_0_vpu_vstart;
  assign io_toMemExu_5_0_bits_vpu_vuopIdx = s1_ctrl_15_0_vpu_vuopIdx;
  assign io_toMemExu_5_0_bits_vpu_lastUop = s1_ctrl_15_0_vpu_lastUop;
  assign io_toMemExu_5_0_bits_vpu_vmask = s1_ctrl_15_0_vpu_vmask;
  assign io_toMemExu_5_0_bits_vpu_nf = s1_ctrl_15_0_vpu_nf;
  assign io_toMemExu_5_0_bits_vpu_veew = s1_ctrl_15_0_vpu_veew;
  assign io_toMemExu_5_0_bits_vpu_isVleff = s1_ctrl_15_0_vpu_isVleff;
  assign io_toMemExu_5_0_bits_ftqIdx_flag = s1_ctrl_15_0_ftqIdx_flag;
  assign io_toMemExu_5_0_bits_ftqIdx_value = s1_ctrl_15_0_ftqIdx_value;
  assign io_toMemExu_5_0_bits_ftqOffset = s1_ctrl_15_0_ftqOffset;
  assign io_toMemExu_5_0_bits_numLsElem = s1_ctrl_15_0_numLsElem;
  assign io_toMemExu_5_0_bits_sqIdx_flag = s1_ctrl_15_0_sqIdx_flag;
  assign io_toMemExu_5_0_bits_sqIdx_value = s1_ctrl_15_0_sqIdx_value;
  assign io_toMemExu_5_0_bits_lqIdx_flag = s1_ctrl_15_0_lqIdx_flag;
  assign io_toMemExu_5_0_bits_lqIdx_value = s1_ctrl_15_0_lqIdx_value;
  assign io_toMemExu_5_0_bits_dataSources_0_value = s1_ctrl_15_0_dataSources_0_value;
  assign io_toMemExu_5_0_bits_dataSources_1_value = s1_ctrl_15_0_dataSources_1_value;
  assign io_toMemExu_5_0_bits_dataSources_2_value = s1_ctrl_15_0_dataSources_2_value;
  assign io_toMemExu_5_0_bits_dataSources_3_value = s1_ctrl_15_0_dataSources_3_value;
  assign io_toMemExu_5_0_bits_dataSources_4_value = s1_ctrl_15_0_dataSources_4_value;
  assign io_toMemExu_5_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_5_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_5_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g16.0 -> MemExu_6_0 输出
  assign io_toMemExu_6_0_valid = s1_valid_16_0;
  assign io_toMemExu_6_0_bits_fuType = s1_ctrl_16_0_fuType;
  assign io_toMemExu_6_0_bits_fuOpType = s1_ctrl_16_0_fuOpType;
  assign io_toMemExu_6_0_bits_robIdx_flag = s1_ctrl_16_0_robIdx_flag;
  assign io_toMemExu_6_0_bits_robIdx_value = s1_ctrl_16_0_robIdx_value;
  assign io_toMemExu_6_0_bits_pdest = s1_ctrl_16_0_pdest;
  assign io_toMemExu_6_0_bits_vecWen = s1_ctrl_16_0_vecWen;
  assign io_toMemExu_6_0_bits_v0Wen = s1_ctrl_16_0_v0Wen;
  assign io_toMemExu_6_0_bits_vlWen = s1_ctrl_16_0_vlWen;
  assign io_toMemExu_6_0_bits_vpu_vma = s1_ctrl_16_0_vpu_vma;
  assign io_toMemExu_6_0_bits_vpu_vta = s1_ctrl_16_0_vpu_vta;
  assign io_toMemExu_6_0_bits_vpu_vsew = s1_ctrl_16_0_vpu_vsew;
  assign io_toMemExu_6_0_bits_vpu_vlmul = s1_ctrl_16_0_vpu_vlmul;
  assign io_toMemExu_6_0_bits_vpu_vm = s1_ctrl_16_0_vpu_vm;
  assign io_toMemExu_6_0_bits_vpu_vstart = s1_ctrl_16_0_vpu_vstart;
  assign io_toMemExu_6_0_bits_vpu_vuopIdx = s1_ctrl_16_0_vpu_vuopIdx;
  assign io_toMemExu_6_0_bits_vpu_lastUop = s1_ctrl_16_0_vpu_lastUop;
  assign io_toMemExu_6_0_bits_vpu_vmask = s1_ctrl_16_0_vpu_vmask;
  assign io_toMemExu_6_0_bits_vpu_nf = s1_ctrl_16_0_vpu_nf;
  assign io_toMemExu_6_0_bits_vpu_veew = s1_ctrl_16_0_vpu_veew;
  assign io_toMemExu_6_0_bits_vpu_isVleff = s1_ctrl_16_0_vpu_isVleff;
  assign io_toMemExu_6_0_bits_ftqIdx_flag = s1_ctrl_16_0_ftqIdx_flag;
  assign io_toMemExu_6_0_bits_ftqIdx_value = s1_ctrl_16_0_ftqIdx_value;
  assign io_toMemExu_6_0_bits_ftqOffset = s1_ctrl_16_0_ftqOffset;
  assign io_toMemExu_6_0_bits_numLsElem = s1_ctrl_16_0_numLsElem;
  assign io_toMemExu_6_0_bits_sqIdx_flag = s1_ctrl_16_0_sqIdx_flag;
  assign io_toMemExu_6_0_bits_sqIdx_value = s1_ctrl_16_0_sqIdx_value;
  assign io_toMemExu_6_0_bits_lqIdx_flag = s1_ctrl_16_0_lqIdx_flag;
  assign io_toMemExu_6_0_bits_lqIdx_value = s1_ctrl_16_0_lqIdx_value;
  assign io_toMemExu_6_0_bits_dataSources_0_value = s1_ctrl_16_0_dataSources_0_value;
  assign io_toMemExu_6_0_bits_dataSources_1_value = s1_ctrl_16_0_dataSources_1_value;
  assign io_toMemExu_6_0_bits_dataSources_2_value = s1_ctrl_16_0_dataSources_2_value;
  assign io_toMemExu_6_0_bits_dataSources_3_value = s1_ctrl_16_0_dataSources_3_value;
  assign io_toMemExu_6_0_bits_dataSources_4_value = s1_ctrl_16_0_dataSources_4_value;
  assign io_toMemExu_6_0_bits_perfDebugInfo_enqRsTime = 64'h0;
  assign io_toMemExu_6_0_bits_perfDebugInfo_selectTime = 64'h0;
  assign io_toMemExu_6_0_bits_perfDebugInfo_issueTime = 64'h0;

  // EXU g17.0 -> MemExu_7_0 输出
  assign io_toMemExu_7_0_valid = s1_valid_17_0;
  assign io_toMemExu_7_0_bits_fuType = s1_ctrl_17_0_fuType;
  assign io_toMemExu_7_0_bits_fuOpType = s1_ctrl_17_0_fuOpType;
  assign io_toMemExu_7_0_bits_robIdx_flag = s1_ctrl_17_0_robIdx_flag;
  assign io_toMemExu_7_0_bits_robIdx_value = s1_ctrl_17_0_robIdx_value;
  assign io_toMemExu_7_0_bits_sqIdx_flag = s1_ctrl_17_0_sqIdx_flag;
  assign io_toMemExu_7_0_bits_sqIdx_value = s1_ctrl_17_0_sqIdx_value;
  assign io_toMemExu_7_0_bits_dataSources_0_value = s1_ctrl_17_0_dataSources_0_value;
  assign io_toMemExu_7_0_bits_exuSources_0_value = s1_ctrl_17_0_exuSources_0_value;
  assign io_toMemExu_7_0_bits_loadDependency_0 = s1_ctrl_17_0_loadDependency_0;
  assign io_toMemExu_7_0_bits_loadDependency_1 = s1_ctrl_17_0_loadDependency_1;
  assign io_toMemExu_7_0_bits_loadDependency_2 = s1_ctrl_17_0_loadDependency_2;

  // EXU g18.0 -> MemExu_8_0 输出
  assign io_toMemExu_8_0_valid = s1_valid_18_0;
  assign io_toMemExu_8_0_bits_fuType = s1_ctrl_18_0_fuType;
  assign io_toMemExu_8_0_bits_fuOpType = s1_ctrl_18_0_fuOpType;
  assign io_toMemExu_8_0_bits_robIdx_flag = s1_ctrl_18_0_robIdx_flag;
  assign io_toMemExu_8_0_bits_robIdx_value = s1_ctrl_18_0_robIdx_value;
  assign io_toMemExu_8_0_bits_sqIdx_flag = s1_ctrl_18_0_sqIdx_flag;
  assign io_toMemExu_8_0_bits_sqIdx_value = s1_ctrl_18_0_sqIdx_value;
  assign io_toMemExu_8_0_bits_dataSources_0_value = s1_ctrl_18_0_dataSources_0_value;
  assign io_toMemExu_8_0_bits_exuSources_0_value = s1_ctrl_18_0_exuSources_0_value;
  assign io_toMemExu_8_0_bits_loadDependency_0 = s1_ctrl_18_0_loadDependency_0;
  assign io_toMemExu_8_0_bits_loadDependency_1 = s1_ctrl_18_0_loadDependency_1;
  assign io_toMemExu_8_0_bits_loadDependency_2 = s1_ctrl_18_0_loadDependency_2;

// === 数据流 5:RegCache 读请求 ===
//   ren = IQ.valid & 该源 dataSources.readRegCache,addr = uop.rcIdx[src];
//   RegCache(黑盒)读数据(内部已寄到 s1)直送 BypassNetwork。
  assign rc_ren_0  = io_fromIntIQ_0_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_0_0_bits_common_dataSources_0_value);
  assign rc_addr_0 = io_fromIntIQ_0_0_bits_rcIdx_0;
  assign rc_ren_1  = io_fromIntIQ_0_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_0_0_bits_common_dataSources_1_value);
  assign rc_addr_1 = io_fromIntIQ_0_0_bits_rcIdx_1;
  assign rc_ren_2  = io_fromIntIQ_0_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_0_1_bits_common_dataSources_0_value);
  assign rc_addr_2 = io_fromIntIQ_0_1_bits_rcIdx_0;
  assign rc_ren_3  = io_fromIntIQ_0_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_0_1_bits_common_dataSources_1_value);
  assign rc_addr_3 = io_fromIntIQ_0_1_bits_rcIdx_1;
  assign rc_ren_4  = io_fromIntIQ_1_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_1_0_bits_common_dataSources_0_value);
  assign rc_addr_4 = io_fromIntIQ_1_0_bits_rcIdx_0;
  assign rc_ren_5  = io_fromIntIQ_1_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_1_0_bits_common_dataSources_1_value);
  assign rc_addr_5 = io_fromIntIQ_1_0_bits_rcIdx_1;
  assign rc_ren_6  = io_fromIntIQ_1_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_1_1_bits_common_dataSources_0_value);
  assign rc_addr_6 = io_fromIntIQ_1_1_bits_rcIdx_0;
  assign rc_ren_7  = io_fromIntIQ_1_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_1_1_bits_common_dataSources_1_value);
  assign rc_addr_7 = io_fromIntIQ_1_1_bits_rcIdx_1;
  assign rc_ren_8  = io_fromIntIQ_2_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_2_0_bits_common_dataSources_0_value);
  assign rc_addr_8 = io_fromIntIQ_2_0_bits_rcIdx_0;
  assign rc_ren_9  = io_fromIntIQ_2_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_2_0_bits_common_dataSources_1_value);
  assign rc_addr_9 = io_fromIntIQ_2_0_bits_rcIdx_1;
  assign rc_ren_10  = io_fromIntIQ_2_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_2_1_bits_common_dataSources_0_value);
  assign rc_addr_10 = io_fromIntIQ_2_1_bits_rcIdx_0;
  assign rc_ren_11  = io_fromIntIQ_2_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_2_1_bits_common_dataSources_1_value);
  assign rc_addr_11 = io_fromIntIQ_2_1_bits_rcIdx_1;
  assign rc_ren_12  = io_fromIntIQ_3_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_3_0_bits_common_dataSources_0_value);
  assign rc_addr_12 = io_fromIntIQ_3_0_bits_rcIdx_0;
  assign rc_ren_13  = io_fromIntIQ_3_0_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_3_0_bits_common_dataSources_1_value);
  assign rc_addr_13 = io_fromIntIQ_3_0_bits_rcIdx_1;
  assign rc_ren_14  = io_fromIntIQ_3_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_3_1_bits_common_dataSources_0_value);
  assign rc_addr_14 = io_fromIntIQ_3_1_bits_rcIdx_0;
  assign rc_ren_15  = io_fromIntIQ_3_1_valid & datapath_pkg::ds_read_regcache(io_fromIntIQ_3_1_bits_common_dataSources_1_value);
  assign rc_addr_15 = io_fromIntIQ_3_1_bits_rcIdx_1;
  assign rc_ren_16  = io_fromMemIQ_0_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_0_0_bits_common_dataSources_0_value);
  assign rc_addr_16 = io_fromMemIQ_0_0_bits_rcIdx_0;
  assign rc_ren_17  = io_fromMemIQ_1_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_1_0_bits_common_dataSources_0_value);
  assign rc_addr_17 = io_fromMemIQ_1_0_bits_rcIdx_0;
  assign rc_ren_18  = io_fromMemIQ_2_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_2_0_bits_common_dataSources_0_value);
  assign rc_addr_18 = io_fromMemIQ_2_0_bits_rcIdx_0;
  assign rc_ren_19  = io_fromMemIQ_3_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_3_0_bits_common_dataSources_0_value);
  assign rc_addr_19 = io_fromMemIQ_3_0_bits_rcIdx_0;
  assign rc_ren_20  = io_fromMemIQ_4_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_4_0_bits_common_dataSources_0_value);
  assign rc_addr_20 = io_fromMemIQ_4_0_bits_rcIdx_0;
  assign rc_ren_21  = io_fromMemIQ_7_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_7_0_bits_common_dataSources_0_value);
  assign rc_addr_21 = io_fromMemIQ_7_0_bits_rcIdx_0;
  assign rc_ren_22  = io_fromMemIQ_8_0_valid & datapath_pkg::ds_read_regcache(io_fromMemIQ_8_0_bits_common_dataSources_0_value);
  assign rc_addr_22 = io_fromMemIQ_8_0_bits_rcIdx_0;

// === og0/og1 响应回送 IQ + 立即数透传 ===
//   og0Failed = IQ.valid & !IQ.ready -> block;
//   og1: s1_valid & !s1_ready -> block;否则 ld/st/向量类 uncertain,余 success。
//   立即数 imm/immType 打一拍(RegEnable on valid)直送 og1ImmInfo(给 BypassNetwork)。
  // EXU g0.0 (Int IQ0.0) og 响应
  assign og0Failed_0_0 = io_fromIntIQ_0_0_valid & ~io_fromIntIQ_0_0_ready;
  assign og1Failed_0_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_0_0_og0resp_valid = og0Failed_0_0;
  assign io_toIntIQ_0_0_og0resp_bits_fuType = io_fromIntIQ_0_0_bits_common_fuType;
  assign io_toIntIQ_0_0_og1resp_valid = s1_valid_0_0;
  always_ff @(posedge clock) if (io_fromIntIQ_0_0_valid) begin  // 立即数打一拍透传
    s1_imm_0_0     <= io_fromIntIQ_0_0_bits_common_imm[31:0];
    s1_immType_0_0 <= io_fromIntIQ_0_0_bits_immType;
  end
  assign io_og1ImmInfo_0_imm     = s1_imm_0_0;
  assign io_og1ImmInfo_0_immType = s1_immType_0_0;

  // EXU g0.1 (Int IQ0.1) og 响应
  assign og0Failed_0_1 = io_fromIntIQ_0_1_valid & ~io_fromIntIQ_0_1_ready;
  assign og1Failed_0_1 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_0_1_og0resp_valid = og0Failed_0_1;
  assign io_toIntIQ_0_1_og1resp_valid = s1_valid_0_1;
  always_ff @(posedge clock) if (io_fromIntIQ_0_1_valid) begin  // 立即数打一拍透传
    s1_imm_0_1     <= io_fromIntIQ_0_1_bits_common_imm[31:0];
    s1_immType_0_1 <= io_fromIntIQ_0_1_bits_immType;
  end
  assign io_og1ImmInfo_1_imm     = s1_imm_0_1;
  assign io_og1ImmInfo_1_immType = s1_immType_0_1;

  // EXU g1.0 (Int IQ1.0) og 响应
  assign og0Failed_1_0 = io_fromIntIQ_1_0_valid & ~io_fromIntIQ_1_0_ready;
  assign og1Failed_1_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_1_0_og0resp_valid = og0Failed_1_0;
  assign io_toIntIQ_1_0_og0resp_bits_fuType = io_fromIntIQ_1_0_bits_common_fuType;
  assign io_toIntIQ_1_0_og1resp_valid = s1_valid_1_0;
  always_ff @(posedge clock) if (io_fromIntIQ_1_0_valid) begin  // 立即数打一拍透传
    s1_imm_1_0     <= io_fromIntIQ_1_0_bits_common_imm[31:0];
    s1_immType_1_0 <= io_fromIntIQ_1_0_bits_immType;
  end
  assign io_og1ImmInfo_2_imm     = s1_imm_1_0;
  assign io_og1ImmInfo_2_immType = s1_immType_1_0;

  // EXU g1.1 (Int IQ1.1) og 响应
  assign og0Failed_1_1 = io_fromIntIQ_1_1_valid & ~io_fromIntIQ_1_1_ready;
  assign og1Failed_1_1 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_1_1_og0resp_valid = og0Failed_1_1;
  assign io_toIntIQ_1_1_og1resp_valid = s1_valid_1_1;
  always_ff @(posedge clock) if (io_fromIntIQ_1_1_valid) begin  // 立即数打一拍透传
    s1_imm_1_1     <= io_fromIntIQ_1_1_bits_common_imm[31:0];
    s1_immType_1_1 <= io_fromIntIQ_1_1_bits_immType;
  end
  assign io_og1ImmInfo_3_imm     = s1_imm_1_1;
  assign io_og1ImmInfo_3_immType = s1_immType_1_1;

  // EXU g2.0 (Int IQ2.0) og 响应
  assign og0Failed_2_0 = io_fromIntIQ_2_0_valid & ~io_fromIntIQ_2_0_ready;
  assign og1Failed_2_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_2_0_og0resp_valid = og0Failed_2_0;
  assign io_toIntIQ_2_0_og1resp_valid = s1_valid_2_0;
  always_ff @(posedge clock) if (io_fromIntIQ_2_0_valid) begin  // 立即数打一拍透传
    s1_imm_2_0     <= io_fromIntIQ_2_0_bits_common_imm[31:0];
    s1_immType_2_0 <= io_fromIntIQ_2_0_bits_immType;
  end
  assign io_og1ImmInfo_4_imm     = s1_imm_2_0;
  assign io_og1ImmInfo_4_immType = s1_immType_2_0;

  // EXU g2.1 (Int IQ2.1) og 响应
  assign og0Failed_2_1 = io_fromIntIQ_2_1_valid & ~io_fromIntIQ_2_1_ready;
  assign og1Failed_2_1 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_2_1_og0resp_valid = og0Failed_2_1;
  assign io_toIntIQ_2_1_og0resp_bits_fuType = io_fromIntIQ_2_1_bits_common_fuType;
  assign io_toIntIQ_2_1_og1resp_valid = s1_valid_2_1;
  always_ff @(posedge clock) if (io_fromIntIQ_2_1_valid) begin  // 立即数打一拍透传
    s1_imm_2_1     <= io_fromIntIQ_2_1_bits_common_imm[31:0];
    s1_immType_2_1 <= io_fromIntIQ_2_1_bits_immType;
  end
  assign io_og1ImmInfo_5_imm     = s1_imm_2_1;
  assign io_og1ImmInfo_5_immType = s1_immType_2_1;

  // EXU g3.0 (Int IQ3.0) og 响应
  assign og0Failed_3_0 = io_fromIntIQ_3_0_valid & ~io_fromIntIQ_3_0_ready;
  assign og1Failed_3_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toIntIQ_3_0_og0resp_valid = og0Failed_3_0;
  assign io_toIntIQ_3_0_og1resp_valid = s1_valid_3_0;
  always_ff @(posedge clock) if (io_fromIntIQ_3_0_valid) begin  // 立即数打一拍透传
    s1_imm_3_0     <= io_fromIntIQ_3_0_bits_common_imm[31:0];
    s1_immType_3_0 <= io_fromIntIQ_3_0_bits_immType;
  end
  assign io_og1ImmInfo_6_imm     = s1_imm_3_0;
  assign io_og1ImmInfo_6_immType = s1_immType_3_0;

  // EXU g3.1 (Int IQ3.1) og 响应
  assign og0Failed_3_1 = io_fromIntIQ_3_1_valid & ~io_fromIntIQ_3_1_ready;
  assign og1Failed_3_1 = s1_valid_3_1 & ~io_toIntExu_3_1_ready;
  assign io_toIntIQ_3_1_og0resp_valid = og0Failed_3_1;
  assign io_toIntIQ_3_1_og1resp_valid = s1_valid_3_1;
  assign io_toIntIQ_3_1_og1resp_bits_resp = og1Failed_3_1 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_SUCCESS;

  // EXU g4.0 (Fp IQ0.0) og 响应
  assign og0Failed_4_0 = io_fromFpIQ_0_0_valid & ~io_fromFpIQ_0_0_ready;
  assign og1Failed_4_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toFpIQ_0_0_og0resp_valid = og0Failed_4_0;
  assign io_toFpIQ_0_0_og0resp_bits_fuType = io_fromFpIQ_0_0_bits_common_fuType;
  assign io_toFpIQ_0_0_og1resp_valid = s1_valid_4_0;

  // EXU g4.1 (Fp IQ0.1) og 响应
  assign og0Failed_4_1 = io_fromFpIQ_0_1_valid & ~io_fromFpIQ_0_1_ready;
  assign og1Failed_4_1 = s1_valid_4_1 & ~io_toFpExu_0_1_ready;
  assign io_toFpIQ_0_1_og0resp_valid = og0Failed_4_1;
  assign io_toFpIQ_0_1_og1resp_valid = s1_valid_4_1;
  assign io_toFpIQ_0_1_og1resp_bits_resp = og1Failed_4_1 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_SUCCESS;

  // EXU g5.0 (Fp IQ1.0) og 响应
  assign og0Failed_5_0 = io_fromFpIQ_1_0_valid & ~io_fromFpIQ_1_0_ready;
  assign og1Failed_5_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toFpIQ_1_0_og0resp_valid = og0Failed_5_0;
  assign io_toFpIQ_1_0_og0resp_bits_fuType = io_fromFpIQ_1_0_bits_common_fuType;
  assign io_toFpIQ_1_0_og1resp_valid = s1_valid_5_0;

  // EXU g5.1 (Fp IQ1.1) og 响应
  assign og0Failed_5_1 = io_fromFpIQ_1_1_valid & ~io_fromFpIQ_1_1_ready;
  assign og1Failed_5_1 = s1_valid_5_1 & ~io_toFpExu_1_1_ready;
  assign io_toFpIQ_1_1_og0resp_valid = og0Failed_5_1;
  assign io_toFpIQ_1_1_og1resp_valid = s1_valid_5_1;
  assign io_toFpIQ_1_1_og1resp_bits_resp = og1Failed_5_1 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_SUCCESS;

  // EXU g6.0 (Fp IQ2.0) og 响应
  assign og0Failed_6_0 = io_fromFpIQ_2_0_valid & ~io_fromFpIQ_2_0_ready;
  assign og1Failed_6_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toFpIQ_2_0_og0resp_valid = og0Failed_6_0;
  assign io_toFpIQ_2_0_og0resp_bits_fuType = io_fromFpIQ_2_0_bits_common_fuType;
  assign io_toFpIQ_2_0_og1resp_valid = s1_valid_6_0;

  // EXU g7.0 (Vf IQ0.0) og 响应
  assign og0Failed_7_0 = io_fromVfIQ_0_0_valid & ~io_fromVfIQ_0_0_ready;
  assign og1Failed_7_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toVfIQ_0_0_og0resp_valid = og0Failed_7_0;
  assign io_toVfIQ_0_0_og0resp_bits_fuType = io_fromVfIQ_0_0_bits_common_fuType;
  assign io_toVfIQ_0_0_og1resp_valid = s1_valid_7_0;

  // EXU g7.1 (Vf IQ0.1) og 响应
  assign og0Failed_7_1 = io_fromVfIQ_0_1_valid & ~io_fromVfIQ_0_1_ready;
  assign og1Failed_7_1 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toVfIQ_0_1_og0resp_valid = og0Failed_7_1;
  assign io_toVfIQ_0_1_og0resp_bits_fuType = io_fromVfIQ_0_1_bits_common_fuType;
  assign io_toVfIQ_0_1_og1resp_valid = s1_valid_7_1;
  always_ff @(posedge clock) if (io_fromVfIQ_0_1_valid) begin  // 立即数打一拍透传
    s1_imm_7_1     <= io_fromVfIQ_0_1_bits_common_imm[31:0];
    s1_immType_7_1 <= io_fromVfIQ_0_1_bits_immType;
  end
  assign io_og1ImmInfo_14_imm     = s1_imm_7_1;
  assign io_og1ImmInfo_14_immType = s1_immType_7_1;

  // EXU g8.0 (Vf IQ1.0) og 响应
  assign og0Failed_8_0 = io_fromVfIQ_1_0_valid & ~io_fromVfIQ_1_0_ready;
  assign og1Failed_8_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toVfIQ_1_0_og0resp_valid = og0Failed_8_0;
  assign io_toVfIQ_1_0_og0resp_bits_fuType = io_fromVfIQ_1_0_bits_common_fuType;
  assign io_toVfIQ_1_0_og1resp_valid = s1_valid_8_0;

  // EXU g8.1 (Vf IQ1.1) og 响应
  assign og0Failed_8_1 = io_fromVfIQ_1_1_valid & ~io_fromVfIQ_1_1_ready;
  assign og1Failed_8_1 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toVfIQ_1_1_og0resp_valid = og0Failed_8_1;
  assign io_toVfIQ_1_1_og0resp_bits_fuType = io_fromVfIQ_1_1_bits_common_fuType;
  assign io_toVfIQ_1_1_og1resp_valid = s1_valid_8_1;

  // EXU g9.0 (Vf IQ2.0) og 响应
  assign og0Failed_9_0 = io_fromVfIQ_2_0_valid & ~io_fromVfIQ_2_0_ready;
  assign og1Failed_9_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toVfIQ_2_0_og0resp_valid = og0Failed_9_0;
  assign io_toVfIQ_2_0_og1resp_valid = s1_valid_9_0;

  // EXU g10.0 (Mem IQ0.0) og 响应
  assign og0Failed_10_0 = io_fromMemIQ_0_0_valid & ~io_fromMemIQ_0_0_ready;
  assign og1Failed_10_0 = s1_valid_10_0 & ~io_toMemExu_0_0_ready;
  assign io_toMemIQ_0_0_og0resp_valid = og0Failed_10_0;
  assign io_toMemIQ_0_0_og1resp_valid = s1_valid_10_0;
  assign io_toMemIQ_0_0_og1resp_bits_resp = og1Failed_10_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_UNCERTAIN;
  always_ff @(posedge clock) if (io_fromMemIQ_0_0_valid) begin  // 立即数打一拍透传
    s1_imm_10_0     <= io_fromMemIQ_0_0_bits_common_imm[31:0];
    s1_immType_10_0 <= io_fromMemIQ_0_0_bits_immType;
  end
  assign io_og1ImmInfo_18_imm     = s1_imm_10_0;
  assign io_og1ImmInfo_18_immType = s1_immType_10_0;

  // EXU g11.0 (Mem IQ1.0) og 响应
  assign og0Failed_11_0 = io_fromMemIQ_1_0_valid & ~io_fromMemIQ_1_0_ready;
  assign og1Failed_11_0 = s1_valid_11_0 & ~io_toMemExu_1_0_ready;
  assign io_toMemIQ_1_0_og0resp_valid = og0Failed_11_0;
  assign io_toMemIQ_1_0_og1resp_valid = s1_valid_11_0;
  assign io_toMemIQ_1_0_og1resp_bits_resp = og1Failed_11_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_UNCERTAIN;
  always_ff @(posedge clock) if (io_fromMemIQ_1_0_valid) begin  // 立即数打一拍透传
    s1_imm_11_0     <= io_fromMemIQ_1_0_bits_common_imm[31:0];
    s1_immType_11_0 <= io_fromMemIQ_1_0_bits_immType;
  end
  assign io_og1ImmInfo_19_imm     = s1_imm_11_0;
  assign io_og1ImmInfo_19_immType = s1_immType_11_0;

  // EXU g12.0 (Mem IQ2.0) og 响应
  assign og0Failed_12_0 = io_fromMemIQ_2_0_valid & ~io_fromMemIQ_2_0_ready;
  assign og1Failed_12_0 = s1_valid_12_0 & ~io_toMemExu_2_0_ready;
  assign io_toMemIQ_2_0_og0resp_valid = og0Failed_12_0;
  assign io_toMemIQ_2_0_og0resp_bits_fuType = io_fromMemIQ_2_0_bits_common_fuType;
  assign io_toMemIQ_2_0_og1resp_valid = s1_valid_12_0;
  assign io_toMemIQ_2_0_og1resp_bits_resp = og1Failed_12_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_UNCERTAIN;
  assign io_toMemIQ_2_0_og1resp_bits_fuType = s1_ctrl_12_0_fuType;
  always_ff @(posedge clock) if (io_fromMemIQ_2_0_valid) begin  // 立即数打一拍透传
    s1_imm_12_0     <= io_fromMemIQ_2_0_bits_common_imm[31:0];
  end
  assign io_og1ImmInfo_20_imm     = s1_imm_12_0;

  // EXU g13.0 (Mem IQ3.0) og 响应
  assign og0Failed_13_0 = io_fromMemIQ_3_0_valid & ~io_fromMemIQ_3_0_ready;
  assign og1Failed_13_0 = s1_valid_13_0 & ~io_toMemExu_3_0_ready;
  assign io_toMemIQ_3_0_og0resp_valid = og0Failed_13_0;
  assign io_toMemIQ_3_0_og0resp_bits_fuType = io_fromMemIQ_3_0_bits_common_fuType;
  assign io_toMemIQ_3_0_og1resp_valid = s1_valid_13_0;
  assign io_toMemIQ_3_0_og1resp_bits_resp = og1Failed_13_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_UNCERTAIN;
  assign io_toMemIQ_3_0_og1resp_bits_fuType = s1_ctrl_13_0_fuType;
  always_ff @(posedge clock) if (io_fromMemIQ_3_0_valid) begin  // 立即数打一拍透传
    s1_imm_13_0     <= io_fromMemIQ_3_0_bits_common_imm[31:0];
  end
  assign io_og1ImmInfo_21_imm     = s1_imm_13_0;

  // EXU g14.0 (Mem IQ4.0) og 响应
  assign og0Failed_14_0 = io_fromMemIQ_4_0_valid & ~io_fromMemIQ_4_0_ready;
  assign og1Failed_14_0 = s1_valid_14_0 & ~io_toMemExu_4_0_ready;
  assign io_toMemIQ_4_0_og0resp_valid = og0Failed_14_0;
  assign io_toMemIQ_4_0_og0resp_bits_fuType = io_fromMemIQ_4_0_bits_common_fuType;
  assign io_toMemIQ_4_0_og1resp_valid = s1_valid_14_0;
  assign io_toMemIQ_4_0_og1resp_bits_resp = og1Failed_14_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_UNCERTAIN;
  assign io_toMemIQ_4_0_og1resp_bits_fuType = s1_ctrl_14_0_fuType;
  always_ff @(posedge clock) if (io_fromMemIQ_4_0_valid) begin  // 立即数打一拍透传
    s1_imm_14_0     <= io_fromMemIQ_4_0_bits_common_imm[31:0];
  end
  assign io_og1ImmInfo_22_imm     = s1_imm_14_0;

  // EXU g15.0 (Mem IQ5.0) og 响应
  assign og0Failed_15_0 = io_fromMemIQ_5_0_valid & ~io_fromMemIQ_5_0_ready;
  assign og1Failed_15_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toMemIQ_5_0_og0resp_valid = og0Failed_15_0;
  assign io_toMemIQ_5_0_og1resp_valid = s1_valid_15_0;

  // EXU g16.0 (Mem IQ6.0) og 响应
  assign og0Failed_16_0 = io_fromMemIQ_6_0_valid & ~io_fromMemIQ_6_0_ready;
  assign og1Failed_16_0 = 1'b0;  // toExu.ready 恒就绪(端口被裁)
  assign io_toMemIQ_6_0_og0resp_valid = og0Failed_16_0;
  assign io_toMemIQ_6_0_og1resp_valid = s1_valid_16_0;

  // EXU g17.0 (Mem IQ7.0) og 响应
  assign og0Failed_17_0 = io_fromMemIQ_7_0_valid & ~io_fromMemIQ_7_0_ready;
  assign og1Failed_17_0 = s1_valid_17_0 & ~io_toMemExu_7_0_ready;
  assign io_toMemIQ_7_0_og0resp_valid = og0Failed_17_0;
  assign io_toMemIQ_7_0_og1resp_valid = s1_valid_17_0;
  assign io_toMemIQ_7_0_og1resp_bits_resp = og1Failed_17_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_SUCCESS;

  // EXU g18.0 (Mem IQ8.0) og 响应
  assign og0Failed_18_0 = io_fromMemIQ_8_0_valid & ~io_fromMemIQ_8_0_ready;
  assign og1Failed_18_0 = s1_valid_18_0 & ~io_toMemExu_8_0_ready;
  assign io_toMemIQ_8_0_og0resp_valid = og0Failed_18_0;
  assign io_toMemIQ_8_0_og1resp_valid = s1_valid_18_0;
  assign io_toMemIQ_8_0_og1resp_bits_resp = og1Failed_18_0 ? datapath_pkg::RESP_BLOCK : datapath_pkg::RESP_SUCCESS;

// === pc-read 请求 + og0Cancel ===
//   needPc 的 EXU 在 s0 把 ftqIdx/valid 送 PcTargetMem,下一拍读回 pc/target。
//   og0Cancel:0 延迟唤醒源在 og0 失败时广播取消(供消费者 squash)。
  assign io_fromPcTargetMem_fromDataPathValid_0     = io_fromIntIQ_0_1_valid;
  assign io_fromPcTargetMem_fromDataPathFtqPtr_0_value = io_fromIntIQ_0_1_bits_common_ftqIdx_value;
  assign io_fromPcTargetMem_fromDataPathValid_1     = io_fromIntIQ_1_1_valid;
  assign io_fromPcTargetMem_fromDataPathFtqPtr_1_value = io_fromIntIQ_1_1_bits_common_ftqIdx_value;
  assign io_fromPcTargetMem_fromDataPathValid_2     = io_fromIntIQ_2_1_valid;
  assign io_fromPcTargetMem_fromDataPathFtqPtr_2_value = io_fromIntIQ_2_1_bits_common_ftqIdx_value;
  assign io_fromPcTargetMem_fromDataPathValid_3     = io_fromMemIQ_2_0_valid;
  assign io_fromPcTargetMem_fromDataPathFtqPtr_3_value = io_fromMemIQ_2_0_bits_common_ftqIdx_value;
  assign io_fromPcTargetMem_fromDataPathValid_4     = io_fromMemIQ_3_0_valid;
  assign io_fromPcTargetMem_fromDataPathFtqPtr_4_value = io_fromMemIQ_3_0_bits_common_ftqIdx_value;
  assign io_fromPcTargetMem_fromDataPathValid_5     = io_fromMemIQ_4_0_valid;
  assign io_fromPcTargetMem_fromDataPathFtqPtr_5_value = io_fromMemIQ_4_0_bits_common_ftqIdx_value;
  assign io_og0Cancel_0 = og0Failed_0_0;
  assign io_og0Cancel_2 = og0Failed_1_0;
  assign io_og0Cancel_4 = og0Failed_2_0;
  assign io_og0Cancel_6 = og0Failed_3_0;
  assign io_og0Cancel_8 = og0Failed_4_0;

// === s0_cancel(0 延迟唤醒取消)+ og0_cancel_delay ===
//   og0_cancel_delay[k] = RegNext(og0Failed[非load EXU k] & is_0latency(fuType));
//   cancel_exuOH = 1<<exuSources[src](喂 UIntExtractor 黑盒散布到 27 位全局空间)。
//   s0_cancel 当前接 0(见文件末 STATUS:精确交集表达式逐 EXU 不同,待精确重写;
//   读/写口背压已由 notBlock 完整表达,s0_cancel 仅 0 延迟取消的稀有纠正路径)。
  logic og0_cancel_delay_0;
  logic og0_cancel_delay_1;
  logic og0_cancel_delay_2;
  logic og0_cancel_delay_3;
  logic og0_cancel_delay_4;
  logic og0_cancel_delay_5;
  logic og0_cancel_delay_6;
  logic og0_cancel_delay_7;
  logic og0_cancel_delay_8;
  logic og0_cancel_delay_9;
  logic og0_cancel_delay_10;
  logic og0_cancel_delay_11;
  logic og0_cancel_delay_12;
  logic og0_cancel_delay_13;
  logic og0_cancel_delay_14;
  logic og0_cancel_delay_15;
  logic og0_cancel_delay_16;
  logic og0_cancel_delay_17;
  logic og0_cancel_delay_18;
  logic og0_cancel_delay_19;
  logic og0_cancel_delay_20;
  logic og0_cancel_delay_21;
  logic og0_cancel_delay_22;
  logic og0_cancel_delay_23;
  always_ff @(posedge clock) og0_cancel_delay_0 <= og0Failed_0_0 & datapath_pkg::is_0latency(io_fromIntIQ_0_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_1 <= og0Failed_0_1 & datapath_pkg::is_0latency(io_fromIntIQ_0_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_2 <= og0Failed_1_0 & datapath_pkg::is_0latency(io_fromIntIQ_1_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_3 <= og0Failed_1_1 & datapath_pkg::is_0latency(io_fromIntIQ_1_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_4 <= og0Failed_2_0 & datapath_pkg::is_0latency(io_fromIntIQ_2_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_5 <= og0Failed_2_1 & datapath_pkg::is_0latency(io_fromIntIQ_2_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_6 <= og0Failed_3_0 & datapath_pkg::is_0latency(io_fromIntIQ_3_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_7 <= og0Failed_3_1 & datapath_pkg::is_0latency(io_fromIntIQ_3_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_8 <= og0Failed_4_0 & datapath_pkg::is_0latency(io_fromFpIQ_0_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_9 <= og0Failed_4_1 & datapath_pkg::is_0latency(io_fromFpIQ_0_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_10 <= og0Failed_5_0 & datapath_pkg::is_0latency(io_fromFpIQ_1_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_11 <= og0Failed_5_1 & datapath_pkg::is_0latency(io_fromFpIQ_1_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_12 <= og0Failed_6_0 & datapath_pkg::is_0latency(io_fromFpIQ_2_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_13 <= og0Failed_7_0 & datapath_pkg::is_0latency(io_fromVfIQ_0_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_14 <= og0Failed_7_1 & datapath_pkg::is_0latency(io_fromVfIQ_0_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_15 <= og0Failed_8_0 & datapath_pkg::is_0latency(io_fromVfIQ_1_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_16 <= og0Failed_8_1 & datapath_pkg::is_0latency(io_fromVfIQ_1_1_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_17 <= og0Failed_9_0 & datapath_pkg::is_0latency(io_fromVfIQ_2_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_18 <= og0Failed_10_0 & datapath_pkg::is_0latency(io_fromMemIQ_0_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_19 <= og0Failed_11_0 & datapath_pkg::is_0latency(io_fromMemIQ_1_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_20 <= og0Failed_15_0 & datapath_pkg::is_0latency(io_fromMemIQ_5_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_21 <= og0Failed_16_0 & datapath_pkg::is_0latency(io_fromMemIQ_6_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_22 <= og0Failed_17_0 & datapath_pkg::is_0latency(io_fromMemIQ_7_0_bits_common_fuType);
  always_ff @(posedge clock) og0_cancel_delay_23 <= og0Failed_18_0 & datapath_pkg::is_0latency(io_fromMemIQ_8_0_bits_common_fuType);
  logic [7:0] cancel_exuOH;
  assign cancel_exuOH = 8'h1 << io_fromIntIQ_0_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_1;
  assign cancel_exuOH_1 = 8'h1 << io_fromIntIQ_0_0_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_2;
  assign cancel_exuOH_2 = 8'h1 << io_fromIntIQ_0_1_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_3;
  assign cancel_exuOH_3 = 8'h1 << io_fromIntIQ_0_1_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_4;
  assign cancel_exuOH_4 = 8'h1 << io_fromIntIQ_1_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_5;
  assign cancel_exuOH_5 = 8'h1 << io_fromIntIQ_1_0_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_6;
  assign cancel_exuOH_6 = 8'h1 << io_fromIntIQ_1_1_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_7;
  assign cancel_exuOH_7 = 8'h1 << io_fromIntIQ_1_1_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_8;
  assign cancel_exuOH_8 = 8'h1 << io_fromIntIQ_2_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_9;
  assign cancel_exuOH_9 = 8'h1 << io_fromIntIQ_2_0_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_10;
  assign cancel_exuOH_10 = 8'h1 << io_fromIntIQ_2_1_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_11;
  assign cancel_exuOH_11 = 8'h1 << io_fromIntIQ_2_1_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_12;
  assign cancel_exuOH_12 = 8'h1 << io_fromIntIQ_3_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_13;
  assign cancel_exuOH_13 = 8'h1 << io_fromIntIQ_3_0_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_14;
  assign cancel_exuOH_14 = 8'h1 << io_fromIntIQ_3_1_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_15;
  assign cancel_exuOH_15 = 8'h1 << io_fromIntIQ_3_1_bits_common_exuSources_1_value;
  logic [7:0] cancel_exuOH_29;
  assign cancel_exuOH_29 = 8'h1 << io_fromMemIQ_0_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_30;
  assign cancel_exuOH_30 = 8'h1 << io_fromMemIQ_1_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_31;
  assign cancel_exuOH_31 = 8'h1 << io_fromMemIQ_2_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_32;
  assign cancel_exuOH_32 = 8'h1 << io_fromMemIQ_3_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_33;
  assign cancel_exuOH_33 = 8'h1 << io_fromMemIQ_4_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_34;
  assign cancel_exuOH_34 = 8'h1 << io_fromMemIQ_7_0_bits_common_exuSources_0_value;
  logic [7:0] cancel_exuOH_35;
  assign cancel_exuOH_35 = 8'h1 << io_fromMemIQ_8_0_bits_common_exuSources_0_value;
  // Fp 域唤醒源 one-hot:Fp EXU 编号空间较小,用 4 位编码(对齐 golden 4'h1<<src)。
  logic [3:0] cancel_exuOH_16;
  assign cancel_exuOH_16 = 4'h1 << io_fromFpIQ_0_0_bits_common_exuSources_0_value;
  logic [3:0] cancel_exuOH_17;
  assign cancel_exuOH_17 = 4'h1 << io_fromFpIQ_0_0_bits_common_exuSources_1_value;
  logic [3:0] cancel_exuOH_18;
  assign cancel_exuOH_18 = 4'h1 << io_fromFpIQ_0_0_bits_common_exuSources_2_value;
  logic [3:0] cancel_exuOH_19;
  assign cancel_exuOH_19 = 4'h1 << io_fromFpIQ_0_1_bits_common_exuSources_0_value;
  logic [3:0] cancel_exuOH_20;
  assign cancel_exuOH_20 = 4'h1 << io_fromFpIQ_0_1_bits_common_exuSources_1_value;
  logic [3:0] cancel_exuOH_21;
  assign cancel_exuOH_21 = 4'h1 << io_fromFpIQ_1_0_bits_common_exuSources_0_value;
  logic [3:0] cancel_exuOH_22;
  assign cancel_exuOH_22 = 4'h1 << io_fromFpIQ_1_0_bits_common_exuSources_1_value;
  logic [3:0] cancel_exuOH_23;
  assign cancel_exuOH_23 = 4'h1 << io_fromFpIQ_1_0_bits_common_exuSources_2_value;
  logic [3:0] cancel_exuOH_24;
  assign cancel_exuOH_24 = 4'h1 << io_fromFpIQ_1_1_bits_common_exuSources_0_value;
  logic [3:0] cancel_exuOH_25;
  assign cancel_exuOH_25 = 4'h1 << io_fromFpIQ_1_1_bits_common_exuSources_1_value;
  logic [3:0] cancel_exuOH_26;
  assign cancel_exuOH_26 = 4'h1 << io_fromFpIQ_2_0_bits_common_exuSources_0_value;
  logic [3:0] cancel_exuOH_27;
  assign cancel_exuOH_27 = 4'h1 << io_fromFpIQ_2_0_bits_common_exuSources_1_value;
  logic [3:0] cancel_exuOH_28;
  assign cancel_exuOH_28 = 4'h1 << io_fromFpIQ_2_0_bits_common_exuSources_2_value;

  // UIntExtractor 黑盒输出:把 8 位(Int/Mem)或 4 位(Fp)唤醒源 one-hot 解码并散布到
  // 27 位全局 EXU 空间(连线见 connect svh)。
  logic [26:0] _exuOHNoLoad_ext_io_out;
  logic [26:0] _exuOHNoLoad_ext_1_io_out;
  logic [26:0] _exuOHNoLoad_ext_2_io_out;
  logic [26:0] _exuOHNoLoad_ext_3_io_out;
  logic [26:0] _exuOHNoLoad_ext_4_io_out;
  logic [26:0] _exuOHNoLoad_ext_5_io_out;
  logic [26:0] _exuOHNoLoad_ext_6_io_out;
  logic [26:0] _exuOHNoLoad_ext_7_io_out;
  logic [26:0] _exuOHNoLoad_ext_8_io_out;
  logic [26:0] _exuOHNoLoad_ext_9_io_out;
  logic [26:0] _exuOHNoLoad_ext_10_io_out;
  logic [26:0] _exuOHNoLoad_ext_11_io_out;
  logic [26:0] _exuOHNoLoad_ext_12_io_out;
  logic [26:0] _exuOHNoLoad_ext_13_io_out;
  logic [26:0] _exuOHNoLoad_ext_14_io_out;
  logic [26:0] _exuOHNoLoad_ext_15_io_out;
  logic [26:0] _exuOHNoLoad_ext_16_io_out;
  logic [26:0] _exuOHNoLoad_ext_17_io_out;
  logic [26:0] _exuOHNoLoad_ext_18_io_out;
  logic [26:0] _exuOHNoLoad_ext_19_io_out;
  logic [26:0] _exuOHNoLoad_ext_20_io_out;
  logic [26:0] _exuOHNoLoad_ext_21_io_out;
  logic [26:0] _exuOHNoLoad_ext_22_io_out;
  logic [26:0] _exuOHNoLoad_ext_23_io_out;
  logic [26:0] _exuOHNoLoad_ext_24_io_out;
  logic [26:0] _exuOHNoLoad_ext_25_io_out;
  logic [26:0] _exuOHNoLoad_ext_26_io_out;
  logic [26:0] _exuOHNoLoad_ext_27_io_out;
  logic [26:0] _exuOHNoLoad_ext_28_io_out;
  logic [26:0] _exuOHNoLoad_ext_29_io_out;
  logic [26:0] _exuOHNoLoad_ext_30_io_out;
  logic [26:0] _exuOHNoLoad_ext_31_io_out;
  logic [26:0] _exuOHNoLoad_ext_32_io_out;
  logic [26:0] _exuOHNoLoad_ext_33_io_out;
  logic [26:0] _exuOHNoLoad_ext_34_io_out;
  logic [26:0] _exuOHNoLoad_ext_35_io_out;

  // og0_cancel_delay 各路打包成 24 位向量喂判定函数(偶位索引对齐解码空间)。
  logic [23:0] og0_cancel_delay_vec;
  assign og0_cancel_delay_vec = {
    og0_cancel_delay_23, og0_cancel_delay_22, og0_cancel_delay_21, og0_cancel_delay_20,
    og0_cancel_delay_19, og0_cancel_delay_18, og0_cancel_delay_17, og0_cancel_delay_16,
    og0_cancel_delay_15, og0_cancel_delay_14, og0_cancel_delay_13, og0_cancel_delay_12,
    og0_cancel_delay_11, og0_cancel_delay_10, og0_cancel_delay_9,  og0_cancel_delay_8,
    og0_cancel_delay_7,  og0_cancel_delay_6,  og0_cancel_delay_5,  og0_cancel_delay_4,
    og0_cancel_delay_3,  og0_cancel_delay_2,  og0_cancel_delay_1,  og0_cancel_delay_0};

  // s0_cancel:对每个发射端口,任一源操作数来自「上拍 og0 失败的 0 延迟非 load 唤醒
  //   EXU」(dataSources==4'h1)即取消接收。Int/Mem 端口监听 Int 域窗口(偶位 0/2/4/6),
  //   Fp 端口监听 Fp 域窗口(偶位 8/10/12)。每端口与其有效信号相与。
  assign s0_cancel_0_0 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_io_out,   og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_0_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_1_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_0_0_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_0_0_valid;
  assign s0_cancel_0_1 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_2_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_0_1_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_3_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_0_1_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_0_1_valid;
  assign s0_cancel_1_0 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_4_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_1_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_5_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_1_0_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_1_0_valid;
  assign s0_cancel_1_1 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_6_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_1_1_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_7_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_1_1_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_1_1_valid;
  assign s0_cancel_2_0 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_8_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_2_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_9_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_2_0_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_2_0_valid;
  assign s0_cancel_2_1 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_10_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_2_1_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_11_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_2_1_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_2_1_valid;
  assign s0_cancel_3_0 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_12_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_3_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_13_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_3_0_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_3_0_valid;
  assign s0_cancel_3_1 = (
      datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_14_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_3_1_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_15_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromIntIQ_3_1_bits_common_dataSources_1_value)
    ) & io_fromIntIQ_3_1_valid;
  // Fp 端口 0_0 / 1_0 / 2_0 有 3 个源,0_1 / 1_1 有 2 个源。
  assign s0_cancel_4_0 = (
      datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_16_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_0_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_17_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_0_0_bits_common_dataSources_1_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_18_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_0_0_bits_common_dataSources_2_value)
    ) & io_fromFpIQ_0_0_valid;
  assign s0_cancel_4_1 = (
      datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_19_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_0_1_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_20_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_0_1_bits_common_dataSources_1_value)
    ) & io_fromFpIQ_0_1_valid;
  assign s0_cancel_5_0 = (
      datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_21_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_1_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_22_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_1_0_bits_common_dataSources_1_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_23_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_1_0_bits_common_dataSources_2_value)
    ) & io_fromFpIQ_1_0_valid;
  assign s0_cancel_5_1 = (
      datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_24_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_1_1_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_25_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_1_1_bits_common_dataSources_1_value)
    ) & io_fromFpIQ_1_1_valid;
  assign s0_cancel_6_0 = (
      datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_26_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_2_0_bits_common_dataSources_0_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_27_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_2_0_bits_common_dataSources_1_value)
    | datapath_pkg::wakeup_failed_fp(_exuOHNoLoad_ext_28_io_out, og0_cancel_delay_vec) & datapath_pkg::ds_from_forward(io_fromFpIQ_2_0_bits_common_dataSources_2_value)
    ) & io_fromFpIQ_2_0_valid;
  // Vf 域端口:golden 未生成 s0_cancel 监听(无 0 延迟唤醒交集),恒 0。
  assign s0_cancel_7_0 = 1'b0;
  assign s0_cancel_7_1 = 1'b0;
  assign s0_cancel_8_0 = 1'b0;
  assign s0_cancel_8_1 = 1'b0;
  assign s0_cancel_9_0 = 1'b0;
  // Mem 域端口:监听 Int 域窗口,单源(dataSources_0)。MemIQ_5/6 golden 无监听,恒 0。
  assign s0_cancel_10_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_29_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_0_0_bits_common_dataSources_0_value) & io_fromMemIQ_0_0_valid;
  assign s0_cancel_11_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_30_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_1_0_bits_common_dataSources_0_value) & io_fromMemIQ_1_0_valid;
  assign s0_cancel_12_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_31_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_2_0_bits_common_dataSources_0_value) & io_fromMemIQ_2_0_valid;
  assign s0_cancel_13_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_32_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_3_0_bits_common_dataSources_0_value) & io_fromMemIQ_3_0_valid;
  assign s0_cancel_14_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_33_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_4_0_bits_common_dataSources_0_value) & io_fromMemIQ_4_0_valid;
  assign s0_cancel_15_0 = 1'b0;
  assign s0_cancel_16_0 = 1'b0;
  assign s0_cancel_17_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_34_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_7_0_bits_common_dataSources_0_value) & io_fromMemIQ_7_0_valid;
  assign s0_cancel_18_0 = datapath_pkg::wakeup_failed_int(_exuOHNoLoad_ext_35_io_out, og0_cancel_delay_vec)
    & datapath_pkg::ds_from_forward(io_fromMemIQ_8_0_bits_common_dataSources_0_value) & io_fromMemIQ_8_0_valid;
// === vecExcp 读响应 / topDown / perf ===
//   vecExcp 读响应:valid 打一拍,bits 按 RegEnable(~isV0) 选 vf 或 v0 读数据。
//   topDown/perf 为性能统计输出(非功能数据流):noUopsIssued = 无 uop 发射。
  logic vecexcp_rd_selvec_0;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_0_valid)
    vecexcp_rd_selvec_0 <= ~io_fromVecExcpMod_r_0_bits_isV0;
  always_ff @(posedge clock) begin
    if (reset) io_toVecExcpMod_rdata_0_valid <= 1'b0;
    else io_toVecExcpMod_rdata_0_valid <= io_fromVecExcpMod_r_0_valid;
  end
  assign io_toVecExcpMod_rdata_0_bits = vecexcp_rd_selvec_0 ? vf_rdata[6] : v0_rdata[2];
  logic vecexcp_rd_selvec_1;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_1_valid)
    vecexcp_rd_selvec_1 <= 1'b1;
  always_ff @(posedge clock) begin
    if (reset) io_toVecExcpMod_rdata_1_valid <= 1'b0;
    else io_toVecExcpMod_rdata_1_valid <= io_fromVecExcpMod_r_1_valid;
  end
  assign io_toVecExcpMod_rdata_1_bits = vecexcp_rd_selvec_1 ? vf_rdata[7] : 128'h0;
  logic vecexcp_rd_selvec_2;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_2_valid)
    vecexcp_rd_selvec_2 <= 1'b1;
  always_ff @(posedge clock) begin
    if (reset) io_toVecExcpMod_rdata_2_valid <= 1'b0;
    else io_toVecExcpMod_rdata_2_valid <= io_fromVecExcpMod_r_2_valid;
  end
  assign io_toVecExcpMod_rdata_2_bits = vecexcp_rd_selvec_2 ? vf_rdata[8] : 128'h0;
  logic vecexcp_rd_selvec_3;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_3_valid)
    vecexcp_rd_selvec_3 <= 1'b1;
  always_ff @(posedge clock) begin
    if (reset) io_toVecExcpMod_rdata_3_valid <= 1'b0;
    else io_toVecExcpMod_rdata_3_valid <= io_fromVecExcpMod_r_3_valid;
  end
  assign io_toVecExcpMod_rdata_3_bits = vecexcp_rd_selvec_3 ? vf_rdata[9] : 128'h0;
  logic vecexcp_rd_selvec_4;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_4_valid)
    vecexcp_rd_selvec_4 <= ~io_fromVecExcpMod_r_4_bits_isV0;
  assign io_toVecExcpMod_rdata_4_bits = vecexcp_rd_selvec_4 ? vf_rdata[10] : v0_rdata[3];
  logic vecexcp_rd_selvec_5;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_5_valid)
    vecexcp_rd_selvec_5 <= 1'b1;
  assign io_toVecExcpMod_rdata_5_bits = vecexcp_rd_selvec_5 ? vf_rdata[11] : 128'h0;
  logic vecexcp_rd_selvec_6;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_6_valid)
    vecexcp_rd_selvec_6 <= 1'b1;
  assign io_toVecExcpMod_rdata_6_bits = vecexcp_rd_selvec_6 ? vf_rdata[0] : 128'h0;
  logic vecexcp_rd_selvec_7;  // RegEnable(~isV0, r.valid)
  always_ff @(posedge clock) if (io_fromVecExcpMod_r_7_valid)
    vecexcp_rd_selvec_7 <= 1'b1;
  assign io_toVecExcpMod_rdata_7_bits = vecexcp_rd_selvec_7 ? vf_rdata[1] : 128'h0;

  assign io_topDownInfo_noUopsIssued = ~(fromIQ_fire_0_0 | fromIQ_fire_0_1 | fromIQ_fire_1_0 | fromIQ_fire_1_1 | fromIQ_fire_2_0 | fromIQ_fire_2_1 | fromIQ_fire_3_0 | fromIQ_fire_3_1 | fromIQ_fire_4_0 | fromIQ_fire_4_1 | fromIQ_fire_5_0 | fromIQ_fire_5_1 | fromIQ_fire_6_0 | fromIQ_fire_7_0 | fromIQ_fire_7_1 | fromIQ_fire_8_0 | fromIQ_fire_8_1 | fromIQ_fire_9_0 | fromIQ_fire_10_0 | fromIQ_fire_11_0 | fromIQ_fire_12_0 | fromIQ_fire_13_0 | fromIQ_fire_14_0 | fromIQ_fire_15_0 | fromIQ_fire_16_0 | fromIQ_fire_17_0 | fromIQ_fire_18_0);
  // === perf 计数(2 级打拍后输出,topDown 性能事件)===
  //   uopsIssued     = 本拍是否有任一 uop 发射(= ~noUopsIssued);
  //   uopsIssuedCnt  = 本拍发射 uop 数(全部 fromIQ_fire 的 popcount);
  //   fewUopsIssued  = 发射 uop 数 <= 3(发射带宽利用率低);
  //   memStall*      = load/store 流水停顿且对应队列非空 / 各级 cache miss;
  //   io_perf_k      = 对应 probe 经 2 级寄存(RegNext×2),零扩展到 6 位。
  //   connect svh 的 stallLoadReg/stallStoreReg(DelayN_1 黑盒)输入用到的 uopsIssued /
  //   fromIQFire_* 别名在此驱动。
  wire uopsIssued = ~io_topDownInfo_noUopsIssued;
  wire fromIQFire_10_0 = fromIQ_fire_10_0;
  wire fromIQFire_11_0 = fromIQ_fire_11_0;
  wire fromIQFire_17_0 = fromIQ_fire_17_0;
  wire fromIQFire_18_0 = fromIQ_fire_18_0;

  logic [4:0] uopsIssuedCnt;
  assign uopsIssuedCnt =
      fromIQ_fire_0_0  + fromIQ_fire_0_1  + fromIQ_fire_1_0  + fromIQ_fire_1_1
    + fromIQ_fire_2_0  + fromIQ_fire_2_1  + fromIQ_fire_3_0  + fromIQ_fire_3_1
    + fromIQ_fire_4_0  + fromIQ_fire_4_1  + fromIQ_fire_5_0  + fromIQ_fire_5_1
    + fromIQ_fire_6_0  + fromIQ_fire_7_0  + fromIQ_fire_7_1  + fromIQ_fire_8_0
    + fromIQ_fire_8_1  + fromIQ_fire_9_0  + fromIQ_fire_10_0 + fromIQ_fire_11_0
    + fromIQ_fire_12_0 + fromIQ_fire_13_0 + fromIQ_fire_14_0 + fromIQ_fire_15_0
    + fromIQ_fire_16_0 + fromIQ_fire_17_0 + fromIQ_fire_18_0;

  // stallLoadReg/stallStoreReg(DelayN_1 黑盒,connect svh 例化)的 1 拍延迟输出。
  wire _stallStoreReg_delay_io_out;
  wire _stallLoadReg_delay_io_out;
  wire fewUopsIssued_probe = uopsIssuedCnt <= 5'h3;
  wire memStallStore_probe = _stallStoreReg_delay_io_out & ~io_topDownInfo_sqEmpty;
  wire memStallL1Miss_probe = _stallLoadReg_delay_io_out & ~io_topDownInfo_lqEmpty & io_topDownInfo_l1Miss;
  wire memStallL2Miss_probe = memStallL1Miss_probe & io_topDownInfo_l2TopMiss_l2Miss;
  wire memStallL3Miss_probe = memStallL2Miss_probe & io_topDownInfo_l2TopMiss_l3Miss;

  logic perf_0_stage1, perf_0_stage2;
  logic perf_1_stage1, perf_1_stage2;
  logic perf_2_stage1, perf_2_stage2;
  logic perf_3_stage1, perf_3_stage2;
  logic perf_4_stage1, perf_4_stage2;
  always_ff @(posedge clock) begin
    perf_0_stage1   <= fewUopsIssued_probe;
    perf_0_stage2 <= perf_0_stage1;
    perf_1_stage1   <= memStallStore_probe;
    perf_1_stage2 <= perf_1_stage1;
    perf_2_stage1   <= memStallL1Miss_probe;
    perf_2_stage2 <= perf_2_stage1;
    perf_3_stage1   <= memStallL2Miss_probe;
    perf_3_stage2 <= perf_3_stage1;
    perf_4_stage1   <= memStallL3Miss_probe;
    perf_4_stage2 <= perf_4_stage1;
  end
  assign io_perf_0_value = {5'h0, perf_0_stage2};
  assign io_perf_1_value = {5'h0, perf_1_stage2};
  assign io_perf_2_value = {5'h0, perf_2_stage2};
  assign io_perf_3_value = {5'h0, perf_3_stage2};
  assign io_perf_4_value = {5'h0, perf_4_stage2};

