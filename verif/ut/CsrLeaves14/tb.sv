`timescale 1ns/1ps
// CsrLeaves14 UT — dual-instantiation differential (golden vs <Name>_xs) plus
// an independent shadow oracle for every state-bearing CSR.
// Directed corners first (all-zero/all-ones wdata, wen off/on, per-byte-lane
// wdata, privilege-mode sweep, counter rollover, write-to-read-only bits,
// mid-run reset), then randoms. Prints exactly "TEST PASSED" or "TEST FAILED".
module tb;
  int unsigned NCYCLES=200000; int errors=0,vectors=0;
  logic clock=0, reset;
  always #5 clock = ~clock;

  // shared stimulus
  logic        wen, dbg_stop, upd;
  logic [63:0] wdata, m_cycle, m_instret;
  logic        mip_vstip, mip_vseip, mip_sgeip, hvip_vssip;
  logic        mie_vssie, mie_vstie, mie_vseie, mie_sgeie;
  logic [11:0] csr_addr;
  logic [1:0]  prvm;
  logic        virt, dbg_mode;

  // golden outputs
  wire [63:0] g_cycle_rd, g_instret_rd, g_hip_rd, g_hie_rd, g_hgeie_rd;
  wire [63:0] g_ms_rd,g_ms_ro, g_ss_rd,g_ss_ro, g_vss_rd,g_vss_ro;
  wire [63:0] g_mn_rd,g_mn_ro, g_d0_rd,g_d0_ro, g_d1_rd,g_d1_ro;
  wire [31:0] g_sctx_rd, g_sctx_ro;
  wire [1:0]  g_tsel_rd, g_tsel_ro;
  wire [6:0]  g_hgeie_ie;
  wire g_hip_vssip,g_hip_vstip,g_hip_vseip,g_hip_sgeip,g_hip_hvip_v,g_hip_hvip_b;
  wire g_hie_vssie,g_hie_vstie,g_hie_vseie,g_hie_sgeie;
  wire g_hie_mie_vss_v,g_hie_mie_vss_b,g_hie_mie_vst_v,g_hie_mie_vst_b;
  wire g_hie_mie_vse_v,g_hie_mie_vse_b,g_hie_mie_sge_v,g_hie_mie_sge_b;
  wire g_pp_ii, g_pp_vi;
  // xs outputs
  wire [63:0] x_cycle_rd, x_instret_rd, x_hip_rd, x_hie_rd, x_hgeie_rd;
  wire [63:0] x_ms_rd,x_ms_ro, x_ss_rd,x_ss_ro, x_vss_rd,x_vss_ro;
  wire [63:0] x_mn_rd,x_mn_ro, x_d0_rd,x_d0_ro, x_d1_rd,x_d1_ro;
  wire [31:0] x_sctx_rd, x_sctx_ro;
  wire [1:0]  x_tsel_rd, x_tsel_ro;
  wire [6:0]  x_hgeie_ie;
  wire x_hip_vssip,x_hip_vstip,x_hip_vseip,x_hip_sgeip,x_hip_hvip_v,x_hip_hvip_b;
  wire x_hie_vssie,x_hie_vstie,x_hie_vseie,x_hie_sgeie;
  wire x_hie_mie_vss_v,x_hie_mie_vss_b,x_hie_mie_vst_v,x_hie_mie_vst_b;
  wire x_hie_mie_vse_v,x_hie_mie_vse_b,x_hie_mie_sge_v,x_hie_mie_sge_b;
  wire x_pp_ii, x_pp_vi;

  cycleModule g_cyc(.clock,.rdata(g_cycle_rd),.mHPM_cycle(m_cycle),.debugModeStopCount(dbg_stop),.unprivCountUpdate(upd));
  cycleModule_xs x_cyc(.clock,.rdata(x_cycle_rd),.mHPM_cycle(m_cycle),.debugModeStopCount(dbg_stop),.unprivCountUpdate(upd));
  instretModule g_ins(.clock,.rdata(g_instret_rd),.mHPM_instret(m_instret),.debugModeStopCount(dbg_stop),.unprivCountUpdate(upd));
  instretModule_xs x_ins(.clock,.rdata(x_instret_rd),.mHPM_instret(m_instret),.debugModeStopCount(dbg_stop),.unprivCountUpdate(upd));

  HipModule g_hip(.w_wen(wen),.w_wdata(wdata),.rdata(g_hip_rd),
    .regOut_VSSIP(g_hip_vssip),.regOut_VSTIP(g_hip_vstip),.regOut_VSEIP(g_hip_vseip),.regOut_SGEIP(g_hip_sgeip),
    .mip_VSTIP(mip_vstip),.mip_VSEIP(mip_vseip),.mip_SGEIP(mip_sgeip),.hvip_VSSIP(hvip_vssip),
    .toHvip_VSSIP_valid(g_hip_hvip_v),.toHvip_VSSIP_bits(g_hip_hvip_b));
  HipModule_xs x_hip(.w_wen(wen),.w_wdata(wdata),.rdata(x_hip_rd),
    .regOut_VSSIP(x_hip_vssip),.regOut_VSTIP(x_hip_vstip),.regOut_VSEIP(x_hip_vseip),.regOut_SGEIP(x_hip_sgeip),
    .mip_VSTIP(mip_vstip),.mip_VSEIP(mip_vseip),.mip_SGEIP(mip_sgeip),.hvip_VSSIP(hvip_vssip),
    .toHvip_VSSIP_valid(x_hip_hvip_v),.toHvip_VSSIP_bits(x_hip_hvip_b));

  HieModule g_hie(.w_wen(wen),.w_wdata(wdata),.rdata(g_hie_rd),
    .regOut_VSSIE(g_hie_vssie),.regOut_VSTIE(g_hie_vstie),.regOut_VSEIE(g_hie_vseie),.regOut_SGEIE(g_hie_sgeie),
    .mie_VSSIE(mie_vssie),.mie_VSTIE(mie_vstie),.mie_VSEIE(mie_vseie),.mie_SGEIE(mie_sgeie),
    .toMie_VSSIE_valid(g_hie_mie_vss_v),.toMie_VSSIE_bits(g_hie_mie_vss_b),
    .toMie_VSTIE_valid(g_hie_mie_vst_v),.toMie_VSTIE_bits(g_hie_mie_vst_b),
    .toMie_VSEIE_valid(g_hie_mie_vse_v),.toMie_VSEIE_bits(g_hie_mie_vse_b),
    .toMie_SGEIE_valid(g_hie_mie_sge_v),.toMie_SGEIE_bits(g_hie_mie_sge_b));
  HieModule_xs x_hie(.w_wen(wen),.w_wdata(wdata),.rdata(x_hie_rd),
    .regOut_VSSIE(x_hie_vssie),.regOut_VSTIE(x_hie_vstie),.regOut_VSEIE(x_hie_vseie),.regOut_SGEIE(x_hie_sgeie),
    .mie_VSSIE(mie_vssie),.mie_VSTIE(mie_vstie),.mie_VSEIE(mie_vseie),.mie_SGEIE(mie_sgeie),
    .toMie_VSSIE_valid(x_hie_mie_vss_v),.toMie_VSSIE_bits(x_hie_mie_vss_b),
    .toMie_VSTIE_valid(x_hie_mie_vst_v),.toMie_VSTIE_bits(x_hie_mie_vst_b),
    .toMie_VSEIE_valid(x_hie_mie_vse_v),.toMie_VSEIE_bits(x_hie_mie_vse_b),
    .toMie_SGEIE_valid(x_hie_mie_sge_v),.toMie_SGEIE_bits(x_hie_mie_sge_b));

  HgeieModule g_hgeie(.clock,.reset,.w_wen(wen),.w_wdata(wdata),.rdata(g_hgeie_rd),.regOut_ie(g_hgeie_ie));
  HgeieModule_xs x_hgeie(.clock,.reset,.w_wen(wen),.w_wdata(wdata),.rdata(x_hgeie_rd),.regOut_ie(x_hgeie_ie));

  MscratchModule g_ms(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(g_ms_rd),.regOut_ALL(g_ms_ro));
  MscratchModule_xs x_ms(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(x_ms_rd),.regOut_ALL(x_ms_ro));
  SscratchModule g_ss(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(g_ss_rd),.regOut_ALL(g_ss_ro));
  SscratchModule_xs x_ss(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(x_ss_rd),.regOut_ALL(x_ss_ro));
  VSscratchModule g_vss(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(g_vss_rd),.regOut_ALL(g_vss_ro));
  VSscratchModule_xs x_vss(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(x_vss_rd),.regOut_ALL(x_vss_ro));
  MnscratchModule g_mn(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(g_mn_rd),.regOut_ALL(g_mn_ro));
  MnscratchModule_xs x_mn(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(x_mn_rd),.regOut_ALL(x_mn_ro));
  Dscratch0Module g_d0(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(g_d0_rd),.regOut_ALL(g_d0_ro));
  Dscratch0Module_xs x_d0(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(x_d0_rd),.regOut_ALL(x_d0_ro));
  Dscratch1Module g_d1(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(g_d1_rd),.regOut_ALL(g_d1_ro));
  Dscratch1Module_xs x_d1(.clock,.w_wen(wen),.w_wdata(wdata),.rdata(x_d1_rd),.regOut_ALL(x_d1_ro));

  ScontextModule g_sctx(.clock,.reset,.w_wen(wen),.w_wdata(wdata),.rdata(g_sctx_rd),.regOut_ALL(g_sctx_ro));
  ScontextModule_xs x_sctx(.clock,.reset,.w_wen(wen),.w_wdata(wdata),.rdata(x_sctx_rd),.regOut_ALL(x_sctx_ro));
  TselectModule g_tsel(.clock,.reset,.w_wen(wen),.w_wdata(wdata),.rdata(g_tsel_rd),.regOut_ALL(g_tsel_ro));
  TselectModule_xs x_tsel(.clock,.reset,.w_wen(wen),.w_wdata(wdata),.rdata(x_tsel_rd),.regOut_ALL(x_tsel_ro));

  PrivilegePermitModule g_pp(.io_in_csrAccess_addr(csr_addr),.io_in_privState_PRVM(prvm),
    .io_in_privState_V(virt),.io_in_debugMode(dbg_mode),
    .io_out_privilege_EX_II(g_pp_ii),.io_out_privilege_EX_VI(g_pp_vi));
  PrivilegePermitModule_xs x_pp(.io_in_csrAccess_addr(csr_addr),.io_in_privState_PRVM(prvm),
    .io_in_privState_V(virt),.io_in_debugMode(dbg_mode),
    .io_out_privilege_EX_II(x_pp_ii),.io_out_privilege_EX_VI(x_pp_vi));

  // ------------------------------------------------------------------
  // Independent shadow oracle (written from the mission spec, not from RTL)
  // ------------------------------------------------------------------
  logic [63:0] sh_cycle, sh_instret, sh_scratch;
  logic [6:0]  sh_hgeie;
  logic [31:0] sh_sctx;
  logic [1:0]  sh_tsel;
  always @(posedge clock) begin
    if (upd) begin sh_cycle <= m_cycle; sh_instret <= m_instret; end
    if (wen) sh_scratch <= wdata;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin sh_hgeie <= 7'h0; sh_sctx <= 32'h0; sh_tsel <= 2'h0; end
    else if (wen) begin
      sh_hgeie <= wdata[7:1];
      sh_sctx  <= wdata[31:0];
      if (wdata < 64'h4) sh_tsel <= wdata[1:0];
    end
  end
  // combinational oracles
  wire [63:0] orc_hip = {51'b0, mip_sgeip,1'b0, mip_vseip,3'b0, mip_vstip,3'b0, hvip_vssip,2'b0};
  wire [63:0] orc_hie = {51'b0, mie_sgeie,1'b0, mie_vseie,3'b0, mie_vstie,3'b0, mie_vssie,2'b0};
  wire [4:0]  pp_inv = ~{virt, prvm, csr_addr[9:8]};
  wire pp_legal_reg = |{&{pp_inv[0],pp_inv[1],pp_inv[3]}, &{pp_inv[1],prvm[0],pp_inv[3]},
                        &{pp_inv[0],prvm[0],pp_inv[4]}, &{prvm[0],prvm[1],pp_inv[4]}};
  wire pp_legal = (csr_addr[11:4] != 8'h7B) & pp_legal_reg | dbg_mode;
  wire orc_ii = ~pp_legal & (~virt | (&csr_addr[9:8]));
  wire orc_vi = ~pp_legal & virt & ~(&csr_addr[9:8]);

  task automatic check(input logic ok, input string tag);
    if (!ok) begin errors++; if (errors<10) $display("mismatch %s @%0t",tag,$time); end
  endtask

  // Compare every output of every module: golden-vs-xs AND golden-vs-oracle.
  task automatic compare_now;
    vectors++;
    // golden vs xs (dual instantiation lockstep)
    check(g_cycle_rd===x_cycle_rd && g_instret_rd===x_instret_rd,"dual-counters");
    check(g_hip_rd===x_hip_rd && g_hie_rd===x_hie_rd && g_hgeie_rd===x_hgeie_rd && g_hgeie_ie===x_hgeie_ie,"dual-irq");
    check(g_hip_vssip===x_hip_vssip && g_hip_vstip===x_hip_vstip && g_hip_vseip===x_hip_vseip &&
          g_hip_sgeip===x_hip_sgeip && g_hip_hvip_v===x_hip_hvip_v && g_hip_hvip_b===x_hip_hvip_b,"dual-hip-side");
    check(g_hie_vssie===x_hie_vssie && g_hie_vstie===x_hie_vstie && g_hie_vseie===x_hie_vseie &&
          g_hie_sgeie===x_hie_sgeie &&
          g_hie_mie_vss_v===x_hie_mie_vss_v && g_hie_mie_vss_b===x_hie_mie_vss_b &&
          g_hie_mie_vst_v===x_hie_mie_vst_v && g_hie_mie_vst_b===x_hie_mie_vst_b &&
          g_hie_mie_vse_v===x_hie_mie_vse_v && g_hie_mie_vse_b===x_hie_mie_vse_b &&
          g_hie_mie_sge_v===x_hie_mie_sge_v && g_hie_mie_sge_b===x_hie_mie_sge_b,"dual-hie-side");
    check(g_ms_rd===x_ms_rd && g_ms_ro===x_ms_ro && g_ss_rd===x_ss_rd && g_ss_ro===x_ss_ro &&
          g_vss_rd===x_vss_rd && g_vss_ro===x_vss_ro && g_mn_rd===x_mn_rd && g_mn_ro===x_mn_ro &&
          g_d0_rd===x_d0_rd && g_d0_ro===x_d0_ro && g_d1_rd===x_d1_rd && g_d1_ro===x_d1_ro,"dual-scratch");
    check(g_sctx_rd===x_sctx_rd && g_sctx_ro===x_sctx_ro && g_tsel_rd===x_tsel_rd && g_tsel_ro===x_tsel_ro,"dual-sctx-tsel");
    check(g_pp_ii===x_pp_ii && g_pp_vi===x_pp_vi,"dual-priv");
    // golden vs independent oracle
    check(g_cycle_rd===(dbg_stop ? sh_cycle : m_cycle),"orc-cycle");
    check(g_instret_rd===(dbg_stop ? sh_instret : m_instret),"orc-instret");
    check(g_hip_rd===orc_hip,"orc-hip-rd");
    check(g_hip_vssip===hvip_vssip && g_hip_vstip===mip_vstip && g_hip_vseip===mip_vseip &&
          g_hip_sgeip===mip_sgeip && g_hip_hvip_v===wen && g_hip_hvip_b===wdata[2],"orc-hip-side");
    check(g_hie_rd===orc_hie,"orc-hie-rd");
    check(g_hie_vssie===mie_vssie && g_hie_vstie===mie_vstie && g_hie_vseie===mie_vseie && g_hie_sgeie===mie_sgeie &&
          g_hie_mie_vss_v===wen && g_hie_mie_vss_b===(wen & wdata[2]) &&
          g_hie_mie_vst_v===wen && g_hie_mie_vst_b===(wen & wdata[6]) &&
          g_hie_mie_vse_v===wen && g_hie_mie_vse_b===(wen & wdata[10]) &&
          g_hie_mie_sge_v===wen && g_hie_mie_sge_b===(wen & wdata[12]),"orc-hie-side");
    check(g_hgeie_rd==={56'b0,sh_hgeie,1'b0} && g_hgeie_ie===sh_hgeie,"orc-hgeie");
    check(g_ms_rd===sh_scratch && g_ms_ro===sh_scratch && g_ss_rd===sh_scratch && g_ss_ro===sh_scratch &&
          g_vss_rd===sh_scratch && g_vss_ro===sh_scratch && g_mn_rd===sh_scratch && g_mn_ro===sh_scratch &&
          g_d0_rd===sh_scratch && g_d0_ro===sh_scratch && g_d1_rd===sh_scratch && g_d1_ro===sh_scratch,"orc-scratch");
    check(g_sctx_rd===sh_sctx && g_sctx_ro===sh_sctx,"orc-sctx");
    check(g_tsel_rd===sh_tsel && g_tsel_ro===sh_tsel,"orc-tsel");
    check(g_pp_ii===orc_ii && g_pp_vi===orc_vi,"orc-priv");
  endtask

  // Drive one cycle of stimulus and compare after the clock edge.
  task automatic step;
    @(negedge clock);
    @(posedge clock); #1;
    compare_now();
  endtask

  task automatic rand_inputs;
    wen=$urandom; dbg_stop=$urandom; upd=$urandom;
    wdata={$urandom,$urandom}; m_cycle={$urandom,$urandom}; m_instret={$urandom,$urandom};
    mip_vstip=$urandom; mip_vseip=$urandom; mip_sgeip=$urandom; hvip_vssip=$urandom;
    mie_vssie=$urandom; mie_vstie=$urandom; mie_vseie=$urandom; mie_sgeie=$urandom;
    csr_addr=$urandom; prvm=$urandom; virt=$urandom; dbg_mode=$urandom;
  endtask

  task automatic do_reset;
    reset=1; wen=0; upd=0;
    repeat(4) @(negedge clock);
    reset=0;
    @(negedge clock);
    // warmup writes so every unreset state register is deterministic
    wen=1; upd=1; wdata=64'hDEAD_BEEF_1234_5678;
    m_cycle=64'h1111_2222_3333_4444; m_instret=64'h5555_6666_7777_8888;
    @(posedge clock); #1;
  endtask

  int unsigned bi;
  initial begin
    void'($value$plusargs("ncycles=%d",NCYCLES));
    rand_inputs();
    do_reset();
    // ---- directed corners ----
    // all-zero / all-ones wdata with wen on and off
    wdata='0; wen=1; upd=1; dbg_stop=0; step();
    wdata='1; wen=1; upd=1; step();
    wdata='0; wen=0; upd=0; step();
    wdata='1; wen=0; upd=0; step();
    // every wdata byte lane individually, wen on (write-to-read-only bits included)
    for (bi=0; bi<8; bi++) begin
      wdata = 64'hFF << (bi*8); wen=1; upd=1; step();
    end
    // dbg_stop read-mux both ways with frozen snapshot vs live count
    wdata=64'h0000_0000_0000_00A5; wen=1; upd=1;
    m_cycle='1; m_instret='1; dbg_stop=1; step();
    m_cycle=64'h0;   m_instret=64'h0;   dbg_stop=1; step();  // snapshot must persist
    dbg_stop=0; step();                                       // live value returns
    // counter rollover edges: all-ones live, update snapshot, wrap live to 0
    m_cycle='1; m_instret='1; upd=1; step();
    m_cycle=64'h0; m_instret=64'h0; upd=0; dbg_stop=1; step();
    dbg_stop=0; step();
    // Tselect write-ignore: 0,1,2,3 take; 4 and above ignored
    wdata=64'd2; wen=1; step();
    wdata=64'd4; wen=1; step();   // ignored: tsel stays 2
    wdata=64'hFFFF_FFFF_FFFF_FFFF; wen=1; step(); // ignored
    wdata=64'd3; wen=1; step();
    // privilege-mode sweep: PRVM x V x debug x address classes
    for (int p=0; p<4; p++) for (int v=0; v<2; v++) for (int d=0; d<2; d++) begin
      prvm=p[1:0]; virt=v[0]; dbg_mode=d[0];
      csr_addr={8'h7B,2'b00,2'b00}; step();        // debug CSR, U level
      csr_addr={8'h7B,2'b11,2'b11}; step();        // debug CSR, M level
      csr_addr={8'h12,2'b00,2'b00}; step();        // normal U CSR
      csr_addr={8'h12,2'b01,2'b00}; step();        // S CSR (addr[9:8]=01)
      csr_addr={8'h12,2'b10,2'b00}; step();        // H CSR (addr[9:8]=10)
      csr_addr={8'h12,2'b11,2'b00}; step();        // M CSR (addr[9:8]=11)
    end
    // mid-run reset: resets Hgeie/Scontext/Tselect; scratch/counters unaffected
    do_reset();
    compare_now();
    // ---- randoms ----
    for (int i=0;i<NCYCLES;i++) begin
      rand_inputs(); step();
    end
    $display("CsrLeaves14 UT: vectors=%0d module_checks=%0d errors=%0d",vectors,vectors*14,errors);
    if (errors==0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
