// =============================================================================
// tb —— FastArbiter_28 UT：golden 与重写件 FastArbiter_28_xs 双例化，同激励逐拍比全部输出。
//
// 比对：io_out_valid + 80 路 io_in_k_ready。
// 覆盖判据（写进 TEST PASSED，不全即判失败），探 golden 自己的内部线：
//   · 每一路 k 都在"轮转命中"（rrSelOH&valids 非 0）时赢过一次（第 0 路按构造不可能）；
//   · 每一路 k 都在"固定优先级兜底"时赢过一次；
//   · out_valid 取过 0/1；每路 ready 取过 0/1。
// 激励：valid 全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 均匀随机 / "只留某一窗口" 轮换；
// 约 1/5000 的单拍异步复位脉冲。
// 为什么要"窗口"模式：兜底赢要求比 k 低的路全不 valid，均匀随机下高位几乎等不到。
//
// 本文件由 scripts/gen_fastarbiter_28.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  localparam int N = 80;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;

  logic         rst;
  logic [N-1:0] vld;
  logic         g_ov, i_ov;
  logic [N-1:0] g_rdy, i_rdy;

  FastArbiter_28 u_g (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (g_rdy[0]),
    .io_in_0_valid (vld[0]),
    .io_in_1_ready (g_rdy[1]),
    .io_in_1_valid (vld[1]),
    .io_in_2_ready (g_rdy[2]),
    .io_in_2_valid (vld[2]),
    .io_in_3_ready (g_rdy[3]),
    .io_in_3_valid (vld[3]),
    .io_in_4_ready (g_rdy[4]),
    .io_in_4_valid (vld[4]),
    .io_in_5_ready (g_rdy[5]),
    .io_in_5_valid (vld[5]),
    .io_in_6_ready (g_rdy[6]),
    .io_in_6_valid (vld[6]),
    .io_in_7_ready (g_rdy[7]),
    .io_in_7_valid (vld[7]),
    .io_in_8_ready (g_rdy[8]),
    .io_in_8_valid (vld[8]),
    .io_in_9_ready (g_rdy[9]),
    .io_in_9_valid (vld[9]),
    .io_in_10_ready (g_rdy[10]),
    .io_in_10_valid (vld[10]),
    .io_in_11_ready (g_rdy[11]),
    .io_in_11_valid (vld[11]),
    .io_in_12_ready (g_rdy[12]),
    .io_in_12_valid (vld[12]),
    .io_in_13_ready (g_rdy[13]),
    .io_in_13_valid (vld[13]),
    .io_in_14_ready (g_rdy[14]),
    .io_in_14_valid (vld[14]),
    .io_in_15_ready (g_rdy[15]),
    .io_in_15_valid (vld[15]),
    .io_in_16_ready (g_rdy[16]),
    .io_in_16_valid (vld[16]),
    .io_in_17_ready (g_rdy[17]),
    .io_in_17_valid (vld[17]),
    .io_in_18_ready (g_rdy[18]),
    .io_in_18_valid (vld[18]),
    .io_in_19_ready (g_rdy[19]),
    .io_in_19_valid (vld[19]),
    .io_in_20_ready (g_rdy[20]),
    .io_in_20_valid (vld[20]),
    .io_in_21_ready (g_rdy[21]),
    .io_in_21_valid (vld[21]),
    .io_in_22_ready (g_rdy[22]),
    .io_in_22_valid (vld[22]),
    .io_in_23_ready (g_rdy[23]),
    .io_in_23_valid (vld[23]),
    .io_in_24_ready (g_rdy[24]),
    .io_in_24_valid (vld[24]),
    .io_in_25_ready (g_rdy[25]),
    .io_in_25_valid (vld[25]),
    .io_in_26_ready (g_rdy[26]),
    .io_in_26_valid (vld[26]),
    .io_in_27_ready (g_rdy[27]),
    .io_in_27_valid (vld[27]),
    .io_in_28_ready (g_rdy[28]),
    .io_in_28_valid (vld[28]),
    .io_in_29_ready (g_rdy[29]),
    .io_in_29_valid (vld[29]),
    .io_in_30_ready (g_rdy[30]),
    .io_in_30_valid (vld[30]),
    .io_in_31_ready (g_rdy[31]),
    .io_in_31_valid (vld[31]),
    .io_in_32_ready (g_rdy[32]),
    .io_in_32_valid (vld[32]),
    .io_in_33_ready (g_rdy[33]),
    .io_in_33_valid (vld[33]),
    .io_in_34_ready (g_rdy[34]),
    .io_in_34_valid (vld[34]),
    .io_in_35_ready (g_rdy[35]),
    .io_in_35_valid (vld[35]),
    .io_in_36_ready (g_rdy[36]),
    .io_in_36_valid (vld[36]),
    .io_in_37_ready (g_rdy[37]),
    .io_in_37_valid (vld[37]),
    .io_in_38_ready (g_rdy[38]),
    .io_in_38_valid (vld[38]),
    .io_in_39_ready (g_rdy[39]),
    .io_in_39_valid (vld[39]),
    .io_in_40_ready (g_rdy[40]),
    .io_in_40_valid (vld[40]),
    .io_in_41_ready (g_rdy[41]),
    .io_in_41_valid (vld[41]),
    .io_in_42_ready (g_rdy[42]),
    .io_in_42_valid (vld[42]),
    .io_in_43_ready (g_rdy[43]),
    .io_in_43_valid (vld[43]),
    .io_in_44_ready (g_rdy[44]),
    .io_in_44_valid (vld[44]),
    .io_in_45_ready (g_rdy[45]),
    .io_in_45_valid (vld[45]),
    .io_in_46_ready (g_rdy[46]),
    .io_in_46_valid (vld[46]),
    .io_in_47_ready (g_rdy[47]),
    .io_in_47_valid (vld[47]),
    .io_in_48_ready (g_rdy[48]),
    .io_in_48_valid (vld[48]),
    .io_in_49_ready (g_rdy[49]),
    .io_in_49_valid (vld[49]),
    .io_in_50_ready (g_rdy[50]),
    .io_in_50_valid (vld[50]),
    .io_in_51_ready (g_rdy[51]),
    .io_in_51_valid (vld[51]),
    .io_in_52_ready (g_rdy[52]),
    .io_in_52_valid (vld[52]),
    .io_in_53_ready (g_rdy[53]),
    .io_in_53_valid (vld[53]),
    .io_in_54_ready (g_rdy[54]),
    .io_in_54_valid (vld[54]),
    .io_in_55_ready (g_rdy[55]),
    .io_in_55_valid (vld[55]),
    .io_in_56_ready (g_rdy[56]),
    .io_in_56_valid (vld[56]),
    .io_in_57_ready (g_rdy[57]),
    .io_in_57_valid (vld[57]),
    .io_in_58_ready (g_rdy[58]),
    .io_in_58_valid (vld[58]),
    .io_in_59_ready (g_rdy[59]),
    .io_in_59_valid (vld[59]),
    .io_in_60_ready (g_rdy[60]),
    .io_in_60_valid (vld[60]),
    .io_in_61_ready (g_rdy[61]),
    .io_in_61_valid (vld[61]),
    .io_in_62_ready (g_rdy[62]),
    .io_in_62_valid (vld[62]),
    .io_in_63_ready (g_rdy[63]),
    .io_in_63_valid (vld[63]),
    .io_in_64_ready (g_rdy[64]),
    .io_in_64_valid (vld[64]),
    .io_in_65_ready (g_rdy[65]),
    .io_in_65_valid (vld[65]),
    .io_in_66_ready (g_rdy[66]),
    .io_in_66_valid (vld[66]),
    .io_in_67_ready (g_rdy[67]),
    .io_in_67_valid (vld[67]),
    .io_in_68_ready (g_rdy[68]),
    .io_in_68_valid (vld[68]),
    .io_in_69_ready (g_rdy[69]),
    .io_in_69_valid (vld[69]),
    .io_in_70_ready (g_rdy[70]),
    .io_in_70_valid (vld[70]),
    .io_in_71_ready (g_rdy[71]),
    .io_in_71_valid (vld[71]),
    .io_in_72_ready (g_rdy[72]),
    .io_in_72_valid (vld[72]),
    .io_in_73_ready (g_rdy[73]),
    .io_in_73_valid (vld[73]),
    .io_in_74_ready (g_rdy[74]),
    .io_in_74_valid (vld[74]),
    .io_in_75_ready (g_rdy[75]),
    .io_in_75_valid (vld[75]),
    .io_in_76_ready (g_rdy[76]),
    .io_in_76_valid (vld[76]),
    .io_in_77_ready (g_rdy[77]),
    .io_in_77_valid (vld[77]),
    .io_in_78_ready (g_rdy[78]),
    .io_in_78_valid (vld[78]),
    .io_in_79_ready (g_rdy[79]),
    .io_in_79_valid (vld[79]),
    .io_out_valid (g_ov)
  );
  FastArbiter_28_xs u_i (
    .clock (clk),
    .reset (rst),
    .io_in_0_ready (i_rdy[0]),
    .io_in_0_valid (vld[0]),
    .io_in_1_ready (i_rdy[1]),
    .io_in_1_valid (vld[1]),
    .io_in_2_ready (i_rdy[2]),
    .io_in_2_valid (vld[2]),
    .io_in_3_ready (i_rdy[3]),
    .io_in_3_valid (vld[3]),
    .io_in_4_ready (i_rdy[4]),
    .io_in_4_valid (vld[4]),
    .io_in_5_ready (i_rdy[5]),
    .io_in_5_valid (vld[5]),
    .io_in_6_ready (i_rdy[6]),
    .io_in_6_valid (vld[6]),
    .io_in_7_ready (i_rdy[7]),
    .io_in_7_valid (vld[7]),
    .io_in_8_ready (i_rdy[8]),
    .io_in_8_valid (vld[8]),
    .io_in_9_ready (i_rdy[9]),
    .io_in_9_valid (vld[9]),
    .io_in_10_ready (i_rdy[10]),
    .io_in_10_valid (vld[10]),
    .io_in_11_ready (i_rdy[11]),
    .io_in_11_valid (vld[11]),
    .io_in_12_ready (i_rdy[12]),
    .io_in_12_valid (vld[12]),
    .io_in_13_ready (i_rdy[13]),
    .io_in_13_valid (vld[13]),
    .io_in_14_ready (i_rdy[14]),
    .io_in_14_valid (vld[14]),
    .io_in_15_ready (i_rdy[15]),
    .io_in_15_valid (vld[15]),
    .io_in_16_ready (i_rdy[16]),
    .io_in_16_valid (vld[16]),
    .io_in_17_ready (i_rdy[17]),
    .io_in_17_valid (vld[17]),
    .io_in_18_ready (i_rdy[18]),
    .io_in_18_valid (vld[18]),
    .io_in_19_ready (i_rdy[19]),
    .io_in_19_valid (vld[19]),
    .io_in_20_ready (i_rdy[20]),
    .io_in_20_valid (vld[20]),
    .io_in_21_ready (i_rdy[21]),
    .io_in_21_valid (vld[21]),
    .io_in_22_ready (i_rdy[22]),
    .io_in_22_valid (vld[22]),
    .io_in_23_ready (i_rdy[23]),
    .io_in_23_valid (vld[23]),
    .io_in_24_ready (i_rdy[24]),
    .io_in_24_valid (vld[24]),
    .io_in_25_ready (i_rdy[25]),
    .io_in_25_valid (vld[25]),
    .io_in_26_ready (i_rdy[26]),
    .io_in_26_valid (vld[26]),
    .io_in_27_ready (i_rdy[27]),
    .io_in_27_valid (vld[27]),
    .io_in_28_ready (i_rdy[28]),
    .io_in_28_valid (vld[28]),
    .io_in_29_ready (i_rdy[29]),
    .io_in_29_valid (vld[29]),
    .io_in_30_ready (i_rdy[30]),
    .io_in_30_valid (vld[30]),
    .io_in_31_ready (i_rdy[31]),
    .io_in_31_valid (vld[31]),
    .io_in_32_ready (i_rdy[32]),
    .io_in_32_valid (vld[32]),
    .io_in_33_ready (i_rdy[33]),
    .io_in_33_valid (vld[33]),
    .io_in_34_ready (i_rdy[34]),
    .io_in_34_valid (vld[34]),
    .io_in_35_ready (i_rdy[35]),
    .io_in_35_valid (vld[35]),
    .io_in_36_ready (i_rdy[36]),
    .io_in_36_valid (vld[36]),
    .io_in_37_ready (i_rdy[37]),
    .io_in_37_valid (vld[37]),
    .io_in_38_ready (i_rdy[38]),
    .io_in_38_valid (vld[38]),
    .io_in_39_ready (i_rdy[39]),
    .io_in_39_valid (vld[39]),
    .io_in_40_ready (i_rdy[40]),
    .io_in_40_valid (vld[40]),
    .io_in_41_ready (i_rdy[41]),
    .io_in_41_valid (vld[41]),
    .io_in_42_ready (i_rdy[42]),
    .io_in_42_valid (vld[42]),
    .io_in_43_ready (i_rdy[43]),
    .io_in_43_valid (vld[43]),
    .io_in_44_ready (i_rdy[44]),
    .io_in_44_valid (vld[44]),
    .io_in_45_ready (i_rdy[45]),
    .io_in_45_valid (vld[45]),
    .io_in_46_ready (i_rdy[46]),
    .io_in_46_valid (vld[46]),
    .io_in_47_ready (i_rdy[47]),
    .io_in_47_valid (vld[47]),
    .io_in_48_ready (i_rdy[48]),
    .io_in_48_valid (vld[48]),
    .io_in_49_ready (i_rdy[49]),
    .io_in_49_valid (vld[49]),
    .io_in_50_ready (i_rdy[50]),
    .io_in_50_valid (vld[50]),
    .io_in_51_ready (i_rdy[51]),
    .io_in_51_valid (vld[51]),
    .io_in_52_ready (i_rdy[52]),
    .io_in_52_valid (vld[52]),
    .io_in_53_ready (i_rdy[53]),
    .io_in_53_valid (vld[53]),
    .io_in_54_ready (i_rdy[54]),
    .io_in_54_valid (vld[54]),
    .io_in_55_ready (i_rdy[55]),
    .io_in_55_valid (vld[55]),
    .io_in_56_ready (i_rdy[56]),
    .io_in_56_valid (vld[56]),
    .io_in_57_ready (i_rdy[57]),
    .io_in_57_valid (vld[57]),
    .io_in_58_ready (i_rdy[58]),
    .io_in_58_valid (vld[58]),
    .io_in_59_ready (i_rdy[59]),
    .io_in_59_valid (vld[59]),
    .io_in_60_ready (i_rdy[60]),
    .io_in_60_valid (vld[60]),
    .io_in_61_ready (i_rdy[61]),
    .io_in_61_valid (vld[61]),
    .io_in_62_ready (i_rdy[62]),
    .io_in_62_valid (vld[62]),
    .io_in_63_ready (i_rdy[63]),
    .io_in_63_valid (vld[63]),
    .io_in_64_ready (i_rdy[64]),
    .io_in_64_valid (vld[64]),
    .io_in_65_ready (i_rdy[65]),
    .io_in_65_valid (vld[65]),
    .io_in_66_ready (i_rdy[66]),
    .io_in_66_valid (vld[66]),
    .io_in_67_ready (i_rdy[67]),
    .io_in_67_valid (vld[67]),
    .io_in_68_ready (i_rdy[68]),
    .io_in_68_valid (vld[68]),
    .io_in_69_ready (i_rdy[69]),
    .io_in_69_valid (vld[69]),
    .io_in_70_ready (i_rdy[70]),
    .io_in_70_valid (vld[70]),
    .io_in_71_ready (i_rdy[71]),
    .io_in_71_valid (vld[71]),
    .io_in_72_ready (i_rdy[72]),
    .io_in_72_valid (vld[72]),
    .io_in_73_ready (i_rdy[73]),
    .io_in_73_valid (vld[73]),
    .io_in_74_ready (i_rdy[74]),
    .io_in_74_valid (vld[74]),
    .io_in_75_ready (i_rdy[75]),
    .io_in_75_valid (vld[75]),
    .io_in_76_ready (i_rdy[76]),
    .io_in_76_valid (vld[76]),
    .io_in_77_ready (i_rdy[77]),
    .io_in_77_valid (vld[77]),
    .io_in_78_ready (i_rdy[78]),
    .io_in_78_valid (vld[78]),
    .io_in_79_ready (i_rdy[79]),
    .io_in_79_valid (vld[79]),
    .io_out_valid (i_ov)
  );

  logic [N-1:0] cov_rr, cov_first, cov_rdy0, cov_rdy1;
  logic [1:0]   cov_ov;

  task automatic check();
    checks++;
    if (g_ov !== i_ov) begin
      errors++;
      if (errors <= 40) $display("[%0t] MISMATCH out_valid golden=%b impl=%b", $time, g_ov, i_ov);
    end
    checks++;
    if (g_rdy !== i_rdy) begin
      errors++;
      if (errors <= 40) $display("[%0t] MISMATCH in_ready golden=%h impl=%h", $time, g_rdy, i_rdy);
    end
    cov_ov[g_ov] = 1'b1;
    for (int k = 0; k < N; k++) begin
      if (g_rdy[k]) cov_rdy1[k] = 1'b1; else cov_rdy0[k] = 1'b1;
      if (u_g.chosenOH[k]) begin
        if (|(u_g.rrSelOH & u_g.valids)) cov_rr[k] = 1'b1;
        else cov_first[k] = 1'b1;
      end
    end
  endtask

  task automatic drive();
    int lo, hi;
    for (int b = 0; b < N; b += 32) vld[b +: 32] = $urandom;
    case ($urandom_range(0, 7))
      0: vld = '0;
      1: vld = '1;
      2: vld = {{(N-1){1'b0}}, 1'b1} << $urandom_range(0, N-1);
      3: for (int b = 0; b < N; b += 32) vld[b +: 32] = $urandom & $urandom & $urandom;  // 稀疏
      4: for (int b = 0; b < N; b += 32) vld[b +: 32] = $urandom | $urandom;             // 稠密
      5, 6: begin                                  // 只留 [lo,hi] 窗口（其余清零）
        lo = $urandom_range(0, N-1);
        hi = $urandom_range(lo, N-1);
        for (int k = 0; k < N; k++) if (k < lo || k > hi) vld[k] = 1'b0;
      end
      default: ;                                   // 均匀随机
    endcase
    rst = ($urandom_range(0, 4999) == 0);  // 单拍异步复位脉冲
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    cov_rr = '0; cov_first = '0; cov_rdy0 = '0; cov_rdy1 = '0; cov_ov = '0;
    rst = 1'b1; vld = '0;
    repeat (8) @(posedge clk);
    #1; drive(); rst = 1'b0;
    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0, nrr = 0, nfi = 0, nr0 = 0, nr1 = 0;
    for (int k = 0; k < N; k++) begin
      nrr += cov_rr[k]; nfi += cov_first[k]; nr0 += cov_rdy0[k]; nr1 += cov_rdy1[k];
    end
    if (nfi != N || nr0 != N || nr1 != N || cov_ov != 2'b11) bad++;
    // 第 0 路永远不可能"轮转命中"（rrGrantMask[0] 恒 0），其余各路必须都命中过
    if (nrr != N - 1 || cov_rr[0]) bad++;
    $display("--- coverage: rr %0d/%0d  first %0d/%0d  rdy0 %0d rdy1 %0d  ov=%b",
             nrr, N-1, nfi, N, nr0, nr1, cov_ov);
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
