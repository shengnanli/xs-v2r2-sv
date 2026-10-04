// =============================================================================
// BlockCipherModule.sv —— 标量密码扩展（Zkne/Zknd/Zksed）的分组密码运算块：AES 与 SM4 的单轮部件
//
// 位置：Bku（位操作 / 密码功能单元）-> CryptoModule -> 本模块。两拍流水：第 0 拍（regEnable 时）
//   读操作数、做完 S 盒的前半段并寄存；第 1 拍从寄存器组合出结果（父模块 CryptoModule 再按 func[4]
//   在本模块与 HashModule 之间二选一）。
//   Scala：src/main/scala/xiangshan/backend/fu/Bku.scala（class BlockCipherModule）
//          + fu/util/CryptoUtils.scala（S 盒电路、ShiftRows、MixColumns）。
//
// 指令（func，与 BKUOpType 编码一致；src1 = rs1，src2 = rs2）：
//   0x20 aes64es   / 0x21 aes64esm   正向一轮：ShiftRows + SubBytes（+ MixColumns），取 128 位状态的低 64 位
//   0x22 aes64ds   / 0x23 aes64dsm   逆向一轮：InvShiftRows + InvSubBytes（+ InvMixColumns）
//   0x24 aes64im                     对 rs1 两列做 InvMixColumns（解密轮密钥变换）
//   0x25 aes64ks1i                   密钥扩展：rs1 高字（rnum != 0xA 时循环右移 8 位）过 S 盒，异或轮常数
//   0x26 aes64ks2                    密钥扩展：w0 = rs1.hi ^ rs2.lo，w1 = w0 ^ rs2.hi，结果 {w1, w0}
//   0x28..0x2B sm4ed bs / 0x2C..0x2F sm4ks bs（bs = func[1:0]，选 rs2 的第 bs 个字节）：
//                                    字节过 SM4 S 盒 -> 线性变换 L（加密）/ L'（密钥扩展）-> 循环左移 8·bs
//                                    （SM4 的字在寄存器里是小端放的，L / L' 要在字节反序的视角下做，见包内注释）
//                                    -> 异或 rs1 的低 32 位 -> 符号扩展到 64 位
//
// ★S 盒为什么不是一张查找表★
//   三种 S 盒（AES、AES 逆、SM4）的标准定义是 256 项查找表（本文件的包里照标准原样列出：
//   FIPS-197 Figure 7 / Figure 14、GB/T 32907-2016 表 1）。但硬件用的是 Boyar–Peralta 式的三段分解：
//       字节 x --[顶层：GF(2) 仿射 8->21]--> --[中层：GF(2^4) 求逆电路 21->18]--> --[底层：GF(2) 仿射 18->8]--> S(x)
//   三种 S 盒共用同一个中层（AES 与 SM4 的 S 盒都是"仿射 ∘ 有限域求逆 ∘ 仿射"），只有顶 / 底两层不同。
//   ★流水线寄存器就切在这条链的中间★：AES / AES 逆 S 盒寄存中层的 18 位输出，密钥扩展与 SM4 寄存顶层的
//   21 位输出。寄存器里存的是这些中间量，所以本文件必须逐位造出同样的中间量 —— 只用查表
//   既不可能与 golden 的寄存器逐位一致（FM 比的就是寄存器），也装不进这个两拍切分。
//   折中：顶 / 底两层写成"矩阵 + 常数"（每个输出位 = 某几个输入位的异或，再异或一个常数），
//   中层照原电路写；查找表在仿真开始时（非综合）对 256 个输入逐个核对"三段串起来 == 标准表"。
//   底层的常数正是两种 S 盒教科书上的仿射常数：AES 0x63、SM4 0xD3。
//
// 怪癖（照 golden，不"修"）：
//   1. aes64ks1i 的轮常数表只有 11 项（rnum 0..10，第 10 项是 0），rnum 11..15 是保留编码；
//      Chisel 的 Vec 越界读回绕到第 0 项，所以 golden 在 rnum >= 11 时异或 0x01。
//   2. 轮常数只异或进 32 位 S 盒结果的最低字节（rcon 是 8 位，零扩展后异或）。
//   3. AES 结果按 func 的**全部 9 位**精确比较选择（LookupTreeDefault），都不命中时给 aes64es 的结果；
//      SM4 只看 func[3]（选 SM4）与 func[2:0]（ed / ks 与字节号），不看其余位。
//   4. SM4 的 S 盒输入字节由**本拍**的 func[1:0] 选（在寄存之前），结果的循环与 ed/ks 选择看寄存后的 func。
// =============================================================================

package blockciphermodule_pkg;
  // ---------------------------------------------------------------------------
  // 标准 S 盒查找表（规格；硬件不查它，只用于仿真自检，见文件头）
  // ---------------------------------------------------------------------------
  // AES S 盒：FIPS-197（2001 / 2023 更新版）Figure 7，SubBytes()。下标 = 输入字节 xy（行 x、列 y）。
  localparam logic [7:0] AES_SBOX [256] = '{
    8'h63, 8'h7C, 8'h77, 8'h7B, 8'hF2, 8'h6B, 8'h6F, 8'hC5, 8'h30, 8'h01, 8'h67, 8'h2B, 8'hFE, 8'hD7, 8'hAB, 8'h76,  // 0_
    8'hCA, 8'h82, 8'hC9, 8'h7D, 8'hFA, 8'h59, 8'h47, 8'hF0, 8'hAD, 8'hD4, 8'hA2, 8'hAF, 8'h9C, 8'hA4, 8'h72, 8'hC0,  // 1_
    8'hB7, 8'hFD, 8'h93, 8'h26, 8'h36, 8'h3F, 8'hF7, 8'hCC, 8'h34, 8'hA5, 8'hE5, 8'hF1, 8'h71, 8'hD8, 8'h31, 8'h15,  // 2_
    8'h04, 8'hC7, 8'h23, 8'hC3, 8'h18, 8'h96, 8'h05, 8'h9A, 8'h07, 8'h12, 8'h80, 8'hE2, 8'hEB, 8'h27, 8'hB2, 8'h75,  // 3_
    8'h09, 8'h83, 8'h2C, 8'h1A, 8'h1B, 8'h6E, 8'h5A, 8'hA0, 8'h52, 8'h3B, 8'hD6, 8'hB3, 8'h29, 8'hE3, 8'h2F, 8'h84,  // 4_
    8'h53, 8'hD1, 8'h00, 8'hED, 8'h20, 8'hFC, 8'hB1, 8'h5B, 8'h6A, 8'hCB, 8'hBE, 8'h39, 8'h4A, 8'h4C, 8'h58, 8'hCF,  // 5_
    8'hD0, 8'hEF, 8'hAA, 8'hFB, 8'h43, 8'h4D, 8'h33, 8'h85, 8'h45, 8'hF9, 8'h02, 8'h7F, 8'h50, 8'h3C, 8'h9F, 8'hA8,  // 6_
    8'h51, 8'hA3, 8'h40, 8'h8F, 8'h92, 8'h9D, 8'h38, 8'hF5, 8'hBC, 8'hB6, 8'hDA, 8'h21, 8'h10, 8'hFF, 8'hF3, 8'hD2,  // 7_
    8'hCD, 8'h0C, 8'h13, 8'hEC, 8'h5F, 8'h97, 8'h44, 8'h17, 8'hC4, 8'hA7, 8'h7E, 8'h3D, 8'h64, 8'h5D, 8'h19, 8'h73,  // 8_
    8'h60, 8'h81, 8'h4F, 8'hDC, 8'h22, 8'h2A, 8'h90, 8'h88, 8'h46, 8'hEE, 8'hB8, 8'h14, 8'hDE, 8'h5E, 8'h0B, 8'hDB,  // 9_
    8'hE0, 8'h32, 8'h3A, 8'h0A, 8'h49, 8'h06, 8'h24, 8'h5C, 8'hC2, 8'hD3, 8'hAC, 8'h62, 8'h91, 8'h95, 8'hE4, 8'h79,  // A_
    8'hE7, 8'hC8, 8'h37, 8'h6D, 8'h8D, 8'hD5, 8'h4E, 8'hA9, 8'h6C, 8'h56, 8'hF4, 8'hEA, 8'h65, 8'h7A, 8'hAE, 8'h08,  // B_
    8'hBA, 8'h78, 8'h25, 8'h2E, 8'h1C, 8'hA6, 8'hB4, 8'hC6, 8'hE8, 8'hDD, 8'h74, 8'h1F, 8'h4B, 8'hBD, 8'h8B, 8'h8A,  // C_
    8'h70, 8'h3E, 8'hB5, 8'h66, 8'h48, 8'h03, 8'hF6, 8'h0E, 8'h61, 8'h35, 8'h57, 8'hB9, 8'h86, 8'hC1, 8'h1D, 8'h9E,  // D_
    8'hE1, 8'hF8, 8'h98, 8'h11, 8'h69, 8'hD9, 8'h8E, 8'h94, 8'h9B, 8'h1E, 8'h87, 8'hE9, 8'hCE, 8'h55, 8'h28, 8'hDF,  // E_
    8'h8C, 8'hA1, 8'h89, 8'h0D, 8'hBF, 8'hE6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2D, 8'h0F, 8'hB0, 8'h54, 8'hBB, 8'h16   // F_
  };
  // AES 逆 S 盒：FIPS-197 Figure 14，InvSubBytes()。
  localparam logic [7:0] AES_INV_SBOX [256] = '{
    8'h52, 8'h09, 8'h6A, 8'hD5, 8'h30, 8'h36, 8'hA5, 8'h38, 8'hBF, 8'h40, 8'hA3, 8'h9E, 8'h81, 8'hF3, 8'hD7, 8'hFB,  // 0_
    8'h7C, 8'hE3, 8'h39, 8'h82, 8'h9B, 8'h2F, 8'hFF, 8'h87, 8'h34, 8'h8E, 8'h43, 8'h44, 8'hC4, 8'hDE, 8'hE9, 8'hCB,  // 1_
    8'h54, 8'h7B, 8'h94, 8'h32, 8'hA6, 8'hC2, 8'h23, 8'h3D, 8'hEE, 8'h4C, 8'h95, 8'h0B, 8'h42, 8'hFA, 8'hC3, 8'h4E,  // 2_
    8'h08, 8'h2E, 8'hA1, 8'h66, 8'h28, 8'hD9, 8'h24, 8'hB2, 8'h76, 8'h5B, 8'hA2, 8'h49, 8'h6D, 8'h8B, 8'hD1, 8'h25,  // 3_
    8'h72, 8'hF8, 8'hF6, 8'h64, 8'h86, 8'h68, 8'h98, 8'h16, 8'hD4, 8'hA4, 8'h5C, 8'hCC, 8'h5D, 8'h65, 8'hB6, 8'h92,  // 4_
    8'h6C, 8'h70, 8'h48, 8'h50, 8'hFD, 8'hED, 8'hB9, 8'hDA, 8'h5E, 8'h15, 8'h46, 8'h57, 8'hA7, 8'h8D, 8'h9D, 8'h84,  // 5_
    8'h90, 8'hD8, 8'hAB, 8'h00, 8'h8C, 8'hBC, 8'hD3, 8'h0A, 8'hF7, 8'hE4, 8'h58, 8'h05, 8'hB8, 8'hB3, 8'h45, 8'h06,  // 6_
    8'hD0, 8'h2C, 8'h1E, 8'h8F, 8'hCA, 8'h3F, 8'h0F, 8'h02, 8'hC1, 8'hAF, 8'hBD, 8'h03, 8'h01, 8'h13, 8'h8A, 8'h6B,  // 7_
    8'h3A, 8'h91, 8'h11, 8'h41, 8'h4F, 8'h67, 8'hDC, 8'hEA, 8'h97, 8'hF2, 8'hCF, 8'hCE, 8'hF0, 8'hB4, 8'hE6, 8'h73,  // 8_
    8'h96, 8'hAC, 8'h74, 8'h22, 8'hE7, 8'hAD, 8'h35, 8'h85, 8'hE2, 8'hF9, 8'h37, 8'hE8, 8'h1C, 8'h75, 8'hDF, 8'h6E,  // 9_
    8'h47, 8'hF1, 8'h1A, 8'h71, 8'h1D, 8'h29, 8'hC5, 8'h89, 8'h6F, 8'hB7, 8'h62, 8'h0E, 8'hAA, 8'h18, 8'hBE, 8'h1B,  // A_
    8'hFC, 8'h56, 8'h3E, 8'h4B, 8'hC6, 8'hD2, 8'h79, 8'h20, 8'h9A, 8'hDB, 8'hC0, 8'hFE, 8'h78, 8'hCD, 8'h5A, 8'hF4,  // B_
    8'h1F, 8'hDD, 8'hA8, 8'h33, 8'h88, 8'h07, 8'hC7, 8'h31, 8'hB1, 8'h12, 8'h10, 8'h59, 8'h27, 8'h80, 8'hEC, 8'h5F,  // C_
    8'h60, 8'h51, 8'h7F, 8'hA9, 8'h19, 8'hB5, 8'h4A, 8'h0D, 8'h2D, 8'hE5, 8'h7A, 8'h9F, 8'h93, 8'hC9, 8'h9C, 8'hEF,  // D_
    8'hA0, 8'hE0, 8'h3B, 8'h4D, 8'hAE, 8'h2A, 8'hF5, 8'hB0, 8'hC8, 8'hEB, 8'hBB, 8'h3C, 8'h83, 8'h53, 8'h99, 8'h61,  // E_
    8'h17, 8'h2B, 8'h04, 8'h7E, 8'hBA, 8'h77, 8'hD6, 8'h26, 8'hE1, 8'h69, 8'h14, 8'h63, 8'h55, 8'h21, 8'h0C, 8'h7D   // F_
  };
  // SM4 S 盒：GB/T 32907-2016《信息安全技术 SM4 分组密码算法》6.2 节表 1。
  localparam logic [7:0] SM4_SBOX [256] = '{
    8'hD6, 8'h90, 8'hE9, 8'hFE, 8'hCC, 8'hE1, 8'h3D, 8'hB7, 8'h16, 8'hB6, 8'h14, 8'hC2, 8'h28, 8'hFB, 8'h2C, 8'h05,  // 0_
    8'h2B, 8'h67, 8'h9A, 8'h76, 8'h2A, 8'hBE, 8'h04, 8'hC3, 8'hAA, 8'h44, 8'h13, 8'h26, 8'h49, 8'h86, 8'h06, 8'h99,  // 1_
    8'h9C, 8'h42, 8'h50, 8'hF4, 8'h91, 8'hEF, 8'h98, 8'h7A, 8'h33, 8'h54, 8'h0B, 8'h43, 8'hED, 8'hCF, 8'hAC, 8'h62,  // 2_
    8'hE4, 8'hB3, 8'h1C, 8'hA9, 8'hC9, 8'h08, 8'hE8, 8'h95, 8'h80, 8'hDF, 8'h94, 8'hFA, 8'h75, 8'h8F, 8'h3F, 8'hA6,  // 3_
    8'h47, 8'h07, 8'hA7, 8'hFC, 8'hF3, 8'h73, 8'h17, 8'hBA, 8'h83, 8'h59, 8'h3C, 8'h19, 8'hE6, 8'h85, 8'h4F, 8'hA8,  // 4_
    8'h68, 8'h6B, 8'h81, 8'hB2, 8'h71, 8'h64, 8'hDA, 8'h8B, 8'hF8, 8'hEB, 8'h0F, 8'h4B, 8'h70, 8'h56, 8'h9D, 8'h35,  // 5_
    8'h1E, 8'h24, 8'h0E, 8'h5E, 8'h63, 8'h58, 8'hD1, 8'hA2, 8'h25, 8'h22, 8'h7C, 8'h3B, 8'h01, 8'h21, 8'h78, 8'h87,  // 6_
    8'hD4, 8'h00, 8'h46, 8'h57, 8'h9F, 8'hD3, 8'h27, 8'h52, 8'h4C, 8'h36, 8'h02, 8'hE7, 8'hA0, 8'hC4, 8'hC8, 8'h9E,  // 7_
    8'hEA, 8'hBF, 8'h8A, 8'hD2, 8'h40, 8'hC7, 8'h38, 8'hB5, 8'hA3, 8'hF7, 8'hF2, 8'hCE, 8'hF9, 8'h61, 8'h15, 8'hA1,  // 8_
    8'hE0, 8'hAE, 8'h5D, 8'hA4, 8'h9B, 8'h34, 8'h1A, 8'h55, 8'hAD, 8'h93, 8'h32, 8'h30, 8'hF5, 8'h8C, 8'hB1, 8'hE3,  // 9_
    8'h1D, 8'hF6, 8'hE2, 8'h2E, 8'h82, 8'h66, 8'hCA, 8'h60, 8'hC0, 8'h29, 8'h23, 8'hAB, 8'h0D, 8'h53, 8'h4E, 8'h6F,  // A_
    8'hD5, 8'hDB, 8'h37, 8'h45, 8'hDE, 8'hFD, 8'h8E, 8'h2F, 8'h03, 8'hFF, 8'h6A, 8'h72, 8'h6D, 8'h6C, 8'h5B, 8'h51,  // B_
    8'h8D, 8'h1B, 8'hAF, 8'h92, 8'hBB, 8'hDD, 8'hBC, 8'h7F, 8'h11, 8'hD9, 8'h5C, 8'h41, 8'h1F, 8'h10, 8'h5A, 8'hD8,  // C_
    8'h0A, 8'hC1, 8'h31, 8'h88, 8'hA5, 8'hCD, 8'h7B, 8'hBD, 8'h2D, 8'h74, 8'hD0, 8'h12, 8'hB8, 8'hE5, 8'hB4, 8'hB0,  // D_
    8'h89, 8'h69, 8'h97, 8'h4A, 8'h0C, 8'h96, 8'h77, 8'h7E, 8'h65, 8'hB9, 8'hF1, 8'h09, 8'hC5, 8'h6E, 8'hC6, 8'h84,  // E_
    8'h18, 8'hF0, 8'h7D, 8'hEC, 8'h3A, 8'hDC, 8'h4D, 8'h20, 8'h79, 8'hEE, 8'h5F, 8'h3E, 8'hD7, 8'hCB, 8'h39, 8'h48   // F_
  };

  // ---------------------------------------------------------------------------
  // S 盒的硬件分解：顶层 / 底层是 GF(2) 仿射映射，写成"行向量 + 常数"：
  //   y[k] = ^(ROWS[k] & x) ^ CONST[k]   （ROWS[k] 的第 b 位为 1 表示 x[b] 参与 y[k] 的异或）
  // 矩阵由 CryptoUtils.scala 的 SboxAesTop / SboxIaesTop / SboxSm4Top / SboxAesOut / SboxIaesOut /
  // SboxSm4Out 逐位导出（对每个输入位单独置 1 求响应），与原电路逐位等价。
  // ---------------------------------------------------------------------------
  localparam logic [7:0] AES_TOP_ROWS [21] = '{
    8'b00000001,  // y[0]
    8'b10010000,  // y[1]
    8'b10000100,  // y[2]
    8'b10000010,  // y[3]
    8'b00010100,  // y[4]
    8'b10011010,  // y[5]
    8'b10011011,  // y[6]
    8'b01100001,  // y[7]
    8'b11111010,  // y[8]
    8'b10010110,  // y[9]
    8'b11011110,  // y[10]
    8'b01001110,  // y[11]
    8'b00101110,  // y[12]
    8'b01001111,  // y[13]
    8'b01110001,  // y[14]
    8'b11100001,  // y[15]
    8'b01100011,  // y[16]
    8'b11100111,  // y[17]
    8'b01111110,  // y[18]
    8'b10101110,  // y[19]
    8'b10110100   // y[20]
  };
  localparam logic [20:0] AES_TOP_CONST = 21'b000000000000000000000;

  localparam logic [7:0] IAES_TOP_ROWS [21] = '{
    8'b10100100,  // y[0]
    8'b00011000,  // y[1]
    8'b11000000,  // y[2]
    8'b00011011,  // y[3]
    8'b11011000,  // y[4]
    8'b01110100,  // y[5]
    8'b11010000,  // y[6]
    8'b00011001,  // y[7]
    8'b11001001,  // y[8]
    8'b11000011,  // y[9]
    8'b11001111,  // y[10]
    8'b11010111,  // y[11]
    8'b01101010,  // y[12]
    8'b01110011,  // y[13]
    8'b01010011,  // y[14]
    8'b01001011,  // y[15]
    8'b01010000,  // y[16]
    8'b10010000,  // y[17]
    8'b00001001,  // y[18]
    8'b00111000,  // y[19]
    8'b00011110   // y[20]
  };
  localparam logic [20:0] IAES_TOP_CONST = 21'b111011101111011010101;

  localparam logic [7:0] SM4_TOP_ROWS [21] = '{
    8'b01100110,  // y[0]
    8'b10011110,  // y[1]
    8'b00011001,  // y[2]
    8'b10001111,  // y[3]
    8'b10000111,  // y[4]
    8'b01100101,  // y[5]
    8'b00000011,  // y[6]
    8'b01011110,  // y[7]
    8'b01011101,  // y[8]
    8'b00001000,  // y[9]
    8'b01000110,  // y[10]
    8'b11011000,  // y[11]
    8'b11100000,  // y[12]
    8'b10111110,  // y[13]
    8'b11010100,  // y[14]
    8'b01001010,  // y[15]
    8'b11000101,  // y[16]
    8'b11011100,  // y[17]
    8'b01000100,  // y[18]
    8'b11110100,  // y[19]
    8'b10000101   // y[20]
  };
  localparam logic [20:0] SM4_TOP_CONST = 21'b000111110000011000001;

  localparam logic [17:0] AES_OUT_ROWS [8] = '{
    18'b110101101100000010,  // y[0]
    18'b000001101100011011,  // y[1]
    18'b110101110111011001,  // y[2]
    18'b011001100001100011,  // y[3]
    18'b101101100001100001,  // y[4]
    18'b010110110100010100,  // y[5]
    18'b001101100001101100,  // y[6]
    18'b100001100001101101   // y[7]
  };
  localparam logic [7:0] AES_OUT_CONST = 8'b01100011;

  localparam logic [17:0] IAES_OUT_ROWS [8] = '{
    18'b000010100010100000,  // y[0]
    18'b100001101100001101,  // y[1]
    18'b001101101100010111,  // y[2]
    18'b010110101111001111,  // y[3]
    18'b010101101100010100,  // y[4]
    18'b111001110111010101,  // y[5]
    18'b111010111001110101,  // y[6]
    18'b100001101100010110   // y[7]
  };
  localparam logic [7:0] IAES_OUT_CONST = 8'b00000000;

  localparam logic [17:0] SM4_OUT_ROWS [8] = '{
    18'b111011011000001110,  // y[0]
    18'b011011000011000011,  // y[1]
    18'b111011011000010101,  // y[2]
    18'b010110100010110100,  // y[3]
    18'b011000011011011000,  // y[4]
    18'b101111000011011010,  // y[5]
    18'b010101110111010100,  // y[6]
    18'b111010101111010101   // y[7]
  };
  localparam logic [7:0] SM4_OUT_CONST = 8'b11010011;
  function automatic logic [20:0] aes_top(input logic [7:0] x);
    for (int k = 0; k < 21; k++) aes_top[k] = (^(AES_TOP_ROWS[k] & x)) ^ AES_TOP_CONST[k];
  endfunction
  function automatic logic [20:0] iaes_top(input logic [7:0] x);
    for (int k = 0; k < 21; k++) iaes_top[k] = (^(IAES_TOP_ROWS[k] & x)) ^ IAES_TOP_CONST[k];
  endfunction
  function automatic logic [20:0] sm4_top(input logic [7:0] x);
    for (int k = 0; k < 21; k++) sm4_top[k] = (^(SM4_TOP_ROWS[k] & x)) ^ SM4_TOP_CONST[k];
  endfunction
  function automatic logic [7:0] aes_out(input logic [17:0] m);
    for (int k = 0; k < 8; k++) aes_out[k] = (^(AES_OUT_ROWS[k] & m)) ^ AES_OUT_CONST[k];
  endfunction
  function automatic logic [7:0] iaes_out(input logic [17:0] m);
    for (int k = 0; k < 8; k++) iaes_out[k] = (^(IAES_OUT_ROWS[k] & m)) ^ IAES_OUT_CONST[k];
  endfunction
  function automatic logic [7:0] sm4_out(input logic [17:0] m);
    for (int k = 0; k < 8; k++) sm4_out[k] = (^(SM4_OUT_ROWS[k] & m)) ^ SM4_OUT_CONST[k];
  endfunction

  // 中层：三种 S 盒共用的 GF(2^4) 求逆电路（21 -> 18）。t[0..23] 把输入组合成 GF(2^4) 元素的各个分量
  // （含 GF(2^4) 乘法的部分积），t[24..45] 是 GF(2^4) 求逆本体，o[*] 是逆元与输入分量的 18 个乘积项，
  // 交给底层的线性层拼回 8 位。逐门照 CryptoUtils.scala 的 SboxInv。
  function automatic logic [17:0] sbox_inv(input logic [20:0] i);
    logic [45:0] t;
    logic [17:0] o;
    t[0] = i[3] ^ i[12];
    t[1] = i[9] & i[5];
    t[2] = i[17] & i[6];
    t[3] = i[10] ^ t[1];
    t[4] = i[14] & i[0];
    t[5] = t[4] ^ t[1];
    t[6] = i[3] & i[12];
    t[7] = i[16] & i[7];
    t[8] = t[0] ^ t[6];
    t[9] = i[15] & i[13];
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
    o[0] = t[38] & i[7];
    o[1] = t[37] & i[13];
    o[2] = t[42] & i[11];
    o[3] = t[45] & i[20];
    o[4] = t[41] & i[8];
    o[5] = t[44] & i[9];
    o[6] = t[40] & i[17];
    o[7] = t[39] & i[14];
    o[8] = t[43] & i[3];
    o[9] = t[38] & i[16];
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

  // ---------------------------------------------------------------------------
  // AES 的行移位与列混合（FIPS-197 5.1.2 / 5.1.3 / 5.3.1 / 5.3.3），作用在 128 位状态的低 64 位（两列）
  //   状态按字节编号：rs1 是字节 0..7、rs2 是字节 8..15，按列优先（字节 4c+r 是第 c 列第 r 行）。
  // ---------------------------------------------------------------------------
  typedef logic [7:0] byte_t;

  // 正向 ShiftRows 后状态的字节 0..7：第 r 行左移 r 列
  function automatic logic [7:0][7:0] shift_rows_fwd(input logic [7:0][7:0] s1, input logic [7:0][7:0] s2);
    return {s1[3], s2[6], s2[1], s1[4], s2[7], s2[2], s1[5], s1[0]};
  endfunction
  // 逆向 ShiftRows 后状态的字节 0..7：第 r 行右移 r 列
  function automatic logic [7:0][7:0] shift_rows_inv(input logic [7:0][7:0] s1, input logic [7:0][7:0] s2);
    return {s2[3], s2[6], s1[1], s1[4], s1[7], s2[2], s2[5], s1[0]};
  endfunction

  // GF(2^8) 上乘以 x（xtime），既约多项式 x^8 + x^4 + x^3 + x + 1
  function automatic byte_t xtime(input byte_t b);
    return {b[6:0], 1'b0} ^ (b[7] ? 8'h1B : 8'h00);
  endfunction
  // GF(2^8) 上乘以 4 位常数 c（c 的每一位选 b·x^k）
  function automatic byte_t gf_mul(input byte_t b, input logic [3:0] c);
    byte_t p, acc;
    p   = b;
    acc = '0;
    for (int k = 0; k < 4; k++) begin
      if (c[k]) acc = acc ^ p;
      p = xtime(p);
    end
    return acc;
  endfunction

  // 一列（4 字节，下标 = 行）的 MixColumns：[2 3 1 1] 的循环矩阵
  function automatic logic [3:0][7:0] mix_column(input logic [3:0][7:0] col);
    for (int r = 0; r < 4; r++) begin
      mix_column[r] = gf_mul(col[r], 4'h2) ^ gf_mul(col[(r+1)%4], 4'h3) ^ col[(r+2)%4] ^ col[(r+3)%4];
    end
  endfunction
  // 一列的 InvMixColumns：[e b d 9] 的循环矩阵
  function automatic logic [3:0][7:0] inv_mix_column(input logic [3:0][7:0] col);
    for (int r = 0; r < 4; r++) begin
      inv_mix_column[r] = gf_mul(col[r], 4'hE) ^ gf_mul(col[(r+1)%4], 4'hB)
                        ^ gf_mul(col[(r+2)%4], 4'hD) ^ gf_mul(col[(r+3)%4], 4'h9);
    end
  endfunction

  // aes64ks1i 的轮常数（FIPS-197 5.2 的 Rcon[1..10]，再加第 10 项 = 0）；下标 11..15 见怪癖 1
  function automatic byte_t aes_rcon(input logic [3:0] rnum);
    case (rnum)
      4'd0:    return 8'h01;
      4'd1:    return 8'h02;
      4'd2:    return 8'h04;
      4'd3:    return 8'h08;
      4'd4:    return 8'h10;
      4'd5:    return 8'h20;
      4'd6:    return 8'h40;
      4'd7:    return 8'h80;
      4'd8:    return 8'h1B;
      4'd9:    return 8'h36;
      4'd10:   return 8'h00;
      default: return 8'h01;   // 保留编码：Chisel Vec 越界读回绕到第 0 项
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // SM4 的线性变换（GB/T 32907-2016）：加密轮 L(B) = B ^ (B<<<2) ^ (B<<<10) ^ (B<<<18) ^ (B<<<24)，
  // 密钥扩展 L'(B) = B ^ (B<<<13) ^ (B<<<23)，B 是**大端**的 32 位字（标准里字节 0 是最高字节）。
  // RISC-V Zksed 把 SM4 的字按小端放进寄存器（寄存器里的字 = 标准字字节反序），所以本模块里
  //   一个 S 盒输出 s 在寄存器视角下位于最低字节 = 标准视角下位于最高字节（s << 24），
  //   变换完再按字节反序放回寄存器视角：result = bswap(L(s << 24))。
  // 这与规范 sm4ed / sm4ks 伪代码里那串"移位 + 掩码"（Scala 原样照抄的就是它）逐位相同；
  // 用标准的 L / L' 写出来，读者可以直接对照 GB/T 32907。
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] rotl32(input logic [31:0] x, input int unsigned n);
    return (n == 0) ? x : ((x << n) | (x >> (32 - n)));
  endfunction
  function automatic logic [31:0] bswap32(input logic [31:0] x);
    return {x[7:0], x[15:8], x[23:16], x[31:24]};
  endfunction
  function automatic logic [31:0] sm4_l_enc(input byte_t s);
    logic [31:0] b;
    b = {s, 24'h0};
    return bswap32(b ^ rotl32(b, 2) ^ rotl32(b, 10) ^ rotl32(b, 18) ^ rotl32(b, 24));
  endfunction
  function automatic logic [31:0] sm4_l_key(input byte_t s);
    logic [31:0] b;
    b = {s, 24'h0};
    return bswap32(b ^ rotl32(b, 13) ^ rotl32(b, 23));
  endfunction
endpackage

module xs_BlockCipherModule_core
  import blockciphermodule_pkg::*;
(
  input  logic        clock,
  input  logic [63:0] src1,         // rs1
  input  logic [63:0] src2,         // rs2
  input  logic [8:0]  func,         // BKUOpType
  input  logic        reg_enable,   // 第 0 拍有效：所有寄存器在此时更新
  output logic [63:0] out
);
  localparam logic [8:0] FUNC_AES64ES   = 9'h20;
  localparam logic [8:0] FUNC_AES64ESM  = 9'h21;
  localparam logic [8:0] FUNC_AES64DS   = 9'h22;
  localparam logic [8:0] FUNC_AES64DSM  = 9'h23;
  localparam logic [8:0] FUNC_AES64IM   = 9'h24;
  localparam logic [8:0] FUNC_AES64KS1I = 9'h25;
  localparam logic [8:0] FUNC_AES64KS2  = 9'h26;
  localparam int unsigned FUNC_SM4_BIT  = 3;    // 1 = SM4（0x28..0x2F）
  localparam int unsigned FUNC_SM4KS_BIT = 2;   // SM4 内：0 = sm4ed，1 = sm4ks

  logic [7:0][7:0] src1_bytes, src2_bytes;
  assign src1_bytes = src1;
  assign src2_bytes = src2;

  // ===========================================================================
  // §1 第 0 拍：各条路径的 S 盒前半段 + 其它要用到的操作数，regEnable 时寄存（全部不复位）
  // ===========================================================================
  // AES 加 / 解密：先行移位，8 个字节各过 S 盒的顶层 + 中层，寄存中层的 18 位
  logic [7:0][7:0] fwd_rows, inv_rows;
  assign fwd_rows = shift_rows_fwd(src1_bytes, src2_bytes);
  assign inv_rows = shift_rows_inv(src1_bytes, src2_bytes);

  // aes64ks1i：rs1 的高字，rnum != 0xA 时循环右移一个字节（RotWord），4 个字节各过 S 盒顶层，寄存顶层的 21 位
  logic [3:0]      ks_rnum;
  logic [3:0][7:0] ks_word;
  assign ks_rnum = src2[3:0];
  assign ks_word = (ks_rnum == 4'hA) ? src1[63:32] : {src1[39:32], src1[63:40]};

  // aes64ks2：两次字异或
  logic [31:0] ks2_w0, ks2_w1;
  assign ks2_w0 = src1[63:32] ^ src2[31:0];
  assign ks2_w1 = ks2_w0 ^ src2[63:32];

  // SM4：本拍 func[1:0] 选 rs2 的一个字节过 S 盒顶层（怪癖 4）
  logic [7:0] sm4_byte;
  assign sm4_byte = src2_bytes[func[1:0]];

  logic [8:0]       func_q;
  logic [7:0][17:0] aes_mid_q;      // AES S 盒中层输出（8 字节）
  logic [7:0][17:0] aes_inv_mid_q;  // AES 逆 S 盒中层输出（8 字节）
  logic [7:0][7:0]  im_src_q;       // aes64im 的输入：rs1 原样
  logic [3:0][20:0] ks_top_q;       // 密钥扩展 S 盒顶层输出（4 字节）
  logic [3:0]       ks_rnum_q;
  logic [63:0]      ks2_q;          // aes64ks2 的结果在第 0 拍就算完了
  logic [20:0]      sm4_top_q;      // SM4 S 盒顶层输出
  logic [31:0]      sm4_rs1_q;      // SM4 最后要异或的 rs1 低字
  always_ff @(posedge clock) begin
    if (reg_enable) begin
      func_q <= func;
      for (int i = 0; i < 8; i++) begin
        aes_mid_q[i]     <= sbox_inv(aes_top(fwd_rows[i]));
        aes_inv_mid_q[i] <= sbox_inv(iaes_top(inv_rows[i]));
      end
      im_src_q <= src1_bytes;
      for (int i = 0; i < 4; i++) begin
        ks_top_q[i] <= aes_top(ks_word[i]);
      end
      ks_rnum_q <= ks_rnum;
      ks2_q     <= {ks2_w1, ks2_w0};
      sm4_top_q <= sm4_top(sm4_byte);
      sm4_rs1_q <= src1[31:0];
    end
  end

  // ===========================================================================
  // §2 第 1 拍：S 盒后半段 + 各指令的结果（组合）
  // ===========================================================================
  // ---- AES 加 / 解密 ----
  logic [7:0][7:0] sub_bytes, inv_sub_bytes;
  for (genvar i = 0; i < 8; i++) begin : g_aes_sbox
    assign sub_bytes[i]     = aes_out(aes_mid_q[i]);
    assign inv_sub_bytes[i] = iaes_out(aes_inv_mid_q[i]);
  end

  logic [63:0] aes64es, aes64esm, aes64ds, aes64dsm, aes64im;
  assign aes64es  = sub_bytes;
  assign aes64ds  = inv_sub_bytes;
  assign aes64esm = {mix_column(sub_bytes[7:4]), mix_column(sub_bytes[3:0])};
  assign aes64dsm = {inv_mix_column(inv_sub_bytes[7:4]), inv_mix_column(inv_sub_bytes[3:0])};
  assign aes64im  = {inv_mix_column(im_src_q[7:4]), inv_mix_column(im_src_q[3:0])};

  // ---- 密钥扩展 ----
  logic [3:0][7:0] ks_sub;
  for (genvar i = 0; i < 4; i++) begin : g_ks_sbox
    assign ks_sub[i] = aes_out(sbox_inv(ks_top_q[i]));
  end
  logic [31:0] ks1_word;
  logic [63:0] aes64ks1i;
  assign ks1_word  = ks_sub ^ {24'h0, aes_rcon(ks_rnum_q)};   // 怪癖 2：只异或最低字节
  assign aes64ks1i = {ks1_word, ks1_word};

  logic [63:0] aes_result;
  always_comb begin
    case (func_q)                    // 怪癖 3：9 位精确比较，不命中给 aes64es
      FUNC_AES64ESM:  aes_result = aes64esm;
      FUNC_AES64DS:   aes_result = aes64ds;
      FUNC_AES64DSM:  aes_result = aes64dsm;
      FUNC_AES64IM:   aes_result = aes64im;
      FUNC_AES64KS1I: aes_result = aes64ks1i;
      FUNC_AES64KS2:  aes_result = ks2_q;
      default:        aes_result = aes64es;
    endcase
  end

  // ---- SM4 ----
  logic [7:0]  sm4_sub;
  logic [31:0] sm4_linear, sm4_word;
  assign sm4_sub    = sm4_out(sbox_inv(sm4_top_q));
  assign sm4_linear = func_q[FUNC_SM4KS_BIT] ? sm4_l_key(sm4_sub) : sm4_l_enc(sm4_sub);
  assign sm4_word   = rotl32(sm4_linear, 8 * func_q[1:0]) ^ sm4_rs1_q;   // 字节号 bs 处的循环左移 8·bs

  assign out = func_q[FUNC_SM4_BIT] ? {{32{sm4_word[31]}}, sm4_word} : aes_result;

`ifndef SYNTHESIS
  // 仿真自检：三段分解串起来就是标准 S 盒（256 个输入逐个核对，见文件头）
  initial begin
    for (int x = 0; x < 256; x++) begin
      if (aes_out(sbox_inv(aes_top(8'(x)))) !== AES_SBOX[x])
        $fatal(1, "BlockCipherModule: AES S 盒分解与 FIPS-197 表不符 x=%02h", x);
      if (iaes_out(sbox_inv(iaes_top(8'(x)))) !== AES_INV_SBOX[x])
        $fatal(1, "BlockCipherModule: AES 逆 S 盒分解与 FIPS-197 表不符 x=%02h", x);
      if (sm4_out(sbox_inv(sm4_top(8'(x)))) !== SM4_SBOX[x])
        $fatal(1, "BlockCipherModule: SM4 S 盒分解与 GB/T 32907 表不符 x=%02h", x);
    end
  end
`endif
endmodule

module BlockCipherModule (
  input         clock,
  input  [63:0] io_src_0,
  input  [63:0] io_src_1,
  input  [8:0]  io_func,
  input         io_regEnable,
  output [63:0] io_out
);
  xs_BlockCipherModule_core u_core (
    .clock      (clock),
    .src1       (io_src_0),
    .src2       (io_src_1),
    .func       (io_func),
    .reg_enable (io_regEnable),
    .out        (io_out)
  );
endmodule
