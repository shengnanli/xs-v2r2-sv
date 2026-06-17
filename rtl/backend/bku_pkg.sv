// =============================================================================
// xs_bku_pkg —— Bku（位操作 / 加密单元）共享类型与纯函数
//
// 对应 Chisel:
//   - xiangshan.BKUOpType        : fuOpType 编码（本文件的 enum）
//   - xiangshan.backend.fu.util.CryptoUtils : 移位/旋转、AES/SM4 S-box、MixColumn
//   - utility.{SignExt, PopCount} : 符号扩展、人口计数
//
// Bku 把 RISC-V 的位操作扩展（Zbb count/min-max、Zbc 无进位乘 clmul、
// Zbkb/Zbkx 字节置换 xperm）与标量密码扩展（Zknh sha、Zksh sm3、Zkne/Zknd
// aes64、Zksed sm4）合并到一个 2 拍流水的 FU 里。所有“为什么这么算”的
// 数学背景集中在本包的函数注释里，核 (Bku.sv) 只负责把它们接成流水线。
//
// XLEN = 64（昆明湖为 RV64）。
// =============================================================================
package xs_bku_pkg;

  localparam int XLEN = 64;

  // ---------------------------------------------------------------------------
  // fuOpType 编码（9 位字段，Bku 只用低 6 位；高位恒 0）
  //
  // 编码的位含义被核里的 mux 直接利用，是“为什么这样分配编码”的关键：
  //   func[5]   = 1 → 密码类 (crypto: hash/sm3 或 block-cipher aes/sm4)
  //   func[3]   = 1 → 计数类 (count: clz/ctz/cpop)         （当 func[5]=0 时）
  //   func[2]   = 1 → 字节置换 (xperm)                      （当 func[5:3]=0 时）
  //   其余             → 无进位乘 (clmul)
  // 各子单元内部再用更低位区分具体操作，见各子单元注释。
  // ---------------------------------------------------------------------------
  typedef enum logic [5:0] {
    // --- Zbc 无进位乘 ---
    OP_CLMUL      = 6'b000000,
    OP_CLMULH     = 6'b000001,
    OP_CLMULR     = 6'b000010,
    // --- Zbkx 字节置换 ---
    OP_XPERMN     = 6'b000100,  // 4-bit nibble 查表置换
    OP_XPERMB     = 6'b000101,  // 8-bit byte   查表置换
    // --- Zbb 计数 ---
    OP_CLZ        = 6'b001000,  // count leading  zeros (64b)
    OP_CLZW       = 6'b001001,  // count leading  zeros (32b)
    OP_CTZ        = 6'b001010,  // count trailing zeros (64b)
    OP_CTZW       = 6'b001011,  // count trailing zeros (32b)
    OP_CPOP       = 6'b001100,  // popcount (64b)
    OP_CPOPW      = 6'b001101,  // popcount (32b)
    // --- Zkne/Zknd AES-64 ---
    OP_AES64ES    = 6'b100000,  // 末轮加密
    OP_AES64ESM   = 6'b100001,  // 中间轮加密 (含 MixColumns)
    OP_AES64DS    = 6'b100010,  // 末轮解密
    OP_AES64DSM   = 6'b100011,  // 中间轮解密 (含 InvMixColumns)
    OP_AES64IM    = 6'b100100,  // 解密密钥 InvMixColumns
    OP_AES64KS1I  = 6'b100101,  // 密钥扩展 (含 SubWord + Rcon)
    OP_AES64KS2   = 6'b100110,  // 密钥扩展 (异或)
    // --- Zksed SM4（ed=加解密, ks=密钥扩展；低 2 位为字节旋转量 bs）---
    OP_SM4ED0     = 6'b101000,
    OP_SM4ED1     = 6'b101001,
    OP_SM4ED2     = 6'b101010,
    OP_SM4ED3     = 6'b101011,
    OP_SM4KS0     = 6'b101100,
    OP_SM4KS1     = 6'b101101,
    OP_SM4KS2     = 6'b101110,
    OP_SM4KS3     = 6'b101111,
    // --- Zknh SHA ---
    OP_SHA256SUM0 = 6'b110000,
    OP_SHA256SUM1 = 6'b110001,
    OP_SHA256SIG0 = 6'b110010,
    OP_SHA256SIG1 = 6'b110011,
    OP_SHA512SUM0 = 6'b110100,
    OP_SHA512SUM1 = 6'b110101,
    OP_SHA512SIG0 = 6'b110110,
    OP_SHA512SIG1 = 6'b110111,
    // --- Zksh SM3 ---
    OP_SM3P0      = 6'b111000,
    OP_SM3P1      = 6'b111001
  } bku_op_e;

  // ===========================================================================
  // 1. 32/64 位逻辑右移与循环右移
  //    对应 CryptoUtils.{SHR32,SHR64,ROR32,ROR64}。SHA 的 Σ/σ 函数由这些
  //    旋转/移位异或而成。XLEN=64，结果用低位有效、高位补 0（32 位版的高
  //    32 位在调用处会被 SignExt 重新填充，故此处补 0 即可）。
  // ===========================================================================
  function automatic logic [63:0] ror32(input logic [63:0] x, input int shamt);
    logic [31:0] w;
    w = x[31:0];
    return {32'b0, (w >> shamt) | (w << (32 - shamt))};
  endfunction

  function automatic logic [63:0] shr32(input logic [63:0] x, input int shamt);
    return {32'b0, (x[31:0] >> shamt)};
  endfunction

  function automatic logic [63:0] ror64(input logic [63:0] x, input int shamt);
    return (x >> shamt) | (x << (64 - shamt));
  endfunction

  function automatic logic [63:0] shr64(input logic [63:0] x, input int shamt);
    return (x >> shamt);
  endfunction

  // 符号扩展 32→64
  function automatic logic [63:0] sext32(input logic [31:0] x);
    return {{32{x[31]}}, x};
  endfunction

  // ===========================================================================
  // 2. AES / SM4 共用的复合域 S-box（Canright 紧凑实现）
  //    分三段：Top（输入线性映射，得 21 位）→ Inv（GF(2^4) 求逆，得 18 位，
  //    打一拍寄存）→ Out（输出线性映射，得 8 位）。三种 S-box 仅 Top/Out 不同，
  //    Inv 完全共用。所有等式逐位照搬 CryptoUtils，是面积优化的固定网表，
  //    不含可“化简的语义”，因此忠实保留为组合函数。
  // ===========================================================================

  // AES 加密 S-box 输入级：8 位 → 21 位
  function automatic logic [20:0] sbox_aes_top(input logic [7:0] i);
    logic [5:0]  t;
    logic [20:0] o;
    t[0] = i[3] ^ i[1];
    t[1] = i[6] ^ i[5];
    t[2] = i[6] ^ i[2];
    t[3] = i[5] ^ i[2];
    t[4] = i[4] ^ i[0];
    t[5] = i[1] ^ i[0];
    o[0]  = i[0];
    o[1]  = i[7] ^ i[4];
    o[2]  = i[7] ^ i[2];
    o[3]  = i[7] ^ i[1];
    o[4]  = i[4] ^ i[2];
    o[5]  = o[1] ^ t[0];
    o[6]  = i[0] ^ o[5];
    o[7]  = i[0] ^ t[1];
    o[8]  = o[5] ^ t[1];
    o[9]  = o[3] ^ o[4];
    o[10] = o[5] ^ t[2];
    o[11] = t[0] ^ t[2];
    o[12] = t[0] ^ t[3];
    o[13] = o[7] ^ o[12];
    o[14] = t[1] ^ t[4];
    o[15] = o[1] ^ o[14];
    o[16] = t[1] ^ t[5];
    o[17] = o[2] ^ o[16];
    o[18] = o[2] ^ o[8];
    o[19] = o[15] ^ o[13];
    o[20] = o[1] ^ t[3];
    return o;
  endfunction

  // AES 解密 S-box 输入级：8 位 → 21 位
  // 注：原 Chisel 等式按“线网连接”书写，存在前向引用（如 o[4] 用到 o[6]）。
  //     这里照搬等式顺序但用 repeat(4) 让赋值多遍收敛（纯组合 DAG、无真实环路，
  //     等价于电路里的拓扑求解），从而保持与源一一对应、便于对照阅读。
  function automatic logic [20:0] sbox_iaes_top(input logic [7:0] i);
    logic [4:0]  t;
    logic [20:0] o;
    o = '0;
    repeat (4) begin
      t[0] = i[1] ^  i[0];
      t[1] = i[6] ^  i[1];
      t[2] = i[5] ^ ~i[2];
      t[3] = i[2] ^ ~i[1];
      t[4] = i[5] ^ ~i[3];
      o[0]  = i[7] ^  t[2];
      o[1]  = i[4] ^  i[3];
      o[2]  = i[7] ^ ~i[6];
      o[3]  = o[1] ^  t[0];
      o[4]  = i[3] ^  o[6];
      o[5]  = o[16] ^ t[2];
      o[6]  = i[6] ^ ~o[17];
      o[7]  = i[0] ^ ~o[1];
      o[8]  = o[2] ^  o[18];
      o[9]  = o[2] ^  t[0];
      o[10] = o[8] ^  t[3];
      o[11] = o[8] ^  o[20];
      o[12] = t[1] ^  t[4];
      o[13] = i[5] ^ ~o[14];
      o[14] = o[16] ^ t[0];
      o[15] = o[18] ^ t[1];
      o[16] = i[6] ^ ~i[4];
      o[17] = i[7] ^  i[4];
      o[18] = i[3] ^ ~i[0];
      o[19] = i[5] ^ ~o[1];
      o[20] = o[1] ^  t[3];
    end
    return o;
  endfunction

  // SM4 加解密共用 S-box 输入级：8 位 → 21 位
  // 同 sbox_iaes_top：等式含前向引用（如 t[2] 用到 o[18]），repeat(4) 多遍收敛。
  function automatic logic [20:0] sbox_sm4_top(input logic [7:0] i);
    logic [6:0]  t;
    logic [20:0] o;
    o = '0;
    repeat (4) begin
    t[0] = i[3] ^  i[4];
    t[1] = i[2] ^  i[7];
    t[2] = i[7] ^  o[18];
    t[3] = i[1] ^  t[1];
    t[4] = i[6] ^  i[7];
    t[5] = i[0] ^  o[18];
    t[6] = i[3] ^  i[6];
    o[0]  = i[5] ^ ~o[10];
    o[1]  = t[0] ^  t[3];
    o[2]  = i[0] ^  t[0];
    o[3]  = i[3] ^  o[4];
    o[4]  = i[0] ^  t[3];
    o[5]  = i[5] ^  t[5];
    o[6]  = i[0] ^ ~i[1];
    o[7]  = t[0] ^ ~o[10];
    o[8]  = t[0] ^  t[5];
    o[9]  = i[3];
    o[10] = i[1] ^  o[18];
    o[11] = t[0] ^  t[4];
    o[12] = i[5] ^  t[4];
    o[13] = i[5] ^ ~o[1];
    o[14] = i[4] ^ ~t[2];
    o[15] = i[1] ^ ~t[6];
    o[16] = i[0] ^ ~t[2];
    o[17] = t[0] ^ ~t[2];
    o[18] = i[2] ^  i[6];
    o[19] = i[5] ^ ~o[14];
    o[20] = i[0] ^  t[1];
    end
    return o;
  endfunction

  // 共用中间级（GF(2^4) 求逆）：21 位 → 18 位
  function automatic logic [17:0] sbox_inv(input logic [20:0] i);
    logic [45:0] t;
    logic [17:0] o;
    t[0]  = i[3] ^ i[12];
    t[1]  = i[9] & i[5];
    t[2]  = i[17] & i[6];
    t[3]  = i[10] ^ t[1];
    t[4]  = i[14] & i[0];
    t[5]  = t[4] ^ t[1];
    t[6]  = i[3] & i[12];
    t[7]  = i[16] & i[7];
    t[8]  = t[0] ^ t[6];
    t[9]  = i[15] & i[13];
    t[10] = t[9] ^ t[6];
    t[11] = i[1] & i[11];
    t[12] = i[4] & i[20];
    t[13] = t[12] ^ t[11];
    t[14] = i[2] & i[8];
    t[15] = t[14] ^ t[11];
    t[16] = t[3] ^ t[2];
    t[17] = t[5] ^ i[18];
    t[18] = t[8] ^ t[7];
    t[19] = t[10] ^ t[15];
    t[20] = t[16] ^ t[13];
    t[21] = t[17] ^ t[15];
    t[22] = t[18] ^ t[13];
    t[23] = t[19] ^ i[19];
    t[24] = t[22] ^ t[23];
    t[25] = t[22] & t[20];
    t[26] = t[21] ^ t[25];
    t[27] = t[20] ^ t[21];
    t[28] = t[23] ^ t[25];
    t[29] = t[28] & t[27];
    t[30] = t[26] & t[24];
    t[31] = t[20] & t[23];
    t[32] = t[27] & t[31];
    t[33] = t[27] ^ t[25];
    t[34] = t[21] & t[22];
    t[35] = t[24] & t[34];
    t[36] = t[24] ^ t[25];
    t[37] = t[21] ^ t[29];
    t[38] = t[32] ^ t[33];
    t[39] = t[23] ^ t[30];
    t[40] = t[35] ^ t[36];
    t[41] = t[38] ^ t[40];
    t[42] = t[37] ^ t[39];
    t[43] = t[37] ^ t[38];
    t[44] = t[39] ^ t[40];
    t[45] = t[42] ^ t[41];
    o[0]  = t[38] & i[7];
    o[1]  = t[37] & i[13];
    o[2]  = t[42] & i[11];
    o[3]  = t[45] & i[20];
    o[4]  = t[41] & i[8];
    o[5]  = t[44] & i[9];
    o[6]  = t[40] & i[17];
    o[7]  = t[39] & i[14];
    o[8]  = t[43] & i[3];
    o[9]  = t[38] & i[16];
    o[10] = t[37] & i[15];
    o[11] = t[42] & i[1];
    o[12] = t[45] & i[4];
    o[13] = t[41] & i[2];
    o[14] = t[44] & i[5];
    o[15] = t[40] & i[6];
    o[16] = t[39] & i[0];
    o[17] = t[43] & i[12];
    return o;
  endfunction

  // AES 加密 S-box 输出级：18 位 → 8 位
  function automatic logic [7:0] sbox_aes_out(input logic [17:0] i);
    logic [29:0] t;
    logic [7:0]  o;
    t[0]  = i[11] ^ i[12];
    t[1]  = i[0] ^ i[6];
    t[2]  = i[14] ^ i[16];
    t[3]  = i[15] ^ i[5];
    t[4]  = i[4] ^ i[8];
    t[5]  = i[17] ^ i[11];
    t[6]  = i[12] ^ t[5];
    t[7]  = i[14] ^ t[3];
    t[8]  = i[1] ^ i[9];
    t[9]  = i[2] ^ i[3];
    t[10] = i[3] ^ t[4];
    t[11] = i[10] ^ t[2];
    t[12] = i[16] ^ i[1];
    t[13] = i[0] ^ t[0];
    t[14] = i[2] ^ i[11];
    t[15] = i[5] ^ t[1];
    t[16] = i[6] ^ t[0];
    t[17] = i[7] ^ t[1];
    t[18] = i[8] ^ t[8];
    t[19] = i[13] ^ t[4];
    t[20] = t[0] ^ t[1];
    t[21] = t[1] ^ t[7];
    t[22] = t[3] ^ t[12];
    t[23] = t[18] ^ t[2];
    t[24] = t[15] ^ t[9];
    t[25] = t[6] ^ t[10];
    t[26] = t[7] ^ t[9];
    t[27] = t[8] ^ t[10];
    t[28] = t[11] ^ t[14];
    t[29] = t[11] ^ t[17];
    o[0]  = t[6] ^ ~t[23];
    o[1]  = t[13] ^ ~t[27];
    o[2]  = t[25] ^ t[29];
    o[3]  = t[20] ^ t[22];
    o[4]  = t[6] ^ t[21];
    o[5]  = t[19] ^ ~t[28];
    o[6]  = t[16] ^ ~t[26];
    o[7]  = t[6] ^ t[24];
    return o;
  endfunction

  // AES 解密 S-box 输出级：18 位 → 8 位
  function automatic logic [7:0] sbox_iaes_out(input logic [17:0] i);
    logic [29:0] t;
    logic [7:0]  o;
    t[0]  = i[2] ^ i[11];
    t[1]  = i[8] ^ i[9];
    t[2]  = i[4] ^ i[12];
    t[3]  = i[15] ^ i[0];
    t[4]  = i[16] ^ i[6];
    t[5]  = i[14] ^ i[1];
    t[6]  = i[17] ^ i[10];
    t[7]  = t[0] ^ t[1];
    t[8]  = i[0] ^ i[3];
    t[9]  = i[5] ^ i[13];
    t[10] = i[7] ^ t[4];
    t[11] = t[0] ^ t[3];
    t[12] = i[14] ^ i[16];
    t[13] = i[17] ^ i[1];
    t[14] = i[17] ^ i[12];
    t[15] = i[4] ^ i[9];
    t[16] = i[7] ^ i[11];
    t[17] = i[8] ^ t[2];
    t[18] = i[13] ^ t[5];
    t[19] = t[2] ^ t[3];
    t[20] = t[4] ^ t[6];
    t[21] = 1'b0;
    t[22] = t[2] ^ t[7];
    t[23] = t[7] ^ t[8];
    t[24] = t[5] ^ t[7];
    t[25] = t[6] ^ t[10];
    t[26] = t[9] ^ t[11];
    t[27] = t[10] ^ t[18];
    t[28] = t[11] ^ t[25];
    t[29] = t[15] ^ t[20];
    o[0]  = t[9] ^ t[16];
    o[1]  = t[14] ^ t[23];
    o[2]  = t[19] ^ t[24];
    o[3]  = t[23] ^ t[27];
    o[4]  = t[12] ^ t[22];
    o[5]  = t[17] ^ t[28];
    o[6]  = t[26] ^ t[29];
    o[7]  = t[13] ^ t[22];
    return o;
  endfunction

  // SM4 加解密共用 S-box 输出级：18 位 → 8 位
  function automatic logic [7:0] sbox_sm4_out(input logic [17:0] i);
    logic [29:0] t;
    logic [7:0]  o;
    t[0]  = i[4] ^ i[7];
    t[1]  = i[13] ^ i[15];
    t[2]  = i[2] ^ i[16];
    t[3]  = i[6] ^ t[0];
    t[4]  = i[12] ^ t[1];
    t[5]  = i[9] ^ i[10];
    t[6]  = i[11] ^ t[2];
    t[7]  = i[1] ^ t[4];
    t[8]  = i[0] ^ i[17];
    t[9]  = i[3] ^ i[17];
    t[10] = i[8] ^ t[3];
    t[11] = t[2] ^ t[5];
    t[12] = i[14] ^ t[6];
    t[13] = t[7] ^ t[9];
    t[14] = i[0] ^ i[6];
    t[15] = i[7] ^ i[16];
    t[16] = i[5] ^ i[13];
    t[17] = i[3] ^ i[15];
    t[18] = i[10] ^ i[12];
    t[19] = i[9] ^ t[1];
    t[20] = i[4] ^ t[4];
    t[21] = i[14] ^ t[3];
    t[22] = i[16] ^ t[5];
    t[23] = t[7] ^ t[14];
    t[24] = t[8] ^ t[11];
    t[25] = t[0] ^ t[12];
    t[26] = t[17] ^ t[3];
    t[27] = t[18] ^ t[10];
    t[28] = t[19] ^ t[6];
    t[29] = t[8] ^ t[10];
    o[0]  = t[11] ^ ~t[13];
    o[1]  = t[15] ^ ~t[23];
    o[2]  = t[20] ^ t[24];
    o[3]  = t[16] ^ t[25];
    o[4]  = t[26] ^ ~t[22];
    o[5]  = t[21] ^ t[13];
    o[6]  = t[27] ^ ~t[12];
    o[7]  = t[28] ^ ~t[29];
    return o;
  endfunction

  // ===========================================================================
  // 3. AES MixColumns / InvMixColumns（GF(2^8) 上的列混淆）
  //    Xt2 = 域内乘 2（x·{02}，溢出时模 {1b}）。XtN 用 {01,02,04,08} 四个倍数
  //    的线性组合实现任意常量乘（系数由 t 的 4 位选择）。ByteEnc/ByteDec 是
  //    正/逆 MixColumns 的一列；MixFwd/MixInv 拼成 4 列（32 位）。
  // ===========================================================================
  function automatic logic [7:0] aes_xt2(input logic [7:0] b);
    return (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
  endfunction

  function automatic logic [7:0] aes_xtn(input logic [7:0] b, input logic [3:0] t);
    logic [7:0] b1, b2, b3;
    b1 = aes_xt2(b);
    b2 = aes_xt2(b1);
    b3 = aes_xt2(b2);
    return (t[0] ? b : 8'h0) ^ (t[1] ? b1 : 8'h0)
         ^ (t[2] ? b2 : 8'h0) ^ (t[3] ? b3 : 8'h0);
  endfunction

  // 正向 MixColumns 一列：02·b0 ^ 03·b1 ^ b2 ^ b3
  function automatic logic [7:0] aes_byte_enc(input logic [7:0] b0, b1, b2, b3);
    return aes_xtn(b0, 4'h2) ^ aes_xtn(b1, 4'h3) ^ b2 ^ b3;
  endfunction

  // 逆向 MixColumns 一列：0e·b0 ^ 0b·b1 ^ 0d·b2 ^ 09·b3
  function automatic logic [7:0] aes_byte_dec(input logic [7:0] b0, b1, b2, b3);
    return aes_xtn(b0, 4'he) ^ aes_xtn(b1, 4'hb)
         ^ aes_xtn(b2, 4'hd) ^ aes_xtn(b3, 4'h9);
  endfunction

  // 4 字节 → 32 位正向列混淆
  function automatic logic [31:0] aes_mix_fwd(input logic [7:0] b0, b1, b2, b3);
    return {aes_byte_enc(b3, b0, b1, b2),
            aes_byte_enc(b2, b3, b0, b1),
            aes_byte_enc(b1, b2, b3, b0),
            aes_byte_enc(b0, b1, b2, b3)};
  endfunction

  // 4 字节 → 32 位逆向列混淆
  function automatic logic [31:0] aes_mix_inv(input logic [7:0] b0, b1, b2, b3);
    return {aes_byte_dec(b3, b0, b1, b2),
            aes_byte_dec(b2, b3, b0, b1),
            aes_byte_dec(b1, b2, b3, b0),
            aes_byte_dec(b0, b1, b2, b3)};
  endfunction

endpackage : xs_bku_pkg
