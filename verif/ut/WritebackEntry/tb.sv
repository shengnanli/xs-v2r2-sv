// 自动生成：verif/ut/WritebackEntry/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// WritebackEntry / WritebackEntry_15 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= WritebackEntry =================
  int unsigned w0_mode = 0;
  logic w0_reset;
  logic [4:0] w0_io_id;
  logic w0_io_req_valid;
  logic [2:0] w0_io_req_bits_param;
  logic w0_io_req_bits_voluntary;
  logic w0_io_req_bits_hasData;
  logic w0_io_req_bits_corrupt;
  logic w0_io_req_bits_dirty;
  logic [47:0] w0_io_req_bits_addr;
  logic [511:0] w0_io_req_data_data;
  logic w0_io_mem_release_ready;
  wire  w0_g_io_mem_release_valid, w0_i_io_mem_release_valid;
  logic w0_s0_io_mem_release_valid = '0, w0_s1_io_mem_release_valid = '0;
  wire  [2:0] w0_g_io_mem_release_bits_opcode, w0_i_io_mem_release_bits_opcode;
  logic [2:0] w0_s0_io_mem_release_bits_opcode = '0, w0_s1_io_mem_release_bits_opcode = '0;
  wire  [2:0] w0_g_io_mem_release_bits_param, w0_i_io_mem_release_bits_param;
  logic [2:0] w0_s0_io_mem_release_bits_param = '0, w0_s1_io_mem_release_bits_param = '0;
  wire  [5:0] w0_g_io_mem_release_bits_source, w0_i_io_mem_release_bits_source;
  logic [5:0] w0_s0_io_mem_release_bits_source = '0, w0_s1_io_mem_release_bits_source = '0;
  wire  [47:0] w0_g_io_mem_release_bits_address, w0_i_io_mem_release_bits_address;
  logic [47:0] w0_s0_io_mem_release_bits_address = '0, w0_s1_io_mem_release_bits_address = '0;
  wire  [255:0] w0_g_io_mem_release_bits_data, w0_i_io_mem_release_bits_data;
  logic [255:0] w0_s0_io_mem_release_bits_data = '0, w0_s1_io_mem_release_bits_data = '0;
  wire  w0_g_io_mem_release_bits_corrupt, w0_i_io_mem_release_bits_corrupt;
  logic w0_s0_io_mem_release_bits_corrupt = '0, w0_s1_io_mem_release_bits_corrupt = '0;
  logic w0_io_mem_grant_valid;
  logic w0_io_primary_valid;
  wire  w0_g_io_primary_ready, w0_i_io_primary_ready;
  logic w0_s0_io_primary_ready = '0, w0_s1_io_primary_ready = '0;
  wire  w0_g_io_block_addr_valid, w0_i_io_block_addr_valid;
  logic w0_s0_io_block_addr_valid = '0, w0_s1_io_block_addr_valid = '0;
  wire  [47:0] w0_g_io_block_addr_bits, w0_i_io_block_addr_bits;
  logic [47:0] w0_s0_io_block_addr_bits = '0, w0_s1_io_block_addr_bits = '0;
  int w0_cov_alloc = 0;
  int w0_cov_probeack = 0;
  int w0_cov_probeackdata = 0;
  int w0_cov_release = 0;
  int w0_cov_releasedata = 0;
  int w0_cov_release_stall = 0;
  int w0_cov_wait_grant = 0;
  int w0_cov_grant_done = 0;
  int w0_cov_reset_mid = 0;
  logic [0:0] w0_armed = '0;
  int w0_armed_at = -1;
  WritebackEntry w0_u_gold (
    .clock(clk),
    .reset(w0_reset),
    .io_id(w0_io_id),
    .io_req_valid(w0_io_req_valid),
    .io_req_bits_param(w0_io_req_bits_param),
    .io_req_bits_voluntary(w0_io_req_bits_voluntary),
    .io_req_bits_hasData(w0_io_req_bits_hasData),
    .io_req_bits_corrupt(w0_io_req_bits_corrupt),
    .io_req_bits_dirty(w0_io_req_bits_dirty),
    .io_req_bits_addr(w0_io_req_bits_addr),
    .io_req_data_data(w0_io_req_data_data),
    .io_mem_release_ready(w0_io_mem_release_ready),
    .io_mem_release_valid(w0_g_io_mem_release_valid),
    .io_mem_release_bits_opcode(w0_g_io_mem_release_bits_opcode),
    .io_mem_release_bits_param(w0_g_io_mem_release_bits_param),
    .io_mem_release_bits_source(w0_g_io_mem_release_bits_source),
    .io_mem_release_bits_address(w0_g_io_mem_release_bits_address),
    .io_mem_release_bits_data(w0_g_io_mem_release_bits_data),
    .io_mem_release_bits_corrupt(w0_g_io_mem_release_bits_corrupt),
    .io_mem_grant_valid(w0_io_mem_grant_valid),
    .io_primary_valid(w0_io_primary_valid),
    .io_primary_ready(w0_g_io_primary_ready),
    .io_block_addr_valid(w0_g_io_block_addr_valid),
    .io_block_addr_bits(w0_g_io_block_addr_bits)
  );
  WritebackEntry_xs w0_u_impl (
    .clock(clk),
    .reset(w0_reset),
    .io_id(w0_io_id),
    .io_req_valid(w0_io_req_valid),
    .io_req_bits_param(w0_io_req_bits_param),
    .io_req_bits_voluntary(w0_io_req_bits_voluntary),
    .io_req_bits_hasData(w0_io_req_bits_hasData),
    .io_req_bits_corrupt(w0_io_req_bits_corrupt),
    .io_req_bits_dirty(w0_io_req_bits_dirty),
    .io_req_bits_addr(w0_io_req_bits_addr),
    .io_req_data_data(w0_io_req_data_data),
    .io_mem_release_ready(w0_io_mem_release_ready),
    .io_mem_release_valid(w0_i_io_mem_release_valid),
    .io_mem_release_bits_opcode(w0_i_io_mem_release_bits_opcode),
    .io_mem_release_bits_param(w0_i_io_mem_release_bits_param),
    .io_mem_release_bits_source(w0_i_io_mem_release_bits_source),
    .io_mem_release_bits_address(w0_i_io_mem_release_bits_address),
    .io_mem_release_bits_data(w0_i_io_mem_release_bits_data),
    .io_mem_release_bits_corrupt(w0_i_io_mem_release_bits_corrupt),
    .io_mem_grant_valid(w0_io_mem_grant_valid),
    .io_primary_valid(w0_io_primary_valid),
    .io_primary_ready(w0_i_io_primary_ready),
    .io_block_addr_valid(w0_i_io_block_addr_valid),
    .io_block_addr_bits(w0_i_io_block_addr_bits)
  );

  // ================= WritebackEntry_15 =================
  int unsigned w15_mode = 0;
  logic w15_reset;
  logic [5:0] w15_io_id;
  logic w15_io_req_valid;
  logic [2:0] w15_io_req_bits_param;
  logic w15_io_req_bits_voluntary;
  logic w15_io_req_bits_hasData;
  logic w15_io_req_bits_corrupt;
  logic w15_io_req_bits_dirty;
  logic [47:0] w15_io_req_bits_addr;
  logic [511:0] w15_io_req_data_data;
  logic w15_io_mem_release_ready;
  wire  w15_g_io_mem_release_valid, w15_i_io_mem_release_valid;
  logic w15_s0_io_mem_release_valid = '0, w15_s1_io_mem_release_valid = '0;
  wire  [2:0] w15_g_io_mem_release_bits_opcode, w15_i_io_mem_release_bits_opcode;
  logic [2:0] w15_s0_io_mem_release_bits_opcode = '0, w15_s1_io_mem_release_bits_opcode = '0;
  wire  [2:0] w15_g_io_mem_release_bits_param, w15_i_io_mem_release_bits_param;
  logic [2:0] w15_s0_io_mem_release_bits_param = '0, w15_s1_io_mem_release_bits_param = '0;
  wire  [5:0] w15_g_io_mem_release_bits_source, w15_i_io_mem_release_bits_source;
  logic [5:0] w15_s0_io_mem_release_bits_source = '0, w15_s1_io_mem_release_bits_source = '0;
  wire  [47:0] w15_g_io_mem_release_bits_address, w15_i_io_mem_release_bits_address;
  logic [47:0] w15_s0_io_mem_release_bits_address = '0, w15_s1_io_mem_release_bits_address = '0;
  wire  [255:0] w15_g_io_mem_release_bits_data, w15_i_io_mem_release_bits_data;
  logic [255:0] w15_s0_io_mem_release_bits_data = '0, w15_s1_io_mem_release_bits_data = '0;
  wire  w15_g_io_mem_release_bits_corrupt, w15_i_io_mem_release_bits_corrupt;
  logic w15_s0_io_mem_release_bits_corrupt = '0, w15_s1_io_mem_release_bits_corrupt = '0;
  logic w15_io_mem_grant_valid;
  logic w15_io_primary_valid;
  wire  w15_g_io_primary_ready, w15_i_io_primary_ready;
  logic w15_s0_io_primary_ready = '0, w15_s1_io_primary_ready = '0;
  wire  w15_g_io_block_addr_valid, w15_i_io_block_addr_valid;
  logic w15_s0_io_block_addr_valid = '0, w15_s1_io_block_addr_valid = '0;
  wire  [47:0] w15_g_io_block_addr_bits, w15_i_io_block_addr_bits;
  logic [47:0] w15_s0_io_block_addr_bits = '0, w15_s1_io_block_addr_bits = '0;
  int w15_cov_alloc = 0;
  int w15_cov_probeack = 0;
  int w15_cov_probeackdata = 0;
  int w15_cov_release = 0;
  int w15_cov_releasedata = 0;
  int w15_cov_release_stall = 0;
  int w15_cov_wait_grant = 0;
  int w15_cov_grant_done = 0;
  int w15_cov_reset_mid = 0;
  logic [0:0] w15_armed = '0;
  int w15_armed_at = -1;
  WritebackEntry_15 w15_u_gold (
    .clock(clk),
    .reset(w15_reset),
    .io_id(w15_io_id),
    .io_req_valid(w15_io_req_valid),
    .io_req_bits_param(w15_io_req_bits_param),
    .io_req_bits_voluntary(w15_io_req_bits_voluntary),
    .io_req_bits_hasData(w15_io_req_bits_hasData),
    .io_req_bits_corrupt(w15_io_req_bits_corrupt),
    .io_req_bits_dirty(w15_io_req_bits_dirty),
    .io_req_bits_addr(w15_io_req_bits_addr),
    .io_req_data_data(w15_io_req_data_data),
    .io_mem_release_ready(w15_io_mem_release_ready),
    .io_mem_release_valid(w15_g_io_mem_release_valid),
    .io_mem_release_bits_opcode(w15_g_io_mem_release_bits_opcode),
    .io_mem_release_bits_param(w15_g_io_mem_release_bits_param),
    .io_mem_release_bits_source(w15_g_io_mem_release_bits_source),
    .io_mem_release_bits_address(w15_g_io_mem_release_bits_address),
    .io_mem_release_bits_data(w15_g_io_mem_release_bits_data),
    .io_mem_release_bits_corrupt(w15_g_io_mem_release_bits_corrupt),
    .io_mem_grant_valid(w15_io_mem_grant_valid),
    .io_primary_valid(w15_io_primary_valid),
    .io_primary_ready(w15_g_io_primary_ready),
    .io_block_addr_valid(w15_g_io_block_addr_valid),
    .io_block_addr_bits(w15_g_io_block_addr_bits)
  );
  WritebackEntry_15_xs w15_u_impl (
    .clock(clk),
    .reset(w15_reset),
    .io_id(w15_io_id),
    .io_req_valid(w15_io_req_valid),
    .io_req_bits_param(w15_io_req_bits_param),
    .io_req_bits_voluntary(w15_io_req_bits_voluntary),
    .io_req_bits_hasData(w15_io_req_bits_hasData),
    .io_req_bits_corrupt(w15_io_req_bits_corrupt),
    .io_req_bits_dirty(w15_io_req_bits_dirty),
    .io_req_bits_addr(w15_io_req_bits_addr),
    .io_req_data_data(w15_io_req_data_data),
    .io_mem_release_ready(w15_io_mem_release_ready),
    .io_mem_release_valid(w15_i_io_mem_release_valid),
    .io_mem_release_bits_opcode(w15_i_io_mem_release_bits_opcode),
    .io_mem_release_bits_param(w15_i_io_mem_release_bits_param),
    .io_mem_release_bits_source(w15_i_io_mem_release_bits_source),
    .io_mem_release_bits_address(w15_i_io_mem_release_bits_address),
    .io_mem_release_bits_data(w15_i_io_mem_release_bits_data),
    .io_mem_release_bits_corrupt(w15_i_io_mem_release_bits_corrupt),
    .io_mem_grant_valid(w15_io_mem_grant_valid),
    .io_primary_valid(w15_io_primary_valid),
    .io_primary_ready(w15_i_io_primary_ready),
    .io_block_addr_valid(w15_i_io_block_addr_valid),
    .io_block_addr_bits(w15_i_io_block_addr_bits)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) w0_mode = $urandom_range(0, 15);
      w0_io_id = 5'($urandom);
      w0_io_req_valid = 1'($urandom);
      w0_io_req_bits_param = 3'($urandom);
      w0_io_req_bits_voluntary = 1'($urandom);
      w0_io_req_bits_hasData = 1'($urandom);
      w0_io_req_bits_corrupt = 1'($urandom);
      w0_io_req_bits_dirty = 1'($urandom);
      w0_io_req_bits_addr = 48'({$urandom, $urandom});
      w0_io_req_data_data = 512'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      w0_io_mem_release_ready = 1'($urandom);
      w0_io_mem_grant_valid = 1'($urandom);
      w0_io_primary_valid = 1'($urandom);
      w0_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_w0
        w0_io_req_valid = ($urandom_range(0, 3) != 0);
        w0_io_primary_valid = ($urandom_range(0, 3) != 0);
        w0_io_mem_grant_valid = ($urandom_range(0, 3) == 0);
      end
      if (cyc % 4000 == 0) w15_mode = $urandom_range(0, 15);
      w15_io_id = 6'($urandom);
      w15_io_req_valid = 1'($urandom);
      w15_io_req_bits_param = 3'($urandom);
      w15_io_req_bits_voluntary = 1'($urandom);
      w15_io_req_bits_hasData = 1'($urandom);
      w15_io_req_bits_corrupt = 1'($urandom);
      w15_io_req_bits_dirty = 1'($urandom);
      w15_io_req_bits_addr = 48'({$urandom, $urandom});
      w15_io_req_data_data = 512'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      w15_io_mem_release_ready = 1'($urandom);
      w15_io_mem_grant_valid = 1'($urandom);
      w15_io_primary_valid = 1'($urandom);
      w15_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_w15
        w15_io_req_valid = ($urandom_range(0, 3) != 0);
        w15_io_primary_valid = ($urandom_range(0, 3) != 0);
        w15_io_mem_grant_valid = ($urandom_range(0, 3) == 0);
      end
      #4;
      if (cyc >= RESET_CYC + 0 && w0_armed_at >= 0 && cyc >= w0_armed_at) begin
        checks++;
        if (w0_g_io_mem_release_valid !== w0_i_io_mem_release_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_valid g=%h i=%h", cyc, w0_g_io_mem_release_valid, w0_i_io_mem_release_valid);
        end
        w0_s1_io_mem_release_valid |= w0_g_io_mem_release_valid;
        w0_s0_io_mem_release_valid |= ~w0_g_io_mem_release_valid;
        checks++;
        if (w0_g_io_mem_release_bits_opcode !== w0_i_io_mem_release_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_bits_opcode g=%h i=%h", cyc, w0_g_io_mem_release_bits_opcode, w0_i_io_mem_release_bits_opcode);
        end
        w0_s1_io_mem_release_bits_opcode |= w0_g_io_mem_release_bits_opcode;
        w0_s0_io_mem_release_bits_opcode |= ~w0_g_io_mem_release_bits_opcode;
        checks++;
        if (w0_g_io_mem_release_bits_param !== w0_i_io_mem_release_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_bits_param g=%h i=%h", cyc, w0_g_io_mem_release_bits_param, w0_i_io_mem_release_bits_param);
        end
        w0_s1_io_mem_release_bits_param |= w0_g_io_mem_release_bits_param;
        w0_s0_io_mem_release_bits_param |= ~w0_g_io_mem_release_bits_param;
        checks++;
        if (w0_g_io_mem_release_bits_source !== w0_i_io_mem_release_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_bits_source g=%h i=%h", cyc, w0_g_io_mem_release_bits_source, w0_i_io_mem_release_bits_source);
        end
        w0_s1_io_mem_release_bits_source |= w0_g_io_mem_release_bits_source;
        w0_s0_io_mem_release_bits_source |= ~w0_g_io_mem_release_bits_source;
        checks++;
        if (w0_g_io_mem_release_bits_address !== w0_i_io_mem_release_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_bits_address g=%h i=%h", cyc, w0_g_io_mem_release_bits_address, w0_i_io_mem_release_bits_address);
        end
        w0_s1_io_mem_release_bits_address |= w0_g_io_mem_release_bits_address;
        w0_s0_io_mem_release_bits_address |= ~w0_g_io_mem_release_bits_address;
        checks++;
        if (w0_g_io_mem_release_bits_data !== w0_i_io_mem_release_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_bits_data g=%h i=%h", cyc, w0_g_io_mem_release_bits_data, w0_i_io_mem_release_bits_data);
        end
        w0_s1_io_mem_release_bits_data |= w0_g_io_mem_release_bits_data;
        w0_s0_io_mem_release_bits_data |= ~w0_g_io_mem_release_bits_data;
        checks++;
        if (w0_g_io_mem_release_bits_corrupt !== w0_i_io_mem_release_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_mem_release_bits_corrupt g=%h i=%h", cyc, w0_g_io_mem_release_bits_corrupt, w0_i_io_mem_release_bits_corrupt);
        end
        w0_s1_io_mem_release_bits_corrupt |= w0_g_io_mem_release_bits_corrupt;
        w0_s0_io_mem_release_bits_corrupt |= ~w0_g_io_mem_release_bits_corrupt;
        checks++;
        if (w0_g_io_primary_ready !== w0_i_io_primary_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_primary_ready g=%h i=%h", cyc, w0_g_io_primary_ready, w0_i_io_primary_ready);
        end
        w0_s1_io_primary_ready |= w0_g_io_primary_ready;
        w0_s0_io_primary_ready |= ~w0_g_io_primary_ready;
        checks++;
        if (w0_g_io_block_addr_valid !== w0_i_io_block_addr_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_block_addr_valid g=%h i=%h", cyc, w0_g_io_block_addr_valid, w0_i_io_block_addr_valid);
        end
        w0_s1_io_block_addr_valid |= w0_g_io_block_addr_valid;
        w0_s0_io_block_addr_valid |= ~w0_g_io_block_addr_valid;
        checks++;
        if (w0_g_io_block_addr_bits !== w0_i_io_block_addr_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry.io_block_addr_bits g=%h i=%h", cyc, w0_g_io_block_addr_bits, w0_i_io_block_addr_bits);
        end
        w0_s1_io_block_addr_bits |= w0_g_io_block_addr_bits;
        w0_s0_io_block_addr_bits |= ~w0_g_io_block_addr_bits;
        if (w0_io_req_valid && w0_io_primary_valid && w0_g_io_primary_ready) w0_cov_alloc++;
        if (w0_g_io_mem_release_valid && w0_io_mem_release_ready && w0_g_io_mem_release_bits_opcode == 3'd4) w0_cov_probeack++;
        if (w0_g_io_mem_release_valid && w0_io_mem_release_ready && w0_g_io_mem_release_bits_opcode == 3'd5) w0_cov_probeackdata++;
        if (w0_g_io_mem_release_valid && w0_io_mem_release_ready && w0_g_io_mem_release_bits_opcode == 3'd6) w0_cov_release++;
        if (w0_g_io_mem_release_valid && w0_io_mem_release_ready && w0_g_io_mem_release_bits_opcode == 3'd7) w0_cov_releasedata++;
        if (w0_g_io_mem_release_valid && !w0_io_mem_release_ready) w0_cov_release_stall++;
        if (w0_u_gold.state == 2'd2 && !w0_io_mem_grant_valid) w0_cov_wait_grant++;
        if (w0_u_gold.state == 2'd2 && w0_io_mem_grant_valid) w0_cov_grant_done++;
        if (w0_reset && cyc > 100) w0_cov_reset_mid++;
      end
      if (w0_io_req_valid && w0_io_primary_valid && w0_g_io_primary_ready) w0_armed[0] = 1'b1;
      if (w0_armed_at < 0 && (&w0_armed)) w0_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && w15_armed_at >= 0 && cyc >= w15_armed_at) begin
        checks++;
        if (w15_g_io_mem_release_valid !== w15_i_io_mem_release_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_valid g=%h i=%h", cyc, w15_g_io_mem_release_valid, w15_i_io_mem_release_valid);
        end
        w15_s1_io_mem_release_valid |= w15_g_io_mem_release_valid;
        w15_s0_io_mem_release_valid |= ~w15_g_io_mem_release_valid;
        checks++;
        if (w15_g_io_mem_release_bits_opcode !== w15_i_io_mem_release_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_bits_opcode g=%h i=%h", cyc, w15_g_io_mem_release_bits_opcode, w15_i_io_mem_release_bits_opcode);
        end
        w15_s1_io_mem_release_bits_opcode |= w15_g_io_mem_release_bits_opcode;
        w15_s0_io_mem_release_bits_opcode |= ~w15_g_io_mem_release_bits_opcode;
        checks++;
        if (w15_g_io_mem_release_bits_param !== w15_i_io_mem_release_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_bits_param g=%h i=%h", cyc, w15_g_io_mem_release_bits_param, w15_i_io_mem_release_bits_param);
        end
        w15_s1_io_mem_release_bits_param |= w15_g_io_mem_release_bits_param;
        w15_s0_io_mem_release_bits_param |= ~w15_g_io_mem_release_bits_param;
        checks++;
        if (w15_g_io_mem_release_bits_source !== w15_i_io_mem_release_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_bits_source g=%h i=%h", cyc, w15_g_io_mem_release_bits_source, w15_i_io_mem_release_bits_source);
        end
        w15_s1_io_mem_release_bits_source |= w15_g_io_mem_release_bits_source;
        w15_s0_io_mem_release_bits_source |= ~w15_g_io_mem_release_bits_source;
        checks++;
        if (w15_g_io_mem_release_bits_address !== w15_i_io_mem_release_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_bits_address g=%h i=%h", cyc, w15_g_io_mem_release_bits_address, w15_i_io_mem_release_bits_address);
        end
        w15_s1_io_mem_release_bits_address |= w15_g_io_mem_release_bits_address;
        w15_s0_io_mem_release_bits_address |= ~w15_g_io_mem_release_bits_address;
        checks++;
        if (w15_g_io_mem_release_bits_data !== w15_i_io_mem_release_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_bits_data g=%h i=%h", cyc, w15_g_io_mem_release_bits_data, w15_i_io_mem_release_bits_data);
        end
        w15_s1_io_mem_release_bits_data |= w15_g_io_mem_release_bits_data;
        w15_s0_io_mem_release_bits_data |= ~w15_g_io_mem_release_bits_data;
        checks++;
        if (w15_g_io_mem_release_bits_corrupt !== w15_i_io_mem_release_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_mem_release_bits_corrupt g=%h i=%h", cyc, w15_g_io_mem_release_bits_corrupt, w15_i_io_mem_release_bits_corrupt);
        end
        w15_s1_io_mem_release_bits_corrupt |= w15_g_io_mem_release_bits_corrupt;
        w15_s0_io_mem_release_bits_corrupt |= ~w15_g_io_mem_release_bits_corrupt;
        checks++;
        if (w15_g_io_primary_ready !== w15_i_io_primary_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_primary_ready g=%h i=%h", cyc, w15_g_io_primary_ready, w15_i_io_primary_ready);
        end
        w15_s1_io_primary_ready |= w15_g_io_primary_ready;
        w15_s0_io_primary_ready |= ~w15_g_io_primary_ready;
        checks++;
        if (w15_g_io_block_addr_valid !== w15_i_io_block_addr_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_block_addr_valid g=%h i=%h", cyc, w15_g_io_block_addr_valid, w15_i_io_block_addr_valid);
        end
        w15_s1_io_block_addr_valid |= w15_g_io_block_addr_valid;
        w15_s0_io_block_addr_valid |= ~w15_g_io_block_addr_valid;
        checks++;
        if (w15_g_io_block_addr_bits !== w15_i_io_block_addr_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d WritebackEntry_15.io_block_addr_bits g=%h i=%h", cyc, w15_g_io_block_addr_bits, w15_i_io_block_addr_bits);
        end
        w15_s1_io_block_addr_bits |= w15_g_io_block_addr_bits;
        w15_s0_io_block_addr_bits |= ~w15_g_io_block_addr_bits;
        if (w15_io_req_valid && w15_io_primary_valid && w15_g_io_primary_ready) w15_cov_alloc++;
        if (w15_g_io_mem_release_valid && w15_io_mem_release_ready && w15_g_io_mem_release_bits_opcode == 3'd4) w15_cov_probeack++;
        if (w15_g_io_mem_release_valid && w15_io_mem_release_ready && w15_g_io_mem_release_bits_opcode == 3'd5) w15_cov_probeackdata++;
        if (w15_g_io_mem_release_valid && w15_io_mem_release_ready && w15_g_io_mem_release_bits_opcode == 3'd6) w15_cov_release++;
        if (w15_g_io_mem_release_valid && w15_io_mem_release_ready && w15_g_io_mem_release_bits_opcode == 3'd7) w15_cov_releasedata++;
        if (w15_g_io_mem_release_valid && !w15_io_mem_release_ready) w15_cov_release_stall++;
        if (w15_u_gold.state == 2'd2 && !w15_io_mem_grant_valid) w15_cov_wait_grant++;
        if (w15_u_gold.state == 2'd2 && w15_io_mem_grant_valid) w15_cov_grant_done++;
        if (w15_reset && cyc > 100) w15_cov_reset_mid++;
      end
      if (w15_io_req_valid && w15_io_primary_valid && w15_g_io_primary_ready) w15_armed[0] = 1'b1;
      if (w15_armed_at < 0 && (&w15_armed)) w15_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(w0_s0_io_mem_release_valid && w0_s1_io_mem_release_valid)) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_valid 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_opcode[0] && w0_s1_io_mem_release_bits_opcode[0])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_opcode[0] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_opcode[1] && w0_s1_io_mem_release_bits_opcode[1])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_opcode[1] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_param[0] && w0_s1_io_mem_release_bits_param[0])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_param[0] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_param[1] && w0_s1_io_mem_release_bits_param[1])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_param[1] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_param[2] && w0_s1_io_mem_release_bits_param[2])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_param[2] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_source[0] && w0_s1_io_mem_release_bits_source[0])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_source[0] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_source[1] && w0_s1_io_mem_release_bits_source[1])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_source[1] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_source[2] && w0_s1_io_mem_release_bits_source[2])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_source[2] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_source[3] && w0_s1_io_mem_release_bits_source[3])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_source[3] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_source[4] && w0_s1_io_mem_release_bits_source[4])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_source[4] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[0] && w0_s1_io_mem_release_bits_address[0])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[0] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[1] && w0_s1_io_mem_release_bits_address[1])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[1] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[2] && w0_s1_io_mem_release_bits_address[2])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[2] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[3] && w0_s1_io_mem_release_bits_address[3])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[3] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[4] && w0_s1_io_mem_release_bits_address[4])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[4] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[5] && w0_s1_io_mem_release_bits_address[5])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[5] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[6] && w0_s1_io_mem_release_bits_address[6])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[6] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[7] && w0_s1_io_mem_release_bits_address[7])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[7] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[8] && w0_s1_io_mem_release_bits_address[8])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[8] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[9] && w0_s1_io_mem_release_bits_address[9])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[9] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[10] && w0_s1_io_mem_release_bits_address[10])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[10] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[11] && w0_s1_io_mem_release_bits_address[11])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[11] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[12] && w0_s1_io_mem_release_bits_address[12])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[12] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[13] && w0_s1_io_mem_release_bits_address[13])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[13] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[14] && w0_s1_io_mem_release_bits_address[14])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[14] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[15] && w0_s1_io_mem_release_bits_address[15])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[15] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[16] && w0_s1_io_mem_release_bits_address[16])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[16] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[17] && w0_s1_io_mem_release_bits_address[17])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[17] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[18] && w0_s1_io_mem_release_bits_address[18])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[18] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[19] && w0_s1_io_mem_release_bits_address[19])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[19] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[20] && w0_s1_io_mem_release_bits_address[20])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[20] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[21] && w0_s1_io_mem_release_bits_address[21])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[21] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[22] && w0_s1_io_mem_release_bits_address[22])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[22] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[23] && w0_s1_io_mem_release_bits_address[23])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[23] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[24] && w0_s1_io_mem_release_bits_address[24])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[24] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[25] && w0_s1_io_mem_release_bits_address[25])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[25] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[26] && w0_s1_io_mem_release_bits_address[26])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[26] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[27] && w0_s1_io_mem_release_bits_address[27])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[27] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[28] && w0_s1_io_mem_release_bits_address[28])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[28] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[29] && w0_s1_io_mem_release_bits_address[29])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[29] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[30] && w0_s1_io_mem_release_bits_address[30])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[30] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[31] && w0_s1_io_mem_release_bits_address[31])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[31] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[32] && w0_s1_io_mem_release_bits_address[32])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[32] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[33] && w0_s1_io_mem_release_bits_address[33])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[33] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[34] && w0_s1_io_mem_release_bits_address[34])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[34] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[35] && w0_s1_io_mem_release_bits_address[35])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[35] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[36] && w0_s1_io_mem_release_bits_address[36])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[36] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[37] && w0_s1_io_mem_release_bits_address[37])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[37] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[38] && w0_s1_io_mem_release_bits_address[38])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[38] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[39] && w0_s1_io_mem_release_bits_address[39])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[39] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[40] && w0_s1_io_mem_release_bits_address[40])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[40] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[41] && w0_s1_io_mem_release_bits_address[41])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[41] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[42] && w0_s1_io_mem_release_bits_address[42])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[42] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[43] && w0_s1_io_mem_release_bits_address[43])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[43] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[44] && w0_s1_io_mem_release_bits_address[44])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[44] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[45] && w0_s1_io_mem_release_bits_address[45])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[45] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[46] && w0_s1_io_mem_release_bits_address[46])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[46] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_address[47] && w0_s1_io_mem_release_bits_address[47])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_address[47] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[0] && w0_s1_io_mem_release_bits_data[0])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[0] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[1] && w0_s1_io_mem_release_bits_data[1])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[1] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[2] && w0_s1_io_mem_release_bits_data[2])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[2] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[3] && w0_s1_io_mem_release_bits_data[3])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[3] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[4] && w0_s1_io_mem_release_bits_data[4])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[4] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[5] && w0_s1_io_mem_release_bits_data[5])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[5] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[6] && w0_s1_io_mem_release_bits_data[6])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[6] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[7] && w0_s1_io_mem_release_bits_data[7])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[7] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[8] && w0_s1_io_mem_release_bits_data[8])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[8] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[9] && w0_s1_io_mem_release_bits_data[9])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[9] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[10] && w0_s1_io_mem_release_bits_data[10])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[10] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[11] && w0_s1_io_mem_release_bits_data[11])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[11] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[12] && w0_s1_io_mem_release_bits_data[12])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[12] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[13] && w0_s1_io_mem_release_bits_data[13])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[13] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[14] && w0_s1_io_mem_release_bits_data[14])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[14] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[15] && w0_s1_io_mem_release_bits_data[15])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[15] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[16] && w0_s1_io_mem_release_bits_data[16])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[16] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[17] && w0_s1_io_mem_release_bits_data[17])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[17] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[18] && w0_s1_io_mem_release_bits_data[18])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[18] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[19] && w0_s1_io_mem_release_bits_data[19])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[19] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[20] && w0_s1_io_mem_release_bits_data[20])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[20] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[21] && w0_s1_io_mem_release_bits_data[21])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[21] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[22] && w0_s1_io_mem_release_bits_data[22])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[22] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[23] && w0_s1_io_mem_release_bits_data[23])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[23] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[24] && w0_s1_io_mem_release_bits_data[24])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[24] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[25] && w0_s1_io_mem_release_bits_data[25])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[25] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[26] && w0_s1_io_mem_release_bits_data[26])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[26] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[27] && w0_s1_io_mem_release_bits_data[27])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[27] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[28] && w0_s1_io_mem_release_bits_data[28])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[28] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[29] && w0_s1_io_mem_release_bits_data[29])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[29] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[30] && w0_s1_io_mem_release_bits_data[30])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[30] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[31] && w0_s1_io_mem_release_bits_data[31])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[31] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[32] && w0_s1_io_mem_release_bits_data[32])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[32] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[33] && w0_s1_io_mem_release_bits_data[33])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[33] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[34] && w0_s1_io_mem_release_bits_data[34])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[34] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[35] && w0_s1_io_mem_release_bits_data[35])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[35] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[36] && w0_s1_io_mem_release_bits_data[36])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[36] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[37] && w0_s1_io_mem_release_bits_data[37])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[37] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[38] && w0_s1_io_mem_release_bits_data[38])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[38] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[39] && w0_s1_io_mem_release_bits_data[39])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[39] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[40] && w0_s1_io_mem_release_bits_data[40])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[40] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[41] && w0_s1_io_mem_release_bits_data[41])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[41] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[42] && w0_s1_io_mem_release_bits_data[42])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[42] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[43] && w0_s1_io_mem_release_bits_data[43])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[43] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[44] && w0_s1_io_mem_release_bits_data[44])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[44] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[45] && w0_s1_io_mem_release_bits_data[45])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[45] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[46] && w0_s1_io_mem_release_bits_data[46])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[46] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[47] && w0_s1_io_mem_release_bits_data[47])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[47] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[48] && w0_s1_io_mem_release_bits_data[48])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[48] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[49] && w0_s1_io_mem_release_bits_data[49])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[49] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[50] && w0_s1_io_mem_release_bits_data[50])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[50] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[51] && w0_s1_io_mem_release_bits_data[51])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[51] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[52] && w0_s1_io_mem_release_bits_data[52])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[52] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[53] && w0_s1_io_mem_release_bits_data[53])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[53] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[54] && w0_s1_io_mem_release_bits_data[54])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[54] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[55] && w0_s1_io_mem_release_bits_data[55])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[55] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[56] && w0_s1_io_mem_release_bits_data[56])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[56] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[57] && w0_s1_io_mem_release_bits_data[57])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[57] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[58] && w0_s1_io_mem_release_bits_data[58])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[58] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[59] && w0_s1_io_mem_release_bits_data[59])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[59] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[60] && w0_s1_io_mem_release_bits_data[60])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[60] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[61] && w0_s1_io_mem_release_bits_data[61])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[61] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[62] && w0_s1_io_mem_release_bits_data[62])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[62] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[63] && w0_s1_io_mem_release_bits_data[63])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[63] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[64] && w0_s1_io_mem_release_bits_data[64])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[64] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[65] && w0_s1_io_mem_release_bits_data[65])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[65] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[66] && w0_s1_io_mem_release_bits_data[66])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[66] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[67] && w0_s1_io_mem_release_bits_data[67])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[67] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[68] && w0_s1_io_mem_release_bits_data[68])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[68] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[69] && w0_s1_io_mem_release_bits_data[69])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[69] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[70] && w0_s1_io_mem_release_bits_data[70])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[70] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[71] && w0_s1_io_mem_release_bits_data[71])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[71] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[72] && w0_s1_io_mem_release_bits_data[72])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[72] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[73] && w0_s1_io_mem_release_bits_data[73])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[73] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[74] && w0_s1_io_mem_release_bits_data[74])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[74] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[75] && w0_s1_io_mem_release_bits_data[75])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[75] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[76] && w0_s1_io_mem_release_bits_data[76])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[76] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[77] && w0_s1_io_mem_release_bits_data[77])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[77] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[78] && w0_s1_io_mem_release_bits_data[78])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[78] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[79] && w0_s1_io_mem_release_bits_data[79])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[79] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[80] && w0_s1_io_mem_release_bits_data[80])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[80] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[81] && w0_s1_io_mem_release_bits_data[81])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[81] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[82] && w0_s1_io_mem_release_bits_data[82])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[82] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[83] && w0_s1_io_mem_release_bits_data[83])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[83] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[84] && w0_s1_io_mem_release_bits_data[84])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[84] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[85] && w0_s1_io_mem_release_bits_data[85])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[85] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[86] && w0_s1_io_mem_release_bits_data[86])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[86] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[87] && w0_s1_io_mem_release_bits_data[87])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[87] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[88] && w0_s1_io_mem_release_bits_data[88])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[88] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[89] && w0_s1_io_mem_release_bits_data[89])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[89] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[90] && w0_s1_io_mem_release_bits_data[90])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[90] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[91] && w0_s1_io_mem_release_bits_data[91])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[91] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[92] && w0_s1_io_mem_release_bits_data[92])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[92] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[93] && w0_s1_io_mem_release_bits_data[93])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[93] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[94] && w0_s1_io_mem_release_bits_data[94])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[94] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[95] && w0_s1_io_mem_release_bits_data[95])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[95] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[96] && w0_s1_io_mem_release_bits_data[96])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[96] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[97] && w0_s1_io_mem_release_bits_data[97])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[97] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[98] && w0_s1_io_mem_release_bits_data[98])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[98] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[99] && w0_s1_io_mem_release_bits_data[99])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[99] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[100] && w0_s1_io_mem_release_bits_data[100])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[100] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[101] && w0_s1_io_mem_release_bits_data[101])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[101] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[102] && w0_s1_io_mem_release_bits_data[102])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[102] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[103] && w0_s1_io_mem_release_bits_data[103])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[103] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[104] && w0_s1_io_mem_release_bits_data[104])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[104] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[105] && w0_s1_io_mem_release_bits_data[105])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[105] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[106] && w0_s1_io_mem_release_bits_data[106])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[106] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[107] && w0_s1_io_mem_release_bits_data[107])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[107] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[108] && w0_s1_io_mem_release_bits_data[108])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[108] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[109] && w0_s1_io_mem_release_bits_data[109])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[109] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[110] && w0_s1_io_mem_release_bits_data[110])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[110] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[111] && w0_s1_io_mem_release_bits_data[111])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[111] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[112] && w0_s1_io_mem_release_bits_data[112])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[112] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[113] && w0_s1_io_mem_release_bits_data[113])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[113] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[114] && w0_s1_io_mem_release_bits_data[114])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[114] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[115] && w0_s1_io_mem_release_bits_data[115])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[115] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[116] && w0_s1_io_mem_release_bits_data[116])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[116] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[117] && w0_s1_io_mem_release_bits_data[117])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[117] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[118] && w0_s1_io_mem_release_bits_data[118])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[118] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[119] && w0_s1_io_mem_release_bits_data[119])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[119] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[120] && w0_s1_io_mem_release_bits_data[120])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[120] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[121] && w0_s1_io_mem_release_bits_data[121])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[121] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[122] && w0_s1_io_mem_release_bits_data[122])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[122] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[123] && w0_s1_io_mem_release_bits_data[123])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[123] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[124] && w0_s1_io_mem_release_bits_data[124])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[124] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[125] && w0_s1_io_mem_release_bits_data[125])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[125] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[126] && w0_s1_io_mem_release_bits_data[126])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[126] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[127] && w0_s1_io_mem_release_bits_data[127])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[127] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[128] && w0_s1_io_mem_release_bits_data[128])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[128] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[129] && w0_s1_io_mem_release_bits_data[129])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[129] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[130] && w0_s1_io_mem_release_bits_data[130])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[130] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[131] && w0_s1_io_mem_release_bits_data[131])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[131] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[132] && w0_s1_io_mem_release_bits_data[132])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[132] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[133] && w0_s1_io_mem_release_bits_data[133])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[133] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[134] && w0_s1_io_mem_release_bits_data[134])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[134] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[135] && w0_s1_io_mem_release_bits_data[135])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[135] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[136] && w0_s1_io_mem_release_bits_data[136])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[136] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[137] && w0_s1_io_mem_release_bits_data[137])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[137] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[138] && w0_s1_io_mem_release_bits_data[138])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[138] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[139] && w0_s1_io_mem_release_bits_data[139])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[139] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[140] && w0_s1_io_mem_release_bits_data[140])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[140] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[141] && w0_s1_io_mem_release_bits_data[141])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[141] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[142] && w0_s1_io_mem_release_bits_data[142])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[142] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[143] && w0_s1_io_mem_release_bits_data[143])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[143] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[144] && w0_s1_io_mem_release_bits_data[144])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[144] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[145] && w0_s1_io_mem_release_bits_data[145])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[145] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[146] && w0_s1_io_mem_release_bits_data[146])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[146] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[147] && w0_s1_io_mem_release_bits_data[147])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[147] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[148] && w0_s1_io_mem_release_bits_data[148])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[148] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[149] && w0_s1_io_mem_release_bits_data[149])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[149] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[150] && w0_s1_io_mem_release_bits_data[150])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[150] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[151] && w0_s1_io_mem_release_bits_data[151])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[151] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[152] && w0_s1_io_mem_release_bits_data[152])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[152] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[153] && w0_s1_io_mem_release_bits_data[153])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[153] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[154] && w0_s1_io_mem_release_bits_data[154])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[154] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[155] && w0_s1_io_mem_release_bits_data[155])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[155] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[156] && w0_s1_io_mem_release_bits_data[156])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[156] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[157] && w0_s1_io_mem_release_bits_data[157])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[157] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[158] && w0_s1_io_mem_release_bits_data[158])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[158] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[159] && w0_s1_io_mem_release_bits_data[159])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[159] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[160] && w0_s1_io_mem_release_bits_data[160])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[160] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[161] && w0_s1_io_mem_release_bits_data[161])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[161] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[162] && w0_s1_io_mem_release_bits_data[162])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[162] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[163] && w0_s1_io_mem_release_bits_data[163])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[163] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[164] && w0_s1_io_mem_release_bits_data[164])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[164] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[165] && w0_s1_io_mem_release_bits_data[165])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[165] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[166] && w0_s1_io_mem_release_bits_data[166])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[166] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[167] && w0_s1_io_mem_release_bits_data[167])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[167] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[168] && w0_s1_io_mem_release_bits_data[168])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[168] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[169] && w0_s1_io_mem_release_bits_data[169])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[169] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[170] && w0_s1_io_mem_release_bits_data[170])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[170] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[171] && w0_s1_io_mem_release_bits_data[171])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[171] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[172] && w0_s1_io_mem_release_bits_data[172])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[172] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[173] && w0_s1_io_mem_release_bits_data[173])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[173] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[174] && w0_s1_io_mem_release_bits_data[174])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[174] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[175] && w0_s1_io_mem_release_bits_data[175])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[175] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[176] && w0_s1_io_mem_release_bits_data[176])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[176] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[177] && w0_s1_io_mem_release_bits_data[177])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[177] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[178] && w0_s1_io_mem_release_bits_data[178])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[178] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[179] && w0_s1_io_mem_release_bits_data[179])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[179] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[180] && w0_s1_io_mem_release_bits_data[180])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[180] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[181] && w0_s1_io_mem_release_bits_data[181])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[181] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[182] && w0_s1_io_mem_release_bits_data[182])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[182] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[183] && w0_s1_io_mem_release_bits_data[183])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[183] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[184] && w0_s1_io_mem_release_bits_data[184])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[184] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[185] && w0_s1_io_mem_release_bits_data[185])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[185] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[186] && w0_s1_io_mem_release_bits_data[186])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[186] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[187] && w0_s1_io_mem_release_bits_data[187])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[187] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[188] && w0_s1_io_mem_release_bits_data[188])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[188] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[189] && w0_s1_io_mem_release_bits_data[189])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[189] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[190] && w0_s1_io_mem_release_bits_data[190])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[190] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[191] && w0_s1_io_mem_release_bits_data[191])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[191] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[192] && w0_s1_io_mem_release_bits_data[192])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[192] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[193] && w0_s1_io_mem_release_bits_data[193])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[193] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[194] && w0_s1_io_mem_release_bits_data[194])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[194] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[195] && w0_s1_io_mem_release_bits_data[195])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[195] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[196] && w0_s1_io_mem_release_bits_data[196])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[196] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[197] && w0_s1_io_mem_release_bits_data[197])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[197] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[198] && w0_s1_io_mem_release_bits_data[198])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[198] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[199] && w0_s1_io_mem_release_bits_data[199])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[199] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[200] && w0_s1_io_mem_release_bits_data[200])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[200] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[201] && w0_s1_io_mem_release_bits_data[201])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[201] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[202] && w0_s1_io_mem_release_bits_data[202])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[202] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[203] && w0_s1_io_mem_release_bits_data[203])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[203] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[204] && w0_s1_io_mem_release_bits_data[204])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[204] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[205] && w0_s1_io_mem_release_bits_data[205])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[205] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[206] && w0_s1_io_mem_release_bits_data[206])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[206] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[207] && w0_s1_io_mem_release_bits_data[207])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[207] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[208] && w0_s1_io_mem_release_bits_data[208])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[208] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[209] && w0_s1_io_mem_release_bits_data[209])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[209] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[210] && w0_s1_io_mem_release_bits_data[210])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[210] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[211] && w0_s1_io_mem_release_bits_data[211])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[211] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[212] && w0_s1_io_mem_release_bits_data[212])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[212] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[213] && w0_s1_io_mem_release_bits_data[213])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[213] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[214] && w0_s1_io_mem_release_bits_data[214])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[214] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[215] && w0_s1_io_mem_release_bits_data[215])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[215] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[216] && w0_s1_io_mem_release_bits_data[216])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[216] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[217] && w0_s1_io_mem_release_bits_data[217])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[217] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[218] && w0_s1_io_mem_release_bits_data[218])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[218] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[219] && w0_s1_io_mem_release_bits_data[219])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[219] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[220] && w0_s1_io_mem_release_bits_data[220])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[220] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[221] && w0_s1_io_mem_release_bits_data[221])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[221] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[222] && w0_s1_io_mem_release_bits_data[222])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[222] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[223] && w0_s1_io_mem_release_bits_data[223])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[223] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[224] && w0_s1_io_mem_release_bits_data[224])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[224] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[225] && w0_s1_io_mem_release_bits_data[225])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[225] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[226] && w0_s1_io_mem_release_bits_data[226])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[226] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[227] && w0_s1_io_mem_release_bits_data[227])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[227] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[228] && w0_s1_io_mem_release_bits_data[228])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[228] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[229] && w0_s1_io_mem_release_bits_data[229])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[229] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[230] && w0_s1_io_mem_release_bits_data[230])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[230] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[231] && w0_s1_io_mem_release_bits_data[231])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[231] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[232] && w0_s1_io_mem_release_bits_data[232])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[232] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[233] && w0_s1_io_mem_release_bits_data[233])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[233] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[234] && w0_s1_io_mem_release_bits_data[234])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[234] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[235] && w0_s1_io_mem_release_bits_data[235])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[235] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[236] && w0_s1_io_mem_release_bits_data[236])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[236] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[237] && w0_s1_io_mem_release_bits_data[237])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[237] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[238] && w0_s1_io_mem_release_bits_data[238])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[238] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[239] && w0_s1_io_mem_release_bits_data[239])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[239] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[240] && w0_s1_io_mem_release_bits_data[240])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[240] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[241] && w0_s1_io_mem_release_bits_data[241])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[241] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[242] && w0_s1_io_mem_release_bits_data[242])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[242] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[243] && w0_s1_io_mem_release_bits_data[243])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[243] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[244] && w0_s1_io_mem_release_bits_data[244])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[244] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[245] && w0_s1_io_mem_release_bits_data[245])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[245] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[246] && w0_s1_io_mem_release_bits_data[246])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[246] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[247] && w0_s1_io_mem_release_bits_data[247])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[247] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[248] && w0_s1_io_mem_release_bits_data[248])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[248] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[249] && w0_s1_io_mem_release_bits_data[249])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[249] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[250] && w0_s1_io_mem_release_bits_data[250])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[250] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[251] && w0_s1_io_mem_release_bits_data[251])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[251] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[252] && w0_s1_io_mem_release_bits_data[252])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[252] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[253] && w0_s1_io_mem_release_bits_data[253])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[253] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[254] && w0_s1_io_mem_release_bits_data[254])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[254] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_data[255] && w0_s1_io_mem_release_bits_data[255])) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_data[255] 未见过 0 和 1"); end
    if (!(w0_s0_io_mem_release_bits_corrupt && w0_s1_io_mem_release_bits_corrupt)) begin cov_fail++; $display("[COV] WritebackEntry.io_mem_release_bits_corrupt 未见过 0 和 1"); end
    if (!(w0_s0_io_primary_ready && w0_s1_io_primary_ready)) begin cov_fail++; $display("[COV] WritebackEntry.io_primary_ready 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_valid && w0_s1_io_block_addr_valid)) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_valid 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[0] && w0_s1_io_block_addr_bits[0])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[0] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[1] && w0_s1_io_block_addr_bits[1])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[1] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[2] && w0_s1_io_block_addr_bits[2])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[2] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[3] && w0_s1_io_block_addr_bits[3])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[3] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[4] && w0_s1_io_block_addr_bits[4])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[4] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[5] && w0_s1_io_block_addr_bits[5])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[5] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[6] && w0_s1_io_block_addr_bits[6])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[6] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[7] && w0_s1_io_block_addr_bits[7])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[7] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[8] && w0_s1_io_block_addr_bits[8])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[8] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[9] && w0_s1_io_block_addr_bits[9])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[9] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[10] && w0_s1_io_block_addr_bits[10])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[10] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[11] && w0_s1_io_block_addr_bits[11])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[11] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[12] && w0_s1_io_block_addr_bits[12])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[12] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[13] && w0_s1_io_block_addr_bits[13])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[13] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[14] && w0_s1_io_block_addr_bits[14])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[14] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[15] && w0_s1_io_block_addr_bits[15])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[15] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[16] && w0_s1_io_block_addr_bits[16])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[16] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[17] && w0_s1_io_block_addr_bits[17])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[17] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[18] && w0_s1_io_block_addr_bits[18])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[18] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[19] && w0_s1_io_block_addr_bits[19])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[19] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[20] && w0_s1_io_block_addr_bits[20])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[20] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[21] && w0_s1_io_block_addr_bits[21])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[21] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[22] && w0_s1_io_block_addr_bits[22])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[22] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[23] && w0_s1_io_block_addr_bits[23])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[23] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[24] && w0_s1_io_block_addr_bits[24])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[24] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[25] && w0_s1_io_block_addr_bits[25])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[25] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[26] && w0_s1_io_block_addr_bits[26])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[26] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[27] && w0_s1_io_block_addr_bits[27])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[27] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[28] && w0_s1_io_block_addr_bits[28])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[28] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[29] && w0_s1_io_block_addr_bits[29])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[29] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[30] && w0_s1_io_block_addr_bits[30])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[30] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[31] && w0_s1_io_block_addr_bits[31])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[31] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[32] && w0_s1_io_block_addr_bits[32])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[32] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[33] && w0_s1_io_block_addr_bits[33])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[33] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[34] && w0_s1_io_block_addr_bits[34])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[34] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[35] && w0_s1_io_block_addr_bits[35])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[35] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[36] && w0_s1_io_block_addr_bits[36])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[36] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[37] && w0_s1_io_block_addr_bits[37])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[37] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[38] && w0_s1_io_block_addr_bits[38])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[38] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[39] && w0_s1_io_block_addr_bits[39])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[39] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[40] && w0_s1_io_block_addr_bits[40])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[40] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[41] && w0_s1_io_block_addr_bits[41])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[41] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[42] && w0_s1_io_block_addr_bits[42])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[42] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[43] && w0_s1_io_block_addr_bits[43])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[43] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[44] && w0_s1_io_block_addr_bits[44])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[44] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[45] && w0_s1_io_block_addr_bits[45])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[45] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[46] && w0_s1_io_block_addr_bits[46])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[46] 未见过 0 和 1"); end
    if (!(w0_s0_io_block_addr_bits[47] && w0_s1_io_block_addr_bits[47])) begin cov_fail++; $display("[COV] WritebackEntry.io_block_addr_bits[47] 未见过 0 和 1"); end
    $display("[ARM] WritebackEntry armed_at=%0d", w0_armed_at);
    if (w0_armed_at < 0) begin cov_fail++; $display("[ARM] WritebackEntry 从未 arm"); end
    $display("[COV] WritebackEntry.alloc = %0d", w0_cov_alloc);
    if (w0_cov_alloc < 50) begin cov_fail++; $display("[COV] WritebackEntry.alloc < 50"); end
    $display("[COV] WritebackEntry.probeack = %0d", w0_cov_probeack);
    if (w0_cov_probeack < 50) begin cov_fail++; $display("[COV] WritebackEntry.probeack < 50"); end
    $display("[COV] WritebackEntry.probeackdata = %0d", w0_cov_probeackdata);
    if (w0_cov_probeackdata < 50) begin cov_fail++; $display("[COV] WritebackEntry.probeackdata < 50"); end
    $display("[COV] WritebackEntry.release = %0d", w0_cov_release);
    if (w0_cov_release < 50) begin cov_fail++; $display("[COV] WritebackEntry.release < 50"); end
    $display("[COV] WritebackEntry.releasedata = %0d", w0_cov_releasedata);
    if (w0_cov_releasedata < 50) begin cov_fail++; $display("[COV] WritebackEntry.releasedata < 50"); end
    $display("[COV] WritebackEntry.release_stall = %0d", w0_cov_release_stall);
    if (w0_cov_release_stall < 50) begin cov_fail++; $display("[COV] WritebackEntry.release_stall < 50"); end
    $display("[COV] WritebackEntry.wait_grant = %0d", w0_cov_wait_grant);
    if (w0_cov_wait_grant < 50) begin cov_fail++; $display("[COV] WritebackEntry.wait_grant < 50"); end
    $display("[COV] WritebackEntry.grant_done = %0d", w0_cov_grant_done);
    if (w0_cov_grant_done < 50) begin cov_fail++; $display("[COV] WritebackEntry.grant_done < 50"); end
    $display("[COV] WritebackEntry.reset_mid = %0d", w0_cov_reset_mid);
    if (w0_cov_reset_mid < 50) begin cov_fail++; $display("[COV] WritebackEntry.reset_mid < 50"); end
    if (!(w15_s0_io_mem_release_valid && w15_s1_io_mem_release_valid)) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_valid 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_opcode[0] && w15_s1_io_mem_release_bits_opcode[0])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_opcode[0] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_opcode[1] && w15_s1_io_mem_release_bits_opcode[1])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_opcode[1] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_param[0] && w15_s1_io_mem_release_bits_param[0])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_param[0] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_param[1] && w15_s1_io_mem_release_bits_param[1])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_param[1] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_param[2] && w15_s1_io_mem_release_bits_param[2])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_param[2] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_source[0] && w15_s1_io_mem_release_bits_source[0])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_source[0] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_source[1] && w15_s1_io_mem_release_bits_source[1])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_source[1] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_source[2] && w15_s1_io_mem_release_bits_source[2])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_source[2] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_source[3] && w15_s1_io_mem_release_bits_source[3])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_source[3] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_source[4] && w15_s1_io_mem_release_bits_source[4])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_source[4] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_source[5] && w15_s1_io_mem_release_bits_source[5])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_source[5] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[0] && w15_s1_io_mem_release_bits_address[0])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[0] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[1] && w15_s1_io_mem_release_bits_address[1])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[1] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[2] && w15_s1_io_mem_release_bits_address[2])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[2] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[3] && w15_s1_io_mem_release_bits_address[3])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[3] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[4] && w15_s1_io_mem_release_bits_address[4])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[4] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[5] && w15_s1_io_mem_release_bits_address[5])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[5] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[6] && w15_s1_io_mem_release_bits_address[6])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[6] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[7] && w15_s1_io_mem_release_bits_address[7])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[7] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[8] && w15_s1_io_mem_release_bits_address[8])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[8] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[9] && w15_s1_io_mem_release_bits_address[9])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[9] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[10] && w15_s1_io_mem_release_bits_address[10])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[10] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[11] && w15_s1_io_mem_release_bits_address[11])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[11] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[12] && w15_s1_io_mem_release_bits_address[12])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[12] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[13] && w15_s1_io_mem_release_bits_address[13])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[13] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[14] && w15_s1_io_mem_release_bits_address[14])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[14] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[15] && w15_s1_io_mem_release_bits_address[15])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[15] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[16] && w15_s1_io_mem_release_bits_address[16])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[16] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[17] && w15_s1_io_mem_release_bits_address[17])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[17] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[18] && w15_s1_io_mem_release_bits_address[18])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[18] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[19] && w15_s1_io_mem_release_bits_address[19])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[19] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[20] && w15_s1_io_mem_release_bits_address[20])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[20] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[21] && w15_s1_io_mem_release_bits_address[21])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[21] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[22] && w15_s1_io_mem_release_bits_address[22])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[22] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[23] && w15_s1_io_mem_release_bits_address[23])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[23] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[24] && w15_s1_io_mem_release_bits_address[24])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[24] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[25] && w15_s1_io_mem_release_bits_address[25])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[25] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[26] && w15_s1_io_mem_release_bits_address[26])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[26] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[27] && w15_s1_io_mem_release_bits_address[27])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[27] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[28] && w15_s1_io_mem_release_bits_address[28])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[28] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[29] && w15_s1_io_mem_release_bits_address[29])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[29] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[30] && w15_s1_io_mem_release_bits_address[30])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[30] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[31] && w15_s1_io_mem_release_bits_address[31])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[31] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[32] && w15_s1_io_mem_release_bits_address[32])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[32] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[33] && w15_s1_io_mem_release_bits_address[33])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[33] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[34] && w15_s1_io_mem_release_bits_address[34])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[34] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[35] && w15_s1_io_mem_release_bits_address[35])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[35] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[36] && w15_s1_io_mem_release_bits_address[36])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[36] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[37] && w15_s1_io_mem_release_bits_address[37])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[37] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[38] && w15_s1_io_mem_release_bits_address[38])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[38] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[39] && w15_s1_io_mem_release_bits_address[39])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[39] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[40] && w15_s1_io_mem_release_bits_address[40])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[40] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[41] && w15_s1_io_mem_release_bits_address[41])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[41] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[42] && w15_s1_io_mem_release_bits_address[42])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[42] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[43] && w15_s1_io_mem_release_bits_address[43])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[43] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[44] && w15_s1_io_mem_release_bits_address[44])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[44] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[45] && w15_s1_io_mem_release_bits_address[45])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[45] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[46] && w15_s1_io_mem_release_bits_address[46])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[46] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_address[47] && w15_s1_io_mem_release_bits_address[47])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_address[47] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[0] && w15_s1_io_mem_release_bits_data[0])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[0] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[1] && w15_s1_io_mem_release_bits_data[1])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[1] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[2] && w15_s1_io_mem_release_bits_data[2])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[2] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[3] && w15_s1_io_mem_release_bits_data[3])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[3] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[4] && w15_s1_io_mem_release_bits_data[4])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[4] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[5] && w15_s1_io_mem_release_bits_data[5])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[5] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[6] && w15_s1_io_mem_release_bits_data[6])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[6] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[7] && w15_s1_io_mem_release_bits_data[7])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[7] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[8] && w15_s1_io_mem_release_bits_data[8])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[8] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[9] && w15_s1_io_mem_release_bits_data[9])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[9] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[10] && w15_s1_io_mem_release_bits_data[10])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[10] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[11] && w15_s1_io_mem_release_bits_data[11])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[11] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[12] && w15_s1_io_mem_release_bits_data[12])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[12] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[13] && w15_s1_io_mem_release_bits_data[13])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[13] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[14] && w15_s1_io_mem_release_bits_data[14])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[14] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[15] && w15_s1_io_mem_release_bits_data[15])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[15] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[16] && w15_s1_io_mem_release_bits_data[16])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[16] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[17] && w15_s1_io_mem_release_bits_data[17])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[17] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[18] && w15_s1_io_mem_release_bits_data[18])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[18] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[19] && w15_s1_io_mem_release_bits_data[19])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[19] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[20] && w15_s1_io_mem_release_bits_data[20])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[20] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[21] && w15_s1_io_mem_release_bits_data[21])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[21] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[22] && w15_s1_io_mem_release_bits_data[22])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[22] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[23] && w15_s1_io_mem_release_bits_data[23])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[23] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[24] && w15_s1_io_mem_release_bits_data[24])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[24] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[25] && w15_s1_io_mem_release_bits_data[25])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[25] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[26] && w15_s1_io_mem_release_bits_data[26])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[26] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[27] && w15_s1_io_mem_release_bits_data[27])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[27] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[28] && w15_s1_io_mem_release_bits_data[28])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[28] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[29] && w15_s1_io_mem_release_bits_data[29])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[29] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[30] && w15_s1_io_mem_release_bits_data[30])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[30] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[31] && w15_s1_io_mem_release_bits_data[31])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[31] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[32] && w15_s1_io_mem_release_bits_data[32])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[32] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[33] && w15_s1_io_mem_release_bits_data[33])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[33] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[34] && w15_s1_io_mem_release_bits_data[34])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[34] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[35] && w15_s1_io_mem_release_bits_data[35])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[35] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[36] && w15_s1_io_mem_release_bits_data[36])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[36] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[37] && w15_s1_io_mem_release_bits_data[37])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[37] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[38] && w15_s1_io_mem_release_bits_data[38])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[38] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[39] && w15_s1_io_mem_release_bits_data[39])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[39] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[40] && w15_s1_io_mem_release_bits_data[40])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[40] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[41] && w15_s1_io_mem_release_bits_data[41])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[41] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[42] && w15_s1_io_mem_release_bits_data[42])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[42] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[43] && w15_s1_io_mem_release_bits_data[43])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[43] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[44] && w15_s1_io_mem_release_bits_data[44])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[44] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[45] && w15_s1_io_mem_release_bits_data[45])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[45] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[46] && w15_s1_io_mem_release_bits_data[46])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[46] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[47] && w15_s1_io_mem_release_bits_data[47])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[47] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[48] && w15_s1_io_mem_release_bits_data[48])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[48] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[49] && w15_s1_io_mem_release_bits_data[49])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[49] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[50] && w15_s1_io_mem_release_bits_data[50])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[50] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[51] && w15_s1_io_mem_release_bits_data[51])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[51] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[52] && w15_s1_io_mem_release_bits_data[52])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[52] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[53] && w15_s1_io_mem_release_bits_data[53])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[53] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[54] && w15_s1_io_mem_release_bits_data[54])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[54] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[55] && w15_s1_io_mem_release_bits_data[55])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[55] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[56] && w15_s1_io_mem_release_bits_data[56])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[56] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[57] && w15_s1_io_mem_release_bits_data[57])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[57] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[58] && w15_s1_io_mem_release_bits_data[58])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[58] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[59] && w15_s1_io_mem_release_bits_data[59])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[59] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[60] && w15_s1_io_mem_release_bits_data[60])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[60] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[61] && w15_s1_io_mem_release_bits_data[61])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[61] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[62] && w15_s1_io_mem_release_bits_data[62])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[62] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[63] && w15_s1_io_mem_release_bits_data[63])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[63] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[64] && w15_s1_io_mem_release_bits_data[64])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[64] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[65] && w15_s1_io_mem_release_bits_data[65])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[65] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[66] && w15_s1_io_mem_release_bits_data[66])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[66] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[67] && w15_s1_io_mem_release_bits_data[67])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[67] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[68] && w15_s1_io_mem_release_bits_data[68])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[68] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[69] && w15_s1_io_mem_release_bits_data[69])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[69] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[70] && w15_s1_io_mem_release_bits_data[70])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[70] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[71] && w15_s1_io_mem_release_bits_data[71])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[71] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[72] && w15_s1_io_mem_release_bits_data[72])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[72] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[73] && w15_s1_io_mem_release_bits_data[73])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[73] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[74] && w15_s1_io_mem_release_bits_data[74])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[74] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[75] && w15_s1_io_mem_release_bits_data[75])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[75] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[76] && w15_s1_io_mem_release_bits_data[76])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[76] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[77] && w15_s1_io_mem_release_bits_data[77])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[77] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[78] && w15_s1_io_mem_release_bits_data[78])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[78] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[79] && w15_s1_io_mem_release_bits_data[79])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[79] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[80] && w15_s1_io_mem_release_bits_data[80])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[80] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[81] && w15_s1_io_mem_release_bits_data[81])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[81] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[82] && w15_s1_io_mem_release_bits_data[82])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[82] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[83] && w15_s1_io_mem_release_bits_data[83])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[83] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[84] && w15_s1_io_mem_release_bits_data[84])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[84] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[85] && w15_s1_io_mem_release_bits_data[85])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[85] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[86] && w15_s1_io_mem_release_bits_data[86])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[86] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[87] && w15_s1_io_mem_release_bits_data[87])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[87] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[88] && w15_s1_io_mem_release_bits_data[88])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[88] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[89] && w15_s1_io_mem_release_bits_data[89])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[89] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[90] && w15_s1_io_mem_release_bits_data[90])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[90] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[91] && w15_s1_io_mem_release_bits_data[91])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[91] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[92] && w15_s1_io_mem_release_bits_data[92])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[92] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[93] && w15_s1_io_mem_release_bits_data[93])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[93] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[94] && w15_s1_io_mem_release_bits_data[94])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[94] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[95] && w15_s1_io_mem_release_bits_data[95])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[95] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[96] && w15_s1_io_mem_release_bits_data[96])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[96] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[97] && w15_s1_io_mem_release_bits_data[97])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[97] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[98] && w15_s1_io_mem_release_bits_data[98])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[98] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[99] && w15_s1_io_mem_release_bits_data[99])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[99] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[100] && w15_s1_io_mem_release_bits_data[100])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[100] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[101] && w15_s1_io_mem_release_bits_data[101])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[101] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[102] && w15_s1_io_mem_release_bits_data[102])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[102] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[103] && w15_s1_io_mem_release_bits_data[103])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[103] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[104] && w15_s1_io_mem_release_bits_data[104])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[104] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[105] && w15_s1_io_mem_release_bits_data[105])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[105] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[106] && w15_s1_io_mem_release_bits_data[106])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[106] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[107] && w15_s1_io_mem_release_bits_data[107])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[107] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[108] && w15_s1_io_mem_release_bits_data[108])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[108] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[109] && w15_s1_io_mem_release_bits_data[109])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[109] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[110] && w15_s1_io_mem_release_bits_data[110])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[110] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[111] && w15_s1_io_mem_release_bits_data[111])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[111] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[112] && w15_s1_io_mem_release_bits_data[112])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[112] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[113] && w15_s1_io_mem_release_bits_data[113])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[113] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[114] && w15_s1_io_mem_release_bits_data[114])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[114] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[115] && w15_s1_io_mem_release_bits_data[115])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[115] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[116] && w15_s1_io_mem_release_bits_data[116])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[116] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[117] && w15_s1_io_mem_release_bits_data[117])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[117] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[118] && w15_s1_io_mem_release_bits_data[118])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[118] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[119] && w15_s1_io_mem_release_bits_data[119])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[119] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[120] && w15_s1_io_mem_release_bits_data[120])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[120] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[121] && w15_s1_io_mem_release_bits_data[121])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[121] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[122] && w15_s1_io_mem_release_bits_data[122])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[122] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[123] && w15_s1_io_mem_release_bits_data[123])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[123] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[124] && w15_s1_io_mem_release_bits_data[124])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[124] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[125] && w15_s1_io_mem_release_bits_data[125])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[125] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[126] && w15_s1_io_mem_release_bits_data[126])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[126] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[127] && w15_s1_io_mem_release_bits_data[127])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[127] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[128] && w15_s1_io_mem_release_bits_data[128])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[128] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[129] && w15_s1_io_mem_release_bits_data[129])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[129] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[130] && w15_s1_io_mem_release_bits_data[130])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[130] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[131] && w15_s1_io_mem_release_bits_data[131])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[131] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[132] && w15_s1_io_mem_release_bits_data[132])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[132] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[133] && w15_s1_io_mem_release_bits_data[133])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[133] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[134] && w15_s1_io_mem_release_bits_data[134])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[134] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[135] && w15_s1_io_mem_release_bits_data[135])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[135] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[136] && w15_s1_io_mem_release_bits_data[136])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[136] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[137] && w15_s1_io_mem_release_bits_data[137])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[137] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[138] && w15_s1_io_mem_release_bits_data[138])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[138] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[139] && w15_s1_io_mem_release_bits_data[139])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[139] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[140] && w15_s1_io_mem_release_bits_data[140])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[140] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[141] && w15_s1_io_mem_release_bits_data[141])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[141] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[142] && w15_s1_io_mem_release_bits_data[142])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[142] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[143] && w15_s1_io_mem_release_bits_data[143])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[143] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[144] && w15_s1_io_mem_release_bits_data[144])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[144] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[145] && w15_s1_io_mem_release_bits_data[145])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[145] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[146] && w15_s1_io_mem_release_bits_data[146])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[146] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[147] && w15_s1_io_mem_release_bits_data[147])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[147] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[148] && w15_s1_io_mem_release_bits_data[148])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[148] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[149] && w15_s1_io_mem_release_bits_data[149])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[149] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[150] && w15_s1_io_mem_release_bits_data[150])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[150] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[151] && w15_s1_io_mem_release_bits_data[151])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[151] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[152] && w15_s1_io_mem_release_bits_data[152])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[152] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[153] && w15_s1_io_mem_release_bits_data[153])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[153] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[154] && w15_s1_io_mem_release_bits_data[154])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[154] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[155] && w15_s1_io_mem_release_bits_data[155])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[155] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[156] && w15_s1_io_mem_release_bits_data[156])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[156] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[157] && w15_s1_io_mem_release_bits_data[157])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[157] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[158] && w15_s1_io_mem_release_bits_data[158])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[158] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[159] && w15_s1_io_mem_release_bits_data[159])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[159] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[160] && w15_s1_io_mem_release_bits_data[160])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[160] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[161] && w15_s1_io_mem_release_bits_data[161])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[161] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[162] && w15_s1_io_mem_release_bits_data[162])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[162] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[163] && w15_s1_io_mem_release_bits_data[163])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[163] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[164] && w15_s1_io_mem_release_bits_data[164])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[164] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[165] && w15_s1_io_mem_release_bits_data[165])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[165] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[166] && w15_s1_io_mem_release_bits_data[166])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[166] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[167] && w15_s1_io_mem_release_bits_data[167])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[167] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[168] && w15_s1_io_mem_release_bits_data[168])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[168] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[169] && w15_s1_io_mem_release_bits_data[169])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[169] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[170] && w15_s1_io_mem_release_bits_data[170])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[170] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[171] && w15_s1_io_mem_release_bits_data[171])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[171] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[172] && w15_s1_io_mem_release_bits_data[172])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[172] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[173] && w15_s1_io_mem_release_bits_data[173])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[173] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[174] && w15_s1_io_mem_release_bits_data[174])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[174] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[175] && w15_s1_io_mem_release_bits_data[175])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[175] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[176] && w15_s1_io_mem_release_bits_data[176])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[176] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[177] && w15_s1_io_mem_release_bits_data[177])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[177] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[178] && w15_s1_io_mem_release_bits_data[178])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[178] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[179] && w15_s1_io_mem_release_bits_data[179])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[179] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[180] && w15_s1_io_mem_release_bits_data[180])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[180] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[181] && w15_s1_io_mem_release_bits_data[181])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[181] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[182] && w15_s1_io_mem_release_bits_data[182])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[182] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[183] && w15_s1_io_mem_release_bits_data[183])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[183] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[184] && w15_s1_io_mem_release_bits_data[184])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[184] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[185] && w15_s1_io_mem_release_bits_data[185])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[185] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[186] && w15_s1_io_mem_release_bits_data[186])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[186] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[187] && w15_s1_io_mem_release_bits_data[187])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[187] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[188] && w15_s1_io_mem_release_bits_data[188])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[188] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[189] && w15_s1_io_mem_release_bits_data[189])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[189] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[190] && w15_s1_io_mem_release_bits_data[190])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[190] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[191] && w15_s1_io_mem_release_bits_data[191])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[191] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[192] && w15_s1_io_mem_release_bits_data[192])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[192] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[193] && w15_s1_io_mem_release_bits_data[193])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[193] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[194] && w15_s1_io_mem_release_bits_data[194])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[194] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[195] && w15_s1_io_mem_release_bits_data[195])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[195] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[196] && w15_s1_io_mem_release_bits_data[196])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[196] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[197] && w15_s1_io_mem_release_bits_data[197])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[197] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[198] && w15_s1_io_mem_release_bits_data[198])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[198] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[199] && w15_s1_io_mem_release_bits_data[199])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[199] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[200] && w15_s1_io_mem_release_bits_data[200])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[200] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[201] && w15_s1_io_mem_release_bits_data[201])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[201] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[202] && w15_s1_io_mem_release_bits_data[202])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[202] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[203] && w15_s1_io_mem_release_bits_data[203])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[203] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[204] && w15_s1_io_mem_release_bits_data[204])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[204] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[205] && w15_s1_io_mem_release_bits_data[205])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[205] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[206] && w15_s1_io_mem_release_bits_data[206])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[206] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[207] && w15_s1_io_mem_release_bits_data[207])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[207] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[208] && w15_s1_io_mem_release_bits_data[208])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[208] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[209] && w15_s1_io_mem_release_bits_data[209])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[209] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[210] && w15_s1_io_mem_release_bits_data[210])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[210] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[211] && w15_s1_io_mem_release_bits_data[211])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[211] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[212] && w15_s1_io_mem_release_bits_data[212])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[212] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[213] && w15_s1_io_mem_release_bits_data[213])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[213] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[214] && w15_s1_io_mem_release_bits_data[214])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[214] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[215] && w15_s1_io_mem_release_bits_data[215])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[215] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[216] && w15_s1_io_mem_release_bits_data[216])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[216] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[217] && w15_s1_io_mem_release_bits_data[217])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[217] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[218] && w15_s1_io_mem_release_bits_data[218])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[218] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[219] && w15_s1_io_mem_release_bits_data[219])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[219] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[220] && w15_s1_io_mem_release_bits_data[220])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[220] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[221] && w15_s1_io_mem_release_bits_data[221])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[221] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[222] && w15_s1_io_mem_release_bits_data[222])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[222] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[223] && w15_s1_io_mem_release_bits_data[223])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[223] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[224] && w15_s1_io_mem_release_bits_data[224])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[224] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[225] && w15_s1_io_mem_release_bits_data[225])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[225] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[226] && w15_s1_io_mem_release_bits_data[226])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[226] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[227] && w15_s1_io_mem_release_bits_data[227])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[227] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[228] && w15_s1_io_mem_release_bits_data[228])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[228] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[229] && w15_s1_io_mem_release_bits_data[229])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[229] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[230] && w15_s1_io_mem_release_bits_data[230])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[230] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[231] && w15_s1_io_mem_release_bits_data[231])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[231] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[232] && w15_s1_io_mem_release_bits_data[232])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[232] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[233] && w15_s1_io_mem_release_bits_data[233])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[233] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[234] && w15_s1_io_mem_release_bits_data[234])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[234] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[235] && w15_s1_io_mem_release_bits_data[235])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[235] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[236] && w15_s1_io_mem_release_bits_data[236])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[236] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[237] && w15_s1_io_mem_release_bits_data[237])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[237] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[238] && w15_s1_io_mem_release_bits_data[238])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[238] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[239] && w15_s1_io_mem_release_bits_data[239])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[239] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[240] && w15_s1_io_mem_release_bits_data[240])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[240] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[241] && w15_s1_io_mem_release_bits_data[241])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[241] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[242] && w15_s1_io_mem_release_bits_data[242])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[242] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[243] && w15_s1_io_mem_release_bits_data[243])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[243] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[244] && w15_s1_io_mem_release_bits_data[244])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[244] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[245] && w15_s1_io_mem_release_bits_data[245])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[245] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[246] && w15_s1_io_mem_release_bits_data[246])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[246] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[247] && w15_s1_io_mem_release_bits_data[247])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[247] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[248] && w15_s1_io_mem_release_bits_data[248])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[248] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[249] && w15_s1_io_mem_release_bits_data[249])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[249] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[250] && w15_s1_io_mem_release_bits_data[250])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[250] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[251] && w15_s1_io_mem_release_bits_data[251])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[251] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[252] && w15_s1_io_mem_release_bits_data[252])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[252] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[253] && w15_s1_io_mem_release_bits_data[253])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[253] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[254] && w15_s1_io_mem_release_bits_data[254])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[254] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_data[255] && w15_s1_io_mem_release_bits_data[255])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_data[255] 未见过 0 和 1"); end
    if (!(w15_s0_io_mem_release_bits_corrupt && w15_s1_io_mem_release_bits_corrupt)) begin cov_fail++; $display("[COV] WritebackEntry_15.io_mem_release_bits_corrupt 未见过 0 和 1"); end
    if (!(w15_s0_io_primary_ready && w15_s1_io_primary_ready)) begin cov_fail++; $display("[COV] WritebackEntry_15.io_primary_ready 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_valid && w15_s1_io_block_addr_valid)) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_valid 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[0] && w15_s1_io_block_addr_bits[0])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[0] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[1] && w15_s1_io_block_addr_bits[1])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[1] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[2] && w15_s1_io_block_addr_bits[2])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[2] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[3] && w15_s1_io_block_addr_bits[3])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[3] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[4] && w15_s1_io_block_addr_bits[4])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[4] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[5] && w15_s1_io_block_addr_bits[5])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[5] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[6] && w15_s1_io_block_addr_bits[6])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[6] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[7] && w15_s1_io_block_addr_bits[7])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[7] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[8] && w15_s1_io_block_addr_bits[8])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[8] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[9] && w15_s1_io_block_addr_bits[9])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[9] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[10] && w15_s1_io_block_addr_bits[10])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[10] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[11] && w15_s1_io_block_addr_bits[11])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[11] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[12] && w15_s1_io_block_addr_bits[12])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[12] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[13] && w15_s1_io_block_addr_bits[13])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[13] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[14] && w15_s1_io_block_addr_bits[14])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[14] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[15] && w15_s1_io_block_addr_bits[15])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[15] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[16] && w15_s1_io_block_addr_bits[16])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[16] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[17] && w15_s1_io_block_addr_bits[17])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[17] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[18] && w15_s1_io_block_addr_bits[18])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[18] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[19] && w15_s1_io_block_addr_bits[19])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[19] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[20] && w15_s1_io_block_addr_bits[20])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[20] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[21] && w15_s1_io_block_addr_bits[21])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[21] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[22] && w15_s1_io_block_addr_bits[22])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[22] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[23] && w15_s1_io_block_addr_bits[23])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[23] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[24] && w15_s1_io_block_addr_bits[24])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[24] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[25] && w15_s1_io_block_addr_bits[25])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[25] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[26] && w15_s1_io_block_addr_bits[26])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[26] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[27] && w15_s1_io_block_addr_bits[27])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[27] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[28] && w15_s1_io_block_addr_bits[28])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[28] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[29] && w15_s1_io_block_addr_bits[29])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[29] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[30] && w15_s1_io_block_addr_bits[30])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[30] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[31] && w15_s1_io_block_addr_bits[31])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[31] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[32] && w15_s1_io_block_addr_bits[32])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[32] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[33] && w15_s1_io_block_addr_bits[33])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[33] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[34] && w15_s1_io_block_addr_bits[34])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[34] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[35] && w15_s1_io_block_addr_bits[35])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[35] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[36] && w15_s1_io_block_addr_bits[36])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[36] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[37] && w15_s1_io_block_addr_bits[37])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[37] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[38] && w15_s1_io_block_addr_bits[38])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[38] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[39] && w15_s1_io_block_addr_bits[39])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[39] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[40] && w15_s1_io_block_addr_bits[40])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[40] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[41] && w15_s1_io_block_addr_bits[41])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[41] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[42] && w15_s1_io_block_addr_bits[42])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[42] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[43] && w15_s1_io_block_addr_bits[43])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[43] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[44] && w15_s1_io_block_addr_bits[44])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[44] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[45] && w15_s1_io_block_addr_bits[45])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[45] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[46] && w15_s1_io_block_addr_bits[46])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[46] 未见过 0 和 1"); end
    if (!(w15_s0_io_block_addr_bits[47] && w15_s1_io_block_addr_bits[47])) begin cov_fail++; $display("[COV] WritebackEntry_15.io_block_addr_bits[47] 未见过 0 和 1"); end
    $display("[ARM] WritebackEntry_15 armed_at=%0d", w15_armed_at);
    if (w15_armed_at < 0) begin cov_fail++; $display("[ARM] WritebackEntry_15 从未 arm"); end
    $display("[COV] WritebackEntry_15.alloc = %0d", w15_cov_alloc);
    if (w15_cov_alloc < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.alloc < 50"); end
    $display("[COV] WritebackEntry_15.probeack = %0d", w15_cov_probeack);
    if (w15_cov_probeack < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.probeack < 50"); end
    $display("[COV] WritebackEntry_15.probeackdata = %0d", w15_cov_probeackdata);
    if (w15_cov_probeackdata < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.probeackdata < 50"); end
    $display("[COV] WritebackEntry_15.release = %0d", w15_cov_release);
    if (w15_cov_release < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.release < 50"); end
    $display("[COV] WritebackEntry_15.releasedata = %0d", w15_cov_releasedata);
    if (w15_cov_releasedata < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.releasedata < 50"); end
    $display("[COV] WritebackEntry_15.release_stall = %0d", w15_cov_release_stall);
    if (w15_cov_release_stall < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.release_stall < 50"); end
    $display("[COV] WritebackEntry_15.wait_grant = %0d", w15_cov_wait_grant);
    if (w15_cov_wait_grant < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.wait_grant < 50"); end
    $display("[COV] WritebackEntry_15.grant_done = %0d", w15_cov_grant_done);
    if (w15_cov_grant_done < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.grant_done < 50"); end
    $display("[COV] WritebackEntry_15.reset_mid = %0d", w15_cov_reset_mid);
    if (w15_cov_reset_mid < 50) begin cov_fail++; $display("[COV] WritebackEntry_15.reset_mid < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
