// 自动生成：scripts/gen_plicfanin.py —— 勿手改
// PLICFanIn 双例化逐拍比对：golden PLICFanIn vs 可读重写 PLICFanIn_xs。
// 纯组合模块：每拍随机驱动 65 路优先级 + 65 位挂起向量，比对 io_dev/io_max。
// 激励混合：全随机 + 偏置 (大量未挂起 / 单热挂起 / 全挂起) 以覆盖仲裁边界。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 20) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic [2:0] io_prio_0;
  logic [2:0] io_prio_1;
  logic [2:0] io_prio_2;
  logic [2:0] io_prio_3;
  logic [2:0] io_prio_4;
  logic [2:0] io_prio_5;
  logic [2:0] io_prio_6;
  logic [2:0] io_prio_7;
  logic [2:0] io_prio_8;
  logic [2:0] io_prio_9;
  logic [2:0] io_prio_10;
  logic [2:0] io_prio_11;
  logic [2:0] io_prio_12;
  logic [2:0] io_prio_13;
  logic [2:0] io_prio_14;
  logic [2:0] io_prio_15;
  logic [2:0] io_prio_16;
  logic [2:0] io_prio_17;
  logic [2:0] io_prio_18;
  logic [2:0] io_prio_19;
  logic [2:0] io_prio_20;
  logic [2:0] io_prio_21;
  logic [2:0] io_prio_22;
  logic [2:0] io_prio_23;
  logic [2:0] io_prio_24;
  logic [2:0] io_prio_25;
  logic [2:0] io_prio_26;
  logic [2:0] io_prio_27;
  logic [2:0] io_prio_28;
  logic [2:0] io_prio_29;
  logic [2:0] io_prio_30;
  logic [2:0] io_prio_31;
  logic [2:0] io_prio_32;
  logic [2:0] io_prio_33;
  logic [2:0] io_prio_34;
  logic [2:0] io_prio_35;
  logic [2:0] io_prio_36;
  logic [2:0] io_prio_37;
  logic [2:0] io_prio_38;
  logic [2:0] io_prio_39;
  logic [2:0] io_prio_40;
  logic [2:0] io_prio_41;
  logic [2:0] io_prio_42;
  logic [2:0] io_prio_43;
  logic [2:0] io_prio_44;
  logic [2:0] io_prio_45;
  logic [2:0] io_prio_46;
  logic [2:0] io_prio_47;
  logic [2:0] io_prio_48;
  logic [2:0] io_prio_49;
  logic [2:0] io_prio_50;
  logic [2:0] io_prio_51;
  logic [2:0] io_prio_52;
  logic [2:0] io_prio_53;
  logic [2:0] io_prio_54;
  logic [2:0] io_prio_55;
  logic [2:0] io_prio_56;
  logic [2:0] io_prio_57;
  logic [2:0] io_prio_58;
  logic [2:0] io_prio_59;
  logic [2:0] io_prio_60;
  logic [2:0] io_prio_61;
  logic [2:0] io_prio_62;
  logic [2:0] io_prio_63;
  logic [2:0] io_prio_64;
  logic [64:0] io_ip;
  wire [6:0] g_io_dev;
  wire [6:0] i_io_dev;
  wire [2:0] g_io_max;
  wire [2:0] i_io_max;

  PLICFanIn u_g (
    .io_prio_0(io_prio_0),
    .io_prio_1(io_prio_1),
    .io_prio_2(io_prio_2),
    .io_prio_3(io_prio_3),
    .io_prio_4(io_prio_4),
    .io_prio_5(io_prio_5),
    .io_prio_6(io_prio_6),
    .io_prio_7(io_prio_7),
    .io_prio_8(io_prio_8),
    .io_prio_9(io_prio_9),
    .io_prio_10(io_prio_10),
    .io_prio_11(io_prio_11),
    .io_prio_12(io_prio_12),
    .io_prio_13(io_prio_13),
    .io_prio_14(io_prio_14),
    .io_prio_15(io_prio_15),
    .io_prio_16(io_prio_16),
    .io_prio_17(io_prio_17),
    .io_prio_18(io_prio_18),
    .io_prio_19(io_prio_19),
    .io_prio_20(io_prio_20),
    .io_prio_21(io_prio_21),
    .io_prio_22(io_prio_22),
    .io_prio_23(io_prio_23),
    .io_prio_24(io_prio_24),
    .io_prio_25(io_prio_25),
    .io_prio_26(io_prio_26),
    .io_prio_27(io_prio_27),
    .io_prio_28(io_prio_28),
    .io_prio_29(io_prio_29),
    .io_prio_30(io_prio_30),
    .io_prio_31(io_prio_31),
    .io_prio_32(io_prio_32),
    .io_prio_33(io_prio_33),
    .io_prio_34(io_prio_34),
    .io_prio_35(io_prio_35),
    .io_prio_36(io_prio_36),
    .io_prio_37(io_prio_37),
    .io_prio_38(io_prio_38),
    .io_prio_39(io_prio_39),
    .io_prio_40(io_prio_40),
    .io_prio_41(io_prio_41),
    .io_prio_42(io_prio_42),
    .io_prio_43(io_prio_43),
    .io_prio_44(io_prio_44),
    .io_prio_45(io_prio_45),
    .io_prio_46(io_prio_46),
    .io_prio_47(io_prio_47),
    .io_prio_48(io_prio_48),
    .io_prio_49(io_prio_49),
    .io_prio_50(io_prio_50),
    .io_prio_51(io_prio_51),
    .io_prio_52(io_prio_52),
    .io_prio_53(io_prio_53),
    .io_prio_54(io_prio_54),
    .io_prio_55(io_prio_55),
    .io_prio_56(io_prio_56),
    .io_prio_57(io_prio_57),
    .io_prio_58(io_prio_58),
    .io_prio_59(io_prio_59),
    .io_prio_60(io_prio_60),
    .io_prio_61(io_prio_61),
    .io_prio_62(io_prio_62),
    .io_prio_63(io_prio_63),
    .io_prio_64(io_prio_64),
    .io_ip(io_ip),
    .io_dev(g_io_dev),
    .io_max(g_io_max)
  );

  PLICFanIn_xs u_i (
    .io_prio_0(io_prio_0),
    .io_prio_1(io_prio_1),
    .io_prio_2(io_prio_2),
    .io_prio_3(io_prio_3),
    .io_prio_4(io_prio_4),
    .io_prio_5(io_prio_5),
    .io_prio_6(io_prio_6),
    .io_prio_7(io_prio_7),
    .io_prio_8(io_prio_8),
    .io_prio_9(io_prio_9),
    .io_prio_10(io_prio_10),
    .io_prio_11(io_prio_11),
    .io_prio_12(io_prio_12),
    .io_prio_13(io_prio_13),
    .io_prio_14(io_prio_14),
    .io_prio_15(io_prio_15),
    .io_prio_16(io_prio_16),
    .io_prio_17(io_prio_17),
    .io_prio_18(io_prio_18),
    .io_prio_19(io_prio_19),
    .io_prio_20(io_prio_20),
    .io_prio_21(io_prio_21),
    .io_prio_22(io_prio_22),
    .io_prio_23(io_prio_23),
    .io_prio_24(io_prio_24),
    .io_prio_25(io_prio_25),
    .io_prio_26(io_prio_26),
    .io_prio_27(io_prio_27),
    .io_prio_28(io_prio_28),
    .io_prio_29(io_prio_29),
    .io_prio_30(io_prio_30),
    .io_prio_31(io_prio_31),
    .io_prio_32(io_prio_32),
    .io_prio_33(io_prio_33),
    .io_prio_34(io_prio_34),
    .io_prio_35(io_prio_35),
    .io_prio_36(io_prio_36),
    .io_prio_37(io_prio_37),
    .io_prio_38(io_prio_38),
    .io_prio_39(io_prio_39),
    .io_prio_40(io_prio_40),
    .io_prio_41(io_prio_41),
    .io_prio_42(io_prio_42),
    .io_prio_43(io_prio_43),
    .io_prio_44(io_prio_44),
    .io_prio_45(io_prio_45),
    .io_prio_46(io_prio_46),
    .io_prio_47(io_prio_47),
    .io_prio_48(io_prio_48),
    .io_prio_49(io_prio_49),
    .io_prio_50(io_prio_50),
    .io_prio_51(io_prio_51),
    .io_prio_52(io_prio_52),
    .io_prio_53(io_prio_53),
    .io_prio_54(io_prio_54),
    .io_prio_55(io_prio_55),
    .io_prio_56(io_prio_56),
    .io_prio_57(io_prio_57),
    .io_prio_58(io_prio_58),
    .io_prio_59(io_prio_59),
    .io_prio_60(io_prio_60),
    .io_prio_61(io_prio_61),
    .io_prio_62(io_prio_62),
    .io_prio_63(io_prio_63),
    .io_prio_64(io_prio_64),
    .io_ip(io_ip),
    .io_dev(i_io_dev),
    .io_max(i_io_max)
  );

  // 随机驱动：mode 控制挂起向量分布，覆盖仲裁各路径
  task automatic drive_random_inputs();
    int mode;
    mode = $urandom_range(0, 4);
    // 优先级始终全随机 (3 位)
    io_prio_0 = 3'($urandom);
    io_prio_1 = 3'($urandom);
    io_prio_2 = 3'($urandom);
    io_prio_3 = 3'($urandom);
    io_prio_4 = 3'($urandom);
    io_prio_5 = 3'($urandom);
    io_prio_6 = 3'($urandom);
    io_prio_7 = 3'($urandom);
    io_prio_8 = 3'($urandom);
    io_prio_9 = 3'($urandom);
    io_prio_10 = 3'($urandom);
    io_prio_11 = 3'($urandom);
    io_prio_12 = 3'($urandom);
    io_prio_13 = 3'($urandom);
    io_prio_14 = 3'($urandom);
    io_prio_15 = 3'($urandom);
    io_prio_16 = 3'($urandom);
    io_prio_17 = 3'($urandom);
    io_prio_18 = 3'($urandom);
    io_prio_19 = 3'($urandom);
    io_prio_20 = 3'($urandom);
    io_prio_21 = 3'($urandom);
    io_prio_22 = 3'($urandom);
    io_prio_23 = 3'($urandom);
    io_prio_24 = 3'($urandom);
    io_prio_25 = 3'($urandom);
    io_prio_26 = 3'($urandom);
    io_prio_27 = 3'($urandom);
    io_prio_28 = 3'($urandom);
    io_prio_29 = 3'($urandom);
    io_prio_30 = 3'($urandom);
    io_prio_31 = 3'($urandom);
    io_prio_32 = 3'($urandom);
    io_prio_33 = 3'($urandom);
    io_prio_34 = 3'($urandom);
    io_prio_35 = 3'($urandom);
    io_prio_36 = 3'($urandom);
    io_prio_37 = 3'($urandom);
    io_prio_38 = 3'($urandom);
    io_prio_39 = 3'($urandom);
    io_prio_40 = 3'($urandom);
    io_prio_41 = 3'($urandom);
    io_prio_42 = 3'($urandom);
    io_prio_43 = 3'($urandom);
    io_prio_44 = 3'($urandom);
    io_prio_45 = 3'($urandom);
    io_prio_46 = 3'($urandom);
    io_prio_47 = 3'($urandom);
    io_prio_48 = 3'($urandom);
    io_prio_49 = 3'($urandom);
    io_prio_50 = 3'($urandom);
    io_prio_51 = 3'($urandom);
    io_prio_52 = 3'($urandom);
    io_prio_53 = 3'($urandom);
    io_prio_54 = 3'($urandom);
    io_prio_55 = 3'($urandom);
    io_prio_56 = 3'($urandom);
    io_prio_57 = 3'($urandom);
    io_prio_58 = 3'($urandom);
    io_prio_59 = 3'($urandom);
    io_prio_60 = 3'($urandom);
    io_prio_61 = 3'($urandom);
    io_prio_62 = 3'($urandom);
    io_prio_63 = 3'($urandom);
    io_prio_64 = 3'($urandom);
    case (mode)
      0: io_ip = '0;                          // 无挂起：占位设备(dev=0)应胜出
      1: io_ip = (65'h1 << $urandom_range(0, 64)); // 单热挂起
      2: io_ip = '1;                          // 全挂起
      3: io_ip = {65{1'b0}} | (65'($urandom) & 65'($urandom)); // 稀疏随机(两随机数相与，挂起更稀)
      default: io_ip = {32'($urandom), 33'($urandom)}; // 全随机 65 位
    endcase
  endtask

  task automatic check_outputs();
    `CHECK(io_dev)
    `CHECK(io_max)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_prio_0 = '0;
    io_prio_1 = '0;
    io_prio_2 = '0;
    io_prio_3 = '0;
    io_prio_4 = '0;
    io_prio_5 = '0;
    io_prio_6 = '0;
    io_prio_7 = '0;
    io_prio_8 = '0;
    io_prio_9 = '0;
    io_prio_10 = '0;
    io_prio_11 = '0;
    io_prio_12 = '0;
    io_prio_13 = '0;
    io_prio_14 = '0;
    io_prio_15 = '0;
    io_prio_16 = '0;
    io_prio_17 = '0;
    io_prio_18 = '0;
    io_prio_19 = '0;
    io_prio_20 = '0;
    io_prio_21 = '0;
    io_prio_22 = '0;
    io_prio_23 = '0;
    io_prio_24 = '0;
    io_prio_25 = '0;
    io_prio_26 = '0;
    io_prio_27 = '0;
    io_prio_28 = '0;
    io_prio_29 = '0;
    io_prio_30 = '0;
    io_prio_31 = '0;
    io_prio_32 = '0;
    io_prio_33 = '0;
    io_prio_34 = '0;
    io_prio_35 = '0;
    io_prio_36 = '0;
    io_prio_37 = '0;
    io_prio_38 = '0;
    io_prio_39 = '0;
    io_prio_40 = '0;
    io_prio_41 = '0;
    io_prio_42 = '0;
    io_prio_43 = '0;
    io_prio_44 = '0;
    io_prio_45 = '0;
    io_prio_46 = '0;
    io_prio_47 = '0;
    io_prio_48 = '0;
    io_prio_49 = '0;
    io_prio_50 = '0;
    io_prio_51 = '0;
    io_prio_52 = '0;
    io_prio_53 = '0;
    io_prio_54 = '0;
    io_prio_55 = '0;
    io_prio_56 = '0;
    io_prio_57 = '0;
    io_prio_58 = '0;
    io_prio_59 = '0;
    io_prio_60 = '0;
    io_prio_61 = '0;
    io_prio_62 = '0;
    io_prio_63 = '0;
    io_prio_64 = '0;
    io_ip = '0;
    repeat (4) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("PLICFanIn checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
