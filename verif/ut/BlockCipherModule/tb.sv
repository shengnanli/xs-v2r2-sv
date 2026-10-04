// 自动生成：verif/ut/BlockCipherModule/gen.py（scripts/dual_tb_lib.py + 本文件的独立参考模型 / 标准向量）—— 勿手改
// BlockCipherModule：golden vs 重写 BlockCipherModule_xs 逐拍比对；查表参考模型逐条判 golden；FIPS-197 / GB/T 32907 标准向量。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= BlockCipherModule =================
  int unsigned bcm_mode = 0;
  always @(posedge clk) tb.bcm_clock = 1'b1;   // 本模块无 reset 端口，时钟自己驱动（见 gen.py 文件头）
  // ============================ 独立参考模型 ============================
  localparam logic [7:0] REF_SM4_SBOX [256] = '{
    8'hD6, 8'h90, 8'hE9, 8'hFE, 8'hCC, 8'hE1, 8'h3D, 8'hB7, 8'h16, 8'hB6, 8'h14, 8'hC2, 8'h28, 8'hFB, 8'h2C, 8'h05,
    8'h2B, 8'h67, 8'h9A, 8'h76, 8'h2A, 8'hBE, 8'h04, 8'hC3, 8'hAA, 8'h44, 8'h13, 8'h26, 8'h49, 8'h86, 8'h06, 8'h99,
    8'h9C, 8'h42, 8'h50, 8'hF4, 8'h91, 8'hEF, 8'h98, 8'h7A, 8'h33, 8'h54, 8'h0B, 8'h43, 8'hED, 8'hCF, 8'hAC, 8'h62,
    8'hE4, 8'hB3, 8'h1C, 8'hA9, 8'hC9, 8'h08, 8'hE8, 8'h95, 8'h80, 8'hDF, 8'h94, 8'hFA, 8'h75, 8'h8F, 8'h3F, 8'hA6,
    8'h47, 8'h07, 8'hA7, 8'hFC, 8'hF3, 8'h73, 8'h17, 8'hBA, 8'h83, 8'h59, 8'h3C, 8'h19, 8'hE6, 8'h85, 8'h4F, 8'hA8,
    8'h68, 8'h6B, 8'h81, 8'hB2, 8'h71, 8'h64, 8'hDA, 8'h8B, 8'hF8, 8'hEB, 8'h0F, 8'h4B, 8'h70, 8'h56, 8'h9D, 8'h35,
    8'h1E, 8'h24, 8'h0E, 8'h5E, 8'h63, 8'h58, 8'hD1, 8'hA2, 8'h25, 8'h22, 8'h7C, 8'h3B, 8'h01, 8'h21, 8'h78, 8'h87,
    8'hD4, 8'h00, 8'h46, 8'h57, 8'h9F, 8'hD3, 8'h27, 8'h52, 8'h4C, 8'h36, 8'h02, 8'hE7, 8'hA0, 8'hC4, 8'hC8, 8'h9E,
    8'hEA, 8'hBF, 8'h8A, 8'hD2, 8'h40, 8'hC7, 8'h38, 8'hB5, 8'hA3, 8'hF7, 8'hF2, 8'hCE, 8'hF9, 8'h61, 8'h15, 8'hA1,
    8'hE0, 8'hAE, 8'h5D, 8'hA4, 8'h9B, 8'h34, 8'h1A, 8'h55, 8'hAD, 8'h93, 8'h32, 8'h30, 8'hF5, 8'h8C, 8'hB1, 8'hE3,
    8'h1D, 8'hF6, 8'hE2, 8'h2E, 8'h82, 8'h66, 8'hCA, 8'h60, 8'hC0, 8'h29, 8'h23, 8'hAB, 8'h0D, 8'h53, 8'h4E, 8'h6F,
    8'hD5, 8'hDB, 8'h37, 8'h45, 8'hDE, 8'hFD, 8'h8E, 8'h2F, 8'h03, 8'hFF, 8'h6A, 8'h72, 8'h6D, 8'h6C, 8'h5B, 8'h51,
    8'h8D, 8'h1B, 8'hAF, 8'h92, 8'hBB, 8'hDD, 8'hBC, 8'h7F, 8'h11, 8'hD9, 8'h5C, 8'h41, 8'h1F, 8'h10, 8'h5A, 8'hD8,
    8'h0A, 8'hC1, 8'h31, 8'h88, 8'hA5, 8'hCD, 8'h7B, 8'hBD, 8'h2D, 8'h74, 8'hD0, 8'h12, 8'hB8, 8'hE5, 8'hB4, 8'hB0,
    8'h89, 8'h69, 8'h97, 8'h4A, 8'h0C, 8'h96, 8'h77, 8'h7E, 8'h65, 8'hB9, 8'hF1, 8'h09, 8'hC5, 8'h6E, 8'hC6, 8'h84,
    8'h18, 8'hF0, 8'h7D, 8'hEC, 8'h3A, 8'hDC, 8'h4D, 8'h20, 8'h79, 8'hEE, 8'h5F, 8'h3E, 8'hD7, 8'hCB, 8'h39, 8'h48
  };
  logic [7:0] ref_aes_sbox [256];
  logic [7:0] ref_aes_inv_sbox [256];
  function automatic logic [7:0] ref_xtime(input logic [7:0] b);
    return {b[6:0], 1'b0} ^ (b[7] ? 8'h1B : 8'h00);
  endfunction
  function automatic logic [7:0] ref_gmul(input logic [7:0] a, input logic [7:0] b);
    logic [7:0] p = 0;
    for (int k = 0; k < 8; k++) begin
      if (b[k]) p ^= a;
      a = ref_xtime(a);
    end
    return p;
  endfunction
  initial begin   // AES S 盒按 FIPS-197 5.1.1 现算：GF(2^8) 乘法逆元（0 映到 0）后过仿射变换
    for (int x = 0; x < 256; x++) begin
      logic [7:0] inv, s;
      inv = 0;
      for (int y = 1; y < 256; y++) if (ref_gmul(8'(x), 8'(y)) == 8'h01) inv = 8'(y);
      for (int i = 0; i < 8; i++)
        s[i] = inv[i] ^ inv[(i+4)%8] ^ inv[(i+5)%8] ^ inv[(i+6)%8] ^ inv[(i+7)%8] ^ (8'h63 >> i) & 1;
      ref_aes_sbox[x] = s;
    end
    for (int x = 0; x < 256; x++) ref_aes_inv_sbox[ref_aes_sbox[x]] = 8'(x);
  end
  
  // 重写件把 S 盒拆成 顶层仿射 / 中层求逆 / 底层仿射 三段（rtl 的包函数）；这里对 256 个输入逐个核对
  // "三段串起来 == 本 tb 独立算出的标准 S 盒"（RTL 里同样的自检在 ifndef SYNTHESIS 下，UT 定义了 SYNTHESIS）。
  int sbox_selfcheck_fail = 0;
  initial begin
    #1;
    for (int x = 0; x < 256; x++) begin
      if (blockciphermodule_pkg::aes_out(blockciphermodule_pkg::sbox_inv(blockciphermodule_pkg::aes_top(8'(x)))) !== ref_aes_sbox[x])
        sbox_selfcheck_fail++;
      if (blockciphermodule_pkg::iaes_out(blockciphermodule_pkg::sbox_inv(blockciphermodule_pkg::iaes_top(8'(x)))) !== ref_aes_inv_sbox[x])
        sbox_selfcheck_fail++;
      if (blockciphermodule_pkg::sm4_out(blockciphermodule_pkg::sbox_inv(blockciphermodule_pkg::sm4_top(8'(x)))) !== REF_SM4_SBOX[x])
        sbox_selfcheck_fail++;
    end
    $display("[SBOX-SELFCHECK] 768 项，不符 %0d", sbox_selfcheck_fail);
    tb.errors += sbox_selfcheck_fail;
  end
  
  function automatic logic [3:0][7:0] ref_mix(input logic [3:0][7:0] c, input bit inv);
    for (int r = 0; r < 4; r++)
      ref_mix[r] = inv ? (ref_gmul(c[r], 8'h0E) ^ ref_gmul(c[(r+1)%4], 8'h0B) ^ ref_gmul(c[(r+2)%4], 8'h0D) ^ ref_gmul(c[(r+3)%4], 8'h09))
                       : (ref_gmul(c[r], 8'h02) ^ ref_gmul(c[(r+1)%4], 8'h03) ^ c[(r+2)%4] ^ c[(r+3)%4]);
  endfunction
  function automatic logic [31:0] ref_rotl(input logic [31:0] x, input int n);
    return (n == 0) ? x : ((x << n) | (x >> (32 - n)));
  endfunction
  function automatic logic [31:0] ref_bswap(input logic [31:0] x);
    return {x[7:0], x[15:8], x[23:16], x[31:24]};
  endfunction
  // 合法返回 1；结果放 res
  function automatic bit ref_op(input logic [8:0] f, input logic [63:0] a, input logic [63:0] b, output logic [63:0] res);
    logic [15:0][7:0] st;
    logic [7:0][7:0]  sb;
    logic [31:0]      w, y;
    logic [7:0]       s;
    st = {b, a};
    res = '0;
    case (f)
      9'h20, 9'h21: begin    // ShiftRows（第 r 行左移 r 列）+ SubBytes (+ MixColumns)
        for (int i = 0; i < 8; i++) sb[i] = ref_aes_sbox[st[(i + 4 * (i % 4)) % 16]];
        res = (f == 9'h20) ? sb : {ref_mix(sb[7:4], 0), ref_mix(sb[3:0], 0)};
      end
      9'h22, 9'h23: begin    // InvShiftRows（第 r 行右移 r 列）+ InvSubBytes (+ InvMixColumns)
        for (int i = 0; i < 8; i++) sb[i] = ref_aes_inv_sbox[st[(i + 16 - 4 * (i % 4)) % 16]];
        res = (f == 9'h22) ? sb : {ref_mix(sb[7:4], 1), ref_mix(sb[3:0], 1)};
      end
      9'h24: res = {ref_mix(a[63:32], 1), ref_mix(a[31:0], 1)};
      9'h25: begin
        if (b[3:0] > 4'd10) return 0;   // 保留编码
        w = a[63:32];
        if (b[3:0] != 4'hA) w = {w[7:0], w[31:8]};
        for (int i = 0; i < 4; i++) w[8*i +: 8] = ref_aes_sbox[w[8*i +: 8]];
        w[7:0] ^= (b[3:0] == 4'hA) ? 8'h00 : (b[3:0] <= 4'd7) ? (8'h01 << b[3:0]) : (b[3:0] == 4'd8) ? 8'h1B : 8'h36;
        res = {w, w};
      end
      9'h26: begin
        w = a[63:32] ^ b[31:0];
        res = {w ^ b[63:32], w};
      end
      9'h28, 9'h29, 9'h2A, 9'h2B, 9'h2C, 9'h2D, 9'h2E, 9'h2F: begin
        s = REF_SM4_SBOX[b[8*f[1:0] +: 8]];
        w = {s, 24'h0};                                   // 标准（大端）视角下字节在最高位
        y = f[2] ? (w ^ ref_rotl(w, 13) ^ ref_rotl(w, 23))
                 : (w ^ ref_rotl(w, 2) ^ ref_rotl(w, 10) ^ ref_rotl(w, 18) ^ ref_rotl(w, 24));
        y = ref_rotl(ref_bswap(y), 8 * f[1:0]) ^ a[31:0];
        res = {{32{y[31]}}, y};
      end
      default: return 0;
    endcase
    return 1;
  endfunction
  
  // ============================ 标准向量程序 ============================
  // 微程序：0 = 发一条 DUT 指令（rd <- 下一拍的 golden 输出），1 = rd = ra ^ rb（软件），2 = rd = imm，
  //         3 = 检查 rf[ra] 与 imm 在 mask 位上相等
  typedef struct { int kind; logic [8:0] f; int rd; int ra; int rb; bit b_imm; logic [63:0] imm; logic [63:0] mask; string what; } mop_t;
  mop_t prog[$];
  logic [63:0] rf [128];
  int pc = 0, pending_rd = -1, vec_checks = 0, vec_fail = 0;
  bit prog_done = 0;
  localparam int R0 = 127;   // 恒 0
  function automatic void m_dut(logic [8:0] f, int rd, int ra, int rb, bit b_imm = 0, logic [63:0] imm = 0);
    mop_t m; m.kind = 0; m.f = f; m.rd = rd; m.ra = ra; m.rb = rb; m.b_imm = b_imm; m.imm = imm; prog.push_back(m);
  endfunction
  function automatic void m_xor(int rd, int ra, int rb);
    mop_t m; m.kind = 1; m.rd = rd; m.ra = ra; m.rb = rb; prog.push_back(m);
  endfunction
  function automatic void m_li(int rd, logic [63:0] imm);
    mop_t m; m.kind = 2; m.rd = rd; m.imm = imm; prog.push_back(m);
  endfunction
  function automatic void m_chk(int ra, logic [63:0] imm, logic [63:0] mask, string what);
    mop_t m; m.kind = 3; m.ra = ra; m.imm = imm; m.mask = mask; m.what = what; prog.push_back(m);
  endfunction
  function automatic logic [31:0] bsw(input logic [31:0] x); return ref_bswap(x); endfunction
  initial begin
    // ---- FIPS-197 C.1 AES-128 ----  r0/r1 = 密钥两半，r2..r23 = 轮密钥 rk[0..21]，r24 临时，r25/r26 状态
    rf[R0] = 0;
    m_li(0, 64'h0706050403020100); m_li(1, 64'h0f0e0d0c0b0a0908);
    m_xor(2, 0, R0); m_xor(3, 1, R0);
    for (int r = 0; r < 10; r++) begin
      m_dut(9'h25, 24, 1, 0, 1, 64'(r));      // aes64ks1i t, k1, rnum
      m_dut(9'h26, 0, 24, 0);                 // aes64ks2  k0, t, k0
      m_dut(9'h26, 1, 0, 1);                  // aes64ks2  k1, k0, k1
      m_xor(4 + 2 * r, 0, R0); m_xor(5 + 2 * r, 1, R0);
    end
    m_li(25, 64'h7766554433221100); m_li(26, 64'hffeeddccbbaa9988);    // 明文 00112233..ff（小端装入）
    m_xor(25, 25, 2); m_xor(26, 26, 3);
    for (int r = 1; r <= 10; r++) begin
      m_dut((r < 10) ? 9'h21 : 9'h20, 27, 25, 26);
      m_dut((r < 10) ? 9'h21 : 9'h20, 28, 26, 25);
      m_xor(25, 27, 2 + 2 * r); m_xor(26, 28, 3 + 2 * r);
    end
    m_chk(25, 64'h30047b6ad8e0c469, '1, "AES-128 enc ct[0:7]");          // 69c4e0d86a7b0430 d8cdb78070b4c55a
    m_chk(26, 64'h5ac5b47080b7cdd8, '1, "AES-128 enc ct[8:15]");
    m_xor(25, 25, 22); m_xor(26, 26, 23);
    for (int r = 9; r >= 0; r--) begin
      m_dut((r > 0) ? 9'h23 : 9'h22, 27, 25, 26);
      m_dut((r > 0) ? 9'h23 : 9'h22, 28, 26, 25);
      if (r > 0) begin
        m_dut(9'h24, 29, 2 + 2 * r, R0); m_xor(25, 27, 29);
        m_dut(9'h24, 29, 3 + 2 * r, R0); m_xor(26, 28, 29);
      end else begin
        m_xor(25, 27, 2); m_xor(26, 28, 3);
      end
    end
    m_chk(25, 64'h7766554433221100, '1, "AES-128 dec pt[0:7]");
    m_chk(26, 64'hffeeddccbbaa9988, '1, "AES-128 dec pt[8:15]");
    // ---- GB/T 32907-2016 附录 A 例 1 SM4 ----  K[i] 在 r40+i，X[i] 在 r80+i，r116/r117 临时
    begin
      logic [31:0] key [4] = '{32'h01234567, 32'h89abcdef, 32'hfedcba98, 32'h76543210};
      logic [31:0] fk  [4] = '{32'ha3b1bac6, 32'h56aa3350, 32'h677d9197, 32'hb27022dc};
      logic [31:0] ck;
      for (int i = 0; i < 4; i++) begin
        m_li(40 + i, 64'(bsw(key[i] ^ fk[i])));
        m_li(80 + i, 64'(bsw(key[i])));
      end
      for (int i = 0; i < 32; i++) begin
        for (int j = 0; j < 4; j++) ck[31 - 8 * j -: 8] = 8'((4 * i + j) * 7);
        m_li(117, 64'(bsw(ck)));
        m_xor(116, 41 + i, 42 + i); m_xor(116, 116, 43 + i); m_xor(116, 116, 117);
        m_xor(44 + i, 40 + i, R0);
        for (int bs = 0; bs < 4; bs++) m_dut(9'h2C | 9'(bs), 44 + i, 44 + i, 116);   // sm4ks
      end
      for (int i = 0; i < 32; i++) begin
        m_xor(116, 81 + i, 82 + i); m_xor(116, 116, 83 + i); m_xor(116, 116, 44 + i);
        m_xor(84 + i, 80 + i, R0);
        for (int bs = 0; bs < 4; bs++) m_dut(9'h28 | 9'(bs), 84 + i, 84 + i, 116);   // sm4ed
      end
      m_chk(115, 64'(bsw(32'h681edf34)), 64'hffff_ffff, "SM4 ct w0");
      m_chk(114, 64'(bsw(32'hd206965e)), 64'hffff_ffff, "SM4 ct w1");
      m_chk(113, 64'(bsw(32'h86b3e94f)), 64'hffff_ffff, "SM4 ct w2");
      m_chk(112, 64'(bsw(32'h536e4246)), 64'hffff_ffff, "SM4 ct w3");
    end
  end
  localparam int VEC_EXPECT = 8;
  
  // stim 调用：程序没跑完时返回 1 并给出本拍要发的指令（先收上一条 DUT 指令的结果，再执行到下一条 DUT 指令）
  function automatic bit prog_step(output logic [8:0] f, output logic [63:0] a, output logic [63:0] b);
    mop_t m;
    if (pending_rd >= 0) begin rf[pending_rd] = tb.bcm_g_io_out; pending_rd = -1; end
    while (pc < prog.size()) begin
      m = prog[pc++];
      case (m.kind)
        0: begin
          f = m.f; a = rf[m.ra]; b = m.b_imm ? m.imm : rf[m.rb]; pending_rd = m.rd;
          return 1;
        end
        1: rf[m.rd] = rf[m.ra] ^ rf[m.rb];
        2: rf[m.rd] = m.imm;
        3: begin
          vec_checks++;
          if (((rf[m.ra] ^ m.imm) & m.mask) != 0) begin
            vec_fail++; tb.errors++;
            $display("[VECTOR] %s FAILED: got %h expect %h", m.what, rf[m.ra] & m.mask, m.imm);
          end else $display("[VECTOR] %s ok (%h)", m.what, m.imm);
        end
      endcase
    end
    prog_done = 1;
    return 0;
  endfunction
  
  // ---- 每拍：regEnable 的指令下一拍与 golden 输出比（negedge 后 3ns，早于主循环比较点）----
  int ref_cyc = 0, ref_checks = 0, ref_errors = 0;
  int ref_cov [16];
  bit ref_pend = 0;
  logic [63:0] ref_exp;
  logic [8:0] ref_f;
  always @(negedge clk) begin
    logic [63:0] r;
    #3;
    if (ref_pend) begin
      ref_checks++;
      if (tb.bcm_g_io_out !== ref_exp) begin
        ref_errors++; tb.errors++;
        if (ref_errors <= 20) $display("[ORACLE] cyc=%0d func=%h golden=%h ref=%h", ref_cyc, ref_f, tb.bcm_g_io_out, ref_exp);
      end else ref_cov[ref_f[3:0]]++;
    end
    ref_pend = 0;
    if (tb.bcm_io_regEnable) begin
      ref_pend = ref_op(tb.bcm_io_func, tb.bcm_io_src_0, tb.bcm_io_src_1, r);
      ref_exp = r;
      ref_f = tb.bcm_io_func;
    end else if (ref_cyc > 0) begin
      ref_pend = ref_pend;   // 输出保持：寄存器不变，不再重复判
    end
    if (ref_cyc == tb.NCYCLES - 1) ref_gate();
    ref_cyc++;
  end
  function automatic void ref_gate();
    $display("[ORACLE] checks=%0d errors=%0d vector_checks=%0d vector_fail=%0d prog_done=%0d",
             ref_checks, ref_errors, vec_checks, vec_fail, prog_done);
    if (!prog_done || vec_checks != VEC_EXPECT) begin tb.cov_fail++; $display("[VECTOR] 标准向量没跑完"); end
    for (int k = 0; k < 16; k++) begin
      if (k == 7) continue;                 // 0x27 不是合法编码
      $display("[ORACLE-COV] func=%h checks=%0d", 9'h20 + k, ref_cov[k]);
      if (ref_cov[k] < 200) begin tb.cov_fail++; $display("[ORACLE-COV] func=%h < 200", 9'h20 + k); end
    end
  endfunction
  logic bcm_clock;
  logic [63:0] bcm_io_src_0;
  logic [63:0] bcm_io_src_1;
  logic [8:0] bcm_io_func;
  logic bcm_io_regEnable;
  wire  [63:0] bcm_g_io_out, bcm_i_io_out;
  logic [63:0] bcm_s0_io_out = '0, bcm_s1_io_out = '0;
  logic [0:0] bcm_armed = '0;
  int bcm_armed_at = -1;
  BlockCipherModule bcm_u_gold (
    .clock(bcm_clock),
    .io_src_0(bcm_io_src_0),
    .io_src_1(bcm_io_src_1),
    .io_func(bcm_io_func),
    .io_regEnable(bcm_io_regEnable),
    .io_out(bcm_g_io_out)
  );
  BlockCipherModule_xs bcm_u_impl (
    .clock(bcm_clock),
    .io_src_0(bcm_io_src_0),
    .io_src_1(bcm_io_src_1),
    .io_func(bcm_io_func),
    .io_regEnable(bcm_io_regEnable),
    .io_out(bcm_i_io_out)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 500 == 0) bcm_mode = $urandom_range(0, 15);
      bcm_clock = 1'($urandom);
      bcm_io_src_0 = 64'({$urandom, $urandom});
      bcm_io_src_1 = 64'({$urandom, $urandom});
      bcm_io_func = 9'($urandom);
      bcm_io_regEnable = 1'($urandom);
      begin : stim_bcm
        begin
          logic [8:0] pf;
          logic [63:0] pa, pb;
          bcm_clock = 1'b0;
          if (prog_step(pf, pa, pb)) begin
            bcm_io_func = pf; bcm_io_src_0 = pa; bcm_io_src_1 = pb; bcm_io_regEnable = 1'b1;
          end else begin
            bcm_io_regEnable = ($urandom_range(0, 3) != 0);
            case ($urandom_range(0, 15))
              0:       ;                                                   // func 全随机（多为保留编码）
              1:       bcm_io_func = 9'h20 | 9'($urandom_range(0, 15)) | (9'($urandom_range(0, 7)) << 6);   // 高位脏
              default: bcm_io_func = 9'h20 + 9'($urandom_range(0, 15));
            endcase
            if ($urandom_range(0, 1)) bcm_io_src_1[3:0] = 4'($urandom_range(0, 10));   // ks1i 的 rnum 多取合法值
            if ($urandom_range(0, 7) == 0) bcm_io_src_0 = '0;
            if ($urandom_range(0, 7) == 0) bcm_io_src_1 = '1;
          end
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&bcm_armed)) begin
        checks++;
        if (bcm_g_io_out !== bcm_i_io_out) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BlockCipherModule.io_out g=%h i=%h", cyc, bcm_g_io_out, bcm_i_io_out);
        end
        bcm_s1_io_out |= bcm_g_io_out;
        bcm_s0_io_out |= ~bcm_g_io_out;
      end
      if (bcm_io_regEnable) bcm_armed[0] = 1'b1;
      if (bcm_armed_at < 0 && (&bcm_armed)) bcm_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(bcm_s0_io_out[0] && bcm_s1_io_out[0])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[0] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[1] && bcm_s1_io_out[1])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[1] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[2] && bcm_s1_io_out[2])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[2] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[3] && bcm_s1_io_out[3])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[3] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[4] && bcm_s1_io_out[4])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[4] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[5] && bcm_s1_io_out[5])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[5] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[6] && bcm_s1_io_out[6])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[6] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[7] && bcm_s1_io_out[7])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[7] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[8] && bcm_s1_io_out[8])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[8] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[9] && bcm_s1_io_out[9])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[9] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[10] && bcm_s1_io_out[10])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[10] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[11] && bcm_s1_io_out[11])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[11] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[12] && bcm_s1_io_out[12])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[12] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[13] && bcm_s1_io_out[13])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[13] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[14] && bcm_s1_io_out[14])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[14] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[15] && bcm_s1_io_out[15])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[15] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[16] && bcm_s1_io_out[16])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[16] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[17] && bcm_s1_io_out[17])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[17] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[18] && bcm_s1_io_out[18])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[18] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[19] && bcm_s1_io_out[19])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[19] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[20] && bcm_s1_io_out[20])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[20] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[21] && bcm_s1_io_out[21])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[21] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[22] && bcm_s1_io_out[22])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[22] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[23] && bcm_s1_io_out[23])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[23] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[24] && bcm_s1_io_out[24])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[24] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[25] && bcm_s1_io_out[25])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[25] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[26] && bcm_s1_io_out[26])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[26] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[27] && bcm_s1_io_out[27])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[27] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[28] && bcm_s1_io_out[28])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[28] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[29] && bcm_s1_io_out[29])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[29] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[30] && bcm_s1_io_out[30])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[30] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[31] && bcm_s1_io_out[31])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[31] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[32] && bcm_s1_io_out[32])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[32] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[33] && bcm_s1_io_out[33])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[33] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[34] && bcm_s1_io_out[34])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[34] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[35] && bcm_s1_io_out[35])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[35] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[36] && bcm_s1_io_out[36])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[36] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[37] && bcm_s1_io_out[37])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[37] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[38] && bcm_s1_io_out[38])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[38] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[39] && bcm_s1_io_out[39])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[39] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[40] && bcm_s1_io_out[40])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[40] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[41] && bcm_s1_io_out[41])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[41] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[42] && bcm_s1_io_out[42])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[42] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[43] && bcm_s1_io_out[43])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[43] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[44] && bcm_s1_io_out[44])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[44] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[45] && bcm_s1_io_out[45])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[45] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[46] && bcm_s1_io_out[46])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[46] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[47] && bcm_s1_io_out[47])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[47] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[48] && bcm_s1_io_out[48])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[48] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[49] && bcm_s1_io_out[49])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[49] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[50] && bcm_s1_io_out[50])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[50] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[51] && bcm_s1_io_out[51])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[51] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[52] && bcm_s1_io_out[52])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[52] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[53] && bcm_s1_io_out[53])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[53] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[54] && bcm_s1_io_out[54])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[54] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[55] && bcm_s1_io_out[55])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[55] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[56] && bcm_s1_io_out[56])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[56] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[57] && bcm_s1_io_out[57])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[57] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[58] && bcm_s1_io_out[58])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[58] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[59] && bcm_s1_io_out[59])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[59] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[60] && bcm_s1_io_out[60])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[60] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[61] && bcm_s1_io_out[61])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[61] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[62] && bcm_s1_io_out[62])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[62] 未见过 0 和 1"); end
    if (!(bcm_s0_io_out[63] && bcm_s1_io_out[63])) begin cov_fail++; $display("[COV] BlockCipherModule.io_out[63] 未见过 0 和 1"); end
    $display("[ARM] BlockCipherModule armed_at=%0d", bcm_armed_at);
    if (bcm_armed_at < 0) begin cov_fail++; $display("[ARM] BlockCipherModule 从未 arm"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
