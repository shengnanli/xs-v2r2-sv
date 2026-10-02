// 自动生成：verif/ut/VIMac64b/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// VIMac64b 双例化逐拍比对：golden VIMac64b vs 重写 VIMac64b_xs，io_vd / io_vxsat 逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= VIMac64b =================
  int unsigned vm_mode = 0;
  int unsigned vm_op;      // 本拍抽到的操作（OPS 下标；16 = 控制位全随机）
  logic [1:0]  vm_sew;
  function automatic logic [63:0] vm_rnd_data(input logic [1:0] sew);
    logic [63:0] d;
    int unsigned w;
    d = {$urandom, $urandom};
    w = 8 << sew;
    if ($urandom_range(0, 2) == 0) begin
      for (int e = 0; e < 64 / w; e++) begin
        logic [63:0] v;
        case ($urandom_range(0, 7))
          0:       v = 64'h0;
          1:       v = ~64'h0;
          2, 3:    v = 64'h1 << (w - 1);            // 最小负数
          4:       v = (64'h1 << (w - 1)) - 64'h1;  // 最大正数
          default: v = {$urandom, $urandom};
        endcase
        for (int b = 0; b < w; b++) d[e * w + b] = v[b];
      end
    end
    return d;
  endfunction
  // 每个元素 3/4 概率取最小负数：专门给 vsmul 打饱和（两个操作数同一元素都是最小负数才饱和）
  function automatic logic [63:0] vm_min_heavy(input logic [1:0] sew);
    logic [63:0] d;
    int unsigned w;
    d = {$urandom, $urandom};
    w = 8 << sew;
    for (int e = 0; e < 64 / w; e++) begin
      if ($urandom_range(0, 3) != 0) begin
        for (int b = 0; b < w; b++) d[e * w + b] = (b == w - 1);
      end
    end
    return d;
  endfunction
  logic vm_reset;
  logic vm_io_fire;
  logic [5:0] vm_io_info_uopIdx;
  logic [1:0] vm_io_info_vxrm;
  logic [3:0] vm_io_srcType_0;
  logic [3:0] vm_io_srcType_1;
  logic [63:0] vm_io_vs1;
  logic [63:0] vm_io_vs2;
  logic [63:0] vm_io_oldVd;
  logic vm_io_highHalf;
  logic vm_io_isMacc;
  logic vm_io_isSub;
  logic vm_io_widen;
  logic vm_io_isFixP;
  wire  [63:0] vm_g_io_vd, vm_i_io_vd;
  logic [63:0] vm_s0_io_vd = '0, vm_s1_io_vd = '0;
  wire  [7:0] vm_g_io_vxsat, vm_i_io_vxsat;
  logic [7:0] vm_s0_io_vxsat = '0, vm_s1_io_vxsat = '0;
  int vm_cov_vmul_e8 = 0;
  int vm_cov_vmul_e16 = 0;
  int vm_cov_vmul_e32 = 0;
  int vm_cov_vmul_e64 = 0;
  int vm_cov_vwmul_e8 = 0;
  int vm_cov_vwmul_e16 = 0;
  int vm_cov_vwmul_e32 = 0;
  int vm_cov_vwmul_e64 = 0;
  int vm_cov_vwmulu_e8 = 0;
  int vm_cov_vwmulu_e16 = 0;
  int vm_cov_vwmulu_e32 = 0;
  int vm_cov_vwmulu_e64 = 0;
  int vm_cov_vwmulsu_e8 = 0;
  int vm_cov_vwmulsu_e16 = 0;
  int vm_cov_vwmulsu_e32 = 0;
  int vm_cov_vwmulsu_e64 = 0;
  int vm_cov_vmulh_e8 = 0;
  int vm_cov_vmulh_e16 = 0;
  int vm_cov_vmulh_e32 = 0;
  int vm_cov_vmulh_e64 = 0;
  int vm_cov_vmulhu_e8 = 0;
  int vm_cov_vmulhu_e16 = 0;
  int vm_cov_vmulhu_e32 = 0;
  int vm_cov_vmulhu_e64 = 0;
  int vm_cov_vmulhsu_e8 = 0;
  int vm_cov_vmulhsu_e16 = 0;
  int vm_cov_vmulhsu_e32 = 0;
  int vm_cov_vmulhsu_e64 = 0;
  int vm_cov_vmacc_e8 = 0;
  int vm_cov_vmacc_e16 = 0;
  int vm_cov_vmacc_e32 = 0;
  int vm_cov_vmacc_e64 = 0;
  int vm_cov_vwmaccu_e8 = 0;
  int vm_cov_vwmaccu_e16 = 0;
  int vm_cov_vwmaccu_e32 = 0;
  int vm_cov_vwmaccu_e64 = 0;
  int vm_cov_vwmacc_e8 = 0;
  int vm_cov_vwmacc_e16 = 0;
  int vm_cov_vwmacc_e32 = 0;
  int vm_cov_vwmacc_e64 = 0;
  int vm_cov_vwmaccsu_e8 = 0;
  int vm_cov_vwmaccsu_e16 = 0;
  int vm_cov_vwmaccsu_e32 = 0;
  int vm_cov_vwmaccsu_e64 = 0;
  int vm_cov_vwmaccus_e8 = 0;
  int vm_cov_vwmaccus_e16 = 0;
  int vm_cov_vwmaccus_e32 = 0;
  int vm_cov_vwmaccus_e64 = 0;
  int vm_cov_vnmsac_e8 = 0;
  int vm_cov_vnmsac_e16 = 0;
  int vm_cov_vnmsac_e32 = 0;
  int vm_cov_vnmsac_e64 = 0;
  int vm_cov_vmadd_e8 = 0;
  int vm_cov_vmadd_e16 = 0;
  int vm_cov_vmadd_e32 = 0;
  int vm_cov_vmadd_e64 = 0;
  int vm_cov_vnmsub_e8 = 0;
  int vm_cov_vnmsub_e16 = 0;
  int vm_cov_vnmsub_e32 = 0;
  int vm_cov_vnmsub_e64 = 0;
  int vm_cov_vsmul_e8 = 0;
  int vm_cov_vsmul_e16 = 0;
  int vm_cov_vsmul_e32 = 0;
  int vm_cov_vsmul_e64 = 0;
  int vm_cov_randctl_e8 = 0;
  int vm_cov_randctl_e16 = 0;
  int vm_cov_randctl_e32 = 0;
  int vm_cov_randctl_e64 = 0;
  int vm_cov_sat_e8 = 0;
  int vm_cov_vsmul_e8_vxrm0 = 0;
  int vm_cov_vsmul_e8_vxrm1 = 0;
  int vm_cov_vsmul_e8_vxrm2 = 0;
  int vm_cov_vsmul_e8_vxrm3 = 0;
  int vm_cov_sub_e8 = 0;
  int vm_cov_high_e8 = 0;
  int vm_cov_sat_e16 = 0;
  int vm_cov_vsmul_e16_vxrm0 = 0;
  int vm_cov_vsmul_e16_vxrm1 = 0;
  int vm_cov_vsmul_e16_vxrm2 = 0;
  int vm_cov_vsmul_e16_vxrm3 = 0;
  int vm_cov_sub_e16 = 0;
  int vm_cov_high_e16 = 0;
  int vm_cov_sat_e32 = 0;
  int vm_cov_vsmul_e32_vxrm0 = 0;
  int vm_cov_vsmul_e32_vxrm1 = 0;
  int vm_cov_vsmul_e32_vxrm2 = 0;
  int vm_cov_vsmul_e32_vxrm3 = 0;
  int vm_cov_sub_e32 = 0;
  int vm_cov_high_e32 = 0;
  int vm_cov_sat_e64 = 0;
  int vm_cov_vsmul_e64_vxrm0 = 0;
  int vm_cov_vsmul_e64_vxrm1 = 0;
  int vm_cov_vsmul_e64_vxrm2 = 0;
  int vm_cov_vsmul_e64_vxrm3 = 0;
  int vm_cov_sub_e64 = 0;
  int vm_cov_high_e64 = 0;
  int vm_cov_widen_uop_even = 0;
  int vm_cov_widen_uop_odd = 0;
  int vm_cov_fire_gap = 0;
  logic [0:0] vm_armed = '0;
  int vm_armed_at = -1;
  VIMac64b vm_u_gold (
    .clock(clk),
    .reset(vm_reset),
    .io_fire(vm_io_fire),
    .io_info_uopIdx(vm_io_info_uopIdx),
    .io_info_vxrm(vm_io_info_vxrm),
    .io_srcType_0(vm_io_srcType_0),
    .io_srcType_1(vm_io_srcType_1),
    .io_vs1(vm_io_vs1),
    .io_vs2(vm_io_vs2),
    .io_oldVd(vm_io_oldVd),
    .io_highHalf(vm_io_highHalf),
    .io_isMacc(vm_io_isMacc),
    .io_isSub(vm_io_isSub),
    .io_widen(vm_io_widen),
    .io_isFixP(vm_io_isFixP),
    .io_vd(vm_g_io_vd),
    .io_vxsat(vm_g_io_vxsat)
  );
  VIMac64b_xs vm_u_impl (
    .clock(clk),
    .reset(vm_reset),
    .io_fire(vm_io_fire),
    .io_info_uopIdx(vm_io_info_uopIdx),
    .io_info_vxrm(vm_io_info_vxrm),
    .io_srcType_0(vm_io_srcType_0),
    .io_srcType_1(vm_io_srcType_1),
    .io_vs1(vm_io_vs1),
    .io_vs2(vm_io_vs2),
    .io_oldVd(vm_io_oldVd),
    .io_highHalf(vm_io_highHalf),
    .io_isMacc(vm_io_isMacc),
    .io_isSub(vm_io_isSub),
    .io_widen(vm_io_widen),
    .io_isFixP(vm_io_isFixP),
    .io_vd(vm_i_io_vd),
    .io_vxsat(vm_i_io_vxsat)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 1000 == 0) vm_mode = $urandom_range(0, 15);
      vm_io_fire = 1'($urandom);
      vm_io_info_uopIdx = 6'($urandom);
      vm_io_info_vxrm = 2'($urandom);
      vm_io_srcType_0 = 4'($urandom);
      vm_io_srcType_1 = 4'($urandom);
      vm_io_vs1 = 64'({$urandom, $urandom});
      vm_io_vs2 = 64'({$urandom, $urandom});
      vm_io_oldVd = 64'({$urandom, $urandom});
      vm_io_highHalf = 1'($urandom);
      vm_io_isMacc = 1'($urandom);
      vm_io_isSub = 1'($urandom);
      vm_io_widen = 1'($urandom);
      vm_io_isFixP = 1'($urandom);
      vm_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_vm
        vm_sew = 2'($urandom);
        vm_op  = (vm_mode == 15) ? 16 : $urandom_range(0, 15);
        vm_io_vs1   = vm_rnd_data(vm_sew);
        vm_io_vs2   = vm_rnd_data(vm_sew);
        vm_io_oldVd = vm_rnd_data(vm_sew);
        vm_io_fire  = (vm_mode < 4) ? 1'b1 : 1'($urandom);
        case (vm_op)
          0: begin  // vmul
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          1: begin  // vwmul
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          2: begin  // vwmulu
            vm_io_srcType_0 = {1'b0, 1'b0, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b0, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          3: begin  // vwmulsu
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b0, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          4: begin  // vmulh
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b1; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          5: begin  // vmulhu
            vm_io_srcType_0 = {1'b0, 1'b0, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b0, vm_sew};
            vm_io_highHalf = 1'b1; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          6: begin  // vmulhsu
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b0, vm_sew};
            vm_io_highHalf = 1'b1; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          7: begin  // vmacc
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          8: begin  // vwmaccu
            vm_io_srcType_0 = {1'b0, 1'b0, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b0, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          9: begin  // vwmacc
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          10: begin  // vwmaccsu
            vm_io_srcType_0 = {1'b0, 1'b0, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          11: begin  // vwmaccus
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b0, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b0; vm_io_widen = 1'b1; vm_io_isFixP = 1'b0;
          end
          12: begin  // vnmsac
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b1; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          13: begin  // vmadd
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          14: begin  // vnmsub
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b1; vm_io_isSub = 1'b1; vm_io_widen = 1'b0; vm_io_isFixP = 1'b0;
          end
          15: begin  // vsmul
            vm_io_srcType_0 = {1'b0, 1'b1, vm_sew}; vm_io_srcType_1 = {1'b0, 1'b1, vm_sew};
            vm_io_highHalf = 1'b0; vm_io_isMacc = 1'b0; vm_io_isSub = 1'b0; vm_io_widen = 1'b0; vm_io_isFixP = 1'b1;
          end
          default: vm_sew = vm_io_srcType_0[1:0];  // 全随机档：sew 以实际灌进去的为准
        endcase
        if (vm_io_isFixP && $urandom_range(0, 1) == 0) begin  // vsmul 饱和偏置
          vm_io_vs1 = vm_min_heavy(vm_sew);
          vm_io_vs2 = vm_min_heavy(vm_sew);
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&vm_armed)) begin
        checks++;
        if (vm_g_io_vd !== vm_i_io_vd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VIMac64b.io_vd g=%h i=%h", cyc, vm_g_io_vd, vm_i_io_vd);
        end
        vm_s1_io_vd |= vm_g_io_vd;
        vm_s0_io_vd |= ~vm_g_io_vd;
        checks++;
        if (vm_g_io_vxsat !== vm_i_io_vxsat) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VIMac64b.io_vxsat g=%h i=%h", cyc, vm_g_io_vxsat, vm_i_io_vxsat);
        end
        vm_s1_io_vxsat |= vm_g_io_vxsat;
        vm_s0_io_vxsat |= ~vm_g_io_vxsat;
        if (vm_io_fire && vm_op == 0 && vm_sew == 2'd0) vm_cov_vmul_e8++;
        if (vm_io_fire && vm_op == 0 && vm_sew == 2'd1) vm_cov_vmul_e16++;
        if (vm_io_fire && vm_op == 0 && vm_sew == 2'd2) vm_cov_vmul_e32++;
        if (vm_io_fire && vm_op == 0 && vm_sew == 2'd3) vm_cov_vmul_e64++;
        if (vm_io_fire && vm_op == 1 && vm_sew == 2'd0) vm_cov_vwmul_e8++;
        if (vm_io_fire && vm_op == 1 && vm_sew == 2'd1) vm_cov_vwmul_e16++;
        if (vm_io_fire && vm_op == 1 && vm_sew == 2'd2) vm_cov_vwmul_e32++;
        if (vm_io_fire && vm_op == 1 && vm_sew == 2'd3) vm_cov_vwmul_e64++;
        if (vm_io_fire && vm_op == 2 && vm_sew == 2'd0) vm_cov_vwmulu_e8++;
        if (vm_io_fire && vm_op == 2 && vm_sew == 2'd1) vm_cov_vwmulu_e16++;
        if (vm_io_fire && vm_op == 2 && vm_sew == 2'd2) vm_cov_vwmulu_e32++;
        if (vm_io_fire && vm_op == 2 && vm_sew == 2'd3) vm_cov_vwmulu_e64++;
        if (vm_io_fire && vm_op == 3 && vm_sew == 2'd0) vm_cov_vwmulsu_e8++;
        if (vm_io_fire && vm_op == 3 && vm_sew == 2'd1) vm_cov_vwmulsu_e16++;
        if (vm_io_fire && vm_op == 3 && vm_sew == 2'd2) vm_cov_vwmulsu_e32++;
        if (vm_io_fire && vm_op == 3 && vm_sew == 2'd3) vm_cov_vwmulsu_e64++;
        if (vm_io_fire && vm_op == 4 && vm_sew == 2'd0) vm_cov_vmulh_e8++;
        if (vm_io_fire && vm_op == 4 && vm_sew == 2'd1) vm_cov_vmulh_e16++;
        if (vm_io_fire && vm_op == 4 && vm_sew == 2'd2) vm_cov_vmulh_e32++;
        if (vm_io_fire && vm_op == 4 && vm_sew == 2'd3) vm_cov_vmulh_e64++;
        if (vm_io_fire && vm_op == 5 && vm_sew == 2'd0) vm_cov_vmulhu_e8++;
        if (vm_io_fire && vm_op == 5 && vm_sew == 2'd1) vm_cov_vmulhu_e16++;
        if (vm_io_fire && vm_op == 5 && vm_sew == 2'd2) vm_cov_vmulhu_e32++;
        if (vm_io_fire && vm_op == 5 && vm_sew == 2'd3) vm_cov_vmulhu_e64++;
        if (vm_io_fire && vm_op == 6 && vm_sew == 2'd0) vm_cov_vmulhsu_e8++;
        if (vm_io_fire && vm_op == 6 && vm_sew == 2'd1) vm_cov_vmulhsu_e16++;
        if (vm_io_fire && vm_op == 6 && vm_sew == 2'd2) vm_cov_vmulhsu_e32++;
        if (vm_io_fire && vm_op == 6 && vm_sew == 2'd3) vm_cov_vmulhsu_e64++;
        if (vm_io_fire && vm_op == 7 && vm_sew == 2'd0) vm_cov_vmacc_e8++;
        if (vm_io_fire && vm_op == 7 && vm_sew == 2'd1) vm_cov_vmacc_e16++;
        if (vm_io_fire && vm_op == 7 && vm_sew == 2'd2) vm_cov_vmacc_e32++;
        if (vm_io_fire && vm_op == 7 && vm_sew == 2'd3) vm_cov_vmacc_e64++;
        if (vm_io_fire && vm_op == 8 && vm_sew == 2'd0) vm_cov_vwmaccu_e8++;
        if (vm_io_fire && vm_op == 8 && vm_sew == 2'd1) vm_cov_vwmaccu_e16++;
        if (vm_io_fire && vm_op == 8 && vm_sew == 2'd2) vm_cov_vwmaccu_e32++;
        if (vm_io_fire && vm_op == 8 && vm_sew == 2'd3) vm_cov_vwmaccu_e64++;
        if (vm_io_fire && vm_op == 9 && vm_sew == 2'd0) vm_cov_vwmacc_e8++;
        if (vm_io_fire && vm_op == 9 && vm_sew == 2'd1) vm_cov_vwmacc_e16++;
        if (vm_io_fire && vm_op == 9 && vm_sew == 2'd2) vm_cov_vwmacc_e32++;
        if (vm_io_fire && vm_op == 9 && vm_sew == 2'd3) vm_cov_vwmacc_e64++;
        if (vm_io_fire && vm_op == 10 && vm_sew == 2'd0) vm_cov_vwmaccsu_e8++;
        if (vm_io_fire && vm_op == 10 && vm_sew == 2'd1) vm_cov_vwmaccsu_e16++;
        if (vm_io_fire && vm_op == 10 && vm_sew == 2'd2) vm_cov_vwmaccsu_e32++;
        if (vm_io_fire && vm_op == 10 && vm_sew == 2'd3) vm_cov_vwmaccsu_e64++;
        if (vm_io_fire && vm_op == 11 && vm_sew == 2'd0) vm_cov_vwmaccus_e8++;
        if (vm_io_fire && vm_op == 11 && vm_sew == 2'd1) vm_cov_vwmaccus_e16++;
        if (vm_io_fire && vm_op == 11 && vm_sew == 2'd2) vm_cov_vwmaccus_e32++;
        if (vm_io_fire && vm_op == 11 && vm_sew == 2'd3) vm_cov_vwmaccus_e64++;
        if (vm_io_fire && vm_op == 12 && vm_sew == 2'd0) vm_cov_vnmsac_e8++;
        if (vm_io_fire && vm_op == 12 && vm_sew == 2'd1) vm_cov_vnmsac_e16++;
        if (vm_io_fire && vm_op == 12 && vm_sew == 2'd2) vm_cov_vnmsac_e32++;
        if (vm_io_fire && vm_op == 12 && vm_sew == 2'd3) vm_cov_vnmsac_e64++;
        if (vm_io_fire && vm_op == 13 && vm_sew == 2'd0) vm_cov_vmadd_e8++;
        if (vm_io_fire && vm_op == 13 && vm_sew == 2'd1) vm_cov_vmadd_e16++;
        if (vm_io_fire && vm_op == 13 && vm_sew == 2'd2) vm_cov_vmadd_e32++;
        if (vm_io_fire && vm_op == 13 && vm_sew == 2'd3) vm_cov_vmadd_e64++;
        if (vm_io_fire && vm_op == 14 && vm_sew == 2'd0) vm_cov_vnmsub_e8++;
        if (vm_io_fire && vm_op == 14 && vm_sew == 2'd1) vm_cov_vnmsub_e16++;
        if (vm_io_fire && vm_op == 14 && vm_sew == 2'd2) vm_cov_vnmsub_e32++;
        if (vm_io_fire && vm_op == 14 && vm_sew == 2'd3) vm_cov_vnmsub_e64++;
        if (vm_io_fire && vm_op == 15 && vm_sew == 2'd0) vm_cov_vsmul_e8++;
        if (vm_io_fire && vm_op == 15 && vm_sew == 2'd1) vm_cov_vsmul_e16++;
        if (vm_io_fire && vm_op == 15 && vm_sew == 2'd2) vm_cov_vsmul_e32++;
        if (vm_io_fire && vm_op == 15 && vm_sew == 2'd3) vm_cov_vsmul_e64++;
        if (vm_io_fire && vm_op == 16 && vm_sew == 2'd0) vm_cov_randctl_e8++;
        if (vm_io_fire && vm_op == 16 && vm_sew == 2'd1) vm_cov_randctl_e16++;
        if (vm_io_fire && vm_op == 16 && vm_sew == 2'd2) vm_cov_randctl_e32++;
        if (vm_io_fire && vm_op == 16 && vm_sew == 2'd3) vm_cov_randctl_e64++;
        if (vm_u_gold.sewS2_oneHot[0] && (|vm_g_io_vxsat)) vm_cov_sat_e8++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[0] && vm_u_gold.vxrmS2 == 2'd0) vm_cov_vsmul_e8_vxrm0++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[0] && vm_u_gold.vxrmS2 == 2'd1) vm_cov_vsmul_e8_vxrm1++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[0] && vm_u_gold.vxrmS2 == 2'd2) vm_cov_vsmul_e8_vxrm2++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[0] && vm_u_gold.vxrmS2 == 2'd3) vm_cov_vsmul_e8_vxrm3++;
        if (vm_u_gold.isSubS2 && !vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[0]) vm_cov_sub_e8++;
        if (vm_u_gold.highHalfS2 && vm_u_gold.sewS2_oneHot[0]) vm_cov_high_e8++;
        if (vm_u_gold.sewS2_oneHot[1] && (|vm_g_io_vxsat)) vm_cov_sat_e16++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[1] && vm_u_gold.vxrmS2 == 2'd0) vm_cov_vsmul_e16_vxrm0++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[1] && vm_u_gold.vxrmS2 == 2'd1) vm_cov_vsmul_e16_vxrm1++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[1] && vm_u_gold.vxrmS2 == 2'd2) vm_cov_vsmul_e16_vxrm2++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[1] && vm_u_gold.vxrmS2 == 2'd3) vm_cov_vsmul_e16_vxrm3++;
        if (vm_u_gold.isSubS2 && !vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[1]) vm_cov_sub_e16++;
        if (vm_u_gold.highHalfS2 && vm_u_gold.sewS2_oneHot[1]) vm_cov_high_e16++;
        if (vm_u_gold.sewS2_oneHot[2] && (|vm_g_io_vxsat)) vm_cov_sat_e32++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[2] && vm_u_gold.vxrmS2 == 2'd0) vm_cov_vsmul_e32_vxrm0++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[2] && vm_u_gold.vxrmS2 == 2'd1) vm_cov_vsmul_e32_vxrm1++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[2] && vm_u_gold.vxrmS2 == 2'd2) vm_cov_vsmul_e32_vxrm2++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[2] && vm_u_gold.vxrmS2 == 2'd3) vm_cov_vsmul_e32_vxrm3++;
        if (vm_u_gold.isSubS2 && !vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[2]) vm_cov_sub_e32++;
        if (vm_u_gold.highHalfS2 && vm_u_gold.sewS2_oneHot[2]) vm_cov_high_e32++;
        if (vm_u_gold.sewS2_oneHot[3] && (|vm_g_io_vxsat)) vm_cov_sat_e64++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[3] && vm_u_gold.vxrmS2 == 2'd0) vm_cov_vsmul_e64_vxrm0++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[3] && vm_u_gold.vxrmS2 == 2'd1) vm_cov_vsmul_e64_vxrm1++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[3] && vm_u_gold.vxrmS2 == 2'd2) vm_cov_vsmul_e64_vxrm2++;
        if (vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[3] && vm_u_gold.vxrmS2 == 2'd3) vm_cov_vsmul_e64_vxrm3++;
        if (vm_u_gold.isSubS2 && !vm_u_gold.isFixPS2 && vm_u_gold.sewS2_oneHot[3]) vm_cov_sub_e64++;
        if (vm_u_gold.highHalfS2 && vm_u_gold.sewS2_oneHot[3]) vm_cov_high_e64++;
        if (vm_u_gold.widenS2 && !vm_u_gold.uopIdxS2[0]) vm_cov_widen_uop_even++;
        if (vm_u_gold.widenS2 && vm_u_gold.uopIdxS2[0]) vm_cov_widen_uop_odd++;
        if (!vm_io_fire) vm_cov_fire_gap++;
      end
      if (vm_u_gold.fireS1_last_r) vm_armed[0] = 1'b1;
      if (vm_armed_at < 0 && (&vm_armed)) vm_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(vm_s0_io_vd[0] && vm_s1_io_vd[0])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[0] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[1] && vm_s1_io_vd[1])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[1] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[2] && vm_s1_io_vd[2])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[2] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[3] && vm_s1_io_vd[3])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[3] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[4] && vm_s1_io_vd[4])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[4] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[5] && vm_s1_io_vd[5])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[5] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[6] && vm_s1_io_vd[6])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[6] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[7] && vm_s1_io_vd[7])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[7] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[8] && vm_s1_io_vd[8])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[8] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[9] && vm_s1_io_vd[9])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[9] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[10] && vm_s1_io_vd[10])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[10] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[11] && vm_s1_io_vd[11])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[11] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[12] && vm_s1_io_vd[12])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[12] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[13] && vm_s1_io_vd[13])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[13] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[14] && vm_s1_io_vd[14])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[14] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[15] && vm_s1_io_vd[15])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[15] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[16] && vm_s1_io_vd[16])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[16] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[17] && vm_s1_io_vd[17])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[17] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[18] && vm_s1_io_vd[18])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[18] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[19] && vm_s1_io_vd[19])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[19] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[20] && vm_s1_io_vd[20])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[20] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[21] && vm_s1_io_vd[21])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[21] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[22] && vm_s1_io_vd[22])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[22] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[23] && vm_s1_io_vd[23])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[23] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[24] && vm_s1_io_vd[24])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[24] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[25] && vm_s1_io_vd[25])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[25] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[26] && vm_s1_io_vd[26])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[26] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[27] && vm_s1_io_vd[27])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[27] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[28] && vm_s1_io_vd[28])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[28] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[29] && vm_s1_io_vd[29])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[29] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[30] && vm_s1_io_vd[30])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[30] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[31] && vm_s1_io_vd[31])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[31] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[32] && vm_s1_io_vd[32])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[32] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[33] && vm_s1_io_vd[33])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[33] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[34] && vm_s1_io_vd[34])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[34] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[35] && vm_s1_io_vd[35])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[35] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[36] && vm_s1_io_vd[36])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[36] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[37] && vm_s1_io_vd[37])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[37] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[38] && vm_s1_io_vd[38])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[38] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[39] && vm_s1_io_vd[39])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[39] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[40] && vm_s1_io_vd[40])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[40] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[41] && vm_s1_io_vd[41])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[41] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[42] && vm_s1_io_vd[42])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[42] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[43] && vm_s1_io_vd[43])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[43] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[44] && vm_s1_io_vd[44])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[44] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[45] && vm_s1_io_vd[45])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[45] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[46] && vm_s1_io_vd[46])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[46] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[47] && vm_s1_io_vd[47])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[47] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[48] && vm_s1_io_vd[48])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[48] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[49] && vm_s1_io_vd[49])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[49] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[50] && vm_s1_io_vd[50])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[50] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[51] && vm_s1_io_vd[51])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[51] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[52] && vm_s1_io_vd[52])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[52] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[53] && vm_s1_io_vd[53])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[53] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[54] && vm_s1_io_vd[54])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[54] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[55] && vm_s1_io_vd[55])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[55] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[56] && vm_s1_io_vd[56])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[56] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[57] && vm_s1_io_vd[57])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[57] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[58] && vm_s1_io_vd[58])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[58] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[59] && vm_s1_io_vd[59])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[59] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[60] && vm_s1_io_vd[60])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[60] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[61] && vm_s1_io_vd[61])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[61] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[62] && vm_s1_io_vd[62])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[62] 未见过 0 和 1"); end
    if (!(vm_s0_io_vd[63] && vm_s1_io_vd[63])) begin cov_fail++; $display("[COV] VIMac64b.io_vd[63] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[0] && vm_s1_io_vxsat[0])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[0] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[1] && vm_s1_io_vxsat[1])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[1] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[2] && vm_s1_io_vxsat[2])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[2] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[3] && vm_s1_io_vxsat[3])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[3] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[4] && vm_s1_io_vxsat[4])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[4] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[5] && vm_s1_io_vxsat[5])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[5] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[6] && vm_s1_io_vxsat[6])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[6] 未见过 0 和 1"); end
    if (!(vm_s0_io_vxsat[7] && vm_s1_io_vxsat[7])) begin cov_fail++; $display("[COV] VIMac64b.io_vxsat[7] 未见过 0 和 1"); end
    $display("[ARM] VIMac64b armed_at=%0d", vm_armed_at);
    if (vm_armed_at < 0) begin cov_fail++; $display("[ARM] VIMac64b 从未 arm"); end
    $display("[COV] VIMac64b.vmul_e8 = %0d", vm_cov_vmul_e8);
    if (vm_cov_vmul_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmul_e8 < 300"); end
    $display("[COV] VIMac64b.vmul_e16 = %0d", vm_cov_vmul_e16);
    if (vm_cov_vmul_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmul_e16 < 300"); end
    $display("[COV] VIMac64b.vmul_e32 = %0d", vm_cov_vmul_e32);
    if (vm_cov_vmul_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmul_e32 < 300"); end
    $display("[COV] VIMac64b.vmul_e64 = %0d", vm_cov_vmul_e64);
    if (vm_cov_vmul_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmul_e64 < 300"); end
    $display("[COV] VIMac64b.vwmul_e8 = %0d", vm_cov_vwmul_e8);
    if (vm_cov_vwmul_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmul_e8 < 300"); end
    $display("[COV] VIMac64b.vwmul_e16 = %0d", vm_cov_vwmul_e16);
    if (vm_cov_vwmul_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmul_e16 < 300"); end
    $display("[COV] VIMac64b.vwmul_e32 = %0d", vm_cov_vwmul_e32);
    if (vm_cov_vwmul_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmul_e32 < 300"); end
    $display("[COV] VIMac64b.vwmul_e64 = %0d", vm_cov_vwmul_e64);
    if (vm_cov_vwmul_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmul_e64 < 300"); end
    $display("[COV] VIMac64b.vwmulu_e8 = %0d", vm_cov_vwmulu_e8);
    if (vm_cov_vwmulu_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulu_e8 < 300"); end
    $display("[COV] VIMac64b.vwmulu_e16 = %0d", vm_cov_vwmulu_e16);
    if (vm_cov_vwmulu_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulu_e16 < 300"); end
    $display("[COV] VIMac64b.vwmulu_e32 = %0d", vm_cov_vwmulu_e32);
    if (vm_cov_vwmulu_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulu_e32 < 300"); end
    $display("[COV] VIMac64b.vwmulu_e64 = %0d", vm_cov_vwmulu_e64);
    if (vm_cov_vwmulu_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulu_e64 < 300"); end
    $display("[COV] VIMac64b.vwmulsu_e8 = %0d", vm_cov_vwmulsu_e8);
    if (vm_cov_vwmulsu_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulsu_e8 < 300"); end
    $display("[COV] VIMac64b.vwmulsu_e16 = %0d", vm_cov_vwmulsu_e16);
    if (vm_cov_vwmulsu_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulsu_e16 < 300"); end
    $display("[COV] VIMac64b.vwmulsu_e32 = %0d", vm_cov_vwmulsu_e32);
    if (vm_cov_vwmulsu_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulsu_e32 < 300"); end
    $display("[COV] VIMac64b.vwmulsu_e64 = %0d", vm_cov_vwmulsu_e64);
    if (vm_cov_vwmulsu_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmulsu_e64 < 300"); end
    $display("[COV] VIMac64b.vmulh_e8 = %0d", vm_cov_vmulh_e8);
    if (vm_cov_vmulh_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulh_e8 < 300"); end
    $display("[COV] VIMac64b.vmulh_e16 = %0d", vm_cov_vmulh_e16);
    if (vm_cov_vmulh_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulh_e16 < 300"); end
    $display("[COV] VIMac64b.vmulh_e32 = %0d", vm_cov_vmulh_e32);
    if (vm_cov_vmulh_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulh_e32 < 300"); end
    $display("[COV] VIMac64b.vmulh_e64 = %0d", vm_cov_vmulh_e64);
    if (vm_cov_vmulh_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulh_e64 < 300"); end
    $display("[COV] VIMac64b.vmulhu_e8 = %0d", vm_cov_vmulhu_e8);
    if (vm_cov_vmulhu_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhu_e8 < 300"); end
    $display("[COV] VIMac64b.vmulhu_e16 = %0d", vm_cov_vmulhu_e16);
    if (vm_cov_vmulhu_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhu_e16 < 300"); end
    $display("[COV] VIMac64b.vmulhu_e32 = %0d", vm_cov_vmulhu_e32);
    if (vm_cov_vmulhu_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhu_e32 < 300"); end
    $display("[COV] VIMac64b.vmulhu_e64 = %0d", vm_cov_vmulhu_e64);
    if (vm_cov_vmulhu_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhu_e64 < 300"); end
    $display("[COV] VIMac64b.vmulhsu_e8 = %0d", vm_cov_vmulhsu_e8);
    if (vm_cov_vmulhsu_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhsu_e8 < 300"); end
    $display("[COV] VIMac64b.vmulhsu_e16 = %0d", vm_cov_vmulhsu_e16);
    if (vm_cov_vmulhsu_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhsu_e16 < 300"); end
    $display("[COV] VIMac64b.vmulhsu_e32 = %0d", vm_cov_vmulhsu_e32);
    if (vm_cov_vmulhsu_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhsu_e32 < 300"); end
    $display("[COV] VIMac64b.vmulhsu_e64 = %0d", vm_cov_vmulhsu_e64);
    if (vm_cov_vmulhsu_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmulhsu_e64 < 300"); end
    $display("[COV] VIMac64b.vmacc_e8 = %0d", vm_cov_vmacc_e8);
    if (vm_cov_vmacc_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmacc_e8 < 300"); end
    $display("[COV] VIMac64b.vmacc_e16 = %0d", vm_cov_vmacc_e16);
    if (vm_cov_vmacc_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmacc_e16 < 300"); end
    $display("[COV] VIMac64b.vmacc_e32 = %0d", vm_cov_vmacc_e32);
    if (vm_cov_vmacc_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmacc_e32 < 300"); end
    $display("[COV] VIMac64b.vmacc_e64 = %0d", vm_cov_vmacc_e64);
    if (vm_cov_vmacc_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmacc_e64 < 300"); end
    $display("[COV] VIMac64b.vwmaccu_e8 = %0d", vm_cov_vwmaccu_e8);
    if (vm_cov_vwmaccu_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccu_e8 < 300"); end
    $display("[COV] VIMac64b.vwmaccu_e16 = %0d", vm_cov_vwmaccu_e16);
    if (vm_cov_vwmaccu_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccu_e16 < 300"); end
    $display("[COV] VIMac64b.vwmaccu_e32 = %0d", vm_cov_vwmaccu_e32);
    if (vm_cov_vwmaccu_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccu_e32 < 300"); end
    $display("[COV] VIMac64b.vwmaccu_e64 = %0d", vm_cov_vwmaccu_e64);
    if (vm_cov_vwmaccu_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccu_e64 < 300"); end
    $display("[COV] VIMac64b.vwmacc_e8 = %0d", vm_cov_vwmacc_e8);
    if (vm_cov_vwmacc_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmacc_e8 < 300"); end
    $display("[COV] VIMac64b.vwmacc_e16 = %0d", vm_cov_vwmacc_e16);
    if (vm_cov_vwmacc_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmacc_e16 < 300"); end
    $display("[COV] VIMac64b.vwmacc_e32 = %0d", vm_cov_vwmacc_e32);
    if (vm_cov_vwmacc_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmacc_e32 < 300"); end
    $display("[COV] VIMac64b.vwmacc_e64 = %0d", vm_cov_vwmacc_e64);
    if (vm_cov_vwmacc_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmacc_e64 < 300"); end
    $display("[COV] VIMac64b.vwmaccsu_e8 = %0d", vm_cov_vwmaccsu_e8);
    if (vm_cov_vwmaccsu_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccsu_e8 < 300"); end
    $display("[COV] VIMac64b.vwmaccsu_e16 = %0d", vm_cov_vwmaccsu_e16);
    if (vm_cov_vwmaccsu_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccsu_e16 < 300"); end
    $display("[COV] VIMac64b.vwmaccsu_e32 = %0d", vm_cov_vwmaccsu_e32);
    if (vm_cov_vwmaccsu_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccsu_e32 < 300"); end
    $display("[COV] VIMac64b.vwmaccsu_e64 = %0d", vm_cov_vwmaccsu_e64);
    if (vm_cov_vwmaccsu_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccsu_e64 < 300"); end
    $display("[COV] VIMac64b.vwmaccus_e8 = %0d", vm_cov_vwmaccus_e8);
    if (vm_cov_vwmaccus_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccus_e8 < 300"); end
    $display("[COV] VIMac64b.vwmaccus_e16 = %0d", vm_cov_vwmaccus_e16);
    if (vm_cov_vwmaccus_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccus_e16 < 300"); end
    $display("[COV] VIMac64b.vwmaccus_e32 = %0d", vm_cov_vwmaccus_e32);
    if (vm_cov_vwmaccus_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccus_e32 < 300"); end
    $display("[COV] VIMac64b.vwmaccus_e64 = %0d", vm_cov_vwmaccus_e64);
    if (vm_cov_vwmaccus_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vwmaccus_e64 < 300"); end
    $display("[COV] VIMac64b.vnmsac_e8 = %0d", vm_cov_vnmsac_e8);
    if (vm_cov_vnmsac_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsac_e8 < 300"); end
    $display("[COV] VIMac64b.vnmsac_e16 = %0d", vm_cov_vnmsac_e16);
    if (vm_cov_vnmsac_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsac_e16 < 300"); end
    $display("[COV] VIMac64b.vnmsac_e32 = %0d", vm_cov_vnmsac_e32);
    if (vm_cov_vnmsac_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsac_e32 < 300"); end
    $display("[COV] VIMac64b.vnmsac_e64 = %0d", vm_cov_vnmsac_e64);
    if (vm_cov_vnmsac_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsac_e64 < 300"); end
    $display("[COV] VIMac64b.vmadd_e8 = %0d", vm_cov_vmadd_e8);
    if (vm_cov_vmadd_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmadd_e8 < 300"); end
    $display("[COV] VIMac64b.vmadd_e16 = %0d", vm_cov_vmadd_e16);
    if (vm_cov_vmadd_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmadd_e16 < 300"); end
    $display("[COV] VIMac64b.vmadd_e32 = %0d", vm_cov_vmadd_e32);
    if (vm_cov_vmadd_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmadd_e32 < 300"); end
    $display("[COV] VIMac64b.vmadd_e64 = %0d", vm_cov_vmadd_e64);
    if (vm_cov_vmadd_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vmadd_e64 < 300"); end
    $display("[COV] VIMac64b.vnmsub_e8 = %0d", vm_cov_vnmsub_e8);
    if (vm_cov_vnmsub_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsub_e8 < 300"); end
    $display("[COV] VIMac64b.vnmsub_e16 = %0d", vm_cov_vnmsub_e16);
    if (vm_cov_vnmsub_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsub_e16 < 300"); end
    $display("[COV] VIMac64b.vnmsub_e32 = %0d", vm_cov_vnmsub_e32);
    if (vm_cov_vnmsub_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsub_e32 < 300"); end
    $display("[COV] VIMac64b.vnmsub_e64 = %0d", vm_cov_vnmsub_e64);
    if (vm_cov_vnmsub_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vnmsub_e64 < 300"); end
    $display("[COV] VIMac64b.vsmul_e8 = %0d", vm_cov_vsmul_e8);
    if (vm_cov_vsmul_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e8 < 300"); end
    $display("[COV] VIMac64b.vsmul_e16 = %0d", vm_cov_vsmul_e16);
    if (vm_cov_vsmul_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e16 < 300"); end
    $display("[COV] VIMac64b.vsmul_e32 = %0d", vm_cov_vsmul_e32);
    if (vm_cov_vsmul_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e32 < 300"); end
    $display("[COV] VIMac64b.vsmul_e64 = %0d", vm_cov_vsmul_e64);
    if (vm_cov_vsmul_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e64 < 300"); end
    $display("[COV] VIMac64b.randctl_e8 = %0d", vm_cov_randctl_e8);
    if (vm_cov_randctl_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.randctl_e8 < 300"); end
    $display("[COV] VIMac64b.randctl_e16 = %0d", vm_cov_randctl_e16);
    if (vm_cov_randctl_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.randctl_e16 < 300"); end
    $display("[COV] VIMac64b.randctl_e32 = %0d", vm_cov_randctl_e32);
    if (vm_cov_randctl_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.randctl_e32 < 300"); end
    $display("[COV] VIMac64b.randctl_e64 = %0d", vm_cov_randctl_e64);
    if (vm_cov_randctl_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.randctl_e64 < 300"); end
    $display("[COV] VIMac64b.sat_e8 = %0d", vm_cov_sat_e8);
    if (vm_cov_sat_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.sat_e8 < 300"); end
    $display("[COV] VIMac64b.vsmul_e8_vxrm0 = %0d", vm_cov_vsmul_e8_vxrm0);
    if (vm_cov_vsmul_e8_vxrm0 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e8_vxrm0 < 300"); end
    $display("[COV] VIMac64b.vsmul_e8_vxrm1 = %0d", vm_cov_vsmul_e8_vxrm1);
    if (vm_cov_vsmul_e8_vxrm1 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e8_vxrm1 < 300"); end
    $display("[COV] VIMac64b.vsmul_e8_vxrm2 = %0d", vm_cov_vsmul_e8_vxrm2);
    if (vm_cov_vsmul_e8_vxrm2 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e8_vxrm2 < 300"); end
    $display("[COV] VIMac64b.vsmul_e8_vxrm3 = %0d", vm_cov_vsmul_e8_vxrm3);
    if (vm_cov_vsmul_e8_vxrm3 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e8_vxrm3 < 300"); end
    $display("[COV] VIMac64b.sub_e8 = %0d", vm_cov_sub_e8);
    if (vm_cov_sub_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.sub_e8 < 300"); end
    $display("[COV] VIMac64b.high_e8 = %0d", vm_cov_high_e8);
    if (vm_cov_high_e8 < 300) begin cov_fail++; $display("[COV] VIMac64b.high_e8 < 300"); end
    $display("[COV] VIMac64b.sat_e16 = %0d", vm_cov_sat_e16);
    if (vm_cov_sat_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.sat_e16 < 300"); end
    $display("[COV] VIMac64b.vsmul_e16_vxrm0 = %0d", vm_cov_vsmul_e16_vxrm0);
    if (vm_cov_vsmul_e16_vxrm0 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e16_vxrm0 < 300"); end
    $display("[COV] VIMac64b.vsmul_e16_vxrm1 = %0d", vm_cov_vsmul_e16_vxrm1);
    if (vm_cov_vsmul_e16_vxrm1 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e16_vxrm1 < 300"); end
    $display("[COV] VIMac64b.vsmul_e16_vxrm2 = %0d", vm_cov_vsmul_e16_vxrm2);
    if (vm_cov_vsmul_e16_vxrm2 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e16_vxrm2 < 300"); end
    $display("[COV] VIMac64b.vsmul_e16_vxrm3 = %0d", vm_cov_vsmul_e16_vxrm3);
    if (vm_cov_vsmul_e16_vxrm3 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e16_vxrm3 < 300"); end
    $display("[COV] VIMac64b.sub_e16 = %0d", vm_cov_sub_e16);
    if (vm_cov_sub_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.sub_e16 < 300"); end
    $display("[COV] VIMac64b.high_e16 = %0d", vm_cov_high_e16);
    if (vm_cov_high_e16 < 300) begin cov_fail++; $display("[COV] VIMac64b.high_e16 < 300"); end
    $display("[COV] VIMac64b.sat_e32 = %0d", vm_cov_sat_e32);
    if (vm_cov_sat_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.sat_e32 < 300"); end
    $display("[COV] VIMac64b.vsmul_e32_vxrm0 = %0d", vm_cov_vsmul_e32_vxrm0);
    if (vm_cov_vsmul_e32_vxrm0 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e32_vxrm0 < 300"); end
    $display("[COV] VIMac64b.vsmul_e32_vxrm1 = %0d", vm_cov_vsmul_e32_vxrm1);
    if (vm_cov_vsmul_e32_vxrm1 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e32_vxrm1 < 300"); end
    $display("[COV] VIMac64b.vsmul_e32_vxrm2 = %0d", vm_cov_vsmul_e32_vxrm2);
    if (vm_cov_vsmul_e32_vxrm2 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e32_vxrm2 < 300"); end
    $display("[COV] VIMac64b.vsmul_e32_vxrm3 = %0d", vm_cov_vsmul_e32_vxrm3);
    if (vm_cov_vsmul_e32_vxrm3 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e32_vxrm3 < 300"); end
    $display("[COV] VIMac64b.sub_e32 = %0d", vm_cov_sub_e32);
    if (vm_cov_sub_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.sub_e32 < 300"); end
    $display("[COV] VIMac64b.high_e32 = %0d", vm_cov_high_e32);
    if (vm_cov_high_e32 < 300) begin cov_fail++; $display("[COV] VIMac64b.high_e32 < 300"); end
    $display("[COV] VIMac64b.sat_e64 = %0d", vm_cov_sat_e64);
    if (vm_cov_sat_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.sat_e64 < 300"); end
    $display("[COV] VIMac64b.vsmul_e64_vxrm0 = %0d", vm_cov_vsmul_e64_vxrm0);
    if (vm_cov_vsmul_e64_vxrm0 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e64_vxrm0 < 300"); end
    $display("[COV] VIMac64b.vsmul_e64_vxrm1 = %0d", vm_cov_vsmul_e64_vxrm1);
    if (vm_cov_vsmul_e64_vxrm1 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e64_vxrm1 < 300"); end
    $display("[COV] VIMac64b.vsmul_e64_vxrm2 = %0d", vm_cov_vsmul_e64_vxrm2);
    if (vm_cov_vsmul_e64_vxrm2 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e64_vxrm2 < 300"); end
    $display("[COV] VIMac64b.vsmul_e64_vxrm3 = %0d", vm_cov_vsmul_e64_vxrm3);
    if (vm_cov_vsmul_e64_vxrm3 < 300) begin cov_fail++; $display("[COV] VIMac64b.vsmul_e64_vxrm3 < 300"); end
    $display("[COV] VIMac64b.sub_e64 = %0d", vm_cov_sub_e64);
    if (vm_cov_sub_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.sub_e64 < 300"); end
    $display("[COV] VIMac64b.high_e64 = %0d", vm_cov_high_e64);
    if (vm_cov_high_e64 < 300) begin cov_fail++; $display("[COV] VIMac64b.high_e64 < 300"); end
    $display("[COV] VIMac64b.widen_uop_even = %0d", vm_cov_widen_uop_even);
    if (vm_cov_widen_uop_even < 300) begin cov_fail++; $display("[COV] VIMac64b.widen_uop_even < 300"); end
    $display("[COV] VIMac64b.widen_uop_odd = %0d", vm_cov_widen_uop_odd);
    if (vm_cov_widen_uop_odd < 300) begin cov_fail++; $display("[COV] VIMac64b.widen_uop_odd < 300"); end
    $display("[COV] VIMac64b.fire_gap = %0d", vm_cov_fire_gap);
    if (vm_cov_fire_gap < 300) begin cov_fail++; $display("[COV] VIMac64b.fire_gap < 300"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
