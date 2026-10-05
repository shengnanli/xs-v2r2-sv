// 自动生成：verif/ut/PatternHistoryTable/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// PatternHistoryTable 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= PatternHistoryTable =================
  int unsigned ph_mode = 0;
  logic [12:0] ph_tags [6];
  initial for (int i = 0; i < 6; i++) ph_tags[i] = 13'($urandom);
  // 厂商 SRAM 行为模型（两侧同一份 golden array_12_ext）的存储阵列与读地址寄存器上电不复位：
  // +vcs+initreg+<seed> 下两个实例各摇各的初值，MBIST 读到没写过的行时两侧不同（与重写无关）。
  // 0 时刻之后把重写侧拷成 golden 侧（普通 always 驱动的变量，可直接过程赋值；只对齐上电初值）。
  initial begin
    #1;
    for (int k = 0; k < 32; k++)
      ph_u_impl.pht_ram.array.array.array_12_ext.ram[k] = ph_u_gold.pht_ram.array.array.array_12_ext.ram[k];
    ph_u_impl.pht_ram.array.array.array_12_ext.reg_RW0_addr = ph_u_gold.pht_ram.array.array.array_12_ext.reg_RW0_addr;
    ph_u_impl.pht_ram.array.array.array_12_ext.reg_RW0_ren = ph_u_gold.pht_ram.array.array.array_12_ext.reg_RW0_ren;
  end
  logic ph_reset;
  logic ph_io_agt_update_valid;
  logic [4:0] ph_io_agt_update_bits_pht_index;
  logic [12:0] ph_io_agt_update_bits_pht_tag;
  logic [15:0] ph_io_agt_update_bits_region_bits;
  logic [15:0] ph_io_agt_update_bits_region_bit_single;
  logic [3:0] ph_io_agt_update_bits_region_offset;
  logic [3:0] ph_io_agt_update_bits_access_cnt;
  logic ph_io_agt_update_bits_decr_mode;
  logic ph_io_agt_update_bits_single_update;
  logic ph_io_agt_update_bits_has_been_signal_updated;
  logic ph_io_s2_agt_lookup_valid;
  logic [4:0] ph_io_s2_agt_lookup_bits_pht_index;
  logic [12:0] ph_io_s2_agt_lookup_bits_pht_tag;
  logic [39:0] ph_io_s2_agt_lookup_bits_region_paddr;
  logic [39:0] ph_io_s2_agt_lookup_bits_region_vaddr;
  logic [3:0] ph_io_s2_agt_lookup_bits_region_offset;
  wire  ph_g_io_pf_gen_req_valid, ph_i_io_pf_gen_req_valid;
  logic ph_s0_io_pf_gen_req_valid = '0, ph_s1_io_pf_gen_req_valid = '0;
  wire  [10:0] ph_g_io_pf_gen_req_bits_region_tag, ph_i_io_pf_gen_req_bits_region_tag;
  logic [10:0] ph_s0_io_pf_gen_req_bits_region_tag = '0, ph_s1_io_pf_gen_req_bits_region_tag = '0;
  wire  [39:0] ph_g_io_pf_gen_req_bits_region_addr, ph_i_io_pf_gen_req_bits_region_addr;
  logic [39:0] ph_s0_io_pf_gen_req_bits_region_addr = '0, ph_s1_io_pf_gen_req_bits_region_addr = '0;
  wire  [15:0] ph_g_io_pf_gen_req_bits_region_bits, ph_i_io_pf_gen_req_bits_region_bits;
  logic [15:0] ph_s0_io_pf_gen_req_bits_region_bits = '0, ph_s1_io_pf_gen_req_bits_region_bits = '0;
  wire  ph_g_io_pf_gen_req_bits_paddr_valid, ph_i_io_pf_gen_req_bits_paddr_valid;
  logic ph_s0_io_pf_gen_req_bits_paddr_valid = '0, ph_s1_io_pf_gen_req_bits_paddr_valid = '0;
  wire  ph_g_io_pf_gen_req_bits_decr_mode, ph_i_io_pf_gen_req_bits_decr_mode;
  logic ph_s0_io_pf_gen_req_bits_decr_mode = '0, ph_s1_io_pf_gen_req_bits_decr_mode = '0;
  logic [5:0] ph_boreChildrenBd_bore_addr;
  logic [5:0] ph_boreChildrenBd_bore_addr_rd;
  logic [147:0] ph_boreChildrenBd_bore_wdata;
  logic [1:0] ph_boreChildrenBd_bore_wmask;
  logic ph_boreChildrenBd_bore_re;
  logic ph_boreChildrenBd_bore_we;
  wire  [147:0] ph_g_boreChildrenBd_bore_rdata, ph_i_boreChildrenBd_bore_rdata;
  logic [147:0] ph_s0_boreChildrenBd_bore_rdata = '0, ph_s1_boreChildrenBd_bore_rdata = '0;
  logic ph_boreChildrenBd_bore_ack;
  logic ph_boreChildrenBd_bore_selectedOH;
  logic [6:0] ph_boreChildrenBd_bore_array;
  logic ph_sigFromSrams_bore_ram_hold;
  logic ph_sigFromSrams_bore_ram_bypass;
  logic ph_sigFromSrams_bore_ram_bp_clken;
  logic ph_sigFromSrams_bore_ram_aux_clk;
  logic ph_sigFromSrams_bore_ram_aux_ckbp;
  logic ph_sigFromSrams_bore_ram_mcp_hold;
  logic ph_sigFromSrams_bore_cgen;
  int ph_cov_evict_hit = 0;
  int ph_cov_evict_miss = 0;
  int ph_cov_lookup_hit = 0;
  int ph_cov_single_skip = 0;
  int ph_cov_s1_wait = 0;
  int ph_cov_cur_req = 0;
  int ph_cov_incr_req = 0;
  int ph_cov_decr_req = 0;
  int ph_cov_incr_held = 0;
  int ph_cov_crosspage = 0;
  int ph_cov_pf_out = 0;
  int ph_cov_reset_mid = 0;
  logic [3:0] ph_armed = '0;
  int ph_armed_at = -1;
  PatternHistoryTable ph_u_gold (
    .clock(clk),
    .reset(ph_reset),
    .io_agt_update_valid(ph_io_agt_update_valid),
    .io_agt_update_bits_pht_index(ph_io_agt_update_bits_pht_index),
    .io_agt_update_bits_pht_tag(ph_io_agt_update_bits_pht_tag),
    .io_agt_update_bits_region_bits(ph_io_agt_update_bits_region_bits),
    .io_agt_update_bits_region_bit_single(ph_io_agt_update_bits_region_bit_single),
    .io_agt_update_bits_region_offset(ph_io_agt_update_bits_region_offset),
    .io_agt_update_bits_access_cnt(ph_io_agt_update_bits_access_cnt),
    .io_agt_update_bits_decr_mode(ph_io_agt_update_bits_decr_mode),
    .io_agt_update_bits_single_update(ph_io_agt_update_bits_single_update),
    .io_agt_update_bits_has_been_signal_updated(ph_io_agt_update_bits_has_been_signal_updated),
    .io_s2_agt_lookup_valid(ph_io_s2_agt_lookup_valid),
    .io_s2_agt_lookup_bits_pht_index(ph_io_s2_agt_lookup_bits_pht_index),
    .io_s2_agt_lookup_bits_pht_tag(ph_io_s2_agt_lookup_bits_pht_tag),
    .io_s2_agt_lookup_bits_region_paddr(ph_io_s2_agt_lookup_bits_region_paddr),
    .io_s2_agt_lookup_bits_region_vaddr(ph_io_s2_agt_lookup_bits_region_vaddr),
    .io_s2_agt_lookup_bits_region_offset(ph_io_s2_agt_lookup_bits_region_offset),
    .io_pf_gen_req_valid(ph_g_io_pf_gen_req_valid),
    .io_pf_gen_req_bits_region_tag(ph_g_io_pf_gen_req_bits_region_tag),
    .io_pf_gen_req_bits_region_addr(ph_g_io_pf_gen_req_bits_region_addr),
    .io_pf_gen_req_bits_region_bits(ph_g_io_pf_gen_req_bits_region_bits),
    .io_pf_gen_req_bits_paddr_valid(ph_g_io_pf_gen_req_bits_paddr_valid),
    .io_pf_gen_req_bits_decr_mode(ph_g_io_pf_gen_req_bits_decr_mode),
    .boreChildrenBd_bore_addr(ph_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(ph_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(ph_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(ph_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(ph_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(ph_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(ph_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(ph_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(ph_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(ph_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(ph_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(ph_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(ph_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(ph_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(ph_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(ph_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(ph_sigFromSrams_bore_cgen)
  );
  PatternHistoryTable_xs ph_u_impl (
    .clock(clk),
    .reset(ph_reset),
    .io_agt_update_valid(ph_io_agt_update_valid),
    .io_agt_update_bits_pht_index(ph_io_agt_update_bits_pht_index),
    .io_agt_update_bits_pht_tag(ph_io_agt_update_bits_pht_tag),
    .io_agt_update_bits_region_bits(ph_io_agt_update_bits_region_bits),
    .io_agt_update_bits_region_bit_single(ph_io_agt_update_bits_region_bit_single),
    .io_agt_update_bits_region_offset(ph_io_agt_update_bits_region_offset),
    .io_agt_update_bits_access_cnt(ph_io_agt_update_bits_access_cnt),
    .io_agt_update_bits_decr_mode(ph_io_agt_update_bits_decr_mode),
    .io_agt_update_bits_single_update(ph_io_agt_update_bits_single_update),
    .io_agt_update_bits_has_been_signal_updated(ph_io_agt_update_bits_has_been_signal_updated),
    .io_s2_agt_lookup_valid(ph_io_s2_agt_lookup_valid),
    .io_s2_agt_lookup_bits_pht_index(ph_io_s2_agt_lookup_bits_pht_index),
    .io_s2_agt_lookup_bits_pht_tag(ph_io_s2_agt_lookup_bits_pht_tag),
    .io_s2_agt_lookup_bits_region_paddr(ph_io_s2_agt_lookup_bits_region_paddr),
    .io_s2_agt_lookup_bits_region_vaddr(ph_io_s2_agt_lookup_bits_region_vaddr),
    .io_s2_agt_lookup_bits_region_offset(ph_io_s2_agt_lookup_bits_region_offset),
    .io_pf_gen_req_valid(ph_i_io_pf_gen_req_valid),
    .io_pf_gen_req_bits_region_tag(ph_i_io_pf_gen_req_bits_region_tag),
    .io_pf_gen_req_bits_region_addr(ph_i_io_pf_gen_req_bits_region_addr),
    .io_pf_gen_req_bits_region_bits(ph_i_io_pf_gen_req_bits_region_bits),
    .io_pf_gen_req_bits_paddr_valid(ph_i_io_pf_gen_req_bits_paddr_valid),
    .io_pf_gen_req_bits_decr_mode(ph_i_io_pf_gen_req_bits_decr_mode),
    .boreChildrenBd_bore_addr(ph_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(ph_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(ph_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(ph_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(ph_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(ph_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(ph_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(ph_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(ph_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(ph_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(ph_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(ph_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(ph_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(ph_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(ph_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(ph_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(ph_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) ph_mode = $urandom_range(0, 15);
      ph_io_agt_update_valid = 1'($urandom);
      ph_io_agt_update_bits_pht_index = 5'($urandom);
      ph_io_agt_update_bits_pht_tag = 13'($urandom);
      ph_io_agt_update_bits_region_bits = 16'($urandom);
      ph_io_agt_update_bits_region_bit_single = 16'($urandom);
      ph_io_agt_update_bits_region_offset = 4'($urandom);
      ph_io_agt_update_bits_access_cnt = 4'($urandom);
      ph_io_agt_update_bits_decr_mode = 1'($urandom);
      ph_io_agt_update_bits_single_update = 1'($urandom);
      ph_io_agt_update_bits_has_been_signal_updated = 1'($urandom);
      ph_io_s2_agt_lookup_valid = 1'($urandom);
      ph_io_s2_agt_lookup_bits_pht_index = 5'($urandom);
      ph_io_s2_agt_lookup_bits_pht_tag = 13'($urandom);
      ph_io_s2_agt_lookup_bits_region_paddr = 40'({$urandom, $urandom});
      ph_io_s2_agt_lookup_bits_region_vaddr = 40'({$urandom, $urandom});
      ph_io_s2_agt_lookup_bits_region_offset = 4'($urandom);
      ph_boreChildrenBd_bore_addr = 6'($urandom);
      ph_boreChildrenBd_bore_addr_rd = 6'($urandom);
      ph_boreChildrenBd_bore_wdata = 148'({$urandom, $urandom, $urandom, $urandom, $urandom});
      ph_boreChildrenBd_bore_wmask = 2'($urandom);
      ph_boreChildrenBd_bore_re = 1'($urandom);
      ph_boreChildrenBd_bore_we = 1'($urandom);
      ph_boreChildrenBd_bore_ack = 1'($urandom);
      ph_boreChildrenBd_bore_selectedOH = 1'($urandom);
      ph_boreChildrenBd_bore_array = 7'($urandom);
      ph_sigFromSrams_bore_ram_hold = 1'($urandom);
      ph_sigFromSrams_bore_ram_bypass = 1'($urandom);
      ph_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      ph_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      ph_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      ph_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      ph_sigFromSrams_bore_cgen = 1'($urandom);
      ph_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_ph
        ph_io_agt_update_valid = ($urandom_range(0, 1) != 0);
        ph_io_agt_update_bits_pht_index = 5'($urandom_range(0, 3));
        ph_io_agt_update_bits_pht_tag = ph_tags[$urandom_range(0, 5)];
        ph_io_agt_update_bits_single_update = ($urandom_range(0, 3) == 0);
        ph_io_agt_update_bits_has_been_signal_updated = ($urandom_range(0, 3) == 0);
        ph_io_s2_agt_lookup_valid = ($urandom_range(0, 1) != 0);
        ph_io_s2_agt_lookup_bits_pht_index = 5'($urandom_range(0, 3));
        ph_io_s2_agt_lookup_bits_pht_tag = ph_tags[$urandom_range(0, 5)];
        case ($urandom_range(0, 3))
          0: ph_io_s2_agt_lookup_bits_region_vaddr[1:0] = 2'b00;
          1: ph_io_s2_agt_lookup_bits_region_vaddr[1:0] = 2'b11;
          default: ;
        endcase
        if (ph_mode != 0) begin
          ph_boreChildrenBd_bore_re = '0;
          ph_boreChildrenBd_bore_we = '0;
          ph_boreChildrenBd_bore_ack = '0;
          ph_boreChildrenBd_bore_selectedOH = '0;
          ph_boreChildrenBd_bore_array = '0;
          ph_boreChildrenBd_bore_wmask = '0;
          ph_sigFromSrams_bore_ram_hold = '0;
          ph_sigFromSrams_bore_ram_bypass = '0;
          ph_sigFromSrams_bore_ram_bp_clken = '0;
          ph_sigFromSrams_bore_ram_aux_clk = '0;
          ph_sigFromSrams_bore_ram_aux_ckbp = '0;
          ph_sigFromSrams_bore_ram_mcp_hold = '0;
          ph_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && ph_armed_at >= 0 && cyc >= ph_armed_at) begin
        checks++;
        if (ph_g_io_pf_gen_req_valid !== ph_i_io_pf_gen_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.io_pf_gen_req_valid g=%h i=%h", cyc, ph_g_io_pf_gen_req_valid, ph_i_io_pf_gen_req_valid);
        end
        ph_s1_io_pf_gen_req_valid |= ph_g_io_pf_gen_req_valid;
        ph_s0_io_pf_gen_req_valid |= ~ph_g_io_pf_gen_req_valid;
        checks++;
        if (ph_g_io_pf_gen_req_bits_region_tag !== ph_i_io_pf_gen_req_bits_region_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.io_pf_gen_req_bits_region_tag g=%h i=%h", cyc, ph_g_io_pf_gen_req_bits_region_tag, ph_i_io_pf_gen_req_bits_region_tag);
        end
        ph_s1_io_pf_gen_req_bits_region_tag |= ph_g_io_pf_gen_req_bits_region_tag;
        ph_s0_io_pf_gen_req_bits_region_tag |= ~ph_g_io_pf_gen_req_bits_region_tag;
        checks++;
        if (ph_g_io_pf_gen_req_bits_region_addr !== ph_i_io_pf_gen_req_bits_region_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.io_pf_gen_req_bits_region_addr g=%h i=%h", cyc, ph_g_io_pf_gen_req_bits_region_addr, ph_i_io_pf_gen_req_bits_region_addr);
        end
        ph_s1_io_pf_gen_req_bits_region_addr |= ph_g_io_pf_gen_req_bits_region_addr;
        ph_s0_io_pf_gen_req_bits_region_addr |= ~ph_g_io_pf_gen_req_bits_region_addr;
        checks++;
        if (ph_g_io_pf_gen_req_bits_region_bits !== ph_i_io_pf_gen_req_bits_region_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.io_pf_gen_req_bits_region_bits g=%h i=%h", cyc, ph_g_io_pf_gen_req_bits_region_bits, ph_i_io_pf_gen_req_bits_region_bits);
        end
        ph_s1_io_pf_gen_req_bits_region_bits |= ph_g_io_pf_gen_req_bits_region_bits;
        ph_s0_io_pf_gen_req_bits_region_bits |= ~ph_g_io_pf_gen_req_bits_region_bits;
        checks++;
        if (ph_g_io_pf_gen_req_bits_paddr_valid !== ph_i_io_pf_gen_req_bits_paddr_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.io_pf_gen_req_bits_paddr_valid g=%h i=%h", cyc, ph_g_io_pf_gen_req_bits_paddr_valid, ph_i_io_pf_gen_req_bits_paddr_valid);
        end
        ph_s1_io_pf_gen_req_bits_paddr_valid |= ph_g_io_pf_gen_req_bits_paddr_valid;
        ph_s0_io_pf_gen_req_bits_paddr_valid |= ~ph_g_io_pf_gen_req_bits_paddr_valid;
        checks++;
        if (ph_g_io_pf_gen_req_bits_decr_mode !== ph_i_io_pf_gen_req_bits_decr_mode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.io_pf_gen_req_bits_decr_mode g=%h i=%h", cyc, ph_g_io_pf_gen_req_bits_decr_mode, ph_i_io_pf_gen_req_bits_decr_mode);
        end
        ph_s1_io_pf_gen_req_bits_decr_mode |= ph_g_io_pf_gen_req_bits_decr_mode;
        ph_s0_io_pf_gen_req_bits_decr_mode |= ~ph_g_io_pf_gen_req_bits_decr_mode;
        checks++;
        if (ph_g_boreChildrenBd_bore_rdata !== ph_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PatternHistoryTable.boreChildrenBd_bore_rdata g=%h i=%h", cyc, ph_g_boreChildrenBd_bore_rdata, ph_i_boreChildrenBd_bore_rdata);
        end
        ph_s1_boreChildrenBd_bore_rdata |= ph_g_boreChildrenBd_bore_rdata;
        ph_s0_boreChildrenBd_bore_rdata |= ~ph_g_boreChildrenBd_bore_rdata;
        if (ph_u_gold.s2_valid_last_REG && ph_u_gold.s2_evict && (|ph_u_gold._s2_pht_hit_T)) ph_cov_evict_hit++;
        if (ph_u_gold.s2_valid_last_REG && ph_u_gold.s2_evict && !(|ph_u_gold._s2_pht_hit_T)) ph_cov_evict_miss++;
        if (ph_u_gold.s2_valid_last_REG && !ph_u_gold.s2_evict && (|ph_u_gold._s2_pht_hit_T)) ph_cov_lookup_hit++;
        if (ph_u_gold.s2_valid_last_REG && ph_u_gold.s2_single_update && !(|ph_u_gold._s2_pht_hit_T) && ph_u_gold.s2_access_cnt_signal <= 4) ph_cov_single_skip++;
        if (ph_u_gold.s1_valid_r && ph_u_gold.s1_wait) ph_cov_s1_wait++;
        if (ph_u_gold.s3_cur_region_valid) ph_cov_cur_req++;
        if (ph_u_gold.s3_incr_region_valid) ph_cov_incr_req++;
        if (ph_u_gold.s3_decr_region_valid) ph_cov_decr_req++;
        if (ph_u_gold.s4_pf_gen_incr_region_valid && !ph_u_gold._pf_gen_req_arb_io_in_1_ready) ph_cov_incr_held++;
        if (ph_g_io_pf_gen_req_valid && !ph_g_io_pf_gen_req_bits_paddr_valid) ph_cov_crosspage++;
        if (ph_g_io_pf_gen_req_valid) ph_cov_pf_out++;
        if (ph_reset && cyc > 100) ph_cov_reset_mid++;
      end
      if (ph_u_gold.s3_cur_region_valid) ph_armed[0] = 1'b1;
      if (ph_u_gold.s3_incr_region_valid) ph_armed[1] = 1'b1;
      if (ph_u_gold.s3_decr_region_valid) ph_armed[2] = 1'b1;
      if (ph_u_gold.pht_ram.respReg) ph_armed[3] = 1'b1;
      if (ph_armed_at < 0 && (&ph_armed)) ph_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(ph_s0_io_pf_gen_req_valid && ph_s1_io_pf_gen_req_valid)) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_valid 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[0] && ph_s1_io_pf_gen_req_bits_region_tag[0])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[0] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[1] && ph_s1_io_pf_gen_req_bits_region_tag[1])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[1] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[2] && ph_s1_io_pf_gen_req_bits_region_tag[2])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[2] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[3] && ph_s1_io_pf_gen_req_bits_region_tag[3])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[3] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[4] && ph_s1_io_pf_gen_req_bits_region_tag[4])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[4] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[5] && ph_s1_io_pf_gen_req_bits_region_tag[5])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[5] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[6] && ph_s1_io_pf_gen_req_bits_region_tag[6])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[6] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[7] && ph_s1_io_pf_gen_req_bits_region_tag[7])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[7] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[8] && ph_s1_io_pf_gen_req_bits_region_tag[8])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[8] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[9] && ph_s1_io_pf_gen_req_bits_region_tag[9])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[9] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_tag[10] && ph_s1_io_pf_gen_req_bits_region_tag[10])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_tag[10] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[0] && ph_s1_io_pf_gen_req_bits_region_addr[0])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[0] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[1] && ph_s1_io_pf_gen_req_bits_region_addr[1])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[1] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[2] && ph_s1_io_pf_gen_req_bits_region_addr[2])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[2] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[3] && ph_s1_io_pf_gen_req_bits_region_addr[3])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[3] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[4] && ph_s1_io_pf_gen_req_bits_region_addr[4])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[4] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[5] && ph_s1_io_pf_gen_req_bits_region_addr[5])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[5] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[6] && ph_s1_io_pf_gen_req_bits_region_addr[6])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[6] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[7] && ph_s1_io_pf_gen_req_bits_region_addr[7])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[7] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[8] && ph_s1_io_pf_gen_req_bits_region_addr[8])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[8] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[9] && ph_s1_io_pf_gen_req_bits_region_addr[9])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[9] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[10] && ph_s1_io_pf_gen_req_bits_region_addr[10])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[10] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[11] && ph_s1_io_pf_gen_req_bits_region_addr[11])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[11] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[12] && ph_s1_io_pf_gen_req_bits_region_addr[12])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[12] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[13] && ph_s1_io_pf_gen_req_bits_region_addr[13])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[13] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[14] && ph_s1_io_pf_gen_req_bits_region_addr[14])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[14] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[15] && ph_s1_io_pf_gen_req_bits_region_addr[15])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[15] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[16] && ph_s1_io_pf_gen_req_bits_region_addr[16])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[16] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[17] && ph_s1_io_pf_gen_req_bits_region_addr[17])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[17] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[18] && ph_s1_io_pf_gen_req_bits_region_addr[18])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[18] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[19] && ph_s1_io_pf_gen_req_bits_region_addr[19])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[19] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[20] && ph_s1_io_pf_gen_req_bits_region_addr[20])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[20] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[21] && ph_s1_io_pf_gen_req_bits_region_addr[21])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[21] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[22] && ph_s1_io_pf_gen_req_bits_region_addr[22])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[22] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[23] && ph_s1_io_pf_gen_req_bits_region_addr[23])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[23] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[24] && ph_s1_io_pf_gen_req_bits_region_addr[24])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[24] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[25] && ph_s1_io_pf_gen_req_bits_region_addr[25])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[25] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[26] && ph_s1_io_pf_gen_req_bits_region_addr[26])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[26] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[27] && ph_s1_io_pf_gen_req_bits_region_addr[27])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[27] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[28] && ph_s1_io_pf_gen_req_bits_region_addr[28])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[28] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[29] && ph_s1_io_pf_gen_req_bits_region_addr[29])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[29] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[30] && ph_s1_io_pf_gen_req_bits_region_addr[30])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[30] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[31] && ph_s1_io_pf_gen_req_bits_region_addr[31])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[31] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[32] && ph_s1_io_pf_gen_req_bits_region_addr[32])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[32] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[33] && ph_s1_io_pf_gen_req_bits_region_addr[33])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[33] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[34] && ph_s1_io_pf_gen_req_bits_region_addr[34])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[34] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[35] && ph_s1_io_pf_gen_req_bits_region_addr[35])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[35] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[36] && ph_s1_io_pf_gen_req_bits_region_addr[36])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[36] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[37] && ph_s1_io_pf_gen_req_bits_region_addr[37])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[37] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[38] && ph_s1_io_pf_gen_req_bits_region_addr[38])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[38] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_addr[39] && ph_s1_io_pf_gen_req_bits_region_addr[39])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_addr[39] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[0] && ph_s1_io_pf_gen_req_bits_region_bits[0])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[0] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[1] && ph_s1_io_pf_gen_req_bits_region_bits[1])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[1] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[2] && ph_s1_io_pf_gen_req_bits_region_bits[2])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[2] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[3] && ph_s1_io_pf_gen_req_bits_region_bits[3])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[3] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[4] && ph_s1_io_pf_gen_req_bits_region_bits[4])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[4] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[5] && ph_s1_io_pf_gen_req_bits_region_bits[5])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[5] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[6] && ph_s1_io_pf_gen_req_bits_region_bits[6])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[6] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[7] && ph_s1_io_pf_gen_req_bits_region_bits[7])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[7] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[8] && ph_s1_io_pf_gen_req_bits_region_bits[8])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[8] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[9] && ph_s1_io_pf_gen_req_bits_region_bits[9])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[9] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[10] && ph_s1_io_pf_gen_req_bits_region_bits[10])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[10] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[11] && ph_s1_io_pf_gen_req_bits_region_bits[11])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[11] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[12] && ph_s1_io_pf_gen_req_bits_region_bits[12])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[12] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[13] && ph_s1_io_pf_gen_req_bits_region_bits[13])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[13] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[14] && ph_s1_io_pf_gen_req_bits_region_bits[14])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[14] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_region_bits[15] && ph_s1_io_pf_gen_req_bits_region_bits[15])) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_region_bits[15] 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_paddr_valid && ph_s1_io_pf_gen_req_bits_paddr_valid)) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_paddr_valid 未见过 0 和 1"); end
    if (!(ph_s0_io_pf_gen_req_bits_decr_mode && ph_s1_io_pf_gen_req_bits_decr_mode)) begin cov_fail++; $display("[COV] PatternHistoryTable.io_pf_gen_req_bits_decr_mode 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[0] && ph_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[1] && ph_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[2] && ph_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[3] && ph_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[4] && ph_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[5] && ph_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[6] && ph_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[7] && ph_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[8] && ph_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[9] && ph_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[10] && ph_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[11] && ph_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[12] && ph_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[13] && ph_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[14] && ph_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[15] && ph_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[16] && ph_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[17] && ph_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[18] && ph_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[19] && ph_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[20] && ph_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[21] && ph_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[22] && ph_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[23] && ph_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[24] && ph_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[25] && ph_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[26] && ph_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[27] && ph_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[28] && ph_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[29] && ph_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[30] && ph_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[31] && ph_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[32] && ph_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[33] && ph_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[34] && ph_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[35] && ph_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[36] && ph_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[37] && ph_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[38] && ph_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[39] && ph_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[40] && ph_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[41] && ph_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[42] && ph_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[43] && ph_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[44] && ph_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[45] && ph_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[46] && ph_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[47] && ph_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[48] && ph_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[49] && ph_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[50] && ph_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[51] && ph_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[52] && ph_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[53] && ph_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[54] && ph_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[55] && ph_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[56] && ph_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[57] && ph_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[58] && ph_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[59] && ph_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[60] && ph_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[61] && ph_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[62] && ph_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[63] && ph_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[64] && ph_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[65] && ph_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[66] && ph_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[67] && ph_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[68] && ph_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[69] && ph_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[70] && ph_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[71] && ph_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[72] && ph_s1_boreChildrenBd_bore_rdata[72])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[72] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[73] && ph_s1_boreChildrenBd_bore_rdata[73])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[73] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[74] && ph_s1_boreChildrenBd_bore_rdata[74])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[74] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[75] && ph_s1_boreChildrenBd_bore_rdata[75])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[75] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[76] && ph_s1_boreChildrenBd_bore_rdata[76])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[76] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[77] && ph_s1_boreChildrenBd_bore_rdata[77])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[77] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[78] && ph_s1_boreChildrenBd_bore_rdata[78])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[78] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[79] && ph_s1_boreChildrenBd_bore_rdata[79])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[79] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[80] && ph_s1_boreChildrenBd_bore_rdata[80])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[80] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[81] && ph_s1_boreChildrenBd_bore_rdata[81])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[81] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[82] && ph_s1_boreChildrenBd_bore_rdata[82])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[82] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[83] && ph_s1_boreChildrenBd_bore_rdata[83])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[83] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[84] && ph_s1_boreChildrenBd_bore_rdata[84])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[84] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[85] && ph_s1_boreChildrenBd_bore_rdata[85])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[85] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[86] && ph_s1_boreChildrenBd_bore_rdata[86])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[86] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[87] && ph_s1_boreChildrenBd_bore_rdata[87])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[87] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[88] && ph_s1_boreChildrenBd_bore_rdata[88])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[88] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[89] && ph_s1_boreChildrenBd_bore_rdata[89])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[89] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[90] && ph_s1_boreChildrenBd_bore_rdata[90])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[90] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[91] && ph_s1_boreChildrenBd_bore_rdata[91])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[91] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[92] && ph_s1_boreChildrenBd_bore_rdata[92])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[92] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[93] && ph_s1_boreChildrenBd_bore_rdata[93])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[93] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[94] && ph_s1_boreChildrenBd_bore_rdata[94])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[94] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[95] && ph_s1_boreChildrenBd_bore_rdata[95])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[95] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[96] && ph_s1_boreChildrenBd_bore_rdata[96])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[96] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[97] && ph_s1_boreChildrenBd_bore_rdata[97])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[97] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[98] && ph_s1_boreChildrenBd_bore_rdata[98])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[98] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[99] && ph_s1_boreChildrenBd_bore_rdata[99])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[99] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[100] && ph_s1_boreChildrenBd_bore_rdata[100])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[100] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[101] && ph_s1_boreChildrenBd_bore_rdata[101])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[101] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[102] && ph_s1_boreChildrenBd_bore_rdata[102])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[102] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[103] && ph_s1_boreChildrenBd_bore_rdata[103])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[103] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[104] && ph_s1_boreChildrenBd_bore_rdata[104])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[104] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[105] && ph_s1_boreChildrenBd_bore_rdata[105])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[105] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[106] && ph_s1_boreChildrenBd_bore_rdata[106])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[106] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[107] && ph_s1_boreChildrenBd_bore_rdata[107])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[107] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[108] && ph_s1_boreChildrenBd_bore_rdata[108])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[108] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[109] && ph_s1_boreChildrenBd_bore_rdata[109])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[109] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[110] && ph_s1_boreChildrenBd_bore_rdata[110])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[110] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[111] && ph_s1_boreChildrenBd_bore_rdata[111])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[111] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[112] && ph_s1_boreChildrenBd_bore_rdata[112])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[112] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[113] && ph_s1_boreChildrenBd_bore_rdata[113])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[113] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[114] && ph_s1_boreChildrenBd_bore_rdata[114])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[114] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[115] && ph_s1_boreChildrenBd_bore_rdata[115])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[115] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[116] && ph_s1_boreChildrenBd_bore_rdata[116])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[116] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[117] && ph_s1_boreChildrenBd_bore_rdata[117])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[117] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[118] && ph_s1_boreChildrenBd_bore_rdata[118])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[118] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[119] && ph_s1_boreChildrenBd_bore_rdata[119])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[119] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[120] && ph_s1_boreChildrenBd_bore_rdata[120])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[120] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[121] && ph_s1_boreChildrenBd_bore_rdata[121])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[121] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[122] && ph_s1_boreChildrenBd_bore_rdata[122])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[122] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[123] && ph_s1_boreChildrenBd_bore_rdata[123])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[123] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[124] && ph_s1_boreChildrenBd_bore_rdata[124])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[124] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[125] && ph_s1_boreChildrenBd_bore_rdata[125])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[125] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[126] && ph_s1_boreChildrenBd_bore_rdata[126])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[126] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[127] && ph_s1_boreChildrenBd_bore_rdata[127])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[127] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[128] && ph_s1_boreChildrenBd_bore_rdata[128])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[128] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[129] && ph_s1_boreChildrenBd_bore_rdata[129])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[129] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[130] && ph_s1_boreChildrenBd_bore_rdata[130])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[130] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[131] && ph_s1_boreChildrenBd_bore_rdata[131])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[131] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[132] && ph_s1_boreChildrenBd_bore_rdata[132])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[132] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[133] && ph_s1_boreChildrenBd_bore_rdata[133])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[133] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[134] && ph_s1_boreChildrenBd_bore_rdata[134])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[134] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[135] && ph_s1_boreChildrenBd_bore_rdata[135])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[135] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[136] && ph_s1_boreChildrenBd_bore_rdata[136])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[136] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[137] && ph_s1_boreChildrenBd_bore_rdata[137])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[137] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[138] && ph_s1_boreChildrenBd_bore_rdata[138])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[138] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[139] && ph_s1_boreChildrenBd_bore_rdata[139])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[139] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[140] && ph_s1_boreChildrenBd_bore_rdata[140])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[140] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[141] && ph_s1_boreChildrenBd_bore_rdata[141])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[141] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[142] && ph_s1_boreChildrenBd_bore_rdata[142])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[142] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[143] && ph_s1_boreChildrenBd_bore_rdata[143])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[143] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[144] && ph_s1_boreChildrenBd_bore_rdata[144])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[144] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[145] && ph_s1_boreChildrenBd_bore_rdata[145])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[145] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[146] && ph_s1_boreChildrenBd_bore_rdata[146])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[146] 未见过 0 和 1"); end
    if (!(ph_s0_boreChildrenBd_bore_rdata[147] && ph_s1_boreChildrenBd_bore_rdata[147])) begin cov_fail++; $display("[COV] PatternHistoryTable.boreChildrenBd_bore_rdata[147] 未见过 0 和 1"); end
    $display("[ARM] PatternHistoryTable armed_at=%0d", ph_armed_at);
    if (ph_armed_at < 0) begin cov_fail++; $display("[ARM] PatternHistoryTable 从未 arm"); end
    $display("[COV] PatternHistoryTable.evict_hit = %0d", ph_cov_evict_hit);
    if (ph_cov_evict_hit < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.evict_hit < 5"); end
    $display("[COV] PatternHistoryTable.evict_miss = %0d", ph_cov_evict_miss);
    if (ph_cov_evict_miss < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.evict_miss < 5"); end
    $display("[COV] PatternHistoryTable.lookup_hit = %0d", ph_cov_lookup_hit);
    if (ph_cov_lookup_hit < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.lookup_hit < 5"); end
    $display("[COV] PatternHistoryTable.single_skip = %0d", ph_cov_single_skip);
    if (ph_cov_single_skip < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.single_skip < 5"); end
    $display("[COV] PatternHistoryTable.s1_wait = %0d", ph_cov_s1_wait);
    if (ph_cov_s1_wait < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.s1_wait < 5"); end
    $display("[COV] PatternHistoryTable.cur_req = %0d", ph_cov_cur_req);
    if (ph_cov_cur_req < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.cur_req < 5"); end
    $display("[COV] PatternHistoryTable.incr_req = %0d", ph_cov_incr_req);
    if (ph_cov_incr_req < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.incr_req < 5"); end
    $display("[COV] PatternHistoryTable.decr_req = %0d", ph_cov_decr_req);
    if (ph_cov_decr_req < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.decr_req < 5"); end
    $display("[COV] PatternHistoryTable.incr_held = %0d", ph_cov_incr_held);
    if (ph_cov_incr_held < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.incr_held < 5"); end
    $display("[COV] PatternHistoryTable.crosspage = %0d", ph_cov_crosspage);
    if (ph_cov_crosspage < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.crosspage < 5"); end
    $display("[COV] PatternHistoryTable.pf_out = %0d", ph_cov_pf_out);
    if (ph_cov_pf_out < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.pf_out < 5"); end
    $display("[COV] PatternHistoryTable.reset_mid = %0d", ph_cov_reset_mid);
    if (ph_cov_reset_mid < 5) begin cov_fail++; $display("[COV] PatternHistoryTable.reset_mid < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
