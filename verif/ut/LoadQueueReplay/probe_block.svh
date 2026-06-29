  // ===========================================================================
  //  FM 失败点假阳性证伪探针：逐拍比对 golden 内部寄存器 vs 可读核内部数组。
  //  FM 报失败点 cause_reg[0]/cause_reg[54]/blockSqIdx_reg[66] 是 struct 数组 vs
  //  golden 逐字段标量配对不收敛的误报。这里用层次引用直接比对真实状态：比对全
  //  72 entry 的 cause 与 blockSqIdx（覆盖面远超 FM 报的 3 点）。golden 这些是
  //  scalar reg（cause_<i> / blockSqIdx_<i>_{flag,value}），无法用变量索引，故逐
  //  entry 显式展开。X 不参与比对（!$isunknown 选通 golden）。
  // ===========================================================================
  int probe_checks = 0, probe_mismatch = 0;
  int pwarm = 6;
  always @(posedge clk) if (!rst && pwarm > 0) pwarm--;
  always @(posedge clk) if (!rst && pwarm == 0) begin
    probe_checks++;
    if (!$isunknown(tb.u_g.cause_0) && tb.u_g.cause_0 !== tb.u_i.u_core.cause[0]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[0] g=%h i=%h", $time, tb.u_g.cause_0, tb.u_i.u_core.cause[0]); end
    if (!$isunknown(tb.u_g.blockSqIdx_0_flag) && tb.u_g.blockSqIdx_0_flag !== tb.u_i.u_core.blockSqIdx[0].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[0] g=%b i=%b", $time, tb.u_g.blockSqIdx_0_flag, tb.u_i.u_core.blockSqIdx[0].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_0_value) && tb.u_g.blockSqIdx_0_value !== tb.u_i.u_core.blockSqIdx[0].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[0] g=%h i=%h", $time, tb.u_g.blockSqIdx_0_value, tb.u_i.u_core.blockSqIdx[0].value); end
    if (!$isunknown(tb.u_g.cause_1) && tb.u_g.cause_1 !== tb.u_i.u_core.cause[1]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[1] g=%h i=%h", $time, tb.u_g.cause_1, tb.u_i.u_core.cause[1]); end
    if (!$isunknown(tb.u_g.blockSqIdx_1_flag) && tb.u_g.blockSqIdx_1_flag !== tb.u_i.u_core.blockSqIdx[1].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[1] g=%b i=%b", $time, tb.u_g.blockSqIdx_1_flag, tb.u_i.u_core.blockSqIdx[1].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_1_value) && tb.u_g.blockSqIdx_1_value !== tb.u_i.u_core.blockSqIdx[1].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[1] g=%h i=%h", $time, tb.u_g.blockSqIdx_1_value, tb.u_i.u_core.blockSqIdx[1].value); end
    if (!$isunknown(tb.u_g.cause_2) && tb.u_g.cause_2 !== tb.u_i.u_core.cause[2]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[2] g=%h i=%h", $time, tb.u_g.cause_2, tb.u_i.u_core.cause[2]); end
    if (!$isunknown(tb.u_g.blockSqIdx_2_flag) && tb.u_g.blockSqIdx_2_flag !== tb.u_i.u_core.blockSqIdx[2].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[2] g=%b i=%b", $time, tb.u_g.blockSqIdx_2_flag, tb.u_i.u_core.blockSqIdx[2].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_2_value) && tb.u_g.blockSqIdx_2_value !== tb.u_i.u_core.blockSqIdx[2].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[2] g=%h i=%h", $time, tb.u_g.blockSqIdx_2_value, tb.u_i.u_core.blockSqIdx[2].value); end
    if (!$isunknown(tb.u_g.cause_3) && tb.u_g.cause_3 !== tb.u_i.u_core.cause[3]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[3] g=%h i=%h", $time, tb.u_g.cause_3, tb.u_i.u_core.cause[3]); end
    if (!$isunknown(tb.u_g.blockSqIdx_3_flag) && tb.u_g.blockSqIdx_3_flag !== tb.u_i.u_core.blockSqIdx[3].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[3] g=%b i=%b", $time, tb.u_g.blockSqIdx_3_flag, tb.u_i.u_core.blockSqIdx[3].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_3_value) && tb.u_g.blockSqIdx_3_value !== tb.u_i.u_core.blockSqIdx[3].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[3] g=%h i=%h", $time, tb.u_g.blockSqIdx_3_value, tb.u_i.u_core.blockSqIdx[3].value); end
    if (!$isunknown(tb.u_g.cause_4) && tb.u_g.cause_4 !== tb.u_i.u_core.cause[4]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[4] g=%h i=%h", $time, tb.u_g.cause_4, tb.u_i.u_core.cause[4]); end
    if (!$isunknown(tb.u_g.blockSqIdx_4_flag) && tb.u_g.blockSqIdx_4_flag !== tb.u_i.u_core.blockSqIdx[4].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[4] g=%b i=%b", $time, tb.u_g.blockSqIdx_4_flag, tb.u_i.u_core.blockSqIdx[4].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_4_value) && tb.u_g.blockSqIdx_4_value !== tb.u_i.u_core.blockSqIdx[4].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[4] g=%h i=%h", $time, tb.u_g.blockSqIdx_4_value, tb.u_i.u_core.blockSqIdx[4].value); end
    if (!$isunknown(tb.u_g.cause_5) && tb.u_g.cause_5 !== tb.u_i.u_core.cause[5]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[5] g=%h i=%h", $time, tb.u_g.cause_5, tb.u_i.u_core.cause[5]); end
    if (!$isunknown(tb.u_g.blockSqIdx_5_flag) && tb.u_g.blockSqIdx_5_flag !== tb.u_i.u_core.blockSqIdx[5].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[5] g=%b i=%b", $time, tb.u_g.blockSqIdx_5_flag, tb.u_i.u_core.blockSqIdx[5].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_5_value) && tb.u_g.blockSqIdx_5_value !== tb.u_i.u_core.blockSqIdx[5].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[5] g=%h i=%h", $time, tb.u_g.blockSqIdx_5_value, tb.u_i.u_core.blockSqIdx[5].value); end
    if (!$isunknown(tb.u_g.cause_6) && tb.u_g.cause_6 !== tb.u_i.u_core.cause[6]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[6] g=%h i=%h", $time, tb.u_g.cause_6, tb.u_i.u_core.cause[6]); end
    if (!$isunknown(tb.u_g.blockSqIdx_6_flag) && tb.u_g.blockSqIdx_6_flag !== tb.u_i.u_core.blockSqIdx[6].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[6] g=%b i=%b", $time, tb.u_g.blockSqIdx_6_flag, tb.u_i.u_core.blockSqIdx[6].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_6_value) && tb.u_g.blockSqIdx_6_value !== tb.u_i.u_core.blockSqIdx[6].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[6] g=%h i=%h", $time, tb.u_g.blockSqIdx_6_value, tb.u_i.u_core.blockSqIdx[6].value); end
    if (!$isunknown(tb.u_g.cause_7) && tb.u_g.cause_7 !== tb.u_i.u_core.cause[7]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[7] g=%h i=%h", $time, tb.u_g.cause_7, tb.u_i.u_core.cause[7]); end
    if (!$isunknown(tb.u_g.blockSqIdx_7_flag) && tb.u_g.blockSqIdx_7_flag !== tb.u_i.u_core.blockSqIdx[7].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[7] g=%b i=%b", $time, tb.u_g.blockSqIdx_7_flag, tb.u_i.u_core.blockSqIdx[7].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_7_value) && tb.u_g.blockSqIdx_7_value !== tb.u_i.u_core.blockSqIdx[7].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[7] g=%h i=%h", $time, tb.u_g.blockSqIdx_7_value, tb.u_i.u_core.blockSqIdx[7].value); end
    if (!$isunknown(tb.u_g.cause_8) && tb.u_g.cause_8 !== tb.u_i.u_core.cause[8]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[8] g=%h i=%h", $time, tb.u_g.cause_8, tb.u_i.u_core.cause[8]); end
    if (!$isunknown(tb.u_g.blockSqIdx_8_flag) && tb.u_g.blockSqIdx_8_flag !== tb.u_i.u_core.blockSqIdx[8].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[8] g=%b i=%b", $time, tb.u_g.blockSqIdx_8_flag, tb.u_i.u_core.blockSqIdx[8].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_8_value) && tb.u_g.blockSqIdx_8_value !== tb.u_i.u_core.blockSqIdx[8].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[8] g=%h i=%h", $time, tb.u_g.blockSqIdx_8_value, tb.u_i.u_core.blockSqIdx[8].value); end
    if (!$isunknown(tb.u_g.cause_9) && tb.u_g.cause_9 !== tb.u_i.u_core.cause[9]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[9] g=%h i=%h", $time, tb.u_g.cause_9, tb.u_i.u_core.cause[9]); end
    if (!$isunknown(tb.u_g.blockSqIdx_9_flag) && tb.u_g.blockSqIdx_9_flag !== tb.u_i.u_core.blockSqIdx[9].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[9] g=%b i=%b", $time, tb.u_g.blockSqIdx_9_flag, tb.u_i.u_core.blockSqIdx[9].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_9_value) && tb.u_g.blockSqIdx_9_value !== tb.u_i.u_core.blockSqIdx[9].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[9] g=%h i=%h", $time, tb.u_g.blockSqIdx_9_value, tb.u_i.u_core.blockSqIdx[9].value); end
    if (!$isunknown(tb.u_g.cause_10) && tb.u_g.cause_10 !== tb.u_i.u_core.cause[10]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[10] g=%h i=%h", $time, tb.u_g.cause_10, tb.u_i.u_core.cause[10]); end
    if (!$isunknown(tb.u_g.blockSqIdx_10_flag) && tb.u_g.blockSqIdx_10_flag !== tb.u_i.u_core.blockSqIdx[10].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[10] g=%b i=%b", $time, tb.u_g.blockSqIdx_10_flag, tb.u_i.u_core.blockSqIdx[10].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_10_value) && tb.u_g.blockSqIdx_10_value !== tb.u_i.u_core.blockSqIdx[10].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[10] g=%h i=%h", $time, tb.u_g.blockSqIdx_10_value, tb.u_i.u_core.blockSqIdx[10].value); end
    if (!$isunknown(tb.u_g.cause_11) && tb.u_g.cause_11 !== tb.u_i.u_core.cause[11]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[11] g=%h i=%h", $time, tb.u_g.cause_11, tb.u_i.u_core.cause[11]); end
    if (!$isunknown(tb.u_g.blockSqIdx_11_flag) && tb.u_g.blockSqIdx_11_flag !== tb.u_i.u_core.blockSqIdx[11].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[11] g=%b i=%b", $time, tb.u_g.blockSqIdx_11_flag, tb.u_i.u_core.blockSqIdx[11].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_11_value) && tb.u_g.blockSqIdx_11_value !== tb.u_i.u_core.blockSqIdx[11].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[11] g=%h i=%h", $time, tb.u_g.blockSqIdx_11_value, tb.u_i.u_core.blockSqIdx[11].value); end
    if (!$isunknown(tb.u_g.cause_12) && tb.u_g.cause_12 !== tb.u_i.u_core.cause[12]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[12] g=%h i=%h", $time, tb.u_g.cause_12, tb.u_i.u_core.cause[12]); end
    if (!$isunknown(tb.u_g.blockSqIdx_12_flag) && tb.u_g.blockSqIdx_12_flag !== tb.u_i.u_core.blockSqIdx[12].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[12] g=%b i=%b", $time, tb.u_g.blockSqIdx_12_flag, tb.u_i.u_core.blockSqIdx[12].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_12_value) && tb.u_g.blockSqIdx_12_value !== tb.u_i.u_core.blockSqIdx[12].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[12] g=%h i=%h", $time, tb.u_g.blockSqIdx_12_value, tb.u_i.u_core.blockSqIdx[12].value); end
    if (!$isunknown(tb.u_g.cause_13) && tb.u_g.cause_13 !== tb.u_i.u_core.cause[13]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[13] g=%h i=%h", $time, tb.u_g.cause_13, tb.u_i.u_core.cause[13]); end
    if (!$isunknown(tb.u_g.blockSqIdx_13_flag) && tb.u_g.blockSqIdx_13_flag !== tb.u_i.u_core.blockSqIdx[13].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[13] g=%b i=%b", $time, tb.u_g.blockSqIdx_13_flag, tb.u_i.u_core.blockSqIdx[13].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_13_value) && tb.u_g.blockSqIdx_13_value !== tb.u_i.u_core.blockSqIdx[13].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[13] g=%h i=%h", $time, tb.u_g.blockSqIdx_13_value, tb.u_i.u_core.blockSqIdx[13].value); end
    if (!$isunknown(tb.u_g.cause_14) && tb.u_g.cause_14 !== tb.u_i.u_core.cause[14]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[14] g=%h i=%h", $time, tb.u_g.cause_14, tb.u_i.u_core.cause[14]); end
    if (!$isunknown(tb.u_g.blockSqIdx_14_flag) && tb.u_g.blockSqIdx_14_flag !== tb.u_i.u_core.blockSqIdx[14].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[14] g=%b i=%b", $time, tb.u_g.blockSqIdx_14_flag, tb.u_i.u_core.blockSqIdx[14].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_14_value) && tb.u_g.blockSqIdx_14_value !== tb.u_i.u_core.blockSqIdx[14].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[14] g=%h i=%h", $time, tb.u_g.blockSqIdx_14_value, tb.u_i.u_core.blockSqIdx[14].value); end
    if (!$isunknown(tb.u_g.cause_15) && tb.u_g.cause_15 !== tb.u_i.u_core.cause[15]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[15] g=%h i=%h", $time, tb.u_g.cause_15, tb.u_i.u_core.cause[15]); end
    if (!$isunknown(tb.u_g.blockSqIdx_15_flag) && tb.u_g.blockSqIdx_15_flag !== tb.u_i.u_core.blockSqIdx[15].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[15] g=%b i=%b", $time, tb.u_g.blockSqIdx_15_flag, tb.u_i.u_core.blockSqIdx[15].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_15_value) && tb.u_g.blockSqIdx_15_value !== tb.u_i.u_core.blockSqIdx[15].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[15] g=%h i=%h", $time, tb.u_g.blockSqIdx_15_value, tb.u_i.u_core.blockSqIdx[15].value); end
    if (!$isunknown(tb.u_g.cause_16) && tb.u_g.cause_16 !== tb.u_i.u_core.cause[16]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[16] g=%h i=%h", $time, tb.u_g.cause_16, tb.u_i.u_core.cause[16]); end
    if (!$isunknown(tb.u_g.blockSqIdx_16_flag) && tb.u_g.blockSqIdx_16_flag !== tb.u_i.u_core.blockSqIdx[16].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[16] g=%b i=%b", $time, tb.u_g.blockSqIdx_16_flag, tb.u_i.u_core.blockSqIdx[16].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_16_value) && tb.u_g.blockSqIdx_16_value !== tb.u_i.u_core.blockSqIdx[16].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[16] g=%h i=%h", $time, tb.u_g.blockSqIdx_16_value, tb.u_i.u_core.blockSqIdx[16].value); end
    if (!$isunknown(tb.u_g.cause_17) && tb.u_g.cause_17 !== tb.u_i.u_core.cause[17]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[17] g=%h i=%h", $time, tb.u_g.cause_17, tb.u_i.u_core.cause[17]); end
    if (!$isunknown(tb.u_g.blockSqIdx_17_flag) && tb.u_g.blockSqIdx_17_flag !== tb.u_i.u_core.blockSqIdx[17].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[17] g=%b i=%b", $time, tb.u_g.blockSqIdx_17_flag, tb.u_i.u_core.blockSqIdx[17].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_17_value) && tb.u_g.blockSqIdx_17_value !== tb.u_i.u_core.blockSqIdx[17].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[17] g=%h i=%h", $time, tb.u_g.blockSqIdx_17_value, tb.u_i.u_core.blockSqIdx[17].value); end
    if (!$isunknown(tb.u_g.cause_18) && tb.u_g.cause_18 !== tb.u_i.u_core.cause[18]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[18] g=%h i=%h", $time, tb.u_g.cause_18, tb.u_i.u_core.cause[18]); end
    if (!$isunknown(tb.u_g.blockSqIdx_18_flag) && tb.u_g.blockSqIdx_18_flag !== tb.u_i.u_core.blockSqIdx[18].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[18] g=%b i=%b", $time, tb.u_g.blockSqIdx_18_flag, tb.u_i.u_core.blockSqIdx[18].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_18_value) && tb.u_g.blockSqIdx_18_value !== tb.u_i.u_core.blockSqIdx[18].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[18] g=%h i=%h", $time, tb.u_g.blockSqIdx_18_value, tb.u_i.u_core.blockSqIdx[18].value); end
    if (!$isunknown(tb.u_g.cause_19) && tb.u_g.cause_19 !== tb.u_i.u_core.cause[19]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[19] g=%h i=%h", $time, tb.u_g.cause_19, tb.u_i.u_core.cause[19]); end
    if (!$isunknown(tb.u_g.blockSqIdx_19_flag) && tb.u_g.blockSqIdx_19_flag !== tb.u_i.u_core.blockSqIdx[19].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[19] g=%b i=%b", $time, tb.u_g.blockSqIdx_19_flag, tb.u_i.u_core.blockSqIdx[19].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_19_value) && tb.u_g.blockSqIdx_19_value !== tb.u_i.u_core.blockSqIdx[19].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[19] g=%h i=%h", $time, tb.u_g.blockSqIdx_19_value, tb.u_i.u_core.blockSqIdx[19].value); end
    if (!$isunknown(tb.u_g.cause_20) && tb.u_g.cause_20 !== tb.u_i.u_core.cause[20]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[20] g=%h i=%h", $time, tb.u_g.cause_20, tb.u_i.u_core.cause[20]); end
    if (!$isunknown(tb.u_g.blockSqIdx_20_flag) && tb.u_g.blockSqIdx_20_flag !== tb.u_i.u_core.blockSqIdx[20].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[20] g=%b i=%b", $time, tb.u_g.blockSqIdx_20_flag, tb.u_i.u_core.blockSqIdx[20].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_20_value) && tb.u_g.blockSqIdx_20_value !== tb.u_i.u_core.blockSqIdx[20].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[20] g=%h i=%h", $time, tb.u_g.blockSqIdx_20_value, tb.u_i.u_core.blockSqIdx[20].value); end
    if (!$isunknown(tb.u_g.cause_21) && tb.u_g.cause_21 !== tb.u_i.u_core.cause[21]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[21] g=%h i=%h", $time, tb.u_g.cause_21, tb.u_i.u_core.cause[21]); end
    if (!$isunknown(tb.u_g.blockSqIdx_21_flag) && tb.u_g.blockSqIdx_21_flag !== tb.u_i.u_core.blockSqIdx[21].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[21] g=%b i=%b", $time, tb.u_g.blockSqIdx_21_flag, tb.u_i.u_core.blockSqIdx[21].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_21_value) && tb.u_g.blockSqIdx_21_value !== tb.u_i.u_core.blockSqIdx[21].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[21] g=%h i=%h", $time, tb.u_g.blockSqIdx_21_value, tb.u_i.u_core.blockSqIdx[21].value); end
    if (!$isunknown(tb.u_g.cause_22) && tb.u_g.cause_22 !== tb.u_i.u_core.cause[22]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[22] g=%h i=%h", $time, tb.u_g.cause_22, tb.u_i.u_core.cause[22]); end
    if (!$isunknown(tb.u_g.blockSqIdx_22_flag) && tb.u_g.blockSqIdx_22_flag !== tb.u_i.u_core.blockSqIdx[22].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[22] g=%b i=%b", $time, tb.u_g.blockSqIdx_22_flag, tb.u_i.u_core.blockSqIdx[22].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_22_value) && tb.u_g.blockSqIdx_22_value !== tb.u_i.u_core.blockSqIdx[22].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[22] g=%h i=%h", $time, tb.u_g.blockSqIdx_22_value, tb.u_i.u_core.blockSqIdx[22].value); end
    if (!$isunknown(tb.u_g.cause_23) && tb.u_g.cause_23 !== tb.u_i.u_core.cause[23]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[23] g=%h i=%h", $time, tb.u_g.cause_23, tb.u_i.u_core.cause[23]); end
    if (!$isunknown(tb.u_g.blockSqIdx_23_flag) && tb.u_g.blockSqIdx_23_flag !== tb.u_i.u_core.blockSqIdx[23].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[23] g=%b i=%b", $time, tb.u_g.blockSqIdx_23_flag, tb.u_i.u_core.blockSqIdx[23].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_23_value) && tb.u_g.blockSqIdx_23_value !== tb.u_i.u_core.blockSqIdx[23].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[23] g=%h i=%h", $time, tb.u_g.blockSqIdx_23_value, tb.u_i.u_core.blockSqIdx[23].value); end
    if (!$isunknown(tb.u_g.cause_24) && tb.u_g.cause_24 !== tb.u_i.u_core.cause[24]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[24] g=%h i=%h", $time, tb.u_g.cause_24, tb.u_i.u_core.cause[24]); end
    if (!$isunknown(tb.u_g.blockSqIdx_24_flag) && tb.u_g.blockSqIdx_24_flag !== tb.u_i.u_core.blockSqIdx[24].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[24] g=%b i=%b", $time, tb.u_g.blockSqIdx_24_flag, tb.u_i.u_core.blockSqIdx[24].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_24_value) && tb.u_g.blockSqIdx_24_value !== tb.u_i.u_core.blockSqIdx[24].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[24] g=%h i=%h", $time, tb.u_g.blockSqIdx_24_value, tb.u_i.u_core.blockSqIdx[24].value); end
    if (!$isunknown(tb.u_g.cause_25) && tb.u_g.cause_25 !== tb.u_i.u_core.cause[25]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[25] g=%h i=%h", $time, tb.u_g.cause_25, tb.u_i.u_core.cause[25]); end
    if (!$isunknown(tb.u_g.blockSqIdx_25_flag) && tb.u_g.blockSqIdx_25_flag !== tb.u_i.u_core.blockSqIdx[25].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[25] g=%b i=%b", $time, tb.u_g.blockSqIdx_25_flag, tb.u_i.u_core.blockSqIdx[25].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_25_value) && tb.u_g.blockSqIdx_25_value !== tb.u_i.u_core.blockSqIdx[25].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[25] g=%h i=%h", $time, tb.u_g.blockSqIdx_25_value, tb.u_i.u_core.blockSqIdx[25].value); end
    if (!$isunknown(tb.u_g.cause_26) && tb.u_g.cause_26 !== tb.u_i.u_core.cause[26]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[26] g=%h i=%h", $time, tb.u_g.cause_26, tb.u_i.u_core.cause[26]); end
    if (!$isunknown(tb.u_g.blockSqIdx_26_flag) && tb.u_g.blockSqIdx_26_flag !== tb.u_i.u_core.blockSqIdx[26].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[26] g=%b i=%b", $time, tb.u_g.blockSqIdx_26_flag, tb.u_i.u_core.blockSqIdx[26].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_26_value) && tb.u_g.blockSqIdx_26_value !== tb.u_i.u_core.blockSqIdx[26].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[26] g=%h i=%h", $time, tb.u_g.blockSqIdx_26_value, tb.u_i.u_core.blockSqIdx[26].value); end
    if (!$isunknown(tb.u_g.cause_27) && tb.u_g.cause_27 !== tb.u_i.u_core.cause[27]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[27] g=%h i=%h", $time, tb.u_g.cause_27, tb.u_i.u_core.cause[27]); end
    if (!$isunknown(tb.u_g.blockSqIdx_27_flag) && tb.u_g.blockSqIdx_27_flag !== tb.u_i.u_core.blockSqIdx[27].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[27] g=%b i=%b", $time, tb.u_g.blockSqIdx_27_flag, tb.u_i.u_core.blockSqIdx[27].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_27_value) && tb.u_g.blockSqIdx_27_value !== tb.u_i.u_core.blockSqIdx[27].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[27] g=%h i=%h", $time, tb.u_g.blockSqIdx_27_value, tb.u_i.u_core.blockSqIdx[27].value); end
    if (!$isunknown(tb.u_g.cause_28) && tb.u_g.cause_28 !== tb.u_i.u_core.cause[28]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[28] g=%h i=%h", $time, tb.u_g.cause_28, tb.u_i.u_core.cause[28]); end
    if (!$isunknown(tb.u_g.blockSqIdx_28_flag) && tb.u_g.blockSqIdx_28_flag !== tb.u_i.u_core.blockSqIdx[28].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[28] g=%b i=%b", $time, tb.u_g.blockSqIdx_28_flag, tb.u_i.u_core.blockSqIdx[28].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_28_value) && tb.u_g.blockSqIdx_28_value !== tb.u_i.u_core.blockSqIdx[28].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[28] g=%h i=%h", $time, tb.u_g.blockSqIdx_28_value, tb.u_i.u_core.blockSqIdx[28].value); end
    if (!$isunknown(tb.u_g.cause_29) && tb.u_g.cause_29 !== tb.u_i.u_core.cause[29]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[29] g=%h i=%h", $time, tb.u_g.cause_29, tb.u_i.u_core.cause[29]); end
    if (!$isunknown(tb.u_g.blockSqIdx_29_flag) && tb.u_g.blockSqIdx_29_flag !== tb.u_i.u_core.blockSqIdx[29].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[29] g=%b i=%b", $time, tb.u_g.blockSqIdx_29_flag, tb.u_i.u_core.blockSqIdx[29].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_29_value) && tb.u_g.blockSqIdx_29_value !== tb.u_i.u_core.blockSqIdx[29].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[29] g=%h i=%h", $time, tb.u_g.blockSqIdx_29_value, tb.u_i.u_core.blockSqIdx[29].value); end
    if (!$isunknown(tb.u_g.cause_30) && tb.u_g.cause_30 !== tb.u_i.u_core.cause[30]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[30] g=%h i=%h", $time, tb.u_g.cause_30, tb.u_i.u_core.cause[30]); end
    if (!$isunknown(tb.u_g.blockSqIdx_30_flag) && tb.u_g.blockSqIdx_30_flag !== tb.u_i.u_core.blockSqIdx[30].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[30] g=%b i=%b", $time, tb.u_g.blockSqIdx_30_flag, tb.u_i.u_core.blockSqIdx[30].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_30_value) && tb.u_g.blockSqIdx_30_value !== tb.u_i.u_core.blockSqIdx[30].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[30] g=%h i=%h", $time, tb.u_g.blockSqIdx_30_value, tb.u_i.u_core.blockSqIdx[30].value); end
    if (!$isunknown(tb.u_g.cause_31) && tb.u_g.cause_31 !== tb.u_i.u_core.cause[31]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[31] g=%h i=%h", $time, tb.u_g.cause_31, tb.u_i.u_core.cause[31]); end
    if (!$isunknown(tb.u_g.blockSqIdx_31_flag) && tb.u_g.blockSqIdx_31_flag !== tb.u_i.u_core.blockSqIdx[31].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[31] g=%b i=%b", $time, tb.u_g.blockSqIdx_31_flag, tb.u_i.u_core.blockSqIdx[31].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_31_value) && tb.u_g.blockSqIdx_31_value !== tb.u_i.u_core.blockSqIdx[31].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[31] g=%h i=%h", $time, tb.u_g.blockSqIdx_31_value, tb.u_i.u_core.blockSqIdx[31].value); end
    if (!$isunknown(tb.u_g.cause_32) && tb.u_g.cause_32 !== tb.u_i.u_core.cause[32]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[32] g=%h i=%h", $time, tb.u_g.cause_32, tb.u_i.u_core.cause[32]); end
    if (!$isunknown(tb.u_g.blockSqIdx_32_flag) && tb.u_g.blockSqIdx_32_flag !== tb.u_i.u_core.blockSqIdx[32].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[32] g=%b i=%b", $time, tb.u_g.blockSqIdx_32_flag, tb.u_i.u_core.blockSqIdx[32].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_32_value) && tb.u_g.blockSqIdx_32_value !== tb.u_i.u_core.blockSqIdx[32].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[32] g=%h i=%h", $time, tb.u_g.blockSqIdx_32_value, tb.u_i.u_core.blockSqIdx[32].value); end
    if (!$isunknown(tb.u_g.cause_33) && tb.u_g.cause_33 !== tb.u_i.u_core.cause[33]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[33] g=%h i=%h", $time, tb.u_g.cause_33, tb.u_i.u_core.cause[33]); end
    if (!$isunknown(tb.u_g.blockSqIdx_33_flag) && tb.u_g.blockSqIdx_33_flag !== tb.u_i.u_core.blockSqIdx[33].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[33] g=%b i=%b", $time, tb.u_g.blockSqIdx_33_flag, tb.u_i.u_core.blockSqIdx[33].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_33_value) && tb.u_g.blockSqIdx_33_value !== tb.u_i.u_core.blockSqIdx[33].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[33] g=%h i=%h", $time, tb.u_g.blockSqIdx_33_value, tb.u_i.u_core.blockSqIdx[33].value); end
    if (!$isunknown(tb.u_g.cause_34) && tb.u_g.cause_34 !== tb.u_i.u_core.cause[34]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[34] g=%h i=%h", $time, tb.u_g.cause_34, tb.u_i.u_core.cause[34]); end
    if (!$isunknown(tb.u_g.blockSqIdx_34_flag) && tb.u_g.blockSqIdx_34_flag !== tb.u_i.u_core.blockSqIdx[34].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[34] g=%b i=%b", $time, tb.u_g.blockSqIdx_34_flag, tb.u_i.u_core.blockSqIdx[34].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_34_value) && tb.u_g.blockSqIdx_34_value !== tb.u_i.u_core.blockSqIdx[34].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[34] g=%h i=%h", $time, tb.u_g.blockSqIdx_34_value, tb.u_i.u_core.blockSqIdx[34].value); end
    if (!$isunknown(tb.u_g.cause_35) && tb.u_g.cause_35 !== tb.u_i.u_core.cause[35]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[35] g=%h i=%h", $time, tb.u_g.cause_35, tb.u_i.u_core.cause[35]); end
    if (!$isunknown(tb.u_g.blockSqIdx_35_flag) && tb.u_g.blockSqIdx_35_flag !== tb.u_i.u_core.blockSqIdx[35].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[35] g=%b i=%b", $time, tb.u_g.blockSqIdx_35_flag, tb.u_i.u_core.blockSqIdx[35].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_35_value) && tb.u_g.blockSqIdx_35_value !== tb.u_i.u_core.blockSqIdx[35].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[35] g=%h i=%h", $time, tb.u_g.blockSqIdx_35_value, tb.u_i.u_core.blockSqIdx[35].value); end
    if (!$isunknown(tb.u_g.cause_36) && tb.u_g.cause_36 !== tb.u_i.u_core.cause[36]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[36] g=%h i=%h", $time, tb.u_g.cause_36, tb.u_i.u_core.cause[36]); end
    if (!$isunknown(tb.u_g.blockSqIdx_36_flag) && tb.u_g.blockSqIdx_36_flag !== tb.u_i.u_core.blockSqIdx[36].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[36] g=%b i=%b", $time, tb.u_g.blockSqIdx_36_flag, tb.u_i.u_core.blockSqIdx[36].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_36_value) && tb.u_g.blockSqIdx_36_value !== tb.u_i.u_core.blockSqIdx[36].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[36] g=%h i=%h", $time, tb.u_g.blockSqIdx_36_value, tb.u_i.u_core.blockSqIdx[36].value); end
    if (!$isunknown(tb.u_g.cause_37) && tb.u_g.cause_37 !== tb.u_i.u_core.cause[37]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[37] g=%h i=%h", $time, tb.u_g.cause_37, tb.u_i.u_core.cause[37]); end
    if (!$isunknown(tb.u_g.blockSqIdx_37_flag) && tb.u_g.blockSqIdx_37_flag !== tb.u_i.u_core.blockSqIdx[37].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[37] g=%b i=%b", $time, tb.u_g.blockSqIdx_37_flag, tb.u_i.u_core.blockSqIdx[37].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_37_value) && tb.u_g.blockSqIdx_37_value !== tb.u_i.u_core.blockSqIdx[37].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[37] g=%h i=%h", $time, tb.u_g.blockSqIdx_37_value, tb.u_i.u_core.blockSqIdx[37].value); end
    if (!$isunknown(tb.u_g.cause_38) && tb.u_g.cause_38 !== tb.u_i.u_core.cause[38]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[38] g=%h i=%h", $time, tb.u_g.cause_38, tb.u_i.u_core.cause[38]); end
    if (!$isunknown(tb.u_g.blockSqIdx_38_flag) && tb.u_g.blockSqIdx_38_flag !== tb.u_i.u_core.blockSqIdx[38].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[38] g=%b i=%b", $time, tb.u_g.blockSqIdx_38_flag, tb.u_i.u_core.blockSqIdx[38].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_38_value) && tb.u_g.blockSqIdx_38_value !== tb.u_i.u_core.blockSqIdx[38].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[38] g=%h i=%h", $time, tb.u_g.blockSqIdx_38_value, tb.u_i.u_core.blockSqIdx[38].value); end
    if (!$isunknown(tb.u_g.cause_39) && tb.u_g.cause_39 !== tb.u_i.u_core.cause[39]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[39] g=%h i=%h", $time, tb.u_g.cause_39, tb.u_i.u_core.cause[39]); end
    if (!$isunknown(tb.u_g.blockSqIdx_39_flag) && tb.u_g.blockSqIdx_39_flag !== tb.u_i.u_core.blockSqIdx[39].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[39] g=%b i=%b", $time, tb.u_g.blockSqIdx_39_flag, tb.u_i.u_core.blockSqIdx[39].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_39_value) && tb.u_g.blockSqIdx_39_value !== tb.u_i.u_core.blockSqIdx[39].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[39] g=%h i=%h", $time, tb.u_g.blockSqIdx_39_value, tb.u_i.u_core.blockSqIdx[39].value); end
    if (!$isunknown(tb.u_g.cause_40) && tb.u_g.cause_40 !== tb.u_i.u_core.cause[40]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[40] g=%h i=%h", $time, tb.u_g.cause_40, tb.u_i.u_core.cause[40]); end
    if (!$isunknown(tb.u_g.blockSqIdx_40_flag) && tb.u_g.blockSqIdx_40_flag !== tb.u_i.u_core.blockSqIdx[40].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[40] g=%b i=%b", $time, tb.u_g.blockSqIdx_40_flag, tb.u_i.u_core.blockSqIdx[40].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_40_value) && tb.u_g.blockSqIdx_40_value !== tb.u_i.u_core.blockSqIdx[40].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[40] g=%h i=%h", $time, tb.u_g.blockSqIdx_40_value, tb.u_i.u_core.blockSqIdx[40].value); end
    if (!$isunknown(tb.u_g.cause_41) && tb.u_g.cause_41 !== tb.u_i.u_core.cause[41]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[41] g=%h i=%h", $time, tb.u_g.cause_41, tb.u_i.u_core.cause[41]); end
    if (!$isunknown(tb.u_g.blockSqIdx_41_flag) && tb.u_g.blockSqIdx_41_flag !== tb.u_i.u_core.blockSqIdx[41].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[41] g=%b i=%b", $time, tb.u_g.blockSqIdx_41_flag, tb.u_i.u_core.blockSqIdx[41].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_41_value) && tb.u_g.blockSqIdx_41_value !== tb.u_i.u_core.blockSqIdx[41].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[41] g=%h i=%h", $time, tb.u_g.blockSqIdx_41_value, tb.u_i.u_core.blockSqIdx[41].value); end
    if (!$isunknown(tb.u_g.cause_42) && tb.u_g.cause_42 !== tb.u_i.u_core.cause[42]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[42] g=%h i=%h", $time, tb.u_g.cause_42, tb.u_i.u_core.cause[42]); end
    if (!$isunknown(tb.u_g.blockSqIdx_42_flag) && tb.u_g.blockSqIdx_42_flag !== tb.u_i.u_core.blockSqIdx[42].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[42] g=%b i=%b", $time, tb.u_g.blockSqIdx_42_flag, tb.u_i.u_core.blockSqIdx[42].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_42_value) && tb.u_g.blockSqIdx_42_value !== tb.u_i.u_core.blockSqIdx[42].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[42] g=%h i=%h", $time, tb.u_g.blockSqIdx_42_value, tb.u_i.u_core.blockSqIdx[42].value); end
    if (!$isunknown(tb.u_g.cause_43) && tb.u_g.cause_43 !== tb.u_i.u_core.cause[43]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[43] g=%h i=%h", $time, tb.u_g.cause_43, tb.u_i.u_core.cause[43]); end
    if (!$isunknown(tb.u_g.blockSqIdx_43_flag) && tb.u_g.blockSqIdx_43_flag !== tb.u_i.u_core.blockSqIdx[43].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[43] g=%b i=%b", $time, tb.u_g.blockSqIdx_43_flag, tb.u_i.u_core.blockSqIdx[43].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_43_value) && tb.u_g.blockSqIdx_43_value !== tb.u_i.u_core.blockSqIdx[43].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[43] g=%h i=%h", $time, tb.u_g.blockSqIdx_43_value, tb.u_i.u_core.blockSqIdx[43].value); end
    if (!$isunknown(tb.u_g.cause_44) && tb.u_g.cause_44 !== tb.u_i.u_core.cause[44]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[44] g=%h i=%h", $time, tb.u_g.cause_44, tb.u_i.u_core.cause[44]); end
    if (!$isunknown(tb.u_g.blockSqIdx_44_flag) && tb.u_g.blockSqIdx_44_flag !== tb.u_i.u_core.blockSqIdx[44].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[44] g=%b i=%b", $time, tb.u_g.blockSqIdx_44_flag, tb.u_i.u_core.blockSqIdx[44].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_44_value) && tb.u_g.blockSqIdx_44_value !== tb.u_i.u_core.blockSqIdx[44].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[44] g=%h i=%h", $time, tb.u_g.blockSqIdx_44_value, tb.u_i.u_core.blockSqIdx[44].value); end
    if (!$isunknown(tb.u_g.cause_45) && tb.u_g.cause_45 !== tb.u_i.u_core.cause[45]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[45] g=%h i=%h", $time, tb.u_g.cause_45, tb.u_i.u_core.cause[45]); end
    if (!$isunknown(tb.u_g.blockSqIdx_45_flag) && tb.u_g.blockSqIdx_45_flag !== tb.u_i.u_core.blockSqIdx[45].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[45] g=%b i=%b", $time, tb.u_g.blockSqIdx_45_flag, tb.u_i.u_core.blockSqIdx[45].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_45_value) && tb.u_g.blockSqIdx_45_value !== tb.u_i.u_core.blockSqIdx[45].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[45] g=%h i=%h", $time, tb.u_g.blockSqIdx_45_value, tb.u_i.u_core.blockSqIdx[45].value); end
    if (!$isunknown(tb.u_g.cause_46) && tb.u_g.cause_46 !== tb.u_i.u_core.cause[46]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[46] g=%h i=%h", $time, tb.u_g.cause_46, tb.u_i.u_core.cause[46]); end
    if (!$isunknown(tb.u_g.blockSqIdx_46_flag) && tb.u_g.blockSqIdx_46_flag !== tb.u_i.u_core.blockSqIdx[46].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[46] g=%b i=%b", $time, tb.u_g.blockSqIdx_46_flag, tb.u_i.u_core.blockSqIdx[46].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_46_value) && tb.u_g.blockSqIdx_46_value !== tb.u_i.u_core.blockSqIdx[46].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[46] g=%h i=%h", $time, tb.u_g.blockSqIdx_46_value, tb.u_i.u_core.blockSqIdx[46].value); end
    if (!$isunknown(tb.u_g.cause_47) && tb.u_g.cause_47 !== tb.u_i.u_core.cause[47]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[47] g=%h i=%h", $time, tb.u_g.cause_47, tb.u_i.u_core.cause[47]); end
    if (!$isunknown(tb.u_g.blockSqIdx_47_flag) && tb.u_g.blockSqIdx_47_flag !== tb.u_i.u_core.blockSqIdx[47].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[47] g=%b i=%b", $time, tb.u_g.blockSqIdx_47_flag, tb.u_i.u_core.blockSqIdx[47].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_47_value) && tb.u_g.blockSqIdx_47_value !== tb.u_i.u_core.blockSqIdx[47].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[47] g=%h i=%h", $time, tb.u_g.blockSqIdx_47_value, tb.u_i.u_core.blockSqIdx[47].value); end
    if (!$isunknown(tb.u_g.cause_48) && tb.u_g.cause_48 !== tb.u_i.u_core.cause[48]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[48] g=%h i=%h", $time, tb.u_g.cause_48, tb.u_i.u_core.cause[48]); end
    if (!$isunknown(tb.u_g.blockSqIdx_48_flag) && tb.u_g.blockSqIdx_48_flag !== tb.u_i.u_core.blockSqIdx[48].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[48] g=%b i=%b", $time, tb.u_g.blockSqIdx_48_flag, tb.u_i.u_core.blockSqIdx[48].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_48_value) && tb.u_g.blockSqIdx_48_value !== tb.u_i.u_core.blockSqIdx[48].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[48] g=%h i=%h", $time, tb.u_g.blockSqIdx_48_value, tb.u_i.u_core.blockSqIdx[48].value); end
    if (!$isunknown(tb.u_g.cause_49) && tb.u_g.cause_49 !== tb.u_i.u_core.cause[49]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[49] g=%h i=%h", $time, tb.u_g.cause_49, tb.u_i.u_core.cause[49]); end
    if (!$isunknown(tb.u_g.blockSqIdx_49_flag) && tb.u_g.blockSqIdx_49_flag !== tb.u_i.u_core.blockSqIdx[49].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[49] g=%b i=%b", $time, tb.u_g.blockSqIdx_49_flag, tb.u_i.u_core.blockSqIdx[49].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_49_value) && tb.u_g.blockSqIdx_49_value !== tb.u_i.u_core.blockSqIdx[49].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[49] g=%h i=%h", $time, tb.u_g.blockSqIdx_49_value, tb.u_i.u_core.blockSqIdx[49].value); end
    if (!$isunknown(tb.u_g.cause_50) && tb.u_g.cause_50 !== tb.u_i.u_core.cause[50]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[50] g=%h i=%h", $time, tb.u_g.cause_50, tb.u_i.u_core.cause[50]); end
    if (!$isunknown(tb.u_g.blockSqIdx_50_flag) && tb.u_g.blockSqIdx_50_flag !== tb.u_i.u_core.blockSqIdx[50].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[50] g=%b i=%b", $time, tb.u_g.blockSqIdx_50_flag, tb.u_i.u_core.blockSqIdx[50].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_50_value) && tb.u_g.blockSqIdx_50_value !== tb.u_i.u_core.blockSqIdx[50].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[50] g=%h i=%h", $time, tb.u_g.blockSqIdx_50_value, tb.u_i.u_core.blockSqIdx[50].value); end
    if (!$isunknown(tb.u_g.cause_51) && tb.u_g.cause_51 !== tb.u_i.u_core.cause[51]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[51] g=%h i=%h", $time, tb.u_g.cause_51, tb.u_i.u_core.cause[51]); end
    if (!$isunknown(tb.u_g.blockSqIdx_51_flag) && tb.u_g.blockSqIdx_51_flag !== tb.u_i.u_core.blockSqIdx[51].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[51] g=%b i=%b", $time, tb.u_g.blockSqIdx_51_flag, tb.u_i.u_core.blockSqIdx[51].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_51_value) && tb.u_g.blockSqIdx_51_value !== tb.u_i.u_core.blockSqIdx[51].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[51] g=%h i=%h", $time, tb.u_g.blockSqIdx_51_value, tb.u_i.u_core.blockSqIdx[51].value); end
    if (!$isunknown(tb.u_g.cause_52) && tb.u_g.cause_52 !== tb.u_i.u_core.cause[52]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[52] g=%h i=%h", $time, tb.u_g.cause_52, tb.u_i.u_core.cause[52]); end
    if (!$isunknown(tb.u_g.blockSqIdx_52_flag) && tb.u_g.blockSqIdx_52_flag !== tb.u_i.u_core.blockSqIdx[52].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[52] g=%b i=%b", $time, tb.u_g.blockSqIdx_52_flag, tb.u_i.u_core.blockSqIdx[52].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_52_value) && tb.u_g.blockSqIdx_52_value !== tb.u_i.u_core.blockSqIdx[52].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[52] g=%h i=%h", $time, tb.u_g.blockSqIdx_52_value, tb.u_i.u_core.blockSqIdx[52].value); end
    if (!$isunknown(tb.u_g.cause_53) && tb.u_g.cause_53 !== tb.u_i.u_core.cause[53]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[53] g=%h i=%h", $time, tb.u_g.cause_53, tb.u_i.u_core.cause[53]); end
    if (!$isunknown(tb.u_g.blockSqIdx_53_flag) && tb.u_g.blockSqIdx_53_flag !== tb.u_i.u_core.blockSqIdx[53].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[53] g=%b i=%b", $time, tb.u_g.blockSqIdx_53_flag, tb.u_i.u_core.blockSqIdx[53].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_53_value) && tb.u_g.blockSqIdx_53_value !== tb.u_i.u_core.blockSqIdx[53].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[53] g=%h i=%h", $time, tb.u_g.blockSqIdx_53_value, tb.u_i.u_core.blockSqIdx[53].value); end
    if (!$isunknown(tb.u_g.cause_54) && tb.u_g.cause_54 !== tb.u_i.u_core.cause[54]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[54] g=%h i=%h", $time, tb.u_g.cause_54, tb.u_i.u_core.cause[54]); end
    if (!$isunknown(tb.u_g.blockSqIdx_54_flag) && tb.u_g.blockSqIdx_54_flag !== tb.u_i.u_core.blockSqIdx[54].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[54] g=%b i=%b", $time, tb.u_g.blockSqIdx_54_flag, tb.u_i.u_core.blockSqIdx[54].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_54_value) && tb.u_g.blockSqIdx_54_value !== tb.u_i.u_core.blockSqIdx[54].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[54] g=%h i=%h", $time, tb.u_g.blockSqIdx_54_value, tb.u_i.u_core.blockSqIdx[54].value); end
    if (!$isunknown(tb.u_g.cause_55) && tb.u_g.cause_55 !== tb.u_i.u_core.cause[55]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[55] g=%h i=%h", $time, tb.u_g.cause_55, tb.u_i.u_core.cause[55]); end
    if (!$isunknown(tb.u_g.blockSqIdx_55_flag) && tb.u_g.blockSqIdx_55_flag !== tb.u_i.u_core.blockSqIdx[55].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[55] g=%b i=%b", $time, tb.u_g.blockSqIdx_55_flag, tb.u_i.u_core.blockSqIdx[55].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_55_value) && tb.u_g.blockSqIdx_55_value !== tb.u_i.u_core.blockSqIdx[55].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[55] g=%h i=%h", $time, tb.u_g.blockSqIdx_55_value, tb.u_i.u_core.blockSqIdx[55].value); end
    if (!$isunknown(tb.u_g.cause_56) && tb.u_g.cause_56 !== tb.u_i.u_core.cause[56]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[56] g=%h i=%h", $time, tb.u_g.cause_56, tb.u_i.u_core.cause[56]); end
    if (!$isunknown(tb.u_g.blockSqIdx_56_flag) && tb.u_g.blockSqIdx_56_flag !== tb.u_i.u_core.blockSqIdx[56].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[56] g=%b i=%b", $time, tb.u_g.blockSqIdx_56_flag, tb.u_i.u_core.blockSqIdx[56].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_56_value) && tb.u_g.blockSqIdx_56_value !== tb.u_i.u_core.blockSqIdx[56].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[56] g=%h i=%h", $time, tb.u_g.blockSqIdx_56_value, tb.u_i.u_core.blockSqIdx[56].value); end
    if (!$isunknown(tb.u_g.cause_57) && tb.u_g.cause_57 !== tb.u_i.u_core.cause[57]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[57] g=%h i=%h", $time, tb.u_g.cause_57, tb.u_i.u_core.cause[57]); end
    if (!$isunknown(tb.u_g.blockSqIdx_57_flag) && tb.u_g.blockSqIdx_57_flag !== tb.u_i.u_core.blockSqIdx[57].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[57] g=%b i=%b", $time, tb.u_g.blockSqIdx_57_flag, tb.u_i.u_core.blockSqIdx[57].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_57_value) && tb.u_g.blockSqIdx_57_value !== tb.u_i.u_core.blockSqIdx[57].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[57] g=%h i=%h", $time, tb.u_g.blockSqIdx_57_value, tb.u_i.u_core.blockSqIdx[57].value); end
    if (!$isunknown(tb.u_g.cause_58) && tb.u_g.cause_58 !== tb.u_i.u_core.cause[58]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[58] g=%h i=%h", $time, tb.u_g.cause_58, tb.u_i.u_core.cause[58]); end
    if (!$isunknown(tb.u_g.blockSqIdx_58_flag) && tb.u_g.blockSqIdx_58_flag !== tb.u_i.u_core.blockSqIdx[58].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[58] g=%b i=%b", $time, tb.u_g.blockSqIdx_58_flag, tb.u_i.u_core.blockSqIdx[58].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_58_value) && tb.u_g.blockSqIdx_58_value !== tb.u_i.u_core.blockSqIdx[58].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[58] g=%h i=%h", $time, tb.u_g.blockSqIdx_58_value, tb.u_i.u_core.blockSqIdx[58].value); end
    if (!$isunknown(tb.u_g.cause_59) && tb.u_g.cause_59 !== tb.u_i.u_core.cause[59]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[59] g=%h i=%h", $time, tb.u_g.cause_59, tb.u_i.u_core.cause[59]); end
    if (!$isunknown(tb.u_g.blockSqIdx_59_flag) && tb.u_g.blockSqIdx_59_flag !== tb.u_i.u_core.blockSqIdx[59].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[59] g=%b i=%b", $time, tb.u_g.blockSqIdx_59_flag, tb.u_i.u_core.blockSqIdx[59].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_59_value) && tb.u_g.blockSqIdx_59_value !== tb.u_i.u_core.blockSqIdx[59].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[59] g=%h i=%h", $time, tb.u_g.blockSqIdx_59_value, tb.u_i.u_core.blockSqIdx[59].value); end
    if (!$isunknown(tb.u_g.cause_60) && tb.u_g.cause_60 !== tb.u_i.u_core.cause[60]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[60] g=%h i=%h", $time, tb.u_g.cause_60, tb.u_i.u_core.cause[60]); end
    if (!$isunknown(tb.u_g.blockSqIdx_60_flag) && tb.u_g.blockSqIdx_60_flag !== tb.u_i.u_core.blockSqIdx[60].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[60] g=%b i=%b", $time, tb.u_g.blockSqIdx_60_flag, tb.u_i.u_core.blockSqIdx[60].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_60_value) && tb.u_g.blockSqIdx_60_value !== tb.u_i.u_core.blockSqIdx[60].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[60] g=%h i=%h", $time, tb.u_g.blockSqIdx_60_value, tb.u_i.u_core.blockSqIdx[60].value); end
    if (!$isunknown(tb.u_g.cause_61) && tb.u_g.cause_61 !== tb.u_i.u_core.cause[61]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[61] g=%h i=%h", $time, tb.u_g.cause_61, tb.u_i.u_core.cause[61]); end
    if (!$isunknown(tb.u_g.blockSqIdx_61_flag) && tb.u_g.blockSqIdx_61_flag !== tb.u_i.u_core.blockSqIdx[61].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[61] g=%b i=%b", $time, tb.u_g.blockSqIdx_61_flag, tb.u_i.u_core.blockSqIdx[61].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_61_value) && tb.u_g.blockSqIdx_61_value !== tb.u_i.u_core.blockSqIdx[61].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[61] g=%h i=%h", $time, tb.u_g.blockSqIdx_61_value, tb.u_i.u_core.blockSqIdx[61].value); end
    if (!$isunknown(tb.u_g.cause_62) && tb.u_g.cause_62 !== tb.u_i.u_core.cause[62]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[62] g=%h i=%h", $time, tb.u_g.cause_62, tb.u_i.u_core.cause[62]); end
    if (!$isunknown(tb.u_g.blockSqIdx_62_flag) && tb.u_g.blockSqIdx_62_flag !== tb.u_i.u_core.blockSqIdx[62].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[62] g=%b i=%b", $time, tb.u_g.blockSqIdx_62_flag, tb.u_i.u_core.blockSqIdx[62].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_62_value) && tb.u_g.blockSqIdx_62_value !== tb.u_i.u_core.blockSqIdx[62].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[62] g=%h i=%h", $time, tb.u_g.blockSqIdx_62_value, tb.u_i.u_core.blockSqIdx[62].value); end
    if (!$isunknown(tb.u_g.cause_63) && tb.u_g.cause_63 !== tb.u_i.u_core.cause[63]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[63] g=%h i=%h", $time, tb.u_g.cause_63, tb.u_i.u_core.cause[63]); end
    if (!$isunknown(tb.u_g.blockSqIdx_63_flag) && tb.u_g.blockSqIdx_63_flag !== tb.u_i.u_core.blockSqIdx[63].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[63] g=%b i=%b", $time, tb.u_g.blockSqIdx_63_flag, tb.u_i.u_core.blockSqIdx[63].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_63_value) && tb.u_g.blockSqIdx_63_value !== tb.u_i.u_core.blockSqIdx[63].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[63] g=%h i=%h", $time, tb.u_g.blockSqIdx_63_value, tb.u_i.u_core.blockSqIdx[63].value); end
    if (!$isunknown(tb.u_g.cause_64) && tb.u_g.cause_64 !== tb.u_i.u_core.cause[64]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[64] g=%h i=%h", $time, tb.u_g.cause_64, tb.u_i.u_core.cause[64]); end
    if (!$isunknown(tb.u_g.blockSqIdx_64_flag) && tb.u_g.blockSqIdx_64_flag !== tb.u_i.u_core.blockSqIdx[64].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[64] g=%b i=%b", $time, tb.u_g.blockSqIdx_64_flag, tb.u_i.u_core.blockSqIdx[64].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_64_value) && tb.u_g.blockSqIdx_64_value !== tb.u_i.u_core.blockSqIdx[64].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[64] g=%h i=%h", $time, tb.u_g.blockSqIdx_64_value, tb.u_i.u_core.blockSqIdx[64].value); end
    if (!$isunknown(tb.u_g.cause_65) && tb.u_g.cause_65 !== tb.u_i.u_core.cause[65]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[65] g=%h i=%h", $time, tb.u_g.cause_65, tb.u_i.u_core.cause[65]); end
    if (!$isunknown(tb.u_g.blockSqIdx_65_flag) && tb.u_g.blockSqIdx_65_flag !== tb.u_i.u_core.blockSqIdx[65].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[65] g=%b i=%b", $time, tb.u_g.blockSqIdx_65_flag, tb.u_i.u_core.blockSqIdx[65].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_65_value) && tb.u_g.blockSqIdx_65_value !== tb.u_i.u_core.blockSqIdx[65].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[65] g=%h i=%h", $time, tb.u_g.blockSqIdx_65_value, tb.u_i.u_core.blockSqIdx[65].value); end
    if (!$isunknown(tb.u_g.cause_66) && tb.u_g.cause_66 !== tb.u_i.u_core.cause[66]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[66] g=%h i=%h", $time, tb.u_g.cause_66, tb.u_i.u_core.cause[66]); end
    if (!$isunknown(tb.u_g.blockSqIdx_66_flag) && tb.u_g.blockSqIdx_66_flag !== tb.u_i.u_core.blockSqIdx[66].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[66] g=%b i=%b", $time, tb.u_g.blockSqIdx_66_flag, tb.u_i.u_core.blockSqIdx[66].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_66_value) && tb.u_g.blockSqIdx_66_value !== tb.u_i.u_core.blockSqIdx[66].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[66] g=%h i=%h", $time, tb.u_g.blockSqIdx_66_value, tb.u_i.u_core.blockSqIdx[66].value); end
    if (!$isunknown(tb.u_g.cause_67) && tb.u_g.cause_67 !== tb.u_i.u_core.cause[67]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[67] g=%h i=%h", $time, tb.u_g.cause_67, tb.u_i.u_core.cause[67]); end
    if (!$isunknown(tb.u_g.blockSqIdx_67_flag) && tb.u_g.blockSqIdx_67_flag !== tb.u_i.u_core.blockSqIdx[67].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[67] g=%b i=%b", $time, tb.u_g.blockSqIdx_67_flag, tb.u_i.u_core.blockSqIdx[67].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_67_value) && tb.u_g.blockSqIdx_67_value !== tb.u_i.u_core.blockSqIdx[67].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[67] g=%h i=%h", $time, tb.u_g.blockSqIdx_67_value, tb.u_i.u_core.blockSqIdx[67].value); end
    if (!$isunknown(tb.u_g.cause_68) && tb.u_g.cause_68 !== tb.u_i.u_core.cause[68]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[68] g=%h i=%h", $time, tb.u_g.cause_68, tb.u_i.u_core.cause[68]); end
    if (!$isunknown(tb.u_g.blockSqIdx_68_flag) && tb.u_g.blockSqIdx_68_flag !== tb.u_i.u_core.blockSqIdx[68].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[68] g=%b i=%b", $time, tb.u_g.blockSqIdx_68_flag, tb.u_i.u_core.blockSqIdx[68].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_68_value) && tb.u_g.blockSqIdx_68_value !== tb.u_i.u_core.blockSqIdx[68].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[68] g=%h i=%h", $time, tb.u_g.blockSqIdx_68_value, tb.u_i.u_core.blockSqIdx[68].value); end
    if (!$isunknown(tb.u_g.cause_69) && tb.u_g.cause_69 !== tb.u_i.u_core.cause[69]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[69] g=%h i=%h", $time, tb.u_g.cause_69, tb.u_i.u_core.cause[69]); end
    if (!$isunknown(tb.u_g.blockSqIdx_69_flag) && tb.u_g.blockSqIdx_69_flag !== tb.u_i.u_core.blockSqIdx[69].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[69] g=%b i=%b", $time, tb.u_g.blockSqIdx_69_flag, tb.u_i.u_core.blockSqIdx[69].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_69_value) && tb.u_g.blockSqIdx_69_value !== tb.u_i.u_core.blockSqIdx[69].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[69] g=%h i=%h", $time, tb.u_g.blockSqIdx_69_value, tb.u_i.u_core.blockSqIdx[69].value); end
    if (!$isunknown(tb.u_g.cause_70) && tb.u_g.cause_70 !== tb.u_i.u_core.cause[70]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[70] g=%h i=%h", $time, tb.u_g.cause_70, tb.u_i.u_core.cause[70]); end
    if (!$isunknown(tb.u_g.blockSqIdx_70_flag) && tb.u_g.blockSqIdx_70_flag !== tb.u_i.u_core.blockSqIdx[70].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[70] g=%b i=%b", $time, tb.u_g.blockSqIdx_70_flag, tb.u_i.u_core.blockSqIdx[70].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_70_value) && tb.u_g.blockSqIdx_70_value !== tb.u_i.u_core.blockSqIdx[70].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[70] g=%h i=%h", $time, tb.u_g.blockSqIdx_70_value, tb.u_i.u_core.blockSqIdx[70].value); end
    if (!$isunknown(tb.u_g.cause_71) && tb.u_g.cause_71 !== tb.u_i.u_core.cause[71]) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE cause[71] g=%h i=%h", $time, tb.u_g.cause_71, tb.u_i.u_core.cause[71]); end
    if (!$isunknown(tb.u_g.blockSqIdx_71_flag) && tb.u_g.blockSqIdx_71_flag !== tb.u_i.u_core.blockSqIdx[71].flag) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqF[71] g=%b i=%b", $time, tb.u_g.blockSqIdx_71_flag, tb.u_i.u_core.blockSqIdx[71].flag); end
    if (!$isunknown(tb.u_g.blockSqIdx_71_value) && tb.u_g.blockSqIdx_71_value !== tb.u_i.u_core.blockSqIdx[71].value) begin probe_mismatch++;
      if(probe_mismatch<=60) $display("[%0t] PROBE bsqV[71] g=%h i=%h", $time, tb.u_g.blockSqIdx_71_value, tb.u_i.u_core.blockSqIdx[71].value); end
  end
