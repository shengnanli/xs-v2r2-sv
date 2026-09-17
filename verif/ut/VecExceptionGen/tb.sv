// =============================================================================
// VecExceptionGen UT —— golden VecExceptionGen 对重写 VecExceptionGen_xs 双例化，
// 同激励逐拍比对唯一输出 io_illegalInst。
//
// ★ 这个 DUT 为什么不能纯随机打 ★
// 它是一张巨大的指令译码表：32 位 inst 里只有极少数编码落进 260 条 BitPat。
// 均匀随机 32 位 inst，命中任何一条向量指令的概率约 1e-4 —— 200k 拍下来
// 每个指令类平均命中个位数次，而真正有判别力的点（EMUL 越界、寄存器不对齐、
// vd/vs 重叠边界）还要叠加 vtype/寄存器号的特定取值，纯随机等于没测。
// 所以激励分三档（见 gen_inst）：
//   70%  从 260 条指令的**真实编码池**里抽一条，再随机填 vd/vs1/vs2/vm/nf 等可变域
//   20%  在真实编码基础上翻 1~3 个随机位（制造「几乎是合法指令」的边界）
//   10%  全 32 位随机（保证非向量编码、默认分支也被覆盖）
// vtype(vsew/vlmul)、vstart、srcType、vecWen、fuType 另行按有判别力的分布打。
//
// ★ 覆盖证据 ★
// tb 统计每个指令类被命中的次数与 7 个非法分支各自被触发的次数，任何一项为 0
// 都说明这一轮没验到它（$display 的 COVERAGE 段），此时 errors=0 不作数。
// =============================================================================

`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  // 指令编码池：VecExceptionGen 关心的全部 232 条指令。
  // 每项 {care 掩码, 值}；可变域（vd/vs1/vs2/vm/nf...）= care 为 0 的位。
  localparam int NPOOL = 232;
  logic [31:0] pool_care [NPOOL];
  logic [31:0] pool_val  [NPOOL];
  string       pool_name [NPOOL];
  longint      cov_class_hit [NPOOL];
  initial begin
    pool_care[  0] = 32'h1DF0707F; pool_val[  0] = 32'h00000007; pool_name[  0] = "VLE8_V";
    pool_care[  1] = 32'h1DF0707F; pool_val[  1] = 32'h00005007; pool_name[  1] = "VLE16_V";
    pool_care[  2] = 32'h1DF0707F; pool_val[  2] = 32'h00006007; pool_name[  2] = "VLE32_V";
    pool_care[  3] = 32'h1DF0707F; pool_val[  3] = 32'h00007007; pool_name[  3] = "VLE64_V";
    pool_care[  4] = 32'h1DF0707F; pool_val[  4] = 32'h00000027; pool_name[  4] = "VSE8_V";
    pool_care[  5] = 32'h1DF0707F; pool_val[  5] = 32'h00005027; pool_name[  5] = "VSE16_V";
    pool_care[  6] = 32'h1DF0707F; pool_val[  6] = 32'h00006027; pool_name[  6] = "VSE32_V";
    pool_care[  7] = 32'h1DF0707F; pool_val[  7] = 32'h00007027; pool_name[  7] = "VSE64_V";
    pool_care[  8] = 32'h1C00707F; pool_val[  8] = 32'h08000007; pool_name[  8] = "VLSE8_V";
    pool_care[  9] = 32'h1C00707F; pool_val[  9] = 32'h08005007; pool_name[  9] = "VLSE16_V";
    pool_care[ 10] = 32'h1C00707F; pool_val[ 10] = 32'h08006007; pool_name[ 10] = "VLSE32_V";
    pool_care[ 11] = 32'h1C00707F; pool_val[ 11] = 32'h08007007; pool_name[ 11] = "VLSE64_V";
    pool_care[ 12] = 32'h1C00707F; pool_val[ 12] = 32'h08000027; pool_name[ 12] = "VSSE8_V";
    pool_care[ 13] = 32'h1C00707F; pool_val[ 13] = 32'h08005027; pool_name[ 13] = "VSSE16_V";
    pool_care[ 14] = 32'h1C00707F; pool_val[ 14] = 32'h08006027; pool_name[ 14] = "VSSE32_V";
    pool_care[ 15] = 32'h1C00707F; pool_val[ 15] = 32'h08007027; pool_name[ 15] = "VSSE64_V";
    pool_care[ 16] = 32'h1DF0707F; pool_val[ 16] = 32'h01000007; pool_name[ 16] = "VLE8FF_V";
    pool_care[ 17] = 32'h1DF0707F; pool_val[ 17] = 32'h01005007; pool_name[ 17] = "VLE16FF_V";
    pool_care[ 18] = 32'h1DF0707F; pool_val[ 18] = 32'h01006007; pool_name[ 18] = "VLE32FF_V";
    pool_care[ 19] = 32'h1DF0707F; pool_val[ 19] = 32'h01007007; pool_name[ 19] = "VLE64FF_V";
    pool_care[ 20] = 32'hFFF0707F; pool_val[ 20] = 32'h02B00007; pool_name[ 20] = "VLM_V";
    pool_care[ 21] = 32'hFFF0707F; pool_val[ 21] = 32'h02B00027; pool_name[ 21] = "VSM_V";
    pool_care[ 22] = 32'h1C00707F; pool_val[ 22] = 32'h04000007; pool_name[ 22] = "VLUXEI8_V";
    pool_care[ 23] = 32'h1C00707F; pool_val[ 23] = 32'h04005007; pool_name[ 23] = "VLUXEI16_V";
    pool_care[ 24] = 32'h1C00707F; pool_val[ 24] = 32'h04006007; pool_name[ 24] = "VLUXEI32_V";
    pool_care[ 25] = 32'h1C00707F; pool_val[ 25] = 32'h04007007; pool_name[ 25] = "VLUXEI64_V";
    pool_care[ 26] = 32'h1C00707F; pool_val[ 26] = 32'h0C000007; pool_name[ 26] = "VLOXEI8_V";
    pool_care[ 27] = 32'h1C00707F; pool_val[ 27] = 32'h0C005007; pool_name[ 27] = "VLOXEI16_V";
    pool_care[ 28] = 32'h1C00707F; pool_val[ 28] = 32'h0C006007; pool_name[ 28] = "VLOXEI32_V";
    pool_care[ 29] = 32'h1C00707F; pool_val[ 29] = 32'h0C007007; pool_name[ 29] = "VLOXEI64_V";
    pool_care[ 30] = 32'h1C00707F; pool_val[ 30] = 32'h04000027; pool_name[ 30] = "VSUXEI8_V";
    pool_care[ 31] = 32'h1C00707F; pool_val[ 31] = 32'h04005027; pool_name[ 31] = "VSUXEI16_V";
    pool_care[ 32] = 32'h1C00707F; pool_val[ 32] = 32'h04006027; pool_name[ 32] = "VSUXEI32_V";
    pool_care[ 33] = 32'h1C00707F; pool_val[ 33] = 32'h04007027; pool_name[ 33] = "VSUXEI64_V";
    pool_care[ 34] = 32'h1C00707F; pool_val[ 34] = 32'h0C000027; pool_name[ 34] = "VSOXEI8_V";
    pool_care[ 35] = 32'h1C00707F; pool_val[ 35] = 32'h0C005027; pool_name[ 35] = "VSOXEI16_V";
    pool_care[ 36] = 32'h1C00707F; pool_val[ 36] = 32'h0C006027; pool_name[ 36] = "VSOXEI32_V";
    pool_care[ 37] = 32'h1C00707F; pool_val[ 37] = 32'h0C007027; pool_name[ 37] = "VSOXEI64_V";
    pool_care[ 38] = 32'hFFF0707F; pool_val[ 38] = 32'h02800007; pool_name[ 38] = "VL1RE8_V";
    pool_care[ 39] = 32'hFFF0707F; pool_val[ 39] = 32'h02805007; pool_name[ 39] = "VL1RE16_V";
    pool_care[ 40] = 32'hFFF0707F; pool_val[ 40] = 32'h02806007; pool_name[ 40] = "VL1RE32_V";
    pool_care[ 41] = 32'hFFF0707F; pool_val[ 41] = 32'h02807007; pool_name[ 41] = "VL1RE64_V";
    pool_care[ 42] = 32'hFFF0707F; pool_val[ 42] = 32'h22800007; pool_name[ 42] = "VL2RE8_V";
    pool_care[ 43] = 32'hFFF0707F; pool_val[ 43] = 32'h22805007; pool_name[ 43] = "VL2RE16_V";
    pool_care[ 44] = 32'hFFF0707F; pool_val[ 44] = 32'h22806007; pool_name[ 44] = "VL2RE32_V";
    pool_care[ 45] = 32'hFFF0707F; pool_val[ 45] = 32'h22807007; pool_name[ 45] = "VL2RE64_V";
    pool_care[ 46] = 32'hFFF0707F; pool_val[ 46] = 32'h62800007; pool_name[ 46] = "VL4RE8_V";
    pool_care[ 47] = 32'hFFF0707F; pool_val[ 47] = 32'h62805007; pool_name[ 47] = "VL4RE16_V";
    pool_care[ 48] = 32'hFFF0707F; pool_val[ 48] = 32'h62806007; pool_name[ 48] = "VL4RE32_V";
    pool_care[ 49] = 32'hFFF0707F; pool_val[ 49] = 32'h62807007; pool_name[ 49] = "VL4RE64_V";
    pool_care[ 50] = 32'hFFF0707F; pool_val[ 50] = 32'hE2800007; pool_name[ 50] = "VL8RE8_V";
    pool_care[ 51] = 32'hFFF0707F; pool_val[ 51] = 32'hE2805007; pool_name[ 51] = "VL8RE16_V";
    pool_care[ 52] = 32'hFFF0707F; pool_val[ 52] = 32'hE2806007; pool_name[ 52] = "VL8RE32_V";
    pool_care[ 53] = 32'hFFF0707F; pool_val[ 53] = 32'hE2807007; pool_name[ 53] = "VL8RE64_V";
    pool_care[ 54] = 32'hFFF0707F; pool_val[ 54] = 32'h02800027; pool_name[ 54] = "VS1R_V";
    pool_care[ 55] = 32'hFFF0707F; pool_val[ 55] = 32'h22800027; pool_name[ 55] = "VS2R_V";
    pool_care[ 56] = 32'hFFF0707F; pool_val[ 56] = 32'h62800027; pool_name[ 56] = "VS4R_V";
    pool_care[ 57] = 32'hFFF0707F; pool_val[ 57] = 32'hE2800027; pool_name[ 57] = "VS8R_V";
    pool_care[ 58] = 32'hFC00707F; pool_val[ 58] = 32'hC4002057; pool_name[ 58] = "VWADD_VV";
    pool_care[ 59] = 32'hFC00707F; pool_val[ 59] = 32'hC4006057; pool_name[ 59] = "VWADD_VX";
    pool_care[ 60] = 32'hFC00707F; pool_val[ 60] = 32'hD4002057; pool_name[ 60] = "VWADD_WV";
    pool_care[ 61] = 32'hFC00707F; pool_val[ 61] = 32'hD4006057; pool_name[ 61] = "VWADD_WX";
    pool_care[ 62] = 32'hFC00707F; pool_val[ 62] = 32'hC0002057; pool_name[ 62] = "VWADDU_VV";
    pool_care[ 63] = 32'hFC00707F; pool_val[ 63] = 32'hC0006057; pool_name[ 63] = "VWADDU_VX";
    pool_care[ 64] = 32'hFC00707F; pool_val[ 64] = 32'hD0002057; pool_name[ 64] = "VWADDU_WV";
    pool_care[ 65] = 32'hFC00707F; pool_val[ 65] = 32'hD0006057; pool_name[ 65] = "VWADDU_WX";
    pool_care[ 66] = 32'hFC00707F; pool_val[ 66] = 32'hF4002057; pool_name[ 66] = "VWMACC_VV";
    pool_care[ 67] = 32'hFC00707F; pool_val[ 67] = 32'hF4006057; pool_name[ 67] = "VWMACC_VX";
    pool_care[ 68] = 32'hFC00707F; pool_val[ 68] = 32'hFC002057; pool_name[ 68] = "VWMACCSU_VV";
    pool_care[ 69] = 32'hFC00707F; pool_val[ 69] = 32'hFC006057; pool_name[ 69] = "VWMACCSU_VX";
    pool_care[ 70] = 32'hFC00707F; pool_val[ 70] = 32'hF0002057; pool_name[ 70] = "VWMACCU_VV";
    pool_care[ 71] = 32'hFC00707F; pool_val[ 71] = 32'hF0006057; pool_name[ 71] = "VWMACCU_VX";
    pool_care[ 72] = 32'hFC00707F; pool_val[ 72] = 32'hF8006057; pool_name[ 72] = "VWMACCUS_VX";
    pool_care[ 73] = 32'hFC00707F; pool_val[ 73] = 32'hEC002057; pool_name[ 73] = "VWMUL_VV";
    pool_care[ 74] = 32'hFC00707F; pool_val[ 74] = 32'hEC006057; pool_name[ 74] = "VWMUL_VX";
    pool_care[ 75] = 32'hFC00707F; pool_val[ 75] = 32'hE8002057; pool_name[ 75] = "VWMULSU_VV";
    pool_care[ 76] = 32'hFC00707F; pool_val[ 76] = 32'hE8006057; pool_name[ 76] = "VWMULSU_VX";
    pool_care[ 77] = 32'hFC00707F; pool_val[ 77] = 32'hE0002057; pool_name[ 77] = "VWMULU_VV";
    pool_care[ 78] = 32'hFC00707F; pool_val[ 78] = 32'hE0006057; pool_name[ 78] = "VWMULU_VX";
    pool_care[ 79] = 32'hFC00707F; pool_val[ 79] = 32'hCC002057; pool_name[ 79] = "VWSUB_VV";
    pool_care[ 80] = 32'hFC00707F; pool_val[ 80] = 32'hCC006057; pool_name[ 80] = "VWSUB_VX";
    pool_care[ 81] = 32'hFC00707F; pool_val[ 81] = 32'hDC002057; pool_name[ 81] = "VWSUB_WV";
    pool_care[ 82] = 32'hFC00707F; pool_val[ 82] = 32'hDC006057; pool_name[ 82] = "VWSUB_WX";
    pool_care[ 83] = 32'hFC00707F; pool_val[ 83] = 32'hC8002057; pool_name[ 83] = "VWSUBU_VV";
    pool_care[ 84] = 32'hFC00707F; pool_val[ 84] = 32'hC8006057; pool_name[ 84] = "VWSUBU_VX";
    pool_care[ 85] = 32'hFC00707F; pool_val[ 85] = 32'hD8002057; pool_name[ 85] = "VWSUBU_WV";
    pool_care[ 86] = 32'hFC00707F; pool_val[ 86] = 32'hD8006057; pool_name[ 86] = "VWSUBU_WX";
    pool_care[ 87] = 32'hFC00707F; pool_val[ 87] = 32'hC0005057; pool_name[ 87] = "VFWADD_VF";
    pool_care[ 88] = 32'hFC00707F; pool_val[ 88] = 32'hC0001057; pool_name[ 88] = "VFWADD_VV";
    pool_care[ 89] = 32'hFC00707F; pool_val[ 89] = 32'hD0005057; pool_name[ 89] = "VFWADD_WF";
    pool_care[ 90] = 32'hFC00707F; pool_val[ 90] = 32'hD0001057; pool_name[ 90] = "VFWADD_WV";
    pool_care[ 91] = 32'hFC00707F; pool_val[ 91] = 32'hC8005057; pool_name[ 91] = "VFWSUB_VF";
    pool_care[ 92] = 32'hFC00707F; pool_val[ 92] = 32'hC8001057; pool_name[ 92] = "VFWSUB_VV";
    pool_care[ 93] = 32'hFC00707F; pool_val[ 93] = 32'hD8005057; pool_name[ 93] = "VFWSUB_WF";
    pool_care[ 94] = 32'hFC00707F; pool_val[ 94] = 32'hD8001057; pool_name[ 94] = "VFWSUB_WV";
    pool_care[ 95] = 32'hFC00707F; pool_val[ 95] = 32'hE0005057; pool_name[ 95] = "VFWMUL_VF";
    pool_care[ 96] = 32'hFC00707F; pool_val[ 96] = 32'hE0001057; pool_name[ 96] = "VFWMUL_VV";
    pool_care[ 97] = 32'hFC00707F; pool_val[ 97] = 32'hF0005057; pool_name[ 97] = "VFWMACC_VF";
    pool_care[ 98] = 32'hFC00707F; pool_val[ 98] = 32'hF0001057; pool_name[ 98] = "VFWMACC_VV";
    pool_care[ 99] = 32'hFC00707F; pool_val[ 99] = 32'hF8005057; pool_name[ 99] = "VFWMSAC_VF";
    pool_care[100] = 32'hFC00707F; pool_val[100] = 32'hF8001057; pool_name[100] = "VFWMSAC_VV";
    pool_care[101] = 32'hFC00707F; pool_val[101] = 32'hF4005057; pool_name[101] = "VFWNMACC_VF";
    pool_care[102] = 32'hFC00707F; pool_val[102] = 32'hF4001057; pool_name[102] = "VFWNMACC_VV";
    pool_care[103] = 32'hFC00707F; pool_val[103] = 32'hFC005057; pool_name[103] = "VFWNMSAC_VF";
    pool_care[104] = 32'hFC00707F; pool_val[104] = 32'hFC001057; pool_name[104] = "VFWNMSAC_VV";
    pool_care[105] = 32'hFC0FF07F; pool_val[105] = 32'h48061057; pool_name[105] = "VFWCVT_F_F_V";
    pool_care[106] = 32'hFC0FF07F; pool_val[106] = 32'h48059057; pool_name[106] = "VFWCVT_F_X_V";
    pool_care[107] = 32'hFC0FF07F; pool_val[107] = 32'h48051057; pool_name[107] = "VFWCVT_F_XU_V";
    pool_care[108] = 32'hFC0FF07F; pool_val[108] = 32'h48079057; pool_name[108] = "VFWCVT_RTZ_X_F_V";
    pool_care[109] = 32'hFC0FF07F; pool_val[109] = 32'h48071057; pool_name[109] = "VFWCVT_RTZ_XU_F_V";
    pool_care[110] = 32'hFC0FF07F; pool_val[110] = 32'h48049057; pool_name[110] = "VFWCVT_X_F_V";
    pool_care[111] = 32'hFC0FF07F; pool_val[111] = 32'h48041057; pool_name[111] = "VFWCVT_XU_F_V";
    pool_care[112] = 32'hFC00707F; pool_val[112] = 32'hD4000057; pool_name[112] = "VWSLL_VV";
    pool_care[113] = 32'hFC00707F; pool_val[113] = 32'hD4004057; pool_name[113] = "VWSLL_VX";
    pool_care[114] = 32'hFC00707F; pool_val[114] = 32'hD4003057; pool_name[114] = "VWSLL_VI";
    pool_care[115] = 32'hFC00707F; pool_val[115] = 32'hBC003057; pool_name[115] = "VNCLIP_WI";
    pool_care[116] = 32'hFC00707F; pool_val[116] = 32'hBC000057; pool_name[116] = "VNCLIP_WV";
    pool_care[117] = 32'hFC00707F; pool_val[117] = 32'hBC004057; pool_name[117] = "VNCLIP_WX";
    pool_care[118] = 32'hFC00707F; pool_val[118] = 32'hB8003057; pool_name[118] = "VNCLIPU_WI";
    pool_care[119] = 32'hFC00707F; pool_val[119] = 32'hB8000057; pool_name[119] = "VNCLIPU_WV";
    pool_care[120] = 32'hFC00707F; pool_val[120] = 32'hB8004057; pool_name[120] = "VNCLIPU_WX";
    pool_care[121] = 32'hFC00707F; pool_val[121] = 32'hB4003057; pool_name[121] = "VNSRA_WI";
    pool_care[122] = 32'hFC00707F; pool_val[122] = 32'hB4000057; pool_name[122] = "VNSRA_WV";
    pool_care[123] = 32'hFC00707F; pool_val[123] = 32'hB4004057; pool_name[123] = "VNSRA_WX";
    pool_care[124] = 32'hFC00707F; pool_val[124] = 32'hB0003057; pool_name[124] = "VNSRL_WI";
    pool_care[125] = 32'hFC00707F; pool_val[125] = 32'hB0000057; pool_name[125] = "VNSRL_WV";
    pool_care[126] = 32'hFC00707F; pool_val[126] = 32'hB0004057; pool_name[126] = "VNSRL_WX";
    pool_care[127] = 32'hFC0FF07F; pool_val[127] = 32'h480A1057; pool_name[127] = "VFNCVT_F_F_W";
    pool_care[128] = 32'hFC0FF07F; pool_val[128] = 32'h48099057; pool_name[128] = "VFNCVT_F_X_W";
    pool_care[129] = 32'hFC0FF07F; pool_val[129] = 32'h48091057; pool_name[129] = "VFNCVT_F_XU_W";
    pool_care[130] = 32'hFC0FF07F; pool_val[130] = 32'h480A9057; pool_name[130] = "VFNCVT_ROD_F_F_W";
    pool_care[131] = 32'hFC0FF07F; pool_val[131] = 32'h480B9057; pool_name[131] = "VFNCVT_RTZ_X_F_W";
    pool_care[132] = 32'hFC0FF07F; pool_val[132] = 32'h480B1057; pool_name[132] = "VFNCVT_RTZ_XU_F_W";
    pool_care[133] = 32'hFC0FF07F; pool_val[133] = 32'h48089057; pool_name[133] = "VFNCVT_X_F_W";
    pool_care[134] = 32'hFC0FF07F; pool_val[134] = 32'h48081057; pool_name[134] = "VFNCVT_XU_F_W";
    pool_care[135] = 32'hFC0FF07F; pool_val[135] = 32'h4803A057; pool_name[135] = "VSEXT_VF2";
    pool_care[136] = 32'hFC0FF07F; pool_val[136] = 32'h4802A057; pool_name[136] = "VSEXT_VF4";
    pool_care[137] = 32'hFC0FF07F; pool_val[137] = 32'h4801A057; pool_name[137] = "VSEXT_VF8";
    pool_care[138] = 32'hFC0FF07F; pool_val[138] = 32'h48032057; pool_name[138] = "VZEXT_VF2";
    pool_care[139] = 32'hFC0FF07F; pool_val[139] = 32'h48022057; pool_name[139] = "VZEXT_VF4";
    pool_care[140] = 32'hFC0FF07F; pool_val[140] = 32'h48012057; pool_name[140] = "VZEXT_VF8";
    pool_care[141] = 32'hFE00707F; pool_val[141] = 32'h46003057; pool_name[141] = "VMADC_VI";
    pool_care[142] = 32'hFE00707F; pool_val[142] = 32'h44003057; pool_name[142] = "VMADC_VIM";
    pool_care[143] = 32'hFE00707F; pool_val[143] = 32'h46000057; pool_name[143] = "VMADC_VV";
    pool_care[144] = 32'hFE00707F; pool_val[144] = 32'h44000057; pool_name[144] = "VMADC_VVM";
    pool_care[145] = 32'hFE00707F; pool_val[145] = 32'h46004057; pool_name[145] = "VMADC_VX";
    pool_care[146] = 32'hFE00707F; pool_val[146] = 32'h44004057; pool_name[146] = "VMADC_VXM";
    pool_care[147] = 32'hFE00707F; pool_val[147] = 32'h4E000057; pool_name[147] = "VMSBC_VV";
    pool_care[148] = 32'hFE00707F; pool_val[148] = 32'h4C000057; pool_name[148] = "VMSBC_VVM";
    pool_care[149] = 32'hFE00707F; pool_val[149] = 32'h4E004057; pool_name[149] = "VMSBC_VX";
    pool_care[150] = 32'hFE00707F; pool_val[150] = 32'h4C004057; pool_name[150] = "VMSBC_VXM";
    pool_care[151] = 32'hFC00707F; pool_val[151] = 32'h60003057; pool_name[151] = "VMSEQ_VI";
    pool_care[152] = 32'hFC00707F; pool_val[152] = 32'h60000057; pool_name[152] = "VMSEQ_VV";
    pool_care[153] = 32'hFC00707F; pool_val[153] = 32'h60004057; pool_name[153] = "VMSEQ_VX";
    pool_care[154] = 32'hFC00707F; pool_val[154] = 32'h7C003057; pool_name[154] = "VMSGT_VI";
    pool_care[155] = 32'hFC00707F; pool_val[155] = 32'h7C004057; pool_name[155] = "VMSGT_VX";
    pool_care[156] = 32'hFC00707F; pool_val[156] = 32'h78003057; pool_name[156] = "VMSGTU_VI";
    pool_care[157] = 32'hFC00707F; pool_val[157] = 32'h78004057; pool_name[157] = "VMSGTU_VX";
    pool_care[158] = 32'hFC00707F; pool_val[158] = 32'h74003057; pool_name[158] = "VMSLE_VI";
    pool_care[159] = 32'hFC00707F; pool_val[159] = 32'h74000057; pool_name[159] = "VMSLE_VV";
    pool_care[160] = 32'hFC00707F; pool_val[160] = 32'h74004057; pool_name[160] = "VMSLE_VX";
    pool_care[161] = 32'hFC00707F; pool_val[161] = 32'h70003057; pool_name[161] = "VMSLEU_VI";
    pool_care[162] = 32'hFC00707F; pool_val[162] = 32'h70000057; pool_name[162] = "VMSLEU_VV";
    pool_care[163] = 32'hFC00707F; pool_val[163] = 32'h70004057; pool_name[163] = "VMSLEU_VX";
    pool_care[164] = 32'hFC00707F; pool_val[164] = 32'h6C000057; pool_name[164] = "VMSLT_VV";
    pool_care[165] = 32'hFC00707F; pool_val[165] = 32'h6C004057; pool_name[165] = "VMSLT_VX";
    pool_care[166] = 32'hFC00707F; pool_val[166] = 32'h68000057; pool_name[166] = "VMSLTU_VV";
    pool_care[167] = 32'hFC00707F; pool_val[167] = 32'h68004057; pool_name[167] = "VMSLTU_VX";
    pool_care[168] = 32'hFC00707F; pool_val[168] = 32'h64003057; pool_name[168] = "VMSNE_VI";
    pool_care[169] = 32'hFC00707F; pool_val[169] = 32'h64000057; pool_name[169] = "VMSNE_VV";
    pool_care[170] = 32'hFC00707F; pool_val[170] = 32'h64004057; pool_name[170] = "VMSNE_VX";
    pool_care[171] = 32'hFC00707F; pool_val[171] = 32'h60005057; pool_name[171] = "VMFEQ_VF";
    pool_care[172] = 32'hFC00707F; pool_val[172] = 32'h60001057; pool_name[172] = "VMFEQ_VV";
    pool_care[173] = 32'hFC00707F; pool_val[173] = 32'h70005057; pool_name[173] = "VMFNE_VF";
    pool_care[174] = 32'hFC00707F; pool_val[174] = 32'h70001057; pool_name[174] = "VMFNE_VV";
    pool_care[175] = 32'hFC00707F; pool_val[175] = 32'h7C005057; pool_name[175] = "VMFGE_VF";
    pool_care[176] = 32'hFC00707F; pool_val[176] = 32'h74005057; pool_name[176] = "VMFGT_VF";
    pool_care[177] = 32'hFC00707F; pool_val[177] = 32'h64005057; pool_name[177] = "VMFLE_VF";
    pool_care[178] = 32'hFC00707F; pool_val[178] = 32'h64001057; pool_name[178] = "VMFLE_VV";
    pool_care[179] = 32'hFC00707F; pool_val[179] = 32'h6C005057; pool_name[179] = "VMFLT_VF";
    pool_care[180] = 32'hFC00707F; pool_val[180] = 32'h6C001057; pool_name[180] = "VMFLT_VV";
    pool_care[181] = 32'hFC00707F; pool_val[181] = 32'h04002057; pool_name[181] = "VREDAND_VS";
    pool_care[182] = 32'hFC00707F; pool_val[182] = 32'h1C002057; pool_name[182] = "VREDMAX_VS";
    pool_care[183] = 32'hFC00707F; pool_val[183] = 32'h18002057; pool_name[183] = "VREDMAXU_VS";
    pool_care[184] = 32'hFC00707F; pool_val[184] = 32'h14002057; pool_name[184] = "VREDMIN_VS";
    pool_care[185] = 32'hFC00707F; pool_val[185] = 32'h10002057; pool_name[185] = "VREDMINU_VS";
    pool_care[186] = 32'hFC00707F; pool_val[186] = 32'h08002057; pool_name[186] = "VREDOR_VS";
    pool_care[187] = 32'hFC00707F; pool_val[187] = 32'h00002057; pool_name[187] = "VREDSUM_VS";
    pool_care[188] = 32'hFC00707F; pool_val[188] = 32'h0C002057; pool_name[188] = "VREDXOR_VS";
    pool_care[189] = 32'hFC00707F; pool_val[189] = 32'h1C001057; pool_name[189] = "VFREDMAX_VS";
    pool_care[190] = 32'hFC00707F; pool_val[190] = 32'h14001057; pool_name[190] = "VFREDMIN_VS";
    pool_care[191] = 32'hFC00707F; pool_val[191] = 32'h0C001057; pool_name[191] = "VFREDOSUM_VS";
    pool_care[192] = 32'hFC00707F; pool_val[192] = 32'h04001057; pool_name[192] = "VFREDUSUM_VS";
    pool_care[193] = 32'hFC00707F; pool_val[193] = 32'hC4000057; pool_name[193] = "VWREDSUM_VS";
    pool_care[194] = 32'hFC00707F; pool_val[194] = 32'hC0000057; pool_name[194] = "VWREDSUMU_VS";
    pool_care[195] = 32'hFC00707F; pool_val[195] = 32'hCC001057; pool_name[195] = "VFWREDOSUM_VS";
    pool_care[196] = 32'hFC00707F; pool_val[196] = 32'hC4001057; pool_name[196] = "VFWREDUSUM_VS";
    pool_care[197] = 32'hFE00707F; pool_val[197] = 32'h66002057; pool_name[197] = "VMAND_MM";
    pool_care[198] = 32'hFE00707F; pool_val[198] = 32'h76002057; pool_name[198] = "VMNAND_MM";
    pool_care[199] = 32'hFE00707F; pool_val[199] = 32'h62002057; pool_name[199] = "VMANDN_MM";
    pool_care[200] = 32'hFE00707F; pool_val[200] = 32'h6E002057; pool_name[200] = "VMXOR_MM";
    pool_care[201] = 32'hFE00707F; pool_val[201] = 32'h6A002057; pool_name[201] = "VMOR_MM";
    pool_care[202] = 32'hFE00707F; pool_val[202] = 32'h7A002057; pool_name[202] = "VMNOR_MM";
    pool_care[203] = 32'hFE00707F; pool_val[203] = 32'h72002057; pool_name[203] = "VMORN_MM";
    pool_care[204] = 32'hFE00707F; pool_val[204] = 32'h7E002057; pool_name[204] = "VMXNOR_MM";
    pool_care[205] = 32'hFC0FF07F; pool_val[205] = 32'h40082057; pool_name[205] = "VCPOP_M";
    pool_care[206] = 32'hFC0FF07F; pool_val[206] = 32'h4008A057; pool_name[206] = "VFIRST_M";
    pool_care[207] = 32'hFC0FF07F; pool_val[207] = 32'h5000A057; pool_name[207] = "VMSBF_M";
    pool_care[208] = 32'hFC0FF07F; pool_val[208] = 32'h5001A057; pool_name[208] = "VMSIF_M";
    pool_care[209] = 32'hFC0FF07F; pool_val[209] = 32'h50012057; pool_name[209] = "VMSOF_M";
    pool_care[210] = 32'hFC0FF07F; pool_val[210] = 32'h50082057; pool_name[210] = "VIOTA_M";
    pool_care[211] = 32'hFDFFF07F; pool_val[211] = 32'h5008A057; pool_name[211] = "VID_V";
    pool_care[212] = 32'hFE0FF07F; pool_val[212] = 32'h42002057; pool_name[212] = "VMV_X_S";
    pool_care[213] = 32'hFFF0707F; pool_val[213] = 32'h42006057; pool_name[213] = "VMV_S_X";
    pool_care[214] = 32'hFE0FF07F; pool_val[214] = 32'h42001057; pool_name[214] = "VFMV_F_S";
    pool_care[215] = 32'hFFF0707F; pool_val[215] = 32'h42005057; pool_name[215] = "VFMV_S_F";
    pool_care[216] = 32'hFE0FF07F; pool_val[216] = 32'h9E003057; pool_name[216] = "VMV1R_V";
    pool_care[217] = 32'hFE0FF07F; pool_val[217] = 32'h9E00B057; pool_name[217] = "VMV2R_V";
    pool_care[218] = 32'hFE0FF07F; pool_val[218] = 32'h9E01B057; pool_name[218] = "VMV4R_V";
    pool_care[219] = 32'hFE0FF07F; pool_val[219] = 32'h9E03B057; pool_name[219] = "VMV8R_V";
    pool_care[220] = 32'hFC00707F; pool_val[220] = 32'h38000057; pool_name[220] = "VRGATHEREI16_VV";
    pool_care[221] = 32'hFE00707F; pool_val[221] = 32'h5E002057; pool_name[221] = "VCOMPRESS_VM";
    pool_care[222] = 32'h8000707F; pool_val[222] = 32'h00007057; pool_name[222] = "VSETVLI";
    pool_care[223] = 32'hC000707F; pool_val[223] = 32'hC0007057; pool_name[223] = "VSETIVLI";
    pool_care[224] = 32'hFE00707F; pool_val[224] = 32'h80007057; pool_name[224] = "VSETVL";
    pool_care[225] = 32'hFC00707F; pool_val[225] = 32'h38004057; pool_name[225] = "VSLIDEUP_VX";
    pool_care[226] = 32'hFC00707F; pool_val[226] = 32'h38003057; pool_name[226] = "VSLIDEUP_VI";
    pool_care[227] = 32'hFC00707F; pool_val[227] = 32'h38006057; pool_name[227] = "VSLIDE1UP_VX";
    pool_care[228] = 32'hFC00707F; pool_val[228] = 32'h38005057; pool_name[228] = "VFSLIDE1UP_VF";
    pool_care[229] = 32'hFC00707F; pool_val[229] = 32'h30000057; pool_name[229] = "VRGATHER_VV";
    pool_care[230] = 32'hFC00707F; pool_val[230] = 32'h30004057; pool_name[230] = "VRGATHER_VX";
    pool_care[231] = 32'hFC00707F; pool_val[231] = 32'h30003057; pool_name[231] = "VRGATHER_VI";
  end

  // 四档指令激励，见文件头说明。返回值同时通过 pool_idx 报告
  // 「这是不是一条未经改动的池内指令」，供覆盖统计用。
  function automatic logic [31:0] gen_inst(output int pool_idx);
    int unsigned r = $urandom_range(0, 99);
    logic [31:0] base, care;
    int          k, b;
    pool_idx = -1;
    if (r >= 95) return $urandom;               // 5%：全随机（非向量编码/默认分支）
    pool_idx = $urandom_range(0, NPOOL - 1);
    care = pool_care[pool_idx];
    base = (pool_val[pool_idx] & care) | ($urandom & ~care);
    base = apply_field_bias(base, care);
    if (r >= 80) begin                          // 15%：合法编码上翻 1~3 位
      for (k = 0; k < $urandom_range(1, 3); k++) begin
        b = $urandom_range(0, 31);
        base[b] = ~base[b];
      end
      pool_idx = -1;
    end else if (r >= 70) begin                 // 10%：只清 vm 位（bit25）
      // 为什么要单独一档：vm=0 是 v0 重叠判据的**唯一**入口，而多数向量指令的
      // BitPat 把 bit25 列为 care 位并钉成 1 —— 靠随机翻位几乎打不到。
      base[25] = 1'b0;
      if (care[25]) pool_idx = -1;              // 动了 care 位就不再算「命中该指令」
    end
    return base;
  endfunction

  // 寄存器号/nf 的定向偏置：只改 care 掩码为 0 的位（不破坏指令归类）。
  // 重叠判据(§6)几乎全部挂在「vd 与 vs1/vs2 的区间恰好相接/包含」上，均匀随机
  // 5 位寄存器号撞上这些边界的概率太低。
  function automatic logic [31:0] apply_field_bias(input logic [31:0] base,
                                                   input logic [31:0] care);
    logic [4:0] vd, vs1, vs2;
    logic [2:0] nf;
    logic [31:0] o = base;
    // vd：1/4 取 v0（v0 重叠判据的必要条件），1/4 取 8 的倍数（对齐边界），其余随机
    // vd：v0（v0 重叠判据的必要条件）、8 的倍数（对齐边界）、高号段 24..31
    //（vd + 2^EMUL - 1 会在 5 位上回绕的唯一区间）各占一档，其余随机。
    case ($urandom_range(0, 3))
      0: vd = 5'd0;
      1: vd = 5'($urandom_range(0, 3)) << 3;
      2: vd = 5'd24 + 5'($urandom_range(0, 7));
      default: vd = 5'($urandom);
    endcase
    // vs1/vs2：各 1/3 概率与 vd 相同（区间完全重合）、与 vd 差 1~4（部分重叠）
    case ($urandom_range(0, 2))
      0: vs1 = vd;
      1: vs1 = vd + 5'($urandom_range(1, 4));
      default: vs1 = 5'($urandom);
    endcase
    case ($urandom_range(0, 2))
      0: vs2 = vd;
      1: vs2 = vd + 5'($urandom_range(1, 4));
      default: vs2 = 5'($urandom);
    endcase
    // nf：一半为 0（非段访存），一半取 1/2/3/7（段访存的合法/非法边界）
    case ($urandom_range(0, 3))
      0, 1: nf = 3'd0;
      2:    nf = 3'($urandom_range(1, 3));
      default: nf = 3'd7;
    endcase
    o = subst(o, care, 11, 7,  {27'd0, vd});
    o = subst(o, care, 19, 15, {27'd0, vs1});
    o = subst(o, care, 24, 20, {27'd0, vs2});
    o = subst(o, care, 31, 29, {29'd0, nf});
    return o;
  endfunction

  // 把 [hi:lo] 里 care 为 0 的位换成 v 的对应位，care 为 1 的位原样保留。
  function automatic logic [31:0] subst(input logic [31:0] o, input logic [31:0] care,
                                        input int hi, input int lo, input logic [31:0] v);
    logic [31:0] r = o;
    for (int i = lo; i <= hi; i++)
      if (!care[i]) r[i] = v[i - lo];
    return r;
  endfunction

  // vtype.vlmul：全 8 种等概率（编码 100..111 是 LMUL 1/2/4/8，000..011 是分数）
  function automatic logic [2:0] gen_vlmul();
    return 3'($urandom);
  endfunction


  // --- DUT 端口 -------------------------------------------------------------
  logic [31:0] io_inst;
  logic [3:0]  io_decodedInst_srcType_0, io_decodedInst_srcType_1, io_decodedInst_srcType_2;
  logic [34:0] io_decodedInst_fuType;
  logic        io_decodedInst_vecWen;
  logic        io_vtype_illegal;
  logic [1:0]  io_vtype_vsew;
  logic [2:0]  io_vtype_vlmul;
  logic [7:0]  io_vstart;
  logic        gold_illegal, xs_illegal;

  VecExceptionGen u_gold (
    .io_inst(io_inst), .io_decodedInst_srcType_0(io_decodedInst_srcType_0),
    .io_decodedInst_srcType_1(io_decodedInst_srcType_1),
    .io_decodedInst_srcType_2(io_decodedInst_srcType_2),
    .io_decodedInst_fuType(io_decodedInst_fuType),
    .io_decodedInst_vecWen(io_decodedInst_vecWen),
    .io_vtype_illegal(io_vtype_illegal), .io_vtype_vsew(io_vtype_vsew),
    .io_vtype_vlmul(io_vtype_vlmul), .io_vstart(io_vstart),
    .io_illegalInst(gold_illegal));

  VecExceptionGen_xs u_xs (
    .io_inst(io_inst), .io_decodedInst_srcType_0(io_decodedInst_srcType_0),
    .io_decodedInst_srcType_1(io_decodedInst_srcType_1),
    .io_decodedInst_srcType_2(io_decodedInst_srcType_2),
    .io_decodedInst_fuType(io_decodedInst_fuType),
    .io_decodedInst_vecWen(io_decodedInst_vecWen),
    .io_vtype_illegal(io_vtype_illegal), .io_vtype_vsew(io_vtype_vsew),
    .io_vtype_vlmul(io_vtype_vlmul), .io_vstart(io_vstart),
    .io_illegalInst(xs_illegal));

  // 覆盖计数：七类非法各自的触发次数由 golden 侧的内部线取（层次引用 golden，
  // 不引用重写件 —— 覆盖统计必须独立于被测件）。
  longint cov_illegal_total = 0, cov_legal_total = 0;
  longint cov_inst_ill = 0, cov_vill_ill = 0, cov_eew_ill = 0, cov_emul_ill = 0;
  longint cov_regnum_ill = 0, cov_overlap_ill = 0, cov_vstart_ill = 0;
  longint cov_pool_exact = 0, cov_flip = 0, cov_rand = 0;
  longint cov_hireg_wrap = 0;   // 「vd 区间上界回绕」定向档命中次数

  int pidx;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < NPOOL; i++) cov_class_hit[i] = 0;
    @(negedge clk);
    for (longint c = 0; c < NCYCLES; c++) begin
      io_inst = gen_inst(pidx);
      if (pidx >= 0) begin cov_class_hit[pidx]++; cov_pool_exact++; end
      // srcType：只有 bit2(isVp) 被读，但整 4 位都随机打，防止「只试了 isVp」
      io_decodedInst_srcType_0 = 4'($urandom);
      io_decodedInst_srcType_1 = 4'($urandom);
      io_decodedInst_srcType_2 = 4'($urandom);
      // fuType：只有 18..27(VArith) 与 31..34(VLoad/VStore) 被读。一半时间点亮
      // 一个随机的向量位（否则 isVArithMem 恒 0，整个模块输出恒 0）。
      // fuType：只有 18..27(向量算术) 与 31..34(向量访存) 被读，而且两组的作用
      // **不同**（vstart 判据只认算术组）。所以三档打：只点算术位 / 只点访存位 /
      // 全 0（此时 isVArithMem=0，重叠判据仍然有效，是另一条独立路径）。
      io_decodedInst_fuType = '0;
      case ($urandom_range(0, 3))
        0: io_decodedInst_fuType[18 + $urandom_range(0, 9)] = 1'b1;   // 向量算术
        1: io_decodedInst_fuType[31 + $urandom_range(0, 3)] = 1'b1;   // 向量访存
        2: begin                                                       // 两组各点一位
             io_decodedInst_fuType[18 + $urandom_range(0, 9)] = 1'b1;
             io_decodedInst_fuType[31 + $urandom_range(0, 3)] = 1'b1;
           end
        default: ;                                                     // 全 0
      endcase
      io_decodedInst_vecWen = 1'($urandom);
      io_vtype_illegal      = ($urandom_range(0, 3) == 0);
      io_vtype_vsew         = 2'($urandom);
      io_vtype_vlmul        = gen_vlmul();
      // vstart：一半为 0（正常路径），一半非零（vstartIllegal 的唯一触发条件）
      io_vstart = $urandom_range(0, 1) ? 8'($urandom) : 8'h0;

      // ★定向档：vd 区间上界在 5 位上回绕★（占 4%）
      // vd_reg_hi = vd + 2^EMUL - 1 是 **5 位** 运算（Chisel 用的是普通 `+`）。
      // 只有 vd 落在 25..31 且 EMUL>1 时才会回绕，而且必须同时满足：
      //   · 不是访存指令（否则 vd 上界走段访存那条路，与这条无关）
      //   · fuType 不含向量位（否则 regNumIllegal 会先把输出拉高，把差别盖掉）
      //   · vs1/vs2 与 vd 挨着（否则「区间不重叠」直接成立，也盖掉差别）
      // 纯随机撞上这一族的概率约 1e-7，200k 拍必漏 —— 实测：负测 M1 在没有这一档
      // 时 200k 抓不到，加上之后才抓到。
      if ($urandom_range(0, 24) == 0) begin
        cov_hireg_wrap++;
        io_vstart             = 8'h0;
        io_decodedInst_fuType = '0;                     // 关掉 regNumIllegal 这条路
        io_decodedInst_vecWen = 1'b1;
        io_decodedInst_srcType_0 = 4'h4;                // isVp
        io_decodedInst_srcType_1 = 4'h4;
        io_decodedInst_srcType_2 = 4'h4;
        io_vtype_illegal = 1'b0;
        io_vtype_vlmul   = 3'($urandom_range(1, 3));    // LMUL 编码 5/6/7（EMUL>1）
        begin
          logic [4:0] hv = 5'd31 - 5'($urandom_range(0, 6));
          io_inst[11:7]  = hv;                          // vd
          io_inst[19:15] = hv - 5'($urandom_range(0, 1));  // vs1 紧挨着 vd
          io_inst[24:20] = hv - 5'($urandom_range(0, 1));  // vs2
        end
      end

      #1;
      checks++;
      if (gold_illegal !== xs_illegal) begin
        errors++;
        if (errors < 20)
          $display("MISMATCH @%0d inst=%08h vsew=%0d vlmul=%0d vstart=%0h vecWen=%0b st=%0h/%0h/%0h fuType=%09h gold=%0b xs=%0b",
                   c, io_inst,
                   io_vtype_vsew, io_vtype_vlmul, io_vstart, io_decodedInst_vecWen,
                   io_decodedInst_srcType_0, io_decodedInst_srcType_1,
                   io_decodedInst_srcType_2, io_decodedInst_fuType,
                   gold_illegal, xs_illegal);
      end
      if (gold_illegal) cov_illegal_total++; else cov_legal_total++;
      if (u_gold.instIllegal)       cov_inst_ill++;
      if (u_gold.villIllegal)       cov_vill_ill++;
      if (u_gold.eewIllegal)        cov_eew_ill++;
      if (u_gold.emulIllegal)       cov_emul_ill++;
      if (u_gold.regNumIllegal)     cov_regnum_ill++;
      if (u_gold.regOverlapIllegal) cov_overlap_ill++;
      if (u_gold.vstartIllegal)     cov_vstart_ill++;
      @(negedge clk);
    end

    $display("=== COVERAGE (VecExceptionGen) ===");
    $display("  checks=%0d  illegal=%0d  legal=%0d", checks, cov_illegal_total,
             cov_legal_total);
    $display("  instIllegal=%0d villIllegal=%0d eewIllegal=%0d emulIllegal=%0d",
             cov_inst_ill, cov_vill_ill, cov_eew_ill, cov_emul_ill);
    $display("  regNumIllegal=%0d regOverlapIllegal=%0d vstartIllegal=%0d",
             cov_regnum_ill, cov_overlap_ill, cov_vstart_ill);
    $display("  定向档「vd 区间上界回绕」命中 %0d 次", cov_hireg_wrap);
    begin
      int zero_classes = 0;
      longint minhit = -1;
      for (int i = 0; i < NPOOL; i++) begin
        if (cov_class_hit[i] == 0) begin
          zero_classes++;
          $display("  ZERO-HIT instruction: %s", pool_name[i]);
        end
        if (minhit < 0 || cov_class_hit[i] < minhit) minhit = cov_class_hit[i];
      end
      $display("  pool instructions=%0d  zero-hit=%0d  min-hit=%0d",
               NPOOL, zero_classes, minhit);
      if (zero_classes != 0) begin
        $display("COVERAGE INSUFFICIENT: %0d 条指令一次都没打到", zero_classes);
        errors++;
      end
      // ★instIllegal 结构上不可达，不列入覆盖闸★
      // instIllegal = maskLogicalInst && VM==0，而 8 条掩码逻辑指令的 BitPat
      // (VMAND_MM = b0110011??????????010?????1010111 等) 都把 bit25(VM) 列为
      // care 位并钉成 1 —— maskLogicalInst 为真时 VM 必为 1，这个「与」永远是 0。
      // Chisel 的本意是「掩码逻辑指令不许带掩码」，但 BitPat 已经把带掩码的编码
      // 排除在外了，于是这条判据是一段死码。golden 照样把它展开成一根 wire
      // (firtool 不做跨 BitPat 的可达性分析)，本重写照抄结构，不合并、不化简。
      // 下面 assert_dead_instillegal 用定向激励把「不可达」验成事实而不是断言。
      if (cov_vill_ill == 0 || cov_eew_ill == 0 ||
          cov_emul_ill == 0 || cov_regnum_ill == 0 || cov_overlap_ill == 0 ||
          cov_vstart_ill == 0) begin
        $display("COVERAGE INSUFFICIENT: 有非法分支一次都没触发");
        errors++;
      end
      if (cov_hireg_wrap == 0) begin
        $display("COVERAGE INSUFFICIENT: 「vd 区间上界回绕」定向档一次都没打到");
        errors++;
      end
      if (cov_inst_ill != 0) begin
        $display("UNEXPECTED: instIllegal 竟然触发了 %0d 次 —— 上面那段「结构不可达」"
                 , cov_inst_ill);
        $display("            的论证已被推翻，必须重新核对 BitPat 与 golden。");
        errors++;
      end
    end

    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end

endmodule
