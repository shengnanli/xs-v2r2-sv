`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES=200000; int errors=0,vectors=0;
  logic [5:0] hartid; logic [6:0] pending; logic [63:0] source,cfg;
  logic [11:0] iid; logic [7:0] prio; logic sync_in;
  wire [63:0] z,h,hg,mi,si,vsi,td,mt,st,vst,p0,p2,p4,p6;
  wire [6:0] hg_raw; wire [63:0] mi2,si2,vsi2,td2,p02,p22,p42,p62;
  wire [11:0] mti,sti,vsti; wire sync_out;
  MconfigptrModule_xs u0(.rdata(z)); MhartidModule_xs u1(.rdata(h),.hartid(hartid));
  HgeipModule_xs u2(.rdata(hg),.regOut_ip(hg_raw),.aiaToCSR_vseip(pending));
  MiregModule_xs u3(.rdata(mi),.regOut_ALL(mi2),.iregRead_mireg(source));
  SiregModule_xs u4(.rdata(si),.regOut_ALL(si2),.iregRead_sireg(source));
  VSiregModule_xs u5(.rdata(vsi),.regOut_ALL(vsi2),.iregRead_sireg(source));
  Tdata2Module_xs u6(.rdata(td),.regOut_ALL(td2),.tdataRead_tdata2(source));
  MtopiModule_xs u7(.rdata(mt),.regOut_IID(mti),.topIR_mtopi_IID(iid),.topIR_mtopi_IPRIO(prio));
  StopiModule_xs u8(.rdata(st),.regOut_IID(sti),.topIR_stopi_IID(iid),.topIR_stopi_IPRIO(prio));
  VStopiModule_xs u9(.rdata(vst),.regOut_IID(vsti),.topIR_vstopi_IID(iid),.topIR_vstopi_IPRIO(prio));
  Pmacfg0Module_xs u10(.rdata(p0),.regOut_ALL(p02),.cfgRData(cfg));
  Pmacfg2Module_xs u11(.rdata(p2),.regOut_ALL(p22),.cfgRData(cfg));
  Pmacfg4Module_xs u12(.rdata(p4),.regOut_ALL(p42),.cfgRData(cfg));
  Pmacfg6Module_xs u13(.rdata(p6),.regOut_ALL(p62),.cfgRData(cfg));
  IntSyncSyncCrossingSink_xs u14(.auto_in_sync_0(sync_in),.auto_out_0(sync_out));
  task automatic check(input logic ok,input string tag); if(!ok) begin errors++; if(errors<8)$display("mismatch %s",tag); end endtask
  task automatic compare_now; #1; vectors++;
    check(z===0,"mconfigptr"); check(h==={58'b0,hartid},"mhartid");
    check(hg==={56'b0,pending,1'b0} && hg_raw===pending,"hgeip");
    check(mi===source&&mi2===source&&si===source&&si2===source&&vsi===source&&vsi2===source&&td===source&&td2===source,"mirrors");
    check(mt==={36'b0,iid,8'b0,prio}&&st===mt&&vst===mt&&mti===iid&&sti===iid&&vsti===iid,"topi");
    check(p0===cfg&&p02===cfg&&p2===cfg&&p22===cfg&&p4===cfg&&p42===cfg&&p6===cfg&&p62===cfg,"pmacfg");
    check(sync_out===sync_in,"sync");
  endtask
  initial begin
    {hartid,pending,source,cfg,iid,prio,sync_in}='0; compare_now();
    {hartid,pending,source,cfg,iid,prio,sync_in}='1; compare_now();
    repeat(NCYCLES) begin hartid=$urandom; pending=$urandom; source={$urandom,$urandom}; cfg={$urandom,$urandom}; iid=$urandom; prio=$urandom; sync_in=$urandom; compare_now(); end
    $display("CSRLeaves15 UT: vectors=%0d module_checks=%0d errors=%0d",vectors,vectors*15,errors);
    if(errors==0)$display("TEST PASSED");else $display("TEST FAILED"); $finish;
  end
endmodule
