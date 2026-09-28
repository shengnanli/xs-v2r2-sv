// =============================================================================
// FastArbiter_28.sv —— FastArbiter 家族薄 wrapper：L2 PCredit 授予仲裁（80 路，无载荷，出口恒 ready）
//
// 例化者：TL2CHICoupledL2.sv（实例 pcrdgrant_arb；Scala coupledL2/tl2chi/TL2CHICoupledL2.scala
//   `fastArb(mshrPCrdArbIn, mshrPCrdArbOut, Some("pcrdgrant"))`）。
// 语义：CHI 下游回来一个 PCrdGrant（重试许可）进 pCrdQueue_s3 队头后，MMIOBridge 与
//   各 slice 的全部 MSHR（共 80 个）里凡是"在等这种许可、且 pCrdType/srcID 对得上"的，
//   都拉起自己那一路 valid；本仲裁器从中挑一个，把 ready 当作"授予"回给它。
//
// 与 FastArbiter_3..7 的两处端口面差别（golden 端口表实测，生成器 fail-closed 核对）：
//   · 载荷是 EmptyBundle（0 位）：golden 没有任何 bits 端口。核的 W 不能为 0，
//     这里给 W=1、每路喂常 0、out_bits 悬空 —— 这一位不进任何寄存器、不到任何输出。
//   · 例化者写死 out.ready := true.B，firtool 折掉了 io_out_ready 端口：
//     golden 里 io_in_k_ready = chosenOH[k]、掩码在 |valids 时就更新。
//     这里把核的 out_ready 接 1'b1，得到的正是同一形状。
//
// 本文件只做端口对位；仲裁逻辑（轮转 + 挂起记忆）在 rtl/common/xs_FastArbiter_core.sv。
// 本文件由 scripts/gen_fastarbiter_28.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_28.sv
// =============================================================================
module FastArbiter_28 (
  input  clock,
  input  reset,
  output io_in_0_ready,
  input  io_in_0_valid,
  output io_in_1_ready,
  input  io_in_1_valid,
  output io_in_2_ready,
  input  io_in_2_valid,
  output io_in_3_ready,
  input  io_in_3_valid,
  output io_in_4_ready,
  input  io_in_4_valid,
  output io_in_5_ready,
  input  io_in_5_valid,
  output io_in_6_ready,
  input  io_in_6_valid,
  output io_in_7_ready,
  input  io_in_7_valid,
  output io_in_8_ready,
  input  io_in_8_valid,
  output io_in_9_ready,
  input  io_in_9_valid,
  output io_in_10_ready,
  input  io_in_10_valid,
  output io_in_11_ready,
  input  io_in_11_valid,
  output io_in_12_ready,
  input  io_in_12_valid,
  output io_in_13_ready,
  input  io_in_13_valid,
  output io_in_14_ready,
  input  io_in_14_valid,
  output io_in_15_ready,
  input  io_in_15_valid,
  output io_in_16_ready,
  input  io_in_16_valid,
  output io_in_17_ready,
  input  io_in_17_valid,
  output io_in_18_ready,
  input  io_in_18_valid,
  output io_in_19_ready,
  input  io_in_19_valid,
  output io_in_20_ready,
  input  io_in_20_valid,
  output io_in_21_ready,
  input  io_in_21_valid,
  output io_in_22_ready,
  input  io_in_22_valid,
  output io_in_23_ready,
  input  io_in_23_valid,
  output io_in_24_ready,
  input  io_in_24_valid,
  output io_in_25_ready,
  input  io_in_25_valid,
  output io_in_26_ready,
  input  io_in_26_valid,
  output io_in_27_ready,
  input  io_in_27_valid,
  output io_in_28_ready,
  input  io_in_28_valid,
  output io_in_29_ready,
  input  io_in_29_valid,
  output io_in_30_ready,
  input  io_in_30_valid,
  output io_in_31_ready,
  input  io_in_31_valid,
  output io_in_32_ready,
  input  io_in_32_valid,
  output io_in_33_ready,
  input  io_in_33_valid,
  output io_in_34_ready,
  input  io_in_34_valid,
  output io_in_35_ready,
  input  io_in_35_valid,
  output io_in_36_ready,
  input  io_in_36_valid,
  output io_in_37_ready,
  input  io_in_37_valid,
  output io_in_38_ready,
  input  io_in_38_valid,
  output io_in_39_ready,
  input  io_in_39_valid,
  output io_in_40_ready,
  input  io_in_40_valid,
  output io_in_41_ready,
  input  io_in_41_valid,
  output io_in_42_ready,
  input  io_in_42_valid,
  output io_in_43_ready,
  input  io_in_43_valid,
  output io_in_44_ready,
  input  io_in_44_valid,
  output io_in_45_ready,
  input  io_in_45_valid,
  output io_in_46_ready,
  input  io_in_46_valid,
  output io_in_47_ready,
  input  io_in_47_valid,
  output io_in_48_ready,
  input  io_in_48_valid,
  output io_in_49_ready,
  input  io_in_49_valid,
  output io_in_50_ready,
  input  io_in_50_valid,
  output io_in_51_ready,
  input  io_in_51_valid,
  output io_in_52_ready,
  input  io_in_52_valid,
  output io_in_53_ready,
  input  io_in_53_valid,
  output io_in_54_ready,
  input  io_in_54_valid,
  output io_in_55_ready,
  input  io_in_55_valid,
  output io_in_56_ready,
  input  io_in_56_valid,
  output io_in_57_ready,
  input  io_in_57_valid,
  output io_in_58_ready,
  input  io_in_58_valid,
  output io_in_59_ready,
  input  io_in_59_valid,
  output io_in_60_ready,
  input  io_in_60_valid,
  output io_in_61_ready,
  input  io_in_61_valid,
  output io_in_62_ready,
  input  io_in_62_valid,
  output io_in_63_ready,
  input  io_in_63_valid,
  output io_in_64_ready,
  input  io_in_64_valid,
  output io_in_65_ready,
  input  io_in_65_valid,
  output io_in_66_ready,
  input  io_in_66_valid,
  output io_in_67_ready,
  input  io_in_67_valid,
  output io_in_68_ready,
  input  io_in_68_valid,
  output io_in_69_ready,
  input  io_in_69_valid,
  output io_in_70_ready,
  input  io_in_70_valid,
  output io_in_71_ready,
  input  io_in_71_valid,
  output io_in_72_ready,
  input  io_in_72_valid,
  output io_in_73_ready,
  input  io_in_73_valid,
  output io_in_74_ready,
  input  io_in_74_valid,
  output io_in_75_ready,
  input  io_in_75_valid,
  output io_in_76_ready,
  input  io_in_76_valid,
  output io_in_77_ready,
  input  io_in_77_valid,
  output io_in_78_ready,
  input  io_in_78_valid,
  output io_in_79_ready,
  input  io_in_79_valid,
  output io_out_valid
);
  localparam int N = 80;

  // ---- 打包：80 路 valid 拼成向量（第 k 路在第 k 位）
  logic [N-1:0] in_valid;
  logic [N-1:0] in_ready;
  assign in_valid = {io_in_79_valid, io_in_78_valid, io_in_77_valid, io_in_76_valid,
                     io_in_75_valid, io_in_74_valid, io_in_73_valid, io_in_72_valid,
                     io_in_71_valid, io_in_70_valid, io_in_69_valid, io_in_68_valid,
                     io_in_67_valid, io_in_66_valid, io_in_65_valid, io_in_64_valid,
                     io_in_63_valid, io_in_62_valid, io_in_61_valid, io_in_60_valid,
                     io_in_59_valid, io_in_58_valid, io_in_57_valid, io_in_56_valid,
                     io_in_55_valid, io_in_54_valid, io_in_53_valid, io_in_52_valid,
                     io_in_51_valid, io_in_50_valid, io_in_49_valid, io_in_48_valid,
                     io_in_47_valid, io_in_46_valid, io_in_45_valid, io_in_44_valid,
                     io_in_43_valid, io_in_42_valid, io_in_41_valid, io_in_40_valid,
                     io_in_39_valid, io_in_38_valid, io_in_37_valid, io_in_36_valid,
                     io_in_35_valid, io_in_34_valid, io_in_33_valid, io_in_32_valid,
                     io_in_31_valid, io_in_30_valid, io_in_29_valid, io_in_28_valid,
                     io_in_27_valid, io_in_26_valid, io_in_25_valid, io_in_24_valid,
                     io_in_23_valid, io_in_22_valid, io_in_21_valid, io_in_20_valid,
                     io_in_19_valid, io_in_18_valid, io_in_17_valid, io_in_16_valid,
                     io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid,
                     io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid,
                     io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid, io_in_3_valid,
                     io_in_2_valid, io_in_1_valid, io_in_0_valid};

  // ---- 核例化：W=1 的占位载荷恒 0、out_bits 不接；out_ready 恒 1
  xs_FastArbiter_core #(.N(N), .W(1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  (in_valid),
    .in_bits   ('0),
    .in_ready  (in_ready),
    .out_ready (1'b1),
    .out_valid (io_out_valid),
    .out_bits  ()
  );

  // ---- 拆包：第 k 路的授予 = in_ready[k]
  assign io_in_0_ready = in_ready[0];
  assign io_in_1_ready = in_ready[1];
  assign io_in_2_ready = in_ready[2];
  assign io_in_3_ready = in_ready[3];
  assign io_in_4_ready = in_ready[4];
  assign io_in_5_ready = in_ready[5];
  assign io_in_6_ready = in_ready[6];
  assign io_in_7_ready = in_ready[7];
  assign io_in_8_ready = in_ready[8];
  assign io_in_9_ready = in_ready[9];
  assign io_in_10_ready = in_ready[10];
  assign io_in_11_ready = in_ready[11];
  assign io_in_12_ready = in_ready[12];
  assign io_in_13_ready = in_ready[13];
  assign io_in_14_ready = in_ready[14];
  assign io_in_15_ready = in_ready[15];
  assign io_in_16_ready = in_ready[16];
  assign io_in_17_ready = in_ready[17];
  assign io_in_18_ready = in_ready[18];
  assign io_in_19_ready = in_ready[19];
  assign io_in_20_ready = in_ready[20];
  assign io_in_21_ready = in_ready[21];
  assign io_in_22_ready = in_ready[22];
  assign io_in_23_ready = in_ready[23];
  assign io_in_24_ready = in_ready[24];
  assign io_in_25_ready = in_ready[25];
  assign io_in_26_ready = in_ready[26];
  assign io_in_27_ready = in_ready[27];
  assign io_in_28_ready = in_ready[28];
  assign io_in_29_ready = in_ready[29];
  assign io_in_30_ready = in_ready[30];
  assign io_in_31_ready = in_ready[31];
  assign io_in_32_ready = in_ready[32];
  assign io_in_33_ready = in_ready[33];
  assign io_in_34_ready = in_ready[34];
  assign io_in_35_ready = in_ready[35];
  assign io_in_36_ready = in_ready[36];
  assign io_in_37_ready = in_ready[37];
  assign io_in_38_ready = in_ready[38];
  assign io_in_39_ready = in_ready[39];
  assign io_in_40_ready = in_ready[40];
  assign io_in_41_ready = in_ready[41];
  assign io_in_42_ready = in_ready[42];
  assign io_in_43_ready = in_ready[43];
  assign io_in_44_ready = in_ready[44];
  assign io_in_45_ready = in_ready[45];
  assign io_in_46_ready = in_ready[46];
  assign io_in_47_ready = in_ready[47];
  assign io_in_48_ready = in_ready[48];
  assign io_in_49_ready = in_ready[49];
  assign io_in_50_ready = in_ready[50];
  assign io_in_51_ready = in_ready[51];
  assign io_in_52_ready = in_ready[52];
  assign io_in_53_ready = in_ready[53];
  assign io_in_54_ready = in_ready[54];
  assign io_in_55_ready = in_ready[55];
  assign io_in_56_ready = in_ready[56];
  assign io_in_57_ready = in_ready[57];
  assign io_in_58_ready = in_ready[58];
  assign io_in_59_ready = in_ready[59];
  assign io_in_60_ready = in_ready[60];
  assign io_in_61_ready = in_ready[61];
  assign io_in_62_ready = in_ready[62];
  assign io_in_63_ready = in_ready[63];
  assign io_in_64_ready = in_ready[64];
  assign io_in_65_ready = in_ready[65];
  assign io_in_66_ready = in_ready[66];
  assign io_in_67_ready = in_ready[67];
  assign io_in_68_ready = in_ready[68];
  assign io_in_69_ready = in_ready[69];
  assign io_in_70_ready = in_ready[70];
  assign io_in_71_ready = in_ready[71];
  assign io_in_72_ready = in_ready[72];
  assign io_in_73_ready = in_ready[73];
  assign io_in_74_ready = in_ready[74];
  assign io_in_75_ready = in_ready[75];
  assign io_in_76_ready = in_ready[76];
  assign io_in_77_ready = in_ready[77];
  assign io_in_78_ready = in_ready[78];
  assign io_in_79_ready = in_ready[79];
endmodule
