// 自动生成：verif/ut/BeDataLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// 后端五个数据叶子双例化逐拍比对：golden <名> vs 重写 <名>_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= VsetModule =================
  int unsigned be_vs_mode = 0;
  logic [63:0] be_vs_io_in_avl;
  logic be_vs_io_in_vtype_illegal;
  logic [54:0] be_vs_io_in_vtype_reserved;
  logic be_vs_io_in_vtype_vma;
  logic be_vs_io_in_vtype_vta;
  logic [2:0] be_vs_io_in_vtype_vsew;
  logic [2:0] be_vs_io_in_vtype_vlmul;
  logic [8:0] be_vs_io_in_func;
  wire  be_vs_g_io_out_vconfig_vtype_illegal, be_vs_i_io_out_vconfig_vtype_illegal;
  logic be_vs_s0_io_out_vconfig_vtype_illegal = '0, be_vs_s1_io_out_vconfig_vtype_illegal = '0;
  wire  be_vs_g_io_out_vconfig_vtype_vma, be_vs_i_io_out_vconfig_vtype_vma;
  logic be_vs_s0_io_out_vconfig_vtype_vma = '0, be_vs_s1_io_out_vconfig_vtype_vma = '0;
  wire  be_vs_g_io_out_vconfig_vtype_vta, be_vs_i_io_out_vconfig_vtype_vta;
  logic be_vs_s0_io_out_vconfig_vtype_vta = '0, be_vs_s1_io_out_vconfig_vtype_vta = '0;
  wire  [1:0] be_vs_g_io_out_vconfig_vtype_vsew, be_vs_i_io_out_vconfig_vtype_vsew;
  logic [1:0] be_vs_s0_io_out_vconfig_vtype_vsew = '0, be_vs_s1_io_out_vconfig_vtype_vsew = '0;
  wire  [2:0] be_vs_g_io_out_vconfig_vtype_vlmul, be_vs_i_io_out_vconfig_vtype_vlmul;
  logic [2:0] be_vs_s0_io_out_vconfig_vtype_vlmul = '0, be_vs_s1_io_out_vconfig_vtype_vlmul = '0;
  wire  [7:0] be_vs_g_io_out_vconfig_vl, be_vs_i_io_out_vconfig_vl;
  logic [7:0] be_vs_s0_io_out_vconfig_vl = '0, be_vs_s1_io_out_vconfig_vl = '0;
  wire  [7:0] be_vs_g_io_out_vlmax, be_vs_i_io_out_vlmax;
  logic [7:0] be_vs_s0_io_out_vlmax = '0, be_vs_s1_io_out_vlmax = '0;
  int be_vs_cov_legal = 0;
  int be_vs_cov_vl_is_vlmax = 0;
  int be_vs_cov_vl_is_avl = 0;
  int be_vs_cov_setvlmax = 0;
  int be_vs_cov_frac_lmul = 0;
  logic [0:0] be_vs_armed = '0;
  int be_vs_armed_at = -1;
  VsetModule be_vs_u_gold (
    .io_in_avl(be_vs_io_in_avl),
    .io_in_vtype_illegal(be_vs_io_in_vtype_illegal),
    .io_in_vtype_reserved(be_vs_io_in_vtype_reserved),
    .io_in_vtype_vma(be_vs_io_in_vtype_vma),
    .io_in_vtype_vta(be_vs_io_in_vtype_vta),
    .io_in_vtype_vsew(be_vs_io_in_vtype_vsew),
    .io_in_vtype_vlmul(be_vs_io_in_vtype_vlmul),
    .io_in_func(be_vs_io_in_func),
    .io_out_vconfig_vtype_illegal(be_vs_g_io_out_vconfig_vtype_illegal),
    .io_out_vconfig_vtype_vma(be_vs_g_io_out_vconfig_vtype_vma),
    .io_out_vconfig_vtype_vta(be_vs_g_io_out_vconfig_vtype_vta),
    .io_out_vconfig_vtype_vsew(be_vs_g_io_out_vconfig_vtype_vsew),
    .io_out_vconfig_vtype_vlmul(be_vs_g_io_out_vconfig_vtype_vlmul),
    .io_out_vconfig_vl(be_vs_g_io_out_vconfig_vl),
    .io_out_vlmax(be_vs_g_io_out_vlmax)
  );
  VsetModule_xs be_vs_u_impl (
    .io_in_avl(be_vs_io_in_avl),
    .io_in_vtype_illegal(be_vs_io_in_vtype_illegal),
    .io_in_vtype_reserved(be_vs_io_in_vtype_reserved),
    .io_in_vtype_vma(be_vs_io_in_vtype_vma),
    .io_in_vtype_vta(be_vs_io_in_vtype_vta),
    .io_in_vtype_vsew(be_vs_io_in_vtype_vsew),
    .io_in_vtype_vlmul(be_vs_io_in_vtype_vlmul),
    .io_in_func(be_vs_io_in_func),
    .io_out_vconfig_vtype_illegal(be_vs_i_io_out_vconfig_vtype_illegal),
    .io_out_vconfig_vtype_vma(be_vs_i_io_out_vconfig_vtype_vma),
    .io_out_vconfig_vtype_vta(be_vs_i_io_out_vconfig_vtype_vta),
    .io_out_vconfig_vtype_vsew(be_vs_i_io_out_vconfig_vtype_vsew),
    .io_out_vconfig_vtype_vlmul(be_vs_i_io_out_vconfig_vtype_vlmul),
    .io_out_vconfig_vl(be_vs_i_io_out_vconfig_vl),
    .io_out_vlmax(be_vs_i_io_out_vlmax)
  );

  // ================= strdiedLSNumOfUopTable =================
  int unsigned be_st_mode = 0;
  logic [4:0] be_st_src;
  wire  [3:0] be_st_g_out, be_st_i_out;
  logic [3:0] be_st_s0_out = '0, be_st_s1_out = '0;
  logic [0:0] be_st_armed = '0;
  int be_st_armed_at = -1;
  strdiedLSNumOfUopTable be_st_u_gold (
    .src(be_st_src),
    .out(be_st_g_out)
  );
  strdiedLSNumOfUopTable_xs be_st_u_impl (
    .src(be_st_src),
    .out(be_st_i_out)
  );

  // ================= indexedLSNumOfUopTable =================
  int unsigned be_ix_mode = 0;
  logic [6:0] be_ix_src;
  wire  [6:0] be_ix_g_out, be_ix_i_out;
  logic [6:0] be_ix_s0_out = '0, be_ix_s1_out = '0;
  logic [0:0] be_ix_armed = '0;
  int be_ix_armed_at = -1;
  indexedLSNumOfUopTable be_ix_u_gold (
    .src(be_ix_src),
    .out(be_ix_g_out)
  );
  indexedLSNumOfUopTable_xs be_ix_u_impl (
    .src(be_ix_src),
    .out(be_ix_i_out)
  );

  // ================= IntToFPDataModule =================
  int unsigned be_i2f_mode = 0;
  logic be_i2f_clock;
  logic [63:0] be_i2f_io_in_src_0;
  logic [1:0] be_i2f_io_in_fpCtrl_typeTagOut;
  logic be_i2f_io_in_fpCtrl_wflags;
  logic [1:0] be_i2f_io_in_fpCtrl_typ;
  logic [2:0] be_i2f_io_in_fpCtrl_rm;
  logic [2:0] be_i2f_io_in_rm;
  wire  [63:0] be_i2f_g_io_out_data, be_i2f_i_io_out_data;
  logic [63:0] be_i2f_s0_io_out_data = '0, be_i2f_s1_io_out_data = '0;
  wire  [4:0] be_i2f_g_io_out_fflags, be_i2f_i_io_out_fflags;
  logic [4:0] be_i2f_s0_io_out_fflags = '0, be_i2f_s1_io_out_fflags = '0;
  logic be_i2f_regEnables_0;
  logic be_i2f_regEnables_1;
  int be_i2f_cov_tag0 = 0;
  int be_i2f_cov_tag1 = 0;
  int be_i2f_cov_tag2 = 0;
  int be_i2f_cov_tag3 = 0;
  int be_i2f_cov_nx = 0;
  int be_i2f_cov_fmv = 0;
  int be_i2f_cov_dyn_rm = 0;
  logic [1:0] be_i2f_armed = '0;
  int be_i2f_armed_at = -1;
  IntToFPDataModule be_i2f_u_gold (
    .clock(clk),
    .io_in_src_0(be_i2f_io_in_src_0),
    .io_in_fpCtrl_typeTagOut(be_i2f_io_in_fpCtrl_typeTagOut),
    .io_in_fpCtrl_wflags(be_i2f_io_in_fpCtrl_wflags),
    .io_in_fpCtrl_typ(be_i2f_io_in_fpCtrl_typ),
    .io_in_fpCtrl_rm(be_i2f_io_in_fpCtrl_rm),
    .io_in_rm(be_i2f_io_in_rm),
    .io_out_data(be_i2f_g_io_out_data),
    .io_out_fflags(be_i2f_g_io_out_fflags),
    .regEnables_0(be_i2f_regEnables_0),
    .regEnables_1(be_i2f_regEnables_1)
  );
  IntToFPDataModule_xs be_i2f_u_impl (
    .clock(clk),
    .io_in_src_0(be_i2f_io_in_src_0),
    .io_in_fpCtrl_typeTagOut(be_i2f_io_in_fpCtrl_typeTagOut),
    .io_in_fpCtrl_wflags(be_i2f_io_in_fpCtrl_wflags),
    .io_in_fpCtrl_typ(be_i2f_io_in_fpCtrl_typ),
    .io_in_fpCtrl_rm(be_i2f_io_in_fpCtrl_rm),
    .io_in_rm(be_i2f_io_in_rm),
    .io_out_data(be_i2f_i_io_out_data),
    .io_out_fflags(be_i2f_i_io_out_fflags),
    .regEnables_0(be_i2f_regEnables_0),
    .regEnables_1(be_i2f_regEnables_1)
  );

  // ================= AluDataModule =================
  int unsigned be_alu_mode = 0;
  logic [6:0] alu_ops [92] = '{7'h00, 7'h01, 7'h02, 7'h03, 7'h04, 7'h05, 7'h06, 7'h07, 7'h08, 7'h09, 7'h0A, 7'h0B, 7'h0C, 7'h0D, 7'h10, 7'h11, 7'h12, 7'h13, 7'h14, 7'h15, 7'h16, 7'h17, 7'h18, 7'h19, 7'h1A, 7'h1B, 7'h1C, 7'h1D, 7'h20, 7'h21, 7'h22, 7'h23, 7'h24, 7'h25, 7'h26, 7'h27, 7'h28, 7'h29, 7'h2A, 7'h2B, 7'h2C, 7'h2D, 7'h2E, 7'h2F, 7'h30, 7'h31, 7'h32, 7'h33, 7'h34, 7'h35, 7'h36, 7'h37, 7'h40, 7'h41, 7'h42, 7'h43, 7'h44, 7'h45, 7'h46, 7'h47, 7'h48, 7'h49, 7'h4A, 7'h4B, 7'h50, 7'h51, 7'h52, 7'h53, 7'h54, 7'h55, 7'h56, 7'h57, 7'h58, 7'h59, 7'h5A, 7'h5B, 7'h60, 7'h61, 7'h62, 7'h63, 7'h64, 7'h65, 7'h66, 7'h67, 7'h68, 7'h69, 7'h6A, 7'h6B, 7'h70, 7'h71, 7'h72, 7'h73};
  logic [63:0] be_alu_io_src_0;
  logic [63:0] be_alu_io_src_1;
  logic [8:0] be_alu_io_func;
  wire  [63:0] be_alu_g_io_result, be_alu_i_io_result;
  logic [63:0] be_alu_s0_io_result = '0, be_alu_s1_io_result = '0;
  int be_alu_cov_ch0 = 0;
  int be_alu_cov_ch1 = 0;
  int be_alu_cov_ch2 = 0;
  int be_alu_cov_ch3 = 0;
  int be_alu_cov_ch4 = 0;
  int be_alu_cov_ch5 = 0;
  int be_alu_cov_ch6 = 0;
  int be_alu_cov_ch7 = 0;
  int be_alu_cov_eq_src = 0;
  logic [0:0] be_alu_armed = '0;
  int be_alu_armed_at = -1;
  AluDataModule be_alu_u_gold (
    .io_src_0(be_alu_io_src_0),
    .io_src_1(be_alu_io_src_1),
    .io_func(be_alu_io_func),
    .io_result(be_alu_g_io_result)
  );
  AluDataModule_xs be_alu_u_impl (
    .io_src_0(be_alu_io_src_0),
    .io_src_1(be_alu_io_src_1),
    .io_func(be_alu_io_func),
    .io_result(be_alu_i_io_result)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) be_vs_mode = $urandom_range(0, 15);
      be_vs_io_in_avl = 64'({$urandom, $urandom});
      be_vs_io_in_vtype_illegal = 1'($urandom);
      be_vs_io_in_vtype_reserved = 55'({$urandom, $urandom});
      be_vs_io_in_vtype_vma = 1'($urandom);
      be_vs_io_in_vtype_vta = 1'($urandom);
      be_vs_io_in_vtype_vsew = 3'($urandom);
      be_vs_io_in_vtype_vlmul = 3'($urandom);
      be_vs_io_in_func = 9'($urandom);
      begin : stim_be_vs
        if ($urandom_range(0, 7) != 0) be_vs_io_in_vtype_reserved = '0;
        if ($urandom_range(0, 7) != 0) be_vs_io_in_vtype_illegal = 1'b0;
        if ($urandom_range(0, 1)) be_vs_io_in_avl = 64'($urandom_range(0, 300));
        case ($urandom_range(0, 3))
          0: be_vs_io_in_func = 9'h0A0 | 9'($urandom_range(0, 1));   // vsetvli（可带 setVlmax）
          1: be_vs_io_in_func = 9'h040 | 9'($urandom_range(0, 1));   // vsetvl
          2: be_vs_io_in_func = 9'h000 | 9'($urandom_range(0, 1));   // vsetivli
          default: ;
        endcase
      end
      if (cyc % 4000 == 0) be_st_mode = $urandom_range(0, 15);
      be_st_src = 5'($urandom);
      if (cyc % 4000 == 0) be_ix_mode = $urandom_range(0, 15);
      be_ix_src = 7'($urandom);
      if (cyc % 300 == 0) be_i2f_mode = $urandom_range(0, 15);
      be_i2f_io_in_src_0 = 64'({$urandom, $urandom});
      be_i2f_io_in_fpCtrl_typeTagOut = 2'($urandom);
      be_i2f_io_in_fpCtrl_wflags = 1'($urandom);
      be_i2f_io_in_fpCtrl_typ = 2'($urandom);
      be_i2f_io_in_fpCtrl_rm = 3'($urandom);
      be_i2f_io_in_rm = 3'($urandom);
      be_i2f_regEnables_0 = 1'($urandom);
      be_i2f_regEnables_1 = 1'($urandom);
      begin : stim_be_i2f
        case (be_i2f_mode % 4)
          0: begin be_i2f_regEnables_0 = 1'b1; be_i2f_regEnables_1 = 1'b1; end
          1: begin be_i2f_regEnables_0 = ($urandom_range(0, 3) == 0); be_i2f_regEnables_1 = ($urandom_range(0, 3) == 0); end
          default: ;
        endcase
        case ($urandom_range(0, 3))
          0: be_i2f_io_in_src_0 = 64'($signed(16'($urandom)));
          1: be_i2f_io_in_src_0 = {$urandom_range(0, 1) ? 32'hFFFF_FFFF : 32'h0, 1'($urandom), 31'($urandom)};
          2: be_i2f_io_in_src_0 = 64'h1 << $urandom_range(0, 63);
          default: ;
        endcase
        if ($urandom_range(0, 3) == 0) be_i2f_io_in_fpCtrl_rm = 3'b111;
      end
      if (cyc % 4000 == 0) be_alu_mode = $urandom_range(0, 15);
      be_alu_io_src_0 = 64'({$urandom, $urandom});
      be_alu_io_src_1 = 64'({$urandom, $urandom});
      be_alu_io_func = 9'($urandom);
      begin : stim_be_alu
        if ($urandom_range(0, 1)) be_alu_io_func = {2'($urandom), alu_ops[$urandom_range(0, $size(alu_ops) - 1)]};
        case ($urandom_range(0, 5))
          0: be_alu_io_src_1[5:0] = 6'd0;
          1: be_alu_io_src_1[5:0] = 6'd31;
          2: be_alu_io_src_1[5:0] = 6'd32;
          3: be_alu_io_src_1[5:0] = 6'd63;
          default: ;
        endcase
        if ($urandom_range(0, 7) == 0) be_alu_io_src_1 = be_alu_io_src_0;
        if ($urandom_range(0, 7) == 0) be_alu_io_src_1 = '0;
      end
      #4;
      be_vs_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&be_vs_armed)) begin
        checks++;
        if (be_vs_g_io_out_vconfig_vtype_illegal !== be_vs_i_io_out_vconfig_vtype_illegal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vconfig_vtype_illegal g=%h i=%h", cyc, be_vs_g_io_out_vconfig_vtype_illegal, be_vs_i_io_out_vconfig_vtype_illegal);
        end
        be_vs_s1_io_out_vconfig_vtype_illegal |= be_vs_g_io_out_vconfig_vtype_illegal;
        be_vs_s0_io_out_vconfig_vtype_illegal |= ~be_vs_g_io_out_vconfig_vtype_illegal;
        checks++;
        if (be_vs_g_io_out_vconfig_vtype_vma !== be_vs_i_io_out_vconfig_vtype_vma) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vconfig_vtype_vma g=%h i=%h", cyc, be_vs_g_io_out_vconfig_vtype_vma, be_vs_i_io_out_vconfig_vtype_vma);
        end
        be_vs_s1_io_out_vconfig_vtype_vma |= be_vs_g_io_out_vconfig_vtype_vma;
        be_vs_s0_io_out_vconfig_vtype_vma |= ~be_vs_g_io_out_vconfig_vtype_vma;
        checks++;
        if (be_vs_g_io_out_vconfig_vtype_vta !== be_vs_i_io_out_vconfig_vtype_vta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vconfig_vtype_vta g=%h i=%h", cyc, be_vs_g_io_out_vconfig_vtype_vta, be_vs_i_io_out_vconfig_vtype_vta);
        end
        be_vs_s1_io_out_vconfig_vtype_vta |= be_vs_g_io_out_vconfig_vtype_vta;
        be_vs_s0_io_out_vconfig_vtype_vta |= ~be_vs_g_io_out_vconfig_vtype_vta;
        checks++;
        if (be_vs_g_io_out_vconfig_vtype_vsew !== be_vs_i_io_out_vconfig_vtype_vsew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vconfig_vtype_vsew g=%h i=%h", cyc, be_vs_g_io_out_vconfig_vtype_vsew, be_vs_i_io_out_vconfig_vtype_vsew);
        end
        be_vs_s1_io_out_vconfig_vtype_vsew |= be_vs_g_io_out_vconfig_vtype_vsew;
        be_vs_s0_io_out_vconfig_vtype_vsew |= ~be_vs_g_io_out_vconfig_vtype_vsew;
        checks++;
        if (be_vs_g_io_out_vconfig_vtype_vlmul !== be_vs_i_io_out_vconfig_vtype_vlmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vconfig_vtype_vlmul g=%h i=%h", cyc, be_vs_g_io_out_vconfig_vtype_vlmul, be_vs_i_io_out_vconfig_vtype_vlmul);
        end
        be_vs_s1_io_out_vconfig_vtype_vlmul |= be_vs_g_io_out_vconfig_vtype_vlmul;
        be_vs_s0_io_out_vconfig_vtype_vlmul |= ~be_vs_g_io_out_vconfig_vtype_vlmul;
        checks++;
        if (be_vs_g_io_out_vconfig_vl !== be_vs_i_io_out_vconfig_vl) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vconfig_vl g=%h i=%h", cyc, be_vs_g_io_out_vconfig_vl, be_vs_i_io_out_vconfig_vl);
        end
        be_vs_s1_io_out_vconfig_vl |= be_vs_g_io_out_vconfig_vl;
        be_vs_s0_io_out_vconfig_vl |= ~be_vs_g_io_out_vconfig_vl;
        checks++;
        if (be_vs_g_io_out_vlmax !== be_vs_i_io_out_vlmax) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VsetModule.io_out_vlmax g=%h i=%h", cyc, be_vs_g_io_out_vlmax, be_vs_i_io_out_vlmax);
        end
        be_vs_s1_io_out_vlmax |= be_vs_g_io_out_vlmax;
        be_vs_s0_io_out_vlmax |= ~be_vs_g_io_out_vlmax;
        if (!be_vs_g_io_out_vconfig_vtype_illegal) be_vs_cov_legal++;
        if (!be_vs_g_io_out_vconfig_vtype_illegal && be_vs_g_io_out_vconfig_vl == be_vs_g_io_out_vlmax && be_vs_io_in_avl > 64'(be_vs_g_io_out_vlmax)) be_vs_cov_vl_is_vlmax++;
        if (!be_vs_g_io_out_vconfig_vtype_illegal && be_vs_io_in_avl < 64'(be_vs_g_io_out_vlmax) && be_vs_io_in_avl != 0) be_vs_cov_vl_is_avl++;
        if (!be_vs_g_io_out_vconfig_vtype_illegal && be_vs_io_in_func[0] && (|be_vs_io_in_func[7:6]) && be_vs_io_in_avl < 64'(be_vs_g_io_out_vlmax)) be_vs_cov_setvlmax++;
        if (!be_vs_g_io_out_vconfig_vtype_illegal && be_vs_io_in_vtype_vlmul[2]) be_vs_cov_frac_lmul++;
      end
      if (be_vs_armed_at < 0 && (&be_vs_armed)) be_vs_armed_at = cyc + 1;
      be_st_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&be_st_armed)) begin
        checks++;
        if (be_st_g_out !== be_st_i_out) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d strdiedLSNumOfUopTable.out g=%h i=%h", cyc, be_st_g_out, be_st_i_out);
        end
        be_st_s1_out |= be_st_g_out;
        be_st_s0_out |= ~be_st_g_out;
      end
      if (be_st_armed_at < 0 && (&be_st_armed)) be_st_armed_at = cyc + 1;
      be_ix_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&be_ix_armed)) begin
        checks++;
        if (be_ix_g_out !== be_ix_i_out) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d indexedLSNumOfUopTable.out g=%h i=%h", cyc, be_ix_g_out, be_ix_i_out);
        end
        be_ix_s1_out |= be_ix_g_out;
        be_ix_s0_out |= ~be_ix_g_out;
      end
      if (be_ix_armed_at < 0 && (&be_ix_armed)) be_ix_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && be_i2f_armed_at >= 0 && cyc >= be_i2f_armed_at) begin
        checks++;
        if (be_i2f_g_io_out_data !== be_i2f_i_io_out_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d IntToFPDataModule.io_out_data g=%h i=%h", cyc, be_i2f_g_io_out_data, be_i2f_i_io_out_data);
        end
        be_i2f_s1_io_out_data |= be_i2f_g_io_out_data;
        be_i2f_s0_io_out_data |= ~be_i2f_g_io_out_data;
        checks++;
        if (be_i2f_g_io_out_fflags !== be_i2f_i_io_out_fflags) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d IntToFPDataModule.io_out_fflags g=%h i=%h", cyc, be_i2f_g_io_out_fflags, be_i2f_i_io_out_fflags);
        end
        be_i2f_s1_io_out_fflags |= be_i2f_g_io_out_fflags;
        be_i2f_s0_io_out_fflags |= ~be_i2f_g_io_out_fflags;
        if (be_i2f_u_gold.s3_tag == 2'd0) be_i2f_cov_tag0++;
        if (be_i2f_u_gold.s3_tag == 2'd1) be_i2f_cov_tag1++;
        if (be_i2f_u_gold.s3_tag == 2'd2) be_i2f_cov_tag2++;
        if (be_i2f_u_gold.s3_tag == 2'd3) be_i2f_cov_tag3++;
        if (be_i2f_g_io_out_fflags[0]) be_i2f_cov_nx++;
        if (be_i2f_regEnables_1 && !be_i2f_u_gold.ctrlReg_wflags) be_i2f_cov_fmv++;
        if (be_i2f_regEnables_0 && be_i2f_io_in_fpCtrl_rm == 3'b111) be_i2f_cov_dyn_rm++;
      end
      if (be_i2f_regEnables_0) be_i2f_armed[0] = 1'b1;
      if (be_i2f_regEnables_1) be_i2f_armed[1] = 1'b1;
      if (be_i2f_armed_at < 0 && (&be_i2f_armed)) be_i2f_armed_at = cyc + 1 + 2;
      be_alu_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&be_alu_armed)) begin
        checks++;
        if (be_alu_g_io_result !== be_alu_i_io_result) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d AluDataModule.io_result g=%h i=%h", cyc, be_alu_g_io_result, be_alu_i_io_result);
        end
        be_alu_s1_io_result |= be_alu_g_io_result;
        be_alu_s0_io_result |= ~be_alu_g_io_result;
        if (be_alu_io_func[6:4] == 3'd0) be_alu_cov_ch0++;
        if (be_alu_io_func[6:4] == 3'd1) be_alu_cov_ch1++;
        if (be_alu_io_func[6:4] == 3'd2) be_alu_cov_ch2++;
        if (be_alu_io_func[6:4] == 3'd3) be_alu_cov_ch3++;
        if (be_alu_io_func[6:4] == 3'd4) be_alu_cov_ch4++;
        if (be_alu_io_func[6:4] == 3'd5) be_alu_cov_ch5++;
        if (be_alu_io_func[6:4] == 3'd6) be_alu_cov_ch6++;
        if (be_alu_io_func[6:4] == 3'd7) be_alu_cov_ch7++;
        if (be_alu_io_src_0 == be_alu_io_src_1) be_alu_cov_eq_src++;
      end
      if (be_alu_armed_at < 0 && (&be_alu_armed)) be_alu_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(be_vs_s0_io_out_vconfig_vtype_illegal && be_vs_s1_io_out_vconfig_vtype_illegal)) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_illegal 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vma && be_vs_s1_io_out_vconfig_vtype_vma)) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vma 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vta && be_vs_s1_io_out_vconfig_vtype_vta)) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vta 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vsew[0] && be_vs_s1_io_out_vconfig_vtype_vsew[0])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vsew[0] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vsew[1] && be_vs_s1_io_out_vconfig_vtype_vsew[1])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vsew[1] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vlmul[0] && be_vs_s1_io_out_vconfig_vtype_vlmul[0])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vlmul[0] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vlmul[1] && be_vs_s1_io_out_vconfig_vtype_vlmul[1])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vlmul[1] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vtype_vlmul[2] && be_vs_s1_io_out_vconfig_vtype_vlmul[2])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vtype_vlmul[2] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[0] && be_vs_s1_io_out_vconfig_vl[0])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[0] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[1] && be_vs_s1_io_out_vconfig_vl[1])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[1] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[2] && be_vs_s1_io_out_vconfig_vl[2])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[2] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[3] && be_vs_s1_io_out_vconfig_vl[3])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[3] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[4] && be_vs_s1_io_out_vconfig_vl[4])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[4] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[5] && be_vs_s1_io_out_vconfig_vl[5])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[5] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[6] && be_vs_s1_io_out_vconfig_vl[6])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[6] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vconfig_vl[7] && be_vs_s1_io_out_vconfig_vl[7])) begin cov_fail++; $display("[COV] VsetModule.io_out_vconfig_vl[7] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[1] && be_vs_s1_io_out_vlmax[1])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[1] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[2] && be_vs_s1_io_out_vlmax[2])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[2] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[3] && be_vs_s1_io_out_vlmax[3])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[3] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[4] && be_vs_s1_io_out_vlmax[4])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[4] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[5] && be_vs_s1_io_out_vlmax[5])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[5] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[6] && be_vs_s1_io_out_vlmax[6])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[6] 未见过 0 和 1"); end
    if (!(be_vs_s0_io_out_vlmax[7] && be_vs_s1_io_out_vlmax[7])) begin cov_fail++; $display("[COV] VsetModule.io_out_vlmax[7] 未见过 0 和 1"); end
    $display("[ARM] VsetModule armed_at=%0d", be_vs_armed_at);
    if (be_vs_armed_at < 0) begin cov_fail++; $display("[ARM] VsetModule 从未 arm"); end
    $display("[COV] VsetModule.legal = %0d", be_vs_cov_legal);
    if (be_vs_cov_legal < 500) begin cov_fail++; $display("[COV] VsetModule.legal < 500"); end
    $display("[COV] VsetModule.vl_is_vlmax = %0d", be_vs_cov_vl_is_vlmax);
    if (be_vs_cov_vl_is_vlmax < 500) begin cov_fail++; $display("[COV] VsetModule.vl_is_vlmax < 500"); end
    $display("[COV] VsetModule.vl_is_avl = %0d", be_vs_cov_vl_is_avl);
    if (be_vs_cov_vl_is_avl < 500) begin cov_fail++; $display("[COV] VsetModule.vl_is_avl < 500"); end
    $display("[COV] VsetModule.setvlmax = %0d", be_vs_cov_setvlmax);
    if (be_vs_cov_setvlmax < 500) begin cov_fail++; $display("[COV] VsetModule.setvlmax < 500"); end
    $display("[COV] VsetModule.frac_lmul = %0d", be_vs_cov_frac_lmul);
    if (be_vs_cov_frac_lmul < 500) begin cov_fail++; $display("[COV] VsetModule.frac_lmul < 500"); end
    if (!(be_st_s0_out[0] && be_st_s1_out[0])) begin cov_fail++; $display("[COV] strdiedLSNumOfUopTable.out[0] 未见过 0 和 1"); end
    if (!(be_st_s0_out[1] && be_st_s1_out[1])) begin cov_fail++; $display("[COV] strdiedLSNumOfUopTable.out[1] 未见过 0 和 1"); end
    if (!(be_st_s0_out[2] && be_st_s1_out[2])) begin cov_fail++; $display("[COV] strdiedLSNumOfUopTable.out[2] 未见过 0 和 1"); end
    if (!(be_st_s0_out[3] && be_st_s1_out[3])) begin cov_fail++; $display("[COV] strdiedLSNumOfUopTable.out[3] 未见过 0 和 1"); end
    $display("[ARM] strdiedLSNumOfUopTable armed_at=%0d", be_st_armed_at);
    if (be_st_armed_at < 0) begin cov_fail++; $display("[ARM] strdiedLSNumOfUopTable 从未 arm"); end
    if (!(be_ix_s0_out[0] && be_ix_s1_out[0])) begin cov_fail++; $display("[COV] indexedLSNumOfUopTable.out[0] 未见过 0 和 1"); end
    if (!(be_ix_s0_out[1] && be_ix_s1_out[1])) begin cov_fail++; $display("[COV] indexedLSNumOfUopTable.out[1] 未见过 0 和 1"); end
    if (!(be_ix_s0_out[2] && be_ix_s1_out[2])) begin cov_fail++; $display("[COV] indexedLSNumOfUopTable.out[2] 未见过 0 和 1"); end
    if (!(be_ix_s0_out[3] && be_ix_s1_out[3])) begin cov_fail++; $display("[COV] indexedLSNumOfUopTable.out[3] 未见过 0 和 1"); end
    $display("[ARM] indexedLSNumOfUopTable armed_at=%0d", be_ix_armed_at);
    if (be_ix_armed_at < 0) begin cov_fail++; $display("[ARM] indexedLSNumOfUopTable 从未 arm"); end
    if (!(be_i2f_s0_io_out_data[0] && be_i2f_s1_io_out_data[0])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[0] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[1] && be_i2f_s1_io_out_data[1])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[1] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[2] && be_i2f_s1_io_out_data[2])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[2] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[3] && be_i2f_s1_io_out_data[3])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[3] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[4] && be_i2f_s1_io_out_data[4])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[4] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[5] && be_i2f_s1_io_out_data[5])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[5] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[6] && be_i2f_s1_io_out_data[6])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[6] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[7] && be_i2f_s1_io_out_data[7])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[7] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[8] && be_i2f_s1_io_out_data[8])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[8] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[9] && be_i2f_s1_io_out_data[9])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[9] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[10] && be_i2f_s1_io_out_data[10])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[10] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[11] && be_i2f_s1_io_out_data[11])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[11] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[12] && be_i2f_s1_io_out_data[12])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[12] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[13] && be_i2f_s1_io_out_data[13])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[13] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[14] && be_i2f_s1_io_out_data[14])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[14] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[15] && be_i2f_s1_io_out_data[15])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[15] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[16] && be_i2f_s1_io_out_data[16])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[16] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[17] && be_i2f_s1_io_out_data[17])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[17] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[18] && be_i2f_s1_io_out_data[18])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[18] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[19] && be_i2f_s1_io_out_data[19])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[19] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[20] && be_i2f_s1_io_out_data[20])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[20] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[21] && be_i2f_s1_io_out_data[21])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[21] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[22] && be_i2f_s1_io_out_data[22])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[22] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[23] && be_i2f_s1_io_out_data[23])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[23] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[24] && be_i2f_s1_io_out_data[24])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[24] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[25] && be_i2f_s1_io_out_data[25])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[25] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[26] && be_i2f_s1_io_out_data[26])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[26] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[27] && be_i2f_s1_io_out_data[27])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[27] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[28] && be_i2f_s1_io_out_data[28])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[28] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[29] && be_i2f_s1_io_out_data[29])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[29] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[30] && be_i2f_s1_io_out_data[30])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[30] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[31] && be_i2f_s1_io_out_data[31])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[31] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[32] && be_i2f_s1_io_out_data[32])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[32] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[33] && be_i2f_s1_io_out_data[33])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[33] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[34] && be_i2f_s1_io_out_data[34])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[34] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[35] && be_i2f_s1_io_out_data[35])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[35] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[36] && be_i2f_s1_io_out_data[36])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[36] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[37] && be_i2f_s1_io_out_data[37])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[37] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[38] && be_i2f_s1_io_out_data[38])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[38] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[39] && be_i2f_s1_io_out_data[39])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[39] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[40] && be_i2f_s1_io_out_data[40])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[40] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[41] && be_i2f_s1_io_out_data[41])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[41] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[42] && be_i2f_s1_io_out_data[42])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[42] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[43] && be_i2f_s1_io_out_data[43])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[43] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[44] && be_i2f_s1_io_out_data[44])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[44] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[45] && be_i2f_s1_io_out_data[45])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[45] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[46] && be_i2f_s1_io_out_data[46])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[46] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[47] && be_i2f_s1_io_out_data[47])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[47] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[48] && be_i2f_s1_io_out_data[48])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[48] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[49] && be_i2f_s1_io_out_data[49])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[49] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[50] && be_i2f_s1_io_out_data[50])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[50] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[51] && be_i2f_s1_io_out_data[51])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[51] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[52] && be_i2f_s1_io_out_data[52])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[52] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[53] && be_i2f_s1_io_out_data[53])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[53] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[54] && be_i2f_s1_io_out_data[54])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[54] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[55] && be_i2f_s1_io_out_data[55])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[55] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[56] && be_i2f_s1_io_out_data[56])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[56] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[57] && be_i2f_s1_io_out_data[57])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[57] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[58] && be_i2f_s1_io_out_data[58])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[58] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[59] && be_i2f_s1_io_out_data[59])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[59] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[60] && be_i2f_s1_io_out_data[60])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[60] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[61] && be_i2f_s1_io_out_data[61])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[61] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[62] && be_i2f_s1_io_out_data[62])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[62] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_data[63] && be_i2f_s1_io_out_data[63])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_data[63] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_fflags[0] && be_i2f_s1_io_out_fflags[0])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_fflags[0] 未见过 0 和 1"); end
    if (!(be_i2f_s0_io_out_fflags[2] && be_i2f_s1_io_out_fflags[2])) begin cov_fail++; $display("[COV] IntToFPDataModule.io_out_fflags[2] 未见过 0 和 1"); end
    $display("[ARM] IntToFPDataModule armed_at=%0d", be_i2f_armed_at);
    if (be_i2f_armed_at < 0) begin cov_fail++; $display("[ARM] IntToFPDataModule 从未 arm"); end
    $display("[COV] IntToFPDataModule.tag0 = %0d", be_i2f_cov_tag0);
    if (be_i2f_cov_tag0 < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.tag0 < 500"); end
    $display("[COV] IntToFPDataModule.tag1 = %0d", be_i2f_cov_tag1);
    if (be_i2f_cov_tag1 < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.tag1 < 500"); end
    $display("[COV] IntToFPDataModule.tag2 = %0d", be_i2f_cov_tag2);
    if (be_i2f_cov_tag2 < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.tag2 < 500"); end
    $display("[COV] IntToFPDataModule.tag3 = %0d", be_i2f_cov_tag3);
    if (be_i2f_cov_tag3 < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.tag3 < 500"); end
    $display("[COV] IntToFPDataModule.nx = %0d", be_i2f_cov_nx);
    if (be_i2f_cov_nx < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.nx < 500"); end
    $display("[COV] IntToFPDataModule.fmv = %0d", be_i2f_cov_fmv);
    if (be_i2f_cov_fmv < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.fmv < 500"); end
    $display("[COV] IntToFPDataModule.dyn_rm = %0d", be_i2f_cov_dyn_rm);
    if (be_i2f_cov_dyn_rm < 500) begin cov_fail++; $display("[COV] IntToFPDataModule.dyn_rm < 500"); end
    if (!(be_alu_s0_io_result[0] && be_alu_s1_io_result[0])) begin cov_fail++; $display("[COV] AluDataModule.io_result[0] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[1] && be_alu_s1_io_result[1])) begin cov_fail++; $display("[COV] AluDataModule.io_result[1] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[2] && be_alu_s1_io_result[2])) begin cov_fail++; $display("[COV] AluDataModule.io_result[2] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[3] && be_alu_s1_io_result[3])) begin cov_fail++; $display("[COV] AluDataModule.io_result[3] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[4] && be_alu_s1_io_result[4])) begin cov_fail++; $display("[COV] AluDataModule.io_result[4] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[5] && be_alu_s1_io_result[5])) begin cov_fail++; $display("[COV] AluDataModule.io_result[5] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[6] && be_alu_s1_io_result[6])) begin cov_fail++; $display("[COV] AluDataModule.io_result[6] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[7] && be_alu_s1_io_result[7])) begin cov_fail++; $display("[COV] AluDataModule.io_result[7] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[8] && be_alu_s1_io_result[8])) begin cov_fail++; $display("[COV] AluDataModule.io_result[8] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[9] && be_alu_s1_io_result[9])) begin cov_fail++; $display("[COV] AluDataModule.io_result[9] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[10] && be_alu_s1_io_result[10])) begin cov_fail++; $display("[COV] AluDataModule.io_result[10] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[11] && be_alu_s1_io_result[11])) begin cov_fail++; $display("[COV] AluDataModule.io_result[11] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[12] && be_alu_s1_io_result[12])) begin cov_fail++; $display("[COV] AluDataModule.io_result[12] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[13] && be_alu_s1_io_result[13])) begin cov_fail++; $display("[COV] AluDataModule.io_result[13] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[14] && be_alu_s1_io_result[14])) begin cov_fail++; $display("[COV] AluDataModule.io_result[14] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[15] && be_alu_s1_io_result[15])) begin cov_fail++; $display("[COV] AluDataModule.io_result[15] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[16] && be_alu_s1_io_result[16])) begin cov_fail++; $display("[COV] AluDataModule.io_result[16] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[17] && be_alu_s1_io_result[17])) begin cov_fail++; $display("[COV] AluDataModule.io_result[17] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[18] && be_alu_s1_io_result[18])) begin cov_fail++; $display("[COV] AluDataModule.io_result[18] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[19] && be_alu_s1_io_result[19])) begin cov_fail++; $display("[COV] AluDataModule.io_result[19] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[20] && be_alu_s1_io_result[20])) begin cov_fail++; $display("[COV] AluDataModule.io_result[20] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[21] && be_alu_s1_io_result[21])) begin cov_fail++; $display("[COV] AluDataModule.io_result[21] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[22] && be_alu_s1_io_result[22])) begin cov_fail++; $display("[COV] AluDataModule.io_result[22] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[23] && be_alu_s1_io_result[23])) begin cov_fail++; $display("[COV] AluDataModule.io_result[23] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[24] && be_alu_s1_io_result[24])) begin cov_fail++; $display("[COV] AluDataModule.io_result[24] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[25] && be_alu_s1_io_result[25])) begin cov_fail++; $display("[COV] AluDataModule.io_result[25] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[26] && be_alu_s1_io_result[26])) begin cov_fail++; $display("[COV] AluDataModule.io_result[26] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[27] && be_alu_s1_io_result[27])) begin cov_fail++; $display("[COV] AluDataModule.io_result[27] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[28] && be_alu_s1_io_result[28])) begin cov_fail++; $display("[COV] AluDataModule.io_result[28] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[29] && be_alu_s1_io_result[29])) begin cov_fail++; $display("[COV] AluDataModule.io_result[29] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[30] && be_alu_s1_io_result[30])) begin cov_fail++; $display("[COV] AluDataModule.io_result[30] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[31] && be_alu_s1_io_result[31])) begin cov_fail++; $display("[COV] AluDataModule.io_result[31] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[32] && be_alu_s1_io_result[32])) begin cov_fail++; $display("[COV] AluDataModule.io_result[32] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[33] && be_alu_s1_io_result[33])) begin cov_fail++; $display("[COV] AluDataModule.io_result[33] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[34] && be_alu_s1_io_result[34])) begin cov_fail++; $display("[COV] AluDataModule.io_result[34] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[35] && be_alu_s1_io_result[35])) begin cov_fail++; $display("[COV] AluDataModule.io_result[35] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[36] && be_alu_s1_io_result[36])) begin cov_fail++; $display("[COV] AluDataModule.io_result[36] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[37] && be_alu_s1_io_result[37])) begin cov_fail++; $display("[COV] AluDataModule.io_result[37] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[38] && be_alu_s1_io_result[38])) begin cov_fail++; $display("[COV] AluDataModule.io_result[38] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[39] && be_alu_s1_io_result[39])) begin cov_fail++; $display("[COV] AluDataModule.io_result[39] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[40] && be_alu_s1_io_result[40])) begin cov_fail++; $display("[COV] AluDataModule.io_result[40] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[41] && be_alu_s1_io_result[41])) begin cov_fail++; $display("[COV] AluDataModule.io_result[41] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[42] && be_alu_s1_io_result[42])) begin cov_fail++; $display("[COV] AluDataModule.io_result[42] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[43] && be_alu_s1_io_result[43])) begin cov_fail++; $display("[COV] AluDataModule.io_result[43] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[44] && be_alu_s1_io_result[44])) begin cov_fail++; $display("[COV] AluDataModule.io_result[44] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[45] && be_alu_s1_io_result[45])) begin cov_fail++; $display("[COV] AluDataModule.io_result[45] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[46] && be_alu_s1_io_result[46])) begin cov_fail++; $display("[COV] AluDataModule.io_result[46] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[47] && be_alu_s1_io_result[47])) begin cov_fail++; $display("[COV] AluDataModule.io_result[47] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[48] && be_alu_s1_io_result[48])) begin cov_fail++; $display("[COV] AluDataModule.io_result[48] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[49] && be_alu_s1_io_result[49])) begin cov_fail++; $display("[COV] AluDataModule.io_result[49] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[50] && be_alu_s1_io_result[50])) begin cov_fail++; $display("[COV] AluDataModule.io_result[50] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[51] && be_alu_s1_io_result[51])) begin cov_fail++; $display("[COV] AluDataModule.io_result[51] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[52] && be_alu_s1_io_result[52])) begin cov_fail++; $display("[COV] AluDataModule.io_result[52] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[53] && be_alu_s1_io_result[53])) begin cov_fail++; $display("[COV] AluDataModule.io_result[53] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[54] && be_alu_s1_io_result[54])) begin cov_fail++; $display("[COV] AluDataModule.io_result[54] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[55] && be_alu_s1_io_result[55])) begin cov_fail++; $display("[COV] AluDataModule.io_result[55] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[56] && be_alu_s1_io_result[56])) begin cov_fail++; $display("[COV] AluDataModule.io_result[56] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[57] && be_alu_s1_io_result[57])) begin cov_fail++; $display("[COV] AluDataModule.io_result[57] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[58] && be_alu_s1_io_result[58])) begin cov_fail++; $display("[COV] AluDataModule.io_result[58] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[59] && be_alu_s1_io_result[59])) begin cov_fail++; $display("[COV] AluDataModule.io_result[59] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[60] && be_alu_s1_io_result[60])) begin cov_fail++; $display("[COV] AluDataModule.io_result[60] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[61] && be_alu_s1_io_result[61])) begin cov_fail++; $display("[COV] AluDataModule.io_result[61] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[62] && be_alu_s1_io_result[62])) begin cov_fail++; $display("[COV] AluDataModule.io_result[62] 未见过 0 和 1"); end
    if (!(be_alu_s0_io_result[63] && be_alu_s1_io_result[63])) begin cov_fail++; $display("[COV] AluDataModule.io_result[63] 未见过 0 和 1"); end
    $display("[ARM] AluDataModule armed_at=%0d", be_alu_armed_at);
    if (be_alu_armed_at < 0) begin cov_fail++; $display("[ARM] AluDataModule 从未 arm"); end
    $display("[COV] AluDataModule.ch0 = %0d", be_alu_cov_ch0);
    if (be_alu_cov_ch0 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch0 < 1000"); end
    $display("[COV] AluDataModule.ch1 = %0d", be_alu_cov_ch1);
    if (be_alu_cov_ch1 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch1 < 1000"); end
    $display("[COV] AluDataModule.ch2 = %0d", be_alu_cov_ch2);
    if (be_alu_cov_ch2 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch2 < 1000"); end
    $display("[COV] AluDataModule.ch3 = %0d", be_alu_cov_ch3);
    if (be_alu_cov_ch3 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch3 < 1000"); end
    $display("[COV] AluDataModule.ch4 = %0d", be_alu_cov_ch4);
    if (be_alu_cov_ch4 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch4 < 1000"); end
    $display("[COV] AluDataModule.ch5 = %0d", be_alu_cov_ch5);
    if (be_alu_cov_ch5 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch5 < 1000"); end
    $display("[COV] AluDataModule.ch6 = %0d", be_alu_cov_ch6);
    if (be_alu_cov_ch6 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch6 < 1000"); end
    $display("[COV] AluDataModule.ch7 = %0d", be_alu_cov_ch7);
    if (be_alu_cov_ch7 < 1000) begin cov_fail++; $display("[COV] AluDataModule.ch7 < 1000"); end
    $display("[COV] AluDataModule.eq_src = %0d", be_alu_cov_eq_src);
    if (be_alu_cov_eq_src < 1000) begin cov_fail++; $display("[COV] AluDataModule.eq_src < 1000"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
