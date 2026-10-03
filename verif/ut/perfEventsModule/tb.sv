// 自动生成：verif/ut/perfEventsModule/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// perfEventsModule 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= perfEventsModule =================
  int unsigned e_mode = 0;
  function automatic logic [4:0] pick_op();
    case ($urandom_range(0, 7))
      0: return 5'd0;
      1: return 5'd1;
      2: return 5'd2;
      3: return 5'd4;
      default: return 5'($urandom);
    endcase
  endfunction
  logic e_reset;
  logic e_w_wen;
  logic [63:0] e_w_wdata;
  wire  [63:0] e_g_rdata, e_i_rdata;
  logic [63:0] e_s0_rdata = '0, e_s1_rdata = '0;
  int e_cov_write = 0;
  int e_cov_op2_legal = 0;
  int e_cov_op2_illegal = 0;
  int e_cov_op1_legal = 0;
  int e_cov_op1_illegal = 0;
  int e_cov_op0_legal = 0;
  int e_cov_op0_illegal = 0;
  int e_cov_reset_mid = 0;
  logic [0:0] e_armed = '0;
  int e_armed_at = -1;
  perfEventsModule e_u_gold (
    .clock(clk),
    .reset(e_reset),
    .w_wen(e_w_wen),
    .w_wdata(e_w_wdata),
    .rdata(e_g_rdata)
  );
  perfEventsModule_xs e_u_impl (
    .clock(clk),
    .reset(e_reset),
    .w_wen(e_w_wen),
    .w_wdata(e_w_wdata),
    .rdata(e_i_rdata)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) e_mode = $urandom_range(0, 15);
      e_w_wen = 1'($urandom);
      e_w_wdata = 64'({$urandom, $urandom});
      e_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_e
        e_w_wen = ($urandom_range(0, 2) == 0);
        e_w_wdata[54:50] = pick_op();
        e_w_wdata[49:45] = pick_op();
        e_w_wdata[44:40] = pick_op();
      end
      #4;
      e_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&e_armed)) begin
        checks++;
        if (e_g_rdata !== e_i_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d perfEventsModule.rdata g=%h i=%h", cyc, e_g_rdata, e_i_rdata);
        end
        e_s1_rdata |= e_g_rdata;
        e_s0_rdata |= ~e_g_rdata;
        if (e_w_wen) e_cov_write++;
        if (e_w_wen && (e_w_wdata[54:50] == 5'd0 || e_w_wdata[54:50] == 5'd1 || e_w_wdata[54:50] == 5'd2 || e_w_wdata[54:50] == 5'd4)) e_cov_op2_legal++;
        if (e_w_wen && !(e_w_wdata[54:50] == 5'd0 || e_w_wdata[54:50] == 5'd1 || e_w_wdata[54:50] == 5'd2 || e_w_wdata[54:50] == 5'd4)) e_cov_op2_illegal++;
        if (e_w_wen && (e_w_wdata[49:45] == 5'd0 || e_w_wdata[49:45] == 5'd1 || e_w_wdata[49:45] == 5'd2 || e_w_wdata[49:45] == 5'd4)) e_cov_op1_legal++;
        if (e_w_wen && !(e_w_wdata[49:45] == 5'd0 || e_w_wdata[49:45] == 5'd1 || e_w_wdata[49:45] == 5'd2 || e_w_wdata[49:45] == 5'd4)) e_cov_op1_illegal++;
        if (e_w_wen && (e_w_wdata[44:40] == 5'd0 || e_w_wdata[44:40] == 5'd1 || e_w_wdata[44:40] == 5'd2 || e_w_wdata[44:40] == 5'd4)) e_cov_op0_legal++;
        if (e_w_wen && !(e_w_wdata[44:40] == 5'd0 || e_w_wdata[44:40] == 5'd1 || e_w_wdata[44:40] == 5'd2 || e_w_wdata[44:40] == 5'd4)) e_cov_op0_illegal++;
        if (e_reset && cyc > 100) e_cov_reset_mid++;
      end
      if (e_armed_at < 0 && (&e_armed)) e_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(e_s0_rdata[0] && e_s1_rdata[0])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[0] 未见过 0 和 1"); end
    if (!(e_s0_rdata[1] && e_s1_rdata[1])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[1] 未见过 0 和 1"); end
    if (!(e_s0_rdata[2] && e_s1_rdata[2])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[2] 未见过 0 和 1"); end
    if (!(e_s0_rdata[3] && e_s1_rdata[3])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[3] 未见过 0 和 1"); end
    if (!(e_s0_rdata[4] && e_s1_rdata[4])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[4] 未见过 0 和 1"); end
    if (!(e_s0_rdata[5] && e_s1_rdata[5])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[5] 未见过 0 和 1"); end
    if (!(e_s0_rdata[6] && e_s1_rdata[6])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[6] 未见过 0 和 1"); end
    if (!(e_s0_rdata[7] && e_s1_rdata[7])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[7] 未见过 0 和 1"); end
    if (!(e_s0_rdata[8] && e_s1_rdata[8])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[8] 未见过 0 和 1"); end
    if (!(e_s0_rdata[9] && e_s1_rdata[9])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[9] 未见过 0 和 1"); end
    if (!(e_s0_rdata[10] && e_s1_rdata[10])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[10] 未见过 0 和 1"); end
    if (!(e_s0_rdata[11] && e_s1_rdata[11])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[11] 未见过 0 和 1"); end
    if (!(e_s0_rdata[12] && e_s1_rdata[12])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[12] 未见过 0 和 1"); end
    if (!(e_s0_rdata[13] && e_s1_rdata[13])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[13] 未见过 0 和 1"); end
    if (!(e_s0_rdata[14] && e_s1_rdata[14])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[14] 未见过 0 和 1"); end
    if (!(e_s0_rdata[15] && e_s1_rdata[15])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[15] 未见过 0 和 1"); end
    if (!(e_s0_rdata[16] && e_s1_rdata[16])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[16] 未见过 0 和 1"); end
    if (!(e_s0_rdata[17] && e_s1_rdata[17])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[17] 未见过 0 和 1"); end
    if (!(e_s0_rdata[18] && e_s1_rdata[18])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[18] 未见过 0 和 1"); end
    if (!(e_s0_rdata[19] && e_s1_rdata[19])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[19] 未见过 0 和 1"); end
    if (!(e_s0_rdata[20] && e_s1_rdata[20])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[20] 未见过 0 和 1"); end
    if (!(e_s0_rdata[21] && e_s1_rdata[21])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[21] 未见过 0 和 1"); end
    if (!(e_s0_rdata[22] && e_s1_rdata[22])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[22] 未见过 0 和 1"); end
    if (!(e_s0_rdata[23] && e_s1_rdata[23])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[23] 未见过 0 和 1"); end
    if (!(e_s0_rdata[24] && e_s1_rdata[24])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[24] 未见过 0 和 1"); end
    if (!(e_s0_rdata[25] && e_s1_rdata[25])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[25] 未见过 0 和 1"); end
    if (!(e_s0_rdata[26] && e_s1_rdata[26])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[26] 未见过 0 和 1"); end
    if (!(e_s0_rdata[27] && e_s1_rdata[27])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[27] 未见过 0 和 1"); end
    if (!(e_s0_rdata[28] && e_s1_rdata[28])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[28] 未见过 0 和 1"); end
    if (!(e_s0_rdata[29] && e_s1_rdata[29])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[29] 未见过 0 和 1"); end
    if (!(e_s0_rdata[30] && e_s1_rdata[30])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[30] 未见过 0 和 1"); end
    if (!(e_s0_rdata[31] && e_s1_rdata[31])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[31] 未见过 0 和 1"); end
    if (!(e_s0_rdata[32] && e_s1_rdata[32])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[32] 未见过 0 和 1"); end
    if (!(e_s0_rdata[33] && e_s1_rdata[33])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[33] 未见过 0 和 1"); end
    if (!(e_s0_rdata[34] && e_s1_rdata[34])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[34] 未见过 0 和 1"); end
    if (!(e_s0_rdata[35] && e_s1_rdata[35])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[35] 未见过 0 和 1"); end
    if (!(e_s0_rdata[36] && e_s1_rdata[36])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[36] 未见过 0 和 1"); end
    if (!(e_s0_rdata[37] && e_s1_rdata[37])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[37] 未见过 0 和 1"); end
    if (!(e_s0_rdata[38] && e_s1_rdata[38])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[38] 未见过 0 和 1"); end
    if (!(e_s0_rdata[39] && e_s1_rdata[39])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[39] 未见过 0 和 1"); end
    if (!(e_s0_rdata[40] && e_s1_rdata[40])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[40] 未见过 0 和 1"); end
    if (!(e_s0_rdata[41] && e_s1_rdata[41])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[41] 未见过 0 和 1"); end
    if (!(e_s0_rdata[42] && e_s1_rdata[42])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[42] 未见过 0 和 1"); end
    if (!(e_s0_rdata[45] && e_s1_rdata[45])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[45] 未见过 0 和 1"); end
    if (!(e_s0_rdata[46] && e_s1_rdata[46])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[46] 未见过 0 和 1"); end
    if (!(e_s0_rdata[47] && e_s1_rdata[47])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[47] 未见过 0 和 1"); end
    if (!(e_s0_rdata[50] && e_s1_rdata[50])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[50] 未见过 0 和 1"); end
    if (!(e_s0_rdata[51] && e_s1_rdata[51])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[51] 未见过 0 和 1"); end
    if (!(e_s0_rdata[52] && e_s1_rdata[52])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[52] 未见过 0 和 1"); end
    if (!(e_s0_rdata[58] && e_s1_rdata[58])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[58] 未见过 0 和 1"); end
    if (!(e_s0_rdata[59] && e_s1_rdata[59])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[59] 未见过 0 和 1"); end
    if (!(e_s0_rdata[60] && e_s1_rdata[60])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[60] 未见过 0 和 1"); end
    if (!(e_s0_rdata[61] && e_s1_rdata[61])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[61] 未见过 0 和 1"); end
    if (!(e_s0_rdata[62] && e_s1_rdata[62])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[62] 未见过 0 和 1"); end
    if (!(e_s0_rdata[63] && e_s1_rdata[63])) begin cov_fail++; $display("[COV] perfEventsModule.rdata[63] 未见过 0 和 1"); end
    $display("[ARM] perfEventsModule armed_at=%0d", e_armed_at);
    if (e_armed_at < 0) begin cov_fail++; $display("[ARM] perfEventsModule 从未 arm"); end
    $display("[COV] perfEventsModule.write = %0d", e_cov_write);
    if (e_cov_write < 50) begin cov_fail++; $display("[COV] perfEventsModule.write < 50"); end
    $display("[COV] perfEventsModule.op2_legal = %0d", e_cov_op2_legal);
    if (e_cov_op2_legal < 50) begin cov_fail++; $display("[COV] perfEventsModule.op2_legal < 50"); end
    $display("[COV] perfEventsModule.op2_illegal = %0d", e_cov_op2_illegal);
    if (e_cov_op2_illegal < 50) begin cov_fail++; $display("[COV] perfEventsModule.op2_illegal < 50"); end
    $display("[COV] perfEventsModule.op1_legal = %0d", e_cov_op1_legal);
    if (e_cov_op1_legal < 50) begin cov_fail++; $display("[COV] perfEventsModule.op1_legal < 50"); end
    $display("[COV] perfEventsModule.op1_illegal = %0d", e_cov_op1_illegal);
    if (e_cov_op1_illegal < 50) begin cov_fail++; $display("[COV] perfEventsModule.op1_illegal < 50"); end
    $display("[COV] perfEventsModule.op0_legal = %0d", e_cov_op0_legal);
    if (e_cov_op0_legal < 50) begin cov_fail++; $display("[COV] perfEventsModule.op0_legal < 50"); end
    $display("[COV] perfEventsModule.op0_illegal = %0d", e_cov_op0_illegal);
    if (e_cov_op0_illegal < 50) begin cov_fail++; $display("[COV] perfEventsModule.op0_illegal < 50"); end
    $display("[COV] perfEventsModule.reset_mid = %0d", e_cov_reset_mid);
    if (e_cov_reset_mid < 50) begin cov_fail++; $display("[COV] perfEventsModule.reset_mid < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
