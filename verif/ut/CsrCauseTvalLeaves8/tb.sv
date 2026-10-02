// CsrCauseTvalLeaves8/tb.sv —— 族 E 八变体双例化逐拍比对：
// golden <M>（u_g_*）vs 可读重写 <M>_xs（u_i_*），同一激励。
// 八个变体同构（cause 亚族 = {Interrupt,ExceptionCode} 字段切割，
// tval 亚族 = 整 64 位直通），所以共用一份激励：trap 装载值取
// trap_all = {trap_int, trap_code}，此时八变体的寄存器值应**永远逐位相同**，
// tb 额外做跨变体一致性检查（任一变体接错线立刻失配）。
//
// 激励覆盖：trap 装载 / 软件写 / 两路同拍竞争（按位或合并语义）/ 空闲保持 /
// 周期内异步复位（含复位与写同拍）/ 全 0 全 1 与随机数据角。
// 覆盖闸：每变体 checks/moves 下限 + rdata 64 位每位都见过 0 和 1 +
// 全局 fires 闸（trap 装载/软件写/竞争/复位拍数各有下限）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned COV_MIN, COV_RST, COV_TRAP, COV_SW, COV_BOTH;
  function automatic int unsigned scaled(int unsigned per200k);
    longint unsigned r;
    begin
      // 用 64 位中间量：NCYCLES*per200k 在 20 万拍基准下会溢出 32 位 int
      r = (longint'(NCYCLES) * per200k) / 200000;
      return r > 0 ? int'(r) : 1;
    end
  endfunction

  bit  clock = 0;
  logic reset = 1'b1;
  logic wen = 1'b0;
  logic [63:0] wdata = '0;
  logic tvalid = 1'b0;
  logic tint = 1'b0;
  logic [62:0] tcode = '0;
  logic [63:0] tall = '0;   // 恒等于 {tint, tcode}，喂 tval 亚族

  int errors = 0;
  int checks = 0;
  int cov_fail = 0;

  // 全局 fires / 角覆盖计数
  int cov_trap_only = 0;   // 仅 trap 装载
  int cov_sw_only   = 0;   // 仅软件写
  int cov_both      = 0;   // 同拍竞争（OR 合并）
  int cov_idle      = 0;   // 都不写（保持）
  int cov_rst       = 0;   // 复位拍
  int cov_rst_write = 0;   // 复位与写使能同拍
  int cov_tint1     = 0;   // trap 装载 Interrupt=1
  int cov_tint0     = 0;   // trap 装载 Interrupt=0
  int cov_wdata0    = 0;   // 软件写全 0
  int cov_wdata1    = 0;   // 软件写全 1
  int cov_tall0     = 0;   // trap 装载全 0
  int cov_tall1     = 0;   // trap 装载全 1

  always #5 clock = ~clock;

  // ---- 变体输出（g=golden, i=impl） ----
  wire [63:0] g_mcause_rdata, i_mcause_rdata;
  wire        g_mcause_int,   i_mcause_int;
  wire [62:0] g_mcause_code,  i_mcause_code;
  wire [63:0] g_scause_rdata, i_scause_rdata;
  wire        g_scause_int,   i_scause_int;
  wire [62:0] g_scause_code,  i_scause_code;
  wire [63:0] g_vscause_rdata, i_vscause_rdata;
  wire        g_vscause_int,   i_vscause_int;
  wire [62:0] g_vscause_code,  i_vscause_code;
  wire [63:0] g_mncause_rdata, i_mncause_rdata;
  wire        g_mncause_int,   i_mncause_int;
  wire [62:0] g_mncause_code,  i_mncause_code;
  wire [63:0] g_mtval_rdata,  i_mtval_rdata,  g_mtval_all,  i_mtval_all;
  wire [63:0] g_stval_rdata,  i_stval_rdata,  g_stval_all,  i_stval_all;
  wire [63:0] g_vstval_rdata, i_vstval_rdata, g_vstval_all, i_vstval_all;
  wire [63:0] g_mtval2_rdata, i_mtval2_rdata, g_mtval2_all, i_mtval2_all;

  // ---- cause 亚族（trap 口前缀各不相同） ----
  McauseModule u_g_mcause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_mcause_rdata), .regOut_Interrupt(g_mcause_int),
    .regOut_ExceptionCode(g_mcause_code),
    .trapToM_mcause_valid(tvalid), .trapToM_mcause_bits_Interrupt(tint),
    .trapToM_mcause_bits_ExceptionCode(tcode));
  McauseModule_xs u_i_mcause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_mcause_rdata), .regOut_Interrupt(i_mcause_int),
    .regOut_ExceptionCode(i_mcause_code),
    .trapToM_mcause_valid(tvalid), .trapToM_mcause_bits_Interrupt(tint),
    .trapToM_mcause_bits_ExceptionCode(tcode));
  ScauseModule u_g_scause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_scause_rdata), .regOut_Interrupt(g_scause_int),
    .regOut_ExceptionCode(g_scause_code),
    .trapToHS_scause_valid(tvalid), .trapToHS_scause_bits_Interrupt(tint),
    .trapToHS_scause_bits_ExceptionCode(tcode));
  ScauseModule_xs u_i_scause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_scause_rdata), .regOut_Interrupt(i_scause_int),
    .regOut_ExceptionCode(i_scause_code),
    .trapToHS_scause_valid(tvalid), .trapToHS_scause_bits_Interrupt(tint),
    .trapToHS_scause_bits_ExceptionCode(tcode));
  VScauseModule u_g_vscause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_vscause_rdata), .regOut_Interrupt(g_vscause_int),
    .regOut_ExceptionCode(g_vscause_code),
    .trapToVS_vscause_valid(tvalid), .trapToVS_vscause_bits_Interrupt(tint),
    .trapToVS_vscause_bits_ExceptionCode(tcode));
  VScauseModule_xs u_i_vscause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_vscause_rdata), .regOut_Interrupt(i_vscause_int),
    .regOut_ExceptionCode(i_vscause_code),
    .trapToVS_vscause_valid(tvalid), .trapToVS_vscause_bits_Interrupt(tint),
    .trapToVS_vscause_bits_ExceptionCode(tcode));
  MncauseModule u_g_mncause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_mncause_rdata), .regOut_Interrupt(g_mncause_int),
    .regOut_ExceptionCode(g_mncause_code),
    .trapToMN_mncause_valid(tvalid), .trapToMN_mncause_bits_Interrupt(tint),
    .trapToMN_mncause_bits_ExceptionCode(tcode));
  MncauseModule_xs u_i_mncause (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_mncause_rdata), .regOut_Interrupt(i_mncause_int),
    .regOut_ExceptionCode(i_mncause_code),
    .trapToMN_mncause_valid(tvalid), .trapToMN_mncause_bits_Interrupt(tint),
    .trapToMN_mncause_bits_ExceptionCode(tcode));

  // ---- tval 亚族 ----
  MtvalModule u_g_mtval (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_mtval_rdata), .regOut_ALL(g_mtval_all),
    .trapToM_mtval_valid(tvalid), .trapToM_mtval_bits_ALL(tall));
  MtvalModule_xs u_i_mtval (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_mtval_rdata), .regOut_ALL(i_mtval_all),
    .trapToM_mtval_valid(tvalid), .trapToM_mtval_bits_ALL(tall));
  StvalModule u_g_stval (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_stval_rdata), .regOut_ALL(g_stval_all),
    .trapToHS_stval_valid(tvalid), .trapToHS_stval_bits_ALL(tall));
  StvalModule_xs u_i_stval (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_stval_rdata), .regOut_ALL(i_stval_all),
    .trapToHS_stval_valid(tvalid), .trapToHS_stval_bits_ALL(tall));
  VStvalModule u_g_vstval (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_vstval_rdata), .regOut_ALL(g_vstval_all),
    .trapToVS_vstval_valid(tvalid), .trapToVS_vstval_bits_ALL(tall));
  VStvalModule_xs u_i_vstval (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_vstval_rdata), .regOut_ALL(i_vstval_all),
    .trapToVS_vstval_valid(tvalid), .trapToVS_vstval_bits_ALL(tall));
  Mtval2Module u_g_mtval2 (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(g_mtval2_rdata), .regOut_ALL(g_mtval2_all),
    .trapToM_mtval2_valid(tvalid), .trapToM_mtval2_bits_ALL(tall));
  Mtval2Module_xs u_i_mtval2 (
    .clock(clock), .reset(reset), .w_wen(wen), .w_wdata(wdata),
    .rdata(i_mtval2_rdata), .regOut_ALL(i_mtval2_all),
    .trapToM_mtval2_valid(tvalid), .trapToM_mtval2_bits_ALL(tall));

  // ---- 每变体位覆盖（取 golden 侧，逐拍比已保证两侧相等） ----
  logic [63:0] ones [8], zeros [8], prev [8];
  int moves [8];

  task automatic check_outputs();
    checks++;
    // 双例化逐拍比：每个变体的全部输出
    if ({g_mcause_rdata, g_mcause_int, g_mcause_code}
        !== {i_mcause_rdata, i_mcause_int, i_mcause_code}) begin
      errors++;
      if (errors <= 20)
        $display("MISMATCH Mcause: g=%h/%b/%h i=%h/%b/%h",
                 g_mcause_rdata, g_mcause_int, g_mcause_code,
                 i_mcause_rdata, i_mcause_int, i_mcause_code);
    end
    if ({g_scause_rdata, g_scause_int, g_scause_code}
        !== {i_scause_rdata, i_scause_int, i_scause_code}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH Scause");
    end
    if ({g_vscause_rdata, g_vscause_int, g_vscause_code}
        !== {i_vscause_rdata, i_vscause_int, i_vscause_code}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH VScause");
    end
    if ({g_mncause_rdata, g_mncause_int, g_mncause_code}
        !== {i_mncause_rdata, i_mncause_int, i_mncause_code}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH Mncause");
    end
    if ({g_mtval_rdata, g_mtval_all} !== {i_mtval_rdata, i_mtval_all}) begin
      errors++;
      if (errors <= 20)
        $display("MISMATCH Mtval: g=%h/%h i=%h/%h",
                 g_mtval_rdata, g_mtval_all, i_mtval_rdata, i_mtval_all);
    end
    if ({g_stval_rdata, g_stval_all} !== {i_stval_rdata, i_stval_all}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH Stval");
    end
    if ({g_vstval_rdata, g_vstval_all} !== {i_vstval_rdata, i_vstval_all}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH VStval");
    end
    if ({g_mtval2_rdata, g_mtval2_all} !== {i_mtval2_rdata, i_mtval2_all}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH Mtval2");
    end
    // 跨变体一致性：同激励下八个值必须逐位相同
    if ({g_scause_rdata, g_vscause_rdata, g_mncause_rdata,
         g_mtval_rdata, g_stval_rdata, g_vstval_rdata, g_mtval2_rdata}
        !== {7{g_mcause_rdata}}) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cross-variant golden");
    end
    // 字段自洽：impl 侧 regOut 必须是 rdata 的切割/镜像
    if (i_mcause_rdata !== {i_mcause_int, i_mcause_code}
        || i_scause_rdata !== {i_scause_int, i_scause_code}
        || i_vscause_rdata !== {i_vscause_int, i_vscause_code}
        || i_mncause_rdata !== {i_mncause_int, i_mncause_code}
        || i_mtval_rdata !== i_mtval_all || i_stval_rdata !== i_stval_all
        || i_vstval_rdata !== i_vstval_all || i_mtval2_rdata !== i_mtval2_all) begin
      errors++;
      if (errors <= 20) $display("MISMATCH impl field slice");
    end
    // 位覆盖累计（golden 侧）
    begin
      logic [63:0] v [8];
      v[0]=g_mcause_rdata; v[1]=g_scause_rdata; v[2]=g_vscause_rdata; v[3]=g_mncause_rdata;
      v[4]=g_mtval_rdata;  v[5]=g_stval_rdata;  v[6]=g_vstval_rdata;  v[7]=g_mtval2_rdata;
      for (int k = 0; k < 8; k++) begin
        ones[k]  |= v[k];
        zeros[k] |= ~v[k];
        if (v[k] !== prev[k]) moves[k]++;
        prev[k] = v[k];
      end
    end
  endtask

  task automatic sample_fires();
    if (reset) begin
      cov_rst++;
      if (wen || tvalid) cov_rst_write++;
    end
    else begin
      if (wen && tvalid)  cov_both++;
      else if (wen)       cov_sw_only++;
      else if (tvalid)    cov_trap_only++;
      else                cov_idle++;
      if (tvalid && tint)  cov_tint1++;
      if (tvalid && !tint) cov_tint0++;
      if (wen && wdata == '0)     cov_wdata0++;
      if (wen && wdata == '1)     cov_wdata1++;
      if (tvalid && tall == '0)   cov_tall0++;
      if (tvalid && tall == '1)   cov_tall1++;
    end
  endtask

  task automatic drive_stim(int unsigned c);
    int k;
    begin
      // 周期性插一段 2 拍复位（含复位与写同拍），其余时间复位保持 0
      reset = (c % 997 == 500 || c % 997 == 501);
      // 写口组合：3/10 空闲、3/10 仅软件写、2/10 仅 trap、2/10 同拍竞争
      k = $urandom_range(0, 9);
      wen    = (k inside {3,4,5,8,9});
      tvalid = (k inside {6,7,8,9});
      // 数据角：全 0 / 全 1 / 随机 三等分
      k = $urandom_range(0, 5);
      if (k == 0)      wdata = '0;
      else if (k == 1) wdata = '1;
      else             wdata = {$urandom, $urandom};
      k = $urandom_range(0, 5);
      if (k == 0)      {tint, tcode} = '0;
      else if (k == 1) {tint, tcode} = '1;
      else             {tint, tcode} = {$urandom, $urandom};
      tall = {tint, tcode};
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    COV_MIN  = scaled(50000);
    COV_RST  = scaled(300);
    COV_TRAP = scaled(20000);
    COV_SW   = scaled(20000);
    COV_BOTH = scaled(20000);
    for (int k = 0; k < 8; k++) begin
      ones[k] = '0; zeros[k] = '0; prev[k] = 'x; moves[k] = 0;
    end
    // 暖机：先拉 5 拍复位，两侧从确定状态出发（+vcs+initreg+random 那轮尤其要）
    reset = 1'b1;
    repeat (5) @(negedge clock);
    reset = 1'b0;

    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clock);   // 输出在 posedge 变，negedge 稳定：先比对上一拍结果，再换激励
      check_outputs();
      sample_fires();
      drive_stim(c);
    end

    $display("CsrCauseTvalLeaves8 UT: checks=%0d errors=%0d", checks, errors);
    $display("  moves: %0d %0d %0d %0d %0d %0d %0d %0d",
             moves[0], moves[1], moves[2], moves[3], moves[4], moves[5], moves[6], moves[7]);
    $display("  fires: trap=%0d sw=%0d both=%0d idle=%0d rst=%0d rst&wr=%0d tint1=%0d tint0=%0d",
             cov_trap_only, cov_sw_only, cov_both, cov_idle, cov_rst, cov_rst_write,
             cov_tint1, cov_tint0);
    $display("  corners: wdata0=%0d wdata1=%0d tall0=%0d tall1=%0d",
             cov_wdata0, cov_wdata1, cov_tall0, cov_tall1);
    // 每拍一次 check_outputs 同时覆盖全部 8 个变体，checks 按拍计
    if (checks < COV_MIN) begin
      $display("COVERAGE FAIL: 有效比对 %0d 次 (需 >= %0d)", checks, COV_MIN);
      cov_fail++;
    end
    for (int k = 0; k < 8; k++) begin
      if (moves[k] < COV_MIN) begin
        $display("COVERAGE FAIL: 变体 %0d 输出只变化 %0d 次 (需 >= %0d)", k, moves[k], COV_MIN);
        cov_fail++;
      end
      if (!(&ones[k]) || !(&zeros[k])) begin
        $display("COVERAGE FAIL: 变体 %0d 有 rdata 位从未观察到 1 或 0", k);
        cov_fail++;
      end
    end
    if (cov_trap_only < COV_TRAP) begin
      $display("COVERAGE FAIL: 仅 trap 装载 %0d 次 (需 >= %0d)", cov_trap_only, COV_TRAP);
      cov_fail++;
    end
    if (cov_sw_only < COV_SW) begin
      $display("COVERAGE FAIL: 仅软件写 %0d 次 (需 >= %0d)", cov_sw_only, COV_SW);
      cov_fail++;
    end
    if (cov_both < COV_BOTH) begin
      $display("COVERAGE FAIL: 同拍竞争 %0d 次 (需 >= %0d)", cov_both, COV_BOTH);
      cov_fail++;
    end
    if (cov_rst < COV_RST || cov_rst_write == 0) begin
      $display("COVERAGE FAIL: 复位拍 %0d / 复位与写同拍 %0d", cov_rst, cov_rst_write);
      cov_fail++;
    end
    if (cov_tint1 < scaled(5000) || cov_tint0 < scaled(5000)) begin
      $display("COVERAGE FAIL: trap Interrupt 位两极覆盖不足 (%0d/%0d)", cov_tint1, cov_tint0);
      cov_fail++;
    end
    if (cov_wdata0 == 0 || cov_wdata1 == 0 || cov_tall0 == 0 || cov_tall1 == 0) begin
      $display("COVERAGE FAIL: 全 0/全 1 数据角没打到 (%0d/%0d/%0d/%0d)",
               cov_wdata0, cov_wdata1, cov_tall0, cov_tall1);
      cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
