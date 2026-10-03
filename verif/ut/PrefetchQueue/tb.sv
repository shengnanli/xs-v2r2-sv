// PrefetchQueue UT —— golden vs 重写件双例化，逐拍比全部输出
// 相位：入队密/出队稀（打满、丢最老、head 追 tail）；入队稀/出队密（打空、直通）；均衡。中途异步复位 3 次。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic        ev, dr;
  logic [32:0] tag;  logic [8:0] st;  logic [43:0] va;  logic nt;  logic [6:0] src;  logic [4:0] pfs;
  wire        g_v, i_v, g_nt, i_nt;
  wire [32:0] g_tag, i_tag;  wire [8:0] g_st, i_st;  wire [43:0] g_va, i_va;  wire [6:0] g_src, i_src;  wire [4:0] g_pfs, i_pfs;

  `define PQ_PORTS(P) \
    .clock(clk), .reset(rst), .io_enq_valid(ev), .io_enq_bits_tag(tag), .io_enq_bits_set(st), .io_enq_bits_vaddr(va), \
    .io_enq_bits_needT(nt), .io_enq_bits_source(src), .io_enq_bits_pfSource(pfs), .io_deq_ready(dr), \
    .io_deq_valid(P``_v), .io_deq_bits_tag(P``_tag), .io_deq_bits_set(P``_st), .io_deq_bits_vaddr(P``_va), \
    .io_deq_bits_needT(P``_nt), .io_deq_bits_source(P``_src), .io_deq_bits_pfSource(P``_pfs)

  PrefetchQueue    g (`PQ_PORTS(g));
  PrefetchQueue_xs i (`PQ_PORTS(i));

  int cyc, phase;
  int cov_full_drop, cov_flow, cov_deq, cov_wrap, cov_midrst;

  always @(negedge clk) begin
    if (rst) begin
      cyc <= 0; ev <= 0; dr <= 0; phase <= 0; tag <= '0; st <= '0; va <= '0; nt <= 0; src <= '0; pfs <= '0;
    end else begin
      cyc <= cyc + 1;
      if ($urandom_range(0, 299) == 0) phase <= $urandom_range(0, 2);
      case (phase)
        0: begin ev <= ($urandom_range(0, 3) != 0); dr <= ($urandom_range(0, 5) == 0); end
        1: begin ev <= ($urandom_range(0, 5) == 0); dr <= ($urandom_range(0, 3) != 0); end
        default: begin ev <= $urandom_range(0, 1); dr <= $urandom_range(0, 1); end
      endcase
      tag <= {$urandom, $urandom}; st <= $urandom; va <= {$urandom, $urandom}; nt <= $urandom; src <= $urandom; pfs <= $urandom;
    end
  end

  `define CHK(nm, gg, ii) \
    if ((gg) !== (ii)) begin errors++; \
      if (errors <= 40) $display("[cyc %0d] %s g=%h i=%h", cyc, nm, gg, ii); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    `CHK("deq.valid", g_v, i_v)
    `CHK("tag", g_tag, i_tag) `CHK("set", g_st, i_st) `CHK("vaddr", g_va, i_va)
    `CHK("needT", g_nt, i_nt) `CHK("source", g_src, i_src) `CHK("pfSource", g_pfs, i_pfs)
    if (ev && g.full_probe && !dr) cov_full_drop++;
    if (ev && g.empty_probe && dr) cov_flow++;
    if (g_v && dr) cov_deq++;
    if (g.head == 5'd31 && !g.empty_probe && dr) cov_wrap++;
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    for (int k = 0; k < 4; k++) begin
      repeat (NCYCLES / 4) @(posedge clk);
      if (k < 3) begin
        #2 rst = 1; cov_midrst++;
        repeat (3) @(posedge clk);
        #2 rst = 0;
      end
    end
    $display("COV full_drop=%0d flow=%0d deq=%0d wrap=%0d midrst=%0d", cov_full_drop, cov_flow, cov_deq, cov_wrap, cov_midrst);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_full_drop > 1000 && cov_flow > 1000 && cov_deq > 1000 && cov_wrap > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
