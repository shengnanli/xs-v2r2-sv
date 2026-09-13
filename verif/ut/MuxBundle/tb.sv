// MuxBundle 双例化逐拍比对：golden MuxBundle vs 可读重写 MuxBundle_xs。
// 被测：ICacheMissUnit 的 10 路预取 Acquire 出口 —— 按 io_sel 选一路接到出口，
//   并把 source id 打成 sel+4（预取 MSHR 在 TileLink source 空间占 4..13）。
// 激励：sel 覆盖 0..15（**含 10..15 越界值**：golden 三元链在越界时退化到第 0 路，
//   FM 比全状态空间，这段必须一起测），in_valid 位图与载荷逐位随机，
//   out_ready 一半概率为 0。
// 覆盖闸：(1) 有效比对 >= COV_MIN；(2) sel 的 0..9 **每个取值**各 >= COV_MIN；
//   (3) sel 越界（>=10）>= COV_MIN；(4) out_ready=0 >= COV_MIN；
//   (5) 被选中那一路 valid=1 与 =0 各 >= COV_MIN；
//   (6) 每个输出位都被观察到过 1 和 0。任何一项不足即 TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  logic [3:0]  sel;
  logic        out_ready;
  logic [9:0]  in_valid;          // 位 9 = 第 0 路
  logic [559:0] in_bits;         // 与 in_valid 同序，每路 {addr 48b, vSetIdx 8b}
  wire  [9:0]  g_ready, i_ready;
  wire         g_out_valid, i_out_valid;
  wire  [3:0]  g_out_source, i_out_source;
  wire  [47:0] g_out_addr, i_out_addr;
  wire  [7:0]  g_out_vset, i_out_vset;

  MuxBundle u_g (
    .io_sel(sel),
    .io_in_0_ready(g_ready[9]),
    .io_in_0_valid(in_valid[9]),
    .io_in_0_bits_acquire_address(in_bits[559:512]),
    .io_in_0_bits_vSetIdx(in_bits[511:504]),
    .io_in_1_ready(g_ready[8]),
    .io_in_1_valid(in_valid[8]),
    .io_in_1_bits_acquire_address(in_bits[503:456]),
    .io_in_1_bits_vSetIdx(in_bits[455:448]),
    .io_in_2_ready(g_ready[7]),
    .io_in_2_valid(in_valid[7]),
    .io_in_2_bits_acquire_address(in_bits[447:400]),
    .io_in_2_bits_vSetIdx(in_bits[399:392]),
    .io_in_3_ready(g_ready[6]),
    .io_in_3_valid(in_valid[6]),
    .io_in_3_bits_acquire_address(in_bits[391:344]),
    .io_in_3_bits_vSetIdx(in_bits[343:336]),
    .io_in_4_ready(g_ready[5]),
    .io_in_4_valid(in_valid[5]),
    .io_in_4_bits_acquire_address(in_bits[335:288]),
    .io_in_4_bits_vSetIdx(in_bits[287:280]),
    .io_in_5_ready(g_ready[4]),
    .io_in_5_valid(in_valid[4]),
    .io_in_5_bits_acquire_address(in_bits[279:232]),
    .io_in_5_bits_vSetIdx(in_bits[231:224]),
    .io_in_6_ready(g_ready[3]),
    .io_in_6_valid(in_valid[3]),
    .io_in_6_bits_acquire_address(in_bits[223:176]),
    .io_in_6_bits_vSetIdx(in_bits[175:168]),
    .io_in_7_ready(g_ready[2]),
    .io_in_7_valid(in_valid[2]),
    .io_in_7_bits_acquire_address(in_bits[167:120]),
    .io_in_7_bits_vSetIdx(in_bits[119:112]),
    .io_in_8_ready(g_ready[1]),
    .io_in_8_valid(in_valid[1]),
    .io_in_8_bits_acquire_address(in_bits[111:64]),
    .io_in_8_bits_vSetIdx(in_bits[63:56]),
    .io_in_9_ready(g_ready[0]),
    .io_in_9_valid(in_valid[0]),
    .io_in_9_bits_acquire_address(in_bits[55:8]),
    .io_in_9_bits_vSetIdx(in_bits[7:0]),
    .io_out_ready(out_ready),
    .io_out_valid(g_out_valid),
    .io_out_bits_acquire_source(g_out_source),
    .io_out_bits_acquire_address(g_out_addr),
    .io_out_bits_vSetIdx(g_out_vset)
  );

  MuxBundle_xs u_i (
    .io_sel(sel),
    .io_in_0_ready(i_ready[9]),
    .io_in_0_valid(in_valid[9]),
    .io_in_0_bits_acquire_address(in_bits[559:512]),
    .io_in_0_bits_vSetIdx(in_bits[511:504]),
    .io_in_1_ready(i_ready[8]),
    .io_in_1_valid(in_valid[8]),
    .io_in_1_bits_acquire_address(in_bits[503:456]),
    .io_in_1_bits_vSetIdx(in_bits[455:448]),
    .io_in_2_ready(i_ready[7]),
    .io_in_2_valid(in_valid[7]),
    .io_in_2_bits_acquire_address(in_bits[447:400]),
    .io_in_2_bits_vSetIdx(in_bits[399:392]),
    .io_in_3_ready(i_ready[6]),
    .io_in_3_valid(in_valid[6]),
    .io_in_3_bits_acquire_address(in_bits[391:344]),
    .io_in_3_bits_vSetIdx(in_bits[343:336]),
    .io_in_4_ready(i_ready[5]),
    .io_in_4_valid(in_valid[5]),
    .io_in_4_bits_acquire_address(in_bits[335:288]),
    .io_in_4_bits_vSetIdx(in_bits[287:280]),
    .io_in_5_ready(i_ready[4]),
    .io_in_5_valid(in_valid[4]),
    .io_in_5_bits_acquire_address(in_bits[279:232]),
    .io_in_5_bits_vSetIdx(in_bits[231:224]),
    .io_in_6_ready(i_ready[3]),
    .io_in_6_valid(in_valid[3]),
    .io_in_6_bits_acquire_address(in_bits[223:176]),
    .io_in_6_bits_vSetIdx(in_bits[175:168]),
    .io_in_7_ready(i_ready[2]),
    .io_in_7_valid(in_valid[2]),
    .io_in_7_bits_acquire_address(in_bits[167:120]),
    .io_in_7_bits_vSetIdx(in_bits[119:112]),
    .io_in_8_ready(i_ready[1]),
    .io_in_8_valid(in_valid[1]),
    .io_in_8_bits_acquire_address(in_bits[111:64]),
    .io_in_8_bits_vSetIdx(in_bits[63:56]),
    .io_in_9_ready(i_ready[0]),
    .io_in_9_valid(in_valid[0]),
    .io_in_9_bits_acquire_address(in_bits[55:8]),
    .io_in_9_bits_vSetIdx(in_bits[7:0]),
    .io_out_ready(out_ready),
    .io_out_valid(i_out_valid),
    .io_out_bits_acquire_source(i_out_source),
    .io_out_bits_acquire_address(i_out_addr),
    .io_out_bits_vSetIdx(i_out_vset)
  );

  wire [69:0] g_out = {g_ready, g_out_valid, g_out_source, g_out_addr, g_out_vset};
  wire [69:0] i_out = {i_ready, i_out_valid, i_out_source, i_out_addr, i_out_vset};

  int c_sel [16];
  int c_oor, c_stall, c_selvalid, c_selidle;
  logic [69:0] ones, zeros;

  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    // 一半概率落在合法的 0..9，一半概率全 4 位随机（因此常打到越界的 10..15）
    sel = ($urandom_range(0, 1)) ? 4'($urandom_range(0, 9)) : 4'($urandom);
    out_ready = ($urandom_range(0, 1) == 1);
    for (int b = 0; b < 10; b++)      in_valid[b] = 1'($urandom);
    for (int b = 0; b < 560; b++)   in_bits[b]  = 1'($urandom);
  endtask

  task automatic check_outputs();
    int eff;
    if ($isunknown(g_out)) return;
    checks++;
    ones  |= g_out;
    zeros |= ~g_out;
    c_sel[sel]++;
    if (sel > 9) c_oor++;
    if (!out_ready) c_stall++;
    eff = (sel > 9) ? 0 : int'(sel);
    if (in_valid[9 - eff]) c_selvalid++; else c_selidle++;
    if (g_out !== i_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] MISMATCH MuxBundle sel=%0d g=%0h i=%0h", $time, sel, g_out, i_out);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    sel = '0; out_ready = 0; in_valid = '0; in_bits = '0;
    ones = '0; zeros = '0; c_oor = 0; c_stall = 0; c_selvalid = 0; c_selidle = 0;
    for (int k = 0; k < 16; k++) c_sel[k] = 0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("MuxBundle checks=%0d errors=%0d", checks, errors);
    $write("  sel 分布=");
    for (int k = 0; k < 16; k++) $write("%0d ", c_sel[k]);
    $display("oor=%0d stall=%0d selvalid=%0d selidle=%0d ones=%0d/70 zeros=%0d/70",
             c_oor, c_stall, c_selvalid, c_selidle, $countones(ones), $countones(zeros));
    cov_fail += cov_short("MuxBundle checks", checks)
              + cov_short("MuxBundle sel 越界", c_oor)
              + cov_short("MuxBundle out_ready=0", c_stall)
              + cov_short("MuxBundle 选中路 valid=1", c_selvalid)
              + cov_short("MuxBundle 选中路 valid=0", c_selidle);
    for (int k = 0; k < 10; k++)
      cov_fail += cov_short($sformatf("MuxBundle sel=%0d", k), c_sel[k]);
    if (!(&ones) || !(&zeros)) begin
      $display("COVERAGE FAIL: MuxBundle 有输出位从未观察到 1 或 0 (ones=%0h zeros=%0h)",
               ones, zeros);
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
