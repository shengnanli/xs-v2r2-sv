// =============================================================================
// xs_Bku —— 香山 V2R2（昆明湖）位操作 / 加密功能单元
//
// 对应 Chisel: xiangshan.backend.fu.Bku（class Bku，latency=2，HasPipelineReg）
// 及其四个子单元 CountModule / ClmulModule / MiscModule / CryptoModule
// （CryptoModule 内含 HashModule + BlockCipherModule）。
//
// 位置：整数执行簇 (ExuBlock) 中的一个叶子 FU。负责 RISC-V 位操作/密码扩展中
//       “需要专用数据通路、不便走普通 ALU”的那部分：
//         · Zbc  无进位乘 clmul/clmulh/clmulr
//         · Zbb  计数  clz/ctz/cpop（含 32 位 .w 变体）
//         · Zbkx 字节置换 xperm.n / xperm.b
//         · Zknh sha256/sha512 的 Σ/σ
//         · Zksh sm3 的 P0/P1
//         · Zkne/Zknd aes64 加解密轮 + 密钥扩展
//         · Zksed sm4 加解密 + 密钥扩展
//       （普通 Zbb/Zbs 的 and/or/min/max/bset 等在 Alu 里，不在此。）
//
// ---------------------------------------------------------------------------
// 流水时序（2 拍，固定延迟）：
//
//   in.fire (cyc0)                  cyc1                       cyc2
//   ┌──────────────┐  regEn(1) ┌──────────────┐  regEn(2) ┌──────────┐
//   │ stage0 组合   │─────────▶│ 子单元内部级寄  │─────────▶│ 输出寄存  │─▶ out
//   │ (各子单元前半) │          │ + stage1 组合  │          │ res.data │
//   └──────────────┘          │ + 顶层 result  │          └──────────┘
//                              │   mux (组合)   │
//                              └──────────────┘
//
//   · 子单元 io_reg_en = regEnable(1) = valid 在第 1 级有效，拍入各子单元的
//     中间寄存器（count 的 c2/cpop、clmul 的 mul3、misc/hash 的输出寄、
//     cipher 的 sbox 中间寄）。
//   · 顶层 func_reg 同样在 in.fire 拍入，用于 cyc1 选出哪个子单元结果。
//   · 顶层输出寄存器 res_data 用 regEnable(2) 拍入 cyc1 选好的 result。
//   · 控制信息（robIdx/pdest/rfWen）与 perf 计时沿用上游已打好的 validPipe/
//     ctrlPipe（外部 datapath 提供），本核只做 valid 的两级打拍与透传。
//
// 注：本核的 reg_en_s1 / reg_en_s2 即 Chisel regEnable(1)/regEnable(2)；因
//     Bku 的 io.out.ready 未引出（恒就绪），rdyVec 恒 1，故 regEnable(i) 退化
//     为 validVec(i-1) = validPipe(i-1) & validThisFu(i-1)。
// ---------------------------------------------------------------------------
// 注意：本文件是“从设计意图重写”的可读实现，命名/结构与 firtool golden 不同；
//       顶层扁平端口的适配见 Bku_wrapper.sv。
// =============================================================================

// -----------------------------------------------------------------------------
// 子单元 1：计数 (Zbb) —— clz / ctz / cpop（含 .w）
//
// 设计意图（对应 CountModule）：
//   · 前导/尾随零计数用“分治归约树”：把 64 位看成 32 个 2-bit 组，逐级两两合并，
//     每级把相邻两段的零计数拼起来（clzi）。ctz 通过先 Reverse(src) 复用 clz 树。
//   · cpop 用四个 16-bit 段各自 PopCount，再两级相加。
//   · 树在中间打一拍（c2 / cpop_tmp），把组合深度切成两半，满足 1 拍内完成。
//   · .w 变体只取低 32 位的子树结果（c4[0] / cpop_lo32）。
//
//   func 位用法：func[1]=方向（1→clz 反转成 ctz）；func[0]=.w；func[2]=cpop。
// -----------------------------------------------------------------------------
module xs_bku_count
  import xs_bku_pkg::*;
(
  input  logic        clock,
  input  logic [63:0] src,
  input  logic [8:0]  func,
  input  logic        reg_en,   // = regEnable(1)
  output logic [63:0] out
);
  // 2-bit 组编码：00→2（两个零）, 01→1（一个零）, 1x→0。
  function automatic logic [1:0] enc2(input logic [1:0] b);
    return (b == 2'b00) ? 2'd2 : (b == 2'b01) ? 2'd1 : 2'd0;
  endfunction

  // clzi：合并相邻两段的前导零计数树。left 为高段，right 为低段，各为 (msb+1) 位。
  //   · left 最高位=0（高段未全零）→ 计数就在高段里，直接用 left（高位补 0）。
  //   · left 最高位=1（高段全零，达到饱和 2^msb）→ 计数 = 高段全数 + 低段前缀：
  //       {both_sat, ~right[msb], right[msb-1:0]}
  //     其中 both_sat = 两段都全零（再进一位）；~right[msb] 表示低段是否也饱和。
  //   返回 (msb+2) 位，高位补 0 便于统一用 logic[63:0] 承接（调用处按需截位）。
  function automatic logic [63:0] clzi(input int msb,
                                       input logic [63:0] left,
                                       input logic [63:0] right);
    logic        left_msb, right_msb, both_sat, low_sat;
    logic [63:0] low_mask;
    left_msb  = left[msb];
    right_msb = right[msb];
    both_sat  = left_msb & right_msb;           // 两段都饱和 → 进位
    low_sat   = ~right_msb;                      // 低段是否也饱和
    low_mask  = (64'h1 << msb) - 64'h1;          // 取 right[msb-1:0]，保持原位
    if (left_msb)
      return (64'(both_sat) << (msb + 1))
           | (64'(low_sat)  << msb)
           | (right & low_mask);                // 低段前导计数
    else
      return left;
  endfunction

  // ---- stage 0 (组合) ----
  // ctz：func[1] 选择对 src 做位翻转，再走同一棵 clz 树。
  logic [63:0] count_src;
  logic [1:0]  c0 [0:31];
  logic [2:0]  c1 [0:15];
  genvar gi;

  always_comb begin
    count_src = func[1] ? {<<{src}} : src; // {<<{}} = Reverse
    for (int i = 0; i < 32; i++) c0[i] = enc2(count_src[2*i+1 -: 2]);
    for (int i = 0; i < 16; i++) c1[i] = 3'(clzi(1, {61'b0, c0[2*i+1]}, {61'b0, c0[2*i]}));
  end

  // ---- 中间级寄存器（regEnable 拍入）----
  logic [8:0]  func_reg;
  logic [3:0]  c2 [0:7];
  logic [4:0]  cpop_tmp [0:3];

  always_ff @(posedge clock) begin
    if (reg_en) begin
      func_reg <= func;
      for (int i = 0; i < 8; i++)
        c2[i] <= 4'(clzi(2, {60'b0, c1[2*i+1]}, {60'b0, c1[2*i]}));
      // 四个 16-bit 段各自 popcount
      for (int i = 0; i < 4; i++)
        cpop_tmp[i] <= 5'($countones(src[i*16 +: 16]));
    end
  end

  // ---- stage 1 (组合) ----
  logic [4:0] c3 [0:3];
  logic [5:0] c4 [0:1];
  logic [6:0] zero_res;                 // 64 位前导/尾随零最大计数 = 64，需 7 位
  logic [5:0] zero_wres;
  logic [6:0] cpop_lo32, cpop_hi32, cpop_res;
  logic [5:0] cpop_wres;

  always_comb begin
    for (int i = 0; i < 4; i++) c3[i] = 5'(clzi(3, {59'b0, c2[2*i+1]}, {59'b0, c2[2*i]}));
    for (int i = 0; i < 2; i++) c4[i] = 6'(clzi(4, {58'b0, c3[2*i+1]}, {58'b0, c3[2*i]}));
    zero_res  = 7'(clzi(5, {58'b0, c4[1]}, {58'b0, c4[0]}));
    zero_wres = func_reg[1] ? c4[1] : c4[0];   // .w：clz 取高段、ctz 取低段

    cpop_lo32 = cpop_tmp[0] + cpop_tmp[1];
    cpop_hi32 = cpop_tmp[2] + cpop_tmp[3];
    cpop_res  = cpop_lo32 + cpop_hi32;
    cpop_wres = cpop_lo32[5:0];

    // func[2]=cpop ? (func[0]=.w ? cpopw : cpop) : (func[0]=.w ? clzw/ctzw : clz/ctz)
    out = func_reg[2] ? (func_reg[0] ? {58'b0, cpop_wres} : {57'b0, cpop_res})
                      : (func_reg[0] ? {58'b0, zero_wres} : {57'b0, zero_res});
  end
endmodule

// -----------------------------------------------------------------------------
// 子单元 2：无进位乘 (Zbc) —— clmul / clmulh / clmulr
//
// 设计意图（对应 ClmulModule）：
//   无进位乘 = GF(2) 上的多项式乘：result = XOR_i ( src1[i] ? (src2 << i) : 0 )。
//   64×64→128 的 64 个移位部分积用平衡 XOR 归约树相加（无进位即异或），
//   树在第 4 级（mul3，8×128）打一拍切分组合深度。
//   · clmul  取低 64 位 res[63:0]
//   · clmulh 取高 64 位 res[127:64]
//   · clmulr 取中间 res[126:63]（位反转对称乘）
// -----------------------------------------------------------------------------
module xs_bku_clmul
  import xs_bku_pkg::*;
(
  input  logic         clock,
  input  logic [63:0]  src1,
  input  logic [63:0]  src2,
  input  logic [8:0]   func,
  input  logic         reg_en,
  output logic [63:0]  out
);
  // ---- stage 0 (组合)：部分积 + 前三级归约 ----
  logic [127:0] mul0 [0:63];
  logic [127:0] mul1 [0:31];
  logic [127:0] mul2 [0:15];

  always_comb begin
    for (int i = 0; i < 64; i++)
      mul0[i] = src1[i] ? ({64'b0, src2} << i) : 128'b0;
    for (int i = 0; i < 32; i++) mul1[i] = mul0[2*i] ^ mul0[2*i+1];
    for (int i = 0; i < 16; i++) mul2[i] = mul1[2*i] ^ mul1[2*i+1];
  end

  // ---- 中间级寄存器：第 4 级归约 + func ----
  logic [8:0]   func_reg;
  logic [127:0] mul3 [0:7];

  always_ff @(posedge clock) begin
    if (reg_en) begin
      func_reg <= func;
      for (int i = 0; i < 8; i++) mul3[i] <= mul2[2*i] ^ mul2[2*i+1];
    end
  end

  // ---- stage 1 (组合)：剩余归约 + 取段 ----
  // 用 9 位 func_reg 整字比较（与 Chisel LookupTreeDefault 一致），默认 clmul。
  logic [127:0] res;
  always_comb begin
    res = 128'b0;
    for (int i = 0; i < 8; i++) res ^= mul3[i];
    if      (func_reg == {3'b0, OP_CLMULH}) out = res[127:64];
    else if (func_reg == {3'b0, OP_CLMULR}) out = res[126:63];
    else                                    out = res[63:0];  // clmul 及其他
  end
endmodule

// -----------------------------------------------------------------------------
// 子单元 3：字节/半字节置换 (Zbkx) —— xperm.n / xperm.b
//
// 设计意图（对应 MiscModule）：
//   把 src1 看成查找表（xperm.n 是 16 个 4-bit 项，xperm.b 是 8 个 8-bit 项），
//   src2 的每个 nibble/byte 作为索引，从表中取出对应项拼成结果。
//   · xperm.b 的索引若高位越界（idx ≥ 8，即 src2[byte][7:3] 非零）则输出 0。
//   输出整体打一拍（regEnable）。
// -----------------------------------------------------------------------------
module xs_bku_misc
  import xs_bku_pkg::*;
(
  input  logic         clock,
  input  logic [63:0]  src1,
  input  logic [63:0]  src2,
  input  logic [8:0]   func,
  input  logic         reg_en,
  output logic [63:0]  out
);
  // 从 src1 的查找表里按 width 位项取 idx 项；越界（idx*width ≥ 64）返回 0。
  function automatic logic [7:0] xperm_lut4(input logic [63:0] tbl, input logic [3:0] idx);
    logic [7:0] r;
    r = 8'b0;
    for (int i = 0; i < 16; i++) if (4'(i) == idx) r = {4'b0, tbl[i*4 +: 4]};
    return r;
  endfunction
  function automatic logic [7:0] xperm_lut8(input logic [63:0] tbl, input logic [2:0] idx);
    logic [7:0] r;
    r = 8'b0;
    for (int i = 0; i < 8; i++) if (3'(i) == idx) r = tbl[i*8 +: 8];
    return r;
  endfunction

  logic [63:0] xpermn, xpermb;
  logic [63:0] result_comb;

  always_comb begin
    for (int i = 0; i < 16; i++)
      xpermn[i*4 +: 4] = 4'(xperm_lut4(src1, src2[i*4 +: 4]));
    for (int i = 0; i < 8; i++)
      xpermb[i*8 +: 8] = (|src2[i*8+3 +: 5]) ? 8'b0 : xperm_lut8(src1, src2[i*8 +: 3]);
    result_comb = func[0] ? xpermb : xpermn; // func[0]=1 → xperm.b
  end

  always_ff @(posedge clock) if (reg_en) out <= result_comb;
endmodule

// -----------------------------------------------------------------------------
// 子单元 4a：哈希 (Zknh/Zksh) —— sha256/sha512 的 Σ/σ + sm3 的 P0/P1
//
// 设计意图（对应 HashModule）：
//   这些都是“若干循环右移与右移的异或”，直接按规范公式列出。
//   sha256 与 sm3 结果是 32 位、符号扩展到 64 位；sha512 是 64 位。
//   func[2:0] 在 sha 内选 8 个之一；func[0] 在 sm3 内选 P0/P1；func[3]=sm3。
//   输出整体打一拍。
// -----------------------------------------------------------------------------
module xs_bku_hash
  import xs_bku_pkg::*;
(
  input  logic         clock,
  input  logic [63:0]  src,
  input  logic [8:0]   func,
  input  logic         reg_en,
  output logic [63:0]  out
);
  logic [63:0] sha [0:7];
  logic [63:0] sm3, sha_sel, result_comb;
  logic [63:0] t256_0, t256_1, t256_2, t256_3;  // sha256 各项中间值（取低 32 位再符扩）
  logic [63:0] tsm3_0, tsm3_1;

  always_comb begin
    t256_0 = ror32(src, 2)  ^ ror32(src, 13) ^ ror32(src, 22);
    t256_1 = ror32(src, 6)  ^ ror32(src, 11) ^ ror32(src, 25);
    t256_2 = ror32(src, 7)  ^ ror32(src, 18) ^ shr32(src, 3);
    t256_3 = ror32(src, 17) ^ ror32(src, 19) ^ shr32(src, 10);
    sha[0] = sext32(t256_0[31:0]); // sha256sum0
    sha[1] = sext32(t256_1[31:0]); // sha256sum1
    sha[2] = sext32(t256_2[31:0]); // sha256sig0
    sha[3] = sext32(t256_3[31:0]); // sha256sig1
    sha[4] = ror64(src, 28) ^ ror64(src, 34) ^ ror64(src, 39); // sha512sum0
    sha[5] = ror64(src, 14) ^ ror64(src, 18) ^ ror64(src, 41); // sha512sum1
    sha[6] = ror64(src, 1)  ^ ror64(src, 8)  ^ shr64(src, 7);  // sha512sig0
    sha[7] = ror64(src, 19) ^ ror64(src, 61) ^ shr64(src, 6);  // sha512sig1
    sha_sel = sha[func[2:0]];

    // sm3 P0/P1：x ^ 两个循环右移 的异或，取低 32 位符号扩展
    tsm3_0 = ror32(src, 23) ^ ror32(src, 15) ^ src; // sm3p0
    tsm3_1 = ror32(src, 9)  ^ ror32(src, 17) ^ src; // sm3p1
    sm3 = func[0] ? sext32(tsm3_1[31:0]) : sext32(tsm3_0[31:0]);

    result_comb = func[3] ? sm3 : sha_sel;
  end

  always_ff @(posedge clock) if (reg_en) out <= result_comb;
endmodule

// -----------------------------------------------------------------------------
// 子单元 4b：分组密码 (Zkne/Zknd/Zksed) —— aes64* + sm4*
//
// 设计意图（对应 BlockCipherModule）：
//   把 {src1,src2} 拆成字节，按指令做 ShiftRows / SubBytes(S-box) /
//   MixColumns / 密钥扩展。S-box 三段中“Inv 求逆”级打一拍（mid 寄存器），
//   故本子单元天然 1 拍延迟；输出按 func 组合选出。
//   func[3]=1 → SM4，否则 AES；AES 内用 func_reg 区分 7 个 aes64* 操作。
// -----------------------------------------------------------------------------
module xs_bku_cipher
  import xs_bku_pkg::*;
(
  input  logic         clock,
  input  logic [63:0]  src1,
  input  logic [63:0]  src2,
  input  logic [8:0]   func,
  input  logic         reg_en,
  output logic [63:0]  out
);
  // 字节视图
  logic [7:0] s1b [0:7];
  logic [7:0] s2b [0:7];
  always_comb for (int i = 0; i < 8; i++) begin
    s1b[i] = src1[i*8 +: 8];
    s2b[i] = src2[i*8 +: 8];
  end

  logic [8:0] func_reg;
  always_ff @(posedge clock) if (reg_en) func_reg <= func;

  // ---- AES SubBytes：ShiftRows 选字节 → S-box（Inv 级打拍）----
  // ForwardShiftRows / InverseShiftRows：从 {src1,src2} 字节里按固定置换取 8 字节。
  logic [7:0] fsr [0:7];   // 正向 ShiftRows 选出的字节
  logic [7:0] isr [0:7];   // 逆向 ShiftRows 选出的字节
  always_comb begin
    fsr = '{s1b[0], s1b[5], s2b[2], s2b[7], s1b[4], s2b[1], s2b[6], s1b[3]};
    isr = '{s1b[0], s2b[5], s2b[2], s1b[7], s1b[4], s1b[1], s2b[6], s2b[3]};
  end

  logic [17:0] aes_mid  [0:7];   // 正向 S-box Inv 级寄存
  logic [17:0] iaes_mid [0:7];   // 逆向 S-box Inv 级寄存
  logic [7:0]  aes_sb   [0:7];
  logic [7:0]  iaes_sb  [0:7];
  logic [7:0]  im_in    [0:7];   // aes64im 用：src1 字节打拍

  always_ff @(posedge clock) if (reg_en) begin
    for (int i = 0; i < 8; i++) begin
      aes_mid[i]  <= sbox_inv(sbox_aes_top(fsr[i]));
      iaes_mid[i] <= sbox_inv(sbox_iaes_top(isr[i]));
      im_in[i]    <= s1b[i];
    end
  end
  always_comb for (int i = 0; i < 8; i++) begin
    aes_sb[i]  = sbox_aes_out(aes_mid[i]);
    iaes_sb[i] = sbox_iaes_out(iaes_mid[i]);
  end

  logic [63:0] aes64es, aes64ds, aes64esm, aes64dsm, aes64im;
  always_comb begin
    aes64es  = {aes_sb[7], aes_sb[6], aes_sb[5], aes_sb[4],
                aes_sb[3], aes_sb[2], aes_sb[1], aes_sb[0]};
    aes64ds  = {iaes_sb[7], iaes_sb[6], iaes_sb[5], iaes_sb[4],
                iaes_sb[3], iaes_sb[2], iaes_sb[1], iaes_sb[0]};
    aes64esm = {aes_mix_fwd(aes_sb[4], aes_sb[5], aes_sb[6], aes_sb[7]),
                aes_mix_fwd(aes_sb[0], aes_sb[1], aes_sb[2], aes_sb[3])};
    aes64dsm = {aes_mix_inv(iaes_sb[4], iaes_sb[5], iaes_sb[6], iaes_sb[7]),
                aes_mix_inv(iaes_sb[0], iaes_sb[1], iaes_sb[2], iaes_sb[3])};
    aes64im  = {aes_mix_inv(im_in[4], im_in[5], im_in[6], im_in[7]),
                aes_mix_inv(im_in[0], im_in[1], im_in[2], im_in[3])};
  end

  // ---- AES 密钥扩展 ks1i / ks2 ----
  // Rcon 轮常量表：合法 rnum 为 0..0xa（10），其中 idx==0xa 返回 0x00。
  // idx 11..15 是非法值（Chisel Vec 长度 11，越界由 firtool 填充为 0x01），
  // 为与 golden 逐位等价，这里同样对越界返回 0x01。
  function automatic logic [7:0] rcon(input logic [3:0] idx);
    case (idx)
      4'h0: return 8'h01; 4'h1: return 8'h02; 4'h2: return 8'h04; 4'h3: return 8'h08;
      4'h4: return 8'h10; 4'h5: return 8'h20; 4'h6: return 8'h40; 4'h7: return 8'h80;
      4'h8: return 8'h1b; 4'h9: return 8'h36; 4'ha: return 8'h00;
      default: return 8'h01;   // 越界 (0xb..0xf)：与 golden 填充一致
    endcase
  endfunction

  // ks1i：rnum==a 时旋转 SubWord，否则不旋转；SubWord 走 AES 正向 S-box（含 Inv 打拍）
  logic [7:0]  ks_in  [0:3];
  logic [20:0] ks_top [0:3];
  logic [7:0]  ks_out [0:3];
  logic        rnum_is_a;
  always_comb begin
    rnum_is_a = (src2[3:0] == 4'ha);
    ks_in[0] = rnum_is_a ? s1b[4] : s1b[5];
    ks_in[1] = rnum_is_a ? s1b[5] : s1b[6];
    ks_in[2] = rnum_is_a ? s1b[6] : s1b[7];
    ks_in[3] = rnum_is_a ? s1b[7] : s1b[4];
  end
  always_ff @(posedge clock) if (reg_en)
    for (int i = 0; i < 4; i++) ks_top[i] <= sbox_aes_top(ks_in[i]);
  always_comb for (int i = 0; i < 4; i++) ks_out[i] = sbox_aes_out(sbox_inv(ks_top[i]));

  logic [3:0]  ks1_idx;
  logic [31:0] ks_word;
  logic [63:0] aes64ks1i;
  always_ff @(posedge clock) if (reg_en) ks1_idx <= src2[3:0];
  always_comb begin
    // Rcon 仅异或进最低字节（与 Chisel: 32位 SubWord ^ 8位 rcon 的零扩展一致）
    ks_word   = {ks_out[3], ks_out[2], ks_out[1], ks_out[0]} ^ {24'b0, rcon(ks1_idx)};
    aes64ks1i = {ks_word, ks_word};
  end

  // ks2：两段异或，整体打拍
  logic [63:0] aes64ks2;
  logic [31:0] ks2_lo;
  always_comb ks2_lo = src1[63:32] ^ src2[31:0];
  logic [63:0] ks2_comb;
  always_comb ks2_comb = {ks2_lo ^ src2[63:32], ks2_lo};
  always_ff @(posedge clock) if (reg_en) aes64ks2 <= ks2_comb;

  logic [63:0] aes_result;
  // 9 位整字比较选 aes 结果（与 Chisel LookupTreeDefault 一致，默认 aes64es）
  always_comb begin
    if      (func_reg == {3'b0, OP_AES64KS2})  aes_result = aes64ks2;
    else if (func_reg == {3'b0, OP_AES64KS1I}) aes_result = aes64ks1i;
    else if (func_reg == {3'b0, OP_AES64IM})   aes_result = aes64im;
    else if (func_reg == {3'b0, OP_AES64DSM})  aes_result = aes64dsm;
    else if (func_reg == {3'b0, OP_AES64DS})   aes_result = aes64ds;
    else if (func_reg == {3'b0, OP_AES64ESM})  aes_result = aes64esm;
    else                                       aes_result = aes64es; // es 及其他
  end

  // ---- SM4：单字节 S-box（Inv 级打拍）→ 加解密/密钥扩展线性扩散 ----
  // 输入字节由 func[1:0] (bs) 选 src2 的某字节
  logic [7:0]  sm4_in;
  logic [20:0] sm4_top;
  logic [7:0]  sm4_sb;
  always_comb sm4_in = s2b[func[1:0]];
  always_ff @(posedge clock) if (reg_en) sm4_top <= sbox_sm4_top(sm4_in);
  always_comb sm4_sb = sbox_sm4_out(sbox_inv(sm4_top));

  // SM4 加解密扩散 L、密钥扩展扩散 L'（32 位，源里用移位异或表达）
  logic [31:0] sm4ed, sm4ks;
  logic [31:0] sm4b;          // sbox 字节零扩展到 32 位
  always_comb begin
    sm4b  = {24'b0, sm4_sb};
    sm4ed = sm4b ^ (sm4b << 8) ^ (sm4b << 2) ^ (sm4b << 18)
          ^ ((sm4b & 32'h3f) << 26) ^ ((sm4b & 32'hc0) << 10);
    sm4ks = sm4b ^ ((sm4b & 32'h07) << 29) ^ ((sm4b & 32'hfe) << 7)
          ^ ((sm4b & 32'h01) << 23) ^ ((sm4b & 32'hf8) << 13);
  end

  // 按 bs (func_reg[2:0] 低 2 位 = 旋转字节数；bit2 = ks/ed) 旋转选项
  logic [31:0] sm4_src [0:7];
  always_comb begin
    sm4_src[0] = sm4ed;
    sm4_src[1] = {sm4ed[23:0], sm4ed[31:24]};
    sm4_src[2] = {sm4ed[15:0], sm4ed[31:16]};
    sm4_src[3] = {sm4ed[7:0],  sm4ed[31:8]};
    sm4_src[4] = sm4ks;
    sm4_src[5] = {sm4ks[23:0], sm4ks[31:24]};
    sm4_src[6] = {sm4ks[15:0], sm4ks[31:16]};
    sm4_src[7] = {sm4ks[7:0],  sm4ks[31:8]};
  end

  logic [31:0] sm4_x0;        // src1 低 32 位打拍，与扩散结果异或
  always_ff @(posedge clock) if (reg_en) sm4_x0 <= src1[31:0];
  logic [63:0] sm4_result;
  always_comb sm4_result = sext32(sm4_src[func_reg[2:0]] ^ sm4_x0);

  always_comb out = func_reg[3] ? sm4_result : aes_result;
endmodule

// -----------------------------------------------------------------------------
// 子单元 4：CryptoModule —— hash 与 block-cipher 的二选一
//   func[4]=1 → hash（sha/sm3），否则 block-cipher（aes/sm4）。
// -----------------------------------------------------------------------------
module xs_bku_crypto
  import xs_bku_pkg::*;
(
  input  logic         clock,
  input  logic [63:0]  src1,
  input  logic [63:0]  src2,
  input  logic [8:0]   func,
  input  logic         reg_en,
  output logic [63:0]  out
);
  logic [8:0]  func_reg;
  logic [63:0] hash_out, cipher_out;

  always_ff @(posedge clock) if (reg_en) func_reg <= func;

  xs_bku_hash u_hash (
    .clock(clock), .src(src1), .func(func), .reg_en(reg_en), .out(hash_out)
  );
  xs_bku_cipher u_cipher (
    .clock(clock), .src1(src1), .src2(src2), .func(func), .reg_en(reg_en), .out(cipher_out)
  );

  always_comb out = func_reg[4] ? hash_out : cipher_out;
endmodule

// =============================================================================
// 可读核：xs_Bku_core
//   集成四个子单元 + 顶层结果选择 + valid/ctrl/perf 流水透传。
//   端口用打包好的结构体，wrapper 负责与 golden 扁平端口对接。
// =============================================================================

// 控制信息（随指令一起在流水里走，本核仅透传上游已打好的 ctrlPipe(2)）
typedef struct packed {
  logic        robIdx_flag;
  logic [7:0]  robIdx_value;
  logic [7:0]  pdest;
  logic        rfWen;
} bku_ctrl_t;

// perf 计时信息（3×64 位，随流水打两拍）
typedef struct packed {
  logic [63:0] enqRsTime;
  logic [63:0] selectTime;
  logic [63:0] issueTime;
} bku_perf_t;

module xs_Bku_core
  import xs_bku_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // 输入握手与 payload
  input  logic        in_valid,
  input  logic [8:0]  in_fuOpType,
  input  logic [63:0] in_src0,
  input  logic [63:0] in_src1,
  input  bku_perf_t   in_perf,
  // 上游 datapath 预先打好的逐级 valid（validPipe）与第 2 级控制（ctrlPipe(2)）
  input  logic        in_validPipe0,
  input  logic        in_validPipe1,
  input  logic        in_validPipe2,
  input  bku_ctrl_t   in_ctrlPipe2,

  // 输出
  output logic        out_valid,
  output bku_ctrl_t   out_ctrl,
  output logic [63:0] out_res_data,
  output bku_perf_t   out_perf
);
  // -------------------------------------------------------------------------
  // valid 两级打拍：本 FU 自身的 valid 链 validThisFu(1)/(2)（带异步复位）。
  // 与上游 validPipe 相与得到各级 regEnable（rdyVec 恒 1）。
  // -------------------------------------------------------------------------
  logic valid_thisfu_1, valid_thisfu_2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_thisfu_1 <= 1'b0;
      valid_thisfu_2 <= 1'b0;
    end else begin
      valid_thisfu_1 <= in_valid;
      valid_thisfu_2 <= valid_thisfu_1;
    end
  end

  // regEnable(1)=stage0→1（子单元中间寄存器使能）：validPipe0 & in_valid
  // regEnable(2)=stage1→2（输出寄存器使能）   ：validPipe1 & validThisFu_1
  logic reg_en_s1, reg_en_s2;
  always_comb begin
    reg_en_s1 = in_validPipe0 & in_valid;
    reg_en_s2 = in_validPipe1 & valid_thisfu_1;
  end

  // -------------------------------------------------------------------------
  // 四个子单元（各 1 拍内部延迟，io_reg_en = regEnable(1)）
  // -------------------------------------------------------------------------
  logic [63:0] count_out, clmul_out, misc_out, crypto_out;

  xs_bku_count  u_count (
    .clock(clock), .src(in_src0), .func(in_fuOpType), .reg_en(reg_en_s1), .out(count_out)
  );
  xs_bku_clmul  u_clmul (
    .clock(clock), .src1(in_src0), .src2(in_src1),
    .func(in_fuOpType), .reg_en(reg_en_s1), .out(clmul_out)
  );
  xs_bku_misc   u_misc (
    .clock(clock), .src1(in_src0), .src2(in_src1),
    .func(in_fuOpType), .reg_en(reg_en_s1), .out(misc_out)
  );
  xs_bku_crypto u_crypto (
    .clock(clock), .src1(in_src0), .src2(in_src1),
    .func(in_fuOpType), .reg_en(reg_en_s1), .out(crypto_out)
  );

  // -------------------------------------------------------------------------
  // 顶层结果选择（cyc1 组合）：func_reg 在 in.fire 拍入。
  //   func[5]=crypto > func[3]=count > func[2]=misc(xperm) > 否则 clmul。
  //   （此优先级与 BKUOpType 编码空间一致，互不重叠。）
  // -------------------------------------------------------------------------
  logic [8:0]  func_reg;
  always_ff @(posedge clock) if (in_valid) func_reg <= in_fuOpType;

  logic [63:0] result;
  always_comb begin
    if      (func_reg[5]) result = crypto_out;
    else if (func_reg[3]) result = count_out;
    else if (func_reg[2]) result = misc_out;
    else                  result = clmul_out;
  end

  // 输出数据寄存器（cyc2）
  logic [63:0] res_data_r;
  always_ff @(posedge clock) if (reg_en_s2) res_data_r <= result;

  // -------------------------------------------------------------------------
  // perf 计时随流水打两拍（第 1 级用 in_valid，第 2 级用 validThisFu_1 使能）
  // -------------------------------------------------------------------------
  bku_perf_t perf_1, perf_2;
  always_ff @(posedge clock) begin
    if (in_valid)       perf_1 <= in_perf;
    if (valid_thisfu_1) perf_2 <= perf_1;
  end

  // -------------------------------------------------------------------------
  // 输出组装：valid = validPipe2 & validThisFu_2；ctrl 透传上游 ctrlPipe(2)。
  // -------------------------------------------------------------------------
  assign out_valid    = in_validPipe2 & valid_thisfu_2;
  assign out_ctrl     = in_ctrlPipe2;
  assign out_res_data = res_data_r;
  assign out_perf     = perf_2;
endmodule
