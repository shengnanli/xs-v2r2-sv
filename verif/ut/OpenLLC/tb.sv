// 自动生成:scripts/gen_openllc.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_rn_0_txsactive;
  logic io_rn_0_syscoreq;
  logic io_rn_0_tx_linkactivereq;
  logic io_rn_0_tx_req_flitpend;
  logic io_rn_0_tx_req_flitv;
  logic [161:0] io_rn_0_tx_req_flit;
  logic io_rn_0_tx_rsp_flitpend;
  logic io_rn_0_tx_rsp_flitv;
  logic [72:0] io_rn_0_tx_rsp_flit;
  logic io_rn_0_tx_dat_flitpend;
  logic io_rn_0_tx_dat_flitv;
  logic [421:0] io_rn_0_tx_dat_flit;
  logic io_rn_0_rx_linkactiveack;
  logic io_rn_0_rx_rsp_lcrdv;
  logic io_rn_0_rx_dat_lcrdv;
  logic io_rn_0_rx_snp_lcrdv;
  logic io_sn_rxsactive;
  logic io_sn_tx_linkactiveack;
  logic io_sn_tx_req_lcrdv;
  logic io_sn_tx_dat_lcrdv;
  logic io_sn_rx_linkactivereq;
  logic io_sn_rx_rsp_flitpend;
  logic io_sn_rx_rsp_flitv;
  logic [72:0] io_sn_rx_rsp_flit;
  logic io_sn_rx_dat_flitpend;
  logic io_sn_rx_dat_flitv;
  logic [421:0] io_sn_rx_dat_flit;
  logic io_debugTopDown_robHeadPaddr_0_valid;
  logic [47:0] io_debugTopDown_robHeadPaddr_0_bits;
  wire g_io_rn_0_rxsactive;
  wire i_io_rn_0_rxsactive;
  wire g_io_rn_0_syscoack;
  wire i_io_rn_0_syscoack;
  wire g_io_rn_0_tx_linkactiveack;
  wire i_io_rn_0_tx_linkactiveack;
  wire g_io_rn_0_tx_req_lcrdv;
  wire i_io_rn_0_tx_req_lcrdv;
  wire g_io_rn_0_tx_rsp_lcrdv;
  wire i_io_rn_0_tx_rsp_lcrdv;
  wire g_io_rn_0_tx_dat_lcrdv;
  wire i_io_rn_0_tx_dat_lcrdv;
  wire g_io_rn_0_rx_linkactivereq;
  wire i_io_rn_0_rx_linkactivereq;
  wire g_io_rn_0_rx_rsp_flitpend;
  wire i_io_rn_0_rx_rsp_flitpend;
  wire g_io_rn_0_rx_rsp_flitv;
  wire i_io_rn_0_rx_rsp_flitv;
  wire [72:0] g_io_rn_0_rx_rsp_flit;
  wire [72:0] i_io_rn_0_rx_rsp_flit;
  wire g_io_rn_0_rx_dat_flitpend;
  wire i_io_rn_0_rx_dat_flitpend;
  wire g_io_rn_0_rx_dat_flitv;
  wire i_io_rn_0_rx_dat_flitv;
  wire [421:0] g_io_rn_0_rx_dat_flit;
  wire [421:0] i_io_rn_0_rx_dat_flit;
  wire g_io_rn_0_rx_snp_flitpend;
  wire i_io_rn_0_rx_snp_flitpend;
  wire g_io_rn_0_rx_snp_flitv;
  wire i_io_rn_0_rx_snp_flitv;
  wire [114:0] g_io_rn_0_rx_snp_flit;
  wire [114:0] i_io_rn_0_rx_snp_flit;
  wire g_io_sn_txsactive;
  wire i_io_sn_txsactive;
  wire g_io_sn_tx_linkactivereq;
  wire i_io_sn_tx_linkactivereq;
  wire g_io_sn_tx_req_flitpend;
  wire i_io_sn_tx_req_flitpend;
  wire g_io_sn_tx_req_flitv;
  wire i_io_sn_tx_req_flitv;
  wire [161:0] g_io_sn_tx_req_flit;
  wire [161:0] i_io_sn_tx_req_flit;
  wire g_io_sn_tx_dat_flitpend;
  wire i_io_sn_tx_dat_flitpend;
  wire g_io_sn_tx_dat_flitv;
  wire i_io_sn_tx_dat_flitv;
  wire [421:0] g_io_sn_tx_dat_flit;
  wire [421:0] i_io_sn_tx_dat_flit;
  wire g_io_sn_rx_linkactiveack;
  wire i_io_sn_rx_linkactiveack;
  wire g_io_sn_rx_rsp_lcrdv;
  wire i_io_sn_rx_rsp_lcrdv;
  wire g_io_sn_rx_dat_lcrdv;
  wire i_io_sn_rx_dat_lcrdv;
  wire g_io_debugTopDown_addrMatch_0;
  wire i_io_debugTopDown_addrMatch_0;
  wire g_io_l3Miss;
  wire i_io_l3Miss;

  OpenLLC    u_g (.clock(clk), .reset(rst), .io_rn_0_txsactive(io_rn_0_txsactive), .io_rn_0_rxsactive(g_io_rn_0_rxsactive), .io_rn_0_syscoreq(io_rn_0_syscoreq), .io_rn_0_syscoack(g_io_rn_0_syscoack), .io_rn_0_tx_linkactivereq(io_rn_0_tx_linkactivereq), .io_rn_0_tx_linkactiveack(g_io_rn_0_tx_linkactiveack), .io_rn_0_tx_req_flitpend(io_rn_0_tx_req_flitpend), .io_rn_0_tx_req_flitv(io_rn_0_tx_req_flitv), .io_rn_0_tx_req_flit(io_rn_0_tx_req_flit), .io_rn_0_tx_req_lcrdv(g_io_rn_0_tx_req_lcrdv), .io_rn_0_tx_rsp_flitpend(io_rn_0_tx_rsp_flitpend), .io_rn_0_tx_rsp_flitv(io_rn_0_tx_rsp_flitv), .io_rn_0_tx_rsp_flit(io_rn_0_tx_rsp_flit), .io_rn_0_tx_rsp_lcrdv(g_io_rn_0_tx_rsp_lcrdv), .io_rn_0_tx_dat_flitpend(io_rn_0_tx_dat_flitpend), .io_rn_0_tx_dat_flitv(io_rn_0_tx_dat_flitv), .io_rn_0_tx_dat_flit(io_rn_0_tx_dat_flit), .io_rn_0_tx_dat_lcrdv(g_io_rn_0_tx_dat_lcrdv), .io_rn_0_rx_linkactivereq(g_io_rn_0_rx_linkactivereq), .io_rn_0_rx_linkactiveack(io_rn_0_rx_linkactiveack), .io_rn_0_rx_rsp_flitpend(g_io_rn_0_rx_rsp_flitpend), .io_rn_0_rx_rsp_flitv(g_io_rn_0_rx_rsp_flitv), .io_rn_0_rx_rsp_flit(g_io_rn_0_rx_rsp_flit), .io_rn_0_rx_rsp_lcrdv(io_rn_0_rx_rsp_lcrdv), .io_rn_0_rx_dat_flitpend(g_io_rn_0_rx_dat_flitpend), .io_rn_0_rx_dat_flitv(g_io_rn_0_rx_dat_flitv), .io_rn_0_rx_dat_flit(g_io_rn_0_rx_dat_flit), .io_rn_0_rx_dat_lcrdv(io_rn_0_rx_dat_lcrdv), .io_rn_0_rx_snp_flitpend(g_io_rn_0_rx_snp_flitpend), .io_rn_0_rx_snp_flitv(g_io_rn_0_rx_snp_flitv), .io_rn_0_rx_snp_flit(g_io_rn_0_rx_snp_flit), .io_rn_0_rx_snp_lcrdv(io_rn_0_rx_snp_lcrdv), .io_sn_txsactive(g_io_sn_txsactive), .io_sn_rxsactive(io_sn_rxsactive), .io_sn_tx_linkactivereq(g_io_sn_tx_linkactivereq), .io_sn_tx_linkactiveack(io_sn_tx_linkactiveack), .io_sn_tx_req_flitpend(g_io_sn_tx_req_flitpend), .io_sn_tx_req_flitv(g_io_sn_tx_req_flitv), .io_sn_tx_req_flit(g_io_sn_tx_req_flit), .io_sn_tx_req_lcrdv(io_sn_tx_req_lcrdv), .io_sn_tx_dat_flitpend(g_io_sn_tx_dat_flitpend), .io_sn_tx_dat_flitv(g_io_sn_tx_dat_flitv), .io_sn_tx_dat_flit(g_io_sn_tx_dat_flit), .io_sn_tx_dat_lcrdv(io_sn_tx_dat_lcrdv), .io_sn_rx_linkactivereq(io_sn_rx_linkactivereq), .io_sn_rx_linkactiveack(g_io_sn_rx_linkactiveack), .io_sn_rx_rsp_flitpend(io_sn_rx_rsp_flitpend), .io_sn_rx_rsp_flitv(io_sn_rx_rsp_flitv), .io_sn_rx_rsp_flit(io_sn_rx_rsp_flit), .io_sn_rx_rsp_lcrdv(g_io_sn_rx_rsp_lcrdv), .io_sn_rx_dat_flitpend(io_sn_rx_dat_flitpend), .io_sn_rx_dat_flitv(io_sn_rx_dat_flitv), .io_sn_rx_dat_flit(io_sn_rx_dat_flit), .io_sn_rx_dat_lcrdv(g_io_sn_rx_dat_lcrdv), .io_debugTopDown_robHeadPaddr_0_valid(io_debugTopDown_robHeadPaddr_0_valid), .io_debugTopDown_robHeadPaddr_0_bits(io_debugTopDown_robHeadPaddr_0_bits), .io_debugTopDown_addrMatch_0(g_io_debugTopDown_addrMatch_0), .io_l3Miss(g_io_l3Miss));
  OpenLLC_xs u_i (.clock(clk), .reset(rst), .io_rn_0_txsactive(io_rn_0_txsactive), .io_rn_0_rxsactive(i_io_rn_0_rxsactive), .io_rn_0_syscoreq(io_rn_0_syscoreq), .io_rn_0_syscoack(i_io_rn_0_syscoack), .io_rn_0_tx_linkactivereq(io_rn_0_tx_linkactivereq), .io_rn_0_tx_linkactiveack(i_io_rn_0_tx_linkactiveack), .io_rn_0_tx_req_flitpend(io_rn_0_tx_req_flitpend), .io_rn_0_tx_req_flitv(io_rn_0_tx_req_flitv), .io_rn_0_tx_req_flit(io_rn_0_tx_req_flit), .io_rn_0_tx_req_lcrdv(i_io_rn_0_tx_req_lcrdv), .io_rn_0_tx_rsp_flitpend(io_rn_0_tx_rsp_flitpend), .io_rn_0_tx_rsp_flitv(io_rn_0_tx_rsp_flitv), .io_rn_0_tx_rsp_flit(io_rn_0_tx_rsp_flit), .io_rn_0_tx_rsp_lcrdv(i_io_rn_0_tx_rsp_lcrdv), .io_rn_0_tx_dat_flitpend(io_rn_0_tx_dat_flitpend), .io_rn_0_tx_dat_flitv(io_rn_0_tx_dat_flitv), .io_rn_0_tx_dat_flit(io_rn_0_tx_dat_flit), .io_rn_0_tx_dat_lcrdv(i_io_rn_0_tx_dat_lcrdv), .io_rn_0_rx_linkactivereq(i_io_rn_0_rx_linkactivereq), .io_rn_0_rx_linkactiveack(io_rn_0_rx_linkactiveack), .io_rn_0_rx_rsp_flitpend(i_io_rn_0_rx_rsp_flitpend), .io_rn_0_rx_rsp_flitv(i_io_rn_0_rx_rsp_flitv), .io_rn_0_rx_rsp_flit(i_io_rn_0_rx_rsp_flit), .io_rn_0_rx_rsp_lcrdv(io_rn_0_rx_rsp_lcrdv), .io_rn_0_rx_dat_flitpend(i_io_rn_0_rx_dat_flitpend), .io_rn_0_rx_dat_flitv(i_io_rn_0_rx_dat_flitv), .io_rn_0_rx_dat_flit(i_io_rn_0_rx_dat_flit), .io_rn_0_rx_dat_lcrdv(io_rn_0_rx_dat_lcrdv), .io_rn_0_rx_snp_flitpend(i_io_rn_0_rx_snp_flitpend), .io_rn_0_rx_snp_flitv(i_io_rn_0_rx_snp_flitv), .io_rn_0_rx_snp_flit(i_io_rn_0_rx_snp_flit), .io_rn_0_rx_snp_lcrdv(io_rn_0_rx_snp_lcrdv), .io_sn_txsactive(i_io_sn_txsactive), .io_sn_rxsactive(io_sn_rxsactive), .io_sn_tx_linkactivereq(i_io_sn_tx_linkactivereq), .io_sn_tx_linkactiveack(io_sn_tx_linkactiveack), .io_sn_tx_req_flitpend(i_io_sn_tx_req_flitpend), .io_sn_tx_req_flitv(i_io_sn_tx_req_flitv), .io_sn_tx_req_flit(i_io_sn_tx_req_flit), .io_sn_tx_req_lcrdv(io_sn_tx_req_lcrdv), .io_sn_tx_dat_flitpend(i_io_sn_tx_dat_flitpend), .io_sn_tx_dat_flitv(i_io_sn_tx_dat_flitv), .io_sn_tx_dat_flit(i_io_sn_tx_dat_flit), .io_sn_tx_dat_lcrdv(io_sn_tx_dat_lcrdv), .io_sn_rx_linkactivereq(io_sn_rx_linkactivereq), .io_sn_rx_linkactiveack(i_io_sn_rx_linkactiveack), .io_sn_rx_rsp_flitpend(io_sn_rx_rsp_flitpend), .io_sn_rx_rsp_flitv(io_sn_rx_rsp_flitv), .io_sn_rx_rsp_flit(io_sn_rx_rsp_flit), .io_sn_rx_rsp_lcrdv(i_io_sn_rx_rsp_lcrdv), .io_sn_rx_dat_flitpend(io_sn_rx_dat_flitpend), .io_sn_rx_dat_flitv(io_sn_rx_dat_flitv), .io_sn_rx_dat_flit(io_sn_rx_dat_flit), .io_sn_rx_dat_lcrdv(i_io_sn_rx_dat_lcrdv), .io_debugTopDown_robHeadPaddr_0_valid(io_debugTopDown_robHeadPaddr_0_valid), .io_debugTopDown_robHeadPaddr_0_bits(io_debugTopDown_robHeadPaddr_0_bits), .io_debugTopDown_addrMatch_0(i_io_debugTopDown_addrMatch_0), .io_l3Miss(i_io_l3Miss));

  bit reported [0:28];
  int distinct_div = 0;

  always @(negedge clk) begin
    if (rst) begin
      io_rn_0_tx_req_flitpend <= 1'b0;
      io_rn_0_tx_req_flitv <= 1'b0;
      io_rn_0_tx_rsp_flitpend <= 1'b0;
      io_rn_0_tx_rsp_flitv <= 1'b0;
      io_rn_0_tx_dat_flitpend <= 1'b0;
      io_rn_0_tx_dat_flitv <= 1'b0;
      io_rn_0_rx_rsp_lcrdv <= 1'b0;
      io_rn_0_rx_dat_lcrdv <= 1'b0;
      io_rn_0_rx_snp_lcrdv <= 1'b0;
      io_sn_tx_req_lcrdv <= 1'b0;
      io_sn_tx_dat_lcrdv <= 1'b0;
      io_sn_rx_rsp_flitpend <= 1'b0;
      io_sn_rx_rsp_flitv <= 1'b0;
      io_sn_rx_dat_flitpend <= 1'b0;
      io_sn_rx_dat_flitv <= 1'b0;
      io_debugTopDown_robHeadPaddr_0_valid <= 1'b0;
    end else begin
      io_rn_0_txsactive <= $urandom_range(0,1);
      io_rn_0_syscoreq <= $urandom_range(0,1);
      io_rn_0_tx_linkactivereq <= $urandom_range(0,1);
      io_rn_0_tx_req_flitpend <= $urandom_range(0,1);
      io_rn_0_tx_req_flitv <= $urandom_range(0,1);
      io_rn_0_tx_req_flit <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      io_rn_0_tx_rsp_flitpend <= $urandom_range(0,1);
      io_rn_0_tx_rsp_flitv <= $urandom_range(0,1);
      io_rn_0_tx_rsp_flit <= {$urandom(), $urandom(), $urandom()};
      io_rn_0_tx_dat_flitpend <= $urandom_range(0,1);
      io_rn_0_tx_dat_flitv <= $urandom_range(0,1);
      io_rn_0_tx_dat_flit <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      io_rn_0_rx_linkactiveack <= $urandom_range(0,1);
      io_rn_0_rx_rsp_lcrdv <= $urandom_range(0,1);
      io_rn_0_rx_dat_lcrdv <= $urandom_range(0,1);
      io_rn_0_rx_snp_lcrdv <= $urandom_range(0,1);
      io_sn_rxsactive <= $urandom_range(0,1);
      io_sn_tx_linkactiveack <= $urandom_range(0,1);
      io_sn_tx_req_lcrdv <= $urandom_range(0,1);
      io_sn_tx_dat_lcrdv <= $urandom_range(0,1);
      io_sn_rx_linkactivereq <= $urandom_range(0,1);
      io_sn_rx_rsp_flitpend <= $urandom_range(0,1);
      io_sn_rx_rsp_flitv <= $urandom_range(0,1);
      io_sn_rx_rsp_flit <= {$urandom(), $urandom(), $urandom()};
      io_sn_rx_dat_flitpend <= $urandom_range(0,1);
      io_sn_rx_dat_flitv <= $urandom_range(0,1);
      io_sn_rx_dat_flit <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      io_debugTopDown_robHeadPaddr_0_valid <= $urandom_range(0,1);
      io_debugTopDown_robHeadPaddr_0_bits <= {$urandom(), $urandom()};
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_rn_0_rxsactive) && g_io_rn_0_rxsactive !== i_io_rn_0_rxsactive) begin errors++;
      if(!reported[0]) begin reported[0]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rxsactive g=%h i=%h", $time, g_io_rn_0_rxsactive, i_io_rn_0_rxsactive); end end
    if (!$isunknown(g_io_rn_0_syscoack) && g_io_rn_0_syscoack !== i_io_rn_0_syscoack) begin errors++;
      if(!reported[1]) begin reported[1]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_syscoack g=%h i=%h", $time, g_io_rn_0_syscoack, i_io_rn_0_syscoack); end end
    if (!$isunknown(g_io_rn_0_tx_linkactiveack) && g_io_rn_0_tx_linkactiveack !== i_io_rn_0_tx_linkactiveack) begin errors++;
      if(!reported[2]) begin reported[2]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_tx_linkactiveack g=%h i=%h", $time, g_io_rn_0_tx_linkactiveack, i_io_rn_0_tx_linkactiveack); end end
    if (!$isunknown(g_io_rn_0_tx_req_lcrdv) && g_io_rn_0_tx_req_lcrdv !== i_io_rn_0_tx_req_lcrdv) begin errors++;
      if(!reported[3]) begin reported[3]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_tx_req_lcrdv g=%h i=%h", $time, g_io_rn_0_tx_req_lcrdv, i_io_rn_0_tx_req_lcrdv); end end
    if (!$isunknown(g_io_rn_0_tx_rsp_lcrdv) && g_io_rn_0_tx_rsp_lcrdv !== i_io_rn_0_tx_rsp_lcrdv) begin errors++;
      if(!reported[4]) begin reported[4]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_tx_rsp_lcrdv g=%h i=%h", $time, g_io_rn_0_tx_rsp_lcrdv, i_io_rn_0_tx_rsp_lcrdv); end end
    if (!$isunknown(g_io_rn_0_tx_dat_lcrdv) && g_io_rn_0_tx_dat_lcrdv !== i_io_rn_0_tx_dat_lcrdv) begin errors++;
      if(!reported[5]) begin reported[5]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_tx_dat_lcrdv g=%h i=%h", $time, g_io_rn_0_tx_dat_lcrdv, i_io_rn_0_tx_dat_lcrdv); end end
    if (!$isunknown(g_io_rn_0_rx_linkactivereq) && g_io_rn_0_rx_linkactivereq !== i_io_rn_0_rx_linkactivereq) begin errors++;
      if(!reported[6]) begin reported[6]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_linkactivereq g=%h i=%h", $time, g_io_rn_0_rx_linkactivereq, i_io_rn_0_rx_linkactivereq); end end
    if (!$isunknown(g_io_rn_0_rx_rsp_flitpend) && g_io_rn_0_rx_rsp_flitpend !== i_io_rn_0_rx_rsp_flitpend) begin errors++;
      if(!reported[7]) begin reported[7]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_rsp_flitpend g=%h i=%h", $time, g_io_rn_0_rx_rsp_flitpend, i_io_rn_0_rx_rsp_flitpend); end end
    if (!$isunknown(g_io_rn_0_rx_rsp_flitv) && g_io_rn_0_rx_rsp_flitv !== i_io_rn_0_rx_rsp_flitv) begin errors++;
      if(!reported[8]) begin reported[8]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_rsp_flitv g=%h i=%h", $time, g_io_rn_0_rx_rsp_flitv, i_io_rn_0_rx_rsp_flitv); end end
    if (!$isunknown(g_io_rn_0_rx_rsp_flit) && g_io_rn_0_rx_rsp_flit !== i_io_rn_0_rx_rsp_flit) begin errors++;
      if(!reported[9]) begin reported[9]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_rsp_flit g=%h i=%h", $time, g_io_rn_0_rx_rsp_flit, i_io_rn_0_rx_rsp_flit); end end
    if (!$isunknown(g_io_rn_0_rx_dat_flitpend) && g_io_rn_0_rx_dat_flitpend !== i_io_rn_0_rx_dat_flitpend) begin errors++;
      if(!reported[10]) begin reported[10]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_dat_flitpend g=%h i=%h", $time, g_io_rn_0_rx_dat_flitpend, i_io_rn_0_rx_dat_flitpend); end end
    if (!$isunknown(g_io_rn_0_rx_dat_flitv) && g_io_rn_0_rx_dat_flitv !== i_io_rn_0_rx_dat_flitv) begin errors++;
      if(!reported[11]) begin reported[11]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_dat_flitv g=%h i=%h", $time, g_io_rn_0_rx_dat_flitv, i_io_rn_0_rx_dat_flitv); end end
    if (!$isunknown(g_io_rn_0_rx_dat_flit) && g_io_rn_0_rx_dat_flit !== i_io_rn_0_rx_dat_flit) begin errors++;
      if(!reported[12]) begin reported[12]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_dat_flit g=%h i=%h", $time, g_io_rn_0_rx_dat_flit, i_io_rn_0_rx_dat_flit); end end
    if (!$isunknown(g_io_rn_0_rx_snp_flitpend) && g_io_rn_0_rx_snp_flitpend !== i_io_rn_0_rx_snp_flitpend) begin errors++;
      if(!reported[13]) begin reported[13]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_snp_flitpend g=%h i=%h", $time, g_io_rn_0_rx_snp_flitpend, i_io_rn_0_rx_snp_flitpend); end end
    if (!$isunknown(g_io_rn_0_rx_snp_flitv) && g_io_rn_0_rx_snp_flitv !== i_io_rn_0_rx_snp_flitv) begin errors++;
      if(!reported[14]) begin reported[14]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_snp_flitv g=%h i=%h", $time, g_io_rn_0_rx_snp_flitv, i_io_rn_0_rx_snp_flitv); end end
    if (!$isunknown(g_io_rn_0_rx_snp_flit) && g_io_rn_0_rx_snp_flit !== i_io_rn_0_rx_snp_flit) begin errors++;
      if(!reported[15]) begin reported[15]=1; distinct_div++;
        $display("[DIV %0t] io_rn_0_rx_snp_flit g=%h i=%h", $time, g_io_rn_0_rx_snp_flit, i_io_rn_0_rx_snp_flit); end end
    if (!$isunknown(g_io_sn_txsactive) && g_io_sn_txsactive !== i_io_sn_txsactive) begin errors++;
      if(!reported[16]) begin reported[16]=1; distinct_div++;
        $display("[DIV %0t] io_sn_txsactive g=%h i=%h", $time, g_io_sn_txsactive, i_io_sn_txsactive); end end
    if (!$isunknown(g_io_sn_tx_linkactivereq) && g_io_sn_tx_linkactivereq !== i_io_sn_tx_linkactivereq) begin errors++;
      if(!reported[17]) begin reported[17]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_linkactivereq g=%h i=%h", $time, g_io_sn_tx_linkactivereq, i_io_sn_tx_linkactivereq); end end
    if (!$isunknown(g_io_sn_tx_req_flitpend) && g_io_sn_tx_req_flitpend !== i_io_sn_tx_req_flitpend) begin errors++;
      if(!reported[18]) begin reported[18]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_req_flitpend g=%h i=%h", $time, g_io_sn_tx_req_flitpend, i_io_sn_tx_req_flitpend); end end
    if (!$isunknown(g_io_sn_tx_req_flitv) && g_io_sn_tx_req_flitv !== i_io_sn_tx_req_flitv) begin errors++;
      if(!reported[19]) begin reported[19]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_req_flitv g=%h i=%h", $time, g_io_sn_tx_req_flitv, i_io_sn_tx_req_flitv); end end
    if (!$isunknown(g_io_sn_tx_req_flit) && g_io_sn_tx_req_flit !== i_io_sn_tx_req_flit) begin errors++;
      if(!reported[20]) begin reported[20]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_req_flit g=%h i=%h", $time, g_io_sn_tx_req_flit, i_io_sn_tx_req_flit); end end
    if (!$isunknown(g_io_sn_tx_dat_flitpend) && g_io_sn_tx_dat_flitpend !== i_io_sn_tx_dat_flitpend) begin errors++;
      if(!reported[21]) begin reported[21]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_dat_flitpend g=%h i=%h", $time, g_io_sn_tx_dat_flitpend, i_io_sn_tx_dat_flitpend); end end
    if (!$isunknown(g_io_sn_tx_dat_flitv) && g_io_sn_tx_dat_flitv !== i_io_sn_tx_dat_flitv) begin errors++;
      if(!reported[22]) begin reported[22]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_dat_flitv g=%h i=%h", $time, g_io_sn_tx_dat_flitv, i_io_sn_tx_dat_flitv); end end
    if (!$isunknown(g_io_sn_tx_dat_flit) && g_io_sn_tx_dat_flit !== i_io_sn_tx_dat_flit) begin errors++;
      if(!reported[23]) begin reported[23]=1; distinct_div++;
        $display("[DIV %0t] io_sn_tx_dat_flit g=%h i=%h", $time, g_io_sn_tx_dat_flit, i_io_sn_tx_dat_flit); end end
    if (!$isunknown(g_io_sn_rx_linkactiveack) && g_io_sn_rx_linkactiveack !== i_io_sn_rx_linkactiveack) begin errors++;
      if(!reported[24]) begin reported[24]=1; distinct_div++;
        $display("[DIV %0t] io_sn_rx_linkactiveack g=%h i=%h", $time, g_io_sn_rx_linkactiveack, i_io_sn_rx_linkactiveack); end end
    if (!$isunknown(g_io_sn_rx_rsp_lcrdv) && g_io_sn_rx_rsp_lcrdv !== i_io_sn_rx_rsp_lcrdv) begin errors++;
      if(!reported[25]) begin reported[25]=1; distinct_div++;
        $display("[DIV %0t] io_sn_rx_rsp_lcrdv g=%h i=%h", $time, g_io_sn_rx_rsp_lcrdv, i_io_sn_rx_rsp_lcrdv); end end
    if (!$isunknown(g_io_sn_rx_dat_lcrdv) && g_io_sn_rx_dat_lcrdv !== i_io_sn_rx_dat_lcrdv) begin errors++;
      if(!reported[26]) begin reported[26]=1; distinct_div++;
        $display("[DIV %0t] io_sn_rx_dat_lcrdv g=%h i=%h", $time, g_io_sn_rx_dat_lcrdv, i_io_sn_rx_dat_lcrdv); end end
    if (!$isunknown(g_io_debugTopDown_addrMatch_0) && g_io_debugTopDown_addrMatch_0 !== i_io_debugTopDown_addrMatch_0) begin errors++;
      if(!reported[27]) begin reported[27]=1; distinct_div++;
        $display("[DIV %0t] io_debugTopDown_addrMatch_0 g=%h i=%h", $time, g_io_debugTopDown_addrMatch_0, i_io_debugTopDown_addrMatch_0); end end
    if (!$isunknown(g_io_l3Miss) && g_io_l3Miss !== i_io_l3Miss) begin errors++;
      if(!reported[28]) begin reported[28]=1; distinct_div++;
        $display("[DIV %0t] io_l3Miss g=%h i=%h", $time, g_io_l3Miss, i_io_l3Miss); end end
  end

  initial begin
    if (!$value$plusargs("NCYCLES=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("distinct_diverging_ports=%0d / %0d", distinct_div, 29);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
