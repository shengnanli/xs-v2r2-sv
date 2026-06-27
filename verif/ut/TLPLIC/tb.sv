// 自动生成：scripts/gen_tlplic.py —— 勿手改
// TLPLIC 双例化逐拍比对: golden TLPLIC vs 可读重写 TLPLIC_xs。
// 激励: 65 路外设中断 (偏置: 多数拉低/单热/稀疏/全高) + TileLink A 随机请求
// (地址偏向命中合法寄存器区: priority/pending/enable/hart claim)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
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

  logic auto_int_in_1_0;
  logic auto_int_in_0_0;
  logic auto_int_in_0_1;
  logic auto_int_in_0_2;
  logic auto_int_in_0_3;
  logic auto_int_in_0_4;
  logic auto_int_in_0_5;
  logic auto_int_in_0_6;
  logic auto_int_in_0_7;
  logic auto_int_in_0_8;
  logic auto_int_in_0_9;
  logic auto_int_in_0_10;
  logic auto_int_in_0_11;
  logic auto_int_in_0_12;
  logic auto_int_in_0_13;
  logic auto_int_in_0_14;
  logic auto_int_in_0_15;
  logic auto_int_in_0_16;
  logic auto_int_in_0_17;
  logic auto_int_in_0_18;
  logic auto_int_in_0_19;
  logic auto_int_in_0_20;
  logic auto_int_in_0_21;
  logic auto_int_in_0_22;
  logic auto_int_in_0_23;
  logic auto_int_in_0_24;
  logic auto_int_in_0_25;
  logic auto_int_in_0_26;
  logic auto_int_in_0_27;
  logic auto_int_in_0_28;
  logic auto_int_in_0_29;
  logic auto_int_in_0_30;
  logic auto_int_in_0_31;
  logic auto_int_in_0_32;
  logic auto_int_in_0_33;
  logic auto_int_in_0_34;
  logic auto_int_in_0_35;
  logic auto_int_in_0_36;
  logic auto_int_in_0_37;
  logic auto_int_in_0_38;
  logic auto_int_in_0_39;
  logic auto_int_in_0_40;
  logic auto_int_in_0_41;
  logic auto_int_in_0_42;
  logic auto_int_in_0_43;
  logic auto_int_in_0_44;
  logic auto_int_in_0_45;
  logic auto_int_in_0_46;
  logic auto_int_in_0_47;
  logic auto_int_in_0_48;
  logic auto_int_in_0_49;
  logic auto_int_in_0_50;
  logic auto_int_in_0_51;
  logic auto_int_in_0_52;
  logic auto_int_in_0_53;
  logic auto_int_in_0_54;
  logic auto_int_in_0_55;
  logic auto_int_in_0_56;
  logic auto_int_in_0_57;
  logic auto_int_in_0_58;
  logic auto_int_in_0_59;
  logic auto_int_in_0_60;
  logic auto_int_in_0_61;
  logic auto_int_in_0_62;
  logic auto_int_in_0_63;
  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [1:0] auto_in_a_bits_size;
  logic [14:0] auto_in_a_bits_source;
  logic [29:0] auto_in_a_bits_address;
  logic [7:0] auto_in_a_bits_mask;
  logic [63:0] auto_in_a_bits_data;
  logic auto_in_d_ready;
  wire g_auto_int_out_1_0;
  wire i_auto_int_out_1_0;
  wire g_auto_int_out_0_0;
  wire i_auto_int_out_0_0;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [1:0] g_auto_in_d_bits_size;
  wire [1:0] i_auto_in_d_bits_size;
  wire [14:0] g_auto_in_d_bits_source;
  wire [14:0] i_auto_in_d_bits_source;
  wire [63:0] g_auto_in_d_bits_data;
  wire [63:0] i_auto_in_d_bits_data;

  TLPLIC u_g (
    .clock(clock),
    .reset(reset),
    .auto_int_in_1_0(auto_int_in_1_0),
    .auto_int_in_0_0(auto_int_in_0_0),
    .auto_int_in_0_1(auto_int_in_0_1),
    .auto_int_in_0_2(auto_int_in_0_2),
    .auto_int_in_0_3(auto_int_in_0_3),
    .auto_int_in_0_4(auto_int_in_0_4),
    .auto_int_in_0_5(auto_int_in_0_5),
    .auto_int_in_0_6(auto_int_in_0_6),
    .auto_int_in_0_7(auto_int_in_0_7),
    .auto_int_in_0_8(auto_int_in_0_8),
    .auto_int_in_0_9(auto_int_in_0_9),
    .auto_int_in_0_10(auto_int_in_0_10),
    .auto_int_in_0_11(auto_int_in_0_11),
    .auto_int_in_0_12(auto_int_in_0_12),
    .auto_int_in_0_13(auto_int_in_0_13),
    .auto_int_in_0_14(auto_int_in_0_14),
    .auto_int_in_0_15(auto_int_in_0_15),
    .auto_int_in_0_16(auto_int_in_0_16),
    .auto_int_in_0_17(auto_int_in_0_17),
    .auto_int_in_0_18(auto_int_in_0_18),
    .auto_int_in_0_19(auto_int_in_0_19),
    .auto_int_in_0_20(auto_int_in_0_20),
    .auto_int_in_0_21(auto_int_in_0_21),
    .auto_int_in_0_22(auto_int_in_0_22),
    .auto_int_in_0_23(auto_int_in_0_23),
    .auto_int_in_0_24(auto_int_in_0_24),
    .auto_int_in_0_25(auto_int_in_0_25),
    .auto_int_in_0_26(auto_int_in_0_26),
    .auto_int_in_0_27(auto_int_in_0_27),
    .auto_int_in_0_28(auto_int_in_0_28),
    .auto_int_in_0_29(auto_int_in_0_29),
    .auto_int_in_0_30(auto_int_in_0_30),
    .auto_int_in_0_31(auto_int_in_0_31),
    .auto_int_in_0_32(auto_int_in_0_32),
    .auto_int_in_0_33(auto_int_in_0_33),
    .auto_int_in_0_34(auto_int_in_0_34),
    .auto_int_in_0_35(auto_int_in_0_35),
    .auto_int_in_0_36(auto_int_in_0_36),
    .auto_int_in_0_37(auto_int_in_0_37),
    .auto_int_in_0_38(auto_int_in_0_38),
    .auto_int_in_0_39(auto_int_in_0_39),
    .auto_int_in_0_40(auto_int_in_0_40),
    .auto_int_in_0_41(auto_int_in_0_41),
    .auto_int_in_0_42(auto_int_in_0_42),
    .auto_int_in_0_43(auto_int_in_0_43),
    .auto_int_in_0_44(auto_int_in_0_44),
    .auto_int_in_0_45(auto_int_in_0_45),
    .auto_int_in_0_46(auto_int_in_0_46),
    .auto_int_in_0_47(auto_int_in_0_47),
    .auto_int_in_0_48(auto_int_in_0_48),
    .auto_int_in_0_49(auto_int_in_0_49),
    .auto_int_in_0_50(auto_int_in_0_50),
    .auto_int_in_0_51(auto_int_in_0_51),
    .auto_int_in_0_52(auto_int_in_0_52),
    .auto_int_in_0_53(auto_int_in_0_53),
    .auto_int_in_0_54(auto_int_in_0_54),
    .auto_int_in_0_55(auto_int_in_0_55),
    .auto_int_in_0_56(auto_int_in_0_56),
    .auto_int_in_0_57(auto_int_in_0_57),
    .auto_int_in_0_58(auto_int_in_0_58),
    .auto_int_in_0_59(auto_int_in_0_59),
    .auto_int_in_0_60(auto_int_in_0_60),
    .auto_int_in_0_61(auto_int_in_0_61),
    .auto_int_in_0_62(auto_int_in_0_62),
    .auto_int_in_0_63(auto_int_in_0_63),
    .auto_int_out_1_0(g_auto_int_out_1_0),
    .auto_int_out_0_0(g_auto_int_out_0_0),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_data(g_auto_in_d_bits_data)
  );

  TLPLIC_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_int_in_1_0(auto_int_in_1_0),
    .auto_int_in_0_0(auto_int_in_0_0),
    .auto_int_in_0_1(auto_int_in_0_1),
    .auto_int_in_0_2(auto_int_in_0_2),
    .auto_int_in_0_3(auto_int_in_0_3),
    .auto_int_in_0_4(auto_int_in_0_4),
    .auto_int_in_0_5(auto_int_in_0_5),
    .auto_int_in_0_6(auto_int_in_0_6),
    .auto_int_in_0_7(auto_int_in_0_7),
    .auto_int_in_0_8(auto_int_in_0_8),
    .auto_int_in_0_9(auto_int_in_0_9),
    .auto_int_in_0_10(auto_int_in_0_10),
    .auto_int_in_0_11(auto_int_in_0_11),
    .auto_int_in_0_12(auto_int_in_0_12),
    .auto_int_in_0_13(auto_int_in_0_13),
    .auto_int_in_0_14(auto_int_in_0_14),
    .auto_int_in_0_15(auto_int_in_0_15),
    .auto_int_in_0_16(auto_int_in_0_16),
    .auto_int_in_0_17(auto_int_in_0_17),
    .auto_int_in_0_18(auto_int_in_0_18),
    .auto_int_in_0_19(auto_int_in_0_19),
    .auto_int_in_0_20(auto_int_in_0_20),
    .auto_int_in_0_21(auto_int_in_0_21),
    .auto_int_in_0_22(auto_int_in_0_22),
    .auto_int_in_0_23(auto_int_in_0_23),
    .auto_int_in_0_24(auto_int_in_0_24),
    .auto_int_in_0_25(auto_int_in_0_25),
    .auto_int_in_0_26(auto_int_in_0_26),
    .auto_int_in_0_27(auto_int_in_0_27),
    .auto_int_in_0_28(auto_int_in_0_28),
    .auto_int_in_0_29(auto_int_in_0_29),
    .auto_int_in_0_30(auto_int_in_0_30),
    .auto_int_in_0_31(auto_int_in_0_31),
    .auto_int_in_0_32(auto_int_in_0_32),
    .auto_int_in_0_33(auto_int_in_0_33),
    .auto_int_in_0_34(auto_int_in_0_34),
    .auto_int_in_0_35(auto_int_in_0_35),
    .auto_int_in_0_36(auto_int_in_0_36),
    .auto_int_in_0_37(auto_int_in_0_37),
    .auto_int_in_0_38(auto_int_in_0_38),
    .auto_int_in_0_39(auto_int_in_0_39),
    .auto_int_in_0_40(auto_int_in_0_40),
    .auto_int_in_0_41(auto_int_in_0_41),
    .auto_int_in_0_42(auto_int_in_0_42),
    .auto_int_in_0_43(auto_int_in_0_43),
    .auto_int_in_0_44(auto_int_in_0_44),
    .auto_int_in_0_45(auto_int_in_0_45),
    .auto_int_in_0_46(auto_int_in_0_46),
    .auto_int_in_0_47(auto_int_in_0_47),
    .auto_int_in_0_48(auto_int_in_0_48),
    .auto_int_in_0_49(auto_int_in_0_49),
    .auto_int_in_0_50(auto_int_in_0_50),
    .auto_int_in_0_51(auto_int_in_0_51),
    .auto_int_in_0_52(auto_int_in_0_52),
    .auto_int_in_0_53(auto_int_in_0_53),
    .auto_int_in_0_54(auto_int_in_0_54),
    .auto_int_in_0_55(auto_int_in_0_55),
    .auto_int_in_0_56(auto_int_in_0_56),
    .auto_int_in_0_57(auto_int_in_0_57),
    .auto_int_in_0_58(auto_int_in_0_58),
    .auto_int_in_0_59(auto_int_in_0_59),
    .auto_int_in_0_60(auto_int_in_0_60),
    .auto_int_in_0_61(auto_int_in_0_61),
    .auto_int_in_0_62(auto_int_in_0_62),
    .auto_int_in_0_63(auto_int_in_0_63),
    .auto_int_out_1_0(i_auto_int_out_1_0),
    .auto_int_out_0_0(i_auto_int_out_0_0),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_data(i_auto_in_d_bits_data)
  );

  // ---- 合法寄存器字节地址 (设备内 30 位地址) ----
  // priorityBase 0x0, pendingBase 0x1000, enableBase 0x2000 (+hart*0x80),
  // hartBase 0x200000 (+hart*0x1000)。地址低 3 位对齐到 8B beat。
  function automatic logic [29:0] pick_addr();
    case ($urandom_range(0, 7))
      0: return 30'($urandom_range(0, 16)) << 3;           // priority 区附近字
      1: return 30'h1000 | (30'($urandom_range(0,1))<<3);  // pending 字 0/1
      2: return 30'h2000 | (30'($urandom_range(0,1))<<3);  // hart0 enable 字
      3: return 30'h2080 | (30'($urandom_range(0,1))<<3);  // hart1 enable 字
      4: return 30'h200000;                                // hart0 threshold/claim
      5: return 30'h201000;                                // hart1 threshold/claim
      default: return 30'($urandom);                       // 全随机 (覆盖未命中)
    endcase
  endfunction

  // 65 路中断激励: 用 65 位向量 iv 计算分布, 再展开到各扁平端口。
  // iv[d] (d=0..63) → auto_int_in_0_d; iv[64] → auto_int_in_1_0。
  bit [64:0] iv;
  task automatic drive_ints();
    int mode;
    mode = $urandom_range(0, 4);
    case (mode)
      0: begin end                              // 全保持 (沿用上拍, 制造电平)
      1: iv[$urandom_range(0,64)] = ~iv[$urandom_range(0,64)]; // 翻转一路
      2: iv = {32'($urandom), 33'($urandom)} & {32'($urandom), 33'($urandom)}; // 稀疏
      3: iv = '1;                               // 全高
      default: iv = {32'($urandom), 33'($urandom)};          // 全随机
    endcase
    apply_iv();
  endtask

  // 把 iv 展开到 65 个扁平中断端口
  task automatic apply_iv();
    auto_int_in_0_0 = iv[0];
    auto_int_in_0_1 = iv[1];
    auto_int_in_0_2 = iv[2];
    auto_int_in_0_3 = iv[3];
    auto_int_in_0_4 = iv[4];
    auto_int_in_0_5 = iv[5];
    auto_int_in_0_6 = iv[6];
    auto_int_in_0_7 = iv[7];
    auto_int_in_0_8 = iv[8];
    auto_int_in_0_9 = iv[9];
    auto_int_in_0_10 = iv[10];
    auto_int_in_0_11 = iv[11];
    auto_int_in_0_12 = iv[12];
    auto_int_in_0_13 = iv[13];
    auto_int_in_0_14 = iv[14];
    auto_int_in_0_15 = iv[15];
    auto_int_in_0_16 = iv[16];
    auto_int_in_0_17 = iv[17];
    auto_int_in_0_18 = iv[18];
    auto_int_in_0_19 = iv[19];
    auto_int_in_0_20 = iv[20];
    auto_int_in_0_21 = iv[21];
    auto_int_in_0_22 = iv[22];
    auto_int_in_0_23 = iv[23];
    auto_int_in_0_24 = iv[24];
    auto_int_in_0_25 = iv[25];
    auto_int_in_0_26 = iv[26];
    auto_int_in_0_27 = iv[27];
    auto_int_in_0_28 = iv[28];
    auto_int_in_0_29 = iv[29];
    auto_int_in_0_30 = iv[30];
    auto_int_in_0_31 = iv[31];
    auto_int_in_0_32 = iv[32];
    auto_int_in_0_33 = iv[33];
    auto_int_in_0_34 = iv[34];
    auto_int_in_0_35 = iv[35];
    auto_int_in_0_36 = iv[36];
    auto_int_in_0_37 = iv[37];
    auto_int_in_0_38 = iv[38];
    auto_int_in_0_39 = iv[39];
    auto_int_in_0_40 = iv[40];
    auto_int_in_0_41 = iv[41];
    auto_int_in_0_42 = iv[42];
    auto_int_in_0_43 = iv[43];
    auto_int_in_0_44 = iv[44];
    auto_int_in_0_45 = iv[45];
    auto_int_in_0_46 = iv[46];
    auto_int_in_0_47 = iv[47];
    auto_int_in_0_48 = iv[48];
    auto_int_in_0_49 = iv[49];
    auto_int_in_0_50 = iv[50];
    auto_int_in_0_51 = iv[51];
    auto_int_in_0_52 = iv[52];
    auto_int_in_0_53 = iv[53];
    auto_int_in_0_54 = iv[54];
    auto_int_in_0_55 = iv[55];
    auto_int_in_0_56 = iv[56];
    auto_int_in_0_57 = iv[57];
    auto_int_in_0_58 = iv[58];
    auto_int_in_0_59 = iv[59];
    auto_int_in_0_60 = iv[60];
    auto_int_in_0_61 = iv[61];
    auto_int_in_0_62 = iv[62];
    auto_int_in_0_63 = iv[63];
    auto_int_in_1_0 = iv[64];
  endtask

  task automatic drive_random_inputs();
    drive_ints();
    auto_in_a_valid        = $urandom_range(0, 1);
    // opcode: 偏向 Get(4,读) / PutFullData(0,写) / PutPartialData(1,写)
    case ($urandom_range(0, 2))
      0: auto_in_a_bits_opcode = 4'h4;
      1: auto_in_a_bits_opcode = 4'h0;
      default: auto_in_a_bits_opcode = 4'h1;
    endcase
    auto_in_a_bits_size    = 2'h3;          // 8 字节访问
    auto_in_a_bits_source  = 15'($urandom);
    auto_in_a_bits_address = pick_addr();
    auto_in_a_bits_mask    = 8'($urandom);
    auto_in_a_bits_data    = {$urandom, $urandom};
    auto_in_d_ready        = $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_int_out_1_0)
    `CHECK(auto_int_out_0_0)
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_opcode)
    `CHECK(auto_in_d_bits_size)
    `CHECK(auto_in_d_bits_source)
    `CHECK(auto_in_d_bits_data)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    iv = '0;
    auto_int_in_1_0 = '0;
    auto_int_in_0_0 = '0;
    auto_int_in_0_1 = '0;
    auto_int_in_0_2 = '0;
    auto_int_in_0_3 = '0;
    auto_int_in_0_4 = '0;
    auto_int_in_0_5 = '0;
    auto_int_in_0_6 = '0;
    auto_int_in_0_7 = '0;
    auto_int_in_0_8 = '0;
    auto_int_in_0_9 = '0;
    auto_int_in_0_10 = '0;
    auto_int_in_0_11 = '0;
    auto_int_in_0_12 = '0;
    auto_int_in_0_13 = '0;
    auto_int_in_0_14 = '0;
    auto_int_in_0_15 = '0;
    auto_int_in_0_16 = '0;
    auto_int_in_0_17 = '0;
    auto_int_in_0_18 = '0;
    auto_int_in_0_19 = '0;
    auto_int_in_0_20 = '0;
    auto_int_in_0_21 = '0;
    auto_int_in_0_22 = '0;
    auto_int_in_0_23 = '0;
    auto_int_in_0_24 = '0;
    auto_int_in_0_25 = '0;
    auto_int_in_0_26 = '0;
    auto_int_in_0_27 = '0;
    auto_int_in_0_28 = '0;
    auto_int_in_0_29 = '0;
    auto_int_in_0_30 = '0;
    auto_int_in_0_31 = '0;
    auto_int_in_0_32 = '0;
    auto_int_in_0_33 = '0;
    auto_int_in_0_34 = '0;
    auto_int_in_0_35 = '0;
    auto_int_in_0_36 = '0;
    auto_int_in_0_37 = '0;
    auto_int_in_0_38 = '0;
    auto_int_in_0_39 = '0;
    auto_int_in_0_40 = '0;
    auto_int_in_0_41 = '0;
    auto_int_in_0_42 = '0;
    auto_int_in_0_43 = '0;
    auto_int_in_0_44 = '0;
    auto_int_in_0_45 = '0;
    auto_int_in_0_46 = '0;
    auto_int_in_0_47 = '0;
    auto_int_in_0_48 = '0;
    auto_int_in_0_49 = '0;
    auto_int_in_0_50 = '0;
    auto_int_in_0_51 = '0;
    auto_int_in_0_52 = '0;
    auto_int_in_0_53 = '0;
    auto_int_in_0_54 = '0;
    auto_int_in_0_55 = '0;
    auto_int_in_0_56 = '0;
    auto_int_in_0_57 = '0;
    auto_int_in_0_58 = '0;
    auto_int_in_0_59 = '0;
    auto_int_in_0_60 = '0;
    auto_int_in_0_61 = '0;
    auto_int_in_0_62 = '0;
    auto_int_in_0_63 = '0;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_mask = '0;
    auto_in_a_bits_data = '0;
    auto_in_d_ready = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("TLPLIC checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
