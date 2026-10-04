// NewcsrLeaves6 双例化逐拍比对 tb —— NewCSR 的 6 个 0 子模块叶：
//   VSstatusModule / VSiselectModule / VstartModule / VStimecmpModule / VtypeModule /
//   VirtualLevelPermitModule
// 每叶 golden <M> u_*_g 与重写件 <M>_xs u_*_i（derive_ut_impl.py 派生）同激励，
// 逐拍比对全部输出（打包成 OUT_W 位向量 g_out / i_out）。
//
// 激励：
//   * 寄存器叶：写使能 40%，写数据 1/8 全 0、1/8 全 1、其余随机；VSstatus 的
//     trap/ret/commit/dirty 各源独立掷点（15%~30%），允许同拍多源（覆盖或合成角）。
//   * VirtualLevelPermit：地址 3/4 从"规则命中地址表"里挑（satp/stopei/vstopei/sip/sie/
//     stimecmp/HPM 窗口/sstateen0..3/senvcfg/sireg 窗口/stopi/scontext/自定义窗口），
//     1/4 全随机；PRVM/V/状态位/counteren/stateen 全随机。
//   * NCYCLES 中点插一次 3 拍复位。
// 覆盖闸（防"DUT 没动也全绿"）：
//   checks   比对次数（0 直接 FAIL）；
//   toggled  golden 输出位中至少翻转一次的个数 —— 每个输出端口至少要有 1 位翻转
//            （port_tog，全部 N_PORT 个端口），否则 FAIL；
//   fires    关键事件计数：vsstatus 各写源、vstart 三条优先级分支、vsiselect 写被 bit12
//            拦下、vtype 提交、VLP 的 EX_II / EX_VI 各自为 1，每类下限 = NCYCLES/400。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0;

  // ---------------- 激励 ----------------
  // VSstatus
  logic        ss_wen;
  logic [63:0] ss_wdata;
  logic        rS_v, rS_sie, rS_spie, rS_spp, rSSDT_v, rM_v, rM_sdt, rMN_v, rMN_sdt, rD_v, rD_sdt;
  logic        tVS_v, tVS_sie, tVS_spie, tVS_spp, tVS_sdt;
  logic        c_fsDirty, c_vsDirty, c_vstart_v;
  logic [6:0]  c_vstart_bits;
  logic        wFCSR, wVCSR, isVirt, mDTE, hDTE;
  // VSiselect / Vstart / VStimecmp
  logic        si_wen, vst_wen, tc_wen;
  logic [63:0] si_wdata, vst_wdata, tc_wdata;
  // Vtype
  logic        vt_valid, vt_vill, vt_vma, vt_vta;
  logic [2:0]  vt_vsew, vt_vlmul;
  // VirtualLevelPermit
  logic        p_wen, p_V, p_vtvm, p_hC, p_hSE0, p_hENV, p_hIND, p_hAIA, p_hIMSIC, p_hCTX;
  logic        p_h1SE, p_h2SE, p_h3SE, p_sC, p_VTI;
  logic [11:0] p_addr;
  logic [1:0]  p_prvm;
  logic [5:0]  p_vgein;
  logic [31:0] p_hcnt, p_scnt;
  logic [63:0] p_henv;

  // ---------------- 输出 ----------------
  // 端口顺序：VSstatus(rdata,SIE,SPIE,SPP,VS,FS,SUM,MXR,SDT) VSiselect(rdata,ALL,inRange)
  //           Vstart(rdata,vstart) VStimecmp(rdata,vstimecmp) Vtype(rdata) VLP(EX_II,EX_VI)
  localparam int N_PORT = 19;
  localparam int OUT_W  = 74 + 78 + 71 + 128 + 64 + 2;   // = 417
  localparam int PORT_W [N_PORT] = '{64,1,1,1,2,2,1,1,1, 64,13,1, 64,7, 64,64, 64, 1,1};
  wire [OUT_W-1:0] g_out, i_out;

`define VSSTATUS_PORTS(o, base) \
    .clock(clock), .reset(reset), .w_wen(ss_wen), .w_wdata(ss_wdata), \
    .rdata(o[base+10 +: 64]), .regOut_SIE(o[base+9]), .regOut_SPIE(o[base+8]), \
    .regOut_SPP(o[base+7]), .regOut_VS(o[base+5 +: 2]), .regOut_FS(o[base+3 +: 2]), \
    .regOut_SUM(o[base+2]), .regOut_MXR(o[base+1]), .regOut_SDT(o[base]), \
    .retFromS_vsstatus_valid(rS_v), .retFromS_vsstatus_bits_SIE(rS_sie), \
    .retFromS_vsstatus_bits_SPIE(rS_spie), .retFromS_vsstatus_bits_SPP(rS_spp), \
    .retFromSSDT_vsstatus_valid(rSSDT_v), .retFromM_vsstatus_valid(rM_v), \
    .retFromM_vsstatus_bits_SDT(rM_sdt), .retFromMN_vsstatus_valid(rMN_v), \
    .retFromMN_vsstatus_bits_SDT(rMN_sdt), .retFromD_vsstatus_valid(rD_v), \
    .retFromD_vsstatus_bits_SDT(rD_sdt), .trapToVS_vsstatus_valid(tVS_v), \
    .trapToVS_vsstatus_bits_SIE(tVS_sie), .trapToVS_vsstatus_bits_SPIE(tVS_spie), \
    .trapToVS_vsstatus_bits_SPP(tVS_spp), .trapToVS_vsstatus_bits_SDT(tVS_sdt), \
    .robCommit_fsDirty(c_fsDirty), .robCommit_vsDirty(c_vsDirty), \
    .robCommit_vstart_valid(c_vstart_v), .robCommit_vstart_bits(c_vstart_bits), \
    .writeFCSR(wFCSR), .writeVCSR(wVCSR), .isVirtMode(isVirt), \
    .menvcfg_DTE(mDTE), .henvcfg_DTE(hDTE)

  // 位段分配（从高到低）：VSstatus 占 [OUT_W-1 : OUT_W-74]，其余依次往下（B_* 是上一段的 lsb）
  localparam int B_SS  = OUT_W - 74;
  localparam int B_SI  = B_SS;               // VSiselect 78 位从这里往下
  localparam int B_VS  = B_SI - 78;          // Vstart 71 位
  localparam int B_TC  = B_VS - 71;          // VStimecmp 128 位
  localparam int B_VT  = B_TC - 128;         // Vtype 64 位
  localparam int B_VLP = B_VT - 64;          // VLP 2 位 = [1:0]

  VSstatusModule    u_ss_g (`VSSTATUS_PORTS(g_out, B_SS));
  VSstatusModule_xs u_ss_i (`VSSTATUS_PORTS(i_out, B_SS));

`define VSISELECT_PORTS(o) \
    .clock(clock), .reset(reset), .w_wen(si_wen), .w_wdata(si_wdata), \
    .rdata(o[B_SI-1 -: 64]), .regOut_ALL(o[B_SI-65 -: 13]), .inIMSICRange(o[B_SI-78])
  VSiselectModule    u_si_g (`VSISELECT_PORTS(g_out));
  VSiselectModule_xs u_si_i (`VSISELECT_PORTS(i_out));

`define VSTART_PORTS(o) \
    .clock(clock), .reset(reset), .w_wen(vst_wen), .w_wdata(vst_wdata), \
    .rdata(o[B_VS-1 -: 64]), .regOut_vstart(o[B_VS-65 -: 7]), \
    .robCommit_vsDirty(c_vsDirty), .robCommit_vstart_valid(c_vstart_v), \
    .robCommit_vstart_bits(c_vstart_bits)
  VstartModule    u_vs_g (`VSTART_PORTS(g_out));
  VstartModule_xs u_vs_i (`VSTART_PORTS(i_out));

`define VSTIMECMP_PORTS(o) \
    .clock(clock), .reset(reset), .w_wen(tc_wen), .w_wdata(tc_wdata), \
    .rdata(o[B_TC-1 -: 64]), .regOut_vstimecmp(o[B_TC-65 -: 64])
  VStimecmpModule    u_tc_g (`VSTIMECMP_PORTS(g_out));
  VStimecmpModule_xs u_tc_i (`VSTIMECMP_PORTS(i_out));

`define VTYPE_PORTS(o) \
    .clock(clock), .reset(reset), .rdata(o[B_VT-1 -: 64]), \
    .robCommit_vtype_valid(vt_valid), .robCommit_vtype_bits_VILL(vt_vill), \
    .robCommit_vtype_bits_VMA(vt_vma), .robCommit_vtype_bits_VTA(vt_vta), \
    .robCommit_vtype_bits_VSEW(vt_vsew), .robCommit_vtype_bits_VLMUL(vt_vlmul)
  VtypeModule    u_vt_g (`VTYPE_PORTS(g_out));
  VtypeModule_xs u_vt_i (`VTYPE_PORTS(i_out));

`define VLP_PORTS(o) \
    .io_in_csrAccess_wen(p_wen), .io_in_csrAccess_addr(p_addr), \
    .io_in_privState_PRVM(p_prvm), .io_in_privState_V(p_V), \
    .io_in_status_vtvm(p_vtvm), .io_in_status_vgein(p_vgein), \
    .io_in_xcounteren_hcounteren(p_hcnt), .io_in_xcounteren_scounteren(p_scnt), \
    .io_in_xenvcfg_henvcfg(p_henv), .io_in_xstateen_hstateen0_C(p_hC), \
    .io_in_xstateen_hstateen0_SE0(p_hSE0), .io_in_xstateen_hstateen0_ENVCFG(p_hENV), \
    .io_in_xstateen_hstateen0_CSRIND(p_hIND), .io_in_xstateen_hstateen0_AIA(p_hAIA), \
    .io_in_xstateen_hstateen0_IMSIC(p_hIMSIC), .io_in_xstateen_hstateen0_CONTEXT(p_hCTX), \
    .io_in_xstateen_hstateen1_SE(p_h1SE), .io_in_xstateen_hstateen2_SE(p_h2SE), \
    .io_in_xstateen_hstateen3_SE(p_h3SE), .io_in_xstateen_sstateen0_C(p_sC), \
    .io_in_aia_hvictlVTI(p_VTI), \
    .io_out_virtualLevelPermit_EX_II(o[B_VLP-1]), .io_out_virtualLevelPermit_EX_VI(o[B_VLP-2])
  VirtualLevelPermitModule    u_vlp_g (`VLP_PORTS(g_out));
  VirtualLevelPermitModule_xs u_vlp_i (`VLP_PORTS(i_out));

  // ---------------- 激励函数 ----------------
  function automatic logic [63:0] rnd_data();
    int unsigned k = $urandom_range(7);
    if (k == 0) return 64'h0;
    if (k == 1) return '1;
    return {$urandom, $urandom};
  endfunction
  function automatic bit pct(int p);
    return $urandom_range(99) < p;
  endfunction
  // VLP 规则命中地址表
  localparam int N_HOT = 24;
  localparam logic [11:0] HOT [N_HOT] = '{
    12'h180, 12'h15C, 12'h25C, 12'h144, 12'h104, 12'h14D, 12'hC00, 12'hC01, 12'hC02, 12'hC1F,
    12'h10C, 12'h10D, 12'h10E, 12'h10F, 12'h10A, 12'h150, 12'h154, 12'h157, 12'hDB0, 12'h5A8,
    12'h5C0, 12'h9FF, 12'h800, 12'hCC0};
  function automatic logic [11:0] rnd_addr();
    logic [11:0] a;
    if ($urandom_range(3) == 0) return $urandom;
    a = HOT[$urandom_range(N_HOT-1)];
    // HPM / 自定义窗口内再随机低位
    if (a[11:8] == 4'hC && a[7:5] == 3'h0) a[4:0] = $urandom;
    if (a == 12'h5C0 || a == 12'h9FF || a == 12'h800 || a == 12'hCC0) a[5:0] = $urandom;
    return a;
  endfunction

  task automatic drive();
    ss_wen = pct(30); ss_wdata = rnd_data();
    rS_v = pct(15); rS_sie = $urandom; rS_spie = $urandom; rS_spp = $urandom;
    rSSDT_v = pct(10); rM_v = pct(10); rM_sdt = $urandom; rMN_v = pct(10); rMN_sdt = $urandom;
    rD_v = pct(10); rD_sdt = $urandom;
    tVS_v = pct(15); tVS_sie = $urandom; tVS_spie = $urandom; tVS_spp = $urandom; tVS_sdt = $urandom;
    c_fsDirty = pct(20); c_vsDirty = pct(20); c_vstart_v = pct(25);
    c_vstart_bits = pct(30) ? 7'h0 : 7'($urandom);
    wFCSR = pct(15); wVCSR = pct(15); isVirt = pct(50); mDTE = pct(60); hDTE = pct(60);
    si_wen = pct(40); si_wdata = rnd_data();
    if (pct(40)) si_wdata[12:0] = 13'($urandom_range(16'h0120, 16'h0060));   // 靠近 IMSIC 窗口边界
    vst_wen = pct(30); vst_wdata = rnd_data();
    tc_wen = pct(40); tc_wdata = rnd_data();
    vt_valid = pct(40); {vt_vill, vt_vma, vt_vta} = $urandom; vt_vsew = $urandom; vt_vlmul = $urandom;
    p_wen = $urandom; p_addr = rnd_addr(); p_prvm = $urandom; p_V = $urandom;
    p_vtvm = $urandom; p_vgein = pct(30) ? 6'h0 : 6'($urandom);
    p_hcnt = pct(20) ? '1 : $urandom; p_scnt = pct(20) ? '1 : $urandom; p_henv = rnd_data();
    {p_hC, p_hSE0, p_hENV, p_hIND, p_hAIA, p_hIMSIC, p_hCTX, p_h1SE, p_h2SE, p_h3SE, p_sC, p_VTI}
      = $urandom;
  endtask

  // ---------------- 覆盖统计 ----------------
  logic [OUT_W-1:0] prev_g, tog;
  longint f_ss_wen = 0, f_ss_ret = 0, f_ss_trap = 0, f_ss_sdtret = 0, f_ss_dirty = 0;
  longint f_vs_wr = 0, f_vs_clr = 0, f_vs_cmt = 0, f_si_blk = 0, f_si_range = 0, f_vt = 0;
  longint f_ii = 0, f_vi = 0;

  always @(negedge clock) if (!reset) begin
    checks++;
    if (g_out !== i_out) begin
      errors++;
      if (errors <= 30)
        $display("[%0t] MISMATCH diff=%h", $time, g_out ^ i_out);
    end
    tog |= prev_g ^ g_out;
    prev_g = g_out;
    f_ss_wen    += ss_wen;
    f_ss_ret    += rS_v & ~ss_wen;
    f_ss_trap   += tVS_v;
    f_ss_sdtret += rSSDT_v | rM_v | rMN_v | rD_v;
    f_ss_dirty  += isVirt & (c_fsDirty | c_vsDirty | wFCSR | wVCSR);
    f_vs_wr     += vst_wen;
    f_vs_clr    += ~vst_wen & c_vsDirty & ~c_vstart_v;
    f_vs_cmt    += ~vst_wen & c_vstart_v;
    f_si_blk    += si_wen & si_wdata[12];
    f_si_range  += g_out[B_SI-78];
    f_vt        += vt_valid;
    f_ii        += g_out[B_VLP-1];
    f_vi        += g_out[B_VLP-2];
  end

  // ---------------- 主流程 ----------------
  initial begin
    int port_tog, lo, minf;
    longint fv [13];
    void'($value$plusargs("ncycles=%d", NCYCLES));
    drive();
    reset = 1;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    prev_g = g_out; tog = '0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(posedge clock); #1;
      if (c == NCYCLES / 2) begin
        reset = 1; repeat (3) @(posedge clock); #1 reset = 0;
      end
      drive();
    end
    // 每个端口至少翻转一位
    port_tog = 0; lo = OUT_W;
    for (int p = 0; p < N_PORT; p++) begin
      lo -= PORT_W[p];
      begin
        bit any = 0;
        for (int b = 0; b < PORT_W[p]; b++) any |= tog[lo + b];
        if (any) port_tog++;
        else $display("NO TOGGLE: port %0d (lsb %0d width %0d)", p, lo, PORT_W[p]);
      end
    end
    fv = '{f_ss_wen, f_ss_ret, f_ss_trap, f_ss_sdtret, f_ss_dirty, f_vs_wr, f_vs_clr, f_vs_cmt,
           f_si_blk, f_si_range, f_vt, f_ii, f_vi};
    minf = NCYCLES / 400;
    $display("NewcsrLeaves6 UT: checks=%0d errors=%0d toggled_bits=%0d/%0d ports=%0d/%0d",
             checks, errors, $countones(tog), OUT_W, port_tog, N_PORT);
    $display("fires: ss_wen=%0d ss_ret=%0d ss_trap=%0d ss_sdtret=%0d ss_dirty=%0d vs_wr=%0d vs_clr=%0d vs_cmt=%0d si_blk=%0d si_range=%0d vt=%0d EX_II=%0d EX_VI=%0d",
             fv[0], fv[1], fv[2], fv[3], fv[4], fv[5], fv[6], fv[7], fv[8], fv[9], fv[10], fv[11], fv[12]);
    if (checks == 0) begin $display("TEST FAILED (no checks)"); $fatal(1); end
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (port_tog != N_PORT) begin $display("TEST FAILED (toggle)"); $fatal(1); end
    foreach (fv[k]) if (fv[k] < minf) begin
      $display("TEST FAILED (fires[%0d]=%0d < %0d)", k, fv[k], minf); $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
