// 自动生成：verif/ut/VectorFloatFMA/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// VectorFloatFMA 双例化逐拍比对：golden VectorFloatFMA vs 重写 VectorFloatFMA_xs，io_fp_result / io_fflags 逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= VectorFloatFMA =================
  int unsigned fa_mode = 0;
  int unsigned fa_op;       // 本拍操作（0..8；9 = op_code 全随机）
  int unsigned fa_fmt;      // 0 = f16, 1 = f32, 2 = f64；3 = fp_format 全随机
  logic        fa_widen;
  
  // 尾数偏置
  function automatic logic [63:0] fa_frac(input int fw);
    logic [63:0] f;
    f = {$urandom, $urandom};
    case ($urandom_range(0, 9))
      0:       f = 64'h0;
      1:       f = ~64'h0;
      2:       f = 64'h1;
      3:       f = 64'h1 << (fw - 1);
      4:       f = (f >> (fw / 2)) << (fw / 2);        // 低半段为 0
      5:       f = ~(64'h1 << $urandom_range(0, fw - 1)); // 只有一位 0
      default: ;
    endcase
    return f & ((64'h1 << fw) - 64'h1);
  endfunction
  function automatic logic [63:0] fa_pack(input int ew, input int fw, input logic s, input logic [63:0] e, input logic [63:0] f);
    return (64'(s) << (ew + fw)) | ((e & ((64'h1 << ew) - 64'h1)) << fw) | (f & ((64'h1 << fw) - 64'h1));
  endfunction
  // 场景 A：特殊值混合
  function automatic logic [63:0] fa_any(input int ew, input int fw);
    logic        s;
    logic [63:0] emax, bias, e, f;
    s    = 1'($urandom);
    emax = (64'h1 << ew) - 64'h1;
    bias = (64'h1 << (ew - 1)) - 64'h1;
    f    = fa_frac(fw);
    case ($urandom_range(0, 15))
      0:       return fa_pack(ew, fw, s, 64'h0, 64'h0);                            // ±0
      1:       return fa_pack(ew, fw, s, emax, 64'h0);                             // ±inf
      2:       return fa_pack(ew, fw, s, emax, f | (64'h1 << (fw - 1)));           // qNaN
      3:       return fa_pack(ew, fw, s, emax, (f & ~(64'h1 << (fw - 1))) | 64'h1);// sNaN
      4:       return fa_pack(ew, fw, s, 64'h0, f | 64'h1);                        // 次正规
      5:       return fa_pack(ew, fw, s, 64'h0, ($urandom_range(0, 1) == 0) ? 64'h1 : ~64'h0);
      6:       return fa_pack(ew, fw, s, 64'h1, ($urandom_range(0, 1) == 0) ? 64'h0 : f);   // 最小规格化数附近
      7:       return fa_pack(ew, fw, s, emax - 64'h1, ($urandom_range(0, 1) == 0) ? ~64'h0 : f); // 最大规格化数附近
      8, 9:    return fa_pack(ew, fw, s, bias + 64'($urandom_range(0, 2)) - 64'h1, f);  // 1.0 附近
      10, 11, 12: begin
        e = bias + 64'($urandom_range(0, 2 * fw + 8)) - 64'(fw + 4);                // 偏置附近
        return fa_pack(ew, fw, s, e, f);
      end
      default: return {$urandom, $urandom};
    endcase
  endfunction
  // 生成一个元素的 x*y+z 三元组。源格式 (sew, sfw)，结果格式 (ew, fw)。
  task automatic fa_triplet(input int sew, input int sfw, input int ew, input int fw,
                            output logic [63:0] x, output logic [63:0] y, output logic [63:0] z);
    int          sbias, bias, emax, semax, ea, eb, te, ec, d;
    logic [63:0] fx, fy, fz;
    sbias = (1 << (sew - 1)) - 1;
    bias  = (1 << (ew - 1)) - 1;
    emax  = (1 << ew) - 1;
    semax = (1 << sew) - 1;
    case ($urandom_range(0, 15))
      0, 1, 2, 3: begin  // A
        x = fa_any(sew, sfw); y = fa_any(sew, sfw); z = fa_any(ew, fw);
      end
      4, 5, 6, 7: begin  // B 指数配平：结果指数 te = ea + eb - 2*sbias + bias
        case ($urandom_range(0, 3))
          0:       te = $urandom_range(0, fw + 6) - (fw + 3);         // 下溢边界
          1:       te = emax - 4 + $urandom_range(0, 6);              // 溢出边界
          default: te = $urandom_range(1, emax - 1);
        endcase
        // ea + eb = te - bias + 2*sbias，在 [1, semax-1] 内拆分（拆不出来就夹住）
        d  = te - bias + 2 * sbias;
        ea = $urandom_range(1, semax - 1);
        eb = d - ea;
        if (eb < 0) begin eb = $urandom_range(0, 1); ea = d - eb; end
        if (eb > semax - 1) begin eb = semax - 1; ea = d - eb; end
        if (ea < 0) ea = 0;
        if (ea > semax - 1) ea = semax - 1;
        x  = fa_pack(sew, sfw, 1'($urandom), 64'(ea), fa_frac(sfw));
        y  = fa_pack(sew, sfw, 1'($urandom), 64'(eb), fa_frac(sfw));
        ec = te + $urandom_range(0, 3 * fw + 12) - (2 * fw + 6);
        if (ec < 0) ec = 0;
        if (ec > emax - 1) ec = emax - 1;
        z  = ($urandom_range(0, 3) == 0) ? fa_any(ew, fw) : fa_pack(ew, fw, 1'($urandom), 64'(ec), fa_frac(fw));
      end
      8, 9, 10, 11: begin  // C 抵消
        ea = $urandom_range(1, semax - 1);
        eb = sbias + $urandom_range(0, 6) - 3;
        if (eb < 1) eb = 1;
        if (eb > semax - 1) eb = semax - 1;
        fx = fa_frac(sfw);
        fy = ($urandom_range(0, 2) == 0) ? (64'h1 << (sfw - 1)) : 64'h0;   // 1.5 或 1.0
        x  = fa_pack(sew, sfw, 1'($urandom), 64'(ea), fx);
        y  = fa_pack(sew, sfw, 1'($urandom), 64'(eb), fy);
        te = ea + eb - 2 * sbias + bias + $urandom_range(0, 8) / 4 - 1;     // 多数为 0 偏移，少数 ±1
        if (te < 1) te = 1;
        if (te > emax - 1) te = emax - 1;
        fz = fx << (fw - sfw);
        case ($urandom_range(0, 5))
          0:       fz = fz ^ 64'h1;
          1:       fz = fz + 64'h1;
          2:       fz = fz ^ (64'h1 << $urandom_range(0, fw - 1));
          3:       fz = fz ^ 64'($urandom_range(0, 15));
          default: ;
        endcase
        z  = fa_pack(ew, fw, 1'($urandom), 64'(te), fz);
      end
      12: begin  // E 特殊值配对：inf*0、inf+inf（符号随机，一半是 inf-inf）、有限数+inf
        x = fa_pack(sew, sfw, 1'($urandom), 64'(semax), 64'h0);
        z = fa_any(ew, fw);
        case ($urandom_range(0, 3))
          0:       y = fa_pack(sew, sfw, 1'($urandom), 64'h0, 64'h0);
          1:       begin y = fa_pack(sew, sfw, 1'($urandom), 64'(sbias), fa_frac(sfw)); z = fa_pack(ew, fw, 1'($urandom), 64'(emax), 64'h0); end
          2:       begin y = x; x = fa_pack(sew, sfw, 1'($urandom), 64'h0, 64'h0); end
          default: begin x = fa_pack(sew, sfw, 1'($urandom), 64'(sbias), fa_frac(sfw)); y = fa_pack(sew, sfw, 1'($urandom), 64'(sbias), fa_frac(sfw));
                         z = fa_pack(ew, fw, 1'($urandom), 64'(emax), 64'h0); end
        endcase
      end
      default: begin  // D
        x = {$urandom, $urandom}; y = {$urandom, $urandom}; z = {$urandom, $urandom};
      end
    endcase
  endtask
  logic fa_reset;
  logic fa_io_fire;
  logic [63:0] fa_io_fp_a;
  logic [63:0] fa_io_fp_b;
  logic [63:0] fa_io_fp_c;
  logic fa_io_uop_idx;
  logic [63:0] fa_io_widen_a;
  logic [63:0] fa_io_widen_b;
  logic [2:0] fa_io_round_mode;
  logic [1:0] fa_io_fp_format;
  logic [3:0] fa_io_op_code;
  logic fa_io_res_widening;
  wire  [63:0] fa_g_io_fp_result, fa_i_io_fp_result;
  logic [63:0] fa_s0_io_fp_result = '0, fa_s1_io_fp_result = '0;
  wire  [19:0] fa_g_io_fflags, fa_i_io_fflags;
  logic [19:0] fa_s0_io_fflags = '0, fa_s1_io_fflags = '0;
  int fa_cov_vfmul_f16_same = 0;
  int fa_cov_vfmul_f16_widen = 0;
  int fa_cov_vfmul_f32_same = 0;
  int fa_cov_vfmul_f32_widen = 0;
  int fa_cov_vfmul_f64_same = 0;
  int fa_cov_vfmul_f64_widen = 0;
  int fa_cov_vfmacc_f16_same = 0;
  int fa_cov_vfmacc_f16_widen = 0;
  int fa_cov_vfmacc_f32_same = 0;
  int fa_cov_vfmacc_f32_widen = 0;
  int fa_cov_vfmacc_f64_same = 0;
  int fa_cov_vfmacc_f64_widen = 0;
  int fa_cov_vfnmacc_f16_same = 0;
  int fa_cov_vfnmacc_f16_widen = 0;
  int fa_cov_vfnmacc_f32_same = 0;
  int fa_cov_vfnmacc_f32_widen = 0;
  int fa_cov_vfnmacc_f64_same = 0;
  int fa_cov_vfnmacc_f64_widen = 0;
  int fa_cov_vfmsac_f16_same = 0;
  int fa_cov_vfmsac_f16_widen = 0;
  int fa_cov_vfmsac_f32_same = 0;
  int fa_cov_vfmsac_f32_widen = 0;
  int fa_cov_vfmsac_f64_same = 0;
  int fa_cov_vfmsac_f64_widen = 0;
  int fa_cov_vfnmsac_f16_same = 0;
  int fa_cov_vfnmsac_f16_widen = 0;
  int fa_cov_vfnmsac_f32_same = 0;
  int fa_cov_vfnmsac_f32_widen = 0;
  int fa_cov_vfnmsac_f64_same = 0;
  int fa_cov_vfnmsac_f64_widen = 0;
  int fa_cov_vfmadd_f16_same = 0;
  int fa_cov_vfmadd_f16_widen = 0;
  int fa_cov_vfmadd_f32_same = 0;
  int fa_cov_vfmadd_f32_widen = 0;
  int fa_cov_vfmadd_f64_same = 0;
  int fa_cov_vfmadd_f64_widen = 0;
  int fa_cov_vfnmadd_f16_same = 0;
  int fa_cov_vfnmadd_f16_widen = 0;
  int fa_cov_vfnmadd_f32_same = 0;
  int fa_cov_vfnmadd_f32_widen = 0;
  int fa_cov_vfnmadd_f64_same = 0;
  int fa_cov_vfnmadd_f64_widen = 0;
  int fa_cov_vfmsub_f16_same = 0;
  int fa_cov_vfmsub_f16_widen = 0;
  int fa_cov_vfmsub_f32_same = 0;
  int fa_cov_vfmsub_f32_widen = 0;
  int fa_cov_vfmsub_f64_same = 0;
  int fa_cov_vfmsub_f64_widen = 0;
  int fa_cov_vfnmsub_f16_same = 0;
  int fa_cov_vfnmsub_f16_widen = 0;
  int fa_cov_vfnmsub_f32_same = 0;
  int fa_cov_vfnmsub_f32_widen = 0;
  int fa_cov_vfnmsub_f64_same = 0;
  int fa_cov_vfnmsub_f64_widen = 0;
  int fa_cov_randop_f16 = 0;
  int fa_cov_randop_f32 = 0;
  int fa_cov_randop_f64 = 0;
  int fa_cov_fmt0_as_f16 = 0;
  int fa_cov_op_undefined = 0;
  int fa_cov_fire_gap = 0;
  int fa_cov_uop_idx_widen = 0;
  int fa_cov_rne_f16 = 0;
  int fa_cov_rtz_f16 = 0;
  int fa_cov_rdn_f16 = 0;
  int fa_cov_rup_f16 = 0;
  int fa_cov_rmm_f16 = 0;
  int fa_cov_rm_invalid_f16 = 0;
  int fa_cov_flag_NV_f16 = 0;
  int fa_cov_flag_OF_f16 = 0;
  int fa_cov_flag_UF_f16 = 0;
  int fa_cov_flag_NX_f16 = 0;
  int fa_cov_rne_f32 = 0;
  int fa_cov_rtz_f32 = 0;
  int fa_cov_rdn_f32 = 0;
  int fa_cov_rup_f32 = 0;
  int fa_cov_rmm_f32 = 0;
  int fa_cov_rm_invalid_f32 = 0;
  int fa_cov_flag_NV_f32 = 0;
  int fa_cov_flag_OF_f32 = 0;
  int fa_cov_flag_UF_f32 = 0;
  int fa_cov_flag_NX_f32 = 0;
  int fa_cov_rne_f64 = 0;
  int fa_cov_rtz_f64 = 0;
  int fa_cov_rdn_f64 = 0;
  int fa_cov_rup_f64 = 0;
  int fa_cov_rmm_f64 = 0;
  int fa_cov_rm_invalid_f64 = 0;
  int fa_cov_flag_NV_f64 = 0;
  int fa_cov_flag_OF_f64 = 0;
  int fa_cov_flag_UF_f64 = 0;
  int fa_cov_flag_NX_f64 = 0;
  int fa_cov_f64_nan = 0;
  int fa_cov_f64_nan_nv = 0;
  int fa_cov_f64_inf = 0;
  int fa_cov_f64_inf_nv = 0;
  int fa_cov_f64_overflow = 0;
  int fa_cov_f64_ab_zero = 0;
  int fa_cov_f64_sum_zero = 0;
  int fa_cov_f64_subnormal = 0;
  int fa_cov_f64_is_fix = 0;
  int fa_cov_f64_sum_neg = 0;
  int fa_cov_f64_uf = 0;
  int fa_cov_f64_nx = 0;
  int fa_cov_f64_exact = 0;
  int fa_cov_f64_round_up = 0;
  int fa_cov_f64_exp_carry = 0;
  int fa_cov_f64_c_medium = 0;
  int fa_cov_f64_c_too_big = 0;
  int fa_cov_f64_c_too_small = 0;
  int fa_cov_f32_0_nan = 0;
  int fa_cov_f32_0_nan_nv = 0;
  int fa_cov_f32_0_inf = 0;
  int fa_cov_f32_0_inf_nv = 0;
  int fa_cov_f32_0_overflow = 0;
  int fa_cov_f32_0_ab_zero = 0;
  int fa_cov_f32_0_sum_zero = 0;
  int fa_cov_f32_0_subnormal = 0;
  int fa_cov_f32_0_is_fix = 0;
  int fa_cov_f32_0_sum_neg = 0;
  int fa_cov_f32_0_uf = 0;
  int fa_cov_f32_0_nx = 0;
  int fa_cov_f32_0_exact = 0;
  int fa_cov_f32_0_round_up = 0;
  int fa_cov_f32_0_exp_carry = 0;
  int fa_cov_f32_0_c_medium = 0;
  int fa_cov_f32_0_c_too_big = 0;
  int fa_cov_f32_0_c_too_small = 0;
  int fa_cov_f32_1_nan = 0;
  int fa_cov_f32_1_nan_nv = 0;
  int fa_cov_f32_1_inf = 0;
  int fa_cov_f32_1_inf_nv = 0;
  int fa_cov_f32_1_overflow = 0;
  int fa_cov_f32_1_ab_zero = 0;
  int fa_cov_f32_1_sum_zero = 0;
  int fa_cov_f32_1_subnormal = 0;
  int fa_cov_f32_1_is_fix = 0;
  int fa_cov_f32_1_sum_neg = 0;
  int fa_cov_f32_1_uf = 0;
  int fa_cov_f32_1_nx = 0;
  int fa_cov_f32_1_exact = 0;
  int fa_cov_f32_1_round_up = 0;
  int fa_cov_f32_1_exp_carry = 0;
  int fa_cov_f32_1_c_medium = 0;
  int fa_cov_f32_1_c_too_big = 0;
  int fa_cov_f32_1_c_too_small = 0;
  int fa_cov_f16_0_nan = 0;
  int fa_cov_f16_0_nan_nv = 0;
  int fa_cov_f16_0_inf = 0;
  int fa_cov_f16_0_inf_nv = 0;
  int fa_cov_f16_0_overflow = 0;
  int fa_cov_f16_0_ab_zero = 0;
  int fa_cov_f16_0_sum_zero = 0;
  int fa_cov_f16_0_subnormal = 0;
  int fa_cov_f16_0_is_fix = 0;
  int fa_cov_f16_0_sum_neg = 0;
  int fa_cov_f16_0_uf = 0;
  int fa_cov_f16_0_nx = 0;
  int fa_cov_f16_0_exact = 0;
  int fa_cov_f16_0_round_up = 0;
  int fa_cov_f16_0_exp_carry = 0;
  int fa_cov_f16_0_c_medium = 0;
  int fa_cov_f16_0_c_too_big = 0;
  int fa_cov_f16_0_c_too_small = 0;
  int fa_cov_f16_1_nan = 0;
  int fa_cov_f16_1_nan_nv = 0;
  int fa_cov_f16_1_inf = 0;
  int fa_cov_f16_1_inf_nv = 0;
  int fa_cov_f16_1_overflow = 0;
  int fa_cov_f16_1_ab_zero = 0;
  int fa_cov_f16_1_sum_zero = 0;
  int fa_cov_f16_1_subnormal = 0;
  int fa_cov_f16_1_is_fix = 0;
  int fa_cov_f16_1_sum_neg = 0;
  int fa_cov_f16_1_uf = 0;
  int fa_cov_f16_1_nx = 0;
  int fa_cov_f16_1_exact = 0;
  int fa_cov_f16_1_round_up = 0;
  int fa_cov_f16_1_exp_carry = 0;
  int fa_cov_f16_1_c_medium = 0;
  int fa_cov_f16_1_c_too_big = 0;
  int fa_cov_f16_1_c_too_small = 0;
  int fa_cov_f16_2_nan = 0;
  int fa_cov_f16_2_nan_nv = 0;
  int fa_cov_f16_2_inf = 0;
  int fa_cov_f16_2_inf_nv = 0;
  int fa_cov_f16_2_overflow = 0;
  int fa_cov_f16_2_ab_zero = 0;
  int fa_cov_f16_2_sum_zero = 0;
  int fa_cov_f16_2_subnormal = 0;
  int fa_cov_f16_2_is_fix = 0;
  int fa_cov_f16_2_sum_neg = 0;
  int fa_cov_f16_2_uf = 0;
  int fa_cov_f16_2_nx = 0;
  int fa_cov_f16_2_exact = 0;
  int fa_cov_f16_2_round_up = 0;
  int fa_cov_f16_2_exp_carry = 0;
  int fa_cov_f16_2_c_medium = 0;
  int fa_cov_f16_2_c_too_big = 0;
  int fa_cov_f16_2_c_too_small = 0;
  int fa_cov_f16_3_nan = 0;
  int fa_cov_f16_3_nan_nv = 0;
  int fa_cov_f16_3_inf = 0;
  int fa_cov_f16_3_inf_nv = 0;
  int fa_cov_f16_3_overflow = 0;
  int fa_cov_f16_3_ab_zero = 0;
  int fa_cov_f16_3_sum_zero = 0;
  int fa_cov_f16_3_subnormal = 0;
  int fa_cov_f16_3_is_fix = 0;
  int fa_cov_f16_3_sum_neg = 0;
  int fa_cov_f16_3_uf = 0;
  int fa_cov_f16_3_nx = 0;
  int fa_cov_f16_3_exact = 0;
  int fa_cov_f16_3_round_up = 0;
  int fa_cov_f16_3_exp_carry = 0;
  int fa_cov_f16_3_c_medium = 0;
  int fa_cov_f16_3_c_too_big = 0;
  int fa_cov_f16_3_c_too_small = 0;
  logic [0:0] fa_armed = '0;
  int fa_armed_at = -1;
  VectorFloatFMA fa_u_gold (
    .clock(clk),
    .reset(fa_reset),
    .io_fire(fa_io_fire),
    .io_fp_a(fa_io_fp_a),
    .io_fp_b(fa_io_fp_b),
    .io_fp_c(fa_io_fp_c),
    .io_uop_idx(fa_io_uop_idx),
    .io_widen_a(fa_io_widen_a),
    .io_widen_b(fa_io_widen_b),
    .io_round_mode(fa_io_round_mode),
    .io_fp_format(fa_io_fp_format),
    .io_op_code(fa_io_op_code),
    .io_res_widening(fa_io_res_widening),
    .io_fp_result(fa_g_io_fp_result),
    .io_fflags(fa_g_io_fflags)
  );
  VectorFloatFMA_xs fa_u_impl (
    .clock(clk),
    .reset(fa_reset),
    .io_fire(fa_io_fire),
    .io_fp_a(fa_io_fp_a),
    .io_fp_b(fa_io_fp_b),
    .io_fp_c(fa_io_fp_c),
    .io_uop_idx(fa_io_uop_idx),
    .io_widen_a(fa_io_widen_a),
    .io_widen_b(fa_io_widen_b),
    .io_round_mode(fa_io_round_mode),
    .io_fp_format(fa_io_fp_format),
    .io_op_code(fa_io_op_code),
    .io_res_widening(fa_io_res_widening),
    .io_fp_result(fa_i_io_fp_result),
    .io_fflags(fa_i_io_fflags)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 1000 == 0) fa_mode = $urandom_range(0, 15);
      fa_io_fire = 1'($urandom);
      fa_io_fp_a = 64'({$urandom, $urandom});
      fa_io_fp_b = 64'({$urandom, $urandom});
      fa_io_fp_c = 64'({$urandom, $urandom});
      fa_io_uop_idx = 1'($urandom);
      fa_io_widen_a = 64'({$urandom, $urandom});
      fa_io_widen_b = 64'({$urandom, $urandom});
      fa_io_round_mode = 3'($urandom);
      fa_io_fp_format = 2'($urandom);
      fa_io_op_code = 4'($urandom);
      fa_io_res_widening = 1'($urandom);
      fa_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_fa
        logic [63:0] vx, vy, vz, wx, wy, tx, ty, tz;
        int          w, ew, fw, sew, sfw, nslot, half;
        logic        swap;
        fa_op    = (fa_mode >= 14) ? 9 : $urandom_range(0, 8);
        fa_fmt   = (fa_mode >= 14) ? 3 : $urandom_range(0, 2);
        fa_widen = ($urandom_range(0, 2) == 0);
        if (fa_op < 9) fa_io_op_code = 4'(fa_op);
        if (fa_fmt < 3) fa_io_fp_format = 2'(fa_fmt + 1);
        fa_io_res_widening = fa_widen;
        fa_io_round_mode   = ($urandom_range(0, 15) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
        fa_io_fire         = (fa_mode < 4) ? 1'b1 : (fa_mode < 6) ? ($urandom_range(0, 7) == 0) : 1'($urandom);
        // 实际生效的格式（fp_format 0 按 f16 处理）
        w  = (fa_io_fp_format == 2'd3) ? 64 : (fa_io_fp_format == 2'd2) ? 32 : 16;
        ew = (w == 64) ? 11 : (w == 32) ? 8 : 5;
        fw = w - 1 - ew;
        if (fa_widen && w != 16) begin
          sew = (w == 64) ? 8 : 5;
          sfw = w / 2 - 1 - sew;
        end else begin
          sew = ew;
          sfw = fw;
        end
        nslot = 64 / w;
        swap  = (fa_io_op_code >= 4'd5) && (fa_io_op_code <= 4'd8);
        half  = fa_io_uop_idx ? 32 : 0;
        vx = {$urandom, $urandom}; vy = {$urandom, $urandom}; vz = {$urandom, $urandom};
        wx = {$urandom, $urandom}; wy = {$urandom, $urandom};
        for (int k = 0; k < nslot; k++) begin
          fa_triplet(sew, sfw, ew, fw, tx, ty, tz);
          for (int b = 0; b < w; b++) vz[k * w + b] = tz[b];
          if (fa_widen && w != 16) begin
            for (int b = 0; b < w / 2; b++) begin
              wx[half + k * (w / 2) + b] = tx[b];
              wy[half + k * (w / 2) + b] = ty[b];
            end
          end else begin
            for (int b = 0; b < w; b++) begin
              vx[k * w + b] = tx[b];
              vy[k * w + b] = ty[b];
            end
          end
        end
        fa_io_fp_b    = vy;
        fa_io_widen_a = wx;
        fa_io_widen_b = wy;
        if (swap) begin
          fa_io_fp_c = vx; fa_io_fp_a = vz;
        end else begin
          fa_io_fp_a = vx; fa_io_fp_c = vz;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&fa_armed)) begin
        checks++;
        if (fa_g_io_fp_result !== fa_i_io_fp_result) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VectorFloatFMA.io_fp_result g=%h i=%h", cyc, fa_g_io_fp_result, fa_i_io_fp_result);
        end
        fa_s1_io_fp_result |= fa_g_io_fp_result;
        fa_s0_io_fp_result |= ~fa_g_io_fp_result;
        checks++;
        if (fa_g_io_fflags !== fa_i_io_fflags) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VectorFloatFMA.io_fflags g=%h i=%h", cyc, fa_g_io_fflags, fa_i_io_fflags);
        end
        fa_s1_io_fflags |= fa_g_io_fflags;
        fa_s0_io_fflags |= ~fa_g_io_fflags;
        if (fa_io_fire && fa_op == 0 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfmul_f16_same++;
        if (fa_io_fire && fa_op == 0 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfmul_f16_widen++;
        if (fa_io_fire && fa_op == 0 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfmul_f32_same++;
        if (fa_io_fire && fa_op == 0 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfmul_f32_widen++;
        if (fa_io_fire && fa_op == 0 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfmul_f64_same++;
        if (fa_io_fire && fa_op == 0 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfmul_f64_widen++;
        if (fa_io_fire && fa_op == 1 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfmacc_f16_same++;
        if (fa_io_fire && fa_op == 1 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfmacc_f16_widen++;
        if (fa_io_fire && fa_op == 1 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfmacc_f32_same++;
        if (fa_io_fire && fa_op == 1 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfmacc_f32_widen++;
        if (fa_io_fire && fa_op == 1 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfmacc_f64_same++;
        if (fa_io_fire && fa_op == 1 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfmacc_f64_widen++;
        if (fa_io_fire && fa_op == 2 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfnmacc_f16_same++;
        if (fa_io_fire && fa_op == 2 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfnmacc_f16_widen++;
        if (fa_io_fire && fa_op == 2 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfnmacc_f32_same++;
        if (fa_io_fire && fa_op == 2 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfnmacc_f32_widen++;
        if (fa_io_fire && fa_op == 2 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfnmacc_f64_same++;
        if (fa_io_fire && fa_op == 2 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfnmacc_f64_widen++;
        if (fa_io_fire && fa_op == 3 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfmsac_f16_same++;
        if (fa_io_fire && fa_op == 3 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfmsac_f16_widen++;
        if (fa_io_fire && fa_op == 3 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfmsac_f32_same++;
        if (fa_io_fire && fa_op == 3 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfmsac_f32_widen++;
        if (fa_io_fire && fa_op == 3 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfmsac_f64_same++;
        if (fa_io_fire && fa_op == 3 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfmsac_f64_widen++;
        if (fa_io_fire && fa_op == 4 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfnmsac_f16_same++;
        if (fa_io_fire && fa_op == 4 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfnmsac_f16_widen++;
        if (fa_io_fire && fa_op == 4 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfnmsac_f32_same++;
        if (fa_io_fire && fa_op == 4 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfnmsac_f32_widen++;
        if (fa_io_fire && fa_op == 4 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfnmsac_f64_same++;
        if (fa_io_fire && fa_op == 4 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfnmsac_f64_widen++;
        if (fa_io_fire && fa_op == 5 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfmadd_f16_same++;
        if (fa_io_fire && fa_op == 5 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfmadd_f16_widen++;
        if (fa_io_fire && fa_op == 5 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfmadd_f32_same++;
        if (fa_io_fire && fa_op == 5 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfmadd_f32_widen++;
        if (fa_io_fire && fa_op == 5 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfmadd_f64_same++;
        if (fa_io_fire && fa_op == 5 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfmadd_f64_widen++;
        if (fa_io_fire && fa_op == 6 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfnmadd_f16_same++;
        if (fa_io_fire && fa_op == 6 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfnmadd_f16_widen++;
        if (fa_io_fire && fa_op == 6 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfnmadd_f32_same++;
        if (fa_io_fire && fa_op == 6 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfnmadd_f32_widen++;
        if (fa_io_fire && fa_op == 6 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfnmadd_f64_same++;
        if (fa_io_fire && fa_op == 6 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfnmadd_f64_widen++;
        if (fa_io_fire && fa_op == 7 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfmsub_f16_same++;
        if (fa_io_fire && fa_op == 7 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfmsub_f16_widen++;
        if (fa_io_fire && fa_op == 7 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfmsub_f32_same++;
        if (fa_io_fire && fa_op == 7 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfmsub_f32_widen++;
        if (fa_io_fire && fa_op == 7 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfmsub_f64_same++;
        if (fa_io_fire && fa_op == 7 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfmsub_f64_widen++;
        if (fa_io_fire && fa_op == 8 && fa_fmt == 0 && fa_widen == 1'b0) fa_cov_vfnmsub_f16_same++;
        if (fa_io_fire && fa_op == 8 && fa_fmt == 0 && fa_widen == 1'b1) fa_cov_vfnmsub_f16_widen++;
        if (fa_io_fire && fa_op == 8 && fa_fmt == 1 && fa_widen == 1'b0) fa_cov_vfnmsub_f32_same++;
        if (fa_io_fire && fa_op == 8 && fa_fmt == 1 && fa_widen == 1'b1) fa_cov_vfnmsub_f32_widen++;
        if (fa_io_fire && fa_op == 8 && fa_fmt == 2 && fa_widen == 1'b0) fa_cov_vfnmsub_f64_same++;
        if (fa_io_fire && fa_op == 8 && fa_fmt == 2 && fa_widen == 1'b1) fa_cov_vfnmsub_f64_widen++;
        if (fa_io_fire && fa_op == 9 && fa_io_fp_format == 2'd1) fa_cov_randop_f16++;
        if (fa_io_fire && fa_op == 9 && fa_io_fp_format == 2'd2) fa_cov_randop_f32++;
        if (fa_io_fire && fa_op == 9 && fa_io_fp_format == 2'd3) fa_cov_randop_f64++;
        if (fa_io_fire && fa_io_fp_format == 2'd0) fa_cov_fmt0_as_f16++;
        if (fa_io_fire && fa_io_op_code > 4'd8) fa_cov_op_undefined++;
        if (!fa_io_fire) fa_cov_fire_gap++;
        if (fa_io_fire && fa_io_res_widening && fa_io_uop_idx) fa_cov_uop_idx_widen++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.RNE_reg2) fa_cov_rne_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.RTZ_reg2) fa_cov_rtz_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.RDN_reg2) fa_cov_rdn_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.RUP_reg2) fa_cov_rup_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.RMM_reg2) fa_cov_rmm_f16++;
        if (fa_u_gold.is_fp16_reg2 && !(fa_u_gold.RNE_reg2 || fa_u_gold.RTZ_reg2 || fa_u_gold.RDN_reg2 || fa_u_gold.RUP_reg2 || fa_u_gold.RMM_reg2)) fa_cov_rm_invalid_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_g_io_fflags[4]) fa_cov_flag_NV_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_g_io_fflags[2]) fa_cov_flag_OF_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_g_io_fflags[1]) fa_cov_flag_UF_f16++;
        if (fa_u_gold.is_fp16_reg2 && fa_g_io_fflags[0]) fa_cov_flag_NX_f16++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.RNE_reg2) fa_cov_rne_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.RTZ_reg2) fa_cov_rtz_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.RDN_reg2) fa_cov_rdn_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.RUP_reg2) fa_cov_rup_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.RMM_reg2) fa_cov_rmm_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !(fa_u_gold.RNE_reg2 || fa_u_gold.RTZ_reg2 || fa_u_gold.RDN_reg2 || fa_u_gold.RUP_reg2 || fa_u_gold.RMM_reg2)) fa_cov_rm_invalid_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_g_io_fflags[4]) fa_cov_flag_NV_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_g_io_fflags[2]) fa_cov_flag_OF_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_g_io_fflags[1]) fa_cov_flag_UF_f32++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_g_io_fflags[0]) fa_cov_flag_NX_f32++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.RNE_reg2) fa_cov_rne_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.RTZ_reg2) fa_cov_rtz_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.RDN_reg2) fa_cov_rdn_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.RUP_reg2) fa_cov_rup_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.RMM_reg2) fa_cov_rmm_f64++;
        if (fa_u_gold.is_fp64_reg2 && !(fa_u_gold.RNE_reg2 || fa_u_gold.RTZ_reg2 || fa_u_gold.RDN_reg2 || fa_u_gold.RUP_reg2 || fa_u_gold.RMM_reg2)) fa_cov_rm_invalid_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_g_io_fflags[4]) fa_cov_flag_NV_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_g_io_fflags[2]) fa_cov_flag_OF_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_g_io_fflags[1]) fa_cov_flag_UF_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_g_io_fflags[0]) fa_cov_flag_NX_f64++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.has_nan_f64_reg2) fa_cov_f64_nan++;
        if (fa_u_gold.is_fp64_reg2 && fa_u_gold.has_nan_f64_reg2 && fa_u_gold.has_nan_f64_is_NV_reg2) fa_cov_f64_nan_nv++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && fa_u_gold.has_inf_f64_reg2) fa_cov_f64_inf++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && fa_u_gold.has_inf_f64_reg2 && fa_u_gold.has_inf_f64_is_NV_reg2) fa_cov_f64_inf_nv++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && fa_u_gold.exponent_overflow_f64) fa_cov_f64_overflow++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && fa_u_gold.fp_a_or_b_is_zero_f64_reg2) fa_cov_f64_ab_zero++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.fp_a_or_b_is_zero_f64_reg2 && fa_u_gold.normal_result_is_zero_f64_reg2) fa_cov_f64_sum_zero++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.exponent_is_min_f64) fa_cov_f64_subnormal++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.is_fix_reg2[0]) fa_cov_f64_is_fix++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.adder_is_negative_reg2[0]) fa_cov_f64_sum_neg++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.UF_f64) fa_cov_f64_uf++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.NX_f64) fa_cov_f64_nx++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && !fa_u_gold.NX_f64) fa_cov_f64_exact++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.round_add1_f64) fa_cov_f64_round_up++;
        if (fa_u_gold.is_fp64_reg2 && !fa_u_gold.has_nan_f64_reg2 && !fa_u_gold.has_inf_f64_reg2 && !fa_u_gold.exponent_overflow_f64 && !fa_u_gold.has_zero_f64_reg2 && fa_u_gold.exponent_add_1_f64) fa_cov_f64_exp_carry++;
        if (fa_io_fire && fa_io_fp_format == 2'd3 && fa_u_gold.Ec_is_medium_f64) fa_cov_f64_c_medium++;
        if (fa_io_fire && fa_io_fp_format == 2'd3 && fa_u_gold.Ec_is_too_big_f64) fa_cov_f64_c_too_big++;
        if (fa_io_fire && fa_io_fp_format == 2'd3 && !fa_u_gold.Ec_is_medium_f64 && !fa_u_gold.Ec_is_too_big_f64) fa_cov_f64_c_too_small++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.has_nan_f32_0_reg2) fa_cov_f32_0_nan++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.has_nan_f32_0_reg2 && fa_u_gold.has_nan_f32_0_is_NV_reg2) fa_cov_f32_0_nan_nv++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && fa_u_gold.has_inf_f32_0_reg2) fa_cov_f32_0_inf++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && fa_u_gold.has_inf_f32_0_reg2 && fa_u_gold.has_inf_f32_0_is_NV_reg2) fa_cov_f32_0_inf_nv++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && fa_u_gold.exponent_overflow_f32_0) fa_cov_f32_0_overflow++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && fa_u_gold.fp_a_or_b_is_zero_f32_0_reg2) fa_cov_f32_0_ab_zero++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.fp_a_or_b_is_zero_f32_0_reg2 && fa_u_gold.normal_result_is_zero_f32_0_reg2) fa_cov_f32_0_sum_zero++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.exponent_is_min_f32_0) fa_cov_f32_0_subnormal++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.is_fix_reg2[0]) fa_cov_f32_0_is_fix++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.adder_is_negative_reg2[0]) fa_cov_f32_0_sum_neg++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.UF_f32_0) fa_cov_f32_0_uf++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.NX_f32_0) fa_cov_f32_0_nx++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && !fa_u_gold.NX_f32_0) fa_cov_f32_0_exact++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.round_add1_f32_0) fa_cov_f32_0_round_up++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_0_reg2 && !fa_u_gold.has_inf_f32_0_reg2 && !fa_u_gold.exponent_overflow_f32_0 && !fa_u_gold.has_zero_f32_0_reg2 && fa_u_gold.exponent_add_1_f32_0) fa_cov_f32_0_exp_carry++;
        if (fa_io_fire && fa_io_fp_format == 2'd2 && fa_u_gold.Ec_is_medium_f32_0) fa_cov_f32_0_c_medium++;
        if (fa_io_fire && fa_io_fp_format == 2'd2 && fa_u_gold.Ec_is_too_big_f32_0) fa_cov_f32_0_c_too_big++;
        if (fa_io_fire && fa_io_fp_format == 2'd2 && !fa_u_gold.Ec_is_medium_f32_0 && !fa_u_gold.Ec_is_too_big_f32_0) fa_cov_f32_0_c_too_small++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.has_nan_f32_1_reg2) fa_cov_f32_1_nan++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && fa_u_gold.has_nan_f32_1_reg2 && fa_u_gold.has_nan_f32_1_is_NV_reg2) fa_cov_f32_1_nan_nv++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && fa_u_gold.has_inf_f32_1_reg2) fa_cov_f32_1_inf++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && fa_u_gold.has_inf_f32_1_reg2 && fa_u_gold.has_inf_f32_1_is_NV_reg2) fa_cov_f32_1_inf_nv++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && fa_u_gold.exponent_overflow_f32_1) fa_cov_f32_1_overflow++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && fa_u_gold.fp_a_or_b_is_zero_f32_1_reg2) fa_cov_f32_1_ab_zero++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.fp_a_or_b_is_zero_f32_1_reg2 && fa_u_gold.normal_result_is_zero_f32_1_reg2) fa_cov_f32_1_sum_zero++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.exponent_is_min_f32_1) fa_cov_f32_1_subnormal++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.is_fix_reg2[1]) fa_cov_f32_1_is_fix++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.adder_is_negative_reg2[1]) fa_cov_f32_1_sum_neg++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.UF_f32_1) fa_cov_f32_1_uf++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.NX_f32_1) fa_cov_f32_1_nx++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && !fa_u_gold.NX_f32_1) fa_cov_f32_1_exact++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.round_add1_f32_1) fa_cov_f32_1_round_up++;
        if ((!fa_u_gold.is_fp64_reg2 && fa_u_gold.is_fp32_reg2) && !fa_u_gold.has_nan_f32_1_reg2 && !fa_u_gold.has_inf_f32_1_reg2 && !fa_u_gold.exponent_overflow_f32_1 && !fa_u_gold.has_zero_f32_1_reg2 && fa_u_gold.exponent_add_1_f32_1) fa_cov_f32_1_exp_carry++;
        if (fa_io_fire && fa_io_fp_format == 2'd2 && fa_u_gold.Ec_is_medium_f32_1) fa_cov_f32_1_c_medium++;
        if (fa_io_fire && fa_io_fp_format == 2'd2 && fa_u_gold.Ec_is_too_big_f32_1) fa_cov_f32_1_c_too_big++;
        if (fa_io_fire && fa_io_fp_format == 2'd2 && !fa_u_gold.Ec_is_medium_f32_1 && !fa_u_gold.Ec_is_too_big_f32_1) fa_cov_f32_1_c_too_small++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_0_reg2) fa_cov_f16_0_nan++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_0_reg2 && fa_u_gold.has_nan_f16_0_is_NV_reg2) fa_cov_f16_0_nan_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && fa_u_gold.has_inf_f16_0_reg2) fa_cov_f16_0_inf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && fa_u_gold.has_inf_f16_0_reg2 && fa_u_gold.has_inf_f16_0_is_NV_reg2) fa_cov_f16_0_inf_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && fa_u_gold.exponent_overflow_f16_0) fa_cov_f16_0_overflow++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && fa_u_gold.fp_a_or_b_is_zero_f16_0_reg2) fa_cov_f16_0_ab_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.fp_a_or_b_is_zero_f16_0_reg2 && fa_u_gold.normal_result_is_zero_f16_0_reg2) fa_cov_f16_0_sum_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.exponent_is_min_f16_0) fa_cov_f16_0_subnormal++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.is_fix_reg2[0]) fa_cov_f16_0_is_fix++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.adder_is_negative_reg2[0]) fa_cov_f16_0_sum_neg++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.UF_f16_0) fa_cov_f16_0_uf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.NX_f16_0) fa_cov_f16_0_nx++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && !fa_u_gold.NX_f16_0) fa_cov_f16_0_exact++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.round_add1_f16_0) fa_cov_f16_0_round_up++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_0_reg2 && !fa_u_gold.has_inf_f16_0_reg2 && !fa_u_gold.exponent_overflow_f16_0 && !fa_u_gold.has_zero_f16_0_reg2 && fa_u_gold.exponent_add_1_f16_0) fa_cov_f16_0_exp_carry++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_medium_f16_0) fa_cov_f16_0_c_medium++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_too_big_f16_0) fa_cov_f16_0_c_too_big++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && !fa_u_gold.Ec_is_medium_f16_0 && !fa_u_gold.Ec_is_too_big_f16_0) fa_cov_f16_0_c_too_small++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_1_reg2) fa_cov_f16_1_nan++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_1_reg2 && fa_u_gold.has_nan_f16_1_is_NV_reg2) fa_cov_f16_1_nan_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && fa_u_gold.has_inf_f16_1_reg2) fa_cov_f16_1_inf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && fa_u_gold.has_inf_f16_1_reg2 && fa_u_gold.has_inf_f16_1_is_NV_reg2) fa_cov_f16_1_inf_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && fa_u_gold.exponent_overflow_f16_1) fa_cov_f16_1_overflow++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && fa_u_gold.fp_a_or_b_is_zero_f16_1_reg2) fa_cov_f16_1_ab_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.fp_a_or_b_is_zero_f16_1_reg2 && fa_u_gold.normal_result_is_zero_f16_1_reg2) fa_cov_f16_1_sum_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.exponent_is_min_f16_1) fa_cov_f16_1_subnormal++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.is_fix_reg2[1]) fa_cov_f16_1_is_fix++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.adder_is_negative_reg2[1]) fa_cov_f16_1_sum_neg++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.UF_f16_1) fa_cov_f16_1_uf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.NX_f16_1) fa_cov_f16_1_nx++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && !fa_u_gold.NX_f16_1) fa_cov_f16_1_exact++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.round_add1_f16_1) fa_cov_f16_1_round_up++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_1_reg2 && !fa_u_gold.has_inf_f16_1_reg2 && !fa_u_gold.exponent_overflow_f16_1 && !fa_u_gold.has_zero_f16_1_reg2 && fa_u_gold.exponent_add_1_f16_1) fa_cov_f16_1_exp_carry++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_medium_f16_1) fa_cov_f16_1_c_medium++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_too_big_f16_1) fa_cov_f16_1_c_too_big++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && !fa_u_gold.Ec_is_medium_f16_1 && !fa_u_gold.Ec_is_too_big_f16_1) fa_cov_f16_1_c_too_small++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_2_reg2) fa_cov_f16_2_nan++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_2_reg2 && fa_u_gold.has_nan_f16_2_is_NV_reg2) fa_cov_f16_2_nan_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && fa_u_gold.has_inf_f16_2_reg2) fa_cov_f16_2_inf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && fa_u_gold.has_inf_f16_2_reg2 && fa_u_gold.has_inf_f16_2_is_NV_reg2) fa_cov_f16_2_inf_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && fa_u_gold.exponent_overflow_f16_2) fa_cov_f16_2_overflow++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && fa_u_gold.fp_a_or_b_is_zero_f16_2_reg2) fa_cov_f16_2_ab_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.fp_a_or_b_is_zero_f16_2_reg2 && fa_u_gold.normal_result_is_zero_f16_2_reg2) fa_cov_f16_2_sum_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.exponent_is_min_f16_2) fa_cov_f16_2_subnormal++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.is_fix_reg2[2]) fa_cov_f16_2_is_fix++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.adder_is_negative_reg2[2]) fa_cov_f16_2_sum_neg++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.UF_f16_2) fa_cov_f16_2_uf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.NX_f16_2) fa_cov_f16_2_nx++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && !fa_u_gold.NX_f16_2) fa_cov_f16_2_exact++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.round_add1_f16_2) fa_cov_f16_2_round_up++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_2_reg2 && !fa_u_gold.has_inf_f16_2_reg2 && !fa_u_gold.exponent_overflow_f16_2 && !fa_u_gold.has_zero_f16_2_reg2 && fa_u_gold.exponent_add_1_f16_2) fa_cov_f16_2_exp_carry++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_medium_f16_2) fa_cov_f16_2_c_medium++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_too_big_f16_2) fa_cov_f16_2_c_too_big++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && !fa_u_gold.Ec_is_medium_f16_2 && !fa_u_gold.Ec_is_too_big_f16_2) fa_cov_f16_2_c_too_small++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_3_reg2) fa_cov_f16_3_nan++;
        if (fa_u_gold.is_fp16_reg2 && fa_u_gold.has_nan_f16_3_reg2 && fa_u_gold.has_nan_f16_3_is_NV_reg2) fa_cov_f16_3_nan_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && fa_u_gold.has_inf_f16_3_reg2) fa_cov_f16_3_inf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && fa_u_gold.has_inf_f16_3_reg2 && fa_u_gold.has_inf_f16_3_is_NV_reg2) fa_cov_f16_3_inf_nv++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && fa_u_gold.exponent_overflow_f16_3) fa_cov_f16_3_overflow++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && fa_u_gold.fp_a_or_b_is_zero_f16_3_reg2) fa_cov_f16_3_ab_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.fp_a_or_b_is_zero_f16_3_reg2 && fa_u_gold.normal_result_is_zero_f16_3_reg2) fa_cov_f16_3_sum_zero++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.exponent_is_min_f16_3) fa_cov_f16_3_subnormal++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.is_fix_reg2[3]) fa_cov_f16_3_is_fix++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.adder_is_negative_reg2[3]) fa_cov_f16_3_sum_neg++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.UF_f16_3) fa_cov_f16_3_uf++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.NX_f16_3) fa_cov_f16_3_nx++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && !fa_u_gold.NX_f16_3) fa_cov_f16_3_exact++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.round_add1_f16_3) fa_cov_f16_3_round_up++;
        if (fa_u_gold.is_fp16_reg2 && !fa_u_gold.has_nan_f16_3_reg2 && !fa_u_gold.has_inf_f16_3_reg2 && !fa_u_gold.exponent_overflow_f16_3 && !fa_u_gold.has_zero_f16_3_reg2 && fa_u_gold.exponent_add_1_f16_3) fa_cov_f16_3_exp_carry++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_medium_f16_3) fa_cov_f16_3_c_medium++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && fa_u_gold.Ec_is_too_big_f16_3) fa_cov_f16_3_c_too_big++;
        if (fa_io_fire && fa_io_fp_format < 2'd2 && !fa_u_gold.Ec_is_medium_f16_3 && !fa_u_gold.Ec_is_too_big_f16_3) fa_cov_f16_3_c_too_small++;
      end
      if (fa_u_gold.fire_reg1_last_r) fa_armed[0] = 1'b1;
      if (fa_armed_at < 0 && (&fa_armed)) fa_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(fa_s0_io_fp_result[0] && fa_s1_io_fp_result[0])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[0] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[1] && fa_s1_io_fp_result[1])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[1] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[2] && fa_s1_io_fp_result[2])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[2] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[3] && fa_s1_io_fp_result[3])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[3] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[4] && fa_s1_io_fp_result[4])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[4] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[5] && fa_s1_io_fp_result[5])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[5] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[6] && fa_s1_io_fp_result[6])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[6] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[7] && fa_s1_io_fp_result[7])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[7] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[8] && fa_s1_io_fp_result[8])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[8] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[9] && fa_s1_io_fp_result[9])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[9] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[10] && fa_s1_io_fp_result[10])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[10] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[11] && fa_s1_io_fp_result[11])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[11] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[12] && fa_s1_io_fp_result[12])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[12] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[13] && fa_s1_io_fp_result[13])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[13] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[14] && fa_s1_io_fp_result[14])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[14] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[15] && fa_s1_io_fp_result[15])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[15] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[16] && fa_s1_io_fp_result[16])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[16] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[17] && fa_s1_io_fp_result[17])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[17] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[18] && fa_s1_io_fp_result[18])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[18] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[19] && fa_s1_io_fp_result[19])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[19] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[20] && fa_s1_io_fp_result[20])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[20] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[21] && fa_s1_io_fp_result[21])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[21] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[22] && fa_s1_io_fp_result[22])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[22] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[23] && fa_s1_io_fp_result[23])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[23] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[24] && fa_s1_io_fp_result[24])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[24] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[25] && fa_s1_io_fp_result[25])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[25] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[26] && fa_s1_io_fp_result[26])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[26] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[27] && fa_s1_io_fp_result[27])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[27] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[28] && fa_s1_io_fp_result[28])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[28] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[29] && fa_s1_io_fp_result[29])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[29] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[30] && fa_s1_io_fp_result[30])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[30] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[31] && fa_s1_io_fp_result[31])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[31] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[32] && fa_s1_io_fp_result[32])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[32] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[33] && fa_s1_io_fp_result[33])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[33] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[34] && fa_s1_io_fp_result[34])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[34] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[35] && fa_s1_io_fp_result[35])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[35] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[36] && fa_s1_io_fp_result[36])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[36] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[37] && fa_s1_io_fp_result[37])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[37] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[38] && fa_s1_io_fp_result[38])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[38] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[39] && fa_s1_io_fp_result[39])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[39] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[40] && fa_s1_io_fp_result[40])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[40] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[41] && fa_s1_io_fp_result[41])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[41] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[42] && fa_s1_io_fp_result[42])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[42] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[43] && fa_s1_io_fp_result[43])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[43] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[44] && fa_s1_io_fp_result[44])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[44] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[45] && fa_s1_io_fp_result[45])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[45] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[46] && fa_s1_io_fp_result[46])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[46] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[47] && fa_s1_io_fp_result[47])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[47] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[48] && fa_s1_io_fp_result[48])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[48] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[49] && fa_s1_io_fp_result[49])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[49] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[50] && fa_s1_io_fp_result[50])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[50] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[51] && fa_s1_io_fp_result[51])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[51] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[52] && fa_s1_io_fp_result[52])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[52] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[53] && fa_s1_io_fp_result[53])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[53] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[54] && fa_s1_io_fp_result[54])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[54] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[55] && fa_s1_io_fp_result[55])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[55] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[56] && fa_s1_io_fp_result[56])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[56] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[57] && fa_s1_io_fp_result[57])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[57] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[58] && fa_s1_io_fp_result[58])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[58] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[59] && fa_s1_io_fp_result[59])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[59] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[60] && fa_s1_io_fp_result[60])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[60] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[61] && fa_s1_io_fp_result[61])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[61] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[62] && fa_s1_io_fp_result[62])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[62] 未见过 0 和 1"); end
    if (!(fa_s0_io_fp_result[63] && fa_s1_io_fp_result[63])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fp_result[63] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[0] && fa_s1_io_fflags[0])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[0] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[1] && fa_s1_io_fflags[1])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[1] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[2] && fa_s1_io_fflags[2])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[2] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[4] && fa_s1_io_fflags[4])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[4] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[5] && fa_s1_io_fflags[5])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[5] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[6] && fa_s1_io_fflags[6])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[6] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[7] && fa_s1_io_fflags[7])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[7] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[9] && fa_s1_io_fflags[9])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[9] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[10] && fa_s1_io_fflags[10])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[10] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[11] && fa_s1_io_fflags[11])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[11] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[12] && fa_s1_io_fflags[12])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[12] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[14] && fa_s1_io_fflags[14])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[14] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[15] && fa_s1_io_fflags[15])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[15] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[16] && fa_s1_io_fflags[16])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[16] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[17] && fa_s1_io_fflags[17])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[17] 未见过 0 和 1"); end
    if (!(fa_s0_io_fflags[19] && fa_s1_io_fflags[19])) begin cov_fail++; $display("[COV] VectorFloatFMA.io_fflags[19] 未见过 0 和 1"); end
    $display("[ARM] VectorFloatFMA armed_at=%0d", fa_armed_at);
    if (fa_armed_at < 0) begin cov_fail++; $display("[ARM] VectorFloatFMA 从未 arm"); end
    $display("[COV] VectorFloatFMA.vfmul_f16_same = %0d", fa_cov_vfmul_f16_same);
    if (fa_cov_vfmul_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmul_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmul_f16_widen = %0d", fa_cov_vfmul_f16_widen);
    if (fa_cov_vfmul_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmul_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmul_f32_same = %0d", fa_cov_vfmul_f32_same);
    if (fa_cov_vfmul_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmul_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmul_f32_widen = %0d", fa_cov_vfmul_f32_widen);
    if (fa_cov_vfmul_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmul_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmul_f64_same = %0d", fa_cov_vfmul_f64_same);
    if (fa_cov_vfmul_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmul_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmul_f64_widen = %0d", fa_cov_vfmul_f64_widen);
    if (fa_cov_vfmul_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmul_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmacc_f16_same = %0d", fa_cov_vfmacc_f16_same);
    if (fa_cov_vfmacc_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmacc_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmacc_f16_widen = %0d", fa_cov_vfmacc_f16_widen);
    if (fa_cov_vfmacc_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmacc_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmacc_f32_same = %0d", fa_cov_vfmacc_f32_same);
    if (fa_cov_vfmacc_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmacc_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmacc_f32_widen = %0d", fa_cov_vfmacc_f32_widen);
    if (fa_cov_vfmacc_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmacc_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmacc_f64_same = %0d", fa_cov_vfmacc_f64_same);
    if (fa_cov_vfmacc_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmacc_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmacc_f64_widen = %0d", fa_cov_vfmacc_f64_widen);
    if (fa_cov_vfmacc_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmacc_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmacc_f16_same = %0d", fa_cov_vfnmacc_f16_same);
    if (fa_cov_vfnmacc_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmacc_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmacc_f16_widen = %0d", fa_cov_vfnmacc_f16_widen);
    if (fa_cov_vfnmacc_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmacc_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmacc_f32_same = %0d", fa_cov_vfnmacc_f32_same);
    if (fa_cov_vfnmacc_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmacc_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmacc_f32_widen = %0d", fa_cov_vfnmacc_f32_widen);
    if (fa_cov_vfnmacc_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmacc_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmacc_f64_same = %0d", fa_cov_vfnmacc_f64_same);
    if (fa_cov_vfnmacc_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmacc_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmacc_f64_widen = %0d", fa_cov_vfnmacc_f64_widen);
    if (fa_cov_vfnmacc_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmacc_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmsac_f16_same = %0d", fa_cov_vfmsac_f16_same);
    if (fa_cov_vfmsac_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsac_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmsac_f16_widen = %0d", fa_cov_vfmsac_f16_widen);
    if (fa_cov_vfmsac_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsac_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmsac_f32_same = %0d", fa_cov_vfmsac_f32_same);
    if (fa_cov_vfmsac_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsac_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmsac_f32_widen = %0d", fa_cov_vfmsac_f32_widen);
    if (fa_cov_vfmsac_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsac_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmsac_f64_same = %0d", fa_cov_vfmsac_f64_same);
    if (fa_cov_vfmsac_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsac_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmsac_f64_widen = %0d", fa_cov_vfmsac_f64_widen);
    if (fa_cov_vfmsac_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsac_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsac_f16_same = %0d", fa_cov_vfnmsac_f16_same);
    if (fa_cov_vfnmsac_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsac_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsac_f16_widen = %0d", fa_cov_vfnmsac_f16_widen);
    if (fa_cov_vfnmsac_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsac_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsac_f32_same = %0d", fa_cov_vfnmsac_f32_same);
    if (fa_cov_vfnmsac_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsac_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsac_f32_widen = %0d", fa_cov_vfnmsac_f32_widen);
    if (fa_cov_vfnmsac_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsac_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsac_f64_same = %0d", fa_cov_vfnmsac_f64_same);
    if (fa_cov_vfnmsac_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsac_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsac_f64_widen = %0d", fa_cov_vfnmsac_f64_widen);
    if (fa_cov_vfnmsac_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsac_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmadd_f16_same = %0d", fa_cov_vfmadd_f16_same);
    if (fa_cov_vfmadd_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmadd_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmadd_f16_widen = %0d", fa_cov_vfmadd_f16_widen);
    if (fa_cov_vfmadd_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmadd_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmadd_f32_same = %0d", fa_cov_vfmadd_f32_same);
    if (fa_cov_vfmadd_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmadd_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmadd_f32_widen = %0d", fa_cov_vfmadd_f32_widen);
    if (fa_cov_vfmadd_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmadd_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmadd_f64_same = %0d", fa_cov_vfmadd_f64_same);
    if (fa_cov_vfmadd_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmadd_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmadd_f64_widen = %0d", fa_cov_vfmadd_f64_widen);
    if (fa_cov_vfmadd_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmadd_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmadd_f16_same = %0d", fa_cov_vfnmadd_f16_same);
    if (fa_cov_vfnmadd_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmadd_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmadd_f16_widen = %0d", fa_cov_vfnmadd_f16_widen);
    if (fa_cov_vfnmadd_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmadd_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmadd_f32_same = %0d", fa_cov_vfnmadd_f32_same);
    if (fa_cov_vfnmadd_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmadd_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmadd_f32_widen = %0d", fa_cov_vfnmadd_f32_widen);
    if (fa_cov_vfnmadd_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmadd_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmadd_f64_same = %0d", fa_cov_vfnmadd_f64_same);
    if (fa_cov_vfnmadd_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmadd_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmadd_f64_widen = %0d", fa_cov_vfnmadd_f64_widen);
    if (fa_cov_vfnmadd_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmadd_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmsub_f16_same = %0d", fa_cov_vfmsub_f16_same);
    if (fa_cov_vfmsub_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsub_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmsub_f16_widen = %0d", fa_cov_vfmsub_f16_widen);
    if (fa_cov_vfmsub_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsub_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmsub_f32_same = %0d", fa_cov_vfmsub_f32_same);
    if (fa_cov_vfmsub_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsub_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmsub_f32_widen = %0d", fa_cov_vfmsub_f32_widen);
    if (fa_cov_vfmsub_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsub_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfmsub_f64_same = %0d", fa_cov_vfmsub_f64_same);
    if (fa_cov_vfmsub_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsub_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfmsub_f64_widen = %0d", fa_cov_vfmsub_f64_widen);
    if (fa_cov_vfmsub_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfmsub_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsub_f16_same = %0d", fa_cov_vfnmsub_f16_same);
    if (fa_cov_vfnmsub_f16_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsub_f16_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsub_f16_widen = %0d", fa_cov_vfnmsub_f16_widen);
    if (fa_cov_vfnmsub_f16_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsub_f16_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsub_f32_same = %0d", fa_cov_vfnmsub_f32_same);
    if (fa_cov_vfnmsub_f32_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsub_f32_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsub_f32_widen = %0d", fa_cov_vfnmsub_f32_widen);
    if (fa_cov_vfnmsub_f32_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsub_f32_widen < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsub_f64_same = %0d", fa_cov_vfnmsub_f64_same);
    if (fa_cov_vfnmsub_f64_same < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsub_f64_same < 100"); end
    $display("[COV] VectorFloatFMA.vfnmsub_f64_widen = %0d", fa_cov_vfnmsub_f64_widen);
    if (fa_cov_vfnmsub_f64_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.vfnmsub_f64_widen < 100"); end
    $display("[COV] VectorFloatFMA.randop_f16 = %0d", fa_cov_randop_f16);
    if (fa_cov_randop_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.randop_f16 < 100"); end
    $display("[COV] VectorFloatFMA.randop_f32 = %0d", fa_cov_randop_f32);
    if (fa_cov_randop_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.randop_f32 < 100"); end
    $display("[COV] VectorFloatFMA.randop_f64 = %0d", fa_cov_randop_f64);
    if (fa_cov_randop_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.randop_f64 < 100"); end
    $display("[COV] VectorFloatFMA.fmt0_as_f16 = %0d", fa_cov_fmt0_as_f16);
    if (fa_cov_fmt0_as_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.fmt0_as_f16 < 100"); end
    $display("[COV] VectorFloatFMA.op_undefined = %0d", fa_cov_op_undefined);
    if (fa_cov_op_undefined < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.op_undefined < 100"); end
    $display("[COV] VectorFloatFMA.fire_gap = %0d", fa_cov_fire_gap);
    if (fa_cov_fire_gap < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.fire_gap < 100"); end
    $display("[COV] VectorFloatFMA.uop_idx_widen = %0d", fa_cov_uop_idx_widen);
    if (fa_cov_uop_idx_widen < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.uop_idx_widen < 100"); end
    $display("[COV] VectorFloatFMA.rne_f16 = %0d", fa_cov_rne_f16);
    if (fa_cov_rne_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rne_f16 < 100"); end
    $display("[COV] VectorFloatFMA.rtz_f16 = %0d", fa_cov_rtz_f16);
    if (fa_cov_rtz_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rtz_f16 < 100"); end
    $display("[COV] VectorFloatFMA.rdn_f16 = %0d", fa_cov_rdn_f16);
    if (fa_cov_rdn_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rdn_f16 < 100"); end
    $display("[COV] VectorFloatFMA.rup_f16 = %0d", fa_cov_rup_f16);
    if (fa_cov_rup_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rup_f16 < 100"); end
    $display("[COV] VectorFloatFMA.rmm_f16 = %0d", fa_cov_rmm_f16);
    if (fa_cov_rmm_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rmm_f16 < 100"); end
    $display("[COV] VectorFloatFMA.rm_invalid_f16 = %0d", fa_cov_rm_invalid_f16);
    if (fa_cov_rm_invalid_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rm_invalid_f16 < 100"); end
    $display("[COV] VectorFloatFMA.flag_NV_f16 = %0d", fa_cov_flag_NV_f16);
    if (fa_cov_flag_NV_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_NV_f16 < 100"); end
    $display("[COV] VectorFloatFMA.flag_OF_f16 = %0d", fa_cov_flag_OF_f16);
    if (fa_cov_flag_OF_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_OF_f16 < 100"); end
    $display("[COV] VectorFloatFMA.flag_UF_f16 = %0d", fa_cov_flag_UF_f16);
    if (fa_cov_flag_UF_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_UF_f16 < 100"); end
    $display("[COV] VectorFloatFMA.flag_NX_f16 = %0d", fa_cov_flag_NX_f16);
    if (fa_cov_flag_NX_f16 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_NX_f16 < 100"); end
    $display("[COV] VectorFloatFMA.rne_f32 = %0d", fa_cov_rne_f32);
    if (fa_cov_rne_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rne_f32 < 100"); end
    $display("[COV] VectorFloatFMA.rtz_f32 = %0d", fa_cov_rtz_f32);
    if (fa_cov_rtz_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rtz_f32 < 100"); end
    $display("[COV] VectorFloatFMA.rdn_f32 = %0d", fa_cov_rdn_f32);
    if (fa_cov_rdn_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rdn_f32 < 100"); end
    $display("[COV] VectorFloatFMA.rup_f32 = %0d", fa_cov_rup_f32);
    if (fa_cov_rup_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rup_f32 < 100"); end
    $display("[COV] VectorFloatFMA.rmm_f32 = %0d", fa_cov_rmm_f32);
    if (fa_cov_rmm_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rmm_f32 < 100"); end
    $display("[COV] VectorFloatFMA.rm_invalid_f32 = %0d", fa_cov_rm_invalid_f32);
    if (fa_cov_rm_invalid_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rm_invalid_f32 < 100"); end
    $display("[COV] VectorFloatFMA.flag_NV_f32 = %0d", fa_cov_flag_NV_f32);
    if (fa_cov_flag_NV_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_NV_f32 < 100"); end
    $display("[COV] VectorFloatFMA.flag_OF_f32 = %0d", fa_cov_flag_OF_f32);
    if (fa_cov_flag_OF_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_OF_f32 < 100"); end
    $display("[COV] VectorFloatFMA.flag_UF_f32 = %0d", fa_cov_flag_UF_f32);
    if (fa_cov_flag_UF_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_UF_f32 < 100"); end
    $display("[COV] VectorFloatFMA.flag_NX_f32 = %0d", fa_cov_flag_NX_f32);
    if (fa_cov_flag_NX_f32 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_NX_f32 < 100"); end
    $display("[COV] VectorFloatFMA.rne_f64 = %0d", fa_cov_rne_f64);
    if (fa_cov_rne_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rne_f64 < 100"); end
    $display("[COV] VectorFloatFMA.rtz_f64 = %0d", fa_cov_rtz_f64);
    if (fa_cov_rtz_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rtz_f64 < 100"); end
    $display("[COV] VectorFloatFMA.rdn_f64 = %0d", fa_cov_rdn_f64);
    if (fa_cov_rdn_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rdn_f64 < 100"); end
    $display("[COV] VectorFloatFMA.rup_f64 = %0d", fa_cov_rup_f64);
    if (fa_cov_rup_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rup_f64 < 100"); end
    $display("[COV] VectorFloatFMA.rmm_f64 = %0d", fa_cov_rmm_f64);
    if (fa_cov_rmm_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rmm_f64 < 100"); end
    $display("[COV] VectorFloatFMA.rm_invalid_f64 = %0d", fa_cov_rm_invalid_f64);
    if (fa_cov_rm_invalid_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.rm_invalid_f64 < 100"); end
    $display("[COV] VectorFloatFMA.flag_NV_f64 = %0d", fa_cov_flag_NV_f64);
    if (fa_cov_flag_NV_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_NV_f64 < 100"); end
    $display("[COV] VectorFloatFMA.flag_OF_f64 = %0d", fa_cov_flag_OF_f64);
    if (fa_cov_flag_OF_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_OF_f64 < 100"); end
    $display("[COV] VectorFloatFMA.flag_UF_f64 = %0d", fa_cov_flag_UF_f64);
    if (fa_cov_flag_UF_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_UF_f64 < 100"); end
    $display("[COV] VectorFloatFMA.flag_NX_f64 = %0d", fa_cov_flag_NX_f64);
    if (fa_cov_flag_NX_f64 < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.flag_NX_f64 < 100"); end
    $display("[COV] VectorFloatFMA.f64_nan = %0d", fa_cov_f64_nan);
    if (fa_cov_f64_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_nan < 100"); end
    $display("[COV] VectorFloatFMA.f64_nan_nv = %0d", fa_cov_f64_nan_nv);
    if (fa_cov_f64_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f64_inf = %0d", fa_cov_f64_inf);
    if (fa_cov_f64_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_inf < 100"); end
    $display("[COV] VectorFloatFMA.f64_inf_nv = %0d", fa_cov_f64_inf_nv);
    if (fa_cov_f64_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f64_overflow = %0d", fa_cov_f64_overflow);
    if (fa_cov_f64_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f64_ab_zero = %0d", fa_cov_f64_ab_zero);
    if (fa_cov_f64_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f64_sum_zero = %0d", fa_cov_f64_sum_zero);
    if (fa_cov_f64_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f64_subnormal = %0d", fa_cov_f64_subnormal);
    if (fa_cov_f64_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f64_is_fix = %0d", fa_cov_f64_is_fix);
    if (fa_cov_f64_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f64_sum_neg = %0d", fa_cov_f64_sum_neg);
    if (fa_cov_f64_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f64_uf = %0d", fa_cov_f64_uf);
    if (fa_cov_f64_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_uf < 100"); end
    $display("[COV] VectorFloatFMA.f64_nx = %0d", fa_cov_f64_nx);
    if (fa_cov_f64_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_nx < 100"); end
    $display("[COV] VectorFloatFMA.f64_exact = %0d", fa_cov_f64_exact);
    if (fa_cov_f64_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_exact < 100"); end
    $display("[COV] VectorFloatFMA.f64_round_up = %0d", fa_cov_f64_round_up);
    if (fa_cov_f64_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f64_exp_carry = %0d", fa_cov_f64_exp_carry);
    if (fa_cov_f64_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f64_c_medium = %0d", fa_cov_f64_c_medium);
    if (fa_cov_f64_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f64_c_too_big = %0d", fa_cov_f64_c_too_big);
    if (fa_cov_f64_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f64_c_too_small = %0d", fa_cov_f64_c_too_small);
    if (fa_cov_f64_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f64_c_too_small < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_nan = %0d", fa_cov_f32_0_nan);
    if (fa_cov_f32_0_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_nan < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_nan_nv = %0d", fa_cov_f32_0_nan_nv);
    if (fa_cov_f32_0_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_inf = %0d", fa_cov_f32_0_inf);
    if (fa_cov_f32_0_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_inf < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_inf_nv = %0d", fa_cov_f32_0_inf_nv);
    if (fa_cov_f32_0_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_overflow = %0d", fa_cov_f32_0_overflow);
    if (fa_cov_f32_0_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_ab_zero = %0d", fa_cov_f32_0_ab_zero);
    if (fa_cov_f32_0_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_sum_zero = %0d", fa_cov_f32_0_sum_zero);
    if (fa_cov_f32_0_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_subnormal = %0d", fa_cov_f32_0_subnormal);
    if (fa_cov_f32_0_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_is_fix = %0d", fa_cov_f32_0_is_fix);
    if (fa_cov_f32_0_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_sum_neg = %0d", fa_cov_f32_0_sum_neg);
    if (fa_cov_f32_0_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_uf = %0d", fa_cov_f32_0_uf);
    if (fa_cov_f32_0_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_uf < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_nx = %0d", fa_cov_f32_0_nx);
    if (fa_cov_f32_0_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_nx < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_exact = %0d", fa_cov_f32_0_exact);
    if (fa_cov_f32_0_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_exact < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_round_up = %0d", fa_cov_f32_0_round_up);
    if (fa_cov_f32_0_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_exp_carry = %0d", fa_cov_f32_0_exp_carry);
    if (fa_cov_f32_0_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_c_medium = %0d", fa_cov_f32_0_c_medium);
    if (fa_cov_f32_0_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_c_too_big = %0d", fa_cov_f32_0_c_too_big);
    if (fa_cov_f32_0_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f32_0_c_too_small = %0d", fa_cov_f32_0_c_too_small);
    if (fa_cov_f32_0_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_0_c_too_small < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_nan = %0d", fa_cov_f32_1_nan);
    if (fa_cov_f32_1_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_nan < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_nan_nv = %0d", fa_cov_f32_1_nan_nv);
    if (fa_cov_f32_1_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_inf = %0d", fa_cov_f32_1_inf);
    if (fa_cov_f32_1_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_inf < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_inf_nv = %0d", fa_cov_f32_1_inf_nv);
    if (fa_cov_f32_1_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_overflow = %0d", fa_cov_f32_1_overflow);
    if (fa_cov_f32_1_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_ab_zero = %0d", fa_cov_f32_1_ab_zero);
    if (fa_cov_f32_1_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_sum_zero = %0d", fa_cov_f32_1_sum_zero);
    if (fa_cov_f32_1_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_subnormal = %0d", fa_cov_f32_1_subnormal);
    if (fa_cov_f32_1_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_is_fix = %0d", fa_cov_f32_1_is_fix);
    if (fa_cov_f32_1_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_sum_neg = %0d", fa_cov_f32_1_sum_neg);
    if (fa_cov_f32_1_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_uf = %0d", fa_cov_f32_1_uf);
    if (fa_cov_f32_1_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_uf < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_nx = %0d", fa_cov_f32_1_nx);
    if (fa_cov_f32_1_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_nx < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_exact = %0d", fa_cov_f32_1_exact);
    if (fa_cov_f32_1_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_exact < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_round_up = %0d", fa_cov_f32_1_round_up);
    if (fa_cov_f32_1_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_exp_carry = %0d", fa_cov_f32_1_exp_carry);
    if (fa_cov_f32_1_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_c_medium = %0d", fa_cov_f32_1_c_medium);
    if (fa_cov_f32_1_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_c_too_big = %0d", fa_cov_f32_1_c_too_big);
    if (fa_cov_f32_1_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f32_1_c_too_small = %0d", fa_cov_f32_1_c_too_small);
    if (fa_cov_f32_1_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f32_1_c_too_small < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_nan = %0d", fa_cov_f16_0_nan);
    if (fa_cov_f16_0_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_nan < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_nan_nv = %0d", fa_cov_f16_0_nan_nv);
    if (fa_cov_f16_0_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_inf = %0d", fa_cov_f16_0_inf);
    if (fa_cov_f16_0_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_inf < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_inf_nv = %0d", fa_cov_f16_0_inf_nv);
    if (fa_cov_f16_0_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_overflow = %0d", fa_cov_f16_0_overflow);
    if (fa_cov_f16_0_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_ab_zero = %0d", fa_cov_f16_0_ab_zero);
    if (fa_cov_f16_0_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_sum_zero = %0d", fa_cov_f16_0_sum_zero);
    if (fa_cov_f16_0_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_subnormal = %0d", fa_cov_f16_0_subnormal);
    if (fa_cov_f16_0_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_is_fix = %0d", fa_cov_f16_0_is_fix);
    if (fa_cov_f16_0_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_sum_neg = %0d", fa_cov_f16_0_sum_neg);
    if (fa_cov_f16_0_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_uf = %0d", fa_cov_f16_0_uf);
    if (fa_cov_f16_0_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_uf < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_nx = %0d", fa_cov_f16_0_nx);
    if (fa_cov_f16_0_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_nx < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_exact = %0d", fa_cov_f16_0_exact);
    if (fa_cov_f16_0_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_exact < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_round_up = %0d", fa_cov_f16_0_round_up);
    if (fa_cov_f16_0_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_exp_carry = %0d", fa_cov_f16_0_exp_carry);
    if (fa_cov_f16_0_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_c_medium = %0d", fa_cov_f16_0_c_medium);
    if (fa_cov_f16_0_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_c_too_big = %0d", fa_cov_f16_0_c_too_big);
    if (fa_cov_f16_0_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f16_0_c_too_small = %0d", fa_cov_f16_0_c_too_small);
    if (fa_cov_f16_0_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_0_c_too_small < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_nan = %0d", fa_cov_f16_1_nan);
    if (fa_cov_f16_1_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_nan < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_nan_nv = %0d", fa_cov_f16_1_nan_nv);
    if (fa_cov_f16_1_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_inf = %0d", fa_cov_f16_1_inf);
    if (fa_cov_f16_1_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_inf < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_inf_nv = %0d", fa_cov_f16_1_inf_nv);
    if (fa_cov_f16_1_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_overflow = %0d", fa_cov_f16_1_overflow);
    if (fa_cov_f16_1_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_ab_zero = %0d", fa_cov_f16_1_ab_zero);
    if (fa_cov_f16_1_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_sum_zero = %0d", fa_cov_f16_1_sum_zero);
    if (fa_cov_f16_1_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_subnormal = %0d", fa_cov_f16_1_subnormal);
    if (fa_cov_f16_1_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_is_fix = %0d", fa_cov_f16_1_is_fix);
    if (fa_cov_f16_1_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_sum_neg = %0d", fa_cov_f16_1_sum_neg);
    if (fa_cov_f16_1_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_uf = %0d", fa_cov_f16_1_uf);
    if (fa_cov_f16_1_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_uf < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_nx = %0d", fa_cov_f16_1_nx);
    if (fa_cov_f16_1_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_nx < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_exact = %0d", fa_cov_f16_1_exact);
    if (fa_cov_f16_1_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_exact < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_round_up = %0d", fa_cov_f16_1_round_up);
    if (fa_cov_f16_1_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_exp_carry = %0d", fa_cov_f16_1_exp_carry);
    if (fa_cov_f16_1_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_c_medium = %0d", fa_cov_f16_1_c_medium);
    if (fa_cov_f16_1_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_c_too_big = %0d", fa_cov_f16_1_c_too_big);
    if (fa_cov_f16_1_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f16_1_c_too_small = %0d", fa_cov_f16_1_c_too_small);
    if (fa_cov_f16_1_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_1_c_too_small < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_nan = %0d", fa_cov_f16_2_nan);
    if (fa_cov_f16_2_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_nan < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_nan_nv = %0d", fa_cov_f16_2_nan_nv);
    if (fa_cov_f16_2_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_inf = %0d", fa_cov_f16_2_inf);
    if (fa_cov_f16_2_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_inf < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_inf_nv = %0d", fa_cov_f16_2_inf_nv);
    if (fa_cov_f16_2_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_overflow = %0d", fa_cov_f16_2_overflow);
    if (fa_cov_f16_2_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_ab_zero = %0d", fa_cov_f16_2_ab_zero);
    if (fa_cov_f16_2_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_sum_zero = %0d", fa_cov_f16_2_sum_zero);
    if (fa_cov_f16_2_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_subnormal = %0d", fa_cov_f16_2_subnormal);
    if (fa_cov_f16_2_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_is_fix = %0d", fa_cov_f16_2_is_fix);
    if (fa_cov_f16_2_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_sum_neg = %0d", fa_cov_f16_2_sum_neg);
    if (fa_cov_f16_2_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_uf = %0d", fa_cov_f16_2_uf);
    if (fa_cov_f16_2_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_uf < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_nx = %0d", fa_cov_f16_2_nx);
    if (fa_cov_f16_2_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_nx < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_exact = %0d", fa_cov_f16_2_exact);
    if (fa_cov_f16_2_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_exact < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_round_up = %0d", fa_cov_f16_2_round_up);
    if (fa_cov_f16_2_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_exp_carry = %0d", fa_cov_f16_2_exp_carry);
    if (fa_cov_f16_2_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_c_medium = %0d", fa_cov_f16_2_c_medium);
    if (fa_cov_f16_2_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_c_too_big = %0d", fa_cov_f16_2_c_too_big);
    if (fa_cov_f16_2_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f16_2_c_too_small = %0d", fa_cov_f16_2_c_too_small);
    if (fa_cov_f16_2_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_2_c_too_small < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_nan = %0d", fa_cov_f16_3_nan);
    if (fa_cov_f16_3_nan < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_nan < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_nan_nv = %0d", fa_cov_f16_3_nan_nv);
    if (fa_cov_f16_3_nan_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_nan_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_inf = %0d", fa_cov_f16_3_inf);
    if (fa_cov_f16_3_inf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_inf < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_inf_nv = %0d", fa_cov_f16_3_inf_nv);
    if (fa_cov_f16_3_inf_nv < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_inf_nv < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_overflow = %0d", fa_cov_f16_3_overflow);
    if (fa_cov_f16_3_overflow < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_overflow < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_ab_zero = %0d", fa_cov_f16_3_ab_zero);
    if (fa_cov_f16_3_ab_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_ab_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_sum_zero = %0d", fa_cov_f16_3_sum_zero);
    if (fa_cov_f16_3_sum_zero < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_sum_zero < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_subnormal = %0d", fa_cov_f16_3_subnormal);
    if (fa_cov_f16_3_subnormal < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_subnormal < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_is_fix = %0d", fa_cov_f16_3_is_fix);
    if (fa_cov_f16_3_is_fix < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_is_fix < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_sum_neg = %0d", fa_cov_f16_3_sum_neg);
    if (fa_cov_f16_3_sum_neg < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_sum_neg < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_uf = %0d", fa_cov_f16_3_uf);
    if (fa_cov_f16_3_uf < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_uf < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_nx = %0d", fa_cov_f16_3_nx);
    if (fa_cov_f16_3_nx < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_nx < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_exact = %0d", fa_cov_f16_3_exact);
    if (fa_cov_f16_3_exact < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_exact < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_round_up = %0d", fa_cov_f16_3_round_up);
    if (fa_cov_f16_3_round_up < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_round_up < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_exp_carry = %0d", fa_cov_f16_3_exp_carry);
    if (fa_cov_f16_3_exp_carry < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_exp_carry < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_c_medium = %0d", fa_cov_f16_3_c_medium);
    if (fa_cov_f16_3_c_medium < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_c_medium < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_c_too_big = %0d", fa_cov_f16_3_c_too_big);
    if (fa_cov_f16_3_c_too_big < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_c_too_big < 100"); end
    $display("[COV] VectorFloatFMA.f16_3_c_too_small = %0d", fa_cov_f16_3_c_too_small);
    if (fa_cov_f16_3_c_too_small < 100) begin cov_fail++; $display("[COV] VectorFloatFMA.f16_3_c_too_small < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
