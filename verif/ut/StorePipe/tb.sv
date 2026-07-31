// 自动生成：scripts/gen_storepipe.py —— 勿手改
// -----------------------------------------------------------------------------
//  StorePipe UT harness(codex_0088 §3 canonical-derivative 对拍)
//  双例化: 官方 reference = G0-StorePipe-observable-v1 canonical-derivative(module
//  `StorePipe`, 见 StorePipe_derivative_ref.sv) vs 可读核 xs_StorePipe_core。
//  同一激励喂两侧, 只比对 36 observable output leaves + 6 perf probes;
//  14 UNSPECIFIED_BY_SOURCE(miss_req DontCare×12 + replace_access.bits×2)排除。
//  seed 1/7/42 + `+vcs+initreg+0` errors=0。
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ===== 共享激励(同时喂 derivative reference 与 xs 核)=====
  logic [47:0] s1_paddr;
  logic        s1_kill, s2_kill;
  logic [49:0] s2_pc;
  logic        req_valid;
  logic [4:0]  req_cmd;
  logic [49:0] req_vaddr;
  logic [3:0]  req_instrtype;
  logic        resp_ready;
  logic        meta_read_ready, tag_read_ready, miss_req_ready;
  logic [1:0]  meta_resp_0, meta_resp_1, meta_resp_2, meta_resp_3;
  logic [42:0] tag_resp_0, tag_resp_1, tag_resp_2, tag_resp_3;
  logic [1:0]  replace_way_way;

  // ---- reference(derivative)输出 ----
  wire        g_req_ready, g_resp_valid, g_resp_miss, g_resp_replay, g_resp_tag_error;
  wire        g_meta_rd_valid, g_tag_rd_valid;
  wire [7:0]  g_meta_idx, g_tag_idx;
  wire [3:0]  g_meta_wayen, g_tag_wayen;
  wire        g_miss_valid, g_miss_cancel;
  wire [3:0]  g_miss_source, g_miss_occupy_way;
  wire [2:0]  g_miss_pf_source, g_miss_word_idx;
  wire [4:0]  g_miss_cmd;
  wire [47:0] g_miss_addr;
  wire [49:0] g_miss_vaddr, g_miss_pc;
  wire        g_miss_lqidx_flag, g_miss_full_ovw, g_miss_isbtot;
  wire [6:0]  g_miss_lqidx_val;
  wire [127:0] g_miss_amo_data, g_miss_amo_cmp;
  wire [15:0] g_miss_amo_mask;
  wire [1:0]  g_miss_coh;
  wire [5:0]  g_miss_id;
  wire [511:0] g_miss_store_data;
  wire [63:0] g_miss_store_mask;
  wire        g_rpa_valid, g_rpw_set_valid;
  wire [7:0]  g_rpa_set, g_rpw_set_bits;
  wire [1:0]  g_rpa_way, g_rpw_dmway;
  wire        g_err_valid, g_err_stag, g_err_sdata, g_err_sl2;
  wire        g_err_fetch, g_err_load, g_err_store, g_err_probe, g_err_rel, g_err_atom;
  wire [47:0] g_err_paddr;
  wire        g_err_beu;

  // ---- impl(xs 核)输出 ----
  wire        i_req_ready, i_resp_valid, i_resp_miss, i_resp_replay, i_resp_tag_error;
  wire        i_meta_rd_valid, i_tag_rd_valid;
  wire [7:0]  i_meta_idx, i_tag_idx;
  wire [3:0]  i_meta_wayen, i_tag_wayen;
  wire        i_miss_valid, i_miss_cancel;
  wire [3:0]  i_miss_source, i_miss_occupy_way;
  wire [2:0]  i_miss_pf_source, i_miss_word_idx;
  wire [4:0]  i_miss_cmd;
  wire [47:0] i_miss_addr;
  wire [49:0] i_miss_vaddr, i_miss_pc;
  wire        i_miss_lqidx_flag, i_miss_full_ovw, i_miss_isbtot;
  wire [6:0]  i_miss_lqidx_val;
  wire [127:0] i_miss_amo_data, i_miss_amo_cmp;
  wire [15:0] i_miss_amo_mask;
  wire [1:0]  i_miss_coh;
  wire [5:0]  i_miss_id;
  wire [511:0] i_miss_store_data;
  wire [63:0] i_miss_store_mask;
  wire        i_rpa_valid, i_rpw_set_valid;
  wire [7:0]  i_rpa_set, i_rpw_set_bits;
  wire [1:0]  i_rpa_way, i_rpw_dmway;
  wire        i_err_valid, i_err_stag, i_err_sdata, i_err_sl2;
  wire        i_err_fetch, i_err_load, i_err_store, i_err_probe, i_err_rel, i_err_atom;
  wire [47:0] i_err_paddr;
  wire        i_err_beu;

  // ===== reference(canonical-derivative, module StorePipe) =====
  StorePipe u_ref (
    .clock(clk), .reset(rst),
    .io_lsu_s1_paddr(s1_paddr), .io_lsu_s1_kill(s1_kill),
    .io_lsu_s2_kill(s2_kill), .io_lsu_s2_pc(s2_pc),
    .io_lsu_req_ready(g_req_ready), .io_lsu_req_valid(req_valid),
    .io_lsu_req_bits_cmd(req_cmd), .io_lsu_req_bits_vaddr(req_vaddr),
    .io_lsu_req_bits_instrtype(req_instrtype),
    .io_lsu_resp_ready(resp_ready),
    .io_lsu_resp_valid(g_resp_valid), .io_lsu_resp_bits_miss(g_resp_miss),
    .io_lsu_resp_bits_replay(g_resp_replay), .io_lsu_resp_bits_tag_error(g_resp_tag_error),
    .io_meta_read_ready(meta_read_ready), .io_meta_read_valid(g_meta_rd_valid),
    .io_meta_read_bits_idx(g_meta_idx), .io_meta_read_bits_way_en(g_meta_wayen),
    .io_meta_resp_0_coh_state(meta_resp_0), .io_meta_resp_1_coh_state(meta_resp_1),
    .io_meta_resp_2_coh_state(meta_resp_2), .io_meta_resp_3_coh_state(meta_resp_3),
    .io_tag_read_ready(tag_read_ready), .io_tag_read_valid(g_tag_rd_valid),
    .io_tag_read_bits_idx(g_tag_idx), .io_tag_read_bits_way_en(g_tag_wayen),
    .io_tag_resp_0(tag_resp_0), .io_tag_resp_1(tag_resp_1),
    .io_tag_resp_2(tag_resp_2), .io_tag_resp_3(tag_resp_3),
    .io_miss_req_ready(miss_req_ready), .io_miss_req_valid(g_miss_valid),
    .io_miss_req_bits_source(g_miss_source), .io_miss_req_bits_pf_source(g_miss_pf_source),
    .io_miss_req_bits_cmd(g_miss_cmd), .io_miss_req_bits_addr(g_miss_addr),
    .io_miss_req_bits_vaddr(g_miss_vaddr), .io_miss_req_bits_pc(g_miss_pc),
    .io_miss_req_bits_lqIdx_flag(g_miss_lqidx_flag), .io_miss_req_bits_lqIdx_value(g_miss_lqidx_val),
    .io_miss_req_bits_full_overwrite(g_miss_full_ovw), .io_miss_req_bits_word_idx(g_miss_word_idx),
    .io_miss_req_bits_amo_data(g_miss_amo_data), .io_miss_req_bits_amo_mask(g_miss_amo_mask),
    .io_miss_req_bits_amo_cmp(g_miss_amo_cmp), .io_miss_req_bits_req_coh_state(g_miss_coh),
    .io_miss_req_bits_id(g_miss_id), .io_miss_req_bits_isBtoT(g_miss_isbtot),
    .io_miss_req_bits_occupy_way(g_miss_occupy_way), .io_miss_req_bits_cancel(g_miss_cancel),
    .io_miss_req_bits_store_data(g_miss_store_data), .io_miss_req_bits_store_mask(g_miss_store_mask),
    .io_replace_access_valid(g_rpa_valid), .io_replace_access_bits_set(g_rpa_set),
    .io_replace_access_bits_way(g_rpa_way),
    .io_replace_way_set_valid(g_rpw_set_valid), .io_replace_way_set_bits(g_rpw_set_bits),
    .io_replace_way_dmWay(g_rpw_dmway), .io_replace_way_way(replace_way_way),
    .io_error_valid(g_err_valid), .io_error_bits_source_tag(g_err_stag),
    .io_error_bits_source_data(g_err_sdata), .io_error_bits_source_l2(g_err_sl2),
    .io_error_bits_opType_fetch(g_err_fetch), .io_error_bits_opType_load(g_err_load),
    .io_error_bits_opType_store(g_err_store), .io_error_bits_opType_probe(g_err_probe),
    .io_error_bits_opType_release(g_err_rel), .io_error_bits_opType_atom(g_err_atom),
    .io_error_bits_paddr(g_err_paddr), .io_error_bits_report_to_beu(g_err_beu)
  );

  // ===== impl(可读核 xs_StorePipe_core, EN_STORE_PF_AT_ISSUE=0 对齐 production) =====
  xs_StorePipe_core #(.EN_STORE_PF_AT_ISSUE(1'b0)) u_core (
    .clock(clk), .reset(rst),
    .io_lsu_s1_paddr(s1_paddr), .io_lsu_s1_kill(s1_kill),
    .io_lsu_s2_kill(s2_kill), .io_lsu_s2_pc(s2_pc),
    .io_lsu_req_ready(i_req_ready), .io_lsu_req_valid(req_valid),
    .io_lsu_req_bits_cmd(req_cmd), .io_lsu_req_bits_vaddr(req_vaddr),
    .io_lsu_req_bits_instrtype(req_instrtype),
    .io_lsu_resp_ready(resp_ready),
    .io_lsu_resp_valid(i_resp_valid), .io_lsu_resp_bits_miss(i_resp_miss),
    .io_lsu_resp_bits_replay(i_resp_replay), .io_lsu_resp_bits_tag_error(i_resp_tag_error),
    .io_meta_read_ready(meta_read_ready), .io_meta_read_valid(i_meta_rd_valid),
    .io_meta_read_bits_idx(i_meta_idx), .io_meta_read_bits_way_en(i_meta_wayen),
    .io_meta_resp_0_coh_state(meta_resp_0), .io_meta_resp_1_coh_state(meta_resp_1),
    .io_meta_resp_2_coh_state(meta_resp_2), .io_meta_resp_3_coh_state(meta_resp_3),
    .io_tag_read_ready(tag_read_ready), .io_tag_read_valid(i_tag_rd_valid),
    .io_tag_read_bits_idx(i_tag_idx), .io_tag_read_bits_way_en(i_tag_wayen),
    .io_tag_resp_0(tag_resp_0), .io_tag_resp_1(tag_resp_1),
    .io_tag_resp_2(tag_resp_2), .io_tag_resp_3(tag_resp_3),
    .io_miss_req_ready(miss_req_ready), .io_miss_req_valid(i_miss_valid),
    .io_miss_req_bits_source(i_miss_source), .io_miss_req_bits_pf_source(i_miss_pf_source),
    .io_miss_req_bits_cmd(i_miss_cmd), .io_miss_req_bits_addr(i_miss_addr),
    .io_miss_req_bits_vaddr(i_miss_vaddr), .io_miss_req_bits_pc(i_miss_pc),
    .io_miss_req_bits_lqIdx_flag(i_miss_lqidx_flag), .io_miss_req_bits_lqIdx_value(i_miss_lqidx_val),
    .io_miss_req_bits_full_overwrite(i_miss_full_ovw), .io_miss_req_bits_word_idx(i_miss_word_idx),
    .io_miss_req_bits_amo_data(i_miss_amo_data), .io_miss_req_bits_amo_mask(i_miss_amo_mask),
    .io_miss_req_bits_amo_cmp(i_miss_amo_cmp), .io_miss_req_bits_req_coh_state(i_miss_coh),
    .io_miss_req_bits_id(i_miss_id), .io_miss_req_bits_isBtoT(i_miss_isbtot),
    .io_miss_req_bits_occupy_way(i_miss_occupy_way), .io_miss_req_bits_cancel(i_miss_cancel),
    .io_miss_req_bits_store_data(i_miss_store_data), .io_miss_req_bits_store_mask(i_miss_store_mask),
    .io_replace_access_valid(i_rpa_valid), .io_replace_access_bits_set(i_rpa_set),
    .io_replace_access_bits_way(i_rpa_way),
    .io_replace_way_set_valid(i_rpw_set_valid), .io_replace_way_set_bits(i_rpw_set_bits),
    .io_replace_way_dmWay(i_rpw_dmway), .io_replace_way_way(replace_way_way),
    .io_error_valid(i_err_valid), .io_error_bits_source_tag(i_err_stag),
    .io_error_bits_source_data(i_err_sdata), .io_error_bits_source_l2(i_err_sl2),
    .io_error_bits_opType_fetch(i_err_fetch), .io_error_bits_opType_load(i_err_load),
    .io_error_bits_opType_store(i_err_store), .io_error_bits_opType_probe(i_err_probe),
    .io_error_bits_opType_release(i_err_rel), .io_error_bits_opType_atom(i_err_atom),
    .io_error_bits_paddr(i_err_paddr), .io_error_bits_report_to_beu(i_err_beu)
  );

  // ---- 随机激励(同一 vector 喂两侧) ----
  always @(negedge clk) begin
    if (rst) begin req_valid<=0; end
    else begin
      req_valid       <= ($urandom_range(0,4)!=0);
      req_cmd         <= 5'($urandom_range(0,31));  // 覆盖全 cmd 空间(命中/onAccess LUT)
      req_instrtype   <= 4'($urandom_range(0,3));
      req_vaddr       <= 50'($urandom);
      // paddr tag 区压窄(低 2 位)以提高 4 路命中概率
      s1_paddr        <= {34'h0, 2'($urandom_range(0,3)), 12'($urandom)};
      s1_kill         <= ($urandom_range(0,7)==0);
      s2_kill         <= ($urandom_range(0,7)==0);
      s2_pc           <= 50'($urandom);
      resp_ready      <= ($urandom_range(0,1));
      meta_read_ready <= ($urandom_range(0,4)!=0);
      tag_read_ready  <= ($urandom_range(0,4)!=0);
      miss_req_ready  <= ($urandom_range(0,4)!=0);
      replace_way_way <= 2'($urandom_range(0,3));
      meta_resp_0 <= 2'($urandom_range(0,3)); meta_resp_1 <= 2'($urandom_range(0,3));
      meta_resp_2 <= 2'($urandom_range(0,3)); meta_resp_3 <= 2'($urandom_range(0,3));
      // tag_resp 低 36 位命中区压窄, 高 7 位随机(不进比对)
      tag_resp_0 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      tag_resp_1 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      tag_resp_2 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      tag_resp_3 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
    end
  end

  // ---- 比对(36 observable output leaves + 6 perf probes; 14 UNSPECIFIED 排除) ----
  `define CHK(name, gexpr, iexpr) \
    if ((gexpr) !== (iexpr)) begin errors++; \
      if (errors<=80) $display("[%0t] %s ref=%h impl=%h", $time, name, (gexpr), (iexpr)); end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    // -- lsu.req / resp (5) --
    `CHK("req_ready",      g_req_ready,      i_req_ready)
    `CHK("resp_valid",     g_resp_valid,     i_resp_valid)
    `CHK("resp_miss",      g_resp_miss,      i_resp_miss)
    `CHK("resp_replay",    g_resp_replay,    i_resp_replay)
    `CHK("resp_tag_error", g_resp_tag_error, i_resp_tag_error)
    // -- meta_read (3) --
    `CHK("meta_rd_valid",  g_meta_rd_valid,  i_meta_rd_valid)
    `CHK("meta_idx",       g_meta_idx,       i_meta_idx)
    `CHK("meta_wayen",     g_meta_wayen,     i_meta_wayen)
    // -- tag_read (3) --
    `CHK("tag_rd_valid",   g_tag_rd_valid,   i_tag_rd_valid)
    `CHK("tag_idx",        g_tag_idx,        i_tag_idx)
    `CHK("tag_wayen",      g_tag_wayen,      i_tag_wayen)
    // -- miss_req live/const (10) --
    `CHK("miss_valid",     g_miss_valid,     i_miss_valid)
    `CHK("miss_source",    g_miss_source,    i_miss_source)
    `CHK("miss_pf_source", g_miss_pf_source, i_miss_pf_source)
    `CHK("miss_cmd",       g_miss_cmd,       i_miss_cmd)
    `CHK("miss_addr",      g_miss_addr,      i_miss_addr)
    `CHK("miss_vaddr",     g_miss_vaddr,     i_miss_vaddr)
    `CHK("miss_pc",        g_miss_pc,        i_miss_pc)
    `CHK("miss_coh",       g_miss_coh,       i_miss_coh)
    `CHK("miss_cancel",    g_miss_cancel,    i_miss_cancel)
    // -- replace_access.valid (1) --
    `CHK("rpa_valid",      g_rpa_valid,      i_rpa_valid)
    // -- replace_way (3) --
    `CHK("rpw_set_valid",  g_rpw_set_valid,  i_rpw_set_valid)
    `CHK("rpw_set_bits",   g_rpw_set_bits,   i_rpw_set_bits)
    `CHK("rpw_dmway",      g_rpw_dmway,      i_rpw_dmway)
    // -- error bundle (12) --
    `CHK("err_valid",      g_err_valid,      i_err_valid)
    `CHK("err_stag",       g_err_stag,       i_err_stag)
    `CHK("err_sdata",      g_err_sdata,      i_err_sdata)
    `CHK("err_sl2",        g_err_sl2,        i_err_sl2)
    `CHK("err_fetch",      g_err_fetch,      i_err_fetch)
    `CHK("err_load",       g_err_load,       i_err_load)
    `CHK("err_store",      g_err_store,      i_err_store)
    `CHK("err_probe",      g_err_probe,      i_err_probe)
    `CHK("err_rel",        g_err_rel,        i_err_rel)
    `CHK("err_atom",       g_err_atom,       i_err_atom)
    `CHK("err_paddr",      g_err_paddr,      i_err_paddr)
    `CHK("err_beu",        g_err_beu,        i_err_beu)
    // === 36 observable leaves checked above ===
    // -- 6 perf probes (hierarchical: derivative _GEN* vs core perfCnt_*) --
    `CHK("perf0", u_ref._GEN,   u_core.perfCnt_s0_valid_not_ready)
    `CHK("perf1", u_ref._GEN_0, u_core.perfCnt_store_fire)
    `CHK("perf2", u_ref._GEN_1, u_core.perfCnt_sta_hit)
    `CHK("perf3", u_ref._GEN_2, u_core.perfCnt_sta_miss)
    `CHK("perf4", u_ref._GEN_3, u_core.perfCnt_store_miss_prefetch_fire)
    `CHK("perf5", u_ref._GEN_4, u_core.perfCnt_store_miss_prefetch_not_fire)
    // === 14 UNSPECIFIED_BY_SOURCE deliberately NOT compared (source is DontCare):
    //   miss_req{lqIdx_flag,lqIdx_value,full_overwrite,word_idx,amo_data,amo_mask,
    //   amo_cmp,id,isBtoT,occupy_way,store_data,store_mask} + replace_access.bits{set,way}
  end

  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
