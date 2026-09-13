// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// DelayN 家族 6 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
// （同一个 xs_DelayN_core 设不同 WIDTH/STAGES）。
//
// tb 把每个变体的载荷当成一根扁平向量随机驱动，再按 **golden 端口顺序 MSB 优先**
// 切片接到各个 io_in_*/io_out_* 上——这份切片是 tb 独立重算的，与薄文件里的拼接
// 互为对照：只要两边的打包顺序对不上，逐拍比对立刻失配。
//
// 打拍链无复位：上电输出为 X，故 $isunknown(golden 输出) 时跳过比对（不计 checks）。
//
// 覆盖闸（小模块最容易假绿：本轮有 tb 在 20 万拍里只 fire 1 次却报 errors=0）：
//   每个变体都必须
//     (1) 有效比对次数 checks >= COV_MIN；
//     (2) 输出发生变化（相邻拍不等）的次数 >= COV_MIN —— 证明数据真的在流动；
//     (3) **每一个载荷位**都在输出上既被观察到 1 也被观察到 0 —— 任何一位常 X /
//         常 0 / 接错都会让 ones/zeros 位图缺位，直接判 FAIL。
//   任何一项不满足即 TEST FAILED，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  int mode;
  always #5 clock = ~clock;

  // ---- DelayN: 载荷 5 位 / 1 级 / 5 字段 ----
  logic [4:0] d0_in;
  wire  [4:0] g_d0_out;
  wire  [4:0] i_d0_out;
  logic [4:0] d0_ones, d0_zeros, d0_prev;
  int   d0_checks, d0_moves;
  DelayN u_g_d0 (
    .clock(clock),
    .io_in_ubtb_enable(d0_in[4]),
    .io_in_btb_enable(d0_in[3]),
    .io_in_tage_enable(d0_in[2]),
    .io_in_sc_enable(d0_in[1]),
    .io_in_ras_enable(d0_in[0]),
    .io_out_ubtb_enable(g_d0_out[4]),
    .io_out_btb_enable(g_d0_out[3]),
    .io_out_tage_enable(g_d0_out[2]),
    .io_out_sc_enable(g_d0_out[1]),
    .io_out_ras_enable(g_d0_out[0])
  );
  DelayN_xs u_i_d0 (
    .clock(clock),
    .io_in_ubtb_enable(d0_in[4]),
    .io_in_btb_enable(d0_in[3]),
    .io_in_tage_enable(d0_in[2]),
    .io_in_sc_enable(d0_in[1]),
    .io_in_ras_enable(d0_in[0]),
    .io_out_ubtb_enable(i_d0_out[4]),
    .io_out_btb_enable(i_d0_out[3]),
    .io_out_tage_enable(i_d0_out[2]),
    .io_out_sc_enable(i_d0_out[1]),
    .io_out_ras_enable(i_d0_out[0])
  );

  // ---- DelayN_1: 载荷 1 位 / 2 级 / 1 字段 ----
  logic [0:0] d1_in;
  wire  [0:0] g_d1_out;
  wire  [0:0] i_d1_out;
  logic [0:0] d1_ones, d1_zeros, d1_prev;
  int   d1_checks, d1_moves;
  DelayN_1 u_g_d1 (
    .clock(clock),
    .io_in(d1_in[0]),
    .io_out(g_d1_out[0])
  );
  DelayN_1_xs u_i_d1 (
    .clock(clock),
    .io_in(d1_in[0]),
    .io_out(i_d1_out[0])
  );

  // ---- DelayN_7: 载荷 219 位 / 2 级 / 29 字段 ----
  logic [218:0] d7_in;
  wire  [218:0] g_d7_out;
  wire  [218:0] i_d7_out;
  logic [218:0] d7_ones, d7_zeros, d7_prev;
  int   d7_checks, d7_moves;
  DelayN_7 u_g_d7 (
    .clock(clock),
    .io_in_satp_mode(d7_in[218:215]),
    .io_in_satp_asid(d7_in[214:199]),
    .io_in_satp_ppn(d7_in[198:155]),
    .io_in_satp_changed(d7_in[154]),
    .io_in_vsatp_mode(d7_in[153:150]),
    .io_in_vsatp_asid(d7_in[149:134]),
    .io_in_vsatp_ppn(d7_in[133:90]),
    .io_in_vsatp_changed(d7_in[89]),
    .io_in_hgatp_mode(d7_in[88:85]),
    .io_in_hgatp_vmid(d7_in[84:69]),
    .io_in_hgatp_ppn(d7_in[68:25]),
    .io_in_hgatp_changed(d7_in[24]),
    .io_in_mbmc_BME(d7_in[23]),
    .io_in_mbmc_CMODE(d7_in[22]),
    .io_in_priv_mxr(d7_in[21]),
    .io_in_priv_sum(d7_in[20]),
    .io_in_priv_vmxr(d7_in[19]),
    .io_in_priv_vsum(d7_in[18]),
    .io_in_priv_virt(d7_in[17]),
    .io_in_priv_virt_changed(d7_in[16]),
    .io_in_priv_spvp(d7_in[15]),
    .io_in_priv_imode(d7_in[14:13]),
    .io_in_priv_dmode(d7_in[12:11]),
    .io_in_priv_debug(d7_in[10]),
    .io_in_pmm_mseccfg(d7_in[9:8]),
    .io_in_pmm_menvcfg(d7_in[7:6]),
    .io_in_pmm_henvcfg(d7_in[5:4]),
    .io_in_pmm_hstatus(d7_in[3:2]),
    .io_in_pmm_senvcfg(d7_in[1:0]),
    .io_out_satp_mode(g_d7_out[218:215]),
    .io_out_satp_asid(g_d7_out[214:199]),
    .io_out_satp_ppn(g_d7_out[198:155]),
    .io_out_satp_changed(g_d7_out[154]),
    .io_out_vsatp_mode(g_d7_out[153:150]),
    .io_out_vsatp_asid(g_d7_out[149:134]),
    .io_out_vsatp_ppn(g_d7_out[133:90]),
    .io_out_vsatp_changed(g_d7_out[89]),
    .io_out_hgatp_mode(g_d7_out[88:85]),
    .io_out_hgatp_vmid(g_d7_out[84:69]),
    .io_out_hgatp_ppn(g_d7_out[68:25]),
    .io_out_hgatp_changed(g_d7_out[24]),
    .io_out_mbmc_BME(g_d7_out[23]),
    .io_out_mbmc_CMODE(g_d7_out[22]),
    .io_out_priv_mxr(g_d7_out[21]),
    .io_out_priv_sum(g_d7_out[20]),
    .io_out_priv_vmxr(g_d7_out[19]),
    .io_out_priv_vsum(g_d7_out[18]),
    .io_out_priv_virt(g_d7_out[17]),
    .io_out_priv_virt_changed(g_d7_out[16]),
    .io_out_priv_spvp(g_d7_out[15]),
    .io_out_priv_imode(g_d7_out[14:13]),
    .io_out_priv_dmode(g_d7_out[12:11]),
    .io_out_priv_debug(g_d7_out[10]),
    .io_out_pmm_mseccfg(g_d7_out[9:8]),
    .io_out_pmm_menvcfg(g_d7_out[7:6]),
    .io_out_pmm_henvcfg(g_d7_out[5:4]),
    .io_out_pmm_hstatus(g_d7_out[3:2]),
    .io_out_pmm_senvcfg(g_d7_out[1:0])
  );
  DelayN_7_xs u_i_d7 (
    .clock(clock),
    .io_in_satp_mode(d7_in[218:215]),
    .io_in_satp_asid(d7_in[214:199]),
    .io_in_satp_ppn(d7_in[198:155]),
    .io_in_satp_changed(d7_in[154]),
    .io_in_vsatp_mode(d7_in[153:150]),
    .io_in_vsatp_asid(d7_in[149:134]),
    .io_in_vsatp_ppn(d7_in[133:90]),
    .io_in_vsatp_changed(d7_in[89]),
    .io_in_hgatp_mode(d7_in[88:85]),
    .io_in_hgatp_vmid(d7_in[84:69]),
    .io_in_hgatp_ppn(d7_in[68:25]),
    .io_in_hgatp_changed(d7_in[24]),
    .io_in_mbmc_BME(d7_in[23]),
    .io_in_mbmc_CMODE(d7_in[22]),
    .io_in_priv_mxr(d7_in[21]),
    .io_in_priv_sum(d7_in[20]),
    .io_in_priv_vmxr(d7_in[19]),
    .io_in_priv_vsum(d7_in[18]),
    .io_in_priv_virt(d7_in[17]),
    .io_in_priv_virt_changed(d7_in[16]),
    .io_in_priv_spvp(d7_in[15]),
    .io_in_priv_imode(d7_in[14:13]),
    .io_in_priv_dmode(d7_in[12:11]),
    .io_in_priv_debug(d7_in[10]),
    .io_in_pmm_mseccfg(d7_in[9:8]),
    .io_in_pmm_menvcfg(d7_in[7:6]),
    .io_in_pmm_henvcfg(d7_in[5:4]),
    .io_in_pmm_hstatus(d7_in[3:2]),
    .io_in_pmm_senvcfg(d7_in[1:0]),
    .io_out_satp_mode(i_d7_out[218:215]),
    .io_out_satp_asid(i_d7_out[214:199]),
    .io_out_satp_ppn(i_d7_out[198:155]),
    .io_out_satp_changed(i_d7_out[154]),
    .io_out_vsatp_mode(i_d7_out[153:150]),
    .io_out_vsatp_asid(i_d7_out[149:134]),
    .io_out_vsatp_ppn(i_d7_out[133:90]),
    .io_out_vsatp_changed(i_d7_out[89]),
    .io_out_hgatp_mode(i_d7_out[88:85]),
    .io_out_hgatp_vmid(i_d7_out[84:69]),
    .io_out_hgatp_ppn(i_d7_out[68:25]),
    .io_out_hgatp_changed(i_d7_out[24]),
    .io_out_mbmc_BME(i_d7_out[23]),
    .io_out_mbmc_CMODE(i_d7_out[22]),
    .io_out_priv_mxr(i_d7_out[21]),
    .io_out_priv_sum(i_d7_out[20]),
    .io_out_priv_vmxr(i_d7_out[19]),
    .io_out_priv_vsum(i_d7_out[18]),
    .io_out_priv_virt(i_d7_out[17]),
    .io_out_priv_virt_changed(i_d7_out[16]),
    .io_out_priv_spvp(i_d7_out[15]),
    .io_out_priv_imode(i_d7_out[14:13]),
    .io_out_priv_dmode(i_d7_out[12:11]),
    .io_out_priv_debug(i_d7_out[10]),
    .io_out_pmm_mseccfg(i_d7_out[9:8]),
    .io_out_pmm_menvcfg(i_d7_out[7:6]),
    .io_out_pmm_henvcfg(i_d7_out[5:4]),
    .io_out_pmm_hstatus(i_d7_out[3:2]),
    .io_out_pmm_senvcfg(i_d7_out[1:0])
  );

  // ---- DelayN_8: 载荷 274 位 / 2 级 / 43 字段 ----
  logic [273:0] d8_in;
  wire  [273:0] g_d8_out;
  wire  [273:0] i_d8_out;
  logic [273:0] d8_ones, d8_zeros, d8_prev;
  int   d8_checks, d8_moves;
  DelayN_8 u_g_d8 (
    .clock(clock),
    .io_in_pf_ctrl_l1I_pf_enable(d8_in[273]),
    .io_in_bp_ctrl_ubtb_enable(d8_in[272]),
    .io_in_bp_ctrl_btb_enable(d8_in[271]),
    .io_in_bp_ctrl_tage_enable(d8_in[270]),
    .io_in_bp_ctrl_sc_enable(d8_in[269]),
    .io_in_bp_ctrl_ras_enable(d8_in[268]),
    .io_in_sbuffer_timeout(d8_in[267:246]),
    .io_in_ldld_vio_check_enable(d8_in[245]),
    .io_in_cache_error_enable(d8_in[244]),
    .io_in_hd_misalign_st_enable(d8_in[243]),
    .io_in_hd_misalign_ld_enable(d8_in[242]),
    .io_in_distribute_csr_w_valid(d8_in[241]),
    .io_in_distribute_csr_w_bits_addr(d8_in[240:229]),
    .io_in_distribute_csr_w_bits_data(d8_in[228:165]),
    .io_in_frontend_trigger_tUpdate_valid(d8_in[164]),
    .io_in_frontend_trigger_tUpdate_bits_addr(d8_in[163:162]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_matchType(d8_in[161:160]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_select(d8_in[159]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_action(d8_in[158:155]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_chain(d8_in[154]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_tdata2(d8_in[153:90]),
    .io_in_frontend_trigger_tEnableVec_0(d8_in[89]),
    .io_in_frontend_trigger_tEnableVec_1(d8_in[88]),
    .io_in_frontend_trigger_tEnableVec_2(d8_in[87]),
    .io_in_frontend_trigger_tEnableVec_3(d8_in[86]),
    .io_in_frontend_trigger_debugMode(d8_in[85]),
    .io_in_frontend_trigger_triggerCanRaiseBpExp(d8_in[84]),
    .io_in_mem_trigger_tUpdate_valid(d8_in[83]),
    .io_in_mem_trigger_tUpdate_bits_addr(d8_in[82:81]),
    .io_in_mem_trigger_tUpdate_bits_tdata_matchType(d8_in[80:79]),
    .io_in_mem_trigger_tUpdate_bits_tdata_select(d8_in[78]),
    .io_in_mem_trigger_tUpdate_bits_tdata_action(d8_in[77:74]),
    .io_in_mem_trigger_tUpdate_bits_tdata_chain(d8_in[73]),
    .io_in_mem_trigger_tUpdate_bits_tdata_store(d8_in[72]),
    .io_in_mem_trigger_tUpdate_bits_tdata_load(d8_in[71]),
    .io_in_mem_trigger_tUpdate_bits_tdata_tdata2(d8_in[70:7]),
    .io_in_mem_trigger_tEnableVec_0(d8_in[6]),
    .io_in_mem_trigger_tEnableVec_1(d8_in[5]),
    .io_in_mem_trigger_tEnableVec_2(d8_in[4]),
    .io_in_mem_trigger_tEnableVec_3(d8_in[3]),
    .io_in_mem_trigger_debugMode(d8_in[2]),
    .io_in_mem_trigger_triggerCanRaiseBpExp(d8_in[1]),
    .io_in_fsIsOff(d8_in[0]),
    .io_out_pf_ctrl_l1I_pf_enable(g_d8_out[273]),
    .io_out_bp_ctrl_ubtb_enable(g_d8_out[272]),
    .io_out_bp_ctrl_btb_enable(g_d8_out[271]),
    .io_out_bp_ctrl_tage_enable(g_d8_out[270]),
    .io_out_bp_ctrl_sc_enable(g_d8_out[269]),
    .io_out_bp_ctrl_ras_enable(g_d8_out[268]),
    .io_out_sbuffer_timeout(g_d8_out[267:246]),
    .io_out_ldld_vio_check_enable(g_d8_out[245]),
    .io_out_cache_error_enable(g_d8_out[244]),
    .io_out_hd_misalign_st_enable(g_d8_out[243]),
    .io_out_hd_misalign_ld_enable(g_d8_out[242]),
    .io_out_distribute_csr_w_valid(g_d8_out[241]),
    .io_out_distribute_csr_w_bits_addr(g_d8_out[240:229]),
    .io_out_distribute_csr_w_bits_data(g_d8_out[228:165]),
    .io_out_frontend_trigger_tUpdate_valid(g_d8_out[164]),
    .io_out_frontend_trigger_tUpdate_bits_addr(g_d8_out[163:162]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_matchType(g_d8_out[161:160]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_select(g_d8_out[159]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_action(g_d8_out[158:155]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_chain(g_d8_out[154]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_tdata2(g_d8_out[153:90]),
    .io_out_frontend_trigger_tEnableVec_0(g_d8_out[89]),
    .io_out_frontend_trigger_tEnableVec_1(g_d8_out[88]),
    .io_out_frontend_trigger_tEnableVec_2(g_d8_out[87]),
    .io_out_frontend_trigger_tEnableVec_3(g_d8_out[86]),
    .io_out_frontend_trigger_debugMode(g_d8_out[85]),
    .io_out_frontend_trigger_triggerCanRaiseBpExp(g_d8_out[84]),
    .io_out_mem_trigger_tUpdate_valid(g_d8_out[83]),
    .io_out_mem_trigger_tUpdate_bits_addr(g_d8_out[82:81]),
    .io_out_mem_trigger_tUpdate_bits_tdata_matchType(g_d8_out[80:79]),
    .io_out_mem_trigger_tUpdate_bits_tdata_select(g_d8_out[78]),
    .io_out_mem_trigger_tUpdate_bits_tdata_action(g_d8_out[77:74]),
    .io_out_mem_trigger_tUpdate_bits_tdata_chain(g_d8_out[73]),
    .io_out_mem_trigger_tUpdate_bits_tdata_store(g_d8_out[72]),
    .io_out_mem_trigger_tUpdate_bits_tdata_load(g_d8_out[71]),
    .io_out_mem_trigger_tUpdate_bits_tdata_tdata2(g_d8_out[70:7]),
    .io_out_mem_trigger_tEnableVec_0(g_d8_out[6]),
    .io_out_mem_trigger_tEnableVec_1(g_d8_out[5]),
    .io_out_mem_trigger_tEnableVec_2(g_d8_out[4]),
    .io_out_mem_trigger_tEnableVec_3(g_d8_out[3]),
    .io_out_mem_trigger_debugMode(g_d8_out[2]),
    .io_out_mem_trigger_triggerCanRaiseBpExp(g_d8_out[1]),
    .io_out_fsIsOff(g_d8_out[0])
  );
  DelayN_8_xs u_i_d8 (
    .clock(clock),
    .io_in_pf_ctrl_l1I_pf_enable(d8_in[273]),
    .io_in_bp_ctrl_ubtb_enable(d8_in[272]),
    .io_in_bp_ctrl_btb_enable(d8_in[271]),
    .io_in_bp_ctrl_tage_enable(d8_in[270]),
    .io_in_bp_ctrl_sc_enable(d8_in[269]),
    .io_in_bp_ctrl_ras_enable(d8_in[268]),
    .io_in_sbuffer_timeout(d8_in[267:246]),
    .io_in_ldld_vio_check_enable(d8_in[245]),
    .io_in_cache_error_enable(d8_in[244]),
    .io_in_hd_misalign_st_enable(d8_in[243]),
    .io_in_hd_misalign_ld_enable(d8_in[242]),
    .io_in_distribute_csr_w_valid(d8_in[241]),
    .io_in_distribute_csr_w_bits_addr(d8_in[240:229]),
    .io_in_distribute_csr_w_bits_data(d8_in[228:165]),
    .io_in_frontend_trigger_tUpdate_valid(d8_in[164]),
    .io_in_frontend_trigger_tUpdate_bits_addr(d8_in[163:162]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_matchType(d8_in[161:160]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_select(d8_in[159]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_action(d8_in[158:155]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_chain(d8_in[154]),
    .io_in_frontend_trigger_tUpdate_bits_tdata_tdata2(d8_in[153:90]),
    .io_in_frontend_trigger_tEnableVec_0(d8_in[89]),
    .io_in_frontend_trigger_tEnableVec_1(d8_in[88]),
    .io_in_frontend_trigger_tEnableVec_2(d8_in[87]),
    .io_in_frontend_trigger_tEnableVec_3(d8_in[86]),
    .io_in_frontend_trigger_debugMode(d8_in[85]),
    .io_in_frontend_trigger_triggerCanRaiseBpExp(d8_in[84]),
    .io_in_mem_trigger_tUpdate_valid(d8_in[83]),
    .io_in_mem_trigger_tUpdate_bits_addr(d8_in[82:81]),
    .io_in_mem_trigger_tUpdate_bits_tdata_matchType(d8_in[80:79]),
    .io_in_mem_trigger_tUpdate_bits_tdata_select(d8_in[78]),
    .io_in_mem_trigger_tUpdate_bits_tdata_action(d8_in[77:74]),
    .io_in_mem_trigger_tUpdate_bits_tdata_chain(d8_in[73]),
    .io_in_mem_trigger_tUpdate_bits_tdata_store(d8_in[72]),
    .io_in_mem_trigger_tUpdate_bits_tdata_load(d8_in[71]),
    .io_in_mem_trigger_tUpdate_bits_tdata_tdata2(d8_in[70:7]),
    .io_in_mem_trigger_tEnableVec_0(d8_in[6]),
    .io_in_mem_trigger_tEnableVec_1(d8_in[5]),
    .io_in_mem_trigger_tEnableVec_2(d8_in[4]),
    .io_in_mem_trigger_tEnableVec_3(d8_in[3]),
    .io_in_mem_trigger_debugMode(d8_in[2]),
    .io_in_mem_trigger_triggerCanRaiseBpExp(d8_in[1]),
    .io_in_fsIsOff(d8_in[0]),
    .io_out_pf_ctrl_l1I_pf_enable(i_d8_out[273]),
    .io_out_bp_ctrl_ubtb_enable(i_d8_out[272]),
    .io_out_bp_ctrl_btb_enable(i_d8_out[271]),
    .io_out_bp_ctrl_tage_enable(i_d8_out[270]),
    .io_out_bp_ctrl_sc_enable(i_d8_out[269]),
    .io_out_bp_ctrl_ras_enable(i_d8_out[268]),
    .io_out_sbuffer_timeout(i_d8_out[267:246]),
    .io_out_ldld_vio_check_enable(i_d8_out[245]),
    .io_out_cache_error_enable(i_d8_out[244]),
    .io_out_hd_misalign_st_enable(i_d8_out[243]),
    .io_out_hd_misalign_ld_enable(i_d8_out[242]),
    .io_out_distribute_csr_w_valid(i_d8_out[241]),
    .io_out_distribute_csr_w_bits_addr(i_d8_out[240:229]),
    .io_out_distribute_csr_w_bits_data(i_d8_out[228:165]),
    .io_out_frontend_trigger_tUpdate_valid(i_d8_out[164]),
    .io_out_frontend_trigger_tUpdate_bits_addr(i_d8_out[163:162]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_matchType(i_d8_out[161:160]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_select(i_d8_out[159]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_action(i_d8_out[158:155]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_chain(i_d8_out[154]),
    .io_out_frontend_trigger_tUpdate_bits_tdata_tdata2(i_d8_out[153:90]),
    .io_out_frontend_trigger_tEnableVec_0(i_d8_out[89]),
    .io_out_frontend_trigger_tEnableVec_1(i_d8_out[88]),
    .io_out_frontend_trigger_tEnableVec_2(i_d8_out[87]),
    .io_out_frontend_trigger_tEnableVec_3(i_d8_out[86]),
    .io_out_frontend_trigger_debugMode(i_d8_out[85]),
    .io_out_frontend_trigger_triggerCanRaiseBpExp(i_d8_out[84]),
    .io_out_mem_trigger_tUpdate_valid(i_d8_out[83]),
    .io_out_mem_trigger_tUpdate_bits_addr(i_d8_out[82:81]),
    .io_out_mem_trigger_tUpdate_bits_tdata_matchType(i_d8_out[80:79]),
    .io_out_mem_trigger_tUpdate_bits_tdata_select(i_d8_out[78]),
    .io_out_mem_trigger_tUpdate_bits_tdata_action(i_d8_out[77:74]),
    .io_out_mem_trigger_tUpdate_bits_tdata_chain(i_d8_out[73]),
    .io_out_mem_trigger_tUpdate_bits_tdata_store(i_d8_out[72]),
    .io_out_mem_trigger_tUpdate_bits_tdata_load(i_d8_out[71]),
    .io_out_mem_trigger_tUpdate_bits_tdata_tdata2(i_d8_out[70:7]),
    .io_out_mem_trigger_tEnableVec_0(i_d8_out[6]),
    .io_out_mem_trigger_tEnableVec_1(i_d8_out[5]),
    .io_out_mem_trigger_tEnableVec_2(i_d8_out[4]),
    .io_out_mem_trigger_tEnableVec_3(i_d8_out[3]),
    .io_out_mem_trigger_debugMode(i_d8_out[2]),
    .io_out_mem_trigger_triggerCanRaiseBpExp(i_d8_out[1]),
    .io_out_fsIsOff(i_d8_out[0])
  );

  // ---- DelayN_9: 载荷 72 位 / 2 级 / 8 字段 ----
  logic [71:0] d9_in;
  wire  [71:0] g_d9_out;
  wire  [71:0] i_d9_out;
  logic [71:0] d9_ones, d9_zeros, d9_prev;
  int   d9_checks, d9_moves;
  DelayN_9 u_g_d9 (
    .clock(clock),
    .io_in_valid(d9_in[71]),
    .io_in_bits_rs1(d9_in[70]),
    .io_in_bits_rs2(d9_in[69]),
    .io_in_bits_addr(d9_in[68:19]),
    .io_in_bits_id(d9_in[18:3]),
    .io_in_bits_flushPipe(d9_in[2]),
    .io_in_bits_hv(d9_in[1]),
    .io_in_bits_hg(d9_in[0]),
    .io_out_valid(g_d9_out[71]),
    .io_out_bits_rs1(g_d9_out[70]),
    .io_out_bits_rs2(g_d9_out[69]),
    .io_out_bits_addr(g_d9_out[68:19]),
    .io_out_bits_id(g_d9_out[18:3]),
    .io_out_bits_flushPipe(g_d9_out[2]),
    .io_out_bits_hv(g_d9_out[1]),
    .io_out_bits_hg(g_d9_out[0])
  );
  DelayN_9_xs u_i_d9 (
    .clock(clock),
    .io_in_valid(d9_in[71]),
    .io_in_bits_rs1(d9_in[70]),
    .io_in_bits_rs2(d9_in[69]),
    .io_in_bits_addr(d9_in[68:19]),
    .io_in_bits_id(d9_in[18:3]),
    .io_in_bits_flushPipe(d9_in[2]),
    .io_in_bits_hv(d9_in[1]),
    .io_in_bits_hg(d9_in[0]),
    .io_out_valid(i_d9_out[71]),
    .io_out_bits_rs1(i_d9_out[70]),
    .io_out_bits_rs2(i_d9_out[69]),
    .io_out_bits_addr(i_d9_out[68:19]),
    .io_out_bits_id(i_d9_out[18:3]),
    .io_out_bits_flushPipe(i_d9_out[2]),
    .io_out_bits_hv(i_d9_out[1]),
    .io_out_bits_hg(i_d9_out[0])
  );

  // ---- DelayN_13: 载荷 1 位 / 1 级 / 1 字段 ----
  logic [0:0] d13_in;
  wire  [0:0] g_d13_out;
  wire  [0:0] i_d13_out;
  logic [0:0] d13_ones, d13_zeros, d13_prev;
  int   d13_checks, d13_moves;
  DelayN_13 u_g_d13 (
    .clock(clock),
    .io_in(d13_in[0]),
    .io_out(g_d13_out[0])
  );
  DelayN_13_xs u_i_d13 (
    .clock(clock),
    .io_in(d13_in[0]),
    .io_out(i_d13_out[0])
  );


  // 每拍随机选一种模式：全 0 / 全 1 / 逐位随机 —— 保证每一位都能被观察到 1 和 0
  task automatic drive_random_inputs();
    mode = $urandom_range(0, 7);
    case (mode)
      0:       d0_in = '0;
      1:       d0_in = '1;
      default: for (int b = 0; b < 5; b++) d0_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d1_in = '0;
      1:       d1_in = '1;
      default: for (int b = 0; b < 1; b++) d1_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d7_in = '0;
      1:       d7_in = '1;
      default: for (int b = 0; b < 219; b++) d7_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d8_in = '0;
      1:       d8_in = '1;
      default: for (int b = 0; b < 274; b++) d8_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d9_in = '0;
      1:       d9_in = '1;
      default: for (int b = 0; b < 72; b++) d9_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d13_in = '0;
      1:       d13_in = '1;
      default: for (int b = 0; b < 1; b++) d13_in[b] = 1'($urandom);
    endcase
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_d0_out)) begin
      checks++; d0_checks++;
      d0_ones  |= g_d0_out;
      d0_zeros |= ~g_d0_out;
      if (d0_prev !== g_d0_out) d0_moves++;
      d0_prev = g_d0_out;
      if (g_d0_out !== i_d0_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN g=%0h i=%0h", $time, g_d0_out, i_d0_out);
      end
    end
    if (!$isunknown(g_d1_out)) begin
      checks++; d1_checks++;
      d1_ones  |= g_d1_out;
      d1_zeros |= ~g_d1_out;
      if (d1_prev !== g_d1_out) d1_moves++;
      d1_prev = g_d1_out;
      if (g_d1_out !== i_d1_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_1 g=%0h i=%0h", $time, g_d1_out, i_d1_out);
      end
    end
    if (!$isunknown(g_d7_out)) begin
      checks++; d7_checks++;
      d7_ones  |= g_d7_out;
      d7_zeros |= ~g_d7_out;
      if (d7_prev !== g_d7_out) d7_moves++;
      d7_prev = g_d7_out;
      if (g_d7_out !== i_d7_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_7 g=%0h i=%0h", $time, g_d7_out, i_d7_out);
      end
    end
    if (!$isunknown(g_d8_out)) begin
      checks++; d8_checks++;
      d8_ones  |= g_d8_out;
      d8_zeros |= ~g_d8_out;
      if (d8_prev !== g_d8_out) d8_moves++;
      d8_prev = g_d8_out;
      if (g_d8_out !== i_d8_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_8 g=%0h i=%0h", $time, g_d8_out, i_d8_out);
      end
    end
    if (!$isunknown(g_d9_out)) begin
      checks++; d9_checks++;
      d9_ones  |= g_d9_out;
      d9_zeros |= ~g_d9_out;
      if (d9_prev !== g_d9_out) d9_moves++;
      d9_prev = g_d9_out;
      if (g_d9_out !== i_d9_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_9 g=%0h i=%0h", $time, g_d9_out, i_d9_out);
      end
    end
    if (!$isunknown(g_d13_out)) begin
      checks++; d13_checks++;
      d13_ones  |= g_d13_out;
      d13_zeros |= ~g_d13_out;
      if (d13_prev !== g_d13_out) d13_moves++;
      d13_prev = g_d13_out;
      if (g_d13_out !== i_d13_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_13 g=%0h i=%0h", $time, g_d13_out, i_d13_out);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    d0_in = '0; d0_ones = '0; d0_zeros = '0; d0_prev = 'x; d0_checks = 0; d0_moves = 0;
    d1_in = '0; d1_ones = '0; d1_zeros = '0; d1_prev = 'x; d1_checks = 0; d1_moves = 0;
    d7_in = '0; d7_ones = '0; d7_zeros = '0; d7_prev = 'x; d7_checks = 0; d7_moves = 0;
    d8_in = '0; d8_ones = '0; d8_zeros = '0; d8_prev = 'x; d8_checks = 0; d8_moves = 0;
    d9_in = '0; d9_ones = '0; d9_zeros = '0; d9_prev = 'x; d9_checks = 0; d9_moves = 0;
    d13_in = '0; d13_ones = '0; d13_zeros = '0; d13_prev = 'x; d13_checks = 0; d13_moves = 0;
    repeat (NCYCLES) begin
      @(negedge clock);   // 输出在 posedge 变，negedge 稳定：先比对上一拍结果，再换激励
      check_outputs();
      drive_random_inputs();
    end
    $display("DelayN family checks=%0d errors=%0d", checks, errors);
    $display("  DelayN: checks=%0d moves=%0d ones=%0d/5 zeros=%0d/5",
             d0_checks, d0_moves, $countones(d0_ones), $countones(d0_zeros));
    if (d0_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN 有效比对只有 %0d 次 (需 >= %0d)", d0_checks, COV_MIN);
      cov_fail++;
    end
    if (d0_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d0_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d0_ones) || !(&d0_zeros)) begin
      $display("COVERAGE FAIL: DelayN 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d0_ones, d0_zeros);
      cov_fail++;
    end
    $display("  DelayN_1: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d1_checks, d1_moves, $countones(d1_ones), $countones(d1_zeros));
    if (d1_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_1 有效比对只有 %0d 次 (需 >= %0d)", d1_checks, COV_MIN);
      cov_fail++;
    end
    if (d1_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_1 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d1_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d1_ones) || !(&d1_zeros)) begin
      $display("COVERAGE FAIL: DelayN_1 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d1_ones, d1_zeros);
      cov_fail++;
    end
    $display("  DelayN_7: checks=%0d moves=%0d ones=%0d/219 zeros=%0d/219",
             d7_checks, d7_moves, $countones(d7_ones), $countones(d7_zeros));
    if (d7_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_7 有效比对只有 %0d 次 (需 >= %0d)", d7_checks, COV_MIN);
      cov_fail++;
    end
    if (d7_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_7 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d7_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d7_ones) || !(&d7_zeros)) begin
      $display("COVERAGE FAIL: DelayN_7 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d7_ones, d7_zeros);
      cov_fail++;
    end
    $display("  DelayN_8: checks=%0d moves=%0d ones=%0d/274 zeros=%0d/274",
             d8_checks, d8_moves, $countones(d8_ones), $countones(d8_zeros));
    if (d8_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_8 有效比对只有 %0d 次 (需 >= %0d)", d8_checks, COV_MIN);
      cov_fail++;
    end
    if (d8_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_8 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d8_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d8_ones) || !(&d8_zeros)) begin
      $display("COVERAGE FAIL: DelayN_8 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d8_ones, d8_zeros);
      cov_fail++;
    end
    $display("  DelayN_9: checks=%0d moves=%0d ones=%0d/72 zeros=%0d/72",
             d9_checks, d9_moves, $countones(d9_ones), $countones(d9_zeros));
    if (d9_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_9 有效比对只有 %0d 次 (需 >= %0d)", d9_checks, COV_MIN);
      cov_fail++;
    end
    if (d9_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_9 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d9_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d9_ones) || !(&d9_zeros)) begin
      $display("COVERAGE FAIL: DelayN_9 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d9_ones, d9_zeros);
      cov_fail++;
    end
    $display("  DelayN_13: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d13_checks, d13_moves, $countones(d13_ones), $countones(d13_zeros));
    if (d13_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_13 有效比对只有 %0d 次 (需 >= %0d)", d13_checks, COV_MIN);
      cov_fail++;
    end
    if (d13_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_13 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d13_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d13_ones) || !(&d13_zeros)) begin
      $display("COVERAGE FAIL: DelayN_13 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d13_ones, d13_zeros);
      cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
