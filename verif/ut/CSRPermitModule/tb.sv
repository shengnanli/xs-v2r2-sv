// CSRPermitModule 双例化逐拍比对 tb（纯组合）。
// golden CSRPermitModule（+golden 6 子模块） vs 重写件 CSRPermitModule_xs（+重写子模块 _xs）。
// 端口表由 golden 头机械抄出（475 输入位 / 9 输出位）；输入打包成 in_vec 每拍重摇。
// 激励偏置（不偏置的话 EX_* 几乎只由地址随机命中，覆盖太稀）：
//   * addr 3/4 从"规则命中地址表"挑（M/S/H/U 各级代表 CSR、HPM、stateen、间接 CSR、自定义窗口、
//     debug CSR、fcsr/vcsr、satp/vsatp、stopei/vstopei、sip/sie），1/4 全随机；
//   * ren/wen 各 50%；xRet 4 条各 10%；*iselect 1/2 落在 IMSIC/iprio 窗口。
// 覆盖闸：每个输出端口在 golden 侧都必须取到过 0 和 1（17 个 1 位输出），
//         并且 EX_II/EX_VI 各自来自"直接"与"仅间接"两条路径的次数都 >= NCYCLES/1000。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint checks = 0, errors = 0;

  localparam int IW = 475, OW = 9;
  logic [IW-1:0] in_vec;
  wire  [OW-1:0] g_out, i_out;
  localparam int OFF_io_in_csrAccess_ren = 474;
  wire [0:0] io_in_csrAccess_ren = in_vec[474 +: 1];
  localparam int OFF_io_in_csrAccess_wen = 473;
  wire [0:0] io_in_csrAccess_wen = in_vec[473 +: 1];
  localparam int OFF_io_in_csrAccess_addr = 461;
  wire [11:0] io_in_csrAccess_addr = in_vec[461 +: 12];
  localparam int OFF_io_in_privState_PRVM = 459;
  wire [1:0] io_in_privState_PRVM = in_vec[459 +: 2];
  localparam int OFF_io_in_privState_V = 458;
  wire [0:0] io_in_privState_V = in_vec[458 +: 1];
  localparam int OFF_io_in_debugMode = 457;
  wire [0:0] io_in_debugMode = in_vec[457 +: 1];
  localparam int OFF_io_in_xRet_mnret = 456;
  wire [0:0] io_in_xRet_mnret = in_vec[456 +: 1];
  localparam int OFF_io_in_xRet_mret = 455;
  wire [0:0] io_in_xRet_mret = in_vec[455 +: 1];
  localparam int OFF_io_in_xRet_sret = 454;
  wire [0:0] io_in_xRet_sret = in_vec[454 +: 1];
  localparam int OFF_io_in_xRet_dret = 453;
  wire [0:0] io_in_xRet_dret = in_vec[453 +: 1];
  localparam int OFF_io_in_status_tsr = 452;
  wire [0:0] io_in_status_tsr = in_vec[452 +: 1];
  localparam int OFF_io_in_status_vtsr = 451;
  wire [0:0] io_in_status_vtsr = in_vec[451 +: 1];
  localparam int OFF_io_in_status_tvm = 450;
  wire [0:0] io_in_status_tvm = in_vec[450 +: 1];
  localparam int OFF_io_in_status_vtvm = 449;
  wire [0:0] io_in_status_vtvm = in_vec[449 +: 1];
  localparam int OFF_io_in_status_vgein = 443;
  wire [5:0] io_in_status_vgein = in_vec[443 +: 6];
  localparam int OFF_io_in_status_mstatusFSOff = 442;
  wire [0:0] io_in_status_mstatusFSOff = in_vec[442 +: 1];
  localparam int OFF_io_in_status_vsstatusFSOff = 441;
  wire [0:0] io_in_status_vsstatusFSOff = in_vec[441 +: 1];
  localparam int OFF_io_in_status_mstatusVSOff = 440;
  wire [0:0] io_in_status_mstatusVSOff = in_vec[440 +: 1];
  localparam int OFF_io_in_status_vsstatusVSOff = 439;
  wire [0:0] io_in_status_vsstatusVSOff = in_vec[439 +: 1];
  localparam int OFF_io_in_xcounteren_mcounteren = 407;
  wire [31:0] io_in_xcounteren_mcounteren = in_vec[407 +: 32];
  localparam int OFF_io_in_xcounteren_hcounteren = 375;
  wire [31:0] io_in_xcounteren_hcounteren = in_vec[375 +: 32];
  localparam int OFF_io_in_xcounteren_scounteren = 343;
  wire [31:0] io_in_xcounteren_scounteren = in_vec[343 +: 32];
  localparam int OFF_io_in_xenvcfg_menvcfg = 279;
  wire [63:0] io_in_xenvcfg_menvcfg = in_vec[279 +: 64];
  localparam int OFF_io_in_xenvcfg_henvcfg = 215;
  wire [63:0] io_in_xenvcfg_henvcfg = in_vec[215 +: 64];
  localparam int OFF_io_in_xstateen_mstateen0_SE0 = 214;
  wire [0:0] io_in_xstateen_mstateen0_SE0 = in_vec[214 +: 1];
  localparam int OFF_io_in_xstateen_mstateen0_ENVCFG = 213;
  wire [0:0] io_in_xstateen_mstateen0_ENVCFG = in_vec[213 +: 1];
  localparam int OFF_io_in_xstateen_mstateen0_CSRIND = 212;
  wire [0:0] io_in_xstateen_mstateen0_CSRIND = in_vec[212 +: 1];
  localparam int OFF_io_in_xstateen_mstateen0_AIA = 211;
  wire [0:0] io_in_xstateen_mstateen0_AIA = in_vec[211 +: 1];
  localparam int OFF_io_in_xstateen_mstateen0_IMSIC = 210;
  wire [0:0] io_in_xstateen_mstateen0_IMSIC = in_vec[210 +: 1];
  localparam int OFF_io_in_xstateen_mstateen0_CONTEXT = 209;
  wire [0:0] io_in_xstateen_mstateen0_CONTEXT = in_vec[209 +: 1];
  localparam int OFF_io_in_xstateen_mstateen0_C = 208;
  wire [0:0] io_in_xstateen_mstateen0_C = in_vec[208 +: 1];
  localparam int OFF_io_in_xstateen_mstateen1_SE = 207;
  wire [0:0] io_in_xstateen_mstateen1_SE = in_vec[207 +: 1];
  localparam int OFF_io_in_xstateen_mstateen2_SE = 206;
  wire [0:0] io_in_xstateen_mstateen2_SE = in_vec[206 +: 1];
  localparam int OFF_io_in_xstateen_mstateen3_SE = 205;
  wire [0:0] io_in_xstateen_mstateen3_SE = in_vec[205 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_C = 204;
  wire [0:0] io_in_xstateen_hstateen0_C = in_vec[204 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_SE0 = 203;
  wire [0:0] io_in_xstateen_hstateen0_SE0 = in_vec[203 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_ENVCFG = 202;
  wire [0:0] io_in_xstateen_hstateen0_ENVCFG = in_vec[202 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_CSRIND = 201;
  wire [0:0] io_in_xstateen_hstateen0_CSRIND = in_vec[201 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_AIA = 200;
  wire [0:0] io_in_xstateen_hstateen0_AIA = in_vec[200 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_IMSIC = 199;
  wire [0:0] io_in_xstateen_hstateen0_IMSIC = in_vec[199 +: 1];
  localparam int OFF_io_in_xstateen_hstateen0_CONTEXT = 198;
  wire [0:0] io_in_xstateen_hstateen0_CONTEXT = in_vec[198 +: 1];
  localparam int OFF_io_in_xstateen_hstateen1_SE = 197;
  wire [0:0] io_in_xstateen_hstateen1_SE = in_vec[197 +: 1];
  localparam int OFF_io_in_xstateen_hstateen2_SE = 196;
  wire [0:0] io_in_xstateen_hstateen2_SE = in_vec[196 +: 1];
  localparam int OFF_io_in_xstateen_hstateen3_SE = 195;
  wire [0:0] io_in_xstateen_hstateen3_SE = in_vec[195 +: 1];
  localparam int OFF_io_in_xstateen_sstateen0_C = 194;
  wire [0:0] io_in_xstateen_sstateen0_C = in_vec[194 +: 1];
  localparam int OFF_io_in_aia_miselect = 130;
  wire [63:0] io_in_aia_miselect = in_vec[130 +: 64];
  localparam int OFF_io_in_aia_siselect = 66;
  wire [63:0] io_in_aia_siselect = in_vec[66 +: 64];
  localparam int OFF_io_in_aia_vsiselect = 2;
  wire [63:0] io_in_aia_vsiselect = in_vec[2 +: 64];
  localparam int OFF_io_in_aia_mvienSEIE = 1;
  wire [0:0] io_in_aia_mvienSEIE = in_vec[1 +: 1];
  localparam int OFF_io_in_aia_hvictlVTI = 0;
  wire [0:0] io_in_aia_hvictlVTI = in_vec[0 +: 1];
  CSRPermitModule u_g (
    .io_in_csrAccess_ren(io_in_csrAccess_ren),
    .io_in_csrAccess_wen(io_in_csrAccess_wen),
    .io_in_csrAccess_addr(io_in_csrAccess_addr),
    .io_in_privState_PRVM(io_in_privState_PRVM),
    .io_in_privState_V(io_in_privState_V),
    .io_in_debugMode(io_in_debugMode),
    .io_in_xRet_mnret(io_in_xRet_mnret),
    .io_in_xRet_mret(io_in_xRet_mret),
    .io_in_xRet_sret(io_in_xRet_sret),
    .io_in_xRet_dret(io_in_xRet_dret),
    .io_in_status_tsr(io_in_status_tsr),
    .io_in_status_vtsr(io_in_status_vtsr),
    .io_in_status_tvm(io_in_status_tvm),
    .io_in_status_vtvm(io_in_status_vtvm),
    .io_in_status_vgein(io_in_status_vgein),
    .io_in_status_mstatusFSOff(io_in_status_mstatusFSOff),
    .io_in_status_vsstatusFSOff(io_in_status_vsstatusFSOff),
    .io_in_status_mstatusVSOff(io_in_status_mstatusVSOff),
    .io_in_status_vsstatusVSOff(io_in_status_vsstatusVSOff),
    .io_in_xcounteren_mcounteren(io_in_xcounteren_mcounteren),
    .io_in_xcounteren_hcounteren(io_in_xcounteren_hcounteren),
    .io_in_xcounteren_scounteren(io_in_xcounteren_scounteren),
    .io_in_xenvcfg_menvcfg(io_in_xenvcfg_menvcfg),
    .io_in_xenvcfg_henvcfg(io_in_xenvcfg_henvcfg),
    .io_in_xstateen_mstateen0_SE0(io_in_xstateen_mstateen0_SE0),
    .io_in_xstateen_mstateen0_ENVCFG(io_in_xstateen_mstateen0_ENVCFG),
    .io_in_xstateen_mstateen0_CSRIND(io_in_xstateen_mstateen0_CSRIND),
    .io_in_xstateen_mstateen0_AIA(io_in_xstateen_mstateen0_AIA),
    .io_in_xstateen_mstateen0_IMSIC(io_in_xstateen_mstateen0_IMSIC),
    .io_in_xstateen_mstateen0_CONTEXT(io_in_xstateen_mstateen0_CONTEXT),
    .io_in_xstateen_mstateen0_C(io_in_xstateen_mstateen0_C),
    .io_in_xstateen_mstateen1_SE(io_in_xstateen_mstateen1_SE),
    .io_in_xstateen_mstateen2_SE(io_in_xstateen_mstateen2_SE),
    .io_in_xstateen_mstateen3_SE(io_in_xstateen_mstateen3_SE),
    .io_in_xstateen_hstateen0_C(io_in_xstateen_hstateen0_C),
    .io_in_xstateen_hstateen0_SE0(io_in_xstateen_hstateen0_SE0),
    .io_in_xstateen_hstateen0_ENVCFG(io_in_xstateen_hstateen0_ENVCFG),
    .io_in_xstateen_hstateen0_CSRIND(io_in_xstateen_hstateen0_CSRIND),
    .io_in_xstateen_hstateen0_AIA(io_in_xstateen_hstateen0_AIA),
    .io_in_xstateen_hstateen0_IMSIC(io_in_xstateen_hstateen0_IMSIC),
    .io_in_xstateen_hstateen0_CONTEXT(io_in_xstateen_hstateen0_CONTEXT),
    .io_in_xstateen_hstateen1_SE(io_in_xstateen_hstateen1_SE),
    .io_in_xstateen_hstateen2_SE(io_in_xstateen_hstateen2_SE),
    .io_in_xstateen_hstateen3_SE(io_in_xstateen_hstateen3_SE),
    .io_in_xstateen_sstateen0_C(io_in_xstateen_sstateen0_C),
    .io_in_aia_miselect(io_in_aia_miselect),
    .io_in_aia_siselect(io_in_aia_siselect),
    .io_in_aia_vsiselect(io_in_aia_vsiselect),
    .io_in_aia_mvienSEIE(io_in_aia_mvienSEIE),
    .io_in_aia_hvictlVTI(io_in_aia_hvictlVTI),
    .io_out_hasLegalWen(g_out[8 +: 1]),
    .io_out_hasLegalMNret(g_out[7 +: 1]),
    .io_out_hasLegalMret(g_out[6 +: 1]),
    .io_out_hasLegalSret(g_out[5 +: 1]),
    .io_out_hasLegalDret(g_out[4 +: 1]),
    .io_out_hasLegalWriteFcsr(g_out[3 +: 1]),
    .io_out_hasLegalWriteVcsr(g_out[2 +: 1]),
    .io_out_EX_II(g_out[1 +: 1]),
    .io_out_EX_VI(g_out[0 +: 1])
  );
  CSRPermitModule_xs u_i (
    .io_in_csrAccess_ren(io_in_csrAccess_ren),
    .io_in_csrAccess_wen(io_in_csrAccess_wen),
    .io_in_csrAccess_addr(io_in_csrAccess_addr),
    .io_in_privState_PRVM(io_in_privState_PRVM),
    .io_in_privState_V(io_in_privState_V),
    .io_in_debugMode(io_in_debugMode),
    .io_in_xRet_mnret(io_in_xRet_mnret),
    .io_in_xRet_mret(io_in_xRet_mret),
    .io_in_xRet_sret(io_in_xRet_sret),
    .io_in_xRet_dret(io_in_xRet_dret),
    .io_in_status_tsr(io_in_status_tsr),
    .io_in_status_vtsr(io_in_status_vtsr),
    .io_in_status_tvm(io_in_status_tvm),
    .io_in_status_vtvm(io_in_status_vtvm),
    .io_in_status_vgein(io_in_status_vgein),
    .io_in_status_mstatusFSOff(io_in_status_mstatusFSOff),
    .io_in_status_vsstatusFSOff(io_in_status_vsstatusFSOff),
    .io_in_status_mstatusVSOff(io_in_status_mstatusVSOff),
    .io_in_status_vsstatusVSOff(io_in_status_vsstatusVSOff),
    .io_in_xcounteren_mcounteren(io_in_xcounteren_mcounteren),
    .io_in_xcounteren_hcounteren(io_in_xcounteren_hcounteren),
    .io_in_xcounteren_scounteren(io_in_xcounteren_scounteren),
    .io_in_xenvcfg_menvcfg(io_in_xenvcfg_menvcfg),
    .io_in_xenvcfg_henvcfg(io_in_xenvcfg_henvcfg),
    .io_in_xstateen_mstateen0_SE0(io_in_xstateen_mstateen0_SE0),
    .io_in_xstateen_mstateen0_ENVCFG(io_in_xstateen_mstateen0_ENVCFG),
    .io_in_xstateen_mstateen0_CSRIND(io_in_xstateen_mstateen0_CSRIND),
    .io_in_xstateen_mstateen0_AIA(io_in_xstateen_mstateen0_AIA),
    .io_in_xstateen_mstateen0_IMSIC(io_in_xstateen_mstateen0_IMSIC),
    .io_in_xstateen_mstateen0_CONTEXT(io_in_xstateen_mstateen0_CONTEXT),
    .io_in_xstateen_mstateen0_C(io_in_xstateen_mstateen0_C),
    .io_in_xstateen_mstateen1_SE(io_in_xstateen_mstateen1_SE),
    .io_in_xstateen_mstateen2_SE(io_in_xstateen_mstateen2_SE),
    .io_in_xstateen_mstateen3_SE(io_in_xstateen_mstateen3_SE),
    .io_in_xstateen_hstateen0_C(io_in_xstateen_hstateen0_C),
    .io_in_xstateen_hstateen0_SE0(io_in_xstateen_hstateen0_SE0),
    .io_in_xstateen_hstateen0_ENVCFG(io_in_xstateen_hstateen0_ENVCFG),
    .io_in_xstateen_hstateen0_CSRIND(io_in_xstateen_hstateen0_CSRIND),
    .io_in_xstateen_hstateen0_AIA(io_in_xstateen_hstateen0_AIA),
    .io_in_xstateen_hstateen0_IMSIC(io_in_xstateen_hstateen0_IMSIC),
    .io_in_xstateen_hstateen0_CONTEXT(io_in_xstateen_hstateen0_CONTEXT),
    .io_in_xstateen_hstateen1_SE(io_in_xstateen_hstateen1_SE),
    .io_in_xstateen_hstateen2_SE(io_in_xstateen_hstateen2_SE),
    .io_in_xstateen_hstateen3_SE(io_in_xstateen_hstateen3_SE),
    .io_in_xstateen_sstateen0_C(io_in_xstateen_sstateen0_C),
    .io_in_aia_miselect(io_in_aia_miselect),
    .io_in_aia_siselect(io_in_aia_siselect),
    .io_in_aia_vsiselect(io_in_aia_vsiselect),
    .io_in_aia_mvienSEIE(io_in_aia_mvienSEIE),
    .io_in_aia_hvictlVTI(io_in_aia_hvictlVTI),
    .io_out_hasLegalWen(i_out[8 +: 1]),
    .io_out_hasLegalMNret(i_out[7 +: 1]),
    .io_out_hasLegalMret(i_out[6 +: 1]),
    .io_out_hasLegalSret(i_out[5 +: 1]),
    .io_out_hasLegalDret(i_out[4 +: 1]),
    .io_out_hasLegalWriteFcsr(i_out[3 +: 1]),
    .io_out_hasLegalWriteVcsr(i_out[2 +: 1]),
    .io_out_EX_II(i_out[1 +: 1]),
    .io_out_EX_VI(i_out[0 +: 1])
  );
  localparam string ONAME [OW] = '{"io_out_hasLegalWen", "io_out_hasLegalMNret", "io_out_hasLegalMret", "io_out_hasLegalSret", "io_out_hasLegalDret", "io_out_hasLegalWriteFcsr", "io_out_hasLegalWriteVcsr", "io_out_EX_II", "io_out_EX_VI"};

  // ---------------- 激励 ----------------
  localparam int N_HOT = 64;
  localparam logic [11:0] HOT [N_HOT] = '{
    12'h300, 12'h301, 12'h302, 12'h306, 12'h30A, 12'h30C, 12'h30D, 12'h30E, 12'h30F, 12'h320,
    12'h323, 12'h350, 12'h351, 12'h35C, 12'hFB0, 12'h7C0, 12'h180, 12'h280, 12'h680, 12'h600,
    12'h606, 12'h60A, 12'h60C, 12'h10A, 12'h10C, 12'h10D, 12'h10E, 12'h10F, 12'h106, 12'h104,
    12'h144, 12'h14D, 12'h24D, 12'h150, 12'h151, 12'h154, 12'h157, 12'h250, 12'h251, 12'h15C,
    12'h25C, 12'hDB0, 12'h5A8, 12'h5C0, 12'h800, 12'hCC0, 12'h001, 12'h002, 12'h003, 12'h008,
    12'h009, 12'h00A, 12'h00F, 12'hC20, 12'hC21, 12'hC22, 12'hC00, 12'hC01, 12'hC02, 12'hC1F,
    12'hB00, 12'h7B0, 12'h7B1, 12'h7A0};
  function automatic logic [11:0] rnd_addr();
    logic [11:0] a;
    if ($urandom_range(3) == 0) return $urandom;
    a = HOT[$urandom_range(N_HOT-1)];
    if (a[11:5] == 7'h60) a[4:0] = $urandom;                         // 计数器窗口
    if (a == 12'h5C0 || a == 12'h800 || a == 12'hCC0) a[5:0] = $urandom; // 自定义窗口
    return a;
  endfunction
  function automatic logic [63:0] rnd_isel();
    case ($urandom_range(3))
      0: return 64'($urandom_range(8'hFF, 8'h70));   // IMSIC 窗口
      1: return 64'($urandom_range(8'h3F, 8'h30));   // iprio 窗口
      2: return 64'($urandom_range(16'h1FF));
      default: return {$urandom, $urandom};
    endcase
  endfunction
  function automatic bit pct(int p);
    return $urandom_range(99) < p;
  endfunction

  task automatic drive();
    for (int k = 0; k < IW; k += 32) in_vec[k +: 32] = $urandom;
    in_vec[OFF_io_in_csrAccess_ren] = pct(50);
    in_vec[OFF_io_in_csrAccess_wen] = pct(50);
    force_fields();
  endtask
  // 关键字段用偏置值覆盖（通过 in_vec 位段写回，保持端口表机械生成）
  task automatic force_fields();
    logic [11:0] a = rnd_addr();
    logic [63:0] mi = rnd_isel(), si = rnd_isel(), vsi = rnd_isel();
    in_vec[OFF_io_in_csrAccess_addr +: $bits(io_in_csrAccess_addr)] = a;
    in_vec[OFF_io_in_xRet_mnret +: $bits(io_in_xRet_mnret)] = pct(10);
    in_vec[OFF_io_in_xRet_mret +: $bits(io_in_xRet_mret)] = pct(10);
    in_vec[OFF_io_in_xRet_sret +: $bits(io_in_xRet_sret)] = pct(10);
    in_vec[OFF_io_in_xRet_dret +: $bits(io_in_xRet_dret)] = pct(10);
    in_vec[OFF_io_in_status_vgein +: $bits(io_in_status_vgein)] = pct(30) ? 0 : $urandom_range(9);
    in_vec[OFF_io_in_aia_miselect +: $bits(io_in_aia_miselect)] = mi;
    in_vec[OFF_io_in_aia_siselect +: $bits(io_in_aia_siselect)] = si;
    in_vec[OFF_io_in_aia_vsiselect +: $bits(io_in_aia_vsiselect)] = vsi;
    // 1/4 拍：VS 态访问 sireg 窗口且 stateen/counteren 全开 —— 让"直接"规则全过、只剩间接规则
    if (pct(25)) begin
      in_vec[OFF_io_in_privState_V] = 1'b1;
      in_vec[OFF_io_in_privState_PRVM +: 2] = 2'h1;
      in_vec[OFF_io_in_csrAccess_addr +: 12] = 12'($urandom_range(12'h157, 12'h151));
      in_vec[OFF_io_in_xstateen_mstateen0_CSRIND] = 1'b1;
      in_vec[OFF_io_in_xstateen_hstateen0_CSRIND] = 1'b1;
      in_vec[OFF_io_in_xstateen_mstateen0_AIA] = 1'b1;
      in_vec[OFF_io_in_xstateen_hstateen0_AIA] = 1'b1;
    end
  endtask

  // ---------------- 比对与覆盖 ----------------
  bit [OW-1:0] seen0, seen1;
  longint f_ii_direct = 0, f_ii_indirect = 0, f_vi_direct = 0, f_vi_indirect = 0, f_xret = 0;
  task automatic check();
    checks++;
    if (g_out !== i_out) begin
      errors++;
      if (errors <= 30)
        $display("[%0d] MISMATCH g=%b i=%b in=%h", checks, g_out, i_out, in_vec);
    end
    seen0 |= ~g_out; seen1 |= g_out;
    if (u_g.io_out_EX_II_0 & u_g.directPermit_illegal) f_ii_direct++;
    if (u_g.io_out_EX_II_0 & ~u_g.directPermit_illegal
        & u_g._indirectCSRPermitMod_io_out_indirectCSR_EX_II) f_ii_indirect++;
    if (u_g.io_out_EX_VI_0 & u_g.directPermit_illegal) f_vi_direct++;
    if (u_g.io_out_EX_VI_0 & ~u_g.directPermit_illegal
        & u_g._indirectCSRPermitMod_io_out_indirectCSR_EX_VI) f_vi_indirect++;
    if (u_g._xRetPermitMod_io_out_Xret_EX_II | u_g._xRetPermitMod_io_out_Xret_EX_VI) f_xret++;
  endtask

  initial begin
    longint minf;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    seen0 = '0; seen1 = '0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      drive();
      #1;
      check();
      #4;
    end
    minf = NCYCLES / 1000;
    $display("CSRPermitModule UT: checks=%0d errors=%0d seen0=%b seen1=%b", checks, errors, seen0, seen1);
    $display("fires: ii_direct=%0d ii_indirect=%0d vi_direct=%0d vi_indirect=%0d xret=%0d",
             f_ii_direct, f_ii_indirect, f_vi_direct, f_vi_indirect, f_xret);
    if (checks == 0) begin $display("TEST FAILED (no checks)"); $fatal(1); end
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (~&seen0 || ~&seen1) begin $display("TEST FAILED (output not toggled)"); $fatal(1); end
    if (f_ii_direct < minf || f_ii_indirect < minf || f_vi_direct < minf || f_vi_indirect < minf
        || f_xret < minf) begin
      $display("TEST FAILED (fires < %0d)", minf); $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
