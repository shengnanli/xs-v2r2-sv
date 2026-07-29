// OpenNCB_1 UT: dual-instantiate golden OpenNCB_1 vs xs 影子核, 逐拍比对全部 output。
`timescale 1ns/1ps
module tb;
  reg clock=0, reset=1;
  integer i, errors=0, checks=0;
  integer seed;
  initial begin
    if (!$value$plusargs("seed=%d", seed)) seed = 1;
    $display("OpenNCB_1 UT seed=%0d", seed);
  end
  always #5 clock = ~clock;

  reg auto_axi4_out_aw_ready;
  reg auto_axi4_out_w_ready;
  reg auto_axi4_out_b_valid;
  reg [4:0] auto_axi4_out_b_bits_id;
  reg auto_axi4_out_ar_ready;
  reg auto_axi4_out_r_valid;
  reg [4:0] auto_axi4_out_r_bits_id;
  reg [255:0] auto_axi4_out_r_bits_data;
  reg auto_axi4_out_r_bits_last;
  reg io_chi_txsactive;
  reg io_chi_tx_linkactivereq;
  reg io_chi_tx_req_flitpend;
  reg io_chi_tx_req_flitv;
  reg [161:0] io_chi_tx_req_flit;
  reg io_chi_tx_dat_flitpend;
  reg io_chi_tx_dat_flitv;
  reg [421:0] io_chi_tx_dat_flit;
  reg io_chi_rx_linkactiveack;
  reg io_chi_rx_rsp_lcrdv;
  reg io_chi_rx_dat_lcrdv;

  wire g_auto_axi4_out_aw_valid, x_auto_axi4_out_aw_valid;
  wire [4:0] g_auto_axi4_out_aw_bits_id, x_auto_axi4_out_aw_bits_id;
  wire [48:0] g_auto_axi4_out_aw_bits_addr, x_auto_axi4_out_aw_bits_addr;
  wire [7:0] g_auto_axi4_out_aw_bits_len, x_auto_axi4_out_aw_bits_len;
  wire [2:0] g_auto_axi4_out_aw_bits_size, x_auto_axi4_out_aw_bits_size;
  wire [1:0] g_auto_axi4_out_aw_bits_burst, x_auto_axi4_out_aw_bits_burst;
  wire [3:0] g_auto_axi4_out_aw_bits_cache, x_auto_axi4_out_aw_bits_cache;
  wire [3:0] g_auto_axi4_out_aw_bits_qos, x_auto_axi4_out_aw_bits_qos;
  wire g_auto_axi4_out_w_valid, x_auto_axi4_out_w_valid;
  wire [255:0] g_auto_axi4_out_w_bits_data, x_auto_axi4_out_w_bits_data;
  wire [31:0] g_auto_axi4_out_w_bits_strb, x_auto_axi4_out_w_bits_strb;
  wire g_auto_axi4_out_w_bits_last, x_auto_axi4_out_w_bits_last;
  wire g_auto_axi4_out_ar_valid, x_auto_axi4_out_ar_valid;
  wire [4:0] g_auto_axi4_out_ar_bits_id, x_auto_axi4_out_ar_bits_id;
  wire [48:0] g_auto_axi4_out_ar_bits_addr, x_auto_axi4_out_ar_bits_addr;
  wire [7:0] g_auto_axi4_out_ar_bits_len, x_auto_axi4_out_ar_bits_len;
  wire [2:0] g_auto_axi4_out_ar_bits_size, x_auto_axi4_out_ar_bits_size;
  wire [1:0] g_auto_axi4_out_ar_bits_burst, x_auto_axi4_out_ar_bits_burst;
  wire [3:0] g_auto_axi4_out_ar_bits_cache, x_auto_axi4_out_ar_bits_cache;
  wire [3:0] g_auto_axi4_out_ar_bits_qos, x_auto_axi4_out_ar_bits_qos;
  wire g_io_chi_rxsactive, x_io_chi_rxsactive;
  wire g_io_chi_tx_linkactiveack, x_io_chi_tx_linkactiveack;
  wire g_io_chi_tx_req_lcrdv, x_io_chi_tx_req_lcrdv;
  wire g_io_chi_tx_dat_lcrdv, x_io_chi_tx_dat_lcrdv;
  wire g_io_chi_rx_linkactivereq, x_io_chi_rx_linkactivereq;
  wire g_io_chi_rx_rsp_flitpend, x_io_chi_rx_rsp_flitpend;
  wire g_io_chi_rx_rsp_flitv, x_io_chi_rx_rsp_flitv;
  wire [72:0] g_io_chi_rx_rsp_flit, x_io_chi_rx_rsp_flit;
  wire g_io_chi_rx_dat_flitpend, x_io_chi_rx_dat_flitpend;
  wire g_io_chi_rx_dat_flitv, x_io_chi_rx_dat_flitv;
  wire [421:0] g_io_chi_rx_dat_flit, x_io_chi_rx_dat_flit;

  OpenNCB_1 u_g (
    .clock(clock), .reset(reset),
    .auto_axi4_out_aw_ready(auto_axi4_out_aw_ready),
    .auto_axi4_out_w_ready(auto_axi4_out_w_ready),
    .auto_axi4_out_b_valid(auto_axi4_out_b_valid),
    .auto_axi4_out_b_bits_id(auto_axi4_out_b_bits_id),
    .auto_axi4_out_ar_ready(auto_axi4_out_ar_ready),
    .auto_axi4_out_r_valid(auto_axi4_out_r_valid),
    .auto_axi4_out_r_bits_id(auto_axi4_out_r_bits_id),
    .auto_axi4_out_r_bits_data(auto_axi4_out_r_bits_data),
    .auto_axi4_out_r_bits_last(auto_axi4_out_r_bits_last),
    .io_chi_txsactive(io_chi_txsactive),
    .io_chi_tx_linkactivereq(io_chi_tx_linkactivereq),
    .io_chi_tx_req_flitpend(io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv(io_chi_tx_req_flitv),
    .io_chi_tx_req_flit(io_chi_tx_req_flit),
    .io_chi_tx_dat_flitpend(io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv(io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit(io_chi_tx_dat_flit),
    .io_chi_rx_linkactiveack(io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_lcrdv(io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_lcrdv(io_chi_rx_dat_lcrdv),
    .auto_axi4_out_aw_valid(g_auto_axi4_out_aw_valid),
    .auto_axi4_out_aw_bits_id(g_auto_axi4_out_aw_bits_id),
    .auto_axi4_out_aw_bits_addr(g_auto_axi4_out_aw_bits_addr),
    .auto_axi4_out_aw_bits_len(g_auto_axi4_out_aw_bits_len),
    .auto_axi4_out_aw_bits_size(g_auto_axi4_out_aw_bits_size),
    .auto_axi4_out_aw_bits_burst(g_auto_axi4_out_aw_bits_burst),
    .auto_axi4_out_aw_bits_cache(g_auto_axi4_out_aw_bits_cache),
    .auto_axi4_out_aw_bits_qos(g_auto_axi4_out_aw_bits_qos),
    .auto_axi4_out_w_valid(g_auto_axi4_out_w_valid),
    .auto_axi4_out_w_bits_data(g_auto_axi4_out_w_bits_data),
    .auto_axi4_out_w_bits_strb(g_auto_axi4_out_w_bits_strb),
    .auto_axi4_out_w_bits_last(g_auto_axi4_out_w_bits_last),
    .auto_axi4_out_ar_valid(g_auto_axi4_out_ar_valid),
    .auto_axi4_out_ar_bits_id(g_auto_axi4_out_ar_bits_id),
    .auto_axi4_out_ar_bits_addr(g_auto_axi4_out_ar_bits_addr),
    .auto_axi4_out_ar_bits_len(g_auto_axi4_out_ar_bits_len),
    .auto_axi4_out_ar_bits_size(g_auto_axi4_out_ar_bits_size),
    .auto_axi4_out_ar_bits_burst(g_auto_axi4_out_ar_bits_burst),
    .auto_axi4_out_ar_bits_cache(g_auto_axi4_out_ar_bits_cache),
    .auto_axi4_out_ar_bits_qos(g_auto_axi4_out_ar_bits_qos),
    .io_chi_rxsactive(g_io_chi_rxsactive),
    .io_chi_tx_linkactiveack(g_io_chi_tx_linkactiveack),
    .io_chi_tx_req_lcrdv(g_io_chi_tx_req_lcrdv),
    .io_chi_tx_dat_lcrdv(g_io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq(g_io_chi_rx_linkactivereq),
    .io_chi_rx_rsp_flitpend(g_io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv(g_io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit(g_io_chi_rx_rsp_flit),
    .io_chi_rx_dat_flitpend(g_io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv(g_io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit(g_io_chi_rx_dat_flit)
  );
  OpenNCB_1_xs u_x (
    .clock(clock), .reset(reset),
    .auto_axi4_out_aw_ready(auto_axi4_out_aw_ready),
    .auto_axi4_out_w_ready(auto_axi4_out_w_ready),
    .auto_axi4_out_b_valid(auto_axi4_out_b_valid),
    .auto_axi4_out_b_bits_id(auto_axi4_out_b_bits_id),
    .auto_axi4_out_ar_ready(auto_axi4_out_ar_ready),
    .auto_axi4_out_r_valid(auto_axi4_out_r_valid),
    .auto_axi4_out_r_bits_id(auto_axi4_out_r_bits_id),
    .auto_axi4_out_r_bits_data(auto_axi4_out_r_bits_data),
    .auto_axi4_out_r_bits_last(auto_axi4_out_r_bits_last),
    .io_chi_txsactive(io_chi_txsactive),
    .io_chi_tx_linkactivereq(io_chi_tx_linkactivereq),
    .io_chi_tx_req_flitpend(io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv(io_chi_tx_req_flitv),
    .io_chi_tx_req_flit(io_chi_tx_req_flit),
    .io_chi_tx_dat_flitpend(io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv(io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit(io_chi_tx_dat_flit),
    .io_chi_rx_linkactiveack(io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_lcrdv(io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_lcrdv(io_chi_rx_dat_lcrdv),
    .auto_axi4_out_aw_valid(x_auto_axi4_out_aw_valid),
    .auto_axi4_out_aw_bits_id(x_auto_axi4_out_aw_bits_id),
    .auto_axi4_out_aw_bits_addr(x_auto_axi4_out_aw_bits_addr),
    .auto_axi4_out_aw_bits_len(x_auto_axi4_out_aw_bits_len),
    .auto_axi4_out_aw_bits_size(x_auto_axi4_out_aw_bits_size),
    .auto_axi4_out_aw_bits_burst(x_auto_axi4_out_aw_bits_burst),
    .auto_axi4_out_aw_bits_cache(x_auto_axi4_out_aw_bits_cache),
    .auto_axi4_out_aw_bits_qos(x_auto_axi4_out_aw_bits_qos),
    .auto_axi4_out_w_valid(x_auto_axi4_out_w_valid),
    .auto_axi4_out_w_bits_data(x_auto_axi4_out_w_bits_data),
    .auto_axi4_out_w_bits_strb(x_auto_axi4_out_w_bits_strb),
    .auto_axi4_out_w_bits_last(x_auto_axi4_out_w_bits_last),
    .auto_axi4_out_ar_valid(x_auto_axi4_out_ar_valid),
    .auto_axi4_out_ar_bits_id(x_auto_axi4_out_ar_bits_id),
    .auto_axi4_out_ar_bits_addr(x_auto_axi4_out_ar_bits_addr),
    .auto_axi4_out_ar_bits_len(x_auto_axi4_out_ar_bits_len),
    .auto_axi4_out_ar_bits_size(x_auto_axi4_out_ar_bits_size),
    .auto_axi4_out_ar_bits_burst(x_auto_axi4_out_ar_bits_burst),
    .auto_axi4_out_ar_bits_cache(x_auto_axi4_out_ar_bits_cache),
    .auto_axi4_out_ar_bits_qos(x_auto_axi4_out_ar_bits_qos),
    .io_chi_rxsactive(x_io_chi_rxsactive),
    .io_chi_tx_linkactiveack(x_io_chi_tx_linkactiveack),
    .io_chi_tx_req_lcrdv(x_io_chi_tx_req_lcrdv),
    .io_chi_tx_dat_lcrdv(x_io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq(x_io_chi_rx_linkactivereq),
    .io_chi_rx_rsp_flitpend(x_io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv(x_io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit(x_io_chi_rx_rsp_flit),
    .io_chi_rx_dat_flitpend(x_io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv(x_io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit(x_io_chi_rx_dat_flit)
  );

  task drive_random;
    begin
      auto_axi4_out_aw_ready = $random(seed);
      auto_axi4_out_w_ready = $random(seed);
      auto_axi4_out_b_valid = $random(seed);
      auto_axi4_out_b_bits_id = $random(seed);
      auto_axi4_out_ar_ready = $random(seed);
      auto_axi4_out_r_valid = $random(seed);
      auto_axi4_out_r_bits_id = $random(seed);
      auto_axi4_out_r_bits_data = {$random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed)};
      auto_axi4_out_r_bits_last = $random(seed);
      io_chi_txsactive = $random(seed);
      io_chi_tx_linkactivereq = $random(seed);
      io_chi_tx_req_flitpend = $random(seed);
      io_chi_tx_req_flitv = $random(seed);
      io_chi_tx_req_flit = {$random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed)};
      io_chi_tx_dat_flitpend = $random(seed);
      io_chi_tx_dat_flitv = $random(seed);
      io_chi_tx_dat_flit = {$random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed) , $random(seed)};
      io_chi_rx_linkactiveack = $random(seed);
      io_chi_rx_rsp_lcrdv = $random(seed);
      io_chi_rx_dat_lcrdv = $random(seed);
    end
  endtask

  task check_outputs;
    begin
      checks = checks + 1;
      if (x_auto_axi4_out_aw_valid !== g_auto_axi4_out_aw_valid) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_valid: xs=%h golden=%h", $time, x_auto_axi4_out_aw_valid, g_auto_axi4_out_aw_valid); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_id !== g_auto_axi4_out_aw_bits_id) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_id: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_id, g_auto_axi4_out_aw_bits_id); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_addr !== g_auto_axi4_out_aw_bits_addr) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_addr: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_addr, g_auto_axi4_out_aw_bits_addr); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_len !== g_auto_axi4_out_aw_bits_len) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_len: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_len, g_auto_axi4_out_aw_bits_len); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_size !== g_auto_axi4_out_aw_bits_size) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_size: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_size, g_auto_axi4_out_aw_bits_size); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_burst !== g_auto_axi4_out_aw_bits_burst) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_burst: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_burst, g_auto_axi4_out_aw_bits_burst); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_cache !== g_auto_axi4_out_aw_bits_cache) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_cache: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_cache, g_auto_axi4_out_aw_bits_cache); end
      checks = checks + 1;
      if (x_auto_axi4_out_aw_bits_qos !== g_auto_axi4_out_aw_bits_qos) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_aw_bits_qos: xs=%h golden=%h", $time, x_auto_axi4_out_aw_bits_qos, g_auto_axi4_out_aw_bits_qos); end
      checks = checks + 1;
      if (x_auto_axi4_out_w_valid !== g_auto_axi4_out_w_valid) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_w_valid: xs=%h golden=%h", $time, x_auto_axi4_out_w_valid, g_auto_axi4_out_w_valid); end
      checks = checks + 1;
      if (x_auto_axi4_out_w_bits_data !== g_auto_axi4_out_w_bits_data) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_w_bits_data: xs=%h golden=%h", $time, x_auto_axi4_out_w_bits_data, g_auto_axi4_out_w_bits_data); end
      checks = checks + 1;
      if (x_auto_axi4_out_w_bits_strb !== g_auto_axi4_out_w_bits_strb) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_w_bits_strb: xs=%h golden=%h", $time, x_auto_axi4_out_w_bits_strb, g_auto_axi4_out_w_bits_strb); end
      checks = checks + 1;
      if (x_auto_axi4_out_w_bits_last !== g_auto_axi4_out_w_bits_last) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_w_bits_last: xs=%h golden=%h", $time, x_auto_axi4_out_w_bits_last, g_auto_axi4_out_w_bits_last); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_valid !== g_auto_axi4_out_ar_valid) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_valid: xs=%h golden=%h", $time, x_auto_axi4_out_ar_valid, g_auto_axi4_out_ar_valid); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_id !== g_auto_axi4_out_ar_bits_id) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_id: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_id, g_auto_axi4_out_ar_bits_id); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_addr !== g_auto_axi4_out_ar_bits_addr) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_addr: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_addr, g_auto_axi4_out_ar_bits_addr); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_len !== g_auto_axi4_out_ar_bits_len) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_len: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_len, g_auto_axi4_out_ar_bits_len); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_size !== g_auto_axi4_out_ar_bits_size) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_size: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_size, g_auto_axi4_out_ar_bits_size); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_burst !== g_auto_axi4_out_ar_bits_burst) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_burst: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_burst, g_auto_axi4_out_ar_bits_burst); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_cache !== g_auto_axi4_out_ar_bits_cache) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_cache: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_cache, g_auto_axi4_out_ar_bits_cache); end
      checks = checks + 1;
      if (x_auto_axi4_out_ar_bits_qos !== g_auto_axi4_out_ar_bits_qos) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t auto_axi4_out_ar_bits_qos: xs=%h golden=%h", $time, x_auto_axi4_out_ar_bits_qos, g_auto_axi4_out_ar_bits_qos); end
      checks = checks + 1;
      if (x_io_chi_rxsactive !== g_io_chi_rxsactive) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rxsactive: xs=%h golden=%h", $time, x_io_chi_rxsactive, g_io_chi_rxsactive); end
      checks = checks + 1;
      if (x_io_chi_tx_linkactiveack !== g_io_chi_tx_linkactiveack) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_tx_linkactiveack: xs=%h golden=%h", $time, x_io_chi_tx_linkactiveack, g_io_chi_tx_linkactiveack); end
      checks = checks + 1;
      if (x_io_chi_tx_req_lcrdv !== g_io_chi_tx_req_lcrdv) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_tx_req_lcrdv: xs=%h golden=%h", $time, x_io_chi_tx_req_lcrdv, g_io_chi_tx_req_lcrdv); end
      checks = checks + 1;
      if (x_io_chi_tx_dat_lcrdv !== g_io_chi_tx_dat_lcrdv) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_tx_dat_lcrdv: xs=%h golden=%h", $time, x_io_chi_tx_dat_lcrdv, g_io_chi_tx_dat_lcrdv); end
      checks = checks + 1;
      if (x_io_chi_rx_linkactivereq !== g_io_chi_rx_linkactivereq) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_linkactivereq: xs=%h golden=%h", $time, x_io_chi_rx_linkactivereq, g_io_chi_rx_linkactivereq); end
      checks = checks + 1;
      if (x_io_chi_rx_rsp_flitpend !== g_io_chi_rx_rsp_flitpend) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_rsp_flitpend: xs=%h golden=%h", $time, x_io_chi_rx_rsp_flitpend, g_io_chi_rx_rsp_flitpend); end
      checks = checks + 1;
      if (x_io_chi_rx_rsp_flitv !== g_io_chi_rx_rsp_flitv) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_rsp_flitv: xs=%h golden=%h", $time, x_io_chi_rx_rsp_flitv, g_io_chi_rx_rsp_flitv); end
      checks = checks + 1;
      if (x_io_chi_rx_rsp_flit !== g_io_chi_rx_rsp_flit) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_rsp_flit: xs=%h golden=%h", $time, x_io_chi_rx_rsp_flit, g_io_chi_rx_rsp_flit); end
      checks = checks + 1;
      if (x_io_chi_rx_dat_flitpend !== g_io_chi_rx_dat_flitpend) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_dat_flitpend: xs=%h golden=%h", $time, x_io_chi_rx_dat_flitpend, g_io_chi_rx_dat_flitpend); end
      checks = checks + 1;
      if (x_io_chi_rx_dat_flitv !== g_io_chi_rx_dat_flitv) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_dat_flitv: xs=%h golden=%h", $time, x_io_chi_rx_dat_flitv, g_io_chi_rx_dat_flitv); end
      checks = checks + 1;
      if (x_io_chi_rx_dat_flit !== g_io_chi_rx_dat_flit) begin errors=errors+1;
        if (errors<20) $display("MISMATCH %0t io_chi_rx_dat_flit: xs=%h golden=%h", $time, x_io_chi_rx_dat_flit, g_io_chi_rx_dat_flit); end
    end
  endtask

  initial begin
    // init all inputs 0
    auto_axi4_out_aw_ready = 0;
    auto_axi4_out_w_ready = 0;
    auto_axi4_out_b_valid = 0;
    auto_axi4_out_b_bits_id = 0;
    auto_axi4_out_ar_ready = 0;
    auto_axi4_out_r_valid = 0;
    auto_axi4_out_r_bits_id = 0;
    auto_axi4_out_r_bits_data = 0;
    auto_axi4_out_r_bits_last = 0;
    io_chi_txsactive = 0;
    io_chi_tx_linkactivereq = 0;
    io_chi_tx_req_flitpend = 0;
    io_chi_tx_req_flitv = 0;
    io_chi_tx_req_flit = 0;
    io_chi_tx_dat_flitpend = 0;
    io_chi_tx_dat_flitv = 0;
    io_chi_tx_dat_flit = 0;
    io_chi_rx_linkactiveack = 0;
    io_chi_rx_rsp_lcrdv = 0;
    io_chi_rx_dat_lcrdv = 0;
    reset = 1;
    repeat (10) @(posedge clock);
    #1 reset = 0;
    for (i = 0; i < 200000; i = i + 1) begin
      @(negedge clock);
      drive_random;
      @(posedge clock);
      #1 check_outputs;
    end
    $display("OpenNCB_1 UT DONE seed=%0d checks=%0d errors=%0d", seed, checks, errors);
    if (errors==0) $display("OpenNCB_1 UT PASS"); else $display("OpenNCB_1 UT FAIL");
    $finish;
  end
endmodule
