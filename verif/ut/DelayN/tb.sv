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

  // ---- DelayN_15: 载荷 1 位 / 4 级 / 1 字段 ----
  logic [0:0] d15_in;
  wire  [0:0] g_d15_out;
  wire  [0:0] i_d15_out;
  logic [0:0] d15_ones, d15_zeros, d15_prev;
  int   d15_checks, d15_moves;
  DelayN_15 u_g_d15 (
    .clock(clock),
    .io_in(d15_in[0]),
    .io_out(g_d15_out[0])
  );
  DelayN_15_xs u_i_d15 (
    .clock(clock),
    .io_in(d15_in[0]),
    .io_out(i_d15_out[0])
  );

  // ---- DelayN_17: 载荷 1 位 / 5 级 / 1 字段 ----
  logic [0:0] d17_in;
  wire  [0:0] g_d17_out;
  wire  [0:0] i_d17_out;
  logic [0:0] d17_ones, d17_zeros, d17_prev;
  int   d17_checks, d17_moves;
  DelayN_17 u_g_d17 (
    .clock(clock),
    .io_in(d17_in[0]),
    .io_out(g_d17_out[0])
  );
  DelayN_17_xs u_i_d17 (
    .clock(clock),
    .io_in(d17_in[0]),
    .io_out(i_d17_out[0])
  );

  // ---- DelayN_208: 载荷 8 位 / 5 级 / 1 字段 ----
  logic [7:0] d208_in;
  wire  [7:0] g_d208_out;
  wire  [7:0] i_d208_out;
  logic [7:0] d208_ones, d208_zeros, d208_prev;
  int   d208_checks, d208_moves;
  DelayN_208 u_g_d208 (
    .clock(clock),
    .io_in(d208_in[7:0]),
    .io_out(g_d208_out[7:0])
  );
  DelayN_208_xs u_i_d208 (
    .clock(clock),
    .io_in(d208_in[7:0]),
    .io_out(i_d208_out[7:0])
  );

  // ---- DelayN_214: 载荷 183 位 / 2 级 / 37 字段 ----
  logic [182:0] d214_in;
  wire  [182:0] g_d214_out;
  wire  [182:0] i_d214_out;
  logic [182:0] d214_ones, d214_zeros, d214_prev;
  int   d214_checks, d214_moves;
  DelayN_214 u_g_d214 (
    .clock(clock),
    .io_in_valid(d214_in[182]),
    .io_in_bits_pc(d214_in[181:132]),
    .io_in_bits_instr(d214_in[131:100]),
    .io_in_bits_exceptionVec_0(d214_in[99]),
    .io_in_bits_exceptionVec_1(d214_in[98]),
    .io_in_bits_exceptionVec_2(d214_in[97]),
    .io_in_bits_exceptionVec_3(d214_in[96]),
    .io_in_bits_exceptionVec_4(d214_in[95]),
    .io_in_bits_exceptionVec_5(d214_in[94]),
    .io_in_bits_exceptionVec_6(d214_in[93]),
    .io_in_bits_exceptionVec_7(d214_in[92]),
    .io_in_bits_exceptionVec_8(d214_in[91]),
    .io_in_bits_exceptionVec_9(d214_in[90]),
    .io_in_bits_exceptionVec_10(d214_in[89]),
    .io_in_bits_exceptionVec_11(d214_in[88]),
    .io_in_bits_exceptionVec_12(d214_in[87]),
    .io_in_bits_exceptionVec_13(d214_in[86]),
    .io_in_bits_exceptionVec_14(d214_in[85]),
    .io_in_bits_exceptionVec_15(d214_in[84]),
    .io_in_bits_exceptionVec_16(d214_in[83]),
    .io_in_bits_exceptionVec_17(d214_in[82]),
    .io_in_bits_exceptionVec_18(d214_in[81]),
    .io_in_bits_exceptionVec_19(d214_in[80]),
    .io_in_bits_exceptionVec_20(d214_in[79]),
    .io_in_bits_exceptionVec_21(d214_in[78]),
    .io_in_bits_exceptionVec_22(d214_in[77]),
    .io_in_bits_exceptionVec_23(d214_in[76]),
    .io_in_bits_isPcBkpt(d214_in[75]),
    .io_in_bits_isFetchMalAddr(d214_in[74]),
    .io_in_bits_satpFlushFirstFetchFault(d214_in[73]),
    .io_in_bits_gpaddr(d214_in[72:9]),
    .io_in_bits_singleStep(d214_in[8]),
    .io_in_bits_crossPageIPFFix(d214_in[7]),
    .io_in_bits_isInterrupt(d214_in[6]),
    .io_in_bits_isHls(d214_in[5]),
    .io_in_bits_trigger(d214_in[4:1]),
    .io_in_bits_isForVSnonLeafPTE(d214_in[0]),
    .io_out_valid(g_d214_out[182]),
    .io_out_bits_pc(g_d214_out[181:132]),
    .io_out_bits_instr(g_d214_out[131:100]),
    .io_out_bits_exceptionVec_0(g_d214_out[99]),
    .io_out_bits_exceptionVec_1(g_d214_out[98]),
    .io_out_bits_exceptionVec_2(g_d214_out[97]),
    .io_out_bits_exceptionVec_3(g_d214_out[96]),
    .io_out_bits_exceptionVec_4(g_d214_out[95]),
    .io_out_bits_exceptionVec_5(g_d214_out[94]),
    .io_out_bits_exceptionVec_6(g_d214_out[93]),
    .io_out_bits_exceptionVec_7(g_d214_out[92]),
    .io_out_bits_exceptionVec_8(g_d214_out[91]),
    .io_out_bits_exceptionVec_9(g_d214_out[90]),
    .io_out_bits_exceptionVec_10(g_d214_out[89]),
    .io_out_bits_exceptionVec_11(g_d214_out[88]),
    .io_out_bits_exceptionVec_12(g_d214_out[87]),
    .io_out_bits_exceptionVec_13(g_d214_out[86]),
    .io_out_bits_exceptionVec_14(g_d214_out[85]),
    .io_out_bits_exceptionVec_15(g_d214_out[84]),
    .io_out_bits_exceptionVec_16(g_d214_out[83]),
    .io_out_bits_exceptionVec_17(g_d214_out[82]),
    .io_out_bits_exceptionVec_18(g_d214_out[81]),
    .io_out_bits_exceptionVec_19(g_d214_out[80]),
    .io_out_bits_exceptionVec_20(g_d214_out[79]),
    .io_out_bits_exceptionVec_21(g_d214_out[78]),
    .io_out_bits_exceptionVec_22(g_d214_out[77]),
    .io_out_bits_exceptionVec_23(g_d214_out[76]),
    .io_out_bits_isPcBkpt(g_d214_out[75]),
    .io_out_bits_isFetchMalAddr(g_d214_out[74]),
    .io_out_bits_satpFlushFirstFetchFault(g_d214_out[73]),
    .io_out_bits_gpaddr(g_d214_out[72:9]),
    .io_out_bits_singleStep(g_d214_out[8]),
    .io_out_bits_crossPageIPFFix(g_d214_out[7]),
    .io_out_bits_isInterrupt(g_d214_out[6]),
    .io_out_bits_isHls(g_d214_out[5]),
    .io_out_bits_trigger(g_d214_out[4:1]),
    .io_out_bits_isForVSnonLeafPTE(g_d214_out[0])
  );
  DelayN_214_xs u_i_d214 (
    .clock(clock),
    .io_in_valid(d214_in[182]),
    .io_in_bits_pc(d214_in[181:132]),
    .io_in_bits_instr(d214_in[131:100]),
    .io_in_bits_exceptionVec_0(d214_in[99]),
    .io_in_bits_exceptionVec_1(d214_in[98]),
    .io_in_bits_exceptionVec_2(d214_in[97]),
    .io_in_bits_exceptionVec_3(d214_in[96]),
    .io_in_bits_exceptionVec_4(d214_in[95]),
    .io_in_bits_exceptionVec_5(d214_in[94]),
    .io_in_bits_exceptionVec_6(d214_in[93]),
    .io_in_bits_exceptionVec_7(d214_in[92]),
    .io_in_bits_exceptionVec_8(d214_in[91]),
    .io_in_bits_exceptionVec_9(d214_in[90]),
    .io_in_bits_exceptionVec_10(d214_in[89]),
    .io_in_bits_exceptionVec_11(d214_in[88]),
    .io_in_bits_exceptionVec_12(d214_in[87]),
    .io_in_bits_exceptionVec_13(d214_in[86]),
    .io_in_bits_exceptionVec_14(d214_in[85]),
    .io_in_bits_exceptionVec_15(d214_in[84]),
    .io_in_bits_exceptionVec_16(d214_in[83]),
    .io_in_bits_exceptionVec_17(d214_in[82]),
    .io_in_bits_exceptionVec_18(d214_in[81]),
    .io_in_bits_exceptionVec_19(d214_in[80]),
    .io_in_bits_exceptionVec_20(d214_in[79]),
    .io_in_bits_exceptionVec_21(d214_in[78]),
    .io_in_bits_exceptionVec_22(d214_in[77]),
    .io_in_bits_exceptionVec_23(d214_in[76]),
    .io_in_bits_isPcBkpt(d214_in[75]),
    .io_in_bits_isFetchMalAddr(d214_in[74]),
    .io_in_bits_satpFlushFirstFetchFault(d214_in[73]),
    .io_in_bits_gpaddr(d214_in[72:9]),
    .io_in_bits_singleStep(d214_in[8]),
    .io_in_bits_crossPageIPFFix(d214_in[7]),
    .io_in_bits_isInterrupt(d214_in[6]),
    .io_in_bits_isHls(d214_in[5]),
    .io_in_bits_trigger(d214_in[4:1]),
    .io_in_bits_isForVSnonLeafPTE(d214_in[0]),
    .io_out_valid(i_d214_out[182]),
    .io_out_bits_pc(i_d214_out[181:132]),
    .io_out_bits_instr(i_d214_out[131:100]),
    .io_out_bits_exceptionVec_0(i_d214_out[99]),
    .io_out_bits_exceptionVec_1(i_d214_out[98]),
    .io_out_bits_exceptionVec_2(i_d214_out[97]),
    .io_out_bits_exceptionVec_3(i_d214_out[96]),
    .io_out_bits_exceptionVec_4(i_d214_out[95]),
    .io_out_bits_exceptionVec_5(i_d214_out[94]),
    .io_out_bits_exceptionVec_6(i_d214_out[93]),
    .io_out_bits_exceptionVec_7(i_d214_out[92]),
    .io_out_bits_exceptionVec_8(i_d214_out[91]),
    .io_out_bits_exceptionVec_9(i_d214_out[90]),
    .io_out_bits_exceptionVec_10(i_d214_out[89]),
    .io_out_bits_exceptionVec_11(i_d214_out[88]),
    .io_out_bits_exceptionVec_12(i_d214_out[87]),
    .io_out_bits_exceptionVec_13(i_d214_out[86]),
    .io_out_bits_exceptionVec_14(i_d214_out[85]),
    .io_out_bits_exceptionVec_15(i_d214_out[84]),
    .io_out_bits_exceptionVec_16(i_d214_out[83]),
    .io_out_bits_exceptionVec_17(i_d214_out[82]),
    .io_out_bits_exceptionVec_18(i_d214_out[81]),
    .io_out_bits_exceptionVec_19(i_d214_out[80]),
    .io_out_bits_exceptionVec_20(i_d214_out[79]),
    .io_out_bits_exceptionVec_21(i_d214_out[78]),
    .io_out_bits_exceptionVec_22(i_d214_out[77]),
    .io_out_bits_exceptionVec_23(i_d214_out[76]),
    .io_out_bits_isPcBkpt(i_d214_out[75]),
    .io_out_bits_isFetchMalAddr(i_d214_out[74]),
    .io_out_bits_satpFlushFirstFetchFault(i_d214_out[73]),
    .io_out_bits_gpaddr(i_d214_out[72:9]),
    .io_out_bits_singleStep(i_d214_out[8]),
    .io_out_bits_crossPageIPFFix(i_d214_out[7]),
    .io_out_bits_isInterrupt(i_d214_out[6]),
    .io_out_bits_isHls(i_d214_out[5]),
    .io_out_bits_trigger(i_d214_out[4:1]),
    .io_out_bits_isForVSnonLeafPTE(i_d214_out[0])
  );

  // ---- DelayN_215: 载荷 9 位 / 2 级 / 2 字段 ----
  logic [8:0] d215_in;
  wire  [8:0] g_d215_out;
  wire  [8:0] i_d215_out;
  logic [8:0] d215_ones, d215_zeros, d215_prev;
  int   d215_checks, d215_moves;
  DelayN_215 u_g_d215 (
    .clock(clock),
    .io_in_flag(d215_in[8]),
    .io_in_value(d215_in[7:0]),
    .io_out_flag(g_d215_out[8]),
    .io_out_value(g_d215_out[7:0])
  );
  DelayN_215_xs u_i_d215 (
    .clock(clock),
    .io_in_flag(d215_in[8]),
    .io_in_value(d215_in[7:0]),
    .io_out_flag(i_d215_out[8]),
    .io_out_value(i_d215_out[7:0])
  );

  // ---- DelayN_220: 载荷 71 位 / 1 级 / 7 字段 ----
  logic [70:0] d220_in;
  wire  [70:0] g_d220_out;
  wire  [70:0] i_d220_out;
  logic [70:0] d220_ones, d220_zeros, d220_prev;
  int   d220_checks, d220_moves;
  DelayN_220 u_g_d220 (
    .clock(clock),
    .io_in_valid(d220_in[70]),
    .io_in_bits_rs1(d220_in[69]),
    .io_in_bits_rs2(d220_in[68]),
    .io_in_bits_addr(d220_in[67:18]),
    .io_in_bits_id(d220_in[17:2]),
    .io_in_bits_hv(d220_in[1]),
    .io_in_bits_hg(d220_in[0]),
    .io_out_valid(g_d220_out[70]),
    .io_out_bits_rs1(g_d220_out[69]),
    .io_out_bits_rs2(g_d220_out[68]),
    .io_out_bits_addr(g_d220_out[67:18]),
    .io_out_bits_id(g_d220_out[17:2]),
    .io_out_bits_hv(g_d220_out[1]),
    .io_out_bits_hg(g_d220_out[0])
  );
  DelayN_220_xs u_i_d220 (
    .clock(clock),
    .io_in_valid(d220_in[70]),
    .io_in_bits_rs1(d220_in[69]),
    .io_in_bits_rs2(d220_in[68]),
    .io_in_bits_addr(d220_in[67:18]),
    .io_in_bits_id(d220_in[17:2]),
    .io_in_bits_hv(d220_in[1]),
    .io_in_bits_hg(d220_in[0]),
    .io_out_valid(i_d220_out[70]),
    .io_out_bits_rs1(i_d220_out[69]),
    .io_out_bits_rs2(i_d220_out[68]),
    .io_out_bits_addr(i_d220_out[67:18]),
    .io_out_bits_id(i_d220_out[17:2]),
    .io_out_bits_hv(i_d220_out[1]),
    .io_out_bits_hg(i_d220_out[0])
  );

  // ---- DelayN_221: 载荷 261 位 / 1 级 / 21 字段 ----
  logic [260:0] d221_in;
  wire  [260:0] g_d221_out;
  wire  [260:0] i_d221_out;
  logic [260:0] d221_ones, d221_zeros, d221_prev;
  int   d221_checks, d221_moves;
  DelayN_221 u_g_d221 (
    .clock(clock),
    .io_in_satp_mode(d221_in[260:257]),
    .io_in_satp_asid(d221_in[256:241]),
    .io_in_satp_ppn(d221_in[240:197]),
    .io_in_satp_changed(d221_in[196]),
    .io_in_vsatp_mode(d221_in[195:192]),
    .io_in_vsatp_asid(d221_in[191:176]),
    .io_in_vsatp_ppn(d221_in[175:132]),
    .io_in_vsatp_changed(d221_in[131]),
    .io_in_hgatp_mode(d221_in[130:127]),
    .io_in_hgatp_vmid(d221_in[126:111]),
    .io_in_hgatp_ppn(d221_in[110:67]),
    .io_in_hgatp_changed(d221_in[66]),
    .io_in_mbmc_BME(d221_in[65]),
    .io_in_mbmc_CMODE(d221_in[64]),
    .io_in_mbmc_BCLEAR(d221_in[63]),
    .io_in_mbmc_BMA(d221_in[62:5]),
    .io_in_priv_virt(d221_in[4]),
    .io_in_priv_virt_changed(d221_in[3]),
    .io_in_priv_debug(d221_in[2]),
    .io_in_mPBMTE(d221_in[1]),
    .io_in_hPBMTE(d221_in[0]),
    .io_out_satp_mode(g_d221_out[260:257]),
    .io_out_satp_asid(g_d221_out[256:241]),
    .io_out_satp_ppn(g_d221_out[240:197]),
    .io_out_satp_changed(g_d221_out[196]),
    .io_out_vsatp_mode(g_d221_out[195:192]),
    .io_out_vsatp_asid(g_d221_out[191:176]),
    .io_out_vsatp_ppn(g_d221_out[175:132]),
    .io_out_vsatp_changed(g_d221_out[131]),
    .io_out_hgatp_mode(g_d221_out[130:127]),
    .io_out_hgatp_vmid(g_d221_out[126:111]),
    .io_out_hgatp_ppn(g_d221_out[110:67]),
    .io_out_hgatp_changed(g_d221_out[66]),
    .io_out_mbmc_BME(g_d221_out[65]),
    .io_out_mbmc_CMODE(g_d221_out[64]),
    .io_out_mbmc_BCLEAR(g_d221_out[63]),
    .io_out_mbmc_BMA(g_d221_out[62:5]),
    .io_out_priv_virt(g_d221_out[4]),
    .io_out_priv_virt_changed(g_d221_out[3]),
    .io_out_priv_debug(g_d221_out[2]),
    .io_out_mPBMTE(g_d221_out[1]),
    .io_out_hPBMTE(g_d221_out[0])
  );
  DelayN_221_xs u_i_d221 (
    .clock(clock),
    .io_in_satp_mode(d221_in[260:257]),
    .io_in_satp_asid(d221_in[256:241]),
    .io_in_satp_ppn(d221_in[240:197]),
    .io_in_satp_changed(d221_in[196]),
    .io_in_vsatp_mode(d221_in[195:192]),
    .io_in_vsatp_asid(d221_in[191:176]),
    .io_in_vsatp_ppn(d221_in[175:132]),
    .io_in_vsatp_changed(d221_in[131]),
    .io_in_hgatp_mode(d221_in[130:127]),
    .io_in_hgatp_vmid(d221_in[126:111]),
    .io_in_hgatp_ppn(d221_in[110:67]),
    .io_in_hgatp_changed(d221_in[66]),
    .io_in_mbmc_BME(d221_in[65]),
    .io_in_mbmc_CMODE(d221_in[64]),
    .io_in_mbmc_BCLEAR(d221_in[63]),
    .io_in_mbmc_BMA(d221_in[62:5]),
    .io_in_priv_virt(d221_in[4]),
    .io_in_priv_virt_changed(d221_in[3]),
    .io_in_priv_debug(d221_in[2]),
    .io_in_mPBMTE(d221_in[1]),
    .io_in_hPBMTE(d221_in[0]),
    .io_out_satp_mode(i_d221_out[260:257]),
    .io_out_satp_asid(i_d221_out[256:241]),
    .io_out_satp_ppn(i_d221_out[240:197]),
    .io_out_satp_changed(i_d221_out[196]),
    .io_out_vsatp_mode(i_d221_out[195:192]),
    .io_out_vsatp_asid(i_d221_out[191:176]),
    .io_out_vsatp_ppn(i_d221_out[175:132]),
    .io_out_vsatp_changed(i_d221_out[131]),
    .io_out_hgatp_mode(i_d221_out[130:127]),
    .io_out_hgatp_vmid(i_d221_out[126:111]),
    .io_out_hgatp_ppn(i_d221_out[110:67]),
    .io_out_hgatp_changed(i_d221_out[66]),
    .io_out_mbmc_BME(i_d221_out[65]),
    .io_out_mbmc_CMODE(i_d221_out[64]),
    .io_out_mbmc_BCLEAR(i_d221_out[63]),
    .io_out_mbmc_BMA(i_d221_out[62:5]),
    .io_out_priv_virt(i_d221_out[4]),
    .io_out_priv_virt_changed(i_d221_out[3]),
    .io_out_priv_debug(i_d221_out[2]),
    .io_out_mPBMTE(i_d221_out[1]),
    .io_out_hPBMTE(i_d221_out[0])
  );

  // ---- DelayN_225: 载荷 1 位 / 0 级 / 1 字段 ----
  logic [0:0] d225_in;
  wire  [0:0] g_d225_out;
  wire  [0:0] i_d225_out;
  logic [0:0] d225_ones, d225_zeros, d225_prev;
  int   d225_checks, d225_moves;
  DelayN_225 u_g_d225 (
    .io_in(d225_in[0]),
    .io_out(g_d225_out[0])
  );
  DelayN_225_xs u_i_d225 (
    .io_in(d225_in[0]),
    .io_out(i_d225_out[0])
  );

  // ---- DelayN_297: 载荷 1 位 / 3 级 / 1 字段 ----
  logic [0:0] d297_in;
  wire  [0:0] g_d297_out;
  wire  [0:0] i_d297_out;
  logic [0:0] d297_ones, d297_zeros, d297_prev;
  int   d297_checks, d297_moves;
  DelayN_297 u_g_d297 (
    .clock(clock),
    .io_in(d297_in[0]),
    .io_out(g_d297_out[0])
  );
  DelayN_297_xs u_i_d297 (
    .clock(clock),
    .io_in(d297_in[0]),
    .io_out(i_d297_out[0])
  );

  // ---- DelayN_331: 载荷 1 位 / 10 级 / 1 字段 ----
  logic [0:0] d331_in;
  wire  [0:0] g_d331_out;
  wire  [0:0] i_d331_out;
  logic [0:0] d331_ones, d331_zeros, d331_prev;
  int   d331_checks, d331_moves;
  DelayN_331 u_g_d331 (
    .clock(clock),
    .io_in(d331_in[0]),
    .io_out(g_d331_out[0])
  );
  DelayN_331_xs u_i_d331 (
    .clock(clock),
    .io_in(d331_in[0]),
    .io_out(i_d331_out[0])
  );

  // ---- DelayN_333: 载荷 14 位 / 2 级 / 5 字段 ----
  logic [13:0] d333_in;
  wire  [13:0] g_d333_out;
  wire  [13:0] i_d333_out;
  logic [13:0] d333_ones, d333_zeros, d333_prev;
  int   d333_checks, d333_moves;
  DelayN_333 u_g_d333 (
    .clock(clock),
    .io_in_l2_pf_master_en(d333_in[13]),
    .io_in_l2_pf_recv_en(d333_in[12]),
    .io_in_l2_pbop_en(d333_in[11]),
    .io_in_l2_vbop_en(d333_in[10]),
    .io_in_l2_pf_delay_latency(d333_in[9:0]),
    .io_out_l2_pf_master_en(g_d333_out[13]),
    .io_out_l2_pf_recv_en(g_d333_out[12]),
    .io_out_l2_pbop_en(g_d333_out[11]),
    .io_out_l2_vbop_en(g_d333_out[10]),
    .io_out_l2_pf_delay_latency(g_d333_out[9:0])
  );
  DelayN_333_xs u_i_d333 (
    .clock(clock),
    .io_in_l2_pf_master_en(d333_in[13]),
    .io_in_l2_pf_recv_en(d333_in[12]),
    .io_in_l2_pbop_en(d333_in[11]),
    .io_in_l2_vbop_en(d333_in[10]),
    .io_in_l2_pf_delay_latency(d333_in[9:0]),
    .io_out_l2_pf_master_en(i_d333_out[13]),
    .io_out_l2_pf_recv_en(i_d333_out[12]),
    .io_out_l2_pbop_en(i_d333_out[11]),
    .io_out_l2_vbop_en(i_d333_out[10]),
    .io_out_l2_pf_delay_latency(i_d333_out[9:0])
  );

  // ---- DelayN_334: 载荷 48 位 / 5 级 / 1 字段 ----
  logic [47:0] d334_in;
  wire  [47:0] g_d334_out;
  wire  [47:0] i_d334_out;
  logic [47:0] d334_ones, d334_zeros, d334_prev;
  int   d334_checks, d334_moves;
  DelayN_334 u_g_d334 (
    .clock(clock),
    .io_in(d334_in[47:0]),
    .io_out(g_d334_out[47:0])
  );
  DelayN_334_xs u_i_d334 (
    .clock(clock),
    .io_in(d334_in[47:0]),
    .io_out(i_d334_out[47:0])
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
    case (mode)
      0:       d15_in = '0;
      1:       d15_in = '1;
      default: for (int b = 0; b < 1; b++) d15_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d17_in = '0;
      1:       d17_in = '1;
      default: for (int b = 0; b < 1; b++) d17_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d208_in = '0;
      1:       d208_in = '1;
      default: for (int b = 0; b < 8; b++) d208_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d214_in = '0;
      1:       d214_in = '1;
      default: for (int b = 0; b < 183; b++) d214_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d215_in = '0;
      1:       d215_in = '1;
      default: for (int b = 0; b < 9; b++) d215_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d220_in = '0;
      1:       d220_in = '1;
      default: for (int b = 0; b < 71; b++) d220_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d221_in = '0;
      1:       d221_in = '1;
      default: for (int b = 0; b < 261; b++) d221_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d225_in = '0;
      1:       d225_in = '1;
      default: for (int b = 0; b < 1; b++) d225_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d297_in = '0;
      1:       d297_in = '1;
      default: for (int b = 0; b < 1; b++) d297_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d331_in = '0;
      1:       d331_in = '1;
      default: for (int b = 0; b < 1; b++) d331_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d333_in = '0;
      1:       d333_in = '1;
      default: for (int b = 0; b < 14; b++) d333_in[b] = 1'($urandom);
    endcase
    case (mode)
      0:       d334_in = '0;
      1:       d334_in = '1;
      default: for (int b = 0; b < 48; b++) d334_in[b] = 1'($urandom);
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
    if (!$isunknown(g_d15_out)) begin
      checks++; d15_checks++;
      d15_ones  |= g_d15_out;
      d15_zeros |= ~g_d15_out;
      if (d15_prev !== g_d15_out) d15_moves++;
      d15_prev = g_d15_out;
      if (g_d15_out !== i_d15_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_15 g=%0h i=%0h", $time, g_d15_out, i_d15_out);
      end
    end
    if (!$isunknown(g_d17_out)) begin
      checks++; d17_checks++;
      d17_ones  |= g_d17_out;
      d17_zeros |= ~g_d17_out;
      if (d17_prev !== g_d17_out) d17_moves++;
      d17_prev = g_d17_out;
      if (g_d17_out !== i_d17_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_17 g=%0h i=%0h", $time, g_d17_out, i_d17_out);
      end
    end
    if (!$isunknown(g_d208_out)) begin
      checks++; d208_checks++;
      d208_ones  |= g_d208_out;
      d208_zeros |= ~g_d208_out;
      if (d208_prev !== g_d208_out) d208_moves++;
      d208_prev = g_d208_out;
      if (g_d208_out !== i_d208_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_208 g=%0h i=%0h", $time, g_d208_out, i_d208_out);
      end
    end
    if (!$isunknown(g_d214_out)) begin
      checks++; d214_checks++;
      d214_ones  |= g_d214_out;
      d214_zeros |= ~g_d214_out;
      if (d214_prev !== g_d214_out) d214_moves++;
      d214_prev = g_d214_out;
      if (g_d214_out !== i_d214_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_214 g=%0h i=%0h", $time, g_d214_out, i_d214_out);
      end
    end
    if (!$isunknown(g_d215_out)) begin
      checks++; d215_checks++;
      d215_ones  |= g_d215_out;
      d215_zeros |= ~g_d215_out;
      if (d215_prev !== g_d215_out) d215_moves++;
      d215_prev = g_d215_out;
      if (g_d215_out !== i_d215_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_215 g=%0h i=%0h", $time, g_d215_out, i_d215_out);
      end
    end
    if (!$isunknown(g_d220_out)) begin
      checks++; d220_checks++;
      d220_ones  |= g_d220_out;
      d220_zeros |= ~g_d220_out;
      if (d220_prev !== g_d220_out) d220_moves++;
      d220_prev = g_d220_out;
      if (g_d220_out !== i_d220_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_220 g=%0h i=%0h", $time, g_d220_out, i_d220_out);
      end
    end
    if (!$isunknown(g_d221_out)) begin
      checks++; d221_checks++;
      d221_ones  |= g_d221_out;
      d221_zeros |= ~g_d221_out;
      if (d221_prev !== g_d221_out) d221_moves++;
      d221_prev = g_d221_out;
      if (g_d221_out !== i_d221_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_221 g=%0h i=%0h", $time, g_d221_out, i_d221_out);
      end
    end
    if (!$isunknown(g_d225_out)) begin
      checks++; d225_checks++;
      d225_ones  |= g_d225_out;
      d225_zeros |= ~g_d225_out;
      if (d225_prev !== g_d225_out) d225_moves++;
      d225_prev = g_d225_out;
      if (g_d225_out !== i_d225_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_225 g=%0h i=%0h", $time, g_d225_out, i_d225_out);
      end
    end
    if (!$isunknown(g_d297_out)) begin
      checks++; d297_checks++;
      d297_ones  |= g_d297_out;
      d297_zeros |= ~g_d297_out;
      if (d297_prev !== g_d297_out) d297_moves++;
      d297_prev = g_d297_out;
      if (g_d297_out !== i_d297_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_297 g=%0h i=%0h", $time, g_d297_out, i_d297_out);
      end
    end
    if (!$isunknown(g_d331_out)) begin
      checks++; d331_checks++;
      d331_ones  |= g_d331_out;
      d331_zeros |= ~g_d331_out;
      if (d331_prev !== g_d331_out) d331_moves++;
      d331_prev = g_d331_out;
      if (g_d331_out !== i_d331_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_331 g=%0h i=%0h", $time, g_d331_out, i_d331_out);
      end
    end
    if (!$isunknown(g_d333_out)) begin
      checks++; d333_checks++;
      d333_ones  |= g_d333_out;
      d333_zeros |= ~g_d333_out;
      if (d333_prev !== g_d333_out) d333_moves++;
      d333_prev = g_d333_out;
      if (g_d333_out !== i_d333_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_333 g=%0h i=%0h", $time, g_d333_out, i_d333_out);
      end
    end
    if (!$isunknown(g_d334_out)) begin
      checks++; d334_checks++;
      d334_ones  |= g_d334_out;
      d334_zeros |= ~g_d334_out;
      if (d334_prev !== g_d334_out) d334_moves++;
      d334_prev = g_d334_out;
      if (g_d334_out !== i_d334_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayN_334 g=%0h i=%0h", $time, g_d334_out, i_d334_out);
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
    d15_in = '0; d15_ones = '0; d15_zeros = '0; d15_prev = 'x; d15_checks = 0; d15_moves = 0;
    d17_in = '0; d17_ones = '0; d17_zeros = '0; d17_prev = 'x; d17_checks = 0; d17_moves = 0;
    d208_in = '0; d208_ones = '0; d208_zeros = '0; d208_prev = 'x; d208_checks = 0; d208_moves = 0;
    d214_in = '0; d214_ones = '0; d214_zeros = '0; d214_prev = 'x; d214_checks = 0; d214_moves = 0;
    d215_in = '0; d215_ones = '0; d215_zeros = '0; d215_prev = 'x; d215_checks = 0; d215_moves = 0;
    d220_in = '0; d220_ones = '0; d220_zeros = '0; d220_prev = 'x; d220_checks = 0; d220_moves = 0;
    d221_in = '0; d221_ones = '0; d221_zeros = '0; d221_prev = 'x; d221_checks = 0; d221_moves = 0;
    d225_in = '0; d225_ones = '0; d225_zeros = '0; d225_prev = 'x; d225_checks = 0; d225_moves = 0;
    d297_in = '0; d297_ones = '0; d297_zeros = '0; d297_prev = 'x; d297_checks = 0; d297_moves = 0;
    d331_in = '0; d331_ones = '0; d331_zeros = '0; d331_prev = 'x; d331_checks = 0; d331_moves = 0;
    d333_in = '0; d333_ones = '0; d333_zeros = '0; d333_prev = 'x; d333_checks = 0; d333_moves = 0;
    d334_in = '0; d334_ones = '0; d334_zeros = '0; d334_prev = 'x; d334_checks = 0; d334_moves = 0;
    repeat (NCYCLES) begin
      @(negedge clock);   // 输出在 posedge 变，negedge 稳定：先比对上一拍结果，再换激励
      check_outputs();
      drive_random_inputs();
    end
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
    $display("  DelayN_15: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d15_checks, d15_moves, $countones(d15_ones), $countones(d15_zeros));
    if (d15_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_15 有效比对只有 %0d 次 (需 >= %0d)", d15_checks, COV_MIN);
      cov_fail++;
    end
    if (d15_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_15 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d15_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d15_ones) || !(&d15_zeros)) begin
      $display("COVERAGE FAIL: DelayN_15 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d15_ones, d15_zeros);
      cov_fail++;
    end
    $display("  DelayN_17: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d17_checks, d17_moves, $countones(d17_ones), $countones(d17_zeros));
    if (d17_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_17 有效比对只有 %0d 次 (需 >= %0d)", d17_checks, COV_MIN);
      cov_fail++;
    end
    if (d17_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_17 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d17_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d17_ones) || !(&d17_zeros)) begin
      $display("COVERAGE FAIL: DelayN_17 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d17_ones, d17_zeros);
      cov_fail++;
    end
    $display("  DelayN_208: checks=%0d moves=%0d ones=%0d/8 zeros=%0d/8",
             d208_checks, d208_moves, $countones(d208_ones), $countones(d208_zeros));
    if (d208_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_208 有效比对只有 %0d 次 (需 >= %0d)", d208_checks, COV_MIN);
      cov_fail++;
    end
    if (d208_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_208 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d208_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d208_ones) || !(&d208_zeros)) begin
      $display("COVERAGE FAIL: DelayN_208 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d208_ones, d208_zeros);
      cov_fail++;
    end
    $display("  DelayN_214: checks=%0d moves=%0d ones=%0d/183 zeros=%0d/183",
             d214_checks, d214_moves, $countones(d214_ones), $countones(d214_zeros));
    if (d214_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_214 有效比对只有 %0d 次 (需 >= %0d)", d214_checks, COV_MIN);
      cov_fail++;
    end
    if (d214_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_214 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d214_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d214_ones) || !(&d214_zeros)) begin
      $display("COVERAGE FAIL: DelayN_214 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d214_ones, d214_zeros);
      cov_fail++;
    end
    $display("  DelayN_215: checks=%0d moves=%0d ones=%0d/9 zeros=%0d/9",
             d215_checks, d215_moves, $countones(d215_ones), $countones(d215_zeros));
    if (d215_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_215 有效比对只有 %0d 次 (需 >= %0d)", d215_checks, COV_MIN);
      cov_fail++;
    end
    if (d215_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_215 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d215_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d215_ones) || !(&d215_zeros)) begin
      $display("COVERAGE FAIL: DelayN_215 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d215_ones, d215_zeros);
      cov_fail++;
    end
    $display("  DelayN_220: checks=%0d moves=%0d ones=%0d/71 zeros=%0d/71",
             d220_checks, d220_moves, $countones(d220_ones), $countones(d220_zeros));
    if (d220_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_220 有效比对只有 %0d 次 (需 >= %0d)", d220_checks, COV_MIN);
      cov_fail++;
    end
    if (d220_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_220 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d220_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d220_ones) || !(&d220_zeros)) begin
      $display("COVERAGE FAIL: DelayN_220 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d220_ones, d220_zeros);
      cov_fail++;
    end
    $display("  DelayN_221: checks=%0d moves=%0d ones=%0d/261 zeros=%0d/261",
             d221_checks, d221_moves, $countones(d221_ones), $countones(d221_zeros));
    if (d221_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_221 有效比对只有 %0d 次 (需 >= %0d)", d221_checks, COV_MIN);
      cov_fail++;
    end
    if (d221_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_221 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d221_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d221_ones) || !(&d221_zeros)) begin
      $display("COVERAGE FAIL: DelayN_221 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d221_ones, d221_zeros);
      cov_fail++;
    end
    $display("  DelayN_225: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d225_checks, d225_moves, $countones(d225_ones), $countones(d225_zeros));
    if (d225_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_225 有效比对只有 %0d 次 (需 >= %0d)", d225_checks, COV_MIN);
      cov_fail++;
    end
    if (d225_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_225 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d225_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d225_ones) || !(&d225_zeros)) begin
      $display("COVERAGE FAIL: DelayN_225 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d225_ones, d225_zeros);
      cov_fail++;
    end
    $display("  DelayN_297: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d297_checks, d297_moves, $countones(d297_ones), $countones(d297_zeros));
    if (d297_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_297 有效比对只有 %0d 次 (需 >= %0d)", d297_checks, COV_MIN);
      cov_fail++;
    end
    if (d297_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_297 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d297_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d297_ones) || !(&d297_zeros)) begin
      $display("COVERAGE FAIL: DelayN_297 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d297_ones, d297_zeros);
      cov_fail++;
    end
    $display("  DelayN_331: checks=%0d moves=%0d ones=%0d/1 zeros=%0d/1",
             d331_checks, d331_moves, $countones(d331_ones), $countones(d331_zeros));
    if (d331_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_331 有效比对只有 %0d 次 (需 >= %0d)", d331_checks, COV_MIN);
      cov_fail++;
    end
    if (d331_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_331 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d331_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d331_ones) || !(&d331_zeros)) begin
      $display("COVERAGE FAIL: DelayN_331 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d331_ones, d331_zeros);
      cov_fail++;
    end
    $display("  DelayN_333: checks=%0d moves=%0d ones=%0d/14 zeros=%0d/14",
             d333_checks, d333_moves, $countones(d333_ones), $countones(d333_zeros));
    if (d333_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_333 有效比对只有 %0d 次 (需 >= %0d)", d333_checks, COV_MIN);
      cov_fail++;
    end
    if (d333_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_333 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d333_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d333_ones) || !(&d333_zeros)) begin
      $display("COVERAGE FAIL: DelayN_333 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d333_ones, d333_zeros);
      cov_fail++;
    end
    $display("  DelayN_334: checks=%0d moves=%0d ones=%0d/48 zeros=%0d/48",
             d334_checks, d334_moves, $countones(d334_ones), $countones(d334_zeros));
    if (d334_checks < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_334 有效比对只有 %0d 次 (需 >= %0d)", d334_checks, COV_MIN);
      cov_fail++;
    end
    if (d334_moves < COV_MIN) begin
      $display("COVERAGE FAIL: DelayN_334 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               d334_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&d334_ones) || !(&d334_zeros)) begin
      $display("COVERAGE FAIL: DelayN_334 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               d334_ones, d334_zeros);
      cov_fail++;
    end
    // ★这一行是判据的唯一出口★：checks / errors / bad_cov 一起打，
    // scripts/mutant_harness.py 按 `checks=N errors=N bad_cov=N` 整条匹配。
    // 只打 errors 的话，"一次都没比对"和"比对全过"在日志里长得一模一样。
    $display("DelayN family checks=%0d errors=%0d bad_cov=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
