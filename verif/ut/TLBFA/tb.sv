// =============================================================================
// TLBFA 家族 UT —— 四个变体各一对 DUT（golden 与重写件 <名>_xs）同激励逐拍全比。
//
// ★本文件由 verif/ut/TLBFA/gen.py 生成，勿手改★（手改会被下一次跑生成器静默删掉）
//
// 比对口径：每个变体把**全部输出端口**拼成一根大向量逐拍比（不是挑几根比），
//   失配那拍再逐端口打印差异。采样点在时钟低电平中段（#4），组合输出已稳定。
//
// 激励要点（要让 TLB 真的命中，随机不能是纯随机）：
//   · 地址取自一个 24 项的 vpn 池，池内高位大量重合 —— 这样 refill 与查询会撞上，
//     且超页（level>0 只比高位）也能命中；低 3 位单独随机以搅动 sector 内的
//     valididx / pteidx / ppn_low 选择。
//   · s2xlate 四种取值均匀出现；命中要求 entry.s2xlate 与请求**完全相等**，
//     所以读写用同一分布才有命中率。
//   · asid/vmid/priv.virt 在 0..3 的小值域里变，保证 asid_hit / vmid_hit 两条路
//     既有命中也有不命中。
//   · sfence / hfence.vvma / hfence.gvma 各约 1%，rs1/rs2 组合均匀。
//   · refill 约 25%，与 sfence 会同拍撞上（golden 的优先级：sfence 赢，entry 照写
//     但 v 不置位）——这个角落靠随机自然覆盖，覆盖计数里有它。
//
// 收尾判据：errors==0 **并且**覆盖门槛全部达标（见 TEST PASSED 那段）。
//   只有 errors==0 是不够的：本工程踩过"两边都不动、比的是一串 0"的假绿。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst = 1;
  bit warm = 0;            // 复位后的热身窗口：两侧无复位寄存器的随机初值不同，
                           // 要等第一次 req/refill 把它们冲成确定值后才开始比
  int errors = 0, checks = 0;

  always #5 clk = ~clk;

  // ---- 共享激励信号 ----
  logic        sf_valid, sf_rs1, sf_rs2, sf_hv, sf_hg;
  logic [49:0] sf_addr;
  logic [15:0] sf_id;
  logic [15:0] csr_satp_asid, csr_vsatp_asid, csr_hgatp_vmid;
  logic        csr_bme, csr_cmode, csr_virt;

  logic [3:0]        rq_valid;
  logic [3:0][37:0]  rq_vpn;
  logic [3:0][1:0]   rq_s2x;

  logic        w_valid;
  logic [5:0]  w_way;
  logic [1:0]  w_s2xlate;
  logic [34:0] w_s1_entry_tag;
  logic [15:0] w_s1_entry_asid;
  logic [13:0] w_s1_entry_vmid;
  logic        w_s1_entry_n;
  logic [1:0]  w_s1_entry_pbmt;
  logic        w_s1_entry_perm_d, w_s1_entry_perm_a, w_s1_entry_perm_g;
  logic        w_s1_entry_perm_u, w_s1_entry_perm_x, w_s1_entry_perm_w, w_s1_entry_perm_r;
  logic [1:0]  w_s1_entry_level;
  logic        w_s1_entry_v;
  logic [40:0] w_s1_entry_ppn;
  logic [7:0][2:0] w_s1_ppn_low;
  logic [7:0]  w_s1_valididx, w_s1_pteidx;
  logic        w_s1_pf, w_s1_af;
  logic [37:0] w_s2_entry_tag;
  logic [13:0] w_s2_entry_vmid;
  logic        w_s2_entry_n;
  logic [1:0]  w_s2_entry_pbmt;
  logic [37:0] w_s2_entry_ppn;
  logic        w_s2_entry_perm_d, w_s2_entry_perm_a, w_s2_entry_perm_g;
  logic        w_s2_entry_perm_u, w_s2_entry_perm_x, w_s2_entry_perm_w, w_s2_entry_perm_r;
  logic [1:0]  w_s2_entry_level;
  logic        w_s2_gpf, w_s2_gaf;

  // ------------------------------------------------------------------
  //  TLBFA: PORTS=3，140 端口（57 个输出逐拍全比）
  // ------------------------------------------------------------------
  wire g_TLBFA_io_r_resp_0_bits_hit, x_TLBFA_io_r_resp_0_bits_hit;
  wire [35:0] g_TLBFA_io_r_resp_0_bits_ppn_0, x_TLBFA_io_r_resp_0_bits_ppn_0;
  wire [1:0] g_TLBFA_io_r_resp_0_bits_pbmt_0, x_TLBFA_io_r_resp_0_bits_pbmt_0;
  wire [1:0] g_TLBFA_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_io_r_resp_0_bits_g_pbmt_0;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_pf, x_TLBFA_io_r_resp_0_bits_perm_0_pf;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_af, x_TLBFA_io_r_resp_0_bits_perm_0_af;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_v, x_TLBFA_io_r_resp_0_bits_perm_0_v;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_a, x_TLBFA_io_r_resp_0_bits_perm_0_a;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_u, x_TLBFA_io_r_resp_0_bits_perm_0_u;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_x, x_TLBFA_io_r_resp_0_bits_perm_0_x;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_w, x_TLBFA_io_r_resp_0_bits_perm_0_w;
  wire g_TLBFA_io_r_resp_0_bits_perm_0_r, x_TLBFA_io_r_resp_0_bits_perm_0_r;
  wire g_TLBFA_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_io_r_resp_0_bits_g_perm_0_pf;
  wire g_TLBFA_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_io_r_resp_0_bits_g_perm_0_af;
  wire g_TLBFA_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_io_r_resp_0_bits_g_perm_0_a;
  wire g_TLBFA_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_io_r_resp_0_bits_g_perm_0_x;
  wire [1:0] g_TLBFA_io_r_resp_0_bits_s2xlate_0, x_TLBFA_io_r_resp_0_bits_s2xlate_0;
  wire g_TLBFA_io_r_resp_1_bits_hit, x_TLBFA_io_r_resp_1_bits_hit;
  wire [35:0] g_TLBFA_io_r_resp_1_bits_ppn_0, x_TLBFA_io_r_resp_1_bits_ppn_0;
  wire [1:0] g_TLBFA_io_r_resp_1_bits_pbmt_0, x_TLBFA_io_r_resp_1_bits_pbmt_0;
  wire [1:0] g_TLBFA_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_io_r_resp_1_bits_g_pbmt_0;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_pf, x_TLBFA_io_r_resp_1_bits_perm_0_pf;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_af, x_TLBFA_io_r_resp_1_bits_perm_0_af;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_v, x_TLBFA_io_r_resp_1_bits_perm_0_v;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_a, x_TLBFA_io_r_resp_1_bits_perm_0_a;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_u, x_TLBFA_io_r_resp_1_bits_perm_0_u;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_x, x_TLBFA_io_r_resp_1_bits_perm_0_x;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_w, x_TLBFA_io_r_resp_1_bits_perm_0_w;
  wire g_TLBFA_io_r_resp_1_bits_perm_0_r, x_TLBFA_io_r_resp_1_bits_perm_0_r;
  wire g_TLBFA_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_io_r_resp_1_bits_g_perm_0_pf;
  wire g_TLBFA_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_io_r_resp_1_bits_g_perm_0_af;
  wire g_TLBFA_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_io_r_resp_1_bits_g_perm_0_a;
  wire g_TLBFA_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_io_r_resp_1_bits_g_perm_0_x;
  wire [1:0] g_TLBFA_io_r_resp_1_bits_s2xlate_0, x_TLBFA_io_r_resp_1_bits_s2xlate_0;
  wire g_TLBFA_io_r_resp_2_bits_hit, x_TLBFA_io_r_resp_2_bits_hit;
  wire [35:0] g_TLBFA_io_r_resp_2_bits_ppn_0, x_TLBFA_io_r_resp_2_bits_ppn_0;
  wire [1:0] g_TLBFA_io_r_resp_2_bits_pbmt_0, x_TLBFA_io_r_resp_2_bits_pbmt_0;
  wire [1:0] g_TLBFA_io_r_resp_2_bits_g_pbmt_0, x_TLBFA_io_r_resp_2_bits_g_pbmt_0;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_pf, x_TLBFA_io_r_resp_2_bits_perm_0_pf;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_af, x_TLBFA_io_r_resp_2_bits_perm_0_af;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_v, x_TLBFA_io_r_resp_2_bits_perm_0_v;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_a, x_TLBFA_io_r_resp_2_bits_perm_0_a;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_u, x_TLBFA_io_r_resp_2_bits_perm_0_u;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_x, x_TLBFA_io_r_resp_2_bits_perm_0_x;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_w, x_TLBFA_io_r_resp_2_bits_perm_0_w;
  wire g_TLBFA_io_r_resp_2_bits_perm_0_r, x_TLBFA_io_r_resp_2_bits_perm_0_r;
  wire g_TLBFA_io_r_resp_2_bits_g_perm_0_pf, x_TLBFA_io_r_resp_2_bits_g_perm_0_pf;
  wire g_TLBFA_io_r_resp_2_bits_g_perm_0_af, x_TLBFA_io_r_resp_2_bits_g_perm_0_af;
  wire g_TLBFA_io_r_resp_2_bits_g_perm_0_a, x_TLBFA_io_r_resp_2_bits_g_perm_0_a;
  wire g_TLBFA_io_r_resp_2_bits_g_perm_0_x, x_TLBFA_io_r_resp_2_bits_g_perm_0_x;
  wire [1:0] g_TLBFA_io_r_resp_2_bits_s2xlate_0, x_TLBFA_io_r_resp_2_bits_s2xlate_0;
  wire g_TLBFA_io_access_0_touch_ways_valid, x_TLBFA_io_access_0_touch_ways_valid;
  wire [5:0] g_TLBFA_io_access_0_touch_ways_bits, x_TLBFA_io_access_0_touch_ways_bits;
  wire g_TLBFA_io_access_1_touch_ways_valid, x_TLBFA_io_access_1_touch_ways_valid;
  wire [5:0] g_TLBFA_io_access_1_touch_ways_bits, x_TLBFA_io_access_1_touch_ways_bits;
  wire g_TLBFA_io_access_2_touch_ways_valid, x_TLBFA_io_access_2_touch_ways_valid;
  wire [5:0] g_TLBFA_io_access_2_touch_ways_bits, x_TLBFA_io_access_2_touch_ways_bits;

  TLBFA u_g_TLBFA (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_req_2_valid(rq_valid[2]),
    .io_r_req_2_bits_vpn(rq_vpn[2]),
    .io_r_req_2_bits_s2xlate(rq_s2x[2]),
    .io_r_resp_0_bits_hit(g_TLBFA_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(g_TLBFA_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(g_TLBFA_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(g_TLBFA_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(g_TLBFA_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(g_TLBFA_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(g_TLBFA_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_a(g_TLBFA_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(g_TLBFA_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(g_TLBFA_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(g_TLBFA_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(g_TLBFA_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(g_TLBFA_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(g_TLBFA_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_a(g_TLBFA_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(g_TLBFA_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_s2xlate_0(g_TLBFA_io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(g_TLBFA_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(g_TLBFA_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(g_TLBFA_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(g_TLBFA_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(g_TLBFA_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(g_TLBFA_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(g_TLBFA_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_a(g_TLBFA_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(g_TLBFA_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(g_TLBFA_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(g_TLBFA_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(g_TLBFA_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(g_TLBFA_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(g_TLBFA_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_a(g_TLBFA_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(g_TLBFA_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_s2xlate_0(g_TLBFA_io_r_resp_1_bits_s2xlate_0),
    .io_r_resp_2_bits_hit(g_TLBFA_io_r_resp_2_bits_hit),
    .io_r_resp_2_bits_ppn_0(g_TLBFA_io_r_resp_2_bits_ppn_0),
    .io_r_resp_2_bits_pbmt_0(g_TLBFA_io_r_resp_2_bits_pbmt_0),
    .io_r_resp_2_bits_g_pbmt_0(g_TLBFA_io_r_resp_2_bits_g_pbmt_0),
    .io_r_resp_2_bits_perm_0_pf(g_TLBFA_io_r_resp_2_bits_perm_0_pf),
    .io_r_resp_2_bits_perm_0_af(g_TLBFA_io_r_resp_2_bits_perm_0_af),
    .io_r_resp_2_bits_perm_0_v(g_TLBFA_io_r_resp_2_bits_perm_0_v),
    .io_r_resp_2_bits_perm_0_a(g_TLBFA_io_r_resp_2_bits_perm_0_a),
    .io_r_resp_2_bits_perm_0_u(g_TLBFA_io_r_resp_2_bits_perm_0_u),
    .io_r_resp_2_bits_perm_0_x(g_TLBFA_io_r_resp_2_bits_perm_0_x),
    .io_r_resp_2_bits_perm_0_w(g_TLBFA_io_r_resp_2_bits_perm_0_w),
    .io_r_resp_2_bits_perm_0_r(g_TLBFA_io_r_resp_2_bits_perm_0_r),
    .io_r_resp_2_bits_g_perm_0_pf(g_TLBFA_io_r_resp_2_bits_g_perm_0_pf),
    .io_r_resp_2_bits_g_perm_0_af(g_TLBFA_io_r_resp_2_bits_g_perm_0_af),
    .io_r_resp_2_bits_g_perm_0_a(g_TLBFA_io_r_resp_2_bits_g_perm_0_a),
    .io_r_resp_2_bits_g_perm_0_x(g_TLBFA_io_r_resp_2_bits_g_perm_0_x),
    .io_r_resp_2_bits_s2xlate_0(g_TLBFA_io_r_resp_2_bits_s2xlate_0),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(g_TLBFA_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(g_TLBFA_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(g_TLBFA_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(g_TLBFA_io_access_1_touch_ways_bits),
    .io_access_2_touch_ways_valid(g_TLBFA_io_access_2_touch_ways_valid),
    .io_access_2_touch_ways_bits(g_TLBFA_io_access_2_touch_ways_bits)
  );

  TLBFA_xs u_x_TLBFA (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_req_2_valid(rq_valid[2]),
    .io_r_req_2_bits_vpn(rq_vpn[2]),
    .io_r_req_2_bits_s2xlate(rq_s2x[2]),
    .io_r_resp_0_bits_hit(x_TLBFA_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(x_TLBFA_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(x_TLBFA_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(x_TLBFA_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(x_TLBFA_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(x_TLBFA_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(x_TLBFA_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_a(x_TLBFA_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(x_TLBFA_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(x_TLBFA_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(x_TLBFA_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(x_TLBFA_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(x_TLBFA_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(x_TLBFA_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_a(x_TLBFA_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(x_TLBFA_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_s2xlate_0(x_TLBFA_io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(x_TLBFA_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(x_TLBFA_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(x_TLBFA_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(x_TLBFA_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(x_TLBFA_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(x_TLBFA_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(x_TLBFA_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_a(x_TLBFA_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(x_TLBFA_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(x_TLBFA_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(x_TLBFA_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(x_TLBFA_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(x_TLBFA_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(x_TLBFA_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_a(x_TLBFA_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(x_TLBFA_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_s2xlate_0(x_TLBFA_io_r_resp_1_bits_s2xlate_0),
    .io_r_resp_2_bits_hit(x_TLBFA_io_r_resp_2_bits_hit),
    .io_r_resp_2_bits_ppn_0(x_TLBFA_io_r_resp_2_bits_ppn_0),
    .io_r_resp_2_bits_pbmt_0(x_TLBFA_io_r_resp_2_bits_pbmt_0),
    .io_r_resp_2_bits_g_pbmt_0(x_TLBFA_io_r_resp_2_bits_g_pbmt_0),
    .io_r_resp_2_bits_perm_0_pf(x_TLBFA_io_r_resp_2_bits_perm_0_pf),
    .io_r_resp_2_bits_perm_0_af(x_TLBFA_io_r_resp_2_bits_perm_0_af),
    .io_r_resp_2_bits_perm_0_v(x_TLBFA_io_r_resp_2_bits_perm_0_v),
    .io_r_resp_2_bits_perm_0_a(x_TLBFA_io_r_resp_2_bits_perm_0_a),
    .io_r_resp_2_bits_perm_0_u(x_TLBFA_io_r_resp_2_bits_perm_0_u),
    .io_r_resp_2_bits_perm_0_x(x_TLBFA_io_r_resp_2_bits_perm_0_x),
    .io_r_resp_2_bits_perm_0_w(x_TLBFA_io_r_resp_2_bits_perm_0_w),
    .io_r_resp_2_bits_perm_0_r(x_TLBFA_io_r_resp_2_bits_perm_0_r),
    .io_r_resp_2_bits_g_perm_0_pf(x_TLBFA_io_r_resp_2_bits_g_perm_0_pf),
    .io_r_resp_2_bits_g_perm_0_af(x_TLBFA_io_r_resp_2_bits_g_perm_0_af),
    .io_r_resp_2_bits_g_perm_0_a(x_TLBFA_io_r_resp_2_bits_g_perm_0_a),
    .io_r_resp_2_bits_g_perm_0_x(x_TLBFA_io_r_resp_2_bits_g_perm_0_x),
    .io_r_resp_2_bits_s2xlate_0(x_TLBFA_io_r_resp_2_bits_s2xlate_0),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(x_TLBFA_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(x_TLBFA_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(x_TLBFA_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(x_TLBFA_io_access_1_touch_ways_bits),
    .io_access_2_touch_ways_valid(x_TLBFA_io_access_2_touch_ways_valid),
    .io_access_2_touch_ways_bits(x_TLBFA_io_access_2_touch_ways_bits)
  );

  wire [185:0] gall_TLBFA = {g_TLBFA_io_r_resp_0_bits_hit, g_TLBFA_io_r_resp_0_bits_ppn_0, g_TLBFA_io_r_resp_0_bits_pbmt_0, g_TLBFA_io_r_resp_0_bits_g_pbmt_0, g_TLBFA_io_r_resp_0_bits_perm_0_pf, g_TLBFA_io_r_resp_0_bits_perm_0_af, g_TLBFA_io_r_resp_0_bits_perm_0_v, g_TLBFA_io_r_resp_0_bits_perm_0_a, g_TLBFA_io_r_resp_0_bits_perm_0_u, g_TLBFA_io_r_resp_0_bits_perm_0_x, g_TLBFA_io_r_resp_0_bits_perm_0_w, g_TLBFA_io_r_resp_0_bits_perm_0_r, g_TLBFA_io_r_resp_0_bits_g_perm_0_pf, g_TLBFA_io_r_resp_0_bits_g_perm_0_af, g_TLBFA_io_r_resp_0_bits_g_perm_0_a, g_TLBFA_io_r_resp_0_bits_g_perm_0_x, g_TLBFA_io_r_resp_0_bits_s2xlate_0, g_TLBFA_io_r_resp_1_bits_hit, g_TLBFA_io_r_resp_1_bits_ppn_0, g_TLBFA_io_r_resp_1_bits_pbmt_0, g_TLBFA_io_r_resp_1_bits_g_pbmt_0, g_TLBFA_io_r_resp_1_bits_perm_0_pf, g_TLBFA_io_r_resp_1_bits_perm_0_af, g_TLBFA_io_r_resp_1_bits_perm_0_v, g_TLBFA_io_r_resp_1_bits_perm_0_a, g_TLBFA_io_r_resp_1_bits_perm_0_u, g_TLBFA_io_r_resp_1_bits_perm_0_x, g_TLBFA_io_r_resp_1_bits_perm_0_w, g_TLBFA_io_r_resp_1_bits_perm_0_r, g_TLBFA_io_r_resp_1_bits_g_perm_0_pf, g_TLBFA_io_r_resp_1_bits_g_perm_0_af, g_TLBFA_io_r_resp_1_bits_g_perm_0_a, g_TLBFA_io_r_resp_1_bits_g_perm_0_x, g_TLBFA_io_r_resp_1_bits_s2xlate_0, g_TLBFA_io_r_resp_2_bits_hit, g_TLBFA_io_r_resp_2_bits_ppn_0, g_TLBFA_io_r_resp_2_bits_pbmt_0, g_TLBFA_io_r_resp_2_bits_g_pbmt_0, g_TLBFA_io_r_resp_2_bits_perm_0_pf, g_TLBFA_io_r_resp_2_bits_perm_0_af, g_TLBFA_io_r_resp_2_bits_perm_0_v, g_TLBFA_io_r_resp_2_bits_perm_0_a, g_TLBFA_io_r_resp_2_bits_perm_0_u, g_TLBFA_io_r_resp_2_bits_perm_0_x, g_TLBFA_io_r_resp_2_bits_perm_0_w, g_TLBFA_io_r_resp_2_bits_perm_0_r, g_TLBFA_io_r_resp_2_bits_g_perm_0_pf, g_TLBFA_io_r_resp_2_bits_g_perm_0_af, g_TLBFA_io_r_resp_2_bits_g_perm_0_a, g_TLBFA_io_r_resp_2_bits_g_perm_0_x, g_TLBFA_io_r_resp_2_bits_s2xlate_0, g_TLBFA_io_access_0_touch_ways_valid, g_TLBFA_io_access_0_touch_ways_bits, g_TLBFA_io_access_1_touch_ways_valid, g_TLBFA_io_access_1_touch_ways_bits, g_TLBFA_io_access_2_touch_ways_valid, g_TLBFA_io_access_2_touch_ways_bits};
  wire [185:0] xall_TLBFA = {x_TLBFA_io_r_resp_0_bits_hit, x_TLBFA_io_r_resp_0_bits_ppn_0, x_TLBFA_io_r_resp_0_bits_pbmt_0, x_TLBFA_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_io_r_resp_0_bits_perm_0_pf, x_TLBFA_io_r_resp_0_bits_perm_0_af, x_TLBFA_io_r_resp_0_bits_perm_0_v, x_TLBFA_io_r_resp_0_bits_perm_0_a, x_TLBFA_io_r_resp_0_bits_perm_0_u, x_TLBFA_io_r_resp_0_bits_perm_0_x, x_TLBFA_io_r_resp_0_bits_perm_0_w, x_TLBFA_io_r_resp_0_bits_perm_0_r, x_TLBFA_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_io_r_resp_0_bits_s2xlate_0, x_TLBFA_io_r_resp_1_bits_hit, x_TLBFA_io_r_resp_1_bits_ppn_0, x_TLBFA_io_r_resp_1_bits_pbmt_0, x_TLBFA_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_io_r_resp_1_bits_perm_0_pf, x_TLBFA_io_r_resp_1_bits_perm_0_af, x_TLBFA_io_r_resp_1_bits_perm_0_v, x_TLBFA_io_r_resp_1_bits_perm_0_a, x_TLBFA_io_r_resp_1_bits_perm_0_u, x_TLBFA_io_r_resp_1_bits_perm_0_x, x_TLBFA_io_r_resp_1_bits_perm_0_w, x_TLBFA_io_r_resp_1_bits_perm_0_r, x_TLBFA_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_io_r_resp_1_bits_s2xlate_0, x_TLBFA_io_r_resp_2_bits_hit, x_TLBFA_io_r_resp_2_bits_ppn_0, x_TLBFA_io_r_resp_2_bits_pbmt_0, x_TLBFA_io_r_resp_2_bits_g_pbmt_0, x_TLBFA_io_r_resp_2_bits_perm_0_pf, x_TLBFA_io_r_resp_2_bits_perm_0_af, x_TLBFA_io_r_resp_2_bits_perm_0_v, x_TLBFA_io_r_resp_2_bits_perm_0_a, x_TLBFA_io_r_resp_2_bits_perm_0_u, x_TLBFA_io_r_resp_2_bits_perm_0_x, x_TLBFA_io_r_resp_2_bits_perm_0_w, x_TLBFA_io_r_resp_2_bits_perm_0_r, x_TLBFA_io_r_resp_2_bits_g_perm_0_pf, x_TLBFA_io_r_resp_2_bits_g_perm_0_af, x_TLBFA_io_r_resp_2_bits_g_perm_0_a, x_TLBFA_io_r_resp_2_bits_g_perm_0_x, x_TLBFA_io_r_resp_2_bits_s2xlate_0, x_TLBFA_io_access_0_touch_ways_valid, x_TLBFA_io_access_0_touch_ways_bits, x_TLBFA_io_access_1_touch_ways_valid, x_TLBFA_io_access_1_touch_ways_bits, x_TLBFA_io_access_2_touch_ways_valid, x_TLBFA_io_access_2_touch_ways_bits};

  task automatic diff_TLBFA();
    if (g_TLBFA_io_r_resp_0_bits_hit !== x_TLBFA_io_r_resp_0_bits_hit) $display("    TLBFA.io_r_resp_0_bits_hit: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_hit, x_TLBFA_io_r_resp_0_bits_hit);
    if (g_TLBFA_io_r_resp_0_bits_ppn_0 !== x_TLBFA_io_r_resp_0_bits_ppn_0) $display("    TLBFA.io_r_resp_0_bits_ppn_0: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_ppn_0, x_TLBFA_io_r_resp_0_bits_ppn_0);
    if (g_TLBFA_io_r_resp_0_bits_pbmt_0 !== x_TLBFA_io_r_resp_0_bits_pbmt_0) $display("    TLBFA.io_r_resp_0_bits_pbmt_0: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_pbmt_0, x_TLBFA_io_r_resp_0_bits_pbmt_0);
    if (g_TLBFA_io_r_resp_0_bits_g_pbmt_0 !== x_TLBFA_io_r_resp_0_bits_g_pbmt_0) $display("    TLBFA.io_r_resp_0_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_io_r_resp_0_bits_g_pbmt_0);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_pf !== x_TLBFA_io_r_resp_0_bits_perm_0_pf) $display("    TLBFA.io_r_resp_0_bits_perm_0_pf: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_pf, x_TLBFA_io_r_resp_0_bits_perm_0_pf);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_af !== x_TLBFA_io_r_resp_0_bits_perm_0_af) $display("    TLBFA.io_r_resp_0_bits_perm_0_af: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_af, x_TLBFA_io_r_resp_0_bits_perm_0_af);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_v !== x_TLBFA_io_r_resp_0_bits_perm_0_v) $display("    TLBFA.io_r_resp_0_bits_perm_0_v: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_v, x_TLBFA_io_r_resp_0_bits_perm_0_v);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_a !== x_TLBFA_io_r_resp_0_bits_perm_0_a) $display("    TLBFA.io_r_resp_0_bits_perm_0_a: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_a, x_TLBFA_io_r_resp_0_bits_perm_0_a);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_u !== x_TLBFA_io_r_resp_0_bits_perm_0_u) $display("    TLBFA.io_r_resp_0_bits_perm_0_u: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_u, x_TLBFA_io_r_resp_0_bits_perm_0_u);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_x !== x_TLBFA_io_r_resp_0_bits_perm_0_x) $display("    TLBFA.io_r_resp_0_bits_perm_0_x: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_x, x_TLBFA_io_r_resp_0_bits_perm_0_x);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_w !== x_TLBFA_io_r_resp_0_bits_perm_0_w) $display("    TLBFA.io_r_resp_0_bits_perm_0_w: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_w, x_TLBFA_io_r_resp_0_bits_perm_0_w);
    if (g_TLBFA_io_r_resp_0_bits_perm_0_r !== x_TLBFA_io_r_resp_0_bits_perm_0_r) $display("    TLBFA.io_r_resp_0_bits_perm_0_r: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_perm_0_r, x_TLBFA_io_r_resp_0_bits_perm_0_r);
    if (g_TLBFA_io_r_resp_0_bits_g_perm_0_pf !== x_TLBFA_io_r_resp_0_bits_g_perm_0_pf) $display("    TLBFA.io_r_resp_0_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_io_r_resp_0_bits_g_perm_0_pf);
    if (g_TLBFA_io_r_resp_0_bits_g_perm_0_af !== x_TLBFA_io_r_resp_0_bits_g_perm_0_af) $display("    TLBFA.io_r_resp_0_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_io_r_resp_0_bits_g_perm_0_af);
    if (g_TLBFA_io_r_resp_0_bits_g_perm_0_a !== x_TLBFA_io_r_resp_0_bits_g_perm_0_a) $display("    TLBFA.io_r_resp_0_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_io_r_resp_0_bits_g_perm_0_a);
    if (g_TLBFA_io_r_resp_0_bits_g_perm_0_x !== x_TLBFA_io_r_resp_0_bits_g_perm_0_x) $display("    TLBFA.io_r_resp_0_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_io_r_resp_0_bits_g_perm_0_x);
    if (g_TLBFA_io_r_resp_0_bits_s2xlate_0 !== x_TLBFA_io_r_resp_0_bits_s2xlate_0) $display("    TLBFA.io_r_resp_0_bits_s2xlate_0: g=%h x=%h", g_TLBFA_io_r_resp_0_bits_s2xlate_0, x_TLBFA_io_r_resp_0_bits_s2xlate_0);
    if (g_TLBFA_io_r_resp_1_bits_hit !== x_TLBFA_io_r_resp_1_bits_hit) $display("    TLBFA.io_r_resp_1_bits_hit: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_hit, x_TLBFA_io_r_resp_1_bits_hit);
    if (g_TLBFA_io_r_resp_1_bits_ppn_0 !== x_TLBFA_io_r_resp_1_bits_ppn_0) $display("    TLBFA.io_r_resp_1_bits_ppn_0: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_ppn_0, x_TLBFA_io_r_resp_1_bits_ppn_0);
    if (g_TLBFA_io_r_resp_1_bits_pbmt_0 !== x_TLBFA_io_r_resp_1_bits_pbmt_0) $display("    TLBFA.io_r_resp_1_bits_pbmt_0: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_pbmt_0, x_TLBFA_io_r_resp_1_bits_pbmt_0);
    if (g_TLBFA_io_r_resp_1_bits_g_pbmt_0 !== x_TLBFA_io_r_resp_1_bits_g_pbmt_0) $display("    TLBFA.io_r_resp_1_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_io_r_resp_1_bits_g_pbmt_0);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_pf !== x_TLBFA_io_r_resp_1_bits_perm_0_pf) $display("    TLBFA.io_r_resp_1_bits_perm_0_pf: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_pf, x_TLBFA_io_r_resp_1_bits_perm_0_pf);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_af !== x_TLBFA_io_r_resp_1_bits_perm_0_af) $display("    TLBFA.io_r_resp_1_bits_perm_0_af: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_af, x_TLBFA_io_r_resp_1_bits_perm_0_af);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_v !== x_TLBFA_io_r_resp_1_bits_perm_0_v) $display("    TLBFA.io_r_resp_1_bits_perm_0_v: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_v, x_TLBFA_io_r_resp_1_bits_perm_0_v);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_a !== x_TLBFA_io_r_resp_1_bits_perm_0_a) $display("    TLBFA.io_r_resp_1_bits_perm_0_a: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_a, x_TLBFA_io_r_resp_1_bits_perm_0_a);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_u !== x_TLBFA_io_r_resp_1_bits_perm_0_u) $display("    TLBFA.io_r_resp_1_bits_perm_0_u: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_u, x_TLBFA_io_r_resp_1_bits_perm_0_u);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_x !== x_TLBFA_io_r_resp_1_bits_perm_0_x) $display("    TLBFA.io_r_resp_1_bits_perm_0_x: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_x, x_TLBFA_io_r_resp_1_bits_perm_0_x);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_w !== x_TLBFA_io_r_resp_1_bits_perm_0_w) $display("    TLBFA.io_r_resp_1_bits_perm_0_w: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_w, x_TLBFA_io_r_resp_1_bits_perm_0_w);
    if (g_TLBFA_io_r_resp_1_bits_perm_0_r !== x_TLBFA_io_r_resp_1_bits_perm_0_r) $display("    TLBFA.io_r_resp_1_bits_perm_0_r: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_perm_0_r, x_TLBFA_io_r_resp_1_bits_perm_0_r);
    if (g_TLBFA_io_r_resp_1_bits_g_perm_0_pf !== x_TLBFA_io_r_resp_1_bits_g_perm_0_pf) $display("    TLBFA.io_r_resp_1_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_io_r_resp_1_bits_g_perm_0_pf);
    if (g_TLBFA_io_r_resp_1_bits_g_perm_0_af !== x_TLBFA_io_r_resp_1_bits_g_perm_0_af) $display("    TLBFA.io_r_resp_1_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_io_r_resp_1_bits_g_perm_0_af);
    if (g_TLBFA_io_r_resp_1_bits_g_perm_0_a !== x_TLBFA_io_r_resp_1_bits_g_perm_0_a) $display("    TLBFA.io_r_resp_1_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_io_r_resp_1_bits_g_perm_0_a);
    if (g_TLBFA_io_r_resp_1_bits_g_perm_0_x !== x_TLBFA_io_r_resp_1_bits_g_perm_0_x) $display("    TLBFA.io_r_resp_1_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_io_r_resp_1_bits_g_perm_0_x);
    if (g_TLBFA_io_r_resp_1_bits_s2xlate_0 !== x_TLBFA_io_r_resp_1_bits_s2xlate_0) $display("    TLBFA.io_r_resp_1_bits_s2xlate_0: g=%h x=%h", g_TLBFA_io_r_resp_1_bits_s2xlate_0, x_TLBFA_io_r_resp_1_bits_s2xlate_0);
    if (g_TLBFA_io_r_resp_2_bits_hit !== x_TLBFA_io_r_resp_2_bits_hit) $display("    TLBFA.io_r_resp_2_bits_hit: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_hit, x_TLBFA_io_r_resp_2_bits_hit);
    if (g_TLBFA_io_r_resp_2_bits_ppn_0 !== x_TLBFA_io_r_resp_2_bits_ppn_0) $display("    TLBFA.io_r_resp_2_bits_ppn_0: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_ppn_0, x_TLBFA_io_r_resp_2_bits_ppn_0);
    if (g_TLBFA_io_r_resp_2_bits_pbmt_0 !== x_TLBFA_io_r_resp_2_bits_pbmt_0) $display("    TLBFA.io_r_resp_2_bits_pbmt_0: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_pbmt_0, x_TLBFA_io_r_resp_2_bits_pbmt_0);
    if (g_TLBFA_io_r_resp_2_bits_g_pbmt_0 !== x_TLBFA_io_r_resp_2_bits_g_pbmt_0) $display("    TLBFA.io_r_resp_2_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_g_pbmt_0, x_TLBFA_io_r_resp_2_bits_g_pbmt_0);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_pf !== x_TLBFA_io_r_resp_2_bits_perm_0_pf) $display("    TLBFA.io_r_resp_2_bits_perm_0_pf: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_pf, x_TLBFA_io_r_resp_2_bits_perm_0_pf);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_af !== x_TLBFA_io_r_resp_2_bits_perm_0_af) $display("    TLBFA.io_r_resp_2_bits_perm_0_af: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_af, x_TLBFA_io_r_resp_2_bits_perm_0_af);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_v !== x_TLBFA_io_r_resp_2_bits_perm_0_v) $display("    TLBFA.io_r_resp_2_bits_perm_0_v: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_v, x_TLBFA_io_r_resp_2_bits_perm_0_v);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_a !== x_TLBFA_io_r_resp_2_bits_perm_0_a) $display("    TLBFA.io_r_resp_2_bits_perm_0_a: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_a, x_TLBFA_io_r_resp_2_bits_perm_0_a);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_u !== x_TLBFA_io_r_resp_2_bits_perm_0_u) $display("    TLBFA.io_r_resp_2_bits_perm_0_u: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_u, x_TLBFA_io_r_resp_2_bits_perm_0_u);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_x !== x_TLBFA_io_r_resp_2_bits_perm_0_x) $display("    TLBFA.io_r_resp_2_bits_perm_0_x: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_x, x_TLBFA_io_r_resp_2_bits_perm_0_x);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_w !== x_TLBFA_io_r_resp_2_bits_perm_0_w) $display("    TLBFA.io_r_resp_2_bits_perm_0_w: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_w, x_TLBFA_io_r_resp_2_bits_perm_0_w);
    if (g_TLBFA_io_r_resp_2_bits_perm_0_r !== x_TLBFA_io_r_resp_2_bits_perm_0_r) $display("    TLBFA.io_r_resp_2_bits_perm_0_r: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_perm_0_r, x_TLBFA_io_r_resp_2_bits_perm_0_r);
    if (g_TLBFA_io_r_resp_2_bits_g_perm_0_pf !== x_TLBFA_io_r_resp_2_bits_g_perm_0_pf) $display("    TLBFA.io_r_resp_2_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_g_perm_0_pf, x_TLBFA_io_r_resp_2_bits_g_perm_0_pf);
    if (g_TLBFA_io_r_resp_2_bits_g_perm_0_af !== x_TLBFA_io_r_resp_2_bits_g_perm_0_af) $display("    TLBFA.io_r_resp_2_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_g_perm_0_af, x_TLBFA_io_r_resp_2_bits_g_perm_0_af);
    if (g_TLBFA_io_r_resp_2_bits_g_perm_0_a !== x_TLBFA_io_r_resp_2_bits_g_perm_0_a) $display("    TLBFA.io_r_resp_2_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_g_perm_0_a, x_TLBFA_io_r_resp_2_bits_g_perm_0_a);
    if (g_TLBFA_io_r_resp_2_bits_g_perm_0_x !== x_TLBFA_io_r_resp_2_bits_g_perm_0_x) $display("    TLBFA.io_r_resp_2_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_g_perm_0_x, x_TLBFA_io_r_resp_2_bits_g_perm_0_x);
    if (g_TLBFA_io_r_resp_2_bits_s2xlate_0 !== x_TLBFA_io_r_resp_2_bits_s2xlate_0) $display("    TLBFA.io_r_resp_2_bits_s2xlate_0: g=%h x=%h", g_TLBFA_io_r_resp_2_bits_s2xlate_0, x_TLBFA_io_r_resp_2_bits_s2xlate_0);
    if (g_TLBFA_io_access_0_touch_ways_valid !== x_TLBFA_io_access_0_touch_ways_valid) $display("    TLBFA.io_access_0_touch_ways_valid: g=%h x=%h", g_TLBFA_io_access_0_touch_ways_valid, x_TLBFA_io_access_0_touch_ways_valid);
    if (g_TLBFA_io_access_0_touch_ways_bits !== x_TLBFA_io_access_0_touch_ways_bits) $display("    TLBFA.io_access_0_touch_ways_bits: g=%h x=%h", g_TLBFA_io_access_0_touch_ways_bits, x_TLBFA_io_access_0_touch_ways_bits);
    if (g_TLBFA_io_access_1_touch_ways_valid !== x_TLBFA_io_access_1_touch_ways_valid) $display("    TLBFA.io_access_1_touch_ways_valid: g=%h x=%h", g_TLBFA_io_access_1_touch_ways_valid, x_TLBFA_io_access_1_touch_ways_valid);
    if (g_TLBFA_io_access_1_touch_ways_bits !== x_TLBFA_io_access_1_touch_ways_bits) $display("    TLBFA.io_access_1_touch_ways_bits: g=%h x=%h", g_TLBFA_io_access_1_touch_ways_bits, x_TLBFA_io_access_1_touch_ways_bits);
    if (g_TLBFA_io_access_2_touch_ways_valid !== x_TLBFA_io_access_2_touch_ways_valid) $display("    TLBFA.io_access_2_touch_ways_valid: g=%h x=%h", g_TLBFA_io_access_2_touch_ways_valid, x_TLBFA_io_access_2_touch_ways_valid);
    if (g_TLBFA_io_access_2_touch_ways_bits !== x_TLBFA_io_access_2_touch_ways_bits) $display("    TLBFA.io_access_2_touch_ways_bits: g=%h x=%h", g_TLBFA_io_access_2_touch_ways_bits, x_TLBFA_io_access_2_touch_ways_bits);
  endtask

  // ------------------------------------------------------------------
  //  TLBFA_1: PORTS=4，198 端口（112 个输出逐拍全比）
  // ------------------------------------------------------------------
  wire g_TLBFA_1_io_r_resp_0_bits_hit, x_TLBFA_1_io_r_resp_0_bits_hit;
  wire [35:0] g_TLBFA_1_io_r_resp_0_bits_ppn_0, x_TLBFA_1_io_r_resp_0_bits_ppn_0;
  wire [35:0] g_TLBFA_1_io_r_resp_0_bits_ppn_1, x_TLBFA_1_io_r_resp_0_bits_ppn_1;
  wire [1:0] g_TLBFA_1_io_r_resp_0_bits_pbmt_0, x_TLBFA_1_io_r_resp_0_bits_pbmt_0;
  wire [1:0] g_TLBFA_1_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_0_bits_g_pbmt_0;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_pf, x_TLBFA_1_io_r_resp_0_bits_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_af, x_TLBFA_1_io_r_resp_0_bits_perm_0_af;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_v, x_TLBFA_1_io_r_resp_0_bits_perm_0_v;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_d, x_TLBFA_1_io_r_resp_0_bits_perm_0_d;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_a, x_TLBFA_1_io_r_resp_0_bits_perm_0_a;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_u, x_TLBFA_1_io_r_resp_0_bits_perm_0_u;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_x, x_TLBFA_1_io_r_resp_0_bits_perm_0_x;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_w, x_TLBFA_1_io_r_resp_0_bits_perm_0_w;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_0_r, x_TLBFA_1_io_r_resp_0_bits_perm_0_r;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_1_pf, x_TLBFA_1_io_r_resp_0_bits_perm_1_pf;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_1_af, x_TLBFA_1_io_r_resp_0_bits_perm_1_af;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_1_v, x_TLBFA_1_io_r_resp_0_bits_perm_1_v;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_1_x, x_TLBFA_1_io_r_resp_0_bits_perm_1_x;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_1_w, x_TLBFA_1_io_r_resp_0_bits_perm_1_w;
  wire g_TLBFA_1_io_r_resp_0_bits_perm_1_r, x_TLBFA_1_io_r_resp_0_bits_perm_1_r;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_af;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_d;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_a;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_x;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_w;
  wire g_TLBFA_1_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_r;
  wire [1:0] g_TLBFA_1_io_r_resp_0_bits_s2xlate_0, x_TLBFA_1_io_r_resp_0_bits_s2xlate_0;
  wire g_TLBFA_1_io_r_resp_1_bits_hit, x_TLBFA_1_io_r_resp_1_bits_hit;
  wire [35:0] g_TLBFA_1_io_r_resp_1_bits_ppn_0, x_TLBFA_1_io_r_resp_1_bits_ppn_0;
  wire [35:0] g_TLBFA_1_io_r_resp_1_bits_ppn_1, x_TLBFA_1_io_r_resp_1_bits_ppn_1;
  wire [1:0] g_TLBFA_1_io_r_resp_1_bits_pbmt_0, x_TLBFA_1_io_r_resp_1_bits_pbmt_0;
  wire [1:0] g_TLBFA_1_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_1_bits_g_pbmt_0;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_pf, x_TLBFA_1_io_r_resp_1_bits_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_af, x_TLBFA_1_io_r_resp_1_bits_perm_0_af;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_v, x_TLBFA_1_io_r_resp_1_bits_perm_0_v;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_d, x_TLBFA_1_io_r_resp_1_bits_perm_0_d;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_a, x_TLBFA_1_io_r_resp_1_bits_perm_0_a;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_u, x_TLBFA_1_io_r_resp_1_bits_perm_0_u;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_x, x_TLBFA_1_io_r_resp_1_bits_perm_0_x;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_w, x_TLBFA_1_io_r_resp_1_bits_perm_0_w;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_0_r, x_TLBFA_1_io_r_resp_1_bits_perm_0_r;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_1_pf, x_TLBFA_1_io_r_resp_1_bits_perm_1_pf;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_1_af, x_TLBFA_1_io_r_resp_1_bits_perm_1_af;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_1_v, x_TLBFA_1_io_r_resp_1_bits_perm_1_v;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_1_x, x_TLBFA_1_io_r_resp_1_bits_perm_1_x;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_1_w, x_TLBFA_1_io_r_resp_1_bits_perm_1_w;
  wire g_TLBFA_1_io_r_resp_1_bits_perm_1_r, x_TLBFA_1_io_r_resp_1_bits_perm_1_r;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_af;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_d;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_a;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_x;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_w;
  wire g_TLBFA_1_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_r;
  wire [1:0] g_TLBFA_1_io_r_resp_1_bits_s2xlate_0, x_TLBFA_1_io_r_resp_1_bits_s2xlate_0;
  wire g_TLBFA_1_io_r_resp_2_bits_hit, x_TLBFA_1_io_r_resp_2_bits_hit;
  wire [35:0] g_TLBFA_1_io_r_resp_2_bits_ppn_0, x_TLBFA_1_io_r_resp_2_bits_ppn_0;
  wire [35:0] g_TLBFA_1_io_r_resp_2_bits_ppn_1, x_TLBFA_1_io_r_resp_2_bits_ppn_1;
  wire [1:0] g_TLBFA_1_io_r_resp_2_bits_pbmt_0, x_TLBFA_1_io_r_resp_2_bits_pbmt_0;
  wire [1:0] g_TLBFA_1_io_r_resp_2_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_2_bits_g_pbmt_0;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_pf, x_TLBFA_1_io_r_resp_2_bits_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_af, x_TLBFA_1_io_r_resp_2_bits_perm_0_af;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_v, x_TLBFA_1_io_r_resp_2_bits_perm_0_v;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_d, x_TLBFA_1_io_r_resp_2_bits_perm_0_d;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_a, x_TLBFA_1_io_r_resp_2_bits_perm_0_a;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_u, x_TLBFA_1_io_r_resp_2_bits_perm_0_u;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_x, x_TLBFA_1_io_r_resp_2_bits_perm_0_x;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_w, x_TLBFA_1_io_r_resp_2_bits_perm_0_w;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_0_r, x_TLBFA_1_io_r_resp_2_bits_perm_0_r;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_1_pf, x_TLBFA_1_io_r_resp_2_bits_perm_1_pf;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_1_af, x_TLBFA_1_io_r_resp_2_bits_perm_1_af;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_1_v, x_TLBFA_1_io_r_resp_2_bits_perm_1_v;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_1_x, x_TLBFA_1_io_r_resp_2_bits_perm_1_x;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_1_w, x_TLBFA_1_io_r_resp_2_bits_perm_1_w;
  wire g_TLBFA_1_io_r_resp_2_bits_perm_1_r, x_TLBFA_1_io_r_resp_2_bits_perm_1_r;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_af;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_d;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_a;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_x;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_w;
  wire g_TLBFA_1_io_r_resp_2_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_r;
  wire [1:0] g_TLBFA_1_io_r_resp_2_bits_s2xlate_0, x_TLBFA_1_io_r_resp_2_bits_s2xlate_0;
  wire g_TLBFA_1_io_r_resp_3_bits_hit, x_TLBFA_1_io_r_resp_3_bits_hit;
  wire [35:0] g_TLBFA_1_io_r_resp_3_bits_ppn_0, x_TLBFA_1_io_r_resp_3_bits_ppn_0;
  wire [1:0] g_TLBFA_1_io_r_resp_3_bits_pbmt_0, x_TLBFA_1_io_r_resp_3_bits_pbmt_0;
  wire [1:0] g_TLBFA_1_io_r_resp_3_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_3_bits_g_pbmt_0;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_pf, x_TLBFA_1_io_r_resp_3_bits_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_af, x_TLBFA_1_io_r_resp_3_bits_perm_0_af;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_v, x_TLBFA_1_io_r_resp_3_bits_perm_0_v;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_d, x_TLBFA_1_io_r_resp_3_bits_perm_0_d;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_a, x_TLBFA_1_io_r_resp_3_bits_perm_0_a;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_u, x_TLBFA_1_io_r_resp_3_bits_perm_0_u;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_x, x_TLBFA_1_io_r_resp_3_bits_perm_0_x;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_w, x_TLBFA_1_io_r_resp_3_bits_perm_0_w;
  wire g_TLBFA_1_io_r_resp_3_bits_perm_0_r, x_TLBFA_1_io_r_resp_3_bits_perm_0_r;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_af;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_d;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_a;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_x;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_w;
  wire g_TLBFA_1_io_r_resp_3_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_r;
  wire g_TLBFA_1_io_access_0_touch_ways_valid, x_TLBFA_1_io_access_0_touch_ways_valid;
  wire [5:0] g_TLBFA_1_io_access_0_touch_ways_bits, x_TLBFA_1_io_access_0_touch_ways_bits;
  wire g_TLBFA_1_io_access_1_touch_ways_valid, x_TLBFA_1_io_access_1_touch_ways_valid;
  wire [5:0] g_TLBFA_1_io_access_1_touch_ways_bits, x_TLBFA_1_io_access_1_touch_ways_bits;
  wire g_TLBFA_1_io_access_2_touch_ways_valid, x_TLBFA_1_io_access_2_touch_ways_valid;
  wire [5:0] g_TLBFA_1_io_access_2_touch_ways_bits, x_TLBFA_1_io_access_2_touch_ways_bits;
  wire g_TLBFA_1_io_access_3_touch_ways_valid, x_TLBFA_1_io_access_3_touch_ways_valid;
  wire [5:0] g_TLBFA_1_io_access_3_touch_ways_bits, x_TLBFA_1_io_access_3_touch_ways_bits;

  TLBFA_1 u_g_TLBFA_1 (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_req_2_valid(rq_valid[2]),
    .io_r_req_2_bits_vpn(rq_vpn[2]),
    .io_r_req_2_bits_s2xlate(rq_s2x[2]),
    .io_r_req_3_valid(rq_valid[3]),
    .io_r_req_3_bits_vpn(rq_vpn[3]),
    .io_r_req_3_bits_s2xlate(rq_s2x[3]),
    .io_r_resp_0_bits_hit(g_TLBFA_1_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(g_TLBFA_1_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_ppn_1(g_TLBFA_1_io_r_resp_0_bits_ppn_1),
    .io_r_resp_0_bits_pbmt_0(g_TLBFA_1_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(g_TLBFA_1_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(g_TLBFA_1_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(g_TLBFA_1_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(g_TLBFA_1_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_d(g_TLBFA_1_io_r_resp_0_bits_perm_0_d),
    .io_r_resp_0_bits_perm_0_a(g_TLBFA_1_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(g_TLBFA_1_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(g_TLBFA_1_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(g_TLBFA_1_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(g_TLBFA_1_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_perm_1_pf(g_TLBFA_1_io_r_resp_0_bits_perm_1_pf),
    .io_r_resp_0_bits_perm_1_af(g_TLBFA_1_io_r_resp_0_bits_perm_1_af),
    .io_r_resp_0_bits_perm_1_v(g_TLBFA_1_io_r_resp_0_bits_perm_1_v),
    .io_r_resp_0_bits_perm_1_x(g_TLBFA_1_io_r_resp_0_bits_perm_1_x),
    .io_r_resp_0_bits_perm_1_w(g_TLBFA_1_io_r_resp_0_bits_perm_1_w),
    .io_r_resp_0_bits_perm_1_r(g_TLBFA_1_io_r_resp_0_bits_perm_1_r),
    .io_r_resp_0_bits_g_perm_0_pf(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r(g_TLBFA_1_io_r_resp_0_bits_g_perm_0_r),
    .io_r_resp_0_bits_s2xlate_0(g_TLBFA_1_io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(g_TLBFA_1_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(g_TLBFA_1_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_ppn_1(g_TLBFA_1_io_r_resp_1_bits_ppn_1),
    .io_r_resp_1_bits_pbmt_0(g_TLBFA_1_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(g_TLBFA_1_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(g_TLBFA_1_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(g_TLBFA_1_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(g_TLBFA_1_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_d(g_TLBFA_1_io_r_resp_1_bits_perm_0_d),
    .io_r_resp_1_bits_perm_0_a(g_TLBFA_1_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(g_TLBFA_1_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(g_TLBFA_1_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(g_TLBFA_1_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(g_TLBFA_1_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_perm_1_pf(g_TLBFA_1_io_r_resp_1_bits_perm_1_pf),
    .io_r_resp_1_bits_perm_1_af(g_TLBFA_1_io_r_resp_1_bits_perm_1_af),
    .io_r_resp_1_bits_perm_1_v(g_TLBFA_1_io_r_resp_1_bits_perm_1_v),
    .io_r_resp_1_bits_perm_1_x(g_TLBFA_1_io_r_resp_1_bits_perm_1_x),
    .io_r_resp_1_bits_perm_1_w(g_TLBFA_1_io_r_resp_1_bits_perm_1_w),
    .io_r_resp_1_bits_perm_1_r(g_TLBFA_1_io_r_resp_1_bits_perm_1_r),
    .io_r_resp_1_bits_g_perm_0_pf(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r(g_TLBFA_1_io_r_resp_1_bits_g_perm_0_r),
    .io_r_resp_1_bits_s2xlate_0(g_TLBFA_1_io_r_resp_1_bits_s2xlate_0),
    .io_r_resp_2_bits_hit(g_TLBFA_1_io_r_resp_2_bits_hit),
    .io_r_resp_2_bits_ppn_0(g_TLBFA_1_io_r_resp_2_bits_ppn_0),
    .io_r_resp_2_bits_ppn_1(g_TLBFA_1_io_r_resp_2_bits_ppn_1),
    .io_r_resp_2_bits_pbmt_0(g_TLBFA_1_io_r_resp_2_bits_pbmt_0),
    .io_r_resp_2_bits_g_pbmt_0(g_TLBFA_1_io_r_resp_2_bits_g_pbmt_0),
    .io_r_resp_2_bits_perm_0_pf(g_TLBFA_1_io_r_resp_2_bits_perm_0_pf),
    .io_r_resp_2_bits_perm_0_af(g_TLBFA_1_io_r_resp_2_bits_perm_0_af),
    .io_r_resp_2_bits_perm_0_v(g_TLBFA_1_io_r_resp_2_bits_perm_0_v),
    .io_r_resp_2_bits_perm_0_d(g_TLBFA_1_io_r_resp_2_bits_perm_0_d),
    .io_r_resp_2_bits_perm_0_a(g_TLBFA_1_io_r_resp_2_bits_perm_0_a),
    .io_r_resp_2_bits_perm_0_u(g_TLBFA_1_io_r_resp_2_bits_perm_0_u),
    .io_r_resp_2_bits_perm_0_x(g_TLBFA_1_io_r_resp_2_bits_perm_0_x),
    .io_r_resp_2_bits_perm_0_w(g_TLBFA_1_io_r_resp_2_bits_perm_0_w),
    .io_r_resp_2_bits_perm_0_r(g_TLBFA_1_io_r_resp_2_bits_perm_0_r),
    .io_r_resp_2_bits_perm_1_pf(g_TLBFA_1_io_r_resp_2_bits_perm_1_pf),
    .io_r_resp_2_bits_perm_1_af(g_TLBFA_1_io_r_resp_2_bits_perm_1_af),
    .io_r_resp_2_bits_perm_1_v(g_TLBFA_1_io_r_resp_2_bits_perm_1_v),
    .io_r_resp_2_bits_perm_1_x(g_TLBFA_1_io_r_resp_2_bits_perm_1_x),
    .io_r_resp_2_bits_perm_1_w(g_TLBFA_1_io_r_resp_2_bits_perm_1_w),
    .io_r_resp_2_bits_perm_1_r(g_TLBFA_1_io_r_resp_2_bits_perm_1_r),
    .io_r_resp_2_bits_g_perm_0_pf(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf),
    .io_r_resp_2_bits_g_perm_0_af(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_af),
    .io_r_resp_2_bits_g_perm_0_d(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_d),
    .io_r_resp_2_bits_g_perm_0_a(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_a),
    .io_r_resp_2_bits_g_perm_0_x(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_x),
    .io_r_resp_2_bits_g_perm_0_w(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_w),
    .io_r_resp_2_bits_g_perm_0_r(g_TLBFA_1_io_r_resp_2_bits_g_perm_0_r),
    .io_r_resp_2_bits_s2xlate_0(g_TLBFA_1_io_r_resp_2_bits_s2xlate_0),
    .io_r_resp_3_bits_hit(g_TLBFA_1_io_r_resp_3_bits_hit),
    .io_r_resp_3_bits_ppn_0(g_TLBFA_1_io_r_resp_3_bits_ppn_0),
    .io_r_resp_3_bits_pbmt_0(g_TLBFA_1_io_r_resp_3_bits_pbmt_0),
    .io_r_resp_3_bits_g_pbmt_0(g_TLBFA_1_io_r_resp_3_bits_g_pbmt_0),
    .io_r_resp_3_bits_perm_0_pf(g_TLBFA_1_io_r_resp_3_bits_perm_0_pf),
    .io_r_resp_3_bits_perm_0_af(g_TLBFA_1_io_r_resp_3_bits_perm_0_af),
    .io_r_resp_3_bits_perm_0_v(g_TLBFA_1_io_r_resp_3_bits_perm_0_v),
    .io_r_resp_3_bits_perm_0_d(g_TLBFA_1_io_r_resp_3_bits_perm_0_d),
    .io_r_resp_3_bits_perm_0_a(g_TLBFA_1_io_r_resp_3_bits_perm_0_a),
    .io_r_resp_3_bits_perm_0_u(g_TLBFA_1_io_r_resp_3_bits_perm_0_u),
    .io_r_resp_3_bits_perm_0_x(g_TLBFA_1_io_r_resp_3_bits_perm_0_x),
    .io_r_resp_3_bits_perm_0_w(g_TLBFA_1_io_r_resp_3_bits_perm_0_w),
    .io_r_resp_3_bits_perm_0_r(g_TLBFA_1_io_r_resp_3_bits_perm_0_r),
    .io_r_resp_3_bits_g_perm_0_pf(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf),
    .io_r_resp_3_bits_g_perm_0_af(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_af),
    .io_r_resp_3_bits_g_perm_0_d(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_d),
    .io_r_resp_3_bits_g_perm_0_a(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_a),
    .io_r_resp_3_bits_g_perm_0_x(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_x),
    .io_r_resp_3_bits_g_perm_0_w(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_w),
    .io_r_resp_3_bits_g_perm_0_r(g_TLBFA_1_io_r_resp_3_bits_g_perm_0_r),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(g_TLBFA_1_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(g_TLBFA_1_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(g_TLBFA_1_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(g_TLBFA_1_io_access_1_touch_ways_bits),
    .io_access_2_touch_ways_valid(g_TLBFA_1_io_access_2_touch_ways_valid),
    .io_access_2_touch_ways_bits(g_TLBFA_1_io_access_2_touch_ways_bits),
    .io_access_3_touch_ways_valid(g_TLBFA_1_io_access_3_touch_ways_valid),
    .io_access_3_touch_ways_bits(g_TLBFA_1_io_access_3_touch_ways_bits)
  );

  TLBFA_1_xs u_x_TLBFA_1 (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_req_2_valid(rq_valid[2]),
    .io_r_req_2_bits_vpn(rq_vpn[2]),
    .io_r_req_2_bits_s2xlate(rq_s2x[2]),
    .io_r_req_3_valid(rq_valid[3]),
    .io_r_req_3_bits_vpn(rq_vpn[3]),
    .io_r_req_3_bits_s2xlate(rq_s2x[3]),
    .io_r_resp_0_bits_hit(x_TLBFA_1_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(x_TLBFA_1_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_ppn_1(x_TLBFA_1_io_r_resp_0_bits_ppn_1),
    .io_r_resp_0_bits_pbmt_0(x_TLBFA_1_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(x_TLBFA_1_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(x_TLBFA_1_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(x_TLBFA_1_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(x_TLBFA_1_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_d(x_TLBFA_1_io_r_resp_0_bits_perm_0_d),
    .io_r_resp_0_bits_perm_0_a(x_TLBFA_1_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(x_TLBFA_1_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(x_TLBFA_1_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(x_TLBFA_1_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(x_TLBFA_1_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_perm_1_pf(x_TLBFA_1_io_r_resp_0_bits_perm_1_pf),
    .io_r_resp_0_bits_perm_1_af(x_TLBFA_1_io_r_resp_0_bits_perm_1_af),
    .io_r_resp_0_bits_perm_1_v(x_TLBFA_1_io_r_resp_0_bits_perm_1_v),
    .io_r_resp_0_bits_perm_1_x(x_TLBFA_1_io_r_resp_0_bits_perm_1_x),
    .io_r_resp_0_bits_perm_1_w(x_TLBFA_1_io_r_resp_0_bits_perm_1_w),
    .io_r_resp_0_bits_perm_1_r(x_TLBFA_1_io_r_resp_0_bits_perm_1_r),
    .io_r_resp_0_bits_g_perm_0_pf(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r(x_TLBFA_1_io_r_resp_0_bits_g_perm_0_r),
    .io_r_resp_0_bits_s2xlate_0(x_TLBFA_1_io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(x_TLBFA_1_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(x_TLBFA_1_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_ppn_1(x_TLBFA_1_io_r_resp_1_bits_ppn_1),
    .io_r_resp_1_bits_pbmt_0(x_TLBFA_1_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(x_TLBFA_1_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(x_TLBFA_1_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(x_TLBFA_1_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(x_TLBFA_1_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_d(x_TLBFA_1_io_r_resp_1_bits_perm_0_d),
    .io_r_resp_1_bits_perm_0_a(x_TLBFA_1_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(x_TLBFA_1_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(x_TLBFA_1_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(x_TLBFA_1_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(x_TLBFA_1_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_perm_1_pf(x_TLBFA_1_io_r_resp_1_bits_perm_1_pf),
    .io_r_resp_1_bits_perm_1_af(x_TLBFA_1_io_r_resp_1_bits_perm_1_af),
    .io_r_resp_1_bits_perm_1_v(x_TLBFA_1_io_r_resp_1_bits_perm_1_v),
    .io_r_resp_1_bits_perm_1_x(x_TLBFA_1_io_r_resp_1_bits_perm_1_x),
    .io_r_resp_1_bits_perm_1_w(x_TLBFA_1_io_r_resp_1_bits_perm_1_w),
    .io_r_resp_1_bits_perm_1_r(x_TLBFA_1_io_r_resp_1_bits_perm_1_r),
    .io_r_resp_1_bits_g_perm_0_pf(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r(x_TLBFA_1_io_r_resp_1_bits_g_perm_0_r),
    .io_r_resp_1_bits_s2xlate_0(x_TLBFA_1_io_r_resp_1_bits_s2xlate_0),
    .io_r_resp_2_bits_hit(x_TLBFA_1_io_r_resp_2_bits_hit),
    .io_r_resp_2_bits_ppn_0(x_TLBFA_1_io_r_resp_2_bits_ppn_0),
    .io_r_resp_2_bits_ppn_1(x_TLBFA_1_io_r_resp_2_bits_ppn_1),
    .io_r_resp_2_bits_pbmt_0(x_TLBFA_1_io_r_resp_2_bits_pbmt_0),
    .io_r_resp_2_bits_g_pbmt_0(x_TLBFA_1_io_r_resp_2_bits_g_pbmt_0),
    .io_r_resp_2_bits_perm_0_pf(x_TLBFA_1_io_r_resp_2_bits_perm_0_pf),
    .io_r_resp_2_bits_perm_0_af(x_TLBFA_1_io_r_resp_2_bits_perm_0_af),
    .io_r_resp_2_bits_perm_0_v(x_TLBFA_1_io_r_resp_2_bits_perm_0_v),
    .io_r_resp_2_bits_perm_0_d(x_TLBFA_1_io_r_resp_2_bits_perm_0_d),
    .io_r_resp_2_bits_perm_0_a(x_TLBFA_1_io_r_resp_2_bits_perm_0_a),
    .io_r_resp_2_bits_perm_0_u(x_TLBFA_1_io_r_resp_2_bits_perm_0_u),
    .io_r_resp_2_bits_perm_0_x(x_TLBFA_1_io_r_resp_2_bits_perm_0_x),
    .io_r_resp_2_bits_perm_0_w(x_TLBFA_1_io_r_resp_2_bits_perm_0_w),
    .io_r_resp_2_bits_perm_0_r(x_TLBFA_1_io_r_resp_2_bits_perm_0_r),
    .io_r_resp_2_bits_perm_1_pf(x_TLBFA_1_io_r_resp_2_bits_perm_1_pf),
    .io_r_resp_2_bits_perm_1_af(x_TLBFA_1_io_r_resp_2_bits_perm_1_af),
    .io_r_resp_2_bits_perm_1_v(x_TLBFA_1_io_r_resp_2_bits_perm_1_v),
    .io_r_resp_2_bits_perm_1_x(x_TLBFA_1_io_r_resp_2_bits_perm_1_x),
    .io_r_resp_2_bits_perm_1_w(x_TLBFA_1_io_r_resp_2_bits_perm_1_w),
    .io_r_resp_2_bits_perm_1_r(x_TLBFA_1_io_r_resp_2_bits_perm_1_r),
    .io_r_resp_2_bits_g_perm_0_pf(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf),
    .io_r_resp_2_bits_g_perm_0_af(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_af),
    .io_r_resp_2_bits_g_perm_0_d(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_d),
    .io_r_resp_2_bits_g_perm_0_a(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_a),
    .io_r_resp_2_bits_g_perm_0_x(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_x),
    .io_r_resp_2_bits_g_perm_0_w(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_w),
    .io_r_resp_2_bits_g_perm_0_r(x_TLBFA_1_io_r_resp_2_bits_g_perm_0_r),
    .io_r_resp_2_bits_s2xlate_0(x_TLBFA_1_io_r_resp_2_bits_s2xlate_0),
    .io_r_resp_3_bits_hit(x_TLBFA_1_io_r_resp_3_bits_hit),
    .io_r_resp_3_bits_ppn_0(x_TLBFA_1_io_r_resp_3_bits_ppn_0),
    .io_r_resp_3_bits_pbmt_0(x_TLBFA_1_io_r_resp_3_bits_pbmt_0),
    .io_r_resp_3_bits_g_pbmt_0(x_TLBFA_1_io_r_resp_3_bits_g_pbmt_0),
    .io_r_resp_3_bits_perm_0_pf(x_TLBFA_1_io_r_resp_3_bits_perm_0_pf),
    .io_r_resp_3_bits_perm_0_af(x_TLBFA_1_io_r_resp_3_bits_perm_0_af),
    .io_r_resp_3_bits_perm_0_v(x_TLBFA_1_io_r_resp_3_bits_perm_0_v),
    .io_r_resp_3_bits_perm_0_d(x_TLBFA_1_io_r_resp_3_bits_perm_0_d),
    .io_r_resp_3_bits_perm_0_a(x_TLBFA_1_io_r_resp_3_bits_perm_0_a),
    .io_r_resp_3_bits_perm_0_u(x_TLBFA_1_io_r_resp_3_bits_perm_0_u),
    .io_r_resp_3_bits_perm_0_x(x_TLBFA_1_io_r_resp_3_bits_perm_0_x),
    .io_r_resp_3_bits_perm_0_w(x_TLBFA_1_io_r_resp_3_bits_perm_0_w),
    .io_r_resp_3_bits_perm_0_r(x_TLBFA_1_io_r_resp_3_bits_perm_0_r),
    .io_r_resp_3_bits_g_perm_0_pf(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf),
    .io_r_resp_3_bits_g_perm_0_af(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_af),
    .io_r_resp_3_bits_g_perm_0_d(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_d),
    .io_r_resp_3_bits_g_perm_0_a(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_a),
    .io_r_resp_3_bits_g_perm_0_x(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_x),
    .io_r_resp_3_bits_g_perm_0_w(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_w),
    .io_r_resp_3_bits_g_perm_0_r(x_TLBFA_1_io_r_resp_3_bits_g_perm_0_r),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(x_TLBFA_1_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(x_TLBFA_1_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(x_TLBFA_1_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(x_TLBFA_1_io_access_1_touch_ways_bits),
    .io_access_2_touch_ways_valid(x_TLBFA_1_io_access_2_touch_ways_valid),
    .io_access_2_touch_ways_bits(x_TLBFA_1_io_access_2_touch_ways_bits),
    .io_access_3_touch_ways_valid(x_TLBFA_1_io_access_3_touch_ways_valid),
    .io_access_3_touch_ways_bits(x_TLBFA_1_io_access_3_touch_ways_bits)
  );

  wire [387:0] gall_TLBFA_1 = {g_TLBFA_1_io_r_resp_0_bits_hit, g_TLBFA_1_io_r_resp_0_bits_ppn_0, g_TLBFA_1_io_r_resp_0_bits_ppn_1, g_TLBFA_1_io_r_resp_0_bits_pbmt_0, g_TLBFA_1_io_r_resp_0_bits_g_pbmt_0, g_TLBFA_1_io_r_resp_0_bits_perm_0_pf, g_TLBFA_1_io_r_resp_0_bits_perm_0_af, g_TLBFA_1_io_r_resp_0_bits_perm_0_v, g_TLBFA_1_io_r_resp_0_bits_perm_0_d, g_TLBFA_1_io_r_resp_0_bits_perm_0_a, g_TLBFA_1_io_r_resp_0_bits_perm_0_u, g_TLBFA_1_io_r_resp_0_bits_perm_0_x, g_TLBFA_1_io_r_resp_0_bits_perm_0_w, g_TLBFA_1_io_r_resp_0_bits_perm_0_r, g_TLBFA_1_io_r_resp_0_bits_perm_1_pf, g_TLBFA_1_io_r_resp_0_bits_perm_1_af, g_TLBFA_1_io_r_resp_0_bits_perm_1_v, g_TLBFA_1_io_r_resp_0_bits_perm_1_x, g_TLBFA_1_io_r_resp_0_bits_perm_1_w, g_TLBFA_1_io_r_resp_0_bits_perm_1_r, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_af, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_d, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_a, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_x, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_w, g_TLBFA_1_io_r_resp_0_bits_g_perm_0_r, g_TLBFA_1_io_r_resp_0_bits_s2xlate_0, g_TLBFA_1_io_r_resp_1_bits_hit, g_TLBFA_1_io_r_resp_1_bits_ppn_0, g_TLBFA_1_io_r_resp_1_bits_ppn_1, g_TLBFA_1_io_r_resp_1_bits_pbmt_0, g_TLBFA_1_io_r_resp_1_bits_g_pbmt_0, g_TLBFA_1_io_r_resp_1_bits_perm_0_pf, g_TLBFA_1_io_r_resp_1_bits_perm_0_af, g_TLBFA_1_io_r_resp_1_bits_perm_0_v, g_TLBFA_1_io_r_resp_1_bits_perm_0_d, g_TLBFA_1_io_r_resp_1_bits_perm_0_a, g_TLBFA_1_io_r_resp_1_bits_perm_0_u, g_TLBFA_1_io_r_resp_1_bits_perm_0_x, g_TLBFA_1_io_r_resp_1_bits_perm_0_w, g_TLBFA_1_io_r_resp_1_bits_perm_0_r, g_TLBFA_1_io_r_resp_1_bits_perm_1_pf, g_TLBFA_1_io_r_resp_1_bits_perm_1_af, g_TLBFA_1_io_r_resp_1_bits_perm_1_v, g_TLBFA_1_io_r_resp_1_bits_perm_1_x, g_TLBFA_1_io_r_resp_1_bits_perm_1_w, g_TLBFA_1_io_r_resp_1_bits_perm_1_r, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_af, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_d, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_a, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_x, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_w, g_TLBFA_1_io_r_resp_1_bits_g_perm_0_r, g_TLBFA_1_io_r_resp_1_bits_s2xlate_0, g_TLBFA_1_io_r_resp_2_bits_hit, g_TLBFA_1_io_r_resp_2_bits_ppn_0, g_TLBFA_1_io_r_resp_2_bits_ppn_1, g_TLBFA_1_io_r_resp_2_bits_pbmt_0, g_TLBFA_1_io_r_resp_2_bits_g_pbmt_0, g_TLBFA_1_io_r_resp_2_bits_perm_0_pf, g_TLBFA_1_io_r_resp_2_bits_perm_0_af, g_TLBFA_1_io_r_resp_2_bits_perm_0_v, g_TLBFA_1_io_r_resp_2_bits_perm_0_d, g_TLBFA_1_io_r_resp_2_bits_perm_0_a, g_TLBFA_1_io_r_resp_2_bits_perm_0_u, g_TLBFA_1_io_r_resp_2_bits_perm_0_x, g_TLBFA_1_io_r_resp_2_bits_perm_0_w, g_TLBFA_1_io_r_resp_2_bits_perm_0_r, g_TLBFA_1_io_r_resp_2_bits_perm_1_pf, g_TLBFA_1_io_r_resp_2_bits_perm_1_af, g_TLBFA_1_io_r_resp_2_bits_perm_1_v, g_TLBFA_1_io_r_resp_2_bits_perm_1_x, g_TLBFA_1_io_r_resp_2_bits_perm_1_w, g_TLBFA_1_io_r_resp_2_bits_perm_1_r, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_af, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_d, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_a, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_x, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_w, g_TLBFA_1_io_r_resp_2_bits_g_perm_0_r, g_TLBFA_1_io_r_resp_2_bits_s2xlate_0, g_TLBFA_1_io_r_resp_3_bits_hit, g_TLBFA_1_io_r_resp_3_bits_ppn_0, g_TLBFA_1_io_r_resp_3_bits_pbmt_0, g_TLBFA_1_io_r_resp_3_bits_g_pbmt_0, g_TLBFA_1_io_r_resp_3_bits_perm_0_pf, g_TLBFA_1_io_r_resp_3_bits_perm_0_af, g_TLBFA_1_io_r_resp_3_bits_perm_0_v, g_TLBFA_1_io_r_resp_3_bits_perm_0_d, g_TLBFA_1_io_r_resp_3_bits_perm_0_a, g_TLBFA_1_io_r_resp_3_bits_perm_0_u, g_TLBFA_1_io_r_resp_3_bits_perm_0_x, g_TLBFA_1_io_r_resp_3_bits_perm_0_w, g_TLBFA_1_io_r_resp_3_bits_perm_0_r, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_af, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_d, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_a, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_x, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_w, g_TLBFA_1_io_r_resp_3_bits_g_perm_0_r, g_TLBFA_1_io_access_0_touch_ways_valid, g_TLBFA_1_io_access_0_touch_ways_bits, g_TLBFA_1_io_access_1_touch_ways_valid, g_TLBFA_1_io_access_1_touch_ways_bits, g_TLBFA_1_io_access_2_touch_ways_valid, g_TLBFA_1_io_access_2_touch_ways_bits, g_TLBFA_1_io_access_3_touch_ways_valid, g_TLBFA_1_io_access_3_touch_ways_bits};
  wire [387:0] xall_TLBFA_1 = {x_TLBFA_1_io_r_resp_0_bits_hit, x_TLBFA_1_io_r_resp_0_bits_ppn_0, x_TLBFA_1_io_r_resp_0_bits_ppn_1, x_TLBFA_1_io_r_resp_0_bits_pbmt_0, x_TLBFA_1_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_0_bits_perm_0_pf, x_TLBFA_1_io_r_resp_0_bits_perm_0_af, x_TLBFA_1_io_r_resp_0_bits_perm_0_v, x_TLBFA_1_io_r_resp_0_bits_perm_0_d, x_TLBFA_1_io_r_resp_0_bits_perm_0_a, x_TLBFA_1_io_r_resp_0_bits_perm_0_u, x_TLBFA_1_io_r_resp_0_bits_perm_0_x, x_TLBFA_1_io_r_resp_0_bits_perm_0_w, x_TLBFA_1_io_r_resp_0_bits_perm_0_r, x_TLBFA_1_io_r_resp_0_bits_perm_1_pf, x_TLBFA_1_io_r_resp_0_bits_perm_1_af, x_TLBFA_1_io_r_resp_0_bits_perm_1_v, x_TLBFA_1_io_r_resp_0_bits_perm_1_x, x_TLBFA_1_io_r_resp_0_bits_perm_1_w, x_TLBFA_1_io_r_resp_0_bits_perm_1_r, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_0_bits_s2xlate_0, x_TLBFA_1_io_r_resp_1_bits_hit, x_TLBFA_1_io_r_resp_1_bits_ppn_0, x_TLBFA_1_io_r_resp_1_bits_ppn_1, x_TLBFA_1_io_r_resp_1_bits_pbmt_0, x_TLBFA_1_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_1_bits_perm_0_pf, x_TLBFA_1_io_r_resp_1_bits_perm_0_af, x_TLBFA_1_io_r_resp_1_bits_perm_0_v, x_TLBFA_1_io_r_resp_1_bits_perm_0_d, x_TLBFA_1_io_r_resp_1_bits_perm_0_a, x_TLBFA_1_io_r_resp_1_bits_perm_0_u, x_TLBFA_1_io_r_resp_1_bits_perm_0_x, x_TLBFA_1_io_r_resp_1_bits_perm_0_w, x_TLBFA_1_io_r_resp_1_bits_perm_0_r, x_TLBFA_1_io_r_resp_1_bits_perm_1_pf, x_TLBFA_1_io_r_resp_1_bits_perm_1_af, x_TLBFA_1_io_r_resp_1_bits_perm_1_v, x_TLBFA_1_io_r_resp_1_bits_perm_1_x, x_TLBFA_1_io_r_resp_1_bits_perm_1_w, x_TLBFA_1_io_r_resp_1_bits_perm_1_r, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_1_bits_s2xlate_0, x_TLBFA_1_io_r_resp_2_bits_hit, x_TLBFA_1_io_r_resp_2_bits_ppn_0, x_TLBFA_1_io_r_resp_2_bits_ppn_1, x_TLBFA_1_io_r_resp_2_bits_pbmt_0, x_TLBFA_1_io_r_resp_2_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_2_bits_perm_0_pf, x_TLBFA_1_io_r_resp_2_bits_perm_0_af, x_TLBFA_1_io_r_resp_2_bits_perm_0_v, x_TLBFA_1_io_r_resp_2_bits_perm_0_d, x_TLBFA_1_io_r_resp_2_bits_perm_0_a, x_TLBFA_1_io_r_resp_2_bits_perm_0_u, x_TLBFA_1_io_r_resp_2_bits_perm_0_x, x_TLBFA_1_io_r_resp_2_bits_perm_0_w, x_TLBFA_1_io_r_resp_2_bits_perm_0_r, x_TLBFA_1_io_r_resp_2_bits_perm_1_pf, x_TLBFA_1_io_r_resp_2_bits_perm_1_af, x_TLBFA_1_io_r_resp_2_bits_perm_1_v, x_TLBFA_1_io_r_resp_2_bits_perm_1_x, x_TLBFA_1_io_r_resp_2_bits_perm_1_w, x_TLBFA_1_io_r_resp_2_bits_perm_1_r, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_2_bits_s2xlate_0, x_TLBFA_1_io_r_resp_3_bits_hit, x_TLBFA_1_io_r_resp_3_bits_ppn_0, x_TLBFA_1_io_r_resp_3_bits_pbmt_0, x_TLBFA_1_io_r_resp_3_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_3_bits_perm_0_pf, x_TLBFA_1_io_r_resp_3_bits_perm_0_af, x_TLBFA_1_io_r_resp_3_bits_perm_0_v, x_TLBFA_1_io_r_resp_3_bits_perm_0_d, x_TLBFA_1_io_r_resp_3_bits_perm_0_a, x_TLBFA_1_io_r_resp_3_bits_perm_0_u, x_TLBFA_1_io_r_resp_3_bits_perm_0_x, x_TLBFA_1_io_r_resp_3_bits_perm_0_w, x_TLBFA_1_io_r_resp_3_bits_perm_0_r, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_r, x_TLBFA_1_io_access_0_touch_ways_valid, x_TLBFA_1_io_access_0_touch_ways_bits, x_TLBFA_1_io_access_1_touch_ways_valid, x_TLBFA_1_io_access_1_touch_ways_bits, x_TLBFA_1_io_access_2_touch_ways_valid, x_TLBFA_1_io_access_2_touch_ways_bits, x_TLBFA_1_io_access_3_touch_ways_valid, x_TLBFA_1_io_access_3_touch_ways_bits};

  task automatic diff_TLBFA_1();
    if (g_TLBFA_1_io_r_resp_0_bits_hit !== x_TLBFA_1_io_r_resp_0_bits_hit) $display("    TLBFA_1.io_r_resp_0_bits_hit: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_hit, x_TLBFA_1_io_r_resp_0_bits_hit);
    if (g_TLBFA_1_io_r_resp_0_bits_ppn_0 !== x_TLBFA_1_io_r_resp_0_bits_ppn_0) $display("    TLBFA_1.io_r_resp_0_bits_ppn_0: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_ppn_0, x_TLBFA_1_io_r_resp_0_bits_ppn_0);
    if (g_TLBFA_1_io_r_resp_0_bits_ppn_1 !== x_TLBFA_1_io_r_resp_0_bits_ppn_1) $display("    TLBFA_1.io_r_resp_0_bits_ppn_1: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_ppn_1, x_TLBFA_1_io_r_resp_0_bits_ppn_1);
    if (g_TLBFA_1_io_r_resp_0_bits_pbmt_0 !== x_TLBFA_1_io_r_resp_0_bits_pbmt_0) $display("    TLBFA_1.io_r_resp_0_bits_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_pbmt_0, x_TLBFA_1_io_r_resp_0_bits_pbmt_0);
    if (g_TLBFA_1_io_r_resp_0_bits_g_pbmt_0 !== x_TLBFA_1_io_r_resp_0_bits_g_pbmt_0) $display("    TLBFA_1.io_r_resp_0_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_0_bits_g_pbmt_0);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_pf !== x_TLBFA_1_io_r_resp_0_bits_perm_0_pf) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_pf, x_TLBFA_1_io_r_resp_0_bits_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_af !== x_TLBFA_1_io_r_resp_0_bits_perm_0_af) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_af, x_TLBFA_1_io_r_resp_0_bits_perm_0_af);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_v !== x_TLBFA_1_io_r_resp_0_bits_perm_0_v) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_v: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_v, x_TLBFA_1_io_r_resp_0_bits_perm_0_v);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_d !== x_TLBFA_1_io_r_resp_0_bits_perm_0_d) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_d, x_TLBFA_1_io_r_resp_0_bits_perm_0_d);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_a !== x_TLBFA_1_io_r_resp_0_bits_perm_0_a) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_a, x_TLBFA_1_io_r_resp_0_bits_perm_0_a);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_u !== x_TLBFA_1_io_r_resp_0_bits_perm_0_u) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_u: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_u, x_TLBFA_1_io_r_resp_0_bits_perm_0_u);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_x !== x_TLBFA_1_io_r_resp_0_bits_perm_0_x) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_x, x_TLBFA_1_io_r_resp_0_bits_perm_0_x);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_w !== x_TLBFA_1_io_r_resp_0_bits_perm_0_w) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_w, x_TLBFA_1_io_r_resp_0_bits_perm_0_w);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_0_r !== x_TLBFA_1_io_r_resp_0_bits_perm_0_r) $display("    TLBFA_1.io_r_resp_0_bits_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_0_r, x_TLBFA_1_io_r_resp_0_bits_perm_0_r);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_1_pf !== x_TLBFA_1_io_r_resp_0_bits_perm_1_pf) $display("    TLBFA_1.io_r_resp_0_bits_perm_1_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_1_pf, x_TLBFA_1_io_r_resp_0_bits_perm_1_pf);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_1_af !== x_TLBFA_1_io_r_resp_0_bits_perm_1_af) $display("    TLBFA_1.io_r_resp_0_bits_perm_1_af: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_1_af, x_TLBFA_1_io_r_resp_0_bits_perm_1_af);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_1_v !== x_TLBFA_1_io_r_resp_0_bits_perm_1_v) $display("    TLBFA_1.io_r_resp_0_bits_perm_1_v: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_1_v, x_TLBFA_1_io_r_resp_0_bits_perm_1_v);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_1_x !== x_TLBFA_1_io_r_resp_0_bits_perm_1_x) $display("    TLBFA_1.io_r_resp_0_bits_perm_1_x: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_1_x, x_TLBFA_1_io_r_resp_0_bits_perm_1_x);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_1_w !== x_TLBFA_1_io_r_resp_0_bits_perm_1_w) $display("    TLBFA_1.io_r_resp_0_bits_perm_1_w: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_1_w, x_TLBFA_1_io_r_resp_0_bits_perm_1_w);
    if (g_TLBFA_1_io_r_resp_0_bits_perm_1_r !== x_TLBFA_1_io_r_resp_0_bits_perm_1_r) $display("    TLBFA_1.io_r_resp_0_bits_perm_1_r: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_perm_1_r, x_TLBFA_1_io_r_resp_0_bits_perm_1_r);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_af !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_af) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_af);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_d !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_d) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_d);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_a !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_a) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_a);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_x !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_x) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_x);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_w !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_w) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_w);
    if (g_TLBFA_1_io_r_resp_0_bits_g_perm_0_r !== x_TLBFA_1_io_r_resp_0_bits_g_perm_0_r) $display("    TLBFA_1.io_r_resp_0_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_0_bits_g_perm_0_r);
    if (g_TLBFA_1_io_r_resp_0_bits_s2xlate_0 !== x_TLBFA_1_io_r_resp_0_bits_s2xlate_0) $display("    TLBFA_1.io_r_resp_0_bits_s2xlate_0: g=%h x=%h", g_TLBFA_1_io_r_resp_0_bits_s2xlate_0, x_TLBFA_1_io_r_resp_0_bits_s2xlate_0);
    if (g_TLBFA_1_io_r_resp_1_bits_hit !== x_TLBFA_1_io_r_resp_1_bits_hit) $display("    TLBFA_1.io_r_resp_1_bits_hit: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_hit, x_TLBFA_1_io_r_resp_1_bits_hit);
    if (g_TLBFA_1_io_r_resp_1_bits_ppn_0 !== x_TLBFA_1_io_r_resp_1_bits_ppn_0) $display("    TLBFA_1.io_r_resp_1_bits_ppn_0: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_ppn_0, x_TLBFA_1_io_r_resp_1_bits_ppn_0);
    if (g_TLBFA_1_io_r_resp_1_bits_ppn_1 !== x_TLBFA_1_io_r_resp_1_bits_ppn_1) $display("    TLBFA_1.io_r_resp_1_bits_ppn_1: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_ppn_1, x_TLBFA_1_io_r_resp_1_bits_ppn_1);
    if (g_TLBFA_1_io_r_resp_1_bits_pbmt_0 !== x_TLBFA_1_io_r_resp_1_bits_pbmt_0) $display("    TLBFA_1.io_r_resp_1_bits_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_pbmt_0, x_TLBFA_1_io_r_resp_1_bits_pbmt_0);
    if (g_TLBFA_1_io_r_resp_1_bits_g_pbmt_0 !== x_TLBFA_1_io_r_resp_1_bits_g_pbmt_0) $display("    TLBFA_1.io_r_resp_1_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_1_bits_g_pbmt_0);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_pf !== x_TLBFA_1_io_r_resp_1_bits_perm_0_pf) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_pf, x_TLBFA_1_io_r_resp_1_bits_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_af !== x_TLBFA_1_io_r_resp_1_bits_perm_0_af) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_af, x_TLBFA_1_io_r_resp_1_bits_perm_0_af);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_v !== x_TLBFA_1_io_r_resp_1_bits_perm_0_v) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_v: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_v, x_TLBFA_1_io_r_resp_1_bits_perm_0_v);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_d !== x_TLBFA_1_io_r_resp_1_bits_perm_0_d) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_d, x_TLBFA_1_io_r_resp_1_bits_perm_0_d);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_a !== x_TLBFA_1_io_r_resp_1_bits_perm_0_a) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_a, x_TLBFA_1_io_r_resp_1_bits_perm_0_a);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_u !== x_TLBFA_1_io_r_resp_1_bits_perm_0_u) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_u: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_u, x_TLBFA_1_io_r_resp_1_bits_perm_0_u);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_x !== x_TLBFA_1_io_r_resp_1_bits_perm_0_x) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_x, x_TLBFA_1_io_r_resp_1_bits_perm_0_x);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_w !== x_TLBFA_1_io_r_resp_1_bits_perm_0_w) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_w, x_TLBFA_1_io_r_resp_1_bits_perm_0_w);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_0_r !== x_TLBFA_1_io_r_resp_1_bits_perm_0_r) $display("    TLBFA_1.io_r_resp_1_bits_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_0_r, x_TLBFA_1_io_r_resp_1_bits_perm_0_r);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_1_pf !== x_TLBFA_1_io_r_resp_1_bits_perm_1_pf) $display("    TLBFA_1.io_r_resp_1_bits_perm_1_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_1_pf, x_TLBFA_1_io_r_resp_1_bits_perm_1_pf);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_1_af !== x_TLBFA_1_io_r_resp_1_bits_perm_1_af) $display("    TLBFA_1.io_r_resp_1_bits_perm_1_af: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_1_af, x_TLBFA_1_io_r_resp_1_bits_perm_1_af);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_1_v !== x_TLBFA_1_io_r_resp_1_bits_perm_1_v) $display("    TLBFA_1.io_r_resp_1_bits_perm_1_v: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_1_v, x_TLBFA_1_io_r_resp_1_bits_perm_1_v);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_1_x !== x_TLBFA_1_io_r_resp_1_bits_perm_1_x) $display("    TLBFA_1.io_r_resp_1_bits_perm_1_x: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_1_x, x_TLBFA_1_io_r_resp_1_bits_perm_1_x);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_1_w !== x_TLBFA_1_io_r_resp_1_bits_perm_1_w) $display("    TLBFA_1.io_r_resp_1_bits_perm_1_w: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_1_w, x_TLBFA_1_io_r_resp_1_bits_perm_1_w);
    if (g_TLBFA_1_io_r_resp_1_bits_perm_1_r !== x_TLBFA_1_io_r_resp_1_bits_perm_1_r) $display("    TLBFA_1.io_r_resp_1_bits_perm_1_r: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_perm_1_r, x_TLBFA_1_io_r_resp_1_bits_perm_1_r);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_af !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_af) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_af);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_d !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_d) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_d);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_a !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_a) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_a);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_x !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_x) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_x);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_w !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_w) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_w);
    if (g_TLBFA_1_io_r_resp_1_bits_g_perm_0_r !== x_TLBFA_1_io_r_resp_1_bits_g_perm_0_r) $display("    TLBFA_1.io_r_resp_1_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_1_bits_g_perm_0_r);
    if (g_TLBFA_1_io_r_resp_1_bits_s2xlate_0 !== x_TLBFA_1_io_r_resp_1_bits_s2xlate_0) $display("    TLBFA_1.io_r_resp_1_bits_s2xlate_0: g=%h x=%h", g_TLBFA_1_io_r_resp_1_bits_s2xlate_0, x_TLBFA_1_io_r_resp_1_bits_s2xlate_0);
    if (g_TLBFA_1_io_r_resp_2_bits_hit !== x_TLBFA_1_io_r_resp_2_bits_hit) $display("    TLBFA_1.io_r_resp_2_bits_hit: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_hit, x_TLBFA_1_io_r_resp_2_bits_hit);
    if (g_TLBFA_1_io_r_resp_2_bits_ppn_0 !== x_TLBFA_1_io_r_resp_2_bits_ppn_0) $display("    TLBFA_1.io_r_resp_2_bits_ppn_0: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_ppn_0, x_TLBFA_1_io_r_resp_2_bits_ppn_0);
    if (g_TLBFA_1_io_r_resp_2_bits_ppn_1 !== x_TLBFA_1_io_r_resp_2_bits_ppn_1) $display("    TLBFA_1.io_r_resp_2_bits_ppn_1: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_ppn_1, x_TLBFA_1_io_r_resp_2_bits_ppn_1);
    if (g_TLBFA_1_io_r_resp_2_bits_pbmt_0 !== x_TLBFA_1_io_r_resp_2_bits_pbmt_0) $display("    TLBFA_1.io_r_resp_2_bits_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_pbmt_0, x_TLBFA_1_io_r_resp_2_bits_pbmt_0);
    if (g_TLBFA_1_io_r_resp_2_bits_g_pbmt_0 !== x_TLBFA_1_io_r_resp_2_bits_g_pbmt_0) $display("    TLBFA_1.io_r_resp_2_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_2_bits_g_pbmt_0);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_pf !== x_TLBFA_1_io_r_resp_2_bits_perm_0_pf) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_pf, x_TLBFA_1_io_r_resp_2_bits_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_af !== x_TLBFA_1_io_r_resp_2_bits_perm_0_af) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_af, x_TLBFA_1_io_r_resp_2_bits_perm_0_af);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_v !== x_TLBFA_1_io_r_resp_2_bits_perm_0_v) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_v: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_v, x_TLBFA_1_io_r_resp_2_bits_perm_0_v);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_d !== x_TLBFA_1_io_r_resp_2_bits_perm_0_d) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_d, x_TLBFA_1_io_r_resp_2_bits_perm_0_d);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_a !== x_TLBFA_1_io_r_resp_2_bits_perm_0_a) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_a, x_TLBFA_1_io_r_resp_2_bits_perm_0_a);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_u !== x_TLBFA_1_io_r_resp_2_bits_perm_0_u) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_u: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_u, x_TLBFA_1_io_r_resp_2_bits_perm_0_u);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_x !== x_TLBFA_1_io_r_resp_2_bits_perm_0_x) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_x, x_TLBFA_1_io_r_resp_2_bits_perm_0_x);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_w !== x_TLBFA_1_io_r_resp_2_bits_perm_0_w) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_w, x_TLBFA_1_io_r_resp_2_bits_perm_0_w);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_0_r !== x_TLBFA_1_io_r_resp_2_bits_perm_0_r) $display("    TLBFA_1.io_r_resp_2_bits_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_0_r, x_TLBFA_1_io_r_resp_2_bits_perm_0_r);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_1_pf !== x_TLBFA_1_io_r_resp_2_bits_perm_1_pf) $display("    TLBFA_1.io_r_resp_2_bits_perm_1_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_1_pf, x_TLBFA_1_io_r_resp_2_bits_perm_1_pf);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_1_af !== x_TLBFA_1_io_r_resp_2_bits_perm_1_af) $display("    TLBFA_1.io_r_resp_2_bits_perm_1_af: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_1_af, x_TLBFA_1_io_r_resp_2_bits_perm_1_af);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_1_v !== x_TLBFA_1_io_r_resp_2_bits_perm_1_v) $display("    TLBFA_1.io_r_resp_2_bits_perm_1_v: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_1_v, x_TLBFA_1_io_r_resp_2_bits_perm_1_v);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_1_x !== x_TLBFA_1_io_r_resp_2_bits_perm_1_x) $display("    TLBFA_1.io_r_resp_2_bits_perm_1_x: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_1_x, x_TLBFA_1_io_r_resp_2_bits_perm_1_x);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_1_w !== x_TLBFA_1_io_r_resp_2_bits_perm_1_w) $display("    TLBFA_1.io_r_resp_2_bits_perm_1_w: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_1_w, x_TLBFA_1_io_r_resp_2_bits_perm_1_w);
    if (g_TLBFA_1_io_r_resp_2_bits_perm_1_r !== x_TLBFA_1_io_r_resp_2_bits_perm_1_r) $display("    TLBFA_1.io_r_resp_2_bits_perm_1_r: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_perm_1_r, x_TLBFA_1_io_r_resp_2_bits_perm_1_r);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_af !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_af) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_af);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_d !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_d) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_d);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_a !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_a) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_a);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_x !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_x) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_x);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_w !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_w) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_w);
    if (g_TLBFA_1_io_r_resp_2_bits_g_perm_0_r !== x_TLBFA_1_io_r_resp_2_bits_g_perm_0_r) $display("    TLBFA_1.io_r_resp_2_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_2_bits_g_perm_0_r);
    if (g_TLBFA_1_io_r_resp_2_bits_s2xlate_0 !== x_TLBFA_1_io_r_resp_2_bits_s2xlate_0) $display("    TLBFA_1.io_r_resp_2_bits_s2xlate_0: g=%h x=%h", g_TLBFA_1_io_r_resp_2_bits_s2xlate_0, x_TLBFA_1_io_r_resp_2_bits_s2xlate_0);
    if (g_TLBFA_1_io_r_resp_3_bits_hit !== x_TLBFA_1_io_r_resp_3_bits_hit) $display("    TLBFA_1.io_r_resp_3_bits_hit: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_hit, x_TLBFA_1_io_r_resp_3_bits_hit);
    if (g_TLBFA_1_io_r_resp_3_bits_ppn_0 !== x_TLBFA_1_io_r_resp_3_bits_ppn_0) $display("    TLBFA_1.io_r_resp_3_bits_ppn_0: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_ppn_0, x_TLBFA_1_io_r_resp_3_bits_ppn_0);
    if (g_TLBFA_1_io_r_resp_3_bits_pbmt_0 !== x_TLBFA_1_io_r_resp_3_bits_pbmt_0) $display("    TLBFA_1.io_r_resp_3_bits_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_pbmt_0, x_TLBFA_1_io_r_resp_3_bits_pbmt_0);
    if (g_TLBFA_1_io_r_resp_3_bits_g_pbmt_0 !== x_TLBFA_1_io_r_resp_3_bits_g_pbmt_0) $display("    TLBFA_1.io_r_resp_3_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_pbmt_0, x_TLBFA_1_io_r_resp_3_bits_g_pbmt_0);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_pf !== x_TLBFA_1_io_r_resp_3_bits_perm_0_pf) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_pf, x_TLBFA_1_io_r_resp_3_bits_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_af !== x_TLBFA_1_io_r_resp_3_bits_perm_0_af) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_af, x_TLBFA_1_io_r_resp_3_bits_perm_0_af);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_v !== x_TLBFA_1_io_r_resp_3_bits_perm_0_v) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_v: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_v, x_TLBFA_1_io_r_resp_3_bits_perm_0_v);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_d !== x_TLBFA_1_io_r_resp_3_bits_perm_0_d) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_d, x_TLBFA_1_io_r_resp_3_bits_perm_0_d);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_a !== x_TLBFA_1_io_r_resp_3_bits_perm_0_a) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_a, x_TLBFA_1_io_r_resp_3_bits_perm_0_a);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_u !== x_TLBFA_1_io_r_resp_3_bits_perm_0_u) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_u: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_u, x_TLBFA_1_io_r_resp_3_bits_perm_0_u);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_x !== x_TLBFA_1_io_r_resp_3_bits_perm_0_x) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_x, x_TLBFA_1_io_r_resp_3_bits_perm_0_x);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_w !== x_TLBFA_1_io_r_resp_3_bits_perm_0_w) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_w, x_TLBFA_1_io_r_resp_3_bits_perm_0_w);
    if (g_TLBFA_1_io_r_resp_3_bits_perm_0_r !== x_TLBFA_1_io_r_resp_3_bits_perm_0_r) $display("    TLBFA_1.io_r_resp_3_bits_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_perm_0_r, x_TLBFA_1_io_r_resp_3_bits_perm_0_r);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_pf);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_af !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_af) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_af, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_af);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_d !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_d) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_d, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_d);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_a !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_a) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_a, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_a);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_x !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_x) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_x, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_x);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_w !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_w) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_w, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_w);
    if (g_TLBFA_1_io_r_resp_3_bits_g_perm_0_r !== x_TLBFA_1_io_r_resp_3_bits_g_perm_0_r) $display("    TLBFA_1.io_r_resp_3_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_1_io_r_resp_3_bits_g_perm_0_r, x_TLBFA_1_io_r_resp_3_bits_g_perm_0_r);
    if (g_TLBFA_1_io_access_0_touch_ways_valid !== x_TLBFA_1_io_access_0_touch_ways_valid) $display("    TLBFA_1.io_access_0_touch_ways_valid: g=%h x=%h", g_TLBFA_1_io_access_0_touch_ways_valid, x_TLBFA_1_io_access_0_touch_ways_valid);
    if (g_TLBFA_1_io_access_0_touch_ways_bits !== x_TLBFA_1_io_access_0_touch_ways_bits) $display("    TLBFA_1.io_access_0_touch_ways_bits: g=%h x=%h", g_TLBFA_1_io_access_0_touch_ways_bits, x_TLBFA_1_io_access_0_touch_ways_bits);
    if (g_TLBFA_1_io_access_1_touch_ways_valid !== x_TLBFA_1_io_access_1_touch_ways_valid) $display("    TLBFA_1.io_access_1_touch_ways_valid: g=%h x=%h", g_TLBFA_1_io_access_1_touch_ways_valid, x_TLBFA_1_io_access_1_touch_ways_valid);
    if (g_TLBFA_1_io_access_1_touch_ways_bits !== x_TLBFA_1_io_access_1_touch_ways_bits) $display("    TLBFA_1.io_access_1_touch_ways_bits: g=%h x=%h", g_TLBFA_1_io_access_1_touch_ways_bits, x_TLBFA_1_io_access_1_touch_ways_bits);
    if (g_TLBFA_1_io_access_2_touch_ways_valid !== x_TLBFA_1_io_access_2_touch_ways_valid) $display("    TLBFA_1.io_access_2_touch_ways_valid: g=%h x=%h", g_TLBFA_1_io_access_2_touch_ways_valid, x_TLBFA_1_io_access_2_touch_ways_valid);
    if (g_TLBFA_1_io_access_2_touch_ways_bits !== x_TLBFA_1_io_access_2_touch_ways_bits) $display("    TLBFA_1.io_access_2_touch_ways_bits: g=%h x=%h", g_TLBFA_1_io_access_2_touch_ways_bits, x_TLBFA_1_io_access_2_touch_ways_bits);
    if (g_TLBFA_1_io_access_3_touch_ways_valid !== x_TLBFA_1_io_access_3_touch_ways_valid) $display("    TLBFA_1.io_access_3_touch_ways_valid: g=%h x=%h", g_TLBFA_1_io_access_3_touch_ways_valid, x_TLBFA_1_io_access_3_touch_ways_valid);
    if (g_TLBFA_1_io_access_3_touch_ways_bits !== x_TLBFA_1_io_access_3_touch_ways_bits) $display("    TLBFA_1.io_access_3_touch_ways_bits: g=%h x=%h", g_TLBFA_1_io_access_3_touch_ways_bits, x_TLBFA_1_io_access_3_touch_ways_bits);
  endtask

  // ------------------------------------------------------------------
  //  TLBFA_2: PORTS=2，126 端口（46 个输出逐拍全比）
  // ------------------------------------------------------------------
  wire g_TLBFA_2_io_r_resp_0_bits_hit, x_TLBFA_2_io_r_resp_0_bits_hit;
  wire [35:0] g_TLBFA_2_io_r_resp_0_bits_ppn_0, x_TLBFA_2_io_r_resp_0_bits_ppn_0;
  wire [1:0] g_TLBFA_2_io_r_resp_0_bits_pbmt_0, x_TLBFA_2_io_r_resp_0_bits_pbmt_0;
  wire [1:0] g_TLBFA_2_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_2_io_r_resp_0_bits_g_pbmt_0;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_pf, x_TLBFA_2_io_r_resp_0_bits_perm_0_pf;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_af, x_TLBFA_2_io_r_resp_0_bits_perm_0_af;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_v, x_TLBFA_2_io_r_resp_0_bits_perm_0_v;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_d, x_TLBFA_2_io_r_resp_0_bits_perm_0_d;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_a, x_TLBFA_2_io_r_resp_0_bits_perm_0_a;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_u, x_TLBFA_2_io_r_resp_0_bits_perm_0_u;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_x, x_TLBFA_2_io_r_resp_0_bits_perm_0_x;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_w, x_TLBFA_2_io_r_resp_0_bits_perm_0_w;
  wire g_TLBFA_2_io_r_resp_0_bits_perm_0_r, x_TLBFA_2_io_r_resp_0_bits_perm_0_r;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_af;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_d;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_a;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_x;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_w;
  wire g_TLBFA_2_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_r;
  wire [1:0] g_TLBFA_2_io_r_resp_0_bits_s2xlate_0, x_TLBFA_2_io_r_resp_0_bits_s2xlate_0;
  wire g_TLBFA_2_io_r_resp_1_bits_hit, x_TLBFA_2_io_r_resp_1_bits_hit;
  wire [35:0] g_TLBFA_2_io_r_resp_1_bits_ppn_0, x_TLBFA_2_io_r_resp_1_bits_ppn_0;
  wire [1:0] g_TLBFA_2_io_r_resp_1_bits_pbmt_0, x_TLBFA_2_io_r_resp_1_bits_pbmt_0;
  wire [1:0] g_TLBFA_2_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_2_io_r_resp_1_bits_g_pbmt_0;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_pf, x_TLBFA_2_io_r_resp_1_bits_perm_0_pf;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_af, x_TLBFA_2_io_r_resp_1_bits_perm_0_af;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_v, x_TLBFA_2_io_r_resp_1_bits_perm_0_v;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_d, x_TLBFA_2_io_r_resp_1_bits_perm_0_d;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_a, x_TLBFA_2_io_r_resp_1_bits_perm_0_a;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_u, x_TLBFA_2_io_r_resp_1_bits_perm_0_u;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_x, x_TLBFA_2_io_r_resp_1_bits_perm_0_x;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_w, x_TLBFA_2_io_r_resp_1_bits_perm_0_w;
  wire g_TLBFA_2_io_r_resp_1_bits_perm_0_r, x_TLBFA_2_io_r_resp_1_bits_perm_0_r;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_af;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_d;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_a;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_x;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_w;
  wire g_TLBFA_2_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_r;
  wire [1:0] g_TLBFA_2_io_r_resp_1_bits_s2xlate_0, x_TLBFA_2_io_r_resp_1_bits_s2xlate_0;
  wire g_TLBFA_2_io_access_0_touch_ways_valid, x_TLBFA_2_io_access_0_touch_ways_valid;
  wire [5:0] g_TLBFA_2_io_access_0_touch_ways_bits, x_TLBFA_2_io_access_0_touch_ways_bits;
  wire g_TLBFA_2_io_access_1_touch_ways_valid, x_TLBFA_2_io_access_1_touch_ways_valid;
  wire [5:0] g_TLBFA_2_io_access_1_touch_ways_bits, x_TLBFA_2_io_access_1_touch_ways_bits;

  TLBFA_2 u_g_TLBFA_2 (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_resp_0_bits_hit(g_TLBFA_2_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(g_TLBFA_2_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(g_TLBFA_2_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(g_TLBFA_2_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(g_TLBFA_2_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(g_TLBFA_2_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(g_TLBFA_2_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_d(g_TLBFA_2_io_r_resp_0_bits_perm_0_d),
    .io_r_resp_0_bits_perm_0_a(g_TLBFA_2_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(g_TLBFA_2_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(g_TLBFA_2_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(g_TLBFA_2_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(g_TLBFA_2_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r(g_TLBFA_2_io_r_resp_0_bits_g_perm_0_r),
    .io_r_resp_0_bits_s2xlate_0(g_TLBFA_2_io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(g_TLBFA_2_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(g_TLBFA_2_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(g_TLBFA_2_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(g_TLBFA_2_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(g_TLBFA_2_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(g_TLBFA_2_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(g_TLBFA_2_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_d(g_TLBFA_2_io_r_resp_1_bits_perm_0_d),
    .io_r_resp_1_bits_perm_0_a(g_TLBFA_2_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(g_TLBFA_2_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(g_TLBFA_2_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(g_TLBFA_2_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(g_TLBFA_2_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r(g_TLBFA_2_io_r_resp_1_bits_g_perm_0_r),
    .io_r_resp_1_bits_s2xlate_0(g_TLBFA_2_io_r_resp_1_bits_s2xlate_0),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(g_TLBFA_2_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(g_TLBFA_2_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(g_TLBFA_2_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(g_TLBFA_2_io_access_1_touch_ways_bits)
  );

  TLBFA_2_xs u_x_TLBFA_2 (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_resp_0_bits_hit(x_TLBFA_2_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(x_TLBFA_2_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(x_TLBFA_2_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(x_TLBFA_2_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(x_TLBFA_2_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(x_TLBFA_2_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(x_TLBFA_2_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_d(x_TLBFA_2_io_r_resp_0_bits_perm_0_d),
    .io_r_resp_0_bits_perm_0_a(x_TLBFA_2_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(x_TLBFA_2_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(x_TLBFA_2_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(x_TLBFA_2_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(x_TLBFA_2_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r(x_TLBFA_2_io_r_resp_0_bits_g_perm_0_r),
    .io_r_resp_0_bits_s2xlate_0(x_TLBFA_2_io_r_resp_0_bits_s2xlate_0),
    .io_r_resp_1_bits_hit(x_TLBFA_2_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(x_TLBFA_2_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(x_TLBFA_2_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(x_TLBFA_2_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(x_TLBFA_2_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(x_TLBFA_2_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(x_TLBFA_2_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_d(x_TLBFA_2_io_r_resp_1_bits_perm_0_d),
    .io_r_resp_1_bits_perm_0_a(x_TLBFA_2_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(x_TLBFA_2_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(x_TLBFA_2_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(x_TLBFA_2_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(x_TLBFA_2_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r(x_TLBFA_2_io_r_resp_1_bits_g_perm_0_r),
    .io_r_resp_1_bits_s2xlate_0(x_TLBFA_2_io_r_resp_1_bits_s2xlate_0),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(x_TLBFA_2_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(x_TLBFA_2_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(x_TLBFA_2_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(x_TLBFA_2_io_access_1_touch_ways_bits)
  );

  wire [131:0] gall_TLBFA_2 = {g_TLBFA_2_io_r_resp_0_bits_hit, g_TLBFA_2_io_r_resp_0_bits_ppn_0, g_TLBFA_2_io_r_resp_0_bits_pbmt_0, g_TLBFA_2_io_r_resp_0_bits_g_pbmt_0, g_TLBFA_2_io_r_resp_0_bits_perm_0_pf, g_TLBFA_2_io_r_resp_0_bits_perm_0_af, g_TLBFA_2_io_r_resp_0_bits_perm_0_v, g_TLBFA_2_io_r_resp_0_bits_perm_0_d, g_TLBFA_2_io_r_resp_0_bits_perm_0_a, g_TLBFA_2_io_r_resp_0_bits_perm_0_u, g_TLBFA_2_io_r_resp_0_bits_perm_0_x, g_TLBFA_2_io_r_resp_0_bits_perm_0_w, g_TLBFA_2_io_r_resp_0_bits_perm_0_r, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_af, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_d, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_a, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_x, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_w, g_TLBFA_2_io_r_resp_0_bits_g_perm_0_r, g_TLBFA_2_io_r_resp_0_bits_s2xlate_0, g_TLBFA_2_io_r_resp_1_bits_hit, g_TLBFA_2_io_r_resp_1_bits_ppn_0, g_TLBFA_2_io_r_resp_1_bits_pbmt_0, g_TLBFA_2_io_r_resp_1_bits_g_pbmt_0, g_TLBFA_2_io_r_resp_1_bits_perm_0_pf, g_TLBFA_2_io_r_resp_1_bits_perm_0_af, g_TLBFA_2_io_r_resp_1_bits_perm_0_v, g_TLBFA_2_io_r_resp_1_bits_perm_0_d, g_TLBFA_2_io_r_resp_1_bits_perm_0_a, g_TLBFA_2_io_r_resp_1_bits_perm_0_u, g_TLBFA_2_io_r_resp_1_bits_perm_0_x, g_TLBFA_2_io_r_resp_1_bits_perm_0_w, g_TLBFA_2_io_r_resp_1_bits_perm_0_r, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_af, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_d, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_a, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_x, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_w, g_TLBFA_2_io_r_resp_1_bits_g_perm_0_r, g_TLBFA_2_io_r_resp_1_bits_s2xlate_0, g_TLBFA_2_io_access_0_touch_ways_valid, g_TLBFA_2_io_access_0_touch_ways_bits, g_TLBFA_2_io_access_1_touch_ways_valid, g_TLBFA_2_io_access_1_touch_ways_bits};
  wire [131:0] xall_TLBFA_2 = {x_TLBFA_2_io_r_resp_0_bits_hit, x_TLBFA_2_io_r_resp_0_bits_ppn_0, x_TLBFA_2_io_r_resp_0_bits_pbmt_0, x_TLBFA_2_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_2_io_r_resp_0_bits_perm_0_pf, x_TLBFA_2_io_r_resp_0_bits_perm_0_af, x_TLBFA_2_io_r_resp_0_bits_perm_0_v, x_TLBFA_2_io_r_resp_0_bits_perm_0_d, x_TLBFA_2_io_r_resp_0_bits_perm_0_a, x_TLBFA_2_io_r_resp_0_bits_perm_0_u, x_TLBFA_2_io_r_resp_0_bits_perm_0_x, x_TLBFA_2_io_r_resp_0_bits_perm_0_w, x_TLBFA_2_io_r_resp_0_bits_perm_0_r, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_2_io_r_resp_0_bits_s2xlate_0, x_TLBFA_2_io_r_resp_1_bits_hit, x_TLBFA_2_io_r_resp_1_bits_ppn_0, x_TLBFA_2_io_r_resp_1_bits_pbmt_0, x_TLBFA_2_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_2_io_r_resp_1_bits_perm_0_pf, x_TLBFA_2_io_r_resp_1_bits_perm_0_af, x_TLBFA_2_io_r_resp_1_bits_perm_0_v, x_TLBFA_2_io_r_resp_1_bits_perm_0_d, x_TLBFA_2_io_r_resp_1_bits_perm_0_a, x_TLBFA_2_io_r_resp_1_bits_perm_0_u, x_TLBFA_2_io_r_resp_1_bits_perm_0_x, x_TLBFA_2_io_r_resp_1_bits_perm_0_w, x_TLBFA_2_io_r_resp_1_bits_perm_0_r, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_2_io_r_resp_1_bits_s2xlate_0, x_TLBFA_2_io_access_0_touch_ways_valid, x_TLBFA_2_io_access_0_touch_ways_bits, x_TLBFA_2_io_access_1_touch_ways_valid, x_TLBFA_2_io_access_1_touch_ways_bits};

  task automatic diff_TLBFA_2();
    if (g_TLBFA_2_io_r_resp_0_bits_hit !== x_TLBFA_2_io_r_resp_0_bits_hit) $display("    TLBFA_2.io_r_resp_0_bits_hit: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_hit, x_TLBFA_2_io_r_resp_0_bits_hit);
    if (g_TLBFA_2_io_r_resp_0_bits_ppn_0 !== x_TLBFA_2_io_r_resp_0_bits_ppn_0) $display("    TLBFA_2.io_r_resp_0_bits_ppn_0: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_ppn_0, x_TLBFA_2_io_r_resp_0_bits_ppn_0);
    if (g_TLBFA_2_io_r_resp_0_bits_pbmt_0 !== x_TLBFA_2_io_r_resp_0_bits_pbmt_0) $display("    TLBFA_2.io_r_resp_0_bits_pbmt_0: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_pbmt_0, x_TLBFA_2_io_r_resp_0_bits_pbmt_0);
    if (g_TLBFA_2_io_r_resp_0_bits_g_pbmt_0 !== x_TLBFA_2_io_r_resp_0_bits_g_pbmt_0) $display("    TLBFA_2.io_r_resp_0_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_2_io_r_resp_0_bits_g_pbmt_0);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_pf !== x_TLBFA_2_io_r_resp_0_bits_perm_0_pf) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_pf: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_pf, x_TLBFA_2_io_r_resp_0_bits_perm_0_pf);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_af !== x_TLBFA_2_io_r_resp_0_bits_perm_0_af) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_af: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_af, x_TLBFA_2_io_r_resp_0_bits_perm_0_af);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_v !== x_TLBFA_2_io_r_resp_0_bits_perm_0_v) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_v: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_v, x_TLBFA_2_io_r_resp_0_bits_perm_0_v);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_d !== x_TLBFA_2_io_r_resp_0_bits_perm_0_d) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_d: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_d, x_TLBFA_2_io_r_resp_0_bits_perm_0_d);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_a !== x_TLBFA_2_io_r_resp_0_bits_perm_0_a) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_a: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_a, x_TLBFA_2_io_r_resp_0_bits_perm_0_a);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_u !== x_TLBFA_2_io_r_resp_0_bits_perm_0_u) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_u: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_u, x_TLBFA_2_io_r_resp_0_bits_perm_0_u);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_x !== x_TLBFA_2_io_r_resp_0_bits_perm_0_x) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_x: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_x, x_TLBFA_2_io_r_resp_0_bits_perm_0_x);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_w !== x_TLBFA_2_io_r_resp_0_bits_perm_0_w) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_w: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_w, x_TLBFA_2_io_r_resp_0_bits_perm_0_w);
    if (g_TLBFA_2_io_r_resp_0_bits_perm_0_r !== x_TLBFA_2_io_r_resp_0_bits_perm_0_r) $display("    TLBFA_2.io_r_resp_0_bits_perm_0_r: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_perm_0_r, x_TLBFA_2_io_r_resp_0_bits_perm_0_r);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_pf);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_af !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_af) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_af);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_d !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_d) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_d);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_a !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_a) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_a);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_x !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_x) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_x);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_w !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_w) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_w);
    if (g_TLBFA_2_io_r_resp_0_bits_g_perm_0_r !== x_TLBFA_2_io_r_resp_0_bits_g_perm_0_r) $display("    TLBFA_2.io_r_resp_0_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_2_io_r_resp_0_bits_g_perm_0_r);
    if (g_TLBFA_2_io_r_resp_0_bits_s2xlate_0 !== x_TLBFA_2_io_r_resp_0_bits_s2xlate_0) $display("    TLBFA_2.io_r_resp_0_bits_s2xlate_0: g=%h x=%h", g_TLBFA_2_io_r_resp_0_bits_s2xlate_0, x_TLBFA_2_io_r_resp_0_bits_s2xlate_0);
    if (g_TLBFA_2_io_r_resp_1_bits_hit !== x_TLBFA_2_io_r_resp_1_bits_hit) $display("    TLBFA_2.io_r_resp_1_bits_hit: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_hit, x_TLBFA_2_io_r_resp_1_bits_hit);
    if (g_TLBFA_2_io_r_resp_1_bits_ppn_0 !== x_TLBFA_2_io_r_resp_1_bits_ppn_0) $display("    TLBFA_2.io_r_resp_1_bits_ppn_0: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_ppn_0, x_TLBFA_2_io_r_resp_1_bits_ppn_0);
    if (g_TLBFA_2_io_r_resp_1_bits_pbmt_0 !== x_TLBFA_2_io_r_resp_1_bits_pbmt_0) $display("    TLBFA_2.io_r_resp_1_bits_pbmt_0: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_pbmt_0, x_TLBFA_2_io_r_resp_1_bits_pbmt_0);
    if (g_TLBFA_2_io_r_resp_1_bits_g_pbmt_0 !== x_TLBFA_2_io_r_resp_1_bits_g_pbmt_0) $display("    TLBFA_2.io_r_resp_1_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_2_io_r_resp_1_bits_g_pbmt_0);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_pf !== x_TLBFA_2_io_r_resp_1_bits_perm_0_pf) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_pf: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_pf, x_TLBFA_2_io_r_resp_1_bits_perm_0_pf);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_af !== x_TLBFA_2_io_r_resp_1_bits_perm_0_af) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_af: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_af, x_TLBFA_2_io_r_resp_1_bits_perm_0_af);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_v !== x_TLBFA_2_io_r_resp_1_bits_perm_0_v) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_v: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_v, x_TLBFA_2_io_r_resp_1_bits_perm_0_v);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_d !== x_TLBFA_2_io_r_resp_1_bits_perm_0_d) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_d: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_d, x_TLBFA_2_io_r_resp_1_bits_perm_0_d);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_a !== x_TLBFA_2_io_r_resp_1_bits_perm_0_a) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_a: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_a, x_TLBFA_2_io_r_resp_1_bits_perm_0_a);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_u !== x_TLBFA_2_io_r_resp_1_bits_perm_0_u) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_u: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_u, x_TLBFA_2_io_r_resp_1_bits_perm_0_u);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_x !== x_TLBFA_2_io_r_resp_1_bits_perm_0_x) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_x: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_x, x_TLBFA_2_io_r_resp_1_bits_perm_0_x);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_w !== x_TLBFA_2_io_r_resp_1_bits_perm_0_w) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_w: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_w, x_TLBFA_2_io_r_resp_1_bits_perm_0_w);
    if (g_TLBFA_2_io_r_resp_1_bits_perm_0_r !== x_TLBFA_2_io_r_resp_1_bits_perm_0_r) $display("    TLBFA_2.io_r_resp_1_bits_perm_0_r: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_perm_0_r, x_TLBFA_2_io_r_resp_1_bits_perm_0_r);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_pf);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_af !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_af) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_af);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_d !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_d) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_d);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_a !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_a) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_a);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_x !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_x) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_x);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_w !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_w) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_w);
    if (g_TLBFA_2_io_r_resp_1_bits_g_perm_0_r !== x_TLBFA_2_io_r_resp_1_bits_g_perm_0_r) $display("    TLBFA_2.io_r_resp_1_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_2_io_r_resp_1_bits_g_perm_0_r);
    if (g_TLBFA_2_io_r_resp_1_bits_s2xlate_0 !== x_TLBFA_2_io_r_resp_1_bits_s2xlate_0) $display("    TLBFA_2.io_r_resp_1_bits_s2xlate_0: g=%h x=%h", g_TLBFA_2_io_r_resp_1_bits_s2xlate_0, x_TLBFA_2_io_r_resp_1_bits_s2xlate_0);
    if (g_TLBFA_2_io_access_0_touch_ways_valid !== x_TLBFA_2_io_access_0_touch_ways_valid) $display("    TLBFA_2.io_access_0_touch_ways_valid: g=%h x=%h", g_TLBFA_2_io_access_0_touch_ways_valid, x_TLBFA_2_io_access_0_touch_ways_valid);
    if (g_TLBFA_2_io_access_0_touch_ways_bits !== x_TLBFA_2_io_access_0_touch_ways_bits) $display("    TLBFA_2.io_access_0_touch_ways_bits: g=%h x=%h", g_TLBFA_2_io_access_0_touch_ways_bits, x_TLBFA_2_io_access_0_touch_ways_bits);
    if (g_TLBFA_2_io_access_1_touch_ways_valid !== x_TLBFA_2_io_access_1_touch_ways_valid) $display("    TLBFA_2.io_access_1_touch_ways_valid: g=%h x=%h", g_TLBFA_2_io_access_1_touch_ways_valid, x_TLBFA_2_io_access_1_touch_ways_valid);
    if (g_TLBFA_2_io_access_1_touch_ways_bits !== x_TLBFA_2_io_access_1_touch_ways_bits) $display("    TLBFA_2.io_access_1_touch_ways_bits: g=%h x=%h", g_TLBFA_2_io_access_1_touch_ways_bits, x_TLBFA_2_io_access_1_touch_ways_bits);
  endtask

  // ------------------------------------------------------------------
  //  TLBFA_3: PORTS=2，124 端口（44 个输出逐拍全比）
  // ------------------------------------------------------------------
  wire g_TLBFA_3_io_r_resp_0_bits_hit, x_TLBFA_3_io_r_resp_0_bits_hit;
  wire [35:0] g_TLBFA_3_io_r_resp_0_bits_ppn_0, x_TLBFA_3_io_r_resp_0_bits_ppn_0;
  wire [1:0] g_TLBFA_3_io_r_resp_0_bits_pbmt_0, x_TLBFA_3_io_r_resp_0_bits_pbmt_0;
  wire [1:0] g_TLBFA_3_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_3_io_r_resp_0_bits_g_pbmt_0;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_pf, x_TLBFA_3_io_r_resp_0_bits_perm_0_pf;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_af, x_TLBFA_3_io_r_resp_0_bits_perm_0_af;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_v, x_TLBFA_3_io_r_resp_0_bits_perm_0_v;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_d, x_TLBFA_3_io_r_resp_0_bits_perm_0_d;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_a, x_TLBFA_3_io_r_resp_0_bits_perm_0_a;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_u, x_TLBFA_3_io_r_resp_0_bits_perm_0_u;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_x, x_TLBFA_3_io_r_resp_0_bits_perm_0_x;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_w, x_TLBFA_3_io_r_resp_0_bits_perm_0_w;
  wire g_TLBFA_3_io_r_resp_0_bits_perm_0_r, x_TLBFA_3_io_r_resp_0_bits_perm_0_r;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_af;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_d;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_a;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_x;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_w;
  wire g_TLBFA_3_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_r;
  wire g_TLBFA_3_io_r_resp_1_bits_hit, x_TLBFA_3_io_r_resp_1_bits_hit;
  wire [35:0] g_TLBFA_3_io_r_resp_1_bits_ppn_0, x_TLBFA_3_io_r_resp_1_bits_ppn_0;
  wire [1:0] g_TLBFA_3_io_r_resp_1_bits_pbmt_0, x_TLBFA_3_io_r_resp_1_bits_pbmt_0;
  wire [1:0] g_TLBFA_3_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_3_io_r_resp_1_bits_g_pbmt_0;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_pf, x_TLBFA_3_io_r_resp_1_bits_perm_0_pf;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_af, x_TLBFA_3_io_r_resp_1_bits_perm_0_af;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_v, x_TLBFA_3_io_r_resp_1_bits_perm_0_v;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_d, x_TLBFA_3_io_r_resp_1_bits_perm_0_d;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_a, x_TLBFA_3_io_r_resp_1_bits_perm_0_a;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_u, x_TLBFA_3_io_r_resp_1_bits_perm_0_u;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_x, x_TLBFA_3_io_r_resp_1_bits_perm_0_x;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_w, x_TLBFA_3_io_r_resp_1_bits_perm_0_w;
  wire g_TLBFA_3_io_r_resp_1_bits_perm_0_r, x_TLBFA_3_io_r_resp_1_bits_perm_0_r;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_af;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_d;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_a;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_x;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_w;
  wire g_TLBFA_3_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_r;
  wire g_TLBFA_3_io_access_0_touch_ways_valid, x_TLBFA_3_io_access_0_touch_ways_valid;
  wire [5:0] g_TLBFA_3_io_access_0_touch_ways_bits, x_TLBFA_3_io_access_0_touch_ways_bits;
  wire g_TLBFA_3_io_access_1_touch_ways_valid, x_TLBFA_3_io_access_1_touch_ways_valid;
  wire [5:0] g_TLBFA_3_io_access_1_touch_ways_bits, x_TLBFA_3_io_access_1_touch_ways_bits;

  TLBFA_3 u_g_TLBFA_3 (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_resp_0_bits_hit(g_TLBFA_3_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(g_TLBFA_3_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(g_TLBFA_3_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(g_TLBFA_3_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(g_TLBFA_3_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(g_TLBFA_3_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(g_TLBFA_3_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_d(g_TLBFA_3_io_r_resp_0_bits_perm_0_d),
    .io_r_resp_0_bits_perm_0_a(g_TLBFA_3_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(g_TLBFA_3_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(g_TLBFA_3_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(g_TLBFA_3_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(g_TLBFA_3_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r(g_TLBFA_3_io_r_resp_0_bits_g_perm_0_r),
    .io_r_resp_1_bits_hit(g_TLBFA_3_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(g_TLBFA_3_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(g_TLBFA_3_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(g_TLBFA_3_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(g_TLBFA_3_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(g_TLBFA_3_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(g_TLBFA_3_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_d(g_TLBFA_3_io_r_resp_1_bits_perm_0_d),
    .io_r_resp_1_bits_perm_0_a(g_TLBFA_3_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(g_TLBFA_3_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(g_TLBFA_3_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(g_TLBFA_3_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(g_TLBFA_3_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r(g_TLBFA_3_io_r_resp_1_bits_g_perm_0_r),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(g_TLBFA_3_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(g_TLBFA_3_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(g_TLBFA_3_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(g_TLBFA_3_io_access_1_touch_ways_bits)
  );

  TLBFA_3_xs u_x_TLBFA_3 (
    .clock(clk),
    .reset(rst),
    .io_sfence_valid(sf_valid),
    .io_sfence_bits_rs1(sf_rs1),
    .io_sfence_bits_rs2(sf_rs2),
    .io_sfence_bits_addr(sf_addr),
    .io_sfence_bits_id(sf_id),
    .io_sfence_bits_hv(sf_hv),
    .io_sfence_bits_hg(sf_hg),
    .io_csr_satp_asid(csr_satp_asid),
    .io_csr_vsatp_asid(csr_vsatp_asid),
    .io_csr_hgatp_vmid(csr_hgatp_vmid),
    .io_csr_mbmc_BME(csr_bme),
    .io_csr_mbmc_CMODE(csr_cmode),
    .io_csr_priv_virt(csr_virt),
    .io_r_req_0_valid(rq_valid[0]),
    .io_r_req_0_bits_vpn(rq_vpn[0]),
    .io_r_req_0_bits_s2xlate(rq_s2x[0]),
    .io_r_req_1_valid(rq_valid[1]),
    .io_r_req_1_bits_vpn(rq_vpn[1]),
    .io_r_req_1_bits_s2xlate(rq_s2x[1]),
    .io_r_resp_0_bits_hit(x_TLBFA_3_io_r_resp_0_bits_hit),
    .io_r_resp_0_bits_ppn_0(x_TLBFA_3_io_r_resp_0_bits_ppn_0),
    .io_r_resp_0_bits_pbmt_0(x_TLBFA_3_io_r_resp_0_bits_pbmt_0),
    .io_r_resp_0_bits_g_pbmt_0(x_TLBFA_3_io_r_resp_0_bits_g_pbmt_0),
    .io_r_resp_0_bits_perm_0_pf(x_TLBFA_3_io_r_resp_0_bits_perm_0_pf),
    .io_r_resp_0_bits_perm_0_af(x_TLBFA_3_io_r_resp_0_bits_perm_0_af),
    .io_r_resp_0_bits_perm_0_v(x_TLBFA_3_io_r_resp_0_bits_perm_0_v),
    .io_r_resp_0_bits_perm_0_d(x_TLBFA_3_io_r_resp_0_bits_perm_0_d),
    .io_r_resp_0_bits_perm_0_a(x_TLBFA_3_io_r_resp_0_bits_perm_0_a),
    .io_r_resp_0_bits_perm_0_u(x_TLBFA_3_io_r_resp_0_bits_perm_0_u),
    .io_r_resp_0_bits_perm_0_x(x_TLBFA_3_io_r_resp_0_bits_perm_0_x),
    .io_r_resp_0_bits_perm_0_w(x_TLBFA_3_io_r_resp_0_bits_perm_0_w),
    .io_r_resp_0_bits_perm_0_r(x_TLBFA_3_io_r_resp_0_bits_perm_0_r),
    .io_r_resp_0_bits_g_perm_0_pf(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf),
    .io_r_resp_0_bits_g_perm_0_af(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_af),
    .io_r_resp_0_bits_g_perm_0_d(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_d),
    .io_r_resp_0_bits_g_perm_0_a(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_a),
    .io_r_resp_0_bits_g_perm_0_x(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_x),
    .io_r_resp_0_bits_g_perm_0_w(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_w),
    .io_r_resp_0_bits_g_perm_0_r(x_TLBFA_3_io_r_resp_0_bits_g_perm_0_r),
    .io_r_resp_1_bits_hit(x_TLBFA_3_io_r_resp_1_bits_hit),
    .io_r_resp_1_bits_ppn_0(x_TLBFA_3_io_r_resp_1_bits_ppn_0),
    .io_r_resp_1_bits_pbmt_0(x_TLBFA_3_io_r_resp_1_bits_pbmt_0),
    .io_r_resp_1_bits_g_pbmt_0(x_TLBFA_3_io_r_resp_1_bits_g_pbmt_0),
    .io_r_resp_1_bits_perm_0_pf(x_TLBFA_3_io_r_resp_1_bits_perm_0_pf),
    .io_r_resp_1_bits_perm_0_af(x_TLBFA_3_io_r_resp_1_bits_perm_0_af),
    .io_r_resp_1_bits_perm_0_v(x_TLBFA_3_io_r_resp_1_bits_perm_0_v),
    .io_r_resp_1_bits_perm_0_d(x_TLBFA_3_io_r_resp_1_bits_perm_0_d),
    .io_r_resp_1_bits_perm_0_a(x_TLBFA_3_io_r_resp_1_bits_perm_0_a),
    .io_r_resp_1_bits_perm_0_u(x_TLBFA_3_io_r_resp_1_bits_perm_0_u),
    .io_r_resp_1_bits_perm_0_x(x_TLBFA_3_io_r_resp_1_bits_perm_0_x),
    .io_r_resp_1_bits_perm_0_w(x_TLBFA_3_io_r_resp_1_bits_perm_0_w),
    .io_r_resp_1_bits_perm_0_r(x_TLBFA_3_io_r_resp_1_bits_perm_0_r),
    .io_r_resp_1_bits_g_perm_0_pf(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf),
    .io_r_resp_1_bits_g_perm_0_af(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_af),
    .io_r_resp_1_bits_g_perm_0_d(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_d),
    .io_r_resp_1_bits_g_perm_0_a(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_a),
    .io_r_resp_1_bits_g_perm_0_x(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_x),
    .io_r_resp_1_bits_g_perm_0_w(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_w),
    .io_r_resp_1_bits_g_perm_0_r(x_TLBFA_3_io_r_resp_1_bits_g_perm_0_r),
    .io_w_valid(w_valid),
    .io_w_bits_wayIdx(w_way),
    .io_w_bits_data_s2xlate(w_s2xlate),
    .io_w_bits_data_s1_entry_tag(w_s1_entry_tag),
    .io_w_bits_data_s1_entry_asid(w_s1_entry_asid),
    .io_w_bits_data_s1_entry_vmid(w_s1_entry_vmid),
    .io_w_bits_data_s1_entry_n(w_s1_entry_n),
    .io_w_bits_data_s1_entry_pbmt(w_s1_entry_pbmt),
    .io_w_bits_data_s1_entry_perm_d(w_s1_entry_perm_d),
    .io_w_bits_data_s1_entry_perm_a(w_s1_entry_perm_a),
    .io_w_bits_data_s1_entry_perm_g(w_s1_entry_perm_g),
    .io_w_bits_data_s1_entry_perm_u(w_s1_entry_perm_u),
    .io_w_bits_data_s1_entry_perm_x(w_s1_entry_perm_x),
    .io_w_bits_data_s1_entry_perm_w(w_s1_entry_perm_w),
    .io_w_bits_data_s1_entry_perm_r(w_s1_entry_perm_r),
    .io_w_bits_data_s1_entry_level(w_s1_entry_level),
    .io_w_bits_data_s1_entry_v(w_s1_entry_v),
    .io_w_bits_data_s1_entry_ppn(w_s1_entry_ppn),
    .io_w_bits_data_s1_ppn_low_0(w_s1_ppn_low[0]),
    .io_w_bits_data_s1_ppn_low_1(w_s1_ppn_low[1]),
    .io_w_bits_data_s1_ppn_low_2(w_s1_ppn_low[2]),
    .io_w_bits_data_s1_ppn_low_3(w_s1_ppn_low[3]),
    .io_w_bits_data_s1_ppn_low_4(w_s1_ppn_low[4]),
    .io_w_bits_data_s1_ppn_low_5(w_s1_ppn_low[5]),
    .io_w_bits_data_s1_ppn_low_6(w_s1_ppn_low[6]),
    .io_w_bits_data_s1_ppn_low_7(w_s1_ppn_low[7]),
    .io_w_bits_data_s1_valididx_0(w_s1_valididx[0]),
    .io_w_bits_data_s1_valididx_1(w_s1_valididx[1]),
    .io_w_bits_data_s1_valididx_2(w_s1_valididx[2]),
    .io_w_bits_data_s1_valididx_3(w_s1_valididx[3]),
    .io_w_bits_data_s1_valididx_4(w_s1_valididx[4]),
    .io_w_bits_data_s1_valididx_5(w_s1_valididx[5]),
    .io_w_bits_data_s1_valididx_6(w_s1_valididx[6]),
    .io_w_bits_data_s1_valididx_7(w_s1_valididx[7]),
    .io_w_bits_data_s1_pteidx_0(w_s1_pteidx[0]),
    .io_w_bits_data_s1_pteidx_1(w_s1_pteidx[1]),
    .io_w_bits_data_s1_pteidx_2(w_s1_pteidx[2]),
    .io_w_bits_data_s1_pteidx_3(w_s1_pteidx[3]),
    .io_w_bits_data_s1_pteidx_4(w_s1_pteidx[4]),
    .io_w_bits_data_s1_pteidx_5(w_s1_pteidx[5]),
    .io_w_bits_data_s1_pteidx_6(w_s1_pteidx[6]),
    .io_w_bits_data_s1_pteidx_7(w_s1_pteidx[7]),
    .io_w_bits_data_s1_pf(w_s1_pf),
    .io_w_bits_data_s1_af(w_s1_af),
    .io_w_bits_data_s2_entry_tag(w_s2_entry_tag),
    .io_w_bits_data_s2_entry_vmid(w_s2_entry_vmid),
    .io_w_bits_data_s2_entry_n(w_s2_entry_n),
    .io_w_bits_data_s2_entry_pbmt(w_s2_entry_pbmt),
    .io_w_bits_data_s2_entry_ppn(w_s2_entry_ppn),
    .io_w_bits_data_s2_entry_perm_d(w_s2_entry_perm_d),
    .io_w_bits_data_s2_entry_perm_a(w_s2_entry_perm_a),
    .io_w_bits_data_s2_entry_perm_g(w_s2_entry_perm_g),
    .io_w_bits_data_s2_entry_perm_u(w_s2_entry_perm_u),
    .io_w_bits_data_s2_entry_perm_x(w_s2_entry_perm_x),
    .io_w_bits_data_s2_entry_perm_w(w_s2_entry_perm_w),
    .io_w_bits_data_s2_entry_perm_r(w_s2_entry_perm_r),
    .io_w_bits_data_s2_entry_level(w_s2_entry_level),
    .io_w_bits_data_s2_gpf(w_s2_gpf),
    .io_w_bits_data_s2_gaf(w_s2_gaf),
    .io_access_0_touch_ways_valid(x_TLBFA_3_io_access_0_touch_ways_valid),
    .io_access_0_touch_ways_bits(x_TLBFA_3_io_access_0_touch_ways_bits),
    .io_access_1_touch_ways_valid(x_TLBFA_3_io_access_1_touch_ways_valid),
    .io_access_1_touch_ways_bits(x_TLBFA_3_io_access_1_touch_ways_bits)
  );

  wire [127:0] gall_TLBFA_3 = {g_TLBFA_3_io_r_resp_0_bits_hit, g_TLBFA_3_io_r_resp_0_bits_ppn_0, g_TLBFA_3_io_r_resp_0_bits_pbmt_0, g_TLBFA_3_io_r_resp_0_bits_g_pbmt_0, g_TLBFA_3_io_r_resp_0_bits_perm_0_pf, g_TLBFA_3_io_r_resp_0_bits_perm_0_af, g_TLBFA_3_io_r_resp_0_bits_perm_0_v, g_TLBFA_3_io_r_resp_0_bits_perm_0_d, g_TLBFA_3_io_r_resp_0_bits_perm_0_a, g_TLBFA_3_io_r_resp_0_bits_perm_0_u, g_TLBFA_3_io_r_resp_0_bits_perm_0_x, g_TLBFA_3_io_r_resp_0_bits_perm_0_w, g_TLBFA_3_io_r_resp_0_bits_perm_0_r, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_af, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_d, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_a, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_x, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_w, g_TLBFA_3_io_r_resp_0_bits_g_perm_0_r, g_TLBFA_3_io_r_resp_1_bits_hit, g_TLBFA_3_io_r_resp_1_bits_ppn_0, g_TLBFA_3_io_r_resp_1_bits_pbmt_0, g_TLBFA_3_io_r_resp_1_bits_g_pbmt_0, g_TLBFA_3_io_r_resp_1_bits_perm_0_pf, g_TLBFA_3_io_r_resp_1_bits_perm_0_af, g_TLBFA_3_io_r_resp_1_bits_perm_0_v, g_TLBFA_3_io_r_resp_1_bits_perm_0_d, g_TLBFA_3_io_r_resp_1_bits_perm_0_a, g_TLBFA_3_io_r_resp_1_bits_perm_0_u, g_TLBFA_3_io_r_resp_1_bits_perm_0_x, g_TLBFA_3_io_r_resp_1_bits_perm_0_w, g_TLBFA_3_io_r_resp_1_bits_perm_0_r, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_af, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_d, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_a, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_x, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_w, g_TLBFA_3_io_r_resp_1_bits_g_perm_0_r, g_TLBFA_3_io_access_0_touch_ways_valid, g_TLBFA_3_io_access_0_touch_ways_bits, g_TLBFA_3_io_access_1_touch_ways_valid, g_TLBFA_3_io_access_1_touch_ways_bits};
  wire [127:0] xall_TLBFA_3 = {x_TLBFA_3_io_r_resp_0_bits_hit, x_TLBFA_3_io_r_resp_0_bits_ppn_0, x_TLBFA_3_io_r_resp_0_bits_pbmt_0, x_TLBFA_3_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_3_io_r_resp_0_bits_perm_0_pf, x_TLBFA_3_io_r_resp_0_bits_perm_0_af, x_TLBFA_3_io_r_resp_0_bits_perm_0_v, x_TLBFA_3_io_r_resp_0_bits_perm_0_d, x_TLBFA_3_io_r_resp_0_bits_perm_0_a, x_TLBFA_3_io_r_resp_0_bits_perm_0_u, x_TLBFA_3_io_r_resp_0_bits_perm_0_x, x_TLBFA_3_io_r_resp_0_bits_perm_0_w, x_TLBFA_3_io_r_resp_0_bits_perm_0_r, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_3_io_r_resp_1_bits_hit, x_TLBFA_3_io_r_resp_1_bits_ppn_0, x_TLBFA_3_io_r_resp_1_bits_pbmt_0, x_TLBFA_3_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_3_io_r_resp_1_bits_perm_0_pf, x_TLBFA_3_io_r_resp_1_bits_perm_0_af, x_TLBFA_3_io_r_resp_1_bits_perm_0_v, x_TLBFA_3_io_r_resp_1_bits_perm_0_d, x_TLBFA_3_io_r_resp_1_bits_perm_0_a, x_TLBFA_3_io_r_resp_1_bits_perm_0_u, x_TLBFA_3_io_r_resp_1_bits_perm_0_x, x_TLBFA_3_io_r_resp_1_bits_perm_0_w, x_TLBFA_3_io_r_resp_1_bits_perm_0_r, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_3_io_access_0_touch_ways_valid, x_TLBFA_3_io_access_0_touch_ways_bits, x_TLBFA_3_io_access_1_touch_ways_valid, x_TLBFA_3_io_access_1_touch_ways_bits};

  task automatic diff_TLBFA_3();
    if (g_TLBFA_3_io_r_resp_0_bits_hit !== x_TLBFA_3_io_r_resp_0_bits_hit) $display("    TLBFA_3.io_r_resp_0_bits_hit: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_hit, x_TLBFA_3_io_r_resp_0_bits_hit);
    if (g_TLBFA_3_io_r_resp_0_bits_ppn_0 !== x_TLBFA_3_io_r_resp_0_bits_ppn_0) $display("    TLBFA_3.io_r_resp_0_bits_ppn_0: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_ppn_0, x_TLBFA_3_io_r_resp_0_bits_ppn_0);
    if (g_TLBFA_3_io_r_resp_0_bits_pbmt_0 !== x_TLBFA_3_io_r_resp_0_bits_pbmt_0) $display("    TLBFA_3.io_r_resp_0_bits_pbmt_0: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_pbmt_0, x_TLBFA_3_io_r_resp_0_bits_pbmt_0);
    if (g_TLBFA_3_io_r_resp_0_bits_g_pbmt_0 !== x_TLBFA_3_io_r_resp_0_bits_g_pbmt_0) $display("    TLBFA_3.io_r_resp_0_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_pbmt_0, x_TLBFA_3_io_r_resp_0_bits_g_pbmt_0);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_pf !== x_TLBFA_3_io_r_resp_0_bits_perm_0_pf) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_pf: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_pf, x_TLBFA_3_io_r_resp_0_bits_perm_0_pf);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_af !== x_TLBFA_3_io_r_resp_0_bits_perm_0_af) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_af: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_af, x_TLBFA_3_io_r_resp_0_bits_perm_0_af);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_v !== x_TLBFA_3_io_r_resp_0_bits_perm_0_v) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_v: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_v, x_TLBFA_3_io_r_resp_0_bits_perm_0_v);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_d !== x_TLBFA_3_io_r_resp_0_bits_perm_0_d) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_d: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_d, x_TLBFA_3_io_r_resp_0_bits_perm_0_d);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_a !== x_TLBFA_3_io_r_resp_0_bits_perm_0_a) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_a: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_a, x_TLBFA_3_io_r_resp_0_bits_perm_0_a);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_u !== x_TLBFA_3_io_r_resp_0_bits_perm_0_u) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_u: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_u, x_TLBFA_3_io_r_resp_0_bits_perm_0_u);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_x !== x_TLBFA_3_io_r_resp_0_bits_perm_0_x) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_x: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_x, x_TLBFA_3_io_r_resp_0_bits_perm_0_x);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_w !== x_TLBFA_3_io_r_resp_0_bits_perm_0_w) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_w: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_w, x_TLBFA_3_io_r_resp_0_bits_perm_0_w);
    if (g_TLBFA_3_io_r_resp_0_bits_perm_0_r !== x_TLBFA_3_io_r_resp_0_bits_perm_0_r) $display("    TLBFA_3.io_r_resp_0_bits_perm_0_r: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_perm_0_r, x_TLBFA_3_io_r_resp_0_bits_perm_0_r);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_pf);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_af !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_af) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_af, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_af);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_d !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_d) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_d, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_d);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_a !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_a) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_a, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_a);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_x !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_x) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_x, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_x);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_w !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_w) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_w, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_w);
    if (g_TLBFA_3_io_r_resp_0_bits_g_perm_0_r !== x_TLBFA_3_io_r_resp_0_bits_g_perm_0_r) $display("    TLBFA_3.io_r_resp_0_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_3_io_r_resp_0_bits_g_perm_0_r, x_TLBFA_3_io_r_resp_0_bits_g_perm_0_r);
    if (g_TLBFA_3_io_r_resp_1_bits_hit !== x_TLBFA_3_io_r_resp_1_bits_hit) $display("    TLBFA_3.io_r_resp_1_bits_hit: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_hit, x_TLBFA_3_io_r_resp_1_bits_hit);
    if (g_TLBFA_3_io_r_resp_1_bits_ppn_0 !== x_TLBFA_3_io_r_resp_1_bits_ppn_0) $display("    TLBFA_3.io_r_resp_1_bits_ppn_0: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_ppn_0, x_TLBFA_3_io_r_resp_1_bits_ppn_0);
    if (g_TLBFA_3_io_r_resp_1_bits_pbmt_0 !== x_TLBFA_3_io_r_resp_1_bits_pbmt_0) $display("    TLBFA_3.io_r_resp_1_bits_pbmt_0: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_pbmt_0, x_TLBFA_3_io_r_resp_1_bits_pbmt_0);
    if (g_TLBFA_3_io_r_resp_1_bits_g_pbmt_0 !== x_TLBFA_3_io_r_resp_1_bits_g_pbmt_0) $display("    TLBFA_3.io_r_resp_1_bits_g_pbmt_0: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_pbmt_0, x_TLBFA_3_io_r_resp_1_bits_g_pbmt_0);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_pf !== x_TLBFA_3_io_r_resp_1_bits_perm_0_pf) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_pf: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_pf, x_TLBFA_3_io_r_resp_1_bits_perm_0_pf);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_af !== x_TLBFA_3_io_r_resp_1_bits_perm_0_af) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_af: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_af, x_TLBFA_3_io_r_resp_1_bits_perm_0_af);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_v !== x_TLBFA_3_io_r_resp_1_bits_perm_0_v) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_v: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_v, x_TLBFA_3_io_r_resp_1_bits_perm_0_v);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_d !== x_TLBFA_3_io_r_resp_1_bits_perm_0_d) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_d: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_d, x_TLBFA_3_io_r_resp_1_bits_perm_0_d);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_a !== x_TLBFA_3_io_r_resp_1_bits_perm_0_a) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_a: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_a, x_TLBFA_3_io_r_resp_1_bits_perm_0_a);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_u !== x_TLBFA_3_io_r_resp_1_bits_perm_0_u) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_u: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_u, x_TLBFA_3_io_r_resp_1_bits_perm_0_u);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_x !== x_TLBFA_3_io_r_resp_1_bits_perm_0_x) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_x: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_x, x_TLBFA_3_io_r_resp_1_bits_perm_0_x);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_w !== x_TLBFA_3_io_r_resp_1_bits_perm_0_w) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_w: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_w, x_TLBFA_3_io_r_resp_1_bits_perm_0_w);
    if (g_TLBFA_3_io_r_resp_1_bits_perm_0_r !== x_TLBFA_3_io_r_resp_1_bits_perm_0_r) $display("    TLBFA_3.io_r_resp_1_bits_perm_0_r: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_perm_0_r, x_TLBFA_3_io_r_resp_1_bits_perm_0_r);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_pf: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_pf);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_af !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_af) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_af: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_af, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_af);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_d !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_d) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_d: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_d, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_d);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_a !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_a) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_a: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_a, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_a);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_x !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_x) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_x: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_x, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_x);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_w !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_w) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_w: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_w, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_w);
    if (g_TLBFA_3_io_r_resp_1_bits_g_perm_0_r !== x_TLBFA_3_io_r_resp_1_bits_g_perm_0_r) $display("    TLBFA_3.io_r_resp_1_bits_g_perm_0_r: g=%h x=%h", g_TLBFA_3_io_r_resp_1_bits_g_perm_0_r, x_TLBFA_3_io_r_resp_1_bits_g_perm_0_r);
    if (g_TLBFA_3_io_access_0_touch_ways_valid !== x_TLBFA_3_io_access_0_touch_ways_valid) $display("    TLBFA_3.io_access_0_touch_ways_valid: g=%h x=%h", g_TLBFA_3_io_access_0_touch_ways_valid, x_TLBFA_3_io_access_0_touch_ways_valid);
    if (g_TLBFA_3_io_access_0_touch_ways_bits !== x_TLBFA_3_io_access_0_touch_ways_bits) $display("    TLBFA_3.io_access_0_touch_ways_bits: g=%h x=%h", g_TLBFA_3_io_access_0_touch_ways_bits, x_TLBFA_3_io_access_0_touch_ways_bits);
    if (g_TLBFA_3_io_access_1_touch_ways_valid !== x_TLBFA_3_io_access_1_touch_ways_valid) $display("    TLBFA_3.io_access_1_touch_ways_valid: g=%h x=%h", g_TLBFA_3_io_access_1_touch_ways_valid, x_TLBFA_3_io_access_1_touch_ways_valid);
    if (g_TLBFA_3_io_access_1_touch_ways_bits !== x_TLBFA_3_io_access_1_touch_ways_bits) $display("    TLBFA_3.io_access_1_touch_ways_bits: g=%h x=%h", g_TLBFA_3_io_access_1_touch_ways_bits, x_TLBFA_3_io_access_1_touch_ways_bits);
  endtask

  // ==================================================================
  //  逐拍比对（时钟低电平中段采样，组合输出已稳定）
  // ==================================================================
  always @(negedge clk) if (!rst && warm) begin
    #4;
    checks++;
    if (gall_TLBFA !== xall_TLBFA) begin
      errors++;
      if (errors <= 20) begin
        $display("[%0t] TLBFA MISMATCH", $time);
        diff_TLBFA();
      end
    end
    if (gall_TLBFA_1 !== xall_TLBFA_1) begin
      errors++;
      if (errors <= 20) begin
        $display("[%0t] TLBFA_1 MISMATCH", $time);
        diff_TLBFA_1();
      end
    end
    if (gall_TLBFA_2 !== xall_TLBFA_2) begin
      errors++;
      if (errors <= 20) begin
        $display("[%0t] TLBFA_2 MISMATCH", $time);
        diff_TLBFA_2();
      end
    end
    if (gall_TLBFA_3 !== xall_TLBFA_3) begin
      errors++;
      if (errors <= 20) begin
        $display("[%0t] TLBFA_3 MISMATCH", $time);
        diff_TLBFA_3();
      end
    end
  end

  // ==================================================================
  //  覆盖计数（★全部取自 golden 侧★：impl 自己说自己覆盖到了不算数）
  //  golden 的 48 个 valid 位用层次引用读出来，用来证明 sfence 真的刷掉过项、
  //  以及阵列真的被填满过——否则"两边都不命中"也能凑出 errors=0。
  // ==================================================================
  wire [47:0] vbits_TLBFA = {u_g_TLBFA.v_47, u_g_TLBFA.v_46, u_g_TLBFA.v_45, u_g_TLBFA.v_44, u_g_TLBFA.v_43, u_g_TLBFA.v_42, u_g_TLBFA.v_41, u_g_TLBFA.v_40, u_g_TLBFA.v_39, u_g_TLBFA.v_38, u_g_TLBFA.v_37, u_g_TLBFA.v_36, u_g_TLBFA.v_35, u_g_TLBFA.v_34, u_g_TLBFA.v_33, u_g_TLBFA.v_32, u_g_TLBFA.v_31, u_g_TLBFA.v_30, u_g_TLBFA.v_29, u_g_TLBFA.v_28, u_g_TLBFA.v_27, u_g_TLBFA.v_26, u_g_TLBFA.v_25, u_g_TLBFA.v_24, u_g_TLBFA.v_23, u_g_TLBFA.v_22, u_g_TLBFA.v_21, u_g_TLBFA.v_20, u_g_TLBFA.v_19, u_g_TLBFA.v_18, u_g_TLBFA.v_17, u_g_TLBFA.v_16, u_g_TLBFA.v_15, u_g_TLBFA.v_14, u_g_TLBFA.v_13, u_g_TLBFA.v_12, u_g_TLBFA.v_11, u_g_TLBFA.v_10, u_g_TLBFA.v_9, u_g_TLBFA.v_8, u_g_TLBFA.v_7, u_g_TLBFA.v_6, u_g_TLBFA.v_5, u_g_TLBFA.v_4, u_g_TLBFA.v_3, u_g_TLBFA.v_2, u_g_TLBFA.v_1, u_g_TLBFA.v_0};
  wire [47:0] vbits_TLBFA_1 = {u_g_TLBFA_1.v_47, u_g_TLBFA_1.v_46, u_g_TLBFA_1.v_45, u_g_TLBFA_1.v_44, u_g_TLBFA_1.v_43, u_g_TLBFA_1.v_42, u_g_TLBFA_1.v_41, u_g_TLBFA_1.v_40, u_g_TLBFA_1.v_39, u_g_TLBFA_1.v_38, u_g_TLBFA_1.v_37, u_g_TLBFA_1.v_36, u_g_TLBFA_1.v_35, u_g_TLBFA_1.v_34, u_g_TLBFA_1.v_33, u_g_TLBFA_1.v_32, u_g_TLBFA_1.v_31, u_g_TLBFA_1.v_30, u_g_TLBFA_1.v_29, u_g_TLBFA_1.v_28, u_g_TLBFA_1.v_27, u_g_TLBFA_1.v_26, u_g_TLBFA_1.v_25, u_g_TLBFA_1.v_24, u_g_TLBFA_1.v_23, u_g_TLBFA_1.v_22, u_g_TLBFA_1.v_21, u_g_TLBFA_1.v_20, u_g_TLBFA_1.v_19, u_g_TLBFA_1.v_18, u_g_TLBFA_1.v_17, u_g_TLBFA_1.v_16, u_g_TLBFA_1.v_15, u_g_TLBFA_1.v_14, u_g_TLBFA_1.v_13, u_g_TLBFA_1.v_12, u_g_TLBFA_1.v_11, u_g_TLBFA_1.v_10, u_g_TLBFA_1.v_9, u_g_TLBFA_1.v_8, u_g_TLBFA_1.v_7, u_g_TLBFA_1.v_6, u_g_TLBFA_1.v_5, u_g_TLBFA_1.v_4, u_g_TLBFA_1.v_3, u_g_TLBFA_1.v_2, u_g_TLBFA_1.v_1, u_g_TLBFA_1.v_0};
  wire [47:0] vbits_TLBFA_2 = {u_g_TLBFA_2.v_47, u_g_TLBFA_2.v_46, u_g_TLBFA_2.v_45, u_g_TLBFA_2.v_44, u_g_TLBFA_2.v_43, u_g_TLBFA_2.v_42, u_g_TLBFA_2.v_41, u_g_TLBFA_2.v_40, u_g_TLBFA_2.v_39, u_g_TLBFA_2.v_38, u_g_TLBFA_2.v_37, u_g_TLBFA_2.v_36, u_g_TLBFA_2.v_35, u_g_TLBFA_2.v_34, u_g_TLBFA_2.v_33, u_g_TLBFA_2.v_32, u_g_TLBFA_2.v_31, u_g_TLBFA_2.v_30, u_g_TLBFA_2.v_29, u_g_TLBFA_2.v_28, u_g_TLBFA_2.v_27, u_g_TLBFA_2.v_26, u_g_TLBFA_2.v_25, u_g_TLBFA_2.v_24, u_g_TLBFA_2.v_23, u_g_TLBFA_2.v_22, u_g_TLBFA_2.v_21, u_g_TLBFA_2.v_20, u_g_TLBFA_2.v_19, u_g_TLBFA_2.v_18, u_g_TLBFA_2.v_17, u_g_TLBFA_2.v_16, u_g_TLBFA_2.v_15, u_g_TLBFA_2.v_14, u_g_TLBFA_2.v_13, u_g_TLBFA_2.v_12, u_g_TLBFA_2.v_11, u_g_TLBFA_2.v_10, u_g_TLBFA_2.v_9, u_g_TLBFA_2.v_8, u_g_TLBFA_2.v_7, u_g_TLBFA_2.v_6, u_g_TLBFA_2.v_5, u_g_TLBFA_2.v_4, u_g_TLBFA_2.v_3, u_g_TLBFA_2.v_2, u_g_TLBFA_2.v_1, u_g_TLBFA_2.v_0};
  wire [47:0] vbits_TLBFA_3 = {u_g_TLBFA_3.v_47, u_g_TLBFA_3.v_46, u_g_TLBFA_3.v_45, u_g_TLBFA_3.v_44, u_g_TLBFA_3.v_43, u_g_TLBFA_3.v_42, u_g_TLBFA_3.v_41, u_g_TLBFA_3.v_40, u_g_TLBFA_3.v_39, u_g_TLBFA_3.v_38, u_g_TLBFA_3.v_37, u_g_TLBFA_3.v_36, u_g_TLBFA_3.v_35, u_g_TLBFA_3.v_34, u_g_TLBFA_3.v_33, u_g_TLBFA_3.v_32, u_g_TLBFA_3.v_31, u_g_TLBFA_3.v_30, u_g_TLBFA_3.v_29, u_g_TLBFA_3.v_28, u_g_TLBFA_3.v_27, u_g_TLBFA_3.v_26, u_g_TLBFA_3.v_25, u_g_TLBFA_3.v_24, u_g_TLBFA_3.v_23, u_g_TLBFA_3.v_22, u_g_TLBFA_3.v_21, u_g_TLBFA_3.v_20, u_g_TLBFA_3.v_19, u_g_TLBFA_3.v_18, u_g_TLBFA_3.v_17, u_g_TLBFA_3.v_16, u_g_TLBFA_3.v_15, u_g_TLBFA_3.v_14, u_g_TLBFA_3.v_13, u_g_TLBFA_3.v_12, u_g_TLBFA_3.v_11, u_g_TLBFA_3.v_10, u_g_TLBFA_3.v_9, u_g_TLBFA_3.v_8, u_g_TLBFA_3.v_7, u_g_TLBFA_3.v_6, u_g_TLBFA_3.v_5, u_g_TLBFA_3.v_4, u_g_TLBFA_3.v_3, u_g_TLBFA_3.v_2, u_g_TLBFA_3.v_1, u_g_TLBFA_3.v_0};
  // 多命中（sector TLB 允许一个请求同时命中多条 entry；golden 用 Mux1H = 按位或，
  // 不是优先选择）。这条覆盖专门回答"本 UT 到底有没有制造出多命中"。
  wire [47:0] hitvec0_TLBFA = {u_g_TLBFA.hitVecReg_47, u_g_TLBFA.hitVecReg_46, u_g_TLBFA.hitVecReg_45, u_g_TLBFA.hitVecReg_44, u_g_TLBFA.hitVecReg_43, u_g_TLBFA.hitVecReg_42, u_g_TLBFA.hitVecReg_41, u_g_TLBFA.hitVecReg_40, u_g_TLBFA.hitVecReg_39, u_g_TLBFA.hitVecReg_38, u_g_TLBFA.hitVecReg_37, u_g_TLBFA.hitVecReg_36, u_g_TLBFA.hitVecReg_35, u_g_TLBFA.hitVecReg_34, u_g_TLBFA.hitVecReg_33, u_g_TLBFA.hitVecReg_32, u_g_TLBFA.hitVecReg_31, u_g_TLBFA.hitVecReg_30, u_g_TLBFA.hitVecReg_29, u_g_TLBFA.hitVecReg_28, u_g_TLBFA.hitVecReg_27, u_g_TLBFA.hitVecReg_26, u_g_TLBFA.hitVecReg_25, u_g_TLBFA.hitVecReg_24, u_g_TLBFA.hitVecReg_23, u_g_TLBFA.hitVecReg_22, u_g_TLBFA.hitVecReg_21, u_g_TLBFA.hitVecReg_20, u_g_TLBFA.hitVecReg_19, u_g_TLBFA.hitVecReg_18, u_g_TLBFA.hitVecReg_17, u_g_TLBFA.hitVecReg_16, u_g_TLBFA.hitVecReg_15, u_g_TLBFA.hitVecReg_14, u_g_TLBFA.hitVecReg_13, u_g_TLBFA.hitVecReg_12, u_g_TLBFA.hitVecReg_11, u_g_TLBFA.hitVecReg_10, u_g_TLBFA.hitVecReg_9, u_g_TLBFA.hitVecReg_8, u_g_TLBFA.hitVecReg_7, u_g_TLBFA.hitVecReg_6, u_g_TLBFA.hitVecReg_5, u_g_TLBFA.hitVecReg_4, u_g_TLBFA.hitVecReg_3, u_g_TLBFA.hitVecReg_2, u_g_TLBFA.hitVecReg_1, u_g_TLBFA.hitVecReg_0};

  int cov_multihit = 0;
  // fence 形态四桶：[0]=sfence.vma [1]=hfence.vvma [2]=hfence.gvma [3]=hv&hg 同置
  int cov_fence [4] = '{default: 0};
  int cov_hvhg = 0, cov_sf_w = 0;   // 两个纯激励侧的角落：hv&hg 同拍、sfence 与 refill 同拍
  int cov_hit_TLBFA = 0, cov_touch_TLBFA = 0, cov_flush_TLBFA = 0;
  int cov_occ_TLBFA = 0, cov_ppnnz_TLBFA = 0;
  int cov_s2x_TLBFA [4] = '{default: 0};
  int prev_occ_TLBFA = 0;
  int cov_hit_TLBFA_1 = 0, cov_touch_TLBFA_1 = 0, cov_flush_TLBFA_1 = 0;
  int cov_occ_TLBFA_1 = 0, cov_ppnnz_TLBFA_1 = 0;
  int cov_s2x_TLBFA_1 [4] = '{default: 0};
  int prev_occ_TLBFA_1 = 0;
  int cov_hit_TLBFA_2 = 0, cov_touch_TLBFA_2 = 0, cov_flush_TLBFA_2 = 0;
  int cov_occ_TLBFA_2 = 0, cov_ppnnz_TLBFA_2 = 0;
  int cov_s2x_TLBFA_2 [4] = '{default: 0};
  int prev_occ_TLBFA_2 = 0;
  int cov_hit_TLBFA_3 = 0, cov_touch_TLBFA_3 = 0, cov_flush_TLBFA_3 = 0;
  int cov_occ_TLBFA_3 = 0, cov_ppnnz_TLBFA_3 = 0;
  int cov_s2x_TLBFA_3 [4] = '{default: 0};
  int prev_occ_TLBFA_3 = 0;

  always @(posedge clk) if (!rst) begin : cov_blk
    int occ;
    occ = $countones(vbits_TLBFA);
    if (occ > cov_occ_TLBFA) cov_occ_TLBFA = occ;
    if (occ < prev_occ_TLBFA) cov_flush_TLBFA++;
    prev_occ_TLBFA = occ;
    if (g_TLBFA_io_r_resp_0_bits_hit) begin
      cov_hit_TLBFA++;
      if (g_TLBFA_io_r_resp_0_bits_ppn_0 != 0) cov_ppnnz_TLBFA++;
      cov_s2x_TLBFA[g_TLBFA_io_r_resp_0_bits_s2xlate_0]++;
    end
    if (g_TLBFA_io_access_0_touch_ways_valid) cov_touch_TLBFA++;
    if (g_TLBFA_io_r_resp_1_bits_hit) begin
      cov_hit_TLBFA++;
      if (g_TLBFA_io_r_resp_1_bits_ppn_0 != 0) cov_ppnnz_TLBFA++;
      cov_s2x_TLBFA[g_TLBFA_io_r_resp_1_bits_s2xlate_0]++;
    end
    if (g_TLBFA_io_access_1_touch_ways_valid) cov_touch_TLBFA++;
    if (g_TLBFA_io_r_resp_2_bits_hit) begin
      cov_hit_TLBFA++;
      if (g_TLBFA_io_r_resp_2_bits_ppn_0 != 0) cov_ppnnz_TLBFA++;
      cov_s2x_TLBFA[g_TLBFA_io_r_resp_2_bits_s2xlate_0]++;
    end
    if (g_TLBFA_io_access_2_touch_ways_valid) cov_touch_TLBFA++;
    occ = $countones(vbits_TLBFA_1);
    if (occ > cov_occ_TLBFA_1) cov_occ_TLBFA_1 = occ;
    if (occ < prev_occ_TLBFA_1) cov_flush_TLBFA_1++;
    prev_occ_TLBFA_1 = occ;
    if (g_TLBFA_1_io_r_resp_0_bits_hit) begin
      cov_hit_TLBFA_1++;
      if (g_TLBFA_1_io_r_resp_0_bits_ppn_0 != 0) cov_ppnnz_TLBFA_1++;
      cov_s2x_TLBFA_1[g_TLBFA_1_io_r_resp_0_bits_s2xlate_0]++;
    end
    if (g_TLBFA_1_io_access_0_touch_ways_valid) cov_touch_TLBFA_1++;
    if (g_TLBFA_1_io_r_resp_1_bits_hit) begin
      cov_hit_TLBFA_1++;
      if (g_TLBFA_1_io_r_resp_1_bits_ppn_0 != 0) cov_ppnnz_TLBFA_1++;
      cov_s2x_TLBFA_1[g_TLBFA_1_io_r_resp_1_bits_s2xlate_0]++;
    end
    if (g_TLBFA_1_io_access_1_touch_ways_valid) cov_touch_TLBFA_1++;
    if (g_TLBFA_1_io_r_resp_2_bits_hit) begin
      cov_hit_TLBFA_1++;
      if (g_TLBFA_1_io_r_resp_2_bits_ppn_0 != 0) cov_ppnnz_TLBFA_1++;
      cov_s2x_TLBFA_1[g_TLBFA_1_io_r_resp_2_bits_s2xlate_0]++;
    end
    if (g_TLBFA_1_io_access_2_touch_ways_valid) cov_touch_TLBFA_1++;
    if (g_TLBFA_1_io_r_resp_3_bits_hit) begin
      cov_hit_TLBFA_1++;
      if (g_TLBFA_1_io_r_resp_3_bits_ppn_0 != 0) cov_ppnnz_TLBFA_1++;
    end
    if (g_TLBFA_1_io_access_3_touch_ways_valid) cov_touch_TLBFA_1++;
    occ = $countones(vbits_TLBFA_2);
    if (occ > cov_occ_TLBFA_2) cov_occ_TLBFA_2 = occ;
    if (occ < prev_occ_TLBFA_2) cov_flush_TLBFA_2++;
    prev_occ_TLBFA_2 = occ;
    if (g_TLBFA_2_io_r_resp_0_bits_hit) begin
      cov_hit_TLBFA_2++;
      if (g_TLBFA_2_io_r_resp_0_bits_ppn_0 != 0) cov_ppnnz_TLBFA_2++;
      cov_s2x_TLBFA_2[g_TLBFA_2_io_r_resp_0_bits_s2xlate_0]++;
    end
    if (g_TLBFA_2_io_access_0_touch_ways_valid) cov_touch_TLBFA_2++;
    if (g_TLBFA_2_io_r_resp_1_bits_hit) begin
      cov_hit_TLBFA_2++;
      if (g_TLBFA_2_io_r_resp_1_bits_ppn_0 != 0) cov_ppnnz_TLBFA_2++;
      cov_s2x_TLBFA_2[g_TLBFA_2_io_r_resp_1_bits_s2xlate_0]++;
    end
    if (g_TLBFA_2_io_access_1_touch_ways_valid) cov_touch_TLBFA_2++;
    occ = $countones(vbits_TLBFA_3);
    if (occ > cov_occ_TLBFA_3) cov_occ_TLBFA_3 = occ;
    if (occ < prev_occ_TLBFA_3) cov_flush_TLBFA_3++;
    prev_occ_TLBFA_3 = occ;
    if (g_TLBFA_3_io_r_resp_0_bits_hit) begin
      cov_hit_TLBFA_3++;
      if (g_TLBFA_3_io_r_resp_0_bits_ppn_0 != 0) cov_ppnnz_TLBFA_3++;
    end
    if (g_TLBFA_3_io_access_0_touch_ways_valid) cov_touch_TLBFA_3++;
    if (g_TLBFA_3_io_r_resp_1_bits_hit) begin
      cov_hit_TLBFA_3++;
      if (g_TLBFA_3_io_r_resp_1_bits_ppn_0 != 0) cov_ppnnz_TLBFA_3++;
    end
    if (g_TLBFA_3_io_access_1_touch_ways_valid) cov_touch_TLBFA_3++;
    if ($countones(hitvec0_TLBFA) > 1) cov_multihit++;
    if (sf_valid) cov_fence[{sf_hg, sf_hv}]++;
    if (sf_valid && sf_hv && sf_hg) cov_hvhg++;
    if (sf_valid && w_valid) cov_sf_w++;
  end

  // 覆盖门槛（按 200k 拍标定；实测值见 sim_*.log 的 [cov] 行）。
  // TH_OCC=30 而不是 48：sfence/hfence 约占 3%，阵列被反复刷掉，48 条同时有效
  // 在这套激励下不会出现（实测峰值 37）。门槛要卡在"确实填起来过"，不是卡在理想值。
  localparam int TH_HIT = 20000, TH_TOUCH = 20000, TH_FLUSH = 500;
  localparam int TH_OCC = 30, TH_PPNNZ = 20000, TH_S2X = 1000, TH_CORNER = 200;

  function automatic void print_cov();
    $display("[cov] fence    sfence=%0d hfence.vvma=%0d hfence.gvma=%0d hv&hg=%0d",
             cov_fence[0], cov_fence[1], cov_fence[2], cov_fence[3]);
    $display("[cov] corner   hv&hg=%0d sfence+refill 同拍=%0d 多命中(TLBFA port0)=%0d",
             cov_hvhg, cov_sf_w, cov_multihit);
    $display("[cov] TLBFA    hit=%0d touch=%0d flush=%0d occ_max=%0d ppn!=0=%0d s2x=[%0d %0d %0d %0d]",
             cov_hit_TLBFA, cov_touch_TLBFA, cov_flush_TLBFA, cov_occ_TLBFA, cov_ppnnz_TLBFA, cov_s2x_TLBFA[0], cov_s2x_TLBFA[1], cov_s2x_TLBFA[2], cov_s2x_TLBFA[3]);
    $display("[cov] TLBFA_1  hit=%0d touch=%0d flush=%0d occ_max=%0d ppn!=0=%0d s2x=[%0d %0d %0d %0d]",
             cov_hit_TLBFA_1, cov_touch_TLBFA_1, cov_flush_TLBFA_1, cov_occ_TLBFA_1, cov_ppnnz_TLBFA_1, cov_s2x_TLBFA_1[0], cov_s2x_TLBFA_1[1], cov_s2x_TLBFA_1[2], cov_s2x_TLBFA_1[3]);
    $display("[cov] TLBFA_2  hit=%0d touch=%0d flush=%0d occ_max=%0d ppn!=0=%0d s2x=[%0d %0d %0d %0d]",
             cov_hit_TLBFA_2, cov_touch_TLBFA_2, cov_flush_TLBFA_2, cov_occ_TLBFA_2, cov_ppnnz_TLBFA_2, cov_s2x_TLBFA_2[0], cov_s2x_TLBFA_2[1], cov_s2x_TLBFA_2[2], cov_s2x_TLBFA_2[3]);
    $display("[cov] TLBFA_3  hit=%0d touch=%0d flush=%0d occ_max=%0d ppn!=0=%0d",
             cov_hit_TLBFA_3, cov_touch_TLBFA_3, cov_flush_TLBFA_3, cov_occ_TLBFA_3, cov_ppnnz_TLBFA_3);
  endfunction

  function automatic bit cov_ok();
    bit ok = 1;
    for (int k = 0; k < 4; k++) if (cov_fence[k] < TH_CORNER) begin ok = 0; $display("[cov] FAIL fence 形态 %0d 只出现 %0d 次 < %0d", k, cov_fence[k], TH_CORNER); end
    if (cov_multihit < TH_CORNER) begin ok = 0; $display("[cov] FAIL 多命中=%0d < %0d", cov_multihit, TH_CORNER); end
    if (cov_hvhg < TH_CORNER) begin ok = 0; $display("[cov] FAIL hv&hg=%0d < %0d", cov_hvhg, TH_CORNER); end
    if (cov_sf_w < TH_CORNER) begin ok = 0; $display("[cov] FAIL sfence+refill=%0d < %0d", cov_sf_w, TH_CORNER); end
    if (cov_hit_TLBFA   < TH_HIT)   begin ok = 0; $display("[cov] FAIL TLBFA hit=%0d < %0d", cov_hit_TLBFA, TH_HIT); end
    if (cov_touch_TLBFA < TH_TOUCH) begin ok = 0; $display("[cov] FAIL TLBFA touch=%0d < %0d", cov_touch_TLBFA, TH_TOUCH); end
    if (cov_flush_TLBFA < TH_FLUSH) begin ok = 0; $display("[cov] FAIL TLBFA flush=%0d < %0d", cov_flush_TLBFA, TH_FLUSH); end
    if (cov_occ_TLBFA   < TH_OCC)   begin ok = 0; $display("[cov] FAIL TLBFA occ_max=%0d < %0d", cov_occ_TLBFA, TH_OCC); end
    if (cov_ppnnz_TLBFA < TH_PPNNZ) begin ok = 0; $display("[cov] FAIL TLBFA ppn!=0=%0d < %0d", cov_ppnnz_TLBFA, TH_PPNNZ); end
    for (int k = 0; k < 4; k++) if (cov_s2x_TLBFA[k] < TH_S2X) begin ok = 0; $display("[cov] FAIL TLBFA s2x[%0d]=%0d < %0d", k, cov_s2x_TLBFA[k], TH_S2X); end
    if (cov_hit_TLBFA_1   < TH_HIT)   begin ok = 0; $display("[cov] FAIL TLBFA_1 hit=%0d < %0d", cov_hit_TLBFA_1, TH_HIT); end
    if (cov_touch_TLBFA_1 < TH_TOUCH) begin ok = 0; $display("[cov] FAIL TLBFA_1 touch=%0d < %0d", cov_touch_TLBFA_1, TH_TOUCH); end
    if (cov_flush_TLBFA_1 < TH_FLUSH) begin ok = 0; $display("[cov] FAIL TLBFA_1 flush=%0d < %0d", cov_flush_TLBFA_1, TH_FLUSH); end
    if (cov_occ_TLBFA_1   < TH_OCC)   begin ok = 0; $display("[cov] FAIL TLBFA_1 occ_max=%0d < %0d", cov_occ_TLBFA_1, TH_OCC); end
    if (cov_ppnnz_TLBFA_1 < TH_PPNNZ) begin ok = 0; $display("[cov] FAIL TLBFA_1 ppn!=0=%0d < %0d", cov_ppnnz_TLBFA_1, TH_PPNNZ); end
    for (int k = 0; k < 4; k++) if (cov_s2x_TLBFA_1[k] < TH_S2X) begin ok = 0; $display("[cov] FAIL TLBFA_1 s2x[%0d]=%0d < %0d", k, cov_s2x_TLBFA_1[k], TH_S2X); end
    if (cov_hit_TLBFA_2   < TH_HIT)   begin ok = 0; $display("[cov] FAIL TLBFA_2 hit=%0d < %0d", cov_hit_TLBFA_2, TH_HIT); end
    if (cov_touch_TLBFA_2 < TH_TOUCH) begin ok = 0; $display("[cov] FAIL TLBFA_2 touch=%0d < %0d", cov_touch_TLBFA_2, TH_TOUCH); end
    if (cov_flush_TLBFA_2 < TH_FLUSH) begin ok = 0; $display("[cov] FAIL TLBFA_2 flush=%0d < %0d", cov_flush_TLBFA_2, TH_FLUSH); end
    if (cov_occ_TLBFA_2   < TH_OCC)   begin ok = 0; $display("[cov] FAIL TLBFA_2 occ_max=%0d < %0d", cov_occ_TLBFA_2, TH_OCC); end
    if (cov_ppnnz_TLBFA_2 < TH_PPNNZ) begin ok = 0; $display("[cov] FAIL TLBFA_2 ppn!=0=%0d < %0d", cov_ppnnz_TLBFA_2, TH_PPNNZ); end
    for (int k = 0; k < 4; k++) if (cov_s2x_TLBFA_2[k] < TH_S2X) begin ok = 0; $display("[cov] FAIL TLBFA_2 s2x[%0d]=%0d < %0d", k, cov_s2x_TLBFA_2[k], TH_S2X); end
    if (cov_hit_TLBFA_3   < TH_HIT)   begin ok = 0; $display("[cov] FAIL TLBFA_3 hit=%0d < %0d", cov_hit_TLBFA_3, TH_HIT); end
    if (cov_touch_TLBFA_3 < TH_TOUCH) begin ok = 0; $display("[cov] FAIL TLBFA_3 touch=%0d < %0d", cov_touch_TLBFA_3, TH_TOUCH); end
    if (cov_flush_TLBFA_3 < TH_FLUSH) begin ok = 0; $display("[cov] FAIL TLBFA_3 flush=%0d < %0d", cov_flush_TLBFA_3, TH_FLUSH); end
    if (cov_occ_TLBFA_3   < TH_OCC)   begin ok = 0; $display("[cov] FAIL TLBFA_3 occ_max=%0d < %0d", cov_occ_TLBFA_3, TH_OCC); end
    if (cov_ppnnz_TLBFA_3 < TH_PPNNZ) begin ok = 0; $display("[cov] FAIL TLBFA_3 ppn!=0=%0d < %0d", cov_ppnnz_TLBFA_3, TH_PPNNZ); end
    return ok;
  endfunction

  // ==================================================================
  //  激励生成
  // ==================================================================
  localparam int POOLN = 24;
  logic [37:0] pool [POOLN];

  initial begin
    // vpn 池：高 11 位只有 3 种、次高 9 位只有 4 种 —— 高位大量重合，
    // 这样 1GB/512GB 超页（只比高位）也能被命中，而不是只测 4KB 精确匹配。
    for (int i = 0; i < POOLN; i++)
      pool[i] = {11'(i % 3), 9'((i / 3) % 4), 9'(i % 5), 9'((i * 37) % 512)};
  end

  function automatic logic [37:0] pick_vpn();
    logic [37:0] a;
    a = pool[$urandom_range(0, POOLN - 1)];
    if ($urandom_range(0, 9) == 0) a = 38'($urandom);   // 10% 纯随机，制造未命中
    a[2:0] = 3'($urandom);                              // sector 内位置单独随机
    return a;
  endfunction

  function automatic logic [1:0] pick_level();
    int r = $urandom_range(0, 9);
    if (r < 6) return 2'd0;                             // 4KB 占多数
    else if (r < 8) return 2'd1;
    else if (r < 9) return 2'd2;
    else return 2'd3;
  endfunction

  function automatic logic [7:0] pick_idxvec(input bit onehot_bias);
    int r = $urandom_range(0, 9);
    if (onehot_bias && r < 6) return 8'(1 << $urandom_range(0, 7));
    if (r < 8) return 8'hFF;
    return 8'($urandom);
  endfunction

  always @(negedge clk) begin
    logic [37:0] a;
    int          kind;
    if (rst) begin
      rq_valid <= 4'hF;      // 复位期间也发请求：把两侧的 hitVecReg 冲成确定的 0
      rq_vpn   <= '0;
      rq_s2x   <= '0;
      w_valid  <= 1'b0;
      sf_valid <= 1'b0;
      sf_hv    <= 1'b0;
      sf_hg    <= 1'b0;
      csr_satp_asid  <= 16'd1;
      csr_vsatp_asid <= 16'd2;
      csr_hgatp_vmid <= 16'd1;
      csr_bme   <= 1'b0;
      csr_cmode <= 1'b0;
      csr_virt  <= 1'b0;
    end else begin
      // --- CSR 现场：偶尔换一次 ---
      if ($urandom_range(0, 999) < 8) begin
        csr_satp_asid  <= 16'($urandom_range(0, 3));
        csr_vsatp_asid <= 16'($urandom_range(0, 3));
        csr_hgatp_vmid <= 16'($urandom_range(0, 3));
        csr_virt       <= 1'($urandom_range(0, 1));
        csr_bme        <= ($urandom_range(0, 9) < 3);
        csr_cmode      <= 1'($urandom_range(0, 1));
      end

      // --- 查询：4 路各自独立 ---
      for (int p = 0; p < 4; p++) begin
        rq_valid[p] <= ($urandom_range(0, 9) < 8);
        rq_vpn[p]   <= pick_vpn();
        rq_s2x[p]   <= 2'($urandom_range(0, 3));
      end

      // --- refill ---
      w_valid   <= ($urandom_range(0, 99) < 25);
      w_way     <= 6'($urandom_range(0, 47));
      w_s2xlate <= 2'($urandom_range(0, 3));
      a = pool[$urandom_range(0, POOLN - 1)];
      w_s1_entry_tag  <= a[37:3];
      w_s2_entry_tag  <= {a[37:3], 3'($urandom)};
      w_s1_entry_asid <= 16'($urandom_range(0, 3));
      w_s1_entry_vmid <= 14'($urandom_range(0, 3));
      w_s2_entry_vmid <= 14'($urandom_range(0, 3));
      w_s1_entry_n    <= ($urandom_range(0, 9) < 2);
      w_s2_entry_n    <= ($urandom_range(0, 9) < 2);
      w_s1_entry_level <= pick_level();
      w_s2_entry_level <= pick_level();
      w_s1_entry_pbmt <= 2'($urandom);
      w_s2_entry_pbmt <= 2'($urandom);
      w_s1_entry_ppn  <= 41'($urandom);
      w_s2_entry_ppn  <= 38'($urandom);
      w_s1_entry_v    <= ($urandom_range(0, 9) < 7);
      w_s1_pf         <= ($urandom_range(0, 9) < 2);
      w_s1_af         <= ($urandom_range(0, 9) < 2);
      w_s2_gpf        <= ($urandom_range(0, 9) < 2);
      w_s2_gaf        <= ($urandom_range(0, 9) < 2);
      {w_s1_entry_perm_d, w_s1_entry_perm_a, w_s1_entry_perm_g, w_s1_entry_perm_u,
       w_s1_entry_perm_x, w_s1_entry_perm_w, w_s1_entry_perm_r} <= 7'($urandom);
      {w_s2_entry_perm_d, w_s2_entry_perm_a, w_s2_entry_perm_g, w_s2_entry_perm_u,
       w_s2_entry_perm_x, w_s2_entry_perm_w, w_s2_entry_perm_r} <= 7'($urandom);
      for (int k = 0; k < 8; k++) w_s1_ppn_low[k] <= 3'($urandom);
      w_s1_valididx <= pick_idxvec(1'b0);
      w_s1_pteidx   <= pick_idxvec(1'b1);

      // --- sfence / hfence：约 3%，三种指令各约 1% ---
      if ($urandom_range(0, 99) < 3) begin
        // kind==3 = hv 与 hg **同时**置位。父级 TLB 不会这么发，但 golden 对这种
        // 输入有确定行为（else-if 链里 hg 排在最前 => hg 赢），所以模块级比对必须覆盖它：
        // 不覆盖的话，把两支优先级写反的重写件照样 errors=0（实测：这正是 M2 变异体）。
        //
        // ★ kind 的声明与赋值必须分开 ★：always 块里变量默认是 **static** 生命期，
        // `int kind = $urandom_range(0,3);` 的初值只在 0 时刻算**一次**，此后永远不变。
        // 实测（本 UT 第一版）：seed=1 整轮 6000 次 sfence **全是** kind=3，
        // seed=7 整轮一次 kind=3 都没有（[cov] hv&hg=0）——三条 fence 指令里
        // 每轮只测了一种，而 errors=0 照样打印。这正是"看起来在验、实际没在验"。
        kind = $urandom_range(0, 3);
        sf_valid <= 1'b1;
        sf_hv    <= (kind == 1) || (kind == 3);
        sf_hg    <= (kind == 2) || (kind == 3);
        sf_rs1   <= 1'($urandom_range(0, 1));
        sf_rs2   <= 1'($urandom_range(0, 1));
        sf_addr  <= {pool[$urandom_range(0, POOLN - 1)], 12'($urandom)};
        sf_id    <= 16'($urandom_range(0, 3));
      end else begin
        sf_valid <= 1'b0;
      end
    end
  end

  // ==================================================================
  //  主控
  // ==================================================================
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if ($test$plusargs("fsdb")) begin
      $fsdbDumpfile("novas.fsdb");
      $fsdbDumpvars(0, tb);
    end

    rst = 1;
    warm = 0;
    repeat (8) @(posedge clk);
    rst = 0;
    repeat (8) @(posedge clk);   // 热身：让无复位寄存器被写成确定值
    warm = 1;

    repeat (NCYCLES / 2) @(posedge clk);

    // 中途复位（正常宽度）：验复位后 entry 还在、但 v=0 所以读不出来
    @(negedge clk);
    rst = 1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst = 0;

    repeat (NCYCLES / 4) @(posedge clk);

    // ★单拍复位毛刺★：rst 在两个上升沿**之间**起落，期间没有任何时钟沿。
    // golden 的 v 是 `always @(posedge clock or posedge reset)`（异步），会当场清零；
    // 写成同步复位的实现则完全看不见这次复位 —— 只有这种激励能把两者区分开。
    // （本 UT 的 M6 变异体就是把异步改成同步，不加这一段它抓不出来。）
    repeat (2) begin
      @(posedge clk);
      #1 rst = 1;
      #3 rst = 0;
      repeat (20) @(posedge clk);
    end

    repeat (NCYCLES / 4) @(posedge clk);

    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    print_cov();
    if (errors == 0 && checks > 10000 && cov_ok())
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end

endmodule
