// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// CHILogger 双例化逐拍比对: golden CHILogger vs 可读重写 CHILogger_xs。
`timescale 1ns/1ps
`define CHK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic io_up_txsactive;
  logic io_up_syscoreq;
  logic io_up_tx_linkactivereq;
  logic io_up_tx_req_flitpend;
  logic io_up_tx_req_flitv;
  logic [161:0] io_up_tx_req_flit;
  logic io_up_tx_rsp_flitpend;
  logic io_up_tx_rsp_flitv;
  logic [72:0] io_up_tx_rsp_flit;
  logic io_up_tx_dat_flitpend;
  logic io_up_tx_dat_flitv;
  logic [421:0] io_up_tx_dat_flit;
  logic io_up_rx_linkactiveack;
  logic io_up_rx_rsp_lcrdv;
  logic io_up_rx_dat_lcrdv;
  logic io_up_rx_snp_lcrdv;
  logic io_down_rxsactive;
  logic io_down_syscoack;
  logic io_down_tx_linkactiveack;
  logic io_down_tx_req_lcrdv;
  logic io_down_tx_rsp_lcrdv;
  logic io_down_tx_dat_lcrdv;
  logic io_down_rx_linkactivereq;
  logic io_down_rx_rsp_flitpend;
  logic io_down_rx_rsp_flitv;
  logic [72:0] io_down_rx_rsp_flit;
  logic io_down_rx_dat_flitpend;
  logic io_down_rx_dat_flitv;
  logic [421:0] io_down_rx_dat_flit;
  logic io_down_rx_snp_flitpend;
  logic io_down_rx_snp_flitv;
  logic [114:0] io_down_rx_snp_flit;
  wire g_io_up_rxsactive;
  wire i_io_up_rxsactive;
  wire g_io_up_syscoack;
  wire i_io_up_syscoack;
  wire g_io_up_tx_linkactiveack;
  wire i_io_up_tx_linkactiveack;
  wire g_io_up_tx_req_lcrdv;
  wire i_io_up_tx_req_lcrdv;
  wire g_io_up_tx_rsp_lcrdv;
  wire i_io_up_tx_rsp_lcrdv;
  wire g_io_up_tx_dat_lcrdv;
  wire i_io_up_tx_dat_lcrdv;
  wire g_io_up_rx_linkactivereq;
  wire i_io_up_rx_linkactivereq;
  wire g_io_up_rx_rsp_flitpend;
  wire i_io_up_rx_rsp_flitpend;
  wire g_io_up_rx_rsp_flitv;
  wire i_io_up_rx_rsp_flitv;
  wire [72:0] g_io_up_rx_rsp_flit;
  wire [72:0] i_io_up_rx_rsp_flit;
  wire g_io_up_rx_dat_flitpend;
  wire i_io_up_rx_dat_flitpend;
  wire g_io_up_rx_dat_flitv;
  wire i_io_up_rx_dat_flitv;
  wire [421:0] g_io_up_rx_dat_flit;
  wire [421:0] i_io_up_rx_dat_flit;
  wire g_io_up_rx_snp_flitpend;
  wire i_io_up_rx_snp_flitpend;
  wire g_io_up_rx_snp_flitv;
  wire i_io_up_rx_snp_flitv;
  wire [114:0] g_io_up_rx_snp_flit;
  wire [114:0] i_io_up_rx_snp_flit;
  wire g_io_down_txsactive;
  wire i_io_down_txsactive;
  wire g_io_down_syscoreq;
  wire i_io_down_syscoreq;
  wire g_io_down_tx_linkactivereq;
  wire i_io_down_tx_linkactivereq;
  wire g_io_down_tx_req_flitpend;
  wire i_io_down_tx_req_flitpend;
  wire g_io_down_tx_req_flitv;
  wire i_io_down_tx_req_flitv;
  wire [161:0] g_io_down_tx_req_flit;
  wire [161:0] i_io_down_tx_req_flit;
  wire g_io_down_tx_rsp_flitpend;
  wire i_io_down_tx_rsp_flitpend;
  wire g_io_down_tx_rsp_flitv;
  wire i_io_down_tx_rsp_flitv;
  wire [72:0] g_io_down_tx_rsp_flit;
  wire [72:0] i_io_down_tx_rsp_flit;
  wire g_io_down_tx_dat_flitpend;
  wire i_io_down_tx_dat_flitpend;
  wire g_io_down_tx_dat_flitv;
  wire i_io_down_tx_dat_flitv;
  wire [421:0] g_io_down_tx_dat_flit;
  wire [421:0] i_io_down_tx_dat_flit;
  wire g_io_down_rx_linkactiveack;
  wire i_io_down_rx_linkactiveack;
  wire g_io_down_rx_rsp_lcrdv;
  wire i_io_down_rx_rsp_lcrdv;
  wire g_io_down_rx_dat_lcrdv;
  wire i_io_down_rx_dat_lcrdv;
  wire g_io_down_rx_snp_lcrdv;
  wire i_io_down_rx_snp_lcrdv;

  CHILogger u_g (
    .io_up_txsactive(io_up_txsactive),
    .io_up_rxsactive(g_io_up_rxsactive),
    .io_up_syscoreq(io_up_syscoreq),
    .io_up_syscoack(g_io_up_syscoack),
    .io_up_tx_linkactivereq(io_up_tx_linkactivereq),
    .io_up_tx_linkactiveack(g_io_up_tx_linkactiveack),
    .io_up_tx_req_flitpend(io_up_tx_req_flitpend),
    .io_up_tx_req_flitv(io_up_tx_req_flitv),
    .io_up_tx_req_flit(io_up_tx_req_flit),
    .io_up_tx_req_lcrdv(g_io_up_tx_req_lcrdv),
    .io_up_tx_rsp_flitpend(io_up_tx_rsp_flitpend),
    .io_up_tx_rsp_flitv(io_up_tx_rsp_flitv),
    .io_up_tx_rsp_flit(io_up_tx_rsp_flit),
    .io_up_tx_rsp_lcrdv(g_io_up_tx_rsp_lcrdv),
    .io_up_tx_dat_flitpend(io_up_tx_dat_flitpend),
    .io_up_tx_dat_flitv(io_up_tx_dat_flitv),
    .io_up_tx_dat_flit(io_up_tx_dat_flit),
    .io_up_tx_dat_lcrdv(g_io_up_tx_dat_lcrdv),
    .io_up_rx_linkactivereq(g_io_up_rx_linkactivereq),
    .io_up_rx_linkactiveack(io_up_rx_linkactiveack),
    .io_up_rx_rsp_flitpend(g_io_up_rx_rsp_flitpend),
    .io_up_rx_rsp_flitv(g_io_up_rx_rsp_flitv),
    .io_up_rx_rsp_flit(g_io_up_rx_rsp_flit),
    .io_up_rx_rsp_lcrdv(io_up_rx_rsp_lcrdv),
    .io_up_rx_dat_flitpend(g_io_up_rx_dat_flitpend),
    .io_up_rx_dat_flitv(g_io_up_rx_dat_flitv),
    .io_up_rx_dat_flit(g_io_up_rx_dat_flit),
    .io_up_rx_dat_lcrdv(io_up_rx_dat_lcrdv),
    .io_up_rx_snp_flitpend(g_io_up_rx_snp_flitpend),
    .io_up_rx_snp_flitv(g_io_up_rx_snp_flitv),
    .io_up_rx_snp_flit(g_io_up_rx_snp_flit),
    .io_up_rx_snp_lcrdv(io_up_rx_snp_lcrdv),
    .io_down_txsactive(g_io_down_txsactive),
    .io_down_rxsactive(io_down_rxsactive),
    .io_down_syscoreq(g_io_down_syscoreq),
    .io_down_syscoack(io_down_syscoack),
    .io_down_tx_linkactivereq(g_io_down_tx_linkactivereq),
    .io_down_tx_linkactiveack(io_down_tx_linkactiveack),
    .io_down_tx_req_flitpend(g_io_down_tx_req_flitpend),
    .io_down_tx_req_flitv(g_io_down_tx_req_flitv),
    .io_down_tx_req_flit(g_io_down_tx_req_flit),
    .io_down_tx_req_lcrdv(io_down_tx_req_lcrdv),
    .io_down_tx_rsp_flitpend(g_io_down_tx_rsp_flitpend),
    .io_down_tx_rsp_flitv(g_io_down_tx_rsp_flitv),
    .io_down_tx_rsp_flit(g_io_down_tx_rsp_flit),
    .io_down_tx_rsp_lcrdv(io_down_tx_rsp_lcrdv),
    .io_down_tx_dat_flitpend(g_io_down_tx_dat_flitpend),
    .io_down_tx_dat_flitv(g_io_down_tx_dat_flitv),
    .io_down_tx_dat_flit(g_io_down_tx_dat_flit),
    .io_down_tx_dat_lcrdv(io_down_tx_dat_lcrdv),
    .io_down_rx_linkactivereq(io_down_rx_linkactivereq),
    .io_down_rx_linkactiveack(g_io_down_rx_linkactiveack),
    .io_down_rx_rsp_flitpend(io_down_rx_rsp_flitpend),
    .io_down_rx_rsp_flitv(io_down_rx_rsp_flitv),
    .io_down_rx_rsp_flit(io_down_rx_rsp_flit),
    .io_down_rx_rsp_lcrdv(g_io_down_rx_rsp_lcrdv),
    .io_down_rx_dat_flitpend(io_down_rx_dat_flitpend),
    .io_down_rx_dat_flitv(io_down_rx_dat_flitv),
    .io_down_rx_dat_flit(io_down_rx_dat_flit),
    .io_down_rx_dat_lcrdv(g_io_down_rx_dat_lcrdv),
    .io_down_rx_snp_flitpend(io_down_rx_snp_flitpend),
    .io_down_rx_snp_flitv(io_down_rx_snp_flitv),
    .io_down_rx_snp_flit(io_down_rx_snp_flit),
    .io_down_rx_snp_lcrdv(g_io_down_rx_snp_lcrdv)
  );
  CHILogger_xs u_i (
    .io_up_txsactive(io_up_txsactive),
    .io_up_rxsactive(i_io_up_rxsactive),
    .io_up_syscoreq(io_up_syscoreq),
    .io_up_syscoack(i_io_up_syscoack),
    .io_up_tx_linkactivereq(io_up_tx_linkactivereq),
    .io_up_tx_linkactiveack(i_io_up_tx_linkactiveack),
    .io_up_tx_req_flitpend(io_up_tx_req_flitpend),
    .io_up_tx_req_flitv(io_up_tx_req_flitv),
    .io_up_tx_req_flit(io_up_tx_req_flit),
    .io_up_tx_req_lcrdv(i_io_up_tx_req_lcrdv),
    .io_up_tx_rsp_flitpend(io_up_tx_rsp_flitpend),
    .io_up_tx_rsp_flitv(io_up_tx_rsp_flitv),
    .io_up_tx_rsp_flit(io_up_tx_rsp_flit),
    .io_up_tx_rsp_lcrdv(i_io_up_tx_rsp_lcrdv),
    .io_up_tx_dat_flitpend(io_up_tx_dat_flitpend),
    .io_up_tx_dat_flitv(io_up_tx_dat_flitv),
    .io_up_tx_dat_flit(io_up_tx_dat_flit),
    .io_up_tx_dat_lcrdv(i_io_up_tx_dat_lcrdv),
    .io_up_rx_linkactivereq(i_io_up_rx_linkactivereq),
    .io_up_rx_linkactiveack(io_up_rx_linkactiveack),
    .io_up_rx_rsp_flitpend(i_io_up_rx_rsp_flitpend),
    .io_up_rx_rsp_flitv(i_io_up_rx_rsp_flitv),
    .io_up_rx_rsp_flit(i_io_up_rx_rsp_flit),
    .io_up_rx_rsp_lcrdv(io_up_rx_rsp_lcrdv),
    .io_up_rx_dat_flitpend(i_io_up_rx_dat_flitpend),
    .io_up_rx_dat_flitv(i_io_up_rx_dat_flitv),
    .io_up_rx_dat_flit(i_io_up_rx_dat_flit),
    .io_up_rx_dat_lcrdv(io_up_rx_dat_lcrdv),
    .io_up_rx_snp_flitpend(i_io_up_rx_snp_flitpend),
    .io_up_rx_snp_flitv(i_io_up_rx_snp_flitv),
    .io_up_rx_snp_flit(i_io_up_rx_snp_flit),
    .io_up_rx_snp_lcrdv(io_up_rx_snp_lcrdv),
    .io_down_txsactive(i_io_down_txsactive),
    .io_down_rxsactive(io_down_rxsactive),
    .io_down_syscoreq(i_io_down_syscoreq),
    .io_down_syscoack(io_down_syscoack),
    .io_down_tx_linkactivereq(i_io_down_tx_linkactivereq),
    .io_down_tx_linkactiveack(io_down_tx_linkactiveack),
    .io_down_tx_req_flitpend(i_io_down_tx_req_flitpend),
    .io_down_tx_req_flitv(i_io_down_tx_req_flitv),
    .io_down_tx_req_flit(i_io_down_tx_req_flit),
    .io_down_tx_req_lcrdv(io_down_tx_req_lcrdv),
    .io_down_tx_rsp_flitpend(i_io_down_tx_rsp_flitpend),
    .io_down_tx_rsp_flitv(i_io_down_tx_rsp_flitv),
    .io_down_tx_rsp_flit(i_io_down_tx_rsp_flit),
    .io_down_tx_rsp_lcrdv(io_down_tx_rsp_lcrdv),
    .io_down_tx_dat_flitpend(i_io_down_tx_dat_flitpend),
    .io_down_tx_dat_flitv(i_io_down_tx_dat_flitv),
    .io_down_tx_dat_flit(i_io_down_tx_dat_flit),
    .io_down_tx_dat_lcrdv(io_down_tx_dat_lcrdv),
    .io_down_rx_linkactivereq(io_down_rx_linkactivereq),
    .io_down_rx_linkactiveack(i_io_down_rx_linkactiveack),
    .io_down_rx_rsp_flitpend(io_down_rx_rsp_flitpend),
    .io_down_rx_rsp_flitv(io_down_rx_rsp_flitv),
    .io_down_rx_rsp_flit(io_down_rx_rsp_flit),
    .io_down_rx_rsp_lcrdv(i_io_down_rx_rsp_lcrdv),
    .io_down_rx_dat_flitpend(io_down_rx_dat_flitpend),
    .io_down_rx_dat_flitv(io_down_rx_dat_flitv),
    .io_down_rx_dat_flit(io_down_rx_dat_flit),
    .io_down_rx_dat_lcrdv(i_io_down_rx_dat_lcrdv),
    .io_down_rx_snp_flitpend(io_down_rx_snp_flitpend),
    .io_down_rx_snp_flitv(io_down_rx_snp_flitv),
    .io_down_rx_snp_flit(io_down_rx_snp_flit),
    .io_down_rx_snp_lcrdv(i_io_down_rx_snp_lcrdv)
  );

  task automatic drive_random();
    io_up_txsactive = $urandom;
    io_up_syscoreq = $urandom;
    io_up_tx_linkactivereq = $urandom;
    io_up_tx_req_flitpend = $urandom;
    io_up_tx_req_flitv = $urandom;
    io_up_tx_req_flit = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_up_tx_rsp_flitpend = $urandom;
    io_up_tx_rsp_flitv = $urandom;
    io_up_tx_rsp_flit = {$urandom, $urandom, $urandom};
    io_up_tx_dat_flitpend = $urandom;
    io_up_tx_dat_flitv = $urandom;
    io_up_tx_dat_flit = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_up_rx_linkactiveack = $urandom;
    io_up_rx_rsp_lcrdv = $urandom;
    io_up_rx_dat_lcrdv = $urandom;
    io_up_rx_snp_lcrdv = $urandom;
    io_down_rxsactive = $urandom;
    io_down_syscoack = $urandom;
    io_down_tx_linkactiveack = $urandom;
    io_down_tx_req_lcrdv = $urandom;
    io_down_tx_rsp_lcrdv = $urandom;
    io_down_tx_dat_lcrdv = $urandom;
    io_down_rx_linkactivereq = $urandom;
    io_down_rx_rsp_flitpend = $urandom;
    io_down_rx_rsp_flitv = $urandom;
    io_down_rx_rsp_flit = {$urandom, $urandom, $urandom};
    io_down_rx_dat_flitpend = $urandom;
    io_down_rx_dat_flitv = $urandom;
    io_down_rx_dat_flit = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_down_rx_snp_flitpend = $urandom;
    io_down_rx_snp_flitv = $urandom;
    io_down_rx_snp_flit = {$urandom, $urandom, $urandom, $urandom};
  endtask

  task automatic check_outputs();
    `CHK(io_up_rxsactive)
    `CHK(io_up_syscoack)
    `CHK(io_up_tx_linkactiveack)
    `CHK(io_up_tx_req_lcrdv)
    `CHK(io_up_tx_rsp_lcrdv)
    `CHK(io_up_tx_dat_lcrdv)
    `CHK(io_up_rx_linkactivereq)
    `CHK(io_up_rx_rsp_flitpend)
    `CHK(io_up_rx_rsp_flitv)
    `CHK(io_up_rx_rsp_flit)
    `CHK(io_up_rx_dat_flitpend)
    `CHK(io_up_rx_dat_flitv)
    `CHK(io_up_rx_dat_flit)
    `CHK(io_up_rx_snp_flitpend)
    `CHK(io_up_rx_snp_flitv)
    `CHK(io_up_rx_snp_flit)
    `CHK(io_down_txsactive)
    `CHK(io_down_syscoreq)
    `CHK(io_down_tx_linkactivereq)
    `CHK(io_down_tx_req_flitpend)
    `CHK(io_down_tx_req_flitv)
    `CHK(io_down_tx_req_flit)
    `CHK(io_down_tx_rsp_flitpend)
    `CHK(io_down_tx_rsp_flitv)
    `CHK(io_down_tx_rsp_flit)
    `CHK(io_down_tx_dat_flitpend)
    `CHK(io_down_tx_dat_flitv)
    `CHK(io_down_tx_dat_flit)
    `CHK(io_down_rx_linkactiveack)
    `CHK(io_down_rx_rsp_lcrdv)
    `CHK(io_down_rx_dat_lcrdv)
    `CHK(io_down_rx_snp_lcrdv)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_up_txsactive = '0;
    io_up_syscoreq = '0;
    io_up_tx_linkactivereq = '0;
    io_up_tx_req_flitpend = '0;
    io_up_tx_req_flitv = '0;
    io_up_tx_req_flit = '0;
    io_up_tx_rsp_flitpend = '0;
    io_up_tx_rsp_flitv = '0;
    io_up_tx_rsp_flit = '0;
    io_up_tx_dat_flitpend = '0;
    io_up_tx_dat_flitv = '0;
    io_up_tx_dat_flit = '0;
    io_up_rx_linkactiveack = '0;
    io_up_rx_rsp_lcrdv = '0;
    io_up_rx_dat_lcrdv = '0;
    io_up_rx_snp_lcrdv = '0;
    io_down_rxsactive = '0;
    io_down_syscoack = '0;
    io_down_tx_linkactiveack = '0;
    io_down_tx_req_lcrdv = '0;
    io_down_tx_rsp_lcrdv = '0;
    io_down_tx_dat_lcrdv = '0;
    io_down_rx_linkactivereq = '0;
    io_down_rx_rsp_flitpend = '0;
    io_down_rx_rsp_flitv = '0;
    io_down_rx_rsp_flit = '0;
    io_down_rx_dat_flitpend = '0;
    io_down_rx_dat_flitv = '0;
    io_down_rx_dat_flit = '0;
    io_down_rx_snp_flitpend = '0;
    io_down_rx_snp_flitv = '0;
    io_down_rx_snp_flit = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("CHILogger checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
