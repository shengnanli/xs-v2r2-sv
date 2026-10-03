// 自动生成：verif/ut/SRT16DividerDataModule/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// SRT16DividerDataModule 双例化逐拍比对：golden vs 重写 _xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= SRT16DividerDataModule =================
  int unsigned sd_mode = 0;
  logic sd_reset;
  logic [63:0] sd_io_src_0;
  logic [63:0] sd_io_src_1;
  logic sd_io_valid;
  logic sd_io_sign;
  logic sd_io_kill_w;
  logic sd_io_kill_r;
  logic sd_io_isHi;
  logic sd_io_isW;
  wire  sd_g_io_in_ready, sd_i_io_in_ready;
  logic sd_s0_io_in_ready = '0, sd_s1_io_in_ready = '0;
  wire  sd_g_io_out_valid, sd_i_io_out_valid;
  logic sd_s0_io_out_valid = '0, sd_s1_io_out_valid = '0;
  wire  [63:0] sd_g_io_out_data, sd_i_io_out_data;
  logic [63:0] sd_s0_io_out_data = '0, sd_s1_io_out_data = '0;
  logic sd_io_out_ready;
  int sd_cov_special = 0;
  int sd_cov_iter = 0;
  int sd_cov_kill_inflight = 0;
  int sd_cov_need_corr = 0;
  int sd_cov_finish_hi = 0;
  int sd_cov_finish_w = 0;
  int sd_cov_d_zero = 0;
  logic [0:0] sd_armed = '0;
  int sd_armed_at = -1;
  SRT16DividerDataModule sd_u_gold (
    .clock(clk),
    .reset(sd_reset),
    .io_src_0(sd_io_src_0),
    .io_src_1(sd_io_src_1),
    .io_valid(sd_io_valid),
    .io_sign(sd_io_sign),
    .io_kill_w(sd_io_kill_w),
    .io_kill_r(sd_io_kill_r),
    .io_isHi(sd_io_isHi),
    .io_isW(sd_io_isW),
    .io_in_ready(sd_g_io_in_ready),
    .io_out_valid(sd_g_io_out_valid),
    .io_out_data(sd_g_io_out_data),
    .io_out_ready(sd_io_out_ready)
  );
  SRT16DividerDataModule_xs sd_u_impl (
    .clock(clk),
    .reset(sd_reset),
    .io_src_0(sd_io_src_0),
    .io_src_1(sd_io_src_1),
    .io_valid(sd_io_valid),
    .io_sign(sd_io_sign),
    .io_kill_w(sd_io_kill_w),
    .io_kill_r(sd_io_kill_r),
    .io_isHi(sd_io_isHi),
    .io_isW(sd_io_isW),
    .io_in_ready(sd_i_io_in_ready),
    .io_out_valid(sd_i_io_out_valid),
    .io_out_data(sd_i_io_out_data),
    .io_out_ready(sd_io_out_ready)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 700 == 0) sd_mode = $urandom_range(0, 15);
      sd_io_src_0 = 64'({$urandom, $urandom});
      sd_io_src_1 = 64'({$urandom, $urandom});
      sd_io_valid = 1'($urandom);
      sd_io_sign = 1'($urandom);
      sd_io_kill_w = 1'($urandom);
      sd_io_kill_r = 1'($urandom);
      sd_io_isHi = 1'($urandom);
      sd_io_isW = 1'($urandom);
      sd_io_out_ready = 1'($urandom);
      sd_reset = (cyc < RESET_CYC) || ($urandom_range(0, 59999) == 0);
      begin : stim_sd
        sd_io_valid = ($urandom_range(0, 3) != 0);
        sd_io_out_ready = $urandom_range(0, 1);
        sd_io_kill_w = ($urandom_range(0, 15) == 0);
        sd_io_kill_r = ($urandom_range(0, 199) == 0);
        case (sd_mode % 7)
          0: ;                                                         // 全随机
          1: begin sd_io_src_0 = 64'($urandom_range(0, 65535)); sd_io_src_1 = 64'($urandom_range(1, 300)); end
          2: begin
            case ($urandom_range(0, 2))
              0: sd_io_src_1 = 64'd0;
              1: sd_io_src_1 = 64'd1;
              default: sd_io_src_1 = '1;
            endcase
          end
          3: begin sd_io_src_0 = 64'h8000_0000_0000_0000; sd_io_src_1 = '1; end
          4: begin sd_io_src_0 = 64'($signed(32'($urandom))); sd_io_src_1 = 64'($signed(32'($urandom) >>> $urandom_range(0, 30))); end
          5: begin sd_io_src_0 = 64'($urandom_range(0, 1000)); sd_io_src_1 = {$urandom, $urandom}; end
          default: begin sd_io_src_0 = {$urandom, $urandom}; sd_io_src_1 = {$urandom, $urandom} >> $urandom_range(0, 63); end
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && sd_armed_at >= 0 && cyc >= sd_armed_at) begin
        checks++;
        if (sd_g_io_in_ready !== sd_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRT16DividerDataModule.io_in_ready g=%h i=%h", cyc, sd_g_io_in_ready, sd_i_io_in_ready);
        end
        sd_s1_io_in_ready |= sd_g_io_in_ready;
        sd_s0_io_in_ready |= ~sd_g_io_in_ready;
        checks++;
        if (sd_g_io_out_valid !== sd_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRT16DividerDataModule.io_out_valid g=%h i=%h", cyc, sd_g_io_out_valid, sd_i_io_out_valid);
        end
        sd_s1_io_out_valid |= sd_g_io_out_valid;
        sd_s0_io_out_valid |= ~sd_g_io_out_valid;
        checks++;
        if (sd_g_io_out_data !== sd_i_io_out_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRT16DividerDataModule.io_out_data g=%h i=%h", cyc, sd_g_io_out_data, sd_i_io_out_data);
        end
        sd_s1_io_out_data |= sd_g_io_out_data;
        sd_s0_io_out_data |= ~sd_g_io_out_data;
        if (sd_u_gold.state[2] && sd_u_gold.special) sd_cov_special++;
        if (sd_u_gold.state[3]) sd_cov_iter++;
        if (sd_io_kill_r && !sd_u_gold.state[0]) sd_cov_kill_inflight++;
        if (sd_u_gold.state[5] && !sd_u_gold.specialReg && sd_u_gold.needCorr) sd_cov_need_corr++;
        if (sd_g_io_out_valid && sd_io_out_ready && sd_io_isHi) sd_cov_finish_hi++;
        if (sd_g_io_out_valid && sd_io_out_ready && sd_io_isW) sd_cov_finish_w++;
        if (sd_u_gold.state[2] && sd_u_gold.dIsZero) sd_cov_d_zero++;
      end
      if (sd_u_gold.state[5]) sd_armed[0] = 1'b1;
      if (sd_armed_at < 0 && (&sd_armed)) sd_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(sd_s0_io_in_ready && sd_s1_io_in_ready)) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_in_ready 未见过 0 和 1"); end
    if (!(sd_s0_io_out_valid && sd_s1_io_out_valid)) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_valid 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[0] && sd_s1_io_out_data[0])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[0] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[1] && sd_s1_io_out_data[1])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[1] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[2] && sd_s1_io_out_data[2])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[2] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[3] && sd_s1_io_out_data[3])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[3] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[4] && sd_s1_io_out_data[4])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[4] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[5] && sd_s1_io_out_data[5])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[5] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[6] && sd_s1_io_out_data[6])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[6] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[7] && sd_s1_io_out_data[7])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[7] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[8] && sd_s1_io_out_data[8])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[8] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[9] && sd_s1_io_out_data[9])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[9] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[10] && sd_s1_io_out_data[10])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[10] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[11] && sd_s1_io_out_data[11])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[11] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[12] && sd_s1_io_out_data[12])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[12] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[13] && sd_s1_io_out_data[13])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[13] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[14] && sd_s1_io_out_data[14])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[14] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[15] && sd_s1_io_out_data[15])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[15] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[16] && sd_s1_io_out_data[16])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[16] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[17] && sd_s1_io_out_data[17])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[17] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[18] && sd_s1_io_out_data[18])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[18] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[19] && sd_s1_io_out_data[19])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[19] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[20] && sd_s1_io_out_data[20])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[20] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[21] && sd_s1_io_out_data[21])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[21] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[22] && sd_s1_io_out_data[22])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[22] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[23] && sd_s1_io_out_data[23])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[23] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[24] && sd_s1_io_out_data[24])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[24] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[25] && sd_s1_io_out_data[25])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[25] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[26] && sd_s1_io_out_data[26])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[26] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[27] && sd_s1_io_out_data[27])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[27] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[28] && sd_s1_io_out_data[28])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[28] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[29] && sd_s1_io_out_data[29])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[29] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[30] && sd_s1_io_out_data[30])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[30] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[31] && sd_s1_io_out_data[31])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[31] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[32] && sd_s1_io_out_data[32])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[32] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[33] && sd_s1_io_out_data[33])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[33] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[34] && sd_s1_io_out_data[34])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[34] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[35] && sd_s1_io_out_data[35])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[35] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[36] && sd_s1_io_out_data[36])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[36] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[37] && sd_s1_io_out_data[37])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[37] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[38] && sd_s1_io_out_data[38])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[38] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[39] && sd_s1_io_out_data[39])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[39] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[40] && sd_s1_io_out_data[40])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[40] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[41] && sd_s1_io_out_data[41])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[41] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[42] && sd_s1_io_out_data[42])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[42] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[43] && sd_s1_io_out_data[43])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[43] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[44] && sd_s1_io_out_data[44])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[44] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[45] && sd_s1_io_out_data[45])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[45] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[46] && sd_s1_io_out_data[46])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[46] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[47] && sd_s1_io_out_data[47])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[47] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[48] && sd_s1_io_out_data[48])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[48] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[49] && sd_s1_io_out_data[49])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[49] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[50] && sd_s1_io_out_data[50])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[50] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[51] && sd_s1_io_out_data[51])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[51] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[52] && sd_s1_io_out_data[52])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[52] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[53] && sd_s1_io_out_data[53])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[53] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[54] && sd_s1_io_out_data[54])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[54] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[55] && sd_s1_io_out_data[55])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[55] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[56] && sd_s1_io_out_data[56])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[56] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[57] && sd_s1_io_out_data[57])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[57] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[58] && sd_s1_io_out_data[58])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[58] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[59] && sd_s1_io_out_data[59])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[59] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[60] && sd_s1_io_out_data[60])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[60] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[61] && sd_s1_io_out_data[61])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[61] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[62] && sd_s1_io_out_data[62])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[62] 未见过 0 和 1"); end
    if (!(sd_s0_io_out_data[63] && sd_s1_io_out_data[63])) begin cov_fail++; $display("[COV] SRT16DividerDataModule.io_out_data[63] 未见过 0 和 1"); end
    $display("[ARM] SRT16DividerDataModule armed_at=%0d", sd_armed_at);
    if (sd_armed_at < 0) begin cov_fail++; $display("[ARM] SRT16DividerDataModule 从未 arm"); end
    $display("[COV] SRT16DividerDataModule.special = %0d", sd_cov_special);
    if (sd_cov_special < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.special < 200"); end
    $display("[COV] SRT16DividerDataModule.iter = %0d", sd_cov_iter);
    if (sd_cov_iter < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.iter < 200"); end
    $display("[COV] SRT16DividerDataModule.kill_inflight = %0d", sd_cov_kill_inflight);
    if (sd_cov_kill_inflight < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.kill_inflight < 200"); end
    $display("[COV] SRT16DividerDataModule.need_corr = %0d", sd_cov_need_corr);
    if (sd_cov_need_corr < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.need_corr < 200"); end
    $display("[COV] SRT16DividerDataModule.finish_hi = %0d", sd_cov_finish_hi);
    if (sd_cov_finish_hi < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.finish_hi < 200"); end
    $display("[COV] SRT16DividerDataModule.finish_w = %0d", sd_cov_finish_w);
    if (sd_cov_finish_w < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.finish_w < 200"); end
    $display("[COV] SRT16DividerDataModule.d_zero = %0d", sd_cov_d_zero);
    if (sd_cov_d_zero < 200) begin cov_fail++; $display("[COV] SRT16DividerDataModule.d_zero < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
