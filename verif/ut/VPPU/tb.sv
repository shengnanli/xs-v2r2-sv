// =============================================================================
// tb —— VPPU UT：golden VPPU（含 golden Permutation / VPermSrcTypeModule）与重写件 VPPU_xs
//   （含重写 child 的 _xs 副本）双例化，同时钟同激励逐拍比全部输出。
//
// 激励：in_valid 约 75%；fuOpType 八成五取 VpermType 的 16 个合法编码（含 vmv1r/2r/4r/8r、vrgatherei16、
//   vfslide1up/down），其余任意 9 位；vsew / vlmul / vm / vma / vta 随机；vuopIdx 七成 0..15；vl 三档；
//   vstart 六成 0；vs1 按"全随机 / 小下标 / 小滑动量"轮换；v0 六种形状；out_ready 九成 1（父级里恒 1，
//   这里也测反压链）；ctrlPipe_2 / validPipe_2 / perfDebugInfo / seqNum 全随机。
// 比较时机（复位域）：valid 链异步复位，复位后每拍比 in_ready / out_valid / ctrl / exceptionVec；
//   res_data 来自 Permutation 的不复位寄存器 —— 第一次 fire 之后 3 拍起每拍比（同 Permutation UT）；
//   perf / seqNum 两级寄存器不复位、受 ready 门控 —— tb 跟踪"第 2 级寄存器被写过"之后才比。
// 覆盖（写进 PASS 判据）：16 个合法 fuOpType 各 >= 2000 次 fire；vmvnr 顶替 vlmul >= 2000；
//   vcompress 清掩码 >= 500 且 vcompress 不清掩码 >= 500；exceptionVec_2 0/1 都出现；
//   反压：in_ready=0 >= 500 拍、第 2 级 payload 因 out_ready=0 停住 >= 500 拍。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;

  logic clock = 0, reset = 1;

  // ---- 激励 ----
  logic         in_valid, out_ready;
  logic [8:0]   fuOpType;
  logic         vma, vta, vm;
  logic [1:0]   vsew;
  logic [2:0]   vlmul;
  logic [7:0]   vstart;
  logic [6:0]   vuopIdx;
  logic         p_rob_flag, p_vecWen, p_v0Wen, validPipe;
  logic [7:0]   p_rob_value, p_pdest, p_vstart;
  logic [7:0]   src4;
  logic [127:0] src3, src2, src1, src0;
  logic         elim;
  logic [63:0]  pt [9];
  logic [55:0]  seqNum;
  logic [7:0]   seqUop;

  // ---- 两侧输出 ----
  typedef struct packed {
    logic         in_ready, out_valid, rob_flag;
    logic [7:0]   rob_value, pdest;
    logic         vecWen, v0Wen, exc2;
  } ctl_o_t;
  typedef struct packed {
    logic         elim;
    logic [63:0]  t0, t1, t2, t3, t4, t5, t6, t7, t8;
    logic [55:0]  seqNum;
    logic [7:0]   seqUop;
  } pay_o_t;
  ctl_o_t g_ctl, i_ctl;
  pay_o_t g_pay, i_pay;
  logic [127:0] g_vd, i_vd;

  `define VPPU_PORTS(CTL, PAY, VD) \
    .clock(clock), .reset(reset), .io_in_ready(CTL.in_ready), .io_in_valid(in_valid), \
    .io_in_bits_ctrl_fuOpType(fuOpType), .io_in_bits_ctrl_vpu_vma(vma), .io_in_bits_ctrl_vpu_vta(vta), \
    .io_in_bits_ctrl_vpu_vsew(vsew), .io_in_bits_ctrl_vpu_vlmul(vlmul), .io_in_bits_ctrl_vpu_vm(vm), \
    .io_in_bits_ctrl_vpu_vstart(vstart), .io_in_bits_ctrl_vpu_vuopIdx(vuopIdx), \
    .io_in_bits_ctrlPipe_2_robIdx_flag(p_rob_flag), .io_in_bits_ctrlPipe_2_robIdx_value(p_rob_value), \
    .io_in_bits_ctrlPipe_2_pdest(p_pdest), .io_in_bits_ctrlPipe_2_vecWen(p_vecWen), \
    .io_in_bits_ctrlPipe_2_v0Wen(p_v0Wen), .io_in_bits_ctrlPipe_2_vpu_vstart(p_vstart), \
    .io_in_bits_validPipe_2(validPipe), .io_in_bits_data_src_4(src4), .io_in_bits_data_src_3(src3), \
    .io_in_bits_data_src_2(src2), .io_in_bits_data_src_1(src1), .io_in_bits_data_src_0(src0), \
    .io_in_bits_perfDebugInfo_eliminatedMove(elim), .io_in_bits_perfDebugInfo_renameTime(pt[0]), \
    .io_in_bits_perfDebugInfo_dispatchTime(pt[1]), .io_in_bits_perfDebugInfo_enqRsTime(pt[2]), \
    .io_in_bits_perfDebugInfo_selectTime(pt[3]), .io_in_bits_perfDebugInfo_issueTime(pt[4]), \
    .io_in_bits_perfDebugInfo_writebackTime(pt[5]), .io_in_bits_perfDebugInfo_runahead_checkpoint_id(pt[6]), \
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(pt[7]), .io_in_bits_perfDebugInfo_tlbRespTime(pt[8]), \
    .io_in_bits_debug_seqNum_seqNum(seqNum), .io_in_bits_debug_seqNum_uopIdx(seqUop), \
    .io_out_ready(out_ready), .io_out_valid(CTL.out_valid), \
    .io_out_bits_ctrl_robIdx_flag(CTL.rob_flag), .io_out_bits_ctrl_robIdx_value(CTL.rob_value), \
    .io_out_bits_ctrl_pdest(CTL.pdest), .io_out_bits_ctrl_vecWen(CTL.vecWen), .io_out_bits_ctrl_v0Wen(CTL.v0Wen), \
    .io_out_bits_ctrl_exceptionVec_2(CTL.exc2), .io_out_bits_res_data(VD), \
    .io_out_bits_perfDebugInfo_eliminatedMove(PAY.elim), .io_out_bits_perfDebugInfo_renameTime(PAY.t0), \
    .io_out_bits_perfDebugInfo_dispatchTime(PAY.t1), .io_out_bits_perfDebugInfo_enqRsTime(PAY.t2), \
    .io_out_bits_perfDebugInfo_selectTime(PAY.t3), .io_out_bits_perfDebugInfo_issueTime(PAY.t4), \
    .io_out_bits_perfDebugInfo_writebackTime(PAY.t5), .io_out_bits_perfDebugInfo_runahead_checkpoint_id(PAY.t6), \
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(PAY.t7), .io_out_bits_perfDebugInfo_tlbRespTime(PAY.t8), \
    .io_out_bits_debug_seqNum_seqNum(PAY.seqNum), .io_out_bits_debug_seqNum_uopIdx(PAY.seqUop)

  VPPU    u_g (`VPPU_PORTS(g_ctl, g_pay, g_vd));
  VPPU_xs u_i (`VPPU_PORTS(i_ctl, i_pay, i_vd));

  // ---- 合法编码表 ----
  localparam int NOPS = 16;
  logic [8:0] OPS [NOPS] = '{9'h080, 9'h081, 9'h002, 9'h042, 9'h003, 9'h043, 9'h004, 9'h024,
                             9'h085, 9'h026, 9'h007, 9'h00F, 9'h017, 9'h01F, 9'h0FF, 9'h1FF};
  // 最后两个：dummy（8 位 0xFF，合法编码表里的"未实现"）与它的 9 位变体，看非法码两侧同样处理
  int cov_op [NOPS];
  int cov_vmvnr, cov_clr, cov_noclr, cov_exc0, cov_exc1, cov_stall_in, cov_stall_pay;

  function automatic logic [127:0] rnd128();
    return {$urandom, $urandom, $urandom, $urandom};
  endfunction
  function automatic logic [127:0] shape();
    case ($urandom_range(0, 5))
      0: return rnd128();
      1: return rnd128() & rnd128() & rnd128();
      2: return rnd128() | rnd128();
      3: return '0;
      4: return '1;
      default: return 128'(1) << $urandom_range(0, 127);
    endcase
  endfunction

  int op_sel;
  task automatic drive();
    in_valid  = ($urandom_range(0, 3) != 0);
    out_ready = ($urandom_range(0, 9) != 0);
    op_sel    = ($urandom_range(0, 19) < 17) ? $urandom_range(0, NOPS - 1) : -1;
    fuOpType  = (op_sel >= 0) ? OPS[op_sel] : 9'($urandom);
    vma = $urandom; vta = $urandom; vm = $urandom;
    vsew = $urandom; vlmul = $urandom;
    vstart  = ($urandom_range(0, 9) < 6) ? 8'd0 : 8'($urandom);
    vuopIdx = ($urandom_range(0, 9) < 7) ? 7'($urandom_range(0, 15)) : 7'($urandom);
    p_rob_flag = $urandom; p_rob_value = $urandom; p_pdest = $urandom;
    p_vecWen = $urandom; p_v0Wen = $urandom; validPipe = ($urandom_range(0, 3) != 0);
    p_vstart = ($urandom_range(0, 1)) ? 8'd0 : 8'($urandom);
    case ($urandom_range(0, 2))
      0: src4 = $urandom_range(0, 16);
      1: src4 = $urandom_range(0, 128);
      default: src4 = $urandom;
    endcase
    case ($urandom_range(0, 2))
      0: src0 = rnd128();
      1: begin
        src0 = rnd128();
        for (int b = 0; b < 16; b++) if ($urandom_range(0, 3) != 0) src0[8*b +: 8] = $urandom_range(0, 63);
      end
      default: begin
        src0 = rnd128();
        src0[63:0] = ($urandom_range(0, 3) != 0) ? 64'($urandom_range(0, 40)) : {$urandom, $urandom};
      end
    endcase
    src1 = rnd128(); src2 = rnd128(); src3 = shape();
    elim = $urandom;
    for (int k = 0; k < 9; k++) pt[k] = {$urandom, $urandom};
    seqNum = {$urandom, $urandom}; seqUop = $urandom;
  endtask

  // ---- 比较 ----
  int first_fire = -1;
  bit w1 = 0, w2 = 0;          // 第 1 / 2 级 payload 寄存器自开机以来被写过
  task automatic compare(input int c);
    checks++;
    if (g_ctl !== i_ctl) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH ctl g=%h i=%h", c, g_ctl, i_ctl);
    end
    if (first_fire >= 0 && c >= first_fire + 3) begin
      checks++;
      if (g_vd !== i_vd) begin
        errors++;
        if (errors <= 30) $display("[%0d] MISMATCH res_data g=%h i=%h", c, g_vd, i_vd);
      end
    end
    if (w2) begin
      checks++;
      if (g_pay !== i_pay) begin
        errors++;
        if (errors <= 30) $display("[%0d] MISMATCH payload g=%h i=%h", c, g_pay, i_pay);
      end
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov_op[k]) cov_op[k] = 0;
    cov_vmvnr = 0; cov_clr = 0; cov_noclr = 0; cov_exc0 = 0; cov_exc1 = 0; cov_stall_in = 0; cov_stall_pay = 0;
    drive();
    reset = 1;
    repeat (4) begin #5 clock = 1; #5 clock = 0; end
    reset = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      drive();
      #1;
      compare(c);
      // 覆盖与"写过"跟踪（用 golden 的可见输出 + 两级 valid）
      if (in_valid) begin
        if (first_fire < 0) first_fire = c;
        if (op_sel >= 0) cov_op[op_sel]++;
        if (fuOpType[2:0] == 3'b111 && fuOpType[7:5] == 3'b000) cov_vmvnr++;
        if (fuOpType == 9'h026) begin
          if (vuopIdx[6:1] == 0) cov_clr++; else cov_noclr++;
        end
      end
      if (g_ctl.exc2) cov_exc1++; else cov_exc0++;
      if (!g_ctl.in_ready) cov_stall_in++;
      if (u_g.validVecThisFu_1 && u_g.validVecThisFu_2 && !out_ready) cov_stall_pay++;
      // 下一拍时钟沿上的写入（与 golden 同条件）
      begin
        bit w1n, w2n;
        w1n = w1 | (g_ctl.in_ready & in_valid);
        w2n = w2 | ((~u_g.validVecThisFu_2 | out_ready) & u_g.validVecThisFu_1 & w1);
        #4 clock = 1;
        w1 = w1n; w2 = w2n;
      end
      #5 clock = 0;
    end
    begin
      int bad = 0;
      foreach (cov_op[k]) if (cov_op[k] < 2000) bad++;
      if (cov_vmvnr < 2000 || cov_clr < 500 || cov_noclr < 500 || cov_exc0 == 0 || cov_exc1 == 0) bad++;
      if (cov_stall_in < 500 || cov_stall_pay < 500) bad++;
      $write("--- coverage: op fires:"); foreach (cov_op[k]) $write(" %0d", cov_op[k]); $display("");
      $display("    vmvnr=%0d vcompress clr/noclr=%0d/%0d exc2 0/1=%0d/%0d in_ready=0 cycles=%0d payload stall=%0d",
               cov_vmvnr, cov_clr, cov_noclr, cov_exc0, cov_exc1, cov_stall_in, cov_stall_pay);
      $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
      if (errors == 0 && bad == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
