// 自动生成：verif/ut/SMSPrefetcher/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// SMSPrefetcher 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= SMSPrefetcher =================
  int unsigned sm_mode = 0;
  logic [49:0] sm_pcs [8];
  logic [39:0] sm_rbase [6];
  logic [35:0] sm_ppn [6];
  initial begin
    for (int i = 0; i < 8; i++) sm_pcs[i] = 50'({$urandom, $urandom});
    for (int i = 0; i < 6; i++) begin
      sm_rbase[i] = 40'({$urandom, $urandom});
      sm_ppn[i] = 36'(32'h0008_0000 + $urandom_range(0, 32'h07ff_ffff));
    end
  end
  // 训练 / evict 用的 vaddr：6 个区域基址 ±1 区域 + 随机块偏移；1/8 完全随机
  function automatic logic [49:0] sm_rnd_vaddr();
    logic [39:0] rg;
    if ($urandom_range(0, 7) == 0) return 50'({$urandom, $urandom});
    rg = sm_rbase[$urandom_range(0, 5)];
    case ($urandom_range(0, 7))
      0: rg = rg + 40'd1;
      1: rg = rg - 40'd1;
      2: if ($urandom_range(0, 3) == 0) rg[20:0] = '1;   // 原始区域地址全 1：+1 越界
      3: if ($urandom_range(0, 3) == 0) rg[20:0] = '0;   // 全 0：-1 越界
      default: ;
    endcase
    return {rg, 4'($urandom), 6'($urandom)};
  endfunction
  // paddr：按 vaddr 页号挑一个物理页（同一虚页恒定映射），拼页内偏移
  function automatic logic [47:0] sm_paddr_of(input logic [49:0] va);
    return {sm_ppn[va[17:12] % 6], va[11:0]};
  endfunction
  // 厂商 SRAM 行为模型（两侧同一份 golden array_12_ext）的存储阵列与读地址寄存器上电不复位：
  // +vcs+initreg+<seed> 下两个实例各摇各的初值，MBIST 读到没写过的行时两侧不同（与重写无关）。
  // 0 时刻之后把重写侧拷成 golden 侧（普通 always 驱动的变量，可直接过程赋值；只对齐上电初值）。
  initial begin
    #1;
    for (int k = 0; k < 32; k++)
      sm_u_impl.pht.pht_ram.array.array.array_12_ext.ram[k] = sm_u_gold.pht.pht_ram.array.array.array_12_ext.ram[k];
    sm_u_impl.pht.pht_ram.array.array.array_12_ext.reg_RW0_addr = sm_u_gold.pht.pht_ram.array.array.array_12_ext.reg_RW0_addr;
    sm_u_impl.pht.pht_ram.array.array.array_12_ext.reg_RW0_ren = sm_u_gold.pht.pht_ram.array.array.array_12_ext.reg_RW0_ren;
  end
  logic sm_reset;
  logic sm_io_ld_in_0_valid;
  logic [49:0] sm_io_ld_in_0_bits_uop_pc;
  logic sm_io_ld_in_0_bits_uop_robIdx_flag;
  logic [7:0] sm_io_ld_in_0_bits_uop_robIdx_value;
  logic [49:0] sm_io_ld_in_0_bits_vaddr;
  logic [47:0] sm_io_ld_in_0_bits_paddr;
  logic sm_io_ld_in_0_bits_miss;
  logic [2:0] sm_io_ld_in_0_bits_meta_prefetch;
  logic sm_io_ld_in_1_valid;
  logic [49:0] sm_io_ld_in_1_bits_uop_pc;
  logic sm_io_ld_in_1_bits_uop_robIdx_flag;
  logic [7:0] sm_io_ld_in_1_bits_uop_robIdx_value;
  logic [49:0] sm_io_ld_in_1_bits_vaddr;
  logic [47:0] sm_io_ld_in_1_bits_paddr;
  logic sm_io_ld_in_1_bits_miss;
  logic [2:0] sm_io_ld_in_1_bits_meta_prefetch;
  logic sm_io_ld_in_2_valid;
  logic [49:0] sm_io_ld_in_2_bits_uop_pc;
  logic sm_io_ld_in_2_bits_uop_robIdx_flag;
  logic [7:0] sm_io_ld_in_2_bits_uop_robIdx_value;
  logic [49:0] sm_io_ld_in_2_bits_vaddr;
  logic [47:0] sm_io_ld_in_2_bits_paddr;
  logic sm_io_ld_in_2_bits_miss;
  logic [2:0] sm_io_ld_in_2_bits_meta_prefetch;
  wire  sm_g_io_tlb_req_req_valid, sm_i_io_tlb_req_req_valid;
  logic sm_s0_io_tlb_req_req_valid = '0, sm_s1_io_tlb_req_req_valid = '0;
  wire  [49:0] sm_g_io_tlb_req_req_bits_vaddr, sm_i_io_tlb_req_req_bits_vaddr;
  logic [49:0] sm_s0_io_tlb_req_req_bits_vaddr = '0, sm_s1_io_tlb_req_req_bits_vaddr = '0;
  wire  [63:0] sm_g_io_tlb_req_req_bits_fullva, sm_i_io_tlb_req_req_bits_fullva;
  logic [63:0] sm_s0_io_tlb_req_req_bits_fullva = '0, sm_s1_io_tlb_req_req_bits_fullva = '0;
  wire  sm_g_io_tlb_req_req_bits_checkfullva, sm_i_io_tlb_req_req_bits_checkfullva;
  logic sm_s0_io_tlb_req_req_bits_checkfullva = '0, sm_s1_io_tlb_req_req_bits_checkfullva = '0;
  wire  [2:0] sm_g_io_tlb_req_req_bits_cmd, sm_i_io_tlb_req_req_bits_cmd;
  logic [2:0] sm_s0_io_tlb_req_req_bits_cmd = '0, sm_s1_io_tlb_req_req_bits_cmd = '0;
  wire  sm_g_io_tlb_req_req_bits_hyperinst, sm_i_io_tlb_req_req_bits_hyperinst;
  logic sm_s0_io_tlb_req_req_bits_hyperinst = '0, sm_s1_io_tlb_req_req_bits_hyperinst = '0;
  wire  sm_g_io_tlb_req_req_bits_hlvx, sm_i_io_tlb_req_req_bits_hlvx;
  logic sm_s0_io_tlb_req_req_bits_hlvx = '0, sm_s1_io_tlb_req_req_bits_hlvx = '0;
  wire  sm_g_io_tlb_req_req_bits_kill, sm_i_io_tlb_req_req_bits_kill;
  logic sm_s0_io_tlb_req_req_bits_kill = '0, sm_s1_io_tlb_req_req_bits_kill = '0;
  wire  sm_g_io_tlb_req_req_bits_isPrefetch, sm_i_io_tlb_req_req_bits_isPrefetch;
  logic sm_s0_io_tlb_req_req_bits_isPrefetch = '0, sm_s1_io_tlb_req_req_bits_isPrefetch = '0;
  wire  sm_g_io_tlb_req_req_bits_no_translate, sm_i_io_tlb_req_req_bits_no_translate;
  logic sm_s0_io_tlb_req_req_bits_no_translate = '0, sm_s1_io_tlb_req_req_bits_no_translate = '0;
  wire  [47:0] sm_g_io_tlb_req_req_bits_pmp_addr, sm_i_io_tlb_req_req_bits_pmp_addr;
  logic [47:0] sm_s0_io_tlb_req_req_bits_pmp_addr = '0, sm_s1_io_tlb_req_req_bits_pmp_addr = '0;
  wire  sm_g_io_tlb_req_req_bits_frm_mabuf, sm_i_io_tlb_req_req_bits_frm_mabuf;
  logic sm_s0_io_tlb_req_req_bits_frm_mabuf = '0, sm_s1_io_tlb_req_req_bits_frm_mabuf = '0;
  wire  sm_g_io_tlb_req_req_bits_debug_robIdx_flag, sm_i_io_tlb_req_req_bits_debug_robIdx_flag;
  logic sm_s0_io_tlb_req_req_bits_debug_robIdx_flag = '0, sm_s1_io_tlb_req_req_bits_debug_robIdx_flag = '0;
  wire  [7:0] sm_g_io_tlb_req_req_bits_debug_robIdx_value, sm_i_io_tlb_req_req_bits_debug_robIdx_value;
  logic [7:0] sm_s0_io_tlb_req_req_bits_debug_robIdx_value = '0, sm_s1_io_tlb_req_req_bits_debug_robIdx_value = '0;
  wire  sm_g_io_tlb_req_req_bits_debug_isFirstIssue, sm_i_io_tlb_req_req_bits_debug_isFirstIssue;
  logic sm_s0_io_tlb_req_req_bits_debug_isFirstIssue = '0, sm_s1_io_tlb_req_req_bits_debug_isFirstIssue = '0;
  logic sm_io_tlb_req_resp_valid;
  logic [47:0] sm_io_tlb_req_resp_bits_paddr_0;
  logic [1:0] sm_io_tlb_req_resp_bits_pbmt_0;
  logic sm_io_tlb_req_resp_bits_miss;
  logic sm_io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic sm_io_tlb_req_resp_bits_excp_0_pf_ld;
  logic sm_io_tlb_req_resp_bits_excp_0_af_ld;
  logic sm_io_pmp_resp_ld;
  logic sm_io_pmp_resp_mmio;
  wire  sm_g_io_l2_req_valid, sm_i_io_l2_req_valid;
  logic sm_s0_io_l2_req_valid = '0, sm_s1_io_l2_req_valid = '0;
  wire  [47:0] sm_g_io_l2_req_bits_addr, sm_i_io_l2_req_bits_addr;
  logic [47:0] sm_s0_io_l2_req_bits_addr = '0, sm_s1_io_l2_req_bits_addr = '0;
  logic sm_io_enable;
  logic sm_io_agt_en;
  logic sm_io_pht_en;
  logic [3:0] sm_io_act_threshold;
  logic [5:0] sm_io_act_stride;
  logic sm_io_dcache_evict_valid;
  logic [49:0] sm_io_dcache_evict_bits_vaddr;
  logic [5:0] sm_boreChildrenBd_bore_addr;
  logic [5:0] sm_boreChildrenBd_bore_addr_rd;
  logic [147:0] sm_boreChildrenBd_bore_wdata;
  logic [1:0] sm_boreChildrenBd_bore_wmask;
  logic sm_boreChildrenBd_bore_re;
  logic sm_boreChildrenBd_bore_we;
  wire  [147:0] sm_g_boreChildrenBd_bore_rdata, sm_i_boreChildrenBd_bore_rdata;
  logic [147:0] sm_s0_boreChildrenBd_bore_rdata = '0, sm_s1_boreChildrenBd_bore_rdata = '0;
  logic sm_boreChildrenBd_bore_ack;
  logic sm_boreChildrenBd_bore_selectedOH;
  logic [6:0] sm_boreChildrenBd_bore_array;
  logic sm_sigFromSrams_bore_ram_hold;
  logic sm_sigFromSrams_bore_ram_bypass;
  logic sm_sigFromSrams_bore_ram_bp_clken;
  logic sm_sigFromSrams_bore_ram_aux_clk;
  logic sm_sigFromSrams_bore_ram_aux_ckbp;
  logic sm_sigFromSrams_bore_ram_mcp_hold;
  logic sm_sigFromSrams_bore_cgen;
  int sm_cov_train_req = 0;
  int sm_cov_agt_evict = 0;
  int sm_cov_agt_lookup = 0;
  int sm_cov_no_cross_p1 = 0;
  int sm_cov_no_cross_m1 = 0;
  int sm_cov_pht_gen = 0;
  int sm_cov_pht_gated = 0;
  int sm_cov_tlb_req = 0;
  int sm_cov_pf_out = 0;
  int sm_cov_l2_req = 0;
  int sm_cov_l2_out_range = 0;
  int sm_cov_l2_disabled = 0;
  int sm_cov_reset_mid = 0;
  logic [17:0] sm_armed = '0;
  int sm_armed_at = -1;
  SMSPrefetcher sm_u_gold (
    .clock(clk),
    .reset(sm_reset),
    .io_ld_in_0_valid(sm_io_ld_in_0_valid),
    .io_ld_in_0_bits_uop_pc(sm_io_ld_in_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag(sm_io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(sm_io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(sm_io_ld_in_0_bits_vaddr),
    .io_ld_in_0_bits_paddr(sm_io_ld_in_0_bits_paddr),
    .io_ld_in_0_bits_miss(sm_io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch(sm_io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid(sm_io_ld_in_1_valid),
    .io_ld_in_1_bits_uop_pc(sm_io_ld_in_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag(sm_io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(sm_io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(sm_io_ld_in_1_bits_vaddr),
    .io_ld_in_1_bits_paddr(sm_io_ld_in_1_bits_paddr),
    .io_ld_in_1_bits_miss(sm_io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch(sm_io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid(sm_io_ld_in_2_valid),
    .io_ld_in_2_bits_uop_pc(sm_io_ld_in_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag(sm_io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(sm_io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(sm_io_ld_in_2_bits_vaddr),
    .io_ld_in_2_bits_paddr(sm_io_ld_in_2_bits_paddr),
    .io_ld_in_2_bits_miss(sm_io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch(sm_io_ld_in_2_bits_meta_prefetch),
    .io_tlb_req_req_valid(sm_g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(sm_g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(sm_g_io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(sm_g_io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(sm_g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst(sm_g_io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(sm_g_io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill(sm_g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(sm_g_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(sm_g_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(sm_g_io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf(sm_g_io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag(sm_g_io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(sm_g_io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(sm_g_io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid(sm_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(sm_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(sm_io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss(sm_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(sm_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(sm_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(sm_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(sm_io_pmp_resp_ld),
    .io_pmp_resp_mmio(sm_io_pmp_resp_mmio),
    .io_l2_req_valid(sm_g_io_l2_req_valid),
    .io_l2_req_bits_addr(sm_g_io_l2_req_bits_addr),
    .io_enable(sm_io_enable),
    .io_agt_en(sm_io_agt_en),
    .io_pht_en(sm_io_pht_en),
    .io_act_threshold(sm_io_act_threshold),
    .io_act_stride(sm_io_act_stride),
    .io_dcache_evict_valid(sm_io_dcache_evict_valid),
    .io_dcache_evict_bits_vaddr(sm_io_dcache_evict_bits_vaddr),
    .boreChildrenBd_bore_addr(sm_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(sm_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(sm_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(sm_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(sm_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(sm_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(sm_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(sm_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(sm_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(sm_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(sm_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sm_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sm_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sm_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sm_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sm_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sm_sigFromSrams_bore_cgen)
  );
  SMSPrefetcher_xs sm_u_impl (
    .clock(clk),
    .reset(sm_reset),
    .io_ld_in_0_valid(sm_io_ld_in_0_valid),
    .io_ld_in_0_bits_uop_pc(sm_io_ld_in_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag(sm_io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(sm_io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(sm_io_ld_in_0_bits_vaddr),
    .io_ld_in_0_bits_paddr(sm_io_ld_in_0_bits_paddr),
    .io_ld_in_0_bits_miss(sm_io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch(sm_io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid(sm_io_ld_in_1_valid),
    .io_ld_in_1_bits_uop_pc(sm_io_ld_in_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag(sm_io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(sm_io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(sm_io_ld_in_1_bits_vaddr),
    .io_ld_in_1_bits_paddr(sm_io_ld_in_1_bits_paddr),
    .io_ld_in_1_bits_miss(sm_io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch(sm_io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid(sm_io_ld_in_2_valid),
    .io_ld_in_2_bits_uop_pc(sm_io_ld_in_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag(sm_io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(sm_io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(sm_io_ld_in_2_bits_vaddr),
    .io_ld_in_2_bits_paddr(sm_io_ld_in_2_bits_paddr),
    .io_ld_in_2_bits_miss(sm_io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch(sm_io_ld_in_2_bits_meta_prefetch),
    .io_tlb_req_req_valid(sm_i_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(sm_i_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(sm_i_io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(sm_i_io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(sm_i_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst(sm_i_io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(sm_i_io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill(sm_i_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(sm_i_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(sm_i_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(sm_i_io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf(sm_i_io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag(sm_i_io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(sm_i_io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(sm_i_io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid(sm_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(sm_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(sm_io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss(sm_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(sm_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(sm_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(sm_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(sm_io_pmp_resp_ld),
    .io_pmp_resp_mmio(sm_io_pmp_resp_mmio),
    .io_l2_req_valid(sm_i_io_l2_req_valid),
    .io_l2_req_bits_addr(sm_i_io_l2_req_bits_addr),
    .io_enable(sm_io_enable),
    .io_agt_en(sm_io_agt_en),
    .io_pht_en(sm_io_pht_en),
    .io_act_threshold(sm_io_act_threshold),
    .io_act_stride(sm_io_act_stride),
    .io_dcache_evict_valid(sm_io_dcache_evict_valid),
    .io_dcache_evict_bits_vaddr(sm_io_dcache_evict_bits_vaddr),
    .boreChildrenBd_bore_addr(sm_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(sm_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(sm_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(sm_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(sm_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(sm_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(sm_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(sm_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(sm_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(sm_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(sm_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sm_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sm_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sm_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sm_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sm_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sm_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) sm_mode = $urandom_range(0, 15);
      sm_io_ld_in_0_valid = 1'($urandom);
      sm_io_ld_in_0_bits_uop_pc = 50'({$urandom, $urandom});
      sm_io_ld_in_0_bits_uop_robIdx_flag = 1'($urandom);
      sm_io_ld_in_0_bits_uop_robIdx_value = 8'($urandom);
      sm_io_ld_in_0_bits_vaddr = 50'({$urandom, $urandom});
      sm_io_ld_in_0_bits_paddr = 48'({$urandom, $urandom});
      sm_io_ld_in_0_bits_miss = 1'($urandom);
      sm_io_ld_in_0_bits_meta_prefetch = 3'($urandom);
      sm_io_ld_in_1_valid = 1'($urandom);
      sm_io_ld_in_1_bits_uop_pc = 50'({$urandom, $urandom});
      sm_io_ld_in_1_bits_uop_robIdx_flag = 1'($urandom);
      sm_io_ld_in_1_bits_uop_robIdx_value = 8'($urandom);
      sm_io_ld_in_1_bits_vaddr = 50'({$urandom, $urandom});
      sm_io_ld_in_1_bits_paddr = 48'({$urandom, $urandom});
      sm_io_ld_in_1_bits_miss = 1'($urandom);
      sm_io_ld_in_1_bits_meta_prefetch = 3'($urandom);
      sm_io_ld_in_2_valid = 1'($urandom);
      sm_io_ld_in_2_bits_uop_pc = 50'({$urandom, $urandom});
      sm_io_ld_in_2_bits_uop_robIdx_flag = 1'($urandom);
      sm_io_ld_in_2_bits_uop_robIdx_value = 8'($urandom);
      sm_io_ld_in_2_bits_vaddr = 50'({$urandom, $urandom});
      sm_io_ld_in_2_bits_paddr = 48'({$urandom, $urandom});
      sm_io_ld_in_2_bits_miss = 1'($urandom);
      sm_io_ld_in_2_bits_meta_prefetch = 3'($urandom);
      sm_io_tlb_req_resp_valid = 1'($urandom);
      sm_io_tlb_req_resp_bits_paddr_0 = 48'({$urandom, $urandom});
      sm_io_tlb_req_resp_bits_pbmt_0 = 2'($urandom);
      sm_io_tlb_req_resp_bits_miss = 1'($urandom);
      sm_io_tlb_req_resp_bits_excp_0_gpf_ld = 1'($urandom);
      sm_io_tlb_req_resp_bits_excp_0_pf_ld = 1'($urandom);
      sm_io_tlb_req_resp_bits_excp_0_af_ld = 1'($urandom);
      sm_io_pmp_resp_ld = 1'($urandom);
      sm_io_pmp_resp_mmio = 1'($urandom);
      sm_io_enable = 1'($urandom);
      sm_io_agt_en = 1'($urandom);
      sm_io_pht_en = 1'($urandom);
      sm_io_act_threshold = 4'($urandom);
      sm_io_act_stride = 6'($urandom);
      sm_io_dcache_evict_valid = 1'($urandom);
      sm_io_dcache_evict_bits_vaddr = 50'({$urandom, $urandom});
      sm_boreChildrenBd_bore_addr = 6'($urandom);
      sm_boreChildrenBd_bore_addr_rd = 6'($urandom);
      sm_boreChildrenBd_bore_wdata = 148'({$urandom, $urandom, $urandom, $urandom, $urandom});
      sm_boreChildrenBd_bore_wmask = 2'($urandom);
      sm_boreChildrenBd_bore_re = 1'($urandom);
      sm_boreChildrenBd_bore_we = 1'($urandom);
      sm_boreChildrenBd_bore_ack = 1'($urandom);
      sm_boreChildrenBd_bore_selectedOH = 1'($urandom);
      sm_boreChildrenBd_bore_array = 7'($urandom);
      sm_sigFromSrams_bore_ram_hold = 1'($urandom);
      sm_sigFromSrams_bore_ram_bypass = 1'($urandom);
      sm_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      sm_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      sm_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      sm_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      sm_sigFromSrams_bore_cgen = 1'($urandom);
      sm_reset = (cyc < RESET_CYC) || ($urandom_range(0, 9999) == 0);
      begin : stim_sm
        for (int k = 0; k < 3; k++) begin : ld
          logic [49:0] va;
          va = sm_rnd_vaddr();
          case (k)
            0: begin sm_io_ld_in_0_valid = ($urandom_range(0, 1) != 0); sm_io_ld_in_0_bits_uop_pc = sm_pcs[$urandom_range(0, 7)]; sm_io_ld_in_0_bits_vaddr = va; sm_io_ld_in_0_bits_paddr = sm_paddr_of(va); end
            1: begin sm_io_ld_in_1_valid = ($urandom_range(0, 1) != 0); sm_io_ld_in_1_bits_uop_pc = sm_pcs[$urandom_range(0, 7)]; sm_io_ld_in_1_bits_vaddr = va; sm_io_ld_in_1_bits_paddr = sm_paddr_of(va); end
            2: begin sm_io_ld_in_2_valid = ($urandom_range(0, 1) != 0); sm_io_ld_in_2_bits_uop_pc = sm_pcs[$urandom_range(0, 7)]; sm_io_ld_in_2_bits_vaddr = va; sm_io_ld_in_2_bits_paddr = sm_paddr_of(va); end
          endcase
        end
        sm_io_dcache_evict_valid = ($urandom_range(0, 15) == 0);
        sm_io_dcache_evict_bits_vaddr = sm_rnd_vaddr();
        sm_io_enable = (sm_mode != 1);
        sm_io_agt_en = (sm_mode != 2);
        sm_io_pht_en = (sm_mode != 3);
        sm_io_tlb_req_resp_valid = ($urandom_range(0, 1) != 0);
        sm_io_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);
        if ($urandom_range(0, 3) != 0) sm_io_tlb_req_resp_bits_paddr_0 = {5'h0, 1'b0, 42'($urandom_range(0, 32'hffff_ffff)) | 42'h8000_0000};
        sm_io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 31) == 0);
        sm_io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 31) == 0);
        sm_io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 31) == 0);
        sm_io_tlb_req_resp_bits_pbmt_0 = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'd0;
        sm_io_pmp_resp_ld = ($urandom_range(0, 31) == 0);
        sm_io_pmp_resp_mmio = ($urandom_range(0, 31) == 0);
        if (sm_mode != 0) begin
          sm_boreChildrenBd_bore_re = '0;
          sm_boreChildrenBd_bore_we = '0;
          sm_boreChildrenBd_bore_ack = '0;
          sm_boreChildrenBd_bore_selectedOH = '0;
          sm_boreChildrenBd_bore_array = '0;
          sm_boreChildrenBd_bore_wmask = '0;
          sm_sigFromSrams_bore_ram_hold = '0;
          sm_sigFromSrams_bore_ram_bypass = '0;
          sm_sigFromSrams_bore_ram_bp_clken = '0;
          sm_sigFromSrams_bore_ram_aux_clk = '0;
          sm_sigFromSrams_bore_ram_aux_ckbp = '0;
          sm_sigFromSrams_bore_ram_mcp_hold = '0;
          sm_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && sm_armed_at >= 0 && cyc >= sm_armed_at) begin
        checks++;
        if (sm_g_io_tlb_req_req_valid !== sm_i_io_tlb_req_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_valid g=%h i=%h", cyc, sm_g_io_tlb_req_req_valid, sm_i_io_tlb_req_req_valid);
        end
        sm_s1_io_tlb_req_req_valid |= sm_g_io_tlb_req_req_valid;
        sm_s0_io_tlb_req_req_valid |= ~sm_g_io_tlb_req_req_valid;
        checks++;
        if (sm_g_io_tlb_req_req_bits_vaddr !== sm_i_io_tlb_req_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_vaddr g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_vaddr, sm_i_io_tlb_req_req_bits_vaddr);
        end
        sm_s1_io_tlb_req_req_bits_vaddr |= sm_g_io_tlb_req_req_bits_vaddr;
        sm_s0_io_tlb_req_req_bits_vaddr |= ~sm_g_io_tlb_req_req_bits_vaddr;
        checks++;
        if (sm_g_io_tlb_req_req_bits_fullva !== sm_i_io_tlb_req_req_bits_fullva) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_fullva g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_fullva, sm_i_io_tlb_req_req_bits_fullva);
        end
        sm_s1_io_tlb_req_req_bits_fullva |= sm_g_io_tlb_req_req_bits_fullva;
        sm_s0_io_tlb_req_req_bits_fullva |= ~sm_g_io_tlb_req_req_bits_fullva;
        checks++;
        if (sm_g_io_tlb_req_req_bits_checkfullva !== sm_i_io_tlb_req_req_bits_checkfullva) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_checkfullva g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_checkfullva, sm_i_io_tlb_req_req_bits_checkfullva);
        end
        sm_s1_io_tlb_req_req_bits_checkfullva |= sm_g_io_tlb_req_req_bits_checkfullva;
        sm_s0_io_tlb_req_req_bits_checkfullva |= ~sm_g_io_tlb_req_req_bits_checkfullva;
        checks++;
        if (sm_g_io_tlb_req_req_bits_cmd !== sm_i_io_tlb_req_req_bits_cmd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_cmd g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_cmd, sm_i_io_tlb_req_req_bits_cmd);
        end
        sm_s1_io_tlb_req_req_bits_cmd |= sm_g_io_tlb_req_req_bits_cmd;
        sm_s0_io_tlb_req_req_bits_cmd |= ~sm_g_io_tlb_req_req_bits_cmd;
        checks++;
        if (sm_g_io_tlb_req_req_bits_hyperinst !== sm_i_io_tlb_req_req_bits_hyperinst) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_hyperinst g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_hyperinst, sm_i_io_tlb_req_req_bits_hyperinst);
        end
        sm_s1_io_tlb_req_req_bits_hyperinst |= sm_g_io_tlb_req_req_bits_hyperinst;
        sm_s0_io_tlb_req_req_bits_hyperinst |= ~sm_g_io_tlb_req_req_bits_hyperinst;
        checks++;
        if (sm_g_io_tlb_req_req_bits_hlvx !== sm_i_io_tlb_req_req_bits_hlvx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_hlvx g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_hlvx, sm_i_io_tlb_req_req_bits_hlvx);
        end
        sm_s1_io_tlb_req_req_bits_hlvx |= sm_g_io_tlb_req_req_bits_hlvx;
        sm_s0_io_tlb_req_req_bits_hlvx |= ~sm_g_io_tlb_req_req_bits_hlvx;
        checks++;
        if (sm_g_io_tlb_req_req_bits_kill !== sm_i_io_tlb_req_req_bits_kill) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_kill g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_kill, sm_i_io_tlb_req_req_bits_kill);
        end
        sm_s1_io_tlb_req_req_bits_kill |= sm_g_io_tlb_req_req_bits_kill;
        sm_s0_io_tlb_req_req_bits_kill |= ~sm_g_io_tlb_req_req_bits_kill;
        checks++;
        if (sm_g_io_tlb_req_req_bits_isPrefetch !== sm_i_io_tlb_req_req_bits_isPrefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_isPrefetch g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_isPrefetch, sm_i_io_tlb_req_req_bits_isPrefetch);
        end
        sm_s1_io_tlb_req_req_bits_isPrefetch |= sm_g_io_tlb_req_req_bits_isPrefetch;
        sm_s0_io_tlb_req_req_bits_isPrefetch |= ~sm_g_io_tlb_req_req_bits_isPrefetch;
        checks++;
        if (sm_g_io_tlb_req_req_bits_no_translate !== sm_i_io_tlb_req_req_bits_no_translate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_no_translate g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_no_translate, sm_i_io_tlb_req_req_bits_no_translate);
        end
        sm_s1_io_tlb_req_req_bits_no_translate |= sm_g_io_tlb_req_req_bits_no_translate;
        sm_s0_io_tlb_req_req_bits_no_translate |= ~sm_g_io_tlb_req_req_bits_no_translate;
        checks++;
        if (sm_g_io_tlb_req_req_bits_pmp_addr !== sm_i_io_tlb_req_req_bits_pmp_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_pmp_addr g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_pmp_addr, sm_i_io_tlb_req_req_bits_pmp_addr);
        end
        sm_s1_io_tlb_req_req_bits_pmp_addr |= sm_g_io_tlb_req_req_bits_pmp_addr;
        sm_s0_io_tlb_req_req_bits_pmp_addr |= ~sm_g_io_tlb_req_req_bits_pmp_addr;
        checks++;
        if (sm_g_io_tlb_req_req_bits_frm_mabuf !== sm_i_io_tlb_req_req_bits_frm_mabuf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_frm_mabuf g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_frm_mabuf, sm_i_io_tlb_req_req_bits_frm_mabuf);
        end
        sm_s1_io_tlb_req_req_bits_frm_mabuf |= sm_g_io_tlb_req_req_bits_frm_mabuf;
        sm_s0_io_tlb_req_req_bits_frm_mabuf |= ~sm_g_io_tlb_req_req_bits_frm_mabuf;
        checks++;
        if (sm_g_io_tlb_req_req_bits_debug_robIdx_flag !== sm_i_io_tlb_req_req_bits_debug_robIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_debug_robIdx_flag g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_debug_robIdx_flag, sm_i_io_tlb_req_req_bits_debug_robIdx_flag);
        end
        sm_s1_io_tlb_req_req_bits_debug_robIdx_flag |= sm_g_io_tlb_req_req_bits_debug_robIdx_flag;
        sm_s0_io_tlb_req_req_bits_debug_robIdx_flag |= ~sm_g_io_tlb_req_req_bits_debug_robIdx_flag;
        checks++;
        if (sm_g_io_tlb_req_req_bits_debug_robIdx_value !== sm_i_io_tlb_req_req_bits_debug_robIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_debug_robIdx_value g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_debug_robIdx_value, sm_i_io_tlb_req_req_bits_debug_robIdx_value);
        end
        sm_s1_io_tlb_req_req_bits_debug_robIdx_value |= sm_g_io_tlb_req_req_bits_debug_robIdx_value;
        sm_s0_io_tlb_req_req_bits_debug_robIdx_value |= ~sm_g_io_tlb_req_req_bits_debug_robIdx_value;
        checks++;
        if (sm_g_io_tlb_req_req_bits_debug_isFirstIssue !== sm_i_io_tlb_req_req_bits_debug_isFirstIssue) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_tlb_req_req_bits_debug_isFirstIssue g=%h i=%h", cyc, sm_g_io_tlb_req_req_bits_debug_isFirstIssue, sm_i_io_tlb_req_req_bits_debug_isFirstIssue);
        end
        sm_s1_io_tlb_req_req_bits_debug_isFirstIssue |= sm_g_io_tlb_req_req_bits_debug_isFirstIssue;
        sm_s0_io_tlb_req_req_bits_debug_isFirstIssue |= ~sm_g_io_tlb_req_req_bits_debug_isFirstIssue;
        checks++;
        if (sm_g_io_l2_req_valid !== sm_i_io_l2_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_l2_req_valid g=%h i=%h", cyc, sm_g_io_l2_req_valid, sm_i_io_l2_req_valid);
        end
        sm_s1_io_l2_req_valid |= sm_g_io_l2_req_valid;
        sm_s0_io_l2_req_valid |= ~sm_g_io_l2_req_valid;
        checks++;
        if (sm_g_io_l2_req_bits_addr !== sm_i_io_l2_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.io_l2_req_bits_addr g=%h i=%h", cyc, sm_g_io_l2_req_bits_addr, sm_i_io_l2_req_bits_addr);
        end
        sm_s1_io_l2_req_bits_addr |= sm_g_io_l2_req_bits_addr;
        sm_s0_io_l2_req_bits_addr |= ~sm_g_io_l2_req_bits_addr;
        checks++;
        if (sm_g_boreChildrenBd_bore_rdata !== sm_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SMSPrefetcher.boreChildrenBd_bore_rdata g=%h i=%h", cyc, sm_g_boreChildrenBd_bore_rdata, sm_i_boreChildrenBd_bore_rdata);
        end
        sm_s1_boreChildrenBd_bore_rdata |= sm_g_boreChildrenBd_bore_rdata;
        sm_s0_boreChildrenBd_bore_rdata |= ~sm_g_boreChildrenBd_bore_rdata;
        if (sm_u_gold._train_filter_io_train_req_valid) sm_cov_train_req++;
        if (sm_u_gold._active_gen_table_io_s2_evict_valid) sm_cov_agt_evict++;
        if (sm_u_gold._active_gen_table_io_s2_pht_lookup_valid) sm_cov_agt_lookup++;
        if (sm_u_gold.train_vld_s0_last_REG && !sm_u_gold.train_allow_cross_region_p1_s0) sm_cov_no_cross_p1++;
        if (sm_u_gold.train_vld_s0_last_REG && !sm_u_gold.train_allow_cross_region_m1_s0) sm_cov_no_cross_m1++;
        if (sm_u_gold._pht_io_pf_gen_req_valid && sm_io_pht_en) sm_cov_pht_gen++;
        if (sm_u_gold._pht_io_pf_gen_req_valid && !sm_io_pht_en) sm_cov_pht_gated++;
        if (sm_g_io_tlb_req_req_valid) sm_cov_tlb_req++;
        if (sm_u_gold._pf_filter_io_l2_pf_addr_valid) sm_cov_pf_out++;
        if (sm_g_io_l2_req_valid) sm_cov_l2_req++;
        if (sm_u_gold._pf_filter_io_l2_pf_addr_valid && sm_io_enable && !sm_g_io_l2_req_valid) sm_cov_l2_out_range++;
        if (sm_u_gold._pf_filter_io_l2_pf_addr_valid && !sm_io_enable) sm_cov_l2_disabled++;
        if (sm_reset && cyc > 100) sm_cov_reset_mid++;
      end
      if (sm_u_gold.pf_filter.valids_0) sm_armed[0] = 1'b1;
      if (sm_u_gold.pf_filter.valids_1) sm_armed[1] = 1'b1;
      if (sm_u_gold.pf_filter.valids_2) sm_armed[2] = 1'b1;
      if (sm_u_gold.pf_filter.valids_3) sm_armed[3] = 1'b1;
      if (sm_u_gold.pf_filter.valids_4) sm_armed[4] = 1'b1;
      if (sm_u_gold.pf_filter.valids_5) sm_armed[5] = 1'b1;
      if (sm_u_gold.pf_filter.valids_6) sm_armed[6] = 1'b1;
      if (sm_u_gold.pf_filter.valids_7) sm_armed[7] = 1'b1;
      if (sm_u_gold.pf_filter.valids_8) sm_armed[8] = 1'b1;
      if (sm_u_gold.pf_filter.valids_9) sm_armed[9] = 1'b1;
      if (sm_u_gold.pf_filter.valids_10) sm_armed[10] = 1'b1;
      if (sm_u_gold.pf_filter.valids_11) sm_armed[11] = 1'b1;
      if (sm_u_gold.pf_filter.valids_12) sm_armed[12] = 1'b1;
      if (sm_u_gold.pf_filter.valids_13) sm_armed[13] = 1'b1;
      if (sm_u_gold.pf_filter.valids_14) sm_armed[14] = 1'b1;
      if (sm_u_gold.pf_filter.valids_15) sm_armed[15] = 1'b1;
      if (sm_g_io_tlb_req_req_valid) sm_armed[16] = 1'b1;
      if (sm_u_gold.pht.pht_ram.respReg) sm_armed[17] = 1'b1;
      if (sm_armed_at < 0 && (&sm_armed)) sm_armed_at = cyc + 1 + 4;
    end

    // ---- 覆盖闸 ----
    if (!(sm_s0_io_tlb_req_req_valid && sm_s1_io_tlb_req_req_valid)) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_valid 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[10] && sm_s1_io_tlb_req_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[11] && sm_s1_io_tlb_req_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[12] && sm_s1_io_tlb_req_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[13] && sm_s1_io_tlb_req_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[14] && sm_s1_io_tlb_req_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[15] && sm_s1_io_tlb_req_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[16] && sm_s1_io_tlb_req_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[17] && sm_s1_io_tlb_req_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[18] && sm_s1_io_tlb_req_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[19] && sm_s1_io_tlb_req_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[20] && sm_s1_io_tlb_req_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[21] && sm_s1_io_tlb_req_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[22] && sm_s1_io_tlb_req_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[23] && sm_s1_io_tlb_req_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[24] && sm_s1_io_tlb_req_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[25] && sm_s1_io_tlb_req_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[26] && sm_s1_io_tlb_req_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[27] && sm_s1_io_tlb_req_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[28] && sm_s1_io_tlb_req_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[29] && sm_s1_io_tlb_req_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[30] && sm_s1_io_tlb_req_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[31] && sm_s1_io_tlb_req_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[32] && sm_s1_io_tlb_req_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[33] && sm_s1_io_tlb_req_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[34] && sm_s1_io_tlb_req_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[35] && sm_s1_io_tlb_req_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[36] && sm_s1_io_tlb_req_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[37] && sm_s1_io_tlb_req_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[38] && sm_s1_io_tlb_req_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[39] && sm_s1_io_tlb_req_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[40] && sm_s1_io_tlb_req_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[41] && sm_s1_io_tlb_req_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[42] && sm_s1_io_tlb_req_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[43] && sm_s1_io_tlb_req_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[44] && sm_s1_io_tlb_req_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[45] && sm_s1_io_tlb_req_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[46] && sm_s1_io_tlb_req_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[47] && sm_s1_io_tlb_req_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[48] && sm_s1_io_tlb_req_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(sm_s0_io_tlb_req_req_bits_vaddr[49] && sm_s1_io_tlb_req_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_tlb_req_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_valid && sm_s1_io_l2_req_valid)) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_valid 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[6] && sm_s1_io_l2_req_bits_addr[6])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[7] && sm_s1_io_l2_req_bits_addr[7])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[8] && sm_s1_io_l2_req_bits_addr[8])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[9] && sm_s1_io_l2_req_bits_addr[9])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[10] && sm_s1_io_l2_req_bits_addr[10])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[11] && sm_s1_io_l2_req_bits_addr[11])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[12] && sm_s1_io_l2_req_bits_addr[12])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[13] && sm_s1_io_l2_req_bits_addr[13])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[14] && sm_s1_io_l2_req_bits_addr[14])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[15] && sm_s1_io_l2_req_bits_addr[15])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[16] && sm_s1_io_l2_req_bits_addr[16])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[17] && sm_s1_io_l2_req_bits_addr[17])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[18] && sm_s1_io_l2_req_bits_addr[18])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[19] && sm_s1_io_l2_req_bits_addr[19])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[20] && sm_s1_io_l2_req_bits_addr[20])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[21] && sm_s1_io_l2_req_bits_addr[21])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[22] && sm_s1_io_l2_req_bits_addr[22])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[23] && sm_s1_io_l2_req_bits_addr[23])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[24] && sm_s1_io_l2_req_bits_addr[24])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[25] && sm_s1_io_l2_req_bits_addr[25])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[26] && sm_s1_io_l2_req_bits_addr[26])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[27] && sm_s1_io_l2_req_bits_addr[27])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[28] && sm_s1_io_l2_req_bits_addr[28])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[29] && sm_s1_io_l2_req_bits_addr[29])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[30] && sm_s1_io_l2_req_bits_addr[30])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[31] && sm_s1_io_l2_req_bits_addr[31])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[32] && sm_s1_io_l2_req_bits_addr[32])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[33] && sm_s1_io_l2_req_bits_addr[33])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[34] && sm_s1_io_l2_req_bits_addr[34])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[35] && sm_s1_io_l2_req_bits_addr[35])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[36] && sm_s1_io_l2_req_bits_addr[36])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[37] && sm_s1_io_l2_req_bits_addr[37])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[38] && sm_s1_io_l2_req_bits_addr[38])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[39] && sm_s1_io_l2_req_bits_addr[39])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[40] && sm_s1_io_l2_req_bits_addr[40])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[41] && sm_s1_io_l2_req_bits_addr[41])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[42] && sm_s1_io_l2_req_bits_addr[42])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[43] && sm_s1_io_l2_req_bits_addr[43])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[44] && sm_s1_io_l2_req_bits_addr[44])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[45] && sm_s1_io_l2_req_bits_addr[45])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[46] && sm_s1_io_l2_req_bits_addr[46])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(sm_s0_io_l2_req_bits_addr[47] && sm_s1_io_l2_req_bits_addr[47])) begin cov_fail++; $display("[COV] SMSPrefetcher.io_l2_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[0] && sm_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[1] && sm_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[2] && sm_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[3] && sm_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[4] && sm_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[5] && sm_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[6] && sm_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[7] && sm_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[8] && sm_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[9] && sm_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[10] && sm_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[11] && sm_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[12] && sm_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[13] && sm_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[14] && sm_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[15] && sm_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[16] && sm_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[17] && sm_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[18] && sm_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[19] && sm_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[20] && sm_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[21] && sm_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[22] && sm_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[23] && sm_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[24] && sm_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[25] && sm_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[26] && sm_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[27] && sm_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[28] && sm_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[29] && sm_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[30] && sm_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[31] && sm_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[32] && sm_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[33] && sm_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[34] && sm_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[35] && sm_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[36] && sm_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[37] && sm_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[38] && sm_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[39] && sm_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[40] && sm_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[41] && sm_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[42] && sm_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[43] && sm_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[44] && sm_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[45] && sm_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[46] && sm_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[47] && sm_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[48] && sm_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[49] && sm_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[50] && sm_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[51] && sm_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[52] && sm_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[53] && sm_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[54] && sm_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[55] && sm_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[56] && sm_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[57] && sm_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[58] && sm_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[59] && sm_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[60] && sm_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[61] && sm_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[62] && sm_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[63] && sm_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[64] && sm_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[65] && sm_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[66] && sm_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[67] && sm_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[68] && sm_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[69] && sm_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[70] && sm_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[71] && sm_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[72] && sm_s1_boreChildrenBd_bore_rdata[72])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[72] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[73] && sm_s1_boreChildrenBd_bore_rdata[73])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[73] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[74] && sm_s1_boreChildrenBd_bore_rdata[74])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[74] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[75] && sm_s1_boreChildrenBd_bore_rdata[75])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[75] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[76] && sm_s1_boreChildrenBd_bore_rdata[76])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[76] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[77] && sm_s1_boreChildrenBd_bore_rdata[77])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[77] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[78] && sm_s1_boreChildrenBd_bore_rdata[78])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[78] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[79] && sm_s1_boreChildrenBd_bore_rdata[79])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[79] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[80] && sm_s1_boreChildrenBd_bore_rdata[80])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[80] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[81] && sm_s1_boreChildrenBd_bore_rdata[81])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[81] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[82] && sm_s1_boreChildrenBd_bore_rdata[82])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[82] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[83] && sm_s1_boreChildrenBd_bore_rdata[83])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[83] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[84] && sm_s1_boreChildrenBd_bore_rdata[84])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[84] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[85] && sm_s1_boreChildrenBd_bore_rdata[85])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[85] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[86] && sm_s1_boreChildrenBd_bore_rdata[86])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[86] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[87] && sm_s1_boreChildrenBd_bore_rdata[87])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[87] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[88] && sm_s1_boreChildrenBd_bore_rdata[88])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[88] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[89] && sm_s1_boreChildrenBd_bore_rdata[89])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[89] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[90] && sm_s1_boreChildrenBd_bore_rdata[90])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[90] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[91] && sm_s1_boreChildrenBd_bore_rdata[91])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[91] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[92] && sm_s1_boreChildrenBd_bore_rdata[92])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[92] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[93] && sm_s1_boreChildrenBd_bore_rdata[93])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[93] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[94] && sm_s1_boreChildrenBd_bore_rdata[94])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[94] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[95] && sm_s1_boreChildrenBd_bore_rdata[95])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[95] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[96] && sm_s1_boreChildrenBd_bore_rdata[96])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[96] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[97] && sm_s1_boreChildrenBd_bore_rdata[97])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[97] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[98] && sm_s1_boreChildrenBd_bore_rdata[98])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[98] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[99] && sm_s1_boreChildrenBd_bore_rdata[99])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[99] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[100] && sm_s1_boreChildrenBd_bore_rdata[100])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[100] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[101] && sm_s1_boreChildrenBd_bore_rdata[101])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[101] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[102] && sm_s1_boreChildrenBd_bore_rdata[102])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[102] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[103] && sm_s1_boreChildrenBd_bore_rdata[103])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[103] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[104] && sm_s1_boreChildrenBd_bore_rdata[104])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[104] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[105] && sm_s1_boreChildrenBd_bore_rdata[105])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[105] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[106] && sm_s1_boreChildrenBd_bore_rdata[106])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[106] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[107] && sm_s1_boreChildrenBd_bore_rdata[107])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[107] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[108] && sm_s1_boreChildrenBd_bore_rdata[108])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[108] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[109] && sm_s1_boreChildrenBd_bore_rdata[109])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[109] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[110] && sm_s1_boreChildrenBd_bore_rdata[110])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[110] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[111] && sm_s1_boreChildrenBd_bore_rdata[111])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[111] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[112] && sm_s1_boreChildrenBd_bore_rdata[112])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[112] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[113] && sm_s1_boreChildrenBd_bore_rdata[113])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[113] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[114] && sm_s1_boreChildrenBd_bore_rdata[114])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[114] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[115] && sm_s1_boreChildrenBd_bore_rdata[115])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[115] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[116] && sm_s1_boreChildrenBd_bore_rdata[116])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[116] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[117] && sm_s1_boreChildrenBd_bore_rdata[117])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[117] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[118] && sm_s1_boreChildrenBd_bore_rdata[118])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[118] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[119] && sm_s1_boreChildrenBd_bore_rdata[119])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[119] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[120] && sm_s1_boreChildrenBd_bore_rdata[120])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[120] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[121] && sm_s1_boreChildrenBd_bore_rdata[121])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[121] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[122] && sm_s1_boreChildrenBd_bore_rdata[122])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[122] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[123] && sm_s1_boreChildrenBd_bore_rdata[123])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[123] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[124] && sm_s1_boreChildrenBd_bore_rdata[124])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[124] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[125] && sm_s1_boreChildrenBd_bore_rdata[125])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[125] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[126] && sm_s1_boreChildrenBd_bore_rdata[126])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[126] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[127] && sm_s1_boreChildrenBd_bore_rdata[127])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[127] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[128] && sm_s1_boreChildrenBd_bore_rdata[128])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[128] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[129] && sm_s1_boreChildrenBd_bore_rdata[129])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[129] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[130] && sm_s1_boreChildrenBd_bore_rdata[130])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[130] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[131] && sm_s1_boreChildrenBd_bore_rdata[131])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[131] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[132] && sm_s1_boreChildrenBd_bore_rdata[132])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[132] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[133] && sm_s1_boreChildrenBd_bore_rdata[133])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[133] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[134] && sm_s1_boreChildrenBd_bore_rdata[134])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[134] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[135] && sm_s1_boreChildrenBd_bore_rdata[135])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[135] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[136] && sm_s1_boreChildrenBd_bore_rdata[136])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[136] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[137] && sm_s1_boreChildrenBd_bore_rdata[137])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[137] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[138] && sm_s1_boreChildrenBd_bore_rdata[138])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[138] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[139] && sm_s1_boreChildrenBd_bore_rdata[139])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[139] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[140] && sm_s1_boreChildrenBd_bore_rdata[140])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[140] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[141] && sm_s1_boreChildrenBd_bore_rdata[141])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[141] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[142] && sm_s1_boreChildrenBd_bore_rdata[142])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[142] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[143] && sm_s1_boreChildrenBd_bore_rdata[143])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[143] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[144] && sm_s1_boreChildrenBd_bore_rdata[144])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[144] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[145] && sm_s1_boreChildrenBd_bore_rdata[145])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[145] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[146] && sm_s1_boreChildrenBd_bore_rdata[146])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[146] 未见过 0 和 1"); end
    if (!(sm_s0_boreChildrenBd_bore_rdata[147] && sm_s1_boreChildrenBd_bore_rdata[147])) begin cov_fail++; $display("[COV] SMSPrefetcher.boreChildrenBd_bore_rdata[147] 未见过 0 和 1"); end
    $display("[ARM] SMSPrefetcher armed_at=%0d", sm_armed_at);
    if (sm_armed_at < 0) begin cov_fail++; $display("[ARM] SMSPrefetcher 从未 arm"); end
    $display("[COV] SMSPrefetcher.train_req = %0d", sm_cov_train_req);
    if (sm_cov_train_req < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.train_req < 5"); end
    $display("[COV] SMSPrefetcher.agt_evict = %0d", sm_cov_agt_evict);
    if (sm_cov_agt_evict < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.agt_evict < 5"); end
    $display("[COV] SMSPrefetcher.agt_lookup = %0d", sm_cov_agt_lookup);
    if (sm_cov_agt_lookup < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.agt_lookup < 5"); end
    $display("[COV] SMSPrefetcher.no_cross_p1 = %0d", sm_cov_no_cross_p1);
    if (sm_cov_no_cross_p1 < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.no_cross_p1 < 5"); end
    $display("[COV] SMSPrefetcher.no_cross_m1 = %0d", sm_cov_no_cross_m1);
    if (sm_cov_no_cross_m1 < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.no_cross_m1 < 5"); end
    $display("[COV] SMSPrefetcher.pht_gen = %0d", sm_cov_pht_gen);
    if (sm_cov_pht_gen < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.pht_gen < 5"); end
    $display("[COV] SMSPrefetcher.pht_gated = %0d", sm_cov_pht_gated);
    if (sm_cov_pht_gated < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.pht_gated < 5"); end
    $display("[COV] SMSPrefetcher.tlb_req = %0d", sm_cov_tlb_req);
    if (sm_cov_tlb_req < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.tlb_req < 5"); end
    $display("[COV] SMSPrefetcher.pf_out = %0d", sm_cov_pf_out);
    if (sm_cov_pf_out < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.pf_out < 5"); end
    $display("[COV] SMSPrefetcher.l2_req = %0d", sm_cov_l2_req);
    if (sm_cov_l2_req < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.l2_req < 5"); end
    $display("[COV] SMSPrefetcher.l2_out_range = %0d", sm_cov_l2_out_range);
    if (sm_cov_l2_out_range < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.l2_out_range < 5"); end
    $display("[COV] SMSPrefetcher.l2_disabled = %0d", sm_cov_l2_disabled);
    if (sm_cov_l2_disabled < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.l2_disabled < 5"); end
    $display("[COV] SMSPrefetcher.reset_mid = %0d", sm_cov_reset_mid);
    if (sm_cov_reset_mid < 5) begin cov_fail++; $display("[COV] SMSPrefetcher.reset_mid < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
