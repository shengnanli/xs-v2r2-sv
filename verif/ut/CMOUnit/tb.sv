// CMOUnit 双例化逐拍比对：golden CMOUnit vs 重写件 CMOUnit_xs（xs_CMOUnit_core）。
// GENERATED 区由 gen.py 从 G1 golden 端口表生成（勿手改）；其余为手写激励与覆盖。
//
// 激励：每拍随机驱动全部输入。req/A-ready/D-valid/resp-ready 各按不同概率给，使四个状态
//   都会停留、也都会前进；wfiReq 成段出现（打断 A 发送、测 wfiSafe）；D.valid 在非 WRESP
//   状态也会出现（golden 只在 WRESP 收，别的状态要被忽略）；每约 3000 拍随机打一次异步复位。
// 暖机：复位后第一拍强制接一条请求，把不复位的 req 寄存器写定后才开始比较。
// 覆盖闸（COV_MIN）：四个状态转移各自发生次数、wfiReq 挡住 A、D 带 denied/corrupt 收下、
//   复位次数；外加每个输出位见过 0 和 1。任一不足 => TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 200;
  int errors = 0, checks = 0, cov_fail = 0, cyc = 0;
  int cov_req_fire = 0, cov_a_fire = 0, cov_d_fire = 0, cov_resp_fire = 0;
  int cov_wfi_block = 0, cov_d_err = 0, cov_reset = 0, cov_d_ignored = 0;

  bit   clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // BEGIN GENERATED(tb-ports)
  // ---- 输入（两侧共用；clock/reset 由 tb 手写区驱动）----
  logic io_req_valid;
  logic [2:0] io_req_bits_opcode;
  logic [63:0] io_req_bits_address;
  logic io_req_chanA_ready;
  logic io_resp_chanD_valid;
  logic io_resp_chanD_bits_denied;
  logic io_resp_chanD_bits_corrupt;
  logic io_resp_to_lsq_ready;
  logic io_wfi_wfiReq;
  // ---- 输出（g_ = golden，i_ = 重写）----
  wire  g_io_req_ready, i_io_req_ready;
  wire  g_io_req_chanA_valid, i_io_req_chanA_valid;
  wire  [3:0] g_io_req_chanA_bits_opcode, i_io_req_chanA_bits_opcode;
  wire  [47:0] g_io_req_chanA_bits_address, i_io_req_chanA_bits_address;
  wire  g_io_resp_chanD_ready, i_io_resp_chanD_ready;
  wire  g_io_resp_to_lsq_valid, i_io_resp_to_lsq_valid;
  wire  g_io_resp_to_lsq_bits_denied, i_io_resp_to_lsq_bits_denied;
  wire  g_io_resp_to_lsq_bits_corrupt, i_io_resp_to_lsq_bits_corrupt;
  wire  g_io_wfi_wfiSafe, i_io_wfi_wfiSafe;
  CMOUnit u_gold (
    .clock(clock),
    .reset(reset),
    .io_req_ready(g_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_opcode(io_req_bits_opcode),
    .io_req_bits_address(io_req_bits_address),
    .io_req_chanA_ready(io_req_chanA_ready),
    .io_req_chanA_valid(g_io_req_chanA_valid),
    .io_req_chanA_bits_opcode(g_io_req_chanA_bits_opcode),
    .io_req_chanA_bits_address(g_io_req_chanA_bits_address),
    .io_resp_chanD_ready(g_io_resp_chanD_ready),
    .io_resp_chanD_valid(io_resp_chanD_valid),
    .io_resp_chanD_bits_denied(io_resp_chanD_bits_denied),
    .io_resp_chanD_bits_corrupt(io_resp_chanD_bits_corrupt),
    .io_resp_to_lsq_ready(io_resp_to_lsq_ready),
    .io_resp_to_lsq_valid(g_io_resp_to_lsq_valid),
    .io_resp_to_lsq_bits_denied(g_io_resp_to_lsq_bits_denied),
    .io_resp_to_lsq_bits_corrupt(g_io_resp_to_lsq_bits_corrupt),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(g_io_wfi_wfiSafe)
  );
  CMOUnit_xs u_impl (
    .clock(clock),
    .reset(reset),
    .io_req_ready(i_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_opcode(io_req_bits_opcode),
    .io_req_bits_address(io_req_bits_address),
    .io_req_chanA_ready(io_req_chanA_ready),
    .io_req_chanA_valid(i_io_req_chanA_valid),
    .io_req_chanA_bits_opcode(i_io_req_chanA_bits_opcode),
    .io_req_chanA_bits_address(i_io_req_chanA_bits_address),
    .io_resp_chanD_ready(i_io_resp_chanD_ready),
    .io_resp_chanD_valid(io_resp_chanD_valid),
    .io_resp_chanD_bits_denied(io_resp_chanD_bits_denied),
    .io_resp_chanD_bits_corrupt(io_resp_chanD_bits_corrupt),
    .io_resp_to_lsq_ready(io_resp_to_lsq_ready),
    .io_resp_to_lsq_valid(i_io_resp_to_lsq_valid),
    .io_resp_to_lsq_bits_denied(i_io_resp_to_lsq_bits_denied),
    .io_resp_to_lsq_bits_corrupt(i_io_resp_to_lsq_bits_corrupt),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(i_io_wfi_wfiSafe)
  );
  // END GENERATED

  // BEGIN GENERATED(tb-compare)
  logic seen1_io_req_ready = '0, seen0_io_req_ready = '0;
  logic seen1_io_req_chanA_valid = '0, seen0_io_req_chanA_valid = '0;
  logic [3:0] seen1_io_req_chanA_bits_opcode = '0, seen0_io_req_chanA_bits_opcode = '0;
  logic [47:0] seen1_io_req_chanA_bits_address = '0, seen0_io_req_chanA_bits_address = '0;
  logic seen1_io_resp_chanD_ready = '0, seen0_io_resp_chanD_ready = '0;
  logic seen1_io_resp_to_lsq_valid = '0, seen0_io_resp_to_lsq_valid = '0;
  logic seen1_io_resp_to_lsq_bits_denied = '0, seen0_io_resp_to_lsq_bits_denied = '0;
  logic seen1_io_resp_to_lsq_bits_corrupt = '0, seen0_io_resp_to_lsq_bits_corrupt = '0;
  logic seen1_io_wfi_wfiSafe = '0, seen0_io_wfi_wfiSafe = '0;
  task automatic compare_outputs();
    if (g_io_req_ready !== i_io_req_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_ready: g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready);
    end
    seen1_io_req_ready |= g_io_req_ready;
    seen0_io_req_ready |= ~g_io_req_ready;
    if (g_io_req_chanA_valid !== i_io_req_chanA_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_chanA_valid: g=%h i=%h", cyc, g_io_req_chanA_valid, i_io_req_chanA_valid);
    end
    seen1_io_req_chanA_valid |= g_io_req_chanA_valid;
    seen0_io_req_chanA_valid |= ~g_io_req_chanA_valid;
    if (g_io_req_chanA_bits_opcode !== i_io_req_chanA_bits_opcode) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_chanA_bits_opcode: g=%h i=%h", cyc, g_io_req_chanA_bits_opcode, i_io_req_chanA_bits_opcode);
    end
    seen1_io_req_chanA_bits_opcode |= g_io_req_chanA_bits_opcode;
    seen0_io_req_chanA_bits_opcode |= ~g_io_req_chanA_bits_opcode;
    if (g_io_req_chanA_bits_address !== i_io_req_chanA_bits_address) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_chanA_bits_address: g=%h i=%h", cyc, g_io_req_chanA_bits_address, i_io_req_chanA_bits_address);
    end
    seen1_io_req_chanA_bits_address |= g_io_req_chanA_bits_address;
    seen0_io_req_chanA_bits_address |= ~g_io_req_chanA_bits_address;
    if (g_io_resp_chanD_ready !== i_io_resp_chanD_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_chanD_ready: g=%h i=%h", cyc, g_io_resp_chanD_ready, i_io_resp_chanD_ready);
    end
    seen1_io_resp_chanD_ready |= g_io_resp_chanD_ready;
    seen0_io_resp_chanD_ready |= ~g_io_resp_chanD_ready;
    if (g_io_resp_to_lsq_valid !== i_io_resp_to_lsq_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_to_lsq_valid: g=%h i=%h", cyc, g_io_resp_to_lsq_valid, i_io_resp_to_lsq_valid);
    end
    seen1_io_resp_to_lsq_valid |= g_io_resp_to_lsq_valid;
    seen0_io_resp_to_lsq_valid |= ~g_io_resp_to_lsq_valid;
    if (g_io_resp_to_lsq_bits_denied !== i_io_resp_to_lsq_bits_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_to_lsq_bits_denied: g=%h i=%h", cyc, g_io_resp_to_lsq_bits_denied, i_io_resp_to_lsq_bits_denied);
    end
    seen1_io_resp_to_lsq_bits_denied |= g_io_resp_to_lsq_bits_denied;
    seen0_io_resp_to_lsq_bits_denied |= ~g_io_resp_to_lsq_bits_denied;
    if (g_io_resp_to_lsq_bits_corrupt !== i_io_resp_to_lsq_bits_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_to_lsq_bits_corrupt: g=%h i=%h", cyc, g_io_resp_to_lsq_bits_corrupt, i_io_resp_to_lsq_bits_corrupt);
    end
    seen1_io_resp_to_lsq_bits_corrupt |= g_io_resp_to_lsq_bits_corrupt;
    seen0_io_resp_to_lsq_bits_corrupt |= ~g_io_resp_to_lsq_bits_corrupt;
    if (g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_wfi_wfiSafe: g=%h i=%h", cyc, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe);
    end
    seen1_io_wfi_wfiSafe |= g_io_wfi_wfiSafe;
    seen0_io_wfi_wfiSafe |= ~g_io_wfi_wfiSafe;
    checks++;
  endtask
  // 返回从未翻转过的输出端口个数（逐个打印）
  function automatic int report_toggle();
    int bad = 0;
    if (((~seen1_io_req_ready | ~seen0_io_req_ready)) != '0) begin bad++; $display("TOGGLE MISS io_req_ready 1=%h 0=%h", seen1_io_req_ready, seen0_io_req_ready); end
    if (((~seen1_io_req_chanA_valid | ~seen0_io_req_chanA_valid)) != '0) begin bad++; $display("TOGGLE MISS io_req_chanA_valid 1=%h 0=%h", seen1_io_req_chanA_valid, seen0_io_req_chanA_valid); end
    if (((~seen1_io_req_chanA_bits_opcode | ~seen0_io_req_chanA_bits_opcode) & ~4'hc) != '0) begin bad++; $display("TOGGLE MISS io_req_chanA_bits_opcode 1=%h 0=%h", seen1_io_req_chanA_bits_opcode, seen0_io_req_chanA_bits_opcode); end
    if (((~seen1_io_req_chanA_bits_address | ~seen0_io_req_chanA_bits_address)) != '0) begin bad++; $display("TOGGLE MISS io_req_chanA_bits_address 1=%h 0=%h", seen1_io_req_chanA_bits_address, seen0_io_req_chanA_bits_address); end
    if (((~seen1_io_resp_chanD_ready | ~seen0_io_resp_chanD_ready)) != '0) begin bad++; $display("TOGGLE MISS io_resp_chanD_ready 1=%h 0=%h", seen1_io_resp_chanD_ready, seen0_io_resp_chanD_ready); end
    if (((~seen1_io_resp_to_lsq_valid | ~seen0_io_resp_to_lsq_valid)) != '0) begin bad++; $display("TOGGLE MISS io_resp_to_lsq_valid 1=%h 0=%h", seen1_io_resp_to_lsq_valid, seen0_io_resp_to_lsq_valid); end
    if (((~seen1_io_resp_to_lsq_bits_denied | ~seen0_io_resp_to_lsq_bits_denied)) != '0) begin bad++; $display("TOGGLE MISS io_resp_to_lsq_bits_denied 1=%h 0=%h", seen1_io_resp_to_lsq_bits_denied, seen0_io_resp_to_lsq_bits_denied); end
    if (((~seen1_io_resp_to_lsq_bits_corrupt | ~seen0_io_resp_to_lsq_bits_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_resp_to_lsq_bits_corrupt 1=%h 0=%h", seen1_io_resp_to_lsq_bits_corrupt, seen0_io_resp_to_lsq_bits_corrupt); end
    if (((~seen1_io_wfi_wfiSafe | ~seen0_io_wfi_wfiSafe)) != '0) begin bad++; $display("TOGGLE MISS io_wfi_wfiSafe 1=%h 0=%h", seen1_io_wfi_wfiSafe, seen0_io_wfi_wfiSafe); end
    return bad;
  endfunction
  // END GENERATED

  int wfi_len = 0;
  task automatic drive();
    io_req_valid               = ($urandom_range(0, 3) == 0);
    io_req_bits_opcode         = 3'($urandom);
    io_req_bits_address        = {$urandom, $urandom};
    io_req_chanA_ready         = ($urandom_range(0, 2) != 0);
    io_resp_chanD_valid        = ($urandom_range(0, 3) == 0);
    io_resp_chanD_bits_denied  = ($urandom_range(0, 3) == 0);
    io_resp_chanD_bits_corrupt = ($urandom_range(0, 3) == 0);
    io_resp_to_lsq_ready       = ($urandom_range(0, 2) != 0);
    // wfiReq 成段出现：平均每 40 拍开一段，长 1..30 拍
    if (wfi_len > 0) wfi_len--;
    else if ($urandom_range(0, 39) == 0) wfi_len = $urandom_range(1, 30);
    io_wfi_wfiReq = (wfi_len > 0);
  endtask

  task automatic count_cov();
    if (io_req_valid && g_io_req_ready) cov_req_fire++;
    if (io_req_chanA_ready && g_io_req_chanA_valid) cov_a_fire++;
    if (io_resp_chanD_valid && g_io_resp_chanD_ready) begin
      cov_d_fire++;
      if (io_resp_chanD_bits_denied || io_resp_chanD_bits_corrupt) cov_d_err++;
    end
    if (io_resp_chanD_valid && !g_io_resp_chanD_ready) cov_d_ignored++;
    if (io_resp_to_lsq_ready && g_io_resp_to_lsq_valid) cov_resp_fire++;
    if (io_wfi_wfiReq && u_gold.state == 2'h1) cov_wfi_block++;
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    reset = 1;
    drive();
    repeat (5) @(negedge clock);
    reset = 0;
    // 暖机：复位后第一拍必接一条请求，把不复位的 req_opcode/req_address 写定，
    // 之后才开比较窗口（+vcs+initreg+random 下两实例这两个寄存器初值不同，A 通道
    // 地址输出在 valid=0 时也可见）。复位不清这两个寄存器，所以只需暖机一次。
    @(negedge clock);
    drive();
    io_req_valid = 1'b1;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      // 约每 3000 拍打一次异步复位（两侧同时），持续 1..3 拍
      if ($urandom_range(0, 2999) == 0) begin
        reset = 1; cov_reset++;
        #1; compare_outputs();
        repeat ($urandom_range(1, 3)) @(negedge clock);
        reset = 0;
        drive();
      end
      #1;
      compare_outputs();
      count_cov();
    end
    $display("COVERAGE req_fire=%0d a_fire=%0d d_fire=%0d resp_fire=%0d wfi_block=%0d d_err=%0d d_ignored=%0d reset=%0d",
             cov_req_fire, cov_a_fire, cov_d_fire, cov_resp_fire, cov_wfi_block, cov_d_err, cov_d_ignored, cov_reset);
    if (cov_req_fire < COV_MIN)  begin cov_fail++; $display("COV FAIL: req_fire"); end
    if (cov_a_fire < COV_MIN)    begin cov_fail++; $display("COV FAIL: a_fire"); end
    if (cov_d_fire < COV_MIN)    begin cov_fail++; $display("COV FAIL: d_fire"); end
    if (cov_resp_fire < COV_MIN) begin cov_fail++; $display("COV FAIL: resp_fire"); end
    if (cov_wfi_block < COV_MIN) begin cov_fail++; $display("COV FAIL: wfi_block"); end
    if (cov_d_err < COV_MIN)     begin cov_fail++; $display("COV FAIL: d_err"); end
    if (cov_d_ignored < COV_MIN) begin cov_fail++; $display("COV FAIL: d_ignored"); end
    if (NCYCLES >= 100000 && cov_reset < 10) begin cov_fail++; $display("COV FAIL: reset"); end
    cov_fail += report_toggle();
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
