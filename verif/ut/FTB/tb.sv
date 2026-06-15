// FTB UT：golden FTB vs 可读 FTB_xs（均内部例化 golden FTBBank / DelayN* / SRAM 链）。
//
// 逐拍比对全部功能输出：
//   - s1: ready / uftbHit / uftbHasIndirect / ftbCloseReq
//   - s2: 4 路 full_pred 全字段（br_taken_mask/slot_valids/targets/jalr/offsets/
//         fallThrough{Addr,Err}/is_{jal,jalr,call,ret}/last_may_be_rvi_call/is_br_sharing/hit）
//   - s3: 4 路 full_pred 全字段（多 multiHit，无 jalr_target）
//   - last_stage: meta / sc_disagree / ftb_entry 全字段
//   - perf_0 / perf_1
//
// 激励：随机 s0_pc(4 路)、各级 fire、ctrl_btb_enable、uFTB 输入条目、update 通道
//       （write entry / false_hit / old_entry / meta / redirectFromIFU）。
//   窄 PC 提升 set/tag 命中、多命中概率；随机 fire 让流水推进与停顿交织；
//   update 随机交错触发立即写 / 先读后写 / 替换分配路径。
//   单端口约束：预测读与更新读不同拍——预测读 = s0_fire&!close（由 DUT 内部决定），
//   更新读 = update_need_read（DUT 内部据 meta 决定）。tb 通过低更新频率 + 让
//   s0_fire 大多数时候有效来近似遵守（与 FTBBank 单端口断言一致；UT 已 +SYNTHESIS 关断言）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 80000;
  int unsigned WARMUP  = 800;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  // ---- 驱动 ----
  logic [47:0] reset_vector;
  logic [49:0] s0_pc [4];
  logic        s0_fire [4], s1_fire [4], s2_fire [4], s3_fire_0;
  logic        ctrl_btb_enable, redirectFromIFU;
  logic [1:0]  in_s2_btm [4], in_s3_btm [4];
  logic        in_scd0, in_scd1;
  // uFTB 条目
  logic        fa_isCall, fa_isRet, fa_isJalr, fa_valid;
  logic [3:0]  fa_broff;  logic fa_brsh, fa_brv; logic [11:0] fa_brlo; logic [1:0] fa_brts;
  logic [3:0]  fa_tloff;  logic fa_tlsh, fa_tlv; logic [19:0] fa_tllo; logic [1:0] fa_tlts;
  logic [3:0]  fa_pft;    logic fa_carry, fa_lrvi, fa_sb0, fa_sb1; logic fa_hit;
  // update 条目
  logic        up_valid; logic [49:0] up_pc;
  logic        u_isCall, u_isRet, u_isJalr, u_evalid;
  logic [3:0]  u_broff;  logic u_brsh, u_brv; logic [11:0] u_brlo; logic [1:0] u_brts;
  logic [3:0]  u_tloff;  logic u_tlsh, u_tlv; logic [19:0] u_tllo; logic [1:0] u_tlts;
  logic [3:0]  u_pft;    logic u_carry, u_lrvi, u_sb0, u_sb1;
  logic        u_false_hit, u_old_entry; logic [515:0] u_meta;

  // ---- 输出（g_=golden, i_=xs），用大向量打包后整体比较 ----
  // s1
  wire g_ready, i_ready, g_uh, i_uh, g_uhi, i_uhi, g_cr, i_cr;
  // perf
  wire [5:0] g_p0, i_p0, g_p1, i_p1;
  // last_stage
  wire [515:0] g_meta, i_meta;
  wire g_scd0, i_scd0, g_scd1, i_scd1;

  // s2/s3 各 dup 输出聚合成单一比较向量（用 generate-like 宏展开端口）
  `define S2W(P,N) \
    wire P``s2_btm0_``N, P``s2_btm1_``N, P``s2_sv0_``N, P``s2_sv1_``N; \
    wire [49:0] P``s2_t0_``N, P``s2_t1_``N, P``s2_jt_``N; \
    wire [3:0] P``s2_o0_``N, P``s2_o1_``N; wire [49:0] P``s2_fta_``N; \
    wire P``s2_fte_``N, P``s2_jal_``N, P``s2_jalr_``N, P``s2_call_``N, P``s2_ret_``N, \
         P``s2_lrvi_``N, P``s2_brsh_``N, P``s2_hit_``N;
  `define S3W(P,N) \
    wire P``s3_btm0_``N, P``s3_btm1_``N, P``s3_sv0_``N, P``s3_sv1_``N; \
    wire [49:0] P``s3_t0_``N, P``s3_t1_``N; \
    wire [3:0] P``s3_o0_``N, P``s3_o1_``N; wire [49:0] P``s3_fta_``N; \
    wire P``s3_fte_``N, P``s3_mh_``N, P``s3_jal_``N, P``s3_jalr_``N, P``s3_call_``N, \
         P``s3_ret_``N, P``s3_lrvi_``N, P``s3_brsh_``N, P``s3_hit_``N;
  `S2W(g_,0) `S2W(g_,1) `S2W(g_,2) `S2W(g_,3)
  `S2W(i_,0) `S2W(i_,1) `S2W(i_,2) `S2W(i_,3)
  `S3W(g_,0) `S3W(g_,1) `S3W(g_,2) `S3W(g_,3)
  `S3W(i_,0) `S3W(i_,1) `S3W(i_,2) `S3W(i_,3)

  // last_stage ftb_entry
  `define LSE(P) \
    wire P``ls_isCall, P``ls_isRet, P``ls_isJalr, P``ls_valid; \
    wire [3:0] P``ls_broff; wire P``ls_brsh, P``ls_brv; wire [11:0] P``ls_brlo; wire [1:0] P``ls_brts; \
    wire [3:0] P``ls_tloff; wire P``ls_tlsh, P``ls_tlv; wire [19:0] P``ls_tllo; wire [1:0] P``ls_tlts; \
    wire [3:0] P``ls_pft; wire P``ls_carry, P``ls_lrvi, P``ls_sb0, P``ls_sb1;
  `LSE(g_) `LSE(i_)

  // ---- 端口连接宏 ----
  `define IN_S2BTM(N) \
    .io_in_bits_resp_in_0_s2_full_pred_``N``_br_taken_mask_0(in_s2_btm[N][0]), \
    .io_in_bits_resp_in_0_s2_full_pred_``N``_br_taken_mask_1(in_s2_btm[N][1])
  `define IN_S3BTM(N) \
    .io_in_bits_resp_in_0_s3_full_pred_``N``_br_taken_mask_0(in_s3_btm[N][0]), \
    .io_in_bits_resp_in_0_s3_full_pred_``N``_br_taken_mask_1(in_s3_btm[N][1])
  `define O_S2(P,N) \
    .io_out_s2_full_pred_``N``_br_taken_mask_0(P``s2_btm0_``N), \
    .io_out_s2_full_pred_``N``_br_taken_mask_1(P``s2_btm1_``N), \
    .io_out_s2_full_pred_``N``_slot_valids_0(P``s2_sv0_``N), \
    .io_out_s2_full_pred_``N``_slot_valids_1(P``s2_sv1_``N), \
    .io_out_s2_full_pred_``N``_targets_0(P``s2_t0_``N), \
    .io_out_s2_full_pred_``N``_targets_1(P``s2_t1_``N), \
    .io_out_s2_full_pred_``N``_jalr_target(P``s2_jt_``N), \
    .io_out_s2_full_pred_``N``_offsets_0(P``s2_o0_``N), \
    .io_out_s2_full_pred_``N``_offsets_1(P``s2_o1_``N), \
    .io_out_s2_full_pred_``N``_fallThroughAddr(P``s2_fta_``N), \
    .io_out_s2_full_pred_``N``_fallThroughErr(P``s2_fte_``N), \
    .io_out_s2_full_pred_``N``_is_jal(P``s2_jal_``N), \
    .io_out_s2_full_pred_``N``_is_jalr(P``s2_jalr_``N), \
    .io_out_s2_full_pred_``N``_is_call(P``s2_call_``N), \
    .io_out_s2_full_pred_``N``_is_ret(P``s2_ret_``N), \
    .io_out_s2_full_pred_``N``_last_may_be_rvi_call(P``s2_lrvi_``N), \
    .io_out_s2_full_pred_``N``_is_br_sharing(P``s2_brsh_``N), \
    .io_out_s2_full_pred_``N``_hit(P``s2_hit_``N)
  `define O_S3(P,N) \
    .io_out_s3_full_pred_``N``_br_taken_mask_0(P``s3_btm0_``N), \
    .io_out_s3_full_pred_``N``_br_taken_mask_1(P``s3_btm1_``N), \
    .io_out_s3_full_pred_``N``_slot_valids_0(P``s3_sv0_``N), \
    .io_out_s3_full_pred_``N``_slot_valids_1(P``s3_sv1_``N), \
    .io_out_s3_full_pred_``N``_targets_0(P``s3_t0_``N), \
    .io_out_s3_full_pred_``N``_targets_1(P``s3_t1_``N), \
    .io_out_s3_full_pred_``N``_offsets_0(P``s3_o0_``N), \
    .io_out_s3_full_pred_``N``_offsets_1(P``s3_o1_``N), \
    .io_out_s3_full_pred_``N``_fallThroughAddr(P``s3_fta_``N), \
    .io_out_s3_full_pred_``N``_fallThroughErr(P``s3_fte_``N), \
    .io_out_s3_full_pred_``N``_multiHit(P``s3_mh_``N), \
    .io_out_s3_full_pred_``N``_is_jal(P``s3_jal_``N), \
    .io_out_s3_full_pred_``N``_is_jalr(P``s3_jalr_``N), \
    .io_out_s3_full_pred_``N``_is_call(P``s3_call_``N), \
    .io_out_s3_full_pred_``N``_is_ret(P``s3_ret_``N), \
    .io_out_s3_full_pred_``N``_last_may_be_rvi_call(P``s3_lrvi_``N), \
    .io_out_s3_full_pred_``N``_is_br_sharing(P``s3_brsh_``N), \
    .io_out_s3_full_pred_``N``_hit(P``s3_hit_``N)
  `define O_LSE(P) \
    .io_out_last_stage_ftb_entry_isCall(P``ls_isCall), \
    .io_out_last_stage_ftb_entry_isRet(P``ls_isRet), \
    .io_out_last_stage_ftb_entry_isJalr(P``ls_isJalr), \
    .io_out_last_stage_ftb_entry_valid(P``ls_valid), \
    .io_out_last_stage_ftb_entry_brSlots_0_offset(P``ls_broff), \
    .io_out_last_stage_ftb_entry_brSlots_0_sharing(P``ls_brsh), \
    .io_out_last_stage_ftb_entry_brSlots_0_valid(P``ls_brv), \
    .io_out_last_stage_ftb_entry_brSlots_0_lower(P``ls_brlo), \
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat(P``ls_brts), \
    .io_out_last_stage_ftb_entry_tailSlot_offset(P``ls_tloff), \
    .io_out_last_stage_ftb_entry_tailSlot_sharing(P``ls_tlsh), \
    .io_out_last_stage_ftb_entry_tailSlot_valid(P``ls_tlv), \
    .io_out_last_stage_ftb_entry_tailSlot_lower(P``ls_tllo), \
    .io_out_last_stage_ftb_entry_tailSlot_tarStat(P``ls_tlts), \
    .io_out_last_stage_ftb_entry_pftAddr(P``ls_pft), \
    .io_out_last_stage_ftb_entry_carry(P``ls_carry), \
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call(P``ls_lrvi), \
    .io_out_last_stage_ftb_entry_strong_bias_0(P``ls_sb0), \
    .io_out_last_stage_ftb_entry_strong_bias_1(P``ls_sb1)

  // bore / sig tie-off
  `define BORETOP \
    .boreChildrenBd_bore_array(6'h0), .boreChildrenBd_bore_all(1'b0), \
    .boreChildrenBd_bore_req(1'b0), .boreChildrenBd_bore_ack(), \
    .boreChildrenBd_bore_writeen(1'b0), .boreChildrenBd_bore_be(4'h0), \
    .boreChildrenBd_bore_addr(10'h0), .boreChildrenBd_bore_indata(40'h0), \
    .boreChildrenBd_bore_readen(1'b0), .boreChildrenBd_bore_addr_rd(10'h0), \
    .boreChildrenBd_bore_outdata()
  `define SIG(N) \
    .sigFromSrams_bore``N``_ram_hold(1'b0), .sigFromSrams_bore``N``_ram_bypass(1'b0), \
    .sigFromSrams_bore``N``_ram_bp_clken(1'b0), .sigFromSrams_bore``N``_ram_aux_clk(1'b0), \
    .sigFromSrams_bore``N``_ram_aux_ckbp(1'b0), .sigFromSrams_bore``N``_ram_mcp_hold(1'b0), \
    .sigFromSrams_bore``N``_cgen(1'b0)

  `define PORTS(P,RDY) \
    .clock(clk), .reset(rst), .io_reset_vector(reset_vector), \
    .io_in_bits_s0_pc_0(s0_pc[0]), .io_in_bits_s0_pc_1(s0_pc[1]), \
    .io_in_bits_s0_pc_2(s0_pc[2]), .io_in_bits_s0_pc_3(s0_pc[3]), \
    `IN_S2BTM(0), `IN_S2BTM(1), `IN_S2BTM(2), `IN_S2BTM(3), \
    `IN_S3BTM(0), `IN_S3BTM(1), `IN_S3BTM(2), `IN_S3BTM(3), \
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(in_scd0), \
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(in_scd1), \
    `O_S2(P,0), `O_S2(P,1), `O_S2(P,2), `O_S2(P,3), \
    `O_S3(P,0), `O_S3(P,1), `O_S3(P,2), `O_S3(P,3), \
    .io_out_s1_uftbHit(P``uh), .io_out_s1_uftbHasIndirect(P``uhi), \
    .io_out_s1_ftbCloseReq(P``cr), \
    .io_out_last_stage_meta(P``meta), \
    .io_out_last_stage_spec_info_sc_disagree_0(P``scd0), \
    .io_out_last_stage_spec_info_sc_disagree_1(P``scd1), \
    `O_LSE(P), \
    .io_fauftb_entry_in_isCall(fa_isCall), .io_fauftb_entry_in_isRet(fa_isRet), \
    .io_fauftb_entry_in_isJalr(fa_isJalr), .io_fauftb_entry_in_valid(fa_valid), \
    .io_fauftb_entry_in_brSlots_0_offset(fa_broff), .io_fauftb_entry_in_brSlots_0_sharing(fa_brsh), \
    .io_fauftb_entry_in_brSlots_0_valid(fa_brv), .io_fauftb_entry_in_brSlots_0_lower(fa_brlo), \
    .io_fauftb_entry_in_brSlots_0_tarStat(fa_brts), .io_fauftb_entry_in_tailSlot_offset(fa_tloff), \
    .io_fauftb_entry_in_tailSlot_sharing(fa_tlsh), .io_fauftb_entry_in_tailSlot_valid(fa_tlv), \
    .io_fauftb_entry_in_tailSlot_lower(fa_tllo), .io_fauftb_entry_in_tailSlot_tarStat(fa_tlts), \
    .io_fauftb_entry_in_pftAddr(fa_pft), .io_fauftb_entry_in_carry(fa_carry), \
    .io_fauftb_entry_in_last_may_be_rvi_call(fa_lrvi), \
    .io_fauftb_entry_in_strong_bias_0(fa_sb0), .io_fauftb_entry_in_strong_bias_1(fa_sb1), \
    .io_fauftb_entry_hit_in(fa_hit), .io_ctrl_btb_enable(ctrl_btb_enable), \
    .io_s0_fire_0(s0_fire[0]), .io_s0_fire_1(s0_fire[1]), .io_s0_fire_2(s0_fire[2]), .io_s0_fire_3(s0_fire[3]), \
    .io_s1_fire_0(s1_fire[0]), .io_s1_fire_1(s1_fire[1]), .io_s1_fire_2(s1_fire[2]), .io_s1_fire_3(s1_fire[3]), \
    .io_s2_fire_0(s2_fire[0]), .io_s2_fire_1(s2_fire[1]), .io_s2_fire_2(s2_fire[2]), .io_s2_fire_3(s2_fire[3]), \
    .io_s3_fire_0(s3_fire_0), .io_s1_ready(RDY), \
    .io_update_valid(up_valid), .io_update_bits_pc(up_pc), \
    .io_update_bits_ftb_entry_isCall(u_isCall), .io_update_bits_ftb_entry_isRet(u_isRet), \
    .io_update_bits_ftb_entry_isJalr(u_isJalr), .io_update_bits_ftb_entry_valid(u_evalid), \
    .io_update_bits_ftb_entry_brSlots_0_offset(u_broff), .io_update_bits_ftb_entry_brSlots_0_sharing(u_brsh), \
    .io_update_bits_ftb_entry_brSlots_0_valid(u_brv), .io_update_bits_ftb_entry_brSlots_0_lower(u_brlo), \
    .io_update_bits_ftb_entry_brSlots_0_tarStat(u_brts), .io_update_bits_ftb_entry_tailSlot_offset(u_tloff), \
    .io_update_bits_ftb_entry_tailSlot_sharing(u_tlsh), .io_update_bits_ftb_entry_tailSlot_valid(u_tlv), \
    .io_update_bits_ftb_entry_tailSlot_lower(u_tllo), .io_update_bits_ftb_entry_tailSlot_tarStat(u_tlts), \
    .io_update_bits_ftb_entry_pftAddr(u_pft), .io_update_bits_ftb_entry_carry(u_carry), \
    .io_update_bits_ftb_entry_last_may_be_rvi_call(u_lrvi), \
    .io_update_bits_ftb_entry_strong_bias_0(u_sb0), .io_update_bits_ftb_entry_strong_bias_1(u_sb1), \
    .io_update_bits_false_hit(u_false_hit), .io_update_bits_old_entry(u_old_entry), \
    .io_update_bits_meta(u_meta), .io_redirectFromIFU(redirectFromIFU), \
    .io_perf_0_value(P``p0), .io_perf_1_value(P``p1), \
    `BORETOP, `SIG(), `SIG(_1), `SIG(_2), `SIG(_3), `SIG(_4), `SIG(_5), `SIG(_6), `SIG(_7)

  FTB    u_g (`PORTS(g_, g_ready));
  FTB_xs u_i (`PORTS(i_, i_ready));

  // ---- 随机激励 ----
  task automatic gen_pc(output logic [49:0] pc);
    pc = {20'h0, 6'($urandom), 14'($urandom)};   // 窄 PC：提升 set/tag 命中
  endtask

  logic [49:0] t;
  always @(negedge clk) begin
    if (rst) begin
      for (int d=0; d<4; d++) begin s0_fire[d]<=0; s1_fire[d]<=0; s2_fire[d]<=0; end
      s3_fire_0<=0; up_valid<=0;
    end else begin
      // fire：大多数拍推进（s0 多有效），让流水持续
      for (int d=0; d<4; d++) begin
        s0_fire[d] <= ($urandom_range(0,9) != 0);  // 90% 推进
        s1_fire[d] <= ($urandom_range(0,9) != 0);
        s2_fire[d] <= ($urandom_range(0,9) != 0);
      end
      s3_fire_0 <= ($urandom_range(0,9) != 0);
      ctrl_btb_enable <= ($urandom_range(0,9) != 0);
      redirectFromIFU <= ($urandom_range(0,15) == 0);
      gen_pc(t); s0_pc[0]<=t; gen_pc(t); s0_pc[1]<=t; gen_pc(t); s0_pc[2]<=t; gen_pc(t); s0_pc[3]<=t;
      for (int d=0; d<4; d++) begin in_s2_btm[d]<=2'($urandom); in_s3_btm[d]<=2'($urandom); end
      in_scd0<=$urandom; in_scd1<=$urandom;
      // uFTB 输入条目（窄目标）
      fa_isCall<=$urandom; fa_isRet<=$urandom; fa_isJalr<=$urandom; fa_valid<=$urandom;
      fa_broff<=4'($urandom); fa_brsh<=$urandom; fa_brv<=$urandom; fa_brlo<=12'($urandom); fa_brts<=2'($urandom_range(0,2));
      fa_tloff<=4'($urandom); fa_tlsh<=$urandom; fa_tlv<=$urandom; fa_tllo<=20'($urandom); fa_tlts<=2'($urandom_range(0,2));
      fa_pft<=4'($urandom); fa_carry<=$urandom; fa_lrvi<=$urandom; fa_sb0<=$urandom; fa_sb1<=$urandom;
      fa_hit<=($urandom_range(0,1));
      // update（20% 触发）
      up_valid <= ($urandom_range(0,4) == 0);
      gen_pc(t); up_pc<=t;
      u_isCall<=$urandom; u_isRet<=$urandom; u_isJalr<=$urandom; u_evalid<=$urandom;
      u_broff<=4'($urandom); u_brsh<=$urandom; u_brv<=$urandom; u_brlo<=12'($urandom); u_brts<=2'($urandom_range(0,2));
      u_tloff<=4'($urandom); u_tlsh<=$urandom; u_tlv<=$urandom; u_tllo<=20'($urandom); u_tlts<=2'($urandom_range(0,2));
      u_pft<=4'($urandom); u_carry<=$urandom; u_lrvi<=$urandom; u_sb0<=$urandom; u_sb1<=$urandom;
      u_false_hit<=$urandom; u_old_entry<=($urandom_range(0,1));
      u_meta<={484'($urandom), 2'($urandom), 1'($urandom), 29'($urandom)};  // meta[66:65]=way meta[64]=now
    end
  end

  // ---- 比对：仅在 golden 非 X 的位上比较（SRAM 在 +SYNTHESIS 下初值 X）----
  `define CK(name,g,i) \
    if (!$isunknown(g) && ((g)!==(i))) begin errors++; \
      if(errors<=30) $display("[%0t] %s mismatch g=%h i=%h",$time,name,g,i); end
  `define CKS2(N) \
    `CK("s2_btm0",g_s2_btm0_``N,i_s2_btm0_``N) `CK("s2_btm1",g_s2_btm1_``N,i_s2_btm1_``N) \
    `CK("s2_sv0",g_s2_sv0_``N,i_s2_sv0_``N) `CK("s2_sv1",g_s2_sv1_``N,i_s2_sv1_``N) \
    `CK("s2_t0",g_s2_t0_``N,i_s2_t0_``N) `CK("s2_t1",g_s2_t1_``N,i_s2_t1_``N) `CK("s2_jt",g_s2_jt_``N,i_s2_jt_``N) \
    `CK("s2_o0",g_s2_o0_``N,i_s2_o0_``N) `CK("s2_o1",g_s2_o1_``N,i_s2_o1_``N) \
    `CK("s2_fta",g_s2_fta_``N,i_s2_fta_``N) `CK("s2_fte",g_s2_fte_``N,i_s2_fte_``N) \
    `CK("s2_jal",g_s2_jal_``N,i_s2_jal_``N) `CK("s2_jalr",g_s2_jalr_``N,i_s2_jalr_``N) \
    `CK("s2_call",g_s2_call_``N,i_s2_call_``N) `CK("s2_ret",g_s2_ret_``N,i_s2_ret_``N) \
    `CK("s2_lrvi",g_s2_lrvi_``N,i_s2_lrvi_``N) `CK("s2_brsh",g_s2_brsh_``N,i_s2_brsh_``N) \
    `CK("s2_hit",g_s2_hit_``N,i_s2_hit_``N)
  `define CKS3(N) \
    `CK("s3_btm0",g_s3_btm0_``N,i_s3_btm0_``N) `CK("s3_btm1",g_s3_btm1_``N,i_s3_btm1_``N) \
    `CK("s3_sv0",g_s3_sv0_``N,i_s3_sv0_``N) `CK("s3_sv1",g_s3_sv1_``N,i_s3_sv1_``N) \
    `CK("s3_t0",g_s3_t0_``N,i_s3_t0_``N) `CK("s3_t1",g_s3_t1_``N,i_s3_t1_``N) \
    `CK("s3_o0",g_s3_o0_``N,i_s3_o0_``N) `CK("s3_o1",g_s3_o1_``N,i_s3_o1_``N) \
    `CK("s3_fta",g_s3_fta_``N,i_s3_fta_``N) `CK("s3_fte",g_s3_fte_``N,i_s3_fte_``N) \
    `CK("s3_mh",g_s3_mh_``N,i_s3_mh_``N) \
    `CK("s3_jal",g_s3_jal_``N,i_s3_jal_``N) `CK("s3_jalr",g_s3_jalr_``N,i_s3_jalr_``N) \
    `CK("s3_call",g_s3_call_``N,i_s3_call_``N) `CK("s3_ret",g_s3_ret_``N,i_s3_ret_``N) \
    `CK("s3_lrvi",g_s3_lrvi_``N,i_s3_lrvi_``N) `CK("s3_brsh",g_s3_brsh_``N,i_s3_brsh_``N) \
    `CK("s3_hit",g_s3_hit_``N,i_s3_hit_``N)

  always @(negedge clk) if (!rst && cycle>WARMUP) begin
    #4; checks++;
    `CK("ready",g_ready,i_ready) `CK("uftbHit",g_uh,i_uh) `CK("uftbHasIndirect",g_uhi,i_uhi)
    `CK("ftbCloseReq",g_cr,i_cr) `CK("perf0",g_p0,i_p0) `CK("perf1",g_p1,i_p1)
    `CK("meta",g_meta,i_meta) `CK("scd0",g_scd0,i_scd0) `CK("scd1",g_scd1,i_scd1)
    `CKS2(0) `CKS2(1) `CKS2(2) `CKS2(3)
    `CKS3(0) `CKS3(1) `CKS3(2) `CKS3(3)
    // last_stage ftb_entry
    `CK("ls_isCall",g_ls_isCall,i_ls_isCall) `CK("ls_isRet",g_ls_isRet,i_ls_isRet)
    `CK("ls_isJalr",g_ls_isJalr,i_ls_isJalr) `CK("ls_valid",g_ls_valid,i_ls_valid)
    `CK("ls_broff",g_ls_broff,i_ls_broff) `CK("ls_brsh",g_ls_brsh,i_ls_brsh) `CK("ls_brv",g_ls_brv,i_ls_brv)
    `CK("ls_brlo",g_ls_brlo,i_ls_brlo) `CK("ls_brts",g_ls_brts,i_ls_brts)
    `CK("ls_tloff",g_ls_tloff,i_ls_tloff) `CK("ls_tlsh",g_ls_tlsh,i_ls_tlsh) `CK("ls_tlv",g_ls_tlv,i_ls_tlv)
    `CK("ls_tllo",g_ls_tllo,i_ls_tllo) `CK("ls_tlts",g_ls_tlts,i_ls_tlts)
    `CK("ls_pft",g_ls_pft,i_ls_pft) `CK("ls_carry",g_ls_carry,i_ls_carry)
    `CK("ls_lrvi",g_ls_lrvi,i_ls_lrvi) `CK("ls_sb0",g_ls_sb0,i_ls_sb0) `CK("ls_sb1",g_ls_sb1,i_ls_sb1)
  end

  initial begin
    rst=1; reset_vector=48'h80000000;
    for (int d=0;d<4;d++) begin s0_pc[d]=0; in_s2_btm[d]=0; in_s3_btm[d]=0; end
    repeat(10) @(posedge clk); rst=0;
    repeat(NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
