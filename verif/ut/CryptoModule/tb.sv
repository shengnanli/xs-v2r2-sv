// 生成 CryptoModule 的 UT testbench（tb.sv）：双例化逐拍比对 + 哈希分支独立参考模型。
//
// 一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：golden CryptoModule（例化 golden HashModule /
//    BlockCipherModule）vs 重写 CryptoModule_xs（例化重写件 HashModule_xs / BlockCipherModule_xs），逐拍比 io_out。
//    本模块只有 clock、无 reset，全部寄存器无复位：第一次 regEnable 之后才开始比（arm）。
//    func 偏置：1/2 拍取合法密码编码（0x20..0x2F 分组密码类 / 0x30..0x39 哈希类），其余拍任意 9 位
//    （证明 funcReg 只看 bit4、其余位两侧同死）；regEnable 3/4 拍为 1，1/4 拍为 0（保持路径）。
// 二、独立参考模型（只覆盖哈希分支，纯 SV，不读任一实现的内部信号）：tb 自己在 regEnable 拍锁存
//    src0 / func，下一拍起若锁存的 func 是合法哈希编码（0x30..0x37 SHA-256/512 Σ/σ，0x38/0x39 SM3 P0/P1），
//    按 RISC-V Zknh/Zksh 定义算期望值，与 golden 和重写件的 io_out 同时核对。
//    分组密码分支的独立参考模型在 verif/ut/BlockCipherModule（查表 S 盒 + FIPS-197 / GB/T 32907 向量），本层只做差分。
// 覆盖闸：哈希 10 条指令各被 oracle 判过 >= 100 次；输出选择两路各 >= 100 拍；regEnable 保持拍 >= 100；
//    io_out 每位见过 0/1。
//
// 用法：python3 gen.py [--check]
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= CryptoModule =================
  int unsigned cm_mode = 0;
  logic [63:0] ref_src;
  logic [8:0]  ref_func;
  int ref_checks = 0, ref_errors = 0;
  function automatic logic [31:0] ref_ror32(input logic [31:0] x, input int n);
    return (x >> n) | (x << (32 - n));
  endfunction
  function automatic logic [63:0] ref_ror64(input logic [63:0] x, input int n);
    return (x >> n) | (x << (64 - n));
  endfunction
  function automatic logic [31:0] ref_rol32(input logic [31:0] x, input int n);
    return (x << n) | (x >> (32 - n));
  endfunction
  // Zknh / Zksh 指令定义（规范原式；SM3 用左旋写法，与 Chisel 的右旋写法独立）
  function automatic logic [63:0] ref_hash(input logic [63:0] x, input logic [8:0] f);
    logic [31:0] w, r;
    w = x[31:0];
    case (f)
      9'h30: begin r = ref_ror32(w, 2) ^ ref_ror32(w, 13) ^ ref_ror32(w, 22); return {{32{r[31]}}, r}; end
      9'h31: begin r = ref_ror32(w, 6) ^ ref_ror32(w, 11) ^ ref_ror32(w, 25); return {{32{r[31]}}, r}; end
      9'h32: begin r = ref_ror32(w, 7) ^ ref_ror32(w, 18) ^ (w >> 3);         return {{32{r[31]}}, r}; end
      9'h33: begin r = ref_ror32(w, 17) ^ ref_ror32(w, 19) ^ (w >> 10);       return {{32{r[31]}}, r}; end
      9'h34: return ref_ror64(x, 28) ^ ref_ror64(x, 34) ^ ref_ror64(x, 39);
      9'h35: return ref_ror64(x, 14) ^ ref_ror64(x, 18) ^ ref_ror64(x, 41);
      9'h36: return ref_ror64(x, 1) ^ ref_ror64(x, 8) ^ (x >> 7);
      9'h37: return ref_ror64(x, 19) ^ ref_ror64(x, 61) ^ (x >> 6);
      9'h38: begin r = w ^ ref_rol32(w, 9) ^ ref_rol32(w, 17);  return {{32{r[31]}}, r}; end
      default: begin r = w ^ ref_rol32(w, 15) ^ ref_rol32(w, 23); return {{32{r[31]}}, r}; end
    endcase
  endfunction
  // 比较点（negedge 后 #4，与差分同一时刻）：锁存的 func 是合法哈希编码才判
  always @(negedge clk) begin
    #4;
    if (tb.cm_armed_at >= 0 && cyc >= tb.cm_armed_at && ref_func >= 9'h30 && ref_func <= 9'h39) begin
      ref_checks++;
      if (tb.cm_g_io_out !== ref_hash(ref_src, ref_func) || tb.cm_i_io_out !== ref_hash(ref_src, ref_func)) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d func=%h src=%h ref=%h g=%h i=%h", cyc, ref_func, ref_src,
                                       ref_hash(ref_src, ref_func), tb.cm_g_io_out, tb.cm_i_io_out);
      end
    end
  end
  always @(posedge clk) if (tb.cm_io_regEnable) begin ref_src <= tb.cm_io_src_0; ref_func <= tb.cm_io_func; end
  final $display("[ORACLE] hash checks=%0d errors=%0d", ref_checks, ref_errors);
  logic [63:0] cm_io_src_0;
  logic [63:0] cm_io_src_1;
  logic [8:0] cm_io_func;
  logic cm_io_regEnable;
  wire  [63:0] cm_g_io_out, cm_i_io_out;
  logic [63:0] cm_s0_io_out = '0, cm_s1_io_out = '0;
  int cm_cov_sel_hash = 0;
  int cm_cov_sel_cipher = 0;
  int cm_cov_hold = 0;
  int cm_cov_oracle_30 = 0;
  int cm_cov_oracle_31 = 0;
  int cm_cov_oracle_32 = 0;
  int cm_cov_oracle_33 = 0;
  int cm_cov_oracle_34 = 0;
  int cm_cov_oracle_35 = 0;
  int cm_cov_oracle_36 = 0;
  int cm_cov_oracle_37 = 0;
  int cm_cov_oracle_38 = 0;
  int cm_cov_oracle_39 = 0;
  logic [0:0] cm_armed = '0;
  int cm_armed_at = -1;
  CryptoModule cm_u_gold (
    .clock(clk),
    .io_src_0(cm_io_src_0),
    .io_src_1(cm_io_src_1),
    .io_func(cm_io_func),
    .io_regEnable(cm_io_regEnable),
    .io_out(cm_g_io_out)
  );
  CryptoModule_xs cm_u_impl (
    .clock(clk),
    .io_src_0(cm_io_src_0),
    .io_src_1(cm_io_src_1),
    .io_func(cm_io_func),
    .io_regEnable(cm_io_regEnable),
    .io_out(cm_i_io_out)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) cm_mode = $urandom_range(0, 15);
      cm_io_src_0 = 64'({$urandom, $urandom});
      cm_io_src_1 = 64'({$urandom, $urandom});
      cm_io_func = 9'($urandom);
      cm_io_regEnable = 1'($urandom);
      begin : stim_cm
        case ($urandom_range(0, 3))
          0: cm_io_func = 9'h20 + $urandom_range(0, 15);   // 分组密码类 aes*/sm4*
          1: cm_io_func = 9'h30 + $urandom_range(0, 9);    // 哈希类 sha*/sm3*
          default: ;                                      // 任意 9 位
        endcase
        cm_io_regEnable = ($urandom_range(0, 3) != 0);
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&cm_armed)) begin
        checks++;
        if (cm_g_io_out !== cm_i_io_out) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CryptoModule.io_out g=%h i=%h", cyc, cm_g_io_out, cm_i_io_out);
        end
        cm_s1_io_out |= cm_g_io_out;
        cm_s0_io_out |= ~cm_g_io_out;
        if (ref_func[4]) cm_cov_sel_hash++;
        if (!ref_func[4]) cm_cov_sel_cipher++;
        if (!cm_io_regEnable) cm_cov_hold++;
        if (ref_func == 9'h30) cm_cov_oracle_30++;
        if (ref_func == 9'h31) cm_cov_oracle_31++;
        if (ref_func == 9'h32) cm_cov_oracle_32++;
        if (ref_func == 9'h33) cm_cov_oracle_33++;
        if (ref_func == 9'h34) cm_cov_oracle_34++;
        if (ref_func == 9'h35) cm_cov_oracle_35++;
        if (ref_func == 9'h36) cm_cov_oracle_36++;
        if (ref_func == 9'h37) cm_cov_oracle_37++;
        if (ref_func == 9'h38) cm_cov_oracle_38++;
        if (ref_func == 9'h39) cm_cov_oracle_39++;
      end
      if (cm_io_regEnable) cm_armed[0] = 1'b1;
      if (cm_armed_at < 0 && (&cm_armed)) cm_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(cm_s0_io_out[0] && cm_s1_io_out[0])) begin cov_fail++; $display("[COV] CryptoModule.io_out[0] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[1] && cm_s1_io_out[1])) begin cov_fail++; $display("[COV] CryptoModule.io_out[1] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[2] && cm_s1_io_out[2])) begin cov_fail++; $display("[COV] CryptoModule.io_out[2] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[3] && cm_s1_io_out[3])) begin cov_fail++; $display("[COV] CryptoModule.io_out[3] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[4] && cm_s1_io_out[4])) begin cov_fail++; $display("[COV] CryptoModule.io_out[4] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[5] && cm_s1_io_out[5])) begin cov_fail++; $display("[COV] CryptoModule.io_out[5] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[6] && cm_s1_io_out[6])) begin cov_fail++; $display("[COV] CryptoModule.io_out[6] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[7] && cm_s1_io_out[7])) begin cov_fail++; $display("[COV] CryptoModule.io_out[7] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[8] && cm_s1_io_out[8])) begin cov_fail++; $display("[COV] CryptoModule.io_out[8] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[9] && cm_s1_io_out[9])) begin cov_fail++; $display("[COV] CryptoModule.io_out[9] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[10] && cm_s1_io_out[10])) begin cov_fail++; $display("[COV] CryptoModule.io_out[10] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[11] && cm_s1_io_out[11])) begin cov_fail++; $display("[COV] CryptoModule.io_out[11] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[12] && cm_s1_io_out[12])) begin cov_fail++; $display("[COV] CryptoModule.io_out[12] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[13] && cm_s1_io_out[13])) begin cov_fail++; $display("[COV] CryptoModule.io_out[13] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[14] && cm_s1_io_out[14])) begin cov_fail++; $display("[COV] CryptoModule.io_out[14] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[15] && cm_s1_io_out[15])) begin cov_fail++; $display("[COV] CryptoModule.io_out[15] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[16] && cm_s1_io_out[16])) begin cov_fail++; $display("[COV] CryptoModule.io_out[16] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[17] && cm_s1_io_out[17])) begin cov_fail++; $display("[COV] CryptoModule.io_out[17] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[18] && cm_s1_io_out[18])) begin cov_fail++; $display("[COV] CryptoModule.io_out[18] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[19] && cm_s1_io_out[19])) begin cov_fail++; $display("[COV] CryptoModule.io_out[19] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[20] && cm_s1_io_out[20])) begin cov_fail++; $display("[COV] CryptoModule.io_out[20] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[21] && cm_s1_io_out[21])) begin cov_fail++; $display("[COV] CryptoModule.io_out[21] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[22] && cm_s1_io_out[22])) begin cov_fail++; $display("[COV] CryptoModule.io_out[22] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[23] && cm_s1_io_out[23])) begin cov_fail++; $display("[COV] CryptoModule.io_out[23] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[24] && cm_s1_io_out[24])) begin cov_fail++; $display("[COV] CryptoModule.io_out[24] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[25] && cm_s1_io_out[25])) begin cov_fail++; $display("[COV] CryptoModule.io_out[25] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[26] && cm_s1_io_out[26])) begin cov_fail++; $display("[COV] CryptoModule.io_out[26] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[27] && cm_s1_io_out[27])) begin cov_fail++; $display("[COV] CryptoModule.io_out[27] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[28] && cm_s1_io_out[28])) begin cov_fail++; $display("[COV] CryptoModule.io_out[28] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[29] && cm_s1_io_out[29])) begin cov_fail++; $display("[COV] CryptoModule.io_out[29] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[30] && cm_s1_io_out[30])) begin cov_fail++; $display("[COV] CryptoModule.io_out[30] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[31] && cm_s1_io_out[31])) begin cov_fail++; $display("[COV] CryptoModule.io_out[31] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[32] && cm_s1_io_out[32])) begin cov_fail++; $display("[COV] CryptoModule.io_out[32] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[33] && cm_s1_io_out[33])) begin cov_fail++; $display("[COV] CryptoModule.io_out[33] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[34] && cm_s1_io_out[34])) begin cov_fail++; $display("[COV] CryptoModule.io_out[34] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[35] && cm_s1_io_out[35])) begin cov_fail++; $display("[COV] CryptoModule.io_out[35] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[36] && cm_s1_io_out[36])) begin cov_fail++; $display("[COV] CryptoModule.io_out[36] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[37] && cm_s1_io_out[37])) begin cov_fail++; $display("[COV] CryptoModule.io_out[37] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[38] && cm_s1_io_out[38])) begin cov_fail++; $display("[COV] CryptoModule.io_out[38] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[39] && cm_s1_io_out[39])) begin cov_fail++; $display("[COV] CryptoModule.io_out[39] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[40] && cm_s1_io_out[40])) begin cov_fail++; $display("[COV] CryptoModule.io_out[40] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[41] && cm_s1_io_out[41])) begin cov_fail++; $display("[COV] CryptoModule.io_out[41] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[42] && cm_s1_io_out[42])) begin cov_fail++; $display("[COV] CryptoModule.io_out[42] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[43] && cm_s1_io_out[43])) begin cov_fail++; $display("[COV] CryptoModule.io_out[43] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[44] && cm_s1_io_out[44])) begin cov_fail++; $display("[COV] CryptoModule.io_out[44] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[45] && cm_s1_io_out[45])) begin cov_fail++; $display("[COV] CryptoModule.io_out[45] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[46] && cm_s1_io_out[46])) begin cov_fail++; $display("[COV] CryptoModule.io_out[46] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[47] && cm_s1_io_out[47])) begin cov_fail++; $display("[COV] CryptoModule.io_out[47] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[48] && cm_s1_io_out[48])) begin cov_fail++; $display("[COV] CryptoModule.io_out[48] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[49] && cm_s1_io_out[49])) begin cov_fail++; $display("[COV] CryptoModule.io_out[49] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[50] && cm_s1_io_out[50])) begin cov_fail++; $display("[COV] CryptoModule.io_out[50] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[51] && cm_s1_io_out[51])) begin cov_fail++; $display("[COV] CryptoModule.io_out[51] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[52] && cm_s1_io_out[52])) begin cov_fail++; $display("[COV] CryptoModule.io_out[52] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[53] && cm_s1_io_out[53])) begin cov_fail++; $display("[COV] CryptoModule.io_out[53] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[54] && cm_s1_io_out[54])) begin cov_fail++; $display("[COV] CryptoModule.io_out[54] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[55] && cm_s1_io_out[55])) begin cov_fail++; $display("[COV] CryptoModule.io_out[55] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[56] && cm_s1_io_out[56])) begin cov_fail++; $display("[COV] CryptoModule.io_out[56] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[57] && cm_s1_io_out[57])) begin cov_fail++; $display("[COV] CryptoModule.io_out[57] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[58] && cm_s1_io_out[58])) begin cov_fail++; $display("[COV] CryptoModule.io_out[58] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[59] && cm_s1_io_out[59])) begin cov_fail++; $display("[COV] CryptoModule.io_out[59] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[60] && cm_s1_io_out[60])) begin cov_fail++; $display("[COV] CryptoModule.io_out[60] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[61] && cm_s1_io_out[61])) begin cov_fail++; $display("[COV] CryptoModule.io_out[61] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[62] && cm_s1_io_out[62])) begin cov_fail++; $display("[COV] CryptoModule.io_out[62] 未见过 0 和 1"); end
    if (!(cm_s0_io_out[63] && cm_s1_io_out[63])) begin cov_fail++; $display("[COV] CryptoModule.io_out[63] 未见过 0 和 1"); end
    $display("[ARM] CryptoModule armed_at=%0d", cm_armed_at);
    if (cm_armed_at < 0) begin cov_fail++; $display("[ARM] CryptoModule 从未 arm"); end
    $display("[COV] CryptoModule.sel_hash = %0d", cm_cov_sel_hash);
    if (cm_cov_sel_hash < 100) begin cov_fail++; $display("[COV] CryptoModule.sel_hash < 100"); end
    $display("[COV] CryptoModule.sel_cipher = %0d", cm_cov_sel_cipher);
    if (cm_cov_sel_cipher < 100) begin cov_fail++; $display("[COV] CryptoModule.sel_cipher < 100"); end
    $display("[COV] CryptoModule.hold = %0d", cm_cov_hold);
    if (cm_cov_hold < 100) begin cov_fail++; $display("[COV] CryptoModule.hold < 100"); end
    $display("[COV] CryptoModule.oracle_30 = %0d", cm_cov_oracle_30);
    if (cm_cov_oracle_30 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_30 < 100"); end
    $display("[COV] CryptoModule.oracle_31 = %0d", cm_cov_oracle_31);
    if (cm_cov_oracle_31 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_31 < 100"); end
    $display("[COV] CryptoModule.oracle_32 = %0d", cm_cov_oracle_32);
    if (cm_cov_oracle_32 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_32 < 100"); end
    $display("[COV] CryptoModule.oracle_33 = %0d", cm_cov_oracle_33);
    if (cm_cov_oracle_33 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_33 < 100"); end
    $display("[COV] CryptoModule.oracle_34 = %0d", cm_cov_oracle_34);
    if (cm_cov_oracle_34 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_34 < 100"); end
    $display("[COV] CryptoModule.oracle_35 = %0d", cm_cov_oracle_35);
    if (cm_cov_oracle_35 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_35 < 100"); end
    $display("[COV] CryptoModule.oracle_36 = %0d", cm_cov_oracle_36);
    if (cm_cov_oracle_36 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_36 < 100"); end
    $display("[COV] CryptoModule.oracle_37 = %0d", cm_cov_oracle_37);
    if (cm_cov_oracle_37 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_37 < 100"); end
    $display("[COV] CryptoModule.oracle_38 = %0d", cm_cov_oracle_38);
    if (cm_cov_oracle_38 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_38 < 100"); end
    $display("[COV] CryptoModule.oracle_39 = %0d", cm_cov_oracle_39);
    if (cm_cov_oracle_39 < 100) begin cov_fail++; $display("[COV] CryptoModule.oracle_39 < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
