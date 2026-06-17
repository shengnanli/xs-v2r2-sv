// ============================================================================
// decodeunit_derived.svh —— DecodeUnit 派生字段逻辑（机器生成，勿手改）
// 由 scripts/gen_decodeunit.py 从 golden DecodeUnit.sv 抽取目标字段表达式的
// 引用闭包后，机械改名生成（GEN 切片->gen_n，单点编码比较->match_n，io 输入->核内信号）。
// 覆盖：exceptionVec 非法/虚拟指令、vpu 明细(isReverse/isExt/isNarrow/...)、
//       wfflags、isMove、isVset、commitType。
// 边界：fuType/fuOpType/uopSplitType/selImm 用核内 fu_ov/op_ov/uop_split/sel_ov；
//       浮点 rm 用 fp_rm；vtype/vstart/CSR 用核内同名信号。
// 本文件在 xs_DecodeUnit_core 模块体内 `include，引用其 instr/fu_ov/... 局部信号。
// ============================================================================

  // ---- 中间信号（按拓扑序输出：被引用者先于引用者，定义先于使用） ----
  //   gen_n   = golden GEN 切片（指令位拼接或派生布尔）
  //   match_n = golden 单点编码比较项
  //   dw_*    = golden 其它命名中间 wire
  wire [16:0] gen_0 = {instr[31:25], instr[14:12], instr[6:0]};
  wire [15:0] gen_1 = {instr[31:26], instr[14:12], instr[6:0]};
  wire [13:0] gen_10 = {instr[31:25], instr[6:0]};
  wire [8:0] gen_11 = {instr[26:25], instr[6:0]};
  wire [16:0] gen_14 = {instr[31], instr[29:28], instr[25:22], instr[14:12], instr[6:0]};
  wire [13:0] gen_15 = {instr[31], instr[29:28], instr[25], instr[14:12], instr[6:0]};
  wire dw_isCsr = instr[6:2] == 5'h1C & (|(instr[13:12]));
  wire dw_isCsrr = dw_isCsr & instr[13] & instr[19:15] == 5'h0;
  wire dw_isCsrrVl = dw_isCsrr & instr[31:20] == 12'hC20;
  wire dw_isCsrrVlenb = dw_isCsrr & instr[31:20] == 12'hC22;
  wire gen_168 = dw_isCsrrVl | dw_isCsrrVlenb;
  wire [21:0] gen_5 = {instr[31:20], instr[14:12], instr[6:0]};
  wire [18:0] gen_6 = {instr[31:20], instr[6:0]};
  wire [26:0] gen_7 = {instr[31:20], instr[14:0]};
  wire [21:0] gen_8 = {instr[31:25], instr[19:12], instr[6:0]};
  wire [20:0] gen_9 = {instr[31:26], instr[19:12], instr[6:0]};
  wire dw_decodedInst_needFrm_scalaNeedFrm_n1 = gen_10 == 14'h53;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n11 = gen_10 == 14'h353;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n13 = gen_6 == 19'h60053;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n15 = gen_6 == 19'h600D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n17 = gen_6 == 19'h60153;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n19 = gen_6 == 19'h601D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n21 = gen_6 == 19'h61053;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n23 = gen_6 == 19'h610D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n25 = gen_6 == 19'h61153;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n27 = gen_6 == 19'h611D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n29 = gen_6 == 19'h200D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n3 = gen_10 == 14'h253;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n31 = gen_6 == 19'h21053;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n33 = gen_6 == 19'h62053;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n35 = gen_6 == 19'h620D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n37 = gen_6 == 19'h62153;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n39 = gen_6 == 19'h621D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n41 = gen_6 == 19'h20153;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n43 = gen_6 == 19'h22053;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n45 = gen_6 == 19'h220D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n47 = gen_6 == 19'h21153;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n49 = gen_6 == 19'h22253;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n5 = gen_10 == 14'hD3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n51 = gen_6 == 19'h20253;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n53 = gen_6 == 19'h21253;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n55 = gen_6 == 19'h222D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n57 = gen_6 == 19'h202D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n59 = gen_6 == 19'h212D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n7 = gen_10 == 14'h2D3;
  wire dw_decodedInst_needFrm_scalaNeedFrm_n9 = gen_10 == 14'h153;
  wire dw_decodedInst_needFrm_vectorNeedFrm_n1 = gen_1 == 16'h3AD7;
  wire dw_decodedInst_needFrm_vectorNeedFrm_n3 = gen_1 == 16'h3ED7;
  wire dw_exceptionII_n85 = op_raw == 9'h1;
  wire dw_exceptionII_n86 = op_raw == 9'h2;
  wire dw_exceptionII_n88 = op_raw == 9'h3;
  wire dw_exceptionVI_n14 = op_raw == 9'h14;
  wire dw_exceptionVI_n15 = op_raw == 9'h13;
  wire dw_exceptionVI_n3 = op_raw == 9'h11;
  wire dw_exceptionVI_n73 = gen_7 == 27'hA00F | gen_7 == 27'h1200F;
  wire dw_exceptionVI_n8 = op_raw == 9'h0;
  wire dw_isFof_T = op_raw == 9'h90;
  wire dw_uopInfoGen_io_in_preInfo_isVlsm_T = op_raw == 9'h8B;
  wire dw_decodedInst_wfflags = gen_10 == 14'h53 | gen_10 == 14'h253 | gen_10 == 14'hD3 | gen_10 == 14'h2D3 | gen_10 == 14'h153 | gen_10 == 14'h353 | gen_0 == 17'h14153 | gen_0 == 17'h140D3 | gen_0 == 17'h14053 | gen_0 == 17'h14553 | gen_0 == 17'h144D3 | gen_0 == 17'h14453 | gen_0 == 17'h14953 | gen_0 == 17'h148D3 | gen_0 == 17'h14853 | gen_0 == 17'h5053 | gen_0 == 17'h50D3 | gen_0 == 17'h5453 | gen_0 == 17'h54D3 | gen_0 == 17'h5853 | gen_0 == 17'h58D3 | gen_10 == 14'h453 | gen_10 == 14'h4D3 | gen_10 == 14'h553 | gen_10 == 14'h653 | gen_10 == 14'h6D3 | gen_6 == 19'h2C053 | gen_6 == 19'h2D053 | gen_10 == 14'h753 | gen_6 == 19'h2E053 | gen_11 == 9'h43 | gen_11 == 9'h47 | gen_11 == 9'h4F | gen_11 == 9'h4B | gen_11 == 9'hC3 | gen_11 == 9'hC7 | gen_11 == 9'hCF | gen_11 == 9'hCB | gen_11 == 9'h143 | gen_11 == 9'h147 | gen_11 == 9'h14F | gen_11 == 9'h14B | gen_0 == 17'h4053 | gen_0 == 17'h40D3 | gen_0 == 17'h4153 | gen_0 == 17'h4853 | gen_0 == 17'h48D3 | gen_0 == 17'h4953 | gen_1 == 16'hD7 | gen_1 == 16'h8D7 | gen_1 == 16'hC0D7 | gen_1 == 16'hC8D7 | gen_1 == 16'hD0D7 | gen_1 == 16'hD8D7 | gen_1 == 16'h90D7 | gen_1 == 16'h80D7 | gen_1 == 16'hE0D7 | gen_1 == 16'hB0D7 | gen_1 == 16'hB4D7 | gen_1 == 16'hB8D7 | gen_1 == 16'hBCD7 | gen_1 == 16'hA0D7 | gen_1 == 16'hA4D7 | gen_1 == 16'hA8D7 | gen_1 == 16'hACD7 | gen_1 == 16'hF0D7 | gen_1 == 16'hF4D7 | gen_1 == 16'hF8D7 | gen_1 == 16'hFCD7 | gen_9 == 21'h980D7 | gen_1 == 16'h10D7 | gen_1 == 16'h18D7 | gen_1 == 16'h60D7 | gen_1 == 16'h70D7 | gen_1 == 16'h6CD7 | gen_1 == 16'h64D7 | gen_1 == 16'h20D7 | gen_1 == 16'h24D7 | gen_1 == 16'h28D7 | gen_1 == 16'h2D7 | gen_1 == 16'hAD7 | gen_1 == 16'h9ED7 | gen_1 == 16'hC2D7 | gen_1 == 16'hCAD7 | gen_1 == 16'hD2D7 | gen_1 == 16'hDAD7 | gen_1 == 16'h92D7 | gen_1 == 16'h82D7 | gen_1 == 16'h86D7 | gen_1 == 16'hE2D7 | gen_1 == 16'hB2D7 | gen_1 == 16'hB6D7 | gen_1 == 16'hBAD7 | gen_1 == 16'hBED7 | gen_1 == 16'hA2D7 | gen_1 == 16'hA6D7 | gen_1 == 16'hAAD7 | gen_1 == 16'hAED7 | gen_1 == 16'hF2D7 | gen_1 == 16'hF6D7 | gen_1 == 16'hFAD7 | gen_1 == 16'hFED7 | gen_1 == 16'h12D7 | gen_1 == 16'h1AD7 | gen_1 == 16'h62D7 | gen_1 == 16'h72D7 | gen_1 == 16'h6ED7 | gen_1 == 16'h66D7 | gen_1 == 16'h76D7 | gen_1 == 16'h7ED7 | gen_1 == 16'h22D7 | gen_1 == 16'h26D7 | gen_1 == 16'h2AD7 | gen_1 == 16'hCD7 | gen_1 == 16'h4D7 | gen_1 == 16'h1CD7 | gen_1 == 16'h14D7 | gen_1 == 16'hCCD7 | gen_1 == 16'hC4D7 | gen_6 == 19'h68053 | gen_6 == 19'h680D3 | gen_6 == 19'h68153 | gen_6 == 19'h681D3 | gen_6 == 19'h60053 | gen_6 == 19'h600D3 | gen_6 == 19'h60153 | gen_6 == 19'h601D3 | gen_6 == 19'h69053 | gen_6 == 19'h690D3 | gen_6 == 19'h69153 | gen_6 == 19'h691D3 | gen_6 == 19'h61053 | gen_6 == 19'h610D3 | gen_6 == 19'h61153 | gen_6 == 19'h611D3 | gen_6 == 19'h200D3 | gen_6 == 19'h21053 | gen_6 == 19'h20153 | gen_6 == 19'h22053 | gen_6 == 19'h220D3 | gen_6 == 19'h21153 | gen_6 == 19'h6A053 | gen_6 == 19'h6A0D3 | gen_6 == 19'h6A153 | gen_6 == 19'h6A1D3 | gen_6 == 19'h62053 | gen_6 == 19'h620D3 | gen_6 == 19'h62153 | gen_6 == 19'h621D3 | gen_9 == 21'h900D7 | gen_9 == 21'h904D7 | gen_9 == 21'h918D7 | gen_9 == 21'h91CD7 | gen_9 == 21'h908D7 | gen_9 == 21'h90CD7 | gen_9 == 21'h920D7 | gen_9 == 21'h924D7 | gen_9 == 21'h938D7 | gen_9 == 21'h93CD7 | gen_9 == 21'h928D7 | gen_9 == 21'h92CD7 | gen_9 == 21'h930D7 | gen_9 == 21'h940D7 | gen_9 == 21'h944D7 | gen_9 == 21'h958D7 | gen_9 == 21'h95CD7 | gen_9 == 21'h948D7 | gen_9 == 21'h94CD7 | gen_9 == 21'h950D7 | gen_9 == 21'h954D7 | gen_9 == 21'h990D7 | gen_9 == 21'h994D7 | gen_0 == 17'h14A53 | gen_0 == 17'h14253 | gen_0 == 17'h14653 | gen_0 == 17'h14AD3 | gen_0 == 17'h142D3 | gen_0 == 17'h146D3 | gen_0 == 17'h5953 | gen_0 == 17'h5153 | gen_0 == 17'h5553 | gen_0 == 17'h59D3 | gen_0 == 17'h51D3 | gen_0 == 17'h55D3 | gen_6 == 19'h22253 | gen_6 == 19'h20253 | gen_6 == 19'h21253 | gen_6 == 19'h222D3 | gen_6 == 19'h202D3 | gen_6 == 19'h212D3 | gen_5 == 22'h30A0D3;
  wire dw_isCboInval = gen_7 == 27'h200F;
  wire dw_isCboZero = gen_7 == 27'h2200F;
  wire dw_isDstMask = gen_0 == 17'h8C57 | gen_0 == 17'h8E57 | gen_0 == 17'h8DD7 | gen_0 == 17'h8857 | gen_0 == 17'h8A57 | gen_0 == 17'h89D7 | gen_0 == 17'h9C57 | gen_0 == 17'h9E57 | gen_0 == 17'h9857 | gen_0 == 17'h9A57 | gen_0 == 17'hCD57 | gen_0 == 17'hED57 | gen_0 == 17'hC557 | gen_0 == 17'hDD57 | gen_0 == 17'hD557 | gen_0 == 17'hF557 | gen_0 == 17'hE557 | gen_0 == 17'hFD57 | gen_1 == 16'h6057 | gen_1 == 16'h6257 | gen_1 == 16'h61D7 | gen_1 == 16'h6457 | gen_1 == 16'h6657 | gen_1 == 16'h65D7 | gen_1 == 16'h7457 | gen_1 == 16'h7657 | gen_1 == 16'h75D7 | gen_1 == 16'h7057 | gen_1 == 16'h7257 | gen_1 == 16'h71D7 | gen_1 == 16'h6C57 | gen_1 == 16'h6E57 | gen_1 == 16'h6857 | gen_1 == 16'h6A57 | gen_1 == 16'h7E57 | gen_1 == 16'h7DD7 | gen_1 == 16'h7A57 | gen_1 == 16'h79D7 | gen_1 == 16'h60D7 | gen_1 == 16'h62D7 | gen_1 == 16'h70D7 | gen_1 == 16'h72D7 | gen_1 == 16'h6CD7 | gen_1 == 16'h6ED7 | gen_1 == 16'h64D7 | gen_1 == 16'h66D7 | gen_1 == 16'h76D7 | gen_1 == 16'h7ED7;
  wire dw_isVload = fu_mid[31] | fu_mid[33];
  wire dw_isFof = dw_isVload & dw_isFof_T;
  wire dw_isNarrow = gen_1 == 16'hB457 | gen_1 == 16'hB657 | gen_1 == 16'hB5D7 | gen_1 == 16'hB057 | gen_1 == 16'hB257 | gen_1 == 16'hB1D7 | gen_1 == 16'hBC57 | gen_1 == 16'hBE57 | gen_1 == 16'hBDD7 | gen_1 == 16'hB857 | gen_1 == 16'hBA57 | gen_1 == 16'hB9D7;
  wire dw_isOpMask = gen_0 == 17'hCD57 | gen_0 == 17'hED57 | gen_0 == 17'hC557 | gen_0 == 17'hDD57 | gen_0 == 17'hD557 | gen_0 == 17'hF557 | gen_0 == 17'hE557 | gen_0 == 17'hFD57;
  wire dw_isVStore = fu_mid[32] | fu_mid[34];
  wire dw_isVls = instr[6:2] == 5'h9 & (~(|(instr[14:12])) | instr[14]) | instr[6:2] == 5'h1 & (~(|(instr[14:12])) | instr[14]);
  wire dw_isZimop = gen_14 == 17'h11E73 | gen_15 == 14'h2673;

  // ---- 目标派生字段 ----
  // 向量逆序操作（vrsub/vrgather 等）
  wire d_isReverse = gen_1 == 16'hDD7 | gen_1 == 16'hE57 | gen_1 == 16'h86D7 | gen_1 == 16'h9ED7 | gen_8 == 22'h1080D7;
  // 向量整数扩展（vzext/vsext）
  wire d_isExt = gen_9 == 21'h91957 | gen_9 == 21'h91157 | gen_9 == 21'h90957 | gen_9 == 21'h91D57 | gen_9 == 21'h91557 | gen_9 == 21'h90D57;
  // 向量窄化（vnsrl/vnclip 等）
  wire d_isNarrow = dw_isNarrow;
  // 目的为掩码寄存器
  wire d_isDstMask = dw_isDstMask;
  // 掩码逻辑操作（vmand 等）
  wire d_isOpMask = dw_isOpMask;
  // 需要读旧 vd（尾/掩码保留）
  wire d_isDependOldVd = fu_mid[20] | fu_mid[23] | fu_mid[24] | fu_mid[25] | fu_mid[26] | fu_mid[27] | dw_isVStore | dw_isDstMask & ~dw_isOpMask | dw_isNarrow | dw_isVload & (op_raw == 9'hE0 | op_raw == 9'hA0) | gen_1 == 16'hB557 | gen_1 == 16'hB757 | gen_1 == 16'hBD57 | gen_1 == 16'hBF57 | gen_1 == 16'hA557 | gen_1 == 16'hA757 | gen_1 == 16'hAD57 | gen_1 == 16'hAF57 | gen_1 == 16'hF157 | gen_1 == 16'hF357 | gen_1 == 16'hF557 | gen_1 == 16'hF757 | gen_1 == 16'hFD57 | gen_1 == 16'hFF57 | gen_1 == 16'hFB57 | dw_isFof | (|vstart);
  // 只写部分 vd
  wire d_isWritePartVd = uop_split == 6'h24 | uop_split == 6'h14 | uop_split == 6'h2C | dw_isVload & dw_uopInfoGen_io_in_preInfo_isVlsm_T | dw_isVload & (op_raw == 9'h80 | dw_isFof_T | op_raw == 9'hC0) & 4'({1'h0, ~(vtype.vlmul[2]), vtype.vlmul[1:0]} + {2'h0, instr[13:12]}) < 4'({2'h0, vtype.vsew} + 4'h4);
  // vleff（fault-only-first 加载）
  wire d_isVleff = dw_isFof & ~(|(instr[31:29]));
  // 向量访存指令
  wire d_vlsInstr = dw_isVls;
  // 写 fflags（浮点/向量浮点）
  wire d_wfflags = dw_decodedInst_wfflags;
  // 可消除的寄存器搬运 (mv/zimop)
  wire d_isMove = (gen_5 == 22'h13 | dw_isZimop) & (|(instr[11:7])) & ~csr_singlestep;
  // vset{i}vl{i} 指令
  wire d_isVset = fu_mid[28] | fu_mid[29] | fu_mid[30];
  // 提交类型 (load/store/branch)
  wire [2:0] d_commitType = {1'h0, fu_mid[15] | fu_mid[16] | dw_isVls, fu_mid[16] & ~(fu_mid[17]) | dw_isVStore | (|predecode_brType) | fu_mid[0]};
  // 非法指令异常 (illegalInstr)
  wire d_excVec2 = gen_168 ? csr_illegal.vsIsOff : sel_ov == 4'h6 | csr_illegal.sfenceVMA & fu_mid[9] & dw_exceptionVI_n3 | csr_illegal.sfencePart & fu_mid[9] & dw_exceptionVI_n8 | csr_illegal.hfenceGVMA & fu_mid[9] & dw_exceptionVI_n14 | csr_illegal.hfenceVVMA & fu_mid[9] & dw_exceptionVI_n15 | csr_illegal.hlsv & fu_mid[15] & (op_raw[4] & ~(op_raw[5]) & ~(|(op_raw[8:7])) | op_raw[4] & op_raw[3] & ~(op_raw[5]) & ~(|(op_raw[8:7]))) | csr_illegal.hlsv & fu_mid[16] & op_raw[4] & ~(op_raw[5]) & ~(|(op_raw[8:7])) | csr_illegal.fsIsOff & (fu_mid[11] | fu_mid[13] | fu_mid[12] | fu_mid[14] | fu_mid[4] | fu_mid[2] | fu_mid[3] | (fu_mid[15] & (dw_exceptionII_n85 | dw_exceptionII_n86 | dw_exceptionII_n88) | fu_mid[16] & (dw_exceptionII_n85 | dw_exceptionII_n86 | dw_exceptionII_n88)) & instr[2] | instr[6:0] == 7'h57 & instr[14:12] == 3'h5 | instr[6:0] == 7'h57 & instr[14:12] == 3'h1) | csr_illegal.vsIsOff & (fu_mid[28] | fu_mid[29] | fu_mid[30] | fu_mid[18] | fu_mid[19] | fu_mid[20] | fu_mid[21] | fu_mid[22] | fu_mid[23] | fu_mid[24] | fu_mid[25] | fu_mid[26] | fu_mid[27] | fu_mid[31] | fu_mid[32] | fu_mid[33] | fu_mid[34]) | csr_illegal.wfi & fu_mid[5] & op_raw[5] & ~(op_raw[1]) | csr_illegal.wrs_nto & fu_mid[5] & op_raw[5] & op_raw[1:0] == 2'h2 | (dw_decodedInst_needFrm_scalaNeedFrm_n1 | dw_decodedInst_needFrm_scalaNeedFrm_n3 | dw_decodedInst_needFrm_scalaNeedFrm_n5 | dw_decodedInst_needFrm_scalaNeedFrm_n7 | dw_decodedInst_needFrm_scalaNeedFrm_n9 | dw_decodedInst_needFrm_scalaNeedFrm_n11 | dw_decodedInst_needFrm_scalaNeedFrm_n13 | dw_decodedInst_needFrm_scalaNeedFrm_n15 | dw_decodedInst_needFrm_scalaNeedFrm_n17 | dw_decodedInst_needFrm_scalaNeedFrm_n19 | dw_decodedInst_needFrm_scalaNeedFrm_n21 | dw_decodedInst_needFrm_scalaNeedFrm_n23 | dw_decodedInst_needFrm_scalaNeedFrm_n25 | dw_decodedInst_needFrm_scalaNeedFrm_n27 | dw_decodedInst_needFrm_scalaNeedFrm_n29 | dw_decodedInst_needFrm_scalaNeedFrm_n31 | dw_decodedInst_needFrm_scalaNeedFrm_n33 | dw_decodedInst_needFrm_scalaNeedFrm_n35 | dw_decodedInst_needFrm_scalaNeedFrm_n37 | dw_decodedInst_needFrm_scalaNeedFrm_n39 | dw_decodedInst_needFrm_scalaNeedFrm_n41 | dw_decodedInst_needFrm_scalaNeedFrm_n43 | dw_decodedInst_needFrm_scalaNeedFrm_n45 | dw_decodedInst_needFrm_scalaNeedFrm_n47 | dw_decodedInst_needFrm_scalaNeedFrm_n49 | dw_decodedInst_needFrm_scalaNeedFrm_n51 | dw_decodedInst_needFrm_scalaNeedFrm_n53 | dw_decodedInst_needFrm_scalaNeedFrm_n55 | dw_decodedInst_needFrm_scalaNeedFrm_n57 | dw_decodedInst_needFrm_scalaNeedFrm_n59 | fu_mid[2] | fu_mid[12] | fu_mid[14]) & (fp_rm == 3'h5 | fp_rm == 3'h6 | (&fp_rm) & csr_illegal.frm) | (dw_decodedInst_needFrm_vectorNeedFrm_n1 | dw_decodedInst_needFrm_vectorNeedFrm_n3 | fu_mid[24] | fu_mid[25] | fu_mid[26] | fu_mid[27]) & csr_illegal.frm | csr_illegal.cboZ & dw_isCboZero | csr_illegal.cboCF & dw_exceptionVI_n73 | csr_illegal.cboI & dw_isCboInval | fu_mid[10] & op_raw == 9'h25 & instr[23:20] > 4'hA | fu_mid[17] & op_raw == 9'h2C & (instr[7] | instr[20]) | in_excVec2;
  // 虚拟指令异常 (virtualInstr)
  wire d_excVec22 = csr_virtual.sfenceVMA & fu_mid[9] & dw_exceptionVI_n3 | csr_virtual.sfencePart & fu_mid[9] & dw_exceptionVI_n8 | csr_virtual.hfence & fu_mid[9] & (dw_exceptionVI_n14 | dw_exceptionVI_n15) | csr_virtual.hlsv & fu_mid[15] & (op_raw[4] & ~(op_raw[5]) & ~(|(op_raw[8:7])) | op_raw[4] & op_raw[3] & ~(op_raw[5]) & ~(|(op_raw[8:7]))) | csr_virtual.hlsv & fu_mid[16] & op_raw[4] & ~(op_raw[5]) & ~(|(op_raw[8:7])) | csr_virtual.wfi & fu_mid[5] & op_raw[5] & ~(op_raw[1]) | csr_virtual.wrs_nto & fu_mid[5] & op_raw[5] & op_raw[1:0] == 2'h2 | csr_virtual.cboZ & dw_isCboZero | csr_virtual.cboCF & dw_exceptionVI_n73 | csr_virtual.cboI & dw_isCboInval;

