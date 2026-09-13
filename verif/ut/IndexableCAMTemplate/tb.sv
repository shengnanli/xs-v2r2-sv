// 自动生成：verif/ut/IndexableCAMTemplate/gen.py —— 勿手改
// IndexableCAMTemplate 家族 5 变体双例化逐拍比对：
//   golden <V> vs 可读重写 <V>_xs（同一个 xs_IndexableCAMTemplate_core 设不同参）。
// 被测语义：写口按索引写入条目（同步），读口把查询键与全部条目并行比较（组合），
//   输出逐条目命中位图。条目寄存器无复位，上电为 X —— 故先做一轮 warmup 把每个
//   变体的每个条目都写一遍，之后两侧才有可比的定值。
// 覆盖闸（小模块最容易假绿）：每个变体都必须
//   (1) 每个条目索引至少被写过一次；
//   (2) 命中（match != 0）与未命中（match == 0）各至少 COV_MIN 次；
//   (3) 有效比对次数 checks 至少 COV_MIN 次。
//   任何一项为 0 / 不足即判 FAIL，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 500;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  // ---- IndexableCAMTemplate: 键 9 位 / 条目 8 项 / 索引 3 位 ----
  logic            cam_clock;
  logic [8:0] cam_rkey;
  logic            cam_wvalid;
  logic [8:0] cam_wkey;
  logic [2:0] cam_widx;
  wire  [7:0] g_cam_match;
  wire  [7:0] i_cam_match;
  int   cam_checks, cam_hit, cam_miss;
  logic [7:0] cam_written;

  IndexableCAMTemplate u_g_cam (
    .clock             (cam_clock),
    .io_r_req_0_idx    (cam_rkey),
    .io_r_resp_0_0    (g_cam_match[0]),
    .io_r_resp_0_1    (g_cam_match[1]),
    .io_r_resp_0_2    (g_cam_match[2]),
    .io_r_resp_0_3    (g_cam_match[3]),
    .io_r_resp_0_4    (g_cam_match[4]),
    .io_r_resp_0_5    (g_cam_match[5]),
    .io_r_resp_0_6    (g_cam_match[6]),
    .io_r_resp_0_7    (g_cam_match[7]),
    .io_w_valid        (cam_wvalid),
    .io_w_bits_data_idx(cam_wkey),
    .io_w_bits_index   (cam_widx)
  );

  IndexableCAMTemplate_xs u_i_cam (
    .clock             (cam_clock),
    .io_r_req_0_idx    (cam_rkey),
    .io_r_resp_0_0    (i_cam_match[0]),
    .io_r_resp_0_1    (i_cam_match[1]),
    .io_r_resp_0_2    (i_cam_match[2]),
    .io_r_resp_0_3    (i_cam_match[3]),
    .io_r_resp_0_4    (i_cam_match[4]),
    .io_r_resp_0_5    (i_cam_match[5]),
    .io_r_resp_0_6    (i_cam_match[6]),
    .io_r_resp_0_7    (i_cam_match[7]),
    .io_w_valid        (cam_wvalid),
    .io_w_bits_data_idx(cam_wkey),
    .io_w_bits_index   (cam_widx)
  );

  // ---- IndexableCAMTemplate_32: 键 11 位 / 条目 8 项 / 索引 3 位 ----
  logic            cam_32_clock;
  logic [10:0] cam_32_rkey;
  logic            cam_32_wvalid;
  logic [10:0] cam_32_wkey;
  logic [2:0] cam_32_widx;
  wire  [7:0] g_cam_32_match;
  wire  [7:0] i_cam_32_match;
  int   cam_32_checks, cam_32_hit, cam_32_miss;
  logic [7:0] cam_32_written;

  IndexableCAMTemplate_32 u_g_cam_32 (
    .clock             (cam_32_clock),
    .io_r_req_0_idx    (cam_32_rkey),
    .io_r_resp_0_0    (g_cam_32_match[0]),
    .io_r_resp_0_1    (g_cam_32_match[1]),
    .io_r_resp_0_2    (g_cam_32_match[2]),
    .io_r_resp_0_3    (g_cam_32_match[3]),
    .io_r_resp_0_4    (g_cam_32_match[4]),
    .io_r_resp_0_5    (g_cam_32_match[5]),
    .io_r_resp_0_6    (g_cam_32_match[6]),
    .io_r_resp_0_7    (g_cam_32_match[7]),
    .io_w_valid        (cam_32_wvalid),
    .io_w_bits_data_idx(cam_32_wkey),
    .io_w_bits_index   (cam_32_widx)
  );

  IndexableCAMTemplate_32_xs u_i_cam_32 (
    .clock             (cam_32_clock),
    .io_r_req_0_idx    (cam_32_rkey),
    .io_r_resp_0_0    (i_cam_32_match[0]),
    .io_r_resp_0_1    (i_cam_32_match[1]),
    .io_r_resp_0_2    (i_cam_32_match[2]),
    .io_r_resp_0_3    (i_cam_32_match[3]),
    .io_r_resp_0_4    (i_cam_32_match[4]),
    .io_r_resp_0_5    (i_cam_32_match[5]),
    .io_r_resp_0_6    (i_cam_32_match[6]),
    .io_r_resp_0_7    (i_cam_32_match[7]),
    .io_w_valid        (cam_32_wvalid),
    .io_w_bits_data_idx(cam_32_wkey),
    .io_w_bits_index   (cam_32_widx)
  );

  // ---- IndexableCAMTemplate_33: 键 8 位 / 条目 16 项 / 索引 4 位 ----
  logic            cam_33_clock;
  logic [7:0] cam_33_rkey;
  logic            cam_33_wvalid;
  logic [7:0] cam_33_wkey;
  logic [3:0] cam_33_widx;
  wire  [15:0] g_cam_33_match;
  wire  [15:0] i_cam_33_match;
  int   cam_33_checks, cam_33_hit, cam_33_miss;
  logic [15:0] cam_33_written;

  IndexableCAMTemplate_33 u_g_cam_33 (
    .clock             (cam_33_clock),
    .io_r_req_0_idx    (cam_33_rkey),
    .io_r_resp_0_0    (g_cam_33_match[0]),
    .io_r_resp_0_1    (g_cam_33_match[1]),
    .io_r_resp_0_2    (g_cam_33_match[2]),
    .io_r_resp_0_3    (g_cam_33_match[3]),
    .io_r_resp_0_4    (g_cam_33_match[4]),
    .io_r_resp_0_5    (g_cam_33_match[5]),
    .io_r_resp_0_6    (g_cam_33_match[6]),
    .io_r_resp_0_7    (g_cam_33_match[7]),
    .io_r_resp_0_8    (g_cam_33_match[8]),
    .io_r_resp_0_9    (g_cam_33_match[9]),
    .io_r_resp_0_10   (g_cam_33_match[10]),
    .io_r_resp_0_11   (g_cam_33_match[11]),
    .io_r_resp_0_12   (g_cam_33_match[12]),
    .io_r_resp_0_13   (g_cam_33_match[13]),
    .io_r_resp_0_14   (g_cam_33_match[14]),
    .io_r_resp_0_15   (g_cam_33_match[15]),
    .io_w_valid        (cam_33_wvalid),
    .io_w_bits_data_idx(cam_33_wkey),
    .io_w_bits_index   (cam_33_widx)
  );

  IndexableCAMTemplate_33_xs u_i_cam_33 (
    .clock             (cam_33_clock),
    .io_r_req_0_idx    (cam_33_rkey),
    .io_r_resp_0_0    (i_cam_33_match[0]),
    .io_r_resp_0_1    (i_cam_33_match[1]),
    .io_r_resp_0_2    (i_cam_33_match[2]),
    .io_r_resp_0_3    (i_cam_33_match[3]),
    .io_r_resp_0_4    (i_cam_33_match[4]),
    .io_r_resp_0_5    (i_cam_33_match[5]),
    .io_r_resp_0_6    (i_cam_33_match[6]),
    .io_r_resp_0_7    (i_cam_33_match[7]),
    .io_r_resp_0_8    (i_cam_33_match[8]),
    .io_r_resp_0_9    (i_cam_33_match[9]),
    .io_r_resp_0_10   (i_cam_33_match[10]),
    .io_r_resp_0_11   (i_cam_33_match[11]),
    .io_r_resp_0_12   (i_cam_33_match[12]),
    .io_r_resp_0_13   (i_cam_33_match[13]),
    .io_r_resp_0_14   (i_cam_33_match[14]),
    .io_r_resp_0_15   (i_cam_33_match[15]),
    .io_w_valid        (cam_33_wvalid),
    .io_w_bits_data_idx(cam_33_wkey),
    .io_w_bits_index   (cam_33_widx)
  );

  // ---- IndexableCAMTemplate_41: 键 8 位 / 条目 4 项 / 索引 2 位 ----
  logic            cam_41_clock;
  logic [7:0] cam_41_rkey;
  logic            cam_41_wvalid;
  logic [7:0] cam_41_wkey;
  logic [1:0] cam_41_widx;
  wire  [3:0] g_cam_41_match;
  wire  [3:0] i_cam_41_match;
  int   cam_41_checks, cam_41_hit, cam_41_miss;
  logic [3:0] cam_41_written;

  IndexableCAMTemplate_41 u_g_cam_41 (
    .clock             (cam_41_clock),
    .io_r_req_0_idx    (cam_41_rkey),
    .io_r_resp_0_0    (g_cam_41_match[0]),
    .io_r_resp_0_1    (g_cam_41_match[1]),
    .io_r_resp_0_2    (g_cam_41_match[2]),
    .io_r_resp_0_3    (g_cam_41_match[3]),
    .io_w_valid        (cam_41_wvalid),
    .io_w_bits_data_idx(cam_41_wkey),
    .io_w_bits_index   (cam_41_widx)
  );

  IndexableCAMTemplate_41_xs u_i_cam_41 (
    .clock             (cam_41_clock),
    .io_r_req_0_idx    (cam_41_rkey),
    .io_r_resp_0_0    (i_cam_41_match[0]),
    .io_r_resp_0_1    (i_cam_41_match[1]),
    .io_r_resp_0_2    (i_cam_41_match[2]),
    .io_r_resp_0_3    (i_cam_41_match[3]),
    .io_w_valid        (cam_41_wvalid),
    .io_w_bits_data_idx(cam_41_wkey),
    .io_w_bits_index   (cam_41_widx)
  );

  // ---- IndexableCAMTemplate_43: 键 9 位 / 条目 4 项 / 索引 2 位 ----
  logic            cam_43_clock;
  logic [8:0] cam_43_rkey;
  logic            cam_43_wvalid;
  logic [8:0] cam_43_wkey;
  logic [1:0] cam_43_widx;
  wire  [3:0] g_cam_43_match;
  wire  [3:0] i_cam_43_match;
  int   cam_43_checks, cam_43_hit, cam_43_miss;
  logic [3:0] cam_43_written;

  IndexableCAMTemplate_43 u_g_cam_43 (
    .clock             (cam_43_clock),
    .io_r_req_0_idx    (cam_43_rkey),
    .io_r_resp_0_0    (g_cam_43_match[0]),
    .io_r_resp_0_1    (g_cam_43_match[1]),
    .io_r_resp_0_2    (g_cam_43_match[2]),
    .io_r_resp_0_3    (g_cam_43_match[3]),
    .io_w_valid        (cam_43_wvalid),
    .io_w_bits_data_idx(cam_43_wkey),
    .io_w_bits_index   (cam_43_widx)
  );

  IndexableCAMTemplate_43_xs u_i_cam_43 (
    .clock             (cam_43_clock),
    .io_r_req_0_idx    (cam_43_rkey),
    .io_r_resp_0_0    (i_cam_43_match[0]),
    .io_r_resp_0_1    (i_cam_43_match[1]),
    .io_r_resp_0_2    (i_cam_43_match[2]),
    .io_r_resp_0_3    (i_cam_43_match[3]),
    .io_w_valid        (cam_43_wvalid),
    .io_w_bits_data_idx(cam_43_wkey),
    .io_w_bits_index   (cam_43_widx)
  );

  // 所有变体共用同一个时钟沿（同一个 clock 网）

  assign cam_clock = clock;
  assign cam_32_clock = clock;
  assign cam_33_clock = clock;
  assign cam_41_clock = clock;
  assign cam_43_clock = clock;


  localparam int KEY_POOL = 24;   // 键池比最大条目数略大：随机键既常命中也常落空
  int cov_fail = 0;

  task automatic drive_random_inputs();
    // IndexableCAMTemplate
    cam_wvalid = ($urandom_range(0, 3) != 0);
    cam_widx   = 3'($urandom);
    cam_wkey   = 9'($urandom_range(0, KEY_POOL - 1));
    cam_rkey   = 9'($urandom_range(0, KEY_POOL - 1));
    if (cam_wvalid) cam_written[cam_widx] = 1'b1;
    // IndexableCAMTemplate_32
    cam_32_wvalid = ($urandom_range(0, 3) != 0);
    cam_32_widx   = 3'($urandom);
    cam_32_wkey   = 11'($urandom_range(0, KEY_POOL - 1));
    cam_32_rkey   = 11'($urandom_range(0, KEY_POOL - 1));
    if (cam_32_wvalid) cam_32_written[cam_32_widx] = 1'b1;
    // IndexableCAMTemplate_33
    cam_33_wvalid = ($urandom_range(0, 3) != 0);
    cam_33_widx   = 4'($urandom);
    cam_33_wkey   = 8'($urandom_range(0, KEY_POOL - 1));
    cam_33_rkey   = 8'($urandom_range(0, KEY_POOL - 1));
    if (cam_33_wvalid) cam_33_written[cam_33_widx] = 1'b1;
    // IndexableCAMTemplate_41
    cam_41_wvalid = ($urandom_range(0, 3) != 0);
    cam_41_widx   = 2'($urandom);
    cam_41_wkey   = 8'($urandom_range(0, KEY_POOL - 1));
    cam_41_rkey   = 8'($urandom_range(0, KEY_POOL - 1));
    if (cam_41_wvalid) cam_41_written[cam_41_widx] = 1'b1;
    // IndexableCAMTemplate_43
    cam_43_wvalid = ($urandom_range(0, 3) != 0);
    cam_43_widx   = 2'($urandom);
    cam_43_wkey   = 9'($urandom_range(0, KEY_POOL - 1));
    cam_43_rkey   = 9'($urandom_range(0, KEY_POOL - 1));
    if (cam_43_wvalid) cam_43_written[cam_43_widx] = 1'b1;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_cam_match)) begin
      checks++; cam_checks++;
      if (|g_cam_match) cam_hit++; else cam_miss++;
      if (g_cam_match !== i_cam_match) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH IndexableCAMTemplate rkey=%0h g=%0h i=%0h",
                   $time, cam_rkey, g_cam_match, i_cam_match);
      end
    end
    if (!$isunknown(g_cam_32_match)) begin
      checks++; cam_32_checks++;
      if (|g_cam_32_match) cam_32_hit++; else cam_32_miss++;
      if (g_cam_32_match !== i_cam_32_match) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH IndexableCAMTemplate_32 rkey=%0h g=%0h i=%0h",
                   $time, cam_32_rkey, g_cam_32_match, i_cam_32_match);
      end
    end
    if (!$isunknown(g_cam_33_match)) begin
      checks++; cam_33_checks++;
      if (|g_cam_33_match) cam_33_hit++; else cam_33_miss++;
      if (g_cam_33_match !== i_cam_33_match) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH IndexableCAMTemplate_33 rkey=%0h g=%0h i=%0h",
                   $time, cam_33_rkey, g_cam_33_match, i_cam_33_match);
      end
    end
    if (!$isunknown(g_cam_41_match)) begin
      checks++; cam_41_checks++;
      if (|g_cam_41_match) cam_41_hit++; else cam_41_miss++;
      if (g_cam_41_match !== i_cam_41_match) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH IndexableCAMTemplate_41 rkey=%0h g=%0h i=%0h",
                   $time, cam_41_rkey, g_cam_41_match, i_cam_41_match);
      end
    end
    if (!$isunknown(g_cam_43_match)) begin
      checks++; cam_43_checks++;
      if (|g_cam_43_match) cam_43_hit++; else cam_43_miss++;
      if (g_cam_43_match !== i_cam_43_match) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH IndexableCAMTemplate_43 rkey=%0h g=%0h i=%0h",
                   $time, cam_43_rkey, g_cam_43_match, i_cam_43_match);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    cam_wvalid = 1'b0; cam_widx = '0; cam_wkey = '0; cam_rkey = '0;
    cam_checks = 0; cam_hit = 0; cam_miss = 0; cam_written = '0;
    cam_32_wvalid = 1'b0; cam_32_widx = '0; cam_32_wkey = '0; cam_32_rkey = '0;
    cam_32_checks = 0; cam_32_hit = 0; cam_32_miss = 0; cam_32_written = '0;
    cam_33_wvalid = 1'b0; cam_33_widx = '0; cam_33_wkey = '0; cam_33_rkey = '0;
    cam_33_checks = 0; cam_33_hit = 0; cam_33_miss = 0; cam_33_written = '0;
    cam_41_wvalid = 1'b0; cam_41_widx = '0; cam_41_wkey = '0; cam_41_rkey = '0;
    cam_41_checks = 0; cam_41_hit = 0; cam_41_miss = 0; cam_41_written = '0;
    cam_43_wvalid = 1'b0; cam_43_widx = '0; cam_43_wkey = '0; cam_43_rkey = '0;
    cam_43_checks = 0; cam_43_hit = 0; cam_43_miss = 0; cam_43_written = '0;
    // warmup：逐条目写满，让两侧条目寄存器脱离 X
    for (int k = 0; k < 16; k++) begin
      @(negedge clock);
      if (k < 8) begin
        cam_wvalid = 1'b1;
        cam_widx   = 3'(k);
        cam_wkey   = 9'($urandom);
        cam_written[cam_widx] = 1'b1;
      end else cam_wvalid = 1'b0;
      if (k < 8) begin
        cam_32_wvalid = 1'b1;
        cam_32_widx   = 3'(k);
        cam_32_wkey   = 11'($urandom);
        cam_32_written[cam_32_widx] = 1'b1;
      end else cam_32_wvalid = 1'b0;
      if (k < 16) begin
        cam_33_wvalid = 1'b1;
        cam_33_widx   = 4'(k);
        cam_33_wkey   = 8'($urandom);
        cam_33_written[cam_33_widx] = 1'b1;
      end else cam_33_wvalid = 1'b0;
      if (k < 4) begin
        cam_41_wvalid = 1'b1;
        cam_41_widx   = 2'(k);
        cam_41_wkey   = 8'($urandom);
        cam_41_written[cam_41_widx] = 1'b1;
      end else cam_41_wvalid = 1'b0;
      if (k < 4) begin
        cam_43_wvalid = 1'b1;
        cam_43_widx   = 2'(k);
        cam_43_wkey   = 9'($urandom);
        cam_43_written[cam_43_widx] = 1'b1;
      end else cam_43_wvalid = 1'b0;
      @(posedge clock);
    end
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("IndexableCAMTemplate family checks=%0d errors=%0d", checks, errors);
    $display("  IndexableCAMTemplate: checks=%0d hit=%0d miss=%0d written=%0h/%0h",
             cam_checks, cam_hit, cam_miss, cam_written, {8{1'b1}});
    if (cam_written !== {8{1'b1}}) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate 有条目从未被写过"); cov_fail++;
    end
    if (cam_checks < COV_MIN || cam_hit < COV_MIN || cam_miss < COV_MIN) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate 事件数不足 (checks/hit/miss 各需 >= %0d)", COV_MIN);
      cov_fail++;
    end
    $display("  IndexableCAMTemplate_32: checks=%0d hit=%0d miss=%0d written=%0h/%0h",
             cam_32_checks, cam_32_hit, cam_32_miss, cam_32_written, {8{1'b1}});
    if (cam_32_written !== {8{1'b1}}) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_32 有条目从未被写过"); cov_fail++;
    end
    if (cam_32_checks < COV_MIN || cam_32_hit < COV_MIN || cam_32_miss < COV_MIN) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_32 事件数不足 (checks/hit/miss 各需 >= %0d)", COV_MIN);
      cov_fail++;
    end
    $display("  IndexableCAMTemplate_33: checks=%0d hit=%0d miss=%0d written=%0h/%0h",
             cam_33_checks, cam_33_hit, cam_33_miss, cam_33_written, {16{1'b1}});
    if (cam_33_written !== {16{1'b1}}) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_33 有条目从未被写过"); cov_fail++;
    end
    if (cam_33_checks < COV_MIN || cam_33_hit < COV_MIN || cam_33_miss < COV_MIN) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_33 事件数不足 (checks/hit/miss 各需 >= %0d)", COV_MIN);
      cov_fail++;
    end
    $display("  IndexableCAMTemplate_41: checks=%0d hit=%0d miss=%0d written=%0h/%0h",
             cam_41_checks, cam_41_hit, cam_41_miss, cam_41_written, {4{1'b1}});
    if (cam_41_written !== {4{1'b1}}) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_41 有条目从未被写过"); cov_fail++;
    end
    if (cam_41_checks < COV_MIN || cam_41_hit < COV_MIN || cam_41_miss < COV_MIN) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_41 事件数不足 (checks/hit/miss 各需 >= %0d)", COV_MIN);
      cov_fail++;
    end
    $display("  IndexableCAMTemplate_43: checks=%0d hit=%0d miss=%0d written=%0h/%0h",
             cam_43_checks, cam_43_hit, cam_43_miss, cam_43_written, {4{1'b1}});
    if (cam_43_written !== {4{1'b1}}) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_43 有条目从未被写过"); cov_fail++;
    end
    if (cam_43_checks < COV_MIN || cam_43_hit < COV_MIN || cam_43_miss < COV_MIN) begin
      $display("COVERAGE FAIL: IndexableCAMTemplate_43 事件数不足 (checks/hit/miss 各需 >= %0d)", COV_MIN);
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
