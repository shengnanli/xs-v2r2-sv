// =============================================================================
// VFixPoint64b.sv —— 向量定点指令（RVV 第 12 章）的第二级：饱和 / 平均舍入 / 缩放移位舍入 / 窄化裁剪
//
// 在哪一层：VIntFixpAlu64b 的第 2 拍。第 1 拍由 VIntAdder64b（加减器）与 VIntMisc64b（移位器）
//   算出 8 个字节的原始结果与进位/符号位（AdderToFixP / MiscToFixP），打一拍后送进本件，
//   本件按 opcode 把它们整理成最终 vd / narrowVd / vxsat。纯组合，64 位数据通路按 8 字节分片。
// 设计源：yunsuan/vector/VectorALU/VFixPoint64b.scala。
//
// 四类指令：
//   12.1 vsadd/vssub（opcode 27/28，isSatAdd）：按 SEW 判上/下溢，溢出的元素整段写饱和值。
//   12.2 vaadd/vasub（29/30）：adder 结果右移一位（高位补 9 位和的最高位 highBitAvg，或者
//        相邻高字节的 bit0），再按 vxrm 对丢掉的那一位做舍入加 1。
//   12.4 vssrl/vssra（31/32，isScalingShift）：Misc 给的移位结果 + 舍入位（rnd_high = 丢掉的最高位，
//        rnd_tail = 其余丢掉的位全 0）按 vxrm 加 1。
//   12.5 vnclip(u)：isNClip 时上面的加 1 链按 2*SEW 传进位，然后把 2*SEW 结果裁到 SEW 并报饱和。
// 舍入加 1 由子模块 Adder_chain_rnd（8 个 8 位加 1 器按 SEW 链进位）完成，它同时给出每字节
//   全 1 / 全 0 / 进位，供窄化裁剪判断高半是否"全是符号扩展"。
// 怪癖（照 golden）：
//   - sew_oneHot 是 4 位输入端口，所有 Mux1H 写成"按位与后相或"，非 one-hot 输入时结果是各项相或。
//   - 饱和值的最高位用 "highestBits"（该字节是不是元素最高字节）拼：下溢写 0x80.. / 上溢写 0x7F..。
//   - 窄化裁剪的 2*SEW 结果最高位取 dout[7] 的 bit7（32 位裁剪）或各半段最高字节的 bit7。
// 子模块：Adder_chain_rnd（本仓已签核的重写件，实例名与 golden 一致）。
// golden 对照：G1-canonical/golden-rtl/VFixPoint64b.sv
// =============================================================================
module xs_VFixPoint64b_core (
  input  logic [5:0]  opcode,
  input  logic [1:0]  vxrm,              // 定点舍入模式：0 rnu / 1 rne / 2 rdn / 3 rod
  input  logic [3:0]  sew_oh,            // {64,32,16,8} one-hot
  input  logic        is_sub,
  input  logic        is_signed,
  input  logic        is_nclip,
  input  logic [7:0]  adder_cout,        // 每字节加法进位
  input  logic [63:0] adder_vd,          // 加法结果
  input  logic [7:0]  adder_vs2h,        // 每字节 vs2 最高位
  input  logic [7:0]  adder_vs1h,        // 每字节 vs1（取反后）最高位
  input  logic [63:0] misc_shift_out,    // 移位结果
  input  logic [7:0]  misc_rnd_high,     // 每字节：被移出的最高位
  input  logic [7:0]  misc_rnd_tail,     // 每字节：被移出的其余位全 0
  output logic [63:0] vd,
  output logic [31:0] narrow_vd,
  output logic [7:0]  vxsat
);
  localparam logic [5:0] OP_VSADD = 6'd27, OP_VSSUB = 6'd28;
  localparam logic [5:0] OP_VSSRL = 6'd31, OP_VSSRA = 6'd32;

  logic is_sat_add, is_scaling_shift;
  assign is_sat_add       = (opcode == OP_VSADD) | (opcode == OP_VSSUB);
  assign is_scaling_shift = (opcode == OP_VSSRL) | (opcode == OP_VSSRA);

  logic [7:0] adder_byte [8];
  for (genvar i = 0; i < 8; i++) begin : g_split
    assign adder_byte[i] = adder_vd[i*8 +: 8];
  end

  // 4 路 Mux1H：按 sew_oh 选 {64,32,16,8} 四个候选位，非 one-hot 时相或（照 golden）
  function automatic logic mux1h_sew(input logic [3:0] oh, input logic b64, input logic b32,
                                     input logic b16, input logic b8);
    return (oh[3] & b64) | (oh[2] & b32) | (oh[1] & b16) | (oh[0] & b8);
  endfunction

  // ---- §1 饱和加减（12.1）----
  // 每字节是否溢出：有符号看"两操作数同号(减法异号)且结果变号"，无符号看进位
  logic [7:0] sat;
  for (genvar i = 0; i < 8; i++) begin : g_sat
    assign sat[i] = is_signed
      ? ((is_sub ? (adder_vs2h[i] != adder_vs1h[i]) : (adder_vs2h[i] == adder_vs1h[i]))
         & (adder_vs2h[i] != adder_byte[i][7]))
      : (adder_cout[i] ^ is_sub);
  end
  // 元素溢出 → 元素里每个字节都饱和：SEW 越宽，用最高字节的 sat 覆盖整个元素
  logic [7:0] saturate;
  assign saturate = (sew_oh[0] ? sat : 8'h0)
                  | (sew_oh[1] ? {{2{sat[7]}}, {2{sat[5]}}, {2{sat[3]}}, {2{sat[1]}}} : 8'h0)
                  | (sew_oh[2] ? {{4{sat[7]}}, {4{sat[3]}}} : 8'h0)
                  | {8{sew_oh[3] & sat[7]}};

  logic [7:0] vd_sat [8];
  for (genvar i = 0; i < 8; i++) begin : g_vdsat
    logic up_overflow_u;    // 无符号上溢（本元素最高字节有进位）
    logic down_overflow_s;  // 有符号下溢（vs2 为负）
    logic highest_byte;     // 本字节是不是元素最高字节
    assign up_overflow_u   = mux1h_sew(sew_oh, adder_cout[7], adder_cout[(i/4)*4+3],
                                       adder_cout[(i/2)*2+1], adder_cout[i]);
    assign down_overflow_s = mux1h_sew(sew_oh, adder_vs2h[7], adder_vs2h[(i/4)*4+3],
                                       adder_vs2h[(i/2)*2+1], adder_vs2h[i]);
    assign highest_byte    = mux1h_sew(sew_oh, (i == 7), (i % 4 == 3), (i % 2 == 1), 1'b1);
    assign vd_sat[i] = !saturate[i] ? adder_byte[i]
                     : is_signed    ? (down_overflow_s ? {highest_byte, 7'h00} : {~highest_byte, 7'h7F})
                                    : {8{up_overflow_u}};
  end

  // ---- §2 平均加减（12.2）：结果右移一位 + 舍入 ----
  // 9 位和的最高位（进位 ^ 减法 ^ 有符号时两操作数符号异或）
  logic [7:0] high_bit_avg;
  for (genvar i = 0; i < 8; i++) begin : g_hba
    assign high_bit_avg[i] = adder_cout[i] ^ is_sub ^ (is_signed & (adder_vs1h[i] ^ adder_vs2h[i]));
  end
  // 右移后补进来的最高位：元素最高字节用 high_bit_avg，其余字节用相邻高字节的 bit0
  logic [7:0] avg_before_rnd [8];
  logic [7:0] avg_rnd_inc;
  for (genvar i = 0; i < 8; i++) begin : g_avg
    logic next_lsb;   // 相邻高字节的 bit0（i=7 没有相邻高字节，也不会被选中）
    if (i < 7) begin : g_has_next
      assign next_lsb = adder_byte[i+1][0];
    end else begin : g_top
      assign next_lsb = 1'b0;
    end
    logic top_bit;
    assign top_bit = mux1h_sew(sew_oh,
                               (i % 8 == 7) ? high_bit_avg[i] : next_lsb,
                               (i % 4 == 3) ? high_bit_avg[i] : next_lsb,
                               (i % 2 == 1) ? high_bit_avg[i] : next_lsb,
                               high_bit_avg[i]);
    assign avg_before_rnd[i] = {top_bit, adder_byte[i][7:1]};
    // roundingInc(v, d=1)：被丢掉的位是 v[0]，v[1] 是保留的最低位
    assign avg_rnd_inc[i] = ((vxrm == 2'd0) & adder_byte[i][0])
                          | ((vxrm == 2'd1) & adder_byte[i][0] & adder_byte[i][1])
                          | ((vxrm == 2'd3) & ~adder_byte[i][1] & adder_byte[i][0]);
  end

  // ---- §3 缩放移位（12.4/12.5）的舍入位 ----
  logic [7:0] shift_rnd_inc;
  for (genvar i = 0; i < 8; i++) begin : g_shift_rnd
    logic lsb;
    assign lsb = misc_shift_out[i*8];
    assign shift_rnd_inc[i] = ((vxrm == 2'd0) & misc_rnd_high[i])
                            | ((vxrm == 2'd1) & misc_rnd_high[i] & (~misc_rnd_tail[i] | lsb))
                            | ((vxrm == 2'd3) & ~lsb & (misc_rnd_high[i] | ~misc_rnd_tail[i]));
  end

  // ---- §4 舍入加 1 链 ----
  logic [7:0] before_rnd [8];
  logic [7:0] rnd_inc;
  for (genvar i = 0; i < 8; i++) begin : g_sel
    assign before_rnd[i] = is_scaling_shift ? misc_shift_out[i*8 +: 8] : avg_before_rnd[i];
    assign rnd_inc[i]    = is_scaling_shift ? shift_rnd_inc[i] : avg_rnd_inc[i];
  end

  logic [7:0] after_rnd [8];
  logic [6:0] chain_cout;      // 字节 0..6 的进位（字节 7 的进位没有读者，golden 已消端口）
  logic [7:1] all_1s, all_0s;  // 字节 1..7 的"全 1 / 全 0"（字节 0 的没有读者）
  Adder_chain_rnd adder_chain_rnd (
    .io_din_0 (before_rnd[0]), .io_din_1 (before_rnd[1]), .io_din_2 (before_rnd[2]), .io_din_3 (before_rnd[3]),
    .io_din_4 (before_rnd[4]), .io_din_5 (before_rnd[5]), .io_din_6 (before_rnd[6]), .io_din_7 (before_rnd[7]),
    .io_rndInc_0 (rnd_inc[0]), .io_rndInc_1 (rnd_inc[1]), .io_rndInc_2 (rnd_inc[2]), .io_rndInc_3 (rnd_inc[3]),
    .io_rndInc_4 (rnd_inc[4]), .io_rndInc_5 (rnd_inc[5]), .io_rndInc_6 (rnd_inc[6]), .io_rndInc_7 (rnd_inc[7]),
    .io_isNClip    (is_nclip),
    .io_sew_oneHot (sew_oh),
    .io_dout_0 (after_rnd[0]), .io_dout_1 (after_rnd[1]), .io_dout_2 (after_rnd[2]), .io_dout_3 (after_rnd[3]),
    .io_dout_4 (after_rnd[4]), .io_dout_5 (after_rnd[5]), .io_dout_6 (after_rnd[6]), .io_dout_7 (after_rnd[7]),
    .io_cout_0 (chain_cout[0]), .io_cout_1 (chain_cout[1]), .io_cout_2 (chain_cout[2]), .io_cout_3 (chain_cout[3]),
    .io_cout_4 (chain_cout[4]), .io_cout_5 (chain_cout[5]), .io_cout_6 (chain_cout[6]),
    .io_all_1s_1 (all_1s[1]), .io_all_1s_2 (all_1s[2]), .io_all_1s_3 (all_1s[3]), .io_all_1s_4 (all_1s[4]),
    .io_all_1s_5 (all_1s[5]), .io_all_1s_6 (all_1s[6]), .io_all_1s_7 (all_1s[7]),
    .io_all_0s_1 (all_0s[1]), .io_all_0s_2 (all_0s[2]), .io_all_0s_3 (all_0s[3]), .io_all_0s_4 (all_0s[4]),
    .io_all_0s_5 (all_0s[5]), .io_all_0s_6 (all_0s[6]), .io_all_0s_7 (all_0s[7])
  );

  logic [63:0] after_rnd_flat;
  for (genvar i = 0; i < 8; i++) begin : g_flat
    assign after_rnd_flat[i*8 +: 8] = after_rnd[i];
  end

  // ---- §5 窄化裁剪（12.5）：2*SEW → SEW ----
  // 高半是否只是低半的符号扩展（有符号）/ 全 0（无符号）。hi_all_0s/hi_all_1s 是高半各字节
  // 加 1 之前的全 0/全 1，cout 是低半向高半的进位（加 1 之后高半 = 原高半 + cout）。
  function automatic logic clip_keep_signed(input logic hi_all_1s, input logic hi_all_0s,
                                            input logic cout, input logic low_top);
    return (hi_all_0s & ~cout & ~low_top) | (hi_all_1s & (cout | (~cout & low_top)));
  endfunction
  function automatic logic clip_keep_unsigned(input logic hi_all_0s, input logic cout);
    return hi_all_0s & ~cout;
  endfunction

  // 32 位裁剪（SEW=32，64→32）
  logic keep32;
  logic [31:0] clip32;
  logic sat32;
  assign keep32 = is_signed
    ? clip_keep_signed(&all_1s[7:4], &all_0s[7:4], chain_cout[3], after_rnd[3][7])
    : clip_keep_unsigned(&all_0s[7:4], chain_cout[3]);
  assign clip32 = keep32 ? after_rnd_flat[31:0]
                : is_signed ? {after_rnd[7][7], {31{~after_rnd[7][7]}}} : 32'hFFFF_FFFF;
  assign sat32  = ~keep32;

  // 16 位裁剪 ×2（SEW=16，每 32 位段 → 16 位）
  logic [1:0]  keep16, sat16;
  logic [15:0] clip16 [2];
  for (genvar k = 0; k < 2; k++) begin : g_clip16
    assign keep16[k] = is_signed
      ? clip_keep_signed(all_1s[k*4+2] & all_1s[k*4+3], all_0s[k*4+2] & all_0s[k*4+3],
                         chain_cout[k*4+1], after_rnd[k*4+1][7])
      : clip_keep_unsigned(all_0s[k*4+2] & all_0s[k*4+3], chain_cout[k*4+1]);
    assign clip16[k] = keep16[k] ? after_rnd_flat[k*32 +: 16]
                     : is_signed ? {after_rnd[k*4+3][7], {15{~after_rnd[k*4+3][7]}}} : 16'hFFFF;
    assign sat16[k]  = ~keep16[k];
  end

  // 8 位裁剪 ×4（SEW=8，每 16 位段 → 8 位）
  logic [3:0] keep8, sat8;
  logic [7:0] clip8 [4];
  for (genvar k = 0; k < 4; k++) begin : g_clip8
    assign keep8[k] = is_signed
      ? clip_keep_signed(all_1s[k*2+1], all_0s[k*2+1], chain_cout[k*2], after_rnd[k*2][7])
      : clip_keep_unsigned(all_0s[k*2+1], chain_cout[k*2]);
    assign clip8[k] = keep8[k] ? after_rnd[k*2]
                    : is_signed ? {after_rnd[k*2+1][7], {7{~after_rnd[k*2+1][7]}}} : 8'hFF;
    assign sat8[k]  = ~keep8[k];
  end

  logic [3:0] nclip_sat;
  assign narrow_vd = (sew_oh[2] ? clip32 : 32'h0)
                   | (sew_oh[1] ? {clip16[1], clip16[0]} : 32'h0)
                   | (sew_oh[0] ? {clip8[3], clip8[2], clip8[1], clip8[0]} : 32'h0);
  assign nclip_sat = {4{sew_oh[2] & sat32}}
                   | (sew_oh[1] ? {{2{sat16[1]}}, {2{sat16[0]}}} : 4'h0)
                   | (sew_oh[0] ? sat8 : 4'h0);

  // ---- §6 输出 ----
  assign vxsat = is_nclip   ? {4'h0, nclip_sat}
               : is_sat_add ? saturate : 8'h0;
  for (genvar i = 0; i < 8; i++) begin : g_vd
    assign vd[i*8 +: 8] = is_sat_add ? vd_sat[i] : after_rnd[i];
  end
endmodule

module VFixPoint64b (
  input  logic [5:0]  io_opcode_op,
  input  logic [1:0]  io_info_vxrm,
  input  logic [3:0]  io_sew_oneHot,
  input  logic        io_isSub,
  input  logic        io_isSigned,
  input  logic        io_isNClip,
  input  logic        io_fromAdder_cout_0,
  input  logic        io_fromAdder_cout_1,
  input  logic        io_fromAdder_cout_2,
  input  logic        io_fromAdder_cout_3,
  input  logic        io_fromAdder_cout_4,
  input  logic        io_fromAdder_cout_5,
  input  logic        io_fromAdder_cout_6,
  input  logic        io_fromAdder_cout_7,
  input  logic [7:0]  io_fromAdder_vd_0,
  input  logic [7:0]  io_fromAdder_vd_1,
  input  logic [7:0]  io_fromAdder_vd_2,
  input  logic [7:0]  io_fromAdder_vd_3,
  input  logic [7:0]  io_fromAdder_vd_4,
  input  logic [7:0]  io_fromAdder_vd_5,
  input  logic [7:0]  io_fromAdder_vd_6,
  input  logic [7:0]  io_fromAdder_vd_7,
  input  logic        io_fromAdder_vs2H_0,
  input  logic        io_fromAdder_vs2H_1,
  input  logic        io_fromAdder_vs2H_2,
  input  logic        io_fromAdder_vs2H_3,
  input  logic        io_fromAdder_vs2H_4,
  input  logic        io_fromAdder_vs2H_5,
  input  logic        io_fromAdder_vs2H_6,
  input  logic        io_fromAdder_vs2H_7,
  input  logic        io_fromAdder_vs1H_0,
  input  logic        io_fromAdder_vs1H_1,
  input  logic        io_fromAdder_vs1H_2,
  input  logic        io_fromAdder_vs1H_3,
  input  logic        io_fromAdder_vs1H_4,
  input  logic        io_fromAdder_vs1H_5,
  input  logic        io_fromAdder_vs1H_6,
  input  logic        io_fromAdder_vs1H_7,
  input  logic [63:0] io_fromMisc_shiftOut,
  input  logic [7:0]  io_fromMisc_rnd_high,
  input  logic [7:0]  io_fromMisc_rnd_tail,
  output logic [63:0] io_vd,
  output logic [31:0] io_narrowVd,
  output logic [7:0]  io_vxsat
);
  xs_VFixPoint64b_core u_core (
    .opcode         (io_opcode_op),
    .vxrm           (io_info_vxrm),
    .sew_oh         (io_sew_oneHot),
    .is_sub         (io_isSub),
    .is_signed      (io_isSigned),
    .is_nclip       (io_isNClip),
    .adder_cout     ({io_fromAdder_cout_7, io_fromAdder_cout_6, io_fromAdder_cout_5, io_fromAdder_cout_4,
                      io_fromAdder_cout_3, io_fromAdder_cout_2, io_fromAdder_cout_1, io_fromAdder_cout_0}),
    .adder_vd       ({io_fromAdder_vd_7, io_fromAdder_vd_6, io_fromAdder_vd_5, io_fromAdder_vd_4,
                      io_fromAdder_vd_3, io_fromAdder_vd_2, io_fromAdder_vd_1, io_fromAdder_vd_0}),
    .adder_vs2h     ({io_fromAdder_vs2H_7, io_fromAdder_vs2H_6, io_fromAdder_vs2H_5, io_fromAdder_vs2H_4,
                      io_fromAdder_vs2H_3, io_fromAdder_vs2H_2, io_fromAdder_vs2H_1, io_fromAdder_vs2H_0}),
    .adder_vs1h     ({io_fromAdder_vs1H_7, io_fromAdder_vs1H_6, io_fromAdder_vs1H_5, io_fromAdder_vs1H_4,
                      io_fromAdder_vs1H_3, io_fromAdder_vs1H_2, io_fromAdder_vs1H_1, io_fromAdder_vs1H_0}),
    .misc_shift_out (io_fromMisc_shiftOut),
    .misc_rnd_high  (io_fromMisc_rnd_high),
    .misc_rnd_tail  (io_fromMisc_rnd_tail),
    .vd             (io_vd),
    .narrow_vd      (io_narrowVd),
    .vxsat          (io_vxsat)
  );
endmodule
