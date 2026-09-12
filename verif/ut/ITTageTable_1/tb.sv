// 自动生成：scripts/gen_zj_ut.py ITTageTable_1 —— 勿手改
// ITTageTable_1 双例化逐拍比对：golden ITTageTable_1 vs 重写 ITTageTable_1_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 120000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 120000;
  localparam int unsigned MIN_TOGGLED = 9;
  localparam int unsigned MIN_FIRES   = 20000;
  localparam int unsigned N_OUT       = 9;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_req_valid;
  logic [49:0] io_req_bits_pc;
  logic [7:0] io_req_bits_folded_hist_hist_14_folded_hist;
  logic [49:0] io_update_pc;
  logic [255:0] io_update_ghist;
  logic io_update_valid;
  logic io_update_correct;
  logic io_update_alloc;
  logic [1:0] io_update_oldCtr;
  logic io_update_uValid;
  logic io_update_u;
  logic io_update_reset_u;
  logic [19:0] io_update_target_offset_offset;
  logic [3:0] io_update_target_offset_pointer;
  logic io_update_target_offset_usePCRegion;
  logic [19:0] io_update_old_target_offset_offset;
  logic [3:0] io_update_old_target_offset_pointer;
  logic io_update_old_target_offset_usePCRegion;
  logic [6:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [75:0] boreChildrenBd_bore_be;
  logic [7:0] boreChildrenBd_bore_addr;
  logic [75:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [7:0] boreChildrenBd_bore_addr_rd;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;

  wire g_io_req_ready;
  wire i_io_req_ready;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire [1:0] g_io_resp_bits_ctr;
  wire [1:0] i_io_resp_bits_ctr;
  wire g_io_resp_bits_u;
  wire i_io_resp_bits_u;
  wire [19:0] g_io_resp_bits_target_offset_offset;
  wire [19:0] i_io_resp_bits_target_offset_offset;
  wire [3:0] g_io_resp_bits_target_offset_pointer;
  wire [3:0] i_io_resp_bits_target_offset_pointer;
  wire g_io_resp_bits_target_offset_usePCRegion;
  wire i_io_resp_bits_target_offset_usePCRegion;
  wire g_boreChildrenBd_bore_ack;
  wire i_boreChildrenBd_bore_ack;
  wire [75:0] g_boreChildrenBd_bore_outdata;
  wire [75:0] i_boreChildrenBd_bore_outdata;

  logic p_io_req_ready;   // 上一拍值（toggle 统计）
  bit tog_io_req_ready;
  logic p_io_resp_valid;   // 上一拍值（toggle 统计）
  bit tog_io_resp_valid;
  logic [1:0] p_io_resp_bits_ctr;   // 上一拍值（toggle 统计）
  bit tog_io_resp_bits_ctr;
  logic p_io_resp_bits_u;   // 上一拍值（toggle 统计）
  bit tog_io_resp_bits_u;
  logic [19:0] p_io_resp_bits_target_offset_offset;   // 上一拍值（toggle 统计）
  bit tog_io_resp_bits_target_offset_offset;
  logic [3:0] p_io_resp_bits_target_offset_pointer;   // 上一拍值（toggle 统计）
  bit tog_io_resp_bits_target_offset_pointer;
  logic p_io_resp_bits_target_offset_usePCRegion;   // 上一拍值（toggle 统计）
  bit tog_io_resp_bits_target_offset_usePCRegion;
  logic p_boreChildrenBd_bore_ack;   // 上一拍值（toggle 统计）
  bit tog_boreChildrenBd_bore_ack;
  logic [75:0] p_boreChildrenBd_bore_outdata;   // 上一拍值（toggle 统计）
  bit tog_boreChildrenBd_bore_outdata;

  ITTageTable_1 u_g (
    .clock(clock),
    .reset(reset),
    .io_req_ready(g_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_bits_folded_hist_hist_14_folded_hist(io_req_bits_folded_hist_hist_14_folded_hist),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_bits_ctr(g_io_resp_bits_ctr),
    .io_resp_bits_u(g_io_resp_bits_u),
    .io_resp_bits_target_offset_offset(g_io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(g_io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(g_io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc),
    .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid),
    .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc),
    .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid),
    .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );
  ITTageTable_1_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_req_ready(i_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc),
    .io_req_bits_folded_hist_hist_14_folded_hist(io_req_bits_folded_hist_hist_14_folded_hist),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_bits_ctr(i_io_resp_bits_ctr),
    .io_resp_bits_u(i_io_resp_bits_u),
    .io_resp_bits_target_offset_offset(i_io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(i_io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(i_io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(io_update_pc),
    .io_update_ghist(io_update_ghist),
    .io_update_valid(io_update_valid),
    .io_update_correct(io_update_correct),
    .io_update_alloc(io_update_alloc),
    .io_update_oldCtr(io_update_oldCtr),
    .io_update_uValid(io_update_uValid),
    .io_update_u(io_update_u),
    .io_update_reset_u(io_update_reset_u),
    .io_update_target_offset_offset(io_update_target_offset_offset),
    .io_update_target_offset_pointer(io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(io_update_old_target_offset_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );

  task automatic drive_random();
    io_req_valid = $urandom % 2;
    io_req_bits_pc = rnd(50);
    io_req_bits_folded_hist_hist_14_folded_hist = rnd(8);
    io_update_pc = rnd(50);
    io_update_ghist = rnd(256);
    io_update_valid = $urandom % 2;
    io_update_correct = $urandom % 2;
    io_update_alloc = $urandom % 2;
    io_update_oldCtr = rnd(2);
    io_update_uValid = $urandom % 2;
    io_update_u = $urandom % 2;
    io_update_reset_u = $urandom % 2;
    io_update_target_offset_offset = rnd(20);
    io_update_target_offset_pointer = rnd(4);
    io_update_target_offset_usePCRegion = $urandom % 2;
    io_update_old_target_offset_offset = rnd(20);
    io_update_old_target_offset_pointer = rnd(4);
    io_update_old_target_offset_usePCRegion = $urandom % 2;
    boreChildrenBd_bore_array = rnd(7);
    boreChildrenBd_bore_all = $urandom % 2;
    boreChildrenBd_bore_req = $urandom % 2;
    boreChildrenBd_bore_writeen = $urandom % 2;
    boreChildrenBd_bore_be = rnd(76);
    boreChildrenBd_bore_addr = rnd(8);
    boreChildrenBd_bore_indata = rnd(76);
    boreChildrenBd_bore_readen = $urandom % 2;
    boreChildrenBd_bore_addr_rd = rnd(8);
    sigFromSrams_bore_ram_hold = $urandom % 2;
    sigFromSrams_bore_ram_bypass = $urandom % 2;
    sigFromSrams_bore_ram_bp_clken = $urandom % 2;
    sigFromSrams_bore_ram_aux_clk = $urandom % 2;
    sigFromSrams_bore_ram_aux_ckbp = $urandom % 2;
    sigFromSrams_bore_ram_mcp_hold = $urandom % 2;
    sigFromSrams_bore_cgen = $urandom % 2;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_req_ready)) begin
      checks++;
      if (g_io_req_ready !== i_io_req_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_req_ready g=%0h i=%0h", $time, g_io_req_ready, i_io_req_ready);
      end
    end
    if (!$isunknown(g_io_resp_valid)) begin
      checks++;
      if (g_io_resp_valid !== i_io_resp_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_resp_valid g=%0h i=%0h", $time, g_io_resp_valid, i_io_resp_valid);
      end
    end
    if (!$isunknown(g_io_resp_bits_ctr)) begin
      checks++;
      if (g_io_resp_bits_ctr !== i_io_resp_bits_ctr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_resp_bits_ctr g=%0h i=%0h", $time, g_io_resp_bits_ctr, i_io_resp_bits_ctr);
      end
    end
    if (!$isunknown(g_io_resp_bits_u)) begin
      checks++;
      if (g_io_resp_bits_u !== i_io_resp_bits_u) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_resp_bits_u g=%0h i=%0h", $time, g_io_resp_bits_u, i_io_resp_bits_u);
      end
    end
    if (!$isunknown(g_io_resp_bits_target_offset_offset)) begin
      checks++;
      if (g_io_resp_bits_target_offset_offset !== i_io_resp_bits_target_offset_offset) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_resp_bits_target_offset_offset g=%0h i=%0h", $time, g_io_resp_bits_target_offset_offset, i_io_resp_bits_target_offset_offset);
      end
    end
    if (!$isunknown(g_io_resp_bits_target_offset_pointer)) begin
      checks++;
      if (g_io_resp_bits_target_offset_pointer !== i_io_resp_bits_target_offset_pointer) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_resp_bits_target_offset_pointer g=%0h i=%0h", $time, g_io_resp_bits_target_offset_pointer, i_io_resp_bits_target_offset_pointer);
      end
    end
    if (!$isunknown(g_io_resp_bits_target_offset_usePCRegion)) begin
      checks++;
      if (g_io_resp_bits_target_offset_usePCRegion !== i_io_resp_bits_target_offset_usePCRegion) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_resp_bits_target_offset_usePCRegion g=%0h i=%0h", $time, g_io_resp_bits_target_offset_usePCRegion, i_io_resp_bits_target_offset_usePCRegion);
      end
    end
    if (!$isunknown(g_boreChildrenBd_bore_ack)) begin
      checks++;
      if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH boreChildrenBd_bore_ack g=%0h i=%0h", $time, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack);
      end
    end
    if (!$isunknown(g_boreChildrenBd_bore_outdata)) begin
      checks++;
      if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH boreChildrenBd_bore_outdata g=%0h i=%0h", $time, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_req_ready !== p_io_req_ready) tog_io_req_ready = 1'b1;
    p_io_req_ready = g_io_req_ready;
    if (g_io_resp_valid !== p_io_resp_valid) tog_io_resp_valid = 1'b1;
    p_io_resp_valid = g_io_resp_valid;
    if (g_io_resp_bits_ctr !== p_io_resp_bits_ctr) tog_io_resp_bits_ctr = 1'b1;
    p_io_resp_bits_ctr = g_io_resp_bits_ctr;
    if (g_io_resp_bits_u !== p_io_resp_bits_u) tog_io_resp_bits_u = 1'b1;
    p_io_resp_bits_u = g_io_resp_bits_u;
    if (g_io_resp_bits_target_offset_offset !== p_io_resp_bits_target_offset_offset) tog_io_resp_bits_target_offset_offset = 1'b1;
    p_io_resp_bits_target_offset_offset = g_io_resp_bits_target_offset_offset;
    if (g_io_resp_bits_target_offset_pointer !== p_io_resp_bits_target_offset_pointer) tog_io_resp_bits_target_offset_pointer = 1'b1;
    p_io_resp_bits_target_offset_pointer = g_io_resp_bits_target_offset_pointer;
    if (g_io_resp_bits_target_offset_usePCRegion !== p_io_resp_bits_target_offset_usePCRegion) tog_io_resp_bits_target_offset_usePCRegion = 1'b1;
    p_io_resp_bits_target_offset_usePCRegion = g_io_resp_bits_target_offset_usePCRegion;
    if (g_boreChildrenBd_bore_ack !== p_boreChildrenBd_bore_ack) tog_boreChildrenBd_bore_ack = 1'b1;
    p_boreChildrenBd_bore_ack = g_boreChildrenBd_bore_ack;
    if (g_boreChildrenBd_bore_outdata !== p_boreChildrenBd_bore_outdata) tog_boreChildrenBd_bore_outdata = 1'b1;
    p_boreChildrenBd_bore_outdata = g_boreChildrenBd_bore_outdata;
    if ((g_io_req_ready && io_req_valid)) fires++;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_req_valid = '0;
    io_req_bits_pc = '0;
    io_req_bits_folded_hist_hist_14_folded_hist = '0;
    io_update_pc = '0;
    io_update_ghist = '0;
    io_update_valid = '0;
    io_update_correct = '0;
    io_update_alloc = '0;
    io_update_oldCtr = '0;
    io_update_uValid = '0;
    io_update_u = '0;
    io_update_reset_u = '0;
    io_update_target_offset_offset = '0;
    io_update_target_offset_pointer = '0;
    io_update_target_offset_usePCRegion = '0;
    io_update_old_target_offset_offset = '0;
    io_update_old_target_offset_pointer = '0;
    io_update_old_target_offset_usePCRegion = '0;
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    p_io_req_ready = '0; tog_io_req_ready = 1'b0;
    p_io_resp_valid = '0; tog_io_resp_valid = 1'b0;
    p_io_resp_bits_ctr = '0; tog_io_resp_bits_ctr = 1'b0;
    p_io_resp_bits_u = '0; tog_io_resp_bits_u = 1'b0;
    p_io_resp_bits_target_offset_offset = '0; tog_io_resp_bits_target_offset_offset = 1'b0;
    p_io_resp_bits_target_offset_pointer = '0; tog_io_resp_bits_target_offset_pointer = 1'b0;
    p_io_resp_bits_target_offset_usePCRegion = '0; tog_io_resp_bits_target_offset_usePCRegion = 1'b0;
    p_boreChildrenBd_bore_ack = '0; tog_boreChildrenBd_bore_ack = 1'b0;
    p_boreChildrenBd_bore_outdata = '0; tog_boreChildrenBd_bore_outdata = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_req_ready) toggled++; else $display("COV: output io_req_ready never toggled");
    if (tog_io_resp_valid) toggled++; else $display("COV: output io_resp_valid never toggled");
    if (tog_io_resp_bits_ctr) toggled++; else $display("COV: output io_resp_bits_ctr never toggled");
    if (tog_io_resp_bits_u) toggled++; else $display("COV: output io_resp_bits_u never toggled");
    if (tog_io_resp_bits_target_offset_offset) toggled++; else $display("COV: output io_resp_bits_target_offset_offset never toggled");
    if (tog_io_resp_bits_target_offset_pointer) toggled++; else $display("COV: output io_resp_bits_target_offset_pointer never toggled");
    if (tog_io_resp_bits_target_offset_usePCRegion) toggled++; else $display("COV: output io_resp_bits_target_offset_usePCRegion never toggled");
    if (tog_boreChildrenBd_bore_ack) toggled++; else $display("COV: output boreChildrenBd_bore_ack never toggled");
    if (tog_boreChildrenBd_bore_outdata) toggled++; else $display("COV: output boreChildrenBd_bore_outdata never toggled");
    $display("ITTageTable_1 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    if (fires < MIN_FIRES) begin $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, MIN_FIRES); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
