// =============================================================================
// tb —— FloatAdderF32WidenF16MixedPipeline UT：golden 与重写件 FloatAdderF32WidenF16MixedPipeline_xs
// 双例化（far/close 子树两侧都是 golden 件），同时钟同激励，每拍比 fp_c / fflags。
//
// 复位域：顶层与子树的寄存器全部 RegEnable(fire) 不复位；子树是独立的流水级，所以 +random 档下
//   要等两次 fire 之后（顶层与子树的寄存器都已被写过）才比对。fire 四分之三的拍为 1。
// 激励：op_code 一半取加减（0/1），其余均匀取 2..0x16/0x1A 的 20 个编码（含未定义编码 0x10/0x13/0x17..）；
//   fp_format bit0 随机；res_widening 1/4，opb_widening / is_vfwredosum 随机；round_mode 均匀 0..7；
//   fp_a/fp_b/widen_a/widen_b 按 "随机 / ±0 / ±Inf / qNaN / sNaN / 次正规 / 指数相等 / 指数差 1" 八种形状轮换
//   （f16 形状按 16 位布局造，高 16 位随机）；widen_a/b 的指数各 1/8 取 0x66 / 0x8F（f16 零/Inf 转出的指数）；
//   1/8 拍两个操作数都是 ±0；打齐 far/close 两条路径与全部特殊值分支；
//   maskForReduction / mask 随机。
// 覆盖（写进 PASS 判据）：22 个 op_code 每个 >= 500；加减类 × {f32, f16, widen} 三格 >= 2000；
//   fflags 非零拍 >= 2000；第 1 拍走 far/close 的拍各 >= 5000（按 golden 内部 is_far_path_reg 统计）；
//   每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（15 输入 / 2 输出）----
  logic io_fire;
  logic [31:0] io_fp_a;
  logic [31:0] io_fp_b;
  logic [31:0] io_widen_a;
  logic [31:0] io_widen_b;
  logic io_is_sub;
  logic io_mask;
  logic [2:0] io_round_mode;
  logic [1:0] io_fp_format;
  logic io_opb_widening;
  logic io_res_widening;
  logic [4:0] io_op_code;
  logic [1:0] io_maskForReduction;
  logic io_is_vfwredosum;
  logic [31:0] g_io_fp_c, i_io_fp_c;
  logic [4:0] g_io_fflags, i_io_fflags;
  FloatAdderF32WidenF16MixedPipeline u_g (
    .clock(clock),
    .io_fire(io_fire),
    .io_fp_a(io_fp_a),
    .io_fp_b(io_fp_b),
    .io_widen_a(io_widen_a),
    .io_widen_b(io_widen_b),
    .io_is_sub(io_is_sub),
    .io_mask(io_mask),
    .io_round_mode(io_round_mode),
    .io_fp_format(io_fp_format),
    .io_opb_widening(io_opb_widening),
    .io_res_widening(io_res_widening),
    .io_op_code(io_op_code),
    .io_maskForReduction(io_maskForReduction),
    .io_is_vfwredosum(io_is_vfwredosum),
    .io_fp_c(g_io_fp_c),
    .io_fflags(g_io_fflags)
  );
  FloatAdderF32WidenF16MixedPipeline_xs u_i (
    .clock(clock),
    .io_fire(io_fire),
    .io_fp_a(io_fp_a),
    .io_fp_b(io_fp_b),
    .io_widen_a(io_widen_a),
    .io_widen_b(io_widen_b),
    .io_is_sub(io_is_sub),
    .io_mask(io_mask),
    .io_round_mode(io_round_mode),
    .io_fp_format(io_fp_format),
    .io_opb_widening(io_opb_widening),
    .io_res_widening(io_res_widening),
    .io_op_code(io_op_code),
    .io_maskForReduction(io_maskForReduction),
    .io_is_vfwredosum(io_is_vfwredosum),
    .io_fp_c(i_io_fp_c),
    .io_fflags(i_io_fflags)
  );
  localparam int N_OUT = 2;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_fp_c, i_io_fp_c, "io_fp_c")
    `CMP(1, g_io_fflags, i_io_fflags, "io_fflags")
  endtask
  task automatic rand_inputs();
    io_fire = 1'($urandom);
    io_fp_a = 32'($urandom);
    io_fp_b = 32'($urandom);
    io_widen_a = 32'($urandom);
    io_widen_b = 32'($urandom);
    io_is_sub = 1'($urandom);
    io_mask = 1'($urandom);
    io_round_mode = 3'($urandom);
    io_fp_format = 2'($urandom);
    io_opb_widening = 1'($urandom);
    io_res_widening = 1'($urandom);
    io_op_code = 5'($urandom);
    io_maskForReduction = 2'($urandom);
    io_is_vfwredosum = 1'($urandom);
  endtask

  localparam int NOPS = 22;
  logic [4:0] OPS [NOPS] = '{5'h00, 5'h01, 5'h02, 5'h03, 5'h04, 5'h05, 5'h06, 5'h07, 5'h08, 5'h09, 5'h0A,
                             5'h0B, 5'h0C, 5'h0D, 5'h0E, 5'h0F, 5'h11, 5'h12, 5'h14, 5'h15, 5'h16, 5'h1A};
  int cov_op [NOPS];
  int cov_addsub_fmt [3];     // f32 / f16 / widen
  int cov_fflags, cov_far, cov_close;
  int fires = 0;

  // 造一个 f32 布局的特殊形状；exp_ref 用来做"指数相等 / 差 1"
  function automatic logic [31:0] shape32(input logic [7:0] exp_ref);
    logic [31:0] x;
    x = $urandom;
    case ($urandom_range(0, 7))
      0: return x;
      1: return {x[31], 31'h0};                            // ±0
      2: return {x[31], 8'hFF, 23'h0};                     // ±Inf
      3: return {x[31], 8'hFF, 1'b1, x[21:0]};             // qNaN
      4: return {x[31], 8'hFF, 1'b0, x[21:1], 1'b1};       // sNaN
      5: return {x[31], 8'h00, x[22:1], 1'b1};             // 次正规
      6: return {x[31], exp_ref, x[22:0]};                 // 指数相等
      default: return {x[31], exp_ref + 8'(($urandom & 1) ? 1 : -1), x[22:0]};  // 指数差 1
    endcase
  endfunction
  function automatic logic [15:0] shape16(input logic [4:0] exp_ref);
    logic [15:0] x;
    x = 16'($urandom);
    case ($urandom_range(0, 7))
      0: return x;
      1: return {x[15], 15'h0};
      2: return {x[15], 5'h1F, 10'h0};
      3: return {x[15], 5'h1F, 1'b1, x[8:0]};
      4: return {x[15], 5'h1F, 1'b0, x[8:1], 1'b1};
      5: return {x[15], 5'h00, x[9:1], 1'b1};
      6: return {x[15], exp_ref, x[9:0]};
      default: return {x[15], exp_ref + 5'(($urandom & 1) ? 1 : -1), x[9:0]};
    endcase
  endfunction

  task automatic drive();
    logic [31:0] a32;
    logic [15:0] a16;
    rand_inputs();
    io_fire = ($urandom_range(0, 3) != 0);
    io_op_code = ($urandom_range(0, 1)) ? 5'($urandom_range(0, 1)) : OPS[$urandom_range(0, NOPS - 1)];
    io_res_widening = ($urandom_range(0, 3) == 0);
    a32 = shape32($urandom);
    io_fp_a = a32;
    io_fp_b = shape32(a32[30:23]);
    io_widen_a = shape32($urandom);
    io_widen_b = shape32(io_widen_a[30:23]);
    // 加宽操作数是前级 f16→f32 转出来的：零/次正规转出来指数 0x66、Inf/NaN 转出来 0x8F，
    // 这两个指数只在加宽路径上有意义，单靠随机 8 位指数打不到，这里各给 1/8
    case ($urandom_range(0, 7))
      0: io_widen_a[30:23] = 8'h66;
      1: io_widen_a[30:23] = 8'h8F;
      default: ;
    endcase
    case ($urandom_range(0, 7))
      0: io_widen_b[30:23] = 8'h66;
      1: io_widen_b[30:23] = 8'h8F;
      default: ;
    endcase
    // 1/8 拍两个操作数都是 ±0（min/max 的 ±0 规则、加宽双零直通）
    if ($urandom_range(0, 7) == 0) begin
      io_fp_a = {1'($urandom), 31'h0}; io_fp_b = {1'($urandom), 31'h0};
      if (!io_fp_format[0]) begin io_fp_a[15:0] = {1'($urandom), 15'h0}; io_fp_b[15:0] = {1'($urandom), 15'h0}; end
      io_widen_a = {1'($urandom), 31'h0}; io_widen_b = {1'($urandom), 31'h0};
    end
    if (!io_fp_format[0]) begin
      a16 = shape16($urandom);
      io_fp_a[15:0] = a16;
      io_fp_b[15:0] = shape16(a16[14:10]);
    end
  endtask

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    io_fire = 0;
    drive(); io_fire = 0;
    @(negedge clock);
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive();
      #2;
      if (fires >= 2) begin
        compare_all();
        for (int j = 0; j < NOPS; j++) if (io_op_code == OPS[j]) cov_op[j]++;
        if (io_op_code < 2) cov_addsub_fmt[io_res_widening ? 2 : (io_fp_format[0] ? 0 : 1)]++;
        if (|g_io_fflags) cov_fflags++;
        if (u_g.is_far_path_reg) cov_far++; else cov_close++;
      end
      @(posedge clock);
      if (io_fire) fires++;
      @(negedge clock);
    end
    bad = 0;
    for (int j = 0; j < NOPS; j++) begin
      $display("cov op=%0h : %0d", OPS[j], cov_op[j]);
      if (cov_op[j] < NCYCLES / 400) bad++;
    end
    $display("cov addsub f32/f16/widen : %0d / %0d / %0d", cov_addsub_fmt[0], cov_addsub_fmt[1], cov_addsub_fmt[2]);
    foreach (cov_addsub_fmt[a]) if (cov_addsub_fmt[a] < NCYCLES / 100) bad++;
    $display("cov fflags!=0 : %0d  far/close : %0d / %0d", cov_fflags, cov_far, cov_close);
    if (cov_fflags < NCYCLES / 100 || cov_far < NCYCLES / 40 || cov_close < NCYCLES / 40) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
