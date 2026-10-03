// 自动生成：verif/ut/ActiveGenerationTable/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// ActiveGenerationTable 双例化逐拍比对：golden vs 重写 ActiveGenerationTable_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= ActiveGenerationTable =================
  int unsigned agt_mode = 0;
  logic [3:0] agt_thr = 4'd2;
  logic [5:0] agt_stride = 6'd1;
  logic       agt_en_hold = 1'b1;
  function automatic logic [10:0] agt_rnd_tag(input int unsigned mode);
    int unsigned pool;
    case (mode % 4)
      0:       pool = 6;
      1:       pool = 20;
      2:       pool = 40;
      default: pool = 12;
    endcase
    // 池内下标 -> tag：低 6 位顺序排，高 5 位（哈希段）在 0/1 间交替，让比较覆盖到高位
    agt_rnd_tag = 11'($urandom_range(0, pool - 1));
    agt_rnd_tag[10:6] = 5'(agt_rnd_tag[0]);
  endfunction
  logic agt_reset;
  logic agt_io_agt_en;
  logic agt_io_s0_lookup_valid;
  logic [10:0] agt_io_s0_lookup_bits_region_tag;
  logic [10:0] agt_io_s0_lookup_bits_region_p1_tag;
  logic [10:0] agt_io_s0_lookup_bits_region_m1_tag;
  logic [3:0] agt_io_s0_lookup_bits_region_offset;
  logic [4:0] agt_io_s0_lookup_bits_pht_index;
  logic [12:0] agt_io_s0_lookup_bits_pht_tag;
  logic agt_io_s0_lookup_bits_allow_cross_region_p1;
  logic agt_io_s0_lookup_bits_allow_cross_region_m1;
  logic [39:0] agt_io_s0_lookup_bits_region_paddr;
  logic [39:0] agt_io_s0_lookup_bits_region_vaddr;
  logic agt_io_s0_dcache_evict_valid;
  logic [49:0] agt_io_s0_dcache_evict_bits_vaddr;
  wire  agt_g_io_s1_sel_stride, agt_i_io_s1_sel_stride;
  logic agt_s0_io_s1_sel_stride = '0, agt_s1_io_s1_sel_stride = '0;
  wire  agt_g_io_s2_pht_lookup_valid, agt_i_io_s2_pht_lookup_valid;
  logic agt_s0_io_s2_pht_lookup_valid = '0, agt_s1_io_s2_pht_lookup_valid = '0;
  wire  [4:0] agt_g_io_s2_pht_lookup_bits_pht_index, agt_i_io_s2_pht_lookup_bits_pht_index;
  logic [4:0] agt_s0_io_s2_pht_lookup_bits_pht_index = '0, agt_s1_io_s2_pht_lookup_bits_pht_index = '0;
  wire  [12:0] agt_g_io_s2_pht_lookup_bits_pht_tag, agt_i_io_s2_pht_lookup_bits_pht_tag;
  logic [12:0] agt_s0_io_s2_pht_lookup_bits_pht_tag = '0, agt_s1_io_s2_pht_lookup_bits_pht_tag = '0;
  wire  [39:0] agt_g_io_s2_pht_lookup_bits_region_paddr, agt_i_io_s2_pht_lookup_bits_region_paddr;
  logic [39:0] agt_s0_io_s2_pht_lookup_bits_region_paddr = '0, agt_s1_io_s2_pht_lookup_bits_region_paddr = '0;
  wire  [39:0] agt_g_io_s2_pht_lookup_bits_region_vaddr, agt_i_io_s2_pht_lookup_bits_region_vaddr;
  logic [39:0] agt_s0_io_s2_pht_lookup_bits_region_vaddr = '0, agt_s1_io_s2_pht_lookup_bits_region_vaddr = '0;
  wire  [3:0] agt_g_io_s2_pht_lookup_bits_region_offset, agt_i_io_s2_pht_lookup_bits_region_offset;
  logic [3:0] agt_s0_io_s2_pht_lookup_bits_region_offset = '0, agt_s1_io_s2_pht_lookup_bits_region_offset = '0;
  wire  agt_g_io_s2_evict_valid, agt_i_io_s2_evict_valid;
  logic agt_s0_io_s2_evict_valid = '0, agt_s1_io_s2_evict_valid = '0;
  wire  [4:0] agt_g_io_s2_evict_bits_pht_index, agt_i_io_s2_evict_bits_pht_index;
  logic [4:0] agt_s0_io_s2_evict_bits_pht_index = '0, agt_s1_io_s2_evict_bits_pht_index = '0;
  wire  [12:0] agt_g_io_s2_evict_bits_pht_tag, agt_i_io_s2_evict_bits_pht_tag;
  logic [12:0] agt_s0_io_s2_evict_bits_pht_tag = '0, agt_s1_io_s2_evict_bits_pht_tag = '0;
  wire  [15:0] agt_g_io_s2_evict_bits_region_bits, agt_i_io_s2_evict_bits_region_bits;
  logic [15:0] agt_s0_io_s2_evict_bits_region_bits = '0, agt_s1_io_s2_evict_bits_region_bits = '0;
  wire  [15:0] agt_g_io_s2_evict_bits_region_bit_single, agt_i_io_s2_evict_bits_region_bit_single;
  logic [15:0] agt_s0_io_s2_evict_bits_region_bit_single = '0, agt_s1_io_s2_evict_bits_region_bit_single = '0;
  wire  [3:0] agt_g_io_s2_evict_bits_region_offset, agt_i_io_s2_evict_bits_region_offset;
  logic [3:0] agt_s0_io_s2_evict_bits_region_offset = '0, agt_s1_io_s2_evict_bits_region_offset = '0;
  wire  [3:0] agt_g_io_s2_evict_bits_access_cnt, agt_i_io_s2_evict_bits_access_cnt;
  logic [3:0] agt_s0_io_s2_evict_bits_access_cnt = '0, agt_s1_io_s2_evict_bits_access_cnt = '0;
  wire  agt_g_io_s2_evict_bits_decr_mode, agt_i_io_s2_evict_bits_decr_mode;
  logic agt_s0_io_s2_evict_bits_decr_mode = '0, agt_s1_io_s2_evict_bits_decr_mode = '0;
  wire  agt_g_io_s2_evict_bits_single_update, agt_i_io_s2_evict_bits_single_update;
  logic agt_s0_io_s2_evict_bits_single_update = '0, agt_s1_io_s2_evict_bits_single_update = '0;
  wire  agt_g_io_s2_evict_bits_has_been_signal_updated, agt_i_io_s2_evict_bits_has_been_signal_updated;
  logic agt_s0_io_s2_evict_bits_has_been_signal_updated = '0, agt_s1_io_s2_evict_bits_has_been_signal_updated = '0;
  logic [3:0] agt_io_act_threshold;
  logic [5:0] agt_io_act_stride;
  int agt_cov_s0_alloc = 0;
  int agt_cov_s0_update = 0;
  int agt_cov_s0_match_prev_blocks_alloc = 0;
  int agt_cov_s0_update_conflict = 0;
  int agt_cov_s0_do_dcache_evict = 0;
  int agt_cov_s0_dcache_evict_blocked_by_lookup = 0;
  int agt_cov_s0_dcache_evict_conflict = 0;
  int agt_cov_s0_m1_hit = 0;
  int agt_cov_s0_p1_hit = 0;
  int agt_cov_s1_alloc_decr_mode = 0;
  int agt_cov_s1_alloc_evicts_valid = 0;
  int agt_cov_s1_alloc_into_empty = 0;
  int agt_cov_s1_dcache_evict = 0;
  int agt_cov_s1_in_active_page = 0;
  int agt_cov_s1_pf_gen_blocks_pht = 0;
  int agt_cov_s1_out_of_range_inc = 0;
  int agt_cov_s1_out_of_range_dec = 0;
  int agt_cov_s1_sel_stride = 0;
  int agt_cov_access_cnt_saturated = 0;
  int agt_cov_s2_pht_lookup = 0;
  int agt_cov_s2_evict_real = 0;
  int agt_cov_s2_evict_real_dropped_onehot = 0;
  int agt_cov_s2_evict_single_update = 0;
  int agt_cov_s2_evict_has_been_updated = 0;
  int agt_cov_s2_evict_decr = 0;
  int agt_cov_agt_disabled = 0;
  logic [1:0] agt_armed = '0;
  int agt_armed_at = -1;
  ActiveGenerationTable agt_u_gold (
    .clock(clk),
    .reset(agt_reset),
    .io_agt_en(agt_io_agt_en),
    .io_s0_lookup_valid(agt_io_s0_lookup_valid),
    .io_s0_lookup_bits_region_tag(agt_io_s0_lookup_bits_region_tag),
    .io_s0_lookup_bits_region_p1_tag(agt_io_s0_lookup_bits_region_p1_tag),
    .io_s0_lookup_bits_region_m1_tag(agt_io_s0_lookup_bits_region_m1_tag),
    .io_s0_lookup_bits_region_offset(agt_io_s0_lookup_bits_region_offset),
    .io_s0_lookup_bits_pht_index(agt_io_s0_lookup_bits_pht_index),
    .io_s0_lookup_bits_pht_tag(agt_io_s0_lookup_bits_pht_tag),
    .io_s0_lookup_bits_allow_cross_region_p1(agt_io_s0_lookup_bits_allow_cross_region_p1),
    .io_s0_lookup_bits_allow_cross_region_m1(agt_io_s0_lookup_bits_allow_cross_region_m1),
    .io_s0_lookup_bits_region_paddr(agt_io_s0_lookup_bits_region_paddr),
    .io_s0_lookup_bits_region_vaddr(agt_io_s0_lookup_bits_region_vaddr),
    .io_s0_dcache_evict_valid(agt_io_s0_dcache_evict_valid),
    .io_s0_dcache_evict_bits_vaddr(agt_io_s0_dcache_evict_bits_vaddr),
    .io_s1_sel_stride(agt_g_io_s1_sel_stride),
    .io_s2_pht_lookup_valid(agt_g_io_s2_pht_lookup_valid),
    .io_s2_pht_lookup_bits_pht_index(agt_g_io_s2_pht_lookup_bits_pht_index),
    .io_s2_pht_lookup_bits_pht_tag(agt_g_io_s2_pht_lookup_bits_pht_tag),
    .io_s2_pht_lookup_bits_region_paddr(agt_g_io_s2_pht_lookup_bits_region_paddr),
    .io_s2_pht_lookup_bits_region_vaddr(agt_g_io_s2_pht_lookup_bits_region_vaddr),
    .io_s2_pht_lookup_bits_region_offset(agt_g_io_s2_pht_lookup_bits_region_offset),
    .io_s2_evict_valid(agt_g_io_s2_evict_valid),
    .io_s2_evict_bits_pht_index(agt_g_io_s2_evict_bits_pht_index),
    .io_s2_evict_bits_pht_tag(agt_g_io_s2_evict_bits_pht_tag),
    .io_s2_evict_bits_region_bits(agt_g_io_s2_evict_bits_region_bits),
    .io_s2_evict_bits_region_bit_single(agt_g_io_s2_evict_bits_region_bit_single),
    .io_s2_evict_bits_region_offset(agt_g_io_s2_evict_bits_region_offset),
    .io_s2_evict_bits_access_cnt(agt_g_io_s2_evict_bits_access_cnt),
    .io_s2_evict_bits_decr_mode(agt_g_io_s2_evict_bits_decr_mode),
    .io_s2_evict_bits_single_update(agt_g_io_s2_evict_bits_single_update),
    .io_s2_evict_bits_has_been_signal_updated(agt_g_io_s2_evict_bits_has_been_signal_updated),
    .io_act_threshold(agt_io_act_threshold),
    .io_act_stride(agt_io_act_stride)
  );
  ActiveGenerationTable_xs agt_u_impl (
    .clock(clk),
    .reset(agt_reset),
    .io_agt_en(agt_io_agt_en),
    .io_s0_lookup_valid(agt_io_s0_lookup_valid),
    .io_s0_lookup_bits_region_tag(agt_io_s0_lookup_bits_region_tag),
    .io_s0_lookup_bits_region_p1_tag(agt_io_s0_lookup_bits_region_p1_tag),
    .io_s0_lookup_bits_region_m1_tag(agt_io_s0_lookup_bits_region_m1_tag),
    .io_s0_lookup_bits_region_offset(agt_io_s0_lookup_bits_region_offset),
    .io_s0_lookup_bits_pht_index(agt_io_s0_lookup_bits_pht_index),
    .io_s0_lookup_bits_pht_tag(agt_io_s0_lookup_bits_pht_tag),
    .io_s0_lookup_bits_allow_cross_region_p1(agt_io_s0_lookup_bits_allow_cross_region_p1),
    .io_s0_lookup_bits_allow_cross_region_m1(agt_io_s0_lookup_bits_allow_cross_region_m1),
    .io_s0_lookup_bits_region_paddr(agt_io_s0_lookup_bits_region_paddr),
    .io_s0_lookup_bits_region_vaddr(agt_io_s0_lookup_bits_region_vaddr),
    .io_s0_dcache_evict_valid(agt_io_s0_dcache_evict_valid),
    .io_s0_dcache_evict_bits_vaddr(agt_io_s0_dcache_evict_bits_vaddr),
    .io_s1_sel_stride(agt_i_io_s1_sel_stride),
    .io_s2_pht_lookup_valid(agt_i_io_s2_pht_lookup_valid),
    .io_s2_pht_lookup_bits_pht_index(agt_i_io_s2_pht_lookup_bits_pht_index),
    .io_s2_pht_lookup_bits_pht_tag(agt_i_io_s2_pht_lookup_bits_pht_tag),
    .io_s2_pht_lookup_bits_region_paddr(agt_i_io_s2_pht_lookup_bits_region_paddr),
    .io_s2_pht_lookup_bits_region_vaddr(agt_i_io_s2_pht_lookup_bits_region_vaddr),
    .io_s2_pht_lookup_bits_region_offset(agt_i_io_s2_pht_lookup_bits_region_offset),
    .io_s2_evict_valid(agt_i_io_s2_evict_valid),
    .io_s2_evict_bits_pht_index(agt_i_io_s2_evict_bits_pht_index),
    .io_s2_evict_bits_pht_tag(agt_i_io_s2_evict_bits_pht_tag),
    .io_s2_evict_bits_region_bits(agt_i_io_s2_evict_bits_region_bits),
    .io_s2_evict_bits_region_bit_single(agt_i_io_s2_evict_bits_region_bit_single),
    .io_s2_evict_bits_region_offset(agt_i_io_s2_evict_bits_region_offset),
    .io_s2_evict_bits_access_cnt(agt_i_io_s2_evict_bits_access_cnt),
    .io_s2_evict_bits_decr_mode(agt_i_io_s2_evict_bits_decr_mode),
    .io_s2_evict_bits_single_update(agt_i_io_s2_evict_bits_single_update),
    .io_s2_evict_bits_has_been_signal_updated(agt_i_io_s2_evict_bits_has_been_signal_updated),
    .io_act_threshold(agt_io_act_threshold),
    .io_act_stride(agt_io_act_stride)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) agt_mode = $urandom_range(0, 15);
      agt_io_agt_en = 1'($urandom);
      agt_io_s0_lookup_valid = 1'($urandom);
      agt_io_s0_lookup_bits_region_tag = 11'($urandom);
      agt_io_s0_lookup_bits_region_p1_tag = 11'($urandom);
      agt_io_s0_lookup_bits_region_m1_tag = 11'($urandom);
      agt_io_s0_lookup_bits_region_offset = 4'($urandom);
      agt_io_s0_lookup_bits_pht_index = 5'($urandom);
      agt_io_s0_lookup_bits_pht_tag = 13'($urandom);
      agt_io_s0_lookup_bits_allow_cross_region_p1 = 1'($urandom);
      agt_io_s0_lookup_bits_allow_cross_region_m1 = 1'($urandom);
      agt_io_s0_lookup_bits_region_paddr = 40'({$urandom, $urandom});
      agt_io_s0_lookup_bits_region_vaddr = 40'({$urandom, $urandom});
      agt_io_s0_dcache_evict_valid = 1'($urandom);
      agt_io_s0_dcache_evict_bits_vaddr = 50'({$urandom, $urandom});
      agt_io_act_threshold = 4'($urandom);
      agt_io_act_stride = 6'($urandom);
      agt_reset = (cyc < RESET_CYC) || ($urandom_range(0, 11999) == 0);
      begin : stim_agt
        logic [10:0] t, et;
        logic [4:0]  r;
        t = agt_rnd_tag(agt_mode);
        agt_io_s0_lookup_bits_region_tag = t;
        agt_io_s0_lookup_bits_region_p1_tag = ($urandom_range(0, 7) == 0) ? 11'($urandom) : agt_rnd_tag(agt_mode);
        agt_io_s0_lookup_bits_region_m1_tag = ($urandom_range(0, 7) == 0) ? 11'($urandom) : agt_rnd_tag(agt_mode);
        case ((agt_mode / 4) % 3)
          0: agt_io_s0_lookup_valid = ($urandom_range(0, 5) == 0);
          1: ;
          2: agt_io_s0_lookup_valid = ($urandom_range(0, 15) != 0);
        endcase
        et = agt_rnd_tag(agt_mode);
        r  = 5'($urandom);
        agt_io_s0_dcache_evict_bits_vaddr = {19'($urandom), r, r ^ et[10:6], 5'h0, et[5:0], 10'($urandom)};
        agt_io_s0_dcache_evict_bits_vaddr[20:16] = 5'h0 ^ et[10:6] ^ r ^ r;
        agt_io_s0_dcache_evict_bits_vaddr[25:21] = r;
        agt_io_s0_dcache_evict_bits_vaddr[30:26] = r;
        if ($urandom_range(0, 3) == 0)
          agt_io_s0_lookup_bits_region_vaddr[10:0] = $urandom_range(0, 1) ? 11'($urandom_range(0, 3)) : 11'h7ff - 11'($urandom_range(0, 3));
        if ($urandom_range(0, 63) == 0) agt_thr = 4'($urandom);
        if ($urandom_range(0, 63) == 0) agt_stride = 6'($urandom);
        if ($urandom_range(0, 63) == 0) agt_en_hold = ($urandom_range(0, 7) != 0);
        agt_io_act_threshold = agt_thr;
        agt_io_act_stride = agt_stride;
        agt_io_agt_en = agt_en_hold;
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&agt_armed)) begin
        checks++;
        if (agt_g_io_s1_sel_stride !== agt_i_io_s1_sel_stride) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s1_sel_stride g=%h i=%h", cyc, agt_g_io_s1_sel_stride, agt_i_io_s1_sel_stride);
        end
        agt_s1_io_s1_sel_stride |= agt_g_io_s1_sel_stride;
        agt_s0_io_s1_sel_stride |= ~agt_g_io_s1_sel_stride;
        checks++;
        if (agt_g_io_s2_pht_lookup_valid !== agt_i_io_s2_pht_lookup_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_pht_lookup_valid g=%h i=%h", cyc, agt_g_io_s2_pht_lookup_valid, agt_i_io_s2_pht_lookup_valid);
        end
        agt_s1_io_s2_pht_lookup_valid |= agt_g_io_s2_pht_lookup_valid;
        agt_s0_io_s2_pht_lookup_valid |= ~agt_g_io_s2_pht_lookup_valid;
        checks++;
        if (agt_g_io_s2_pht_lookup_bits_pht_index !== agt_i_io_s2_pht_lookup_bits_pht_index) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_pht_lookup_bits_pht_index g=%h i=%h", cyc, agt_g_io_s2_pht_lookup_bits_pht_index, agt_i_io_s2_pht_lookup_bits_pht_index);
        end
        agt_s1_io_s2_pht_lookup_bits_pht_index |= agt_g_io_s2_pht_lookup_bits_pht_index;
        agt_s0_io_s2_pht_lookup_bits_pht_index |= ~agt_g_io_s2_pht_lookup_bits_pht_index;
        checks++;
        if (agt_g_io_s2_pht_lookup_bits_pht_tag !== agt_i_io_s2_pht_lookup_bits_pht_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag g=%h i=%h", cyc, agt_g_io_s2_pht_lookup_bits_pht_tag, agt_i_io_s2_pht_lookup_bits_pht_tag);
        end
        agt_s1_io_s2_pht_lookup_bits_pht_tag |= agt_g_io_s2_pht_lookup_bits_pht_tag;
        agt_s0_io_s2_pht_lookup_bits_pht_tag |= ~agt_g_io_s2_pht_lookup_bits_pht_tag;
        checks++;
        if (agt_g_io_s2_pht_lookup_bits_region_paddr !== agt_i_io_s2_pht_lookup_bits_region_paddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr g=%h i=%h", cyc, agt_g_io_s2_pht_lookup_bits_region_paddr, agt_i_io_s2_pht_lookup_bits_region_paddr);
        end
        agt_s1_io_s2_pht_lookup_bits_region_paddr |= agt_g_io_s2_pht_lookup_bits_region_paddr;
        agt_s0_io_s2_pht_lookup_bits_region_paddr |= ~agt_g_io_s2_pht_lookup_bits_region_paddr;
        checks++;
        if (agt_g_io_s2_pht_lookup_bits_region_vaddr !== agt_i_io_s2_pht_lookup_bits_region_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr g=%h i=%h", cyc, agt_g_io_s2_pht_lookup_bits_region_vaddr, agt_i_io_s2_pht_lookup_bits_region_vaddr);
        end
        agt_s1_io_s2_pht_lookup_bits_region_vaddr |= agt_g_io_s2_pht_lookup_bits_region_vaddr;
        agt_s0_io_s2_pht_lookup_bits_region_vaddr |= ~agt_g_io_s2_pht_lookup_bits_region_vaddr;
        checks++;
        if (agt_g_io_s2_pht_lookup_bits_region_offset !== agt_i_io_s2_pht_lookup_bits_region_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_pht_lookup_bits_region_offset g=%h i=%h", cyc, agt_g_io_s2_pht_lookup_bits_region_offset, agt_i_io_s2_pht_lookup_bits_region_offset);
        end
        agt_s1_io_s2_pht_lookup_bits_region_offset |= agt_g_io_s2_pht_lookup_bits_region_offset;
        agt_s0_io_s2_pht_lookup_bits_region_offset |= ~agt_g_io_s2_pht_lookup_bits_region_offset;
        checks++;
        if (agt_g_io_s2_evict_valid !== agt_i_io_s2_evict_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_valid g=%h i=%h", cyc, agt_g_io_s2_evict_valid, agt_i_io_s2_evict_valid);
        end
        agt_s1_io_s2_evict_valid |= agt_g_io_s2_evict_valid;
        agt_s0_io_s2_evict_valid |= ~agt_g_io_s2_evict_valid;
        checks++;
        if (agt_g_io_s2_evict_bits_pht_index !== agt_i_io_s2_evict_bits_pht_index) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_pht_index g=%h i=%h", cyc, agt_g_io_s2_evict_bits_pht_index, agt_i_io_s2_evict_bits_pht_index);
        end
        agt_s1_io_s2_evict_bits_pht_index |= agt_g_io_s2_evict_bits_pht_index;
        agt_s0_io_s2_evict_bits_pht_index |= ~agt_g_io_s2_evict_bits_pht_index;
        checks++;
        if (agt_g_io_s2_evict_bits_pht_tag !== agt_i_io_s2_evict_bits_pht_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_pht_tag g=%h i=%h", cyc, agt_g_io_s2_evict_bits_pht_tag, agt_i_io_s2_evict_bits_pht_tag);
        end
        agt_s1_io_s2_evict_bits_pht_tag |= agt_g_io_s2_evict_bits_pht_tag;
        agt_s0_io_s2_evict_bits_pht_tag |= ~agt_g_io_s2_evict_bits_pht_tag;
        checks++;
        if (agt_g_io_s2_evict_bits_region_bits !== agt_i_io_s2_evict_bits_region_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_region_bits g=%h i=%h", cyc, agt_g_io_s2_evict_bits_region_bits, agt_i_io_s2_evict_bits_region_bits);
        end
        agt_s1_io_s2_evict_bits_region_bits |= agt_g_io_s2_evict_bits_region_bits;
        agt_s0_io_s2_evict_bits_region_bits |= ~agt_g_io_s2_evict_bits_region_bits;
        checks++;
        if (agt_g_io_s2_evict_bits_region_bit_single !== agt_i_io_s2_evict_bits_region_bit_single) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_region_bit_single g=%h i=%h", cyc, agt_g_io_s2_evict_bits_region_bit_single, agt_i_io_s2_evict_bits_region_bit_single);
        end
        agt_s1_io_s2_evict_bits_region_bit_single |= agt_g_io_s2_evict_bits_region_bit_single;
        agt_s0_io_s2_evict_bits_region_bit_single |= ~agt_g_io_s2_evict_bits_region_bit_single;
        checks++;
        if (agt_g_io_s2_evict_bits_region_offset !== agt_i_io_s2_evict_bits_region_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_region_offset g=%h i=%h", cyc, agt_g_io_s2_evict_bits_region_offset, agt_i_io_s2_evict_bits_region_offset);
        end
        agt_s1_io_s2_evict_bits_region_offset |= agt_g_io_s2_evict_bits_region_offset;
        agt_s0_io_s2_evict_bits_region_offset |= ~agt_g_io_s2_evict_bits_region_offset;
        checks++;
        if (agt_g_io_s2_evict_bits_access_cnt !== agt_i_io_s2_evict_bits_access_cnt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_access_cnt g=%h i=%h", cyc, agt_g_io_s2_evict_bits_access_cnt, agt_i_io_s2_evict_bits_access_cnt);
        end
        agt_s1_io_s2_evict_bits_access_cnt |= agt_g_io_s2_evict_bits_access_cnt;
        agt_s0_io_s2_evict_bits_access_cnt |= ~agt_g_io_s2_evict_bits_access_cnt;
        checks++;
        if (agt_g_io_s2_evict_bits_decr_mode !== agt_i_io_s2_evict_bits_decr_mode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_decr_mode g=%h i=%h", cyc, agt_g_io_s2_evict_bits_decr_mode, agt_i_io_s2_evict_bits_decr_mode);
        end
        agt_s1_io_s2_evict_bits_decr_mode |= agt_g_io_s2_evict_bits_decr_mode;
        agt_s0_io_s2_evict_bits_decr_mode |= ~agt_g_io_s2_evict_bits_decr_mode;
        checks++;
        if (agt_g_io_s2_evict_bits_single_update !== agt_i_io_s2_evict_bits_single_update) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_single_update g=%h i=%h", cyc, agt_g_io_s2_evict_bits_single_update, agt_i_io_s2_evict_bits_single_update);
        end
        agt_s1_io_s2_evict_bits_single_update |= agt_g_io_s2_evict_bits_single_update;
        agt_s0_io_s2_evict_bits_single_update |= ~agt_g_io_s2_evict_bits_single_update;
        checks++;
        if (agt_g_io_s2_evict_bits_has_been_signal_updated !== agt_i_io_s2_evict_bits_has_been_signal_updated) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ActiveGenerationTable.io_s2_evict_bits_has_been_signal_updated g=%h i=%h", cyc, agt_g_io_s2_evict_bits_has_been_signal_updated, agt_i_io_s2_evict_bits_has_been_signal_updated);
        end
        agt_s1_io_s2_evict_bits_has_been_signal_updated |= agt_g_io_s2_evict_bits_has_been_signal_updated;
        agt_s0_io_s2_evict_bits_has_been_signal_updated |= ~agt_g_io_s2_evict_bits_has_been_signal_updated;
        if (agt_u_gold.s0_alloc) agt_cov_s0_alloc++;
        if (agt_u_gold.s0_update) agt_cov_s0_update++;
        if (agt_io_s0_lookup_valid && !(|agt_u_gold._any_region_match_T) && !agt_u_gold.s0_alloc) agt_cov_s0_match_prev_blocks_alloc++;
        if (agt_io_s0_lookup_valid && (|agt_u_gold._any_region_match_T) && !agt_u_gold.s0_update) agt_cov_s0_update_conflict++;
        if (agt_u_gold.s0_do_dcache_evict) agt_cov_s0_do_dcache_evict++;
        if (agt_io_s0_dcache_evict_valid && agt_io_s0_lookup_valid) agt_cov_s0_dcache_evict_blocked_by_lookup++;
        if (agt_io_s0_dcache_evict_valid && !agt_u_gold._io_s0_dcache_evict_ready_T_1) agt_cov_s0_dcache_evict_conflict++;
        if (agt_io_s0_lookup_valid && agt_u_gold.any_region_m1_match) agt_cov_s0_m1_hit++;
        if (agt_io_s0_lookup_valid && agt_u_gold.any_region_p1_match) agt_cov_s0_p1_hit++;
        if (agt_u_gold.s1_alloc_last_REG && agt_u_gold.s1_agt_entry_decr_mode) agt_cov_s1_alloc_decr_mode++;
        if (agt_u_gold.s1_alloc_last_REG && agt_u_gold.s1_evict_valid) agt_cov_s1_alloc_evicts_valid++;
        if (agt_u_gold.s1_alloc_last_REG && !agt_u_gold.s1_evict_valid) agt_cov_s1_alloc_into_empty++;
        if (agt_u_gold.s1_do_dcache_evict_last_REG) agt_cov_s1_dcache_evict++;
        if (agt_u_gold.prev_lookup_valid_last_REG && (agt_u_gold._io_s1_sel_stride_T || agt_u_gold.s1_update_last_REG) && agt_u_gold.s1_in_active_page) agt_cov_s1_in_active_page++;
        if (agt_u_gold.prev_lookup_valid_last_REG && !agt_u_gold.s1_pht_lookup_valid) agt_cov_s1_pf_gen_blocks_pht++;
        if (agt_u_gold.prev_lookup_valid_last_REG && (agt_u_gold._io_s1_sel_stride_T || agt_u_gold.s1_update_last_REG) && agt_u_gold._s1_pf_gen_vaddr_inc_T_2[15]) agt_cov_s1_out_of_range_inc++;
        if (agt_u_gold.prev_lookup_valid_last_REG && (agt_u_gold._io_s1_sel_stride_T || agt_u_gold.s1_update_last_REG) && agt_u_gold._s1_pf_gen_vaddr_dec_T_2[15]) agt_cov_s1_out_of_range_dec++;
        if (agt_g_io_s1_sel_stride) agt_cov_s1_sel_stride++;
        if ((agt_u_gold.valids_0 && agt_u_gold.entries_0_access_cnt == 4'hf) || (agt_u_gold.valids_1 && agt_u_gold.entries_1_access_cnt == 4'hf) || (agt_u_gold.valids_2 && agt_u_gold.entries_2_access_cnt == 4'hf) || (agt_u_gold.valids_3 && agt_u_gold.entries_3_access_cnt == 4'hf) || (agt_u_gold.valids_4 && agt_u_gold.entries_4_access_cnt == 4'hf) || (agt_u_gold.valids_5 && agt_u_gold.entries_5_access_cnt == 4'hf) || (agt_u_gold.valids_6 && agt_u_gold.entries_6_access_cnt == 4'hf) || (agt_u_gold.valids_7 && agt_u_gold.entries_7_access_cnt == 4'hf) || (agt_u_gold.valids_8 && agt_u_gold.entries_8_access_cnt == 4'hf) || (agt_u_gold.valids_9 && agt_u_gold.entries_9_access_cnt == 4'hf) || (agt_u_gold.valids_10 && agt_u_gold.entries_10_access_cnt == 4'hf) || (agt_u_gold.valids_11 && agt_u_gold.entries_11_access_cnt == 4'hf) || (agt_u_gold.valids_12 && agt_u_gold.entries_12_access_cnt == 4'hf) || (agt_u_gold.valids_13 && agt_u_gold.entries_13_access_cnt == 4'hf) || (agt_u_gold.valids_14 && agt_u_gold.entries_14_access_cnt == 4'hf) || (agt_u_gold.valids_15 && agt_u_gold.entries_15_access_cnt == 4'hf)) agt_cov_access_cnt_saturated++;
        if (agt_g_io_s2_pht_lookup_valid) agt_cov_s2_pht_lookup++;
        if (agt_g_io_s2_evict_valid && agt_u_gold.s2_real_update) agt_cov_s2_evict_real++;
        if (agt_u_gold.s2_evict_valid_last_REG && agt_u_gold.s2_real_update && !agt_g_io_s2_evict_valid) agt_cov_s2_evict_real_dropped_onehot++;
        if (agt_g_io_s2_evict_valid && agt_g_io_s2_evict_bits_single_update) agt_cov_s2_evict_single_update++;
        if (agt_g_io_s2_evict_valid && agt_g_io_s2_evict_bits_has_been_signal_updated) agt_cov_s2_evict_has_been_updated++;
        if (agt_g_io_s2_evict_valid && agt_g_io_s2_evict_bits_decr_mode) agt_cov_s2_evict_decr++;
        if (!agt_io_agt_en) agt_cov_agt_disabled++;
      end
      if (agt_g_io_s2_pht_lookup_valid) agt_armed[0] = 1'b1;
      if (agt_u_gold.s2_evict_valid_last_REG) agt_armed[1] = 1'b1;
      if (agt_armed_at < 0 && (&agt_armed)) agt_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(agt_s0_io_s1_sel_stride && agt_s1_io_s1_sel_stride)) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s1_sel_stride 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_valid && agt_s1_io_s2_pht_lookup_valid)) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_valid 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_index[0] && agt_s1_io_s2_pht_lookup_bits_pht_index[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_index[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_index[1] && agt_s1_io_s2_pht_lookup_bits_pht_index[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_index[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_index[2] && agt_s1_io_s2_pht_lookup_bits_pht_index[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_index[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_index[3] && agt_s1_io_s2_pht_lookup_bits_pht_index[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_index[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_index[4] && agt_s1_io_s2_pht_lookup_bits_pht_index[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_index[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[0] && agt_s1_io_s2_pht_lookup_bits_pht_tag[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[1] && agt_s1_io_s2_pht_lookup_bits_pht_tag[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[2] && agt_s1_io_s2_pht_lookup_bits_pht_tag[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[3] && agt_s1_io_s2_pht_lookup_bits_pht_tag[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[4] && agt_s1_io_s2_pht_lookup_bits_pht_tag[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[5] && agt_s1_io_s2_pht_lookup_bits_pht_tag[5])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[5] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[6] && agt_s1_io_s2_pht_lookup_bits_pht_tag[6])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[6] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[7] && agt_s1_io_s2_pht_lookup_bits_pht_tag[7])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[7] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[8] && agt_s1_io_s2_pht_lookup_bits_pht_tag[8])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[8] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[9] && agt_s1_io_s2_pht_lookup_bits_pht_tag[9])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[9] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[10] && agt_s1_io_s2_pht_lookup_bits_pht_tag[10])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[10] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[11] && agt_s1_io_s2_pht_lookup_bits_pht_tag[11])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[11] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_pht_tag[12] && agt_s1_io_s2_pht_lookup_bits_pht_tag[12])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_pht_tag[12] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[0] && agt_s1_io_s2_pht_lookup_bits_region_paddr[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[1] && agt_s1_io_s2_pht_lookup_bits_region_paddr[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[2] && agt_s1_io_s2_pht_lookup_bits_region_paddr[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[3] && agt_s1_io_s2_pht_lookup_bits_region_paddr[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[4] && agt_s1_io_s2_pht_lookup_bits_region_paddr[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[5] && agt_s1_io_s2_pht_lookup_bits_region_paddr[5])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[5] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[6] && agt_s1_io_s2_pht_lookup_bits_region_paddr[6])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[6] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[7] && agt_s1_io_s2_pht_lookup_bits_region_paddr[7])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[7] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[8] && agt_s1_io_s2_pht_lookup_bits_region_paddr[8])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[8] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[9] && agt_s1_io_s2_pht_lookup_bits_region_paddr[9])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[9] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[10] && agt_s1_io_s2_pht_lookup_bits_region_paddr[10])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[10] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[11] && agt_s1_io_s2_pht_lookup_bits_region_paddr[11])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[11] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[12] && agt_s1_io_s2_pht_lookup_bits_region_paddr[12])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[12] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[13] && agt_s1_io_s2_pht_lookup_bits_region_paddr[13])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[13] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[14] && agt_s1_io_s2_pht_lookup_bits_region_paddr[14])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[14] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[15] && agt_s1_io_s2_pht_lookup_bits_region_paddr[15])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[15] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[16] && agt_s1_io_s2_pht_lookup_bits_region_paddr[16])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[16] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[17] && agt_s1_io_s2_pht_lookup_bits_region_paddr[17])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[17] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[18] && agt_s1_io_s2_pht_lookup_bits_region_paddr[18])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[18] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[19] && agt_s1_io_s2_pht_lookup_bits_region_paddr[19])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[19] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[20] && agt_s1_io_s2_pht_lookup_bits_region_paddr[20])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[20] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[21] && agt_s1_io_s2_pht_lookup_bits_region_paddr[21])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[21] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[22] && agt_s1_io_s2_pht_lookup_bits_region_paddr[22])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[22] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[23] && agt_s1_io_s2_pht_lookup_bits_region_paddr[23])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[23] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[24] && agt_s1_io_s2_pht_lookup_bits_region_paddr[24])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[24] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[25] && agt_s1_io_s2_pht_lookup_bits_region_paddr[25])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[25] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[26] && agt_s1_io_s2_pht_lookup_bits_region_paddr[26])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[26] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[27] && agt_s1_io_s2_pht_lookup_bits_region_paddr[27])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[27] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[28] && agt_s1_io_s2_pht_lookup_bits_region_paddr[28])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[28] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[29] && agt_s1_io_s2_pht_lookup_bits_region_paddr[29])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[29] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[30] && agt_s1_io_s2_pht_lookup_bits_region_paddr[30])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[30] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[31] && agt_s1_io_s2_pht_lookup_bits_region_paddr[31])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[31] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[32] && agt_s1_io_s2_pht_lookup_bits_region_paddr[32])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[32] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[33] && agt_s1_io_s2_pht_lookup_bits_region_paddr[33])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[33] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[34] && agt_s1_io_s2_pht_lookup_bits_region_paddr[34])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[34] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[35] && agt_s1_io_s2_pht_lookup_bits_region_paddr[35])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[35] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[36] && agt_s1_io_s2_pht_lookup_bits_region_paddr[36])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[36] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[37] && agt_s1_io_s2_pht_lookup_bits_region_paddr[37])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[37] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[38] && agt_s1_io_s2_pht_lookup_bits_region_paddr[38])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[38] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_paddr[39] && agt_s1_io_s2_pht_lookup_bits_region_paddr[39])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_paddr[39] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[0] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[1] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[2] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[3] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[4] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[5] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[5])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[5] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[6] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[6])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[6] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[7] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[7])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[7] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[8] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[8])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[8] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[9] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[9])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[9] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[10] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[10])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[10] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[11] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[11])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[11] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[12] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[12])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[12] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[13] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[13])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[13] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[14] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[14])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[14] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[15] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[15])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[15] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[16] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[16])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[16] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[17] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[17])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[17] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[18] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[18])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[18] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[19] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[19])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[19] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[20] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[20])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[20] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[21] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[21])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[21] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[22] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[22])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[22] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[23] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[23])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[23] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[24] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[24])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[24] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[25] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[25])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[25] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[26] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[26])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[26] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[27] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[27])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[27] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[28] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[28])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[28] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[29] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[29])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[29] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[30] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[30])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[30] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[31] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[31])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[31] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[32] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[32])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[32] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[33] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[33])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[33] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[34] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[34])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[34] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[35] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[35])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[35] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[36] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[36])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[36] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[37] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[37])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[37] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[38] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[38])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[38] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_vaddr[39] && agt_s1_io_s2_pht_lookup_bits_region_vaddr[39])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_vaddr[39] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_offset[0] && agt_s1_io_s2_pht_lookup_bits_region_offset[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_offset[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_offset[1] && agt_s1_io_s2_pht_lookup_bits_region_offset[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_offset[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_offset[2] && agt_s1_io_s2_pht_lookup_bits_region_offset[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_offset[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_pht_lookup_bits_region_offset[3] && agt_s1_io_s2_pht_lookup_bits_region_offset[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_pht_lookup_bits_region_offset[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_valid && agt_s1_io_s2_evict_valid)) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_valid 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_index[0] && agt_s1_io_s2_evict_bits_pht_index[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_index[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_index[1] && agt_s1_io_s2_evict_bits_pht_index[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_index[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_index[2] && agt_s1_io_s2_evict_bits_pht_index[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_index[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_index[3] && agt_s1_io_s2_evict_bits_pht_index[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_index[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_index[4] && agt_s1_io_s2_evict_bits_pht_index[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_index[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[0] && agt_s1_io_s2_evict_bits_pht_tag[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[1] && agt_s1_io_s2_evict_bits_pht_tag[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[2] && agt_s1_io_s2_evict_bits_pht_tag[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[3] && agt_s1_io_s2_evict_bits_pht_tag[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[4] && agt_s1_io_s2_evict_bits_pht_tag[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[5] && agt_s1_io_s2_evict_bits_pht_tag[5])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[5] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[6] && agt_s1_io_s2_evict_bits_pht_tag[6])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[6] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[7] && agt_s1_io_s2_evict_bits_pht_tag[7])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[7] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[8] && agt_s1_io_s2_evict_bits_pht_tag[8])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[8] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[9] && agt_s1_io_s2_evict_bits_pht_tag[9])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[9] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[10] && agt_s1_io_s2_evict_bits_pht_tag[10])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[10] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[11] && agt_s1_io_s2_evict_bits_pht_tag[11])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[11] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_pht_tag[12] && agt_s1_io_s2_evict_bits_pht_tag[12])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_pht_tag[12] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[0] && agt_s1_io_s2_evict_bits_region_bits[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[1] && agt_s1_io_s2_evict_bits_region_bits[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[2] && agt_s1_io_s2_evict_bits_region_bits[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[3] && agt_s1_io_s2_evict_bits_region_bits[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[4] && agt_s1_io_s2_evict_bits_region_bits[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[5] && agt_s1_io_s2_evict_bits_region_bits[5])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[5] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[6] && agt_s1_io_s2_evict_bits_region_bits[6])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[6] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[7] && agt_s1_io_s2_evict_bits_region_bits[7])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[7] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[8] && agt_s1_io_s2_evict_bits_region_bits[8])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[8] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[9] && agt_s1_io_s2_evict_bits_region_bits[9])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[9] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[10] && agt_s1_io_s2_evict_bits_region_bits[10])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[10] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[11] && agt_s1_io_s2_evict_bits_region_bits[11])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[11] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[12] && agt_s1_io_s2_evict_bits_region_bits[12])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[12] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[13] && agt_s1_io_s2_evict_bits_region_bits[13])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[13] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[14] && agt_s1_io_s2_evict_bits_region_bits[14])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[14] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bits[15] && agt_s1_io_s2_evict_bits_region_bits[15])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bits[15] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[0] && agt_s1_io_s2_evict_bits_region_bit_single[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[1] && agt_s1_io_s2_evict_bits_region_bit_single[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[2] && agt_s1_io_s2_evict_bits_region_bit_single[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[3] && agt_s1_io_s2_evict_bits_region_bit_single[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[4] && agt_s1_io_s2_evict_bits_region_bit_single[4])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[4] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[5] && agt_s1_io_s2_evict_bits_region_bit_single[5])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[5] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[6] && agt_s1_io_s2_evict_bits_region_bit_single[6])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[6] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[7] && agt_s1_io_s2_evict_bits_region_bit_single[7])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[7] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[8] && agt_s1_io_s2_evict_bits_region_bit_single[8])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[8] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[9] && agt_s1_io_s2_evict_bits_region_bit_single[9])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[9] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[10] && agt_s1_io_s2_evict_bits_region_bit_single[10])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[10] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[11] && agt_s1_io_s2_evict_bits_region_bit_single[11])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[11] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[12] && agt_s1_io_s2_evict_bits_region_bit_single[12])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[12] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[13] && agt_s1_io_s2_evict_bits_region_bit_single[13])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[13] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[14] && agt_s1_io_s2_evict_bits_region_bit_single[14])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[14] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_bit_single[15] && agt_s1_io_s2_evict_bits_region_bit_single[15])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_bit_single[15] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_offset[0] && agt_s1_io_s2_evict_bits_region_offset[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_offset[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_offset[1] && agt_s1_io_s2_evict_bits_region_offset[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_offset[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_offset[2] && agt_s1_io_s2_evict_bits_region_offset[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_offset[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_region_offset[3] && agt_s1_io_s2_evict_bits_region_offset[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_region_offset[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_access_cnt[0] && agt_s1_io_s2_evict_bits_access_cnt[0])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_access_cnt[0] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_access_cnt[1] && agt_s1_io_s2_evict_bits_access_cnt[1])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_access_cnt[1] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_access_cnt[2] && agt_s1_io_s2_evict_bits_access_cnt[2])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_access_cnt[2] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_access_cnt[3] && agt_s1_io_s2_evict_bits_access_cnt[3])) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_access_cnt[3] 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_decr_mode && agt_s1_io_s2_evict_bits_decr_mode)) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_decr_mode 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_single_update && agt_s1_io_s2_evict_bits_single_update)) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_single_update 未见过 0 和 1"); end
    if (!(agt_s0_io_s2_evict_bits_has_been_signal_updated && agt_s1_io_s2_evict_bits_has_been_signal_updated)) begin cov_fail++; $display("[COV] ActiveGenerationTable.io_s2_evict_bits_has_been_signal_updated 未见过 0 和 1"); end
    $display("[ARM] ActiveGenerationTable armed_at=%0d", agt_armed_at);
    if (agt_armed_at < 0) begin cov_fail++; $display("[ARM] ActiveGenerationTable 从未 arm"); end
    $display("[COV] ActiveGenerationTable.s0_alloc = %0d", agt_cov_s0_alloc);
    if (agt_cov_s0_alloc < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_alloc < 100"); end
    $display("[COV] ActiveGenerationTable.s0_update = %0d", agt_cov_s0_update);
    if (agt_cov_s0_update < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_update < 100"); end
    $display("[COV] ActiveGenerationTable.s0_match_prev_blocks_alloc = %0d", agt_cov_s0_match_prev_blocks_alloc);
    if (agt_cov_s0_match_prev_blocks_alloc < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_match_prev_blocks_alloc < 100"); end
    $display("[COV] ActiveGenerationTable.s0_update_conflict = %0d", agt_cov_s0_update_conflict);
    if (agt_cov_s0_update_conflict < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_update_conflict < 100"); end
    $display("[COV] ActiveGenerationTable.s0_do_dcache_evict = %0d", agt_cov_s0_do_dcache_evict);
    if (agt_cov_s0_do_dcache_evict < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_do_dcache_evict < 100"); end
    $display("[COV] ActiveGenerationTable.s0_dcache_evict_blocked_by_lookup = %0d", agt_cov_s0_dcache_evict_blocked_by_lookup);
    if (agt_cov_s0_dcache_evict_blocked_by_lookup < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_dcache_evict_blocked_by_lookup < 100"); end
    $display("[COV] ActiveGenerationTable.s0_dcache_evict_conflict = %0d", agt_cov_s0_dcache_evict_conflict);
    if (agt_cov_s0_dcache_evict_conflict < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_dcache_evict_conflict < 100"); end
    $display("[COV] ActiveGenerationTable.s0_m1_hit = %0d", agt_cov_s0_m1_hit);
    if (agt_cov_s0_m1_hit < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_m1_hit < 100"); end
    $display("[COV] ActiveGenerationTable.s0_p1_hit = %0d", agt_cov_s0_p1_hit);
    if (agt_cov_s0_p1_hit < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s0_p1_hit < 100"); end
    $display("[COV] ActiveGenerationTable.s1_alloc_decr_mode = %0d", agt_cov_s1_alloc_decr_mode);
    if (agt_cov_s1_alloc_decr_mode < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_alloc_decr_mode < 100"); end
    $display("[COV] ActiveGenerationTable.s1_alloc_evicts_valid = %0d", agt_cov_s1_alloc_evicts_valid);
    if (agt_cov_s1_alloc_evicts_valid < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_alloc_evicts_valid < 100"); end
    $display("[COV] ActiveGenerationTable.s1_alloc_into_empty = %0d", agt_cov_s1_alloc_into_empty);
    if (agt_cov_s1_alloc_into_empty < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_alloc_into_empty < 100"); end
    $display("[COV] ActiveGenerationTable.s1_dcache_evict = %0d", agt_cov_s1_dcache_evict);
    if (agt_cov_s1_dcache_evict < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_dcache_evict < 100"); end
    $display("[COV] ActiveGenerationTable.s1_in_active_page = %0d", agt_cov_s1_in_active_page);
    if (agt_cov_s1_in_active_page < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_in_active_page < 100"); end
    $display("[COV] ActiveGenerationTable.s1_pf_gen_blocks_pht = %0d", agt_cov_s1_pf_gen_blocks_pht);
    if (agt_cov_s1_pf_gen_blocks_pht < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_pf_gen_blocks_pht < 100"); end
    $display("[COV] ActiveGenerationTable.s1_out_of_range_inc = %0d", agt_cov_s1_out_of_range_inc);
    if (agt_cov_s1_out_of_range_inc < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_out_of_range_inc < 100"); end
    $display("[COV] ActiveGenerationTable.s1_out_of_range_dec = %0d", agt_cov_s1_out_of_range_dec);
    if (agt_cov_s1_out_of_range_dec < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_out_of_range_dec < 100"); end
    $display("[COV] ActiveGenerationTable.s1_sel_stride = %0d", agt_cov_s1_sel_stride);
    if (agt_cov_s1_sel_stride < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s1_sel_stride < 100"); end
    $display("[COV] ActiveGenerationTable.access_cnt_saturated = %0d", agt_cov_access_cnt_saturated);
    if (agt_cov_access_cnt_saturated < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.access_cnt_saturated < 100"); end
    $display("[COV] ActiveGenerationTable.s2_pht_lookup = %0d", agt_cov_s2_pht_lookup);
    if (agt_cov_s2_pht_lookup < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s2_pht_lookup < 100"); end
    $display("[COV] ActiveGenerationTable.s2_evict_real = %0d", agt_cov_s2_evict_real);
    if (agt_cov_s2_evict_real < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s2_evict_real < 100"); end
    $display("[COV] ActiveGenerationTable.s2_evict_real_dropped_onehot = %0d", agt_cov_s2_evict_real_dropped_onehot);
    if (agt_cov_s2_evict_real_dropped_onehot < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s2_evict_real_dropped_onehot < 100"); end
    $display("[COV] ActiveGenerationTable.s2_evict_single_update = %0d", agt_cov_s2_evict_single_update);
    if (agt_cov_s2_evict_single_update < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s2_evict_single_update < 100"); end
    $display("[COV] ActiveGenerationTable.s2_evict_has_been_updated = %0d", agt_cov_s2_evict_has_been_updated);
    if (agt_cov_s2_evict_has_been_updated < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s2_evict_has_been_updated < 100"); end
    $display("[COV] ActiveGenerationTable.s2_evict_decr = %0d", agt_cov_s2_evict_decr);
    if (agt_cov_s2_evict_decr < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.s2_evict_decr < 100"); end
    $display("[COV] ActiveGenerationTable.agt_disabled = %0d", agt_cov_agt_disabled);
    if (agt_cov_agt_disabled < 100) begin cov_fail++; $display("[COV] ActiveGenerationTable.agt_disabled < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
