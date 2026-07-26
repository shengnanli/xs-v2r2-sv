// MipModule UT: golden vs readable primitive (_xs) cycle-by-cycle compare.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen; logic [63:0] w_wdata;
  logic        mvip_SEIP, mvien_SEIE, hvip_VSSIP, hvip_VSTIP, hvip_VSEIP;
  logic [4:0]  hgeip_ip, hgeie_ie; logic [5:0] hstatusVGEIN;
  logic        platformIRP_MEIP, platformIRP_MTIP, platformIRP_MSIP, platformIRP_SEIP;
  logic        platformIRP_STIP, platformIRP_VSTIP, menvcfg_STCE, lcofiReq;
  logic        aiaToCSR_meip, aiaToCSR_seip;
  logic        fromMvip_SSIP_valid, fromMvip_SSIP_bits, fromMvip_STIP_valid, fromMvip_STIP_bits;
  logic        fromSip_SSIP_valid, fromSip_SSIP_bits, fromSip_LCOFIP_valid, fromSip_LCOFIP_bits;
  logic        fromVSip_LCOFIP_valid, fromVSip_LCOFIP_bits;

  logic [63:0] g_rd, i_rd;
  logic [26:0] g_o, i_o;  // pack 11 regOut + 11 rdataFields + 4 to* = 26 bits + spare

  `define PORTS(P) \
    .clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(P``_rd), \
    .regOut_SSIP(P``_o[0]),.regOut_VSSIP(P``_o[1]),.regOut_MSIP(P``_o[2]), \
    .regOut_STIP(P``_o[3]),.regOut_VSTIP(P``_o[4]),.regOut_MTIP(P``_o[5]), \
    .regOut_SEIP(P``_o[6]),.regOut_VSEIP(P``_o[7]),.regOut_MEIP(P``_o[8]), \
    .regOut_SGEIP(P``_o[9]),.regOut_LCOFIP(P``_o[10]), \
    .rdataFields_SSIP(P``_o[11]),.rdataFields_VSSIP(P``_o[12]),.rdataFields_MSIP(P``_o[13]), \
    .rdataFields_STIP(P``_o[14]),.rdataFields_VSTIP(P``_o[15]),.rdataFields_MTIP(P``_o[16]), \
    .rdataFields_SEIP(P``_o[17]),.rdataFields_VSEIP(P``_o[18]),.rdataFields_MEIP(P``_o[19]), \
    .rdataFields_SGEIP(P``_o[20]),.rdataFields_LCOFIP(P``_o[21]), \
    .toMvip_SEIP_valid(P``_o[22]),.toMvip_SEIP_bits(P``_o[23]), \
    .toHvip_VSSIP_valid(P``_o[24]),.toHvip_VSSIP_bits(P``_o[25]), \
    .mvip_SEIP(mvip_SEIP),.mvien_SEIE(mvien_SEIE),.hvip_VSSIP(hvip_VSSIP), \
    .hvip_VSTIP(hvip_VSTIP),.hvip_VSEIP(hvip_VSEIP),.hgeip_ip(hgeip_ip), \
    .hgeie_ie(hgeie_ie),.hstatusVGEIN(hstatusVGEIN), \
    .platformIRP_MEIP(platformIRP_MEIP),.platformIRP_MTIP(platformIRP_MTIP), \
    .platformIRP_MSIP(platformIRP_MSIP),.platformIRP_SEIP(platformIRP_SEIP), \
    .platformIRP_STIP(platformIRP_STIP),.platformIRP_VSTIP(platformIRP_VSTIP), \
    .menvcfg_STCE(menvcfg_STCE),.lcofiReq(lcofiReq), \
    .aiaToCSR_meip(aiaToCSR_meip),.aiaToCSR_seip(aiaToCSR_seip), \
    .fromMvip_SSIP_valid(fromMvip_SSIP_valid),.fromMvip_SSIP_bits(fromMvip_SSIP_bits), \
    .fromMvip_STIP_valid(fromMvip_STIP_valid),.fromMvip_STIP_bits(fromMvip_STIP_bits), \
    .fromSip_SSIP_valid(fromSip_SSIP_valid),.fromSip_SSIP_bits(fromSip_SSIP_bits), \
    .fromSip_LCOFIP_valid(fromSip_LCOFIP_valid),.fromSip_LCOFIP_bits(fromSip_LCOFIP_bits), \
    .fromVSip_LCOFIP_valid(fromVSip_LCOFIP_valid),.fromVSip_LCOFIP_bits(fromVSip_LCOFIP_bits)

  MipModule    g(`PORTS(g));
  MipModule_xs i(`PORTS(i));

  always @(negedge clk) begin
    if (rst) begin
      w_wen<='0; w_wdata<='0;
      {mvip_SEIP,mvien_SEIE,hvip_VSSIP,hvip_VSTIP,hvip_VSEIP}<='0;
      hgeip_ip<='0; hgeie_ie<='0; hstatusVGEIN<='0;
      {platformIRP_MEIP,platformIRP_MTIP,platformIRP_MSIP,platformIRP_SEIP,platformIRP_STIP,platformIRP_VSTIP}<='0;
      {menvcfg_STCE,lcofiReq,aiaToCSR_meip,aiaToCSR_seip}<='0;
      {fromMvip_SSIP_valid,fromMvip_SSIP_bits,fromMvip_STIP_valid,fromMvip_STIP_bits}<='0;
      {fromSip_SSIP_valid,fromSip_SSIP_bits,fromSip_LCOFIP_valid,fromSip_LCOFIP_bits}<='0;
      {fromVSip_LCOFIP_valid,fromVSip_LCOFIP_bits}<='0;
    end else begin
      w_wen<=($urandom_range(0,1)==0); w_wdata<={$urandom,$urandom};
      {mvip_SEIP,mvien_SEIE,hvip_VSSIP,hvip_VSTIP,hvip_VSEIP}<=5'($urandom);
      hgeip_ip<=5'($urandom); hgeie_ie<=5'($urandom);
      hstatusVGEIN<=6'($urandom_range(0,10)); // valid VGEIN range + a few over
      {platformIRP_MEIP,platformIRP_MTIP,platformIRP_MSIP,platformIRP_SEIP,platformIRP_STIP,platformIRP_VSTIP}<=6'($urandom);
      {menvcfg_STCE,lcofiReq,aiaToCSR_meip,aiaToCSR_seip}<=4'($urandom);
      {fromMvip_SSIP_valid,fromMvip_SSIP_bits,fromMvip_STIP_valid,fromMvip_STIP_bits}<=4'($urandom);
      {fromSip_SSIP_valid,fromSip_SSIP_bits,fromSip_LCOFIP_valid,fromSip_LCOFIP_bits}<=4'($urandom);
      {fromVSip_LCOFIP_valid,fromVSip_LCOFIP_bits}<=2'($urandom);
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_o!==i_o) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h | o g=%h i=%h",$time,g_rd,i_rd,g_o,i_o);
      end
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
