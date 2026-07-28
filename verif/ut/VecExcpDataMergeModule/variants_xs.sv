// VecExcpDataMergeModule_xs + 子模块 _xs 副本 —— UT 双例化变体 (与可读核逐字一致,
// 仅模块/子模块名加 _xs)。DelayN 用 xs_delayn_core (来自 DelayN.sv, TB 已含)。
// 自动生成: scripts/gen_vecexcpdatamerge.py —— 勿手改 (bit-exact 标识符改名转写)。
// VecExcpDataMergeModule: 向量异常数据合并 5 态 FSM (详见脚本头注释)。
// 可读化 = 去 golden 的 _GEN_/_T_ SSA 噪声 (纯改名, 逐位一致); DelayN_13->xs_delayn_core。
module VecExcpDataMergeModule_xs(
  input          clock,
  input          reset,
  input          i_fromExceptionGen_valid,
  input  [6:0]   i_fromExceptionGen_bits_vstart,
  input  [1:0]   i_fromExceptionGen_bits_vsew,
  input  [1:0]   i_fromExceptionGen_bits_veew,
  input  [2:0]   i_fromExceptionGen_bits_vlmul,
  input  [2:0]   i_fromExceptionGen_bits_nf,
  input          i_fromExceptionGen_bits_isStride,
  input          i_fromExceptionGen_bits_isIndexed,
  input          i_fromExceptionGen_bits_isWhole,
  input          i_fromExceptionGen_bits_isVlm,
  input          i_fromRab_logicPhyRegMap_0_valid,
  input  [5:0]   i_fromRab_logicPhyRegMap_0_bits_lreg,
  input  [6:0]   i_fromRab_logicPhyRegMap_0_bits_preg,
  input          i_fromRab_logicPhyRegMap_1_valid,
  input  [5:0]   i_fromRab_logicPhyRegMap_1_bits_lreg,
  input  [6:0]   i_fromRab_logicPhyRegMap_1_bits_preg,
  input          i_fromRab_logicPhyRegMap_2_valid,
  input  [5:0]   i_fromRab_logicPhyRegMap_2_bits_lreg,
  input  [6:0]   i_fromRab_logicPhyRegMap_2_bits_preg,
  input          i_fromRab_logicPhyRegMap_3_valid,
  input  [5:0]   i_fromRab_logicPhyRegMap_3_bits_lreg,
  input  [6:0]   i_fromRab_logicPhyRegMap_3_bits_preg,
  input          i_fromRab_logicPhyRegMap_4_valid,
  input  [5:0]   i_fromRab_logicPhyRegMap_4_bits_lreg,
  input  [6:0]   i_fromRab_logicPhyRegMap_4_bits_preg,
  input          i_fromRab_logicPhyRegMap_5_valid,
  input  [5:0]   i_fromRab_logicPhyRegMap_5_bits_lreg,
  input  [6:0]   i_fromRab_logicPhyRegMap_5_bits_preg,
  input          i_fromRat_vecOldVdPdest_0_valid,
  input  [6:0]   i_fromRat_vecOldVdPdest_0_bits,
  input          i_fromRat_vecOldVdPdest_1_valid,
  input  [6:0]   i_fromRat_vecOldVdPdest_1_bits,
  input          i_fromRat_vecOldVdPdest_2_valid,
  input  [6:0]   i_fromRat_vecOldVdPdest_2_bits,
  input          i_fromRat_vecOldVdPdest_3_valid,
  input  [6:0]   i_fromRat_vecOldVdPdest_3_bits,
  input          i_fromRat_vecOldVdPdest_4_valid,
  input  [6:0]   i_fromRat_vecOldVdPdest_4_bits,
  input          i_fromRat_vecOldVdPdest_5_valid,
  input  [6:0]   i_fromRat_vecOldVdPdest_5_bits,
  input          i_fromRat_v0OldVdPdest_0_valid,
  input  [6:0]   i_fromRat_v0OldVdPdest_0_bits,
  input          i_fromRat_v0OldVdPdest_1_valid,
  input  [6:0]   i_fromRat_v0OldVdPdest_1_bits,
  input          i_fromRat_v0OldVdPdest_2_valid,
  input  [6:0]   i_fromRat_v0OldVdPdest_2_bits,
  input          i_fromRat_v0OldVdPdest_3_valid,
  input  [6:0]   i_fromRat_v0OldVdPdest_3_bits,
  input          i_fromRat_v0OldVdPdest_4_valid,
  input  [6:0]   i_fromRat_v0OldVdPdest_4_bits,
  input          i_fromRat_v0OldVdPdest_5_valid,
  input  [6:0]   i_fromRat_v0OldVdPdest_5_bits,
  input          i_fromVprf_rdata_0_valid,
  input  [127:0] i_fromVprf_rdata_0_bits,
  input          i_fromVprf_rdata_1_valid,
  input  [127:0] i_fromVprf_rdata_1_bits,
  input          i_fromVprf_rdata_2_valid,
  input  [127:0] i_fromVprf_rdata_2_bits,
  input          i_fromVprf_rdata_3_valid,
  input  [127:0] i_fromVprf_rdata_3_bits,
  input  [127:0] i_fromVprf_rdata_4_bits,
  input  [127:0] i_fromVprf_rdata_5_bits,
  input  [127:0] i_fromVprf_rdata_6_bits,
  input  [127:0] i_fromVprf_rdata_7_bits,
  output         o_toVPRF_r_0_valid,
  output         o_toVPRF_r_0_bits_isV0,
  output [6:0]   o_toVPRF_r_0_bits_addr,
  output         o_toVPRF_r_1_valid,
  output [6:0]   o_toVPRF_r_1_bits_addr,
  output         o_toVPRF_r_2_valid,
  output [6:0]   o_toVPRF_r_2_bits_addr,
  output         o_toVPRF_r_3_valid,
  output [6:0]   o_toVPRF_r_3_bits_addr,
  output         o_toVPRF_r_4_valid,
  output         o_toVPRF_r_4_bits_isV0,
  output [6:0]   o_toVPRF_r_4_bits_addr,
  output         o_toVPRF_r_5_valid,
  output [6:0]   o_toVPRF_r_5_bits_addr,
  output         o_toVPRF_r_6_valid,
  output [6:0]   o_toVPRF_r_6_bits_addr,
  output         o_toVPRF_r_7_valid,
  output [6:0]   o_toVPRF_r_7_bits_addr,
  output         o_toVPRF_w_0_valid,
  output         o_toVPRF_w_0_bits_isV0,
  output [6:0]   o_toVPRF_w_0_bits_newVdAddr,
  output [127:0] o_toVPRF_w_0_bits_newVdData,
  output         o_toVPRF_w_1_valid,
  output [6:0]   o_toVPRF_w_1_bits_newVdAddr,
  output [127:0] o_toVPRF_w_1_bits_newVdData,
  output         o_toVPRF_w_2_valid,
  output [6:0]   o_toVPRF_w_2_bits_newVdAddr,
  output [127:0] o_toVPRF_w_2_bits_newVdData,
  output         o_toVPRF_w_3_valid,
  output [6:0]   o_toVPRF_w_3_bits_newVdAddr,
  output [127:0] o_toVPRF_w_3_bits_newVdData,
  output         o_status_busy
);

  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_0_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_0_until;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_1_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_1_until;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_2_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_2_until;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_3_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_3_until;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_4_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_4_until;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_5_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_5_until;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_6_from;
  wire [7:0]      n_NfMappedElemIdx_out_idxRangeVec_6_until;
  wire [3:0]      g_GetE8OffsetInVreg_out_offset;
  wire [7:0][2:0] w_gen = '{3'h6, 3'h6, 3'h6, 3'h6, 3'h6, 3'h6, 3'h3, 3'h6};
  wire [7:0][2:0] w0 = '{3'h5, 3'h5, 3'h5, 3'h5, 3'h5, 3'h5, 3'h6, 3'h5};
  wire [7:0][2:0] w1 = '{3'h4, 3'h4, 3'h4, 3'h4, 3'h4, 3'h4, 3'h2, 3'h4};
  wire [7:0][2:0] w2 = '{3'h3, 3'h3, 3'h3, 3'h3, 3'h3, 3'h3, 3'h5, 3'h3};
  wire [7:0][2:0] w3 = '{3'h2, 3'h2, 3'h2, 3'h2, 3'h2, 3'h2, 3'h1, 3'h2};
  wire [7:0][2:0] w4 = '{3'h1, 3'h1, 3'h1, 3'h1, 3'h1, 3'h1, 3'h4, 3'h1};
  wire [7:0][2:0] w5 = '{3'h7, 3'h7, 3'h7, 3'h7, 3'h7, 3'h0, 3'h0, 3'h7};
  wire [7:0][2:0] w6 = '{3'h6, 3'h6, 3'h6, 3'h6, 3'h5, 3'h0, 3'h0, 3'h6};
  wire [7:0][2:0] w7 = '{3'h5, 3'h5, 3'h5, 3'h5, 3'h3, 3'h5, 3'h0, 3'h5};
  wire [7:0][2:0] w8 = '{3'h4, 3'h4, 3'h4, 3'h4, 3'h1, 3'h3, 3'h0, 3'h4};
  wire [7:0][2:0] w9 = '{3'h3, 3'h3, 3'h3, 3'h3, 3'h6, 3'h1, 3'h3, 3'h3};
  wire [7:0][2:0] w10 = '{3'h2, 3'h2, 3'h2, 3'h2, 3'h4, 3'h4, 3'h1, 3'h2};
  wire [7:0][2:0] w11 = '{3'h1, 3'h1, 3'h1, 3'h1, 3'h2, 3'h2, 3'h2, 3'h1};
  wire            oldPregVecFromRat_0_valid =
    i_fromRat_vecOldVdPdest_0_valid | i_fromRat_v0OldVdPdest_0_valid;
  wire            oldPregVecFromRat_1_valid =
    i_fromRat_vecOldVdPdest_1_valid | i_fromRat_v0OldVdPdest_1_valid;
  wire            oldPregVecFromRat_2_valid =
    i_fromRat_vecOldVdPdest_2_valid | i_fromRat_v0OldVdPdest_2_valid;
  wire            oldPregVecFromRat_3_valid =
    i_fromRat_vecOldVdPdest_3_valid | i_fromRat_v0OldVdPdest_3_valid;
  wire            oldPregVecFromRat_4_valid =
    i_fromRat_vecOldVdPdest_4_valid | i_fromRat_v0OldVdPdest_4_valid;
  wire            oldPregVecFromRat_5_valid =
    i_fromRat_vecOldVdPdest_5_valid | i_fromRat_v0OldVdPdest_5_valid;
  wire [2:0]      sNoExcp_vemul =
    3'(3'(i_fromExceptionGen_bits_vlmul + {1'h0, i_fromExceptionGen_bits_veew})
       - {1'h0, i_fromExceptionGen_bits_vsew});
  wire [2:0]      sNoExcp_ivemul = sNoExcp_vemul;
  wire [2:0]      sNoExcp_dvemul =
    i_fromExceptionGen_bits_isIndexed ? i_fromExceptionGen_bits_vlmul : sNoExcp_vemul;
  wire [1:0]      sNoExcp_dvemulNoLessThanM1_t1 =
    sNoExcp_dvemul[2] ? 2'h0 : sNoExcp_dvemul[1:0];
  reg             commitNeeded_0;
  reg             commitNeeded_1;
  reg             commitNeeded_2;
  reg             commitNeeded_3;
  reg             commitNeeded_4;
  reg             commitNeeded_5;
  reg             commitNeeded_6;
  reg             commitNeeded_7;
  reg             rabCommitted_0;
  reg             rabCommitted_1;
  reg             rabCommitted_2;
  reg             rabCommitted_3;
  reg             rabCommitted_4;
  reg             rabCommitted_5;
  reg             rabCommitted_6;
  reg             rabCommitted_7;
  reg             ratCommitted_0;
  reg             ratCommitted_1;
  reg             ratCommitted_2;
  reg             ratCommitted_3;
  reg             ratCommitted_4;
  reg             ratCommitted_5;
  reg             ratCommitted_6;
  reg             ratCommitted_7;
  reg             hasReadRf_0;
  reg             hasReadRf_1;
  reg             hasReadRf_2;
  reg             hasReadRf_3;
  reg             hasReadRf_4;
  reg             hasReadRf_5;
  reg             hasReadRf_6;
  reg             hasReadRf_7;
  reg  [5:0]      regMaps_0_lreg;
  reg  [6:0]      regMaps_0_newPreg;
  reg  [6:0]      regMaps_0_oldPreg;
  reg  [5:0]      regMaps_1_lreg;
  reg  [6:0]      regMaps_1_newPreg;
  reg  [6:0]      regMaps_1_oldPreg;
  reg  [5:0]      regMaps_2_lreg;
  reg  [6:0]      regMaps_2_newPreg;
  reg  [6:0]      regMaps_2_oldPreg;
  reg  [5:0]      regMaps_3_lreg;
  reg  [6:0]      regMaps_3_newPreg;
  reg  [6:0]      regMaps_3_oldPreg;
  reg  [5:0]      regMaps_4_lreg;
  reg  [6:0]      regMaps_4_newPreg;
  reg  [6:0]      regMaps_4_oldPreg;
  reg  [5:0]      regMaps_5_lreg;
  reg  [6:0]      regMaps_5_newPreg;
  reg  [6:0]      regMaps_5_oldPreg;
  reg  [5:0]      regMaps_6_lreg;
  reg  [6:0]      regMaps_6_newPreg;
  reg  [6:0]      regMaps_6_oldPreg;
  reg  [5:0]      regMaps_7_lreg;
  reg  [6:0]      regMaps_7_newPreg;
  reg  [6:0]      regMaps_7_oldPreg;
  reg  [3:0]      currentIdx;
  wire [3:0]      currentIdxVec_t1 = 4'(currentIdx + 4'h1);
  wire [3:0]      currentIdxVec_t2 = 4'(currentIdx + 4'h2);
  wire [3:0]      currentIdxVec_t3 = 4'(currentIdx + 4'h3);
  reg  [127:0]    mergedVd_0_rawData;
  reg  [127:0]    mergedVd_1_rawData;
  reg  [127:0]    mergedVd_2_rawData;
  reg  [127:0]    mergedVd_3_rawData;
  wire [3:0]      sNoExcp_deewOH =
    i_fromExceptionGen_bits_isIndexed
      ? 4'h1 << i_fromExceptionGen_bits_vsew
      : 4'h1 << i_fromExceptionGen_bits_veew;
  wire [6:0]      w12 = {3'h0, 4'({1'h0, i_fromExceptionGen_bits_nf} + 4'h1)};
  wire [6:0]      sNoExcp_maxVdIdx =
    i_fromExceptionGen_valid
      ? (i_fromExceptionGen_bits_isVlm
           ? 7'h1
           : i_fromExceptionGen_bits_isWhole
               ? w12
               : w12 << sNoExcp_dvemulNoLessThanM1_t1)
      : 7'h0;
  reg  [2:0]      sWaitRab_vecExcpInfo_next_bits_r_nf;
  reg             sWaitRab_vecExcpInfo_next_bits_r_isStride;
  reg             sWaitRab_vecExcpInfo_next_bits_r_isWhole;
  reg  [2:0]      sWaitRab_useNewVdUntil;
  reg  [3:0]      sWaitRab_needMergeUntil;
  reg  [3:0]      sWaitRab_e8offset;
  reg  [3:0]      sWaitRab_handleUntil;
  reg             sWaitRab_nonSegIndexed;
  reg             sWaitRab_vemul_i_d_0;
  reg             sWaitRab_vemul_i_d_1;
  reg             sWaitRab_vemul_i_d_2;
  reg             sWaitRab_vemul_i_d_3;
  reg  [1:0]      sWaitRab_dvemulNoLessThanM1;
  reg  [3:0]      sWaitRab_rabWriteOffset;
  reg  [3:0]      sWaitRab_ratWriteOffset;
  wire [3:0][2:0] w13 =
    {{3'h1},
     {w4[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {w11[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {3'h1}};
  wire [3:0][2:0] w14 =
    {{3'h2},
     {w3[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {w10[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {3'h2}};
  wire [3:0][2:0] w15 =
    {{3'h3},
     {w2[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {w9[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {3'h3}};
  wire [3:0][2:0] w16 =
    {{3'h4},
     {w1[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {w8[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {3'h4}};
  wire [3:0][2:0] w17 =
    {{3'h5},
     {w0[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {w7[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {3'h5}};
  wire [3:0][2:0] w18 =
    {{3'h6},
     {w_gen[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {w6[sWaitRab_vecExcpInfo_next_bits_r_nf]},
     {3'h6}};
  wire [3:0][2:0] w19 =
    {{3'h7}, {3'h7}, {w5[sWaitRab_vecExcpInfo_next_bits_r_nf]}, {3'h7}};
  wire [7:0][2:0] w20 =
    {{w19[sWaitRab_dvemulNoLessThanM1]},
     {w18[sWaitRab_dvemulNoLessThanM1]},
     {w17[sWaitRab_dvemulNoLessThanM1]},
     {w16[sWaitRab_dvemulNoLessThanM1]},
     {w15[sWaitRab_dvemulNoLessThanM1]},
     {w14[sWaitRab_dvemulNoLessThanM1]},
     {w13[sWaitRab_dvemulNoLessThanM1]},
     {3'h0}};
  wire [2:0]      w21 = w20[currentIdx[2:0]];
  wire [2:0]      oldVdLocVec_0 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdx[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdx[1:0], 1'h0} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdx[0], 2'h0} : 3'h0)
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdx[2:0] : w21;
  wire [2:0]      w22 = w20[currentIdxVec_t1[2:0]];
  wire [2:0]      oldVdLocVec_1 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdxVec_t1[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdxVec_t1[1:0], 1'h0} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdxVec_t1[0], 2'h0} : 3'h0)
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdxVec_t1[2:0] : w22;
  wire [2:0]      w23 = w20[currentIdxVec_t2[2:0]];
  wire [2:0]      oldVdLocVec_2 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdxVec_t2[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdxVec_t2[1:0], 1'h0} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdxVec_t2[0], 2'h0} : 3'h0)
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdxVec_t2[2:0] : w23;
  wire [2:0]      w24 = w20[currentIdxVec_t3[2:0]];
  wire [2:0]      oldVdLocVec_3 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdxVec_t3[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdxVec_t3[1:0], 1'h0} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdxVec_t3[0], 2'h0} : 3'h0)
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdxVec_t3[2:0] : w24;
  wire [2:0]      newVdLocVec_0 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdx[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdx[1:0], 1'h1} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdx[0], 2'h3} : 3'h0)
        | {3{sWaitRab_vemul_i_d_3}}
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdx[2:0] : w21;
  wire [2:0]      newVdLocVec_1 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdxVec_t1[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdxVec_t1[1:0], 1'h1} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdxVec_t1[0], 2'h3} : 3'h0)
        | {3{sWaitRab_vemul_i_d_3}}
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdxVec_t1[2:0] : w22;
  wire [2:0]      newVdLocVec_2 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdxVec_t2[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdxVec_t2[1:0], 1'h1} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdxVec_t2[0], 2'h3} : 3'h0)
        | {3{sWaitRab_vemul_i_d_3}}
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdxVec_t2[2:0] : w23;
  wire [2:0]      newVdLocVec_3 =
    sWaitRab_nonSegIndexed
      ? (sWaitRab_vemul_i_d_0 ? currentIdxVec_t3[2:0] : 3'h0)
        | (sWaitRab_vemul_i_d_1 ? {currentIdxVec_t3[1:0], 1'h1} : 3'h0)
        | (sWaitRab_vemul_i_d_2 ? {currentIdxVec_t3[0], 2'h3} : 3'h0)
        | {3{sWaitRab_vemul_i_d_3}}
      : sWaitRab_vecExcpInfo_next_bits_r_isWhole ? currentIdxVec_t3[2:0] : w24;
  reg  [2:0]      state;
  wire            mvFinished = currentIdx >= sWaitRab_handleUntil;
  wire            w25 = sWaitRab_vemul_i_d_3 & rabCommitted_0;
  wire            w26 = sWaitRab_vemul_i_d_2 & rabCommitted_0;
  wire            w27 = sWaitRab_vemul_i_d_1 & rabCommitted_0;
  wire            w28 = sWaitRab_vemul_i_d_1 & ratCommitted_0;
  wire            w29 = sWaitRab_vemul_i_d_2 & ratCommitted_0;
  wire            w30 = sWaitRab_vemul_i_d_3 & ratCommitted_0;
  wire [7:0]      collectedAllRegMap_t7 =
    ~{commitNeeded_7,
      commitNeeded_6,
      commitNeeded_5,
      commitNeeded_4,
      commitNeeded_3,
      commitNeeded_2,
      commitNeeded_1,
      commitNeeded_0}
    | {commitNeeded_7,
       commitNeeded_6,
       commitNeeded_5,
       commitNeeded_4,
       commitNeeded_3,
       commitNeeded_2,
       commitNeeded_1,
       commitNeeded_0}
    & {sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_7 | w27 | w26 | w25
         : rabCommitted_7,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_6 | w27 | w26 | w25
         : rabCommitted_6,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_5 | w27 | w26 | w25
         : rabCommitted_5,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_4 | w27 | w26 | w25
         : rabCommitted_4,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_3 | sWaitRab_vemul_i_d_1 & rabCommitted_7
           | w26 | w25
         : rabCommitted_3,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_2 | sWaitRab_vemul_i_d_1 & rabCommitted_5
           | w26 | w25
         : rabCommitted_2,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_1 | sWaitRab_vemul_i_d_1 & rabCommitted_3
           | sWaitRab_vemul_i_d_2 & rabCommitted_7 | w25
         : rabCommitted_1,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & rabCommitted_0 | sWaitRab_vemul_i_d_1 & rabCommitted_1
           | sWaitRab_vemul_i_d_2 & rabCommitted_3 | sWaitRab_vemul_i_d_3 & rabCommitted_7
         : rabCommitted_0}
    & {sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_7 | w28 | w29 | w30
         : ratCommitted_7,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_6 | w28 | w29 | w30
         : ratCommitted_6,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_5 | w28 | w29 | w30
         : ratCommitted_5,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_4 | w28 | w29 | w30
         : ratCommitted_4,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_3 | sWaitRab_vemul_i_d_1 & ratCommitted_6
           | w29 | w30
         : ratCommitted_3,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_2 | sWaitRab_vemul_i_d_1 & ratCommitted_4
           | w29 | w30
         : ratCommitted_2,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_1 | sWaitRab_vemul_i_d_1 & ratCommitted_2
           | sWaitRab_vemul_i_d_2 & ratCommitted_4 | w30
         : ratCommitted_1,
       sWaitRab_nonSegIndexed
         ? sWaitRab_vemul_i_d_0 & ratCommitted_0 | w28 | w29 | w30
         : ratCommitted_0};
  wire            w31 = state == 3'h0;
  wire            w32 = state == 3'h1;
  wire            w33 = state == 3'h3;
  wire            w34 = state == 3'h4;
  wire [7:0][2:0] w35 =
    {{state},
     {state},
     {state},
     {3'h0},
     {mvFinished ? 3'h4 : state},
     {mvFinished ? 3'h4 : currentIdx >= sWaitRab_needMergeUntil ? 3'h3 : state},
     {(&collectedAllRegMap_t7) ? 3'h2 : state},
     {i_fromExceptionGen_valid ? 3'h1 : state}};
  wire [2:0]      stateNext = w35[state];
  wire            o_status_busy_t1 = state == 3'h2;
  wire            w36 = stateNext == 3'h1;
  wire            w37 = sWaitRab_rabWriteOffset == 4'h0;
  wire            w38 =
    sWaitRab_vecExcpInfo_next_bits_r_isStride & i_fromRab_logicPhyRegMap_0_valid;
  wire            w39 = sWaitRab_ratWriteOffset == 4'h0;
  wire            w40 =
    sWaitRab_vecExcpInfo_next_bits_r_isStride & oldPregVecFromRat_0_valid;
  wire [7:0]      w41 =
    {{hasReadRf_7},
     {hasReadRf_6},
     {hasReadRf_5},
     {hasReadRf_4},
     {hasReadRf_3},
     {hasReadRf_2},
     {hasReadRf_1},
     {hasReadRf_0}};
  wire            w42 = w41[currentIdx[2:0]];
  wire [7:0]      w43 =
    {{commitNeeded_7},
     {commitNeeded_6},
     {commitNeeded_5},
     {commitNeeded_4},
     {commitNeeded_3},
     {commitNeeded_2},
     {commitNeeded_1},
     {commitNeeded_0}};
  wire            w44 = w43[currentIdx[2:0]];
  wire            hasReadRf_t1 = currentIdx < sWaitRab_needMergeUntil;
  wire [7:0][5:0] w45 =
    {{regMaps_7_lreg},
     {regMaps_6_lreg},
     {regMaps_5_lreg},
     {regMaps_4_lreg},
     {regMaps_3_lreg},
     {regMaps_2_lreg},
     {regMaps_1_lreg},
     {regMaps_0_lreg}};
  wire [7:0][6:0] w46 =
    {{regMaps_7_oldPreg},
     {regMaps_6_oldPreg},
     {regMaps_5_oldPreg},
     {regMaps_4_oldPreg},
     {regMaps_3_oldPreg},
     {regMaps_2_oldPreg},
     {regMaps_1_oldPreg},
     {regMaps_0_oldPreg}};
  wire [7:0][6:0] w47 =
    {{regMaps_7_newPreg},
     {regMaps_6_newPreg},
     {regMaps_5_newPreg},
     {regMaps_4_newPreg},
     {regMaps_3_newPreg},
     {regMaps_2_newPreg},
     {regMaps_1_newPreg},
     {regMaps_0_newPreg}};
  wire            w48 = w41[currentIdxVec_t1[2:0]];
  wire            w49 = w43[currentIdxVec_t1[2:0]];
  wire            hasReadRf_t3 = currentIdxVec_t1 < sWaitRab_needMergeUntil;
  wire            w50 = w41[currentIdxVec_t2[2:0]];
  wire            w51 = w43[currentIdxVec_t2[2:0]];
  wire            hasReadRf_t5 = currentIdxVec_t2 < sWaitRab_needMergeUntil;
  wire            w52 = w41[currentIdxVec_t3[2:0]];
  wire            w53 = w43[currentIdxVec_t3[2:0]];
  wire            hasReadRf_t7 = currentIdxVec_t3 < sWaitRab_needMergeUntil;
  wire            hasReadRf_t9 = currentIdx < sWaitRab_handleUntil;
  wire            hasReadRf_t11 = currentIdxVec_t1 < sWaitRab_handleUntil;
  wire            hasReadRf_t13 = currentIdxVec_t2 < sWaitRab_handleUntil;
  wire            hasReadRf_t15 = currentIdxVec_t3 < sWaitRab_handleUntil;
  wire            w54 = o_status_busy_t1 | w33;
  reg             o_toVPRF_w_0_valid_REG;
  reg             o_toVPRF_w_1_valid_REG;
  reg             o_toVPRF_w_2_valid_REG;
  reg             o_toVPRF_w_3_valid_REG;
  wire            w55 = w32 | ~w34;
  wire [1:0]      w56 = {1'h0, o_toVPRF_w_0_valid_REG};
  wire [1:0]      w57 = {1'h0, o_toVPRF_w_1_valid_REG};
  wire [1:0]      w58 = {1'h0, o_toVPRF_w_2_valid_REG};
  wire [1:0]      w59 = {1'h0, o_toVPRF_w_3_valid_REG};
  wire            w60 = w31 | w32 | ~w34;
  wire            w61 = w60 & hasReadRf_0;
  wire            w62 = w60 & hasReadRf_1;
  wire            w63 = w60 & hasReadRf_2;
  wire            w64 = w60 & hasReadRf_3;
  wire            w65 = w60 & hasReadRf_4;
  wire            w66 = w60 & hasReadRf_5;
  wire            w67 = w60 & hasReadRf_6;
  wire            w68 = w60 & hasReadRf_7;
  wire            w69 = currentIdx[2:0] == 3'h0;
  wire            w70 = currentIdx[2:0] == 3'h1;
  wire            w71 = currentIdx[2:0] == 3'h2;
  wire            w72 = currentIdx[2:0] == 3'h3;
  wire            w73 = currentIdx[2:0] == 3'h4;
  wire            w74 = currentIdx[2:0] == 3'h5;
  wire            w75 = currentIdx[2:0] == 3'h6;
  wire            w76 = currentIdxVec_t1[2:0] == 3'h0;
  wire            w77 = currentIdxVec_t1[2:0] == 3'h1;
  wire            w78 = currentIdxVec_t1[2:0] == 3'h2;
  wire            w79 = currentIdxVec_t1[2:0] == 3'h3;
  wire            w80 = currentIdxVec_t1[2:0] == 3'h4;
  wire            w81 = currentIdxVec_t1[2:0] == 3'h5;
  wire            w82 = currentIdxVec_t1[2:0] == 3'h6;
  wire            w83 = currentIdxVec_t2[2:0] == 3'h0;
  wire            w84 = currentIdxVec_t2[2:0] == 3'h1;
  wire            w85 = currentIdxVec_t2[2:0] == 3'h2;
  wire            w86 = currentIdxVec_t2[2:0] == 3'h3;
  wire            w87 = currentIdxVec_t2[2:0] == 3'h4;
  wire            w88 = currentIdxVec_t2[2:0] == 3'h5;
  wire            w89 = currentIdxVec_t2[2:0] == 3'h6;
  wire            w90 = currentIdxVec_t3[2:0] == 3'h0;
  wire            w91 = currentIdxVec_t3[2:0] == 3'h1;
  wire            w92 = currentIdxVec_t3[2:0] == 3'h2;
  wire            w93 = currentIdxVec_t3[2:0] == 3'h3;
  wire            w94 = currentIdxVec_t3[2:0] == 3'h4;
  wire            w95 = currentIdxVec_t3[2:0] == 3'h5;
  wire            w96 = currentIdxVec_t3[2:0] == 3'h6;
  wire [7:0][3:0] w97 =
    {{currentIdx},
     {currentIdx},
     {currentIdx},
     {4'h0},
     {o_toVPRF_w_0_valid_REG
        ? 4'(currentIdx
             + {1'h0, 3'({1'h0, 2'(w56 + w57)} + {1'h0, 2'(w58 + w59)})})
        : currentIdx},
     {o_toVPRF_w_0_valid_REG
        ? 4'(currentIdx
             + {1'h0, 3'({1'h0, 2'(w56 + w57)} + {1'h0, 2'(w58 + w59)})})
        : currentIdx},
     {(&collectedAllRegMap_t7) ? {1'h0, sWaitRab_useNewVdUntil} : currentIdx},
     {currentIdx}};
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      commitNeeded_0 <= 1'h0;
      commitNeeded_1 <= 1'h0;
      commitNeeded_2 <= 1'h0;
      commitNeeded_3 <= 1'h0;
      commitNeeded_4 <= 1'h0;
      commitNeeded_5 <= 1'h0;
      commitNeeded_6 <= 1'h0;
      commitNeeded_7 <= 1'h0;
      rabCommitted_0 <= 1'h0;
      rabCommitted_1 <= 1'h0;
      rabCommitted_2 <= 1'h0;
      rabCommitted_3 <= 1'h0;
      rabCommitted_4 <= 1'h0;
      rabCommitted_5 <= 1'h0;
      rabCommitted_6 <= 1'h0;
      rabCommitted_7 <= 1'h0;
      ratCommitted_0 <= 1'h0;
      ratCommitted_1 <= 1'h0;
      ratCommitted_2 <= 1'h0;
      ratCommitted_3 <= 1'h0;
      ratCommitted_4 <= 1'h0;
      ratCommitted_5 <= 1'h0;
      ratCommitted_6 <= 1'h0;
      ratCommitted_7 <= 1'h0;
      hasReadRf_0 <= 1'h0;
      hasReadRf_1 <= 1'h0;
      hasReadRf_2 <= 1'h0;
      hasReadRf_3 <= 1'h0;
      hasReadRf_4 <= 1'h0;
      hasReadRf_5 <= 1'h0;
      hasReadRf_6 <= 1'h0;
      hasReadRf_7 <= 1'h0;
      currentIdx <= 4'h0;
      state <= 3'h0;
    end
    else begin
      if (w31) begin
        if (w36) begin
          commitNeeded_0 <= |sNoExcp_maxVdIdx;
          commitNeeded_1 <= |(sNoExcp_maxVdIdx[6:1]);
          commitNeeded_2 <= sNoExcp_maxVdIdx > 7'h2;
          commitNeeded_3 <= |(sNoExcp_maxVdIdx[6:2]);
          commitNeeded_4 <= sNoExcp_maxVdIdx > 7'h4;
          commitNeeded_5 <= sNoExcp_maxVdIdx > 7'h5;
          commitNeeded_6 <= sNoExcp_maxVdIdx > 7'h6;
          commitNeeded_7 <= |(sNoExcp_maxVdIdx[6:3]);
        end
      end
      else begin
        commitNeeded_0 <= w55 & commitNeeded_0;
        commitNeeded_1 <= w55 & commitNeeded_1;
        commitNeeded_2 <= w55 & commitNeeded_2;
        commitNeeded_3 <= w55 & commitNeeded_3;
        commitNeeded_4 <= w55 & commitNeeded_4;
        commitNeeded_5 <= w55 & commitNeeded_5;
        commitNeeded_6 <= w55 & commitNeeded_6;
        commitNeeded_7 <= w55 & commitNeeded_7;
        if (w32) begin
          if (w37) begin
            if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
              rabCommitted_0 <= i_fromRab_logicPhyRegMap_2_valid | rabCommitted_0;
              rabCommitted_1 <= i_fromRab_logicPhyRegMap_3_valid | rabCommitted_1;
              rabCommitted_2 <= i_fromRab_logicPhyRegMap_4_valid | rabCommitted_2;
              rabCommitted_3 <= i_fromRab_logicPhyRegMap_5_valid | rabCommitted_3;
            end
            else begin
              rabCommitted_0 <= i_fromRab_logicPhyRegMap_1_valid | rabCommitted_0;
              rabCommitted_1 <= i_fromRab_logicPhyRegMap_2_valid | rabCommitted_1;
              rabCommitted_2 <= i_fromRab_logicPhyRegMap_3_valid | rabCommitted_2;
              rabCommitted_3 <= i_fromRab_logicPhyRegMap_4_valid | rabCommitted_3;
            end
            rabCommitted_4 <=
              ~sWaitRab_vecExcpInfo_next_bits_r_isStride
              & i_fromRab_logicPhyRegMap_5_valid | rabCommitted_4;
          end
          else begin
            rabCommitted_4 <= w38 | rabCommitted_4;
            if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
              rabCommitted_5 <= i_fromRab_logicPhyRegMap_1_valid | rabCommitted_5;
              rabCommitted_6 <= i_fromRab_logicPhyRegMap_2_valid | rabCommitted_6;
              rabCommitted_7 <= i_fromRab_logicPhyRegMap_3_valid | rabCommitted_7;
            end
            else begin
              rabCommitted_5 <= i_fromRab_logicPhyRegMap_0_valid | rabCommitted_5;
              rabCommitted_6 <= i_fromRab_logicPhyRegMap_1_valid | rabCommitted_6;
              rabCommitted_7 <= i_fromRab_logicPhyRegMap_2_valid | rabCommitted_7;
            end
          end
          if (w39) begin
            if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
              ratCommitted_0 <= oldPregVecFromRat_2_valid | ratCommitted_0;
              ratCommitted_1 <= oldPregVecFromRat_3_valid | ratCommitted_1;
              ratCommitted_2 <= oldPregVecFromRat_4_valid | ratCommitted_2;
              ratCommitted_3 <= oldPregVecFromRat_5_valid | ratCommitted_3;
            end
            else begin
              ratCommitted_0 <= oldPregVecFromRat_1_valid | ratCommitted_0;
              ratCommitted_1 <= oldPregVecFromRat_2_valid | ratCommitted_1;
              ratCommitted_2 <= oldPregVecFromRat_3_valid | ratCommitted_2;
              ratCommitted_3 <= oldPregVecFromRat_4_valid | ratCommitted_3;
            end
            ratCommitted_4 <=
              ~sWaitRab_vecExcpInfo_next_bits_r_isStride & oldPregVecFromRat_5_valid
              | ratCommitted_4;
          end
          else begin
            ratCommitted_4 <= w40 | ratCommitted_4;
            if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
              ratCommitted_5 <= oldPregVecFromRat_1_valid | ratCommitted_5;
              ratCommitted_6 <= oldPregVecFromRat_2_valid | ratCommitted_6;
              ratCommitted_7 <= oldPregVecFromRat_3_valid | ratCommitted_7;
            end
            else begin
              ratCommitted_5 <= oldPregVecFromRat_0_valid | ratCommitted_5;
              ratCommitted_6 <= oldPregVecFromRat_1_valid | ratCommitted_6;
              ratCommitted_7 <= oldPregVecFromRat_2_valid | ratCommitted_7;
            end
          end
        end
        else begin
          rabCommitted_0 <= ~w34 & rabCommitted_0;
          rabCommitted_1 <= ~w34 & rabCommitted_1;
          rabCommitted_2 <= ~w34 & rabCommitted_2;
          rabCommitted_3 <= ~w34 & rabCommitted_3;
          rabCommitted_4 <= ~w34 & rabCommitted_4;
          rabCommitted_5 <= ~w34 & rabCommitted_5;
          rabCommitted_6 <= ~w34 & rabCommitted_6;
          rabCommitted_7 <= ~w34 & rabCommitted_7;
          ratCommitted_0 <= ~w34 & ratCommitted_0;
          ratCommitted_1 <= ~w34 & ratCommitted_1;
          ratCommitted_2 <= ~w34 & ratCommitted_2;
          ratCommitted_3 <= ~w34 & ratCommitted_3;
          ratCommitted_4 <= ~w34 & ratCommitted_4;
          ratCommitted_5 <= ~w34 & ratCommitted_5;
          ratCommitted_6 <= ~w34 & ratCommitted_6;
          ratCommitted_7 <= ~w34 & ratCommitted_7;
        end
      end
      if (o_status_busy_t1) begin
        if (w90)
          hasReadRf_0 <= hasReadRf_t7;
        else if (w83)
          hasReadRf_0 <= hasReadRf_t5;
        else if (w76)
          hasReadRf_0 <= hasReadRf_t3;
        else if (w69)
          hasReadRf_0 <= hasReadRf_t1;
        else
          hasReadRf_0 <= w61;
        if (w91)
          hasReadRf_1 <= hasReadRf_t7;
        else if (w84)
          hasReadRf_1 <= hasReadRf_t5;
        else if (w77)
          hasReadRf_1 <= hasReadRf_t3;
        else if (w70)
          hasReadRf_1 <= hasReadRf_t1;
        else
          hasReadRf_1 <= w62;
        if (w92)
          hasReadRf_2 <= hasReadRf_t7;
        else if (w85)
          hasReadRf_2 <= hasReadRf_t5;
        else if (w78)
          hasReadRf_2 <= hasReadRf_t3;
        else if (w71)
          hasReadRf_2 <= hasReadRf_t1;
        else
          hasReadRf_2 <= w63;
        if (w93)
          hasReadRf_3 <= hasReadRf_t7;
        else if (w86)
          hasReadRf_3 <= hasReadRf_t5;
        else if (w79)
          hasReadRf_3 <= hasReadRf_t3;
        else if (w72)
          hasReadRf_3 <= hasReadRf_t1;
        else
          hasReadRf_3 <= w64;
        if (w94)
          hasReadRf_4 <= hasReadRf_t7;
        else if (w87)
          hasReadRf_4 <= hasReadRf_t5;
        else if (w80)
          hasReadRf_4 <= hasReadRf_t3;
        else if (w73)
          hasReadRf_4 <= hasReadRf_t1;
        else
          hasReadRf_4 <= w65;
        if (w95)
          hasReadRf_5 <= hasReadRf_t7;
        else if (w88)
          hasReadRf_5 <= hasReadRf_t5;
        else if (w81)
          hasReadRf_5 <= hasReadRf_t3;
        else if (w74)
          hasReadRf_5 <= hasReadRf_t1;
        else
          hasReadRf_5 <= w66;
        if (w96)
          hasReadRf_6 <= hasReadRf_t7;
        else if (w89)
          hasReadRf_6 <= hasReadRf_t5;
        else if (w82)
          hasReadRf_6 <= hasReadRf_t3;
        else if (w75)
          hasReadRf_6 <= hasReadRf_t1;
        else
          hasReadRf_6 <= w67;
        if (&(currentIdxVec_t3[2:0]))
          hasReadRf_7 <= hasReadRf_t7;
        else if (&(currentIdxVec_t2[2:0]))
          hasReadRf_7 <= hasReadRf_t5;
        else if (&(currentIdxVec_t1[2:0]))
          hasReadRf_7 <= hasReadRf_t3;
        else if (&(currentIdx[2:0]))
          hasReadRf_7 <= hasReadRf_t1;
        else
          hasReadRf_7 <= w68;
      end
      else if (w33) begin
        if (w90)
          hasReadRf_0 <= hasReadRf_t15;
        else if (w83)
          hasReadRf_0 <= hasReadRf_t13;
        else if (w76)
          hasReadRf_0 <= hasReadRf_t11;
        else if (w69)
          hasReadRf_0 <= hasReadRf_t9;
        else
          hasReadRf_0 <= w61;
        if (w91)
          hasReadRf_1 <= hasReadRf_t15;
        else if (w84)
          hasReadRf_1 <= hasReadRf_t13;
        else if (w77)
          hasReadRf_1 <= hasReadRf_t11;
        else if (w70)
          hasReadRf_1 <= hasReadRf_t9;
        else
          hasReadRf_1 <= w62;
        if (w92)
          hasReadRf_2 <= hasReadRf_t15;
        else if (w85)
          hasReadRf_2 <= hasReadRf_t13;
        else if (w78)
          hasReadRf_2 <= hasReadRf_t11;
        else if (w71)
          hasReadRf_2 <= hasReadRf_t9;
        else
          hasReadRf_2 <= w63;
        if (w93)
          hasReadRf_3 <= hasReadRf_t15;
        else if (w86)
          hasReadRf_3 <= hasReadRf_t13;
        else if (w79)
          hasReadRf_3 <= hasReadRf_t11;
        else if (w72)
          hasReadRf_3 <= hasReadRf_t9;
        else
          hasReadRf_3 <= w64;
        if (w94)
          hasReadRf_4 <= hasReadRf_t15;
        else if (w87)
          hasReadRf_4 <= hasReadRf_t13;
        else if (w80)
          hasReadRf_4 <= hasReadRf_t11;
        else if (w73)
          hasReadRf_4 <= hasReadRf_t9;
        else
          hasReadRf_4 <= w65;
        if (w95)
          hasReadRf_5 <= hasReadRf_t15;
        else if (w88)
          hasReadRf_5 <= hasReadRf_t13;
        else if (w81)
          hasReadRf_5 <= hasReadRf_t11;
        else if (w74)
          hasReadRf_5 <= hasReadRf_t9;
        else
          hasReadRf_5 <= w66;
        if (w96)
          hasReadRf_6 <= hasReadRf_t15;
        else if (w89)
          hasReadRf_6 <= hasReadRf_t13;
        else if (w82)
          hasReadRf_6 <= hasReadRf_t11;
        else if (w75)
          hasReadRf_6 <= hasReadRf_t9;
        else
          hasReadRf_6 <= w67;
        if (&(currentIdxVec_t3[2:0]))
          hasReadRf_7 <= hasReadRf_t15;
        else if (&(currentIdxVec_t2[2:0]))
          hasReadRf_7 <= hasReadRf_t13;
        else if (&(currentIdxVec_t1[2:0]))
          hasReadRf_7 <= hasReadRf_t11;
        else if (&(currentIdx[2:0]))
          hasReadRf_7 <= hasReadRf_t9;
        else
          hasReadRf_7 <= w68;
      end
      else begin
        hasReadRf_0 <= w61;
        hasReadRf_1 <= w62;
        hasReadRf_2 <= w63;
        hasReadRf_3 <= w64;
        hasReadRf_4 <= w65;
        hasReadRf_5 <= w66;
        hasReadRf_6 <= w67;
        hasReadRf_7 <= w68;
      end
      currentIdx <= w97[state];
      state <= stateNext;
    end
  end // always @(posedge, posedge)
  wire [1:0]      sNoExcp_ivemulNoLessThanM1_t1 =
    sNoExcp_ivemul[2] ? 2'h0 : sNoExcp_ivemul[1:0];
  wire [2:0]      w98 = {1'h0, sNoExcp_dvemulNoLessThanM1_t1};
  wire [2:0]      w99 = {1'h0, sNoExcp_ivemulNoLessThanM1_t1};
  wire [7:0]      w100 = {1'h0, i_fromExceptionGen_bits_vstart};
  wire [2:0]      sNoExcp_useNewVdUntil =
    i_fromExceptionGen_bits_isVlm | w100 >= n_NfMappedElemIdx_out_idxRangeVec_0_from
    & w100 < n_NfMappedElemIdx_out_idxRangeVec_0_until
      ? 3'h0
      : ~i_fromExceptionGen_bits_isVlm
        & w100 >= n_NfMappedElemIdx_out_idxRangeVec_1_from
        & w100 < n_NfMappedElemIdx_out_idxRangeVec_1_until
          ? 3'h1
          : ~i_fromExceptionGen_bits_isVlm
            & w100 >= n_NfMappedElemIdx_out_idxRangeVec_2_from
            & w100 < n_NfMappedElemIdx_out_idxRangeVec_2_until
              ? 3'h2
              : ~i_fromExceptionGen_bits_isVlm
                & w100 >= n_NfMappedElemIdx_out_idxRangeVec_3_from
                & w100 < n_NfMappedElemIdx_out_idxRangeVec_3_until
                  ? 3'h3
                  : ~i_fromExceptionGen_bits_isVlm
                    & w100 >= n_NfMappedElemIdx_out_idxRangeVec_4_from
                    & w100 < n_NfMappedElemIdx_out_idxRangeVec_4_until
                      ? 3'h4
                      : ~i_fromExceptionGen_bits_isVlm
                        & w100 >= n_NfMappedElemIdx_out_idxRangeVec_5_from
                        & w100 < n_NfMappedElemIdx_out_idxRangeVec_5_until
                          ? 3'h5
                          : {2'h3,
                             ~(~i_fromExceptionGen_bits_isVlm
                               & w100 >= n_NfMappedElemIdx_out_idxRangeVec_6_from
                               & w100 < n_NfMappedElemIdx_out_idxRangeVec_6_until)};
  wire [6:0]      oldPregVecFromRat_0_bits_t2 =
    (i_fromRat_vecOldVdPdest_0_valid ? i_fromRat_vecOldVdPdest_0_bits : 7'h0)
    | (i_fromRat_v0OldVdPdest_0_valid ? i_fromRat_v0OldVdPdest_0_bits : 7'h0);
  wire [6:0]      oldPregVecFromRat_1_bits_t2 =
    (i_fromRat_vecOldVdPdest_1_valid ? i_fromRat_vecOldVdPdest_1_bits : 7'h0)
    | (i_fromRat_v0OldVdPdest_1_valid ? i_fromRat_v0OldVdPdest_1_bits : 7'h0);
  wire [6:0]      oldPregVecFromRat_2_bits_t2 =
    (i_fromRat_vecOldVdPdest_2_valid ? i_fromRat_vecOldVdPdest_2_bits : 7'h0)
    | (i_fromRat_v0OldVdPdest_2_valid ? i_fromRat_v0OldVdPdest_2_bits : 7'h0);
  wire [6:0]      oldPregVecFromRat_3_bits_t2 =
    (i_fromRat_vecOldVdPdest_3_valid ? i_fromRat_vecOldVdPdest_3_bits : 7'h0)
    | (i_fromRat_v0OldVdPdest_3_valid ? i_fromRat_v0OldVdPdest_3_bits : 7'h0);
  wire [6:0]      oldPregVecFromRat_4_bits_t2 =
    (i_fromRat_vecOldVdPdest_4_valid ? i_fromRat_vecOldVdPdest_4_bits : 7'h0)
    | (i_fromRat_v0OldVdPdest_4_valid ? i_fromRat_v0OldVdPdest_4_bits : 7'h0);
  wire [6:0]      oldPregVecFromRat_5_bits_t2 =
    (i_fromRat_vecOldVdPdest_5_valid ? i_fromRat_vecOldVdPdest_5_bits : 7'h0)
    | (i_fromRat_v0OldVdPdest_5_valid ? i_fromRat_v0OldVdPdest_5_bits : 7'h0);
  wire            mergedVdWData_3_data_0_t1 = sWaitRab_e8offset == 4'h0;
  wire            mergedVdWData_3_data_1_t1 = sWaitRab_e8offset < 4'h2;
  wire            mergedVdWData_3_data_2_t1 = sWaitRab_e8offset < 4'h3;
  wire            mergedVdWData_3_data_3_t1 = sWaitRab_e8offset < 4'h4;
  wire            mergedVdWData_3_data_4_t1 = sWaitRab_e8offset < 4'h5;
  wire            mergedVdWData_3_data_5_t1 = sWaitRab_e8offset < 4'h6;
  wire            mergedVdWData_3_data_6_t1 = sWaitRab_e8offset < 4'h7;
  wire            mergedVdWData_3_data_8_t1 = sWaitRab_e8offset < 4'h9;
  wire            mergedVdWData_3_data_9_t1 = sWaitRab_e8offset < 4'hA;
  wire            mergedVdWData_3_data_10_t1 = sWaitRab_e8offset < 4'hB;
  wire            mergedVdWData_3_data_11_t1 = sWaitRab_e8offset[3:2] != 2'h3;
  wire            mergedVdWData_3_data_12_t1 = sWaitRab_e8offset < 4'hD;
  wire            mergedVdWData_3_data_13_t1 = sWaitRab_e8offset[3:1] != 3'h7;
  wire            mergedVdWData_3_data_14_t1 = sWaitRab_e8offset != 4'hF;
  wire            w101 = w31 | ~(w32 & w37);
  wire            w102 = w31 | ~w32 | w37;
  wire            w103 = w31 | ~(w32 & w39);
  wire            w104 = w31 | ~w32 | w39;
  wire            w105 = state == 3'h2 | w33;
  always @(posedge clock) begin
    if (w101) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_2_valid) begin
        regMaps_0_lreg <= i_fromRab_logicPhyRegMap_2_bits_lreg;
        regMaps_0_newPreg <= i_fromRab_logicPhyRegMap_2_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_1_valid) begin
      regMaps_0_lreg <= i_fromRab_logicPhyRegMap_1_bits_lreg;
      regMaps_0_newPreg <= i_fromRab_logicPhyRegMap_1_bits_preg;
    end
    if (w103) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_2_valid)
        regMaps_0_oldPreg <= oldPregVecFromRat_2_bits_t2;
    end
    else if (oldPregVecFromRat_1_valid)
      regMaps_0_oldPreg <= oldPregVecFromRat_1_bits_t2;
    if (w101) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_3_valid) begin
        regMaps_1_lreg <= i_fromRab_logicPhyRegMap_3_bits_lreg;
        regMaps_1_newPreg <= i_fromRab_logicPhyRegMap_3_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_2_valid) begin
      regMaps_1_lreg <= i_fromRab_logicPhyRegMap_2_bits_lreg;
      regMaps_1_newPreg <= i_fromRab_logicPhyRegMap_2_bits_preg;
    end
    if (w103) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_3_valid)
        regMaps_1_oldPreg <= oldPregVecFromRat_3_bits_t2;
    end
    else if (oldPregVecFromRat_2_valid)
      regMaps_1_oldPreg <= oldPregVecFromRat_2_bits_t2;
    if (w101) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_4_valid) begin
        regMaps_2_lreg <= i_fromRab_logicPhyRegMap_4_bits_lreg;
        regMaps_2_newPreg <= i_fromRab_logicPhyRegMap_4_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_3_valid) begin
      regMaps_2_lreg <= i_fromRab_logicPhyRegMap_3_bits_lreg;
      regMaps_2_newPreg <= i_fromRab_logicPhyRegMap_3_bits_preg;
    end
    if (w103) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_4_valid)
        regMaps_2_oldPreg <= oldPregVecFromRat_4_bits_t2;
    end
    else if (oldPregVecFromRat_3_valid)
      regMaps_2_oldPreg <= oldPregVecFromRat_3_bits_t2;
    if (w101) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_5_valid) begin
        regMaps_3_lreg <= i_fromRab_logicPhyRegMap_5_bits_lreg;
        regMaps_3_newPreg <= i_fromRab_logicPhyRegMap_5_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_4_valid) begin
      regMaps_3_lreg <= i_fromRab_logicPhyRegMap_4_bits_lreg;
      regMaps_3_newPreg <= i_fromRab_logicPhyRegMap_4_bits_preg;
    end
    if (w103) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_5_valid)
        regMaps_3_oldPreg <= oldPregVecFromRat_5_bits_t2;
    end
    else if (oldPregVecFromRat_4_valid)
      regMaps_3_oldPreg <= oldPregVecFromRat_4_bits_t2;
    if (w31 | ~w32) begin
    end
    else begin
      if (w37) begin
        if (sWaitRab_vecExcpInfo_next_bits_r_isStride
            | ~i_fromRab_logicPhyRegMap_5_valid) begin
        end
        else begin
          regMaps_4_lreg <= i_fromRab_logicPhyRegMap_5_bits_lreg;
          regMaps_4_newPreg <= i_fromRab_logicPhyRegMap_5_bits_preg;
        end
      end
      else if (w38) begin
        regMaps_4_lreg <= i_fromRab_logicPhyRegMap_0_bits_lreg;
        regMaps_4_newPreg <= i_fromRab_logicPhyRegMap_0_bits_preg;
      end
      if (w39) begin
        if (sWaitRab_vecExcpInfo_next_bits_r_isStride | ~oldPregVecFromRat_5_valid) begin
        end
        else
          regMaps_4_oldPreg <= oldPregVecFromRat_5_bits_t2;
      end
      else if (w40)
        regMaps_4_oldPreg <= oldPregVecFromRat_0_bits_t2;
    end
    if (w102) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_1_valid) begin
        regMaps_5_lreg <= i_fromRab_logicPhyRegMap_1_bits_lreg;
        regMaps_5_newPreg <= i_fromRab_logicPhyRegMap_1_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_0_valid) begin
      regMaps_5_lreg <= i_fromRab_logicPhyRegMap_0_bits_lreg;
      regMaps_5_newPreg <= i_fromRab_logicPhyRegMap_0_bits_preg;
    end
    if (w104) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_1_valid)
        regMaps_5_oldPreg <= oldPregVecFromRat_1_bits_t2;
    end
    else if (oldPregVecFromRat_0_valid)
      regMaps_5_oldPreg <= oldPregVecFromRat_0_bits_t2;
    if (w102) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_2_valid) begin
        regMaps_6_lreg <= i_fromRab_logicPhyRegMap_2_bits_lreg;
        regMaps_6_newPreg <= i_fromRab_logicPhyRegMap_2_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_1_valid) begin
      regMaps_6_lreg <= i_fromRab_logicPhyRegMap_1_bits_lreg;
      regMaps_6_newPreg <= i_fromRab_logicPhyRegMap_1_bits_preg;
    end
    if (w104) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_2_valid)
        regMaps_6_oldPreg <= oldPregVecFromRat_2_bits_t2;
    end
    else if (oldPregVecFromRat_1_valid)
      regMaps_6_oldPreg <= oldPregVecFromRat_1_bits_t2;
    if (w102) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (i_fromRab_logicPhyRegMap_3_valid) begin
        regMaps_7_lreg <= i_fromRab_logicPhyRegMap_3_bits_lreg;
        regMaps_7_newPreg <= i_fromRab_logicPhyRegMap_3_bits_preg;
      end
    end
    else if (i_fromRab_logicPhyRegMap_2_valid) begin
      regMaps_7_lreg <= i_fromRab_logicPhyRegMap_2_bits_lreg;
      regMaps_7_newPreg <= i_fromRab_logicPhyRegMap_2_bits_preg;
    end
    if (w104) begin
    end
    else if (sWaitRab_vecExcpInfo_next_bits_r_isStride) begin
      if (oldPregVecFromRat_3_valid)
        regMaps_7_oldPreg <= oldPregVecFromRat_3_bits_t2;
    end
    else if (oldPregVecFromRat_2_valid)
      regMaps_7_oldPreg <= oldPregVecFromRat_2_bits_t2;
    if (w105 & i_fromVprf_rdata_0_valid)
      mergedVd_0_rawData <=
        {o_status_busy_t1
           ? i_fromVprf_rdata_0_bits[127:120]
           : i_fromVprf_rdata_0_bits[127:120],
         o_status_busy_t1
           ? (mergedVdWData_3_data_14_t1
                ? i_fromVprf_rdata_0_bits[119:112]
                : i_fromVprf_rdata_4_bits[119:112])
           : i_fromVprf_rdata_0_bits[119:112],
         o_status_busy_t1
           ? (mergedVdWData_3_data_13_t1
                ? i_fromVprf_rdata_0_bits[111:104]
                : i_fromVprf_rdata_4_bits[111:104])
           : i_fromVprf_rdata_0_bits[111:104],
         o_status_busy_t1
           ? (mergedVdWData_3_data_12_t1
                ? i_fromVprf_rdata_0_bits[103:96]
                : i_fromVprf_rdata_4_bits[103:96])
           : i_fromVprf_rdata_0_bits[103:96],
         o_status_busy_t1
           ? (mergedVdWData_3_data_11_t1
                ? i_fromVprf_rdata_0_bits[95:88]
                : i_fromVprf_rdata_4_bits[95:88])
           : i_fromVprf_rdata_0_bits[95:88],
         o_status_busy_t1
           ? (mergedVdWData_3_data_10_t1
                ? i_fromVprf_rdata_0_bits[87:80]
                : i_fromVprf_rdata_4_bits[87:80])
           : i_fromVprf_rdata_0_bits[87:80],
         o_status_busy_t1
           ? (mergedVdWData_3_data_9_t1
                ? i_fromVprf_rdata_0_bits[79:72]
                : i_fromVprf_rdata_4_bits[79:72])
           : i_fromVprf_rdata_0_bits[79:72],
         o_status_busy_t1
           ? (mergedVdWData_3_data_8_t1
                ? i_fromVprf_rdata_0_bits[71:64]
                : i_fromVprf_rdata_4_bits[71:64])
           : i_fromVprf_rdata_0_bits[71:64],
         o_status_busy_t1
           ? (sWaitRab_e8offset[3]
                ? i_fromVprf_rdata_4_bits[63:56]
                : i_fromVprf_rdata_0_bits[63:56])
           : i_fromVprf_rdata_0_bits[63:56],
         o_status_busy_t1
           ? (mergedVdWData_3_data_6_t1
                ? i_fromVprf_rdata_0_bits[55:48]
                : i_fromVprf_rdata_4_bits[55:48])
           : i_fromVprf_rdata_0_bits[55:48],
         o_status_busy_t1
           ? (mergedVdWData_3_data_5_t1
                ? i_fromVprf_rdata_0_bits[47:40]
                : i_fromVprf_rdata_4_bits[47:40])
           : i_fromVprf_rdata_0_bits[47:40],
         o_status_busy_t1
           ? (mergedVdWData_3_data_4_t1
                ? i_fromVprf_rdata_0_bits[39:32]
                : i_fromVprf_rdata_4_bits[39:32])
           : i_fromVprf_rdata_0_bits[39:32],
         o_status_busy_t1
           ? (mergedVdWData_3_data_3_t1
                ? i_fromVprf_rdata_0_bits[31:24]
                : i_fromVprf_rdata_4_bits[31:24])
           : i_fromVprf_rdata_0_bits[31:24],
         o_status_busy_t1
           ? (mergedVdWData_3_data_2_t1
                ? i_fromVprf_rdata_0_bits[23:16]
                : i_fromVprf_rdata_4_bits[23:16])
           : i_fromVprf_rdata_0_bits[23:16],
         o_status_busy_t1
           ? (mergedVdWData_3_data_1_t1
                ? i_fromVprf_rdata_0_bits[15:8]
                : i_fromVprf_rdata_4_bits[15:8])
           : i_fromVprf_rdata_0_bits[15:8],
         o_status_busy_t1
           ? (mergedVdWData_3_data_0_t1
                ? i_fromVprf_rdata_0_bits[7:0]
                : i_fromVprf_rdata_4_bits[7:0])
           : i_fromVprf_rdata_0_bits[7:0]};
    if (w105 & i_fromVprf_rdata_1_valid)
      mergedVd_1_rawData <=
        {o_status_busy_t1
           ? i_fromVprf_rdata_1_bits[127:120]
           : i_fromVprf_rdata_1_bits[127:120],
         o_status_busy_t1
           ? (mergedVdWData_3_data_14_t1
                ? i_fromVprf_rdata_1_bits[119:112]
                : i_fromVprf_rdata_5_bits[119:112])
           : i_fromVprf_rdata_1_bits[119:112],
         o_status_busy_t1
           ? (mergedVdWData_3_data_13_t1
                ? i_fromVprf_rdata_1_bits[111:104]
                : i_fromVprf_rdata_5_bits[111:104])
           : i_fromVprf_rdata_1_bits[111:104],
         o_status_busy_t1
           ? (mergedVdWData_3_data_12_t1
                ? i_fromVprf_rdata_1_bits[103:96]
                : i_fromVprf_rdata_5_bits[103:96])
           : i_fromVprf_rdata_1_bits[103:96],
         o_status_busy_t1
           ? (mergedVdWData_3_data_11_t1
                ? i_fromVprf_rdata_1_bits[95:88]
                : i_fromVprf_rdata_5_bits[95:88])
           : i_fromVprf_rdata_1_bits[95:88],
         o_status_busy_t1
           ? (mergedVdWData_3_data_10_t1
                ? i_fromVprf_rdata_1_bits[87:80]
                : i_fromVprf_rdata_5_bits[87:80])
           : i_fromVprf_rdata_1_bits[87:80],
         o_status_busy_t1
           ? (mergedVdWData_3_data_9_t1
                ? i_fromVprf_rdata_1_bits[79:72]
                : i_fromVprf_rdata_5_bits[79:72])
           : i_fromVprf_rdata_1_bits[79:72],
         o_status_busy_t1
           ? (mergedVdWData_3_data_8_t1
                ? i_fromVprf_rdata_1_bits[71:64]
                : i_fromVprf_rdata_5_bits[71:64])
           : i_fromVprf_rdata_1_bits[71:64],
         o_status_busy_t1
           ? (sWaitRab_e8offset[3]
                ? i_fromVprf_rdata_5_bits[63:56]
                : i_fromVprf_rdata_1_bits[63:56])
           : i_fromVprf_rdata_1_bits[63:56],
         o_status_busy_t1
           ? (mergedVdWData_3_data_6_t1
                ? i_fromVprf_rdata_1_bits[55:48]
                : i_fromVprf_rdata_5_bits[55:48])
           : i_fromVprf_rdata_1_bits[55:48],
         o_status_busy_t1
           ? (mergedVdWData_3_data_5_t1
                ? i_fromVprf_rdata_1_bits[47:40]
                : i_fromVprf_rdata_5_bits[47:40])
           : i_fromVprf_rdata_1_bits[47:40],
         o_status_busy_t1
           ? (mergedVdWData_3_data_4_t1
                ? i_fromVprf_rdata_1_bits[39:32]
                : i_fromVprf_rdata_5_bits[39:32])
           : i_fromVprf_rdata_1_bits[39:32],
         o_status_busy_t1
           ? (mergedVdWData_3_data_3_t1
                ? i_fromVprf_rdata_1_bits[31:24]
                : i_fromVprf_rdata_5_bits[31:24])
           : i_fromVprf_rdata_1_bits[31:24],
         o_status_busy_t1
           ? (mergedVdWData_3_data_2_t1
                ? i_fromVprf_rdata_1_bits[23:16]
                : i_fromVprf_rdata_5_bits[23:16])
           : i_fromVprf_rdata_1_bits[23:16],
         o_status_busy_t1
           ? (mergedVdWData_3_data_1_t1
                ? i_fromVprf_rdata_1_bits[15:8]
                : i_fromVprf_rdata_5_bits[15:8])
           : i_fromVprf_rdata_1_bits[15:8],
         o_status_busy_t1
           ? (mergedVdWData_3_data_0_t1
                ? i_fromVprf_rdata_1_bits[7:0]
                : i_fromVprf_rdata_5_bits[7:0])
           : i_fromVprf_rdata_1_bits[7:0]};
    if (w105 & i_fromVprf_rdata_2_valid)
      mergedVd_2_rawData <=
        {o_status_busy_t1
           ? i_fromVprf_rdata_2_bits[127:120]
           : i_fromVprf_rdata_2_bits[127:120],
         o_status_busy_t1
           ? (mergedVdWData_3_data_14_t1
                ? i_fromVprf_rdata_2_bits[119:112]
                : i_fromVprf_rdata_6_bits[119:112])
           : i_fromVprf_rdata_2_bits[119:112],
         o_status_busy_t1
           ? (mergedVdWData_3_data_13_t1
                ? i_fromVprf_rdata_2_bits[111:104]
                : i_fromVprf_rdata_6_bits[111:104])
           : i_fromVprf_rdata_2_bits[111:104],
         o_status_busy_t1
           ? (mergedVdWData_3_data_12_t1
                ? i_fromVprf_rdata_2_bits[103:96]
                : i_fromVprf_rdata_6_bits[103:96])
           : i_fromVprf_rdata_2_bits[103:96],
         o_status_busy_t1
           ? (mergedVdWData_3_data_11_t1
                ? i_fromVprf_rdata_2_bits[95:88]
                : i_fromVprf_rdata_6_bits[95:88])
           : i_fromVprf_rdata_2_bits[95:88],
         o_status_busy_t1
           ? (mergedVdWData_3_data_10_t1
                ? i_fromVprf_rdata_2_bits[87:80]
                : i_fromVprf_rdata_6_bits[87:80])
           : i_fromVprf_rdata_2_bits[87:80],
         o_status_busy_t1
           ? (mergedVdWData_3_data_9_t1
                ? i_fromVprf_rdata_2_bits[79:72]
                : i_fromVprf_rdata_6_bits[79:72])
           : i_fromVprf_rdata_2_bits[79:72],
         o_status_busy_t1
           ? (mergedVdWData_3_data_8_t1
                ? i_fromVprf_rdata_2_bits[71:64]
                : i_fromVprf_rdata_6_bits[71:64])
           : i_fromVprf_rdata_2_bits[71:64],
         o_status_busy_t1
           ? (sWaitRab_e8offset[3]
                ? i_fromVprf_rdata_6_bits[63:56]
                : i_fromVprf_rdata_2_bits[63:56])
           : i_fromVprf_rdata_2_bits[63:56],
         o_status_busy_t1
           ? (mergedVdWData_3_data_6_t1
                ? i_fromVprf_rdata_2_bits[55:48]
                : i_fromVprf_rdata_6_bits[55:48])
           : i_fromVprf_rdata_2_bits[55:48],
         o_status_busy_t1
           ? (mergedVdWData_3_data_5_t1
                ? i_fromVprf_rdata_2_bits[47:40]
                : i_fromVprf_rdata_6_bits[47:40])
           : i_fromVprf_rdata_2_bits[47:40],
         o_status_busy_t1
           ? (mergedVdWData_3_data_4_t1
                ? i_fromVprf_rdata_2_bits[39:32]
                : i_fromVprf_rdata_6_bits[39:32])
           : i_fromVprf_rdata_2_bits[39:32],
         o_status_busy_t1
           ? (mergedVdWData_3_data_3_t1
                ? i_fromVprf_rdata_2_bits[31:24]
                : i_fromVprf_rdata_6_bits[31:24])
           : i_fromVprf_rdata_2_bits[31:24],
         o_status_busy_t1
           ? (mergedVdWData_3_data_2_t1
                ? i_fromVprf_rdata_2_bits[23:16]
                : i_fromVprf_rdata_6_bits[23:16])
           : i_fromVprf_rdata_2_bits[23:16],
         o_status_busy_t1
           ? (mergedVdWData_3_data_1_t1
                ? i_fromVprf_rdata_2_bits[15:8]
                : i_fromVprf_rdata_6_bits[15:8])
           : i_fromVprf_rdata_2_bits[15:8],
         o_status_busy_t1
           ? (mergedVdWData_3_data_0_t1
                ? i_fromVprf_rdata_2_bits[7:0]
                : i_fromVprf_rdata_6_bits[7:0])
           : i_fromVprf_rdata_2_bits[7:0]};
    if (w105 & i_fromVprf_rdata_3_valid)
      mergedVd_3_rawData <=
        {o_status_busy_t1
           ? i_fromVprf_rdata_3_bits[127:120]
           : i_fromVprf_rdata_3_bits[127:120],
         o_status_busy_t1
           ? (mergedVdWData_3_data_14_t1
                ? i_fromVprf_rdata_3_bits[119:112]
                : i_fromVprf_rdata_7_bits[119:112])
           : i_fromVprf_rdata_3_bits[119:112],
         o_status_busy_t1
           ? (mergedVdWData_3_data_13_t1
                ? i_fromVprf_rdata_3_bits[111:104]
                : i_fromVprf_rdata_7_bits[111:104])
           : i_fromVprf_rdata_3_bits[111:104],
         o_status_busy_t1
           ? (mergedVdWData_3_data_12_t1
                ? i_fromVprf_rdata_3_bits[103:96]
                : i_fromVprf_rdata_7_bits[103:96])
           : i_fromVprf_rdata_3_bits[103:96],
         o_status_busy_t1
           ? (mergedVdWData_3_data_11_t1
                ? i_fromVprf_rdata_3_bits[95:88]
                : i_fromVprf_rdata_7_bits[95:88])
           : i_fromVprf_rdata_3_bits[95:88],
         o_status_busy_t1
           ? (mergedVdWData_3_data_10_t1
                ? i_fromVprf_rdata_3_bits[87:80]
                : i_fromVprf_rdata_7_bits[87:80])
           : i_fromVprf_rdata_3_bits[87:80],
         o_status_busy_t1
           ? (mergedVdWData_3_data_9_t1
                ? i_fromVprf_rdata_3_bits[79:72]
                : i_fromVprf_rdata_7_bits[79:72])
           : i_fromVprf_rdata_3_bits[79:72],
         o_status_busy_t1
           ? (mergedVdWData_3_data_8_t1
                ? i_fromVprf_rdata_3_bits[71:64]
                : i_fromVprf_rdata_7_bits[71:64])
           : i_fromVprf_rdata_3_bits[71:64],
         o_status_busy_t1
           ? (sWaitRab_e8offset[3]
                ? i_fromVprf_rdata_7_bits[63:56]
                : i_fromVprf_rdata_3_bits[63:56])
           : i_fromVprf_rdata_3_bits[63:56],
         o_status_busy_t1
           ? (mergedVdWData_3_data_6_t1
                ? i_fromVprf_rdata_3_bits[55:48]
                : i_fromVprf_rdata_7_bits[55:48])
           : i_fromVprf_rdata_3_bits[55:48],
         o_status_busy_t1
           ? (mergedVdWData_3_data_5_t1
                ? i_fromVprf_rdata_3_bits[47:40]
                : i_fromVprf_rdata_7_bits[47:40])
           : i_fromVprf_rdata_3_bits[47:40],
         o_status_busy_t1
           ? (mergedVdWData_3_data_4_t1
                ? i_fromVprf_rdata_3_bits[39:32]
                : i_fromVprf_rdata_7_bits[39:32])
           : i_fromVprf_rdata_3_bits[39:32],
         o_status_busy_t1
           ? (mergedVdWData_3_data_3_t1
                ? i_fromVprf_rdata_3_bits[31:24]
                : i_fromVprf_rdata_7_bits[31:24])
           : i_fromVprf_rdata_3_bits[31:24],
         o_status_busy_t1
           ? (mergedVdWData_3_data_2_t1
                ? i_fromVprf_rdata_3_bits[23:16]
                : i_fromVprf_rdata_7_bits[23:16])
           : i_fromVprf_rdata_3_bits[23:16],
         o_status_busy_t1
           ? (mergedVdWData_3_data_1_t1
                ? i_fromVprf_rdata_3_bits[15:8]
                : i_fromVprf_rdata_7_bits[15:8])
           : i_fromVprf_rdata_3_bits[15:8],
         o_status_busy_t1
           ? (mergedVdWData_3_data_0_t1
                ? i_fromVprf_rdata_3_bits[7:0]
                : i_fromVprf_rdata_7_bits[7:0])
           : i_fromVprf_rdata_3_bits[7:0]};
    if (i_fromExceptionGen_valid) begin
      sWaitRab_vecExcpInfo_next_bits_r_nf <= i_fromExceptionGen_bits_nf;
      sWaitRab_vecExcpInfo_next_bits_r_isStride <= i_fromExceptionGen_bits_isStride;
      sWaitRab_vecExcpInfo_next_bits_r_isWhole <= i_fromExceptionGen_bits_isWhole;
      sWaitRab_useNewVdUntil <= sNoExcp_useNewVdUntil;
      sWaitRab_needMergeUntil <=
        4'({1'h0,
            3'(sNoExcp_useNewVdUntil
               + (i_fromExceptionGen_bits_isWhole ? 3'h0 : i_fromExceptionGen_bits_nf))}
           + 4'h1);
      sWaitRab_e8offset <= (|sNoExcp_deewOH) ? g_GetE8OffsetInVreg_out_offset : 4'h0;
      sWaitRab_handleUntil <= sNoExcp_maxVdIdx[3:0];
      sWaitRab_nonSegIndexed <=
        i_fromExceptionGen_bits_isIndexed & i_fromExceptionGen_bits_nf == 3'h0;
      sWaitRab_vemul_i_d_0 <=
        sNoExcp_ivemulNoLessThanM1_t1 == sNoExcp_dvemulNoLessThanM1_t1
        | sNoExcp_ivemulNoLessThanM1_t1 < sNoExcp_dvemulNoLessThanM1_t1;
      sWaitRab_vemul_i_d_1 <= w99 == 3'(w98 + 3'h1);
      sWaitRab_vemul_i_d_2 <= w99 == 3'(w98 + 3'h2);
      sWaitRab_vemul_i_d_3 <= w99 == 3'(w98 + 3'h3);
      sWaitRab_dvemulNoLessThanM1 <= sNoExcp_dvemulNoLessThanM1_t1;
    end
    if (w31) begin
      if (w36) begin
        sWaitRab_rabWriteOffset <= 4'h0;
        sWaitRab_ratWriteOffset <= 4'h0;
      end
    end
    else if (w32) begin
      if (i_fromRab_logicPhyRegMap_0_valid)
        sWaitRab_rabWriteOffset <=
          4'(sWaitRab_rabWriteOffset
             + {1'h0,
                i_fromRab_logicPhyRegMap_5_valid
                  ? 3'h6
                  : i_fromRab_logicPhyRegMap_4_valid
                      ? 3'h5
                      : i_fromRab_logicPhyRegMap_3_valid
                          ? 3'h4
                          : {1'h0,
                             i_fromRab_logicPhyRegMap_2_valid
                               ? 2'h3
                               : i_fromRab_logicPhyRegMap_1_valid ? 2'h2 : 2'h1}});
      if (oldPregVecFromRat_0_valid)
        sWaitRab_ratWriteOffset <=
          4'(sWaitRab_ratWriteOffset
             + {1'h0,
                oldPregVecFromRat_5_valid
                  ? 3'h6
                  : oldPregVecFromRat_4_valid
                      ? 3'h5
                      : oldPregVecFromRat_3_valid
                          ? 3'h4
                          : {1'h0,
                             oldPregVecFromRat_2_valid
                               ? 2'h3
                               : oldPregVecFromRat_1_valid ? 2'h2 : 2'h1}});
    end
    else if (w34) begin
      sWaitRab_rabWriteOffset <= 4'h0;
      sWaitRab_ratWriteOffset <= 4'h0;
    end
    o_toVPRF_w_0_valid_REG <= i_fromVprf_rdata_0_valid;
    o_toVPRF_w_1_valid_REG <= i_fromVprf_rdata_1_valid;
    o_toVPRF_w_2_valid_REG <= i_fromVprf_rdata_2_valid;
    o_toVPRF_w_3_valid_REG <= i_fromVprf_rdata_3_valid;
  end // always @(posedge)
  `ifdef ENABLE_INITIAL_REG_
    `ifdef FIRRTL_BEFORE_INITIAL
      `FIRRTL_BEFORE_INITIAL
    `endif // FIRRTL_BEFORE_INITIAL
    logic [31:0] _RANDOM[0:27];
    initial begin
      `ifdef INIT_RANDOM_PROLOG_
        `INIT_RANDOM_PROLOG_
      `endif // INIT_RANDOM_PROLOG_
      `ifdef RANDOMIZE_REG_INIT
        for (logic [4:0] i = 5'h0; i < 5'h1C; i += 5'h1) begin
          _RANDOM[i] = `RANDOM;
        end
        commitNeeded_0 = _RANDOM[5'h0][0];
        commitNeeded_1 = _RANDOM[5'h0][1];
        commitNeeded_2 = _RANDOM[5'h0][2];
        commitNeeded_3 = _RANDOM[5'h0][3];
        commitNeeded_4 = _RANDOM[5'h0][4];
        commitNeeded_5 = _RANDOM[5'h0][5];
        commitNeeded_6 = _RANDOM[5'h0][6];
        commitNeeded_7 = _RANDOM[5'h0][7];
        rabCommitted_0 = _RANDOM[5'h0][8];
        rabCommitted_1 = _RANDOM[5'h0][9];
        rabCommitted_2 = _RANDOM[5'h0][10];
        rabCommitted_3 = _RANDOM[5'h0][11];
        rabCommitted_4 = _RANDOM[5'h0][12];
        rabCommitted_5 = _RANDOM[5'h0][13];
        rabCommitted_6 = _RANDOM[5'h0][14];
        rabCommitted_7 = _RANDOM[5'h0][15];
        ratCommitted_0 = _RANDOM[5'h0][16];
        ratCommitted_1 = _RANDOM[5'h0][17];
        ratCommitted_2 = _RANDOM[5'h0][18];
        ratCommitted_3 = _RANDOM[5'h0][19];
        ratCommitted_4 = _RANDOM[5'h0][20];
        ratCommitted_5 = _RANDOM[5'h0][21];
        ratCommitted_6 = _RANDOM[5'h0][22];
        ratCommitted_7 = _RANDOM[5'h0][23];
        hasReadRf_0 = _RANDOM[5'h0][24];
        hasReadRf_1 = _RANDOM[5'h0][25];
        hasReadRf_2 = _RANDOM[5'h0][26];
        hasReadRf_3 = _RANDOM[5'h0][27];
        hasReadRf_4 = _RANDOM[5'h0][28];
        hasReadRf_5 = _RANDOM[5'h0][29];
        hasReadRf_6 = _RANDOM[5'h0][30];
        hasReadRf_7 = _RANDOM[5'h0][31];
        regMaps_0_lreg = _RANDOM[5'h1][5:0];
        regMaps_0_newPreg = _RANDOM[5'h1][12:6];
        regMaps_0_oldPreg = _RANDOM[5'h1][19:13];
        regMaps_1_lreg = _RANDOM[5'h1][25:20];
        regMaps_1_newPreg = {_RANDOM[5'h1][31:26], _RANDOM[5'h2][0]};
        regMaps_1_oldPreg = _RANDOM[5'h2][7:1];
        regMaps_2_lreg = _RANDOM[5'h2][13:8];
        regMaps_2_newPreg = _RANDOM[5'h2][20:14];
        regMaps_2_oldPreg = _RANDOM[5'h2][27:21];
        regMaps_3_lreg = {_RANDOM[5'h2][31:28], _RANDOM[5'h3][1:0]};
        regMaps_3_newPreg = _RANDOM[5'h3][8:2];
        regMaps_3_oldPreg = _RANDOM[5'h3][15:9];
        regMaps_4_lreg = _RANDOM[5'h3][21:16];
        regMaps_4_newPreg = _RANDOM[5'h3][28:22];
        regMaps_4_oldPreg = {_RANDOM[5'h3][31:29], _RANDOM[5'h4][3:0]};
        regMaps_5_lreg = _RANDOM[5'h4][9:4];
        regMaps_5_newPreg = _RANDOM[5'h4][16:10];
        regMaps_5_oldPreg = _RANDOM[5'h4][23:17];
        regMaps_6_lreg = _RANDOM[5'h4][29:24];
        regMaps_6_newPreg = {_RANDOM[5'h4][31:30], _RANDOM[5'h5][4:0]};
        regMaps_6_oldPreg = _RANDOM[5'h5][11:5];
        regMaps_7_lreg = _RANDOM[5'h5][17:12];
        regMaps_7_newPreg = _RANDOM[5'h5][24:18];
        regMaps_7_oldPreg = _RANDOM[5'h5][31:25];
        currentIdx = _RANDOM[5'h6][3:0];
        mergedVd_0_rawData =
          {_RANDOM[5'h6][31:4],
           _RANDOM[5'h7],
           _RANDOM[5'h8],
           _RANDOM[5'h9],
           _RANDOM[5'hA][3:0]};
        mergedVd_1_rawData =
          {_RANDOM[5'hA][31:4],
           _RANDOM[5'hB],
           _RANDOM[5'hC],
           _RANDOM[5'hD],
           _RANDOM[5'hE][3:0]};
        mergedVd_2_rawData =
          {_RANDOM[5'hE][31:4],
           _RANDOM[5'hF],
           _RANDOM[5'h10],
           _RANDOM[5'h11],
           _RANDOM[5'h12][3:0]};
        mergedVd_3_rawData =
          {_RANDOM[5'h12][31:4],
           _RANDOM[5'h13],
           _RANDOM[5'h14],
           _RANDOM[5'h15],
           _RANDOM[5'h16][3:0]};
        sWaitRab_vecExcpInfo_next_bits_r_nf = _RANDOM[5'h16][21:19];
        sWaitRab_vecExcpInfo_next_bits_r_isStride = _RANDOM[5'h16][22];
        sWaitRab_vecExcpInfo_next_bits_r_isWhole = _RANDOM[5'h16][24];
        sWaitRab_useNewVdUntil = _RANDOM[5'h16][28:26];
        sWaitRab_needMergeUntil = {_RANDOM[5'h16][31:29], _RANDOM[5'h17][0]};
        sWaitRab_e8offset = _RANDOM[5'h17][4:1];
        sWaitRab_handleUntil = _RANDOM[5'h1B][9:6];
        sWaitRab_nonSegIndexed = _RANDOM[5'h1B][10];
        sWaitRab_vemul_i_d_0 = _RANDOM[5'h1B][11];
        sWaitRab_vemul_i_d_1 = _RANDOM[5'h1B][12];
        sWaitRab_vemul_i_d_2 = _RANDOM[5'h1B][13];
        sWaitRab_vemul_i_d_3 = _RANDOM[5'h1B][14];
        sWaitRab_dvemulNoLessThanM1 = _RANDOM[5'h1B][16:15];
        sWaitRab_rabWriteOffset = _RANDOM[5'h1B][20:17];
        sWaitRab_ratWriteOffset = _RANDOM[5'h1B][24:21];
        state = _RANDOM[5'h1B][27:25];
        o_toVPRF_w_0_valid_REG = _RANDOM[5'h1B][28];
        o_toVPRF_w_1_valid_REG = _RANDOM[5'h1B][29];
        o_toVPRF_w_2_valid_REG = _RANDOM[5'h1B][30];
        o_toVPRF_w_3_valid_REG = _RANDOM[5'h1B][31];
      `endif // RANDOMIZE_REG_INIT
      if (reset) begin
        commitNeeded_0 = 1'h0;
        commitNeeded_1 = 1'h0;
        commitNeeded_2 = 1'h0;
        commitNeeded_3 = 1'h0;
        commitNeeded_4 = 1'h0;
        commitNeeded_5 = 1'h0;
        commitNeeded_6 = 1'h0;
        commitNeeded_7 = 1'h0;
        rabCommitted_0 = 1'h0;
        rabCommitted_1 = 1'h0;
        rabCommitted_2 = 1'h0;
        rabCommitted_3 = 1'h0;
        rabCommitted_4 = 1'h0;
        rabCommitted_5 = 1'h0;
        rabCommitted_6 = 1'h0;
        rabCommitted_7 = 1'h0;
        ratCommitted_0 = 1'h0;
        ratCommitted_1 = 1'h0;
        ratCommitted_2 = 1'h0;
        ratCommitted_3 = 1'h0;
        ratCommitted_4 = 1'h0;
        ratCommitted_5 = 1'h0;
        ratCommitted_6 = 1'h0;
        ratCommitted_7 = 1'h0;
        hasReadRf_0 = 1'h0;
        hasReadRf_1 = 1'h0;
        hasReadRf_2 = 1'h0;
        hasReadRf_3 = 1'h0;
        hasReadRf_4 = 1'h0;
        hasReadRf_5 = 1'h0;
        hasReadRf_6 = 1'h0;
        hasReadRf_7 = 1'h0;
        currentIdx = 4'h0;
        state = 3'h0;
      end
    end // initial
    `ifdef FIRRTL_AFTER_INITIAL
      `FIRRTL_AFTER_INITIAL
    `endif // FIRRTL_AFTER_INITIAL
  `endif // ENABLE_INITIAL_REG_
  GetE8OffsetInVreg_xs GetE8OffsetInVreg (
    .in_eewOH   (sNoExcp_deewOH),
    .in_idx     (i_fromExceptionGen_bits_vstart),
    .out_offset (g_GetE8OffsetInVreg_out_offset)
  );
  NfMappedElemIdx_xs NfMappedElemIdx (
    .in_nf
      (i_fromExceptionGen_bits_isWhole ? 3'h0 : i_fromExceptionGen_bits_nf),
    .in_eewOH                (sNoExcp_deewOH),
    .out_idxRangeVec_0_from  (n_NfMappedElemIdx_out_idxRangeVec_0_from),
    .out_idxRangeVec_0_until (n_NfMappedElemIdx_out_idxRangeVec_0_until),
    .out_idxRangeVec_1_from  (n_NfMappedElemIdx_out_idxRangeVec_1_from),
    .out_idxRangeVec_1_until (n_NfMappedElemIdx_out_idxRangeVec_1_until),
    .out_idxRangeVec_2_from  (n_NfMappedElemIdx_out_idxRangeVec_2_from),
    .out_idxRangeVec_2_until (n_NfMappedElemIdx_out_idxRangeVec_2_until),
    .out_idxRangeVec_3_from  (n_NfMappedElemIdx_out_idxRangeVec_3_from),
    .out_idxRangeVec_3_until (n_NfMappedElemIdx_out_idxRangeVec_3_until),
    .out_idxRangeVec_4_from  (n_NfMappedElemIdx_out_idxRangeVec_4_from),
    .out_idxRangeVec_4_until (n_NfMappedElemIdx_out_idxRangeVec_4_until),
    .out_idxRangeVec_5_from  (n_NfMappedElemIdx_out_idxRangeVec_5_from),
    .out_idxRangeVec_5_until (n_NfMappedElemIdx_out_idxRangeVec_5_until),
    .out_idxRangeVec_6_from  (n_NfMappedElemIdx_out_idxRangeVec_6_from),
    .out_idxRangeVec_6_until (n_NfMappedElemIdx_out_idxRangeVec_6_until),
    .out_idxRangeVec_7_from  (/* unused */),
    .out_idxRangeVec_7_until (/* unused */)
  );
  xs_delayn_core #(.WIDTH(1), .N(1)) o_status_busy_delay (
    .clock  (clock),
    .io_in  (|{state == 3'h3, o_status_busy_t1, state == 3'h1}),
    .io_out (o_status_busy)
  );
  assign o_toVPRF_r_0_valid =
    o_status_busy_t1
      ? w44 & ~w42 & hasReadRf_t1
      : w33 & w44 & ~w42 & hasReadRf_t9;
  assign o_toVPRF_r_0_bits_isV0 =
    o_status_busy_t1
      ? ~(|w45[oldVdLocVec_0])
      : w33 & ~(|w45[oldVdLocVec_0]);
  assign o_toVPRF_r_0_bits_addr = w54 ? w46[oldVdLocVec_0] : 7'h0;
  assign o_toVPRF_r_1_valid =
    o_status_busy_t1
      ? w49 & ~w48 & hasReadRf_t3
      : w33 & w49 & ~w48 & hasReadRf_t11;
  assign o_toVPRF_r_1_bits_addr = w54 ? w46[oldVdLocVec_1] : 7'h0;
  assign o_toVPRF_r_2_valid =
    o_status_busy_t1
      ? w51 & ~w50 & hasReadRf_t5
      : w33 & w51 & ~w50 & hasReadRf_t13;
  assign o_toVPRF_r_2_bits_addr = w54 ? w46[oldVdLocVec_2] : 7'h0;
  assign o_toVPRF_r_3_valid =
    o_status_busy_t1
      ? w53 & ~w52 & hasReadRf_t7
      : w33 & w53 & ~w52 & hasReadRf_t15;
  assign o_toVPRF_r_3_bits_addr = w54 ? w46[oldVdLocVec_3] : 7'h0;
  assign o_toVPRF_r_4_valid = o_status_busy_t1 & w44 & ~w42 & hasReadRf_t1;
  assign o_toVPRF_r_4_bits_isV0 = o_status_busy_t1 & ~(|w45[newVdLocVec_0]);
  assign o_toVPRF_r_4_bits_addr = o_status_busy_t1 ? w47[newVdLocVec_0] : 7'h0;
  assign o_toVPRF_r_5_valid = o_status_busy_t1 & w49 & ~w48 & hasReadRf_t3;
  assign o_toVPRF_r_5_bits_addr = o_status_busy_t1 ? w47[newVdLocVec_1] : 7'h0;
  assign o_toVPRF_r_6_valid = o_status_busy_t1 & w51 & ~w50 & hasReadRf_t5;
  assign o_toVPRF_r_6_bits_addr = o_status_busy_t1 ? w47[newVdLocVec_2] : 7'h0;
  assign o_toVPRF_r_7_valid = o_status_busy_t1 & w53 & ~w52 & hasReadRf_t7;
  assign o_toVPRF_r_7_bits_addr = o_status_busy_t1 ? w47[newVdLocVec_3] : 7'h0;
  assign o_toVPRF_w_0_valid = o_toVPRF_w_0_valid_REG;
  assign o_toVPRF_w_0_bits_isV0 = ~(|w45[newVdLocVec_0]);
  assign o_toVPRF_w_0_bits_newVdAddr = w47[newVdLocVec_0];
  assign o_toVPRF_w_0_bits_newVdData = mergedVd_0_rawData;
  assign o_toVPRF_w_1_valid = o_toVPRF_w_1_valid_REG;
  assign o_toVPRF_w_1_bits_newVdAddr = w47[newVdLocVec_1];
  assign o_toVPRF_w_1_bits_newVdData = mergedVd_1_rawData;
  assign o_toVPRF_w_2_valid = o_toVPRF_w_2_valid_REG;
  assign o_toVPRF_w_2_bits_newVdAddr = w47[newVdLocVec_2];
  assign o_toVPRF_w_2_bits_newVdData = mergedVd_2_rawData;
  assign o_toVPRF_w_3_valid = o_toVPRF_w_3_valid_REG;
  assign o_toVPRF_w_3_bits_newVdAddr = w47[newVdLocVec_3];
  assign o_toVPRF_w_3_bits_newVdData = mergedVd_3_rawData;
endmodule

module NfMappedElemIdx_xs(
  input  [2:0] in_nf,
  input  [3:0] in_eewOH,
  output [7:0] out_idxRangeVec_0_from,
  output [7:0] out_idxRangeVec_0_until,
  output [7:0] out_idxRangeVec_1_from,
  output [7:0] out_idxRangeVec_1_until,
  output [7:0] out_idxRangeVec_2_from,
  output [7:0] out_idxRangeVec_2_until,
  output [7:0] out_idxRangeVec_3_from,
  output [7:0] out_idxRangeVec_3_until,
  output [7:0] out_idxRangeVec_4_from,
  output [7:0] out_idxRangeVec_4_until,
  output [7:0] out_idxRangeVec_5_from,
  output [7:0] out_idxRangeVec_5_until,
  output [7:0] out_idxRangeVec_6_from,
  output [7:0] out_idxRangeVec_6_until,
  output [7:0] out_idxRangeVec_7_from,
  output [7:0] out_idxRangeVec_7_until
);

  wire [7:0]      _GEN = {3'h0, in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 1'h0};
  wire [7:0]      _GEN_0 =
    {2'h0, in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 2'h0};
  wire [7:0]      _GEN_1 =
    (in_eewOH[0] ? 8'h30 : 8'h0) | (in_eewOH[1] ? 8'h18 : 8'h0)
    | (in_eewOH[2] ? 8'hC : 8'h0) | (in_eewOH[3] ? 8'h6 : 8'h0);
  wire [7:0]      _GEN_2 =
    {1'h0, in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 3'h0};
  wire [7:0]      _GEN_3 =
    (in_eewOH[0] ? 8'h50 : 8'h0) | (in_eewOH[1] ? 8'h28 : 8'h0)
    | (in_eewOH[2] ? 8'h14 : 8'h0) | (in_eewOH[3] ? 8'hA : 8'h0);
  wire [7:0]      _GEN_4 =
    (in_eewOH[0] ? 8'h60 : 8'h0) | (in_eewOH[1] ? 8'h30 : 8'h0)
    | (in_eewOH[2] ? 8'h18 : 8'h0) | (in_eewOH[3] ? 8'hC : 8'h0);
  wire [7:0]      _GEN_5 =
    (in_eewOH[0] ? 8'h70 : 8'h0) | (in_eewOH[1] ? 8'h38 : 8'h0)
    | (in_eewOH[2] ? 8'h1C : 8'h0) | (in_eewOH[3] ? 8'hE : 8'h0);
  wire [7:0][7:0] _GEN_6 =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {_GEN}};
  wire [7:0][7:0] _GEN_7 =
    {{_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}};
  wire [7:0][7:0] _GEN_8 =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {_GEN}, {_GEN_0}};
  wire [7:0][7:0] _GEN_9 =
    {{_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_1}};
  wire [7:0][7:0] _GEN_10 =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {_GEN}, {_GEN}, {_GEN_1}};
  wire [7:0][7:0] _GEN_11 =
    {{_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_0}, {_GEN_2}};
  wire [7:0][7:0] _GEN_12 =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_2}};
  wire [7:0][7:0] _GEN_13 =
    {{_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_0}, {_GEN_1}, {_GEN_3}};
  wire [7:0][7:0] _GEN_14 =
    {{8'h0}, {8'h0}, {8'h0}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_3}};
  wire [7:0][7:0] _GEN_15 =
    {{_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_0}, {_GEN_0}, {_GEN_1}, {_GEN_4}};
  wire [7:0][7:0] _GEN_16 =
    {{8'h0}, {8'h0}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_1}, {_GEN_4}};
  wire [7:0][7:0] _GEN_17 =
    {{_GEN}, {_GEN}, {_GEN_0}, {_GEN_0}, {_GEN_0}, {_GEN_1}, {_GEN_2}, {_GEN_5}};
  wire [7:0][7:0] _GEN_18 =
    {{8'h0}, {_GEN}, {_GEN}, {_GEN}, {_GEN}, {_GEN_0}, {_GEN_1}, {_GEN_5}};
  wire [7:0][7:0] _GEN_19 =
    {{_GEN},
     {_GEN_0},
     {_GEN_0},
     {_GEN_0},
     {_GEN_0},
     {_GEN_1},
     {_GEN_2},
     {{in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 4'h0}}};
  assign out_idxRangeVec_0_from = 8'h0;
  assign out_idxRangeVec_0_until = _GEN;
  assign out_idxRangeVec_1_from = _GEN_6[in_nf];
  assign out_idxRangeVec_1_until = _GEN_7[in_nf];
  assign out_idxRangeVec_2_from = _GEN_8[in_nf];
  assign out_idxRangeVec_2_until = _GEN_9[in_nf];
  assign out_idxRangeVec_3_from = _GEN_10[in_nf];
  assign out_idxRangeVec_3_until = _GEN_11[in_nf];
  assign out_idxRangeVec_4_from = _GEN_12[in_nf];
  assign out_idxRangeVec_4_until = _GEN_13[in_nf];
  assign out_idxRangeVec_5_from = _GEN_14[in_nf];
  assign out_idxRangeVec_5_until = _GEN_15[in_nf];
  assign out_idxRangeVec_6_from = _GEN_16[in_nf];
  assign out_idxRangeVec_6_until = _GEN_17[in_nf];
  assign out_idxRangeVec_7_from = _GEN_18[in_nf];
  assign out_idxRangeVec_7_until = _GEN_19[in_nf];
endmodule

module GetE8OffsetInVreg_xs(
  input  [3:0] in_eewOH,
  input  [6:0] in_idx,
  output [3:0] out_offset
);

  assign out_offset =
    (in_eewOH[0] ? in_idx[3:0] : 4'h0) | (in_eewOH[1] ? {in_idx[2:0], 1'h0} : 4'h0)
    | (in_eewOH[2] ? {in_idx[1:0], 2'h0} : 4'h0)
    | (in_eewOH[3] ? {in_idx[0], 3'h0} : 4'h0);
endmodule
