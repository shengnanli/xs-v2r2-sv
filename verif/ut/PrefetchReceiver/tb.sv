`timescale 1ns/1ps
// Differential UT for PrefetchReceiver (L1 prefetch address -> L2 tag/set).
// golden vs rewritten plus an in-tb oracle written from the L2 geometry
// (64B line, 512 sets: offset [5:0], set [14:6], tag [47:15]), compared on
// every vector.  Walking-one addresses check every address bit lands in the
// right field (or is dropped: offset bits and [63:48]).
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  int unsigned vld[4];   // {enable, recv_valid} combinations seen

  logic        enable, recv_valid;
  logic [63:0] addr;
  logic [4:0]  pf_src;
  wire         v_g, v_i;
  wire  [32:0] tag_g, tag_i;
  wire  [8:0]  set_g, set_i;
  wire  [4:0]  src_g, src_i;

  PrefetchReceiver g (
    .io_req_valid(v_g), .io_req_bits_tag(tag_g), .io_req_bits_set(set_g),
    .io_req_bits_pfSource(src_g), .io_recv_addr_valid(recv_valid),
    .io_recv_addr_bits_addr(addr), .io_recv_addr_bits_pfSource(pf_src), .io_enable(enable)
  );
  PrefetchReceiver_xs i (
    .io_req_valid(v_i), .io_req_bits_tag(tag_i), .io_req_bits_set(set_i),
    .io_req_bits_pfSource(src_i), .io_recv_addr_valid(recv_valid),
    .io_recv_addr_bits_addr(addr), .io_recv_addr_bits_pfSource(pf_src), .io_enable(enable)
  );

  task automatic compare_now;
    logic [32:0] e_tag;
    logic [8:0]  e_set;
    begin
      #1;
      vectors++;
      vld[{enable, recv_valid}]++;
      e_tag = 33'(addr >> 15);
      e_set = 9'(addr >> 6);
      if ({v_g, tag_g, set_g, src_g} !== {v_i, tag_i, set_i, src_i}) begin
        errors++;
        if (errors < 8) $display("golden mismatch @%0d addr=%h", vectors, addr);
      end
      if ({v_i, tag_i, set_i, src_i} !== {enable & recv_valid, e_tag, e_set, pf_src}) begin
        errors++;
        if (errors < 8) $display("oracle mismatch @%0d addr=%h", vectors, addr);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    enable = 1'b1; recv_valid = 1'b1; pf_src = '0;
    for (int bit_idx = 0; bit_idx < 64; bit_idx++) begin
      addr = 64'b1 << bit_idx;
      compare_now();
      addr = ~(64'b1 << bit_idx);
      compare_now();
    end
    repeat (NCYCLES) begin
      {enable, recv_valid} = 2'($urandom);
      addr   = {$urandom, $urandom};
      pf_src = 5'($urandom);
      compare_now();
    end
    $display("COVERAGE {enable,valid}: 00=%0d 01=%0d 10=%0d 11=%0d", vld[0], vld[1], vld[2], vld[3]);
    if (vld[0] == 0 || vld[1] == 0 || vld[2] == 0 || vld[3] == 0) begin
      errors++;
      $display("coverage hole");
    end
    $display("PrefetchReceiver UT: vectors=%0d errors=%0d", vectors, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
